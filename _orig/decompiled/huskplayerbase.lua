function HuskPlayerBase.pre_destroy(arg_1_0, arg_1_1)
	UnitBase.pre_destroy(arg_1_0, arg_1_1)
	arg_1_0._unit:movement():pre_destroy(arg_1_1)
	arg_1_0._unit:inventory():pre_destroy(arg_1_0._unit)
	managers.groupai:state():unregister_criminal(arg_1_0._unit)

	if managers.network:session() then
		local var_1_0 = managers.network:session():peer_by_unit(arg_1_0._unit)

		if var_1_0 then
			var_1_0:set_unit(nil)
		end
	end
end
