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

function util.choose(options)
  local choice = 1
  local w, h = engine.ui.wh()
  local tw = 0
  for i, o in ipairs(options) do
    if #o > tw then
      tw = #o
    end
  end
  local bw, bh = tw + 6, #options + 2
  local bx, by = math.floor(w/2-bw/2), math.floor(h/2-bh/2)

  for y = by, by+bh-1 do
    engine.ui.gotoxy(bx, y)
    for x = bx, bx+bw-1 do
      engine.ui.putstr(' ')
    end
  end

  for i, o in ipairs(options) do
    engine.ui.gotoxy(bx+2, by+i)
    engine.ui.putch(engine.keys.a+i-1)
    engine.ui.putstr(") " .. o)
  end

  -- begin selection
  while true do
    for i, o in ipairs(options) do
      engine.ui.gotoxy(bx+1, by+i)
      if choice == i then
        engine.ui.putstr("*")
      else
        engine.ui.putstr("-")
      end
    end

   local c = engine.getch()

    local mov = util.control_movement(c)
    if mov.y ~= 0 and mov.x == 0 then
      choice = choice + mov.y
      if choice < 1 then choice = 1 end
      if choice > #options then choice = #options end
    end

    if c == engine.keys['.'] or c == engine.keys['return'] then
      return choice
    end

    for i, o in ipairs(options) do
      if c == engine.keys.a+i-1 then
        choice = i
        return choice
      end
    end
  end
end

function util.amount(max)
  local prompt = "How many? 0-" .. max
  local max_digits = 5

  local w, h = engine.ui.wh()
  local x = math.floor(w/2 - #prompt/2)
  local y = math.floor(h/2 - 2)

  engine.ui.gotoxy(x, y)
  engine.ui.putstr(prompt)

  for j = 1, 2 do
    engine.ui.gotoxy(x, y+j)
    for i = 1, #prompt do
      engine.ui.putstr(' ')
    end
  end

  engine.ui.gotoxy(x, y+2)
  engine.ui.putstr(':')

  local digits = {}

  while true do
    engine.ui.gotoxy(x+1, y+2)
    for i = 1, max_digits do
      if digits[i] then
        engine.ui.putch(digits[i])
      else
        engine.ui.putstr(' ')
      end
    end

    local c = engine.getch()

    if c == engine.keys['return'] then break end

    if c >= engine.keys['0'] and c <= engine.keys['9'] then
      if #digits < max_digits then
        digits[#digits+1] = c
      end
    elseif c == engine.keys.backspace then
      if #digits > 0 then
        digits[#digits] = nil
      end
    end
  end

  if #digits == 0 then return 0 end

  local num = 0
  for i, d in ipairs(digits) do
    num = num*10 + d-engine.keys['0']
  end

  if num > max then
    return max
  else
    return num
  end
end

return util
