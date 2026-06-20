-- Decoration Configuration
-- See https://wiki.hypr.land/Configuring/Variables/

hl.config({
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 0.9,
        dim_inactive = true,
        dim_strength = 0.1,

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
        },
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(" .. colors.mantleAlpha .. "ee)",
        },
    },
})
