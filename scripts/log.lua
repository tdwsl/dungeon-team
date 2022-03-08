-- used to describe what's going on

local log = {
  logs = {}
}

function log.log(l)
  log.logs[#log.logs+1] = {log=l}
end

function log.update()
  local i = 1
  while i <= #log.logs do
    if log.logs[i].old then
      for j = i, #log.logs do
        log.logs[j] = log.logs[j+1]
      end
      log.logs[#log.logs] = nil
      i = i - 1
    else
      log.logs[i].old = true
    end
    i = i + 1
  end
end

function log.draw()
  local w, h = engine.ui.wh()
  for i, l in ipairs(log.logs) do
    engine.ui.gotoxy(0, h-#log.logs-1+i)
    engine.ui.putstr(l.log)
  end
end

return log
