data:extend{
  {
    type = "bool-setting",
    name = "moc-instant-deconstruction",
    setting_type = "runtime-global",
    default_value = false,
    order = "a"
  },
  {
    type = "bool-setting",
    name = "moc-enable-construction",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "a"
  },
  {
    type = "bool-setting",
    name = "moc-enable-upgrading",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "b"
  },
  {
    type = "bool-setting",
    name = "moc-enable-deconstruction",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "c"
  }
}