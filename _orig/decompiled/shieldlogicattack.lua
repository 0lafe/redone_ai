local var_0_0 = math.abs
local var_0_1 = mvector3.copy
local var_0_2 = mvector3.distance_sq
local var_0_3 = mvector3.dot
local var_0_4 = mvector3.normalize
local var_0_5 = AIAttentionObject.REACT_AIM

function ShieldLogicAttack.queued_update(arg_1_0)
	arg_1_0.t = TimerManager:game():time()

	local var_1_0 = arg_1_0.unit
	local var_1_1 = arg_1_0.internal_data

	ShieldLogicAttack._upd_enemy_detection(arg_1_0)

	if var_1_1 ~= arg_1_0.internal_data then
		return
	end

	if var_1_1.has_old_action then
		CopLogicAttack._upd_stop_old_action(arg_1_0, var_1_1)
		ShieldLogicAttack.queue_update(arg_1_0, var_1_1)
		CopLogicBase._report_detections(arg_1_0.detected_attention_objects)

		return
	end

	local var_1_2 = arg_1_0.attention_obj

	if not var_1_2 or var_1_2.reaction < var_0_5 then
		ShieldLogicAttack.queue_update(arg_1_0, var_1_1)

		return
	end

	if var_1_0:anim_data().stand then
		CopLogicAttack._chk_request_action_crouch(arg_1_0)
	end

	ShieldLogicAttack._process_pathing_results(arg_1_0, var_1_1)

	if not var_1_1.turning and not var_1_0:movement():chk_action_forbidden("walk") and not var_1_1.walking_to_optimal_pos and not var_1_1.pathing_to_optimal_pos then
		if var_1_1.optimal_path then
			ShieldLogicAttack._chk_request_action_walk_to_optimal_pos(arg_1_0, var_1_1)
		elseif var_1_1.optimal_pos and var_1_2.nav_tracker then
			local var_1_3 = var_1_1.optimal_pos

			var_1_1.optimal_pos = nil

			local var_1_4 = {
				trace = true,
				tracker_from = var_1_0:movement():nav_tracker(),
				pos_to = var_1_3
			}
			local var_1_5 = managers.navigation:raycast(var_1_4)
			local var_1_6 = var_1_4.trace[1]

			if var_1_5 then
				local var_1_7 = arg_1_0.m_pos - var_1_6

				var_0_4(var_1_7)

				if var_0_3(var_1_0:movement():m_fwd(), var_1_7) > 0 then
					local var_1_8 = var_1_2.nav_tracker

					if var_1_8:lost() then
						var_1_4.tracker_from = nil
						var_1_4.pos_from = var_1_8:field_position()
					else
						var_1_4.tracker_from = var_1_8
					end

					local var_1_9 = managers.navigation:raycast(var_1_4)

					var_1_6 = var_1_4.trace[1]
				end
			end

			local var_1_10 = ShieldLogicAttack.chk_wall_distance(arg_1_0, var_1_1, var_1_6)
			local var_1_11 = var_0_2(var_1_10, arg_1_0.m_pos) > 10000

			if not var_1_11 then
				local var_1_12, var_1_13 = ShieldLogicAttack.chk_wall_distance(arg_1_0, var_1_1, arg_1_0.m_pos)

				if var_1_13 then
					var_1_11 = true
				end
			end

			if var_1_11 then
				var_1_1.pathing_to_optimal_pos = true
				var_1_1.optimal_path_search_id = tostring(var_1_0:key()) .. "optimal"

				local var_1_14 = managers.navigation:reserve_pos(nil, nil, var_1_10, callback(ShieldLogicAttack, ShieldLogicAttack, "_reserve_pos_step_clbk", {
					unit_pos = arg_1_0.m_pos
				}), 70, arg_1_0.pos_rsrv_id)

				if var_1_14 then
					var_1_10 = var_1_14.position
				else
					var_1_14 = {
						radius = 60,
						position = var_0_1(var_1_10),
						filter = arg_1_0.pos_rsrv_id
					}

					managers.navigation:add_pos_reservation(var_1_14)
				end

				arg_1_0.brain:set_pos_rsrv("path", var_1_14)
				arg_1_0.brain:search_for_path(var_1_1.optimal_path_search_id, var_1_10)
			end
		end
	end

	ShieldLogicAttack.queue_update(arg_1_0, var_1_1)
	CopLogicBase._report_detections(arg_1_0.detected_attention_objects)
end

function ShieldLogicAttack._chk_request_action_walk_to_optimal_pos(arg_2_0, arg_2_1, arg_2_2)
	if not arg_2_0.unit:movement():chk_action_forbidden("walk") then
		local var_2_0 = arg_2_1.optimal_path

		arg_2_1.optimal_path = nil

		CopLogicAttack._correct_path_start_pos(arg_2_0, var_2_0)

		arg_2_1.walking_to_optimal_pos = arg_2_0.unit:brain():action_request({
			type = "walk",
			body_part = 2,
			variant = "walk",
			nav_path = var_2_0,
			end_rot = arg_2_2
		})

		if arg_2_1.walking_to_optimal_pos then
			arg_2_0.brain:rem_pos_rsrv("path")

			if arg_2_0.group and arg_2_0.group.leader_key == arg_2_0.key and arg_2_0.char_tweak.chatter.follow_me and var_0_2(var_2_0[#var_2_0], arg_2_0.m_pos) > 640000 and not arg_2_0.unit:sound():speaking(arg_2_0.t) then
				managers.groupai:state():chk_say_enemy_chatter(arg_2_0.unit, arg_2_0.m_pos, "follow_me")
			end
		end
	end
end

function ShieldLogicAttack.action_complete_clbk(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0.internal_data
	local var_3_1 = arg_3_1:type()

	if var_3_1 == "walk" then
		var_3_0.advancing = nil

		if var_3_0.walking_to_optimal_pos then
			var_3_0.walking_to_optimal_pos = nil
		end

		if arg_3_1:expired() then
			ShieldLogicAttack._upd_aim(arg_3_0, var_3_0)
		end
	elseif var_3_1 == "shoot" then
		var_3_0.shooting = nil
	elseif var_3_1 == "act" or var_3_1 == "reload" or var_3_1 == "hurt" or var_3_1 == "healed" then
		if arg_3_1:expired() then
			ShieldLogicAttack._upd_aim(arg_3_0, var_3_0)
		end
	elseif var_3_1 == "turn" then
		var_3_0.turning = nil
	end
end
