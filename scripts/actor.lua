-- define actor classes and functions

local item = require("scripts/item")
local spell = require("scripts/spell")
local util = require("scripts/util")
local tile = require("scripts/tile")
local map = require("scripts/map")
local dirs = require("scripts/dirs")

local actor = {
  map = nil,
  items = nil,
  actors = {},

  -- player classes
  ranger = {name="Ranger",
    base={maxhp=8, str=6, dex=6, ranged=10, maxmp=1},
    mod={maxhp=0.4, str=0.3, dex=0.5, ranged=0.6, maxmp=0.01},
    inv={{1, item.bow}, {24, item.arrow}},
    spelltypes={healing=0.3, offensive=0.3},
    spells={},
    graphic=3,
  },
  warrior = {name="Warrior",
    base={maxhp=10, str=8, dex=4, ranged=3, maxmp=1},
    mod={maxhp=0.6, str=0.6, dex=0.2, ranged=0.1, maxmp=0.01},
    inv={{1, item.shortsword}, {1, item.shield}, {1, item.healing_potion}},
    spelltypes={healing=0.2, offensive=0.3},
    spells={},
    graphic=1, friendly=true
  },
  healer = {name="Healer",
    base={maxhp=4, str=2, dex=2, ranged=2, maxmp=6},
    mod={maxhp=0.1, str=0.02, dex=0.1, ranged=0.01, maxmp=0.6},
    inv={},
    spelltypes={healing=2.2, offensive=0.1},
    spells={spell.heal_small},
    graphic=4, friendly=true
  },
  wizard = {name="Wizard",
    base={maxhp=5, str=3, dex=2, ranged=2, maxmp=5},
    mod={maxhp=0.2, str=0.1, dex=0.2, ranged=0.01, maxmp=0.6},
    inv={},
    spelltypes={healing=1.0, offensive=1.0},
    spells={spell.fireball_small},
    graphic=0
  },
  rogue = {name="Rogue",
    base={maxhp=6, str=5, dex=8, ranged=4, maxmp=2},
    mod={maxhp=0.4, str=0.4, dex=0.6, ranged=0.3, maxmp=0.1},
    inv={{1, item.dagger}, {8, item.throwing_knives}},
    spelltypes={healing=0.4, offensive=0.5},
    spells={},
    graphic=2
  },

  -- friendly
  townsperson = {name="Townsperson",
    base={maxhp=8, str=4, dex=4, ranged=2, maxmp=1},
    mod={maxhp=0, str=0, dex=0, ranged=0, maxmp=0},
    inv={},
    spelltypes={healing=0.5, offensive=0.5},
    spells={},
    graphic=8, friendly=true
  },

  -- enemies
  slime = {name="Slime",
    base={maxhp=3, str=2, dex=0, ranged=0, maxmp=1},
    mod={maxhp=0.4, str=0.4, dex=0, ranged=0, maxmp=0.3},
    inv={},
    spelltypes={healing=0.3, offensive=0},
    spells={},
    graphic=11
  },
  skeleton = {name="Skeleton",
    base={maxhp=6, str=4, dex=5, ranged=0, maxmp=0},
    mod={maxhp=0.3, str=0.2, dex=0.4, ranged=0, maxmp=0},
    inv={},
    spelltypes={healing=0, offensive=0},
    spells={},
    graphic=12, undead=true
  }
}

function actor.clear()
  actor.actors = {}
end

function actor.add(a)
  actor.actors[#actor.actors+1] = a
end

function actor:calculate_stats()
  local mul = self.level - 1

  self.maxhp = util.nzfloor(self.base.maxhp * (1 + self.mod.maxhp*mul))
  self.str = util.nzfloor(self.base.str * (1 + self.mod.str*mul))
  self.dex = util.nzfloor(self.base.dex * (1 + self.mod.dex*mul))
  self.ranged = util.nzfloor(self.base.ranged * (1 + self.mod.ranged*mul))
  self.maxmp = util.nzfloor(self.base.maxmp * (1 + self.mod.maxmp*mul))
end

function actor:new(type, level, ally, x, y)
  local a = {}
  a.base = type.base
  a.mod = type.mod
  a.spelltypes = type.spelltypes
  a.graphic = type.graphic
  a.undead = type.undead
  a.name = type.name
  a.friendly = type.friendly
  a.inventory = {}
  for i, t in ipairs(type.inv) do
    for j = 1, t[1] do
      a.inventory[#a.inventory+1] = item:new(t[2], level)
    end
  end
  a.spells = {}
  for i, s in ipairs(type.spells) do
    a.spells[#a.spells+1] = s
  end

  setmetatable(a, self)
  self.__index = self

  if a.graphic == 8 then
    if math.random(10) > 7 then
      a.graphic = 9
    end
  end

  a.ally = ally
  if level ~= nil then
    a.level = level
  else
    a.level = 1
  end
  a:calculate_stats()

  a.mp = a.maxmp
  a.hp = a.maxhp

  if x and y then
    a.x = x
    a.y = y
  else
    a.x = 0
    a.y = 0
  end

  return a
end

function actor:brief_description()
  local str = self.name .. " (Level " .. self.level .. ")"
  if self.friendly then
    str = str .. " (friendly)"
  end
  if self.ally then
    str = str .. " (ally)"
  end
  if self.undead then
    str = str .. " (undead)"
  end

  return str
end

function actor:description()
  local str = self:brief_description()

  str = str .. "\nHP: " .. self.hp .. "/" .. self.maxhp
  str = str .. "\nMP: " .. self.mp .. "/" .. self.maxmp
  str = str .. "\nDEX: " .. self.dex
  str = str .. "\nstrength: " .. self.str
  str = str .. "\nranged: " .. self.ranged

  return str
end

function actor:move(x, y)
  local dx, dy = self.x+x, self.y+y

  local t = actor.map:get_tile(dx, dy)

  if t == tile.closeddoor then
    actor.map:set_tile(dx, dy, tile.opendoor)
    return
  end

  if tile.blocks(t) then
    return false
  end

  for i, a in ipairs(actor.actors) do
    if a ~= self and a.x == dx and a.y == dy then
      return false
    end
  end

  self.x = dx
  self.y = dy

  return true
end

function actor:navigate_to(tx, ty)
  local pmap = map:new(actor.map.w, actor.map.h, 0)
  for i = 0, actor.map.w*actor.map.h-1 do
    if tile.blocks(actor.map.map[i]) and
        actor.map.map[i] ~= tile.closeddoor then
      pmap.map[i] = -1
    end
  end

  for i, a in ipairs(actor.actors) do
    pmap:set_tile(a.x, a.y, -1)
  end
  pmap:set_tile(self.x, self.y, 0)
  pmap:set_tile(tx, ty, 1)

  pmap:generate_heatmap(dirs.dirs8)
  local t = pmap:get_tile(self.x, self.y)

  for i, d in ipairs(dirs.dirs4) do
    if pmap:get_tile(self.x+d.x, self.y+d.y) == t-1 then
      self:move(d.x, d.y)
      return
    end
  end
  for i, d in ipairs(dirs.dirs8) do
    if pmap:get_tile(self.x+d.x, self.y+d.y) == t-1 then
      self:move(d.x, d.y)
      return
    end
  end

end

function actor:follow_target()
  if self.target.x and self.target.y then
    self:navigate_to(self.target.x, self.target.y)
    if self.x == self.target.x and self.y == self.target.y then
      self.target = nil
    end
  end
end

function actor:update()
  if self.updated then
    self.updated = false
    return
  end

  if self.target then
    self:follow_target()
  end
end

function actor.update_all()
  for i, a in ipairs(actor.actors) do
    a:update()
  end
end

--local a = actor:new(actor.rogue, 1, true)
--print(a:description())

return actor
