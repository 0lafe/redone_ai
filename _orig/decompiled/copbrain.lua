local var_0_0 = math.lerp
local var_0_1 = math.random
local var_0_2 = math.UP

Hooks:PostHook(CopBrain, "clbk_pathing_results", "REAI_clbk_pathing_results", function(arg_1_0, arg_1_1, arg_1_2)
	if arg_1_2 and arg_1_0._current_logic.clbk_pathing_results then
		arg_1_0._current_logic.clbk_pathing_results(arg_1_0._logic_data)
	end
end)
Hooks:PostHook(CopBrain, "clbk_coarse_pathing_results", "REAI_clbk_coarse_pathing_results", function(arg_2_0, arg_2_1, arg_2_2)
	if arg_2_2 and arg_2_0._current_logic.clbk_pathing_results then
		arg_2_0._current_logic.clbk_pathing_results(arg_2_0._logic_data)
	end
end)

function CopBrain._chk_use_cover_grenade(arg_3_0, arg_3_1)
	local var_3_0 = Network:is_server() and arg_3_0._logic_data.char_tweak.dodge_with_grenade

	if not var_3_0 or not arg_3_0._logic_data.attention_obj then
		return
	end

	local var_3_1 = var_3_0.check
	local var_3_2 = TimerManager:game():time()

	if var_3_1 and (not arg_3_0._next_cover_grenade_chk_t or var_3_2 > arg_3_0._next_cover_grenade_chk_t) then
		local var_3_3
		local var_3_4, var_3_5 = var_3_1(var_3_2, arg_3_0._nr_flashbang_covers_used or 0)

		arg_3_0._next_cover_grenade_chk_t = var_3_5

		if not var_3_4 then
			return
		end
	end

	if arg_3_0._logic_data.attention_obj.dis > 1000 or not var_3_0.flash then
		if var_3_0.smoke and not managers.groupai:state():is_smoke_grenade_active() then
			local var_3_6 = var_3_0.smoke.duration

			managers.groupai:state():detonate_smoke_grenade(arg_3_0._logic_data.m_pos + var_0_2 * 10, arg_3_0._unit:movement():m_head_pos(), var_0_0(var_3_6[1], var_3_6[2], var_0_1()), false)

			arg_3_0._nr_flashbang_covers_used = (arg_3_0._nr_flashbang_covers_used or 0) + 1
		end
	elseif var_3_0.flash then
		local var_3_7 = var_3_0.flash.duration

		managers.groupai:state():detonate_smoke_grenade(arg_3_0._logic_data.m_pos + var_0_2 * 10, arg_3_0._unit:movement():m_head_pos(), var_0_0(var_3_7[1], var_3_7[2], var_0_1()), true)

		arg_3_0._nr_flashbang_covers_used = (arg_3_0._nr_flashbang_covers_used or 0) + 1
	end
end
