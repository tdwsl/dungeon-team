-- main game file

local map = require("scripts/map")
local tile = require("scripts/tile")
local actor = require("scripts/actor")
local level = require("scripts/level")

local cursor = {x=0, y=0}

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

game.dungeon:enter(party)
game.dungeon.fov:init(game.dungeon.fov.w, game.dungeon.fov.h, tile.visible)

function draw()
  game.dungeon:draw()
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
