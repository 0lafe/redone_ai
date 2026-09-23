Hooks:PostHook(CopActionIdle, "init", "REAI_init", function(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0._turn_allowed = true
	arg_1_0._start_fwd = arg_1_2.rot:y()
end)
