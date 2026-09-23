-- Remove vanilla animation for exiting DOT anims
function CopActionHurt:_upd_sick(t)
	if self._sick_time then
		if t > self._sick_time then
			self._ext_movement:play_redirect("idle")

			self._sick_time = nil
		end
	elseif not self._ext_anim.hurt then
		self._expired = true
	end
end