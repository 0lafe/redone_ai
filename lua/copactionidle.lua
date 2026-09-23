-- Improvement for cop turning on client husks
Hooks:PostHook(CopActionIdle, "init", "RDAI_init", function(self, action_desc, common_data)
	if self._body_part ~= 1 and self._body_part ~= 3 then
		return
	end

	self._turn_allowed = true
	self._start_fwd = mvector3.copy(common_data.fwd)
end)
