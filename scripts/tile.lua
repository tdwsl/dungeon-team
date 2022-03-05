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

  unknown = 0,
  known = 1,
  visible = 2
}

function tile.blocksvision(t)
  if t == tile.none then
    return false
  elseif t == tile.closeddoor then
    return false
  elseif t == tile.out then
    return false
  elseif t == tile.wall then
    return false
  else
    return true
  end
end

return tile
