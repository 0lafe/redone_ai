local mvec3_distance = mvector3.distance
local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local tmp_vec1 = Vector3()

local function flat_distance(pos_a, pos_b)
	mvec3_set(tmp_vec1, pos_b)
	mvec3_set_z(tmp_vec1, pos_a.z)

	return mvec3_distance(pos_a, tmp_vec1)
end

-- Slight improvement to vanilla client husk mechanics
function ActionSpooc:_husk_needs_speedup()
	local queued_actions = self._ext_movement._queued_actions

	if queued_actions and next(queued_actions) then
		return true
	elseif #self._nav_path > 2 then
		local my_pos = self._common_data.pos
		local path_len = 0

		for i = 2, #self._nav_path do
			local nav_point = self._nav_path[i]

			path_len = path_len + flat_distance(my_pos, nav_point)
			my_pos = nav_point
		end

		if path_len > 300 then
			return true
		end
	end
end
