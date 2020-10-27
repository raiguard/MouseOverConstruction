local event = require("__flib__.event")
local migration = require("__flib__.migration")

local global_data = require("scripts.global-data")
local player_data = require("scripts.player-data")

local function toggle_mouseover(player_index)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]
  player_table.flags.mouseover_enabled = not player_table.flags.mouseover_enabled
  player.set_shortcut_toggled("moc-toggle", player_table.flags.mouseover_enabled)
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  global_data.init()

  for i in pairs(game.players) do
    player_data.init(i)
  end
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, {}) then

  end
end)

-- CUSTOM INPUT

event.register("moc-toggle", function(e)
  toggle_mouseover(e.player_index)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  player.create_local_flying_text{
    text = {"moc-message."..(player_table.flags.mouseover_enabled and "enabled" or "disabled").."-moc"},
    create_at_cursor = true
  }
end)

-- ENTITY

event.on_selected_entity_changed(function(e)

end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- SHORTCUT

event.on_lua_shortcut(function(e)
  if e.prototype_name == "moc-toggle" then
    toggle_mouseover(e.player_index)
  end
end)