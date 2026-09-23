-- Vanilla appends a duplicate of the final nav point to a *queued* walk action
-- before clearing persistent. The rewritten walk action builds its own path and
-- drops vanilla's duplicate-terminal-point insertions consistently (see
-- CopActionWalk:_upd_wait), so that insert is deliberately omitted here.
function CopMovement:sync_action_walk_stop(explicit)
	local walk_action, is_queued = self:_get_latest_walk_action()

	if is_queued then
		walk_action.persistent = nil
	elseif walk_action then
		walk_action:stop()
	end
end
