local state = {
	ratio = 0.5,
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
				target:place(ctx:split(area, side, state.ratio))
				area = ctx:split(area, opposite[side], 1.0 - state.ratio)
			end
		end
	end,

	layout_msg = function(ctx, msg)
		local command, arg = msg:match("^(%S+)%s*(.*)$")
		local n = #ctx.targets

		if command == "default" then
			state.ratio = clamp(0.5, 0.1, 0.9)
		elseif command == "resizestep" then
			-- Expects a value like "0.05" or "-0.05"
			local step = tonumber(arg) or 0
			state.ratio = clamp(state.ratio + step, 0.1, 0.9)
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
