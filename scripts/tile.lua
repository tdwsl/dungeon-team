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

return tile
