-- transition between town and dungeon levels

local level = require("scripts/level")
local tile = require("scripts/tile")
local util = require("scripts/util")
local actor = require("scripts/actor")
local map = require("scripts/map")
local log = require("scripts/log")

local overworld = {
  x=0, y=0,
  map=nil,
  actor=nil
}

function overworld.find(tile)
  for i = 0, overworld.map.w*overworld.map.h-1 do
    if overworld.map.map[i] == tile then
      overworld.x = i%overworld.map.w
      overworld.y = math.floor(i/overworld.map.w)
      break
    end
  end
end

function overworld.draw()
  engine.ui.clear()
  engine.ui.gotoxy(0, 0)
  engine.ui.putstr("Overworld")
  log.draw()

  if not overworld.dummyfov then
    overworld.dummyfov = map:new(overworld.map.w, overworld.map.h, tile.visible)
  end

  engine.draw_map(overworld.map, overworld.dummyfov)
  engine.draw_actor(overworld.actor)
end

function overworld.navigate(a)
  if not overworld.map then
    overworld.map = map:new()
    overworld.map:generate_overworld()
    overworld.find(tile.town)
  end

  overworld.actor = a
  overworld.actor.x, overworld.actor.y = overworld.x, overworld.y
  actor.actors = {}
  actor.map = overworld.map
  overworld.active = true

  while true do
    engine.cursor(overworld.actor.x, overworld.actor.y)
    local c = engine.getch()
    local mov = util.control_movement(c)
    if mov.x ~= 0 or mov.y ~= 0 then
      if overworld.actor:move(mov.x, mov.y) then
        local t = overworld.map:get_tile(overworld.actor.x, overworld.actor.y)
        if t == tile.town or t == tile.dungeon then
          log.log(tile.description(t) .. " - press '>' to enter")
        end
      end
      log.update()
    end

    if c == engine.keys['>'] then
      local t = overworld.map:get_tile(overworld.actor.x, overworld.actor.y)
      if t == tile.town or t == tile.dungeon then
        overworld.x, overworld.y = overworld.actor.x, overworld.actor.y
        break
      end
    end
  end

  overworld.active = false
  return overworld.x, overworld.y
end

return overworld
