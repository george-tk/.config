-- Dynamic Workspace Consolidation, Icon Management & Event Listeners
-- See https://wiki.hypr.land/

local ICON_MAP = {
	kitty = "",
	alacritty = "",
	firefox = "",
	["brave-browser"] = "",
	["google-chrome"] = "",
	youtube = "󰗃",
	gmail = "󰊫",
	gemini = "󰧑",
	code = "",
	discord = "󰙯",
	spotify = "󰓇",
	thunar = "",
	nautilus = "",
	["org.gnome.nautilus"] = "",
	pavucontrol = "",
	["blueman-manager"] = "󰂯",
	neovim = ""
}

local function get_workspace_icon(win)
	if not win then
		return ""
	end
	local cls = (win.class or ""):lower()
	local title = (win.title or ""):lower()

	-- Check web apps by class or title first
	if cls:find("youtube", 1, true) or title:find("youtube", 1, true) then
		return "󰗃"
	elseif cls:find("gmail", 1, true) or title:find("gmail", 1, true) or cls:find("mail.google.com", 1, true) then
		return "󰊫"
	elseif cls:find("gemini", 1, true) or title:find("gemini", 1, true) then
		return "󰧑"
	end

	for key, icon in pairs(ICON_MAP) do
		if cls:find(key, 1, true) or key:find(cls, 1, true) then
			return icon
		end
	end
	return ""
end

local last_ws_icons = {}

-- Lightweight function to update Waybar workspace icons with ZERO window movement overhead
local function update_workspace_icons(windows, active_win)
	active_win = active_win or hl.get_active_window()
	windows = windows or hl.get_windows()
	local ws_icon_map = {}

	if windows then
		for _, w in ipairs(windows) do
			if w.mapped ~= false and not w.hidden and w.workspace and w.workspace.id and w.workspace.id > 0 then
				local ws_id = w.workspace.id
				local w_hist = w.focus_history_id or w.focusHistoryID or 9999

				if active_win and w.address and active_win.address and w.address == active_win.address then
					w_hist = -1
				end

				local current_master = ws_icon_map[ws_id]
				if not current_master or w_hist < current_master.hist then
					ws_icon_map[ws_id] = { win = w, hist = w_hist }
				end
			end
		end
	end

	local current_workspaces = hl.get_workspaces()
	local active_ws_ids = {}
	if current_workspaces then
		for _, ws in ipairs(current_workspaces) do
			active_ws_ids[ws.id] = true
			local master_entry = ws_icon_map[ws.id]
			local icon = "·"
			if master_entry and master_entry.win then
				icon = get_workspace_icon(master_entry.win)
			end
			local unique_name = icon .. string.rep("\u{200B}", (ws.id or 1) - 1)
			if last_ws_icons[ws.id] ~= unique_name then
				last_ws_icons[ws.id] = unique_name
				hl.dispatch(hl.dsp.workspace.rename({ workspace = ws.id, name = unique_name }))
			end
		end
	end

	-- Clear cache for destroyed workspaces so recreated workspaces get properly renamed
	for ws_id, _ in pairs(last_ws_icons) do
		if not active_ws_ids[ws_id] then
			last_ws_icons[ws_id] = nil
		end
	end
end

-- Helper function to compact all workspaces into consecutive IDs starting at 1 (1, 2, 3...)
local function compact_workspaces()
	local windows = hl.get_windows()
	local occupied_map = {}
	local occupied_ids = {}

	if windows then
		for _, w in ipairs(windows) do
			if w.mapped ~= false and not w.hidden and w.workspace and w.workspace.id and w.workspace.id > 0 and not w.pinned then
				local ws_id = w.workspace.id
				if not occupied_map[ws_id] then
					occupied_map[ws_id] = {}
					table.insert(occupied_ids, ws_id)
				end
				table.insert(occupied_map[ws_id], w)
			end
		end
	end

	table.sort(occupied_ids)

	local remap = {}
	for new_id, old_id in ipairs(occupied_ids) do
		remap[old_id] = new_id
	end

	-- 1. Move windows to compact workspace IDs
	for old_id, new_id in pairs(remap) do
		if old_id ~= new_id then
			local wins_to_move = occupied_map[old_id]
			for _, w in ipairs(wins_to_move) do
				hl.dispatch(hl.dsp.window.move({ window = "address:" .. w.address, workspace = tostring(new_id) }))
			end
		end
	end

	-- 2. Compact Monitors
	local monitors = hl.get_monitors()
	local num_occupied = #occupied_ids
	if monitors then
		for _, mon in ipairs(monitors) do
			local aws = mon.active_workspace
			if aws and aws.id then
				local target_ws = aws.id
				if remap[aws.id] then
					target_ws = remap[aws.id]
				elseif aws.id > math.max(num_occupied, 1) then
					local other_active = {}
					for _, m2 in ipairs(monitors) do
						if m2.name ~= mon.name and m2.active_workspace then
							local other_ws = remap[m2.active_workspace.id] or m2.active_workspace.id
							other_active[other_ws] = true
						end
					end
					for w = 1, 10 do
						if not other_active[w] then
							target_ws = w
							break
						end
					end
				end

				if target_ws ~= aws.id then
					hl.dispatch(hl.dsp.workspace.move({ workspace = target_ws, monitor = mon.name }))
				end
			end
		end
	end

	-- 3. Update Workspace Names with Icons for Waybar (Reusing queried windows list)
	update_workspace_icons(windows)
end

-- Helper function for dynamic workspace navigation & consolidation
local function smart_switch_workspace(target_ws)
	return function()
		local monitors = hl.get_monitors()
		local active_mon = hl.get_active_monitor()
		local target_mon = nil
		local used_workspaces = {}

		if monitors then
			for _, mon in ipairs(monitors) do
				if mon.active_workspace and mon.active_workspace.id and mon.active_workspace.id > 0 then
					used_workspaces[mon.active_workspace.id] = true
					if mon.active_workspace.id == target_ws then
						target_mon = mon
					end
				end
			end
		end

		local windows = hl.get_windows()
		local occupied_workspaces = {}
		if windows then
			for _, w in ipairs(windows) do
				if w.workspace and w.workspace.id and w.workspace.id > 0 then
					used_workspaces[w.workspace.id] = true
					occupied_workspaces[w.workspace.id] = true
				end
			end
		end

		local current_ws_id = active_mon and active_mon.active_workspace and active_mon.active_workspace.id
		local is_current_empty = current_ws_id and not occupied_workspaces[current_ws_id]
		local is_target_unused = not used_workspaces[target_ws]

		if target_mon and active_mon and target_mon.name ~= active_mon.name then
			-- target_mon loses target_ws and needs a replacement workspace.
			-- 1. Look for an un-displayed occupied workspace (containing windows) not used by either monitor
			local replacement_ws = nil
			for ws_id, _ in pairs(occupied_workspaces) do
				if ws_id ~= target_ws and ws_id ~= current_ws_id then
					replacement_ws = ws_id
					break
				end
			end

			-- 2. If no un-displayed occupied workspace exists, use current_ws_id
			if not replacement_ws then
				replacement_ws = current_ws_id
			end

			hl.dispatch(hl.dsp.workspace.move({ workspace = replacement_ws, monitor = target_mon.name }))
			hl.dispatch(hl.dsp.workspace.move({ workspace = target_ws, monitor = active_mon.name }))
			hl.dispatch(hl.dsp.focus({ monitor = active_mon.name }))
			hl.dispatch(hl.dsp.focus({ workspace = tostring(target_ws) }))

		elseif is_target_unused and is_current_empty then
			-- Current monitor is ALREADY sitting on an empty workspace! Stay on current empty workspace.
			compact_workspaces()
			return

		elseif is_target_unused then
			-- Current monitor has windows. Check if ANOTHER monitor is sitting on an empty workspace!
			local empty_mon = nil
			local empty_mon_ws = nil
			if monitors then
				for _, mon in ipairs(monitors) do
					if mon.name ~= active_mon.name and mon.active_workspace then
						local m_ws = mon.active_workspace.id
						if not occupied_workspaces[m_ws] then
							empty_mon = mon
							empty_mon_ws = m_ws
							break
						end
					end
				end
			end

			if empty_mon and empty_mon_ws then
				-- Another monitor is sitting on an empty workspace! Swap so current monitor gets the empty workspace.
				hl.dispatch(hl.dsp.workspace.move({ workspace = current_ws_id, monitor = empty_mon.name }))
				hl.dispatch(hl.dsp.workspace.move({ workspace = empty_mon_ws, monitor = active_mon.name }))
				hl.dispatch(hl.dsp.focus({ monitor = active_mon.name }))
				hl.dispatch(hl.dsp.focus({ workspace = tostring(empty_mon_ws) }))
			else
				-- All active monitors contain windows -> Find lowest unused workspace ID and open it
				local lowest_unused = 1
				for w = 1, 20 do
					if not used_workspaces[w] then
						lowest_unused = w
						break
					end
				end
				local unique_name = "·" .. string.rep("\u{200B}", lowest_unused - 1)
				last_ws_icons[lowest_unused] = unique_name
				hl.dispatch(hl.dsp.workspace.rename({ workspace = lowest_unused, name = unique_name }))
				hl.dispatch(hl.dsp.workspace.move({ workspace = lowest_unused, monitor = "current" }))
				hl.dispatch(hl.dsp.focus({ workspace = tostring(lowest_unused) }))
			end
		else
			-- Target workspace exists (occupied) -> Move to current monitor and focus it
			hl.dispatch(hl.dsp.workspace.move({ workspace = target_ws, monitor = "current" }))
			hl.dispatch(hl.dsp.focus({ workspace = tostring(target_ws) }))
		end

		compact_workspaces()
	end
end

local function smart_move_window(target_ws)
	return function()
		local used_workspaces = {}
		local monitors = hl.get_monitors()
		if monitors then
			for _, mon in ipairs(monitors) do
				if mon.active_workspace and mon.active_workspace.id and mon.active_workspace.id > 0 then
					used_workspaces[mon.active_workspace.id] = true
				end
			end
		end
		local windows = hl.get_windows()
		if windows then
			for _, w in ipairs(windows) do
				if w.workspace and w.workspace.id and w.workspace.id > 0 then
					used_workspaces[w.workspace.id] = true
				end
			end
		end

		if used_workspaces[target_ws] then
			hl.dispatch(hl.dsp.window.move({ workspace = tostring(target_ws) }))
		else
			local lowest_unused = 1
			for w = 1, 20 do
				if not used_workspaces[w] then
					lowest_unused = w
					break
				end
			end
			hl.dispatch(hl.dsp.window.move({ workspace = tostring(lowest_unused) }))
		end

		compact_workspaces()
	end
end

local function smart_focus_monitor(dir)
	return function()
		local active_mon = hl.get_active_monitor()
		local monitors = hl.get_monitors()
		local target_mon = nil

		if monitors and active_mon then
			for _, mon in ipairs(monitors) do
				if mon.name ~= active_mon.name then
					target_mon = mon
					break
				end
			end
		end

		if active_mon and target_mon then
			local windows = hl.get_windows()
			local occupied = {}
			if windows then
				for _, w in ipairs(windows) do
					if w.workspace and w.workspace.id and w.workspace.id > 0 then
						occupied[w.workspace.id] = true
					end
				end
			end

			local active_ws_id = active_mon.active_workspace and active_mon.active_workspace.id
			local is_active_empty = active_ws_id and not occupied[active_ws_id]

			if is_active_empty then
				local replacement = nil
				for ws_id, _ in pairs(occupied) do
					if target_mon.active_workspace and ws_id ~= target_mon.active_workspace.id then
						replacement = ws_id
						break
					end
				end

				if replacement then
					hl.dispatch(hl.dsp.focus({ monitor = active_mon.name }))
					hl.dispatch(hl.dsp.focus({ workspace = tostring(replacement) }))
				end
			end

			hl.dispatch(hl.dsp.focus({ monitor = target_mon.name }))
		else
			hl.dispatch(hl.dsp.focus({ monitor = dir }))
		end

		compact_workspaces()
	end
end

-- Auto-update workspace names/icons and compact on window open, close, and workspace events
hl.on("window.active", function()
	update_workspace_icons()
end)

hl.on("workspace.active", function()
	update_workspace_icons()
end)

hl.on("monitor.focused", function()
	update_workspace_icons()
end)

hl.on("workspace.created", function()
	update_workspace_icons()
end)

hl.on("workspace.removed", function()
	update_workspace_icons()
end)

hl.on("hyprland.start", function()
	compact_workspaces()
end)

-- Initial compaction and icon assignment on startup
compact_workspaces()

return {
	compact = compact_workspaces,
	smart_switch = smart_switch_workspace,
	smart_move = smart_move_window,
	smart_focus_monitor = smart_focus_monitor,
}
