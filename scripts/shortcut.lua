--- @param e EventData.on_lua_shortcut|EventData.CustomInputEvent
local function toggle_mouseover(e)
  local name = e.input_name or e.prototype_name
  if name ~= "moc-toggle" then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local new_value = not global.mouseover_active[e.player_index]
  global.mouseover_active[e.player_index] = new_value
  player.set_shortcut_toggled("moc-toggle", new_value)
  if e.input_name then
    player.create_local_flying_text({
      text = new_value and { "message.moc-enabled" } or { "message.moc-disabled" },
      create_at_cursor = true,
    })
  end
end

local M = {}

function M.on_init()
  --- @type table<uint, boolean>
  global.mouseover_active = {}
end

M.on_configuration_changed = M.on_init

M.events = {
  [defines.events.on_lua_shortcut] = toggle_mouseover,
  ["moc-toggle"] = toggle_mouseover,
}

return M
