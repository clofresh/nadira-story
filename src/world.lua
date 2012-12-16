local ATL = require("lib/Advanced-Tiled-Loader").Loader
local Camera = require 'lib/hump/camera'
local sprite = require('src/sprite')

local World = Class{function(self, map)
  self.map = map
  self.cam = Camera.new(980, 1260, 1, 0)
  self.focus = nil
  self.turn = 1
  self.keyInputEnabled = true
  self._keysPressed = {}

  -- Set the background image
  if map.properties.background then
    self:setBackground(map.properties.background)
  end

  -- Instantiate the sprites
  local spriteLayer = map("sprites")
  self.sprites = {}
  for i, obj in pairs(spriteLayer.objects) do
    local spr = sprite.fromTmx(obj)
    self:register(spr)
    if spr.name == spriteLayer.properties.focus then
      self:focusOn(spr)
    end
  end

  -- sprite update callback
  spriteLayer.update = function(layer, dt)
    for name, spr in pairs(self.sprites) do
      -- table.insert(spr.toDo, spr:move(vector(0, 1), 100, self))
      spr:update(dt, self)
    end
  end

  -- sprite draw callback
  spriteLayer.draw = function(layer)
    local drawOrder = {}
    local i = 1
    for name, spr in pairs(self.sprites) do
      drawOrder[i] = spr
      i = i + 1
    end
    table.sort(drawOrder, function(a, b)
      return a.pos and b.pos and a.pos.y < b.pos.y
    end)
    for i, spr in ipairs(drawOrder) do
      --if spr.tostring then
      --  log("Drawing %s", spr:tostring())
      --end
      spr:draw()
    end
  end

end}

function World.fromTmx(filename)
  return World(ATL.load(filename))
end

function World:register(spr)
  self.sprites[spr.name] = spr
end

function World:unregister(spr)
  self.sprites[spr.name] = nil
end

function World:setBackground(background)
  self.background = love.graphics.newImage(background)
end

function World:update(dt)
  local dx = love.graphics.getWidth()/2
  local dy = love.graphics.getHeight()/2
  self.map:callback("update", dt)
  if self.focus then
    self.cam.x = math.min(math.max(dx, self.focus.pos.x), (self.map.width * self.map.tileWidth) - dx)
    -- self.cam.y = self.focus.pos.y
    self.cam.y = dy
  end
  self.map:setDrawRange(self.cam.x - dx, self.cam.y - dy,
                        self.cam.x + dx, self.cam.y + dy)
end

function World:draw()
  --log("Drawing turn %d", self.turn)
  if self.background then
    love.graphics.draw(self.background)
  end
  self.cam:draw(function()
    self.map:draw()
  end)
  love.graphics.print(string.format("(%f, %f)", self.cam.x, self.cam.y), 1, 1)

  self.turn = self.turn + 1
end

function World:focusOn(spr)
  self.focus = spr
end

function World:pressedKey(key)
  if self.keyInputEnabled then
    self._keysPressed[key] = true
  end
end

function World:releasedKey(key)
  self._keysPressed[key] = nil
end

function World:keysPressed()
  return self._keysPressed
end

return {
  World = World,
}
