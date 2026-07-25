--  _   _                  _                 _  
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| | 
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` | 
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| | 
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_| 
--        |___/|_|                              
--  
-- ----------------------------------------------------- 
-- Full documentation https://wiki.hypr.land/Configuring/Start/

-- Load theme colors
colors = require("mocha")

-- Load modular configurations
require("conf/monitor")
require("conf/autostart")
require("conf/cursor")
require("conf/environments")
require("conf/input")
require("conf/general")
require("conf/decoration")
require("conf/animations")
require("conf/layouts")
require("conf/gestures")
require("conf/misc")
require("conf/windowrules")
require("conf/binds")

-- Main autostarts
hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/scripts/rotate-wallpaper.sh --init")
end)
