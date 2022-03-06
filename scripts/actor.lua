-- define actor classes and functions

local item = require("scripts/item")
local spell = require("scripts/spell")
local util = require("scripts/util")

local actor = {
  -- player classes
  ranger = {name="Ranger",
    base={maxhp=8, str=6, dex=6, ranged=10, maxmp=1},
    mod={maxhp=0.4, str=0.3, dex=0.5, ranged=0.6, maxmp=0.01},
    inv={item.bow, 1, item.arrow, 24},
    spelltypes={healing=0.3, offensive=0.3},
    spells={},
    graphic=3,
  },
  warrior = {name="Warrior",
    base={maxhp=10, str=8, dex=4, ranged=3, maxmp=1},
    mod={maxhp=0.6, str=0.6, dex=0.2, ranged=0.1, maxmp=0.01},
    inv={item.shortsword, 1, item.shield, 1, item.healing_potion, 1},
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
    inv={item.dagger, 1, item.throwing_knives, 8},
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
    graphic=11
  },
  skeleton = {name="Skeleton",
    base={maxhp=6, str=4, dex=5, ranged=0, maxmp=0},
    mod={maxhp=0.3, str=0.2, dex=0.4, ranged=0, maxmp=0},
    inv={},
    spelltypes={healing=0, offensive=0},
    graphic=12, undead=true
  }
}

function actor:calculate_stats()
  local mul = self.level - 1

  self.maxhp = util.nzfloor(self.base.maxhp * (1 + self.mod.maxhp*mul))
  self.str = util.nzfloor(self.base.str * (1 + self.mod.str*mul))
  self.dex = util.nzfloor(self.base.dex * (1 + self.mod.dex*mul))
  self.ranged = util.nzfloor(self.base.ranged * (1 + self.mod.ranged*mul))
  self.maxmp = util.nzfloor(self.base.maxmp * (1 + self.mod.maxmp*mul))
end

function actor:new(type, level, ally)
  local a = type
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

  return a
end

function actor:description()
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
  str = str .. "\nHP: " .. self.hp .. "/" .. self.maxhp
  str = str .. "\nMP: " .. self.mp .. "/" .. self.maxmp
  str = str .. "\nDEX: " .. self.dex
  str = str .. "\nstrength: " .. self.str
  str = str .. "\nranged: " .. self.ranged

  return str
end

--local a = actor:new(actor.rogue, 1, true)
--print(a:description())

return actor