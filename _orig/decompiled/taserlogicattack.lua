local var_0_0 = mvector3.copy
local var_0_1 = AIAttentionObject.REACT_AIM
local var_0_2 = AIAttentionObject.REACT_COMBAT
local var_0_3 = AIAttentionObject.REACT_SHOOT
local var_0_4 = AIAttentionObject.REACT_SPECIAL_ATTACK

function TaserLogicAttack.queued_update(arg_1_0)
	local var_1_0 = arg_1_0.internal_data

	arg_1_0.t = TimerManager:game():time()

	TaserLogicAttack._upd_enemy_detection(arg_1_0)

	if var_1_0 ~= arg_1_0.internal_data then
		CopLogicBase._report_detections(arg_1_0.detected_attention_objects)

		return
	elseif not arg_1_0.attention_obj then
		CopLogicBase.queue_task(var_1_0, var_1_0.update_task_key, TaserLogicAttack.queued_update, arg_1_0, arg_1_0.t + 1, arg_1_0.important)
		CopLogicBase._report_detections(arg_1_0.detected_attention_objects)

		return
	end

	if var_1_0.has_old_action then
		CopLogicAttack._upd_stop_old_action(arg_1_0, var_1_0)
		CopLogicBase.queue_task(var_1_0, var_1_0.update_task_key, TaserLogicAttack.queued_update, arg_1_0, arg_1_0.t + 1.5, arg_1_0.important)

		return
	end

	if CopLogicIdle._chk_relocate(arg_1_0) or CopLogicAttack._chk_exit_non_walkable_area(arg_1_0) then
		return
	end

	CopLogicAttack._update_cover(arg_1_0)

	if var_1_0.tasing then
		CopLogicBase.queue_task(var_1_0, var_1_0.update_task_key, TaserLogicAttack.queued_update, arg_1_0, arg_1_0.t + 2, arg_1_0.important)
		CopLogicBase._report_detections(arg_1_0.detected_attention_objects)

		return
	end

	CopLogicAttack._process_pathing_results(arg_1_0, var_1_0)

	if var_0_2 <= arg_1_0.attention_obj.reaction then
		CopLogicAttack._update_cover(arg_1_0)
		CopLogicAttack._upd_combat_movement(arg_1_0)
	end

	CopLogicBase.queue_task(var_1_0, var_1_0.update_task_key, TaserLogicAttack.queued_update, arg_1_0, arg_1_0.t + 1.5, arg_1_0.important)
	CopLogicBase._report_detections(arg_1_0.detected_attention_objects)
end

function TaserLogicAttack._upd_enemy_detection(arg_2_0)
	managers.groupai:state():on_unit_detection_updated(arg_2_0.unit)

	arg_2_0.t = TimerManager:game():time()

	local var_2_0 = arg_2_0.internal_data
	local var_2_1 = AIAttentionObject.REACT_AIM

	CopLogicBase._upd_attention_obj_detection(arg_2_0, var_2_1, nil)

	if var_2_0.tasing then
		return
	end

	local var_2_2, var_2_3, var_2_4 = CopLogicIdle._get_priority_attention(arg_2_0, arg_2_0.detected_attention_objects, TaserLogicAttack._chk_reaction_to_attention_object)
	local var_2_5 = arg_2_0.attention_obj

	CopLogicBase._set_attention_obj(arg_2_0, var_2_2, var_2_4)
	CopLogicAttack._chk_exit_attack_logic(arg_2_0, var_2_4)

	if var_2_0 ~= arg_2_0.internal_data then
		return
	end

	if var_2_2 then
		if var_2_5 then
			if var_2_5.u_key ~= var_2_2.u_key then
				CopLogicAttack._cancel_charge(arg_2_0, var_2_0)

				if not arg_2_0.unit:movement():chk_action_forbidden("walk") then
					CopLogicAttack._cancel_walking_to_cover(arg_2_0, var_2_0)
				end

				CopLogicAttack._set_best_cover(arg_2_0, var_2_0, nil)
				TaserLogicAttack._chk_play_charge_weapon_sound(arg_2_0, var_2_0, var_2_2)
			end
		else
			TaserLogicAttack._chk_play_charge_weapon_sound(arg_2_0, var_2_0, var_2_2)
		end
	elseif var_2_5 then
		CopLogicAttack._cancel_charge(arg_2_0, var_2_0)
	end

	TaserLogicAttack._upd_aim(arg_2_0, var_2_0, var_2_4)
end

function TaserLogicAttack._upd_aim(arg_3_0, arg_3_1, arg_3_2)
	if arg_3_1.tasing then
		return
	end

	local var_3_0 = arg_3_2 and arg_3_2 == var_0_4
	local var_3_1 = var_3_0
	local var_3_2 = var_3_0
	local var_3_3 = arg_3_0.attention_obj
	local var_3_4 = var_3_3 and var_3_3.verified
	local var_3_5 = var_3_3 and var_3_3.nearly_visible
	local var_3_6 = var_3_3 and (var_3_3.last_verified_pos or var_3_3.verified_pos)

	if not var_3_0 then
		if var_3_3 and arg_3_2 >= var_0_1 then
			local var_3_7 = var_3_3.verified_t
			local var_3_8 = var_3_7 and arg_3_0.t - var_3_7 or 60
			local var_3_9 = arg_3_1.advancing and not arg_3_1.advancing:stopping() and arg_3_1.advancing._cur_vel and arg_3_1.advancing._cur_vel > 300

			if var_3_4 or var_3_5 then
				local var_3_10 = var_3_9 and arg_3_0.internal_data.weapon_range.close or arg_3_0.internal_data.weapon_range.far
				local var_3_11 = var_3_3.verified_dis

				if arg_3_2 >= var_0_3 then
					local var_3_12 = arg_3_0.unit:character_damage():last_suppression_t()
					local var_3_13 = var_3_3.vis_ray
					local var_3_14 = var_3_3.criminal_record

					if var_3_4 and var_3_11 < var_3_10 then
						var_3_1 = true
					elseif var_3_4 and var_3_14 and var_3_14.assault_t and arg_3_0.t - var_3_14.assault_t < 2 then
						var_3_1 = true
					elseif arg_3_1.attitude == "engage" and arg_3_1.firing and var_3_8 < 3.5 then
						var_3_1 = true
					elseif var_3_12 and arg_3_0.t - var_3_12 < (var_3_9 and 2.1 or 7) * (var_3_4 and 1 or var_3_13 and var_3_13.distance > 500 and 0.5 or 0.2) then
						var_3_1 = true
					end
				end

				var_3_2 = var_3_1 or var_3_11 < var_3_10
			elseif var_3_6 then
				var_3_2 = not var_3_9 or var_3_8 < 3.5
				var_3_1 = var_3_2 and arg_3_1.shooting and arg_3_2 >= var_0_3 and var_3_8 < (var_3_9 and 2 or 3)
			end

			var_3_2 = var_3_2 or arg_3_2 >= var_0_2 and arg_3_0.char_tweak.always_face_enemy
		end
	elseif not arg_3_0.unit:movement():chk_action_forbidden("walk") then
		arg_3_0.unit:brain():action_request({
			body_part = 2,
			type = "idle"
		})
	end

	if var_3_2 or var_3_1 then
		if var_3_4 or var_3_5 then
			if arg_3_1.attention_unit ~= var_3_3.u_key then
				CopLogicBase._set_attention(arg_3_0, var_3_3)

				arg_3_1.attention_unit = var_3_3.u_key
			end
		elseif var_3_6 and arg_3_1.attention_unit ~= var_3_6 then
			CopLogicBase._set_attention_on_pos(arg_3_0, var_0_0(var_3_6))

			arg_3_1.attention_unit = var_0_0(var_3_6)
		end

		if not arg_3_0.unit:anim_data().reload and not arg_3_0.unit:movement():chk_action_forbidden("action") then
			if var_3_0 and not var_3_3.unit:movement():zipline_unit() then
				if arg_3_0.unit:brain():action_request({
					body_part = 3,
					type = "tase"
				}) then
					arg_3_1.tasing = {
						target_u_data = var_3_3,
						target_u_key = var_3_3.u_key,
						start_t = arg_3_0.t
					}

					CopLogicAttack._cancel_charge(arg_3_0, arg_3_1)
					managers.groupai:state():on_tase_start(arg_3_0.key, var_3_3.u_key)
				end
			elseif not arg_3_1.shooting then
				arg_3_1.shooting = arg_3_0.unit:brain():action_request({
					body_part = 3,
					type = "shoot"
				})
			end
		end
	else
		if arg_3_1.shooting then
			arg_3_1.shooting = not arg_3_0.unit:brain():action_request({
				body_part = 3,
				type = "idle"
			}) and arg_3_1.shooting
		end

		if arg_3_1.attention_unit then
			CopLogicBase._reset_attention(arg_3_0)

			arg_3_1.attention_unit = nil
		end
	end

	CopLogicAttack.aim_allow_fire(var_3_1, var_3_2, arg_3_0, arg_3_1)
end

function TaserLogicAttack.action_complete_clbk(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0.internal_data
	local var_4_1 = arg_4_1:type()

	if var_4_1 == "walk" then
		var_4_0.advancing = nil

		CopLogicAttack._cancel_cover_pathing(arg_4_0, var_4_0)
		CopLogicAttack._cancel_charge(arg_4_0, var_4_0)

		if var_4_0.moving_to_cover then
			if arg_4_1:expired() then
				var_4_0.in_cover = var_4_0.moving_to_cover

				CopLogicAttack._set_nearest_cover(var_4_0, var_4_0.in_cover)

				var_4_0.cover_enter_t = arg_4_0.t
				var_4_0.cover_sideways_chk = nil
			end

			var_4_0.moving_to_cover = nil
		elseif var_4_0.walking_to_cover_shoot_pos then
			var_4_0.walking_to_cover_shoot_pos = nil
		end

		if arg_4_1:expired() then
			TaserLogicAttack._upd_aim(arg_4_0, var_4_0, arg_4_0.attention_obj and arg_4_0.attention_obj.reaction)
		end
	elseif var_4_1 == "shoot" then
		var_4_0.shooting = nil
	elseif var_4_1 == "act" or var_4_1 == "stand" or var_4_1 == "crouch" or var_4_1 == "reload" then
		if arg_4_1:expired() then
			TaserLogicAttack._upd_aim(arg_4_0, var_4_0, arg_4_0.attention_obj and arg_4_0.attention_obj.reaction)
		end
	elseif var_4_1 == "turn" then
		var_4_0.turning = nil
	elseif var_4_1 == "hurt" or var_4_1 == "healed" then
		CopLogicAttack._cancel_cover_pathing(arg_4_0, var_4_0)

		if arg_4_1:expired() then
			TaserLogicAttack._upd_aim(arg_4_0, var_4_0, arg_4_0.attention_obj and arg_4_0.attention_obj.reaction)
		end
	elseif var_4_1 == "dodge" then
		local var_4_2 = arg_4_1:timeout()

		if var_4_2 then
			arg_4_0.dodge_timeout_t = TimerManager:game():time() + math.lerp(var_4_2[1], var_4_2[2], math.random())
		end

		CopLogicAttack._cancel_cover_pathing(arg_4_0, var_4_0)

		if arg_4_1:expired() then
			TaserLogicAttack._upd_aim(arg_4_0, var_4_0, arg_4_0.attention_obj and arg_4_0.attention_obj.reaction)
		end
	elseif var_4_1 == "tase" then
		if arg_4_1:expired() and var_4_0.tasing then
			local var_4_3 = managers.groupai:state():criminal_record(var_4_0.tasing.target_u_key)

			if var_4_3 and var_4_3.status then
				arg_4_0.tase_delay_t = TimerManager:game():time() + 45
			end
		end

		managers.groupai:state():on_tase_end(var_4_0.tasing.target_u_key)

		var_4_0.tasing = nil

		if arg_4_1:expired() then
			TaserLogicAttack._upd_aim(arg_4_0, var_4_0, arg_4_0.attention_obj and arg_4_0.attention_obj.reaction)
		end
	end
end
