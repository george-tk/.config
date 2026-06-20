-- Autostart Applications
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local home = os.getenv("HOME")

hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("/usr/lib/xdg-desktop-portal")
    hl.exec_cmd("/usr/lib/xdg-desktop-portal-gtk")
    hl.exec_cmd("waybar")
    hl.exec_cmd("python3 " .. home .. "/.config/scripts/waybar_sync.py")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("dunst")
    hl.exec_cmd(home .. "/.config/scripts/keybindings.sh")
end)

-- Load configuration from ML4W Hyprland Settings App (if uncommented in conf)
-- hl.exec_cmd(home .. "/.config/ml4w-hyprland-settings/hyprctl.sh")
