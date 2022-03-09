-- handle multiple levels

local actor = require("scripts/actor")
local map = require("scripts/map")
local item = require("scripts/item")
local tile = require("scripts/tile")
local log = require("scripts/log")

local level = {}

local specs = {
  { -- level 1
    actors = {
      {type=actor.skeleton, min=0, max=1, level=1},
      {type=actor.slime, min=2, max=3, level=1}
    },
    items = {
      options=1,
      {type=item.arrow, stack=4, num=1},
      {type=item.shortsword, stack=1, num=1, level=1}
    }
  },
  { -- level 2
    actors = {
      {type=actor.skeleton, min=1, max=2, level=1},
      {type=actor.slime, min=2, max=4, level=2}
    },
    items = {
      options=2,
      {type=item.arrow, stack=4, num=2},
      --{type=item.throwing_knives, stack=5, num=1, level=1},
      {type=item.longsword, stack=1, num=1, level=1},
      --{type=item.small_healing_potion, stack=2, num=1}
    }
  },
  { -- level 3
    actors = {
      {type=actor.slime, min=8, max=14, level=4}
    },
    items = {
      options=4,
      {type=item.cloak, stack=1, num=2, level=3},
      {type=item.leather_armor, stack=1, num=1, level=1},
      {type=item.shortsword, stack=1, num=2, level=4},
      {type=item.chainmail, stack=1, num=1, level=2},
      --{type=item.novice_spellcasting, stack=1, num=1},
      {type=item.arrow, stack=6, num=5},
      --{type=item.basic_healing, stack=1, num=1}
    }
  },
  { -- level 4
    actors = {
      {type=actor.slime, min=1, max=3, level=4},
      {type=actor.skeleton, min=1, max=2, level=3}
    },
    items = {
      options=2,
      {type=item.shield, stack=1, num=1, level=3},
      {type=item.arrow, stack=4, num=3},
      {type=item.dagger, stack=1, num=1, level=2},
      {type=item.shortsword, stack=1, num=1, level=3}
    }
  },
  { -- level 5
    actors = {
      {type=actor.slime, min=1, max=3, level=4},
      {type=actor.skeleton, min=1, max=2, level=4},
      {type=actor.orc, min=1, max=1, level=2}
    },
    items = {
      options=2,
      {type=item.arrow, stack=4, num=4},
      --{type=item.basic_offensive_magic, stack=1, num=1},
      {type=item.longsword, stack=1, num=1, level=4}
    }
  },
  { -- level 6
    actors = {
      {type=actor.skeleton, min=1, max=2, level=5},
      {type=actor.orc, min=1, max=2, level=3}
    },
    items = {
      options=2,
      {type=item.arrow, stack=4, num=3},
      --{type=item.throwing_knives, stack=8, num=3, level=3},
      {type=item.shortsword, stack=1, num=2, level=5}
    }
  },
  { -- level 7
    actors = {
      {type=actor.orc, min=5, max=9, level=10}
    },
    items = {
      options=5,
      {type=item.shield, stack=1, num=3, level=5},
      {type=item.arrow, stack=4, num=6},
      {type=item.dagger, stack=1, num=3, level=6},
      {type=item.shortsword, stack=1, num=2, level=8},
      {type=item.bow, stack=1, num=2, level=6},
      --{type=item.healing_potion, stack=2, num=4}
    }
  },
  { -- level 8
    actors = {
      {type=actor.slime, min=1, max=3, level=6},
      {type=actor.skeleton, min=1, max=2, level=8},
      {type=actor.orc, min=1, max=1, level=8}
    },
    items = {
      options=2,
      {type=item.arrow, stack=8, num=5},
      {type=item.basic_offensive_magic, stack=1, num=1},
      {type=item.longsword, stack=1, num=1, level=4},
      --{type=item.healing_potion, stack=1, num=3}
    }
  },
  { -- level 9
    actors = {
      {type=actor.slime, min=3, max=5, level=7},
      {type=actor.skeleton, min=2, max=5, level=10},
      {type=actor.orc, min=2, max=3, level=9}
    },
    items = {
      options=3,
      {type=item.arrow, stack=8, num=5},
      --{type=item.basic_offensive_magic, stack=1, num=1},
      {type=item.longsword, stack=1, num=1, level=6},
      --{type=item.healing_potion, stack=1, num=3},
      --{type=item.novice_spellcasting, stack=2, num=1},
      {type=item.leather_armor, stack=1, num=2, level=8}
    }
  },
  { -- level 10
    actors = {
      {type=actor.slime, min=6, max=5, level=9},
      {type=actor.skeleton, min=4, max=8, level=14},
      {type=actor.orc, min=4, max=6, level=12}
    },
    items = {
      options=5,
      {type=item.arrow, stack=8, num=5},
      --{type=item.basic_offensive_magic, stack=1, num=1},
      {type=item.longsword, stack=1, num=1, level=6},
      --{type=item.healing_potion, stack=1, num=3},
      --{type=item.novice_spellcasting, stack=2, num=1},
      {type=item.leather_armor, stack=1, num=2, level=8},
      {type=item.chainmail, stack=1, num=1, level=10},
      {type=item.shield, stack=1, num=3, level=7}
    }
  },
  { -- level 11 - final level
    actors = {
      {type=actor.slime, min=2, max=2, level=18},
      {type=actor.orc, min=1, max=1, level=20},
      {type=actor.rogue, min=1, max=1, level=20}
    },
    items = {
      options = 1,
      {type=item.amulet_of_yendor, min=1, max=1}
    }
  }
}

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
  lvl = lvl + math.random(2) - 1
  if lvl <= 0 then lvl = 1 end
  for i = 1, num do
    local a = actor:new(type, lvl)
    a.x, a.y = self:freexy()
    self.actors[#self.actors+1] = a
  end
end

function level:scatter_items(type, lvl, ss, num)
  for i = 1, num do
    local x, y = self:freexy()
    for j = 1, ss do
      local it = item:new(type, lvl)
      it.x = x
      it.y = y
      self.items[#self.items+1] = it
    end
  end
end

function level:init()
  self.fov = map:new(self.map.w, self.map.h, tile.unknown)
  self.actors = {}
  self.items = {}

  -- scatter enemies and items
  if self.depth == 0 then
    self:scatter_actors(actor.townsperson, 1, 6 + math.random(8))
  elseif self.depth > 0 then
    -- enemies
    for i, s in ipairs(specs[self.depth].actors) do
      self:scatter_actors(s.type, s.level, math.random(s.min, s.max))
    end

    -- items
    local choices = {}
    for i = 1, specs[self.depth].items.options do
      local ch = math.random(#specs[self.depth].items)
      while true do
        local unique = true
        for j, c in ipairs(choices) do
          if c == ch then
            unique = false
            break
          end
        end
        if unique then break end

        ch = ch + 1
        if ch > #specs[self.depth].items then
          ch = 1
        end
      end

      choices[i] = ch
    end

    for i, c in ipairs(choices) do
      local s = specs[self.depth].items[c]
      self:scatter_items(s.type, s.level, s.stack, s.num)
    end
  end

  self.remembered = true
end

function level:enter(party, x, y)
  self.party = party

  if not self.generated then
    self:generate()
    self:init()
  elseif not self.remembered then
    local items = self.items
    self:init()
    self.items = items
  end

  for i, a in ipairs(self.party) do
    self.actors[#self.actors+1] = a
  end

  local entrance

  if x ~= nil and y ~= nil then
    entrance = {x=x, y=y}
  else
    entrance = {x=0, y=0}
    for i = 1, self.map.w*self.map.h-1 do
      if self.map.map[i] == tile.upstairs then
        entrance = {x=i%self.map.w, y=math.floor(i/self.map.w)}
        break
      end
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
  actor.items = self.items
  actor.fov = self.fov
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
    local the_end
    if self.depth >= 11 then the_end = true end
    self.map:generate_dungeon(self.depth, the_end)
  end

  self.generated = true
  self.remembered = false
end

function level:forget()
  if not self.remembered then
    return
  end

  self.fov = nil
  --self.items = {}
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

  if self.projectile then
    engine.draw_item(self.projectile)
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

  for i, a in ipairs(self.actors) do
    if x == a.x and y == a.y then
      lines[#lines+1] = a:brief_description()
    end
  end

  local items = {}
  for i, it in ipairs(self.items) do
    if it.x == x and it.y == y then
      items[#items+1] = it
    end
  end

  local itemdesc = item.string_list(item.item_list(items))

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
      self.fov:reveal_fov(self.map, a.x, a.y, 8)
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

function level:fire_projectile(shooter, xm, ym, itm, dist)
  if dist == nil then dist = 6 end

  local has = false
  for i, it in ipairs(shooter.inventory) do
    if it.base == itm.base and it.level == itm.level then
      shooter.inventory[i] = shooter.inventory[#shooter.inventory]
      shooter.inventory[#shooter.inventory] = nil
      has = true
      break
    end
  end
  if not has then
    for i, it in ipairs(shooter.equipped) do
      if it.base == itm.base and it.level == itm.level then
        shooter.equipped[i] = shooter.equipped[#shooter.equipped]
        shooter.equipped[#shooter.equipped] = nil
        has = true
        break
      end
    end
    if not has then return end
  end

  self.projectile = itm

  for d = 1, dist do
    itm.x, itm.y = shooter.x+xm*d, shooter.y+ym*d
    engine.delay(0.1)

    if tile.blocks(self.map:get_tile(itm.x, itm.y)) then
      itm.x, itm.y = shooter.x+xm*(d-1), shooter.y+ym*(d-1)
      self.projectile = nil
      self.items[#self.items+1] = itm
      return
    end

    for i, a in ipairs(self.actors) do
      if shooter:is_enemy(a) and a.hp > 0 then
        if self.projectile.x == a.x and self.projectile.y == a.y then
          shooter:hit_projectile(a, itm)
          self.projectile = nil
          return
        end
      end
    end
  end

  self.projectile = nil
  self.items[#self.items+1] = itm
end

return level
