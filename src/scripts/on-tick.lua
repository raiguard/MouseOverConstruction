local event = require("__flib__.event")

local deconstruction = require("scripts.deconstruction")
local repair = require("scripts.repair")

local on_tick = {}

local function on_tick_handler()
  local deregister = true

  -- it won't exist yet if going to 1.1.0 from 1.0.0
  if next(global.repairing_players or {}) then
    deregister = false
    repair.iterate()
  end

  if next(global.deconstructing_players) then
    deregister = false
    deconstruction.iterate()
  end

  if deregister then
    event.on_tick(nil)
  end
end

function on_tick.register()
  if next(global.deconstructing_players) or next(global.repairing_players) then
    event.on_tick(on_tick_handler)
  end
end

return on_tick