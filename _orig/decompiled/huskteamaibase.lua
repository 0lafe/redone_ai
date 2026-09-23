Hooks:PostHook(HuskTeamAIBase, "post_init", "REAI_post_init", function(arg_1_0)
	arg_1_0._ext_movement = arg_1_0._unit:movement()
end)

HuskTeamAIBase.chk_freeze_anims = nil
