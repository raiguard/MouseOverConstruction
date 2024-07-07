local player_data = {}

function player_data.init(player_index)
  --- @class PlayerTable
  global.players[player_index] = {
    flags = {
      deconstructing = false,
      mouseover_enabled = false,
      recheck_on_move = false,
      repairing = false,
    },
    settings = {},
  }
end

function player_data.toggle_mouseover(player, player_table)
  player_table.flags.mouseover_enabled = not player_table.flags.mouseover_enabled
  player.set_shortcut_toggled("moc-toggle", player_table.flags.mouseover_enabled)
end

return player_data
