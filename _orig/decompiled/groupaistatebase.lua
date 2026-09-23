local var_0_0 = math.lerp
local var_0_1 = math.min
local var_0_2 = math.random
local var_0_3 = mvector3.set_z
local var_0_4 = table.remove

Hooks:PostHook(GroupAIStateBase, "criminal_spotted", "REAI_criminal_spotted", function(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_0._criminals[arg_1_1:key()]

	mvector3.set(var_1_0.pos, var_1_0.m_det_pos)
end)

function GroupAIStateBase.on_criminal_nav_seg_change(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = arg_2_1:key()
	local var_2_1 = arg_2_0._criminals[var_2_0]

	if not var_2_1 then
		return
	end

	local var_2_2 = var_2_1.area

	var_2_1.seg = arg_2_2

	local var_2_3

	if var_2_2 and var_2_2.nav_segs[arg_2_2] then
		var_2_3 = var_2_2
	else
		var_2_3 = arg_2_0:get_area_from_nav_seg_id(arg_2_2)
	end

	if var_2_2 ~= var_2_3 then
		var_2_1.area = var_2_3

		if var_2_2 then
			var_2_2.criminal.units[var_2_0] = nil
		end

		var_2_3.criminal.units[var_2_0] = var_2_1
	end
end

Hooks:PostHook(GroupAIStateBase, "on_enemy_unregistered", "REAI_on_enemy_unregistered", function(arg_3_0, arg_3_1)
	if arg_3_0._is_server then
		arg_3_0:set_enemy_assigned(nil, arg_3_1:key())

		local var_3_0 = arg_3_1:brain():objective()
		local var_3_1 = var_3_0 and var_3_0.fail_clbk

		if var_3_1 then
			var_3_0.fail_clbk = nil

			var_3_1(arg_3_1)
		end
	end
end)

function GroupAIStateBase.chk_say_teamAI_combat_chatter(arg_4_0, arg_4_1)
	if not arg_4_0:is_detection_persistent() then
		return
	end

	local var_4_0 = arg_4_0._drama_data.amount
	local var_4_1 = tweak_data.sound.criminal_sound
	local var_4_2 = var_4_1.combat_callout_delay
	local var_4_3 = arg_4_0._t

	if var_4_3 < arg_4_0._teamAI_last_combat_chatter_t + var_0_0(var_4_2[1], var_4_2[2], var_4_0) then
		return
	end

	arg_4_0._teamAI_last_combat_chatter_t = var_4_3

	local var_4_4 = var_4_1.combat_callout_chance

	if var_0_0(var_4_4[1], var_4_4[2], var_0_1(var_4_0^2, 1)) < var_0_2() then
		return
	end

	arg_4_1:sound():say("g90", true, true)
end

function GroupAIStateBase.is_nav_seg_safe(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0._char_criminals) do
		if iter_5_1.tracker:nav_segment() == arg_5_1 then
			return false
		end
	end

	return true
end

function GroupAIStateBase._merge_coarse_path_by_area(arg_6_0, arg_6_1)
	local var_6_0 = #arg_6_1
	local var_6_1

	while var_6_0 > 0 and #arg_6_1 > 2 do
		local var_6_2 = arg_6_0:get_area_from_nav_seg_id(arg_6_1[var_6_0][1])

		if var_6_1 and var_6_1 == var_6_2 then
			var_0_4(arg_6_1, var_6_0)
		else
			var_6_1 = var_6_2
		end

		var_6_0 = var_6_0 - 1
	end
end
