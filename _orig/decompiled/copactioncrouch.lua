local var_0_0 = Idstring("base")

function CopActionCrouch.init(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0._ext_movement = arg_1_2.ext_movement

	local var_1_0 = arg_1_2.ext_anim

	arg_1_0._ext_anim = var_1_0

	if not arg_1_2.ext_movement._actions.walk._walk_anim_lengths.crouch then
		return
	end

	if arg_1_2.active_actions[2] and arg_1_2.active_actions[2]._nav_link then
		return
	end

	local var_1_1

	if var_1_0.move then
		local var_1_2

		if var_1_0.run_start_turn then
			var_1_2 = arg_1_2.ext_movement._actions.walk._walk_anim_lengths.crouch[arg_1_2.stance.name].run_start_turn[var_1_0.move_side]
		elseif var_1_0.run_start then
			var_1_2 = arg_1_2.ext_movement._actions.walk._walk_anim_lengths.crouch[arg_1_2.stance.name].run_start[var_1_0.move_side]
		elseif var_1_0.run_stop then
			var_1_2 = arg_1_2.ext_movement._actions.walk._walk_anim_lengths.crouch[arg_1_2.stance.name].run_stop[var_1_0.move_side]
		else
			var_1_2 = arg_1_2.ext_movement._actions.walk._walk_anim_lengths
			var_1_2 = var_1_2 and var_1_2.crouch[arg_1_2.stance.name]
			var_1_2 = var_1_2 and var_1_2[var_1_0.run and "run" or "walk"]
			var_1_2 = var_1_2 and var_1_2[var_1_0.move_side] or 29
		end

		var_1_1 = arg_1_2.machine:segment_relative_time(var_0_0) * var_1_2
	end

	if arg_1_2.ext_movement:play_redirect("crouch", var_1_1) then
		if not arg_1_1.syncless and Network:is_server() then
			arg_1_2.ext_network:send("set_pose", 2)
		end

		arg_1_0._ext_movement:enable_update()

		return true
	end
end
