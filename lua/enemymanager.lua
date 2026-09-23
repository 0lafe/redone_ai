-- Defer entirely to ThinkFaster if it is installed
if not _G.ThinkFaster then
	function EnemyManager:queue_task(id, task_clbk, data, execute_t, verification_clbk, asap)
		-- Fast path: with nothing else pending and nothing already run this frame,
		-- run the task now instead of waiting for the next queue tick. update()
		-- clears _queued_task_executed every frame, so this can only re-enter once
		-- per frame.
		if not execute_t and #self._queued_tasks == 0 and not self._queued_task_executed then
			self._queued_task_executed = true

			if verification_clbk then
				verification_clbk(id)
			end

			task_clbk(data)

			return
		end

		table.insert(self._queued_tasks, {
			clbk = task_clbk,
			id = id,
			data = data,
			t = execute_t or 0,
			v_cb = verification_clbk,
			asap = asap
		})
	end

	-- Vanilla's implementation with the tick rate taken from RDAI settings instead
	-- of tweak_data.group_ai.ai_tick_rate.
	--
	-- The loop structure matters: _execute_queued_task table.remove()s the entry it
	-- runs, so iterating _queued_tasks with a plain ipairs and executing inside it
	-- silently skips whichever task shifts into the vacated slot. The checked-set +
	-- break + restart below is what vanilla does to avoid that, and it only shows up
	-- once the tick rate is raised far enough to run several tasks in one frame --
	-- which is exactly what the ai_tickrate slider is for.
	function EnemyManager:_update_queued_tasks(t, dt)
		self._queue_buffer = self._queue_buffer + dt

		local i_asap_task
		local tick_rate = 1 / RDAI.settings.ai_tickrate
		local queued_tasks = self._queued_tasks

		if tick_rate <= self._queue_buffer then
			local checked = {}

			while true do
				local stop = true

				for i_task, task_data in ipairs(queued_tasks) do
					if not checked[task_data] then
						checked[task_data] = true

						if t > task_data.t then
							self._queue_buffer = self._queue_buffer - tick_rate
							stop = self._queue_buffer <= 0

							self:_execute_queued_task(i_task)

							break
						elseif not i_asap_task and task_data.asap then
							i_asap_task = i_task
						end
					end
				end

				if stop then
					break
				end
			end
		end

		if i_asap_task and not self._queued_task_executed then
			self._queue_buffer = self._queue_buffer - tick_rate

			self:_execute_queued_task(i_asap_task)
		end

		-- Clamp, so the buffer cannot accumulate while tasks are pending but not yet
		-- due and then dump a burst in one frame.
		self._queue_buffer = #queued_tasks == 0 and 0 or math.min(self._queue_buffer, tick_rate * #queued_tasks)

		local next_callback = self._delayed_clbks[#self._delayed_clbks]

		if next_callback and t > next_callback[2] then
			local clbk = table.remove(self._delayed_clbks)[3]

			clbk()
		end
	end
end
