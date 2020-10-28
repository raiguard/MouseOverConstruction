local mouseover = {}

function mouseover.construct(player, entity)
  local inventory = player.get_main_inventory()
  local use_item
  local ghost_prototype = game.entity_prototypes[entity.ghost_name]
  for _, item_stack in ipairs(ghost_prototype.items_to_place_this) do
    local count = inventory.get_item_count(item_stack.name)
    if count >= item_stack.count then
      use_item = item_stack
      break
    end
  end

  if use_item then
    inventory.remove(use_item)
    entity.revive{raise_revive = true}
  end
end

return mouseover