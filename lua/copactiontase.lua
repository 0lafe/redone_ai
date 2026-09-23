local math_abs = math.abs
local math_up = math.UP
local mvec3_dot = mvector3.dot
local mvec3_direction = mvector3.direction
local mvec3_distance = mvector3.distance
local mvec3_normalize = mvector3.normalize
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()

-- Slight improvement for turning radius for tasers
function CopActionTase:update(t)
	if self._expired then
		return
	end

	local shoot_from_pos = self._ext_movement:m_head_pos()
	local target_vec = tmp_vec1
	local target_pos = tmp_vec2

	self._attention.unit:character_damage():shoot_pos_mid(target_pos)
	mvec3_direction(target_vec, shoot_from_pos, target_pos)

	local target_vec_flat = target_vec:with_z(0)

	mvec3_normalize(target_vec_flat)

	local fwd = self._common_data.fwd

	if mvec3_dot(fwd, target_vec_flat) > 0.7 then
		if not self._modifier_on then
			self._modifier_on = true

			self._machine:force_modifier(self._modifier_name)

			self._mod_enable_t = t + 0.5
		end

		self._modifier:set_target_y(target_vec)
	else
		if self._modifier_on then
			self._modifier_on = nil

			self._machine:allow_modifier(self._modifier_name)
		end

		local active_action = self._common_data.active_actions[2]
		local queued_actions = self._common_data.queued_actions

		if (not active_action or active_action:type() == "idle") and (not queued_actions or not queued_actions[1] and not queued_actions[2]) then
			local spin = target_vec_flat:to_polar_with_reference(fwd, math_up).spin

			if math_abs(spin) > 25 then
				self._ext_movement:action_request({
					body_part = 2,
					type = "turn",
					angle = spin
				})
			end
		end

		target_vec = nil
	end

	if not self._ext_anim.reload and not self._ext_anim.equip and not self._ext_anim.melee then
		if self._discharging then
			local vis_ray = self._unit:raycast("ray", shoot_from_pos, target_pos, "slot_mask", self._line_of_fire_slotmask, "sphere_cast_radius", self._w_usage_tweak.tase_sphere_cast_radius, "ignore_unit", self._tasing_local_unit, "report")

			if not self._tasing_local_unit:movement():tased() or vis_ray then
				if Network:is_server() then
					self._expired = true
				else
					self._tasing_local_unit:movement():on_tase_ended()
					self._attention.unit:movement():on_targetted_for_attack(false, self._unit)

					self._discharging = nil
					self._tasing_player = nil
					self._tasing_local_unit = nil
					self.update = self._upd_empty
				end
			end
		elseif self._shoot_t and target_vec and self._common_data.allow_fire and t > self._shoot_t and t > self._mod_enable_t then
			if self._tase_effect then
				World:effect_manager():fade_kill(self._tase_effect)
			end

			self._tase_effect = World:effect_manager():spawn({
				force_synch = true,
				effect = Idstring("effects/payday2/particles/character/taser_thread"),
				parent = self._ext_inventory:equipped_unit():get_object(Idstring("fire"))
			})

			if self._tasing_local_unit and mvec3_distance(shoot_from_pos, target_pos) < self._w_usage_tweak.tase_distance then
				local record = managers.groupai:state():criminal_record(self._tasing_local_unit:key())

				if not record or record.status or self._tasing_local_unit:movement():chk_action_forbidden("hurt") or self._tasing_local_unit:movement():zipline_unit() then
					if Network:is_server() then
						self._expired = true
					end
				elseif not self._unit:raycast("ray", shoot_from_pos, target_pos, "slot_mask", self._line_of_fire_slotmask, "sphere_cast_radius", self._w_usage_tweak.tase_sphere_cast_radius, "ignore_unit", self._tasing_local_unit, "report") then
					self._common_data.ext_network:send("action_tase_event", 3)
					self._attention.unit:character_damage():damage_tase({
						attacker_unit = self._unit
					})
					CopDamage._notify_listeners("on_criminal_tased", self._unit, self._attention.unit)

					self._discharging = true

					if not self._tasing_local_unit:base().is_local_player then
						self._tasered_sound = self._unit:sound():play("tasered_3rd", nil)
					end

					local redir_res = self._ext_movement:play_redirect("recoil_auto")

					self._shoot_t = nil
				end
			elseif not self._tasing_local_unit then
				self._tasered_sound = self._unit:sound():play("tasered_3rd", nil)

				local redir_res = self._ext_movement:play_redirect("recoil_auto")

				self._shoot_t = nil
			end
		end
	end
end
