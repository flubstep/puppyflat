local tween = require('vendor/tween')

local blinkInterval = 0.5

StartMenu = {}

function StartMenu:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  local titleFont = love.graphics.newFont('assets/PressStart2P.ttf', 16)
  local selectFont = love.graphics.newFont('assets/PressStart2P.ttf', 8)

  o.titleText = love.graphics.newText(titleFont, "Puppyflat")
  o.selectText = love.graphics.newText(selectFont, "Press space!")

  o.titleY = 160
  o.selectY = 220
  o.offsetY = -220
  o.tween = nil

  o.hidden = true
  o.shownTime = 0

  return o
end

function StartMenu:update(dt)
  self.shownTime = self.shownTime + dt
  if self.hidden and puppycat:isInPlace() then
    self.hidden = false
    self:show()
  end
  if self.tween then
    self.tween:update(dt)
  end
end

function StartMenu:draw()
  if self.active and not self.hidden then
    love.graphics.setColor(0, 0, 0)
    drawCentered(self.titleText, self.titleY + self.offsetY)
    -- todo: this is a terrible hack
    if math.floor(self.shownTime / blinkInterval) % 2 == 0 then
      drawCentered(self.selectText, self.selectY + self.offsetY)
    end
    love.graphics.setColor(255, 255, 255)
  end
end

function StartMenu:show()
  self.offsetY = -220
  self.tween = tween.new(0.3, self, {offsetY=0}, "outBounce")
end

function StartMenu:hide()
  self.offsetY = -220
  self.tween = nil
end

function drawCentered(text, y)
  local startX = (800 - text:getWidth()*scale) / 2
  love.graphics.draw(text, startX, y, 0, scale, scale)
end