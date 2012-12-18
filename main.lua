math.randomseed(1)
debugMode = false

Class = require('lib/hump/class')
util = require('src/util')
graphics = require('src/graphics')

local World = require('src/world').World
local sprite = require('src/sprite')

local world, player

function love.load()
  graphics.load()
  world = World.fromTmx('village_entrance')
  local entrance = world.entrances.A
  player = sprite.fromTmx({
    x=entrance.x, y=entrance.y,
    name='player',
    type='Player'
  })
  world:register(player)
  world:focusOn(player)
end

function love.update(dt)
  world:update(dt)
end

function love.draw()
  world:draw()
  love.graphics.print(string.format("Memory: %dKB", math.floor(collectgarbage('count'))), 1, 1)
end

function love.keypressed(key, unicode)
  world:pressedKey(key)
end

function love.keyreleased(key)
  world:releasedKey(key)
end