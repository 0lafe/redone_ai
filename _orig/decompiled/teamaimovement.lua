function TeamAIMovement.pre_destroy(arg_1_0)
	TeamAIMovement.super.pre_destroy(arg_1_0)

	if arg_1_0._heat_listener_clbk then
		managers.groupai:state():remove_listener(arg_1_0._heat_listener_clbk)

		arg_1_0._heat_listener_clbk = nil
	end

	if arg_1_0._switch_to_not_cool_clbk_id then
		managers.enemy:remove_delayed_clbk(arg_1_0._switch_to_not_cool_clbk_id)

		arg_1_0._switch_to_not_cool_clbk_id = nil
	end
end
