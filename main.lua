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

-- Two-finger tap = right-click (v1.1.2)
-- Left-click fires on RELEASE (a tap), not on a timer: holding one finger
-- to aim a right-click never triggers a left-click, so it can no longer
-- open an item info page by accident. Right-click fires at the pointer
-- (first finger) the moment the second finger goes down. mousemoved is
-- redirected to the pointer during a two-finger gesture, so the pointer
-- never visibly jumps to the second finger.
do
    local game_mousepressed = love.mousepressed
    local game_mousereleased = love.mousereleased
    local game_mousemoved = love.mousemoved
    local real_getPosition = love.mouse and love.mouse.getPosition

    local active_touches = {}
    local first_pos = nil      -- position of the first (pointer) finger
    local pending = nil        -- {x, y} single tap waiting for release
    local right_pos = nil      -- pointer position during a right-click
    local right_touch_id = nil
    local swallowed = {}

    local function is_swallowed(x, y)
        local now = love.timer.getTime()
        for i = #swallowed, 1, -1 do
            local s = swallowed[i]
            if now - s.t > 1 then
                table.remove(swallowed, i)
            elseif math.abs(s.x - x) <= 60 and math.abs(s.y - y) <= 60 then
                table.remove(swallowed, i)
                return true
            end
        end
        return false
    end

    local function set_pointer(x, y)
        if love.mouse and love.mouse.setPosition then
            pcall(love.mouse.setPosition, x, y)
        end
    end

    local function count_touches()
        local n = 0
        for _ in pairs(active_touches) do n = n + 1 end
        return n
    end

    love.touchpressed = function(id, x, y, dx, dy, pressure)
        active_touches[id] = { x = x, y = y }
        if count_touches() == 1 then
            first_pos = { x = x, y = y }
            pending = { x = x, y = y }
        elseif count_touches() >= 2 and first_pos then
            -- second finger: right-click at the pointer (first finger)
            right_pos = { x = first_pos.x, y = first_pos.y }
            right_touch_id = id
            pending = nil
            set_pointer(right_pos.x, right_pos.y)
            if game_mousepressed then
                game_mousepressed(right_pos.x, right_pos.y, 2, true, 1)
            end
        end
    end

    love.touchreleased = function(id, x, y, dx, dy, pressure)
        local was_right = (id == right_touch_id)
        active_touches[id] = nil
        if was_right and right_pos then
            local rp = right_pos
            right_pos = nil
            right_touch_id = nil
            set_pointer(rp.x, rp.y)
            if game_mousereleased then
                game_mousereleased(rp.x, rp.y, 2, true, 1)
            end
        elseif count_touches() == 0 then
            -- all fingers up: a pending tap becomes a left click now
            if pending then
                local p = pending
                pending = nil
                set_pointer(p.x, p.y)
                if game_mousepressed then
                    game_mousepressed(p.x, p.y, 1, true, 1)
                end
                if game_mousereleased then
                    game_mousereleased(p.x, p.y, 1, true, 1)
                end
            end
            first_pos = nil
        end
    end

    love.mousepressed = function(x, y, button, istouch, presses)
        if istouch then
            if count_touches() >= 2 then
                swallowed[#swallowed + 1] = { x = x, y = y, t = love.timer.getTime() }
            end
            -- single-finger auto left-click is held as a pending tap,
            -- it fires on release (see touchreleased)
            return
        end
        if game_mousepressed then game_mousepressed(x, y, button, istouch, presses) end
    end

    love.mousereleased = function(x, y, button, istouch, presses)
        if istouch then
            -- the tap is fired by touchreleased; swallow the engine's
            -- auto release so the game never sees a release without a press
            is_swallowed(x, y)
            return
        end
        if game_mousereleased then game_mousereleased(x, y, button, istouch, presses) end
    end

    love.mousemoved = function(x, y, dx, dy, istouch)
        if istouch and right_pos then
            -- during a two-finger gesture, keep the pointer at the first finger
            if game_mousemoved then game_mousemoved(right_pos.x, right_pos.y, 0, 0, istouch) end
            return
        end
        if game_mousemoved then game_mousemoved(x, y, dx, dy, istouch) end
    end

    -- If the game polls love.mouse.getPosition() instead of using
    -- mousemoved, it must also see the pointer, not the second finger.
    if love.mouse and real_getPosition then
        love.mouse.getPosition = function()
            if right_pos then return right_pos.x, right_pos.y end
            if pending then return pending.x, pending.y end
            return real_getPosition()
        end
    end
end
