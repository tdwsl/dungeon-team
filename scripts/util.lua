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

function util.control_movement(c)
  local mov = {x=0, y=0}

  if c == engine.keys.up or c == engine.keys['8'] or c == engine.keys.k then
    mov = {x=0, y=-1}
  elseif c == engine.keys.down or c == engine.keys['2'] or c == engine.keys.j then
    mov = {x=0, y=1}
  elseif c == engine.keys.left or c == engine.keys['4'] or c == engine.keys.h then
    mov = {x=-1, y=0}
  elseif c == engine.keys.right or c == engine.keys['6'] or c == engine.keys.l then
    mov = {x=1, y=0}
  elseif c == engine.keys['7'] or c == engine.keys.y then
    mov = {x=-1, y=-1}
  elseif c == engine.keys['9'] or c == engine.keys.u then
    mov = {x=1, y=-1}
  elseif c == engine.keys['1'] or c == engine.keys.b then
    mov = {x=-1, y=1}
  elseif c == engine.keys['3'] or c == engine.keys.n then
    mov = {x=1, y=1}
  end

  return mov
end

function util.limit_cursor(cursor, w, h)
  if cursor.x < 0 then cursor.x = 0 end
  if cursor.x >= w then cursor.x = w-1 end
  if cursor.y < 0 then cursor.y = 0 end
  if cursor.y >= h then cursor.y = h-1 end
end

return util
