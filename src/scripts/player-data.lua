local constants = require("constants")

local player_data = {}

function player_data.init(player_index)
  global.players[player_index] = {
    flags = {
      deconstructing = false,
      mouseover_enabled = false,
      recheck_on_move = false,
      repairing = false
    },
    settings = {}
  }
end

function player_data.update_settings(player, player_table)
  local player_settings = player.mod_settings
  local settings = {}
  for prototype, internal in pairs(constants.setting_names) do
    settings[internal] = player_settings[prototype].value
  end
  player_table.settings = settings
end

function player_data.toggle_mouseover(player, player_table)
  player_table.flags.mouseover_enabled = not player_table.flags.mouseover_enabled
  player.set_shortcut_toggled("moc-toggle", player_table.flags.mouseover_enabled)
end

return player_data