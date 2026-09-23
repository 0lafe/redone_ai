local math_abs = math.abs
local math_clamp = math.clamp
local math_lerp = math.lerp
local math_min = math.min
local math_random = math.random
local math_up = math.UP
local mrot_x = mrotation.x
local mvec3_add = mvector3.add
local mvec3_angle = mvector3.angle
local mvec3_copy = mvector3.copy
local mvec3_cross = mvector3.cross
local mvec3_direction = mvector3.direction
local mvec3_distance = mvector3.distance
local mvec3_dot = mvector3.dot
local mvec3_length = mvector3.length
local mvec3_multiply = mvector3.multiply
local mvec3_negate = mvector3.negate
local mvec3_normalize = mvector3.normalize
local mvec3_random_orthogonal = mvector3.random_orthogonal
local mvec3_set = mvector3.set
local mvec3_set_length = mvector3.set_length
local mvec3_set_z = mvector3.set_z
local mvec3_subtract = mvector3.subtract
local pairs_g = pairs
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local REACT_COMBAT = AIAttentionObject.REACT_COMBAT
local REACT_SCARED = AIAttentionObject.REACT_SCARED
local REACT_SUSPICIOUS = AIAttentionObject.REACT_SUSPICIOUS

function CopLogicBase._upd_attention_obj_detection(data, min_reaction, max_reaction)
	local t = data.t
	local detected_obj = data.detected_attention_objects
	local my_data = data.internal_data
	local my_key = data.key
	local my_pos = data.unit:movement():m_head_pos()
	local my_access = data.SO_access
	local all_attention_objects = managers.groupai:state():get_AI_attention_objects_by_filter(data.SO_access_str, data.team)
	local my_head_fwd
	local my_tracker = data.unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	local is_detection_persistent = managers.groupai:state():is_detection_persistent()
	local delay = 1
	local player_importance_wgt = data.unit:in_slot(managers.slot:get_mask("enemies")) and {}

	for u_key, attention_info in pairs_g(all_attention_objects) do
		if u_key ~= my_key and not detected_obj[u_key] and (not attention_info.nav_tracker or chk_vis_func(my_tracker, attention_info.nav_tracker)) then
			local handler = attention_info.handler
			local settings = handler:get_attention(my_access, min_reaction, max_reaction, data.team)

			if settings then
				local angle
				local acquired
				local attention_pos = handler:get_detection_m_pos()
				local dis = mvec3_direction(tmp_vec1, my_pos, attention_pos)
				local detection = my_data.detection

				if settings.uncover_range and detection.use_uncover_range and dis < settings.uncover_range then
					angle = -1
				else
					local dis_max = math_min(detection.dis_max, settings.max_range or detection.dis_max)
					local settings_detection = settings.detection

					if settings_detection and settings_detection.range_mul then
						dis_max = dis_max * settings_detection.range_mul
					end

					if dis < dis_max then
						if settings.notice_requires_FOV then
							my_head_fwd = data.unit:movement():m_head_rot():z()

							local head_angle = mvec3_angle(my_head_fwd, tmp_vec1)

							if head_angle < 55 and not detection.use_uncover_range and settings.uncover_range and dis < settings.uncover_range then
								angle = -1
							elseif head_angle < math_lerp(180, detection.angle_max, math_clamp((dis - 150) / 700, 0, 1)) then
								angle = head_angle
							end
						else
							angle = 0
						end
					end
				end

				if angle then
					local vis_ray = World:raycast("ray", my_pos, attention_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision")

					if not vis_ray or vis_ray.unit:key() == u_key then
						acquired = true
						detected_obj[u_key] = CopLogicBase._create_detected_attention_object_data(data.t, data.unit, u_key, attention_info, settings)
					end
				end

				if not acquired and player_importance_wgt then
					local is_human_player
					local is_husk_player

					if attention_info.unit:base() then
						local is_local_player = attention_info.unit:base().is_local_player

						is_husk_player = not is_local_player and attention_info.unit:base().is_husk_player
						is_human_player = is_local_player or is_husk_player
					end

					if is_human_player then
						local dis_to_me = mvec3_direction(tmp_vec1, attention_pos, my_pos)
						local detect_look_dir

						if is_husk_player then
							detect_look_dir = attention_info.unit:movement():detect_look_dir()
						else
							detect_look_dir = attention_info.unit:movement():m_head_rot():y()
						end

						local wgt = dis_to_me * dis_to_me * (1 - mvec3_dot(detect_look_dir, tmp_vec1))

						player_importance_wgt[#player_importance_wgt + 1] = u_key
						player_importance_wgt[#player_importance_wgt + 1] = wgt
					end
				end
			end
		end
	end

	for u_key, attention_info in pairs_g(detected_obj) do
		if t < attention_info.next_verify_t then
			if REACT_SUSPICIOUS <= attention_info.reaction then
				delay = math_min(attention_info.next_verify_t - t, delay)
			end
		else
			attention_info.next_verify_t = t + (attention_info.identified and attention_info.verified and attention_info.settings.verification_interval or attention_info.settings.notice_interval or attention_info.settings.verification_interval)
			delay = math_min(delay, attention_info.settings.verification_interval)

			if not attention_info.identified then
				local angle
				local dis_multiplier
				local noticable
				local att_head_pos = attention_info.m_head_pos
				local dis = mvec3_direction(tmp_vec1, my_pos, att_head_pos)
				local detection = my_data.detection
				local settings = attention_info.settings

				if settings.uncover_range and detection.use_uncover_range and dis < settings.uncover_range then
					angle = -1
					dis_multiplier = 0
				else
					local dis_max = math_min(detection.dis_max, settings.max_range or detection.dis_max)
					local settings_detection = settings.detection

					if settings_detection and settings_detection.range_mul then
						dis_max = dis_max * settings_detection.range_mul
					end

					local dis_mul = dis / dis_max

					if dis_mul < 1 then
						if settings.notice_requires_FOV then
							my_head_fwd = data.unit:movement():m_head_rot():z()

							local head_angle = mvec3_angle(my_head_fwd, tmp_vec1)

							if head_angle < 55 and not detection.use_uncover_range and settings.uncover_range and dis < settings.uncover_range then
								angle = -1
								dis_multiplier = 0
							elseif head_angle / math_lerp(180, detection.angle_max, math_clamp((dis - 150) / 700, 0, 1)) < 1 then
								angle = head_angle
								dis_multiplier = dis_mul
							end
						else
							angle = 0
							dis_multiplier = dis_mul
						end
					end
				end

				if angle then
					local attention_pos = attention_info.handler:get_detection_m_pos()
					local vis_ray = World:raycast("ray", my_pos, attention_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision")

					if not vis_ray or vis_ray.unit:key() == u_key then
						noticable = true
					end
				end

				local delta_prog
				local dt = t - attention_info.prev_notice_chk_t

				if noticable then
					if angle == -1 then
						-- Vanilla version gives client more leway which is removed for now. Restore if it feels bad as client
						-- delta_prog = dt / (peer ping in seconds) + 0.02

						delta_prog = 1
					else
						local min_delay = my_data.detection.delay[1]
						local max_delay = my_data.detection.delay[2]
						local angle_mul_mod = 0.25 * math_min(angle / my_data.detection.angle_max, 1)
						local dis_mul_mod = 0.75 * dis_multiplier
						local notice_delay_mul = attention_info.settings.notice_delay_mul or 1

						if attention_info.settings.detection and attention_info.settings.detection.delay_mul then
							notice_delay_mul = notice_delay_mul * attention_info.settings.detection.delay_mul
						end

						-- Vanilla adds the peer's ping here for husk players:
						--   notice_delay_modified = notice_delay_modified + ping/1000 + 0.02
						-- That is the "enemies ignore me for a moment" grace period clients get and
						-- the host never does. Deliberately skipped for now; revisit after testing.
						local notice_delay_modified = math_lerp(min_delay * notice_delay_mul, max_delay, dis_mul_mod + angle_mul_mod)

						delta_prog = notice_delay_modified > 0 and dt / notice_delay_modified or 1
					end
				else
					delta_prog = dt * -0.125
				end

				attention_info.notice_progress = attention_info.notice_progress + delta_prog

				if attention_info.notice_progress > 1 then
					attention_info.notice_progress = nil
					attention_info.prev_notice_chk_t = nil
					attention_info.identified = true
					attention_info.release_t = t + attention_info.settings.release_delay
					attention_info.identified_t = t
					noticable = true

					data.logic.on_attention_obj_identified(data, u_key, attention_info)
				elseif attention_info.notice_progress < 0 then
					CopLogicBase._destroy_detected_attention_object_data(data, attention_info)

					noticable = false
				else
					noticable = attention_info.notice_progress
					attention_info.prev_notice_chk_t = t

					if data.cool and REACT_SCARED <= attention_info.settings.reaction then
						managers.groupai:state():on_criminal_suspicion_progress(attention_info.unit, data.unit, noticable)
					end
				end

				if noticable ~= false and attention_info.settings.notice_clbk then
					attention_info.settings.notice_clbk(data.unit, noticable)
				end
			end

			if attention_info.identified then
				delay = math_min(delay, attention_info.settings.verification_interval)
				attention_info.nearly_visible = nil

				local verified
				local vis_ray
				local attention_pos = attention_info.handler:get_detection_m_pos()
				local dis = mvec3_distance(data.m_pos, attention_info.m_pos)

				if dis < my_data.detection.dis_max * 1.2 and (not attention_info.settings.max_range or dis < attention_info.settings.max_range * (attention_info.settings.detection and attention_info.settings.detection.range_mul or 1) * 1.2) then
					local detect_pos

					if attention_info.is_husk_player and attention_info.unit:anim_data().crouch then
						detect_pos = attention_info.m_pos + tweak_data.player.stances.default.crouched.head.translation
					else
						detect_pos = attention_pos
					end

					local in_FOV = not attention_info.settings.notice_requires_FOV or data.enemy_slotmask and attention_info.unit:in_slot(data.enemy_slotmask)

					if not in_FOV then
						mvec3_direction(tmp_vec1, my_pos, attention_pos)

						my_head_fwd = my_head_fwd or data.unit:movement():m_head_rot():z()

						local angle = mvec3_angle(my_head_fwd, tmp_vec1)

						if math_lerp(180, my_data.detection.angle_max, math_clamp((dis - 150) / 700, 0, 1)) > angle * 0.8 then
							in_FOV = true
						end
					end

					if in_FOV then
						vis_ray = World:raycast("ray", my_pos, detect_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision")

						if not vis_ray or vis_ray.unit:key() == u_key then
							verified = true
						end
					end
				end

				attention_info.verified = verified
				attention_info.dis = dis
				attention_info.vis_ray = vis_ray and vis_ray.dis or nil

				local is_ignored = false

				if attention_info.unit:movement() and attention_info.unit:movement().is_cuffed then
					is_ignored = attention_info.unit:movement():is_cuffed()
				end

				if is_ignored then
					CopLogicBase._destroy_detected_attention_object_data(data, attention_info)
				elseif verified then
					attention_info.release_t = nil
					attention_info.verified_t = t
					-- Must copy INTO the owned vector. attention_pos is the handler's live
					-- _m_detect_pos; assigning it would make verified_pos track the target in
					-- real time and defeat the whole point of a "last seen" position.
					mvec3_set(attention_info.verified_pos, attention_pos)
					attention_info.last_verified_pos = mvec3_copy(attention_pos)
					attention_info.verified_dis = dis
				elseif data.enemy_slotmask and attention_info.unit:in_slot(data.enemy_slotmask) then
					if attention_info.criminal_record and REACT_COMBAT <= attention_info.settings.reaction then
						-- LIKELY BUG (left as-is for play testing): 490000 is 700^2, so this was
						-- meant to be mvector3.distance_sq -- the original aliased mvector3.distance
						-- twice by mistake. Vanilla is: distance(...) > 700. With a linear distance
						-- the test never passes, so an attention object whose shared criminal_record
						-- position has drifted far from where we last saw them is never dropped --
						-- i.e. enemies never lose track. Only matters outside an active assault,
						-- since is_detection_persistent() is true while a wave is running.
						if not is_detection_persistent and mvec3_distance(attention_pos, attention_info.criminal_record.pos) > 490000 then
							CopLogicBase._destroy_detected_attention_object_data(data, attention_info)
						else
							delay = math_min(0.2, delay)
							attention_info.verified_pos = mvec3_copy(attention_info.criminal_record.pos)
							attention_info.verified_dis = dis

							if vis_ray and data.logic._chk_nearly_visible_chk_needed(data, attention_info, u_key) and attention_info.verified_dis < 2000 and math_abs(attention_pos.z - my_pos.z) < 300 then
								local near_pos = tmp_vec1

								mvec3_set(near_pos, attention_pos)
								mvec3_set_z(near_pos, near_pos.z + 100)

								local near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision", "report")

								if near_vis_ray then
									local side_vec = tmp_vec2

									mvec3_set(side_vec, attention_pos)
									mvec3_subtract(side_vec, my_pos)
									mvec3_cross(side_vec, side_vec, math_up)
									mvec3_set_length(side_vec, 150)
									mvec3_set(near_pos, attention_pos)
									mvec3_add(near_pos, side_vec)

									near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision", "report")

									if near_vis_ray then
										mvec3_multiply(side_vec, -2)
										mvec3_add(near_pos, side_vec)

										near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision", "report")
									end
								end

								if not near_vis_ray then
									attention_info.nearly_visible = true
									attention_info.last_verified_pos = mvec3_copy(near_pos)
								end
							end
						end
					elseif attention_info.release_t and t > attention_info.release_t then
						CopLogicBase._destroy_detected_attention_object_data(data, attention_info)
					else
						attention_info.release_t = attention_info.release_t or t + attention_info.settings.release_delay
					end
				elseif attention_info.release_t and t > attention_info.release_t then
					CopLogicBase._destroy_detected_attention_object_data(data, attention_info)
				else
					attention_info.release_t = attention_info.release_t or t + attention_info.settings.release_delay
				end
			end
		end

		if player_importance_wgt and attention_info.is_human_player then
			local dis = mvec3_direction(tmp_vec1, attention_info.m_head_pos, my_pos)
			local detect_look_dir

			if attention_info.is_husk_player then
				detect_look_dir = attention_info.unit:movement():detect_look_dir()
			else
				detect_look_dir = attention_info.unit:movement():m_head_rot():y()
			end

			local wgt = dis * dis * (1 - mvec3_dot(detect_look_dir, tmp_vec1))

			player_importance_wgt[#player_importance_wgt + 1] = attention_info.u_key
			player_importance_wgt[#player_importance_wgt + 1] = wgt
		end
	end

	if player_importance_wgt then
		managers.groupai:state():set_importance_weight(data.key, player_importance_wgt)
	end

	return delay
end

function CopLogicBase.chk_start_action_dodge(data, reason)
	local dodge = data.char_tweak.dodge

	if not dodge or not dodge.occasions[reason] or data.dodge_chk_timeout_t and data.t < data.dodge_chk_timeout_t or data.unit:movement():chk_action_forbidden("walk") then
		return
	end

	local dodge_tweak = dodge.occasions[reason]

	data.dodge_chk_timeout_t = TimerManager:game():time() + math_lerp(dodge_tweak.check_timeout[1], dodge_tweak.check_timeout[2], math_random())

	if dodge_tweak.chance == 0 or dodge_tweak.chance < math_random() then
		return
	end

	local dodge_dir = Vector3()

	if data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction then
		mvec3_set(dodge_dir, data.attention_obj.m_pos)
		mvec3_subtract(dodge_dir, data.m_pos)
		mvec3_set_z(dodge_dir, 0)
		mvec3_normalize(dodge_dir)
		mvec3_cross(dodge_dir, dodge_dir, math_up)

		if math_random() < 0.5 then
			mvec3_negate(dodge_dir)
		end
	else
		mvec3_random_orthogonal(dodge_dir, math_up)
	end

	local test_pos = tmp_vec1
	local unused_4 -- unused, kept for bytecode parity

	mvec3_set(test_pos, dodge_dir)
	mvec3_multiply(test_pos, 130)
	mvec3_add(test_pos, data.m_pos)

	local ray_params = {
		trace = true,
		tracker_from = data.unit:movement():nav_tracker(),
		pos_to = test_pos
	}

	if managers.navigation:raycast(ray_params) then
		mvec3_set(test_pos, ray_params.trace[1])
		mvec3_subtract(test_pos, data.m_pos)
		mvec3_set_z(test_pos, 0)

		local blocked_dis_1 = mvec3_length(test_pos)

		mvec3_set(test_pos, dodge_dir)
		mvec3_multiply(test_pos, -130)
		mvec3_add(test_pos, data.m_pos)

		if managers.navigation:raycast(ray_params) then
			mvec3_set(test_pos, ray_params.trace[1])
			mvec3_subtract(test_pos, data.m_pos)
			mvec3_set_z(test_pos, 0)

			local blocked_dis_2 = mvec3_length(test_pos)

			if blocked_dis_1 < blocked_dis_2 then
				if blocked_dis_2 < 90 then
					return
				else
					mvec3_negate(dodge_dir)
				end
			elseif blocked_dis_1 < 90 then
				return
			end
		else
			mvec3_negate(dodge_dir)
		end
	end

	mrot_x(data.unit:movement():m_rot(), test_pos)

	local fwd_dot = mvec3_dot(dodge_dir, data.unit:movement():m_fwd())
	local right_dot = mvec3_dot(dodge_dir, test_pos)
	local dodge_side = math_abs(fwd_dot) > 0.7071067690849 and (fwd_dot > 0 and "fwd" or "bwd") or right_dot > 0 and "r" or "l"
	local rand_nr = math_random()
	local total_chance = 0
	local variation
	local variation_data

	for test_variation, test_variation_data in pairs_g(dodge_tweak.variations) do
		total_chance = total_chance + test_variation_data.chance

		if test_variation_data.chance > 0 and rand_nr <= total_chance then
			variation = test_variation
			variation_data = test_variation_data

			break
		end
	end

	local body_part = 1
	local shoot_chance = variation_data.shoot_chance

	if shoot_chance and shoot_chance > math_random() then
		body_part = 2
	end

	local action_data = {
		type = "dodge",
		body_part = body_part,
		variation = variation,
		side = dodge_side,
		direction = dodge_dir,
		timeout = variation_data.timeout,
		speed = dodge.speed,
		shoot_accuracy = variation_data.shoot_accuracy,
		blocks = {
			tase = -1,
			walk = -1,
			bleedout = -1,
			dodge = -1,
			act = -1,
			action = body_part == 1 and -1 or nil,
			aim = body_part == 1 and -1 or nil,
			hurt = variation ~= "side_step" and -1 or nil,
			heavy_hurt = variation ~= "side_step" and -1 or nil
		}
	}
	local action = data.unit:movement():action_request(action_data)

	if action then
		local my_data = data.internal_data

		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)
		CopLogicAttack._cancel_expected_pos_path(data, my_data)
		CopLogicAttack._cancel_walking_to_cover(data, my_data, true)
	end

	return action
end
