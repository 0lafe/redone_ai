local mvec3_copy = mvector3.copy
local mvec3_distance_sq = mvector3.distance_sq
local mvec3_dot = mvector3.dot
local mvec3_normalize = mvector3.normalize
local REACT_AIM = AIAttentionObject.REACT_AIM

-- Allow shields to crouch and path in the same game tick
function ShieldLogicAttack.queued_update(data)
	data.t = TimerManager:game():time()

	local unit = data.unit
	local my_data = data.internal_data

	ShieldLogicAttack._upd_enemy_detection(data)

	if my_data ~= data.internal_data then
		return
	end

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
		ShieldLogicAttack.queue_update(data, my_data)
		CopLogicBase._report_detections(data.detected_attention_objects)

		return
	end

	local focus_enemy = data.attention_obj

	if not focus_enemy or focus_enemy.reaction < REACT_AIM then
		ShieldLogicAttack.queue_update(data, my_data)

		return
	end

	if unit:anim_data().stand then
		CopLogicAttack._chk_request_action_crouch(data)
	end

	ShieldLogicAttack._process_pathing_results(data, my_data)

	if not my_data.turning and not unit:movement():chk_action_forbidden("walk") and not my_data.walking_to_optimal_pos and not my_data.pathing_to_optimal_pos then
		if my_data.optimal_path then
			ShieldLogicAttack._chk_request_action_walk_to_optimal_pos(data, my_data)
		elseif my_data.optimal_pos and focus_enemy.nav_tracker then
			local to_pos = my_data.optimal_pos

			my_data.optimal_pos = nil

			local ray_params = {
				trace = true,
				tracker_from = unit:movement():nav_tracker(),
				pos_to = to_pos
			}
			local ray_res = managers.navigation:raycast(ray_params)
			local trace_pos = ray_params.trace[1]

			if ray_res then
				local vec = data.m_pos - trace_pos

				mvec3_normalize(vec)

				if mvec3_dot(unit:movement():m_fwd(), vec) > 0 then
					local enemy_tracker = focus_enemy.nav_tracker

					if enemy_tracker:lost() then
						ray_params.tracker_from = nil
						ray_params.pos_from = enemy_tracker:field_position()
					else
						ray_params.tracker_from = enemy_tracker
					end

					trace_pos = ray_params.trace[1]
				end
			end

			local wall_to_pos = ShieldLogicAttack.chk_wall_distance(data, my_data, trace_pos)
			local do_move = mvec3_distance_sq(wall_to_pos, data.m_pos) > 10000

			if not do_move then
				local to_pos_current, fwd_bump_current = ShieldLogicAttack.chk_wall_distance(data, my_data, data.m_pos)

				if fwd_bump_current then
					do_move = true
				end
			end

			if do_move then
				my_data.pathing_to_optimal_pos = true
				my_data.optimal_path_search_id = tostring(unit:key()) .. "optimal"

				local reservation = managers.navigation:reserve_pos(nil, nil, wall_to_pos, callback(ShieldLogicAttack, ShieldLogicAttack, "_reserve_pos_step_clbk", {
					unit_pos = data.m_pos
				}), 70, data.pos_rsrv_id)

				if reservation then
					wall_to_pos = reservation.position
				else
					reservation = {
						radius = 60,
						position = mvec3_copy(wall_to_pos),
						filter = data.pos_rsrv_id
					}

					managers.navigation:add_pos_reservation(reservation)
				end

				data.brain:set_pos_rsrv("path", reservation)
				data.brain:search_for_path(my_data.optimal_path_search_id, wall_to_pos)
			end
		end
	end

	ShieldLogicAttack.queue_update(data, my_data)
	CopLogicBase._report_detections(data.detected_attention_objects)
end

function ShieldLogicAttack.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()

	if action_type == "walk" then
		my_data.advancing = nil

		if my_data.walking_to_optimal_pos then
			my_data.walking_to_optimal_pos = nil
		end

		if action:expired() then
			ShieldLogicAttack._upd_aim(data, my_data)
		end
	elseif action_type == "shoot" then
		my_data.shooting = nil
	elseif action_type == "act" or action_type == "reload" or action_type == "hurt" or action_type == "healed" then
		if action:expired() then
			ShieldLogicAttack._upd_aim(data, my_data)
		end
	elseif action_type == "turn" then
		my_data.turning = nil
	end
end
