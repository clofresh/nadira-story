vector = require 'lib/hump/vector'


local Dimensions = Class{function(self, w, h)
  self.w = w
  self.h = h
end}

function Dimensions:tostring()
  return string.format("w: %d, h: %d", self.w, self.h)
end

local Queue = Class{function(self, initial)
    if initial == nil then
        self.q = {}
    else
        self.q = initial
    end
end}

function Queue:push(item)
    table.insert(self.q, item)
end

function Queue:pop()
    return table.remove(self.q, 1)
end

function Queue:extend(items)
  for k, val in pairs(items) do
    table.insert(self.q, item)
  end
end

function Queue:__tostring()
    local output = ''
    for i, val in ipairs(self.q) do
        output = output .. tostring(val)
    end
    return output
end

function Queue:copy()
    local q = {}
    for k, val in pairs(self.q) do
        q[k] = val
    end
    return Queue(q)
end

function log(msg, ...)
  print(os.date("%Y-%m-%dT%I:%M:%S%p") .. " - " .. string.format(msg, ...))
end

function string:split(sSeparator, nMax, bRegexp)
  assert(sSeparator ~= '')
  assert(nMax == nil or nMax >= 1)

  local aRecord = {}

  if self:len() > 0 then
    local bPlain = not bRegexp
    nMax = nMax or -1

    local nField=1 nStart=1
    local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
    while nFirst and nMax ~= 0 do
      aRecord[nField] = self:sub(nStart, nFirst-1)
      nField = nField+1
      nStart = nLast+1
      nFirst,nLast = self:find(sSeparator, nStart, bPlain)
      nMax = nMax-1
    end
    aRecord[nField] = self:sub(nStart)
  end

  return aRecord
end

function getVertices(obj)
  if not obj.width or not obj.height then
    return {vector(obj.x, obj.y)}
  else
    return {
        vector(obj.x,                 obj.y),                   -- nw
        vector(obj.x + obj.width / 2, obj.y),                   -- n
        vector(obj.x + obj.width,     obj.y),                   -- ne
        vector(obj.x + obj.width,     obj.y + obj.height / 2),  -- e
        vector(obj.x + obj.width,     obj.y + obj.height),      -- se
        vector(obj.x + obj.width / 2, obj.y + obj.height),      -- s
        vector(obj.x,                 obj.y + obj.height),      -- sw
        vector(obj.x,                 obj.y + obj.height / 2),  -- w
    }
  end
end

function getCenter(obj)
  if not obj.width or not obj.height then
    return {vector(obj.x, obj.y)}
  else
    return vector(obj.x + obj.width / 2, obj.y + obj.height / 2)
  end
end

function vectorSum(vectors)
  local totalVector = vector(0, 0)
  for i, vec in pairs(vectors) do
    totalVector = totalVector + vec
  end
  return totalVector
end

return {
  Position = Position,
  Dimensions = Dimensions,
  log = log,
  Queue = Queue,
  getVertices = getVertices,
  getCenter = getCenter,
  vectorSum = vectorSum,
}
