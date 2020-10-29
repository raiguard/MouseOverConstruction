local event = require("__flib__.event")

local deconstruction = require("scripts.deconstruction")

local on_tick = {}

local function on_tick_handler()
  if next(global.deconstructing_players) then
    deconstruction.iterate()
  else
    event.on_tick(nil)
  end
end

function on_tick.register()
  if next(global.deconstructing_players) then
    event.on_tick(on_tick_handler)
  end
end

return on_tick