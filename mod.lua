if not RDAI then
	RDAI = {
		mod_path = ModPath,
		save_path = SavePath .. "RDAI.txt",
		loc_path = ModPath .. "loc/english.txt",
		options_path = ModPath .. "menu/options.txt",
		required = {},
		settings = {
			old_fades = false,
			ai_tickrate = 60,
			masochism = false,
			cover_wait_time = 2,
			enemy_spawn_interval = 2,
			spawngroups = true
		}
	}

	function RDAI:load()
		local file = io.open(self.save_path, "r")

		if file then
			local ok, data = pcall(json.decode, file:read("*all"))

			file:close()

			if ok and type(data) == "table" then
				for k, v in pairs(data) do
					self.settings[k] = v
				end
			end
		else
			self:save()
		end
	end

	function RDAI:save()
		local file = io.open(self.save_path, "w+")

		if file then
			file:write(json.encode(self.settings))
			file:close()
		end
	end

	RDAI:load()
end

if RequiredScript and not RDAI.required[RequiredScript] then
	local fname = RDAI.mod_path .. RequiredScript:gsub(".+/(.+)", "lua/%1.lua")

	if io.file_is_readable(fname) then
		dofile(fname)
	end

	RDAI.required[RequiredScript] = true
end
