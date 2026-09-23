local math_lerp = math.lerp
local math_min = math.min
local math_random = math.random
local mvec3_set_z = mvector3.set_z
local table_remove = table.remove

Hooks:PostHook(GroupAIStateBase, "criminal_spotted", "RDAI_criminal_spotted", function(self, unit)
	local criminal = self._criminals[unit:key()]

	mvector3.set(criminal.pos, criminal.m_det_pos)
end)

function GroupAIStateBase:on_criminal_nav_seg_change(unit, nav_seg_id)
	local u_key = unit:key()
	local u_sighting = self._criminals[u_key]

	if not u_sighting then
		return
	end

	local prev_area = u_sighting.area

	u_sighting.seg = nav_seg_id

	local area

	if prev_area and prev_area.nav_segs[nav_seg_id] then
		area = prev_area
	else
		area = self:get_area_from_nav_seg_id(nav_seg_id)
	end

	if prev_area ~= area then
		u_sighting.area = area

		if prev_area then
			prev_area.criminal.units[u_key] = nil
		end

		area.criminal.units[u_key] = u_sighting
	end
end

Hooks:PostHook(GroupAIStateBase, "on_enemy_unregistered", "RDAI_on_enemy_unregistered", function(self, unit)
	if self._is_server then
		self:set_enemy_assigned(nil, unit:key())

		local objective = unit:brain():objective()
		local fail_clbk = objective and objective.fail_clbk

		if fail_clbk then
			objective.fail_clbk = nil

			fail_clbk(unit)
		end
	end
end)

function GroupAIStateBase:chk_say_teamAI_combat_chatter(unit)
	if not self:is_detection_persistent() then
		return
	end

	local drama_amount = self._drama_data.amount
	local criminal_sound = tweak_data.sound.criminal_sound
	local delay_tweak = criminal_sound.combat_callout_delay
	local t = self._t

	if t < self._teamAI_last_combat_chatter_t + math_lerp(delay_tweak[1], delay_tweak[2], drama_amount) then
		return
	end

	self._teamAI_last_combat_chatter_t = t

	local chance_tweak = criminal_sound.combat_callout_chance

	if math_lerp(chance_tweak[1], chance_tweak[2], math_min(drama_amount^2, 1)) < math_random() then
		return
	end

	unit:sound():say("g90", true, true)
end

function GroupAIStateBase:is_nav_seg_safe(nav_seg)
	for char_criminal_key, char_criminal in pairs(self._char_criminals) do
		if char_criminal.tracker:nav_segment() == nav_seg then
			return false
		end
	end

	return true
end

function GroupAIStateBase:_merge_coarse_path_by_area(coarse_path)
	local i_nav_seg = #coarse_path
	local last_area

	while i_nav_seg > 0 and #coarse_path > 2 do
		local area = self:get_area_from_nav_seg_id(coarse_path[i_nav_seg][1])

		if last_area and last_area == area then
			table_remove(coarse_path, i_nav_seg)
		else
			last_area = area
		end

		i_nav_seg = i_nav_seg - 1
	end
end
