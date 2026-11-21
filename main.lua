-- Slotbound iOS shim (LÖVE 11.5 / LiveContainer).
-- 1) Fake ffi.C: SbLuck*/SbPity* are Windows-only native exports from Slotbound.exe.
--    Luck/pity run on base probabilities only.
-- 2) iOS has no JIT: wrap jit.on/jit.off so the game's jit.on(fn, true) calls
--    fail silently instead of aborting startup.
-- 3) Two-finger tap = right-click: a second finger down within the tap window
--    cancels the pending left-click and fires a right-click instead.
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

-- Drop-rate tuner v1.3.0 (live, file-based).
-- The dylib's native UI writes slider values to "drop_rates_ui.lua"
-- in the save dir (same folder as save_fallback.dat).
-- Format: return { grade = { normal=100, advanced=0, rare=0, legendary=0, prism=0 },
--                 class = { A=1, D=1, H=1, M=1, S=1, W=1 } }
-- This shim polls that file in love.update and applies changes live
-- (no restart). Grades: normal=普通 advanced=高级 rare=稀有
-- legendary=传说 prism=棱镜. Classes: A=弓手 D=决斗者 H=骑兵
-- M=法师 S=枪兵 W=战士 (multiplier: 1=正常, 5=五倍, 0=不出).
local drop_grade = { normal = 100, advanced = 0, rare = 0, legendary = 0, prism = 0 }
local drop_class = { A = 1, D = 1, H = 1, M = 1, S = 1, W = 1 }
local drop_last_content = nil
local drop_poll_t = 0
local GRADE_KEYS = { "normal", "advanced", "rare", "legendary", "prism" }
local CLASS_KEYS = { "A", "D", "H", "M", "S", "W" }

local function apply_drop_grades()
    local total = 0
    for _, k in ipairs(GRADE_KEYS) do total = total + (drop_grade[k] or 0) end
    local ok, constants = pcall(require, "src.data.constants")
    if ok and constants and constants.unitGrades and constants.unitGrades.probabilities then
        local p = constants.unitGrades.probabilities
        for _, k in ipairs(GRADE_KEYS) do
            if total > 0 then
                p[k] = (drop_grade[k] or 0) / total
            else
                p[k] = (k == "normal") and 1 or 0
            end
        end
        p.special = 0
    end
end

local function load_drop_ui_config()
    local ok, content = pcall(love.filesystem.read, "drop_rates_ui.lua")
    if not ok or not content then return false end
    if content == drop_last_content then return false end
    drop_last_content = content
    local fn = loadstring(content)
    if not fn then return false end
    local ok2, tbl = pcall(fn)
    if not ok2 or type(tbl) ~= "table" then return false end
    if type(tbl.grade) == "table" then
        for _, k in ipairs(GRADE_KEYS) do
            local v = tonumber(tbl.grade[k])
            if v and v >= 0 and v <= 100 then drop_grade[k] = v end
        end
    end
    if type(tbl.class) == "table" then
        for _, k in ipairs(CLASS_KEYS) do
            local v = tonumber(tbl.class[k])
            if v and v >= 0 and v <= 5 then drop_class[k] = v end
        end
    end
    apply_drop_grades()
    return true
end

local function apply_drop_mult(weights)
    if type(weights) ~= "table" then return weights end
    local out = {}
    local total = 0
    for k, v in pairs(weights) do
        local m = drop_class[k] or 1
        local nv = (tonumber(v) or 0) * m
        out[k] = nv
        total = total + nv
    end
    if total <= 0 then return weights end
    for k in pairs(out) do out[k] = out[k] / total end
    return out
end

-- Hook src.game.cores as soon as it loads, so every weight lookup (base and
-- projected) passes through the user's multipliers before any slot spins.
local _require = require
function require(name)
    local mod = _require(name)
    if name == "src.game.cores" and type(mod) == "table" and not mod.__drop_hooked then
        mod.__drop_hooked = true
        pcall(load_drop_ui_config)
        pcall(apply_drop_grades)
        if type(mod.getProjectedSymbolWeights) == "function" then
            local orig = mod.getProjectedSymbolWeights
            mod.getProjectedSymbolWeights = function(...) return apply_drop_mult(orig(...)) end
        end
        if type(mod.baseSymbolWeights) == "function" then
            local orig = mod.baseSymbolWeights
            mod.baseSymbolWeights = function(...) return apply_drop_mult(orig(...)) end
        end
    end
    return mod
end

local chunk = love.filesystem.load("real_main.luac")
chunk()
package.loaded["ffi"] = real_ffi

-- Two-finger tap = right-click (touch only). [v1.1.1 base]
-- A single-finger tap is held for TAP_DELAY seconds before it is delivered
-- as a left-click, so a second finger landing in that window can turn the
-- gesture into a right-click instead of firing a stray left-click first.
-- [v1.1.3] Toggle button added on top of v1.1.1: a small button in the
-- top-right corner switches right-click mode (L = left, R = right, orange
-- when on). In right mode, a single tap fires a right-click; the two-finger
-- gesture from v1.1.1 still works as well.
local TAP_DELAY = 0.09
local game_mousepressed = love.mousepressed
local game_mousereleased = love.mousereleased
local game_update = love.update
local game_draw = love.draw
local game_keypressed = love.keypressed
local game_keyreleased = love.keyreleased

-- Toggle button (top-right corner) and back button (top-left, ESC)
local right_mode = false
local right_taps = {}  -- touch id -> {x, y} for single taps in right mode
local BW, BH = 100, 48
local MARGIN = 12

local function back_rect()
    return MARGIN, MARGIN, BW, BH
end

local function on_back_button(x, y)
    local bx, by, bw, bh = back_rect()
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

local function press_esc()
    if game_keypressed then game_keypressed("escape", "escape", false) end
end

local function release_esc()
    if game_keyreleased then game_keyreleased("escape", "escape") end
end

local function button_rect()
    local w, h = love.graphics.getDimensions()
    return w - BW - MARGIN, MARGIN, BW, BH
end

local function on_button(x, y)
    local bx, by, bw, bh = button_rect()
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

local function draw_button()
    local bx, by, bw, bh = button_rect()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.push()
    love.graphics.origin()
    if right_mode then
        love.graphics.setColor(0.85, 0.35, 0.1, 0.85)
    else
        love.graphics.setColor(0.12, 0.12, 0.16, 0.65)
    end
    love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx, by, bw, bh, 8, 8)
    local label = right_mode and "R" or "L"
    local font = love.graphics.getFont()
    local tw = font:getWidth(label)
    local th = font:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(label, bx + (bw - tw) / 2, by + (bh - th) / 2)
    love.graphics.pop()
    love.graphics.setColor(r, g, b, a)
end

local function draw_back_button()
    local bx, by, bw, bh = back_rect()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(0.12, 0.12, 0.16, 0.65)
    love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx, by, bw, bh, 8, 8)
    local label = "ESC"
    local font = love.graphics.getFont()
    local tw = font:getWidth(label)
    local th = font:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(label, bx + (bw - tw) / 2, by + (bh - th) / 2)
    love.graphics.pop()
    love.graphics.setColor(r, g, b, a)
end

love.draw = function()
    if game_draw then game_draw() end
    draw_button()
    draw_back_button()
end

local active_touches = {}
local pending = nil          -- {x, y, t, released, rx, ry}
local right_pos = nil        -- {x, y} where the right-click fired (first finger = pointer)
local right_touch_id = nil   -- id of the finger that triggered the right-click
-- Positions where a touch left-press was swallowed (cancelled pending or
-- second-finger auto click). Their matching releases are swallowed too, so
-- the game never sees a release without a press. Entries expire after 1s.
local swallowed = {}

local function dist2(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return dx * dx + dy * dy
end

local function swallow_at(x, y)
    swallowed[#swallowed + 1] = { x = x, y = y, t = love.timer.getTime() }
end

local function is_swallowed(x, y)
    local now = love.timer.getTime()
    for i = #swallowed, 1, -1 do
        local s = swallowed[i]
        if now - s.t > 1.0 then
            table.remove(swallowed, i)
        elseif dist2(x, y, s.x, s.y) <= 60 * 60 then
            table.remove(swallowed, i)
            return true
        end
    end
    return false
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if on_back_button(x, y) then
        press_esc()
        return
    end
    if on_button(x, y) then
        right_mode = not right_mode
        return
    end
    local count = 0
    local first_x, first_y = nil, nil
    for _, t in pairs(active_touches) do
        count = count + 1
        first_x, first_y = t.x, t.y
    end
    active_touches[id] = { x = x, y = y }
    if count == 0 and right_mode then
        -- Single tap in right mode: fire a right-click at once.
        right_taps[id] = { x = x, y = y }
        if love.mouse and love.mouse.setPosition then
            pcall(love.mouse.setPosition, x, y)
        end
        if game_mousepressed then game_mousepressed(x, y, 2, true, 1) end
        return
    end
    if count == 1 then
        -- Second finger down: cancel the pending left-click, fire right-click
        -- at the FIRST finger's position (the pointer), not at this finger.
        if pending then swallow_at(pending.x, pending.y) end
        pending = nil
        local rx, ry = first_x or x, first_y or y
        right_pos = { x = rx, y = ry }
        right_touch_id = id
        -- The touch system moved the internal mouse position to this
        -- (second) finger; move it back to the pointer (first finger)
        -- so the game does not see the pointer jump to another place.
        if love.mouse and love.mouse.setPosition then
            pcall(love.mouse.setPosition, rx, ry)
        end
        if game_mousepressed then game_mousepressed(rx, ry, 2, true, 1) end
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if on_back_button(x, y) then
        release_esc()
        return
    end
    active_touches[id] = nil
    if right_taps[id] then
        local p = right_taps[id]
        right_taps[id] = nil
        if game_mousereleased then game_mousereleased(p.x, p.y, 2, true, 1) end
        return
    end
    if right_touch_id and id == right_touch_id then
        -- The finger that triggered the right-click lifted: release it at
        -- the same pointer position where the press fired.
        local rp = right_pos
        right_touch_id = nil
        right_pos = nil
        if rp and game_mousereleased then game_mousereleased(rp.x, rp.y, 2, true, 1) end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if not istouch and on_back_button(x, y) then
        press_esc()
        return
    end
    if not istouch and on_button(x, y) then
        right_mode = not right_mode
        return
    end
    if istouch and button == 1 then
        -- A touch on a button is already handled by touchpressed;
        -- swallow its auto left-click.
        if on_button(x, y) or on_back_button(x, y) then return end
        -- Single tap in right mode: the right-click was already fired by
        -- touchpressed; swallow the engine's auto left-click.
        if right_mode then
            local touches = love.touch.getTouches()
            if #touches == 1 then return end
        end
        -- Auto left-click generated from a touch. If two fingers are down,
        -- this is the second finger: swallow it (right-click is handled
        -- through love.touchpressed instead).
        local touches = love.touch.getTouches()
        if #touches >= 2 or (right_pos and dist2(x, y, right_pos.x, right_pos.y) <= 60 * 60) then
            swallow_at(x, y)
            return
        end
        -- First finger: hold briefly to see if a second finger joins.
        pending = { x = x, y = y, t = love.timer.getTime(), released = false }
        return
    end
    if game_mousepressed then game_mousepressed(x, y, button, istouch, presses) end
end

function love.mousereleased(x, y, button, istouch, presses)
    if not istouch and on_back_button(x, y) then
        release_esc()
        return
    end
    if not istouch and on_button(x, y) then return end
    if istouch and button == 1 then
        if on_button(x, y) or on_back_button(x, y) then return end
        if is_swallowed(x, y) then return end
        -- In right mode every touch release was already delivered by
        -- touchreleased (right-mode tap or two-finger right-click).
        if right_mode then return end
        if pending then
            -- Finger lifted before the delayed press fired: remember the
            -- release so it is delivered right after the press.
            pending.released = true
            pending.rx, pending.ry = x, y
            return
        end
    end
    if game_mousereleased then game_mousereleased(x, y, button, istouch, presses) end
end

function love.update(dt)
    if game_update then game_update(dt) end
    -- Live drop-rate polling: the dylib UI writes drop_rates_ui.lua;
    -- pick up changes within ~0.5s and apply them immediately.
    drop_poll_t = drop_poll_t + dt
    if drop_poll_t >= 0.5 then
        drop_poll_t = 0
        pcall(load_drop_ui_config)
    end
    if pending and love.timer.getTime() - pending.t >= TAP_DELAY then
        local p = pending
        pending = nil
        if love.mouse and love.mouse.setPosition then
            pcall(love.mouse.setPosition, p.x, p.y)
        end
        if game_mousepressed then game_mousepressed(p.x, p.y, 1, true, 1) end
        if p.released and game_mousereleased then
            game_mousereleased(p.rx, p.ry, 1, true, 1)
        end
    end
end
