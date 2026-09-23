local var_0_0 = math.abs
local var_0_1 = mvector3.copy
local var_0_2 = table.remove

Hooks:PostHook(CivilianLogicTravel, "enter", "REAI_enter", function(arg_1_0)
	CivilianLogicTravel.update(arg_1_0)
end)
Hooks:PostHook(CivilianLogicTravel, "exit", "REAI_exit", function(arg_2_0)
	arg_2_0.brain:rem_pos_rsrv("path")
end)

function CivilianLogicTravel._optimize_path(arg_3_0)
	if #arg_3_0 <= 2 then
		return arg_3_0
	end

	local function var_3_0(arg_4_0)
		for iter_4_0 = #arg_4_0, 2, -1 do
			if arg_4_0[iter_4_0] == arg_4_0[iter_4_0 - 1] then
				var_0_2(arg_4_0, iter_4_0)
			end
		end
	end

	var_3_0(arg_3_0)

	local var_3_1 = {
		arg_3_0[1]
	}
	local var_3_2 = 1
	local var_3_3 = 1

	while var_3_2 < #arg_3_0 do
		local var_3_4 = arg_3_0[var_3_2]

		var_3_2 = var_3_2 + 1

		for iter_3_0 = #arg_3_0, var_3_2 + 1, -1 do
			local var_3_5 = arg_3_0[iter_3_0]

			if not managers.navigation:raycast({
				pos_from = var_3_4,
				pos_to = var_3_5
			}) then
				var_3_2 = iter_3_0

				break
			end
		end

		var_3_3 = var_3_3 + 1
		var_3_1[var_3_3] = arg_3_0[var_3_2]
	end

	var_3_0(var_3_1)

	return var_3_1
end

function CivilianLogicTravel.update(arg_5_0)
	local var_5_0 = arg_5_0.internal_data
	local var_5_1 = arg_5_0.unit
	local var_5_2 = arg_5_0.objective

	if var_5_0.has_old_action then
		CivilianLogicTravel._upd_stop_old_action(arg_5_0, var_5_0)
	elseif var_5_0.warp_pos then
		local var_5_3 = {
			body_part = 1,
			type = "warp",
			position = var_0_1(var_5_2.pos),
			rotation = var_5_2.rot
		}

		if var_5_1:movement():action_request(var_5_3) then
			CivilianLogicTravel._on_destination_reached(arg_5_0)
		end
	elseif not var_5_0.advancing then
		if var_5_0.processing_advance_path or var_5_0.processing_coarse_path then
			CivilianLogicEscort._upd_pathing(arg_5_0, var_5_0)

			if var_5_0 ~= arg_5_0.internal_data then
				return
			end
		end

		if not var_5_0.processing_advance_path and not var_5_0.processing_coarse_path then
			if var_5_0.advance_path then
				CopLogicAttack._correct_path_start_pos(arg_5_0, var_5_0.advance_path)

				if var_5_0.is_hostage then
					var_5_0.advance_path = CivilianLogicTravel._optimize_path(var_5_0.advance_path)
				end

				local var_5_4 = {
					type = "walk",
					body_part = 2,
					nav_path = var_5_0.advance_path,
					variant = var_5_2 and var_5_2.haste or "walk",
					end_rot = var_5_0.coarse_path_index == #var_5_0.coarse_path - 1 and var_5_2 and var_5_2.rot
				}

				var_5_0.advance_path = nil
				var_5_0.starting_advance_action = true
				var_5_0.advancing = var_5_1:brain():action_request(var_5_4)
				var_5_0.starting_advance_action = false

				if var_5_0.advancing then
					arg_5_0.brain:rem_pos_rsrv("path")
				end
			elseif var_5_2 then
				if var_5_0.coarse_path then
					local var_5_5 = var_5_0.coarse_path_index
					local var_5_6 = #var_5_0.coarse_path

					if var_5_6 <= var_5_5 then
						var_5_2.in_place = true

						if var_5_2.type ~= "escort" and var_5_2.type ~= "act" and var_5_2.type ~= "follow" and not var_5_2.action_duration then
							arg_5_0.objective_complete_clbk(var_5_1, var_5_2)
						else
							CivilianLogicTravel.on_new_objective(arg_5_0)
						end
					else
						local var_5_7 = var_5_5 == var_5_6 - 1 and CivilianLogicTravel._determine_exact_destination(arg_5_0, var_5_2) or var_5_0.coarse_path[var_5_5 + 1][2]

						arg_5_0.brain:add_pos_rsrv("path", {
							radius = 60,
							position = var_0_1(var_5_7)
						})

						var_5_0.processing_advance_path = true

						var_5_1:brain():search_for_path(var_5_0.advance_path_search_id, var_5_7)
					end
				else
					var_5_0.processing_coarse_path = true

					var_5_1:brain():search_for_coarse_path(var_5_0.coarse_path_search_id, var_5_2.follow_unit and var_5_2.follow_unit:movement():nav_tracker():nav_segment() or var_5_2.nav_seg)
				end
			else
				CopLogicBase._exit(var_5_1, "idle")
			end
		end
	end
end

function CivilianLogicTravel._determine_exact_destination(arg_6_0, arg_6_1)
	if arg_6_1.pos then
		return arg_6_1.pos
	elseif arg_6_1.type == "follow" then
		return arg_6_1.follow_unit:movement():nav_tracker():field_position()
	else
		return CopLogicTravel._get_pos_on_wall(managers.navigation:find_random_position_in_segment(arg_6_1.nav_seg), 700)
	end
end

CivilianLogicTravel.clbk_pathing_results = CivilianLogicTravel.update
