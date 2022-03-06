-- lua module for map and mapgen

local tile = require("scripts/tile")
local dirs = require("scripts/dirs")

local map = {}

function map:init(w, h, t)
  self.w = w
  self.h = h
  self.map = {}
  if t == nil then
    t = tile.none
  end
  for i = 0, w*h-1 do
    self.map[i] = t
  end
end

function map:new(w, h, t)
  local m = {}
  setmetatable(m, self)
  self.__index = self
  if w ~= nil and h ~= nil then
    self:init(w, h, t)
  end
  return m
end

function map:print()
  --print(self.w .. " " .. self.h)
  for i = 0, self.w*self.h-1 do
    if self.map[i] == tile.floor then
      io.write('.')
    elseif self.map[i] == tile.path then
      io.write('-')
    elseif self.map[i] == tile.closeddoor then
      io.write('+')
    elseif self.map[i] == tile.wall then
      io.write('#')
    elseif self.map[i] == tile.upstairs then
      io.write('<')
    elseif self.map[i] == tile.downstairs then
      io.write('>');
    else
      io.write(' ')
    end

    if (i+1)%self.w == 0 then
      print()
    end
  end
end

function map:set_tile(x, y, t)
  if y < 0 or x < 0 or x >= self.w or y >= self.h then
    return
  end

  self.map[y*self.w+x] = t
end

function map:get_tile(x, y)
  if y < 0 or x < 0 or x >= self.w or y >= self.h then
    return tile.out
  end

  return self.map[y*self.w+x]
end

function map:generate_heatmap(drs)
  local stuck = false
  local i = 0

  while not stuck do
    i = i + 1
    stuck = true

    for j = 0, self.w*self.h-1 do
      if self.map[j] == i then
        stuck = false

        for k, d in ipairs(drs) do
          local x = j%self.w + d.x
          local y = math.floor(j/self.w) + d.y
          if self:get_tile(x, y) == 0 then
            self:set_tile(x, y, i+1)
          end
        end

      end
    end

  end

end

function map:addfov(mp, x, y, r)
  local a = 0
  while a <= math.pi*2 do
    a = a + 0.1

    for m = 0, r do
      local tx = math.floor(x+math.cos(a)*m+0.5)
      local ty = math.floor(y+math.sin(a)*m+0.5)
      self:set_tile(tx, ty, tile.visible)

      if tile.blocksvision(mp:get_tile(tx, ty)) then
        break
      end
    end
  end
end

function map:clear_visible()
  for i = 0, self.w*self.h-1 do
    if self.map[i] == tile.visible then
      self.map[i] = tile.known
    end
  end
end

function map:generate_dungeon(depth)
  if depth >= 2 then
    self:init(60+math.random(30), 25+math.random(20), tile.none)
  else
    self:init(30+math.random(20), 20+math.random(10), tile.none)
  end

  local rn = 4
  if depth >= 2 then
    rn = 5+math.random(3)
  elseif depth >= 4 then
    rn = 8+math.random(6)
  end

  local fail = 0
  local rooms = {}

  -- rooms
  ::retry::
  for ri = 1, rn do
    ::begin::
    local w, h = 2+5+math.random(6), 2+3+math.random(4)
    local rx, ry = 1+math.random(self.w-w-2), 1+math.random(self.h-h-2)
    local blocked = false

    for x = rx-1, rx+w do
      for y = ry-1, ry+h do
        if self.map[y*self.w+x] ~= tile.none then
          fail = fail + 1

          if fail > 100 then
            self:init(self.w, self.h, tile.none)
            fail = 0
            goto retry
          end

          goto begin
        end

      end
    end

    for x = rx, rx+w-1 do
      for y = ry, ry+h-1 do
        if x == rx+math.floor(w/2) or y == ry+math.floor(h/2) then
          self:set_tile(x, y, tile.none)
        else
          self:set_tile(x, y, tile.wall)
        end
      end
    end

    for x = rx+1, rx+w-2 do
      for y = ry+1, ry+h-2 do
        self:set_tile(x, y, tile.floor)
      end
    end

    rooms[ri] = {x = rx+math.floor(w/2), y = ry+math.floor(h/2)}
  end

  -- paths
  for ri = 2, rn do
    local hmap = map:new(self.w, self.h)

    for i = 0, self.w*self.h-1 do
      if self.map[i] == tile.wall then
        hmap.map[i] = -1
      else
        hmap.map[i] = 0
      end
    end

    hmap:set_tile(rooms[ri].x, rooms[ri].y, 1)
    hmap:generate_heatmap(dirs.dirs4)

    local x, y = rooms[ri-1].x, rooms[ri-1].y
    local tt = hmap:get_tile(x, y)

    while x ~= rooms[ri].x or y ~= rooms[ri].y do
      tt = tt - 1
      local pmt = self:get_tile(x, y)
      local px, py = x, y

      for k, d in ipairs(dirs.dirs4) do
        local tx, ty = x+d.x, y+d.y
        if hmap:get_tile(tx, ty) == tt then
          x = tx
          y = ty
          break
        end
      end

      if self:get_tile(x, y) == tile.floor and pmt == tile.path then
        self:set_tile(px, py, tile.closeddoor)
      elseif self:get_tile(x, y) == tile.none and pmt == tile.floor then
        self:set_tile(x, y, tile.closeddoor)
      elseif self:get_tile(x, y) == tile.none then
        self:set_tile(x, y, tile.path)
      end

      --if tt < 1 then break end
    end

  end

  -- add walls
  for i = 0, self.w*self.h-1 do
    if self.map[i] == tile.none then
      local adj = false
      for j, d in ipairs(dirs.dirs8) do
        local t = self:get_tile(i%self.w+d.x, math.floor(i/self.w)+d.y)
        if t ~= tile.out and t ~= tile.wall and t ~= tile.none then
          adj = true
        end
      end

      if adj then
        self.map[i] = tile.wall
      end
    end
  end

  -- entrance + exit
  self:set_tile(rooms[1].x, rooms[1].y, tile.upstairs)
  self:set_tile(rooms[rn].x, rooms[rn].y, tile.downstairs)

end

function map:spread(t, dtiles, n)
  for i = 1, n do
    for j = 0, self.w*self.h-1 do
      if self.map[j] == t then
        local d = dirs.dirs4[math.random(4)]
        local x, y = j%self.w+d.x, math.floor(j/self.w)+d.y
        local ct = self:get_tile(x, y)

        local blocked = true
        for l, dt in ipairs(dtiles) do
          if ct == dt then
            blocked = false
            break
          end
        end

        if not blocked then
          self.map[y*self.w+x] = tile.out
        end
      end
    end

    for j = 0, self.w*self.h-1 do
      if self.map[j] == tile.out then
        self.map[j] = t
      end
    end
  end
end

function map:expand(t, dtiles, n)
  for i = 1, n do

    for j = 0, self.w*self.h-1 do
      if self.map[j] == t then
        for k, d in ipairs(dirs.dirs4) do
          local x, y = j%self.w+d.x, math.floor(j/self.w)+d.y
          local ct = self:get_tile(x, y)

          local blocked = true
          for l, dt in ipairs(dtiles) do
            if ct == dt then
              blocked = false
              break
            end
          end

          if not blocked then
            self.map[y*self.w+x] = tile.out
          end
        end
      end
    end

    for j = 0, self.w*self.h-1 do
      if self.map[j] == tile.out then
        self.map[j] = t
      end
    end

  end
end

function map:generate_overmap()
  self:init(40+math.random(15), 20+math.random(10), tile.water)

  for i = 1, 3 do
    local x = math.floor(self.w*0.4) + math.random(math.floor(self.w*0.2))
    local y = math.floor(self.h*0.4) + math.random(math.floor(self.h*0.2))
    self.map[y*self.w+x] = tile.grass
  end

  self:spread(tile.grass, {tile.water}, 10)
  self:expand(tile.grass, {tile.water}, 2)

  for i = 1, 50 do
    local x = math.floor(self.w*0.2) + math.random(math.floor(self.w*0.6))
    local y = math.floor(self.h*0.2) + math.random(math.floor(self.h*0.6))
    if self.map[y*self.w+x] == tile.grass then
      self.map[y*self.w+x] = tile.tree
    end
  end

  for i = 1, 23 do
    local x = math.floor(self.w*0.2) + math.random(math.floor(self.w*0.6))
    local y = math.floor(self.h*0.2) + math.random(math.floor(self.h*0.6))
    if self.map[y*self.w+x] == tile.grass then
      self.map[y*self.w+x] = tile.mountain
    end
  end

  self:spread(tile.mountain, {tile.water, tile.grass, tile.tree}, 3)
  self:expand(tile.mountain, {tile.grass}, 1)

  -- place key locations

  self.map[math.floor(self.h/2)*self.w+math.floor(self.w/2)] = tile.dungeon

  for i = math.floor(self.h*0.3)*self.w, math.floor(self.w*self.h/2) do
    if self.map[i] == tile.grass then
      self.map[i] = tile.town
      break
    end
  end

  for i = self.w*math.floor(self.h*0.7)-1,
      math.floor(self.w*self.h/2), -1 do
    if self.map[i] == tile.grass then
      self.map[i] = tile.town
      break
    end
  end

end

return map
