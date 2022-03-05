-- directions used in movement, pathfinding and mapgen

local dirs = {}

dirs.dirs4 = {
  {x=0, y=-1},
  {x=1, y=0},
  {x=0, y=1},
  {x=-1, y=0}
}

dirs.dirs8 = {
  {x=0, y=-1},
  {x=1, y=-1},
  {x=1, y=0},
  {x=1, y=1},
  {x=0, y=1},
  {x=-1, y=1},
  {x=-1, y=0},
  {x=-1, y=-1}
}

return dirs