return {
  ["1.1.0"] = function()
    global.repairing_players = {}
  end,
  ["1.1.1"] = function()
    -- the previous version was setting this flag erroneously
    for _, player_table in pairs(global.players) do
      player_table.flags.repair = nil
    end
  end
}