local constants = {}

constants.arc_color = {r = 0.8, g = 0.2, b = 0.2, a = 0.75}

-- you can't read the god or editor controllers' mining speed, so here they are hardcoded
constants.controller_mining_speeds = {
  [defines.controllers.editor] = 6,
  [defines.controllers.god] = 1
}

constants.setting_names = {
  ["moc-enable-construction"] = "enable_construction",
  ["moc-enable-upgrading"] = "enable_upgrading",
  ["moc-enable-deconstruction"] = "enable_deconstruction"
}

return constants