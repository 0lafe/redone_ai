local var_0_0 = math.lerp
local var_0_1 = math.min
local var_0_2 = math.random
local var_0_3 = mvector3.copy
local var_0_4 = mvector3.distance
local var_0_5 = mvector3.distance_sq
local var_0_6 = next
local var_0_7 = ipairs
local var_0_8 = pairs
local var_0_9 = table.insert
local var_0_10 = table.remove
local var_0_11 = type

function GroupAIStateBesiege._queue_police_upd_task(arg_1_0)
	if not arg_1_0._police_upd_task_queued then
		arg_1_0._police_upd_task_queued = true

		managers.enemy:queue_task("GroupAIStateBesiege._upd_police_activity", arg_1_0._upd_police_activity, arg_1_0, arg_1_0._t + 0.5)
	end
end

GroupAIStateBesiege.on_enemy_unregistered = nil

function GroupAIStateBesiege._upd_police_activity(arg_2_0)
	arg_2_0._police_upd_task_queued = false

	if not arg_2_0._police_activity_blocked then
		if arg_2_0._ai_enabled then
			arg_2_0:_upd_SO()
			arg_2_0:_upd_grp_SO()

			if arg_2_0._enemy_weapons_hot then
				arg_2_0:_claculate_drama_value()
				arg_2_0:_upd_group_spawning()
				arg_2_0:_begin_new_tasks()
				arg_2_0:_upd_regroup_task()
				arg_2_0:_upd_reenforce_tasks()
				arg_2_0:_upd_recon_tasks()
				arg_2_0:_upd_assault_task()
				arg_2_0:_check_spawn_phalanx()
				arg_2_0:_check_phalanx_group_has_spawned()
				arg_2_0:_check_phalanx_damage_reduction_increase()
				arg_2_0:_upd_groups()
			end
		end

		arg_2_0:_queue_police_upd_task()
	end
end

local var_0_12 = GroupAIStateBesiege._upd_assault_task

function GroupAIStateBesiege._upd_assault_task(arg_3_0, ...)
	local var_3_0 = arg_3_0._task_data.assault

	if not var_3_0.active then
		return
	end

	if var_3_0.phase ~= "fade" or arg_3_0._hunt_mode then
		return var_0_12(arg_3_0, ...)
	end

	local var_3_1 = arg_3_0._t

	arg_3_0:_assign_recon_groups_to_retire()

	local var_3_2 = false

	if REAI.settings.old_fades and not managers.skirmish:is_skirmish() then
		if arg_3_0:_count_police_force("assault") < 7 or var_3_1 > var_3_0.phase_end_t + 350 then
			if var_3_1 > var_3_0.phase_end_t - 8 and not var_3_0.said_retreat then
				if arg_3_0._drama_data.amount < tweak_data.drama.assault_fade_end then
					var_3_0.said_retreat = true

					arg_3_0:_police_announce_retreat()
				end
			elseif var_3_1 > var_3_0.phase_end_t and arg_3_0._drama_data.amount < tweak_data.drama.assault_fade_end and arg_3_0:_count_criminals_engaged_force(4) <= 3 then
				var_3_2 = true
			end
		end
	elseif arg_3_0:_count_police_force("assault") < 50 or var_3_1 > var_3_0.phase_end_t + (managers.skirmish:is_skirmish() and 0 or 30) then
		if not var_3_0.said_retreat then
			var_3_0.said_retreat = true

			arg_3_0:_police_announce_retreat()
		elseif var_3_1 > var_3_0.phase_end_t and (arg_3_0._drama_data.amount < tweak_data.drama.assault_fade_end and arg_3_0:_count_criminals_engaged_force(11) <= 10 or var_3_1 > var_3_0.phase_end_t + (managers.skirmish:is_skirmish() and 0 or 60)) then
			var_3_2 = true
		end
	end

	if var_3_0.force_end or var_3_2 then
		var_3_0.active = nil
		var_3_0.phase = nil
		var_3_0.said_retreat = nil
		var_3_0.force_end = nil

		local var_3_3 = var_3_0.force_regroup

		var_3_0.force_regroup = nil

		if arg_3_0._draw_drama then
			arg_3_0._draw_drama.assault_hist[#arg_3_0._draw_drama.assault_hist][2] = var_3_1
		end

		managers.mission:call_global_event("end_assault")
		arg_3_0:_begin_regroup_task(var_3_3)

		return
	end

	if arg_3_0._drama_data.amount <= tweak_data.drama.low then
		for iter_3_0, iter_3_1 in pairs(arg_3_0._player_criminals) do
			arg_3_0:criminal_spotted(iter_3_1.unit)

			for iter_3_2, iter_3_3 in pairs(arg_3_0._groups) do
				if iter_3_3.objective.charge then
					for iter_3_4, iter_3_5 in pairs(iter_3_3.units) do
						iter_3_5.unit:brain():clbk_group_member_attention_identified(nil, iter_3_0)
					end
				end
			end
		end
	end

	local var_3_4 = var_3_0.target_areas[1]

	if arg_3_0:is_area_safe_assault(var_3_4) then
		local var_3_5 = var_3_4.pos
		local var_3_6
		local var_3_7

		for iter_3_6, iter_3_7 in var_0_8(arg_3_0._player_criminals) do
			if not iter_3_7.status then
				local var_3_8 = var_0_5(var_3_5, iter_3_7.m_pos)

				if not var_3_7 or var_3_8 < var_3_7 then
					var_3_7 = var_3_8
					var_3_6 = arg_3_0:get_area_from_nav_seg_id(iter_3_7.tracker:nav_segment())
				end
			end
		end

		if var_3_6 then
			local var_3_9 = var_3_6

			var_3_0.target_areas[1] = var_3_6
		end
	end

	if var_3_1 > var_3_0.use_smoke_timer then
		var_3_0.use_smoke = true
	end

	arg_3_0:detonate_queued_smoke_grenades()
	arg_3_0:_assign_enemy_groups_to_assault(var_3_0.phase)
end

function GroupAIStateBesiege._begin_reenforce_task(arg_4_0, arg_4_1)
	local var_4_0 = {
		use_spawn_event = true,
		target_area = arg_4_1,
		start_t = arg_4_0._t
	}

	var_0_9(arg_4_0._task_data.reenforce.tasks, var_4_0)

	arg_4_0._task_data.reenforce.active = true
end

function GroupAIStateBesiege._find_spawn_group_near_area(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	arg_5_3 = arg_5_3 or arg_5_1.pos

	local var_5_0 = arg_5_0._t
	local var_5_1 = {}
	local var_5_2 = {}

	for iter_5_0, iter_5_1 in var_0_8(arg_5_0._area_data) do
		local var_5_3 = iter_5_1.spawn_groups

		if var_5_3 then
			for iter_5_2 = 1, #var_5_3 do
				local var_5_4 = var_5_3[iter_5_2]

				if var_5_0 >= var_5_4.delay_t and (not arg_5_5 or arg_5_5(var_5_4)) then
					local var_5_5 = var_5_4.nav_seg .. "-" .. arg_5_1.pos_nav_seg
					local var_5_6 = arg_5_0._graph_distance_cache[var_5_5]

					if not var_5_6 then
						local var_5_7 = managers.navigation:search_coarse({
							access_pos = "swat",
							from_seg = var_5_4.nav_seg,
							to_seg = arg_5_1.pos_nav_seg,
							id = var_5_5
						})

						if var_5_7 and #var_5_7 >= 2 then
							local var_5_8 = 0
							local var_5_9 = var_5_4.pos

							for iter_5_3 = 2, #var_5_7 do
								local var_5_10 = var_5_7[iter_5_3][2]

								if var_5_9 and var_5_10 then
									var_5_8 = var_5_8 + var_0_4(var_5_9, var_5_10)
								end

								var_5_9 = var_5_10
							end

							var_5_6 = var_5_8
							arg_5_0._graph_distance_cache[var_5_5] = var_5_8
						end
					end

					if var_5_6 and (not arg_5_4 or var_5_6 < arg_5_4) then
						local var_5_11 = var_5_4.mission_element:id()

						var_5_1[var_5_11] = var_5_4
						var_5_2[var_5_11] = var_5_6
					end
				end
			end
		end
	end

	if not var_0_6(var_5_1) then
		return
	end

	local var_5_12 = 0
	local var_5_13 = {}

	for iter_5_4, iter_5_5 in var_0_8(var_5_2) do
		local var_5_14 = var_5_1[iter_5_4]

		var_5_14.distance = iter_5_5
		var_5_12 = var_5_12 + arg_5_0:_choose_best_groups(var_5_13, var_5_14, var_5_14.mission_element:spawn_groups(), arg_5_2, var_0_0(1, 0.2, var_0_1(1, iter_5_5 / 5000)) * 5)
	end

	if var_5_12 == 0 then
		return
	end

	return arg_5_0:_choose_best_group(var_5_13, var_5_12)
end

local var_0_13 = GroupAIStateBesiege._upd_group_spawning

function GroupAIStateBesiege._upd_group_spawning(arg_6_0, ...)
	if arg_6_0._t > (arg_6_0._next_spawn_t or 0) then
		var_0_13(arg_6_0, ...)

		arg_6_0._next_spawn_t = arg_6_0._t + (next(arg_6_0._spawning_groups) and 0.5 or REAI.settings.enemy_spawn_interval)
	end
end

Hooks:OverrideFunction(GroupAIStateBesiege, "_perform_group_spawning", function(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = 0
	local var_7_1 = {
		name = true,
		spawn_ai = {}
	}
	local var_7_2 = tweak_data.group_ai.unit_categories
	local var_7_3 = arg_7_1.spawn_group.spawn_pts

	local function var_7_4(arg_8_0, arg_8_1)
		if not REAI.settings.masochism and GroupAIStateBesiege._MAX_SIMULTANEOUS_SPAWNS <= var_7_0 and not arg_7_2 then
			return
		end

		local var_8_0 = true
		local var_8_1 = tweak_data.levels:get_ai_group_type()

		for iter_8_0 = 1, #var_7_3 do
			local var_8_2 = var_7_3[iter_8_0]
			local var_8_3 = var_7_2[arg_8_0]

			if (var_8_2.accessibility == "any" or var_8_3.access[var_8_2.accessibility]) and (not var_8_2.amount or var_8_2.amount > 0) and var_8_2.mission_element:enabled() then
				var_8_0 = false

				if var_8_2.delay_t < arg_7_0._t then
					local var_8_4 = var_8_3.unit_types[var_8_1]

					var_7_1.name = managers.modifiers:modify_value("GroupAIStateBesiege:SpawningUnit", var_8_4[var_0_2(#var_8_4)])

					local var_8_5 = var_8_2.mission_element:produce(var_7_1)
					local var_8_6 = var_8_5:key()
					local var_8_7

					if arg_7_1.objective then
						var_8_7 = arg_7_0.clone_objective(arg_7_1.objective)
					else
						var_8_7 = arg_7_1.group.objective.element:get_random_SO(var_8_5)

						if not var_8_7 then
							var_8_5:set_slot(0)

							return true
						end

						var_8_7.grp_objective = arg_7_1.group.objective
					end

					local var_8_8 = arg_7_0._police[var_8_6]

					arg_7_0:set_enemy_assigned(var_8_7.area, var_8_6)

					if arg_8_1.tactics then
						var_8_8.tactics = arg_8_1.tactics
						var_8_8.tactics_map = {}

						for iter_8_1, iter_8_2 in var_0_7(var_8_8.tactics) do
							var_8_8.tactics_map[iter_8_2] = true
						end
					end

					var_8_5:brain():set_spawn_entry(arg_8_1, var_8_8.tactics_map)

					var_8_8.rank = arg_8_1.rank

					arg_7_0:_add_group_member(arg_7_1.group, var_8_6)

					if var_8_5:brain():is_available_for_assignment(var_8_7) then
						if var_8_7.element then
							var_8_7.element:clbk_objective_administered(var_8_5)
						end

						var_8_5:brain():set_objective(var_8_7)
					else
						var_8_5:brain():set_followup_objective(var_8_7)
					end

					var_7_0 = var_7_0 + 1

					if arg_7_1.ai_task then
						arg_7_1.ai_task.force_spawned = arg_7_1.ai_task.force_spawned + 1
						var_8_5:brain()._logic_data.spawned_in_phase = arg_7_1.ai_task.phase
					end

					var_8_2.delay_t = arg_7_0._t + var_8_2.interval

					if var_8_2.amount then
						var_8_2.amount = var_8_2.amount - 1
					end

					return true
				end
			end
		end

		if var_8_0 then
			return true
		end
	end

	local var_7_5 = true

	for iter_7_0, iter_7_1 in var_0_8(arg_7_1.units_remaining) do
		if not var_7_2[iter_7_0].access.acrobatic then
			for iter_7_2 = iter_7_1.amount, 1, -1 do
				if var_7_4(iter_7_0, iter_7_1.spawn_entry) then
					iter_7_1.amount = iter_7_1.amount - 1
				else
					var_7_5 = false

					break
				end
			end
		end
	end

	for iter_7_3, iter_7_4 in var_0_8(arg_7_1.units_remaining) do
		for iter_7_5 = iter_7_4.amount, 1, -1 do
			if var_7_4(iter_7_3, iter_7_4.spawn_entry) then
				iter_7_4.amount = iter_7_4.amount - 1
			else
				var_7_5 = false

				break
			end
		end
	end

	if var_7_5 then
		arg_7_1.group.has_spawned = true

		var_0_10(arg_7_0._spawning_groups, arg_7_3 and #arg_7_0._spawning_groups or 1)

		if arg_7_1.group.size <= 0 then
			arg_7_0._groups[arg_7_1.group.id] = nil
		end
	end
end)

function GroupAIStateBesiege._assign_enemy_groups_to_assault(arg_9_0, arg_9_1)
	for iter_9_0, iter_9_1 in var_0_8(arg_9_0._groups) do
		if iter_9_1.has_spawned and iter_9_1.objective.type == "assault_area" then
			if iter_9_1.objective.moving_out then
				local var_9_0 = false

				for iter_9_2, iter_9_3 in var_0_8(iter_9_1.units) do
					local var_9_1 = iter_9_3.unit:brain():objective()

					if var_9_1 and var_9_1.grp_objective == iter_9_1.objective then
						if var_9_1.in_place or var_9_1.area.nav_segs[iter_9_3.unit:movement():nav_tracker():nav_segment()] then
							var_9_0 = true
						else
							var_9_0 = false

							break
						end
					end
				end

				if var_9_0 then
					iter_9_1.objective.moving_out = nil
					iter_9_1.in_place_t = arg_9_0._t
					iter_9_1.objective.moving_in = nil

					arg_9_0:_voice_move_complete(iter_9_1)
				end
			end

			arg_9_0:_set_assault_objective_to_group(iter_9_1, arg_9_1)
		end
	end
end

function GroupAIStateBesiege._set_assault_objective_to_group(arg_10_0, arg_10_1, arg_10_2)
	if not arg_10_1.has_spawned then
		return
	end

	local var_10_0 = arg_10_2 == "anticipation"
	local var_10_1 = arg_10_1.objective
	local var_10_2
	local var_10_3
	local var_10_4
	local var_10_5
	local var_10_6
	local var_10_7 = arg_10_0:_chk_group_areas_tresspassed(arg_10_1)
	local var_10_8, var_10_9 = arg_10_0._determine_group_leader(arg_10_1.units)
	local var_10_10 = {}

	if var_10_9 and var_10_9.tactics then
		for iter_10_0, iter_10_1 in ipairs(var_10_9.tactics) do
			var_10_10[iter_10_1] = true
		end

		if var_10_1.tactic and not var_10_10[var_10_1.tactic] then
			var_10_1.tactic = nil
		end

		for iter_10_2, iter_10_3 in ipairs(var_10_9.tactics) do
			if iter_10_3 == "deathguard" and not var_10_0 then
				if var_10_1.tactic == iter_10_3 then
					for iter_10_4, iter_10_5 in pairs(arg_10_0._char_criminals) do
						if iter_10_5.status and var_10_1.follow_unit == iter_10_5.unit then
							local var_10_11 = iter_10_5.tracker:nav_segment()

							if var_10_1.area.nav_segs[var_10_11] then
								return
							end
						end
					end
				end

				local var_10_12
				local var_10_13

				for iter_10_6, iter_10_7 in pairs(arg_10_0._char_criminals) do
					if iter_10_7.status then
						local var_10_14, var_10_15, var_10_16 = arg_10_0._get_closest_group_unit_to_pos(iter_10_7.m_pos, arg_10_1.units)

						if var_10_16 and (not var_10_13 or var_10_16 < var_10_13) then
							var_10_12 = iter_10_7
							var_10_13 = var_10_16
						end
					end
				end

				if var_10_12 then
					local var_10_17 = {
						id = "GroupAI_deathguard",
						from_tracker = var_10_9.unit:movement():nav_tracker(),
						to_tracker = var_10_12.tracker,
						access_pos = arg_10_0._get_group_acces_mask(arg_10_1)
					}
					local var_10_18 = managers.navigation:search_coarse(var_10_17)

					if var_10_18 then
						local var_10_19 = {
							moving_in = true,
							attitude = "engage",
							distance = 800,
							type = "assault_area",
							tactic = "deathguard",
							follow_unit = var_10_12.unit,
							area = arg_10_0:get_area_from_nav_seg_id(var_10_18[#var_10_18][1]),
							coarse_path = var_10_18
						}

						arg_10_1.is_chasing = true

						arg_10_0:_set_objective_to_enemy_group(arg_10_1, var_10_19)
						arg_10_0:_voice_deathguard_start(arg_10_1)

						return
					end
				end
			elseif iter_10_3 == "charge" and not var_10_1.moving_out and arg_10_1.in_place_t and (arg_10_0._t - arg_10_1.in_place_t > 15 or arg_10_0._t - arg_10_1.in_place_t > 4 and arg_10_0._drama_data.amount <= tweak_data.drama.low) and next(var_10_1.area.criminal.units) and arg_10_1.is_chasing and not var_10_1.charge then
				var_10_6 = true
			end
		end
	end

	local var_10_20 = var_10_1.area

	if var_10_7 then
		if var_10_0 then
			var_10_5 = true
		elseif var_10_1.moving_out then
			if not var_10_1.open_fire then
				var_10_3 = true
				var_10_20 = var_10_7
			end
		elseif not var_10_1.pushed or var_10_6 and not var_10_1.charge then
			var_10_4 = true
		end
	elseif not var_10_1.moving_out then
		local var_10_21

		for iter_10_8, iter_10_9 in pairs(var_10_1.area.neighbours) do
			if next(iter_10_9.criminal.units) then
				var_10_21 = true

				break
			end
		end

		if var_10_6 then
			var_10_4 = true
		elseif not var_10_21 or not arg_10_1.in_place_t then
			var_10_2 = true
		elseif not var_10_0 then
			if not var_10_1.open_fire then
				var_10_3 = true
			elseif arg_10_1.is_chasing or not var_10_10.ranged_fire or arg_10_0._t - arg_10_1.in_place_t > 15 then
				var_10_4 = true
			end
		elseif var_10_1.open_fire then
			var_10_5 = true
		end
	elseif not var_10_1.open_fire then
		local var_10_22 = arg_10_0:_chk_coarse_path_obstructed(arg_10_1)

		if var_10_22 then
			var_10_20 = arg_10_0:get_area_from_nav_seg_id(var_10_1.coarse_path[math.max(var_10_22 - 1, 1)][1])
			var_10_3 = true
		end
	end

	if var_10_3 then
		local var_10_23 = {
			attitude = "engage",
			pose = "stand",
			type = "assault_area",
			stance = "hos",
			open_fire = true,
			tactic = var_10_1.tactic,
			area = var_10_20,
			coarse_path = {
				{
					var_10_20.pos_nav_seg,
					mvector3.copy(var_10_20.pos)
				}
			}
		}

		arg_10_0:_set_objective_to_enemy_group(arg_10_1, var_10_23)
		arg_10_0:_voice_open_fire_start(arg_10_1)
	elseif var_10_2 or var_10_4 then
		local var_10_24
		local var_10_25
		local var_10_26
		local var_10_27
		local var_10_28
		local var_10_29 = {
			var_10_20
		}
		local var_10_30 = {
			[var_10_20] = var_10_20
		}

		repeat
			local var_10_31 = table.remove(var_10_29, 1)

			if next(var_10_31.criminal.units) then
				local var_10_32 = true

				if not var_10_4 and var_10_10.flank then
					local var_10_33 = var_10_30[var_10_31]

					if var_10_33 ~= var_10_20 then
						var_10_32 = false

						if not var_10_25 or var_0_2() < 0.5 then
							local var_10_34 = managers.navigation:search_coarse({
								id = "GroupAI_assault",
								from_seg = var_10_1.area.pos_nav_seg,
								to_seg = var_10_33.pos_nav_seg,
								access_pos = arg_10_0._get_group_acces_mask(arg_10_1),
								verify_clbk = callback(arg_10_0, arg_10_0, "is_nav_seg_safe")
							})

							if var_10_34 then
								arg_10_0:_merge_coarse_path_by_area(var_10_34)

								var_10_28 = var_10_34
								var_10_25 = var_10_31
								var_10_26 = var_10_33
							end
						end

						var_10_30[var_10_31] = nil
					end
				end

				if var_10_32 then
					var_10_27 = managers.navigation:search_coarse({
						id = "GroupAI_assault",
						from_seg = var_10_1.area.pos_nav_seg,
						to_seg = var_10_31.pos_nav_seg,
						access_pos = arg_10_0._get_group_acces_mask(arg_10_1),
						verify_clbk = callback(arg_10_0, arg_10_0, "is_nav_seg_safe")
					})

					if var_10_27 then
						arg_10_0:_merge_coarse_path_by_area(var_10_27)

						var_10_24 = var_10_31

						break
					end
				end
			else
				for iter_10_10, iter_10_11 in pairs(var_10_31.neighbours) do
					if not var_10_30[iter_10_11] then
						var_0_9(var_10_29, iter_10_11)

						var_10_30[iter_10_11] = var_10_31
					end
				end
			end
		until #var_10_29 == 0

		if var_10_25 then
			var_10_24 = var_10_25
			var_10_30[var_10_24] = var_10_26
			var_10_27 = var_10_28
		end

		if var_10_24 and var_10_27 then
			local var_10_35

			if var_10_4 then
				local var_10_36 = var_10_6 and var_10_24.criminal.units[table.random_key(var_10_24.criminal.units)].unit:movement():m_pos()
				local var_10_37 = var_0_2() < 0.5 and arg_10_0._chk_group_use_flash_grenade or arg_10_0._chk_group_use_smoke_grenade
				local var_10_38 = var_10_37 == arg_10_0._chk_group_use_flash_grenade and arg_10_0._chk_group_use_smoke_grenade or arg_10_0._chk_group_use_flash_grenade

				var_10_35 = var_10_37(arg_10_0, arg_10_1, arg_10_0._task_data.assault, var_10_36) or var_10_38(arg_10_0, arg_10_1, arg_10_0._task_data.assault, var_10_36)

				arg_10_0:_voice_move_in_start(arg_10_1)
			else
				var_10_24 = var_10_30[var_10_24]

				if #var_10_27 > 2 and var_10_24.nav_segs[var_10_27[#var_10_27 - 1][1]] then
					var_0_10(var_10_27)
				end
			end

			if not var_10_4 or var_10_35 or var_10_10.charge or REAI.settings.masochism then
				local var_10_39 = {
					type = "assault_area",
					stance = "hos",
					area = var_10_24,
					coarse_path = var_10_27,
					pose = var_10_4 and not REAI.settings.masochism and "crouch" or "stand",
					attitude = var_10_4 and "engage" or "avoid",
					moving_in = var_10_4 or nil,
					open_fire = var_10_4 or nil,
					pushed = var_10_4 or nil,
					charge = var_10_6,
					interrupt_dis = var_10_6 and 0 or nil
				}

				arg_10_1.is_chasing = arg_10_1.is_chasing or var_10_4

				arg_10_0:_set_objective_to_enemy_group(arg_10_1, var_10_39)
			end
		end
	elseif var_10_5 then
		local var_10_40

		for iter_10_12, iter_10_13 in pairs(arg_10_1.units) do
			local var_10_41 = iter_10_13.tracker:nav_segment()

			if var_10_1.area.nav_segs[var_10_41] then
				var_10_40 = var_10_1.area

				break
			end

			if arg_10_0:is_nav_seg_safe(var_10_41) then
				var_10_40 = arg_10_0:get_area_from_nav_seg_id(var_10_41)

				break
			end
		end

		if not var_10_40 and var_10_1.coarse_path then
			local var_10_42 = arg_10_0:_get_group_forwardmost_coarse_path_index(arg_10_1)

			if var_10_42 then
				var_10_40 = arg_10_0:get_area_from_nav_seg_id(var_10_1.coarse_path[var_10_42][1])
			end
		end

		if var_10_40 then
			local var_10_43 = {
				attitude = "avoid",
				pose = "crouch",
				type = "assault_area",
				stance = "hos",
				area = var_10_40,
				coarse_path = {
					{
						var_10_40.pos_nav_seg,
						mvector3.copy(var_10_40.pos)
					}
				}
			}

			arg_10_1.is_chasing = nil

			arg_10_0:_set_objective_to_enemy_group(arg_10_1, var_10_43)

			return
		end
	end
end

function GroupAIStateBesiege._chk_group_use_smoke_grenade(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if arg_11_2.use_smoke and not arg_11_0:is_smoke_grenade_active() then
		local var_11_0
		local var_11_1

		for iter_11_0, iter_11_1 in var_0_8(arg_11_1.units) do
			if iter_11_1.tactics_map and iter_11_1.tactics_map.smoke_grenade then
				if not arg_11_3 then
					for iter_11_2, iter_11_3 in var_0_8(managers.navigation._nav_segments[iter_11_1.tracker:nav_segment()].neighbours) do
						local var_11_2 = arg_11_0:get_area_from_nav_seg_id(iter_11_2)

						if arg_11_2.target_areas[1].nav_segs[iter_11_2] or var_0_6(var_11_2.criminal.units) then
							local var_11_3 = iter_11_3[var_0_2(#iter_11_3)]

							if var_0_11(var_11_3) == "number" then
								arg_11_3 = managers.navigation._room_doors[var_11_3].center
							else
								arg_11_3 = var_11_3:script_data().element:nav_link_end_pos()
							end

							var_11_0 = var_0_3(iter_11_1.m_pos)
							var_11_1 = iter_11_1

							break
						end
					end
				else
					var_11_0 = var_0_3(iter_11_1.m_pos)
					var_11_1 = iter_11_1
				end

				if arg_11_3 and var_11_1 then
					arg_11_0:detonate_smoke_grenade(arg_11_3, var_11_0, tweak_data.group_ai.smoke_grenade_lifetime, false)

					local var_11_4 = tweak_data.group_ai.smoke_and_flash_grenade_timeout

					arg_11_2.use_smoke_timer = arg_11_0._t + var_0_0(var_11_4[1], var_11_4[2], var_0_2()^0.5)
					arg_11_2.use_smoke = false

					if var_11_1.char_tweak.chatter.smoke then
						arg_11_0:chk_say_enemy_chatter(var_11_1.unit, var_11_1.m_pos, "smoke")
					end

					return true
				end
			end
		end
	end
end

function GroupAIStateBesiege._chk_group_use_flash_grenade(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if arg_12_2.use_smoke then
		local var_12_0
		local var_12_1

		for iter_12_0, iter_12_1 in var_0_8(arg_12_1.units) do
			if iter_12_1.tactics_map and iter_12_1.tactics_map.flash_grenade then
				if not arg_12_3 then
					for iter_12_2, iter_12_3 in var_0_8(managers.navigation._nav_segments[iter_12_1.tracker:nav_segment()].neighbours) do
						if arg_12_2.target_areas[1].nav_segs[iter_12_2] then
							local var_12_2 = iter_12_3[var_0_2(#iter_12_3)]

							if var_0_11(var_12_2) == "number" then
								arg_12_3 = managers.navigation._room_doors[var_12_2].center
							else
								arg_12_3 = var_12_2:script_data().element:nav_link_end_pos()
							end

							var_12_0 = var_0_3(iter_12_1.m_pos)
							var_12_1 = iter_12_1

							break
						end
					end
				else
					var_12_0 = var_0_3(iter_12_1.m_pos)
					var_12_1 = iter_12_1
				end

				if arg_12_3 and var_12_1 then
					arg_12_0:detonate_smoke_grenade(arg_12_3, var_12_0, tweak_data.group_ai.flash_grenade_lifetime, true)

					local var_12_3 = tweak_data.group_ai.smoke_and_flash_grenade_timeout

					arg_12_2.use_smoke_timer = arg_12_0._t + var_0_0(var_12_3[1], var_12_3[2], var_0_2()^0.5)
					arg_12_2.use_smoke = false

					if var_12_1.char_tweak.chatter.flash_grenade then
						arg_12_0:chk_say_enemy_chatter(var_12_1.unit, var_12_1.m_pos, "flash_grenade")
					end

					return true
				end
			end
		end
	end
end

function GroupAIStateBesiege._chk_group_areas_tresspassed(arg_13_0, arg_13_1)
	for iter_13_0, iter_13_1 in var_0_8(arg_13_1.units) do
		for iter_13_2, iter_13_3 in var_0_8(arg_13_0:get_areas_from_nav_seg_id(iter_13_1.tracker:nav_segment())) do
			if not arg_13_0:is_area_safe(iter_13_3) then
				return iter_13_3
			end
		end
	end
end

function GroupAIStateBesiege._chk_coarse_path_obstructed(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_1.objective

	if not var_14_0.coarse_path then
		return
	end

	local var_14_1 = arg_14_0:_get_group_forwardmost_coarse_path_index(arg_14_1)

	if var_14_1 and var_14_0.coarse_path[var_14_1 + 1] and not arg_14_0:is_nav_seg_safe(var_14_0.coarse_path[var_14_1 + 1][1]) then
		return var_14_1 + 1
	end
end
