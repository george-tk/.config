local state = {
	ratio = 0.50,
	ratios = {},
	offset = 0,
	last_master_idx = nil, -- Tracks the previous window index for the master toggle
}

-- We alternate strictly between cutting from the Left and cutting from the Top
local sides = { "left", "top" }

local opposite = {
	left = "right",
	top = "bottom",
	-- Keep these just in case other parts of the script look for them
	right = "left",
	bottom = "top",
}

local function clamp(x, min, max)
	return math.max(min, math.min(max, x))
end

local function get_ratio(i)
	if not state.ratios then
		state.ratios = {}
	end
	if not state.ratios[i] then
		state.ratios[i] = state.ratio or 0.5
	end
	return state.ratios[i]
end

local function set_ratio(i, val)
	if not state.ratios then
		state.ratios = {}
	end
	state.ratios[i] = clamp(val, 0.1, 0.9)
end

local function get_active_index(targets)
	for i, target in ipairs(targets) do
		if target.window and target.window.active then
			return i
		end
	end
	return nil
end

hl.layout.register("spiral", {
	recalculate = function(ctx)
		local n = #ctx.targets
		if n == 0 then
			return
		end

		local area = ctx.area

		for i, target in ipairs(ctx.targets) do
			if i == n then
				target:place(area)
			else
				local side = sides[((i - 1 + state.offset) % #sides) + 1]
				local r = get_ratio(i)
				target:place(ctx:split(area, side, r))
				area = ctx:split(area, opposite[side], 1.0 - r)
			end
		end
	end,

	layout_msg = function(ctx, msg)
		local command, arg = msg:match("^(%S+)%s*(.*)$")
		local n = #ctx.targets

		if command == "default" then
			state.ratio = 0.5
			state.ratios = {}
		elseif command == "resizestep" then
			-- Expects a value like "0.05" or "-0.05"
			local step = tonumber(arg) or 0
			local active_idx = get_active_index(ctx.targets)
			if active_idx and n > 1 then
				for i = 1, n - 1 do
					if i < active_idx then
						-- Ancestor split: to expand active_idx, we decrease the ratio
						local r = get_ratio(i)
						set_ratio(i, r - step)
					elseif i == active_idx then
						-- Immediate split: to expand active_idx, we increase the ratio
						local r = get_ratio(i)
						set_ratio(i, r + step)
					end
				end
			else
				state.ratio = clamp(state.ratio + step, 0.1, 0.9)
			end
		elseif command == "resizedir" then
			local dir, step_str = arg:match("^(%S+)%s*(.*)$")
			local step = tonumber(step_str) or 0.05
			local active_idx = get_active_index(ctx.targets)
			if active_idx and n > 1 then
				local function get_split_side(idx)
					return sides[((idx - 1 + state.offset) % #sides) + 1]
				end

				if dir == "left" or dir == "right" then
					-- Adjust right edge (split active_idx, if it's a "left" split)
					if active_idx < n and get_split_side(active_idx) == "left" then
						local r = get_ratio(active_idx)
						if dir == "right" then
							set_ratio(active_idx, r + step)
						else
							set_ratio(active_idx, r - step)
						end
					end
					-- Adjust left edges (all ancestor "left" splits)
					for i = 1, active_idx - 1 do
						if get_split_side(i) == "left" then
							local r = get_ratio(i)
							if dir == "left" then
								set_ratio(i, r - step)
							else
								set_ratio(i, r + step)
							end
						end
					end
				elseif dir == "up" or dir == "down" then
					-- Adjust bottom edge (split active_idx, if it's a "top" split)
					if active_idx < n and get_split_side(active_idx) == "top" then
						local r = get_ratio(active_idx)
						if dir == "down" then
							set_ratio(active_idx, r + step)
						else
							set_ratio(active_idx, r - step)
						end
					end
					-- Adjust top edges (all ancestor "top" splits)
					for i = 1, active_idx - 1 do
						if get_split_side(i) == "top" then
							local r = get_ratio(i)
							if dir == "up" then
								set_ratio(i, r - step)
							else
								set_ratio(i, r + step)
							end
						end
					end
				end
			end
		elseif command == "cyclenext" then
			local active_idx = get_active_index(ctx.targets)
			if active_idx and n > 1 then
				local next_idx = (active_idx % n) + 1
				local target = ctx.targets[next_idx]
				if target and target.window then
					hl.dispatch(hl.dsp.focus({ window = "address:" .. target.window.address }))
				end
			end
		elseif command == "cycleprev" then
			local active_idx = get_active_index(ctx.targets)
			if active_idx and n > 1 then
				local prev_idx = ((active_idx - 2 + n) % n) + 1
				local target = ctx.targets[prev_idx]
				if target and target.window then
					hl.dispatch(hl.dsp.focus({ window = "address:" .. target.window.address }))
				end
			end
		elseif command == "swapwithmaster" then
			local active_idx = get_active_index(ctx.targets)
			if active_idx and n > 1 then
				local target_idx = nil

				if active_idx == 1 then
					target_idx = state.last_master_idx or 2
					if target_idx > n then
						target_idx = 2
					end
				else
					state.last_master_idx = active_idx
					target_idx = 1
				end

				local target = ctx.targets[target_idx]
				if target and target.window then
					hl.dispatch(hl.dsp.window.swap({ with = "address:" .. target.window.address }))
				end
			end
		elseif command == "swapnext" then
			local active_idx = get_active_index(ctx.targets)
			if active_idx and n > 1 then
				local next_idx = (active_idx % n) + 1
				local target = ctx.targets[next_idx]
				if target and target.window then
					hl.dispatch(hl.dsp.window.swap({ with = "address:" .. target.window.address }))
				end
			end
		elseif command == "swapprev" then
			local active_idx = get_active_index(ctx.targets)
			if active_idx and n > 1 then
				local prev_idx = ((active_idx - 2 + n) % n) + 1
				local target = ctx.targets[prev_idx]
				if target and target.window then
					hl.dispatch(hl.dsp.window.swap({ with = "address:" .. target.window.address }))
				end
			end
		else
			return "spiral: expected ratio <0.1..0.9>, grow, shrink, rotate, cyclenext, cycleprev, swapwithmaster, swapnext, or swapprev"
		end

		return true
	end,
})
