if Global.level_data and Global.level_data.level_id and Global.level_data.level_id:find("skm_") or not REAI.settings.spawngroups then
	return
end

local var_0_0 = {
	"single_spooc",
	"Phalanx"
}

Hooks:PreHook(ElementSpawnEnemyGroup, "_finalize_values", "revert_spawnpoint_delays_finalize_values", function(arg_1_0)
	local var_1_0 = arg_1_0._values.preferred_spawn_groups

	if var_1_0 and #var_1_0 > 0 and not table.contains_all(var_0_0, var_1_0) then
		arg_1_0._values.preferred_spawn_groups = {}

		for iter_1_0 in pairs(tweak_data.group_ai.enemy_spawn_groups) do
			if not table.contains(var_0_0, iter_1_0) then
				table.insert(arg_1_0._values.preferred_spawn_groups, iter_1_0)
			end
		end
	end
end)
