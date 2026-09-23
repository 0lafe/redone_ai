Hooks:Add("LocalizationManagerPostInit", "RDAI_LocalizationManagerPostInit", function(loc_manager)
	loc_manager:load_localization_file(RDAI.loc_path)
end)

Hooks:Add("MenuManagerInitialize", "RDAI_MenuManagerInitialize", function(menu_manager)
	function MenuCallbackHandler:RDAI_check_clbk(item)
		RDAI.settings[item:name()] = item:value() == "on"
	end

	function MenuCallbackHandler:RDAI_slider_clbk(item)
		RDAI.settings[item:name()] = item:value()
	end

	function MenuCallbackHandler:RDAI_callback_options_closed()
		RDAI:save()
	end

	MenuHelper:LoadFromJsonFile(RDAI.options_path, RDAI, RDAI.settings)
end)
