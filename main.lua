math.randomseed(1)
debugMode = false

Class = require('lib/hump/class')
util = require('src/util')
graphics = require('src/graphics')

local World = require('src/world').World

local world

function love.load()
  graphics.load()
  world = World.fromTmx('village_entrance.tmx')

  local music = love.audio.newSource("audio/koertes-ccby-birdsongloop16s.ogg")
  music:setLooping(true)
  love.audio.play(music)
end

function love.update(dt)
  world:update(dt)
end

function love.draw()
  world:draw()
end

function love.keypressed(key, unicode)
  world:pressedKey(key)
end

function love.keyreleased(key)
  world:releasedKey(key)
end