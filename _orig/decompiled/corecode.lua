_G.REAI = _G.REAI or {
	save_path = SavePath .. "REAI.txt",
	loc_path = ModPath .. "loc/english.txt",
	options_path = ModPath .. "menu/options.txt",
	settings = {
		old_fades = false,
		ai_tickrate = 60,
		masochism = false,
		cover_wait_time = 2,
		enemy_spawn_interval = 2,
		enemy_accuracy_fix = true,
		spawngroups = true
	}
}

function REAI.load(arg_1_0)
	local var_1_0 = io.open(arg_1_0.save_path, "r")

	if var_1_0 then
		for iter_1_0, iter_1_1 in pairs(json.decode(var_1_0:read("*all"))) do
			arg_1_0.settings[iter_1_0] = iter_1_1
		end

		var_1_0:close()
	else
		REAI:save()
	end
end

function REAI.save(arg_2_0)
	local var_2_0 = io.open(arg_2_0.save_path, "w+")

	if var_2_0 then
		var_2_0:write(json.encode(arg_2_0.settings))
		var_2_0:close()
	end
end

REAI:load()
