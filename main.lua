-- todo: possibly put this into a global gamespace or something?
world = nil
scale = 2
m = 32
objectSpeed = 10*m
screenWidth = 600
screenHeight = 600

tween = require('vendor/tween')

require('tiledscroller')
require('eggplant')
require('puppycat')
require('gamescore')
require('startmenu')


puppycat = nil
floorTiles = nil
backgroundTiles = nil
gameScore = nil
startMenu = nil
gameStarted = false
backgroundMusic = nil

function love.load()
  love.window.setTitle("Puppyflat")

  -- remove anti-aliasing
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setBackgroundColor(255, 255, 255)
  love.physics.setMeter(m)

  -- todo: don't make it a global
  world = love.physics.newWorld(0, 9.81*m, true)

  -- player
  puppycat = Puppycat:new{scale=scale}

  -- generate floor and scrolling tiles
  local floor = love.graphics.newImage("assets/floor.png")
  local floorWidth = love.graphics:getWidth()
  local floorHeight = floor:getHeight()*scale
  local floorY = love.graphics:getHeight() - floorHeight

  floorTiles = TiledScroller:new{
    image=floor,
    count=12,
    startX=0,
    startY=floorY,
    speed=objectSpeed
  }

  -- offset it slightly so that the cat lands slightly on the floor
  floorOffset = 5*scale
  floorBody = love.physics.newBody(world, 0, floorY+floorOffset, "static")
  floorShape = love.physics.newRectangleShape(
    floorWidth/2,
    floorHeight/2,
    floorWidth,
    floorHeight
  )
  floorFixture = love.physics.newFixture(floorBody, floorShape)
  floorFixture:setUserData({tag="Floor"})

  -- parallax scrolling background
  background = love.graphics.newImage("assets/background.png")
  backgroundTiles = TiledScroller:new{
    image=background,
    count=12,
    startX=0,
    startY=0,
    speed=1*m
  }

  -- initialize the singleton
  EggplantManager.create()

  -- initialize score text
  gameScore = GameScore:new{}

  -- initialize start menu
  startMenu = StartMenu:new{active=true}

  -- background music
  -- backgroundMusic = love.audio.newSource("assets/morera_-_i_pray_original_mix.mp3")
  -- backgroundMusic:play()

  -- set the collision callback.
  world:setCallbacks(onContactBegin, onContactEnd)
end


function love.update(dt)
  -- update game objects
  floorTiles:update(dt)
  backgroundTiles:update(dt)
  puppycat:update(dt)
  startMenu:update(dt)
  if gameStarted then
    EggplantManager.update(dt)
  end
  world:update(dt)
end


-- todo: possibly have gameobjects with 'active' prop that
-- determine if they are to be updated with "setActive" or
-- whatever
function love.draw()
  backgroundTiles:draw()
  floorTiles:draw()
  if gameStarted then
    EggplantManager.draw()
    gameScore:draw()
  else
    startMenu:draw()
  end
  puppycat:draw()
end


-- todo: have event listeners for these? doesn't make sense to have
-- it all defined in the global scope
function love.keypressed(key, scancode, isrepeat)
  if key == 'escape' then
    love.event.push('quit')
  end
  if key == "space" and not startMenu.hidden and not gameStarted then
    startGame()
  elseif gameStarted and (key == "space" or key == "up") then
    puppycat:holdJump()
  end
end


function love.keyreleased(key)
  if gameStarted and (key == "space" or key == "up") then
    puppycat:releaseJump()
  end
end


function startGame()
  startMenu.active = false
  gameStarted = true
  EggplantManager.start()
end


function updateSpeed(newSpeed)
  EggplantManager.updateSpeed(newSpeed)
  floorTiles.speed = newSpeed
  objectSpeed = newSpeed
end


function onContactBegin(a, b, coll)
  local aObject = a:getUserData().gameObject
  local bObject = b:getUserData().gameObject

  if not (aObject == nil or aObject.onCollisionBegin == nil) then
    aObject:onCollisionBegin(b)
  end

  if not (bObject == nil or bObject.onCollisionBegin == nil) then
    bObject:onCollisionBegin(a)
  end
end


function onContactEnd(a, b, coll)
  local aObject = a:getUserData().gameObject
  local bObject = b:getUserData().gameObject

  if not (aObject == nil or aObject.onCollisionEnd == nil) then
    aObject:onCollisionEnd(b)
  end

  if not (bObject == nil or bObject.onCollisionEnd == nil) then
    bObject:onCollisionEnd(a)
  end
end
