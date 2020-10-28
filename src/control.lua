local event = require("__flib__.event")
local migration = require("__flib__.migration")

local global_data = require("scripts.global-data")
local mouseover = require("scripts.mouseover")
local player_data = require("scripts.player-data")

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
  local player_table = global.players[e.player_index]
  if player_table.flags.mouseover_enabled then
    local player = game.get_player(e.player_index)
    local cursor_stack = player.cursor_stack
    -- if the cursor stack exists, but is empty
    if cursor_stack and cursor_stack.valid and not cursor_stack.valid_for_read then
      local selected = player.selected
      if selected then
        -- revive ghosts
        if selected.type == "entity-ghost" then
          mouseover.construct(player, selected)
        -- upgrade to-be-upgraded from inventory
        elseif selected.to_be_upgraded() then
          local upgrade = selected.get_upgrade_target()
          if upgrade then
            mouseover.upgrade(player, selected, upgrade)
          end
        end
      end
    end
  end
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
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_data.toggle_mouseover(player, player_table)
  end
end)