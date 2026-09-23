local mvec3_copy = mvector3.copy
local REACT_AIM = AIAttentionObject.REACT_AIM
local REACT_COMBAT = AIAttentionObject.REACT_COMBAT
local REACT_SHOOT = AIAttentionObject.REACT_SHOOT
local REACT_SPECIAL_ATTACK = AIAttentionObject.REACT_SPECIAL_ATTACK

function TaserLogicAttack.queued_update(data)
	local my_data = data.internal_data

	data.t = TimerManager:game():time()

	TaserLogicAttack._upd_enemy_detection(data)

	if my_data ~= data.internal_data then
		CopLogicBase._report_detections(data.detected_attention_objects)

		return
	elseif not data.attention_obj then
		CopLogicBase.queue_task(my_data, my_data.update_task_key, TaserLogicAttack.queued_update, data, data.t + 1, data.important)
		CopLogicBase._report_detections(data.detected_attention_objects)

		return
	end

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
		CopLogicBase.queue_task(my_data, my_data.update_task_key, TaserLogicAttack.queued_update, data, data.t + 1.5, data.important)

		return
	end

	if CopLogicIdle._chk_relocate(data) or CopLogicAttack._chk_exit_non_walkable_area(data) then
		return
	end

	CopLogicAttack._update_cover(data)

	if my_data.tasing then
		CopLogicBase.queue_task(my_data, my_data.update_task_key, TaserLogicAttack.queued_update, data, data.t + 2, data.important)
		CopLogicBase._report_detections(data.detected_attention_objects)

		return
	end

	CopLogicAttack._process_pathing_results(data, my_data)

	if REACT_COMBAT <= data.attention_obj.reaction then
		CopLogicAttack._update_cover(data)
		CopLogicAttack._upd_combat_movement(data)
	end

	CopLogicBase.queue_task(my_data, my_data.update_task_key, TaserLogicAttack.queued_update, data, data.t + 1.5, data.important)
	CopLogicBase._report_detections(data.detected_attention_objects)
end

function TaserLogicAttack._upd_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)

	data.t = TimerManager:game():time()

	local my_data = data.internal_data
	local min_reaction = AIAttentionObject.REACT_AIM

	CopLogicBase._upd_attention_obj_detection(data, min_reaction, nil)

	local tasing = my_data.tasing

	if tasing then
		if tasing.target_u_data.unit:movement():tased() or data.t - tasing.start_t < math.max(1, data.char_tweak.weapon.is_rifle.aim_delay_tase[2] * 1.5) then
			return
		end

		TaserLogicAttack._cancel_tase_attempt(data, my_data)
	end

	local new_attention, new_prio_slot, new_reaction = CopLogicIdle._get_priority_attention(data, data.detected_attention_objects, TaserLogicAttack._chk_reaction_to_attention_object)
	local old_att_obj = data.attention_obj

	CopLogicBase._set_attention_obj(data, new_attention, new_reaction)
	CopLogicAttack._chk_exit_attack_logic(data, new_reaction)

	if my_data ~= data.internal_data then
		return
	end

	if new_attention then
		if old_att_obj then
			if old_att_obj.u_key ~= new_attention.u_key then
				CopLogicAttack._cancel_charge(data, my_data)

				if not data.unit:movement():chk_action_forbidden("walk") then
					CopLogicAttack._cancel_walking_to_cover(data, my_data)
				end

				CopLogicAttack._set_best_cover(data, my_data, nil)
				TaserLogicAttack._chk_play_charge_weapon_sound(data, my_data, new_attention)
			end
		else
			TaserLogicAttack._chk_play_charge_weapon_sound(data, my_data, new_attention)
		end
	elseif old_att_obj then
		CopLogicAttack._cancel_charge(data, my_data)
	end

	TaserLogicAttack._upd_aim(data, my_data, new_reaction)
end

function TaserLogicAttack._upd_aim(data, my_data, reaction)
	if my_data.tasing then
		return
	end

	local tase = reaction and reaction == REACT_SPECIAL_ATTACK
	local shoot = tase
	local aim = tase
	local focus_enemy = data.attention_obj
	local verified = focus_enemy and focus_enemy.verified
	local nearly_visible = focus_enemy and focus_enemy.nearly_visible
	local verified_pos = focus_enemy and (focus_enemy.last_verified_pos or focus_enemy.verified_pos)

	if not tase then
		if focus_enemy and reaction >= REACT_AIM then
			local verified_t = focus_enemy.verified_t
			local time_since_verification = verified_t and data.t - verified_t or 60
			local running = my_data.advancing and not my_data.advancing:stopping() and my_data.advancing._cur_vel and my_data.advancing._cur_vel > 300

			if verified or nearly_visible then
				local far = running and data.internal_data.weapon_range.close or data.internal_data.weapon_range.far
				local verified_dis = focus_enemy.verified_dis

				if reaction >= REACT_SHOOT then
					local last_suppression_t = data.unit:character_damage():last_suppression_t()
					local vis_ray = focus_enemy.vis_ray
					local criminal_record = focus_enemy.criminal_record

					if verified and verified_dis < far then
						shoot = true
					elseif verified and criminal_record and criminal_record.assault_t and data.t - criminal_record.assault_t < 2 then
						shoot = true
					elseif my_data.attitude == "engage" and my_data.firing and time_since_verification < 3.5 then
						shoot = true
					elseif last_suppression_t and data.t - last_suppression_t < (running and 2.1 or 7) * (verified and 1 or vis_ray and vis_ray.distance > 500 and 0.5 or 0.2) then
						shoot = true
					end
				end

				aim = shoot or verified_dis < far
			elseif verified_pos then
				aim = not running or time_since_verification < 3.5
				shoot = aim and my_data.shooting and reaction >= REACT_SHOOT and time_since_verification < (running and 2 or 3)
			end

			aim = aim or reaction >= REACT_COMBAT and data.char_tweak.always_face_enemy
		end
	elseif not data.unit:movement():chk_action_forbidden("walk") then
		data.unit:brain():action_request({
			body_part = 2,
			type = "idle"
		})
	end

	if aim or shoot then
		if verified or nearly_visible then
			if my_data.attention_unit ~= focus_enemy.u_key then
				CopLogicBase._set_attention(data, focus_enemy)

				my_data.attention_unit = focus_enemy.u_key
			end
		elseif verified_pos and my_data.attention_unit ~= verified_pos then
			CopLogicBase._set_attention_on_pos(data, mvec3_copy(verified_pos))

			my_data.attention_unit = mvec3_copy(verified_pos)
		end

		if not data.unit:anim_data().reload and not data.unit:movement():chk_action_forbidden("action") then
			if tase and not focus_enemy.unit:movement():zipline_unit() then
				if data.unit:brain():action_request({
					body_part = 3,
					type = "tase"
				}) then
					my_data.tasing = {
						target_u_data = focus_enemy,
						target_u_key = focus_enemy.u_key,
						start_t = data.t
					}

					CopLogicAttack._cancel_charge(data, my_data)
					managers.groupai:state():on_tase_start(data.key, focus_enemy.u_key)
				end
			elseif not my_data.shooting then
				my_data.shooting = data.unit:brain():action_request({
					body_part = 3,
					type = "shoot"
				})
			end
		end
	else
		if my_data.shooting then
			my_data.shooting = not data.unit:brain():action_request({
				body_part = 3,
				type = "idle"
			}) and my_data.shooting
		end

		if my_data.attention_unit then
			CopLogicBase._reset_attention(data)

			my_data.attention_unit = nil
		end
	end

	CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
end

function TaserLogicAttack.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()

	if action_type == "walk" then
		my_data.advancing = nil

		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)

		if my_data.moving_to_cover then
			if action:expired() then
				my_data.in_cover = my_data.moving_to_cover

				CopLogicAttack._set_nearest_cover(my_data, my_data.in_cover)

				my_data.cover_enter_t = data.t
				my_data.cover_sideways_chk = nil
			end

			my_data.moving_to_cover = nil
		elseif my_data.walking_to_cover_shoot_pos then
			my_data.walking_to_cover_shoot_pos = nil
		end

		if action:expired() then
			TaserLogicAttack._upd_aim(data, my_data, data.attention_obj and data.attention_obj.reaction)
		end
	elseif action_type == "shoot" then
		my_data.shooting = nil
	elseif action_type == "act" or action_type == "stand" or action_type == "crouch" or action_type == "reload" then
		if action:expired() then
			TaserLogicAttack._upd_aim(data, my_data, data.attention_obj and data.attention_obj.reaction)
		end
	elseif action_type == "turn" then
		my_data.turning = nil
	elseif action_type == "hurt" or action_type == "healed" then
		CopLogicAttack._cancel_cover_pathing(data, my_data)

		if action:expired() then
			TaserLogicAttack._upd_aim(data, my_data, data.attention_obj and data.attention_obj.reaction)
		end
	elseif action_type == "dodge" then
		local timeout = action:timeout()

		if timeout then
			data.dodge_timeout_t = TimerManager:game():time() + math.lerp(timeout[1], timeout[2], math.random())
		end

		CopLogicAttack._cancel_cover_pathing(data, my_data)

		if action:expired() then
			TaserLogicAttack._upd_aim(data, my_data, data.attention_obj and data.attention_obj.reaction)
		end
	elseif action_type == "tase" then
		if action:expired() and my_data.tasing then
			local record = managers.groupai:state():criminal_record(my_data.tasing.target_u_key)

			if record and record.status then
				data.tase_delay_t = TimerManager:game():time() + 45
			end
		end

		managers.groupai:state():on_tase_end(my_data.tasing.target_u_key)

		my_data.tasing = nil

		if action:expired() then
			TaserLogicAttack._upd_aim(data, my_data, data.attention_obj and data.attention_obj.reaction)
		end
	end
end
