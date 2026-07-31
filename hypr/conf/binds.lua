-- Keybindings Configuration
-- See https://wiki.hypr.land/Configuring/Binds/

local mainMod = "SUPER"
local home = os.getenv("HOME")

local ws = require("conf/workspaces")

-- Rofi
hl.bind(
	mainMod .. " + " .. mainMod .. "_L",
	hl.dsp.exec_cmd("~/.config/scripts/toggle-launcher.sh"),
	{ release = true, description = "Menu" }
) -- Menu
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(home .. "/.config/rofi/wifi-menu.sh"), { description = "WiFi Menu" })
hl.bind(
	mainMod .. " + SHIFT + I",
	hl.dsp.exec_cmd([[sh -c "~/.config/scripts/window_switcher.py; touch /tmp/rofi_cooldown; (sleep 0.2 && rm -f /tmp/rofi_cooldown) &"]]),
	{ description = "Window Menu" }
)
hl.bind(
	mainMod .. " + K",
	hl.dsp.exec_cmd(home .. "/.config/scripts/keybindings.sh"),
	{ description = "Keybinds Menu" }
)
hl.bind(
	mainMod .. " + V",
	hl.dsp.exec_cmd(home .. "/.config/scripts/cliphist-menu.sh"),
	{ description = "Clipboard Menu" }
)

-- Applications
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty"), { description = "Open Terminal" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("kitty --class neovim nvim"), { description = "Open Neovim" })
hl.bind(
	mainMod .. " + A",
	hl.dsp.exec_cmd(home .. "/.config/scripts/open_web_app.sh https://gemini.google.com/"),
	{ description = "Open Gemini" }
)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"), { description = "Open File Manager" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("pavucontrol"), { description = "Open Audio Control" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("google-chrome-stable --disable-features=Vulkan --ozone-platform-hint=auto"), { description = "Open Web Browser" })
hl.bind(
	mainMod .. " + G",
	hl.dsp.exec_cmd(home .. "/.config/scripts/open_web_app.sh https://mail.google.com/"),
	{ description = "Open Gmail" }
)
hl.bind(
	mainMod .. " + Y",
	hl.dsp.exec_cmd(home .. "/.config/scripts/open_web_app.sh https://www.youtube.com/"),
	{ description = "Open YouTube" }
)
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("blueman-manager"), { description = "Open Bluetooth Manager" })

-- Navigation (Windows)
hl.bind(mainMod .. " + Q", function()
	hl.dispatch(hl.dsp.window.close())
	ws.compact()
end, { description = "Close Window" })
hl.bind(mainMod .. " + Tab", hl.dsp.layout("cyclenext"), { description = "Cycle Next Window" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.layout("cycleprev"), { description = "Cycle Previous Window" })
hl.bind(mainMod .. " + ALT + Tab", hl.dsp.layout("swapnext"), { description = "Swap Next Window" })
hl.bind(mainMod .. " + SHIFT + ALT + Tab", hl.dsp.layout("swapprev"), { description = "Swap Previous Window" })

-- Navigation (Workspace)
hl.bind(mainMod .. " + W", ws.smart_switch("empty"), { description = "Next Workspace" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.focus({ workspace = "r-1" }), { description = "Previous Workspace" })
hl.bind(
	mainMod .. " + ALT + W",
	hl.dsp.window.move({ workspace = "r+1" }),
	{ description = "Move Window to Next Workspace" }
)
hl.bind(
	mainMod .. " + SHIFT + ALT + W",
	hl.dsp.window.move({ workspace = "r-1" }),
	{ description = "Move Window to Previous Workspace" }
)
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll Next Workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll Previous Workspace" })

-- Navigation (Display)
hl.bind(mainMod .. " + D", ws.smart_focus_monitor("+1"), { description = "Focus Next Monitor" })
hl.bind(mainMod .. " + SHIFT + D", ws.smart_focus_monitor("-1"), { description = "Focus Previous Monitor" })
hl.bind(
	mainMod .. " + ALT + D",
	hl.dsp.window.move({ monitor = "+1" }),
	{ description = "Move Window to Next Monitor" }
)
hl.bind(
	mainMod .. " + SHIFT + ALT + D",
	hl.dsp.window.move({ monitor = "-1" }),
	{ description = "Move Window to Previous Monitor" }
)
hl.bind(
	mainMod .. " + CONTROL + D",
	hl.dsp.workspace.move({ monitor = "+1" }),
	{ description = "Move Workspace to Next Monitor" }
)
hl.bind(
	mainMod .. " + SHIFT + CONTROL + D",
	hl.dsp.workspace.move({ monitor = "-1" }),
	{ description = "Move Workspace to Previous Monitor" }
)

-- Window Sizes
hl.bind(mainMod .. " + M", hl.dsp.layout("swapwithmaster"), { description = "Swap with Master" })
hl.bind(
	mainMod .. " + SHIFT + M",
	hl.dsp.window.fullscreen({ mode = "maximized" }),
	{ description = "Maximize Window" }
)
hl.bind(
	mainMod .. " + ALT + M",
	hl.dsp.window.fullscreen({ mode = "fullscreen" }),
	{ description = "Fullscreen Window" }
)

-- Large Adjustments (Coarse step: 5%)
hl.bind(mainMod .. " + equal", hl.dsp.layout("resizestep 0.05"), { description = "Expand Focused Window (5%)" })
hl.bind(mainMod .. " + minus", hl.dsp.layout("resizestep -0.05"), { description = "Shrink Focused Window (5%)" })

-- Small Adjustments (Fine SHIFT step: 1%)
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.layout("resizestep 0.01"), { description = "Expand Focused Window (1%)" })
hl.bind(
	mainMod .. " + SHIFT + minus",
	hl.dsp.layout("resizestep -0.01"),
	{ description = "Shrink Focused Window (1%)" }
)
hl.bind(mainMod .. " + ALT + equal", hl.dsp.layout("default"), { description = "Reset Layout Size" })
hl.bind(mainMod .. " + ALT + minus", hl.dsp.layout("default"), { description = "Reset Layout Size" })

-- Directional Resizing (Coarse step: 5%)
hl.bind(mainMod .. " + left", hl.dsp.layout("resizedir left 0.05"), { description = "Resize Left (5%)" })
hl.bind(mainMod .. " + right", hl.dsp.layout("resizedir right 0.05"), { description = "Resize Right (5%)" })
hl.bind(mainMod .. " + up", hl.dsp.layout("resizedir up 0.05"), { description = "Resize Up (5%)" })
hl.bind(mainMod .. " + down", hl.dsp.layout("resizedir down 0.05"), { description = "Resize Down (5%)" })

-- Directional Resizing (Fine SHIFT step: 1%)
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.layout("resizedir left 0.01"), { description = "Resize Left (1%)" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.layout("resizedir right 0.01"), { description = "Resize Right (1%)" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.layout("resizedir up 0.01"), { description = "Resize Up (1%)" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.layout("resizedir down 0.01"), { description = "Resize Down (1%)" })
-- Actions
hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd("hyprlock"), { description = "Lock Screen" })
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("wlogout -b 4"), { description = "Power Menu" })
hl.bind(
	mainMod .. " + S",
	hl.dsp.exec_cmd(home .. "/.config/scripts/screenshot.sh --region"),
	{ description = "Screenshot (Region)" }
)
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.exec_cmd(home .. "/.config/scripts/screenshot.sh --window"),
	{ description = "Screenshot (Window)" }
)
hl.bind(
	mainMod .. " + ALT + S",
	hl.dsp.exec_cmd(home .. "/.config/scripts/screenshot.sh --fullscreen"),
	{ description = "Screenshot (Fullscreen)" }
)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ description = "Raise Volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"),
	{ description = "Lower Volume" }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+"), { description = "Raise Brightness" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { description = "Lower Brightness" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Toggle Mute" })
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ description = "Toggle Mic Mute" }
)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Play/Pause Media" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { description = "Next Track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { description = "Previous Track" })
hl.bind(mainMod .. " + ALT + Space", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Play/Pause Media (Alt)" })
hl.bind(mainMod .. " + ALT + Right", hl.dsp.exec_cmd("playerctl next"), { description = "Next Track (Alt)" })
hl.bind(mainMod .. " + ALT + Left", hl.dsp.exec_cmd("playerctl previous"), { description = "Previous Track (Alt)" })
hl.bind("XF86WLAN", hl.dsp.exec_cmd("nmcli radio wifi toggle"), { description = "Toggle WiFi" })
hl.bind("XF86Refresh", hl.dsp.exec_cmd("xdotool key F5"), { description = "Refresh" })

-- Triggered when the lid is closed
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })

-- Triggered when the lid is opened
hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "enable" }), { locked = true })

-- Navigate workspaces by number (Pure Lua Consolidation & Monitor Swapping)
for i = 1, 9 do
	hl.bind(
		mainMod .. " + " .. i,
		ws.smart_switch(i),
		{ description = "Switch to Workspace " .. i }
	)
	hl.bind(
		mainMod .. " + SHIFT + " .. i,
		ws.smart_move(i),
		{ description = "Move Window to Workspace " .. i }
	)
end
hl.bind(mainMod .. " + 0", ws.smart_switch(10), { description = "Switch to Workspace 10" })
hl.bind(
	mainMod .. " + SHIFT + 0",
	ws.smart_move(10),
	{ description = "Move Window to Workspace 10" }
)

-- Global Media Control
hl.bind(
    mainMod .. " + space",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { description = "Toggle Media Play/Pause" }
)
