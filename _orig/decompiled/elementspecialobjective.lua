Hooks:PostHook(ElementSpecialObjective, "clbk_objective_failed", "REAI_clbk_objective_failed", function(arg_1_0, arg_1_1)
	if (not arg_1_1:brain():objective() or arg_1_1:brain():objective().is_default) and arg_1_1:brain()._logic_data and arg_1_1:brain()._logic_data.path_fail_t and arg_1_1:brain()._logic_data.path_fail_t == TimerManager:game():time() then
		local var_1_0 = arg_1_0:choose_followup_SO(arg_1_1)

		if var_1_0 then
			local var_1_1 = var_1_0:get_objective(arg_1_1)

			if var_1_1 then
				arg_1_1:brain():set_objective(var_1_1)
			end
		end
	end
end)
