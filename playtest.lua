-- Automated playtest harness. Run with: love . --playtest[=SECONDS]
--
-- Simulates spacebar input to start the game and hop over/into eggplants,
-- logs the cat's position and score to stdout once per second, and captures
-- screenshots into the save directory at regular intervals. Audio is muted
-- for the duration of the run. Does nothing unless --playtest is passed.

local duration = nil
for _, v in ipairs(arg or {}) do
  if v == "--playtest" then
    duration = 12.5
  else
    local seconds = v:match("^%-%-playtest=(%d+%.?%d*)$")
    if seconds then duration = tonumber(seconds) end
  end
end
if not duration then return end

love.filesystem.setIdentity("puppyflat-playtest")
love.audio.setVolume(0)

local origUpdate = love.update

local t = 0
local lastShot = 0
local shotInterval = 2.0
local shotCount = 0
local startedGame = false
local jumpHeld = false
local currentArc = nil
local lastLog = 0

print("[playtest] running for " .. duration .. "s, screenshots in " ..
  love.filesystem.getSaveDirectory())

love.update = function(dt)
  origUpdate(dt)
  t = t + dt

  -- press space to leave the start menu
  if not startedGame and t >= 1.0 then
    love.keypressed("space")
    startedGame = true
    print(string.format("[playtest] t=%.2f pressed space to start game", t))
  end

  -- autopilot: for each spawned arc, start charging early enough to
  -- reach the arc's jump power, then release at its recorded jump moment
  if startedGame then
    local clock = EggplantManager.clock
    if not jumpHeld then
      for _, arc in ipairs(EggplantManager.arcs) do
        local holdTime = (arc.v - Puppycat.minJumpVelocity) / Puppycat.jumpChargeSpeed
        if clock >= arc.jumpAt - holdTime and clock < arc.jumpAt then
          love.keypressed("space")
          jumpHeld = true
          currentArc = arc
          break
        end
      end
    elseif clock >= currentArc.jumpAt then
      print(string.format("[playtest] t=%.2f jumping for arc v=%.0f (charged %.0f)",
        t, currentArc.v, puppycat.jumpVelocity))
      love.keyreleased("space")
      jumpHeld = false
      currentArc = nil
    end
  end

  if t - lastLog >= 1.0 then
    lastLog = t
    print(string.format("[playtest] t=%.2f catX=%.1f catY=%.1f score=%d grounded=%s",
      t, puppycat.body:getX(), puppycat.body:getY(),
      gameScore.score, tostring(puppycat.touchingGround)))
  end

  if t - lastShot >= shotInterval then
    lastShot = t
    shotCount = shotCount + 1
    local name = string.format("shot_%02d_t%04.1f.png", shotCount, t)
    love.graphics.captureScreenshot(name)
    print("[playtest] captured " .. name)
  end

  if t >= duration then
    print(string.format("[playtest] final score=%d of %d spawned after %.1fs -- quitting",
      gameScore.score, EggplantManager.index - 1, t))
    love.event.quit()
  end
end
