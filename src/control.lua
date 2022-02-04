local event = require("__flib__.event")
local migration = require("__flib__.migration")

local constants = require("constants")

local deconstruction = require("scripts.deconstruction")
local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local on_tick = require("scripts.on-tick")
local player_data = require("scripts.player-data")
local repair = require("scripts.repair")

-- -----------------------------------------------------------------------------
-- COMMON FUNCTIONS

--- @param inventory LuaInventory
--- @param entity_prototype LuaEntityPrototype
local function get_first_item(inventory, entity_prototype)
  for _, item_stack in ipairs(entity_prototype.items_to_place_this) do
    local count = inventory.get_item_count(item_stack.name)
    if count >= item_stack.count then
      return item_stack
    end
  end
end

--- @param cursor_stack LuaItemStack
--- @param entity_prototype LuaEntityPrototype
local function get_first_item_cursor(cursor_stack, entity_prototype)
  for _, item_stack in ipairs(entity_prototype.items_to_place_this) do
    if item_stack.name == cursor_stack.name and item_stack.count <= cursor_stack.count then
      return item_stack
    end
  end
end

--- @param player LuaPlayer
--- @param player_table PlayerTable
local function check_selected(player, player_table)
  -- check setting
  if player_table.flags.mouseover_enabled then
    local cursor_stack = player.cursor_stack
    -- if the cursor stack exists, but is empty
    if cursor_stack and cursor_stack.valid then
      -- if the player has something selected
      local selected = player.selected
      if selected then
        -- check reachability
        if player.can_reach_entity(selected) then
          local settings = player_table.settings
          local is_empty = not cursor_stack.valid_for_read
          local is_repair_tool = not is_empty and cursor_stack.type == "repair-tool"

          -- Check to see if the entity's name, ghost name, or upgrade name matches what we're holding
          local upgrade_prototype = selected.get_upgrade_target()
          local selected_name = selected.name
          if upgrade_prototype then
            selected_name = upgrade_prototype.name
          elseif selected.type == "entity-ghost" then
            selected_name = selected.ghost_name
          end
          local matches_selected = not is_empty
            and cursor_stack.prototype.place_result
            and cursor_stack.prototype.place_result.name == selected_name

          -- revive ghosts
          if
            settings.enable_construction
            and selected.type == "entity-ghost"
            and (matches_selected or is_empty or is_repair_tool)
          then
            -- extra checks
            if
              player.can_place_entity({
                name = selected.ghost_name,
                position = selected.position,
                direction = selected.direction,
              })
            then
              if matches_selected then
                local use_item = get_first_item_cursor(cursor_stack, selected.ghost_prototype)
                if use_item then
                  cursor_stack.count = cursor_stack.count - use_item.count
                  selected.revive({ raise_revive = true })
                end
              else
                local inventory = player.get_main_inventory()
                local use_item = get_first_item(inventory, selected.ghost_prototype)
                if use_item then
                  inventory.remove(use_item)
                  selected.revive({ raise_revive = true })
                end
              end
            else
              -- recheck when the player moves
              player_table.flags.recheck_on_move = true
            end
            -- check for repair pack and low entity health
          elseif
            settings.enable_repairing
            and is_repair_tool
            and selected.health
            and selected.health < selected.prototype.max_health
          then
            repair.start(player, player_table, selected)
            on_tick.register()
            -- upgrade to-be-upgraded from inventory
          elseif
            settings.enable_upgrading
            and selected.to_be_upgraded()
            and (matches_selected or is_empty or is_repair_tool)
          then
            local upgrade_prototype = selected.get_upgrade_target()
            if upgrade_prototype then
              if matches_selected then
                local use_item = get_first_item_cursor(cursor_stack, upgrade_prototype)
                if use_item then
                  local upgraded_entity = player.surface.create_entity({
                    name = upgrade_prototype.name,
                    position = selected.position,
                    direction = selected.direction,
                    force = selected.force,
                    player = player,
                    fast_replace = true,
                    raise_built = true,
                  })
                  if upgraded_entity then
                    player.play_sound({
                      path = "entity-build/" .. upgraded_entity.name,
                      position = upgraded_entity.position,
                    })
                    cursor_stack.count = cursor_stack.count - use_item.count
                  end
                end
              else
                local inventory = player.get_main_inventory()
                local use_item = get_first_item(inventory, upgrade_prototype)
                if use_item then
                  local upgraded_entity = player.surface.create_entity({
                    name = upgrade_prototype.name,
                    position = selected.position,
                    direction = selected.direction,
                    force = selected.force,
                    player = player,
                    fast_replace = true,
                    raise_built = true,
                  })
                  if upgraded_entity then
                    player.play_sound({
                      path = "entity-build/" .. upgraded_entity.name,
                      position = upgraded_entity.position,
                    })
                    inventory.remove(use_item)
                  end
                end
              end
            end
            -- deconstruct to-be-deconstructed entities
          elseif
            settings.enable_deconstruction
            and selected.to_be_deconstructed()
            and (matches_selected or is_empty or is_repair_tool)
          then
            -- start deconstruction operation
            deconstruction.start(player, player_table, selected)
            on_tick.register()
          end
        else
          -- recheck when the player moves
          player_table.flags.recheck_on_move = true
        end
      end
    end
  end
end

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
  if migration.on_config_changed(e, migrations) then
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
  player.create_local_flying_text({
    text = { "moc-message." .. (player_table.flags.mouseover_enabled and "enabled" or "disabled") .. "-moc" },
    create_at_cursor = true,
  })
end)

-- ENTITY

event.on_selected_entity_changed(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  -- reset flag
  player_table.flags.recheck_on_move = false
  -- cancel active deconstruction
  if player_table.flags.deconstructing then
    deconstruction.cancel(player, player_table)
  end
  -- cancel active repair
  if player_table.flags.repairing then
    repair.cancel(player, player_table)
  end
  check_selected(player, player_table)
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

event.on_player_changed_position(function(e)
  local player_table = global.players[e.player_index]
  if player_table and player_table.flags.recheck_on_move then
    local player = game.get_player(e.player_index)
    check_selected(player, player_table)
  end
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
