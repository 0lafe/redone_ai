local var_0_0 = math.random

Hooks:PostHook(CopActionHurt, "init", "REAI_init", function(arg_1_0)
	if arg_1_0._hurt_type == "concussion" then
		arg_1_0.update = arg_1_0._upd_hurt
	end
end)

function CopActionHurt._upd_sick(arg_2_0, arg_2_1)
	if arg_2_0._sick_time then
		if arg_2_1 > arg_2_0._sick_time then
			arg_2_0._ext_movement:play_redirect("idle")

			arg_2_0._sick_time = nil
		end
	elseif not arg_2_0._ext_anim.hurt then
		arg_2_0._expired = true
	end
end

function CopActionHurt._pseudorandom(arg_3_0, arg_3_1, arg_3_2)
	return var_0_0(arg_3_1, arg_3_2)
end
