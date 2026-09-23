Hooks:PostHook(ElementSpecialObjective, "clbk_objective_failed", "RDAI_clbk_objective_failed", function(self, unit)
	if (not unit:brain():objective() or unit:brain():objective().is_default) and unit:brain()._logic_data and unit:brain()._logic_data.path_fail_t and unit:brain()._logic_data.path_fail_t == TimerManager:game():time() then
		local followup_element = self:choose_followup_SO(unit)

		if followup_element then
			local objective = followup_element:get_objective(unit)

			if objective then
				unit:brain():set_objective(objective)
			end
		end
	end
end)
