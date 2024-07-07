--- @class Repair
local repair = {}

--- @param player LuaPlayer
--- @param entity LuaEntity
function repair.start(player, entity)
  global.repairing[player.index] = entity.position
end

function repair.iterate()
  for player_index, position in pairs(global.repairing) do
    local player = game.get_player(player_index)
    if not player then
      repair.cancel(player_index)
      goto continue
    end
    local entity = player.selected
    if entity and entity.health < entity.prototype.max_health then
      player.repair_state = { repairing = true, position = position }
    else
      repair.cancel(player_index)
      -- TODO:
      -- -- call the on_selected_entity_changed event handler again in case it's marked for upgrade or deconstruction
      -- script.get_event_handler(defines.events.on_selected_entity_changed)({ player_index = player_index })
    end
    ::continue::
  end
end

--- @param player_index uint
function repair.cancel(player_index)
  global.repairing[player_index] = nil
end

return repair
