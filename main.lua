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
--   按下              → 静默，只记 (x0,y0), t0，不发任何事件
--   移动 > slop       → 按 phase 分派：拖兵(补发 press@x0,y0 + mousemoved 跟随)
--                                       / 升级树平移(dragPan) / 列表滚动(滚轮)
--   不动 > 500ms      → 长按：静默悬停（tooltip 出详细，不发 press）
--   松手(未动未长按)   → 单击：升级树/专职两段式(hover→click)，其余直接 click
--   双指              → 升级树捏合缩放 + 中点拖动平移；两指轻点 = 右键
--   三指轻点          → 截图；左边缘右滑 → ESC；顶部按钮 L/R、ESC 兜底
------------------------------------------------------------------------
local TAP_SLOP    = 14     -- 移动判定阈值（px）
local TWO_TAP_SLOP = 50    -- 两段式第二下匹配阈值（px）
local LONG_MS     = 0.5    -- 长按判定（秒）
local WHEEL_STEP  = 40     -- 列表滚动每多少 px 折一格滚轮
local EDGE_W_FRAC = 0.05   -- 左边缘宽度（屏幕宽比例）
local EDGE_SWIPE_FRAC = 0.06
local EDGE_MAX_MS = 400

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
local function fire_right_click(x, y)
    set_hover(x, y)
    if game_mousepressed then game_mousepressed(x, y, 2, true, 1) end
    if game_mousereleased then game_mousereleased(x, y, 2, true, 1) end
end

local function drag_kind_for_phase()
    local ph = phase_now()
    if ph == "upgrade" then return "tree" end
    if ph == "prep" or ph == "battle" or ph == "spin" then return "drag" end
    return "wheel"
end

-- 移动超 slop：按 phase 分派
local function dispatch_drag(t)
    if t.dispatched or t.long then return end
    t.dispatched = true
    local kind = drag_kind_for_phase()
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

-- 长按：静默悬停（tooltip 出详细）。道具「使用」事件待定位，先统一悬停。
local function do_long_press(t)
    if t.long then return end
    t.long = true
    set_hover(t.x, t.y)
    -- 长按 = 右键（上下文操作）+ 持续悬停（tooltip 看详细）
    fire_right_click(t.x, t.y)
    glog(string.format("long press -> right click + hover @%.0f,%.0f", t.x, t.y))
end

-- 单击：升级树/专职两段式，其余直接 click
local function do_tap(x, y)
    local ph = phase_now()
    local two_step = ph == "upgrade" or in_class_select() or in_shop()
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
        glog("tap -> click")
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
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
                t.wheel_acc = (t.wheel_acc or 0) - dy
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
            glog("drag end -> release")
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
            elseif not tt.moved and (t - tt.t0) >= LONG_MS then
                do_long_press(tt)
            end
        end
    end
end

-- 训练器后端（纯 Lua，读取 cheats_ui.lua）
pcall(function() require("trainer_backend") end)
