--- @class Deconstruction
local deconstruction = {}

--- @param player LuaPlayer
--- @param entity LuaEntity
function deconstruction.start(player, entity)
  storage.deconstructing[player.index] = entity.position
end

function deconstruction.iterate()
  for player_index, position in pairs(storage.deconstructing) do
    local player = game.get_player(player_index)
    if not player then
      deconstruction.cancel(player_index)
      goto continue
    end
    player.mining_state = { mining = true, position = position }
    ::continue::
  end
end

--- @param player_index uint
function deconstruction.cancel(player_index)
  storage.deconstructing[player_index] = nil
end

return deconstruction
