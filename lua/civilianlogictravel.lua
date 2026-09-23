local mvec3_copy = mvector3.copy

-- Runs update travel logic on same frame as other logic
Hooks:PostHook(CivilianLogicTravel, "enter", "RDAI_enter", function(data)
	CivilianLogicTravel.update(data)
end)

-- Cleanup on deletion
Hooks:PostHook(CivilianLogicTravel, "exit", "RDAI_exit", function(data)
	data.brain:rem_pos_rsrv("path")
end)

-- Overwrite to vanilla update implementing slightly improved mechanics for civs
function CivilianLogicTravel.update(data)
	local my_data = data.internal_data
	local unit = data.unit
	local objective = data.objective

	if my_data.has_old_action then
		CivilianLogicTravel._upd_stop_old_action(data, my_data)
	elseif my_data.warp_pos then
		local new_action_data = {
			body_part = 1,
			type = "warp",
			position = mvec3_copy(objective.pos),
			rotation = objective.rot
		}

		if unit:movement():action_request(new_action_data) then
			CivilianLogicTravel._on_destination_reached(data)
		end
	elseif not my_data.advancing then
		if my_data.processing_advance_path or my_data.processing_coarse_path then
			CivilianLogicEscort._upd_pathing(data, my_data)

			if my_data ~= data.internal_data then
				return
			end
		end

		if not my_data.processing_advance_path and not my_data.processing_coarse_path then
			if my_data.advance_path then
				CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)

				if my_data.is_hostage then
					my_data.advance_path = CivilianLogicTravel._optimize_path(my_data.advance_path)
				end

				local new_action_data = {
					type = "walk",
					body_part = 2,
					nav_path = my_data.advance_path,
					variant = objective and objective.haste or "walk",
					end_rot = my_data.coarse_path_index == #my_data.coarse_path - 1 and objective and objective.rot
				}

				my_data.advance_path = nil
				my_data.starting_advance_action = true
				my_data.advancing = unit:brain():action_request(new_action_data)
				my_data.starting_advance_action = false

				if my_data.advancing then
					data.brain:rem_pos_rsrv("path")
				end
			elseif objective then
				if my_data.coarse_path then
					local cur_index = my_data.coarse_path_index
					local total_nav_points = #my_data.coarse_path

					if total_nav_points <= cur_index then
						objective.in_place = true

						if objective.type ~= "escort" and objective.type ~= "act" and objective.type ~= "follow" and not objective.action_duration then
							data.objective_complete_clbk(unit, objective)
						else
							CivilianLogicTravel.on_new_objective(data)
						end
					else
						local next_pos = cur_index == total_nav_points - 1 and CivilianLogicTravel._determine_exact_destination(data, objective) or my_data.coarse_path[cur_index + 1][2]

						if next_pos then
							data.brain:add_pos_rsrv("path", {
								radius = 60,
								position = mvec3_copy(next_pos)
							})

							my_data.processing_advance_path = true

							unit:brain():search_for_path(my_data.advance_path_search_id, next_pos)
						end
					end
				else
					my_data.processing_coarse_path = true

					unit:brain():search_for_coarse_path(my_data.coarse_path_search_id, objective.follow_unit and objective.follow_unit:movement():nav_tracker():nav_segment() or objective.nav_seg)
				end
			else
				CopLogicBase._exit(unit, "idle")
			end
		end
	end
end

-- Implements for later to run pathing logic on same frame as pathing creation
CivilianLogicTravel.clbk_pathing_results = CivilianLogicTravel.update