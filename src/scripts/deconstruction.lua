local math = require("__flib__.math")

local constants = require("constants")

local mouseover = require("scripts.mouseover")

local deconstruction = {}

function deconstruction.start(player, player_table, entity)
  -- figure out the player's mining speed
  local mining_speed
  if player.controller_type == defines.controllers.character then
    mining_speed = (1 + player.force.manual_mining_speed_modifier) * (1 + player.character_mining_speed_modifier)
  else
    mining_speed = constants.controller_mining_speeds[player.controller_type]
  end

  -- only bother if the player can actually mine things
  if mining_speed then
    global.deconstructing_players[player.index] = true
    player_table.flags.deconstructing = true
    player_table.deconstruction = {
      started_tick = game.ticks_played,
      entity = entity,
      mining_time = (entity.prototype.mineable_properties.mining_time / mining_speed) * 60
    }
  end
end

function deconstruction.iterate()
  local tick = game.ticks_played
  for player_index in pairs(global.deconstructing_players) do
    local player = game.get_player(player_index)
    local player_table = global.players[player_index]
    local deconstruction_data = player_table.deconstruction
    local entity = deconstruction_data.entity

    local progress = (tick - deconstruction_data.started_tick) / deconstruction_data.mining_time

    if progress >= 1 then
      mouseover.deconstruct(player, entity)
      deconstruction.cancel(player, player_table)
    else
      -- set player states
      player.walking_state = {walking = false, direction = player.walking_state.direction}
      player.mining_state = {mining = false}

      local arc_id = deconstruction_data.arc_id
      local arc_angle = progress * 360 * math.deg_to_rad
      if arc_id then
        -- update arc angle
        rendering.set_angle(arc_id, arc_angle)
      else
        -- create arc
        deconstruction_data.arc_id = rendering.draw_arc{
          color = constants.arc_color,
          max_radius = 0.7,
          min_radius = 0.5,
          start_angle = -90 * math.deg_to_rad,
          angle = arc_angle,
          target = entity,
          surface = entity.surface,
          players = {player_index}
        }
      end
    end
  end
end

function deconstruction.cancel(player, player_table)
  global.deconstructing_players[player.index] = nil
  player_table.flags.deconstructing = false
  rendering.destroy(player_table.deconstruction.arc_id)
  player_table.deconstruction = nil
end

return deconstruction

