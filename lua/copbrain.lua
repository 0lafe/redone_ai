local math_lerp = math.lerp
local math_random = math.random
local math_up = math.UP

Hooks:PostHook(CopBrain, "clbk_pathing_results", "RDAI_clbk_pathing_results", function(self, search_id, path)
	if path and self._current_logic and self._current_logic.clbk_pathing_results then
		self._current_logic.clbk_pathing_results(self._logic_data)
	end
end)

Hooks:PostHook(CopBrain, "clbk_coarse_pathing_results", "RDAI_clbk_coarse_pathing_results", function(self, search_id, path)
	if path and self._current_logic and self._current_logic.clbk_pathing_results then
		self._current_logic.clbk_pathing_results(self._logic_data)
	end
end)

function CopBrain:_chk_use_cover_grenade(unit)
	local dodge_with_grenade = Network:is_server() and self._logic_data.char_tweak.dodge_with_grenade

	if not dodge_with_grenade or not self._logic_data.attention_obj then
		return
	end

	local check_f = dodge_with_grenade.check
	local t = TimerManager:game():time()

	-- Weird logic to increase smoke grenade throughput. Possibly unintended but sort of existing in old mod
	if check_f and (not self._next_cover_grenade_chk_t or t > self._next_cover_grenade_chk_t) then
		local result, next_t = check_f(t, self._nr_flashbang_covers_used or 0)

		self._next_cover_grenade_chk_t = next_t

		if not result then
			return
		end
	end

	if self._logic_data.attention_obj.dis > 1000 or not dodge_with_grenade.flash then
		if dodge_with_grenade.smoke and not managers.groupai:state():is_smoke_grenade_active() then
			local duration = dodge_with_grenade.smoke.duration

			managers.groupai:state():detonate_smoke_grenade(self._logic_data.m_pos + math_up * 10, self._unit:movement():m_head_pos(), math_lerp(duration[1], duration[2], math_random()), false, dodge_with_grenade.smoke.instant)

			self._nr_flashbang_covers_used = (self._nr_flashbang_covers_used or 0) + 1
		end
	elseif dodge_with_grenade.flash then
		local duration = dodge_with_grenade.flash.duration

		managers.groupai:state():detonate_smoke_grenade(self._logic_data.m_pos + math_up * 10, self._unit:movement():m_head_pos(), math_lerp(duration[1], duration[2], math_random()), true, dodge_with_grenade.flash.instant)

		self._nr_flashbang_covers_used = (self._nr_flashbang_covers_used or 0) + 1
	end
end
