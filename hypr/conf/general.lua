-- General look and feel settings
-- See https://wiki.hypr.land/Configuring/Variables/

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 9,
		border_size = 3,
		col = {
			active_border = { colors = { colors.blue, colors.mauve }, angle = 45 },
			inactive_border = "rgba(" .. colors.mantleAlpha .. "aa)",
		},
		-- layout = "master",
		layout = "lua:spiral",
		-- layout = "dwindle",
		resize_on_border = true,
	},
})
