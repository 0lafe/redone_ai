local math_abs = math.abs
local math_random = math.random
local mvec3_copy = mvector3.copy
local mvec3_distance_sq = mvector3.distance_sq
local mvec3_step = mvector3.step
local pairs_g = pairs
local REACT_SCARED = AIAttentionObject.REACT_SCARED
local REACT_SUSPICIOUS = AIAttentionObject.REACT_SUSPICIOUS
local table_insert = table.insert
local tmp_vec = Vector3()

Hooks:PostHook(CopLogicTravel, "enter", "RDAI_enter", function(data)
	local old_internal_data = data.internal_data
	if not RDAI.settings.masochism then
		local cover_wait_t = old_internal_data.cover_wait_t or {
			RDAI.settings.cover_wait_time,
			RDAI.settings.cover_wait_time / 2
		}

		old_internal_data.cover_leave_t = TimerManager:game():time() + math.rand(cover_wait_t[1], cover_wait_t[2])
	end

	CopLogicTravel.upd_advance(data)
end)

Hooks:OverrideFunction(CopLogicTravel, "upd_advance", function(data)
	local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	local t = TimerManager:game():time()

	data.t = t

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)

		if my_data.has_old_action then
			return
		end
	end

	if my_data.warp_pos then
		local new_action_data = {
			body_part = 1,
			type = "warp",
			position = mvec3_copy(objective.pos),
			rotation = objective.rot
		}

		if unit:movement():action_request(new_action_data) then
			CopLogicTravel._on_destination_reached(data)
		end
	elseif my_data.advancing then
		if my_data.coarse_path then
			if my_data.announce_t and t > my_data.announce_t then
				CopLogicTravel._try_anounce(data, my_data)
			end

			CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
		end
	else
		if my_data.processing_advance_path or my_data.processing_coarse_path then
			CopLogicTravel._upd_pathing(data, my_data)

			if my_data ~= data.internal_data then
				return
			end
		end

		if not my_data.processing_advance_path and not my_data.processing_coarse_path and (not my_data.cover_leave_t or t >= my_data.cover_leave_t and not unit:movement():chk_action_forbidden("walk") and not data.unit:anim_data().reload) then
			my_data.cover_leave_t = nil

			if my_data.advance_path then
				CopLogicTravel._chk_begin_advance(data, my_data)

				if my_data.advancing and my_data.path_ahead then
					CopLogicTravel._check_start_path_ahead(data)
				end
			elseif objective and (objective.nav_seg or objective.type == "follow") then
				if my_data.coarse_path then
					CopLogicTravel._chk_start_pathing_to_next_nav_point(data, my_data)
				else
					CopLogicTravel._begin_coarse_pathing(data, my_data)
				end
			else
				CopLogicBase._exit(data.unit, data.logic._get_logic_state_from_reaction(data) or "idle")
			end
		elseif data.attention_obj and REACT_SCARED <= data.attention_obj.reaction and (not my_data.best_cover or not my_data.best_cover[4]) and not unit:anim_data().crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
			CopLogicAttack._chk_request_action_crouch(data)
		end
	end
end)

function CopLogicTravel._upd_enemy_detection(data)
	local my_data = data.internal_data
	local delay = CopLogicBase._upd_attention_obj_detection(data, nil, nil)
	local new_attention, new_prio_slot, new_reaction = CopLogicIdle._get_priority_attention(data, data.detected_attention_objects, nil)

	CopLogicBase._set_attention_obj(data, new_attention, new_reaction)

	local objective = data.objective
	local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, new_attention)

	if allow_trans and (obj_failed or not objective or objective.type ~= "follow") then
		local wanted_state = CopLogicBase._get_logic_state_from_reaction(data)

		if wanted_state and wanted_state ~= data.name then
			if obj_failed then
				data.objective_failed_clbk(data.unit, data.objective)
			end

			if my_data == data.internal_data and not objective.is_default then
				CopLogicBase._exit(data.unit, wanted_state)
			end

			CopLogicBase._report_detections(data.detected_attention_objects)

			return delay
		end
	end

	if my_data ~= data.internal_data then
		-- _set_attention_obj above can switch logic; my_data would be stale.
		CopLogicBase._report_detections(data.detected_attention_objects)

		return delay
	end

	if data.cool then
		if new_reaction and new_reaction <= REACT_SCARED then
			local set_attention = data.unit:movement():attention()

			if not set_attention or set_attention.u_key ~= new_attention.u_key then
				CopLogicBase._set_attention(data, new_attention, nil)
			end
		end

		if new_reaction == REACT_SUSPICIOUS and CopLogicBase._upd_suspicion(data, my_data, new_attention) then
			CopLogicBase._report_detections(data.detected_attention_objects)

			return delay
		end

		CopLogicTravel.upd_suspicion_decay(data)
	else
		CopLogicAttack._upd_aim(data, my_data)

		if not data.entrance and new_attention and data.char_tweak.chatter.entrance and new_attention.criminal_record and new_attention.verified and new_reaction >= REACT_SCARED and math_abs(data.m_pos.z - new_attention.m_pos.z) < 4000 then
			data.unit:sound():say(data.brain.entrance_chatter_cue or "entrance", true, nil)

			data.entrance = true
		end
	end

	CopLogicBase._report_detections(data.detected_attention_objects)

	return delay
end

function CopLogicTravel._upd_pathing(data, my_data)
	if data.pathing_results then
		local pathing_results = data.pathing_results

		data.pathing_results = nil

		local path = pathing_results[my_data.advance_path_search_id]

		if path and my_data.processing_advance_path then
			my_data.processing_advance_path = nil

			if path ~= "failed" then
				my_data.advance_path = path
			else
				data.path_fail_t = data.t

				data.objective_failed_clbk(data.unit, data.objective)

				return
			end
		end

		local coarse_path = pathing_results[my_data.coarse_path_search_id]

		if coarse_path and my_data.processing_coarse_path then
			my_data.processing_coarse_path = nil

			if coarse_path ~= "failed" then
				managers.groupai:state():_merge_coarse_path_by_area(coarse_path)

				my_data.coarse_path = coarse_path
				my_data.coarse_path_index = 1
			elseif my_data.path_safely then
				my_data.path_safely = nil
			else
				data.path_fail_t = data.t

				data.objective_failed_clbk(data.unit, data.objective)
			end
		end
	end
end

function CopLogicTravel._update_cover(ignore_this, data)
	local my_data = data.internal_data

	CopLogicBase.on_delayed_clbk(my_data, my_data.cover_update_task_key)

	local nearest_cover = my_data.nearest_cover
	local best_cover = my_data.best_cover
	local m_pos = data.m_pos

	if not my_data.in_cover and nearest_cover and mvec3_distance_sq(nearest_cover[1][1], m_pos) > 10000 then
		managers.navigation:release_cover(nearest_cover[1])

		my_data.nearest_cover = nil
		nearest_cover = nil
	end

	if best_cover and mvec3_distance_sq(best_cover[1][1], m_pos) > 10000 then
		managers.navigation:release_cover(best_cover[1])

		my_data.best_cover = nil
		best_cover = nil
	end

	if nearest_cover or best_cover then
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end
end

function CopLogicTravel.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()

	if action_type == "walk" then
		local advancing_coarse_path = false
		local intermediate_action_complete = action._intermediate_action_complete
		local action_done = action:expired() or intermediate_action_complete

		if not my_data.starting_advance_action and my_data.coarse_path_index and not my_data.has_old_action and my_data.advancing then
			advancing_coarse_path = true

			if action_done or my_data.coarse_path_index <= #my_data.coarse_path - 2 and data.unit:movement():nav_tracker():nav_segment() == my_data.coarse_path[my_data.coarse_path_index + 1][1] then
				my_data.coarse_path_index = my_data.coarse_path_index + 1
			end
		end

		if not intermediate_action_complete then
			my_data.advancing = nil
		end

		if my_data.moving_to_cover then
			if action_done then
				if my_data.best_cover then
					managers.navigation:release_cover(my_data.best_cover[1])
				end

				my_data.best_cover = my_data.moving_to_cover

				CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.cover_update_task_key)

				local high_ray = CopLogicTravel._chk_cover_height(data, my_data.best_cover[1], data.visibility_slotmask)

				my_data.best_cover[4] = high_ray
				my_data.in_cover = true

				-- Same bounds as the enter hook above; see the note there.
				if not RDAI.settings.masochism then
					local cover_wait_t = my_data.cover_wait_t or {
						RDAI.settings.cover_wait_time,
						RDAI.settings.cover_wait_time / 2
					}

					my_data.cover_leave_t = TimerManager:game():time() + math.rand(cover_wait_t[1], cover_wait_t[2])
				end
			else
				managers.navigation:release_cover(my_data.moving_to_cover[1])

				if my_data.best_cover and mvec3_distance_sq(my_data.best_cover[1][1], data.unit:movement():m_pos()) > 10000 then
					managers.navigation:release_cover(my_data.best_cover[1])

					my_data.best_cover = nil
				end
			end

			my_data.moving_to_cover = nil
		elseif my_data.best_cover and mvec3_distance_sq(my_data.best_cover[1][1], data.unit:movement():m_pos()) > 10000 then
			managers.navigation:release_cover(my_data.best_cover[1])

			my_data.best_cover = nil
		end

		if not action_done then
			if my_data.processing_advance_path then
				local pathing_results = data.pathing_results

				if pathing_results and pathing_results[my_data.advance_path_search_id] then
					data.pathing_results[my_data.advance_path_search_id] = nil
					my_data.processing_advance_path = nil
				end
			elseif my_data.advance_path then
				my_data.advance_path = nil
			end

			data.unit:brain():abort_detailed_pathing(my_data.advance_path_search_id)
		end

		if advancing_coarse_path then
			if my_data.coarse_path_index >= #my_data.coarse_path then
				CopLogicTravel._on_destination_reached(data)
			elseif intermediate_action_complete then
				CopLogicTravel._check_start_path_ahead(data)
			elseif data.logic.clbk_pathing_results then
				data.logic.clbk_pathing_results(data)
			end
		end
	elseif action_type == "turn" then
		data.internal_data.turning = nil
	elseif action_type == "shoot" then
		data.internal_data.shooting = nil
	elseif action_type == "dodge" then
		local objective = data.objective
		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, nil)

		if allow_trans then
			local wanted_state = data.logic._get_logic_state_from_reaction(data)

			if wanted_state and wanted_state ~= data.name and obj_failed then
				data.objective_failed_clbk(data.unit, data.objective)

				if my_data == data.internal_data then
					CopLogicBase._exit(data.unit, wanted_state)
				end
			end
		end
	end
end

if RDAI.settings.masochism then
	Hooks:PostHook(CopLogicTravel, "enter", "RDAI_masochism_enter", function(data)
		data.internal_data.path_ahead = true
	end)

	function CopLogicTravel.chk_group_ready_to_move(data, my_data)
		return true
	end
else
	function CopLogicTravel.chk_group_ready_to_move(data, my_data)
		local my_objective = data.objective

		if not my_objective.grp_objective then
			return true
		end

		local my_dis = mvec3_distance_sq(my_objective.area.pos, data.m_pos) * 1.3225

		if my_dis > 5290000 then
			return true
		end

		for u_key, u_data in pairs_g(data.group.units) do
			if u_key ~= data.key then
				local his_objective = u_data.unit:brain():objective()

				if his_objective and his_objective.grp_objective == my_objective.grp_objective and not his_objective.in_place and my_dis < mvec3_distance_sq(his_objective.area.pos, u_data.m_pos) then
					return false
				end
			end
		end

		return true
	end
end

function CopLogicTravel.complete_coarse_path(data, my_data, coarse_path)
	local first_seg_id = coarse_path[1][1]
	local current_seg_id = data.unit:movement():nav_tracker():nav_segment()
	local all_nav_segs = managers.navigation._nav_segments

	if not coarse_path[1][2] then
		coarse_path[1][2] = mvec3_copy(all_nav_segs[first_seg_id].pos)
	end

	if first_seg_id ~= current_seg_id then
		table_insert(coarse_path, 1, {
			current_seg_id,
			mvec3_copy(data.m_pos)
		})
	elseif #coarse_path == 1 then
		-- Vanilla keeps a minimum of two nodes; plenty of downstream code indexes
		-- coarse_path[index + 1] without checking.
		table_insert(coarse_path, 1, {
			current_seg_id,
			mvec3_copy(data.m_pos)
		})
	end

	local i_current = 1
	local i_nav_point = 1

	while i_nav_point < #coarse_path do
		local nav_seg_id = coarse_path[i_nav_point][1]
		local next_nav_seg_id = coarse_path[i_nav_point + 1][1]
		local nav_seg = all_nav_segs[nav_seg_id]

		if nav_seg_id ~= next_nav_seg_id and not nav_seg.neighbours[next_nav_seg_id] then
			local search_params = {
				id = "CopLogicTravel_complete_coarse_path",
				from_seg = nav_seg_id,
				to_seg = next_nav_seg_id,
				access_pos = data.SO_access
			}
			local ins_coarse_path = managers.navigation:search_coarse(search_params)

			if not ins_coarse_path then
				my_data.coarse_path = nil

				return
			end

			local i_insert = i_nav_point - 1

			for i = 2, #ins_coarse_path - 1 do
				table_insert(coarse_path, i_insert + i, ins_coarse_path[i])
			end
		end

		if nav_seg_id == current_seg_id then
			i_current = i_nav_point
		end

		i_nav_point = i_nav_point + 1
	end

	return i_current
end

local get_exact_move_pos = CopLogicTravel._get_exact_move_pos

function CopLogicTravel._get_exact_move_pos(data, nav_index, ...)
	local my_data = data.internal_data
	local coarse_path = my_data.coarse_path

	if nav_index >= #coarse_path then
		return get_exact_move_pos(data, nav_index, ...)
	end

	if my_data.moving_to_cover then
		managers.navigation:release_cover(my_data.moving_to_cover[1])

		my_data.moving_to_cover = nil
	end

	local nav_seg = coarse_path[nav_index][1]
	local area = managers.groupai:state():get_area_from_nav_seg_id(nav_seg)
	local to_pos
	local cover = managers.navigation:find_cover_in_nav_seg_2(area.nav_segs, coarse_path[nav_index + 1][2])

	if cover then
		managers.navigation:reserve_cover(cover, data.pos_rsrv_id)

		my_data.moving_to_cover = {
			cover
		}
		to_pos = cover[1]
	else
		to_pos = CopLogicTravel._get_pos_on_wall(managers.navigation:find_random_position_in_segment(nav_seg))
	end

	data.brain:add_pos_rsrv("path", {
		radius = 60,
		position = mvec3_copy(to_pos)
	})

	return to_pos
end

function CopLogicTravel._begin_coarse_pathing(data, my_data)
	-- Prevent infinite loop of gathering paths
	my_data.processing_coarse_path = true

	data.unit:brain():search_for_coarse_path(my_data.coarse_path_search_id, data.objective.follow_unit and data.objective.follow_unit:movement():nav_tracker():nav_segment() or data.objective.nav_seg, my_data.path_safely and callback(CopLogicTravel, CopLogicTravel, "_investigate_coarse_path_verify_clbk"))
end

function CopLogicTravel.clbk_pathing_results(data)
	local my_data = data.internal_data

	data.t = TimerManager:game():time()

	if my_data.coarse_path and my_data.advancing then
		CopLogicTravel._upd_pathing(data, my_data)

		if my_data.advance_path and my_data.advancing:append_path(my_data.advance_path, my_data.coarse_path[my_data.coarse_path_index + 1][1]) then
			my_data.advance_path = nil

			if my_data.coarse_path_index >= #my_data.coarse_path - 2 and data.objective.rot then
				my_data.advancing._end_rot = data.objective.rot
			end
		end
	else
		CopLogicTravel.upd_advance(data)
	end
end
