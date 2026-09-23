local var_0_0 = math.abs
local var_0_1 = math.clamp
local var_0_2 = math.lerp
local var_0_3 = math.min
local var_0_4 = math.random
local var_0_5 = math.UP
local var_0_6 = mrotation.x
local var_0_7 = mvector3.add
local var_0_8 = mvector3.angle
local var_0_9 = mvector3.copy
local var_0_10 = mvector3.cross
local var_0_11 = mvector3.direction
local var_0_12 = mvector3.distance
local var_0_13 = mvector3.distance
local var_0_14 = mvector3.dot
local var_0_15 = mvector3.length
local var_0_16 = mvector3.multiply
local var_0_17 = mvector3.negate
local var_0_18 = mvector3.normalize
local var_0_19 = mvector3.random_orthogonal
local var_0_20 = mvector3.set
local var_0_21 = mvector3.set_length
local var_0_22 = mvector3.set_z
local var_0_23 = mvector3.subtract
local var_0_24 = pairs
local var_0_25 = Vector3()
local var_0_26 = Vector3()
local var_0_27 = AIAttentionObject.REACT_COMBAT
local var_0_28 = AIAttentionObject.REACT_SCARED
local var_0_29 = AIAttentionObject.REACT_SUSPICIOUS

function CopLogicBase._upd_attention_obj_detection(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = arg_1_0.t
	local var_1_1 = arg_1_0.detected_attention_objects
	local var_1_2 = arg_1_0.internal_data
	local var_1_3 = arg_1_0.key
	local var_1_4 = arg_1_0.unit:movement():m_head_pos()
	local var_1_5 = arg_1_0.SO_access
	local var_1_6 = managers.groupai:state():get_AI_attention_objects_by_filter(arg_1_0.SO_access_str, arg_1_0.team)
	local var_1_7
	local var_1_8 = arg_1_0.unit:movement():nav_tracker()
	local var_1_9 = var_1_8.check_visibility
	local var_1_10 = managers.groupai:state():is_detection_persistent()
	local var_1_11 = 1
	local var_1_12 = arg_1_0.unit:in_slot(managers.slot:get_mask("enemies")) and {}

	for iter_1_0, iter_1_1 in var_0_24(var_1_6) do
		if iter_1_0 ~= var_1_3 and not var_1_1[iter_1_0] and (not iter_1_1.nav_tracker or var_1_9(var_1_8, iter_1_1.nav_tracker)) then
			local var_1_13 = iter_1_1.handler
			local var_1_14 = var_1_13:get_attention(var_1_5, arg_1_1, arg_1_2, arg_1_0.team)

			if var_1_14 then
				local var_1_15
				local var_1_16
				local var_1_17 = var_1_13:get_detection_m_pos()
				local var_1_18 = var_0_11(var_0_25, var_1_4, var_1_17)
				local var_1_19 = var_1_2.detection

				if var_1_14.uncover_range and var_1_19.use_uncover_range and var_1_18 < var_1_14.uncover_range then
					var_1_15 = -1
				else
					local var_1_20 = var_0_3(var_1_19.dis_max, var_1_14.max_range or var_1_19.dis_max)
					local var_1_21 = var_1_14.detection

					if var_1_21 and var_1_21.range_mul then
						var_1_20 = var_1_20 * var_1_21.range_mul
					end

					if var_1_18 < var_1_20 then
						if var_1_14.notice_requires_FOV then
							var_1_7 = arg_1_0.unit:movement():m_head_rot():z()

							local var_1_22 = var_0_8(var_1_7, var_0_25)

							if var_1_22 < 55 and not var_1_19.use_uncover_range and var_1_14.uncover_range and var_1_18 < var_1_14.uncover_range then
								var_1_15 = -1
							elseif var_1_22 < var_0_2(180, var_1_19.angle_max, var_0_1((var_1_18 - 150) / 700, 0, 1)) then
								var_1_15 = var_1_22
							end
						else
							var_1_15 = 0
						end
					end
				end

				if var_1_15 then
					local var_1_23 = World:raycast("ray", var_1_4, var_1_17, "slot_mask", arg_1_0.visibility_slotmask, "ray_type", "ai_vision")

					if not var_1_23 or var_1_23.unit:key() == iter_1_0 then
						var_1_16 = true
						var_1_1[iter_1_0] = CopLogicBase._create_detected_attention_object_data(arg_1_0.t, arg_1_0.unit, iter_1_0, iter_1_1, var_1_14)
					end
				end

				if not var_1_16 and var_1_12 then
					local var_1_24
					local var_1_25
					local var_1_26

					if iter_1_1.unit:base() then
						local var_1_27 = iter_1_1.unit:base().is_local_player

						var_1_26 = not var_1_27 and iter_1_1.unit:base().is_husk_player
						var_1_24 = var_1_27 or var_1_26
					end

					if var_1_24 then
						local var_1_28 = var_0_11(var_0_25, var_1_17, var_1_4)
						local var_1_29

						if var_1_26 then
							var_1_29 = iter_1_1.unit:movement():detect_look_dir()
						else
							var_1_29 = iter_1_1.unit:movement():m_head_rot():y()
						end

						local var_1_30 = var_1_28 * var_1_28 * (1 - var_0_14(var_1_29, var_0_25))

						var_1_12[#var_1_12 + 1] = iter_1_0
						var_1_12[#var_1_12 + 1] = var_1_30
					end
				end
			end
		end
	end

	for iter_1_2, iter_1_3 in var_0_24(var_1_1) do
		if var_1_0 < iter_1_3.next_verify_t then
			if var_0_29 <= iter_1_3.reaction then
				var_1_11 = var_0_3(iter_1_3.next_verify_t - var_1_0, var_1_11)
			end
		else
			iter_1_3.next_verify_t = var_1_0 + (iter_1_3.identified and iter_1_3.verified and iter_1_3.settings.verification_interval or iter_1_3.settings.notice_interval or iter_1_3.settings.verification_interval)
			var_1_11 = var_0_3(var_1_11, iter_1_3.settings.verification_interval)

			if not iter_1_3.identified then
				local var_1_31
				local var_1_32
				local var_1_33
				local var_1_34 = iter_1_3.m_head_pos
				local var_1_35 = var_0_11(var_0_25, var_1_4, var_1_34)
				local var_1_36 = var_1_2.detection
				local var_1_37 = iter_1_3.settings

				if var_1_37.uncover_range and var_1_36.use_uncover_range and var_1_35 < var_1_37.uncover_range then
					var_1_31 = -1
					var_1_32 = 0
				else
					local var_1_38
					local var_1_39
					local var_1_40 = var_0_3(var_1_36.dis_max, var_1_37.max_range or var_1_36.dis_max)
					local var_1_41 = var_1_37.detection

					if var_1_41 and var_1_41.range_mul then
						var_1_40 = var_1_40 * var_1_41.range_mul
					end

					local var_1_42 = var_1_35 / var_1_40

					if var_1_42 < 1 then
						if var_1_37.notice_requires_FOV then
							var_1_7 = arg_1_0.unit:movement():m_head_rot():z()

							local var_1_43 = var_0_8(var_1_7, var_0_25)

							if var_1_43 < 55 and not var_1_36.use_uncover_range and var_1_37.uncover_range and var_1_35 < var_1_37.uncover_range then
								var_1_31 = -1
								var_1_32 = 0
							elseif var_1_43 / var_0_2(180, var_1_36.angle_max, var_0_1((var_1_35 - 150) / 700, 0, 1)) < 1 then
								var_1_31 = var_1_43
								var_1_32 = var_1_42
							end
						else
							var_1_31 = 0
							var_1_32 = var_1_42
						end
					end
				end

				if var_1_31 then
					local var_1_44 = iter_1_3.handler:get_detection_m_pos()
					local var_1_45 = World:raycast("ray", var_1_4, var_1_44, "slot_mask", arg_1_0.visibility_slotmask, "ray_type", "ai_vision")

					if not var_1_45 or var_1_45.unit:key() == iter_1_2 then
						var_1_33 = true
					end
				end

				local var_1_46
				local var_1_47 = var_1_0 - iter_1_3.prev_notice_chk_t

				if var_1_33 then
					if var_1_31 == -1 then
						var_1_46 = 1
					else
						local var_1_48 = var_1_2.detection.delay[1]
						local var_1_49 = var_1_2.detection.delay[2]
						local var_1_50 = 0.25 * var_0_3(var_1_31 / var_1_2.detection.angle_max, 1)
						local var_1_51 = 0.75 * var_1_32
						local var_1_52 = iter_1_3.settings.notice_delay_mul or 1

						if iter_1_3.settings.detection and iter_1_3.settings.detection.delay_mul then
							var_1_52 = var_1_52 * iter_1_3.settings.detection.delay_mul
						end

						local var_1_53 = var_0_2(var_1_48 * var_1_52, var_1_49, var_1_51 + var_1_50)

						var_1_46 = var_1_53 > 0 and var_1_47 / var_1_53 or 1
					end
				else
					var_1_46 = var_1_47 * -0.125
				end

				iter_1_3.notice_progress = iter_1_3.notice_progress + var_1_46

				if iter_1_3.notice_progress > 1 then
					iter_1_3.notice_progress = nil
					iter_1_3.prev_notice_chk_t = nil
					iter_1_3.identified = true
					iter_1_3.release_t = var_1_0 + iter_1_3.settings.release_delay
					iter_1_3.identified_t = var_1_0
					var_1_33 = true

					arg_1_0.logic.on_attention_obj_identified(arg_1_0, iter_1_2, iter_1_3)
				elseif iter_1_3.notice_progress < 0 then
					CopLogicBase._destroy_detected_attention_object_data(arg_1_0, iter_1_3)

					var_1_33 = false
				else
					var_1_33 = iter_1_3.notice_progress
					iter_1_3.prev_notice_chk_t = var_1_0

					if arg_1_0.cool and var_0_28 <= iter_1_3.settings.reaction then
						managers.groupai:state():on_criminal_suspicion_progress(iter_1_3.unit, arg_1_0.unit, var_1_33)
					end
				end

				if var_1_33 ~= false and iter_1_3.settings.notice_clbk then
					iter_1_3.settings.notice_clbk(arg_1_0.unit, var_1_33)
				end
			end

			if iter_1_3.identified then
				var_1_11 = var_0_3(var_1_11, iter_1_3.settings.verification_interval)
				iter_1_3.nearly_visible = nil

				local var_1_54
				local var_1_55
				local var_1_56 = iter_1_3.handler:get_detection_m_pos()
				local var_1_57 = var_0_12(arg_1_0.m_pos, iter_1_3.m_pos)

				if var_1_57 < var_1_2.detection.dis_max * 1.2 and (not iter_1_3.settings.max_range or var_1_57 < iter_1_3.settings.max_range * (iter_1_3.settings.detection and iter_1_3.settings.detection.range_mul or 1) * 1.2) then
					local var_1_58

					if iter_1_3.is_husk_player and iter_1_3.unit:anim_data().crouch then
						var_1_58 = iter_1_3.m_pos + tweak_data.player.stances.default.crouched.head.translation
					else
						var_1_58 = var_1_56
					end

					local var_1_59 = not iter_1_3.settings.notice_requires_FOV or arg_1_0.enemy_slotmask and iter_1_3.unit:in_slot(arg_1_0.enemy_slotmask)

					if not var_1_59 then
						var_0_11(var_0_25, var_1_4, var_1_56)

						var_1_7 = var_1_7 or arg_1_0.unit:movement():m_head_rot():z()

						local var_1_60 = var_0_8(var_1_7, var_0_25)

						if var_0_2(180, var_1_2.detection.angle_max, var_0_1((var_1_57 - 150) / 700, 0, 1)) > var_1_60 * 0.8 then
							var_1_59 = true
						end
					end

					if var_1_59 then
						var_1_55 = World:raycast("ray", var_1_4, var_1_58, "slot_mask", arg_1_0.visibility_slotmask, "ray_type", "ai_vision")

						if not var_1_55 or var_1_55.unit:key() == iter_1_2 then
							var_1_54 = true
						end
					end
				end

				iter_1_3.verified = var_1_54
				iter_1_3.dis = var_1_57
				iter_1_3.vis_ray = var_1_55 and var_1_55.dis or nil

				local var_1_61 = false

				if iter_1_3.unit:movement() and iter_1_3.unit:movement().is_cuffed then
					var_1_61 = iter_1_3.unit:movement():is_cuffed()
				end

				if var_1_61 then
					CopLogicBase._destroy_detected_attention_object_data(arg_1_0, iter_1_3)
				elseif var_1_54 then
					iter_1_3.release_t = nil
					iter_1_3.verified_t = var_1_0
					iter_1_3.verified_pos = var_1_56
					iter_1_3.last_verified_pos = var_0_9(var_1_56)
					iter_1_3.verified_dis = var_1_57
				elseif arg_1_0.enemy_slotmask and iter_1_3.unit:in_slot(arg_1_0.enemy_slotmask) then
					if iter_1_3.criminal_record and var_0_27 <= iter_1_3.settings.reaction then
						if not var_1_10 and var_0_13(var_1_56, iter_1_3.criminal_record.pos) > 490000 then
							CopLogicBase._destroy_detected_attention_object_data(arg_1_0, iter_1_3)
						else
							var_1_11 = var_0_3(0.2, var_1_11)
							iter_1_3.verified_pos = var_0_9(iter_1_3.criminal_record.pos)
							iter_1_3.verified_dis = var_1_57

							if var_1_55 and arg_1_0.logic._chk_nearly_visible_chk_needed(arg_1_0, iter_1_3, iter_1_2) and iter_1_3.verified_dis < 2000 and var_0_0(var_1_56.z - var_1_4.z) < 300 then
								local var_1_62 = var_0_25

								var_0_20(var_1_62, var_1_56)
								var_0_22(var_1_62, var_1_62.z + 100)

								local var_1_63 = World:raycast("ray", var_1_4, var_1_62, "slot_mask", arg_1_0.visibility_slotmask, "ray_type", "ai_vision", "report")

								if var_1_63 then
									local var_1_64 = var_0_26

									var_0_20(var_1_64, var_1_56)
									var_0_23(var_1_64, var_1_4)
									var_0_10(var_1_64, var_1_64, var_0_5)
									var_0_21(var_1_64, 150)
									var_0_20(var_1_62, var_1_56)
									var_0_7(var_1_62, var_1_64)

									var_1_63 = World:raycast("ray", var_1_4, var_1_62, "slot_mask", arg_1_0.visibility_slotmask, "ray_type", "ai_vision", "report")

									if var_1_63 then
										var_0_16(var_1_64, -2)
										var_0_7(var_1_62, var_1_64)

										var_1_63 = World:raycast("ray", var_1_4, var_1_62, "slot_mask", arg_1_0.visibility_slotmask, "ray_type", "ai_vision", "report")
									end
								end

								if not var_1_63 then
									iter_1_3.nearly_visible = true
									iter_1_3.last_verified_pos = var_0_9(var_1_62)
								end
							end
						end
					elseif iter_1_3.release_t and var_1_0 > iter_1_3.release_t then
						CopLogicBase._destroy_detected_attention_object_data(arg_1_0, iter_1_3)
					else
						iter_1_3.release_t = iter_1_3.release_t or var_1_0 + iter_1_3.settings.release_delay
					end
				elseif iter_1_3.release_t and var_1_0 > iter_1_3.release_t then
					CopLogicBase._destroy_detected_attention_object_data(arg_1_0, iter_1_3)
				else
					iter_1_3.release_t = iter_1_3.release_t or var_1_0 + iter_1_3.settings.release_delay
				end
			end
		end

		if var_1_12 and iter_1_3.is_human_player then
			local var_1_65 = var_0_11(var_0_25, iter_1_3.m_head_pos, var_1_4)
			local var_1_66

			if iter_1_3.is_husk_player then
				var_1_66 = iter_1_3.unit:movement():detect_look_dir()
			else
				var_1_66 = iter_1_3.unit:movement():m_head_rot():y()
			end

			local var_1_67 = var_1_65 * var_1_65 * (1 - var_0_14(var_1_66, var_0_25))

			var_1_12[#var_1_12 + 1] = iter_1_3.u_key
			var_1_12[#var_1_12 + 1] = var_1_67
		end
	end

	if var_1_12 then
		managers.groupai:state():set_importance_weight(arg_1_0.key, var_1_12)
	end

	return var_1_11
end

function CopLogicBase.identify_attention_obj_instant(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_0.detected_attention_objects[arg_2_1]
	local var_2_1 = not var_2_0

	if var_2_0 then
		var_0_20(var_2_0.verified_pos, var_2_0.handler:get_detection_m_pos())

		var_2_0.verified_dis = var_0_12(var_2_0.verified_pos, arg_2_0.unit:movement():m_stand_pos())

		if not var_2_0.identified then
			var_2_0.identified = true
			var_2_0.identified_t = TimerManager:game():time()
			var_2_0.notice_progress = nil
			var_2_0.prev_notice_chk_t = nil

			if var_2_0.settings.notice_clbk then
				var_2_0.settings.notice_clbk(arg_2_0.unit, true)
			end

			arg_2_0.logic.on_attention_obj_identified(arg_2_0, arg_2_1, var_2_0)
		elseif var_2_0.uncover_progress then
			var_2_0.uncover_progress = nil

			var_2_0.unit:movement():on_suspicion(arg_2_0.unit, false)
		end
	else
		local var_2_2 = managers.groupai:state():get_AI_attention_objects_by_filter(arg_2_0.SO_access_str)[arg_2_1]

		if var_2_2 then
			local var_2_3 = var_2_2.handler:get_attention(arg_2_0.SO_access, nil, nil, arg_2_0.team)

			if var_2_3 then
				local var_2_4 = TimerManager:game():time()

				var_2_0 = CopLogicBase._create_detected_attention_object_data(var_2_4, arg_2_0.unit, arg_2_1, var_2_2, var_2_3)
				var_2_0.identified = true
				var_2_0.identified_t = var_2_4
				var_2_0.notice_progress = nil
				var_2_0.prev_notice_chk_t = nil

				if var_2_0.settings.notice_clbk then
					var_2_0.settings.notice_clbk(arg_2_0.unit, true)
				end

				arg_2_0.detected_attention_objects[arg_2_1] = var_2_0

				arg_2_0.logic.on_attention_obj_identified(arg_2_0, arg_2_1, var_2_0)
			end
		end
	end

	return var_2_0, var_2_1
end

function CopLogicBase.chk_start_action_dodge(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_0.char_tweak.dodge

	if not var_3_0 or not var_3_0.occasions[arg_3_1] or arg_3_0.dodge_chk_timeout_t and arg_3_0.t < arg_3_0.dodge_chk_timeout_t or arg_3_0.unit:movement():chk_action_forbidden("walk") then
		return
	end

	local var_3_1 = var_3_0.occasions[arg_3_1]

	arg_3_0.dodge_chk_timeout_t = TimerManager:game():time() + var_0_2(var_3_1.check_timeout[1], var_3_1.check_timeout[2], var_0_4())

	if var_3_1.chance == 0 or var_3_1.chance < var_0_4() then
		return
	end

	local var_3_2 = Vector3()

	if arg_3_0.attention_obj and AIAttentionObject.REACT_COMBAT <= arg_3_0.attention_obj.reaction then
		var_0_20(var_3_2, arg_3_0.attention_obj.m_pos)
		var_0_23(var_3_2, arg_3_0.m_pos)
		var_0_22(var_3_2, 0)
		var_0_18(var_3_2)
		var_0_10(var_3_2, var_3_2, var_0_5)

		if var_0_4() < 0.5 then
			var_0_17(var_3_2)
		end
	else
		var_0_19(var_3_2, var_0_5)
	end

	local var_3_3 = var_0_25
	local var_3_4

	var_0_20(var_3_3, var_3_2)
	var_0_16(var_3_3, 130)
	var_0_7(var_3_3, arg_3_0.m_pos)

	local var_3_5 = {
		trace = true,
		tracker_from = arg_3_0.unit:movement():nav_tracker(),
		pos_to = var_3_3
	}

	if managers.navigation:raycast(var_3_5) then
		var_0_20(var_3_3, var_3_5.trace[1])
		var_0_23(var_3_3, arg_3_0.m_pos)
		var_0_22(var_3_3, 0)

		local var_3_6 = var_0_15(var_3_3)

		var_0_20(var_3_3, var_3_2)
		var_0_16(var_3_3, -130)
		var_0_7(var_3_3, arg_3_0.m_pos)

		if managers.navigation:raycast(var_3_5) then
			var_0_20(var_3_3, var_3_5.trace[1])
			var_0_23(var_3_3, arg_3_0.m_pos)
			var_0_22(var_3_3, 0)

			local var_3_7 = var_0_15(var_3_3)

			if var_3_6 < var_3_7 then
				if var_3_7 < 90 then
					return
				else
					var_0_17(var_3_2)
				end
			elseif var_3_6 < 90 then
				return
			end
		else
			var_0_17(var_3_2)
		end
	end

	var_0_6(arg_3_0.unit:movement():m_rot(), var_3_3)

	local var_3_8 = var_0_14(var_3_2, arg_3_0.unit:movement():m_fwd())
	local var_3_9 = var_0_14(var_3_2, var_3_3)
	local var_3_10 = var_0_0(var_3_8) > 0.7071067690849 and (var_3_8 > 0 and "fwd" or "bwd") or var_3_9 > 0 and "r" or "l"
	local var_3_11 = var_0_4()
	local var_3_12 = 0
	local var_3_13
	local var_3_14

	for iter_3_0, iter_3_1 in var_0_24(var_3_1.variations) do
		var_3_12 = var_3_12 + iter_3_1.chance

		if iter_3_1.chance > 0 and var_3_11 <= var_3_12 then
			var_3_13 = iter_3_0
			var_3_14 = iter_3_1

			break
		end
	end

	local var_3_15 = 1
	local var_3_16 = var_3_14.shoot_chance

	if var_3_16 and var_3_16 > var_0_4() then
		var_3_15 = 2
	end

	local var_3_17 = {
		type = "dodge",
		body_part = var_3_15,
		variation = var_3_13,
		side = var_3_10,
		direction = var_3_2,
		timeout = var_3_14.timeout,
		speed = var_3_0.speed,
		shoot_accuracy = var_3_14.shoot_accuracy,
		blocks = {
			tase = -1,
			walk = -1,
			bleedout = -1,
			dodge = -1,
			act = -1,
			action = var_3_15 == 1 and -1 or nil,
			aim = var_3_15 == 1 and -1 or nil,
			hurt = var_3_13 ~= "side_step" and -1 or nil,
			heavy_hurt = var_3_13 ~= "side_step" and -1 or nil
		}
	}
	local var_3_18 = arg_3_0.unit:movement():action_request(var_3_17)

	if var_3_18 then
		local var_3_19 = arg_3_0.internal_data

		CopLogicAttack._cancel_cover_pathing(arg_3_0, var_3_19)
		CopLogicAttack._cancel_charge(arg_3_0, var_3_19)
		CopLogicAttack._cancel_expected_pos_path(arg_3_0, var_3_19)
		CopLogicAttack._cancel_walking_to_cover(arg_3_0, var_3_19, true)
	end

	return var_3_18
end

function CopLogicBase.chk_am_i_aimed_at(arg_4_0, arg_4_1, arg_4_2)
	if not arg_4_1.is_person then
		return
	end

	if arg_4_1.dis < 700 and arg_4_2 > 0.3 then
		arg_4_2 = math.lerp(0.3, arg_4_2, (arg_4_1.dis - 50) / 650)
	end

	local var_4_0 = var_0_25

	if arg_4_1.is_local_player then
		mrotation.y(arg_4_1.unit:movement():m_head_rot(), var_4_0)
	elseif arg_4_1.is_husk_player then
		var_0_20(var_4_0, arg_4_1.unit:movement():detect_look_dir())
	else
		var_0_20(var_4_0, arg_4_1.unit:movement():look_vec())
	end

	local var_4_1 = var_0_26

	var_0_11(var_4_1, arg_4_1.m_head_pos, arg_4_0.unit:movement():m_com())

	return arg_4_2 < var_0_14(var_4_1, var_4_0)
end
