local Action = Class{function(self, duration, toExecute)
  self.duration = duration
  self.elapsed = 0
  self.toExecute = toExecute
end}

function Action:execute(dt, world)
  self.elapsed = self.elapsed + dt
  self:toExecute(dt, world)
end

local Sprite = Class{function(self, name, pos, dir, dim, animationSet)
  self.name = name
  self.pos = pos
  self.dir = dir
  self.dim = dim
  self.animationSet = animationSet
  self:setAnimation('idle')
  self.toDo = {} -- treat as a deque
  self.cooldown = 0
end}

function Sprite:setAnimation(animationType)
  local animationName = animationType..self.dir
  local animation = self.animationSet:getAnimation(animationName)
  if animation and self.animationSet.currentAnimation ~= animation then
    self.animationSet:setAnimation(animation)
  end
end

function Sprite:animationFinished()
  return self.animation and self.animation:isFinished()
end

function Sprite:update(dt, world)
  self:planActions(dt, world)
  self:act(dt, world)
  if self.animationSet then
    self.animationSet:update(dt, self)
  end
end

function Sprite:planActions(dt, world)
end

function Sprite:act(dt, world)
  self.cooldown = self.cooldown - dt
  if self.cooldown < 0 then
    self.cooldown = 0
  end
  if self.cooldown == 0 then
    local action = self.toDo[1]
    if action then
      action:execute(dt, world)
      if action.elapsed > action.duration then
        table.remove(self.toDo, 1)
      end
    else
      self:idle(dt, world)
    end
  end
  local leftToDo = #self.toDo
  -- if leftToDo > 0 then
  --   util.log("%s has %d left to do", self.name, leftToDo)
  -- end
end

function Sprite:move(velocity, duration, world)
  -- FIXME: Update distance to be a displacement vector, instead of a scalar,
  -- and update the pathfinding algorithm to return a list of displacement vectors
  -- instead of NSEW directions.
  local action = Action(duration, function(self, dt)
    -- Compute the ideal step, if there were no obstacles
    local step = dt * velocity

    -- Find an obstacles that might prevent the sprite from taking the
    -- desired step, first on the x axis, then the y axis
    local actualStep
    if step.x ~= 0 then
      self.sprite:setAnimation('walking')
      local tryX = self.sprite.pos + vector(step.x, 0)
      local leadingEdge
      if step.x > 0 then
        leadingEdge = self.sprite.pos + vector(self.sprite.dim.w, 0)
      elseif step.x < 0 then
        leadingEdge = self.sprite.pos
      else
        error("Unexpected value for step.x")
      end
      local intersectedTiles = {}
      local platformLayer = world.map.layers["bg1"]
      local tileX = math.floor(tryX.x / world.map.tileWidth)
      local tileY = math.floor(tryX.y / world.map.tileHeight)
      local tileWidth = math.floor(self.sprite.dim.w / world.map.tileWidth)
      local tileHeight = math.floor(self.sprite.dim.h / world.map.tileHeight)

      local closestObstacle
      for obsTileX, obsTileY, tile in platformLayer:rectangle(tileX, tileY,
                                        tileWidth, tileHeight, false) do
        if tile.properties.obstacle then
          if step.x > 0 then
            obsX = obsTileX * world.map.tileWidth
          elseif step.x < 0 then
            obsX = (obsTileX * world.map.tileWidth) + world.map.tileWidth
          else
            error("Unexpected value for step.x")
          end
          if closestObstacle == nil
            or (step.x > 0 and
                obsX > leadingEdge.x and obsX < closestObstacle.x)
            or (step.x < 0 and
                obsX > closestObstacle.x and obsX < leadingEdge.x) then
            closestObstacle = {x=obsX, tile=tile}
          end
        end
      end
      if closestObstacle then
        util.log("Found x-obstacle at %f (leading edge at : %f)",
          closestObstacle.x, leadingEdge.x)
        if step.x > 0 then
          actualStep = vector(math.min(step.x,
                              closestObstacle.x - leadingEdge.x - 1), step.y)
        elseif step.x < 0 then
          actualStep = vector(-1 * math.min(math.abs(step.x),
                              math.abs(closestObstacle.x - leadingEdge.x)), step.y)
        else
          error("Unexpected value for step.x")
        end
      end
    else
      self.sprite:setAnimation('idle')
    end
    if not actualStep then
      actualStep = step
    end

    if step.y ~= 0 then
      local tryY = self.sprite.pos + vector(0, step.y)
      local leadingEdge
      if step.y > 0 then
        leadingEdge = self.sprite.pos + vector(0, self.sprite.dim.h)
      elseif step.y < 0 then
        leadingEdge = self.sprite.pos
      else
        error("Unexpected value for step.y")
      end
      local intersectedTiles = {}
      local platformLayer = world.map.layers["bg1"]
      local tileX = math.floor(tryY.x / world.map.tileWidth)
      local tileY = math.floor(tryY.y / world.map.tileHeight)
      local tileWidth = math.floor(self.sprite.dim.w / world.map.tileWidth)
      local tileHeight = math.floor(self.sprite.dim.h / world.map.tileHeight)

      local closestObstacle
      for obsTileX, obsTileY, tile in platformLayer:rectangle(tileX, tileY,
                                        tileWidth, tileHeight, false) do
        if tile.properties.obstacle then
          if step.y > 0 then
            obsY = obsTileY * world.map.tileHeight
          elseif step.y < 0 then
            obsY = (obsTileY * world.map.tileHeight) + world.map.tileHeight
          else
            error("Unexpected value for step.y")
          end
          if closestObstacle == nil
            or (step.y > 0 and
                obsY > leadingEdge.y and obsY < closestObstacle.y)
            or (step.y < 0 and
                obsY > closestObstacle.y and obsY < leadingEdge.y) then
            closestObstacle = {y=obsY, tile=tile}
          end
        end
      end
      if closestObstacle then
        util.log("Found y-obstacle at %f (leading edge at : %f)",
          closestObstacle.y, leadingEdge.y)
        if step.y > 0 then
          actualStep = vector(actualStep.x, math.min(step.y,
                        closestObstacle.y - leadingEdge.y - 1))
        elseif step.y < 0 then
          actualStep = vector(actualStep.x, -1 * math.min(math.abs(step.y),
                              math.abs(closestObstacle.y - leadingEdge.y)))
        else
          error("Unexpected value for step.y")
        end
      end
    end

    if math.abs(actualStep.y) < 0.0001 and self.sprite.jumpDuration ~= nil then
      self.sprite.jumpDuration = nil
    end
    if step.x < 0 then
      self.sprite.dir = "W"
    elseif step.x > 0 then
      self.sprite.dir = "E"
    end

    self.sprite.pos = self.sprite.pos + actualStep
  end)
  action.sprite = self
  return action
end

function Sprite:followPath(directions)
  for i, delta in pairs(directions) do
    table.insert(self.toDo, self:move(delta))
  end
end

function Sprite:idle(dt, world)
  self:setAnimation('idle')
end

function Sprite:draw()
  if debugMode then
    love.graphics.rectangle('fill', self.pos.x, self.pos.y, self.dim.w, self.dim.h)
  end
  if self.animationSet then
    self.animationSet:draw(self)
  end
end

function Sprite:onCollide(dt, otherSprite, mtvX, mtvY)
end

function Sprite:applyDamage(attacker, amount, mtvX, mtvY)
  self.pos:move(mtvX, mtvY)
end

function Sprite:tostring()
  return string.format("%s (%s; %s)", self.name, tostring(self.pos),
    self.dim:tostring())
end


-- Nadira
local Nadira = Class{inherits=Sprite, function(self, name, pos, dir, dim, animationSet)
  Sprite.construct(self, name, pos, dir, dim, animationSet)
  self.velocity = 110
end}


-- Player
local Player = Class{inherits=Sprite, function(self, name, pos, dir, dim, animationSet)
  Sprite.construct(self, name, pos, dir, dim, animationSet)
  self.walkVelocity = 200
  self.jumpVelocity = -400
  self.jumpDuration = nil
  self.jumpMaxDuration = .25
end}

function Player:onCollide(dt, otherSprite, mtvX, mtvY)
  if otherSprite.properties and otherSprite.properties.obstruction then
    self.pos:move(mtvX, mtvY)
  end
end

function Player:planActions(dt, world)
  local keysPressed = world:keysPressed()
  local direction = ""

  -- Don't let the actions queue get too long
  if #self.toDo > 20 then
    return
  end

  -- if keysPressed["w"] then
  --   direction = direction .. "N"
  -- elseif keysPressed["s"] then
  --   direction = direction .. "S"
  -- end
  if keysPressed["a"] then
    direction = direction .. "W"
  elseif keysPressed["d"] then
    direction = direction .. "E"
  end

  local vx = 0
  local vy = 300 -- gravity


  if keysPressed[" "] and self.jumpDuration == nil then
    -- Starting a jump
    self.jumpDuration = 0
    vy = self.jumpVelocity
  elseif keysPressed[" "] and self.jumpDuration ~= nil
    and self.jumpDuration < self.jumpMaxDuration then
    -- Continuing a jump, if there's any jumpDuration left
    self.jumpDuration = self.jumpDuration + dt
    vy = self.jumpVelocity
  elseif not keysPressed[" "] and self.jumpDuration ~= nil then
    -- After starting a jump and letting go of the jump button,
    -- don't let you jump more
    self.jumpDuration = self.jumpMaxDuration
  end

  if direction ~= "" then
    if     direction == "E"  then vx =  self.walkVelocity
    elseif direction == "W"  then vx = -self.walkVelocity
    end
  end
  local velocity = vector(vx, vy)
  table.insert(self.toDo, self:move(velocity, .01, world))
end




local exports = {
  Sprite     = Sprite,
  Player     = Player,
  Nadira     = Nadira,
}

function fromTmx(obj)
  local cls = exports[obj.type]
  util.log(obj.name)
  local s = cls(
    obj.name,
    vector(obj.x, obj.y),
    "E",
    util.Dimensions(obj.width, obj.height),
    graphics.animations[obj.name]
  )
  util.log("Loaded %s", s:tostring())
  return s
end

exports.fromTmx = fromTmx
return exports

