-- main game file

local map = require("scripts/map")
local tile = require("scripts/tile")
local actor = require("scripts/actor")
local level = require("scripts/level")
local util = require("scripts/util")
local dirs = require("scripts/dirs")
local log = require("scripts/log")

local game = {
  town1 = level:new(0),
  town2 = level:new(0),
  dungeon = level:new(1),
  overmap = level:new(-1)
}

local party = {
  actor:new(actor.rogue, 2, true),
  actor:new(actor.warrior, 2, true)
}

local selected = party[1]
game.current_level = game.dungeon

game.dungeon:enter(party)

function draw()
  game.current_level:draw()
end

function draw_partyinfo()
  for i, a in ipairs(party) do
    engine.ui.gotoxy(0, i-1)
    if a == selected then
      engine.ui.putstr(i .. "+ ")
    else
      engine.ui.putstr(i .. "- ")
    end

    engine.ui.putstr(a.name .. "\t")

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

function control()
  draw_ui()
  engine.cursor(selected.x, selected.y)

  local c = engine.getch()

  -- movement
  local mov = util.control_movement(c)
  if mov.x ~= 0 or mov.y ~= 0 then
    selected:move(mov.x, mov.y)
    selected.updated = true
    return true
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
      elseif c == engine.keys['.'] then
        -- set target
        local a = game.current_level:actor_at(cursor.x, cursor.y)
        if a ~= nil and a ~= selected then
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
  if c == engine.keys['.'] then
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

end

while true do
  log.update()
  if control() then
    game.current_level:update()
  end
end
