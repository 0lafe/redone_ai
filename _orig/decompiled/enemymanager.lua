if not _G.ThinkFaster then
	function EnemyManager.queue_task(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5, arg_1_6)
		if not arg_1_4 and #arg_1_0._queued_tasks == 0 and not arg_1_0._queued_task_executed then
			arg_1_0._queued_task_executed = true

			if arg_1_5 then
				arg_1_5(arg_1_1)
			end

			arg_1_2(arg_1_3)
		else
			table.insert(arg_1_0._queued_tasks, {
				clbk = arg_1_2,
				id = arg_1_1,
				data = arg_1_3,
				t = arg_1_4,
				v_cb = arg_1_5,
				asap = arg_1_6
			})
		end
	end

	function EnemyManager._execute_queued_task(arg_2_0, arg_2_1)
		local var_2_0 = table.remove(arg_2_0._queued_tasks, arg_2_1)

		arg_2_0._queued_task_executed = true

		if var_2_0.v_cb then
			var_2_0.v_cb(var_2_0.id)
		end

		var_2_0.clbk(var_2_0.data)
	end

	function EnemyManager._update_queued_tasks(arg_3_0, arg_3_1, arg_3_2)
		local var_3_0
		local var_3_1

		arg_3_0._queue_buffer = arg_3_0._queue_buffer + arg_3_2

		local var_3_2 = 1 / REAI.settings.ai_tickrate

		if var_3_2 <= arg_3_0._queue_buffer then
			for iter_3_0, iter_3_1 in ipairs(arg_3_0._queued_tasks) do
				if not iter_3_1.t or arg_3_1 > iter_3_1.t then
					arg_3_0:_execute_queued_task(iter_3_0)

					arg_3_0._queue_buffer = arg_3_0._queue_buffer - var_3_2

					if arg_3_0._queue_buffer <= 0 then
						break
					end
				elseif iter_3_1.asap and (not var_3_1 or var_3_1 > iter_3_1.t) then
					var_3_0 = iter_3_0
					var_3_1 = iter_3_1.t
				end
			end
		end

		if #arg_3_0._queued_tasks == 0 then
			arg_3_0._queue_buffer = 0
		end

		if var_3_0 and not arg_3_0._queued_task_executed then
			arg_3_0:_execute_queued_task(var_3_0)
		end

		local var_3_3 = arg_3_0._delayed_clbks

		if var_3_3[1] and arg_3_1 > var_3_3[1][2] then
			table.remove(var_3_3, 1)[3]()
		end
	end
end

function EnemyManager.get_nearby_medic(arg_4_0, arg_4_1)
	if not arg_4_0:is_civilian(arg_4_1) then
		local var_4_0 = World:find_units_quick(arg_4_1, "sphere", arg_4_1:position(), tweak_data.medic.radius, managers.slot:get_mask("enemies"))

		for iter_4_0 = 1, #var_4_0 do
			local var_4_1 = var_4_0[iter_4_0]

			if var_4_1:base():has_tag("medic") and (not var_4_1:anim_data() or not var_4_1:anim_data().act) and Application:time() > var_4_1:character_damage()._heal_cooldown_t + managers.modifiers:modify_value("MedicDamage:CooldownTime", tweak_data.medic.cooldown) then
				return var_4_1
			end
		end
	end
end
