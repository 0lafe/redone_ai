function MedicActionHeal.update(arg_1_0, arg_1_1)
	if not arg_1_0._ext_anim.healing then
		arg_1_0._expired = true
	end
end

MedicActionHeal.chk_block = nil
