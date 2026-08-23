-- Monitor Layout Configuration
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local home = os.getenv("HOME")
local monitors_conf = home .. "/.config/hypr/monitors.conf"

-- Load configurations saved by nwg-displays if available
local ok = pcall(require, "monitors")
if not ok then
	local file = io.open(monitors_conf, "r")
	if file then
		for raw_line in file:lines() do
			local trimmed = raw_line:match("^%s*(.-)%s*$")
			if trimmed and trimmed:match("^monitor%s*=") then
				local val = trimmed:match("^monitor%s*=%s*(.*)$")
				if val and val ~= "" and not val:match("^#") then
					local parts = {}
					for part in string.gmatch(val, "[^,]+") do
						table.insert(parts, (part:match("^%s*(.-)%s*$")))
					end
					if #parts > 0 then
						local output, mode, position, scale
						if string.sub(val, 1, 1) == "," then
							output = ""
							mode = parts[1] or "preferred"
							position = parts[2] or "auto"
							scale = parts[3] or "1"
						else
							output = parts[1] or ""
							mode = parts[2] or "preferred"
							position = parts[3] or "auto"
							scale = parts[4] or "1"
						end
						hl.monitor({
							output = output,
							mode = mode,
							position = position,
							scale = scale,
						})
					end
				end
			end
		end
		file:close()
	end
end

-- Default fallback rule for any unconfigured / new displays
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1",
})

