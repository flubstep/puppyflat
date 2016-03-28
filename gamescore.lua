GameScore = {}

function GameScore:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  o.score = 0
  o.font = love.graphics.newFont('assets/PressStart2P.ttf', 8)
  o.text = love.graphics.newText(o.font, "")
  return o
end

function GameScore:increment()
  self.score = self.score + 1
end

function GameScore:draw()
  love.graphics.setColor(0, 0, 0)
  self.text:set("Eggplants: " .. self.score)
  -- todo: this scale factor should be calculated independently of the global scale
  -- since arbitrary font sizes result in anti-aliasing
  love.graphics.draw(self.text, 30, 30, 0, 3, 3)
  love.graphics.setColor(255, 255, 255)
end