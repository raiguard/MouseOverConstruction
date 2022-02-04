local event = require("__flib__.event")

local repair = {}

function repair.start(player, player_table, entity)
  global.repairing_players[player.index] = true
  player_table.flags.repairing = true
  player_table.repairing_position = entity.position
end

function repair.iterate()
  for player_index in pairs(global.repairing_players) do
    local player = game.get_player(player_index)
    local player_table = global.players[player_index]
    local entity = player.selected
    if entity and entity.health < entity.prototype.max_health then
      player.repair_state = { repairing = true, position = player_table.repairing_position }
    else
      repair.cancel(player, player_table)
      -- call the on_selected_entity_changed event handler again in case it's marked for upgrade or deconstruction
      event.get_handler(defines.events.on_selected_entity_changed)({ player_index = player_index })
    end
  end
end

function repair.cancel(player, player_table)
  global.repairing_players[player.index] = nil
  player_table.flags.repairing = false
  player_table.repairing_position = nil
end

return repair
