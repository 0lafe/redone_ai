function TeamAIInventory.add_unit_by_name(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = World:spawn_unit(arg_1_1, Vector3(), Rotation())
	local var_1_1 = {
		expend_ammo = false,
		alert_AI = true,
		user_unit = arg_1_0._unit,
		ignore_units = {
			arg_1_0._unit,
			var_1_0
		},
		hit_slotmask = managers.slot:get_mask("bullet_impact_targets"),
		user_sound_variant = tweak_data.character[arg_1_0._unit:base()._tweak_table].weapon_voice,
		alert_filter = arg_1_0._unit:brain():SO_access()
	}

	var_1_0:base():setup(var_1_1)
	arg_1_0:add_unit(var_1_0, arg_1_2)
end
