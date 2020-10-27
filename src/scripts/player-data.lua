local player_data = {}

function player_data.init(player_index)
  global.players[player_index] = {
    flags = {
      mouseover_enabled = false
    },
    render_objects = {}
  }
end

return player_data