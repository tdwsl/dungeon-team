-- main game file

local map = require("scripts/map")
local tile = require("scripts/tile")
local actor = require("scripts/actor")
local level = require("scripts/level")
local util = require("scripts/util")
local dirs = require("scripts/dirs")
local log = require("scripts/log")
local item = require("scripts/item")
local overworld = require("scripts/overworld")

local game = {
  dungeons = {},
  towns = {level:new(0), level:new(0)},
  depth=1
}

local party = {
  actor:new(actor.ranger, 2, true),
  actor:new(actor.wizard, 2, true),
  actor:new(actor.warrior, 2, true)
}

local selected = party[1]

function navigate_overworld()
  for i, d in ipairs(game.dungeons) do
    if d.remembered then
      d:forget()
    end
  end

  for i, a in ipairs(party) do
    a.hp = a.maxhp
    a.mp = a.maxmp
  end

  log.logs = {}
  overworld.navigate(selected)
  game.depth = 1

  if overworld.map:get_tile(overworld.x, overworld.y) == tile.dungeon then
    if not game.dungeons[game.depth] then
      game.dungeons[game.depth] = level:new(game.depth)
    end
    game.dungeons[game.depth]:enter(party)
    game.current_level = game.dungeons[game.depth]
    return
  end

  local n = 0
  for i = 0, overworld.y*overworld.map.w+overworld.x do
    if overworld.map.map[i] == tile.town then
      n = n + 1
    end
  end

  game.towns[n]:enter(party)
  game.current_level = game.towns[n]
end

function draw()
  if overworld.active then
    overworld.draw()
  else
    game.current_level:draw()
  end
end

function draw_partyinfo()
  for i, a in ipairs(party) do
    engine.ui.gotoxy(0, (i-1)*2)
    if a == selected then
      engine.ui.putstr(i .. "+ ")
    else
      engine.ui.putstr(i .. "- ")
    end

    engine.ui.putstr(a.name)

    engine.ui.gotoxy(3, (i-1)*2+1)

    engine.ui.putstr("(" .. a.hp .. "/" .. a.maxhp .. ")\t")

    if a.target then
      if a.target.x and a.target.y then
        engine.ui.putstr("(targeting ")
        if a.target.name then
          engine.ui.putstr(a.target.name .. " at ")
        end
        engine.ui.putstr("[" .. a.target.x .. "," ..
            a.target.y .. "])")
      end
    else
      engine.ui.putstr("(no task)")
    end
  end
end

function draw_ui()
  engine.ui.clear()
  draw_partyinfo()
  log.draw()
end

function party_gathered()
  local avg = {x=0, y=0}
  for i, a in ipairs(party) do
    avg.x = avg.x + a.x
    avg.y = avg.y + a.y
  end
  avg.x = avg.x / #party
  avg.y = avg.y / #party

  for i, a in ipairs(party) do
    local xd, yd = avg.x-a.x, avg.y-a.y
    if xd*xd+yd*yd > 4*4 then
      return false
    end
  end

  return true
end

function control()
  draw_ui()
  engine.cursor(selected.x, selected.y)
  selected.updated = true

  local c = engine.getch()

  -- movement
  local mov = util.control_movement(c)
  if mov.x ~= 0 or mov.y ~= 0 then
    if(selected:move(mov.x, mov.y)) then
      -- see items on floor
      local items = game.current_level:items_at(selected.x, selected.y)
      items = item.item_list(items)
      items = item.string_list(items)
      if #items == 1 then
        log.log("Here you see: " .. items[1])
      elseif #items > 0 then
        log.log("You see multiple items here")
      end

      selected.updated = true
      return true
    else
      return false
    end
  end

  -- change / switch control
  if c == engine.keys.c then
    local w, h = engine.ui.wh()
    engine.ui.clear()
    draw_partyinfo()
    engine.ui.gotoxy(0, h-1)
    engine.ui.putstr("Press 1-" .. #party .. ", any other key to cancel")
    c = engine.getch()
    for i, a in ipairs(party) do
      if c == engine.keys["" .. i] then
        selected = a
        selected.target = nil
        return false
      end
    end
    return false
  end

  -- target
  if c == engine.keys.t then
    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Press '.' to target, any other key to cancel")
    local cursor = {x=selected.x, y=selected.y}

    while true do
      c = engine.getch()
      mov = util.control_movement(c)
      if mov.x ~= 0 or mov.y ~= 0 then
        cursor.x = cursor.x + mov.x
        cursor.y = cursor.y + mov.y
        util.limit_cursor(cursor, actor.map.w, actor.map.h)
      elseif c == engine.keys['.'] or c == engine.keys['5'] then
        -- set target
        local a = game.current_level:actor_at(cursor.x, cursor.y)
        if a ~= nil and a ~= selected and
            game.current_level.fov:get_tile(a.x, a.y) == tile.visible then
          selected.target = a
        else
          selected.target = {x=cursor.x, y=cursor.y}
        end
        break
      else
        selected.target = nil
        break
      end
      engine.cursor(cursor.x, cursor.y)
    end

    draw_ui()
    return false
  end

  -- look/examine
  if c == engine.keys.x then
    local cursor = {x=selected.x, y=selected.y}
    local w, h = engine.ui.wh()

    while true do
      engine.ui.clear()
      local coords = "[" .. cursor.x .. "," .. cursor.y .. "]"
      engine.ui.gotoxy(w-#coords, 0)
      engine.ui.putstr(coords)
      local desc = game.current_level:tile_description(cursor.x, cursor.y)
      for i, d in ipairs(desc) do
        engine.ui.gotoxy(0, i-1)
        engine.ui.putstr(d)
      end
      engine.cursor(cursor.x, cursor.y)

      c = engine.getch()
      mov = util.control_movement(c)
      if mov.x == 0 and mov.y == 0 then
        break
      end
      cursor.x = cursor.x + mov.x
      cursor.y = cursor.y + mov.y
      util.limit_cursor(cursor, actor.map.w, actor.map.h)
    end
    return false
  end

  -- wait/continue
  if c == engine.keys['.'] or c == engine.keys['5'] then
    if selected.target then
      selected.updated = false
    else
      selected.updated = true
    end
    return true
  end

  -- close door
  if c == engine.keys.C then
    local dn = 0
    local ld
    for i, d in ipairs(dirs.dirs8) do
      if actor.map:get_tile(selected.x+d.x, selected.y+d.y) ==
          tile.opendoor then
        dn = dn + 1
        ld = d
      end
    end

    if dn == 0 then
      log.log("No open doors")
      return false
    end

    if dn == 1 then
      local x, y = selected.x+ld.x, selected.y+ld.y
      if game.current_level:actor_at(x, y) or
          #game.current_level:items_at(x, y) > 0 then
        log.log("The door is blocked")
        return false
      end
      actor.map:set_tile(x, y, tile.closeddoor)
      return true
    end

    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Choose a door to close")

    c = engine.getch()
    local mov = util.control_movement(c)

    if mov.x == 0 and mov.y == 0 then
      log.log("Nevermind")
      return false
    end

    local x, y = selected.x+mov.x, selected.y+mov.y

    if actor.map:get_tile(x, y) == tile.opendoor then
      if game.current_level:actor_at(x, y) or
          #game.current_level:items_at(x, y) > 0 then
        log.log("The door is blocked")
        return false
      end
      actor.map:set_tile(x, y, tile.closeddoor)
      return true
    else
      log.log("There is no door there")
      return false
    end
  end

  -- pick up
  if c == engine.keys[','] or c == engine.keys['g'] then
    local items = game.current_level:items_at(selected.x, selected.y)
    items = item.item_list(items)

    if #items == 0 then
      log.log("Nothing to pick up")
      return false
    end

    if #items == 1 then
      if items[1].num == 1 then
        if items[1].item.base == item.amulet_of_yendor then
          victory()
        end
        return selected:pick_up(items[1].item)
      else
        local num = util.amount(items[1].num)
        if num == 0 then
          log.log("Nevermind")
        else
          return selected:pick_up_amount(items[1].item, num)
        end
      end
    end

    -- choose between multiple

    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Choose an item to pick up")

    local options = item.string_list(items)
    options[#options+1] = "Cancel"

    local choice = util.choose(options)

    if choice > #items then
      log.log("Nevermind")
      return false
    end

    if items[choice].num == 1 then
      if items[choice].item.base == item.amulet_of_yendor then
        victory()
      end
      return selected:pick_up(items[choice].item)
    else
      local num = util.amount(items[choice].num)
      if num == 0 then
        log.log("Nevermind")
      else
        return selected:pick_up_amount(items[choice].item, num)
      end
    end

  end

  -- show inventory / stats
  if c == engine.keys.i then
    selected:stats_screen()
    return false
  end

  -- drop items
  if c == engine.keys.d then
    local items = item.item_list(selected.inventory)

    local options = item.string_list(items)
    options[#options+1] = "Cancel"

    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Choose an item to drop")

    local choice = util.choose(options)

    if choice > #items then
      log.log("Nevermind")
      return false
    end

    if items[choice].num == 1 then
      selected:drop(items[choice].item)
      return true
    else
      local num = util.amount(items[choice].num)
      if num == 0 then
        log.log("Nevermind")
        return false
      end

      for i = 1, num do
        selected:drop(items[choice].item)
      end
      return true
    end
  end

  -- wield/equip
  if c == engine.keys.w then
    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Choose an item to equip")

    local items = {}
    for i, it in ipairs(selected.inventory) do
      if it.type == item.armor or it.type == item.melee or it.type == item.ranged then
        local already = false
        for j, e in ipairs(selected.equipped) do
          if it.base == e.base and it.level == e.level then
            already = true
            break
          end
        end
        if not already then
          items[#items+1] = it
        end
      end
    end
    items = item.item_list(items)

    local options = item.string_list(items)
    options[#options+1] = "Cancel"

    local choice = util.choose(options)

    if choice > #items then
      log.log("Nevermind")
      return false
    end

    if selected:equip(items[choice].item) then
      return true
    else
      log.log("Can't equip " .. options[choice] .. " - try unequipping items")
      return false
    end
  end

  -- unequip
  if c == engine.keys.W then
    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Choose an item to unequip")

    local options = {}
    for i, it in ipairs(selected.equipped) do
      options[i] = it:brief_description()
    end
    options[#options+1] = "Cancel"

    local choice = util.choose(options)

    if choice > #selected.equipped then
      log.log("Nevermind")
      return false
    end

    selected.equipped[choice] = selected.equipped[#selected.equipped]
    selected.equipped[#selected.equipped] = nil
    return true
  end

  -- go down / enter
  if c == engine.keys['>'] then
    local t = game.current_level.map:get_tile(selected.x, selected.y)
    if t ~= tile.downstairs then
      log.log("Can't go down here")
      return false
    end

    if not party_gathered() then
      log.log("Party must be nearby")
      return false
    end

    game.current_level:exit()
    game.depth = game.depth + 1
    if not game.dungeons[game.depth] then
      game.dungeons[game.depth] = level:new(game.depth)
    end
    game.current_level = game.dungeons[game.depth]
    game.current_level.entrance = {x=selected.x, y=selected.y}
    game.current_level:enter(party)
    return true
  end

  if c == engine.keys['<'] then
    local t = game.current_level.map:get_tile(selected.x, selected.y)
    if t ~= tile.upstairs then
      log.log("Can't go up here")
      return false
    end

    if not party_gathered() then
      log.log("Party must be nearby")
      return false
    end

    -- go up
    game.current_level:exit()
    game.depth = game.depth - 1

    if game.depth >= 1 then
      local x, y = game.current_level.entrance.x, game.current_level.entrance.y
      game.current_level = game.dungeons[game.depth]
      game.current_level:enter(party, x, y)
      return false
    else
      navigate_overworld()
    end
  end

  -- cast a spell
  if c == engine.keys.z then
    -- select spell

    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Choose a spell to cast")

    local options = {}
    for i, sp in ipairs(selected.spells) do
      options[i] = sp.name
    end
    options[#options+1] = "Cancel"

    local choice = util.choose(options)
    if choice > #selected.spells then
      log.log("Nevermind")
      return false
    end

    local spel = selected.spells[choice]
    if spel.mp > selected.mp then
      log.log("Not enough MP")
      return false
    end

    -- select tile

    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Casting " .. spel.name)

    local cursor = {x=selected.x, y=selected.y}

    while true do
      local c = engine.getch()
      local mov = util.control_movement(c)
      if mov.x ~= 0 or mov.y ~= 0 then
        cursor.x = cursor.x + mov.x
        cursor.y = cursor.y + mov.y
        util.limit_cursor(cursor, actor.map.w, actor.map.h)
        engine.cursor(cursor.x, cursor.y)
      elseif c == engine.keys['return'] or c == engine.keys['.'] then
        break
      else
        log.log("Nevermind")
        return false
      end
    end

    -- cast

    if not selected:can_see(cursor.x, cursor.y) then
      log.log("Must have clear line to target")
      return false
    end

    if not game.current_level:actor_at(cursor.x, cursor.y) then
      log.log("No creatures here")
      return false
    end

    selected:cast_spell(selected.spells[choice], cursor.x, cursor.y)
    return true
  end

  -- fire weapon
  if c == engine.keys.f then
    -- find weapon
    local weapon = nil
    for i, it in ipairs(selected.equipped) do
      if it.type == item.ranged then
        weapon = it
        break
      end
    end
    if not weapon then
      log.log("No weapon to fire")
      return false
    end

    local ammo
    for i, it in ipairs(selected.inventory) do
      if it.base == weapon.ammo then
        ammo = it
      end
    end
    if not ammo then
      log.log("No ammo")
      return false
    end

    -- choose direction to fire
    engine.ui.clear()
    engine.ui.gotoxy(0, 0)
    engine.ui.putstr("Choose a direction to fire")

    local c = engine.getch()
    local mov = util.control_movement(c)
    if mov.x == 0 and mov.y == 0 then
      log.log("Nevermind")
      return false
    end

    game.current_level:fire_projectile(selected, mov.x, mov.y, ammo,
        4+math.floor(selected.ranged/2))
    return true
  end

  return false
end

function gameover()
  engine.ui.clear()
  local text = "Game over!"
  local w, h = engine.ui.wh()
  engine.ui.gotoxy(math.floor(w/2-#text/2), math.floor(h/2))
  engine.ui.putstr(text)

  while true do
    local c = engine.getch()
  end
end

function victory()
  engine.ui.clear()
  local w, h = engine.ui.wh()
  local text = "You found the Amulet of Yendor!"
  engine.ui.gotoxy(math.floor(w/2-#text/2), math.floor(h/2))
  engine.ui.putstr(text)

  while true do
    engine.getch()
  end
end

-- begin

navigate_overworld()
--[[local it = item:new(item.amulet_of_yendor, 1)
it.x = selected.x-1
it.y = selected.y
game.current_level.items[#game.current_level.items+1] = it]]--

while true do
  log.update()
  if control() then
    game.current_level:update()
    util.turn = util.turn + 1
    if selected.hp <= 0 then
      selected = party[1]
      if selected == nil then
        gameover()
      end
    end
  end
end
