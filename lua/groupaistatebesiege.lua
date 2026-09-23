local math_lerp = math.lerp
local math_min = math.min
local math_random = math.random
local mvec3_copy = mvector3.copy
local mvec3_distance = mvector3.distance
local mvec3_distance_sq = mvector3.distance_sq
local next_g = next
local ipairs_g = ipairs
local pairs_g = pairs
local table_insert = table.insert
local table_remove = table.remove

function GroupAIStateBesiege:_queue_police_upd_task()
	if not self._police_upd_task_queued then
		self._police_upd_task_queued = true

		managers.enemy:queue_task("GroupAIStateBesiege._upd_police_activity", self._upd_police_activity, self, self._t + 0.5)
	end
end

GroupAIStateBesiege.on_enemy_unregistered = nil

function GroupAIStateBesiege:_upd_police_activity()
	self._police_upd_task_queued = false

	if not self._police_activity_blocked then
		if self._ai_enabled then
			self:_upd_SO()
			self:_upd_grp_SO()

			if self._enemy_weapons_hot then
				self:_claculate_drama_value()
				self:_upd_group_spawning()
				self:_begin_new_tasks()
				self:_upd_regroup_task()
				self:_upd_reenforce_tasks()
				self:_upd_recon_tasks()
				self:_upd_assault_task()
				self:_check_spawn_phalanx()
				self:_check_phalanx_group_has_spawned()
				self:_check_phalanx_damage_reduction_increase()
				self:_upd_groups()
			end
		end

		self:_queue_police_upd_task()
	end
end

local upd_assault_task = GroupAIStateBesiege._upd_assault_task

function GroupAIStateBesiege:_upd_assault_task(...)
	local task_data = self._task_data.assault

	if not task_data.active then
		return
	end

	if task_data.phase ~= "fade" or self._hunt_mode then
		return upd_assault_task(self, ...)
	end

	local t = self._t

	self:_assign_recon_groups_to_retire()

	local end_assault = false

	if RDAI.settings.old_fades and not managers.skirmish:is_skirmish() then
		if self:_count_police_force("assault") < 7 or t > task_data.phase_end_t + 350 then
			if t > task_data.phase_end_t - 8 and not task_data.said_retreat then
				if self._drama_data.amount < tweak_data.drama.assault_fade_end then
					task_data.said_retreat = true

					self:_police_announce_retreat()
				end
			elseif t > task_data.phase_end_t and self._drama_data.amount < tweak_data.drama.assault_fade_end and self:_count_criminals_engaged_force(4) <= 3 then
				end_assault = true
			end
		end
	elseif self:_count_police_force("assault") < 50 or t > task_data.phase_end_t + (managers.skirmish:is_skirmish() and 0 or 30) then
		if not task_data.said_retreat then
			task_data.said_retreat = true

			self:_police_announce_retreat()
		elseif t > task_data.phase_end_t and (self._drama_data.amount < tweak_data.drama.assault_fade_end and self:_count_criminals_engaged_force(11) <= 10 or t > task_data.phase_end_t + (managers.skirmish:is_skirmish() and 0 or 60)) then
			end_assault = true
		end
	end

	if task_data.force_end or end_assault then
		task_data.active = nil
		task_data.phase = nil
		task_data.said_retreat = nil
		task_data.force_end = nil

		local force_regroup = task_data.force_regroup

		task_data.force_regroup = nil

		if self._draw_drama then
			self._draw_drama.assault_hist[#self._draw_drama.assault_hist][2] = t
		end

		managers.mission:call_global_event("end_assault")
		self:_begin_regroup_task(force_regroup)

		return
	end

	if self._drama_data.amount <= tweak_data.drama.low then
		for criminal_key, criminal_data in pairs(self._player_criminals) do
			self:criminal_spotted(criminal_data.unit)

			for _, group in pairs(self._groups) do
				if group.objective.charge then
					for u_key, u_data in pairs(group.units) do
						u_data.unit:brain():clbk_group_member_attention_identified(nil, criminal_key)
					end
				end
			end
		end
	end

	local primary_target_area = task_data.target_areas[1]

	if self:is_area_safe_assault(primary_target_area) then
		local target_pos = primary_target_area.pos
		local nearest_area
		local nearest_dis

		for criminal_key, criminal_data in pairs_g(self._player_criminals) do
			if not criminal_data.status then
				local dis = mvec3_distance_sq(target_pos, criminal_data.m_pos)

				if not nearest_dis or dis < nearest_dis then
					nearest_dis = dis
					nearest_area = self:get_area_from_nav_seg_id(criminal_data.tracker:nav_segment())
				end
			end
		end

		if nearest_area then
			task_data.target_areas[1] = nearest_area
		end
	end

	if t > task_data.use_smoke_timer then
		task_data.use_smoke = true
	end

	self:detonate_queued_smoke_grenades()
	self:_assign_enemy_groups_to_assault(task_data.phase)
end

function GroupAIStateBesiege:_begin_reenforce_task(reenforce_area)
	local new_task = {
		use_spawn_event = true,
		target_area = reenforce_area,
		start_t = self._t
	}

	table_insert(self._task_data.reenforce.tasks, new_task)

	self._task_data.reenforce.active = true
end

function GroupAIStateBesiege:_find_spawn_group_near_area(target_area, allowed_groups, target_pos, max_dis, verify_clbk)
	target_pos = target_pos or target_area.pos

	local t = self._t
	local valid_spawn_groups = {}
	local valid_spawn_group_distances = {}

	for area_id, area in pairs_g(self._area_data) do
		local spawn_groups = area.spawn_groups

		if spawn_groups then
			for i = 1, #spawn_groups do
				local spawn_group = spawn_groups[i]

				if t >= spawn_group.delay_t and (not verify_clbk or verify_clbk(spawn_group)) then
					local dis_id = spawn_group.nav_seg .. "-" .. target_area.pos_nav_seg
					local my_dis = self._graph_distance_cache[dis_id]

					if not my_dis then
						local path = managers.navigation:search_coarse({
							access_pos = "swat",
							from_seg = spawn_group.nav_seg,
							to_seg = target_area.pos_nav_seg,
							id = dis_id
						})

						if path and #path >= 2 then
							local total_dis = 0
							local current = spawn_group.pos

							for i = 2, #path do
								local nxt = path[i][2]

								if current and nxt then
									total_dis = total_dis + mvec3_distance(current, nxt)
								end

								current = nxt
							end

							my_dis = total_dis
							self._graph_distance_cache[dis_id] = total_dis
						end
					end

					if my_dis and (not max_dis or my_dis < max_dis) then
						local id = spawn_group.mission_element:id()

						valid_spawn_groups[id] = spawn_group
						valid_spawn_group_distances[id] = my_dis
					end
				end
			end
		end
	end

	if not next_g(valid_spawn_groups) then
		return
	end

	local total_weight = 0
	local candidate_groups = {}

	for i, dis in pairs_g(valid_spawn_group_distances) do
		local spawn_group = valid_spawn_groups[i]

		spawn_group.distance = dis
		total_weight = total_weight + self:_choose_best_groups(candidate_groups, spawn_group, spawn_group.mission_element:spawn_groups(), allowed_groups, math_lerp(1, 0.2, math_min(1, dis / 5000)) * 5)
	end

	if total_weight == 0 then
		return
	end

	return self:_choose_best_group(candidate_groups, total_weight)
end

local upd_group_spawning = GroupAIStateBesiege._upd_group_spawning

function GroupAIStateBesiege:_upd_group_spawning(...)
	if self._t > (self._next_spawn_t or 0) then
		upd_group_spawning(self, ...)

		self._next_spawn_t = self._t + (next(self._spawning_groups) and 0.5 or RDAI.settings.enemy_spawn_interval)
	end
end

Hooks:OverrideFunction(GroupAIStateBesiege, "_perform_group_spawning", function(self, spawn_task, force, use_last)
	local nr_units_spawned = 0
	local produce_data = {
		name = true,
		spawn_ai = {}
	}
	local unit_categories = tweak_data.group_ai.unit_categories
	local spawn_pts = spawn_task.spawn_group.spawn_pts

	local function _try_spawn_unit(u_type_name, spawn_entry)
		if not RDAI.settings.masochism and GroupAIStateBesiege._MAX_SIMULTANEOUS_SPAWNS <= nr_units_spawned and not force then
			return
		end

		local hopeless = true
		local current_unit_type = tweak_data.levels:get_ai_group_type()

		for i = 1, #spawn_pts do
			local sp_data = spawn_pts[i]
			local category = unit_categories[u_type_name]

			if (sp_data.accessibility == "any" or category.access[sp_data.accessibility]) and (not sp_data.amount or sp_data.amount > 0) and sp_data.mission_element:enabled() then
				hopeless = false

				if sp_data.delay_t < self._t then
					local units = category.unit_types[current_unit_type]

					produce_data.name = managers.modifiers:modify_value("GroupAIStateBesiege:SpawningUnit", units[math_random(#units)])

					local spawned_unit = sp_data.mission_element:produce(produce_data)
					local u_key = spawned_unit:key()
					local objective

					if spawn_task.objective then
						objective = self.clone_objective(spawn_task.objective)
					else
						objective = spawn_task.group.objective.element:get_random_SO(spawned_unit)

						if not objective then
							spawned_unit:set_slot(0)

							return true
						end

						objective.grp_objective = spawn_task.group.objective
					end

					local u_data = self._police[u_key]

					self:set_enemy_assigned(objective.area, u_key)

					if spawn_entry.tactics then
						u_data.tactics = spawn_entry.tactics
						u_data.tactics_map = {}

						for _, tactic_name in ipairs_g(u_data.tactics) do
							u_data.tactics_map[tactic_name] = true
						end
					end

					spawned_unit:brain():set_spawn_entry(spawn_entry, u_data.tactics_map)

					u_data.rank = spawn_entry.rank

					self:_add_group_member(spawn_task.group, u_key)

					if spawned_unit:brain():is_available_for_assignment(objective) then
						if objective.element then
							objective.element:clbk_objective_administered(spawned_unit)
						end

						spawned_unit:brain():set_objective(objective)
					else
						spawned_unit:brain():set_followup_objective(objective)
					end

					nr_units_spawned = nr_units_spawned + 1

					if spawn_task.ai_task then
						spawn_task.ai_task.force_spawned = spawn_task.ai_task.force_spawned + 1
						spawned_unit:brain()._logic_data.spawned_in_phase = spawn_task.ai_task.phase
					end

					sp_data.delay_t = self._t + sp_data.interval

					if sp_data.amount then
						sp_data.amount = sp_data.amount - 1
					end

					return true
				end
			end
		end

		if hopeless then
			return true
		end
	end

	local complete = true

	for u_type_name, spawn_info in pairs_g(spawn_task.units_remaining) do
		if not unit_categories[u_type_name].access.acrobatic then
			for i = spawn_info.amount, 1, -1 do
				if _try_spawn_unit(u_type_name, spawn_info.spawn_entry) then
					spawn_info.amount = spawn_info.amount - 1
				else
					complete = false

					break
				end
			end
		end
	end

	for u_type_name, spawn_info in pairs_g(spawn_task.units_remaining) do
		for i = spawn_info.amount, 1, -1 do
			if _try_spawn_unit(u_type_name, spawn_info.spawn_entry) then
				spawn_info.amount = spawn_info.amount - 1
			else
				complete = false

				break
			end
		end
	end

	if complete then
		spawn_task.group.has_spawned = true

		table_remove(self._spawning_groups, use_last and #self._spawning_groups or 1)

		if spawn_task.group.size <= 0 then
			self._groups[spawn_task.group.id] = nil
		end
	end
end)

function GroupAIStateBesiege:_assign_enemy_groups_to_assault(phase)
	for group_id, group in pairs_g(self._groups) do
		if group.has_spawned and group.objective.type == "assault_area" then
			if group.objective.moving_out then
				local done_moving = false

				for u_key, u_data in pairs_g(group.units) do
					local objective = u_data.unit:brain():objective()

					if objective and objective.grp_objective == group.objective then
						if objective.in_place or objective.area.nav_segs[u_data.unit:movement():nav_tracker():nav_segment()] then
							done_moving = true
						else
							done_moving = false

							break
						end
					end
				end

				if done_moving then
					group.objective.moving_out = nil
					group.in_place_t = self._t
					group.objective.moving_in = nil

					self:_voice_move_complete(group)
				end
			end

			self:_set_assault_objective_to_group(group, phase)
		end
	end
end

function GroupAIStateBesiege:_set_assault_objective_to_group(group, phase)
	if not group.has_spawned then
		return
	end

	local phase_is_anticipation = phase == "anticipation"
	local current_objective = group.objective
	local approach
	local open_fire
	local push
	local pull_back
	local charge
	local obstructed_area = self:_chk_group_areas_tresspassed(group)
	local group_leader_u_key, group_leader_u_data = self._determine_group_leader(group.units)
	local tactics_map = {}

	if group_leader_u_data and group_leader_u_data.tactics then
		for _, tactic_name in ipairs(group_leader_u_data.tactics) do
			tactics_map[tactic_name] = true
		end

		if current_objective.tactic and not tactics_map[current_objective.tactic] then
			current_objective.tactic = nil
		end

		for _, tactic_name in ipairs(group_leader_u_data.tactics) do
			if tactic_name == "deathguard" and not phase_is_anticipation then
				if current_objective.tactic == tactic_name then
					for u_key, u_data in pairs(self._char_criminals) do
						if u_data.status and current_objective.follow_unit == u_data.unit then
							local crim_nav_seg = u_data.tracker:nav_segment()

							if current_objective.area.nav_segs[crim_nav_seg] then
								return
							end
						end
					end
				end

				local closest_crim_u_data
				local closest_crim_dis

				for u_key, u_data in pairs(self._char_criminals) do
					if u_data.status then
						local closest_u_id, closest_u_data, closest_u_dis_sq = self._get_closest_group_unit_to_pos(u_data.m_pos, group.units)

						if closest_u_dis_sq and (not closest_crim_dis or closest_u_dis_sq < closest_crim_dis) then
							closest_crim_u_data = u_data
							closest_crim_dis = closest_u_dis_sq
						end
					end
				end

				if closest_crim_u_data then
					local search_params = {
						id = "GroupAI_deathguard",
						from_tracker = group_leader_u_data.unit:movement():nav_tracker(),
						to_tracker = closest_crim_u_data.tracker,
						access_pos = self._get_group_acces_mask(group)
					}
					local coarse_path = managers.navigation:search_coarse(search_params)

					if coarse_path then
						local grp_objective = {
							moving_in = true,
							attitude = "engage",
							distance = 800,
							type = "assault_area",
							tactic = "deathguard",
							follow_unit = closest_crim_u_data.unit,
							area = self:get_area_from_nav_seg_id(coarse_path[#coarse_path][1]),
							coarse_path = coarse_path
						}

						group.is_chasing = true

						self:_set_objective_to_enemy_group(group, grp_objective)
						self:_voice_deathguard_start(group)

						return
					end
				end
			elseif tactic_name == "charge" and not current_objective.moving_out and group.in_place_t and (self._t - group.in_place_t > 15 or self._t - group.in_place_t > 4 and self._drama_data.amount <= tweak_data.drama.low) and next(current_objective.area.criminal.units) and group.is_chasing and not current_objective.charge then
				charge = true
			end
		end
	end

	local objective_area = current_objective.area

	if obstructed_area then
		if phase_is_anticipation then
			pull_back = true
		elseif current_objective.moving_out then
			if not current_objective.open_fire then
				open_fire = true
				objective_area = obstructed_area
			end
		elseif not current_objective.pushed or charge and not current_objective.charge then
			push = true
		end
	elseif not current_objective.moving_out then
		local has_criminals_close

		for area_id, neighbour_area in pairs(current_objective.area.neighbours) do
			if next(neighbour_area.criminal.units) then
				has_criminals_close = true

				break
			end
		end

		if charge then
			push = true
		elseif not has_criminals_close or not group.in_place_t then
			approach = true
		elseif not phase_is_anticipation then
			if not current_objective.open_fire then
				open_fire = true
			elseif group.is_chasing or not tactics_map.ranged_fire or self._t - group.in_place_t > 15 then
				push = true
			end
		elseif current_objective.open_fire then
			pull_back = true
		end
	elseif not current_objective.open_fire then
		local obstructed_path_index = self:_chk_coarse_path_obstructed(group)

		if obstructed_path_index then
			objective_area = self:get_area_from_nav_seg_id(current_objective.coarse_path[math.max(obstructed_path_index - 1, 1)][1])
			open_fire = true
		end
	end

	if open_fire then
		local grp_objective = {
			attitude = "engage",
			pose = "stand",
			type = "assault_area",
			stance = "hos",
			open_fire = true,
			tactic = current_objective.tactic,
			area = objective_area,
			coarse_path = {
				{
					objective_area.pos_nav_seg,
					mvector3.copy(objective_area.pos)
				}
			}
		}

		self:_set_objective_to_enemy_group(group, grp_objective)
		self:_voice_open_fire_start(group)
	elseif approach or push then
		local assault_area
		local alternate_assault_area
		local alternate_assault_area_from
		local assault_path
		local alternate_assault_path
		local to_search_areas = {
			objective_area
		}
		local found_areas = {
			[objective_area] = objective_area
		}

		repeat
			local search_area = table.remove(to_search_areas, 1)

			if next(search_area.criminal.units) then
				local assault_from_here = true

				if not push and tactics_map.flank then
					local assault_from_area = found_areas[search_area]

					if assault_from_area ~= objective_area then
						assault_from_here = false

						if not alternate_assault_area or math_random() < 0.5 then
							local coarse_path = managers.navigation:search_coarse({
								id = "GroupAI_assault",
								from_seg = current_objective.area.pos_nav_seg,
								to_seg = assault_from_area.pos_nav_seg,
								access_pos = self._get_group_acces_mask(group),
								verify_clbk = callback(self, self, "is_nav_seg_safe")
							})

							if coarse_path then
								self:_merge_coarse_path_by_area(coarse_path)

								alternate_assault_path = coarse_path
								alternate_assault_area = search_area
								alternate_assault_area_from = assault_from_area
							end
						end

						found_areas[search_area] = nil
					end
				end

				if assault_from_here then
					assault_path = managers.navigation:search_coarse({
						id = "GroupAI_assault",
						from_seg = current_objective.area.pos_nav_seg,
						to_seg = search_area.pos_nav_seg,
						access_pos = self._get_group_acces_mask(group),
						verify_clbk = callback(self, self, "is_nav_seg_safe")
					})

					if assault_path then
						self:_merge_coarse_path_by_area(assault_path)

						assault_area = search_area

						break
					end
				end
			else
				for other_area_id, other_area in pairs(search_area.neighbours) do
					if not found_areas[other_area] then
						table_insert(to_search_areas, other_area)

						found_areas[other_area] = search_area
					end
				end
			end
		until #to_search_areas == 0

		if alternate_assault_area then
			assault_area = alternate_assault_area
			found_areas[assault_area] = alternate_assault_area_from
			assault_path = alternate_assault_path
		end

		if assault_area and assault_path then
			local used_grenade

			if push then
				local detonate_pos

				if charge then
					-- Vanilla picks the first non-deployable criminal; without the filter a
					-- charging group can end up lobbing its grenade at a sentry gun, and
					-- table.random_key on an empty set would index nil.
					for criminal_key, criminal_data in pairs_g(assault_area.criminal.units) do
						local record = self._criminals[criminal_key]

						if record and not record.is_deployable then
							detonate_pos = criminal_data.unit:movement():m_pos()

							break
						end
					end
				end

				local first_chk = math_random() < 0.5 and self._chk_group_use_flash_grenade or self._chk_group_use_smoke_grenade
				local second_chk = first_chk == self._chk_group_use_flash_grenade and self._chk_group_use_smoke_grenade or self._chk_group_use_flash_grenade

				used_grenade = first_chk(self, group, self._task_data.assault, detonate_pos) or second_chk(self, group, self._task_data.assault, detonate_pos)

				self:_voice_move_in_start(group)
			else
				assault_area = found_areas[assault_area]

				if #assault_path > 2 and assault_area.nav_segs[assault_path[#assault_path - 1][1]] then
					table_remove(assault_path)
				end
			end

			-- Only hold a push back for grenade cover if the group can actually produce
			-- cover. Otherwise a group with neither smoke/flash nor the charge tactic
			-- would never be told to move in at all -- which is what happens on vanilla
			-- tactics, i.e. whenever the spawngroups setting is off and
			-- groupaitweakdata.lua bails out before redefining _tactics.
			local can_make_cover = false

			for _, u_data in pairs_g(group.units) do
				if u_data.tactics_map and (u_data.tactics_map.smoke_grenade or u_data.tactics_map.flash_grenade) then
					can_make_cover = true

					break
				end
			end

			if not push or used_grenade or not can_make_cover or tactics_map.charge or RDAI.settings.masochism then
				local grp_objective = {
					type = "assault_area",
					stance = "hos",
					area = assault_area,
					coarse_path = assault_path,
					pose = push and not RDAI.settings.masochism and "crouch" or "stand",
					attitude = push and "engage" or "avoid",
					moving_in = push or nil,
					open_fire = push or nil,
					pushed = push or nil,
					charge = charge,
					interrupt_dis = charge and 0 or nil
				}

				group.is_chasing = group.is_chasing or push

				self:_set_objective_to_enemy_group(group, grp_objective)
			end
		end
	elseif pull_back then
		local retreat_area

		for u_key, u_data in pairs(group.units) do
			local nav_seg_id = u_data.tracker:nav_segment()

			if current_objective.area.nav_segs[nav_seg_id] then
				retreat_area = current_objective.area

				break
			end

			if self:is_nav_seg_safe(nav_seg_id) then
				retreat_area = self:get_area_from_nav_seg_id(nav_seg_id)

				break
			end
		end

		if not retreat_area and current_objective.coarse_path then
			local forwardmost_i_nav_point = self:_get_group_forwardmost_coarse_path_index(group)

			if forwardmost_i_nav_point then
				retreat_area = self:get_area_from_nav_seg_id(current_objective.coarse_path[forwardmost_i_nav_point][1])
			end
		end

		if retreat_area then
			local new_grp_objective = {
				attitude = "avoid",
				pose = "crouch",
				type = "assault_area",
				stance = "hos",
				area = retreat_area,
				coarse_path = {
					{
						retreat_area.pos_nav_seg,
						mvector3.copy(retreat_area.pos)
					}
				}
			}

			group.is_chasing = nil

			self:_set_objective_to_enemy_group(group, new_grp_objective)

			return
		end
	end
end

function GroupAIStateBesiege:_chk_group_use_smoke_grenade(group, task_data, detonate_pos)
	if task_data.use_smoke and not self:is_smoke_grenade_active() then
		local shooter_pos
		local shooter_u_data

		for u_key, u_data in pairs_g(group.units) do
			if u_data.tactics_map and u_data.tactics_map.smoke_grenade then
				if not detonate_pos then
					for neighbour_nav_seg_id, door_list in pairs_g(managers.navigation._nav_segments[u_data.tracker:nav_segment()].neighbours) do
						local area = self:get_area_from_nav_seg_id(neighbour_nav_seg_id)

						if task_data.target_areas[1].nav_segs[neighbour_nav_seg_id] or next_g(area.criminal.units) then
							local door = door_list[math_random(#door_list)]

							if door.x then
								detonate_pos = door
							else
								detonate_pos = door:script_data().element:nav_link_end_pos()
							end

							shooter_pos = mvec3_copy(u_data.m_pos)
							shooter_u_data = u_data

							break
						end
					end
				else
					shooter_pos = mvec3_copy(u_data.m_pos)
					shooter_u_data = u_data
				end

				if detonate_pos and shooter_u_data then
					self:detonate_smoke_grenade(detonate_pos, shooter_pos, tweak_data.group_ai.smoke_grenade_lifetime, false)

					local timeout = tweak_data.group_ai.smoke_and_flash_grenade_timeout

					task_data.use_smoke_timer = self._t + math_lerp(timeout[1], timeout[2], math_random()^0.5)
					task_data.use_smoke = false

					if shooter_u_data.char_tweak.chatter.smoke then
						self:chk_say_enemy_chatter(shooter_u_data.unit, shooter_u_data.m_pos, "smoke")
					end

					return true
				end
			end
		end
	end
end

function GroupAIStateBesiege:_chk_group_use_flash_grenade(group, task_data, detonate_pos)
	if task_data.use_smoke then
		local shooter_pos
		local shooter_u_data

		for u_key, u_data in pairs_g(group.units) do
			if u_data.tactics_map and u_data.tactics_map.flash_grenade then
				if not detonate_pos then
					for neighbour_nav_seg_id, door_list in pairs_g(managers.navigation._nav_segments[u_data.tracker:nav_segment()].neighbours) do
						if task_data.target_areas[1].nav_segs[neighbour_nav_seg_id] then
							local door = door_list[math_random(#door_list)]

							if door.x then
								detonate_pos = door
							else
								detonate_pos = door:script_data().element:nav_link_end_pos()
							end

							shooter_pos = mvec3_copy(u_data.m_pos)
							shooter_u_data = u_data

							break
						end
					end
				else
					shooter_pos = mvec3_copy(u_data.m_pos)
					shooter_u_data = u_data
				end

				if detonate_pos and shooter_u_data then
					self:detonate_smoke_grenade(detonate_pos, shooter_pos, tweak_data.group_ai.flash_grenade_lifetime, true)

					local timeout = tweak_data.group_ai.smoke_and_flash_grenade_timeout

					task_data.use_smoke_timer = self._t + math_lerp(timeout[1], timeout[2], math_random()^0.5)
					task_data.use_smoke = false

					if shooter_u_data.char_tweak.chatter.flash_grenade then
						self:chk_say_enemy_chatter(shooter_u_data.unit, shooter_u_data.m_pos, "flash_grenade")
					end

					return true
				end
			end
		end
	end
end

function GroupAIStateBesiege:_chk_group_areas_tresspassed(group)
	for u_key, u_data in pairs_g(group.units) do
		for area_id, area in pairs_g(self:get_areas_from_nav_seg_id(u_data.tracker:nav_segment())) do
			if not self:is_area_safe(area) then
				return area
			end
		end
	end
end

function GroupAIStateBesiege:_chk_coarse_path_obstructed(group)
	local current_objective = group.objective

	if not current_objective.coarse_path then
		return
	end

	local forwardmost_i_nav_point = self:_get_group_forwardmost_coarse_path_index(group)

	if forwardmost_i_nav_point and current_objective.coarse_path[forwardmost_i_nav_point + 1] and not self:is_nav_seg_safe(current_objective.coarse_path[forwardmost_i_nav_point + 1][1]) then
		return forwardmost_i_nav_point + 1
	end
end
