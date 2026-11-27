-- Slotbound iOS shim (LÖVE 11.5 / LiveContainer).
-- 1) Fake ffi.C: SbLuck*/SbPity* are Windows-only native exports from Slotbound.exe.
--    Luck/pity run on base probabilities only.
-- 2) iOS has no JIT: wrap jit.on/jit.off so the game's jit.on(fn, true) calls
--    fail silently instead of aborting startup.
-- 3) 手势层 v2（触屏交互方案定稿）：按下静默，靠「移动 / 长按 / 松手」三分派，
--    不再「按下 90ms 派发左键」。拖兵在移动超 slop 时补发 press（用按下坐标），
--    长按静默悬停出 tooltip（看详细），单击松手才发 click；升级树/专职两段式。
-- 运行时错误兜底：出错写 boot_error.log（否则 LÖVE 只弹蓝色错误屏，日志拿不到）
local function __sb_errh(msg)
    pcall(function() love.filesystem.append("boot_error.log", "[runtime] " .. tostring(msg) .. string.char(10)) end)
    return function() end
end
if love and love.errorhandler then love.errorhandler = __sb_errh end

-- 4) Discord 按钮重定向：菜单里的 Discord 邀请链接改跳本项目仓库（只拦这一个 URL）。
--    语言文件里 menu_discord 的显示文字同步改成 Yakult00。
do
    local origOpenURL = love.system and love.system.openURL
    if origOpenURL then
        love.system.openURL = function(url)
            if type(url) == "string" and url:find("discord.com/invite/XthPFC9thw", 1, true) then
                url = "https://github.com/Yakult00/Slotbound-iOS"
            end
            return origOpenURL(url)
        end
    end
end

local real_ffi = require("ffi")

local function SbLuckAbi(pitySize) return 1 end
local function SbLuckChance(wave, streak, used, earned, maxPermanent, chances, count)
    return 0.0
end
local function SbLuckChoose(weights, weightCount, candidateWeights, count, roll)
    if count and count >= 1 then return 1 end
    return 0
end
local function SbPityReset(state)
    if state then
        local s = state[0]
        s.missedWaves = 0
        s.currentWave = 0
        s.currentWavePresent = 0
        s.currentWaveHadSpin = 0
        s.currentWaveWon = 0
        s.guaranteePending = 0
    end
end
local function SbPityImport(state, missed, pending, current, present, hadSpin, won)
    if state then
        local s = state[0]
        s.missedWaves = missed or 0
        s.guaranteePending = pending or 0
        s.currentWave = current or 0
        s.currentWavePresent = present or 0
        s.currentWaveHadSpin = hadSpin or 0
        s.currentWaveWon = won or 0
    end
    return 1
end
local function SbPityNote(state, wave, won, excluded) return 0 end
local function SbPityFinish(state, wave) return 0 end
local function SbPityEligible(state, wave, excluded, alreadyForced) return 0 end
local function SbPityForce(state, futureSpins, roll) return 0 end

local fake_ffi = {}
for k, v in pairs(real_ffi) do fake_ffi[k] = v end
fake_ffi.C = {
    SbLuckAbi = SbLuckAbi,
    SbLuckChance = SbLuckChance,
    SbLuckChoose = SbLuckChoose,
    SbPityReset = SbPityReset,
    SbPityImport = SbPityImport,
    SbPityNote = SbPityNote,
    SbPityFinish = SbPityFinish,
    SbPityEligible = SbPityEligible,
    SbPityForce = SbPityForce,
}
package.loaded["ffi"] = fake_ffi

if jit then
    local _jit_on, _jit_off = jit.on, jit.off
    if _jit_on then
        jit.on = function(...) local ok = pcall(_jit_on, ...) return ok end
    end
    if _jit_off then
        jit.off = function(...) local ok = pcall(_jit_off, ...) return ok end
    end
end

local chunk = love.filesystem.load("real_main.luac")
-- 发行版完整性校验有两个钩子，这里一起关掉，才能替换游戏源码模块：
-- 1) real_main 启动时先校验 release_integrity.lua 的 hash（bootstrap）→ 覆盖原生 _verifyProtected 返回 true；
-- 2) release_integrity.verify() 会逐个校验资源文件 → 用空实现替换该模块（见 zip 内 src/release_integrity.lua）。
pcall(function() love.filesystem._verifyProtected = function() return true end end)
chunk()
package.loaded["ffi"] = real_ffi

------------------------------------------------------------------------
-- 手势层 v2
--
--   【定位】本层不改游戏逻辑，目标是把 iOS 触摸"基本还原成 PC 的鼠标交互"：
--     单击 = 左键点击      长按 0.38s = 右键（悬停 0.09s 后发）
--     长按拖 = 左键拖动    列表/升级树 = 滚轮
--     刻印吸收按钮长按 = 按住左键   双指/三指 = 原生手势（捏合 / 截图）
--
--   按下              → 静默，只记 (x0,y0), t0，不发任何事件
--   移动 > slop       → 按 phase 分派：拖兵(补发 press@x0,y0 + mousemoved 跟随)
--                                       / 升级树平移(dragPan) / 列表滚动(滚轮)
--   不动 > 380ms      → 长按：静默悬停（tooltip 出详细，不发 press）
--   松手(未动未长按)   → 单击：升级树/专职两段式(hover→click)，其余直接 click
--   双指              → 升级树捏合缩放 + 中点拖动平移；两指轻点 = 右键
--   三指轻点          → 截图；左边缘右滑 → ESC；顶部按钮 L/R、ESC 兜底
------------------------------------------------------------------------
local TAP_SLOP    = 14     -- 移动判定阈值（px）
local TWO_TAP_SLOP = 50    -- 两段式第二下匹配阈值（px）
local LONG_MS     = 0.38   -- 长按判定（秒）
local LONG_PIN_DELAY = 0.09 -- 长按触发后先悬停这么多秒再发右键：candidate 由 love.update 每帧算，同一帧发右键读到的是旧值
local WHEEL_STEP  = 40     -- 列表滚动每多少 px 折一格滚轮
local EDGE_W_FRAC = 0.05   -- 左边缘宽度（屏幕宽比例）
local EDGE_SWIPE_FRAC = 0.06
local EDGE_MAX_MS = 400
local SECTION_BAR_W = 90    -- 商店右侧 section 切换栏宽度（虚拟 px）：该区域单击切换界面，不走两段式

local game_mousepressed  = love.mousepressed
local game_mousereleased = love.mousereleased
local game_mousemoved    = love.mousemoved
local game_update        = love.update
local game_draw          = love.draw
local game_keypressed    = love.keypressed
local game_keyreleased   = love.keyreleased
local game_wheelmoved    = love.wheelmoved

local GEST_LOG, gest_lines = "gesture.log", 0
local function glog(s)
    if gest_lines > 3000 then return end
    gest_lines = gest_lines + 1
    pcall(love.filesystem.append, GEST_LOG, string.format("[%6.2f] %s\n", love.timer.getTime(), s))
end

local right_mode = false
local BW, BH = 124, 60
local MARGIN = 12
local LABEL_SCALE = 1.45

local function back_rect() return MARGIN, MARGIN, BW, BH end
local function button_rect()
    local w, h = love.graphics.getDimensions()
    return w - BW - MARGIN, MARGIN, BW, BH
end
local function hit(rx, ry, bw, bh, x, y)
    return x >= rx and x <= rx + bw and y >= ry and y <= ry + bh
end
local function on_back_button(x, y) local rx, ry, bw, bh = back_rect(); return hit(rx, ry, bw, bh, x, y) end
local function on_button(x, y) local rx, ry, bw, bh = button_rect(); return hit(rx, ry, bw, bh, x, y) end

local function press_esc()
    if game_keypressed then game_keypressed("escape", "escape", false) end
end
local function release_esc()
    if game_keyreleased then game_keyreleased("escape", "escape") end
end
local function fire_esc()
    glog("ESC (gesture)")
    press_esc(); release_esc()
end

local function draw_label_centered(text, bx, by, bw, bh, scale)
    local font = love.graphics.getFont()
    love.graphics.push()
    love.graphics.translate(bx + bw / 2, by + bh / 2)
    love.graphics.scale(scale or 1)
    love.graphics.print(text, -font:getWidth(text) / 2, -font:getHeight(text) / 2)
    love.graphics.pop()
end

local function draw_box(rx, ry, bw, bh, text, color)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(color[1], color[2], color[3], color[4])
    love.graphics.rectangle("fill", rx, ry, bw, bh, 8, 8)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rx, ry, bw, bh, 8, 8)
    love.graphics.setColor(1, 1, 1, 1)
    draw_label_centered(text, rx, ry, bw, bh, LABEL_SCALE)
    love.graphics.pop()
    love.graphics.setColor(r, g, b, a)
end

love.draw = function()
    -- iOS 无物理鼠标：关掉游戏自绘光标（cursor.png），否则拖动手势会留下箭头残影
    local ctl = rawget(_G, "Controller")
    if ctl then ctl.hideCursor = true end
    if game_draw then game_draw() end
    local bx, by, bw, bh = button_rect()
    draw_box(bx, by, bw, bh, right_mode and "R" or "L",
             right_mode and {0.85, 0.35, 0.1, 0.85} or {0.12, 0.12, 0.16, 0.65})
    local ex, ey, ew, eh = back_rect()
    draw_box(ex, ey, ew, eh, "ESC", {0.12, 0.12, 0.16, 0.65})
end

------------------------------------------------------------------------
-- 手势状态
------------------------------------------------------------------------
local touches = {}        -- id -> {x0,y0,x,y,t0,moved,dispatched,long,dead,ui,drag_kind,prev,wheel_acc}
local primary_id = nil
local order = {}          -- 按落下顺序的 id
local two = nil           -- {ids={a,b}, y0,d0,baseZoom,moved,t0,x,y,mx,my}
local last_tap = nil      -- 两段式：{x,y}（第一下悬停位置）

local function dist2(x1, y1, x2, y2) local dx, dy = x1 - x2, y1 - y2; return dx * dx + dy * dy end
local function now() return love.timer.getTime() end
local function ntouch() local n = 0; for _ in pairs(touches) do n = n + 1 end; return n end

local function upgrade_mod() return package.loaded["src.ui.upgrade"] end
local function to_virtual(x, y)
    local sc = rawget(_G, "screenScale") or 1
    local ox = rawget(_G, "screenOffsetX") or 0
    local oy = rawget(_G, "screenOffsetY") or 0
    return (x - ox) / sc, (y - oy) / sc
end
local function phase_now() return rawget(_G, "phase") end
local function in_class_select()
    local bf = rawget(_G, "battlefield")
    return bf and bf.classSelect and true or false
end
local function get_ui() return rawget(_G, "ui") end
local function in_shop()
    local u = get_ui()
    return u and u._shopMode == true or false
end

local function set_hover(x, y)
    if love.mouse and love.mouse.setPosition then pcall(love.mouse.setPosition, x, y) end
end
local function fire_left_press(x, y)
    set_hover(x, y)
    if game_mousepressed then game_mousepressed(x, y, 1, true, 1) end
end
local function fire_left_release(x, y)
    if game_mousereleased then game_mousereleased(x, y, 1, true, 1) end
end
-- 左键单击钉住士兵：点按抬起后延一帧再读 candidate（同一帧里 press+release 连发，
-- tooltip 的 candidate 还没算出来；长按有 0.09s 悬停等待所以不受影响）。
-- 拖拽松手不排队 → 不会钉住。
local pending_pin = false
local suppress_hover = false   -- 拖拽抬手后压住悬停面板，直到下一次触摸
local function queue_pin(x, y, tag)
    pending_pin = { x = x, y = y, tag = tag or "tap" }
end
local function flush_pin()
    local p = pending_pin
    if not p then return end
    pending_pin = false
    local u = get_ui()
    local tp = u and u.tooltip
    local bf = rawget(_G, "battlefield")
    if not (tp and bf and tp.pinHoveredUnit) then return end
    local ph = phase_now()
    if ph == "menu" or ph == "upgrade" or in_shop() or in_class_select() then return end
    local c = tp.candidate
    if c and c.ref and (c.kind == "roster" or c.kind == "ally" or c.kind == "enemy") then
        tp:pinHoveredUnit(bf)
        glog(string.format("%s pin -> %s @%.0f,%.0f absorb=%s", p.tag, tostring(c.kind), p.x, p.y, tostring(bf.absorbMode)))
    else
        glog(string.format("%s pin skip: kind=%s absorb=%s", p.tag, tostring(c and c.kind), tostring(bf.absorbMode)))
    end
end
local function fire_right_click(x, y)
    set_hover(x, y)
    if game_mousepressed then game_mousepressed(x, y, 2, true, 1) end
    -- v1.0.3 的 tooltip:mousepressed(2) 在 iOS 上也会走 _macRightPress 延迟分支并 return true，
    -- 而 mousereleased 里先 self._macRightPress = nil 再判空（上游写反）→ 永远钉不住，
    -- 同时把 real_main 后面的 stone.rerollAt 也挡掉了。这里替它把这两件事做掉。
    local u = get_ui()
    local tip = u and u.tooltip
    if tip then
        tip._macRightPress = nil
        -- v1.0.3 的 mousepressed(2) 会先被某个前置分支 return true（实测 pinHoveredUnit 根本没被调到），
        -- 所以这里不指望它：candidate 有 ref 就直接钉住。
        local c = tip.candidate
        if c and c.ref then
            pcall(tip.pinHoveredUnit, tip, rawget(_G, "battlefield"))
        end
        if u._stoneMode then
            local ok, st = pcall(require, "src.game.stone")
            if ok and st and st.rerollAt then
                local vx, vy = to_virtual(x, y)
                pcall(st.rerollAt, u, rawget(_G, "battlefield"), vx, vy)
                glog(string.format("right click -> stone.rerollAt %.0f,%.0f", vx, vy))
            end
        end
    end
    if game_mousereleased then game_mousereleased(x, y, 2, true, 1) end
end

local function results_like()
    -- 结算/战斗详细（DPS 明细）界面：整屏只能滚，不能拖兵
    local bf = rawget(_G, "battlefield")
    if bf and (bf.gameOver or (bf.victoryPending and bf.victoryPending.active)) then return true end
    local u = get_ui()
    return (u and u._dpsHoverTarget ~= nil) and true or false
end

-- 印记「长按吸收」按钮的命中区（模块在 package.loaded，不在 ui 下）
local function imprint_absorb_hit(x, y)
    -- 必须先确认刻印弹窗真的开着：imprint 模块的 _absorbAllRect 在弹窗关闭后
    -- 不会被清空（实测 bf.imprintModal=false 时 rect 仍是旧值），
    -- 不加这个判断，残留矩形会让长按在普通界面误触发。
    local bf = rawget(_G, "battlefield")
    local m = bf and bf.imprintModal
    if not (m and m.active) then return false end
    local imp = package.loaded["src.ui.imprint"]
    local r = imp and imp._absorbAllRect
    if type(r) ~= "table" then return false end
    local vx, vy = to_virtual(x, y)
    local w, h = r.w or 0, r.h or 0
    return vx >= r.x and vx <= r.x + w and vy >= r.y and vy <= r.y + h
end

local function drag_kind_for_phase(x, y)
    if results_like() then return "wheel" end
    local ph = phase_now()
    if ph == "upgrade" then return "tree" end
    if ph == "prep" or ph == "battle" or ph == "spin" then
        -- 手指没落在单位上 = 在拖列表/滚动条，按滚轮派发；落在单位上才是拖兵
        local u = get_ui()
        local c = u and u.tooltip and u.tooltip.candidate
        if c and c.ref then return "drag" end
        -- 印记「长按吸收」按钮：v1.3.5 靠"长按后滑动 -> 补发左键"启动游戏自己的
        -- holdTimer（imprint._absorbHold / holdTimer）；按矩形命中判定，不能当滚轮。
        if imprint_absorb_hit(x, y) then return "drag" end
        return "wheel"
    end
    return "wheel"
end

-- 移动超 slop：按 phase 分派
local function dispatch_drag(t)
    if t.dispatched then return end  -- 长按后移动仍可拖拽（吸收/拖兵）
    t.dispatched = true
    local kind = drag_kind_for_phase(t.x0, t.y0)
    t.drag_kind = kind
    if kind == "tree" then
        glog("drag -> tree pan")
    elseif kind == "drag" then
        fire_left_press(t.x0, t.y0)   -- 用按下坐标，drag.ox 才对，无跳变
        glog(string.format("drag -> press@%.0f,%.0f", t.x0, t.y0))
    else
        t.wheel_acc = 0
        glog("drag -> wheel scroll")
    end
end

-- 长按：先只悬停（tooltip 出详细），延迟几帧再发右键。
-- v1.0.3 起右键=钉住提示/核心重掷，游戏读的是上一帧算出的 tooltip.candidate；
-- 同一帧 set_hover + 右键会拿到旧位置（多半是 nil），必须错开一帧。
local function cand_desc()
    local u = get_ui()
    local c = u and u.tooltip and u.tooltip.candidate
    if not c then return "nil" end
    local r = c.ref
    return tostring(c.kind) .. "/" .. tostring(r and (r.id or r.name or r.key) or "?")
end

local function do_long_press(t)
    if t.long then return end
    t.long = true
    if imprint_absorb_hit(t.x0, t.y0) then
        -- 吸收按钮：长按 0.5 秒后补发左键（等价 PC 按住左键）。
        -- 游戏自己的 tooltip.update 每帧查 isDown(1) 续吸，抬手即停，
        -- 不需要补 release；本分支以外所有路径原样不动。
        fire_left_press(t.x0, t.y0)
        glog(string.format("long press on absorb button @%.0f,%.0f -> left press", t.x0, t.y0))
        return
    end
    t.pin_at = now() + LONG_PIN_DELAY
    set_hover(t.x, t.y)
    glog(string.format("long press -> hover @%.0f,%.0f (right click in %.2fs)", t.x, t.y, LONG_PIN_DELAY))
end

-- 开局前 SLOT 界面（flow.machine_select）的长按=右键。
-- 合成出来的 love.mousepressed(button=2) 到不了它的 mousepressed，
-- 只能直接调模块。
local function machine_select_right(vx, vy)
    -- 只在开局前的 SLOT 界面生效，战斗/商店绝不能接管长按
    if rawget(_G, "phase") ~= "menu" then return false end
    local bf = rawget(_G, "battlefield")
    if bf and bf.mode == "battle" then return false end
    local ok, F = pcall(require, "src.ui.flow")
    if not ok or type(F) ~= "table" then return false end
    local M = F.machine_select
    if type(M) ~= "table" or type(M.mousepressed) ~= "function" then return false end
    if type(M.isActive) == "function" then
        local a, act = pcall(M.isActive)
        if not a or not act then return false end
    end
    local c, ret = pcall(M.mousepressed, vx, vy, 2)
    return (c and ret) and true or false
end

local function fire_long_pin(t)
    t.pinned = true
    local ctl = rawget(_G, "Controller")
    local u = get_ui()
    glog(string.format("long pin -> right click @%.0f,%.0f candidate=%s locked=%s rcPin=%s stone=%s shop=%s",
        t.x, t.y, cand_desc(), tostring(u and u.tooltip and u.tooltip.locked),
        tostring(ctl and ctl.rightClickPin),
        tostring(u and u._stoneMode), tostring(u and u._shopMode)))
    local mvx, mvy = to_virtual(t.x0, t.y0)
    if machine_select_right(mvx, mvy) then
        glog(string.format("long pin -> machine_select right @%.0f,%.0f", mvx, mvy))
        return
    end
    fire_right_click(t.x, t.y)
    glog(string.format("long pin done: locked=%s state=%s target=%s",
        tostring(u and u.tooltip and u.tooltip.locked),
        tostring(u and u.tooltip and u.tooltip.state),
        tostring(u and u.tooltip and u.tooltip.target and u.tooltip.target.kind)))
end

-- 单击：升级树/专职/商店商品槽两段式；商店右侧 section 栏单击切换；其余直接 click
local function do_tap(x, y)
    local ph = phase_now()
    local two_step = ph == "upgrade" or in_class_select() or in_shop()
    if in_shop() then
        -- 商店：右侧 section 切换栏（战场/商店/石头/升级树）单击切换；
        -- 左上角返回键单击退出（与升级树一致）；其余（商品槽）走两段式购买。
        local vx, vy = to_virtual(x, y)
        local u = get_ui()
        local vw = u and u.virtual and u.virtual.W
        local in_section = vw and vx >= vw - SECTION_BAR_W
        local in_back = vx < 130 and vy < 130
        if in_section or in_back then
            two_step = false
            last_tap = nil
        end
        glog(string.format("shop tap vx=%.0f vy=%.0f vw=%s sec=%s back=%s two=%s",
            vx, vy, tostring(vw), tostring(in_section), tostring(in_back), tostring(two_step)))
    end
    if two_step then
        -- 升级树左上角返回键：单击立即退出，不走两段式
        if ph == "upgrade" then
            local vx, vy = to_virtual(x, y)
            if vx < 130 and vy < 130 then
                fire_left_press(x, y)
                fire_left_release(x, y)
                glog("tap -> upgrade back click")
                last_tap = nil
                return
            end
        end
        if last_tap and dist2(x, y, last_tap.x, last_tap.y) <= TWO_TAP_SLOP * TWO_TAP_SLOP then
            fire_left_press(x, y)
            fire_left_release(x, y)
            glog("tap2 -> confirm")
            last_tap = nil
        else
            set_hover(x, y)
            last_tap = { x = x, y = y }
            glog("tap1 -> hover")
        end
    else
        fire_left_press(x, y)
        fire_left_release(x, y)
        queue_pin(x, y, "tap")
        glog("tap -> click")
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    suppress_hover = false
    if on_back_button(x, y) then
        touches[id] = { ui = "esc" }
        press_esc()
        return
    end
    if on_button(x, y) then
        touches[id] = { ui = "mode" }
        right_mode = not right_mode
        glog("mode -> " .. (right_mode and "R" or "L"))
        return
    end

    touches[id] = { x0 = x, y0 = y, x = x, y = y, t0 = now(),
                    moved = false, dispatched = false, long = false }
    set_hover(x, y)   -- 按下即悬停：candidate 立刻对准手指下的对象（长按/右键都要它）
    order[#order + 1] = id
    if #order == 1 then primary_id = id end

    local n = ntouch()
    if n == 2 then
        local a, b = order[#order - 1], order[#order]
        local ta, tb = touches[a], touches[b]
        if ta and tb then
            -- 第一指：若已在拖拽中则放下，否则标记 dead（取消其单击/长按）
            if ta.dispatched and ta.drag_kind == "drag" then
                fire_left_release(ta.x, ta.y)
            end
            ta.dead = true
            local dx2, dy2 = ta.x - tb.x, ta.y - tb.y
            local u0 = upgrade_mod()
            two = { ids = { a, b }, y0 = (ta.y + tb.y) / 2,
                    d0 = math.max(20, math.sqrt(dx2 * dx2 + dy2 * dy2)),
                    baseZoom = (u0 and u0.getZoom and u0.getZoom()) or 1,
                    moved = 0, t0 = now(), x = ta.x0, y = ta.y0,
                    mx = (ta.x + tb.x) / 2, my = (ta.y + tb.y) / 2 }
            glog("two-finger down")
        end
    elseif n == 3 then
        if two then two = nil end
        pcall(love.graphics.captureScreenshot, "shot_auto.png")
        glog("screenshot -> shot_auto.png")
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    local t = touches[id]
    if not t then return end
    if t.ui then return end   -- ESC / L-R 按钮触摸没有 x0,y0，移动会炸 dist2
    t.x, t.y = x, y
    if not t.moved and dist2(x, y, t.x0, t.y0) > TAP_SLOP * TAP_SLOP then t.moved = true end

    local w, h = love.graphics.getDimensions()

    if ntouch() == 1 then
        set_hover(x, y)   -- 悬停跟手：tooltip / hover 才有反应

        if t.moved and not t.dispatched then
            dispatch_drag(t)
        end

        if t.dispatched then
            if t.drag_kind == "tree" then
                if t.prev then
                    local u = upgrade_mod()
                    if u and u.dragPan then
                        local sc = rawget(_G, "screenScale") or 1
                        u.dragPan((x - t.prev.x) / sc, (y - t.prev.y) / sc)
                    end
                end
                t.prev = { x = x, y = y }
            elseif t.drag_kind == "drag" then
                if game_mousemoved then game_mousemoved(x, y, dx, dy) end
            else
                t.wheel_acc = (t.wheel_acc or 0) + dy
                while math.abs(t.wheel_acc) >= WHEEL_STEP do
                    local dir = t.wheel_acc > 0 and 1 or -1
                    t.wheel_acc = t.wheel_acc - dir * WHEEL_STEP
                    set_hover(x, y)
                    if game_wheelmoved then game_wheelmoved(0, dir) end
                    glog("wheel scroll " .. dir)
                end
            end
        end

        -- 左边缘右滑 = ESC
        if t.x0 < w * EDGE_W_FRAC then
            local dt = (now() - t.t0) * 1000
            if (x - t.x0) > w * EDGE_SWIPE_FRAC and math.abs(y - t.y0) < h * 0.1 and dt < EDGE_MAX_MS then
                t.dead = true
                touches[id] = nil
                fire_esc()
                return
            end
        end
    end

    -- 双指：捏合缩放 + 中点拖动平移（仅升级树）
    if two and two.ids[1] and two.ids[2] then
        local a, b = touches[two.ids[1]], touches[two.ids[2]]
        if a and b then
            local ddx, ddy = a.x - b.x, a.y - b.y
            local d = math.max(20, math.sqrt(ddx * ddx + ddy * ddy))
            local mx, my = (a.x + b.x) / 2, (a.y + b.y) / 2
            local u = upgrade_mod()
            if phase_now() == "upgrade" and u then
                if math.abs(d - two.d0) > 3 then
                    two.moved = two.moved + 1
                    if u.pinchZoom then
                        local ratio = d / two.d0
                        local scale = (two.baseZoom or 1) * ratio
                        local vx, vy = to_virtual(mx, my)
                        u.pinchZoom(vx, vy, scale)
                        glog(string.format("pinch r=%.3f scale=%.3f mid=%.0f,%.0f", ratio, scale, mx, my))
                    end
                end
                if two.mx and two.my and u.dragPan then
                    local sc = rawget(_G, "screenScale") or 1
                    local dpx, dpy = (mx - two.mx) / sc, (my - two.my) / sc
                    if math.abs(dpx) > 1 or math.abs(dpy) > 1 then
                        two.moved = two.moved + 1
                        u.dragPan(dpx, dpy)
                        glog(string.format("2pan dx=%.1f dy=%.1f", dpx, dpy))
                    end
                end
            end
            two.mx, two.my = mx, my
        end
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    local t = touches[id]
    touches[id] = nil
    for i = #order, 1, -1 do if order[i] == id then table.remove(order, i) end end
    if primary_id == id then primary_id = order[1] end
    if not t then return end

    if t.ui == "esc" then release_esc(); return end
    if t.ui == "mode" then return end

    if two and (id == two.ids[1] or id == two.ids[2]) then
        local a, b = touches[two.ids[1]], touches[two.ids[2]]
        if not a and not b then          -- 两指都抬起
            local held = (now() - two.t0) * 1000
            local wx, wy = two.x, two.y
            local moved = two.moved
            two = nil
            if moved == 0 and held < 300 then
                fire_right_click(wx, wy)
                glog("two-finger tap -> right click")
                return
            end
        end
        return
    end

    if t.dead then return end

    if t.dispatched then
        if t.drag_kind == "drag" then
            fire_left_release(x, y)
            suppress_hover = true
            glog("drag end -> release (hover suppressed)")
        end
        return
    end

    if t.long then
        -- 长按结束（已悬停看详细）
        return
    end

    if t.moved then return end   -- 兜底：移动过但未分派

    -- 纯单击
    if right_mode then
        fire_right_click(x, y)
        glog("right-mode tap -> right click")
    else
        do_tap(x, y)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if not istouch then
        if on_back_button(x, y) then press_esc(); return end
        if on_button(x, y) then right_mode = not right_mode; return end
    end
    if istouch then return end   -- 引擎自动 touch→mouse 事件全吞，判定在 love.touch* 里做
    if game_mousepressed then game_mousepressed(x, y, button, istouch, presses) end
end

function love.mousereleased(x, y, button, istouch, presses)
    if not istouch then
        if on_back_button(x, y) then release_esc(); return end
        if on_button(x, y) then return end
    end
    if istouch then return end
    if game_mousereleased then game_mousereleased(x, y, button, istouch, presses) end
end

function love.wheelmoved(x, y)
    if game_wheelmoved then game_wheelmoved(x, y) end
end

local auto_shot = false
function love.update(dt)
    if game_update then game_update(dt) end
    flush_pin()
    if suppress_hover then
        local sp = get_ui()
        local stp = sp and sp.tooltip
        if stp and not stp.locked then
            stp.candidate = nil
            stp.target = nil
            stp.state = "IDLE"
            stp.fade = 0
            stp.hoverT = 0
        end
    end
    local t = now()
    if not auto_shot and t > 4 then
        auto_shot = true
        pcall(love.graphics.captureScreenshot, "shot_boot.png")
        glog("boot screenshot -> shot_boot.png")
    end

    -- 长按判定（单指、未移动、未长按）
    if ntouch() == 1 then
        local id, tt = next(touches)
        if tt and not tt.ui and not tt.dead then
            if tt.long then
                set_hover(tt.x, tt.y)
                if not tt.pinned and tt.pin_at and t >= tt.pin_at then
                    fire_long_pin(tt)
                end
            elseif not tt.moved and (t - tt.t0) >= LONG_MS then
                do_long_press(tt)
            end
        end
    end
end

-- 训练器后端（纯 Lua，读取 cheats_ui.lua）
pcall(function() require("trainer_backend") end)
-- ==== 设置页注入：导出/恢复存档 + 滚动补偿 ====
-- 原生设置列表里插入「导出存档 / 恢复存档」
-- 原理：__slotSettingsLayout 是全局函数，每帧先拿到整张 items 表再算布局；
-- 在它里面把 resetSaveData 挪到末尾、前面插两行 button，之后游戏自己的
-- 绘制/布局/滚动条/字体适配全部照常工作（就是原生行）。
local S = {}
_G.__sbSaveRows = S
if S.installed or S.installing then return S end

local ROWH = 26

local function dir()
  local ok, d = pcall(function() return love.filesystem.getSaveDirectory() end)
  return ok and d or "."
end

local function log(...)
  local args = { ... }
  local ok, line = pcall(function() return table.concat(args, " ") end)
  if not ok then return end
  local p = dir() .. "/sblog2.txt"
  local prev = ""
  local f = io.open(p, "rb")
  if f then prev = f:read("*a") or ""; f:close() end
  if #prev > 3000 then prev = prev:sub(-3000) end
  local h = io.open(p, "wb")
  if h then h:write(prev .. os.date("%H:%M:%S ") .. line .. "\n"); h:close() end
end

local ffi_ok, ffi = pcall(require, "ffi")
if ffi_ok then
  pcall(ffi.cdef, [[
    typedef struct objc_object { void *isa; } *sb_id;
    typedef struct objc_selector *sb_sel;
    sb_id objc_getClass(const char *name);
    sb_sel sel_registerName(const char *name);
    sb_id objc_msgSend(sb_id self, sb_sel op, ...);
  ]])
end

local function call_panel(selname)
  if not ffi_ok then log("ffi missing") return false end
  local ok, r = pcall(function()
    local cls = ffi.C.objc_getClass("CheatsOverlay")
    if cls == nil then return false end
    local s = ffi.C.sel_registerName(selname)
    if s == nil then return false end
    ffi.C.objc_msgSend(cls, s, nil)
    return true
  end)
  log("call", selname, tostring(ok), tostring(r))
  return ok and r == true
end

local function labels()
  local l = (ui and ui.menuSettings and ui.menuSettings.language) or "en"
  if l == "zh" or l == "cn" or l == "zh_cn" or l == "chinese" then
    return "导出存档", "恢复存档"
  elseif l == "ko" then
    return "저장 내보내기", "저장 불러오기"
  elseif l == "ja" then
    return "セーブ書き出し", "セーブ読み込み"
  end
  return "Export Save", "Import Save"
end

local function act_export() if not call_panel("exportSave:") then log("export unreachable") end end
local function act_import() if not call_panel("importSave:") then log("import unreachable") end end

local function make_rows()
  local lex, limp = labels()
  return {
    { kind = "button", key = "sbExportSave", label = lex, tone = "normal", disabled = false, set = act_export },
    { kind = "button", key = "sbImportSave", label = limp, tone = "normal", disabled = false, set = act_import },
  }
end

local function is_target(items)
  if type(items) ~= "table" then return false end
  local n = #items
  if n < 8 then return false end
  local last = items[n]
  if type(last) ~= "table" or last.key ~= "resetSaveData" then return false end
  -- 战斗内暂停页的列表同一张表、但重置存档是 disabled（游戏自己传 "pause" 建的）；
  -- 那种页面保持原样：只有一个不可点的「重置存档」。
  if last.disabled == true then return false end
  return true
end

-- 让 settingsScrollMax 对外多报 52（两行），内部仍存原值；
-- 这样游戏每帧重算的 clamp、滚动条几何、拖动全部自动跟上。
local function hook_state(st)
  if type(st) ~= "table" or st.__sbHooked then return end
  local raw = st.settingsScrollMax or 0
  rawset(st, "settingsScrollMax", nil)
  local mt = {
    __index = function(t, k)
      if k == "settingsScrollMax" then
        if rawget(t, "page") == nil then return raw + ROWH * 2 end
        return raw
      end
      return rawget(t, k)
    end,
    __newindex = function(t, k, v)
      if k == "settingsScrollMax" then raw = v else rawset(t, k, v) end
    end,
  }
  setmetatable(st, mt)
  rawset(st, "__sbHooked", true)
  log("state hooked raw=" .. tostring(raw))
end

local function to_virtual(x, y)
  if toVirtual then
    local ok, a, b = pcall(toVirtual, x, y)
    if ok and a then return a, b end
  end
  local sc = screenScale or 1
  return (x - (screenOffsetX or 0)) / sc, (y - (screenOffsetY or 0)) / sc
end

function S.install()
  if S.installed then return true end
  if type(__slotSettingsLayout) ~= "function" then return false end

  local prev_layout = __slotSettingsLayout
  __slotSettingsLayout = function(items, x, w)
    S.injected = false
    if is_target(items) and not items.__sbDone then
      local ok = pcall(function()
        items.__sbDone = true
        S.injected = true
        local reset = table.remove(items)
        local rows = make_rows()
        items[#items + 1] = rows[1]
        items[#items + 1] = rows[2]
        items[#items + 1] = reset
        S.items = items
        local t = os.time()
        if S.lastlog ~= t then
          S.lastlog = t
          local st = ui and ui.menuSettingsOverlayState
          log("inject n=" .. #items .. " x=" .. tostring(math.floor(x)) .. " w=" .. tostring(math.floor(w)) ..
              " sy=" .. tostring(math.floor((st and st.settingsScrollY) or 0)) ..
              " max=" .. tostring(math.floor((st and st.settingsScrollMax) or 0)))
        end
      end)
      if not ok then log("inject failed") end
    end
    return prev_layout(items, x, w)
  end

  if type(updateMenuSettingsOverlay) == "function" then
    local prev_update = updateMenuSettingsOverlay
    updateMenuSettingsOverlay = function(dt)
      prev_update(dt)
      if ui then
        hook_state(ui.menuSettingsOverlayState)
      end
    end
  else
    log("update missing")
  end

  if type(menuSettingsOverlayMousepressed) == "function" then
    local prev_press = menuSettingsOverlayMousepressed
    menuSettingsOverlayMousepressed = function(x, y, btn)
      local ok, handled = pcall(function()
        if not S.injected then return false end
        if type(__slotPadSettingsView) ~= "function" or not ui then return false end
        local v = __slotPadSettingsView()
        if not v or not v.st or v.st.open ~= true or v.st.page ~= nil then return false end
        local vx, vy = x, y
        local W = (ui.virtual and ui.virtual.W) or 640
        local H = (ui.virtual and ui.virtual.H) or 360
        if x > W + 1 or y > H + 1 then vx, vy = to_virtual(x, y) end
        if vx < v.cx or vx > v.cx + v.cw - 20 then return false end
        if vy < v.cy or vy > v.cy + v.ch then return false end
        local idx = math.floor((vy - v.cy + (v.scrollY or 0)) / ROWH) + 1
        local row = type(S.items) == "table" and S.items[idx] or nil
        if type(row) ~= "table" then return false end
        if idx >= 9 then log("press idx=" .. idx .. " key=" .. tostring(row.key) .. " vy=" .. tostring(math.floor(vy))) end
        if row.key == "sbExportSave" then act_export() return true end
        if row.key == "sbImportSave" then act_import() return true end
        if row.key == "resetSaveData" then
          -- 直接走这一行自己的回调（内部是 openConfirm("resetsave")），
          -- 不再用「上移两行再模拟点击」——新版底座里那样会落到导出存档那一行。
          if row.disabled ~= true and type(row.set) == "function" then pcall(row.set) end
          return true
        end
        return false
      end)
      if ok and handled == true then return true end
      if not ok then log("press err " .. tostring(handled)) end
      return prev_press(x, y, btn)
    end
  else
    log("press missing")
  end

  S.installed = true
  log("installed v2")
  return true
end

if not S.install() then
  log("deferred")
  local tick = love.update
  love.update = function(dt)
    if tick then tick(dt) end
    if not S.installed then S.install() end
  end
end

return S
