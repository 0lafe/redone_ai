local var_0_0 = mvector3.copy
local var_0_1 = mvector3.distance
local var_0_2 = mvector3.distance_sq
local var_0_3 = mvector3.equal
local var_0_4 = mvector3.set

function CopLogicIdle._chk_relocate(arg_1_0)
	if arg_1_0.objective and arg_1_0.objective.type == "follow" then
		if arg_1_0.is_converted then
			if TeamAILogicIdle._check_should_relocate(arg_1_0, arg_1_0.internal_data, arg_1_0.objective) then
				arg_1_0.objective.in_place = nil

				arg_1_0.logic._exit(arg_1_0.unit, "travel")

				return true
			end

			return
		end

		if arg_1_0.is_tied and arg_1_0.objective.lose_track_dis and arg_1_0.objective.lose_track_dis * arg_1_0.objective.lose_track_dis < var_0_2(arg_1_0.m_pos, arg_1_0.objective.follow_unit:movement():m_pos()) then
			arg_1_0.brain:set_objective(nil)

			return true
		end

		local var_1_0
		local var_1_1 = arg_1_0.objective.follow_unit
		local var_1_2 = var_1_1:brain() and var_1_1:brain():is_advancing() or var_1_1:movement():m_pos()

		if arg_1_0.objective.relocated_to and var_0_3(arg_1_0.objective.relocated_to, var_1_2) then
			return
		end

		if arg_1_0.objective.distance and arg_1_0.objective.distance < var_0_1(arg_1_0.m_pos, var_1_2) then
			var_1_0 = true
		end

		if not var_1_0 then
			local var_1_3 = {
				tracker_from = arg_1_0.unit:movement():nav_tracker(),
				pos_to = var_1_2
			}

			if managers.navigation:raycast(var_1_3) then
				var_1_0 = true
			end
		end

		if var_1_0 then
			arg_1_0.objective.in_place = nil
			arg_1_0.objective.nav_seg = var_1_1:movement():nav_tracker():nav_segment()
			arg_1_0.objective.relocated_to = var_0_0(var_1_2)

			arg_1_0.logic._exit(arg_1_0.unit, "travel")

			return true
		end
	end
end

function CopLogicIdle._chk_exit_non_walkable_area(arg_2_0)
	local var_2_0 = arg_2_0.internal_data

	if var_2_0.advancing or var_2_0.old_action_advancing or not CopLogicAttack._can_move(arg_2_0) or arg_2_0.unit:movement():chk_action_forbidden("walk") then
		return
	end

	local var_2_1 = arg_2_0.unit:movement():nav_tracker()

	if not var_2_1:obstructed() then
		return
	end

	if arg_2_0.objective and arg_2_0.objective.nav_seg then
		local var_2_2 = var_2_1:nav_segment()

		if not managers.navigation._nav_segments[var_2_2].disabled then
			arg_2_0.objective.in_place = nil

			arg_2_0.logic.on_new_objective(arg_2_0)

			return true
		end
	end
end
