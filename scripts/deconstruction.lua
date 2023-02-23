local deconstruction = {}

function deconstruction.start(player, player_table, entity)
  global.deconstructing_players[player.index] = true
  player_table.flags.deconstructing = true
  player_table.deconstructing_position = entity.position
end

function deconstruction.iterate()
  for player_index in pairs(global.deconstructing_players) do
    local player = game.get_player(player_index)
    local player_table = global.players[player_index]
    player.mining_state = { mining = true, position = player_table.deconstructing_position }
  end
end

function deconstruction.cancel(player, player_table)
  global.deconstructing_players[player.index] = nil
  player_table.flags.deconstructing = false
  player_table.deconstructing_position = nil
end

return deconstruction
