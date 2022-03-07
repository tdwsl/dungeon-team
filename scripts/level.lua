-- handle multiple levels

local actor = require("scripts/actor")
local map = require("scripts/map")
local item = require("scripts/item")
local tile = require("scripts/tile")

local level = {}

function level:exit()
  local i = 1
  while i <= #self.party do
    if self.party[i].hp <= 0 then
      self.party[i] = self.party[#self.party]
      self.party[#self.party] = nil
      i = i - 1
    end
    i = i + 1
  end

  for i, m in ipairs(self.party) do
    for j, a in ipairs(self.actors) do
      if a == m then
        self.actors[j] = self.actors[#self.actors]
        self.actors[#self.actors] = nil
        break
      end
    end
  end

  actor.actors = {}
end

function level:actor_at(x, y)
  for i, a in ipairs(self.actors) do
    if a.x == x and a.y == y then
      return a
    end
  end

  return nil
end

function level:freexy()
  while true do
    local x = math.random(self.map.w)-1
    local y = math.random(self.map.h)-1

    local t = self.map:get_tile(x, y)

    if (not tile.blocks(t)) and t ~= tile.upstairs then
      if not self:actor_at(x, y) then
        return x, y
      end
    end
  end
end

function level:scatter_actors(type, lvl, num)
  for i = 1, num do
    local a = actor:new(type, lvl)
    a.x, a.y = self:freexy()
    self.actors[#self.actors+1] = a
  end
end

function level:scatter_items(type, lvl, num)
  for i = 1, num do
    local it = item:new(type, lvl)
    it.x, it.y = self:freexy()
    self.items[#self.items+1] = it
  end
end

function level:init()
  self.fov = map:new(self.map.w, self.map.h, tile.unknown)
  self.actors = {}
  self.items = {}

  -- scatter enemies and items
  if self.depth == 0 then
    actor.scatter(actor.townsperson, 1, 6 + math.random(8))
  elseif self.depth > 0 then
    -- enemies
    if self.depth < 3 then
      self:scatter_actors(actor.slime, self.depth, 2 + math.random(3))
      self:scatter_actors(actor.skeleton, self.depth, math.random(3))
    elseif self.level < 8 then
      self:scatter_actors(actor.slime, self.depth, math.random(3))
      self:scatter_actors(actor.skeleton, self.depth, 4 + math.random(3))
    else
      actor.scatter(actor.skeleton, self.depth, 5 + math.random(4))
    end
    -- items
    self:scatter_items(item.longsword, self.depth, math.random(self.depth+1)-1)
    self:scatter_items(item.shortsword, self.depth, math.random(self.depth+1)-1)
    self:scatter_items(item.arrow, self.depth, math.random(4*self.depth+1)-1)
  end

  self.remembered = true
end

function level:enter(party)
  self.party = party

  if not self.generated then
    self:generate()
  end
  if not self.remembered then
    self:init()
  end

  for i, a in ipairs(self.party) do
    self.actors[#self.actors+1] = a
  end

  local entrance = {x=0, y=0}
  for i = 1, self.map.w*self.map.h-1 do
    if self.map.map[i] == tile.upstairs then
      entrance = {x=i%self.map.w, y=math.floor(i/self.map.w)}
      break
    end
  end

  for i, a in ipairs(self.party) do
    if self:actor_at(entrance.x, entrance.y) then
      a.x, a.y = entrance.x, entrance.y
    else
      for j = 0, 3*3-1 do
        local x, y = entrance.x-1+j%3, entrance.y-1+math.floor(j/3)
        if not tile.blocks(self.map:get_tile(x, y)) then
          if not self:actor_at(x, y) then
            a.x, a.y = x, y
            break
          end
        end
      end
    end
  end

  self:update_fov()

  actor.actors = self.actors
  actor.map = self.map
end

function level:new(depth)
  local l = {}

  l.depth = depth
  l.generated = false
  l.remembered = false

  setmetatable(l, self)
  self.__index = self

  return l
end

function level:generate()
  self.map = map:new()

  if self.depth == -1 then
    self.map:generate_overworld()
  elseif self.depth == 0 then
    self.map:generate_town()
  else
    self.map:generate_dungeon(self.depth)
  end

  self.generated = true
  self.remembered = false
end

function level:forget()
  if not self.remembered then
    return
  end

  self.fov = nil
  self.items = {}
  self.actors = {}
  self.remembered = false
end

function level:draw()
  engine.draw_map(self.map, self.fov)

  for i, a in ipairs(self.actors) do
    if a.hp <= 0 then
      engine.draw_actor(a)
    end
  end

  for i, it in ipairs(self.items) do
    engine.draw_item(it)
  end

  for i, a in ipairs(self.actors) do
    if a.hp > 0 then
      engine.draw_actor(a)
    end
  end
end

function level:items_at(x, y)
  local items = {}
  for i, it in ipairs(self.items) do
    if it.x == x and it.y == y then
      items[#items+1] = it
    end
  end

  return items
end

function level:tile_description(x, y)
  local t = self.map:get_tile(x, y)
  local f = self.fov:get_tile(x, y)
  if f == tile.unknown then
    t = tile.none
  end
  local lines = {tile.description(t)}

  if f ~= tile.visible then
    return lines
  end

  local a = self:actor_at(x, y)
  if a then
    lines[#lines+1] = a:brief_description()
  end

  local itemdesc = {}
  for i, it in ipairs(self.items) do
    if it.x == x and it.y == y then
      itemdesc[#itemdesc+1] = it:brief_description()
    end
  end

  if #itemdesc > 0 then
    lines[#lines+1] = "Items here:"
    for i, d in ipairs(itemdesc) do
      lines[#lines+1] = d
    end
  end

  return lines
end

function level:update_fov()
  self.fov:clear_visible()
  for i, a in ipairs(self.actors) do
    if a.ally and a.hp > 0 then
      self.fov:reveal_fov(self.map, a.x, a.y, 5)
    end
  end
end

function level:update()
  for i, a in ipairs(self.actors) do
    a:update()
  end
  self:update_fov()

  -- check for dead party members
  local i = 1
  while i <= #self.party do
    if self.party[i].hp <= 0 then
      self.party[i] = self.party[#self.party]
      self.party[#self.party] = nil
      i = i - 1
    end
    i = i + 1
  end
end

return level
