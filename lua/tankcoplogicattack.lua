local math_abs = math.abs
local mvec3_copy = mvector3.copy
local mvec3_distance_sq = mvector3.distance_sq
local REACT_AIM = AIAttentionObject.REACT_AIM
local REACT_COMBAT = AIAttentionObject.REACT_COMBAT

function TankCopLogicAttack.update(data)
	local unit = data.unit
	local my_data = data.internal_data

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)

		return
	end

	if CopLogicIdle._chk_relocate(data) or CopLogicAttack._chk_exit_non_walkable_area(data) then
		return
	end

	TankCopLogicAttack._process_pathing_results(data, my_data)

	if not data.attention_obj or data.attention_obj.reaction < REACT_AIM then
		CopLogicAttack._upd_enemy_detection(data, true)

		if my_data ~= data.internal_data or not data.attention_obj or data.attention_obj.reaction < REACT_COMBAT then
			TankCopLogicAttack._cancel_chase_attempt(data, my_data)

			return
		end
	end

	if my_data.turning or unit:movement():chk_action_forbidden("walk") then
		return
	end

	if unit:anim_data().crouch then
		CopLogicAttack._chk_request_action_stand(data)
	end

	local chase
	local focus_enemy = data.attention_obj
	local dist = focus_enemy.verified_dis

	if math_abs(data.m_pos.z - focus_enemy.m_pos.z) < 300 or dist > 2000 then
		chase = true
	elseif focus_enemy.verified then
		if my_data.attitude == "engage" and dist > 500 then
			chase = true
		end
	elseif my_data.attitude == "engage" and (not focus_enemy.verified_t or data.t - focus_enemy.verified_t > 5 or dist > 700) then
		chase = true
	end

	if chase then
		if not my_data.walking_to_chase_pos and not my_data.pathing_to_chase_pos then
			if my_data.chase_path then
				TankCopLogicAttack._chk_request_action_walk_to_chase_pos(data, my_data, "run")
			elseif focus_enemy.nav_tracker then
				local chase_pos = CopLogicAttack._find_flank_pos(data, my_data, focus_enemy.nav_tracker)

				if chase_pos and mvec3_distance_sq(data.m_pos, chase_pos) > 10000 then
					my_data.chase_path_search_id = tostring(unit:key()) .. "chase"
					my_data.pathing_to_chase_pos = true

					data.brain:add_pos_rsrv("path", {
						radius = 60,
						position = mvec3_copy(chase_pos)
					})
					unit:brain():search_for_path(my_data.chase_path_search_id, chase_pos)
				end
			end
		end
	else
		TankCopLogicAttack._cancel_chase_attempt(data, my_data)
	end
end
