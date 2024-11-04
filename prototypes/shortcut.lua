data:extend({
  {
    type = "shortcut",
    name = "moc-toggle",
    icons = {
      {
        icon = "__MouseOverConstruction__/graphics/shortcut-x32.png",
        icon_size = 32,
        -- y = 0,
        -- mipmap_count = 2,
        -- flags = { "icon" },
      },
    },
    -- disabled_icon = {
    --   filename = "__MouseOverConstruction__/graphics/shortcut-x32.png",
    --   y = 32,
    --   size = 32,
    --   mipmap_count = 2,
    --   flags = { "icon" },
    -- },
    small_icons = {
      {
        icon = "__MouseOverConstruction__/graphics/shortcut-x24.png",
        icon_size = 24,
        -- y = 0,
        -- mipmap_count = 2,
        -- flags = { "icon" },
      },
    },
    -- disabled_small_icon = {
    --   filename = "__MouseOverConstruction__/graphics/shortcut-x24.png",
    --   y = 24,
    --   size = 24,
    --   mipmap_count = 2,
    --   flags = { "icon" },
    -- },
    action = "lua",
    toggleable = true,
    associated_control_input = "moc-toggle",
  },
})
