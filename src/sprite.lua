local Action = Class{function(self, duration, toExecute)
  self.duration = duration
  self.elapsed = 0
  self.toExecute = toExecute
end}

function Action:execute(dt, world)
  self.elapsed = self.elapsed + dt
  self:toExecute(dt, world)
end

local Sprite = Class{function(self, id, name, pos, dir, dim, animationSet)
  self.id = id
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

function Sprite:initShape(collider)
  self.shape = collider:addRectangle(
    self.pos.x + self.dim.w / 2,
    self.pos.y + self.dim.h / 2,
    self.dim.w, self.dim.h)
  return self.shape
end

function Sprite:update(dt, world)
  self:planActions(dt, world)
  self:act(dt, world)
  self.shape:moveTo(self.pos.x + self.dim.w / 2, self.pos.y + self.dim.h / 2)
  if self.animationSet then
    self.animationSet:update(dt, self)
  end
end

function Sprite:planActions(dt, world)
end

function Sprite:enqueue(action)
  table.insert(self.toDo, action)
end

function Sprite:clearToDo()
  self.toDo = {}
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
    local x1, y1, x2, y2 = self.sprite.shape:bbox()
    if step.x ~= 0 then
      self.sprite:setAnimation('walking')
      local tryX = self.sprite.pos + vector(step.x, 0)
      local leadingEdgeX
      if step.x > 0 then
        leadingEdgeX = x2
      elseif step.x < 0 then
        leadingEdgeX = x1
      else
        error("Unexpected value for step.x")
      end
      local intersectedTiles = {}
      local platformLayer = world.map.layers["bg1"]
      local tileX = math.floor(tryX.x / world.map.tileWidth)
      local tileY = math.floor(tryX.y / world.map.tileHeight)
      local tileWidth = math.floor(self.sprite.dim.w / world.map.tileWidth) + 1
      local tileHeight = math.floor(self.sprite.dim.h / world.map.tileHeight)

      local closestObstacle
      for obsTileX, obsTileY, tile in platformLayer:rectangle(tileX, tileY,
                                        tileWidth, tileHeight, false) do
        if tile.properties.obstacle then
          util.log("Tile %d (%d, %d)", tile.id, obsTileX, obsTileY)
          if step.x > 0 then
            obsX = obsTileX * world.map.tileWidth
          elseif step.x < 0 then
            obsX = (obsTileX * world.map.tileWidth) + world.map.tileWidth
          else
            error("Unexpected value for step.x")
          end
          if closestObstacle == nil
            or (step.x > 0 and
                obsX > leadingEdgeX and obsX < closestObstacle.x)
            or (step.x < 0 and
                obsX > closestObstacle.x and obsX < leadingEdgeX) then
            closestObstacle = {x=obsX, tileX=obsTileX, tile=tile}
          end
        end
      end
      if closestObstacle then
        util.log("Found x-obstacle at %f (leading edge at : %f, tileX is: %f, tile id is: %f)", closestObstacle.x, leadingEdgeX, closestObstacle.tileX, closestObstacle.tile.id)
        if step.x > 0 then
          actualStep = vector(math.min(step.x,
                              closestObstacle.x - leadingEdgeX - 1), step.y)
        elseif step.x < 0 then
          actualStep = vector(-1 * math.min(math.abs(step.x),
                              math.abs(closestObstacle.x - leadingEdgeX)), step.y)
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
      local leadingEdgeY
      if step.y > 0 then
        leadingEdgeY = y2
      elseif step.y < 0 then
        leadingEdgeY = y1
      else
        error("Unexpected value for step.y")
      end
      local intersectedTiles = {}
      local platformLayer = world.map.layers["bg1"]
      local tileX = math.floor(tryY.x / world.map.tileWidth)
      local tileY = math.floor(tryY.y / world.map.tileHeight)
      local tileWidth = math.floor(self.sprite.dim.w / world.map.tileWidth)
      local tileHeight = math.floor(self.sprite.dim.h / world.map.tileHeight) + 1

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
                obsY > leadingEdgeY and obsY < closestObstacle.y)
            or (step.y < 0 and
                obsY > closestObstacle.y and obsY < leadingEdgeY) then
            closestObstacle = {y=obsY, tile=tile}
          end
        end
      end
      if closestObstacle then
        -- util.log("Found y-obstacle at %f (leading edge at : %f)",
        --  closestObstacle.y, leadingEdgeY)
        if step.y > 0 then
          actualStep = vector(actualStep.x, math.min(step.y,
                        closestObstacle.y - leadingEdgeY - 1))
        elseif step.y < 0 then
          actualStep = vector(actualStep.x, -1 * math.min(math.abs(step.y),
                              math.abs(closestObstacle.y - leadingEdgeY)))
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
    self.shape:draw('fill')
  end
  if self.animationSet then
    self.animationSet:draw(self)
  end
end

function Sprite:onCollide(dt, otherSprite, mtvX, mtvY, world)
end

function Sprite:applyDamage(attacker, amount, mtvX, mtvY)
  self.pos:move(mtvX, mtvY)
end

function Sprite:tostring()
  return string.format("%s (%s; %s)", self.name, tostring(self.pos),
    self.dim:tostring())
end


local Slime = Class{inherits=Sprite, function(self, id, name, pos, dir, dim, animationSet)
  Sprite.construct(self, id, name, pos, dir, dim, animationSet)
  self.velocity = 50
end}

function Slime:planActions(dt, world)
  local rand = math.random(1, 3)
  local vx
  local vy = world.gravity
  if rand == 1 then
    vx = self.velocity
  elseif rand == 2 then
    vx = -self.velocity
  end
  self:enqueue(self:move(vector(vx, vy), .5, world))
end

-- Player
local Player = Class{inherits=Sprite, function(self, id, name, pos, dir, dim, animationSet)
  Sprite.construct(self, id, name, pos, dir, dim, animationSet)
  self.walkVelocity = 200
  self.jumpVelocity = -400
  self.jumpDuration = nil
  self.jumpMaxDuration = .125
end}

function Player:onCollide(dt, otherSprite, mtvX, mtvY, world)
  util.log("Player collision")
  self:clearToDo()
  self:enqueue(self:move(vector(mtvX*10, world.gravity), .025, world))
  -- self.pos:move(mtvX, mtvY)
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
  local vy = world.gravity


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
  self:enqueue(self:move(velocity, .01, world))
end




local exports = {
  Sprite = Sprite,
  Player = Player,
  Slime  = Slime,
}

local idSequence = 0
function fromTmx(obj)
  local cls = exports[obj.type]
  idSequence = idSequence + 1
  local width, height
  if obj.properties.width then
    width = obj.properties.width
  else
    width = obj.width
  end
  if obj.properties.height then
    height = obj.properties.height
  else
    height = obj.height
  end

  local s = cls(
    idSequence,
    obj.name,
    vector(obj.x, obj.y),
    "E",
    util.Dimensions(width, height,
      obj.properties.offsetX, obj.properties.offsetY),
    graphics.animations[obj.type]
  )
  util.log("Loaded sprite %d: %s", s.id, s:tostring())
  return s
end

exports.fromTmx = fromTmx
return exports

