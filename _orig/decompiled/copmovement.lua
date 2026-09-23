function CopMovement.look_vec(arg_1_0)
	return arg_1_0._action_common_data.look_vec
end

local var_0_0 = CopMovement.play_redirect

function CopMovement.play_redirect(arg_2_0, arg_2_1, ...)
	local var_2_0 = var_0_0(arg_2_0, arg_2_1, ...)

	if var_2_0 and arg_2_1 == "suppressed_reaction" and arg_2_0._ext_anim.crouch then
		arg_2_0._machine:set_parameter(var_2_0, "from_stand", 0)
	end

	return var_2_0
end

function CopMovement.synch_attention(arg_3_0, arg_3_1)
	arg_3_0:_remove_attention_destroy_listener(arg_3_0._attention)
	arg_3_0:_add_attention_destroy_listener(arg_3_1)

	if arg_3_1 and arg_3_1.unit and not arg_3_1.destroy_listener_key then
		return arg_3_0:synch_attention(nil)
	end

	local var_3_0 = arg_3_0._attention

	arg_3_0._attention = arg_3_1
	arg_3_0._action_common_data.attention = arg_3_1

	for iter_3_0, iter_3_1 in ipairs(arg_3_0._active_actions) do
		if iter_3_1 and iter_3_1.on_attention then
			iter_3_1:on_attention(arg_3_1, var_3_0)
		end
	end
end

function CopMovement.sync_action_walk_stop(arg_4_0, arg_4_1)
	local var_4_0, var_4_1 = arg_4_0:_get_latest_walk_action()

	if var_4_1 then
		var_4_0.persistent = nil
	elseif var_4_0 then
		var_4_0:stop()
	end
end

local var_0_1 = CopMovement.sync_action_dodge_start

function CopMovement.sync_action_dodge_start(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, ...)
	return var_0_1(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6 / 10, ...)
end
