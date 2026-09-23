local var_0_0 = mvector3.distance
local var_0_1 = mvector3.set
local var_0_2 = mvector3.set_z
local var_0_3 = next
local var_0_4 = Vector3()

local function var_0_5(arg_1_0, arg_1_1)
	var_0_1(var_0_4, arg_1_1)
	var_0_2(var_0_4, arg_1_0.z)

	return var_0_0(arg_1_0, var_0_4)
end

function ActionSpooc.complete(arg_2_0)
	return arg_2_0._beating_end_t and arg_2_0._beating_end_t < TimerManager:game():time() and (not arg_2_0:is_flying_strike() or arg_2_0._last_vel_z >= 0)
end

function ActionSpooc._get_current_max_walk_speed(arg_3_0, arg_3_1)
	if arg_3_1 == "l" or arg_3_1 == "r" then
		arg_3_1 = "strafe"
	end

	local var_3_0 = arg_3_0._common_data.char_tweak.move_speed[arg_3_0._ext_anim.pose][arg_3_0._haste][arg_3_0._stance.name][arg_3_1]

	if not arg_3_0._is_local and arg_3_0:_husk_needs_speedup() then
		var_3_0 = var_3_0 * (1 + (Unit.occluded(arg_3_0._unit) and 1 or CopActionWalk.lod_multipliers[arg_3_0._ext_base:lod_stage()] or 1))
	end

	return var_3_0
end

function ActionSpooc._husk_needs_speedup(arg_4_0)
	local var_4_0 = arg_4_0._ext_movement._queued_actions

	if var_4_0 and var_0_3(var_4_0) then
		return true
	elseif #arg_4_0._nav_path > 2 then
		local var_4_1 = arg_4_0._common_data.pos
		local var_4_2 = 0

		for iter_4_0 = 2, #arg_4_0._nav_path do
			local var_4_3 = arg_4_0._nav_path[iter_4_0]

			var_4_2 = var_4_2 + var_0_5(var_4_1, var_4_3)
			var_4_1 = var_4_3
		end

		if var_4_2 > 300 then
			return true
		end
	end
end
