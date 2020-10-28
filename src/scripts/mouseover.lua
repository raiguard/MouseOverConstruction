local mouseover = {}

local function get_first_item(inventory, entity_prototype)
  for _, item_stack in ipairs(entity_prototype.items_to_place_this) do
    local count = inventory.get_item_count(item_stack.name)
    if count >= item_stack.count then
      return item_stack
    end
  end
end

function mouseover.construct(player, entity)
  local inventory = player.get_main_inventory()
  local use_item = get_first_item(inventory, game.entity_prototypes[entity.ghost_name])
  if use_item then
    inventory.remove(use_item)
    entity.revive{raise_revive = true}
  end
end

function mouseover.upgrade(player, entity, upgrade_prototype)
  local inventory = player.get_main_inventory()
  local use_item = get_first_item(inventory, upgrade_prototype)
  if use_item then
    local upgraded_entity = player.surface.create_entity{
      name = upgrade_prototype.name,
      position = entity.position,
      direction = entity.direction,
      force = entity.force,
      player = player,
      fast_replace = true,
      raise_built = true
    }
    if upgraded_entity then
      player.play_sound{
        path = "entity-build/"..upgraded_entity.name,
        position = upgraded_entity.position
      }
    end
  end
end

function mouseover.deconstruct(player, entity)
  local name = entity.name
  local position = entity.position
  if player.mine_entity(entity) then
    player.play_sound{
      path = "entity-mined/"..name,
      position = position
    }
  end
end

return mouseover