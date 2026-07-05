-- Singleton EggplantManager
--
-- Eggplants spawn in volleys placed along a jump arc: pick a jump
-- power the player can reach, then lay the eggplants on the parabola
-- the cat traces (relative to the scrolling world) when jumping with
-- exactly that power. Since every eggplant scrolls left at the same
-- speed, the arc keeps its shape, and one well-timed jump grabs the
-- whole volley.

local usingFlash = true

-- fraction of the jump's flight time covered by the first and last
-- eggplant of a volley (endpoints sit at ground level, so inset a bit)
local arcStart = 0.12
local arcEnd = 0.88
-- keep arcs below the max jump so a full-power jump clears the apex
local arcMaxPower = 0.95
-- arcs with less curve than this are trivial hops; reroll them
local minArcLength = 240
-- seconds of breathing room between one arc leaving and the next arriving
local gapMin = 1.0
local gapMax = 2.0

EggplantManager = {}

function EggplantManager.create()
  EggplantManager.index = 1
  EggplantManager.eggplants = {}
  EggplantManager.arcs = {}
  EggplantManager.clock = 0
  EggplantManager.spawnTimer = 1
  EggplantManager.image = love.graphics.newImage("assets/eggplant.png")
end

function EggplantManager.update(dt)
  EggplantManager.clock = EggplantManager.clock + dt

  EggplantManager.spawnTimer = EggplantManager.spawnTimer - dt
  if EggplantManager.spawnTimer <= 0 then
    local flightTime = EggplantManager.spawnArc()
    EggplantManager.spawnTimer =
      flightTime + gapMin + (gapMax - gapMin)*love.math.random()
  end

  -- drop arc records once their jump moment has passed
  for i = #EggplantManager.arcs, 1, -1 do
    if EggplantManager.arcs[i].jumpAt < EggplantManager.clock - 1 then
      table.remove(EggplantManager.arcs, i)
    end
  end

  for _, eggplant in pairs(EggplantManager.eggplants) do
    eggplant:update(dt)
  end
end

-- Times along a jump parabola that divide the curve between t0 and t1
-- into segments of equal absolute (euclidean arc) length, so eggplants
-- look evenly strung along the arc instead of bunching at the apex.
-- The curve is (objectSpeed*t, y0 - v*t + g*t^2/2); integrate its speed
-- sqrt(objectSpeed^2 + (v - g*t)^2) numerically, then invert.
local function equalSpacedTimes(v, g, t0, t1, count)
  local steps = 200
  local dt = (t1 - t0)/steps
  local lengths = {[0]=0}
  for i = 1, steps do
    local tMid = t0 + (i - 0.5)*dt
    local dy = v - g*tMid
    lengths[i] = lengths[i - 1] + math.sqrt(objectSpeed^2 + dy^2)*dt
  end

  local times = {}
  local j = 1
  for i = 1, count do
    local target = lengths[steps]*(i - 1)/(count - 1)
    while j < steps and lengths[j] < target do j = j + 1 end
    local segment = lengths[j] - lengths[j - 1]
    local frac = segment > 0 and (target - lengths[j - 1])/segment or 0
    times[i] = t0 + (j - 1 + frac)*dt
  end
  return times, lengths[steps]
end

-- Spawn a volley of eggplants along the parabola of a jump with
-- velocity v: relative to the scrolling world the cat moves right at
-- objectSpeed, so a single jump of that power (timed to the arc's
-- takeoff point) sweeps the whole volley. Returns the arc's flight time.
function EggplantManager.spawnArc()
  local g = Puppycat.jumpGravity
  local minV = Puppycat.minJumpVelocity
  local maxV = Puppycat.maxJumpVelocity * arcMaxPower

  local v, flightTime, arcLength
  repeat
    v = minV + (maxV - minV)*love.math.random()
    flightTime = 2*v/g
    _, arcLength = equalSpacedTimes(
      v, g, arcStart*flightTime, arcEnd*flightTime, 2)
  until arcLength >= minArcLength
  -- more eggplants on longer arcs: roughly one per 60px of curve
  local count = math.min(12, math.max(5, math.floor(arcLength/60)))
  local times = equalSpacedTimes(
    v, g, arcStart*flightTime, arcEnd*flightTime, count)

  local imageWidth = EggplantManager.image:getWidth()*scale
  local imageHeight = EggplantManager.image:getHeight()*scale
  local spawnX = love.graphics.getWidth()
  local originX, originY = puppycat:getJumpOrigin()

  -- shared by the volley's eggplants to detect a full sweep for combos
  local volley = {total=count, collected=0}

  for i = 1, count do
    local t = times[i]

    local id = "id"..EggplantManager.index
    EggplantManager.index = EggplantManager.index + 1

    EggplantManager.eggplants[id] = Eggplant:new{
      id=id,
      -- body position is the top-left corner; center the sprite on the arc
      x=spawnX + objectSpeed*t,
      y=originY - v*t + g*t*t/2 - imageHeight/2,
      speed=objectSpeed,
      volley=volley
    }
  end

  -- when the arc's takeoff point scrolls over the cat, a jump of power v
  -- collects the volley; recorded so tools (e.g. the playtest autopilot)
  -- can time a perfect jump
  table.insert(EggplantManager.arcs, {
    v=v,
    jumpAt=EggplantManager.clock + (spawnX + imageWidth/2 - originX)/objectSpeed
  })

  return flightTime
end

function EggplantManager.start()
  EggplantManager.clock = 0
  EggplantManager.spawnTimer = 1
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
    if not self.collected then
      gameCombo:breakStreak()
    end
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
      love.graphics.draw(self.text,
        self:centerX(), self:centerY()-self.flashRadius, 0, 2, 2,
        self.text:getWidth()/2, self.text:getHeight()/2)
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
  if self.collected then
    return
  end
  self.collected = true

  self.volley.collected = self.volley.collected + 1
  if self.volley.collected == self.volley.total then
    gameCombo:fullSweep()
  end

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
