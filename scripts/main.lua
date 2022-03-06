-- main game file

local map = require("scripts/map")
local tile = require("scripts/tile")
local actor = require("scripts/actor")

local cursor = {x=0, y=0}

local game = {
  town1 = map:new(),
  town2 = map:new(),
  dungeon = map:new(),
  overmap = map:new(),
  fov = map:new()
}

game.overmap:generate_overmap()
game.dungeon:generate_dungeon(1)

game.fov:init(game.dungeon.w, game.dungeon.h, tile.visible)

actor.map = game.dungeon

for i = 0, actor.map.w*actor.map.h-1 do
  if actor.map.map[i] == tile.upstairs or actor.map.map[i] == tile.town then
    cursor = {x = i%actor.map.w, y = math.floor(i/actor.map.w)}
    actor.add(actor:new(actor.rogue, 2, true, cursor.x, cursor.y))
    actor.add(actor:new(actor.rogue, 2, true, cursor.x+1, cursor.y))
    break
  end
end

function draw()
  engine.draw_map(actor.map, game.fov)
  for i, a in ipairs(actor.actors) do
    engine.draw_actor(a)
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
  elseif c == engine.keys['return'] then
    actor.actors[1].target = {x=cursor.x, y=cursor.y}
  elseif c == engine.keys['.'] then
    actor.update_all()
  elseif c == engine.keys['>'] then
    engine.ui.putstr('>')
  end
end