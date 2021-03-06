-- define actor classes and functions

local item = require("scripts/item")
local spell = require("scripts/spell")
local util = require("scripts/util")
local tile = require("scripts/tile")
local map = require("scripts/map")
local dirs = require("scripts/dirs")
local log = require("scripts/log")

local actor = {
  map = nil,
  items = nil,
  fov = nil,
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
    spells={spell.fireball_small, spell.heal_small},
    graphic=0
  },
  rogue = {name="Rogue",
    base={maxhp=6, str=5, dex=8, ranged=4, maxmp=2},
    mod={maxhp=0.4, str=0.4, dex=0.6, ranged=0.3, maxmp=0.1},
    inv={{1, item.dagger} },--, {8, item.throwing_knives}},
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
    base={maxhp=3, str=5, dex=0, ranged=0, maxmp=1},
    mod={maxhp=0.4, str=0.4, dex=0, ranged=0, maxmp=0.3},
    inv={},
    spelltypes={healing=0.3, offensive=0},
    spells={},
    graphic=11
  },
  skeleton = {name="Skeleton",
    base={maxhp=6, str=10, dex=5, ranged=0, maxmp=0},
    mod={maxhp=0.3, str=0.2, dex=0.4, ranged=0, maxmp=0},
    inv={},
    spelltypes={healing=0, offensive=0},
    spells={},
    graphic=12, undead=true
  },
  orc = {name="Orc",
    base={maxhp=9, str=16, dex=3, ranged=0, maxmp=0},
    mod={maxhp=0.7, str=0.6, dex=0, ranged=0, maxmp=0},
    inv={{1, item.shortsword}},
    spelltypes={healing=0, offensive=0},
    spells={},
    graphic=14, undead=false
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

  self.capacity = 20 + self.str*3 + self.dex

  self.maxxp = self.level*10 + math.floor((self.maxhp+self.maxmp+self.dex+self.ranged)*0.2)
end

function actor:free_slots()
  local hands = 2
  local armor = false
  local shield = false

  for i, it in ipairs(self.equipped) do
    if it.type == item.melee then
      if it.twohands then
        hands = hands - 2
      else
        hands = hands - 1
      end
    elseif it.type == item.armor then
      if it.shield then
        hands = hands - 1
        shield = true
      else
        armor = true
      end
    elseif it.type == item.ranged then
      hands = hands - 2
    end
  end

  return {hands=hands, armor=armor, shield=shield}
end

function actor:equip(itm)
  local slots = self:free_slots()

  if itm.type == item.armor then
    if itm.shield and (slots.hands < 1 or slots.shield) then
      return false
    elseif slots.armor and not itm.shield then
      return false
    end
  elseif itm.type == item.ranged then
    if slots.hands < 2 then
      return false
    end
  elseif itm.type == item.melee then
    if itm.twohands and slots.hands < 2 then
      return false
    elseif slots.hands < 1 then
      return false
    end
  else
    return false
  end

  self.equipped[#self.equipped+1] = itm
  return true
end

function actor:level_up()
  local hpmul = self.hp / self.maxhp
  self.xp = self.xp - self.maxxp
  self.level = self.level + 1
  self:calculate_stats()
  self.hp = math.ceil(self.hp * hpmul)
  log.log(self.name .. " gained a level")
end

function actor:new(type, level, ally, x, y)
  local a = {}
  setmetatable(a, self)
  self.__index = self

  a.base = type.base
  a.mod = type.mod
  a.spelltypes = type.spelltypes
  a.graphic = type.graphic
  a.undead = type.undead
  a.name = type.name
  a.friendly = type.friendly
  a.inventory = {}
  a.xp = 0
  for i, t in ipairs(type.inv) do
    for j = 1, t[1] do
      a.inventory[#a.inventory+1] = item:new(t[2], level)
    end
  end
  a.spells = {}
  for i, s in ipairs(type.spells) do
    a.spells[#a.spells+1] = s
  end
  a.effects = {}

  -- equip any equippable items
  a.equipped = {}
  for i, it in ipairs(a.inventory) do
    a:equip(it)
  end

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
  if self.undead and self.hp > 0 then
    str = str .. " (undead)"
  end
  if self.hp < 0 then
    str = str .. " (dead)"
  end

  return str
end

function actor:description()
  local lines = {
    self:brief_description(),
    "HP: " .. self.hp .. "/" .. self.maxhp,
    "MP: " .. self.mp .. "/" .. self.maxmp,
    "DEX: " .. self.dex,
    "strength: " .. self.str,
    "ranged: " .. self.ranged,
    "XP: " .. self.xp .. "/" .. self.maxxp,
    "Encumberance: " .. self:used_capacity() .. "/" .. self.capacity
  }

  return lines
end

function actor:move(x, y)
  if self.hp <= 0 then
    return false
  end

  local dx, dy = self.x+x, self.y+y

  local t = actor.map:get_tile(dx, dy)

  if t == tile.closeddoor then
    actor.map:set_tile(dx, dy, tile.opendoor)
    return true
  end

  if tile.blocks(t) then
    return false
  end

  for i, a in ipairs(actor.actors) do
    if a ~= self and a.x == dx and a.y == dy and a.hp > 0 then
      if self.ally and not a.ally and not a.friendly then
        self:hit_actor(a)
        return true
      elseif a.ally and not self.ally and not a.friendly then
        self:hit_actor(a)
        return true
      elseif self:is_enemy(a) then
        self:hit_actor(a)
        return true
      elseif self.target ~= a then
        if self.target ~= nil then
          return false
        end

        local x = a.x
        local y = a.y
        a.x = self.x
        a.y = self.y
        self.x = x
        self.y = y
      end
      return true
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
    if (a.ally or a.friendly) and a.hp > 0 and a.target == self.target then
      if actor.map:get_tile(a.x, a.y) ~= tile.path then
        pmap:set_tile(a.x, a.y, -1)
      end
    end
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
    elseif self.target.hp then
      if self.target.hp <= 0 then
        self.target = nil
      end
    end
  end
end

function actor:calculate_dex()
  local dex = self.dex;
  for i, it in ipairs(self.equipped) do
    if it.dex then
      dex = dex + it.dex
    end
  end
  return dex
end

function actor:calculate_melee()
  local blunt = util.nzfloor(self.str/2)
  local sharp = 0

  local dex = self:calculate_dex()
  local str = self.str

  for i, it in ipairs(self.equipped) do
    if it.type == item.melee then
      sharp = sharp + it.sharp*util.nzfloor((dex/2) * (3/it.size) * 0.5)
      blunt = blunt + it.blunt*util.nzfloor((str/2) * (it.size/5) * 0.5)
    end
  end

  return {sharp=sharp, blunt=blunt}
end

function actor:calculate_ac()
  local ac = math.floor(self.str/2)

  for i, it in ipairs(self.equipped) do
    if it.ac then
      ac = ac + it.ac
    end
  end

  ac = util.nzfloor(ac/5)

  return ac
end

function actor:add_xp(xp)
  self.xp = self.xp + xp
  if self.xp >= self.maxxp then
    self:level_up()
  end
end

function actor:hit_actor(a)
  local melee = self:calculate_melee()
  local ac = a:calculate_ac()

  melee.blunt = melee.blunt - math.floor(ac*0.1)
  if melee.blunt < 0 then melee.blunt = 0 end
  melee.sharp = melee.sharp - math.floor(ac*0.25)
  if melee.sharp < 0 then melee.sharp = 0 end

  local damage = math.floor((melee.blunt + melee.sharp) / 2)

  if damage <= 0 then
    log.log(self.name .. " misses " .. a.name)
  else
    damage = math.random(damage)
    a.hp = a.hp - damage

    local str = self.name .. " hits " .. a.name
    if a.hp <= 0 then
      log.log(str .. " - " .. a.name .. " is dead")
      a.graphic = 31
      self:add_xp(math.floor(a.maxxp/2))
    else
      log.log(str .. " - " .. damage .. " damage")
    end

    self:add_xp(1)

    if self.hp/self.maxhp < a.hp/a.maxhp then
      self:add_xp(2)
    end
  end
end

function actor:calculate_ranged(a, wep, amm)
  local damage = {sharp=amm.sharp, blunt=amm.blunt}
  damage.sharp = util.nzfloor(damage.sharp * (2-1/(self.ranged*wep.ranged/2)))
  damage.blunt = util.nzfloor(damage.blunt * (2-1/(self.ranged*wep.ranged/2)))

  local ac = a:calculate_ac()

  damage.blunt = damage.blunt - math.floor(ac*0.5)
  if damage.blunt < 0 then damage.blunt = 0 end
  damage.sharp = damage.sharp - math.floor(ac*0.8)
  if damage.sharp < 0 then damage.sharp = 0 end

  local xd, yd = a.x - self.x, a.y - self.y
  if xd >= -1 and xd <= 1 and yd >= -1 and yd <= 1 then
    damage.sharp = util.nzfloor(damage.sharp / 6)
    damage.blunt = util.nzfloor(damage.blunt / 4)
  end

  return damage
end

function actor:hit_projectile(a, itm)
  local damage = {sharp=0, blunt=1}

  if itm.type == item.ammo then
    local compatible = false
    local ci
    for i, it in ipairs(self.equipped) do
      if it.type == item.ranged and it.ammo == itm.base then
        compatible = true
        ci = it
        break
      end
    end

    if compatible then
      damage = self:calculate_ranged(a, ci, itm)
      if math.random(2) == 2 then
        itm.x, itm.y = a.x, a.y
        actor.items[#actor.items+1] = itm
      end
    end
  else
    if itm.type == item.melee and itm.size <= 3 then
      damage = self:calculate_melee()
      damage.sharp = math.floor((damage.sharp/4)*self.dex)
      damage.blunt = math.floor((damage.blunt/6)*self.dex)
    end

    itm.x, itm.y = a.x, a.y
    actor.items[#actor.items+1] = itm
  end

  local hp = math.floor(damage.blunt/2 + damage.sharp/2)
  a.hp = a.hp - hp

  local str = itm.name .. " hits " .. a.name .. " - "
  if a.hp <= 0 then
    a.graphic = 31
    log.log(str .. a.name .. " dies!")
    self:add_xp(a.maxhp)
  else
    log.log(str .. hp .. " damage")
    self:add_xp(2)
  end
end

function actor:cast_spell(spel, x, y)
  local casted = false

  for i, a in ipairs(actor.actors) do
    if a.x == x and a.y == y then
      spell.cast(spel, self, a)
      casted = true
    end
  end

  if casted then
    self.mp = self.mp - spel.mp
    return true
  else
    return false
  end
end

function actor:update_effect(eff)
  if self.hp <= 0 then return end

  self.hp = self.hp + eff.effect.hp
  if eff.effect.hp < 0 then
    log.log(self.name .. " takes " .. eff.effect.hp*-1 .. " damage")
  end
  if self.hp <= 0 then
    log.log(self.name .. " dies")
    self.graphic = 31
    if eff.caster then
      if eff.caster.hp > 0 then
        eff.caster:add_xp(self.maxhp+self.str)
      end
    end
  end

  self.mp = self.mp + eff.effect.mp
  if self.mp < 0 then
    self.mp = 0
  end

  eff.duration = eff.duration - 1
  if eff.duration > 0 then
    return true
  end

  for i, ef in ipairs(self.effects) do
    if ef == eff then
      self.effects[i] = self.effects[#self.effects]
      self.effects[#self.effects] = nil
      return false
    end
  end
end

function actor:add_effect(eff, caster)
  self.effects[#self.effects+1] = {
    effect=eff, duration=eff.duration, caster=caster
  }
  self:update_effect(self.effects[#self.effects])
end

function actor:update_effects()
  local i = 1
  while i <= #self.effects do
    if self:update_effect(self.effects[i]) then
      i = i - 1
    end
  end
end

function actor:update()
  if self.hp <= 0 then
    return
  elseif self.hp < self.maxhp then
    if not self.regen_cooldown then
      self.hp = self.hp + 1
      self.regen_cooldown = 5
    elseif self.regen_cooldown <= 0 then
      self.hp = self.hp + 1
      self.regen_cooldown = 5
    else
      self.regen_cooldown = self.regen_cooldown - 1
    end
  end

  if self.mp < self.maxmp then
    self.mp = self.mp + 1
  end

  self:update_effects()

  if self.updated then
    self.updated = false
    return
  end

  if not self.ally and not self.friendly then
    if util.turn % 3 == 0 then return end
  end

  if self.target and not self.target.ally == self.ally then
    self:follow_target()
  else
    for i, a in ipairs(actor.actors) do
      if self:is_enemy(a) and self:can_see(a.x, a.y) and a.hp > 0 then
        if self:can_see(a.x, a.y, 5) then
          self.target = a
          break
        end
      end
    end
    if self.target then
      self:follow_target()
    end
  end

  -- wander
  if not self.target and not self.ally and util.turn % 2 == 0 and math.random(3) == 1 then
    local d = dirs.dirs8[math.random(8)]
    self:move(d.x, d.y)
  end
end

function actor:can_see(x, y, r)
  if not r then
    r = 10
  end

  local a = math.atan(y-self.y, x-self.x)
  local sina, cosa = math.sin(a), math.cos(a)

  local fail = 0

  for m = 0, r, 0.5 do
    local tx = math.floor(self.x+0.5+cosa*m)
    local ty = math.floor(self.y+0.5+sina*m)

    if x == tx and y == ty then
      return true
    end

    if tile.blocks(actor.map:get_tile(tx, ty)) then
      fail = fail + 1
      if fail >= 2 then
        break
      end
    end
  end

  return false
end

function actor:is_enemy(a)
  if a.friendly or a.ally then
    return (not (self.friendly or self.ally))
  else
    return (self.friendly or self.ally)
  end
end

function actor:used_capacity()
  local used = 0
  for i, it in ipairs(self.inventory) do
    used = used + it.size
  end

  return used
end

function actor:pick_up(itm)
  if self:used_capacity() + itm.size > self.capacity then
    log.log(self.name .. " cannot pick up " .. itm.name)
    return false

  else
    for i, it in ipairs(actor.items) do
      if it.x == itm.x and it.y == itm.y and
          it.base == itm.base and it.level == itm.level then
        actor.items[i] = actor.items[#actor.items]
        actor.items[#actor.items] = nil
        break
      end
    end

    self.inventory[#self.inventory+1] = itm

    log.log(self.name .. " took " .. itm.name)
    return true
  end

end

function actor:drop(itm)
  for i, it in ipairs(self.inventory) do
    if it.base == itm.base and it.level == itm.level then
      it.x = self.x
      it.y = self.y
      actor.items[#actor.items+1] = it

      self.inventory[i] = self.inventory[#self.inventory]
      self.inventory[#self.inventory] = nil

      for j, tm in ipairs(self.equipped) do
        if tm.base == it.base and tm.level == it.level then
          self.equipped[j] = self.equipped[#self.equipped]
          self.equipped[#self.equipped] = nil
          break
        end
      end

      return
    end
  end
end

function actor:stats_screen()
  engine.ui.clear()
  local w, h = engine.ui.wh()

  local desc = self:description()
  for i, d in ipairs(desc) do
    engine.ui.gotoxy(1, i)
    engine.ui.putstr(d)
  end

  local x = math.floor(w/2)+1
  engine.ui.gotoxy(x, 1)
  engine.ui.putstr("Inventory:")

  local items = item.item_list(self.inventory)
  local sitems = item.string_list(items)

  for i, it in ipairs(items) do
    engine.ui.gotoxy(x-2, i+1)
    local equipped = false
    for j, tm in ipairs(self.equipped) do
      if it.item.base == tm.base and it.item.level == tm.level then
        equipped = true
        break
      end
    end
    if equipped then
      engine.ui.putstr("* ")
    else
      engine.ui.putstr("  ")
    end
    engine.ui.putstr(sitems[i])
  end

  engine.ui.gotoxy(x, #items+3)
  engine.ui.putstr("Spells:")
  for i, sp in ipairs(self.spells) do
    engine.ui.gotoxy(x, #items+3+i)
    engine.ui.putstr(sp.name)
  end

  engine.ui.gotoxy(1, h-1)
  engine.ui.putstr("(Press any key)")

  engine.getch()
end

function actor:pick_up_amount(itm, num)
  for i = 1, num do
    if not self:pick_up(itm) then
      if i == 1 then return false end
      break
    end
  end
  return true
end

return actor
