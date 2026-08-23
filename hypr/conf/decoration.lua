-- Decoration Configuration
-- See https://wiki.hypr.land/Configuring/Variables/

hl.config({
    decoration = {
        rounding = 0,
        active_opacity = 1.0,
        inactive_opacity = 0.94,
        dim_inactive = true,
        dim_strength = 0.08,

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            new_optimizations = true,
        },
        shadow = {
            enabled = false,
        },
    },
})
