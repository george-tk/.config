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
ws = require("conf/workspaces")
_G.workspace = function(id)
	return hl.dsp.focus({ workspace = tostring(id) })
end
switch_workspace = function(id)
	local num = tonumber(id)
	if not num and type(id) == "string" then
		local raw = id:gsub("^name:", "")
		local workspaces = hl.get_workspaces()
		if workspaces then
			for _, ws_entry in ipairs(workspaces) do
				if ws_entry.name == raw or ws_entry.name == id then
					num = ws_entry.id
					break
				end
			end
		end
		if not num then
			local _, zw_count = raw:gsub("\u{200B}", "")
			if zw_count and zw_count >= 0 then
				num = zw_count + 1
			end
		end
	end

	if num then
		ws.smart_switch(num)()
	else
		hl.dispatch(hl.dsp.focus({ workspace = tostring(id) }))
	end
end
require("conf/binds")

-- Main autostarts
hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/scripts/rotate-wallpaper.sh --init")
end)
