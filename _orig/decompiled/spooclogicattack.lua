function SpoocLogicAttack.action_complete_clbk(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_1:type()
	local var_1_1 = arg_1_0.internal_data

	if var_1_0 == "walk" then
		var_1_1.advancing = nil

		CopLogicAttack._cancel_cover_pathing(arg_1_0, var_1_1)
		CopLogicAttack._cancel_charge(arg_1_0, var_1_1)

		if var_1_1.surprised then
			var_1_1.surprised = false
		elseif var_1_1.moving_to_cover then
			if arg_1_1:expired() then
				var_1_1.in_cover = var_1_1.moving_to_cover

				CopLogicAttack._set_nearest_cover(var_1_1, var_1_1.in_cover)

				var_1_1.cover_enter_t = arg_1_0.t
				var_1_1.cover_sideways_chk = nil
			end

			var_1_1.moving_to_cover = nil
		elseif var_1_1.walking_to_cover_shoot_pos then
			var_1_1.walking_to_cover_shoot_pos = nil
		end

		if arg_1_1:expired() then
			SpoocLogicAttack._upd_aim(arg_1_0, var_1_1)
		end
	elseif var_1_0 == "shoot" then
		var_1_1.shooting = nil
	elseif var_1_0 == "act" or var_1_0 == "stand" or var_1_0 == "crouch" or var_1_0 == "reload" then
		if arg_1_1:expired() then
			SpoocLogicAttack._upd_aim(arg_1_0, var_1_1)
		end
	elseif var_1_0 == "turn" then
		var_1_1.turning = nil
	elseif var_1_0 == "hurt" or var_1_0 == "healed" then
		CopLogicAttack._cancel_cover_pathing(arg_1_0, var_1_1)

		if arg_1_1:expired() and not CopLogicBase.chk_start_action_dodge(arg_1_0, "hit") then
			SpoocLogicAttack._upd_aim(arg_1_0, var_1_1)
		end
	elseif var_1_0 == "spooc" then
		arg_1_0.spooc_attack_timeout_t = TimerManager:game():time() + math.lerp(arg_1_0.char_tweak.spooc_attack_timeout[1], arg_1_0.char_tweak.spooc_attack_timeout[2], math.random())

		if arg_1_1:complete() and arg_1_0.char_tweak.spooc_attack_use_smoke_chance > 0 and math.random() <= arg_1_0.char_tweak.spooc_attack_use_smoke_chance and not managers.groupai:state():is_smoke_grenade_active() then
			managers.groupai:state():detonate_smoke_grenade(arg_1_0.m_pos + math.UP * 10, arg_1_0.unit:movement():m_head_pos(), math.lerp(15, 30, math.random()), false)
		end

		var_1_1.spooc_attack = nil

		if arg_1_1:complete() then
			SpoocLogicAttack._upd_aim(arg_1_0, var_1_1)
		end
	elseif var_1_0 == "dodge" then
		local var_1_2 = arg_1_1:timeout()

		if var_1_2 then
			arg_1_0.dodge_timeout_t = TimerManager:game():time() + math.lerp(var_1_2[1], var_1_2[2], math.random())
		end

		CopLogicAttack._cancel_cover_pathing(arg_1_0, var_1_1)

		if arg_1_1:expired() then
			SpoocLogicAttack._upd_aim(arg_1_0, var_1_1)
		end
	end
end

function SpoocLogicAttack._chk_request_action_spooc_attack(arg_2_0, arg_2_1, arg_2_2)
	CopLogicAttack._cancel_cover_pathing(arg_2_0, arg_2_1)
	CopLogicAttack._cancel_charge(arg_2_0, arg_2_1)

	if arg_2_0.unit:anim_data().crouch then
		CopLogicAttack._chk_request_action_stand(arg_2_0)
	end

	local var_2_0 = {
		body_part = 3,
		type = "idle"
	}

	arg_2_0.unit:brain():action_request(var_2_0)

	local var_2_1 = {
		body_part = 1,
		type = "spooc",
		flying_strike = arg_2_2
	}

	if arg_2_2 then
		var_2_1.blocks = {
			heavy_hurt = -1,
			fire_hurt = -1,
			idle = -1,
			turn = -1,
			light_hurt = -1,
			walk = -1,
			act = -1,
			hurt = -1,
			expl_hurt = -1,
			taser_tased = -1
		}
	end

	return (arg_2_0.unit:brain():action_request(var_2_1))
end
