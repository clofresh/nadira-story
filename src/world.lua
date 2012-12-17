local ATL = require("lib/Advanced-Tiled-Loader").Loader
local Camera = require 'lib/hump/camera'
local HC = require 'lib/HardonCollider'
local sprite = require('src/sprite')

ATL.path = "maps/"
local World = Class{function(self, map)
  self.cam = Camera.new(980, 1260, 1, 0)
  self.collider = HC(100, function(dt, shapeA, shapeB, mtvX, mtvY)
    self:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  end)
  self.gravity = 300
  self.focus = nil
  self.turn = 1
  self.keyInputEnabled = true
  self.shapes = {}
  self._keysPressed = {}

  self:setMap(map)
end}

function World.fromTmx(map)
  return World(ATL.load(map..".tmx"))
end

function World:setMap(map)
  -- Set the background image
  if map.properties.background then
    self:setBackground(map.properties.background)
  end
  map.drawObjects = false
  if map.properties.debugMode == 1 then
    debugMode = true
  else
    debugMode = false
  end

  -- Instantiate the entrances
  local entrancesLayer = map("entrances")
  self.entrances = {}
  for i, obj in pairs(entrancesLayer.objects) do
    self.entrances[obj.name] = obj
  end

  -- Instantiate the exits
  local exitsLayer = map("exits")
  self.exitsByName = {}
  self.exitsByTile = {}
  for i, obj in pairs(exitsLayer.objects) do
    self.exitsByName[obj.name] = {
      name = obj.name,
      map = obj.properties.map,
      entrance = obj.properties.entrance,
    }
    -- Build up a spatial hash of exits indexed by tile number
    for i = obj.y, obj.y + obj.height - 1, map.tileHeight do
      local row = math.floor(i / map.tileHeight)
      for j = obj.x, obj.x + obj.width - 1, map.tileWidth do
        local col = math.floor(j / map.tileWidth)
        local tileNum = row * map.width + col
        self.exitsByTile[tileNum] = obj.name
        util.log("Exit %s at tile %d", obj.name, tileNum)
      end
    end

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
      spr:update(dt, self)
    end
  end

  -- sprite draw callback
  spriteLayer.draw = function(layer)
    for name, spr in pairs(self.sprites) do
      spr:draw()
    end
  end
  self.map = map
end

function World:register(spr)
  local shape = spr:initShape(self.collider)
  self.sprites[spr.id] = spr
  self.shapes[shape] = spr.id
end

function World:unregister(spr)
  self.shapes[spr.shape] = nil
  self.collider:remove(spr.shape)
  self.sprites[spr.id] = nil
end

function World:unregisterAll()
  for key, spr in pairs(self.sprites) do
    self:unregister(spr)
  end
end

function World:setBackground(background)
  self.background = love.graphics.newImage(background)
end

function World:clearBackground()
  self.background = nil
end

function World:getExit(tileNum)
  local exitName = self.exitsByTile[tileNum]
  if exitName then
    return self.exitsByName[exitName]
  else
    return nil
  end
end

function World:clearExits()
  self.exitsByName = nil
  self.exitsByTile = nil
end

function World:getEntrance(entranceName)
  return self.entrances[entranceName]
end

function World:clearEntrances()
  self.entrances = nil
end

function World:changeMap(mapName)
  self:unregisterAll()
  self:clearBackground()
  self:clearExits()
  self:clearEntrances()
  local newMap = ATL.load(mapName .. ".tmx")
  self:setMap(newMap)
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
  self.collider:update(dt)
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
  love.graphics.print(string.format("Cam: (%f, %f)", self.cam.x, self.cam.y), 1, 15)
  if self.focus then
    local tiles = ""
    for i, tileNum in pairs(self.focus:currentTileNums(self)) do
      tiles = tiles .. tileNum .. " "
    end
    love.graphics.print(string.format("TileNums: %s", tiles), 1, 29)
  end
  self.turn = self.turn + 1
end

function World:focusOn(spr)
  self.focus = spr
end

function World:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  local spriteA, spriteB
  spriteA = self.sprites[self.shapes[shapeA]]
  spriteB = self.sprites[self.shapes[shapeB]]
  spriteA:onCollide(dt, spriteB, mtvX, mtvY, self)
  spriteB:onCollide(dt, spriteA, mtvX, mtvY, self)
end

function World:pressedKey(key)
  if key == "1" then
    util.log("Loading village entrance")
    self:changeMap('village_entrance')
  elseif key == "2" then
    util.log("Loading village")
    self:changeMap('village')
  end
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
