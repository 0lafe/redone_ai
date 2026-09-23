-- Give cloakers ability to dodge when being shot
function SpoocLogicAttack.action_complete_clbk(data, action)
	local action_type = action:type()
	local my_data = data.internal_data

	if action_type == "walk" then
		my_data.advancing = nil

		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)

		if my_data.surprised then
			my_data.surprised = false
		elseif my_data.moving_to_cover then
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
			SpoocLogicAttack._upd_aim(data, my_data)
		end
	elseif action_type == "shoot" then
		my_data.shooting = nil
	elseif action_type == "act" or action_type == "stand" or action_type == "crouch" or action_type == "reload" then
		if action:expired() then
			SpoocLogicAttack._upd_aim(data, my_data)
		end
	elseif action_type == "turn" then
		my_data.turning = nil
	elseif action_type == "hurt" or action_type == "healed" then
		CopLogicAttack._cancel_cover_pathing(data, my_data)

		if action:expired() and not CopLogicBase.chk_start_action_dodge(data, "hit") then
			SpoocLogicAttack._upd_aim(data, my_data)
		end
	elseif action_type == "spooc" then
		data.spooc_attack_timeout_t = TimerManager:game():time() + math.lerp(data.char_tweak.spooc_attack_timeout[1], data.char_tweak.spooc_attack_timeout[2], math.random())

		if action:complete() and data.char_tweak.spooc_attack_use_smoke_chance > 0 and math.random() <= data.char_tweak.spooc_attack_use_smoke_chance and not managers.groupai:state():is_smoke_grenade_active() then
			managers.groupai:state():detonate_smoke_grenade(data.m_pos + math.UP * 10, nil, math.lerp(15, 30, math.random()), false, false)
		end

		my_data.spooc_attack = nil

		if action:complete() then
			SpoocLogicAttack._upd_aim(data, my_data)
		end
	elseif action_type == "dodge" then
		local timeout = action:timeout()

		if timeout then
			data.dodge_timeout_t = TimerManager:game():time() + math.lerp(timeout[1], timeout[2], math.random())
		end

		CopLogicAttack._cancel_cover_pathing(data, my_data)

		if action:expired() then
			SpoocLogicAttack._upd_aim(data, my_data)
		end
	end
end

function SpoocLogicAttack._chk_request_action_spooc_attack(data, my_data, flying_strike)
	CopLogicAttack._cancel_cover_pathing(data, my_data)
	CopLogicAttack._cancel_charge(data, my_data)

	if data.unit:anim_data().crouch then
		CopLogicAttack._chk_request_action_stand(data)
	end

	local idle_action = {
		body_part = 3,
		type = "idle"
	}

	data.unit:brain():action_request(idle_action)

	local spooc_action = {
		body_part = 1,
		type = "spooc",
		flying_strike = flying_strike
	}

	if flying_strike then
		spooc_action.blocks = {
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

	return (data.unit:brain():action_request(spooc_action))
end
