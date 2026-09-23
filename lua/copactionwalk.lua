local idstr_base = Idstring("base")
local mrot_set_look_at = mrotation.set_look_at
local mrot_set_yaw_pitch_roll = mrotation.set_yaw_pitch_roll
local mrot_slerp = mrotation.slerp
local mrot_yaw = mrotation.yaw
local mvec3_add = mvector3.add
local mvec3_bezier = mvector3.bezier
local mvec3_copy = mvector3.copy
local mvec3_cross = mvector3.cross
local mvec3_dot = mvector3.dot
local mvec3_direction = mvector3.direction
local mvec3_distance = mvector3.distance
local mvec3_distance_sq = mvector3.distance_sq
local mvec3_length = mvector3.length
local mvec3_lerp = mvector3.lerp
local mvec3_multiply = mvector3.multiply
local mvec3_normalize = mvector3.normalize
local mvec3_rotate_with = mvector3.rotate_with
local mvec3_set = mvector3.set
local mvec3_set_length = mvector3.set_length
local mvec3_set_z = mvector3.set_z
local mvec3_subtract = mvector3.subtract
local math_abs = math.abs
local math_ceil = math.ceil
local math_clamp = math.clamp
local math_lerp = math.lerp
local math_max = math.max
local math_min = math.min
local math_step = math.step
local math_up = math.UP
local next_g = next
local REACT_SHOOT = AIAttentionObject.REACT_SHOOT
local REACT_SURPRISED = AIAttentionObject.REACT_SURPRISED
local table_insert = table.insert
local table_remove = table.remove
local temp_rot1 = Rotation()
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vec3 = Vector3()
local tmp_vec4 = Vector3()
local tmp_vec5 = Vector3()
local flat_vec = Vector3()

local function flat_distance(pos_a, pos_b)
	mvec3_set(flat_vec, pos_a)
	mvec3_set_z(flat_vec, pos_b.z)

	return mvec3_distance(flat_vec, pos_b)
end

local function flat_distance_sq(pos_a, pos_b)
	mvec3_set(flat_vec, pos_a)
	mvec3_set_z(flat_vec, pos_b.z)

	return mvec3_distance_sq(flat_vec, pos_b)
end

function CopActionWalk:init(action_desc, common_data)
	self._common_data = common_data
	self._action_desc = action_desc
	self._unit = common_data.unit
	self._ext_movement = common_data.ext_movement
	self._ext_anim = common_data.ext_anim
	self._ext_base = common_data.ext_base
	self._ext_network = common_data.ext_network
	self._body_part = action_desc.body_part

	self:_init_ik()

	self._machine = common_data.machine

	self:on_attention(common_data.attention)

	self._stance = common_data.stance
	self._last_vel_z = 0
	self._cur_vel = 0
	self._end_rot = action_desc.end_rot

	CopActionAct._create_blocks_table(self, action_desc.blocks)

	self._persistent = action_desc.persistent
	self._haste = action_desc.variant
	self._start_t = TimerManager:game():time()
	self._no_walk = action_desc.no_walk
	self._no_strafe = action_desc.no_strafe
	self._last_pos = mvec3_copy(common_data.pos)
	self._footstep_pos = mvec3_copy(common_data.pos)
	self._NO_RUN_START = common_data.char_tweak.no_run_start
	self._NO_RUN_STOP = common_data.char_tweak.no_run_stop
	self._simplified_path = action_desc.nav_path
	self._host_stop_pos_ahead = action_desc.host_stop_pos_ahead
	self._last_upd_t = self._start_t - 0.001
	self._sync = Network:is_server()
	self._was_interrupted = action_desc.interrupted
	self._skipped_frames = 1

	if self._ext_anim.needs_idle then
		self._waiting_full_blend = true

		self:_set_updator("_upd_wait_for_full_blend")

		if self._sync then
			self._unit:brain():add_pos_rsrv("move_dest", {
				radius = 30,
				position = mvec3_copy(self._simplified_path[#self._simplified_path])
			})

			local stand_rsrv = self._unit:brain():get_pos_rsrv("stand")

			if not stand_rsrv or mvec3_distance_sq(stand_rsrv.position, common_data.pos) > 400 then
				self._unit:brain():add_pos_rsrv("stand", {
					radius = 30,
					position = mvec3_copy(common_data.pos)
				})
			end
		end
	elseif not self:_init() then
		return
	end

	self._ext_movement:enable_update()

	return true
end

function CopActionWalk:_init()
	if not self:_sanitize() then
		return
	end

	local new_nav_points = self._simplified_path
	local action_desc = self._action_desc
	local common_data = self._common_data

	if self._sync then
		if managers.groupai:state():all_AI_criminals()[common_data.unit:key()] then
			self._nav_link_invul = true
		end

		for i = 1, #new_nav_points do
			local new_nav_point = new_nav_points[i]

			if new_nav_point.x then
				new_nav_points[i] = mvec3_copy(new_nav_point)
			elseif alive(new_nav_point) then
				new_nav_points[i] = {
					element = new_nav_point:script_data().element,
					c_class = new_nav_point
				}
			else
				return false
			end
		end

		if not action_desc.path_simplified then
			self._calculate_simplified_path(mvec3_copy(common_data.pos), new_nav_points, 2, true, true)
		end
	else
		for i = 1, #new_nav_points do
			local new_nav_point = new_nav_points[i]

			if not new_nav_point.x then
				function new_nav_point.element.value(element, key)
					return element[key]
				end

				function new_nav_point.element.nav_link_wants_align_pos(element)
					return element.from_idle
				end
			end
		end

		if action_desc.interrupted then
			new_nav_points[1] = mvec3_copy(common_data.pos)
		else
			table_insert(new_nav_points, 1, mvec3_copy(common_data.pos))
		end

		local next_pos = new_nav_points[2] and self._nav_point_pos(new_nav_points[2])

		if not next_pos or not self._host_stop_pos_ahead and managers.navigation:raycast({
			tracker_from = common_data.nav_tracker,
			pos_to = next_pos
		}) then
			table_insert(new_nav_points, 2, mvec3_copy(self._ext_movement:m_host_stop_pos()))

			self._host_stop_pos_ahead = true
		end
	end

	if not new_nav_points[2].x then
		self._next_is_nav_link = new_nav_points[2]
	end

	self._curve_path_index = 1

	self:_chk_start_anim(self._nav_point_pos(new_nav_points[2]))

	if self._start_run then
		self:_set_updator("_upd_start_anim_first_frame")
	end

	if not self._start_run_turn and self._ext_base:lod_stage() == 1 and flat_distance_sq(new_nav_points[1], self._nav_point_pos(new_nav_points[2])) > 160000 then
		self._curve_path = self:_calculate_curved_path(new_nav_points, 1, 1, common_data.fwd)
	else
		self._curve_path = {
			new_nav_points[1],
			self._nav_point_pos(new_nav_points[2])
		}
	end

	if self._next_is_nav_link and self._next_is_nav_link.element:nav_link_wants_align_pos() and #self._curve_path == 2 and not self._NO_RUN_STOP and self._haste == "run" and flat_distance_sq(self._curve_path[1], self._curve_path[2]) >= 14400 then
		self._chk_stop_dis = 210
	end

	if self._sync then
		local sync_yaw = 0

		if self._end_rot then
			local yaw = self._end_rot:yaw()

			if yaw < 0 then
				yaw = 360 + yaw
			end

			sync_yaw = 1 + math_ceil(yaw * 254 / 360)
		end

		self._ext_network:send("action_walk_start", self._nav_point_pos(new_nav_points[2]), 1, 0, false, self._haste == "walk" and 1 or 2, sync_yaw, self._no_walk and true or false, self._no_strafe and true or false, not action_desc.pose and 0 or action_desc.pose == "stand" and 1 or 2, not action_desc.end_pose and 0 or action_desc.end_pose == "stand" and 1 or 2)
		self._unit:brain():rem_pos_rsrv("stand")
		self._unit:brain():add_pos_rsrv("move_dest", {
			radius = 30,
			position = mvec3_copy(new_nav_points[#new_nav_points])
		})
	end

	self._init_called = true

	return true
end

function CopActionWalk:append_path(path, separator)
	if self._end_of_path and not self._next_is_nav_link or self._action_desc.path_simplified or self:stopping() then
		return false
	end

	local simplified_path = self._simplified_path

	for i = 1, #path do
		local nav_point = path[i]

		if nav_point.x then
			path[i] = mvec3_copy(nav_point)
		elseif alive(nav_point) then
			path[i] = {
				element = nav_point:script_data().element,
				c_class = nav_point
			}
		else
			return false
		end
	end

	for i = 1, #path do
		table_insert(simplified_path, path[i])
	end

	if simplified_path[1].x then
		simplified_path[1] = mvec3_copy(self._common_data.pos)
	else
		simplified_path[1] = simplified_path[1].c_class:end_position()
	end

	self._calculate_simplified_path(nil, simplified_path, 2, true, true)

	if #simplified_path == 2 then
		table_insert(simplified_path, 2, path[1])
	end

	if self._curve_path and not managers.navigation:raycast({
		pos_from = simplified_path[1],
		pos_to = self._nav_point_pos(simplified_path[2])
	}) then
		if not self._start_run_turn and self._ext_base:lod_stage() == 1 and flat_distance_sq(simplified_path[1], self._nav_point_pos(simplified_path[2])) > 490000 then
			mvec3_set(tmp_vec1, self._curve_path[self._curve_path_index + 1])
			mvec3_subtract(tmp_vec1, self._curve_path[self._curve_path_index])
			mvec3_set_z(tmp_vec1, 0)
			mvec3_normalize(tmp_vec1)

			self._curve_path = self:_calculate_curved_path(simplified_path, 1, 1, tmp_vec1)
		else
			self._curve_path = {
				simplified_path[1],
				self._nav_point_pos(simplified_path[2])
			}
		end

		self._curve_path_index = 1
	end

	if not simplified_path[2].x then
		self._next_is_nav_link = simplified_path[2]
	end

	self._end_of_curved_path = nil
	self._chk_stop_dis = nil
	self._nav_seg = separator

	self._unit:brain():add_pos_rsrv("move_dest", {
		radius = 30,
		position = mvec3_copy(simplified_path[#simplified_path])
	})

	return true
end

local opposite_pose = {
	crouch = "stand",
	stand = "crouch"
}

function CopActionWalk:_sanitize()
	local ext_anim = self._ext_anim

	if not ext_anim.pose then
		self._ext_movement:play_redirect("idle")

		if not ext_anim.pose and not self._ext_movement:play_state("std/stand/still/idle/look") then
			return
		end
	end

	local pose = ext_anim.pose or self._fallback_pose
	local wanted_pose = self._action_desc.pose

	if wanted_pose and not ext_anim[wanted_pose] and self._walk_anim_lengths[wanted_pose] then
		self._ext_movement:play_redirect(wanted_pose)
	elseif not self._walk_anim_lengths[pose] then
		self._ext_movement:play_redirect(opposite_pose[pose])
	end

	return true
end

function CopActionWalk:_chk_start_anim(next_pos)
	if self._haste ~= "run" or self._NO_RUN_START or (self._ext_base:lod_stage() or 4) > 2 then
		return
	end

	local can_turn_and_fire = true
	local path_dir = tmp_vec1

	mvec3_set(path_dir, next_pos)
	mvec3_subtract(path_dir, self._common_data.pos)
	mvec3_set_z(path_dir, 0)

	local path_len = mvec3_normalize(path_dir)
	local anim_movement = self._anim_movement[self._ext_anim.pose or self._fallback_pose]

	if self._attention_pos then
		local target_vec_flat = tmp_vec2

		mvec3_set(target_vec_flat, self._attention_pos)
		mvec3_subtract(target_vec_flat, self._common_data.pos)
		mvec3_set_z(target_vec_flat, 0)
		mvec3_normalize(target_vec_flat)

		if mvec3_dot(path_dir, target_vec_flat) < 0.7 then
			can_turn_and_fire = false
		end
	end

	if can_turn_and_fire then
		local spin = path_dir:to_polar_with_reference(self._common_data.fwd, math_up).spin

		if math_abs(spin) > 135 then
			if mvec3_length(anim_movement.run_start_turn_bwd.ds) < path_len - 100 then
				if spin > 0 then
					spin = spin - 360
				end

				self._start_run_turn = {
					self._common_data.rot:yaw(),
					spin,
					"bwd"
				}
			end
		elseif spin < -65 then
			if mvec3_length(anim_movement.run_start_turn_r.ds) < path_len - 100 then
				self._start_run_turn = {
					self._common_data.rot:yaw(),
					spin,
					"r"
				}
			end
		elseif spin > 65 and mvec3_length(anim_movement.run_start_turn_l.ds) < path_len - 100 then
			self._start_run_turn = {
				self._common_data.rot:yaw(),
				spin,
				"l"
			}
		end
	end

	self._start_run = true

	if not self._root_blend_disabled then
		self._root_blend_disabled = true

		self._ext_movement:set_root_blend(false)
	end

	if not self._start_run_turn then
		local right_dot = mvec3_dot(path_dir, self._common_data.right)
		local fwd_dot = mvec3_dot(path_dir, self._common_data.fwd)

		if math_abs(right_dot) < math_abs(fwd_dot) then
			self._start_run_straight = fwd_dot > 0 and "fwd" or "bwd"
		else
			self._start_run_straight = right_dot > 0 and "r" or "l"
		end
	end
end

function CopActionWalk._calculate_shortened_path(path)
	local test_pos = tmp_vec1

	for i = 2, #path - 1 do
		if path[i].x then
			local prev_nav_point = path[i - 1]

			mvec3_lerp(test_pos, prev_nav_point.x and prev_nav_point or prev_nav_point.c_class:end_position(), path[i], 0.8)

			if not managers.navigation:raycast({
				pos_from = test_pos,
				pos_to = CopActionWalk._nav_point_pos(path[i + 1])
			}) then
				mvec3_set(path[i], test_pos)
			end
		end
	end
end

local diagonals = {
	Vector3(212.132, 212.132, 0),
	Vector3(212.132, -212.132, 0)
}

function CopActionWalk._apply_padding_to_simplified_path(path)
	local offset = tmp_vec1
	local to_pos = tmp_vec2

	for i = 2, #path - 1 do
		local pos = path[i]

		if pos.x then
			for _ = 1, #diagonals do
				local diagonal = diagonals[_]

				mvec3_set(to_pos, pos)
				mvec3_add(to_pos, diagonal)

				local col_pos_fwd, trace_fwd = CopActionWalk._chk_shortcut_pos_to_pos(pos, to_pos, true)

				mvec3_set(offset, trace_fwd[1])
				mvec3_set(to_pos, pos)
				mvec3_multiply(diagonal, -1)
				mvec3_add(to_pos, diagonal)

				local col_pos_bwd, trace_bwd = CopActionWalk._chk_shortcut_pos_to_pos(pos, to_pos, true)

				mvec3_lerp(offset, offset, trace_bwd[1], 0.5)

				local prev_nav_point = path[i - 1]

				if not managers.navigation:raycast({
					pos_from = offset,
					pos_to = CopActionWalk._nav_point_pos(path[i + 1])
				}) and not managers.navigation:raycast({
					pos_from = prev_nav_point.x and prev_nav_point or prev_nav_point.c_class:end_position(),
					pos_to = offset
				}) then
					mvec3_set(pos, offset)
				end
			end
		end
	end
end

function CopActionWalk:_calculate_curved_path(path, index, curvature_factor, enter_dir)
	local p1 = path[index]
	local p4 = self._nav_point_pos(path[index + 1])
	local p2
	local p3
	local curved_path = {
		p1
	}
	local segment_dis = flat_distance(p4, p1)
	local vec_out = tmp_vec1
	local vec_in = tmp_vec2
	local nr_control_pts = 2

	if enter_dir then
		nr_control_pts = 3

		mvec3_set(vec_out, enter_dir)
		mvec3_set_length(vec_out, segment_dis)
		mvec3_set(vec_in, p4)
		mvec3_subtract(vec_in, p1)
		mvec3_set_length(vec_in, segment_dis * curvature_factor)
		mvec3_add(vec_out, vec_in)
		mvec3_set_z(vec_out, 0)
		mvec3_set_length(vec_out, segment_dis * 0.3)

		p2 = tmp_vec3

		mvec3_set(p2, p1)
		mvec3_add(p2, vec_out)
	end

	if p2 and path[index + 2] then
		nr_control_pts = nr_control_pts + 1

		mvec3_set(vec_out, p4)
		mvec3_subtract(vec_out, self._nav_point_pos(path[index + 2]))
		mvec3_set_length(vec_out, segment_dis)
		mvec3_set(vec_in, p1)
		mvec3_subtract(vec_in, p2)
		mvec3_set_length(vec_in, segment_dis * curvature_factor)
		mvec3_add(vec_out, vec_in)
		mvec3_set_z(vec_out, 0)
		mvec3_set_length(vec_out, segment_dis * 0.3)

		p3 = tmp_vec4

		mvec3_set(p3, p4)
		mvec3_add(p3, vec_out)
	end

	if nr_control_pts > 2 then
		local prev_pos = curved_path[1]

		for i = 1, 6 do
			local pos = tmp_vec1

			if nr_control_pts == 3 then
				mvec3_bezier(pos, p1, p2 or p3, p4, i / 7)
			else
				mvec3_bezier(pos, p1, p2, p3, p4, i / 7)
			end

			if managers.navigation:raycast({
				pos_from = prev_pos,
				pos_to = pos
			}) then
				return curvature_factor < 1 and {
					curved_path[1],
					p4
				} or self:_calculate_curved_path(path, index, 0.5, enter_dir)
			end

			prev_pos = mvec3_copy(pos)

			table_insert(curved_path, prev_pos)
		end

		if managers.navigation:raycast({
			pos_from = prev_pos,
			pos_to = p4
		}) then
			return curvature_factor < 1 and {
				curved_path[1],
				p4
			} or self:_calculate_curved_path(path, index, 0.5, enter_dir)
		end

		table_insert(curved_path, p4)
	else
		table_insert(curved_path, p4)
	end

	return curved_path
end

function CopActionWalk:on_exit()
	if self._expired and self._end_rot then
		self._ext_movement:set_rotation(self._end_rot)
	end

	if self._root_blend_disabled then
		self._ext_movement:set_root_blend(true)
	end

	if self._changed_driving then
		self._common_data.unit:set_driving("script")
	end

	if self._expired and self._ext_anim.move then
		self:_stop_walk()
	end

	self:_set_ik_modifier_state(false)
	self._ext_movement:drop_held_items()

	if self._sync then
		if self._init_called then
			if not self._expired then
				self._ext_network:send("action_walk_nav_point", mvec3_copy(self._ext_movement:m_pos()))
			end

			self._ext_network:send("action_walk_stop")
		end

		self._unit:brain():rem_pos_rsrv("move_dest")
	else
		self._ext_movement:set_m_host_stop_pos(self._ext_movement:m_pos())
	end

	if self._nav_link_invul_on then
		self._common_data.ext_damage:set_invulnerable(false)
	end
end

function CopActionWalk:_upd_wait_for_full_blend(t)
	if self._ext_anim.needs_idle and not self._ext_anim.to_idle then
		if not self._ext_movement:play_redirect("idle") then
			return
		end

		self._ext_movement:spawn_wanted_items()
	end

	if not self._ext_anim.to_idle and self._ext_anim.idle_full_blend then
		self._waiting_full_blend = nil

		if self:_init() then
			self._ext_movement:drop_held_items()

			if self._updator == "_upd_wait_for_full_blend" then
				self:_set_updator(nil)
			end
		else
			self._ext_movement:action_request({
				body_part = 2,
				type = "idle"
			})
		end
	else
		self._ext_movement:set_m_rot(self._unit:rotation())
		self._ext_movement:set_m_pos(self._unit:position())
	end
end

function CopActionWalk:update(t)
	if self._ik_update then
		self._ik_update(t)
	end

	local dt
	local vis_state = self._ext_base:lod_stage() or 4

	if vis_state == 1 then
		dt = t - self._last_upd_t
		self._last_upd_t = TimerManager:game():time()
	elseif vis_state > self._skipped_frames then
		self._skipped_frames = self._skipped_frames + 1

		return
	else
		self._skipped_frames = 1
		dt = t - self._last_upd_t
		self._last_upd_t = TimerManager:game():time()
	end

	local anim_data = self._ext_anim

	if self._end_of_path and (not anim_data.act or not anim_data.walk) then
		if self._next_is_nav_link then
			self:_set_updator("_upd_nav_link_first_frame")
			self:update(t)

			return
		elseif self._persistent then
			self:_set_updator("_upd_wait")
		else
			self._expired = true

			if self._end_rot then
				self._ext_movement:set_rotation(self._end_rot)
			end
		end
	else
		self:_nav_chk_walk(t, dt, vis_state)
	end

	if self._cur_vel < 0.1 or anim_data.act and anim_data.walk then
		-- block empty
	elseif not self._expired then
		local move_dir = tmp_vec3

		mvec3_set(move_dir, self._last_pos)
		mvec3_subtract(move_dir, self._common_data.pos)
		mvec3_set_z(move_dir, 0)
		mvec3_normalize(move_dir)

		local wanted_walk_dir

		if self._no_strafe or self._walk_turn then
			wanted_walk_dir = "fwd"
		else
			local face_fwd = tmp_vec1

			if self._curve_path_end_rot and flat_distance_sq(self._last_pos, self._footstep_pos) < 19600 then
				mvec3_set(face_fwd, self._common_data.fwd)
			else
				if self._attention_pos then
					mvec3_set(face_fwd, self._attention_pos)
					mvec3_subtract(face_fwd, self._common_data.pos)
				elseif self._footstep_pos then
					mvec3_set(face_fwd, self._footstep_pos)
					mvec3_subtract(face_fwd, self._common_data.pos)
				end

				mvec3_set_z(face_fwd, 0)
				mvec3_normalize(face_fwd)
			end

			local face_right = tmp_vec2

			mvec3_cross(face_right, face_fwd, math_up)

			local right_dot = mvec3_dot(move_dir, face_right)
			local fwd_dot = mvec3_dot(move_dir, face_fwd)

			if math_abs(right_dot) < math_abs(fwd_dot) then
				if (anim_data.move_l and right_dot < 0 or anim_data.move_r and right_dot > 0) and math_abs(fwd_dot) < 0.73 then
					wanted_walk_dir = anim_data.move_side
				elseif fwd_dot > 0 then
					wanted_walk_dir = "fwd"
				else
					wanted_walk_dir = "bwd"
				end
			elseif (anim_data.move_fwd and fwd_dot > 0 or anim_data.move_bwd and fwd_dot < 0) and math_abs(right_dot) < 0.73 then
				wanted_walk_dir = anim_data.move_side
			else
				wanted_walk_dir = right_dot > 0 and "r" or "l"
			end
		end

		local rot_new = temp_rot1

		if self._curve_path_end_rot then
			mrot_slerp(rot_new, self._curve_path_end_rot, self._nav_link_rot or self._end_rot, 1 - math_min(1, flat_distance(self._last_pos, self._footstep_pos) / 140))
		else
			local wanted_u_fwd = tmp_vec1

			mvec3_set(wanted_u_fwd, move_dir)
			mvec3_rotate_with(wanted_u_fwd, self._walk_side_rot[wanted_walk_dir])
			mrot_set_look_at(rot_new, wanted_u_fwd, math_up)
			mrot_slerp(rot_new, self._common_data.rot, rot_new, math_min(1, dt * 5))
		end

		self._ext_movement:set_rotation(rot_new)

		if self._chk_stop_dis then
			local end_dis = flat_distance(self._last_pos, self._nav_point_pos(self._simplified_path[2]))

			if end_dis < self._chk_stop_dis then
				local end_pose = self._action_desc.end_pose

				if end_pose and not self._next_is_nav_link then
					if end_pose ~= anim_data.pose then
						self._ext_movement:action_request({
							no_sync = true,
							body_part = 4,
							type = end_pose
						})
					end
				else
					end_pose = self._ext_anim.pose
				end

				if vis_state < 3 and self._ext_anim.run then
					local stop_anim_fwd = self._nav_link_rot and self._nav_link_rot:y() or self._end_rot and self._end_rot:y() or move_dir:rotate_with(self._walk_side_rot[wanted_walk_dir])
					local move_dir_r_norm = tmp_vec3

					mvec3_cross(move_dir_r_norm, move_dir, math_up)

					local stop_fwd_dot = mvec3_dot(stop_anim_fwd, move_dir)
					local stop_r_dot = mvec3_dot(stop_anim_fwd, move_dir_r_norm)
					local unused_17 -- unused, kept for bytecode parity
					local stop_anim_side = math_abs(stop_r_dot) < math_abs(stop_fwd_dot) and (stop_fwd_dot > 0 and "fwd" or "bwd") or stop_r_dot > 0 and "l" or "r"
					local stop_dis = self._anim_movement[end_pose]["run_stop_" .. stop_anim_side]

					if stop_dis and end_dis < stop_dis then
						self._stop_anim_side = stop_anim_side
						self._stop_anim_fwd = stop_anim_fwd
						self._stop_dis = stop_dis

						self:_set_updator("_upd_stop_anim_first_frame")
					end
				end
			end
		elseif self._walk_turn and flat_distance_sq(self._last_pos, self._curve_path[self._curve_path_index + 1]) < 2025 then
			self:_set_updator("_upd_walk_turn_first_frame")
		end

		local walk_anim_velocities = self._walk_anim_velocities[self._stance.values[4] > 0 and "wounded" or anim_data.pose or "stand"][self._stance.name]
		local real_velocity = self._cur_vel
		local variant = self._haste

		if variant == "run" then
			if anim_data.sprint then
				if real_velocity > 480 and anim_data.pose == "stand" then
					variant = "sprint"
				elseif real_velocity > 250 then
					variant = "run"
				elseif not self._no_walk then
					variant = "walk"
				end
			elseif anim_data.run then
				if real_velocity > 530 and walk_anim_velocities.sprint and anim_data.pose == "stand" then
					variant = "sprint"
				elseif real_velocity > 250 then
					variant = "run"
				elseif not self._no_walk then
					variant = "walk"
				end
			elseif real_velocity > 530 and walk_anim_velocities.sprint and anim_data.pose == "stand" then
				variant = "sprint"
			elseif real_velocity > 300 then
				variant = "run"
			elseif not self._no_walk then
				variant = "walk"
			end
		end

		self:_adjust_move_anim(wanted_walk_dir, variant)
		self:_adjust_walk_anim_speed(dt, real_velocity / walk_anim_velocities[variant][wanted_walk_dir])
	end

	self:_set_new_pos(dt)
end

function CopActionWalk:_upd_start_anim_first_frame(t)
	self:_start_move_anim(self._start_run_turn and self._start_run_turn[3] or self._start_run_straight, "run", self:_get_current_max_walk_speed("fwd") / self._walk_anim_velocities[self._ext_anim.pose or "stand"][self._stance.name][self._haste].fwd, self._start_run_turn)

	self._start_max_vel = 0

	self:_set_updator("_upd_start_anim")
end

function CopActionWalk:_upd_start_anim(t)
	if self._ext_anim.run_start then
		local dt = TimerManager:game():delta_time()

		if self._start_run_turn then
			if self._ext_anim.run_start_full_blend then
				local seg_rel_t = self._machine:segment_relative_time(idstr_base)

				if not self._start_run_turn.start_seg_rel_t then
					self._start_run_turn.start_seg_rel_t = seg_rel_t
				end

				local delta_pos = self._common_data.unit:get_animation_delta_position()
				local new_pos = tmp_vec1

				mvec3_set(new_pos, self._common_data.pos)
				mvec3_add(new_pos, delta_pos)

				local ray_params = {
					trace = true,
					allow_entry = true,
					tracker_from = self._common_data.nav_tracker,
					pos_to = new_pos
				}

				if managers.navigation:raycast(ray_params) then
					new_pos = ray_params.trace[1]

					local travel_vec = tmp_vec1

					mvec3_set(travel_vec, new_pos)
					mvec3_subtract(travel_vec, self._last_pos)
					mvec3_set_z(travel_vec, 0)

					self._cur_vel = mvec3_length(travel_vec) / dt
					self._start_max_vel = self._cur_vel
				else
					self._cur_vel = math_max(mvec3_length(delta_pos) / dt, self._start_max_vel)
				end

				mvec3_set(self._last_pos, new_pos)

				local new_rot = temp_rot1

				mrot_set_yaw_pitch_roll(new_rot, self._start_run_turn[1] + self._start_run_turn[2] * math_clamp((seg_rel_t - self._start_run_turn.start_seg_rel_t) / 0.77, 0, 1), 0, 0)
				self._ext_movement:set_rotation(new_rot)
			else
				self._start_run_turn.start_seg_rel_t = self._machine:segment_relative_time(idstr_base)
			end
		else
			if self._end_of_path then
				if self._next_is_nav_link then
					self._start_run = nil

					self:_set_updator("_upd_nav_link_first_frame")
					self:update(t)

					return
				elseif self._persistent then
					self._start_run = nil

					self:_set_updator("_upd_wait")
				else
					self._expired = true

					if self._end_rot then
						self._ext_movement:set_rotation(self._end_rot)
					end
				end

				return
			else
				self:_nav_chk_walk(t, dt, self._ext_base:lod_stage() or 4)
			end

			if not self._end_of_curved_path then
				local wanted_fwd = tmp_vec1

				mvec3_direction(wanted_fwd, self._common_data.pos, self._curve_path[self._curve_path_index + 1])
				mvec3_rotate_with(wanted_fwd, self._walk_side_rot[self._start_run_straight])
				mrot_set_look_at(temp_rot1, wanted_fwd, math_up)
				mrot_slerp(temp_rot1, self._common_data.rot, temp_rot1, math_min(1, dt * 5))
				self._ext_movement:set_rotation(temp_rot1)
			end
		end

		self:_set_new_pos(dt)
	else
		self._start_run = nil
		self._start_run_turn = nil

		local old_pos = self._curve_path[1]

		self._curve_path[1] = mvec3_copy(self._common_data.pos)

		mvec3_set(tmp_vec1, self._curve_path[1])
		mvec3_subtract(tmp_vec1, old_pos)

		while self._curve_path[3] do
			mvec3_set(tmp_vec2, self._curve_path[2])
			mvec3_subtract(tmp_vec2, self._curve_path[1])

			if mvec3_dot(tmp_vec1, tmp_vec2) < 0 and not managers.navigation:raycast({
				pos_from = old_pos,
				pos_to = self._curve_path[3]
			}) then
				table_remove(self._curve_path, 2)
			else
				break
			end
		end

		mvec3_set(self._last_pos, self._common_data.pos)

		self._curve_path_index = 1
		self._start_max_vel = nil

		self:_set_updator(nil)
		self:update(t)
	end
end

function CopActionWalk:_set_new_pos(dt)
	local path_pos = self._last_pos
	local path_z = path_pos.z

	self._ext_movement:upd_ground_ray(path_pos, true)

	local gnd_z = math_clamp(self._common_data.gnd_ray.position.z, path_z - 80, path_z + 80)
	local pos_new = tmp_vec1

	mvec3_set(pos_new, path_pos)

	if gnd_z < self._common_data.pos.z then
		mvec3_set_z(pos_new, self._common_data.pos.z)

		self._last_vel_z = self._apply_freefall(pos_new, self._last_vel_z, gnd_z, dt)
	else
		mvec3_set_z(pos_new, gnd_z)

		self._last_vel_z = 0
	end

	self._ext_movement:set_position(pos_new)
end

function CopActionWalk:get_husk_interrupt_desc()
	local old_action_desc = {
		body_part = 2,
		type = "walk",
		path_simplified = true,
		interrupted = self._init_called,
		end_rot = self._end_rot,
		variant = self._haste,
		nav_path = self._simplified_path,
		persistent = self._persistent,
		no_walk = self._no_walk,
		no_strafe = self._no_strafe,
		pose = self._init_called and (self._ext_anim.pose or "stand") or self._action_desc.pose,
		end_pose = self._action_desc.end_pose,
		host_stop_pos_ahead = self._host_stop_pos_ahead
	}

	if self._blocks or self._old_blocks then
		local blocks = {}

		for block_key in pairs(self._old_blocks or self._blocks) do
			blocks[block_key] = -1
		end

		old_action_desc.blocks = blocks
	end

	return old_action_desc
end

function CopActionWalk:on_attention(attention)
	if attention then
		if attention.handler then
			if (managers.groupai:state():enemy_weapons_hot() and REACT_SHOOT or REACT_SURPRISED) <= attention.reaction then
				self._attention_pos = attention.handler:get_attention_m_pos()
			else
				self._attention_pos = nil
			end
		elseif self._common_data.stance.name ~= "ntl" then
			if attention.unit then
				self._attention_pos = attention.unit:movement():m_pos()
			else
				self._attention_pos = nil
			end
		end
	else
		self._attention_pos = nil
	end

	self._attention = attention
end

function CopActionWalk:_get_current_max_walk_speed(move_dir)
	if move_dir == "l" or move_dir == "r" then
		move_dir = "strafe"
	end

	local speed = self._common_data.char_tweak.move_speed[self._ext_anim.pose or self._fallback_pose][self._haste][self._stance.name][move_dir] * (self._unit:brain().is_hostage and self._unit:brain():is_hostage() and self._common_data.char_tweak.hostage_move_speed or 1)

	if not self._sync then
		if self:_husk_needs_speedup() then
			speed = speed * (1 + (Unit.occluded(self._unit) and 1 or CopActionWalk.lod_multipliers[self._ext_base:lod_stage()] or 1))
		elseif not managers.groupai:state():enemy_weapons_hot() then
			speed = speed * tweak_data.network.stealth_speed_boost
		end
	end

	return speed
end

function CopActionWalk:save(save_data)
	if not self._init_called then
		return
	end

	save_data.type = "walk"
	save_data.body_part = self._body_part
	save_data.variant = self._haste
	save_data.end_rot = self._end_rot
	save_data.no_walk = self._no_walk
	save_data.no_strafe = self._no_strafe
	save_data.end_pose = self._action_desc.end_pose
	save_data.persistent = true
	save_data.path_simplified = true
	save_data.blocks = {
		act = -1,
		turn = -1,
		idle = -1,
		walk = -1
	}
	save_data.nav_path = {
		self._nav_point_pos(self._simplified_path[2])
	}
end

function CopActionWalk._calculate_simplified_path(good_pos, original_path, nr_iterations, z_test, apply_padding)
	if good_pos then
		table_insert(original_path, 1, good_pos)
	end

	local original_path_size = #original_path

	if original_path_size > 2 then
		local nr_removed = 0
		local pos_from = original_path[1]

		for i = 2, original_path_size - 1 do
			local nav_point = original_path[i]
			local pos_to = CopActionWalk._nav_point_pos(original_path[i + 1])

			if nav_point.x and math_abs(nav_point.z - pos_from.z + nav_point.z - pos_to.z) < 60 and not managers.navigation:raycast({
				pos_from = pos_from,
				pos_to = pos_to
			}) then
				original_path[i] = nil
				nr_removed = nr_removed + 1
			else
				pos_from = nav_point.x and nav_point or nav_point.c_class:end_position()

				if nr_removed > 0 then
					original_path[i], original_path[i - nr_removed] = nil, nav_point
				end
			end
		end

		if nr_removed > 0 then
			original_path[original_path_size], original_path[original_path_size - nr_removed] = nil, original_path[original_path_size]
		end

		if original_path_size - nr_removed > 2 then
			if apply_padding then
				CopActionWalk._apply_padding_to_simplified_path(original_path)
				CopActionWalk._calculate_shortened_path(original_path)
			end

			if nr_iterations > 1 then
				CopActionWalk._calculate_simplified_path(nil, original_path, nr_iterations - 1, z_test, apply_padding)
			end
		end
	end
end

function CopActionWalk:_nav_chk_walk(t, dt, vis_state)
	local s_path = self._simplified_path
	local c_path = self._curve_path
	local c_index = self._curve_path_index
	local vel

	if self._ext_anim.act and self._ext_anim.walk then
		vel = mvec3_length(self._unit:get_animation_delta_position()) / dt

		if vel == 0 then
			return
		end
	else
		vel = self:_get_current_max_walk_speed(self._ext_anim.move_side or "fwd")
	end

	local walk_dis = vel * dt
	local cur_pos = self._common_data.pos
	local nav_advanced
	local new_pos
	local unused_8 -- unused, kept for bytecode parity
	local unused_9 -- unused, kept for bytecode parity
	local upd_footstep

	while not self._end_of_curved_path do
		local new_c_index, complete

		new_pos, new_c_index, complete = self._walk_spline(c_path, self._last_pos, c_index, walk_dis + 200)
		upd_footstep = true

		if complete then
			if #s_path == 2 then
				self._end_of_curved_path = true

				if self._end_rot and not self._persistent then
					self._curve_path_end_rot = Rotation(mrot_yaw(self._common_data.rot), 0, 0)
				end

				nav_advanced = true

				break
			elseif self._next_is_nav_link then
				self._end_of_curved_path = true
				self._nav_link_rot = Rotation(self._next_is_nav_link.element:value("rotation"), 0, 0)
				self._curve_path_end_rot = Rotation(mrot_yaw(self._common_data.rot), 0, 0)

				break
			else
				self:_advance_simplified_path()

				local next_pos = self._nav_point_pos(s_path[2])

				if self._sync and not self._action_desc.path_simplified and not self._next_is_nav_link and s_path[3] then
					self:_reserve_nav_pos(next_pos, self._nav_point_pos(s_path[3]), c_path[#c_path], vel)
				end

				local new_c_path

				if vis_state == 1 and flat_distance_sq(s_path[1], next_pos) > 490000 then
					mvec3_set(tmp_vec1, s_path[1])
					mvec3_subtract(tmp_vec1, c_path[#c_path - 1])
					mvec3_set_z(tmp_vec1, 0)
					mvec3_normalize(tmp_vec1)

					new_c_path = self:_calculate_curved_path(s_path, 1, 1, tmp_vec1)
				else
					new_c_path = {
						s_path[1],
						next_pos
					}
				end

				for i = #c_path - 1, c_index, -1 do
					table_insert(new_c_path, 1, c_path[i])
				end

				self._curve_path = new_c_path
				self._curve_path_index = 1
				c_path = self._curve_path
				c_index = 1

				if self._sync then
					self:_send_nav_point(next_pos)
				end

				nav_advanced = true
			end
		else
			break
		end
	end

	if upd_footstep then
		mvec3_set(self._footstep_pos, new_pos)
	end

	if self._start_run then
		walk_dis = mvec3_length(self._common_data.unit:get_animation_delta_position())
		self._cur_vel = math_min(self:_get_current_max_walk_speed(self._ext_anim.move_side or "fwd"), math_max(walk_dis / dt, self._start_max_vel))

		if self._cur_vel < self._start_max_vel then
			self._cur_vel = self._start_max_vel
			walk_dis = self._cur_vel * dt
		else
			self._start_max_vel = self._cur_vel
		end
	else
		local wanted_vel = vel

		if self._turn_vel then
			local dis = flat_distance_sq(c_path[c_index + 1], cur_pos)

			if dis < 4900 then
				wanted_vel = math_lerp(self._turn_vel, vel, dis / 4900)
			end
		end

		if self._cur_vel ~= wanted_vel then
			self._cur_vel = math_step(self._cur_vel, wanted_vel, vel * (wanted_vel > self._cur_vel and 1.5 or 4) * dt)
		end

		walk_dis = self._cur_vel * dt
	end

	local new_pos, new_c_index, complete = self._walk_spline(c_path, self._last_pos, c_index, walk_dis)

	if complete then
		if self._next_is_nav_link then
			self._end_of_path = true

			if self._sync and alive(self._next_is_nav_link.c_class) and self._next_is_nav_link.element:nav_link_delay() then
				self._next_is_nav_link.c_class:set_delay_time(t + self._next_is_nav_link.element:nav_link_delay())
			end
		elseif #s_path == 2 then
			self._end_of_path = true
		end
	elseif new_c_index ~= self._curve_path_index or nav_advanced then
		local future_pos = c_path[new_c_index + 2]
		local next_pos = c_path[new_c_index + 1]

		if future_pos then
			local cur_vec = tmp_vec2

			mvec3_set(cur_vec, next_pos)
			mvec3_subtract(cur_vec, c_path[new_c_index])
			mvec3_set_z(cur_vec, 0)
			mvec3_normalize(cur_vec)

			local next_vec = tmp_vec1

			mvec3_set(next_vec, future_pos)
			mvec3_subtract(next_vec, next_pos)
			mvec3_set_z(next_vec, 0)

			local future_dis_flat = mvec3_normalize(next_vec)
			local next_dot = mvec3_dot(cur_vec, next_vec)

			if self._haste ~= "run" and math_abs(next_dot) < 0.7 and not self._attention_pos and future_dis_flat > 80 and self._common_data.stance.name == "ntl" and mvec3_dot(self._common_data.fwd, cur_vec) > 0.97 then
				self._turn_vel = nil
				self._walk_turn = true
			else
				self._turn_vel = math_lerp(math_min(vel, 100), self:_get_current_max_walk_speed(self._ext_anim.move_side or "fwd"), next_dot^2)
				self._walk_turn = nil
			end
		else
			if (not self._persistent and #s_path == 2 or self._next_is_nav_link and self._next_is_nav_link.element:nav_link_wants_align_pos()) and not self._NO_RUN_STOP and self._haste == "run" and flat_distance_sq(new_pos, next_pos) >= 14400 then
				self._chk_stop_dis = 210
			end

			self._turn_vel = nil
			self._walk_turn = nil
		end
	end

	self._curve_path_index = new_c_index

	mvec3_set(self._last_pos, new_pos)
end

function CopActionWalk._walk_spline(path, pos, index, walk_dis)
	if walk_dis >= 0 then
		while true do
			mvec3_set(tmp_vec1, path[index + 1])
			mvec3_subtract(tmp_vec1, path[index])
			mvec3_set_z(tmp_vec1, 0)

			local dis = mvec3_normalize(tmp_vec1)

			mvec3_set(tmp_vec2, pos)
			mvec3_subtract(tmp_vec2, path[index])
			mvec3_set_z(tmp_vec2, 0)

			local my_dis = mvec3_dot(tmp_vec1, tmp_vec2) + walk_dis

			if dis == 0 or dis <= my_dis then
				if index == #path - 1 then
					return path[index + 1], index, true
				else
					index = index + 1
				end
			else
				mvec3_lerp(tmp_vec5, path[index], path[index + 1], my_dis / dis)

				return tmp_vec5, index
			end
		end
	else
		while true do
			mvec3_set(tmp_vec1, path[index])
			mvec3_subtract(tmp_vec1, path[index + 1])
			mvec3_set_z(tmp_vec1, 0)

			local dis = mvec3_normalize(tmp_vec1)

			mvec3_set(tmp_vec2, pos)
			mvec3_subtract(tmp_vec2, path[index + 1])
			mvec3_set_z(tmp_vec2, 0)

			local my_dis = mvec3_dot(tmp_vec1, tmp_vec2) - walk_dis

			if dis == 0 or dis <= my_dis then
				if index == 1 then
					return path[index + 1], index
				else
					index = index - 1
				end
			else
				mvec3_lerp(tmp_vec5, path[index + 1], path[index], my_dis / dis)

				return tmp_vec5, index
			end
		end
	end
end

function CopActionWalk:_reserve_nav_pos(nav_pos, next_pos, from_pos, vel)
	local step_vec = tmp_vec1

	mvec3_set(step_vec, nav_pos)
	mvec3_subtract(step_vec, self._common_data.pos)
	mvec3_set_z(step_vec, 0)

	local dis = mvec3_length(step_vec)

	mvec3_cross(step_vec, step_vec, math_up)
	mvec3_set_length(step_vec, 65)

	local step_clbk = callback(self, self, "_reserve_pos_step_clbk", {
		step_mul = 1,
		nr_attempts = 0,
		start_pos = nav_pos,
		fwd_pos = next_pos,
		bwd_pos = from_pos,
		step_vec = step_vec
	})
	local res_pos = managers.navigation:reserve_pos(TimerManager:game():time() + dis / vel, 1, nav_pos, step_clbk, 40, self._ext_movement:pos_rsrv_id())

	if res_pos then
		mvec3_set(nav_pos, res_pos.position)

		return true
	end
end

function CopActionWalk:_adjust_move_anim(side, speed)
	local anim_data = self._ext_anim

	if anim_data[speed] and (not anim_data.haste or anim_data.haste == speed) and anim_data["move_" .. side] then
		return
	end

	local enter_t
	local move_side = anim_data.move_side

	if move_side and (side == move_side or self._matching_walk_anims[side][move_side]) then
		enter_t = self._machine:segment_relative_time(idstr_base) * self._walk_anim_lengths[anim_data.pose or self._fallback_pose][self._stance.name][speed][side]
	end

	return self._ext_movement:play_redirect(speed .. "_" .. side, enter_t)
end

function CopActionWalk:get_walk_to_pos()
	local next_point = self._simplified_path and self._simplified_path[2]

	return next_point and self._nav_point_pos(next_point)
end

function CopActionWalk:_upd_wait(t)
	if self._ext_anim.move then
		self:_stop_walk()
	end

	if not self._end_of_curved_path or not self._persistent then
		self._curve_path_index = 1

		self:_chk_start_anim(self._nav_point_pos(self._simplified_path[2]))

		if self._start_run then
			self:_set_updator("_upd_start_anim_first_frame")
		else
			self:_set_updator(nil)
		end

		if not self._start_run_turn and self._ext_base:lod_stage() == 1 and flat_distance_sq(self._simplified_path[1], self._nav_point_pos(self._simplified_path[2])) > 160000 then
			self._curve_path = self:_calculate_curved_path(self._simplified_path, 1, 1, self._common_data.fwd)
		else
			self._curve_path = {
				self._simplified_path[1],
				self._nav_point_pos(self._simplified_path[2])
			}
		end

		self._cur_vel = 0
	end
end

local stop_anim_progress_curves = {
	stand = {
		fwd = function(p)
			return (math_clamp(p, 0, 0.6) / 0.6)^0.8
		end,
		bwd = function(p)
			local p_clamped = math_clamp(p, 0, 0.8) / 0.8

			return p_clamped < 0.9 and 0.97 * (1 - (0.9 - p_clamped) / 0.9) or 0.97 + 0.03 * (p_clamped - 0.9) / 0.1
		end,
		l = function(p)
			local p_clamped = math_clamp(p, 0, 0.75) / 0.75

			return p_clamped < 0.6 and 0.8 * p_clamped / 0.6 or 0.8 + 0.19999999999999996 * (p_clamped - 0.6) / 0.4
		end,
		r = function(p)
			local p_clamped = math_clamp(p, 0, 0.8) / 0.8

			return p_clamped < 0.85 and 0.9 * (1 - (0.85 - p_clamped) / 0.85) or 0.9 + 0.1 * (p_clamped - 0.85) / 0.15
		end
	},
	crouch = {
		fwd = function(p)
			return (math_clamp(p, 0, 0.4) / 0.4)^0.85
		end,
		bwd = function(p)
			return (math_clamp(p, 0, 0.4) / 0.4)^0.85
		end,
		l = function(p)
			return (math_clamp(p, 0, 0.3) / 0.3)^0.85
		end,
		r = function(p)
			return (math_clamp(p, 0, 0.6) / 0.6)^0.85
		end
	}
}

function CopActionWalk:_upd_stop_anim_first_frame(t)
	local redir_res = self._ext_movement:play_redirect("run_stop_" .. self._stop_anim_side)

	if not redir_res then
		return
	end

	local pose = self._ext_anim.pose or self._fallback_pose
	local pose_velocities = self._walk_anim_velocities[pose]
	local stance_velocities = pose_velocities and pose_velocities[self._stance.name]
	local haste_velocities = stance_velocities and stance_velocities[self._haste]

	if not haste_velocities then
		return
	end

	self._machine:set_speed(redir_res, self:_get_current_max_walk_speed(self._stop_anim_side) / haste_velocities[self._stop_anim_side])

	self._stop_anim_init_pos = mvec3_copy(self._last_pos)
	self._stop_anim_end_pos = self._nav_point_pos(self._simplified_path[2])
	self._chk_stop_dis = nil

	self:_set_updator("_upd_stop_anim")

	self._stop_anim_displacement_f = stop_anim_progress_curves[pose][self._stop_anim_side]

	self:update(t)
end

function CopActionWalk:_upd_stop_anim(t)
	local dt = TimerManager:game():delta_time()
	local rot_new = temp_rot1
	local stop_fwd = tmp_vec1

	if not self._nav_link_rot and not self._end_rot and self._attention_pos then
		mvec3_direction(stop_fwd, self._common_data.pos, self._attention_pos)
	else
		stop_fwd = self._stop_anim_fwd
	end

	mrot_set_look_at(rot_new, stop_fwd, math_up)
	mrot_slerp(rot_new, self._common_data.rot, rot_new, math_min(1, dt * 5))
	self._ext_movement:set_rotation(rot_new)

	if self._ext_anim.run_stop then
		mvec3_lerp(self._last_pos, self._stop_anim_init_pos, self._stop_anim_end_pos, self._stop_anim_displacement_f(self._machine:segment_relative_time(idstr_base)))
	else
		if self._next_is_nav_link then
			self:_set_updator("_upd_nav_link_first_frame")
			self:update(t)
		elseif self._persistent then
			self:_set_updator("_upd_wait")
		else
			self._expired = true

			if self._end_rot then
				self._ext_movement:set_rotation(self._end_rot)
			end
		end

		mvec3_set(self._last_pos, self._stop_anim_end_pos)

		self._stop_anim_displacement_f = nil
		self._stop_anim_end_pos = nil
		self._stop_anim_fwd = nil
		self._stop_anim_init_pos = nil
		self._stop_anim_side = nil
		self._stop_dis = nil
	end

	self:_set_new_pos(dt)
end

local updators_not_started = {
	_upd_wait = true,
	_upd_start_anim_first_frame = true,
	_upd_start_anim = true
}
local updators_cannot_shorten = {
	_upd_nav_link_blend_to_idle = true,
	_upd_nav_link = true,
	_upd_walk_turn = true,
	_upd_stop_anim_first_frame = true,
	_upd_walk_turn_first_frame = true,
	_upd_nav_link_first_frame = true,
	_upd_stop_anim = true
}

function CopActionWalk:stop()
	local end_pos = self._simplified_path[#self._simplified_path]

	self._persistent = false

	if self._init_called then
		if updators_not_started[self._updator] then
			self._end_of_curved_path = nil
			self._end_of_path = nil
		elseif not self._next_is_nav_link then
			self._end_of_curved_path = nil
		end

		if #self._simplified_path >= 3 and not updators_cannot_shorten[self._updator] and math_abs(self._common_data.pos.z - end_pos.z) < 100 and not managers.navigation:raycast({
			tracker_from = self._common_data.nav_tracker,
			pos_to = end_pos
		}) then
			self._next_is_nav_link = nil
			self._end_of_curved_path = nil
			self._end_of_path = nil
			self._walk_turn = nil
			self._curve_path_index = 1

			local stop_pos = mvec3_copy(self._common_data.pos)

			self._curve_path = {
				stop_pos,
				end_pos
			}
			self._simplified_path = {
				stop_pos,
				end_pos
			}
		end
	end

	for i = 2, #self._simplified_path - 2 do
		local nav_point = self._simplified_path[i]

		if nav_point.x and math_abs(nav_point.z - end_pos.z) < 100 and not managers.navigation:raycast({
			pos_from = nav_point,
			pos_to = end_pos
		}) then
			self._simplified_path[i + 1] = end_pos

			for i_clear = i + 2, #self._simplified_path do
				self._simplified_path[i_clear] = nil
			end

			break
		end
	end
end

function CopActionWalk:append_nav_point(nav_point)
	if not nav_point.x then
		function nav_point.element.value(element, key)
			return element[key]
		end

		function nav_point.element.nav_link_wants_align_pos(element)
			return element.from_idle
		end
	end

	table_insert(self._simplified_path, nav_point)

	if not nav_point.x and #self._simplified_path == 2 then
		self._next_is_nav_link = nav_point
	end

	if self._init_called then
		if updators_not_started[self._updator] then
			self._end_of_curved_path = nil
			self._end_of_path = nil
		elseif not self._next_is_nav_link then
			self._end_of_curved_path = nil
		end
	end
end

function CopActionWalk:_play_nav_link_anim(t)
	local nav_link = self._next_is_nav_link

	self._old_blocks = self._blocks

	self:_set_blocks(self._anim_block_presets.block_all)

	local nav_link_rot = temp_rot1

	mrot_set_yaw_pitch_roll(nav_link_rot, nav_link.element:value("rotation"), 0, 0)
	self._ext_movement:set_rotation(nav_link_rot)
	mvec3_set(self._last_pos, nav_link.element:value("position"))

	self._next_is_nav_link = nil
	self._end_of_curved_path = nil
	self._end_of_path = nil
	self._curve_path_end_rot = nil
	self._nav_link_rot = nil

	self:_advance_simplified_path()

	if self._ext_movement:play_redirect(nav_link.element:value("so_action")) then
		self._nav_link = nav_link

		if self._nav_link_invul and not self._nav_link_invul_on then
			self._common_data.ext_damage:set_invulnerable(true)

			self._nav_link_invul_on = true
		end

		if self._sync then
			self:_send_nav_point(self._simplified_path[1])
		end

		self:_set_updator("_upd_nav_link")
		self._common_data.unit:set_driving("animation")

		self._changed_driving = true

		if self._blocks.action then
			self._ext_movement:action_request({
				type = "idle",
				client_interrupt = true,
				body_part = 3,
				non_persistent = true
			})
		end
	else
		self._simplified_path[1] = mvec3_copy(self._common_data.pos)

		self:_set_new_pos(TimerManager:game():delta_time())

		if self._sync then
			if alive(nav_link.c_class) then
				table_insert(self._simplified_path, 2, nav_link.c_class:end_position())

				self._next_is_nav_link = nil
			end

			self:_send_nav_point(self._nav_point_pos(self._simplified_path[2]))
		end

		self._cur_vel = 0

		self:_set_blocks(self._old_blocks)

		self._old_blocks = nil

		if self._simplified_path[2] then
			self:_chk_start_anim(self._nav_point_pos(self._simplified_path[2]))

			if self._start_run then
				self:_set_updator("_upd_start_anim_first_frame")
			else
				self:_set_updator(nil)
			end

			if not self._start_run_turn and self._ext_base:lod_stage() == 1 and flat_distance_sq(self._simplified_path[1], self._nav_point_pos(self._simplified_path[2])) > 160000 then
				self._curve_path = self:_calculate_curved_path(self._simplified_path, 1, 1, self._common_data.fwd)
			else
				self._curve_path = {
					self._simplified_path[1],
					self._nav_point_pos(self._simplified_path[2])
				}
			end

			self._curve_path_index = 1

			self:update(t)
		else
			self._end_of_curved_path = true

			self:_set_updator("_upd_wait")
		end
	end
end

function CopActionWalk:_upd_nav_link(t)
	if self._ext_anim.act and not self._ext_anim.walk then
		self._last_pos = self._unit:position()

		self._ext_movement:set_m_pos(self._last_pos)
		self._ext_movement:set_m_rot(self._unit:rotation())
	else
		self._simplified_path[1] = mvec3_copy(self._common_data.pos)

		self._common_data.unit:set_driving("script")

		self._changed_driving = nil

		local nav_link = self._nav_link

		if self._sync then
			if alive(nav_link.c_class) and managers.navigation:raycast({
				tracker_from = self._common_data.nav_tracker,
				pos_to = self._nav_point_pos(self._simplified_path[2])
			}) then
				table_insert(self._simplified_path, 2, nav_link.c_class:end_position())

				self._next_is_nav_link = nil
			elseif not self._next_is_nav_link then
				self._calculate_simplified_path(nil, self._simplified_path, 1, true, true)

				if not self._simplified_path[2].x then
					self._next_is_nav_link = self._simplified_path[2]
				end
			end

			self:_send_nav_point(self._nav_point_pos(self._simplified_path[2]))
		end

		if self._nav_link_invul_on then
			self._nav_link_invul_on = nil

			self._common_data.ext_damage:set_invulnerable(false)
		end

		self._nav_link = nil
		self._cur_vel = 0
		self._last_vel_z = 0

		self:_set_blocks(self._old_blocks)

		self._old_blocks = nil

		self:_chk_correct_pose()

		if self._simplified_path[2] then
			if nav_link.element:nav_link_wants_align_pos() then
				self:_chk_start_anim(self._nav_point_pos(self._simplified_path[2]))
			end

			if self._start_run then
				self:_set_updator("_upd_start_anim_first_frame")
			else
				self:_set_updator(nil)
			end

			if not self._start_run_turn and self._ext_base:lod_stage() == 1 and flat_distance_sq(self._simplified_path[1], self._nav_point_pos(self._simplified_path[2])) > 160000 then
				self._curve_path = self:_calculate_curved_path(self._simplified_path, 1, 1, self._common_data.fwd)
			else
				self._curve_path = {
					self._simplified_path[1],
					self._nav_point_pos(self._simplified_path[2])
				}
			end

			self._curve_path_index = 1

			self:update(t)
		else
			self._end_of_curved_path = true

			self:_set_updator("_upd_wait")
		end
	end
end

function CopActionWalk:_upd_walk_turn_first_frame(t)
	local next_pos = self._curve_path[self._curve_path_index + 1]
	local future_pos = self._curve_path[self._curve_path_index + 2]

	if not next_pos or not future_pos then
		self._walk_turn = nil

		self:_set_updator(nil)
		self:update(t)

		return
	end

	mvec3_set(tmp_vec2, future_pos)
	mvec3_subtract(tmp_vec2, next_pos)

	local seg_rel_t = self._machine:segment_relative_time(idstr_base)
	local left_foot = seg_rel_t < 0.25 or seg_rel_t > 0.75
	local redir_res = self._ext_movement:play_redirect("walk_turn_" .. (mvec3_dot(self._common_data.right, tmp_vec2) > 0 and "r_" or "l_") .. (left_foot and "lf" or "rf"))

	if redir_res then
		self._cur_vel = self:_get_current_max_walk_speed("fwd")

		self._machine:set_speed(redir_res, self._cur_vel / self._walk_anim_velocities.stand.ntl.walk.fwd)
		self._common_data.unit:set_driving("animation")

		self._changed_driving = true
		self._curve_path_index = self._curve_path_index + 1

		if not left_foot then
			self._walk_turn_blend_to_middle = true
		end

		self:_set_updator("_upd_walk_turn")
	else
		self._walk_turn = nil

		self:_set_updator(nil)
		self:update(t)
	end
end

function CopActionWalk:_upd_walk_turn(t)
	if self._ext_anim.walk_turn then
		self._last_pos = self._unit:position()

		self._ext_movement:set_m_pos(self._last_pos)
		self:_set_new_pos(TimerManager:game():delta_time())
		self._ext_movement:set_m_rot(self._unit:rotation())
	else
		if self._walk_turn_blend_to_middle then
			self._machine:set_animation_time_all_segments(0.5)
		end

		self._common_data.unit:set_driving("script")

		self._changed_driving = nil

		local c_index = self._curve_path_index + 2

		while c_index < #self._curve_path do
			if not managers.navigation:raycast({
				pos_from = self._common_data.pos,
				pos_to = self._curve_path[c_index]
			}) then
				table_remove(self._curve_path, c_index - 1)
			else
				break
			end
		end

		self._curve_path[self._curve_path_index] = mvec3_copy(self._common_data.pos)
		self._walk_turn = nil
		self._walk_turn_blend_to_middle = nil

		self:_set_updator(nil)
		self:update(t)
	end
end

function CopActionWalk:_set_updator(name)
	self.update = self[name]
	self._updator = name

	if not name then
		self._last_upd_t = TimerManager:game():time() - 0.001
	end
end

function CopActionWalk:on_nav_link_unregistered(element_id)
	if self._next_is_nav_link and self._next_is_nav_link.element._id == element_id then
		self._ext_movement:action_request({
			body_part = 2,
			type = "idle"
		})
	else
		for i = 1, #self._simplified_path do
			local nav_point = self._simplified_path[i]

			if not nav_point.x and (nav_point.element and nav_point.element:id() or nav_point:script_data().element:id()) == element_id then
				self._ext_movement:action_request({
					body_part = 2,
					type = "idle"
				})

				return
			end
		end
	end
end

Hooks:PostHook(CopActionWalk, "_advance_simplified_path", "RDAI_advance_simplified_path", function(self)
	if self._nav_seg and (#self._simplified_path == 2 or managers.navigation:get_nav_seg_from_pos(self._nav_point_pos(self._simplified_path[1]), false) == self._nav_seg) then
		self._nav_seg = nil
		self._intermediate_action_complete = true

		self._unit:brain():action_complete_clbk(self)

		self._intermediate_action_complete = false
	end
end)

function CopActionWalk:_husk_needs_speedup()
	if self._was_interrupted or self._ext_movement._queued_actions and next_g(self._ext_movement._queued_actions) then
		return true
	elseif #self._simplified_path > 2 then
		local prev_pos = self._common_data.pos
		local dis_error_total = 0

		for i = 2, #self._simplified_path do
			local next_pos = self._nav_point_pos(self._simplified_path[i])

			dis_error_total = dis_error_total + flat_distance(prev_pos, next_pos)

			if dis_error_total > 300 then
				return true
			end

			prev_pos = next_pos
		end
	end
end

function CopActionWalk:_chk_correct_pose()
	local pose = self._ext_anim.pose
	local allowed_poses = self._common_data.char_tweak.allowed_poses

	if not allowed_poses then
		return
	end

	if not pose then
		self._ext_movement:action_request({
			no_sync = true,
			body_part = 4,
			type = allowed_poses.stand and "stand" or "crouch"
		})

		return
	end

	if not allowed_poses[pose] then
		self._ext_movement:action_request({
			no_sync = true,
			body_part = 4,
			type = opposite_pose[pose]
		})
	end

	if pose == "crouch" and self._common_data.is_cool then
		self._ext_movement:action_request({
			no_sync = true,
			body_part = 4,
			type = "stand"
		})
	end
end
