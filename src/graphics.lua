local Class = require 'lib/hump/class'
local anim8 = require 'lib/anim8/anim8'
local animations = {}

local AnimationSet = Class{function(self, image, animations)
  self.image = image
  self.animations = animations
  self.currentAnimation = nil
end}

function AnimationSet:tostring()
  local status, frame
  if self.currentAnimation then
    if self.currentAnimation.status then
      status = self.currentAnimation.status
    else
      status = 'nil'
    end
    if self.currentAnimation.frame then
      frame = self.currentAnimation.frame
    else
      frame = 'nil'
    end
  else
    status = 'nil'
    frame = 'nil'
  end
  return string.format("status: %s, frame: %s", status, frame)
end

function AnimationSet:getAnimation(name)
  return self.animations[name]
end

function AnimationSet:setAnimation(animation)
  animation:gotoFrame(1)
  self.currentAnimation = animation
end

function AnimationSet:update(dt, sprite)
  if self.currentAnimation then
    self.currentAnimation:update(dt)
  end
end
function AnimationSet:draw(sprite)
  if self.currentAnimation then
    self.currentAnimation:draw(self.image, sprite.pos.x, sprite.pos.y, 0, sprite.pos.dir, 1, sprite.dim.offsetX, sprite.dim.offsetY)
  end
end
function AnimationSet:isFinished()
  return self.currentAnimation and self.currentAnimation.status == 'finished'
end

function load()
  local player = love.graphics.newImage('maps/tilesets/nadira.png')
  local g = anim8.newGrid(64, 64, player:getWidth(), player:getHeight())
  animations.Player = AnimationSet(player, {
    idleN = anim8.newAnimation(g(1,1), 0.1),
    idleW = anim8.newAnimation(g(1,2), 0.1),
    idleS = anim8.newAnimation(g(1,3), 0.1),
    idleE = anim8.newAnimation(g(1,4), 0.1),
    walkingN = anim8.newAnimation(g('2-9',1), 0.1),
    walkingW = anim8.newAnimation(g('2-9',2), 0.1),
    walkingS = anim8.newAnimation(g('2-9',3), 0.1),
    walkingE = anim8.newAnimation(g('2-9',4), 0.1),
    castingN = anim8.newAnimation(g('1-7',5), 0.1),
    castingW = anim8.newAnimation(g('1-7',6), 0.1),
    castingS = anim8.newAnimation(g('1-7',7), 0.1),
    castingE = anim8.newAnimation(g('1-7',8), 0.8, {0.8, 0.8, 0.8, 0.8, 0.8, 1.6, 0.8}),
    })

  local slime = love.graphics.newImage('maps/tilesets/slime.png')
  local g = anim8.newGrid(32, 32, slime:getWidth(), slime:getHeight())
  animations.Slime = AnimationSet(slime, {
    idleN = anim8.newAnimation(g(1,1), 0.1),
    idleW = anim8.newAnimation(g(1,2), 0.1),
    idleS = anim8.newAnimation(g(1,3), 0.1),
    idleE = anim8.newAnimation(g(1,4), 0.1),
    walkingN = anim8.newAnimation(g('1-3',1), 0.1),
    walkingW = anim8.newAnimation(g('1-3',2), 0.1),
    walkingS = anim8.newAnimation(g('1-3',3), 0.1),
    walkingE = anim8.newAnimation(g('1-3',4), 0.1),
    })
end

return {
  load = load,
  animations = animations,
}
