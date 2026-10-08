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

-- Collection of logic related to speeding up SO interaction
local SABOTAGE_ACTIONS = {
	e_so_pull_lever = true,
	e_so_pull_lever_var2 = true,
	e_so_container_kick = true,
	e_so_ntl_look_under_car = true,
	e_so_push_button_low = true,
	e_so_disarm_bomb = true,
	e_so_tube_interact = true,
	e_so_stomp = true,
	e_so_weapon_butt = true,
}

local sniper_bit
local function without_snipers(access)
	sniper_bit = sniper_bit or managers.navigation:convert_access_filter_to_number({ "sniper" })

	if access and math.floor(access / sniper_bit) % 2 == 1 then
		return access - sniper_bit
	end

	return access
end

local function sabotage_verification(unit)
	local logic_data = unit:brain()._logic_data
	local t = TimerManager:game():time()

	return not unit:movement():cool()
		and not (logic_data.path_fail_t and t < logic_data.path_fail_t + 6)
		and not unit:base().is_phalanx
end

Hooks:PostHook(ElementSpecialObjective, "on_executed", "RDAI_aggressive_sabotage_SO", function(self)
	if not RDAI.settings.aggressive_objectives or not Network:is_server() then
		return
	end

	if not SABOTAGE_ACTIONS[self._values.so_action] then
		return
	end

	local so = managers.groupai:state()._special_objectives[self._id]

	if not so or so.data.AI_group ~= "enemies" then
		return
	end

	local data = so.data
	local objective = data.objective

	data.search_dis_sq = 10000 * 10000
	data.verification_clbk = sabotage_verification
	data.access = without_snipers(data.access)

	if not data.interval or data.interval > 5 then
		data.interval = 5
	end

	data.base_chance = 1
	data.chance_inc = 0
	so.chance = 1

	objective.forced = true
	objective.interrupt_dis = nil
	objective.interrupt_health = nil
	objective.haste = "run"
	objective.stance = "hos"
end)
