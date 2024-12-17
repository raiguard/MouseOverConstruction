local deconstruction = require("scripts.deconstruction")
local repair = require("scripts.repair")

local handler = require("__core__.lualib.event_handler")

handler.add_lib(require("scripts.shortcut"))

-- -----------------------------------------------------------------------------
-- COMMON FUNCTIONS

--- @param item_source LuaItemStack|LuaInventory
--- @param entity_prototype LuaEntityPrototype|LuaTilePrototype
--- @param quality LuaQualityPrototype
local function get_first_item(item_source, entity_prototype, quality)
  local is_inventory = item_source.object_name == "LuaInventory"
  for _, item_to_place in pairs(entity_prototype.items_to_place_this) do
    local count = 0
    if is_inventory then
      count = item_source.get_item_count({ name = item_to_place.name, quality = quality })
    else
      count = item_source.name == item_to_place.name and item_source.quality == quality and item_source.count or 0
    end
    if count >= item_to_place.count then
      item_to_place.quality = quality.name
      return item_to_place
    end
  end
end

--- @param item_source LuaItemStack|LuaInventory
--- @param player LuaPlayer
--- @param entity LuaEntity
--- @param upgrade_prototype LuaEntityPrototype
--- @param upgrade_quality LuaQualityPrototype
local function upgrade_entity(item_source, player, entity, upgrade_prototype, upgrade_quality)
  local is_inventory = item_source.object_name == "LuaInventory"
  local use_item = get_first_item(item_source, upgrade_prototype, upgrade_quality)
  if use_item then
    local upgraded_entity = player.surface.create_entity({
      name = upgrade_prototype.name,
      position = entity.position,
      direction = entity.direction,
      force = entity.force,
      player = player,
      quality = upgrade_quality,
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
local function check_selected(player)
  if not storage.mouseover_active[player.index] then
    return
  end

  local cursor_stack = player.cursor_stack
  if not cursor_stack or not cursor_stack.valid then
    return
  end

  local selected = player.selected
  if not selected then
    return
  end

  if not player.can_reach_entity(selected) then
    storage.recheck_on_move[player.index] = true
    return
  end

  local settings = player.mod_settings
  local is_empty = not cursor_stack.valid_for_read
  local is_repair_tool = not is_empty and cursor_stack.type == "repair-tool"

  local upgrade_prototype, upgrade_quality = selected.get_upgrade_target()
  local selected_name, selected_quality = selected.name, selected.quality
  if upgrade_prototype then
    --- @cast upgrade_quality -?
    selected_name = upgrade_prototype.name
    selected_quality = upgrade_quality
  elseif selected.type == "entity-ghost" then
    selected_name = selected.ghost_name
  end
  local matches_selected = not is_empty
    and cursor_stack.prototype.place_result
    and cursor_stack.prototype.place_result.name == selected_name
    and cursor_stack.quality == selected_quality

  if
    settings["moc-enable-construction"].value
    and selected.type == "entity-ghost"
    and (matches_selected or is_empty or is_repair_tool)
  then
    if
      player.can_place_entity({
        name = selected.ghost_name,
        position = selected.position,
        direction = selected.direction,
      })
    then
      if matches_selected then
        local use_item = get_first_item(cursor_stack, selected.ghost_prototype, selected.quality)
        if use_item then
          local _, revived = selected.revive({ raise_revive = true })
          if revived and revived.valid then
            cursor_stack.count = cursor_stack.count - use_item.count
          end
        end
      else
        local inventory = player.get_main_inventory()
        if inventory then
          local use_item = get_first_item(inventory, selected.ghost_prototype, selected.quality)
          if use_item then
            local _, revived = selected.revive({ raise_revive = true })
            if revived and revived.valid then
              inventory.remove(use_item)
            end
          end
        end
      end
    else
      storage.recheck_on_move[player.index] = true
    end

    return
  end

  if
    settings["moc-enable-repairing"].value
    and is_repair_tool
    and selected.health
    and selected.health < selected.prototype.get_max_health(selected.quality)
    and not player.vehicle
  then
    repair.start(player, selected)
  end

  if
    settings["moc-enable-upgrading"].value
    and selected.to_be_upgraded()
    and (matches_selected or is_empty or is_repair_tool)
  then
    local upgrade_prototype, upgrade_quality = selected.get_upgrade_target()
    if upgrade_prototype then
      --- @cast upgrade_quality -?
      local underground_neighbour = selected.type == "underground-belt" and selected.neighbours or nil --[[@as LuaEntity?]]
      local main_inventory = player.get_main_inventory()
      if not main_inventory then
        return
      end
      local item_source = matches_selected and cursor_stack or main_inventory
      if
        upgrade_entity(item_source, player, selected, upgrade_prototype, upgrade_quality)
        and underground_neighbour
        and underground_neighbour.valid
      then
        local upgrade_target, upgrade_quality = underground_neighbour.get_upgrade_target()
        if upgrade_target then
          --- @cast upgrade_quality -?
          upgrade_entity(item_source, player, underground_neighbour, upgrade_target, upgrade_quality)
        end
      end
    end

    return
  end

  if
    settings["moc-enable-deconstruction"].value
    and selected.to_be_deconstructed()
    and (matches_selected or is_empty or is_repair_tool)
  then
    deconstruction.start(player, selected)
    return
  end
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

local M = {}

function M.on_init()
  --- @type table<uint, MapPosition>
  storage.deconstructing = {}
  --- @type table<uint, MapPosition>
  storage.repairing = {}
  --- @type table<uint, boolean>
  storage.recheck_on_move = {}
end

M.events = {
  [defines.events.on_selected_entity_changed] = function(e)
    storage.recheck_on_move[e.player_index] = nil
    if storage.deconstructing[e.player_index] then
      deconstruction.cancel(e.player_index)
    end
    if storage.repairing[e.player_index] then
      repair.cancel(e.player_index)
    end
    local player = game.get_player(e.player_index)
    if not player then
      return
    end
    check_selected(player)
  end,

  [defines.events.on_player_removed] = function(e)
    storage.players[e.player_index] = nil
  end,

  [defines.events.on_player_changed_position] = function(e)
    if not storage.recheck_on_move[e.player_index] then
      return
    end
    storage.recheck_on_move[e.player_index] = nil

    local player = game.get_player(e.player_index)
    if not player then
      return
    end

    check_selected(player)
  end,

  [defines.events.on_tick] = function()
    if next(storage.repairing) then
      repair.iterate()
    end
    if next(storage.deconstructing) then
      deconstruction.iterate()
    end
  end,
}

handler.add_lib(M)
