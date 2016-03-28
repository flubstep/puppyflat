-- Class TiledScroller
-- Generic display for a tiled infinite scrolling set of images

TiledScroller = {}

function TiledScroller:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.tiles = {}
  o.width = o.image:getWidth()

  for i=1,o.count do
    local tile = {}
    tile.x = o.startX + (o.width * scale * (i-1))
    tile.y = o.startY
    o.tiles[i] = tile
  end
  return o
end

function TiledScroller:update(dt)
  for _, tile in ipairs(self.tiles) do
    tile.x = tile.x - self.speed * dt
    if tile.x < (-2*self.width*scale) then
      tile.x = tile.x + (self.width * self.count * scale)
    end
  end
end

function TiledScroller:draw()
  for _, tile in ipairs(self.tiles) do
    love.graphics.draw(self.image, tile.x, tile.y, 0, scale, scale)
  end
end