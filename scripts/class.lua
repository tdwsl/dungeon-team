-- define actor classes

local item = require("scripts/item")
local spell = require("scripts/spell")

local class = {
  ranger = {
    stats={maxhp=8, str=6, dex=6, ranged=10, maxmp=1},
    mod={maxhp=0.4, str=0.3, dex=0.5, ranged=0.6, maxmp=0.01},
    inv={item.bow, 1, item.arrow, 24},
    spelltypes={healing=0.4, offensive=0.4},
    spells={}
  },
  warrior = {
    stats={maxhp=10, str=8, dex=4, ranged=3, maxmp=1},
    mod={maxhp=0.6, str=0.6, dex=0.2, ranged=0.1, maxmp=0.01},
    inv={item.shortsword, 1, item.shield, 1, item.healing_potion, 1},
    spelltypes={healing=0.2, offensive=0.3},
    spells={}
  },
  healer = {
    stats={maxhp=4, str=2, dex=2, ranged=2, maxmp=6},
    mod={maxhp=0.1, str=0.02, dex=0.1, ranged=0.01, maxmp=0.6},
    inv={},
    spelltypes={healing=2.2, offensive=0.1},
    spells={spell.heal_small}
  },
  wizard = {
    stats={maxhp=5, str=3, dex=2, ranged=2, maxmp=5},
    mod={maxhp=0.2, str=0.1, dex=0.2, ranged=0.01, maxmp=0.6},
    inv={},
    spelltypes={healing=1.0, offensive=1.0},
    spells={spell.fireball_small}
  },
  rogue = {
    stats={maxhp=6, str=5, dex=8, ranged=4, maxmp=2},
    mod={maxhp=0.4, str=0.4, dex=0.6, ranged=0.3, maxmp=0.1},
    inv={item.dagger, 1, item.throwing_knives, 8},
    spelltypes={healing=0.3, offensive=0.4},
    spells={}
  }
}

return class