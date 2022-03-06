-- utility functions

local util = {}

function util.mul_effect(effect, m)
  effect.hp = effect.hp * m
  effect.str = effect.str *m
  effect.mp = effect.mp * m
  effect.dex = effect.dex * m

  return effect
end

function util.nzfloor(n)
  if n < 0 and n > -0.5 then
    n = -1
  elseif n > 0 and n < 0.5 then
    n = 1
  end
  n = math.floor(n)

  return n
end

function util.floor_effect(effect)
  effect.hp = nzfloor(effect.hp)
  effect.str = nzfloor(effect.str)
  effect.mp = nzfloor(effect.mp)
  effect.dex = nzfloor(effect.dex)

  return effect
end

return util