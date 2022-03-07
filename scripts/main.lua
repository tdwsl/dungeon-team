-- main game file

local map = require("scripts/map")
local tile = require("scripts/tile")
local actor = require("scripts/actor")
local level = require("scripts/level")
local util = require("scripts/util")

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

function drawPartyInfo()
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
        engine.ui.putstr("(targeting [" .. a.target.x .. "," ..
            a.target.y .. "])")
      end
    else
      engine.ui.putstr("(no task)")
    end
  end
end

function drawUI()
  engine.ui.clear()
  drawPartyInfo()
end

function control()
  drawUI()
  engine.cursor(selected.x, selected.y)

  local c = engine.getch()

  local mov = util.control_movement(c)
  if mov.x ~= 0 or mov.y ~= 0 then
    selected:move(mov.x, mov.y)
    selected.updated = true
    return true
  end

  if c == engine.keys.c then
    local w, h = engine.ui.wh()
    engine.ui.clear()
    drawPartyInfo()
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
        selected.target = {x=cursor.x, y=cursor.y}
        break
      else
        selected.target = nil
        break
      end
      engine.cursor(cursor.x, cursor.y)
    end

    drawUI()
    return false
  end

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

  if c == engine.keys['.'] then
    return true
  end
end

while true do
  if control() then
    game.current_level:update()
  end
end
