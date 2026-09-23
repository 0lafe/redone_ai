function UnitNetworkHandler.action_aim_state(arg_1_0, arg_1_1, arg_1_2)
	if not arg_1_0._verify_gamestate(arg_1_0._gamestate_filter.any_ingame) or not arg_1_0._verify_character(arg_1_1) then
		return
	end

	if arg_1_2 then
		arg_1_1:movement():action_request({
			type = "shoot",
			body_part = 3,
			block_type = "action"
		})
	else
		arg_1_1:movement():sync_action_aim_end()
	end
end
