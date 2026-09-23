local var_0_0 = math.abs
local var_0_1 = math.UP
local var_0_2 = mvector3.dot
local var_0_3 = mvector3.direction
local var_0_4 = mvector3.distance
local var_0_5 = mvector3.normalize
local var_0_6 = Vector3()
local var_0_7 = Vector3()

function CopActionTase.update(arg_1_0, arg_1_1)
	if arg_1_0._expired then
		return
	end

	local var_1_0 = arg_1_0._ext_movement:m_head_pos()
	local var_1_1 = var_0_6
	local var_1_2 = var_0_7

	arg_1_0._attention.unit:character_damage():shoot_pos_mid(var_1_2)
	var_0_3(var_1_1, var_1_0, var_1_2)

	local var_1_3 = var_1_1:with_z(0)

	var_0_5(var_1_3)

	local var_1_4 = arg_1_0._common_data.fwd

	if var_0_2(var_1_4, var_1_3) > 0.7 then
		if not arg_1_0._modifier_on then
			arg_1_0._modifier_on = true

			arg_1_0._machine:force_modifier(arg_1_0._modifier_name)

			arg_1_0._mod_enable_t = arg_1_1 + 0.5
		end

		arg_1_0._modifier:set_target_y(var_1_1)
	else
		if arg_1_0._modifier_on then
			arg_1_0._modifier_on = nil

			arg_1_0._machine:allow_modifier(arg_1_0._modifier_name)
		end

		local var_1_5 = arg_1_0._common_data.active_actions[2]
		local var_1_6 = arg_1_0._common_data.queued_actions

		if (not var_1_5 or var_1_5:type() == "idle") and (not var_1_6 or not var_1_6[1] and not var_1_6[2]) then
			local var_1_7 = var_1_3:to_polar_with_reference(var_1_4, var_0_1).spin

			if var_0_0(var_1_7) > 25 then
				arg_1_0._ext_movement:action_request({
					body_part = 2,
					type = "turn",
					angle = var_1_7
				})
			end
		end

		var_1_1 = nil
	end

	if not arg_1_0._ext_anim.reload and not arg_1_0._ext_anim.equip and not arg_1_0._ext_anim.melee then
		if arg_1_0._discharging then
			local var_1_8 = arg_1_0._unit:raycast("ray", var_1_0, var_1_2, "slot_mask", arg_1_0._line_of_fire_slotmask, "sphere_cast_radius", arg_1_0._w_usage_tweak.tase_sphere_cast_radius, "ignore_unit", arg_1_0._tasing_local_unit, "report")

			if not arg_1_0._tasing_local_unit:movement():tased() or var_1_8 then
				if Network:is_server() then
					arg_1_0._expired = true
				else
					arg_1_0._tasing_local_unit:movement():on_tase_ended()
					arg_1_0._attention.unit:movement():on_targetted_for_attack(false, arg_1_0._unit)

					arg_1_0._discharging = nil
					arg_1_0._tasing_player = nil
					arg_1_0._tasing_local_unit = nil
					arg_1_0.update = arg_1_0._upd_empty
				end
			end
		elseif arg_1_0._shoot_t and var_1_1 and arg_1_0._common_data.allow_fire and arg_1_1 > arg_1_0._shoot_t and arg_1_1 > arg_1_0._mod_enable_t then
			if arg_1_0._tase_effect then
				World:effect_manager():fade_kill(arg_1_0._tase_effect)
			end

			arg_1_0._tase_effect = World:effect_manager():spawn({
				force_synch = true,
				effect = Idstring("effects/payday2/particles/character/taser_thread"),
				parent = arg_1_0._ext_inventory:equipped_unit():get_object(Idstring("fire"))
			})

			if arg_1_0._tasing_local_unit and var_0_4(var_1_0, var_1_2) < arg_1_0._w_usage_tweak.tase_distance then
				local var_1_9 = managers.groupai:state():criminal_record(arg_1_0._tasing_local_unit:key())

				if not var_1_9 or var_1_9.status or arg_1_0._tasing_local_unit:movement():chk_action_forbidden("hurt") or arg_1_0._tasing_local_unit:movement():zipline_unit() then
					if Network:is_server() then
						arg_1_0._expired = true
					end
				elseif not arg_1_0._unit:raycast("ray", var_1_0, var_1_2, "slot_mask", arg_1_0._line_of_fire_slotmask, "sphere_cast_radius", arg_1_0._w_usage_tweak.tase_sphere_cast_radius, "ignore_unit", arg_1_0._tasing_local_unit, "report") then
					arg_1_0._common_data.ext_network:send("action_tase_event", 3)
					arg_1_0._attention.unit:character_damage():damage_tase({
						attacker_unit = arg_1_0._unit
					})
					CopDamage._notify_listeners("on_criminal_tased", arg_1_0._unit, arg_1_0._attention.unit)

					arg_1_0._discharging = true

					if not arg_1_0._tasing_local_unit:base().is_local_player then
						arg_1_0._tasered_sound = arg_1_0._unit:sound():play("tasered_3rd", nil)
					end

					local var_1_10 = arg_1_0._ext_movement:play_redirect("recoil_auto")

					arg_1_0._shoot_t = nil
				end
			elseif not arg_1_0._tasing_local_unit then
				arg_1_0._tasered_sound = arg_1_0._unit:sound():play("tasered_3rd", nil)

				local var_1_11 = arg_1_0._ext_movement:play_redirect("recoil_auto")

				arg_1_0._shoot_t = nil
			end
		end
	end
end
