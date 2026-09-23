-- Keeps units assigned to defend_area on the area instead of seeking out a player
local _chk_relocate = CopLogicIdle._chk_relocate
function CopLogicIdle._chk_relocate(data)
	if data.objective and data.objective.type == "defend_area" then
		return
	end

	return _chk_relocate(data)
end
