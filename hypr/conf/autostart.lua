-- Autostart Applications
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local home = os.getenv("HOME")

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("waybar")
	hl.exec_cmd("dunst")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd(home .. "/.config/scripts/keybindings.sh")
	-- hl.exec_cmd("nm-applet --indicator") -- Disabled to prevent redundant Wi-Fi icon in tray (use Waybar network module)
	-- hl.exec_cmd("blueman-applet") -- Disabled to prevent redundant Bluetooth icon in tray (use Waybar bluetooth module)
end)
