local var_0_0 = math.abs
local var_0_1 = mvector3.copy
local var_0_2 = mvector3.distance_sq
local var_0_3 = AIAttentionObject.REACT_AIM
local var_0_4 = AIAttentionObject.REACT_COMBAT

function TankCopLogicAttack.update(arg_1_0)
	local var_1_0 = arg_1_0.unit
	local var_1_1 = arg_1_0.internal_data

	if var_1_1.has_old_action then
		CopLogicAttack._upd_stop_old_action(arg_1_0, var_1_1)

		return
	end

	if CopLogicIdle._chk_relocate(arg_1_0) or CopLogicAttack._chk_exit_non_walkable_area(arg_1_0) then
		return
	end

	TankCopLogicAttack._process_pathing_results(arg_1_0, var_1_1)

	if not arg_1_0.attention_obj or arg_1_0.attention_obj.reaction < var_0_3 then
		CopLogicAttack._upd_enemy_detection(arg_1_0, true)

		if var_1_1 ~= arg_1_0.internal_data or not arg_1_0.attention_obj or arg_1_0.attention_obj.reaction < var_0_4 then
			TankCopLogicAttack._cancel_chase_attempt(arg_1_0, var_1_1)

			return
		end
	end

	if var_1_1.turning or var_1_0:movement():chk_action_forbidden("walk") then
		return
	end

	if var_1_0:anim_data().crouch then
		CopLogicAttack._chk_request_action_stand(arg_1_0)
	end

	local var_1_2
	local var_1_3 = arg_1_0.attention_obj
	local var_1_4 = var_1_3.verified_dis

	if var_0_0(arg_1_0.m_pos.z - var_1_3.m_pos.z) < 300 or var_1_4 > 2000 then
		var_1_2 = true
	elseif var_1_3.verified then
		if var_1_1.attitude == "engage" and var_1_4 > 500 then
			var_1_2 = true
		end
	elseif var_1_1.attitude == "engage" and (not var_1_3.verified_t or arg_1_0.t - var_1_3.verified_t > 5 or var_1_4 > 700) then
		var_1_2 = true
	end

	if var_1_2 then
		if not var_1_1.walking_to_chase_pos and not var_1_1.pathing_to_chase_pos then
			if var_1_1.chase_path then
				TankCopLogicAttack._chk_request_action_walk_to_chase_pos(arg_1_0, var_1_1, var_1_4 < (var_1_3.verified and 1500 or 800) and "walk" or "run")
			elseif var_1_3.nav_tracker then
				local var_1_5 = CopLogicAttack._find_flank_pos(arg_1_0, var_1_1, var_1_3.nav_tracker)

				if var_1_5 and var_0_2(arg_1_0.m_pos, var_1_5) > 10000 then
					var_1_1.chase_path_search_id = tostring(var_1_0:key()) .. "chase"
					var_1_1.pathing_to_chase_pos = true

					arg_1_0.brain:add_pos_rsrv("path", {
						radius = 60,
						position = var_0_1(var_1_5)
					})
					var_1_0:brain():search_for_path(var_1_1.chase_path_search_id, var_1_5)
				end
			end
		end
	else
		TankCopLogicAttack._cancel_chase_attempt(arg_1_0, var_1_1)
	end
end

function TankCopLogicAttack._chk_request_action_walk_to_chase_pos(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	if not arg_2_0.unit:movement():chk_action_forbidden("walk") then
		local var_2_0 = arg_2_1.chase_path

		CopLogicAttack._correct_path_start_pos(arg_2_0, var_2_0)

		arg_2_1.chase_path = nil
		arg_2_1.walking_to_chase_pos = arg_2_0.unit:brain():action_request({
			type = "walk",
			body_part = 2,
			nav_path = var_2_0,
			variant = arg_2_2 or "run",
			end_rot = arg_2_3
		})

		if arg_2_1.walking_to_chase_pos then
			arg_2_0.brain:rem_pos_rsrv("path")
		end
	end
end
