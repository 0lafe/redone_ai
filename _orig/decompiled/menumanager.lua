Hooks:Add("LocalizationManagerPostInit", "REAI_LocalizationManagerPostInit", function(arg_1_0)
	arg_1_0:load_localization_file(REAI.loc_path)
end)
Hooks:Add("MenuManagerInitialize", "REAI_MenuManagerInitialize", function(arg_2_0)
	function MenuCallbackHandler.REAI_check_clbk(arg_3_0, arg_3_1)
		REAI.settings[arg_3_1:name()] = arg_3_1:value() == "on"
	end

	function MenuCallbackHandler.REAI_slider_clbk(arg_4_0, arg_4_1)
		REAI.settings[arg_4_1:name()] = arg_4_1:value()
	end

	function MenuCallbackHandler.REAI_callback_options_closed(arg_5_0)
		REAI:save()
	end

	MenuHelper:LoadFromJsonFile(REAI.options_path, REAI, REAI.settings)
end)
