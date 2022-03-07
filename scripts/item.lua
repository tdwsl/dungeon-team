-- define items

local spell = require("scripts/spell")
local util = require("scripts/util")

melee=0
ranged=1
comestible=3
ammo=4
spellbook=5
armor=6

local item = {
  melee=melee,
  ranged=ranged,
  comestible=comestible,
  ammo=ammo,
  spellbook=spellbook,
  armor=armor,

  log = {},

  shortsword={type=melee, size=6, sharp=8, blunt=2,
    mod={size=0, sharp=0.5, blunt=0},
    name="Shortsword", value=100, graphic=0
  },
  throwing_knives={type=melee, size=2, sharp=4, blunt=0,
    mod={size=-0.1, sharp=0.4, blunt=0},
    name="Throwing Knives", value=25, grapic=1
  },
  dagger={type=melee, size=4, sharp=6, blunt=1,
    mod={size=0, sharp=0.4, blunt=0},
    name="Dagger", value=75, graphic=1
  },
  longsword={type=melee, size=8, sharp=12, blunt=3,
    mod={size=0, sharp=0.5, blunt=0.05},
    name="Longsword", value=150, graphic=0
  },
  bow={type=ranged, size=8, ranged=6, speed=4, ammo="arrow",
    mod={size=0.1, ranged=0.6, speed=0.3},
    name="Bow", value=150, graphic=2
  },
  arrow={type=ammo, size=2, sharp=3, blunt=0,
    name="Arrow", value=8, graphic=3
  },
  healing_potion={type=comestible, size=2,
    effect={hp=14, duration=1, str=0, mp=0, dex=0, ranged=0},
    name="Healing Potion", value=50, graphic=4
  },
  small_healing_potion={type=comestible, size=1,
    effect={hp=6, duration=1, str=0, mp=0, dex=0, ranged=0},
    name="Healing Potion (small)", value=20, graphic=4
  },
  shield={type=armor, shield=true, size=3, ac=4, dex=-4,
    mod={size=0, ac=0.3, dex=0.1},
    name="Shield", value=80, graphic=5
  },
  cloak={type=armor, shield=false, size=3, ac=1, dex=0,
    mod={size=0, ac=0.01, dex=0},
    name="Cloak", value=15, graphic=6
  },
  leather_armor={type=armor, shield=false, size=5, ac=6, dex=-1,
    mod={size=0, ac=0.4, dex=0.2},
    name="Leather Armor", value=180, graphic=7
  },
  chainmail={type=armor, shield=false, size=7, ac=9, dex=-3,
    mod={size=0, ac=0.5, dex=0.1},
    name="Chainmail Armor", value=240, graphic=7
  },
  basic_healing={type=spellbook, size=2,
    spells={spell.heal_small},
    name="Book of Basic Healing", value=100, graphic=8
  },
  novice_spellcasting={type=spellbook, size=5,
    spells={spell.heal_small, spell.swap_small, spell.detect_magic},
    name="Book of Novice Spellcasting", value=210, graphic=8
  },
  basic_offensive_magic={type=spellbook, size=3,
    spells={spell.fireball_small, spell.electricity_small},
    name="Book of Basic Offensive Magic", value=140, graphic=8
  }
}

function item.type_is_leveled(t)
  if t == item.spellbook or t == item.comestible or t == item.ammo then
    return false
  else
    return true
  end
end

function item:calculate_stats()
  if not item.type_is_leveled(self.type) then
    return
  end

  self.type = self.base.type
  self.name = self.base.name
  self.graphic = self.base.graphic
  local mul = self.level-1

  self.value = util.nzfloor(self.base.value * (1 + 0.2*mul))

  self.size = util.nzfloor(self.base.size +
      self.base.mod.size * mul)

  if self.type == item.armor then
    self.ac = util.nzfloor(self.base.ac + self.base.mod.ac * mul)
    self.dex = util.nzfloor(self.base.dex +
        self.base.mod.dex * mul)

  elseif self.type == item.melee then
    self.sharp = util.nzfloor(self.base.sharp +
        self.base.mod.sharp * mul)
    self.blunt = util.nzfloor(self.base.blunt +
        self.base.mod.blunt * mul)

  elseif self.type == item.ranged then
    self.ranged = util.nzfloor(self.base.ranged +
        self.base.mod.ranged * mul)
    self.speed = util.nzfloor(self.base.speed +
        self.base.mod.speed * mul)

  end
end

function item:new(itm, lvl)
  local it = {}
  if item.type_is_leveled(itm.type) then
    it.level = lvl
    it.base = itm
    setmetatable(it, self)
    self.__index = self
    it:calculate_stats()
  else
    it = itm
    setmetatable(it, self)
    self.__index = self
  end

  return it
end

function item:brief_description()
  local str = self.name
  if item.type_is_leveled(self.type) then
    str = str .. " (Level " .. self.level .. ")"
  end

  return str
end

function item:description()
  local str = item:brief_description()

  str = str .. "\n"
  str = str .. "weight: " .. self.size .. "\n"

  if self.type == item.melee then
    str = str .. "damage: " .. self.sharp .. " (sharp), " ..
        self.blunt .. " (blunt)\n"
  elseif self.type == item.ranged then
    str = str .. "ranged: " .. self.ranged ..
        "\nspeed: " .. self.speed .. "\n"
  elseif self.type == item.armor then
    str = str .. "AC: " .. self.ac .. "\n" ..
        "DEX: " .. self.dex .. "\n"
  elseif self.type == item.spellbook then
    str = str .. "spells: "
    for i, s in ipairs(self.spells) do
      str = str .. s.name .. " "
    end
    str = str .. "\n"
  elseif self.type == item.ammo then
    str = str .. "damage: " .. self.sharp .. " (sharp), " ..
        self.blunt .. " (blunt)\n"
  end

  str = str .. "value: $" .. self.value

  return str
end

--local it = item:new(item.leather_armor, 3)
--print(it:description())

return item
