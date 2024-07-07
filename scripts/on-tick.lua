local deconstruction = require("scripts/deconstruction")
local repair = require("scripts/repair")

local on_tick = {}

local function on_tick_handler()
  local deregister = true

  if next(global.repairing_players) then
    deregister = false
    repair.iterate()
  end

  if next(global.deconstructing_players) then
    deregister = false
    deconstruction.iterate()
  end

  if deregister then
    script.on_event(defines.events.on_tick, nil)
  end
end

function on_tick.register()
  if next(global.deconstructing_players) or next(global.repairing_players or {}) then
    script.on_event(defines.events.on_tick, on_tick_handler)
  end
end

return on_tick
