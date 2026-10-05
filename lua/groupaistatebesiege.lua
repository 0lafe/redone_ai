local math_lerp = math.lerp
local math_random = math.random
local mvec3_copy = mvector3.copy
local mvec3_distance_sq = mvector3.distance_sq
local next_g = next
local pairs_g = pairs
local table_insert = table.insert
local table_remove = table.remove

-- Tick rate for upd_police_activity normally
GroupAIStateBesiege._POLICE_ACTIVITY_DELAY = 0.5
-- When spawns are queued
GroupAIStateBesiege._POLICE_ACTIVITY_DELAY_FAST = 0.4

-- Slight reordering of vanilla (not sure why yet)
function GroupAIStateBesiege:_upd_police_activity()
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
	end
end

-- Allow reenforce tasks to run more often
local next_dispatch_t_backup
Hooks:PreHook(GroupAIStateBesiege, "_begin_reenforce_task", "RDAI_prevent_next_dispatch_t_pre", function(self, ...)
	next_dispatch_t_backup = self._task_data.reenforce.next_dispatch_t
end)
Hooks:PostHook(GroupAIStateBesiege, "_begin_reenforce_task", "RDAI_prevent_next_dispatch_t_post", function(self, ...)
	self._task_data.reenforce.next_dispatch_t = next_dispatch_t_backup
end)

-- Old fade logic overwrite when enabled
local upd_assault_task = GroupAIStateBesiege._upd_assault_task
function GroupAIStateBesiege:_upd_assault_task(...)
	local task_data = self._task_data.assault

	if not task_data.active then
		return
	end

	if task_data.phase ~= "fade" or self._hunt_mode or not RDAI.settings.old_fades or managers.skirmish:is_skirmish() then
		return upd_assault_task(self, ...)
	end

	local t = self._t

	self:_assign_recon_groups_to_retire()

	local end_assault = false

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

-- Overwrite spawn point cooldowns based on spawn mode choice
Hooks:PostHook(GroupAIStateBesiege, "_choose_best_group", "RDAI_set_spawnpoint_cooldowns", function(self, ...)
	local spawn_group = Hooks:GetReturn()

	if not spawn_group then
		return
	end

	local id = spawn_group.mission_element:id()

	if RDAI.settings.spawn_mechanic == "240_3" then
		self._spawn_group_timers[id] = self._t + 5
	elseif RDAI.settings.spawn_mechanic == "pre_240_3" then
		self._spawn_group_timers[id] = self._t + math.random(15, 20)
	elseif RDAI.settings.spawn_mechanic == "increased" then
		self._spawn_group_timers[id] = self._t + 1
	end
end)

-- Conditionally overwrite all spawn point CD's when none are available
local find_spawn_group_near_area = GroupAIStateBesiege._find_spawn_group_near_area
function GroupAIStateBesiege:_find_spawn_group_near_area(...)
	local spawn_group, spawn_group_type = find_spawn_group_near_area(self, ...)

	if not spawn_group and (RDAI.settings.spawn_mechanic == "pre_240_3" or RDAI.settings.spawn_mechanic == "increased") then
		local timers = self._spawn_group_timers
		local t = self._t
		local blocked

		for _, cooldown in pairs(timers) do
			if cooldown > t then
				blocked = true

				break
			end
		end

		if blocked then
			self._spawn_group_timers = {}

			spawn_group, spawn_group_type = find_spawn_group_near_area(self, ...)
		end
	end

	return spawn_group, spawn_group_type
end

-- Throttle spawning based on spawn mechanic selected
-- Needed because base update loop runs faster than vanilla
local upd_group_spawning = GroupAIStateBesiege._upd_group_spawning
function GroupAIStateBesiege:_upd_group_spawning(...)
	if self._t > (self._next_spawn_t or 0) then
		upd_group_spawning(self, ...)

		self._next_spawn_t = self._t + (next(self._spawning_groups) and GroupAIStateBesiege._POLICE_ACTIVITY_DELAY_FAST or RDAI:enemy_spawn_interval())
	end
end

-- Can use >3 spawn points at once if increased spawns is enabled
-- Original mod also allowed multiple of the same unit to spawn at once. I might add that back later
local perform_group_spawning = GroupAIStateBesiege._perform_group_spawning
function GroupAIStateBesiege:_perform_group_spawning(spawn_task, force, use_last)
	if RDAI.settings.spawn_mechanic == "increased" then
		perform_group_spawning(self, spawn_task, true, use_last)
	else
		perform_group_spawning(self, spawn_task, force, use_last)
	end
end

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
