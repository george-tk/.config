-- General look and feel settings
-- See https://wiki.hypr.land/Configuring/Variables/

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 9,
		border_size = 0,
		col = {
			active_border = colors.lavender,
			inactive_border = colors.surface0,
		},
		-- layout = "master",
		layout = "lua:spiral",
		-- layout = "dwindle",
		resize_on_border = true,
	},
})
