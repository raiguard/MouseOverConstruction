--- @class Repair
local repair = {}

--- @param player LuaPlayer
--- @param entity LuaEntity
function repair.start(player, entity)
  storage.repairing[player.index] = entity.position
end

function repair.iterate()
  for player_index, position in pairs(storage.repairing) do
    local player = game.get_player(player_index)
    if not player then
      repair.cancel(player_index)
      goto continue
    end
    local entity = player.selected
    if entity and entity.health < entity.prototype.get_max_health(entity.quality) then
      player.repair_state = { repairing = true, position = position }
    else
      repair.cancel(player_index)
      -- call the on_selected_entity_changed event handler again in case it's marked for upgrade or deconstruction
      script.get_event_handler(defines.events.on_selected_entity_changed)({ player_index = player_index }) --- @diagnostic disable-line
    end
    ::continue::
  end
end

--- @param player_index uint
function repair.cancel(player_index)
  storage.repairing[player_index] = nil
end

return repair
