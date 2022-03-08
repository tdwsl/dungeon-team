-- define spells

local util = require("scripts/util")
local log = require("scripts/log")

local spell = {
  healing=0,
  offensive=1,
  other=3,

  heal_small={type=healing, radius=0,
    level=1, mp=4, special=false,
    effect={hp=4, duration=1, str=0, mp=0, ranged=0, dex=0},
    name="Heal small", desc="Heal a creature"
  },
  fireball_small={type=offensive, radius=0,
    level=2, mp=3, special=false,
    effect={hp=-3, duration=1, str=0, mp=0, ranged=0, dex=0},
    name="Fireball small", desc="Inflict damage upon a creature"
  },
  swap_small={type=other, radius=0,
    level=5, mp=5, special=true,
    fun = function(c, a)
      if a.level > 8 then
        log.log(a.name .. " is too strong!")
        return
      end
      local x, y = c.x, c.y
      c.x = a.x
      c.y = a.y
      a.x = x
      a.y = y
      log.log(c.name .. " swapped places with " .. a.name)
    end,
    name="Swap small",
    desc="Swap places with a creature below a certain level"
  }
}

function spell.cast(spel, caster, castee)
  log.log(caster.name .. " casts " .. spel.name .. " on " .. castee.name)

  if spel.special then
    if caster.level < spel.level then
      log.log("Nothing happens!")
    else
      spel.fun(caster, castee)
    end
  else
    local effect = spel.effect
    if spel.type == spell.healing then
      effect = util.mul_effect(effect, caster.spelltype.healing)
      if castee.undead then
        effect.hp = effect.hp * -1
      end
    elseif spel.type == spell.offensive then
      effect = util.mul_effect(effect, caster.spelltype.offensive)
    end
    util.floor_effect(effect)

    castee:add_effect(effect)
  end
end

return spell
