-- trainer.lua -- Slotbound iOS trainer (pure Lua, no dylib needed)
--
-- Injection model: this file is packaged into game.love and required at the
-- end of main.lua. If it is absent (or main.lua does not require it) the game
-- runs completely untouched -- no code is left behind in the binary.
--
-- Everything happens at the Lua level, which is what makes it portable to iOS:
--   * globals (coins / spinsLeft / jungsu) are pinned AFTER the game's update
--   * slot:buildResultGrid is wrapped (the result is decided at lever pull)
--   * roster units are edited through the same tables the game reads
--   * skill cooldown is wrapped on __slotGetSkillCooldownMul
--
-- ASCII labels only: LÖVE's default font has no CJK glyphs.

local T = {}

----------------------------------------------------------------------
-- state
----------------------------------------------------------------------
local SAVE = "slotbound_trainer.txt"
local CMD = "trainer_cmd.txt"
local LOG = "trainer_log.txt"

T.values = { coins = 999999, spins = 999, essence = 999 }

T.state = {
    panel = false,
    page = 1,
    coins = true,
    spins = true,
    essence = true,
    jackpot = false,
}

T.jackpotSymbol = "A"

----------------------------------------------------------------------
-- persistence
----------------------------------------------------------------------
local function saveState()
    local out = {}
    for k, v in pairs(T.state) do
        if type(v) == "boolean" then out[#out + 1] = k .. "=" .. tostring(v) end
    end
    out[#out + 1] = "sy=" .. tostring(T.jackpotSymbol)
    pcall(function() love.filesystem.write(SAVE, table.concat(out, "\n")) end)
end

local function loadState()
    local ok, data = pcall(function() return love.filesystem.read(SAVE) end)
    if not ok or type(data) ~= "string" then return end
    for line in data:gmatch("[^\r\n]+") do
        local k, v = line:match("^([%w_]+)=(.*)$")
        if k == "sy" then
            T.jackpotSymbol = v
        elseif k and T.state[k] ~= nil then
            T.state[k] = (v == "true")
        end
    end
end

----------------------------------------------------------------------
-- core: pinned globals
----------------------------------------------------------------------
local function isnum(v) return type(v) == "number" end

local function pinGlobals()
    local Gv = _G
    if T.state.coins then
        if isnum(Gv.coins) then Gv.coins = T.values.coins end
        if isnum(Gv.displayCoins) then Gv.displayCoins = T.values.coins end
    end
    if T.state.spins then
        if isnum(Gv.spinsLeft) then Gv.spinsLeft = T.values.spins end
    end
    if T.state.essence then
        if isnum(Gv.jungsu) then Gv.jungsu = T.values.essence end
        if isnum(Gv.jungsuBalanceTarget) then Gv.jungsuBalanceTarget = T.values.essence end
        if isnum(Gv.displayJungsu) then Gv.displayJungsu = T.values.essence end
    end
end

----------------------------------------------------------------------
-- slot jackpot
----------------------------------------------------------------------
local function jackpotGrid()
    local s = T.jackpotSymbol or "A"
    return { { s, s, s }, { s, s, s }, { s, s, s } }
end

local function hookSlot()
    local s = rawget(_G, "slot")
    if type(s) ~= "table" or s.__sbTrainerHooked then return end

    local orig = s.buildResultGrid
    if type(orig) ~= "function" then
        local mt = getmetatable(s)
        local idx = mt and mt.__index
        if type(idx) == "table" and type(idx.buildResultGrid) == "function" then
            orig = idx.buildResultGrid
        end
    end
    if type(orig) ~= "function" then return end

    s.buildResultGrid = function(self, ...)
        if T.state.jackpot then
            T._jpCalls = (T._jpCalls or 0) + 1
            local s1 = T.jackpotSymbol or "A"
            T._lastGrid = s1 .. s1 .. s1 .. "/" .. s1 .. s1 .. s1 .. "/" .. s1 .. s1 .. s1
            return jackpotGrid()
        end
        return orig(self, ...)
    end
    s.__sbTrainerHooked = true
end

----------------------------------------------------------------------
-- roster helpers
----------------------------------------------------------------------
local function roster()
    local bf = rawget(_G, "battlefield")
    local list = bf and bf.rosterUnits
    if type(list) ~= "table" then return nil end
    return list
end

local function eachUnit(fn)
    local list = roster()
    if not list then return 0 end
    local idx = tonumber(T.target) or 0
    if idx > 0 then
        local u = list[idx]
        if type(u) == "table" then
            if pcall(fn, u) then return 1 end
        end
        return 0
    end
    local n = 0
    for _, u in ipairs(list) do
        if type(u) == "table" then
            local ok = pcall(fn, u)
            if ok then n = n + 1 end
        end
    end
    return n
end

----------------------------------------------------------------------
-- feature: unit stats
----------------------------------------------------------------------
local function applyStatMul(mul)
    mul = tonumber(mul) or 5
    return eachUnit(function(u)
        local st = u.stats
        if type(st) ~= "table" then return end
        for _, k in ipairs({ "hp", "atk", "aspd" }) do
            if type(st[k]) == "number" then st[k] = st[k] * mul end
        end
        local a = u.allyRef
        if type(a) == "table" then
            for _, k in ipairs({ "maxhp", "hp", "dmg" }) do
                if type(a[k]) == "number" then a[k] = a[k] * mul end
            end
            if type(a.atkPeriod) == "number" then a.atkPeriod = a.atkPeriod / mul end
        end
    end)
end

----------------------------------------------------------------------
-- feature: imprints (刻印)
----------------------------------------------------------------------
local function imprintInstance(def, level)
    local levels = def.levels or {}
    level = math.max(1, math.min(level or 1, #levels > 0 and #levels or 1))
    local lv = levels[level] or {}
    local inst = {}
    for k, v in pairs(def) do inst[k] = v end
    inst.level = level
    inst.maxLevel = #levels > 0 and #levels or 5
    inst.stats = lv.stats
    inst.desc = lv.desc
    inst.shortDesc = lv.shortDesc
    return inst
end

local function addAllImprints(level)
    local ok, consts = pcall(require, "src.data.constants")
    if not ok or type(consts) ~= "table" then return 0 end
    local defs = consts.imprint and consts.imprint.definitions
    if type(defs) ~= "table" then return 0 end
    local added = 0
    eachUnit(function(u)
        u.imprints = u.imprints or {}
        if type(u.maxImprintSlots) == "number" then
            u.maxImprintSlots = math.max(u.maxImprintSlots, 99)
        end
        for id, def in pairs(defs) do
            if type(def) == "table" then
                local targetId = def.id or id
                local have = false
                for _, e in ipairs(u.imprints) do
                    if type(e) == "table" and e.id == targetId then have = true break end
                end
                if not have then
                    u.imprints[#u.imprints + 1] = imprintInstance(def, level)
                    added = added + 1
                end
            end
        end
    end)
    return added
end

----------------------------------------------------------------------
-- feature: random options (词条)
----------------------------------------------------------------------
local function instanceFromDef(def)
    local inst = {
        id = def.id, name = def.name, effect = def.effect,
        icon = def.icon, rarity = def.rarity, source = def.source,
        variant = {},
    }
    local vs = def.variants or {}
    if #vs > 0 then
        local total = 0
        for _, v in ipairs(vs) do total = total + (tonumber(v.chance) or 0) end
        local roll = math.random() * (total > 0 and total or 1)
        local acc = 0
        for _, v in ipairs(vs) do
            acc = acc + (tonumber(v.chance) or 0)
            if roll <= acc then inst.variant = { value = v.value } break end
        end
        if not inst.variant.value then inst.variant = { value = vs[1].value } end
    end
    return inst
end

local function addAllOptions()
    local ok, RO = pcall(require, "src.data.randomoption")
    if not ok or type(RO) ~= "table" then return 0 end
    local catalog = RO.catalog
    if type(catalog) ~= "table" then return 0 end
    local added = 0
    eachUnit(function(u)
        u.randomOptions = u.randomOptions or {}
        for _, def in pairs(catalog) do
            if type(def) == "table" and def.id then
                local have = false
                for _, e in ipairs(u.randomOptions) do
                    if type(e) == "table" and e.id == def.id then have = true break end
                end
                if not have then
                    u.randomOptions[#u.randomOptions + 1] = instanceFromDef(def)
                    added = added + 1
                end
            end
        end
    end)
    return added
end

----------------------------------------------------------------------
-- feature: awakening (觉醒)
----------------------------------------------------------------------
local function fillAwakening(n)
    n = tonumber(n) or 3
    local ok, A = pcall(require, "src.game.awakening")
    if not ok or type(A) ~= "table" then return 0 end
    local count = 0
    eachUnit(function(u)
        local pool = nil
        if type(A.pool) == "function" then
            local ok2, p = pcall(A.pool, u)
            if ok2 then pool = p end
        end
        if type(pool) ~= "table" and type(A.catalog) == "function" then
            local ok3, cat = pcall(A.catalog, u)
            if ok3 and type(cat) == "table" then pool = cat.candidates end
        end
        if type(pool) == "table" then
            local aw = u.awakening or { version = 10, selected = {} }
            aw.selected = aw.selected or {}
            aw.version = aw.version or 10
            local added = 0
            for _, c in ipairs(pool) do
                local id = type(c) == "table" and (c.id or c.unitId) or c
                if id ~= nil then
                    local dup = false
                    for _, s in ipairs(aw.selected) do if s == id then dup = true break end end
                    if not dup then
                        aw.selected[#aw.selected + 1] = id
                        added = added + 1
                        if added >= n then break end
                    end
                end
            end
            u.awakening = aw
            if type(A.normalize) == "function" then pcall(A.normalize, u) end
            count = count + 1
        end
    end)
    return count
end

----------------------------------------------------------------------
-- feature: items (商店背包)
----------------------------------------------------------------------
local function addAllItems(level)
    local ok, mod = pcall(require, "src.game.item")
    if not ok or type(mod) ~= "table" then return 0 end
    local ui = rawget(_G, "ui")
    if type(ui) ~= "table" then return 0 end
    ui._itemPurchased = ui._itemPurchased or {}
    ui._itemPurchasedKeys = ui._itemPurchasedKeys or {}
    local list, keys = ui._itemPurchased, ui._itemPurchasedKeys
    local all = type(mod.getAll) == "function" and mod.getAll() or {}
    local added = 0
    local nextId = tonumber(ui._itemPanelNextId) or 11
    for _, def in ipairs(all) do
        if type(def) == "table" and def.id then
            local found = nil
            for i, e in ipairs(list) do
                if type(e) == "table" and e.id == def.id then found = i break end
            end
            if found then
                local maxlv = tonumber(def.maxLevel) or 1
                list[found].level = math.min(maxlv, math.max(tonumber(level) or 1, tonumber(list[found].level) or 1))
            else
                local inst = {}
                for k, v in pairs(def) do inst[k] = v end
                inst.level = math.min(tonumber(def.maxLevel) or 1, tonumber(level) or 1)
                if type(inst.updateEffectString) == "function" then pcall(inst.updateEffectString, inst) end
                list[#list + 1] = inst
                keys[#keys + 1] = "p" .. nextId
                nextId = nextId + 1
                added = added + 1
            end
        end
    end
    ui._itemPanelNextId = nextId
    return added
end

----------------------------------------------------------------------
-- feature: unit rank / absorb level
----------------------------------------------------------------------
local function raiseAllRanks()
    local f = rawget(_G, "__slotStoneRaiseRank")
    if type(f) ~= "function" then return 0 end
    return eachUnit(function(u) pcall(f, u, 3) end)
end

local function setAllAwakenLevel(lv)
    local f = rawget(_G, "__slotSetAwakeningLevel")
    if type(f) ~= "function" then return 0 end
    lv = tonumber(lv) or 100
    return eachUnit(function(u) pcall(f, u, lv) end)
end

----------------------------------------------------------------------
-- feature: skill cooldown
----------------------------------------------------------------------
local function applyCdMul(mul)
    mul = tonumber(mul) or 0.1
    local f = rawget(_G, "__slotGetSkillCooldownMul")
    if type(f) ~= "function" then return 0 end
    if not rawget(_G, "__sbCdWrapped") then
        _G.__sbCdOrig = f
        _G.__slotGetSkillCooldownMul = function(u)
            local v = _G.__sbCdOrig(u)
            if type(v) == "number" then return v * (rawget(_G, "__sbCdMul") or 1) end
            return v
        end
        _G.__sbCdWrapped = true
    end
    _G.__sbCdMul = mul
    return 1
end

----------------------------------------------------------------------
-- remote commands (trainer_cmd.txt), polled once per second
--   coins=1 / spins=0 / essence=1 / jackpot=1 / sy=H
--   act=statmul:5 | imprints:5 | options | awaken:3 | items:1
--   act=rank | lv:100 | cd:0.1
----------------------------------------------------------------------
T.lastAction = "-"

local function runAction(cmd)
    local name, arg = cmd:match("^(%a+):?(.*)$")
    if not name then return end
    local n
    if name == "statmul" then n = applyStatMul(arg)
    elseif name == "imprints" then n = addAllImprints(tonumber(arg) or 5)
    elseif name == "options" then n = addAllOptions()
    elseif name == "awaken" then n = fillAwakening(arg)
    elseif name == "items" then n = addAllItems(tonumber(arg) or 1)
    elseif name == "rank" then n = raiseAllRanks()
    elseif name == "lv" then n = setAllAwakenLevel(arg)
    elseif name == "cd" then n = applyCdMul(arg)
    elseif name == "target" then
        local list = roster()
        local cnt = list and #list or 0
        T.target = ((tonumber(T.target) or 0) + 1) % (cnt + 1)
        n = T.target
    else n = "?" end
    T.lastAction = name .. ":" .. tostring(arg or "") .. " -> " .. tostring(n)
end

local lastCmdData = nil

local function pollRemote()
    local ok, data = pcall(function() return love.filesystem.read(CMD) end)
    if not ok then return end
    if type(data) ~= "string" then return end
    -- Apply the command file only when its content CHANGES. Re-applying every
    -- tick would fight the panel: a switch you turn off by hand would be
    -- turned back on one second later by a stale `coins=1` line.
    if data == lastCmdData then return end
    lastCmdData = data
    for line in data:gmatch("[^\r\n]+") do
        local k, v = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
        if k == "act" then
            runAction(v)
        elseif k == "sy" then
            T.jackpotSymbol = v
        elseif k and T.state[k] ~= nil and k ~= "panel" and k ~= "page" then
            T.state[k] = (v ~= "0")
        end
    end
    saveState()
end

----------------------------------------------------------------------
-- debug log
----------------------------------------------------------------------
local function logState()
    pcall(function()
        local list = roster()
        local u1 = list and list[1] or nil
        local lines = {
            "time=" .. string.format("%.1f", love.timer.getTime()),
            "coins=" .. tostring(_G.coins) .. " display=" .. tostring(_G.displayCoins),
            "spinsLeft=" .. tostring(_G.spinsLeft),
            "jungsu=" .. tostring(_G.jungsu) .. " display=" .. tostring(_G.displayJungsu),
            "slot=" .. tostring(rawget(_G, "slot") ~= nil) .. " hooked=" .. tostring(rawget(_G, "slot") and _G.slot.__sbTrainerHooked or false),
            "roster=" .. tostring(list and #list or 0),
            "jackpotCalls=" .. tostring(T._jpCalls or 0) .. " lastGrid=" .. tostring(T._lastGrid or "-"),
            "lastAction=" .. T.lastAction,
            "target=" .. tostring(T.target or 0),
            "sw=" .. tostring(T.state.coins) .. "/" .. tostring(T.state.spins) .. "/" .. tostring(T.state.essence) .. "/" .. tostring(T.state.jackpot),
        }
        if list then
            local names = {}
            for i, u in ipairs(list) do
                if type(u) == "table" then
                    names[#names + 1] = i .. ":" .. tostring(u.id or u.unitId or "?")
                end
            end
            lines[#lines + 1] = "units=" .. table.concat(names, " ")
        end
        if u1 then
            local st = type(u1.stats) == "table" and u1.stats or {}
            lines[#lines + 1] = string.format("unit1=%s rank=%s lv=%s hp=%s atk=%s aspd=%s imp=%d opt=%d aw=%d",
                tostring(u1.id or "?"), tostring(u1.rank), tostring(u1.absorbLV),
                tostring(st.hp), tostring(st.atk), tostring(st.aspd),
                type(u1.imprints) == "table" and #u1.imprints or 0,
                type(u1.randomOptions) == "table" and #u1.randomOptions or 0,
                (type(u1.awakening) == "table" and type(u1.awakening.selected) == "table") and #u1.awakening.selected or 0)
        end
        love.filesystem.write(LOG, table.concat(lines, "\n"))
    end)
end

----------------------------------------------------------------------
-- ui
----------------------------------------------------------------------
local PAGES = { "主面板", "单位", "商店" }

local ROWS = {
    { page = 1, key = "coins",   label = "金币 999999" },
    { page = 1, key = "spins",   label = "旋转次数 999" },
    { page = 1, key = "essence", label = "水晶 999" },
    { page = 1, key = "jackpot", label = "老虎机大奖 全A" },
}

local ACTIONS = {
    { page = 2, act = "target",           label = "目标: 全部单位" },
    { page = 2, label = "属性 x5",         act = "statmul:5" },
    { page = 2, label = "刻印 全满级",      act = "imprints:5" },
    { page = 2, label = "词条 全给",        act = "options" },
    { page = 2, label = "觉醒 x3",          act = "awaken:3" },
    { page = 2, label = "升星到 3",         act = "rank" },
    { page = 2, label = "吸收 LV100",       act = "lv:100" },
    { page = 2, label = "技能冷却 x0.1",    act = "cd:0.1" },
    { page = 3, label = "物品 全给",        act = "items:1" },
}

local ui = { scale = 1, font = nil }

local function S(v) return math.floor(v * ui.scale + 0.5) end

local function updateScale()
    local w, h = love.graphics.getDimensions()
    if not (w and h and w > 0 and h > 0) then return end
    local s = math.max(1, math.min(w / 1280, h / 720))
    if not ui.font or math.abs(s - ui.scale) > 0.01 then
        ui.scale = s
        -- the default font is 12px and has no CJK glyphs; trainer_font.ttf is
        -- a Noto Sans SC subset shipped inside the .love
        local px = math.floor(20 * s + 0.5)
        local ok, f = pcall(love.graphics.newFont, "trainer_font.ttf", px)
        if not ok or not f then
            ok, f = pcall(love.graphics.newFont, px)
        end
        if ok and f then ui.font = f end
    end
end

local function toggleRect()
    local w, h = love.graphics.getDimensions()
    return S(16), h - S(100), S(96), S(84)
end

local function panelRect()
    local w, h = love.graphics.getDimensions()
    local ph = S(72) + S(64) * 9
    local pw = math.min(S(700), w - S(32))
    return S(16), math.max(S(16), h - S(100) - S(12) - ph), pw, ph
end

local function pageButtonRect(i)
    local px, py = panelRect()
    return px + S(12) + (i - 1) * S(160), py + S(10), S(150), S(52)
end

local function rowRect(idx)
    local px, py, pw = panelRect()
    return px + S(12), py + S(72) + (idx - 1) * S(64), pw - S(24), S(56)
end

local function rowsForPage(p)
    local out = {}
    for _, r in ipairs(ROWS) do if r.page == p then out[#out + 1] = r end end
    for _, a in ipairs(ACTIONS) do if a.page == p then out[#out + 1] = a end end
    return out
end

local function inRect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

local function handleTap(x, y)
    local tx, ty, tw, th = toggleRect()
    if inRect(x, y, tx, ty, tw, th) then
        T.state.panel = not T.state.panel
        saveState()
        return true
    end
    if not T.state.panel then return false end

    local px, py, pw, ph = panelRect()
    if inRect(x, y, px, py, pw, ph) then
        for i = 1, #PAGES do
            local bx, by, bw, bh = pageButtonRect(i)
            if inRect(x, y, bx, by, bw, bh) then
                T.state.page = i
                return true
            end
        end
        local rows = rowsForPage(T.state.page)
        for i, r in ipairs(rows) do
            local rx, ry, rw, rh = rowRect(i)
            if inRect(x, y, rx, ry, rw, rh) then
                if r.key then
                    T.state[r.key] = not T.state[r.key]
                    saveState()
                else
                    runAction(r.act)
                end
                return true
            end
        end
        return true
    end
    T.state.panel = false
    return false
end

local function box(x, y, w, h, col)
    love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)
    love.graphics.rectangle("fill", x, y, w, h, S(6), S(6))
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setLineWidth(math.max(1, S(2)))
    love.graphics.rectangle("line", x, y, w, h, S(6), S(6))
end

local function text(str, x, y, w, align)
    love.graphics.setColor(1, 1, 1, 0.96)
    love.graphics.printf(str, x, y, w, align or "left")
end

local function drawUi()
    updateScale()
    love.graphics.push()
    love.graphics.origin()
    if ui.font then love.graphics.setFont(ui.font) end

    local tx, ty, tw, th = toggleRect()
    box(tx, ty, tw, th, T.state.panel and { 0.15, 0.45, 0.85, 0.92 } or { 0.12, 0.12, 0.16, 0.7 })
    text("T", tx, ty + th / 2 - S(9), tw, "center")

    if T.state.panel then
        local px, py, pw, ph = panelRect()
        box(px, py, pw, ph, { 0.06, 0.06, 0.09, 0.95 })
        for i, name in ipairs(PAGES) do
            local bx, by, bw, bh = pageButtonRect(i)
            box(bx, by, bw, bh, T.state.page == i and { 0.2, 0.5, 0.85, 0.95 } or { 0.18, 0.18, 0.22, 0.95 })
            text(name, bx, by + bh / 2 - S(9), bw, "center")
        end
        local rows = rowsForPage(T.state.page)
        for i, r in ipairs(rows) do
            local rx, ry, rw, rh = rowRect(i)
            if r.key then
                box(rx, ry, rw, rh, T.state[r.key] and { 0.16, 0.55, 0.28, 0.95 } or { 0.2, 0.2, 0.24, 0.95 })
                text(r.label, rx + S(14), ry + S(15), rw - S(120))
                text(T.state[r.key] and "开" or "关", rx, ry + S(15), rw - S(14), "right")
            else
                box(rx, ry, rw, rh, { 0.3, 0.25, 0.45, 0.95 })
                local lbl = r.label
                if r.act == "target" then
                    local list = roster()
                    local cnt = list and #list or 0
                    local t = tonumber(T.target) or 0
                    if t == 0 then
                        lbl = "目标: 全部单位 (" .. cnt .. ")"
                    else
                        lbl = "目标: 单位 #" .. t .. " / " .. cnt
                    end
                end
                text(lbl, rx + S(14), ry + S(15), rw - S(24))
            end
        end
    end

    love.graphics.pop()
end

----------------------------------------------------------------------
-- hooks
----------------------------------------------------------------------
local prev_update = love.update
local prev_draw = love.draw
local prev_touchpressed = love.touchpressed
local prev_mousepressed = love.mousepressed

local acc = 0

love.update = function(dt)
    if prev_update then prev_update(dt) end
    hookSlot()
    pinGlobals()
    acc = acc + (dt or 0)
    if acc >= 1 then
        acc = 0
        pollRemote()
        logState()
    end
end

love.draw = function()
    if prev_draw then prev_draw() end
    drawUi()
end

-- On iOS LÖVE delivers BOTH touchpressed and a synthetic mousepressed
-- (istouch=true) for the same finger. Consuming the tap in both paths toggled
-- the panel twice, which is why it looked dead. Touch is handled only in
-- touchpressed now; mousepressed only deals with real mouse input.
love.touchpressed = function(id, x, y, dx, dy, pressure)
    if handleTap(x, y) then return end
    if prev_touchpressed then prev_touchpressed(id, x, y, dx, dy, pressure) end
end

love.mousepressed = function(x, y, button, istouch, presses)
    if not istouch and button == 1 and handleTap(x, y) then return end
    if prev_mousepressed then prev_mousepressed(x, y, button, istouch, presses) end
end

T.action = runAction
_G.__sbTrainer = T

loadState()

return T
