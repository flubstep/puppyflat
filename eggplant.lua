-- Singleton EggplantManager

local spawnMin = 100
local spawnMax = 500
local interval = 100

local usingFlash = true

EggplantManager = {}

function EggplantManager.create()
  EggplantManager.index = 1
  EggplantManager.eggplants = {}
  EggplantManager.nextSpawnTime = os.time() + 1
  EggplantManager.image = love.graphics.newImage("assets/eggplant.png")
end

function EggplantManager.update(dt)
  -- spawn new eggplant every second
  local t = os.time()
  if t >= EggplantManager.nextSpawnTime then

    EggplantManager.nextSpawnTime = t + 1
    id = "id"..EggplantManager.index
    EggplantManager.index = EggplantManager.index + 1    

    eggplant = Eggplant:new{
      id=id,
      y=math.random(spawnMin/interval, spawnMax/interval)*interval,
      speed=objectSpeed
    }
    EggplantManager.eggplants[id] = eggplant
  end

  for _, eggplant in pairs(EggplantManager.eggplants) do
    eggplant:update(dt)
  end
end

function EggplantManager.start()
  EggplantManager.nextSpawnTime = os.time() + 1
end

function EggplantManager.draw()
  for _, eggplant in pairs(EggplantManager.eggplants) do
    eggplant:draw()
  end
end

function EggplantManager.remove(eggplant)
  EggplantManager.eggplants[eggplant.id] = nil
end

function EggplantManager.updateSpeed(newSpeed)
  for _, eggplant in pairs(EggplantManager.eggplants) do
    eggplant.body:setLinearVelocity(-newSpeed, 0)
  end
end


-- Class Eggplant
-- Eggplant body controller

Eggplant = {}

function Eggplant:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  o.image = love.graphics.newImage("assets/eggplant.png")

  local height = o.image:getHeight()*scale
  local width = o.image:getWidth()*scale

  o.active = true
  o.x = o.x or love.graphics:getWidth()
  o.body = love.physics.newBody(world, o.x, o.y, "kinematic")
  o.shape = love.physics.newRectangleShape(
    width/2,
    height/2,
    width,
    height
    )
  o.fixture = love.physics.newFixture(o.body, o.shape)
  o.fixture:setUserData({tag="Eggplant", gameObject=o})
  o.fixture:setSensor(true)

  font = love.graphics.newFont('assets/PressStart2P.ttf', 16)
  o.text = love.graphics.newText(font, "+1")

  o.body:setMass(0)
  o.body:setLinearVelocity(-o.speed, 0)
  o.body:setGravityScale(0)

  o.flashTween = nil
  o.flashRadius = 0

  return o
end

function Eggplant:update(dt)
  if self.body:getX() < -100 then
    self:destroy()
  end
  if self.flashTween then
    if self.flashTween:update(dt) then
      self:destroy()
    end
  end
end

function Eggplant:centerX()
  return self.body:getX() + self.image:getWidth()*scale/2
end

function Eggplant:centerY()
  return self.body:getY() + self.image:getHeight()*scale/2
end

function Eggplant:draw()
  local squareSize = 6*scale
  if self.active then
    if self.flashTween then
      love.graphics.setColor(0, 0, 0)
      love.graphics.draw(self.text, self:centerX(), self:centerY()-self.flashRadius)
      love.graphics.setColor(255, 255, 255)
    else
      love.graphics.draw(self.image, self.body:getX(), self.body:getY(), 0, scale, scale)
    end
  end
end

function Eggplant:startFlash()
  local flashFrom = 0*scale
  local flashTo = 16*scale
  self.flashRadius = flashFrom
  self.flashTween = tween.new(0.45, self, {flashRadius=flashTo}, "outQuart")
end

function Eggplant:onCollisionBegin(other)
  if usingFlash then
    self:startFlash()
  else
    self:destroy()
  end
end

function Eggplant:destroy()
  EggplantManager.remove(self)
  self.body:destroy()
  self.active = false
end
