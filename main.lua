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

local chunk = love.filesystem.load("real_main.luac")
chunk()
package.loaded["ffi"] = real_ffi

-- Two-finger tap = right-click (touch only).
-- A single-finger tap is held for TAP_DELAY seconds before it is delivered
-- as a left-click, so a second finger landing in that window can turn the
-- gesture into a right-click instead of firing a stray left-click first.
local TAP_DELAY = 0.09
local game_mousepressed = love.mousepressed
local game_mousereleased = love.mousereleased
local game_update = love.update

local active_touches = {}
local pending = nil          -- {x, y, t, released, rx, ry}
local right_pos = nil        -- {x, y} of the touch that fired the right-click
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
    local count = 0
    for _ in pairs(active_touches) do count = count + 1 end
    active_touches[id] = { x = x, y = y }
    if count == 1 then
        -- Second finger down: cancel the pending left-click, fire right-click.
        if pending then swallow_at(pending.x, pending.y) end
        pending = nil
        right_pos = { x = x, y = y }
        if game_mousepressed then game_mousepressed(x, y, 2, true, 1) end
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    local was_right = right_pos and dist2(x, y, right_pos.x, right_pos.y) <= 60 * 60
    active_touches[id] = nil
    if was_right then
        right_pos = nil
        if game_mousereleased then game_mousereleased(x, y, 2, true, 1) end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if istouch and button == 1 then
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
    if istouch and button == 1 then
        if is_swallowed(x, y) then return end
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
    if pending and love.timer.getTime() - pending.t >= TAP_DELAY then
        local p = pending
        pending = nil
        if game_mousepressed then game_mousepressed(p.x, p.y, 1, true, 1) end
        if p.released and game_mousereleased then
            game_mousereleased(p.rx, p.ry, 1, true, 1)
        end
    end
end
