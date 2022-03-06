-- main game file

local map = require("scripts/map")
local tile = require("scripts/tile")
local actor = require("scripts/actor")

local level = {
  map = map:new(),
  fov = map:new()
}

local cursor = {x=0, y=0}
local actors = {actor:new(actor.rogue, 1, true, 0, 0), actor:new(actor.rogue, 1, true, 0, 0)}

--level.map:generate_dungeon(1)
level.map:generate_overmap()
level.fov:init(level.map.w, level.map.h, tile.visible)

function draw()
  engine.draw_map(level.map, level.fov)
  for i, a in ipairs(actors) do
    engine.draw_actor(a)
  end
end

for i = 0, level.map.w*level.map.h-1 do
  if level.map.map[i] == tile.upstairs then
    cursor = {x = i%level.map.w, y = math.floor(i/level.map.w)}
    actors[1].x, actors[1].y = cursor.x, cursor.y
    actors[2].x, actors[2].y = cursor.x+1, cursor.y
    break
  end
end

engine.ui.gotoxy(0, 0)
engine.ui.putstr('Hello, world!')

while true do
  engine.cursor(cursor.x, cursor.y)
  local c = engine.getch()
  if c == engine.keys.up then
    cursor.y = cursor.y - 1
  elseif c == engine.keys.down then
    cursor.y = cursor.y + 1
  elseif c == engine.keys.left then
    cursor.x = cursor.x - 1
  elseif c == engine.keys.right then
    cursor.x = cursor.x + 1
  elseif c == engine.keys['>'] then
    engine.ui.putstr('>')
  end
end