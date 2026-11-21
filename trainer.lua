-- trainer.lua -- Slotbound iOS trainer (pure Lua, no dylib)
-- Hooks LÖVE/Lua state directly; every change is applied after the game's
-- own update so the game cannot overwrite it in the same frame.
-- Labels are ASCII on purpose: LÖVE's default font has no CJK glyphs.

local T = {}

----------------------------------------------------------------------
-- config
----------------------------------------------------------------------
local CFG = "slotbound_trainer.txt"

T.values = {
    coins = 999999,
    spins = 999,
    essence = 999,
}

T.state = {
    panel = false,
    coins = false,
    spins = false,
    essence = false,
    jackpot = false,
}

T.jackpotSymbol = "A" -- W A S M H D

local function serialize()
    local out = {}
    for k, v in pairs(T.state) do
        if type(v) == "boolean" then out[#out + 1] = k .. "=" .. tostring(v) end
    end
    out[#out + 1] = "jackpotSymbol=" .. tostring(T.jackpotSymbol)
    for k, v in pairs(T.values) do
        if type(v) == "number" then out[#out + 1] = "val_" .. k .. "=" .. tostring(v) end
    end
    return table.concat(out, "\n")
end

local function save()
    pcall(function() love.filesystem.write(CFG, serialize()) end)
end

local function loadCfg()
    local ok, data = pcall(function() return love.filesystem.read(CFG) end)
    if not ok or type(data) ~= "string" then return end
    for line in data:gmatch("[^\r\n]+") do
        local k, v = line:match("^([%w_]+)=(.*)$")
        if k then
            if k == "jackpotSymbol" then
                T.jackpotSymbol = v
            elseif k:sub(1, 4) == "val_" then
                T.values[k:sub(5)] = tonumber(v) or T.values[k:sub(5)]
            elseif T.state[k] ~= nil then
                T.state[k] = (v == "true")
            end
        end
    end
end

----------------------------------------------------------------------
-- per-frame enforcement (runs AFTER the game's update)
----------------------------------------------------------------------
local function isnum(v) return type(v) == "number" end

local function enforce()
    local G = _G
    if T.state.coins then
        if isnum(G.coins) then G.coins = T.values.coins end
        -- display coins are recomputed every frame from an animation table;
        -- writing them after the update keeps the UI in sync.
        if isnum(G.displayCoins) then G.displayCoins = T.values.coins end
    end
    if T.state.spins then
        if isnum(G.spinsLeft) then G.spinsLeft = T.values.spins end
    end
    if T.state.essence then
        if isnum(G.jungsu) then G.jungsu = T.values.essence end
        -- essence has no per-frame interpolation source: the balance target
        -- only moves when the game itself adds/removes essence, so all three
        -- are written to make the counter roll immediately.
        if isnum(G.jungsuBalanceTarget) then G.jungsuBalanceTarget = T.values.essence end
        if isnum(G.displayJungsu) then G.displayJungsu = T.values.essence end
    end
end

----------------------------------------------------------------------
-- jackpot: wrap slot:buildResultGrid (result is decided at lever pull)
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
        if T.state.jackpot then return jackpotGrid() end
        return orig(self, ...)
    end
    s.__sbTrainerHooked = true
end

----------------------------------------------------------------------
-- ui
----------------------------------------------------------------------
local BW, BH, MARGIN = 100, 48, 12
local PANEL_W, ROW_H = 360, 52

local function toggleRect()
    return MARGIN, MARGIN + BH + 8, BW, BH
end

local function panelRect()
    local x, y = MARGIN, MARGIN + BH * 2 + 16
    return x, y, PANEL_W, ROW_H * 5 + 12
end

local ROWS = {
    { key = "coins",   label = "COINS" },
    { key = "spins",   label = "SPINS" },
    { key = "essence", label = "ESSENCE" },
    { key = "jackpot", label = "JACKPOT" },
}

local function inRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function handleTap(x, y)
    if inRect(x, y, toggleRect()) then
        T.state.panel = not T.state.panel
        return true
    end
    if not T.state.panel then return false end

    local px, py, pw = panelRect()
    if inRect(x, y, px, py, pw, ROW_H * #ROWS + 12) then
        local row = math.floor((y - py) / ROW_H) + 1
        local r = ROWS[row]
        if r then
            T.state[r.key] = not T.state[r.key]
            save()
            return true
        end
        return true -- swallow taps inside the panel body
    end
    -- tap outside the panel closes it
    T.state.panel = false
    return false
end

local function box(x, y, w, h, r, g, b, a)
    love.graphics.setColor(r, g, b, a or 1)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
end

local function drawUi()
    local font = love.graphics.getFont()
    love.graphics.push()
    love.graphics.origin()

    -- toggle button
    local bx, by = toggleRect()
    if T.state.panel then
        box(bx, by, BW, BH, 0.15, 0.45, 0.85, 0.9)
    else
        box(bx, by, BW, BH, 0.12, 0.12, 0.16, 0.68)
    end
    love.graphics.setColor(1, 1, 1, 1)
    do
        local text = "T"
        local tw, th = font:getWidth(text), font:getHeight()
        love.graphics.print(text, bx + (BW - tw) / 2, by + (BH - th) / 2)
    end

    if T.state.panel then
        local px, py, pw = panelRect()
        box(px, py, pw, ROW_H * #ROWS + 12, 0.08, 0.08, 0.11, 0.92)
        for i, r in ipairs(ROWS) do
            local ry = py + 6 + (i - 1) * ROW_H
            local on = T.state[r.key]
            if on then
                love.graphics.setColor(0.18, 0.62, 0.30, 0.95)
            else
                love.graphics.setColor(0.22, 0.22, 0.26, 0.95)
            end
            love.graphics.rectangle("fill", px + 8, ry + 4, pw - 16, ROW_H - 10, 6, 6)
            love.graphics.setColor(1, 1, 1, 0.95)
            love.graphics.print(r.label, px + 20, ry + 14)
            local tag = on and "ON" or "OFF"
            love.graphics.print(tag, px + pw - 20 - font:getWidth(tag), ry + 14)
        end
    end

    love.graphics.pop()
end

----------------------------------------------------------------------
-- hooking
----------------------------------------------------------------------
local prev_update = love.update
local prev_draw = love.draw
local prev_touchpressed = love.touchpressed
local prev_mousepressed = love.mousepressed

love.update = function(dt)
    if prev_update then prev_update(dt) end
    hookSlot()
    enforce()
end

love.draw = function()
    if prev_draw then prev_draw() end
    drawUi()
end

love.touchpressed = function(id, x, y, dx, dy, pressure)
    if handleTap(x, y) then return end
    if prev_touchpressed then prev_touchpressed(id, x, y, dx, dy, pressure) end
end

love.mousepressed = function(x, y, button, istouch, presses)
    -- touch deliveries also arrive here (istouch = true); the press that we
    -- already consumed in touchpressed must not reach the game.
    if button == 1 and handleTap(x, y) then return end
    if prev_mousepressed then prev_mousepressed(x, y, button, istouch, presses) end
end

loadCfg()

return T
