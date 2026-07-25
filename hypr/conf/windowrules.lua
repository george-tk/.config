-- Window Rules Configuration
-- See https://wiki.hypr.land/Configuring/Window-Rules/

-- nmtui: Using the new match syntax and explicit values
hl.window_rule({
    match = { title = "^(nmtui)$" },
    float = true,
    center = true,
    size = { "40%", "40%" },
})

-- Rofi: Handled by animations.conf and waybar_sync script
-- No special rules needed here currently

-- Rofi Frosted Glass Layer Rule
hl.layer_rule({
    match = { namespace = "rofi" },
    blur = true,
})

-- Wlogout Frosted Glass Layer Rule
hl.layer_rule({
    match = { namespace = "wlogout" },
    blur = true,
})
