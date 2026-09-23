if Global.level_data and Global.level_data.level_id and Global.level_data.level_id:find("skm_") or not RDAI.settings.spawngroups then
	return
end

local excluded_groups = {
	"single_spooc",
	"Phalanx"
}

Hooks:PreHook(ElementSpawnEnemyGroup, "_finalize_values", "remove_bad_spawn_group_options", function(self)
	local preferred_spawn_groups = self._values.preferred_spawn_groups

	if preferred_spawn_groups and #preferred_spawn_groups > 0 and not table.contains_all(excluded_groups, preferred_spawn_groups) then
		self._values.preferred_spawn_groups = {}

		for group_name in pairs(tweak_data.group_ai.enemy_spawn_groups) do
			if not table.contains(excluded_groups, group_name) then
				table.insert(self._values.preferred_spawn_groups, group_name)
			end
		end
	end
end)
