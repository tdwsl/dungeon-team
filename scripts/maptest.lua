-- simple mapgen test

local map = require("map")

local m = map:new()

for i = 0, 8 do
  print(i)
  m:generate_dungeon(i)
  m:print()
  print()
end