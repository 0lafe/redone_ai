function CopActionDodge.init(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0._common_data = arg_1_2
	arg_1_0._ext_base = arg_1_2.ext_base
	arg_1_0._ext_movement = arg_1_2.ext_movement
	arg_1_0._ext_anim = arg_1_2.ext_anim
	arg_1_0._body_part = arg_1_1.body_part
	arg_1_0._unit = arg_1_2.unit
	arg_1_0._timeout = arg_1_1.timeout
	arg_1_0._machine = arg_1_2.machine
	arg_1_0._ids_base = Idstring("base")

	local var_1_0 = arg_1_2.ext_movement:play_redirect("dodge")

	if var_1_0 then
		if arg_1_0._ext_anim.upper_body_active and not arg_1_0._ext_anim.upper_body_empty then
			arg_1_0._ext_movement:play_redirect("up_idle")
		end

		arg_1_0._descriptor = arg_1_1
		arg_1_0._last_vel_z = 0

		arg_1_0:_determine_rotation_transition()
		arg_1_0._ext_movement:set_root_blend(false)
		arg_1_0._machine:set_parameter(var_1_0, arg_1_1.variation, 1)

		if arg_1_1.speed then
			arg_1_0._machine:set_speed(var_1_0, arg_1_1.speed)
		end

		arg_1_0._machine:set_parameter(var_1_0, arg_1_1.side, 1)

		if Network:is_server() then
			local var_1_1 = math.clamp(math.floor((arg_1_1.shoot_accuracy or 1) * 10), 0, 10)

			arg_1_2.ext_network:send("action_dodge_start", arg_1_0._body_part, CopActionDodge._get_variation_index(arg_1_1.variation), CopActionDodge._get_side_index(arg_1_1.side), Rotation(arg_1_1.direction, math.UP):yaw(), arg_1_1.speed or 1, var_1_1)
		end

		arg_1_0._ext_movement:enable_update()

		return true
	end
end
