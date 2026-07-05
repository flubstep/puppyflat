-- Full-sweep combo tracker: collecting every eggplant in a volley
-- extends the streak and pops a message in the top right, with wording
-- that escalates the longer the streak runs. Missing any eggplant
-- resets the streak.

local comboWords = {
  "Great!",
  "Awesome!",
  "Pawsome!",
  "Incredible!",
  "Unstoppable!",
  "LEGENDARY!",
}

local displayTime = 1.6
local fadeTime = 0.4
local textScale = 3
local marginX = 30
local marginY = 30
local messageGap = 20
local shakeDuration = 0.5
local shakeAmplitude = 4*scale

GameCombo = {}

function GameCombo:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  o.streak = 0
  o.font = love.graphics.newFont('assets/PressStart2P.ttf', 8)
  o.text = love.graphics.newText(o.font, "")
  o.counterText = love.graphics.newText(o.font, "Combo: 0")
  o.age = nil
  o.popScale = 1
  o.popTween = nil
  o.shakeTime = nil
  return o
end

function GameCombo:fullSweep()
  self.streak = self.streak + 1
  self.counterText:set("Combo: " .. self.streak)
  self.text:set(comboWords[math.min(self.streak, #comboWords)])
  self.age = 0
  self.popScale = 0.3
  self.popTween = tween.new(0.3, self, {popScale=1}, 'outBack')
end

function GameCombo:breakStreak()
  if self.streak > 0 then
    self.shakeTime = 0
  end
  self.streak = 0
  self.counterText:set("Combo: 0")
end

function GameCombo:update(dt)
  if self.age then
    self.age = self.age + dt
  end
  if self.popTween and self.popTween:update(dt) then
    self.popTween = nil
  end
  if self.shakeTime then
    self.shakeTime = self.shakeTime + dt
    if self.shakeTime >= shakeDuration then
      self.shakeTime = nil
    end
  end
end

function GameCombo:draw()
  -- persistent counter in the top right; shakes with decaying jitter
  -- when the streak breaks
  local shakeX, shakeY = 0, 0
  if self.shakeTime then
    local amplitude = shakeAmplitude*(1 - self.shakeTime/shakeDuration)
    shakeX = (love.math.random()*2 - 1)*amplitude
    shakeY = (love.math.random()*2 - 1)*amplitude
  end
  local counterX = screenWidth - marginX - self.counterText:getWidth()*textScale
  love.graphics.setColor(0, 0, 0)
  love.graphics.draw(self.counterText,
    counterX + shakeX, marginY + shakeY, 0, textScale, textScale)
  love.graphics.setColor(255, 255, 255)

  if not self.age or self.age > displayTime then
    return
  end

  local alpha = 1
  if self.age > displayTime - fadeTime then
    alpha = (displayTime - self.age)/fadeTime
  end

  -- sweep message below the counter, right-aligned, scaling around the
  -- text center so the pop-in overshoot stays in place
  local width = self.text:getWidth()
  local height = self.text:getHeight()
  local x = screenWidth - marginX - width*textScale/2
  local y = marginY + self.counterText:getHeight()*textScale + messageGap
    + height*textScale/2
  local s = textScale*self.popScale

  love.graphics.setColor(0, 0, 0, alpha)
  love.graphics.draw(self.text, x, y, 0, s, s, width/2, height/2)
  love.graphics.setColor(255, 255, 255)
end
