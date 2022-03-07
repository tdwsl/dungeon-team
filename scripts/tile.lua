-- definitions of tile 'constants', to avoid having to use strings or numbers

local tile = {
  out = -10,

  none = 0,
  floor = 11,
  wall = 4,
  path = 18,
  closeddoor = 12,
  opendoor = 13,
  upstairs = 17,
  downstairs = 16,

  water = 10,
  grass = -1,
  mountain = 1,
  tree = 3,
  dungeon = 8,
  town = 9,

  unknown = 0,
  known = 1,
  visible = 2
}

function tile.blocksvision(t)
  if t == tile.none then
    return true
  elseif t == tile.closeddoor then
    return true
  elseif t == tile.out then
    return true
  elseif t == tile.wall then
    return true
  else
    return false
  end
end

function tile.blocks(t)
  if t == tile.none or t == tile.out then
    return true
  elseif t == tile.closeddoor or t == tile.wall then
    return true
  elseif t == tile.water then
    return true
  else
    return false
  end
end

function tile.description(t)
  if t == tile.grass then
    return "grass"
  elseif t == tile.water then
    return "water"
  elseif t == tile.closeddoor then
    return "door (closed)"
  elseif t == tile.opendoor then
    return "door (open)"
  elseif t == tile.wall then
    return "wall"
  elseif t == tile.floor then
    return "floor"
  elseif t == tile.path then
    return "path"
  elseif t == tile.upstairs then
    return "stairs (up)"
  elseif t == tile.downstairs then
    return "stairs (down)"
  elseif t == tile.tree then
    return "forest"
  elseif t == tile.mountain then
    return "mountain"
  elseif t == tile.town then
    return "town"
  elseif t == tile.dungeon then
    return "dungeon"
  else
    return "unknown tile"
  end
end

return tile
