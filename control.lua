local migration = require("__flib__.migration")

local deconstruction = require("scripts.deconstruction")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local repair = require("scripts.repair")

local handler = require("__core__.lualib.event_handler")

handler.add_lib(require("scripts.shortcut"))

-- -----------------------------------------------------------------------------
-- COMMON FUNCTIONS

--- @param item_source LuaItemStack|LuaInventory
--- @param entity_prototype LuaEntityPrototype|LuaTilePrototype
local function get_first_item(item_source, entity_prototype)
  local is_inventory = item_source.object_name == "LuaInventory"
  for _, item_stack in ipairs(entity_prototype.items_to_place_this) do
    local count
    if is_inventory then
      count = item_source.get_item_count(item_stack.name)
    else
      count = item_source.name == item_stack.name and item_source.count or nil
    end
    if count >= item_stack.count then
      return item_stack
    end
  end
end

--- @param item_source LuaItemStack|LuaInventory
--- @param player LuaPlayer
--- @param entity LuaEntity
--- @param upgrade_prototype LuaEntityPrototype
local function upgrade_entity(item_source, player, entity, upgrade_prototype)
  local is_inventory = item_source.object_name == "LuaInventory"
  local use_item = get_first_item(item_source, upgrade_prototype)
  if use_item then
    local upgraded_entity = player.surface.create_entity({
      name = upgrade_prototype.name,
      position = entity.position,
      direction = entity.direction,
      force = entity.force,
      player = player,
      fast_replace = true,
      raise_built = true,
      type = entity.type == "underground-belt" and entity.belt_to_ground_type or nil,
    })
    if upgraded_entity then
      player.play_sound({
        path = "entity-build/" .. upgraded_entity.name,
        position = upgraded_entity.position,
      })
      if is_inventory then
        item_source.remove(use_item)
      else
        item_source.count = item_source.count - use_item.count
      end
      return true
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
          local settings = player.mod_settings
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
            settings["moc-enable-construction"].value
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
                local use_item = get_first_item(cursor_stack, selected.ghost_prototype)
                if use_item then
                  local _, revived = selected.revive({ raise_revive = true })
                  if revived and revived.valid then
                    cursor_stack.count = cursor_stack.count - use_item.count
                  end
                end
              else
                local inventory = player.get_main_inventory()
                if inventory then
                  local use_item = get_first_item(inventory, selected.ghost_prototype)
                  if use_item then
                    local _, revived = selected.revive({ raise_revive = true })
                    if revived and revived.valid then
                      inventory.remove(use_item)
                    end
                  end
                end
              end
            else
              -- recheck when the player moves
              player_table.flags.recheck_on_move = true
            end
            -- check for repair pack and low entity health
          elseif
            settings["moc-enable-repairing"]
            and is_repair_tool
            and selected.health
            and selected.health < selected.prototype.max_health
            and not player.vehicle
          then
            repair.start(player, player_table, selected)
            -- upgrade to-be-upgraded from inventory
          elseif
            settings["moc-enable-upgrading"]
            and selected.to_be_upgraded()
            and (matches_selected or is_empty or is_repair_tool)
          then
            local upgrade_prototype = selected.get_upgrade_target()
            if upgrade_prototype then
              local underground_neighbour = selected.type == "underground-belt" and selected.neighbours or nil
              local item_source = matches_selected and cursor_stack or player.get_main_inventory()
              if
                upgrade_entity(item_source, player, selected, upgrade_prototype)
                and underground_neighbour
                and underground_neighbour.valid
                and underground_neighbour.get_upgrade_target()
              then
                upgrade_entity(item_source, player, underground_neighbour, underground_neighbour.get_upgrade_target())
              end
            end
            -- deconstruct to-be-deconstructed entities
          elseif
            settings["moc-enable-deconstruction"]
            and selected.to_be_deconstructed()
            and (matches_selected or is_empty or is_repair_tool)
          then
            -- start deconstruction operation
            deconstruction.start(player, player_table, selected)
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

local M = {}

function M.on_init()
  global.deconstructing_players = {}
  global.players = {}
  global.repairing_players = {}

  for i in pairs(game.players) do
    player_data.init(i)
    local player = game.get_player(i)
    local player_table = global.players[i]
    player_data.update_settings(player, player_table)
  end
end

--- @param e ConfigurationChangedData
function M.on_configuration_changed(e)
  if migration.on_config_changed(e, migrations) then
    for i, player_table in pairs(global.players) do
      player_data.update_settings(game.get_player(i), player_table)
    end
  end
end

M.events = {
  [defines.events.on_selected_entity_changed] = function(e)
    local player = game.get_player(e.player_index)
    if not player then
      return
    end
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
  end,

  [defines.events.on_player_created] = function(e)
    player_data.init(e.player_index)
  end,

  [defines.events.on_player_removed] = function(e)
    global.players[e.player_index] = nil
  end,

  [defines.events.on_player_changed_position] = function(e)
    local player_table = global.players[e.player_index]
    if player_table and player_table.flags.recheck_on_move then
      local player = game.get_player(e.player_index)
      check_selected(player, player_table)
    end
  end,

  [defines.events.on_tick] = function()
    if next(global.repairing_players) then
      repair.iterate()
    end
    if next(global.deconstructing_players) then
      deconstruction.iterate()
    end
  end,
}

handler.add_lib(M)
