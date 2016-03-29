local anim8 = require 'vendor/anim8'

local playerWidth = 38
local playerHeight = 28
local minVelocity = 10*m
local maxVelocity = 36*m
local chargeSpeed = 48*m
local startX = screenWidth / 4
local startY = screenHeight * 3 / 4

local barHeight = 5 * scale
local padding = 5
local borderWidth = 1 * scale
local borderRadius = 0

Puppycat = {}

function Puppycat:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  -- player sprite
  o.image = love.graphics.newImage("assets/puppycat.png")
  o.sheet = love.graphics.newImage("assets/puppycatRunning.png")
  g = anim8.newGrid(playerWidth, playerHeight, o.sheet:getWidth(), o.sheet:getHeight())
  o.animation = anim8.newAnimation(g('1-4',1), 0.1)

  o.body = love.physics.newBody(world, 0, startY, "dynamic")
  o.body:setGravityScale(4.2)

  o.jumpSound = love.audio.newSource("assets/jump.wav", "static")
  o.collectSound = love.audio.newSource("assets/collect.wav", "static")

  -- make the rectangle line up with where we will draw the cat
  o.shape = love.physics.newRectangleShape(
    playerWidth*scale/2,
    playerHeight*scale/2,
    playerWidth*scale - 12*scale, -- make the hitbox slightly smaller
    playerHeight*scale - 8*scale  -- to account for whitespace
  )
  o.fixture = love.physics.newFixture(o.body, o.shape)
  o.fixture:setUserData({tag="Puppycat", gameObject=o})

  o.touchingGround = false
  o.holdingJump = false
  o.jumpVelocity = 0
  return o
end

function Puppycat:isInPlace()
  return self.body:getX() >= startX
end

function Puppycat:update(dt)
  self.animation:update(dt)
  local _, linearY = self.body:getLinearVelocity()
  if self.body:getX() < startX then
    self.body:setLinearVelocity(5.0*m, linearY)
  else
    self.body:setLinearVelocity(0, linearY)
  end
  if self.holdingJump then
    self.jumpVelocity = math.min(self.jumpVelocity + dt*chargeSpeed, maxVelocity)
  end
end

function Puppycat:draw()

  if not self.touchingGround then
    local _, yVelocity = self.body:getLinearVelocity()
    if yVelocity < 0 then
      self.animation:gotoFrame(2)
    else
      self.animation:gotoFrame(4)
    end
  end

  self.animation:draw(self.sheet, self.body:getX(), self.body:getY(), 0, self.scale, self.scale)
  self:drawJumpPower()
end


function Puppycat:drawJumpPower()
  if self.holdingJump then
    
    local maxBarWidth = playerWidth * scale
    local barWidth = (self.jumpVelocity - minVelocity) / (maxVelocity - minVelocity) * maxBarWidth
    local barX = self.body:getX() + maxBarWidth/2 - barWidth/2
    local barY = self.body:getY() - barHeight - padding * scale

    love.graphics.setColor(0, 0, 0)
    local border = love.graphics.rectangle("fill",
      barX, barY,
      barWidth, barHeight,
      borderRadius, borderRadius
    )
    love.graphics.setColor(0, 196, 0)
    local rectangle = love.graphics.rectangle("fill",
      barX+borderWidth, barY+borderWidth,
      barWidth-2*borderWidth, barHeight-2*borderWidth,
      borderRadius, borderRadius
    )

    love.graphics.setColor(255, 255, 255)
  end
end

function Puppycat:onCollisionBegin(other)
  local data = other:getUserData()
  if data.tag == "Eggplant" then
    gameScore:increment()
    self.collectSound:play()
    --updateSpeed(objectSpeed + 0.5*m)
  end
  if data.tag == "Floor" then
    self.touchingGround = true
    self.animation:resume()
  end
end

function Puppycat:onCollisionEnd(other)
  local data = other:getUserData()
  if data.tag == "Floor" then
    self.touchingGround = false
    self.animation:pause()
  end
end

function Puppycat:holdJump()
  if self.touchingGround then
    self.jumpVelocity = minVelocity
    self.holdingJump = true
  end
end

function Puppycat:releaseJump()
  if self.touchingGround and self.holdingJump then
    self.body:setLinearVelocity(0, -self.jumpVelocity)
    self.jumpVelocity = minVelocity
    self.holdingJump = false
    self.jumpSound:play()
  end
end
