local var_0_0 = math.abs
local var_0_1 = math.random
local var_0_2 = mvector3.copy
local var_0_3 = mvector3.distance_sq
local var_0_4 = mvector3.step
local var_0_5 = pairs
local var_0_6 = AIAttentionObject.REACT_SCARED
local var_0_7 = AIAttentionObject.REACT_SUSPICIOUS
local var_0_8 = table.insert
local var_0_9 = Vector3()

Hooks:PostHook(CopLogicTravel, "enter", "REAI_enter", function(arg_1_0)
	local var_1_0 = arg_1_0.internal_data

	if not REAI.settings.masochism then
		local var_1_1 = var_1_0.cover_wait_t or {
			REAI.settings.cover_wait_time,
			REAI.settings.cover_wait_time / 2
		}

		var_1_0.cover_leave_t = TimerManager:game():time() + math.rand(var_1_1[1], var_1_1[2])
	end

	CopLogicTravel.upd_advance(arg_1_0)
end)
Hooks:OverrideFunction(CopLogicTravel, "upd_advance", function(arg_2_0)
	local var_2_0 = arg_2_0.unit
	local var_2_1 = arg_2_0.internal_data
	local var_2_2 = arg_2_0.objective
	local var_2_3 = TimerManager:game():time()

	arg_2_0.t = var_2_3

	if var_2_1.has_old_action then
		CopLogicAttack._upd_stop_old_action(arg_2_0, var_2_1)

		if var_2_1.has_old_action then
			return
		end
	end

	if var_2_1.warp_pos then
		local var_2_4 = {
			body_part = 1,
			type = "warp",
			position = var_0_2(var_2_2.pos),
			rotation = var_2_2.rot
		}

		if var_2_0:movement():action_request(var_2_4) then
			CopLogicTravel._on_destination_reached(arg_2_0)
		end
	elseif var_2_1.advancing then
		if var_2_1.coarse_path then
			if var_2_1.announce_t and var_2_3 > var_2_1.announce_t then
				CopLogicTravel._try_anounce(arg_2_0, var_2_1)
			end

			CopLogicTravel._chk_stop_for_follow_unit(arg_2_0, var_2_1)
		end
	else
		if var_2_1.processing_advance_path or var_2_1.processing_coarse_path then
			CopLogicTravel._upd_pathing(arg_2_0, var_2_1)

			if var_2_1 ~= arg_2_0.internal_data then
				return
			end
		end

		if not var_2_1.processing_advance_path and not var_2_1.processing_coarse_path and (not var_2_1.cover_leave_t or var_2_3 >= var_2_1.cover_leave_t and not var_2_0:movement():chk_action_forbidden("walk") and not arg_2_0.unit:anim_data().reload) then
			var_2_1.cover_leave_t = nil

			if var_2_1.advance_path then
				CopLogicTravel._chk_begin_advance(arg_2_0, var_2_1)

				if var_2_1.advancing and var_2_1.path_ahead then
					CopLogicTravel._check_start_path_ahead(arg_2_0)
				end
			elseif var_2_2 and (var_2_2.nav_seg or var_2_2.type == "follow") then
				if var_2_1.coarse_path then
					CopLogicTravel._chk_start_pathing_to_next_nav_point(arg_2_0, var_2_1)
				else
					CopLogicTravel._begin_coarse_pathing(arg_2_0, var_2_1)
				end
			else
				CopLogicBase._exit(arg_2_0.unit, arg_2_0.logic._get_logic_state_from_reaction(arg_2_0) or "idle")
			end
		elseif arg_2_0.attention_obj and var_0_6 <= arg_2_0.attention_obj.reaction and (not var_2_1.best_cover or not var_2_1.best_cover[4]) and not var_2_0:anim_data().crouch and (not arg_2_0.char_tweak.allowed_poses or arg_2_0.char_tweak.allowed_poses.crouch) then
			CopLogicAttack._chk_request_action_crouch(arg_2_0)
		end
	end
end)

function CopLogicTravel._upd_enemy_detection(arg_3_0)
	local var_3_0 = arg_3_0.internal_data
	local var_3_1 = CopLogicBase._upd_attention_obj_detection(arg_3_0, nil, nil)
	local var_3_2, var_3_3, var_3_4 = CopLogicIdle._get_priority_attention(arg_3_0, arg_3_0.detected_attention_objects, nil)

	CopLogicBase._set_attention_obj(arg_3_0, var_3_2, var_3_4)

	local var_3_5 = arg_3_0.objective
	local var_3_6, var_3_7 = CopLogicBase.is_obstructed(arg_3_0, var_3_5, nil, var_3_2)

	if var_3_6 and (var_3_7 or not var_3_5 or var_3_5.type ~= "follow") then
		local var_3_8 = CopLogicBase._get_logic_state_from_reaction(arg_3_0)

		if var_3_8 and var_3_8 ~= arg_3_0.name then
			if var_3_7 then
				arg_3_0.objective_failed_clbk(arg_3_0.unit, arg_3_0.objective)
			end

			if var_3_0 == arg_3_0.internal_data and not var_3_5.is_default then
				CopLogicBase._exit(arg_3_0.unit, var_3_8)
			end

			CopLogicBase._report_detections(arg_3_0.detected_attention_objects)

			return var_3_1
		end
	end

	if arg_3_0.cool then
		if var_3_4 and var_3_4 <= var_0_6 then
			local var_3_9 = arg_3_0.unit:movement():attention()

			if not var_3_9 or var_3_9.u_key ~= var_3_2.u_key then
				CopLogicBase._set_attention(arg_3_0, var_3_2, nil)
			end
		end

		if var_3_4 == var_0_7 and CopLogicBase._upd_suspicion(arg_3_0, var_3_0, var_3_2) then
			CopLogicBase._report_detections(arg_3_0.detected_attention_objects)

			return var_3_1
		end

		CopLogicTravel.upd_suspicion_decay(arg_3_0)
	else
		CopLogicAttack._upd_aim(arg_3_0, var_3_0)

		if not arg_3_0.entrance and var_3_2 and arg_3_0.char_tweak.chatter.entrance and var_3_2.criminal_record and var_3_2.verified and var_3_4 >= var_0_6 and var_0_0(arg_3_0.m_pos.z - var_3_2.m_pos.z) < 4000 then
			arg_3_0.unit:sound():say(arg_3_0.brain.entrance_chatter_cue or "entrance", true, nil)

			arg_3_0.entrance = true
		end
	end

	CopLogicBase._report_detections(arg_3_0.detected_attention_objects)

	return var_3_1
end

function CopLogicTravel._upd_pathing(arg_4_0, arg_4_1)
	if arg_4_0.pathing_results then
		local var_4_0 = arg_4_0.pathing_results

		arg_4_0.pathing_results = nil

		local var_4_1 = var_4_0[arg_4_1.advance_path_search_id]

		if var_4_1 and arg_4_1.processing_advance_path then
			arg_4_1.processing_advance_path = nil

			if var_4_1 ~= "failed" then
				arg_4_1.advance_path = var_4_1
			else
				arg_4_0.path_fail_t = arg_4_0.t

				arg_4_0.objective_failed_clbk(arg_4_0.unit, arg_4_0.objective)

				return
			end
		end

		local var_4_2 = var_4_0[arg_4_1.coarse_path_search_id]

		if var_4_2 and arg_4_1.processing_coarse_path then
			arg_4_1.processing_coarse_path = nil

			if var_4_2 ~= "failed" then
				managers.groupai:state():_merge_coarse_path_by_area(var_4_2)

				arg_4_1.coarse_path = var_4_2
				arg_4_1.coarse_path_index = 1
			elseif arg_4_1.path_safely then
				arg_4_1.path_safely = nil
			else
				arg_4_0.path_fail_t = arg_4_0.t

				arg_4_0.objective_failed_clbk(arg_4_0.unit, arg_4_0.objective)
			end
		end
	end
end

function CopLogicTravel._update_cover(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.internal_data

	CopLogicBase.on_delayed_clbk(var_5_0, var_5_0.cover_update_task_key)

	local var_5_1 = var_5_0.nearest_cover
	local var_5_2 = var_5_0.best_cover
	local var_5_3 = arg_5_1.m_pos

	if not var_5_0.in_cover and var_5_1 and var_0_3(var_5_1[1][1], var_5_3) > 10000 then
		managers.navigation:release_cover(var_5_1[1])

		var_5_0.nearest_cover = nil
		var_5_1 = nil
	end

	if var_5_2 and var_0_3(var_5_2[1][1], var_5_3) > 10000 then
		managers.navigation:release_cover(var_5_2[1])

		var_5_0.best_cover = nil
		var_5_2 = nil
	end

	if var_5_1 or var_5_2 then
		CopLogicBase.add_delayed_clbk(var_5_0, var_5_0.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", arg_5_1), arg_5_1.t + 1)
	end
end

function CopLogicTravel.action_complete_clbk(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.internal_data
	local var_6_1 = arg_6_1:type()

	if var_6_1 == "walk" then
		local var_6_2 = false
		local var_6_3 = arg_6_1._intermediate_action_complete
		local var_6_4 = arg_6_1:expired() or var_6_3

		if not var_6_0.starting_advance_action and var_6_0.coarse_path_index and not var_6_0.has_old_action and var_6_0.advancing then
			var_6_2 = true

			if var_6_4 or var_6_0.coarse_path_index <= #var_6_0.coarse_path - 2 and arg_6_0.unit:movement():nav_tracker():nav_segment() == var_6_0.coarse_path[var_6_0.coarse_path_index + 1][1] then
				var_6_0.coarse_path_index = var_6_0.coarse_path_index + 1
			end
		end

		if not var_6_3 then
			var_6_0.advancing = nil
		end

		if var_6_0.moving_to_cover then
			if var_6_4 then
				if var_6_0.best_cover then
					managers.navigation:release_cover(var_6_0.best_cover[1])
				end

				var_6_0.best_cover = var_6_0.moving_to_cover

				CopLogicBase.chk_cancel_delayed_clbk(var_6_0, var_6_0.cover_update_task_key)

				local var_6_5 = CopLogicTravel._chk_cover_height(arg_6_0, var_6_0.best_cover[1], arg_6_0.visibility_slotmask)

				var_6_0.best_cover[4] = var_6_5
				var_6_0.in_cover = true

				if not REAI.settings.masochism then
					local var_6_6 = var_6_0.cover_wait_t or {
						REAI.settings.cover_wait_time,
						REAI.settings.cover_wait_time / 2
					}

					var_6_0.cover_leave_t = TimerManager:game():time() + math.rand(var_6_6[1], var_6_6[2])
				end
			else
				managers.navigation:release_cover(var_6_0.moving_to_cover[1])

				if var_6_0.best_cover and var_0_3(var_6_0.best_cover[1][1], arg_6_0.unit:movement():m_pos()) > 10000 then
					managers.navigation:release_cover(var_6_0.best_cover[1])

					var_6_0.best_cover = nil
				end
			end

			var_6_0.moving_to_cover = nil
		elseif var_6_0.best_cover and var_0_3(var_6_0.best_cover[1][1], arg_6_0.unit:movement():m_pos()) > 10000 then
			managers.navigation:release_cover(var_6_0.best_cover[1])

			var_6_0.best_cover = nil
		end

		if not var_6_4 then
			if var_6_0.processing_advance_path then
				local var_6_7 = arg_6_0.pathing_results

				if var_6_7 and var_6_7[var_6_0.advance_path_search_id] then
					arg_6_0.pathing_results[var_6_0.advance_path_search_id] = nil
					var_6_0.processing_advance_path = nil
				end
			elseif var_6_0.advance_path then
				var_6_0.advance_path = nil
			end

			arg_6_0.unit:brain():abort_detailed_pathing(var_6_0.advance_path_search_id)
		end

		if var_6_2 then
			if var_6_0.coarse_path_index >= #var_6_0.coarse_path then
				CopLogicTravel._on_destination_reached(arg_6_0)
			elseif var_6_3 then
				CopLogicTravel._check_start_path_ahead(arg_6_0)
			elseif arg_6_0.logic.clbk_pathing_results then
				arg_6_0.logic.clbk_pathing_results(arg_6_0)
			end
		end
	elseif var_6_1 == "turn" then
		arg_6_0.internal_data.turning = nil
	elseif var_6_1 == "shoot" then
		arg_6_0.internal_data.shooting = nil
	elseif var_6_1 == "dodge" then
		local var_6_8 = arg_6_0.objective
		local var_6_9, var_6_10 = CopLogicBase.is_obstructed(arg_6_0, var_6_8, nil, nil)

		if var_6_9 then
			local var_6_11 = arg_6_0.logic._get_logic_state_from_reaction(arg_6_0)

			if var_6_11 and var_6_11 ~= arg_6_0.name and var_6_10 then
				arg_6_0.objective_failed_clbk(arg_6_0.unit, arg_6_0.objective)

				if var_6_0 == arg_6_0.internal_data then
					CopLogicBase._exit(arg_6_0.unit, var_6_11)
				end
			end
		end
	end
end

if REAI.settings.masochism then
	Hooks:PostHook(CopLogicTravel, "enter", "REAI_masochism_enter", function(arg_7_0)
		arg_7_0.internal_data.path_ahead = true
	end)

	function CopLogicTravel.chk_group_ready_to_move(arg_8_0, arg_8_1)
		return true
	end
else
	function CopLogicTravel.chk_group_ready_to_move(arg_9_0, arg_9_1)
		local var_9_0 = arg_9_0.objective

		if not var_9_0.grp_objective then
			return true
		end

		local var_9_1 = var_0_3(var_9_0.area.pos, arg_9_0.m_pos) * 1.3225

		if var_9_1 > 5290000 then
			return true
		end

		for iter_9_0, iter_9_1 in var_0_5(arg_9_0.group.units) do
			if iter_9_0 ~= arg_9_0.key then
				local var_9_2 = iter_9_1.unit:brain():objective()

				if var_9_2 and var_9_2.grp_objective == var_9_0.grp_objective and not var_9_2.in_place and var_9_1 < var_0_3(var_9_2.area.pos, iter_9_1.m_pos) then
					return false
				end
			end
		end

		return true
	end
end

function CopLogicTravel.complete_coarse_path(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_2[1][1]
	local var_10_1 = arg_10_0.unit:movement():nav_tracker():nav_segment()
	local var_10_2 = managers.navigation._nav_segments

	if not arg_10_2[1][2] then
		arg_10_2[1][2] = var_0_2(var_10_2[var_10_0].pos)
	end

	if var_10_0 ~= var_10_1 then
		var_0_8(arg_10_2, 1, {
			var_10_1,
			var_0_2(arg_10_0.m_pos)
		})
	end

	local var_10_3 = 1
	local var_10_4 = 1

	while var_10_4 < #arg_10_2 do
		local var_10_5 = arg_10_2[var_10_4][1]
		local var_10_6 = arg_10_2[var_10_4 + 1][1]
		local var_10_7 = var_10_2[var_10_5]

		if var_10_5 ~= var_10_6 and not var_10_7.neighbours[var_10_6] then
			local var_10_8 = {
				id = "CopLogicTravel_complete_coarse_path",
				from_seg = var_10_5,
				to_seg = var_10_6,
				access_pos = arg_10_0.SO_access
			}
			local var_10_9 = managers.navigation:search_coarse(var_10_8)

			if not var_10_9 then
				arg_10_1.coarse_path = nil

				return
			end

			local var_10_10 = var_10_4 - 1

			for iter_10_0 = 2, #var_10_9 - 1 do
				var_0_8(arg_10_2, var_10_10 + iter_10_0, var_10_9[iter_10_0])
			end
		end

		if var_10_5 == var_10_1 then
			var_10_3 = var_10_4
		end

		var_10_4 = var_10_4 + 1
	end

	return var_10_3
end

local var_0_10 = CopLogicTravel._get_exact_move_pos

function CopLogicTravel._get_exact_move_pos(arg_11_0, arg_11_1, ...)
	local var_11_0 = arg_11_0.internal_data
	local var_11_1 = var_11_0.coarse_path

	if arg_11_1 >= #var_11_1 then
		return var_0_10(arg_11_0, arg_11_1, ...)
	end

	if var_11_0.moving_to_cover then
		managers.navigation:release_cover(var_11_0.moving_to_cover[1])

		var_11_0.moving_to_cover = nil
	end

	local var_11_2 = var_11_1[arg_11_1][1]
	local var_11_3 = managers.groupai:state():get_area_from_nav_seg_id(var_11_2)
	local var_11_4
	local var_11_5 = managers.navigation:find_cover_in_nav_seg_2(var_11_3.nav_segs, var_11_1[arg_11_1 + 1][2])

	if var_11_5 then
		managers.navigation:reserve_cover(var_11_5, arg_11_0.pos_rsrv_id)

		var_11_0.moving_to_cover = {
			var_11_5
		}
		var_11_4 = var_11_5[1]
	else
		var_11_4 = CopLogicTravel._get_pos_on_wall(managers.navigation:find_random_position_in_segment(var_11_2))
	end

	arg_11_0.brain:add_pos_rsrv("path", {
		radius = 60,
		position = var_0_2(var_11_4)
	})

	return var_11_4
end

function CopLogicTravel._begin_coarse_pathing(arg_12_0, arg_12_1)
	arg_12_1.processing_coarse_path = true

	arg_12_0.unit:brain():search_for_coarse_path(arg_12_1.coarse_path_search_id, arg_12_0.objective.follow_unit and arg_12_0.objective.follow_unit:movement():nav_tracker():nav_segment() or arg_12_0.objective.nav_seg, arg_12_1.path_safely and callback(CopLogicTravel, CopLogicTravel, "_investigate_coarse_path_verify_clbk"))
end

function CopLogicTravel.clbk_pathing_results(arg_13_0)
	local var_13_0 = arg_13_0.internal_data

	arg_13_0.t = TimerManager:game():time()

	if var_13_0.coarse_path and var_13_0.advancing then
		CopLogicTravel._upd_pathing(arg_13_0, var_13_0)

		if var_13_0.advance_path and var_13_0.advancing:append_path(var_13_0.advance_path, var_13_0.coarse_path[var_13_0.coarse_path_index + 1][1]) then
			var_13_0.advance_path = nil

			if var_13_0.coarse_path_index >= #var_13_0.coarse_path - 2 and arg_13_0.objective.rot then
				var_13_0.advancing._end_rot = arg_13_0.objective.rot
			end
		end
	else
		CopLogicTravel.upd_advance(arg_13_0)
	end
end
