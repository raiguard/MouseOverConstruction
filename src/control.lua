local event = require("__flib__.event")
local migration = require("__flib__.migration")

local constants = require("constants")

local deconstruction = require("scripts.deconstruction")
local global_data = require("scripts.global-data")
local mouseover = require("scripts.mouseover")
local on_tick = require("scripts.on-tick")
local player_data = require("scripts.player-data")

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- `on_tick` handler is located and registered in `scripts.on-tick`
-- all other event handlers are here

-- BOOTSTRAP

event.on_init(function()
  global_data.init()

  for i in pairs(game.players) do
    player_data.init(i)
    local player = game.get_player(i)
    local player_table = global.players[i]
    player_data.update_settings(player, player_table)
  end
end)

event.on_load(function()
  on_tick.register()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, {}) then
    for i, player_table in pairs(global.players) do
      player_data.update_settings(game.get_player(i), player_table)
    end
  end
end)

-- CUSTOM INPUT

event.register("moc-toggle", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  player_data.toggle_mouseover(player, player_table)
  player.create_local_flying_text{
    text = {"moc-message."..(player_table.flags.mouseover_enabled and "enabled" or "disabled").."-moc"},
    create_at_cursor = true
  }
end)

-- ENTITY

event.on_selected_entity_changed(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  -- cancel deconstruction
  if player_table.flags.deconstructing then
    deconstruction.cancel(player, player_table)
  end
  -- check setting
  if player_table.flags.mouseover_enabled then
    local cursor_stack = player.cursor_stack
    -- if the cursor stack exists, but is empty
    if cursor_stack and cursor_stack.valid and not cursor_stack.valid_for_read then
      -- if the player has something selected
      local selected = player.selected
      if selected then
        -- if the player is able to build / upgrade / deconstruct
        local settings = player_table.settings
        -- revive ghosts
        if settings.enable_construction and selected.type == "entity-ghost" then
          mouseover.construct(player, selected)
        -- upgrade to-be-upgraded from inventory
        elseif settings.enable_upgrading and selected.to_be_upgraded() then
          local upgrade = selected.get_upgrade_target()
          if upgrade then
            mouseover.upgrade(player, selected, upgrade)
          end
        -- deconstruct to-be-deconstructed entities
        elseif settings.enable_deconstruction and selected.to_be_deconstructed() then
          -- start deconstruction operation
          deconstruction.start(player, player_table, selected)
          on_tick.register()
        end
      end
    end
  end
end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  player_data.update_settings(player, player_table)
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- SHORTCUT

event.on_lua_shortcut(function(e)
  if e.prototype_name == "moc-toggle" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_data.toggle_mouseover(player, player_table)
  end
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if constants.setting_names[e.setting] then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_data.update_settings(player, player_table)
  end
end)