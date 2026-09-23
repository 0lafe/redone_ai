local var_0_0 = Idstring("base")
local var_0_1 = mrotation.set_look_at
local var_0_2 = mrotation.set_yaw_pitch_roll
local var_0_3 = mrotation.slerp
local var_0_4 = mrotation.yaw
local var_0_5 = mvector3.add
local var_0_6 = mvector3.bezier
local var_0_7 = mvector3.copy
local var_0_8 = mvector3.cross
local var_0_9 = mvector3.dot
local var_0_10 = mvector3.direction
local var_0_11 = mvector3.distance
local var_0_12 = mvector3.distance_sq
local var_0_13 = mvector3.length
local var_0_14 = mvector3.lerp
local var_0_15 = mvector3.multiply
local var_0_16 = mvector3.normalize
local var_0_17 = mvector3.rotate_with
local var_0_18 = mvector3.set
local var_0_19 = mvector3.set_length
local var_0_20 = mvector3.set_z
local var_0_21 = mvector3.subtract
local var_0_22 = math.abs
local var_0_23 = math.ceil
local var_0_24 = math.clamp
local var_0_25 = math.lerp
local var_0_26 = math.max
local var_0_27 = math.min
local var_0_28 = math.step
local var_0_29 = math.UP
local var_0_30 = next
local var_0_31 = AIAttentionObject.REACT_SHOOT
local var_0_32 = AIAttentionObject.REACT_SURPRISED
local var_0_33 = table.insert
local var_0_34 = table.remove
local var_0_35 = Rotation()
local var_0_36 = Vector3()
local var_0_37 = Vector3()
local var_0_38 = Vector3()
local var_0_39 = Vector3()
local var_0_40 = Vector3()
local var_0_41 = Vector3()

local function var_0_42(arg_1_0, arg_1_1)
	var_0_18(var_0_41, arg_1_0)
	var_0_20(var_0_41, arg_1_1.z)

	return var_0_11(var_0_41, arg_1_1)
end

local function var_0_43(arg_2_0, arg_2_1)
	var_0_18(var_0_41, arg_2_0)
	var_0_20(var_0_41, arg_2_1.z)

	return var_0_12(var_0_41, arg_2_1)
end

function CopActionWalk.init(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0._common_data = arg_3_2
	arg_3_0._action_desc = arg_3_1
	arg_3_0._unit = arg_3_2.unit
	arg_3_0._ext_movement = arg_3_2.ext_movement
	arg_3_0._ext_anim = arg_3_2.ext_anim
	arg_3_0._ext_base = arg_3_2.ext_base
	arg_3_0._ext_network = arg_3_2.ext_network
	arg_3_0._body_part = arg_3_1.body_part

	arg_3_0:_init_ik()

	arg_3_0._machine = arg_3_2.machine

	arg_3_0:on_attention(arg_3_2.attention)

	arg_3_0._stance = arg_3_2.stance
	arg_3_0._last_vel_z = 0
	arg_3_0._cur_vel = 0
	arg_3_0._end_rot = arg_3_1.end_rot

	CopActionAct._create_blocks_table(arg_3_0, arg_3_1.blocks)

	arg_3_0._persistent = arg_3_1.persistent
	arg_3_0._haste = arg_3_1.variant
	arg_3_0._start_t = TimerManager:game():time()
	arg_3_0._no_walk = arg_3_1.no_walk
	arg_3_0._no_strafe = arg_3_1.no_strafe
	arg_3_0._last_pos = var_0_7(arg_3_2.pos)
	arg_3_0._footstep_pos = var_0_7(arg_3_2.pos)
	arg_3_0._NO_RUN_START = arg_3_2.char_tweak.no_run_start
	arg_3_0._NO_RUN_STOP = arg_3_2.char_tweak.no_run_stop
	arg_3_0._simplified_path = arg_3_1.nav_path
	arg_3_0._host_stop_pos_ahead = arg_3_1.host_stop_pos_ahead
	arg_3_0._last_upd_t = arg_3_0._start_t - 0.001
	arg_3_0._sync = Network:is_server()
	arg_3_0._skipped_frames = 1

	if arg_3_0._ext_anim.needs_idle then
		arg_3_0._waiting_full_blend = true

		arg_3_0:_set_updator("_upd_wait_for_full_blend")

		if arg_3_0._sync then
			arg_3_0._unit:brain():add_pos_rsrv("move_dest", {
				radius = 30,
				position = var_0_7(arg_3_0._simplified_path[#arg_3_0._simplified_path])
			})

			local var_3_0 = arg_3_0._unit:brain():get_pos_rsrv("stand")

			if not var_3_0 or var_0_12(var_3_0.position, arg_3_2.pos) > 400 then
				arg_3_0._unit:brain():add_pos_rsrv("stand", {
					radius = 30,
					position = var_0_7(arg_3_2.pos)
				})
			end
		end
	elseif not arg_3_0:_init() then
		return
	end

	arg_3_0._ext_movement:enable_update()

	return true
end

function CopActionWalk._init(arg_4_0)
	if not arg_4_0:_sanitize() then
		return
	end

	local var_4_0 = arg_4_0._simplified_path
	local var_4_1 = arg_4_0._action_desc
	local var_4_2 = arg_4_0._common_data

	if arg_4_0._sync then
		if managers.groupai:state():all_AI_criminals()[var_4_2.unit:key()] then
			arg_4_0._nav_link_invul = true
		end

		for iter_4_0 = 1, #var_4_0 do
			local var_4_3 = var_4_0[iter_4_0]

			if var_4_3.x then
				var_4_0[iter_4_0] = var_0_7(var_4_3)
			elseif alive(var_4_3) then
				var_4_0[iter_4_0] = {
					element = var_4_3:script_data().element,
					c_class = var_4_3
				}
			else
				return false
			end
		end

		if not var_4_1.path_simplified then
			arg_4_0._calculate_simplified_path(var_0_7(var_4_2.pos), var_4_0, 2, true, true)
		end
	else
		for iter_4_1 = 1, #var_4_0 do
			local var_4_4 = var_4_0[iter_4_1]

			if not var_4_4.x then
				function var_4_4.element.value(arg_5_0, arg_5_1)
					return arg_5_0[arg_5_1]
				end

				function var_4_4.element.nav_link_wants_align_pos(arg_6_0)
					return arg_6_0.from_idle
				end
			end
		end

		if var_4_1.interrupted then
			var_4_0[1] = var_0_7(var_4_2.pos)
		else
			var_0_33(var_4_0, 1, var_0_7(var_4_2.pos))
		end

		local var_4_5 = var_4_0[2] and arg_4_0._nav_point_pos(var_4_0[2])

		if not var_4_5 or not arg_4_0._host_stop_pos_ahead and managers.navigation:raycast({
			tracker_from = var_4_2.nav_tracker,
			pos_to = var_4_5
		}) then
			var_0_33(var_4_0, 2, var_0_7(arg_4_0._ext_movement:m_host_stop_pos()))

			arg_4_0._host_stop_pos_ahead = true
		end
	end

	if not var_4_0[2].x then
		arg_4_0._next_is_nav_link = var_4_0[2]
	end

	arg_4_0._curve_path_index = 1

	arg_4_0:_chk_start_anim(arg_4_0._nav_point_pos(var_4_0[2]))

	if arg_4_0._start_run then
		arg_4_0:_set_updator("_upd_start_anim_first_frame")
	end

	if not arg_4_0._start_run_turn and arg_4_0._ext_base:lod_stage() == 1 and var_0_43(var_4_0[1], arg_4_0._nav_point_pos(var_4_0[2])) > 160000 then
		arg_4_0._curve_path = arg_4_0:_calculate_curved_path(var_4_0, 1, 1, var_4_2.fwd)
	else
		arg_4_0._curve_path = {
			var_4_0[1],
			arg_4_0._nav_point_pos(var_4_0[2])
		}
	end

	if arg_4_0._next_is_nav_link and arg_4_0._next_is_nav_link.element:nav_link_wants_align_pos() and #arg_4_0._curve_path == 2 and not arg_4_0._NO_RUN_STOP and arg_4_0._haste == "run" and var_0_43(arg_4_0._curve_path[1], arg_4_0._curve_path[2]) >= 14400 then
		arg_4_0._chk_stop_dis = 210
	end

	if arg_4_0._sync then
		local var_4_6 = 0

		if arg_4_0._end_rot then
			local var_4_7 = arg_4_0._end_rot:yaw()

			if var_4_7 < 0 then
				var_4_7 = 360 + var_4_7
			end

			var_4_6 = 1 + var_0_23(var_4_7 * 254 / 360)
		end

		arg_4_0._ext_network:send("action_walk_start", arg_4_0._nav_point_pos(var_4_0[2]), 1, 0, false, arg_4_0._haste == "walk" and 1 or 2, var_4_6, arg_4_0._no_walk and true or false, arg_4_0._no_strafe and true or false, not var_4_1.pose and 0 or var_4_1.pose == "stand" and 1 or 2, not var_4_1.end_pose and 0 or var_4_1.end_pose == "stand" and 1 or 2)
		arg_4_0._unit:brain():rem_pos_rsrv("stand")
		arg_4_0._unit:brain():add_pos_rsrv("move_dest", {
			radius = 30,
			position = var_0_7(var_4_0[#var_4_0])
		})
	end

	arg_4_0._init_called = true

	return true
end

function CopActionWalk.append_path(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0._end_of_path and not arg_7_0._next_is_nav_link or arg_7_0._action_desc.path_simplified or arg_7_0:stopping() then
		return false
	end

	local var_7_0 = arg_7_0._simplified_path

	for iter_7_0 = 1, #arg_7_1 do
		local var_7_1 = arg_7_1[iter_7_0]

		if var_7_1.x then
			arg_7_1[iter_7_0] = var_0_7(var_7_1)
		elseif alive(var_7_1) then
			arg_7_1[iter_7_0] = {
				element = var_7_1:script_data().element,
				c_class = var_7_1
			}
		else
			return false
		end
	end

	for iter_7_1 = 1, #arg_7_1 do
		var_0_33(var_7_0, arg_7_1[iter_7_1])
	end

	if var_7_0[1].x then
		var_7_0[1] = var_0_7(arg_7_0._common_data.pos)
	else
		var_7_0[1] = var_7_0[1].c_class:end_position()
	end

	arg_7_0._calculate_simplified_path(nil, var_7_0, 2, true, true)

	if #var_7_0 == 2 then
		var_0_33(var_7_0, 2, arg_7_1[1])
	end

	if arg_7_0._curve_path and not managers.navigation:raycast({
		pos_from = var_7_0[1],
		pos_to = arg_7_0._nav_point_pos(var_7_0[2])
	}) then
		if not arg_7_0._start_run_turn and arg_7_0._ext_base:lod_stage() == 1 and var_0_43(var_7_0[1], arg_7_0._nav_point_pos(var_7_0[2])) > 490000 then
			var_0_18(var_0_36, arg_7_0._curve_path[arg_7_0._curve_path_index + 1])
			var_0_21(var_0_36, arg_7_0._curve_path[arg_7_0._curve_path_index])
			var_0_20(var_0_36, 0)
			var_0_16(var_0_36)

			arg_7_0._curve_path = arg_7_0:_calculate_curved_path(var_7_0, 1, 1, var_0_36)
		else
			arg_7_0._curve_path = {
				var_7_0[1],
				arg_7_0._nav_point_pos(var_7_0[2])
			}
		end

		arg_7_0._curve_path_index = 1
	end

	if not var_7_0[2].x then
		arg_7_0._next_is_nav_link = var_7_0[2]
	end

	arg_7_0._end_of_curved_path = nil
	arg_7_0._chk_stop_dis = nil
	arg_7_0._nav_seg = arg_7_2

	arg_7_0._unit:brain():add_pos_rsrv("move_dest", {
		radius = 30,
		position = var_0_7(var_7_0[#var_7_0])
	})

	return true
end

local var_0_44 = {
	crouch = "stand",
	stand = "crouch"
}

function CopActionWalk._sanitize(arg_8_0)
	local var_8_0 = arg_8_0._ext_anim

	if not var_8_0.pose then
		arg_8_0._ext_movement:play_redirect("idle")

		if not var_8_0.pose and not arg_8_0._ext_movement:play_state("std/stand/still/idle/look") then
			return
		end
	end

	local var_8_1 = var_8_0.pose
	local var_8_2 = arg_8_0._action_desc.pose

	if var_8_2 and not var_8_0[var_8_2] and arg_8_0._walk_anim_lengths[var_8_2] then
		arg_8_0._ext_movement:play_redirect(var_8_2)
	elseif not arg_8_0._walk_anim_lengths[var_8_1] then
		arg_8_0._ext_movement:play_redirect(var_0_44[var_8_1])
	end

	return true
end

function CopActionWalk._chk_start_anim(arg_9_0, arg_9_1)
	if arg_9_0._haste ~= "run" or arg_9_0._NO_RUN_START or (arg_9_0._ext_base:lod_stage() or 4) > 2 then
		return
	end

	local var_9_0 = true
	local var_9_1 = var_0_36

	var_0_18(var_9_1, arg_9_1)
	var_0_21(var_9_1, arg_9_0._common_data.pos)
	var_0_20(var_9_1, 0)

	local var_9_2 = var_0_16(var_9_1)

	if arg_9_0._attention_pos then
		local var_9_3 = var_0_37

		var_0_18(var_9_3, arg_9_0._attention_pos)
		var_0_21(var_9_3, arg_9_0._common_data.pos)
		var_0_20(var_9_3, 0)
		var_0_16(var_9_3)

		if var_0_9(var_9_1, var_9_3) < 0.7 then
			var_9_0 = false
		end
	end

	if var_9_0 then
		local var_9_4 = var_9_1:to_polar_with_reference(arg_9_0._common_data.fwd, var_0_29).spin

		if var_0_22(var_9_4) > 135 then
			if var_0_13(arg_9_0._anim_movement[arg_9_0._ext_anim.pose].run_start_turn_bwd.ds) < var_9_2 - 100 then
				if var_9_4 > 0 then
					var_9_4 = var_9_4 - 360
				end

				arg_9_0._start_run_turn = {
					arg_9_0._common_data.rot:yaw(),
					var_9_4,
					"bwd"
				}
			end
		elseif var_9_4 < -65 then
			if var_0_13(arg_9_0._anim_movement[arg_9_0._ext_anim.pose].run_start_turn_r.ds) < var_9_2 - 100 then
				arg_9_0._start_run_turn = {
					arg_9_0._common_data.rot:yaw(),
					var_9_4,
					"r"
				}
			end
		elseif var_9_4 > 65 and var_0_13(arg_9_0._anim_movement[arg_9_0._ext_anim.pose].run_start_turn_l.ds) < var_9_2 - 100 then
			arg_9_0._start_run_turn = {
				arg_9_0._common_data.rot:yaw(),
				var_9_4,
				"l"
			}
		end
	end

	arg_9_0._start_run = true

	if not arg_9_0._root_blend_disabled then
		arg_9_0._root_blend_disabled = true

		arg_9_0._ext_movement:set_root_blend(false)
	end

	if not arg_9_0._start_run_turn then
		local var_9_5 = var_0_9(var_9_1, arg_9_0._common_data.right)
		local var_9_6 = var_0_9(var_9_1, arg_9_0._common_data.fwd)

		if var_0_22(var_9_5) < var_0_22(var_9_6) then
			arg_9_0._start_run_straight = var_9_6 > 0 and "fwd" or "bwd"
		else
			arg_9_0._start_run_straight = var_9_5 > 0 and "r" or "l"
		end
	end
end

function CopActionWalk._calculate_shortened_path(arg_10_0)
	local var_10_0 = var_0_36

	for iter_10_0 = 2, #arg_10_0 - 1 do
		if arg_10_0[iter_10_0].x then
			local var_10_1 = arg_10_0[iter_10_0 - 1]

			var_0_14(var_10_0, var_10_1.x and var_10_1 or var_10_1.c_class:end_position(), arg_10_0[iter_10_0], 0.8)

			if not managers.navigation:raycast({
				pos_from = var_10_0,
				pos_to = CopActionWalk._nav_point_pos(arg_10_0[iter_10_0 + 1])
			}) then
				var_0_18(arg_10_0[iter_10_0], var_10_0)
			end
		end
	end
end

local var_0_45 = {
	Vector3(212.132, 212.132, 0),
	Vector3(212.132, -212.132, 0)
}

function CopActionWalk._apply_padding_to_simplified_path(arg_11_0)
	local var_11_0 = var_0_36
	local var_11_1 = var_0_37

	for iter_11_0 = 2, #arg_11_0 - 1 do
		local var_11_2 = arg_11_0[iter_11_0]

		if var_11_2.x then
			for iter_11_1 = 1, #var_0_45 do
				local var_11_3 = var_0_45[iter_11_1]

				var_0_18(var_11_1, var_11_2)
				var_0_5(var_11_1, var_11_3)

				local var_11_4, var_11_5 = CopActionWalk._chk_shortcut_pos_to_pos(var_11_2, var_11_1, true)

				var_0_18(var_11_0, var_11_5[1])
				var_0_18(var_11_1, var_11_2)
				var_0_15(var_11_3, -1)
				var_0_5(var_11_1, var_11_3)

				local var_11_6, var_11_7 = CopActionWalk._chk_shortcut_pos_to_pos(var_11_2, var_11_1, true)

				var_0_14(var_11_0, var_11_0, var_11_7[1], 0.5)

				local var_11_8 = arg_11_0[iter_11_0 - 1]

				if not managers.navigation:raycast({
					pos_from = var_11_0,
					pos_to = CopActionWalk._nav_point_pos(arg_11_0[iter_11_0 + 1])
				}) and not managers.navigation:raycast({
					pos_from = var_11_8.x and var_11_8 or var_11_8.c_class:end_position(),
					pos_to = var_11_0
				}) then
					var_0_18(var_11_2, var_11_0)
				end
			end
		end
	end
end

function CopActionWalk._calculate_curved_path(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local var_12_0 = arg_12_1[arg_12_2]
	local var_12_1 = arg_12_0._nav_point_pos(arg_12_1[arg_12_2 + 1])
	local var_12_2
	local var_12_3
	local var_12_4 = {
		var_12_0
	}
	local var_12_5 = var_0_42(var_12_1, var_12_0)
	local var_12_6 = var_0_36
	local var_12_7 = var_0_37
	local var_12_8 = 2

	if arg_12_4 then
		var_12_8 = 3

		var_0_18(var_12_6, arg_12_4)
		var_0_19(var_12_6, var_12_5)
		var_0_18(var_12_7, var_12_1)
		var_0_21(var_12_7, var_12_0)
		var_0_19(var_12_7, var_12_5 * arg_12_3)
		var_0_5(var_12_6, var_12_7)
		var_0_20(var_12_6, 0)
		var_0_19(var_12_6, var_12_5 * 0.3)

		var_12_2 = var_0_38

		var_0_18(var_12_2, var_12_0)
		var_0_5(var_12_2, var_12_6)
	end

	if var_12_2 and arg_12_1[arg_12_2 + 2] then
		var_12_8 = var_12_8 + 1

		var_0_18(var_12_6, var_12_1)
		var_0_21(var_12_6, arg_12_0._nav_point_pos(arg_12_1[arg_12_2 + 2]))
		var_0_19(var_12_6, var_12_5)
		var_0_18(var_12_7, var_12_0)
		var_0_21(var_12_7, var_12_2)
		var_0_19(var_12_7, var_12_5 * arg_12_3)
		var_0_5(var_12_6, var_12_7)
		var_0_20(var_12_6, 0)
		var_0_19(var_12_6, var_12_5 * 0.3)

		var_12_3 = var_0_39

		var_0_18(var_12_3, var_12_1)
		var_0_5(var_12_3, var_12_6)
	end

	if var_12_8 > 2 then
		local var_12_9 = var_12_4[1]

		for iter_12_0 = 1, 6 do
			local var_12_10 = var_0_36

			if var_12_8 == 3 then
				var_0_6(var_12_10, var_12_0, var_12_2 or var_12_3, var_12_1, iter_12_0 / 7)
			else
				var_0_6(var_12_10, var_12_0, var_12_2, var_12_3, var_12_1, iter_12_0 / 7)
			end

			if managers.navigation:raycast({
				pos_from = var_12_9,
				pos_to = var_12_10
			}) then
				return arg_12_3 < 1 and {
					var_12_4[1],
					var_12_1
				} or arg_12_0:_calculate_curved_path(arg_12_1, arg_12_2, 0.5, arg_12_4)
			end

			var_12_9 = var_0_7(var_12_10)

			var_0_33(var_12_4, var_12_9)
		end

		if managers.navigation:raycast({
			pos_from = var_12_9,
			pos_to = var_12_1
		}) then
			return arg_12_3 < 1 and {
				var_12_4[1],
				var_12_1
			} or arg_12_0:_calculate_curved_path(arg_12_1, arg_12_2, 0.5, arg_12_4)
		end

		var_0_33(var_12_4, var_12_1)
	else
		var_0_33(var_12_4, var_12_1)
	end

	return var_12_4
end

function CopActionWalk.on_exit(arg_13_0)
	if arg_13_0._expired and arg_13_0._end_rot then
		arg_13_0._ext_movement:set_rotation(arg_13_0._end_rot)
	end

	if arg_13_0._root_blend_disabled then
		arg_13_0._ext_movement:set_root_blend(true)
	end

	if arg_13_0._changed_driving then
		arg_13_0._common_data.unit:set_driving("script")
	end

	if arg_13_0._expired and arg_13_0._ext_anim.move then
		arg_13_0:_stop_walk()
	end

	arg_13_0._ext_movement:drop_held_items()

	if arg_13_0._sync then
		if arg_13_0._init_called then
			if not arg_13_0._expired then
				arg_13_0._ext_network:send("action_walk_nav_point", var_0_7(arg_13_0._ext_movement:m_pos()))
			end

			arg_13_0._ext_network:send("action_walk_stop")
		end

		arg_13_0._unit:brain():rem_pos_rsrv("move_dest")
	else
		arg_13_0._ext_movement:set_m_host_stop_pos(arg_13_0._ext_movement:m_pos())
	end

	if arg_13_0._nav_link_invul_on then
		arg_13_0._common_data.ext_damage:set_invulnerable(false)
	end
end

function CopActionWalk._upd_wait_for_full_blend(arg_14_0, arg_14_1)
	if arg_14_0._ext_anim.needs_idle and not arg_14_0._ext_anim.to_idle then
		if not arg_14_0._ext_movement:play_redirect("idle") then
			return
		end

		arg_14_0._ext_movement:spawn_wanted_items()
	end

	if not arg_14_0._ext_anim.to_idle and arg_14_0._ext_anim.idle_full_blend then
		arg_14_0._waiting_full_blend = nil

		if arg_14_0:_init() then
			arg_14_0._ext_movement:drop_held_items()

			if arg_14_0._updator == "_upd_wait_for_full_blend" then
				arg_14_0:_set_updator(nil)
			end
		else
			arg_14_0._ext_movement:action_request({
				body_part = 2,
				type = "idle"
			})
		end
	else
		arg_14_0._ext_movement:set_m_rot(arg_14_0._unit:rotation())
		arg_14_0._ext_movement:set_m_pos(arg_14_0._unit:position())
	end
end

function CopActionWalk.update(arg_15_0, arg_15_1)
	if arg_15_0._ik_update then
		arg_15_0._ik_update(arg_15_1)
	end

	local var_15_0
	local var_15_1 = arg_15_0._ext_base:lod_stage() or 4

	if var_15_1 == 1 then
		var_15_0 = arg_15_1 - arg_15_0._last_upd_t
		arg_15_0._last_upd_t = TimerManager:game():time()
	elseif var_15_1 > arg_15_0._skipped_frames then
		arg_15_0._skipped_frames = arg_15_0._skipped_frames + 1

		return
	else
		arg_15_0._skipped_frames = 1
		var_15_0 = arg_15_1 - arg_15_0._last_upd_t
		arg_15_0._last_upd_t = TimerManager:game():time()
	end

	local var_15_2 = arg_15_0._ext_anim

	if arg_15_0._end_of_path and (not var_15_2.act or not var_15_2.walk) then
		if arg_15_0._next_is_nav_link then
			arg_15_0:_set_updator("_upd_nav_link_first_frame")
			arg_15_0:update(arg_15_1)

			return
		elseif arg_15_0._persistent then
			arg_15_0:_set_updator("_upd_wait")
		else
			arg_15_0._expired = true

			if arg_15_0._end_rot then
				arg_15_0._ext_movement:set_rotation(arg_15_0._end_rot)
			end
		end
	else
		arg_15_0:_nav_chk_walk(arg_15_1, var_15_0, var_15_1)
	end

	if arg_15_0._cur_vel < 0.1 or var_15_2.act and var_15_2.walk then
		-- block empty
	elseif not arg_15_0._expired then
		local var_15_3 = var_0_38

		var_0_18(var_15_3, arg_15_0._last_pos)
		var_0_21(var_15_3, arg_15_0._common_data.pos)
		var_0_20(var_15_3, 0)
		var_0_16(var_15_3)

		local var_15_4

		if arg_15_0._no_strafe or arg_15_0._walk_turn then
			var_15_4 = "fwd"
		else
			local var_15_5 = var_0_36

			if arg_15_0._curve_path_end_rot and var_0_43(arg_15_0._last_pos, arg_15_0._footstep_pos) < 19600 then
				var_0_18(var_15_5, arg_15_0._common_data.fwd)
			else
				if arg_15_0._attention_pos then
					var_0_18(var_15_5, arg_15_0._attention_pos)
					var_0_21(var_15_5, arg_15_0._common_data.pos)
				elseif arg_15_0._footstep_pos then
					var_0_18(var_15_5, arg_15_0._footstep_pos)
					var_0_21(var_15_5, arg_15_0._common_data.pos)
				end

				var_0_20(var_15_5, 0)
				var_0_16(var_15_5)
			end

			local var_15_6 = var_0_37

			var_0_8(var_15_6, var_15_5, var_0_29)

			local var_15_7 = var_0_9(var_15_3, var_15_6)
			local var_15_8 = var_0_9(var_15_3, var_15_5)

			if var_0_22(var_15_7) < var_0_22(var_15_8) then
				if (var_15_2.move_l and var_15_7 < 0 or var_15_2.move_r and var_15_7 > 0) and var_0_22(var_15_8) < 0.73 then
					var_15_4 = var_15_2.move_side
				elseif var_15_8 > 0 then
					var_15_4 = "fwd"
				else
					var_15_4 = "bwd"
				end
			elseif (var_15_2.move_fwd and var_15_8 > 0 or var_15_2.move_bwd and var_15_8 < 0) and var_0_22(var_15_7) < 0.73 then
				var_15_4 = var_15_2.move_side
			else
				var_15_4 = var_15_7 > 0 and "r" or "l"
			end
		end

		local var_15_9 = var_0_35

		if arg_15_0._curve_path_end_rot then
			var_0_3(var_15_9, arg_15_0._curve_path_end_rot, arg_15_0._nav_link_rot or arg_15_0._end_rot, 1 - var_0_27(1, var_0_42(arg_15_0._last_pos, arg_15_0._footstep_pos) / 140))
		else
			local var_15_10 = var_0_36

			var_0_18(var_15_10, var_15_3)
			var_0_17(var_15_10, arg_15_0._walk_side_rot[var_15_4])
			var_0_1(var_15_9, var_15_10, var_0_29)
			var_0_3(var_15_9, arg_15_0._common_data.rot, var_15_9, var_0_27(1, var_15_0 * 5))
		end

		arg_15_0._ext_movement:set_rotation(var_15_9)

		if arg_15_0._chk_stop_dis then
			local var_15_11 = var_0_42(arg_15_0._last_pos, arg_15_0._nav_point_pos(arg_15_0._simplified_path[2]))

			if var_15_11 < arg_15_0._chk_stop_dis then
				local var_15_12 = arg_15_0._action_desc.end_pose

				if var_15_12 and not arg_15_0._next_is_nav_link then
					if var_15_12 ~= var_15_2.pose then
						arg_15_0._ext_movement:action_request({
							syncless = true,
							body_part = 4,
							type = var_15_12
						})
					end
				else
					var_15_12 = arg_15_0._ext_anim.pose
				end

				if var_15_1 < 3 and arg_15_0._ext_anim.run then
					local var_15_13 = arg_15_0._nav_link_rot and arg_15_0._nav_link_rot:y() or arg_15_0._end_rot and arg_15_0._end_rot:y() or var_15_3:rotate_with(arg_15_0._walk_side_rot[var_15_4])
					local var_15_14 = var_0_38

					var_0_8(var_15_14, var_15_3, var_0_29)

					local var_15_15 = var_0_9(var_15_13, var_15_3)
					local var_15_16 = var_0_9(var_15_13, var_15_14)
					local var_15_17
					local var_15_18 = var_0_22(var_15_16) < var_0_22(var_15_15) and (var_15_15 > 0 and "fwd" or "bwd") or var_15_16 > 0 and "l" or "r"
					local var_15_19 = arg_15_0._anim_movement[var_15_12]["run_stop_" .. var_15_18]

					if var_15_19 and var_15_11 < var_15_19 then
						arg_15_0._stop_anim_side = var_15_18
						arg_15_0._stop_anim_fwd = var_15_13
						arg_15_0._stop_dis = var_15_19

						arg_15_0:_set_updator("_upd_stop_anim_first_frame")
					end
				end
			end
		elseif arg_15_0._walk_turn and var_0_43(arg_15_0._last_pos, arg_15_0._curve_path[arg_15_0._curve_path_index + 1]) < 2025 then
			arg_15_0:_set_updator("_upd_walk_turn_first_frame")
		end

		local var_15_20 = arg_15_0._walk_anim_velocities[arg_15_0._stance.values[4] > 0 and "wounded" or var_15_2.pose or "stand"][arg_15_0._stance.name]
		local var_15_21 = arg_15_0._cur_vel
		local var_15_22 = arg_15_0._haste

		if var_15_22 == "run" then
			if var_15_2.sprint then
				if var_15_21 > 480 and var_15_2.pose == "stand" then
					var_15_22 = "sprint"
				elseif var_15_21 > 250 then
					var_15_22 = "run"
				elseif not arg_15_0._no_walk then
					var_15_22 = "walk"
				end
			elseif var_15_2.run then
				if var_15_21 > 530 and var_15_20.sprint and var_15_2.pose == "stand" then
					var_15_22 = "sprint"
				elseif var_15_21 > 250 then
					var_15_22 = "run"
				elseif not arg_15_0._no_walk then
					var_15_22 = "walk"
				end
			elseif var_15_21 > 530 and var_15_20.sprint and var_15_2.pose == "stand" then
				var_15_22 = "sprint"
			elseif var_15_21 > 300 then
				var_15_22 = "run"
			elseif not arg_15_0._no_walk then
				var_15_22 = "walk"
			end
		end

		arg_15_0:_adjust_move_anim(var_15_4, var_15_22)
		arg_15_0:_adjust_walk_anim_speed(var_15_0, var_15_21 / var_15_20[var_15_22][var_15_4])
	end

	arg_15_0:_set_new_pos(var_15_0)
end

function CopActionWalk._upd_start_anim_first_frame(arg_16_0, arg_16_1)
	arg_16_0:_start_move_anim(arg_16_0._start_run_turn and arg_16_0._start_run_turn[3] or arg_16_0._start_run_straight, "run", arg_16_0:_get_current_max_walk_speed("fwd") / arg_16_0._walk_anim_velocities[arg_16_0._ext_anim.pose or "stand"][arg_16_0._stance.name][arg_16_0._haste].fwd, arg_16_0._start_run_turn)

	arg_16_0._start_max_vel = 0

	arg_16_0:_set_updator("_upd_start_anim")
	arg_16_0._ext_base:chk_freeze_anims()
end

function CopActionWalk._upd_start_anim(arg_17_0, arg_17_1)
	if arg_17_0._ext_anim.run_start then
		local var_17_0 = TimerManager:game():delta_time()

		if arg_17_0._start_run_turn then
			if arg_17_0._ext_anim.run_start_full_blend then
				local var_17_1 = arg_17_0._machine:segment_relative_time(var_0_0)

				if not arg_17_0._start_run_turn.start_seg_rel_t then
					arg_17_0._start_run_turn.start_seg_rel_t = var_17_1
				end

				local var_17_2 = arg_17_0._common_data.unit:get_animation_delta_position()
				local var_17_3 = var_0_36

				var_0_18(var_17_3, arg_17_0._common_data.pos)
				var_0_5(var_17_3, var_17_2)

				local var_17_4 = {
					trace = true,
					allow_entry = true,
					tracker_from = arg_17_0._common_data.nav_tracker,
					pos_to = var_17_3
				}

				if managers.navigation:raycast(var_17_4) then
					var_17_3 = var_17_4.trace[1]

					local var_17_5 = var_0_36

					var_0_18(var_17_5, var_17_3)
					var_0_21(var_17_5, arg_17_0._last_pos)
					var_0_20(var_17_5, 0)

					arg_17_0._cur_vel = var_0_13(var_17_5) / var_17_0
					arg_17_0._start_max_vel = arg_17_0._cur_vel
				else
					arg_17_0._cur_vel = var_0_26(var_0_13(var_17_2) / var_17_0, arg_17_0._start_max_vel)
				end

				var_0_18(arg_17_0._last_pos, var_17_3)

				local var_17_6 = var_0_35

				var_0_2(var_17_6, arg_17_0._start_run_turn[1] + arg_17_0._start_run_turn[2] * var_0_24((var_17_1 - arg_17_0._start_run_turn.start_seg_rel_t) / 0.77, 0, 1), 0, 0)
				arg_17_0._ext_movement:set_rotation(var_17_6)
			else
				arg_17_0._start_run_turn.start_seg_rel_t = arg_17_0._machine:segment_relative_time(var_0_0)
			end
		else
			if arg_17_0._end_of_path then
				if arg_17_0._next_is_nav_link then
					arg_17_0._start_run = nil

					arg_17_0:_set_updator("_upd_nav_link_first_frame")
					arg_17_0:update(arg_17_1)

					return
				elseif arg_17_0._persistent then
					arg_17_0._start_run = nil

					arg_17_0:_set_updator("_upd_wait")
				else
					arg_17_0._expired = true

					if arg_17_0._end_rot then
						arg_17_0._ext_movement:set_rotation(arg_17_0._end_rot)
					end
				end

				return
			else
				arg_17_0:_nav_chk_walk(arg_17_1, var_17_0, arg_17_0._ext_base:lod_stage() or 4)
			end

			if not arg_17_0._end_of_curved_path then
				local var_17_7 = var_0_36

				var_0_10(var_17_7, arg_17_0._common_data.pos, arg_17_0._curve_path[arg_17_0._curve_path_index + 1])
				var_0_17(var_17_7, arg_17_0._walk_side_rot[arg_17_0._start_run_straight])
				var_0_1(var_0_35, var_17_7, var_0_29)
				var_0_3(var_0_35, arg_17_0._common_data.rot, var_0_35, var_0_27(1, var_17_0 * 5))
				arg_17_0._ext_movement:set_rotation(var_0_35)
			end
		end

		arg_17_0:_set_new_pos(var_17_0)
	else
		arg_17_0._start_run = nil
		arg_17_0._start_run_turn = nil

		local var_17_8 = arg_17_0._curve_path[1]

		arg_17_0._curve_path[1] = var_0_7(arg_17_0._common_data.pos)

		var_0_18(var_0_36, arg_17_0._curve_path[1])
		var_0_21(var_0_36, var_17_8)

		while arg_17_0._curve_path[3] do
			var_0_18(var_0_37, arg_17_0._curve_path[2])
			var_0_21(var_0_37, arg_17_0._curve_path[1])

			if var_0_9(var_0_36, var_0_37) < 0 and not managers.navigation:raycast({
				pos_from = var_17_8,
				pos_to = arg_17_0._curve_path[3]
			}) then
				var_0_34(arg_17_0._curve_path, 2)
			else
				break
			end
		end

		var_0_18(arg_17_0._last_pos, arg_17_0._common_data.pos)

		arg_17_0._curve_path_index = 1
		arg_17_0._start_max_vel = nil

		arg_17_0:_set_updator(nil)
		arg_17_0:update(arg_17_1)
	end
end

function CopActionWalk._set_new_pos(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_0._last_pos
	local var_18_1 = var_18_0.z

	arg_18_0._ext_movement:upd_ground_ray(var_18_0, true)

	local var_18_2 = var_0_24(arg_18_0._common_data.gnd_ray.position.z, var_18_1 - 80, var_18_1 + 80)
	local var_18_3 = var_0_36

	var_0_18(var_18_3, var_18_0)

	if var_18_2 < arg_18_0._common_data.pos.z then
		var_0_20(var_18_3, arg_18_0._common_data.pos.z)

		arg_18_0._last_vel_z = arg_18_0._apply_freefall(var_18_3, arg_18_0._last_vel_z, var_18_2, arg_18_1)
	else
		var_0_20(var_18_3, var_18_2)

		arg_18_0._last_vel_z = 0
	end

	arg_18_0._ext_movement:set_position(var_18_3)
end

function CopActionWalk.get_husk_interrupt_desc(arg_19_0)
	local var_19_0 = {
		body_part = 2,
		type = "walk",
		path_simplified = true,
		interrupted = arg_19_0._init_called,
		end_rot = arg_19_0._end_rot,
		variant = arg_19_0._haste,
		nav_path = arg_19_0._simplified_path,
		persistent = arg_19_0._persistent,
		no_walk = arg_19_0._no_walk,
		no_strafe = arg_19_0._no_strafe,
		pose = arg_19_0._init_called and (arg_19_0._ext_anim.pose or "stand") or arg_19_0._action_desc.pose,
		end_pose = arg_19_0._action_desc.end_pose,
		host_stop_pos_ahead = arg_19_0._host_stop_pos_ahead
	}

	if arg_19_0._blocks or arg_19_0._old_blocks then
		local var_19_1 = {}

		for iter_19_0 in pairs(arg_19_0._old_blocks or arg_19_0._blocks) do
			var_19_1[iter_19_0] = -1
		end

		var_19_0.blocks = var_19_1
	end

	return var_19_0
end

function CopActionWalk.on_attention(arg_20_0, arg_20_1)
	if arg_20_1 then
		if arg_20_1.handler then
			if (managers.groupai:state():enemy_weapons_hot() and var_0_31 or var_0_32) <= arg_20_1.reaction then
				arg_20_0._attention_pos = arg_20_1.handler:get_attention_m_pos()
			else
				arg_20_0._attention_pos = nil
			end
		elseif arg_20_0._common_data.stance.name ~= "ntl" then
			if arg_20_1.unit then
				arg_20_0._attention_pos = arg_20_1.unit:movement():m_pos()
			else
				arg_20_0._attention_pos = nil
			end
		end
	else
		arg_20_0._attention_pos = nil
	end

	arg_20_0._attention = arg_20_1
end

function CopActionWalk._get_current_max_walk_speed(arg_21_0, arg_21_1)
	if arg_21_1 == "l" or arg_21_1 == "r" then
		arg_21_1 = "strafe"
	end

	local var_21_0 = arg_21_0._common_data.char_tweak.move_speed[arg_21_0._ext_anim.pose][arg_21_0._haste][arg_21_0._stance.name][arg_21_1] * (arg_21_0._unit:brain().is_hostage and arg_21_0._unit:brain():is_hostage() and arg_21_0._common_data.char_tweak.hostage_move_speed or 1)

	if not arg_21_0._sync then
		if arg_21_0:_husk_needs_speedup() then
			var_21_0 = var_21_0 * (1 + (Unit.occluded(arg_21_0._unit) and 1 or CopActionWalk.lod_multipliers[arg_21_0._ext_base:lod_stage()] or 1))
		elseif not managers.groupai:state():enemy_weapons_hot() then
			var_21_0 = var_21_0 * tweak_data.network.stealth_speed_boost
		end
	end

	return var_21_0
end

function CopActionWalk.save(arg_22_0, arg_22_1)
	if not arg_22_0._init_called then
		return
	end

	arg_22_1.type = "walk"
	arg_22_1.body_part = arg_22_0._body_part
	arg_22_1.variant = arg_22_0._haste
	arg_22_1.end_rot = arg_22_0._end_rot
	arg_22_1.no_walk = arg_22_0._no_walk
	arg_22_1.no_strafe = arg_22_0._no_strafe
	arg_22_1.end_pose = arg_22_0._action_desc.end_pose
	arg_22_1.persistent = true
	arg_22_1.path_simplified = true
	arg_22_1.blocks = {
		act = -1,
		turn = -1,
		idle = -1,
		walk = -1
	}
	arg_22_1.nav_path = {
		arg_22_0._nav_point_pos(arg_22_0._simplified_path[2])
	}
end

function CopActionWalk._calculate_simplified_path(arg_23_0, arg_23_1, arg_23_2, arg_23_3, arg_23_4)
	if arg_23_0 then
		var_0_33(arg_23_1, 1, arg_23_0)
	end

	local var_23_0 = #arg_23_1

	if var_23_0 > 2 then
		local var_23_1 = 0
		local var_23_2 = arg_23_1[1]

		for iter_23_0 = 2, var_23_0 - 1 do
			local var_23_3 = arg_23_1[iter_23_0]
			local var_23_4 = CopActionWalk._nav_point_pos(arg_23_1[iter_23_0 + 1])

			if var_23_3.x and var_0_22(var_23_3.z - var_23_2.z + var_23_3.z - var_23_4.z) < 60 and not managers.navigation:raycast({
				pos_from = var_23_2,
				pos_to = var_23_4
			}) then
				arg_23_1[iter_23_0] = nil
				var_23_1 = var_23_1 + 1
			else
				var_23_2 = var_23_3.x and var_23_3 or var_23_3.c_class:end_position()

				if var_23_1 > 0 then
					arg_23_1[iter_23_0], arg_23_1[iter_23_0 - var_23_1] = nil, var_23_3
				end
			end
		end

		if var_23_1 > 0 then
			arg_23_1[var_23_0], arg_23_1[var_23_0 - var_23_1] = nil, arg_23_1[var_23_0]
		end

		if var_23_0 - var_23_1 > 2 then
			if arg_23_4 then
				CopActionWalk._apply_padding_to_simplified_path(arg_23_1)
				CopActionWalk._calculate_shortened_path(arg_23_1)
			end

			if arg_23_2 > 1 then
				CopActionWalk._calculate_simplified_path(nil, arg_23_1, arg_23_2 - 1, arg_23_3, arg_23_4)
			end
		end
	end
end

function CopActionWalk._nav_chk_walk(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	local var_24_0 = arg_24_0._simplified_path
	local var_24_1 = arg_24_0._curve_path
	local var_24_2 = arg_24_0._curve_path_index
	local var_24_3

	if arg_24_0._ext_anim.act and arg_24_0._ext_anim.walk then
		var_24_3 = var_0_13(arg_24_0._unit:get_animation_delta_position()) / arg_24_2

		if var_24_3 == 0 then
			return
		end
	else
		var_24_3 = arg_24_0:_get_current_max_walk_speed(arg_24_0._ext_anim.move_side or "fwd")
	end

	local var_24_4 = var_24_3 * arg_24_2
	local var_24_5 = arg_24_0._common_data.pos
	local var_24_6
	local var_24_7
	local var_24_8
	local var_24_9
	local var_24_10

	while not arg_24_0._end_of_curved_path do
		local var_24_11, var_24_12

		var_24_7, var_24_11, var_24_12 = arg_24_0._walk_spline(var_24_1, arg_24_0._last_pos, var_24_2, var_24_4 + 200)
		var_24_10 = true

		if var_24_12 then
			if #var_24_0 == 2 then
				arg_24_0._end_of_curved_path = true

				if arg_24_0._end_rot and not arg_24_0._persistent then
					arg_24_0._curve_path_end_rot = Rotation(var_0_4(arg_24_0._common_data.rot), 0, 0)
				end

				var_24_6 = true

				break
			elseif arg_24_0._next_is_nav_link then
				arg_24_0._end_of_curved_path = true
				arg_24_0._nav_link_rot = Rotation(arg_24_0._next_is_nav_link.element:value("rotation"), 0, 0)
				arg_24_0._curve_path_end_rot = Rotation(var_0_4(arg_24_0._common_data.rot), 0, 0)

				break
			else
				arg_24_0:_advance_simplified_path()

				local var_24_13 = arg_24_0._nav_point_pos(var_24_0[2])

				if arg_24_0._sync and not arg_24_0._action_desc.path_simplified and not arg_24_0._next_is_nav_link and var_24_0[3] then
					arg_24_0:_reserve_nav_pos(var_24_13, arg_24_0._nav_point_pos(var_24_0[3]), var_24_1[#var_24_1], var_24_3)
				end

				local var_24_14

				if arg_24_3 == 1 and var_0_43(var_24_0[1], var_24_13) > 490000 then
					var_0_18(var_0_36, var_24_0[1])
					var_0_21(var_0_36, var_24_1[#var_24_1 - 1])
					var_0_20(var_0_36, 0)
					var_0_16(var_0_36)

					var_24_14 = arg_24_0:_calculate_curved_path(var_24_0, 1, 1, var_0_36)
				else
					var_24_14 = {
						var_24_0[1],
						var_24_13
					}
				end

				for iter_24_0 = #var_24_1 - 1, var_24_2, -1 do
					var_0_33(var_24_14, 1, var_24_1[iter_24_0])
				end

				arg_24_0._curve_path = var_24_14
				arg_24_0._curve_path_index = 1
				var_24_1 = arg_24_0._curve_path
				var_24_2 = 1

				if arg_24_0._sync then
					arg_24_0:_send_nav_point(var_24_13)
				end

				var_24_6 = true
			end
		else
			break
		end
	end

	if var_24_10 then
		var_0_18(arg_24_0._footstep_pos, var_24_7)
	end

	if arg_24_0._start_run then
		var_24_4 = var_0_13(arg_24_0._common_data.unit:get_animation_delta_position())
		arg_24_0._cur_vel = var_0_27(arg_24_0:_get_current_max_walk_speed(arg_24_0._ext_anim.move_side or "fwd"), var_0_26(var_24_4 / arg_24_2, arg_24_0._start_max_vel))

		if arg_24_0._cur_vel < arg_24_0._start_max_vel then
			arg_24_0._cur_vel = arg_24_0._start_max_vel
			var_24_4 = arg_24_0._cur_vel * arg_24_2
		else
			arg_24_0._start_max_vel = arg_24_0._cur_vel
		end
	else
		local var_24_15 = var_24_3

		if arg_24_0._turn_vel then
			local var_24_16 = var_0_43(var_24_1[var_24_2 + 1], var_24_5)

			if var_24_16 < 4900 then
				var_24_15 = var_0_25(arg_24_0._turn_vel, var_24_3, var_24_16 / 4900)
			end
		end

		if arg_24_0._cur_vel ~= var_24_15 then
			arg_24_0._cur_vel = var_0_28(arg_24_0._cur_vel, var_24_15, var_24_3 * (var_24_15 > arg_24_0._cur_vel and 1.5 or 4) * arg_24_2)
		end

		var_24_4 = arg_24_0._cur_vel * arg_24_2
	end

	local var_24_17, var_24_18, var_24_19 = arg_24_0._walk_spline(var_24_1, arg_24_0._last_pos, var_24_2, var_24_4)

	if var_24_19 then
		if arg_24_0._next_is_nav_link then
			arg_24_0._end_of_path = true

			if arg_24_0._sync and alive(arg_24_0._next_is_nav_link.c_class) and arg_24_0._next_is_nav_link.element:nav_link_delay() then
				arg_24_0._next_is_nav_link.c_class:set_delay_time(arg_24_1 + arg_24_0._next_is_nav_link.element:nav_link_delay())
			end
		elseif #var_24_0 == 2 then
			arg_24_0._end_of_path = true
		end
	elseif var_24_18 ~= arg_24_0._curve_path_index or var_24_6 then
		local var_24_20 = var_24_1[var_24_18 + 2]
		local var_24_21 = var_24_1[var_24_18 + 1]

		if var_24_20 then
			local var_24_22 = var_0_37

			var_0_18(var_24_22, var_24_21)
			var_0_21(var_24_22, var_24_1[var_24_18])
			var_0_20(var_24_22, 0)
			var_0_16(var_24_22)

			local var_24_23 = var_0_36

			var_0_18(var_24_23, var_24_20)
			var_0_21(var_24_23, var_24_21)
			var_0_20(var_24_23, 0)

			local var_24_24 = var_0_16(var_24_23)
			local var_24_25 = var_0_9(var_24_22, var_24_23)

			if arg_24_0._haste ~= "run" and var_0_22(var_24_25) < 0.7 and not arg_24_0._attention_pos and var_24_24 > 80 and arg_24_0._common_data.stance.name == "ntl" and var_0_9(arg_24_0._common_data.fwd, var_24_22) > 0.97 then
				arg_24_0._turn_vel = nil
				arg_24_0._walk_turn = true
			else
				arg_24_0._turn_vel = var_0_25(var_0_27(var_24_3, 100), arg_24_0:_get_current_max_walk_speed(arg_24_0._ext_anim.move_side or "fwd"), var_24_25^2)
				arg_24_0._walk_turn = nil
			end
		else
			if (not arg_24_0._persistent and #var_24_0 == 2 or arg_24_0._next_is_nav_link and arg_24_0._next_is_nav_link.element:nav_link_wants_align_pos()) and not arg_24_0._NO_RUN_STOP and arg_24_0._haste == "run" and var_0_43(var_24_17, var_24_21) >= 14400 then
				arg_24_0._chk_stop_dis = 210
			end

			arg_24_0._turn_vel = nil
			arg_24_0._walk_turn = nil
		end
	end

	arg_24_0._curve_path_index = var_24_18

	var_0_18(arg_24_0._last_pos, var_24_17)
end

function CopActionWalk._walk_spline(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	if arg_25_3 >= 0 then
		while true do
			var_0_18(var_0_36, arg_25_0[arg_25_2 + 1])
			var_0_21(var_0_36, arg_25_0[arg_25_2])
			var_0_20(var_0_36, 0)

			local var_25_0 = var_0_16(var_0_36)

			var_0_18(var_0_37, arg_25_1)
			var_0_21(var_0_37, arg_25_0[arg_25_2])
			var_0_20(var_0_37, 0)

			local var_25_1 = var_0_9(var_0_36, var_0_37) + arg_25_3

			if var_25_0 == 0 or var_25_0 <= var_25_1 then
				if arg_25_2 == #arg_25_0 - 1 then
					return arg_25_0[arg_25_2 + 1], arg_25_2, true
				else
					arg_25_2 = arg_25_2 + 1
				end
			else
				var_0_14(var_0_40, arg_25_0[arg_25_2], arg_25_0[arg_25_2 + 1], var_25_1 / var_25_0)

				return var_0_40, arg_25_2
			end
		end
	else
		while true do
			var_0_18(var_0_36, arg_25_0[arg_25_2])
			var_0_21(var_0_36, arg_25_0[arg_25_2 + 1])
			var_0_20(var_0_36, 0)

			local var_25_2 = var_0_16(var_0_36)

			var_0_18(var_0_37, arg_25_1)
			var_0_21(var_0_37, arg_25_0[arg_25_2 + 1])
			var_0_20(var_0_37, 0)

			local var_25_3 = var_0_9(var_0_36, var_0_37) - arg_25_3

			if var_25_2 == 0 or var_25_2 <= var_25_3 then
				if arg_25_2 == 1 then
					return arg_25_0[arg_25_2 + 1], arg_25_2
				else
					arg_25_2 = arg_25_2 - 1
				end
			else
				var_0_14(var_0_40, arg_25_0[arg_25_2 + 1], arg_25_0[arg_25_2], var_25_3 / var_25_2)

				return var_0_40, arg_25_2
			end
		end
	end
end

function CopActionWalk._reserve_nav_pos(arg_26_0, arg_26_1, arg_26_2, arg_26_3, arg_26_4)
	local var_26_0 = var_0_36

	var_0_18(var_26_0, arg_26_1)
	var_0_21(var_26_0, arg_26_0._common_data.pos)
	var_0_20(var_26_0, 0)

	local var_26_1 = var_0_13(var_26_0)

	var_0_8(var_26_0, var_26_0, var_0_29)
	var_0_19(var_26_0, 65)

	local var_26_2 = callback(arg_26_0, arg_26_0, "_reserve_pos_step_clbk", {
		step_mul = 1,
		nr_attempts = 0,
		start_pos = arg_26_1,
		fwd_pos = arg_26_2,
		bwd_pos = arg_26_3,
		step_vec = var_26_0
	})
	local var_26_3 = managers.navigation:reserve_pos(TimerManager:game():time() + var_26_1 / arg_26_4, 1, arg_26_1, var_26_2, 40, arg_26_0._ext_movement:pos_rsrv_id())

	if var_26_3 then
		var_0_18(arg_26_1, var_26_3.position)

		return true
	end
end

function CopActionWalk._adjust_move_anim(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_0._ext_anim

	if var_27_0[arg_27_2] and (not var_27_0.haste or var_27_0.haste == arg_27_2) and var_27_0["move_" .. arg_27_1] then
		return
	end

	local var_27_1
	local var_27_2 = var_27_0.move_side

	if var_27_2 and (arg_27_1 == var_27_2 or arg_27_0._matching_walk_anims[arg_27_1][var_27_2]) then
		var_27_1 = arg_27_0._machine:segment_relative_time(var_0_0) * arg_27_0._walk_anim_lengths[var_27_0.pose][arg_27_0._stance.name][arg_27_2][arg_27_1]
	end

	local var_27_3 = var_27_0.can_freeze and (not var_27_0.upper_body_active or var_27_0.upper_body_empty)
	local var_27_4 = arg_27_0._ext_movement:play_redirect(arg_27_2 .. "_" .. arg_27_1, var_27_1)

	if var_27_3 then
		arg_27_0._ext_base:chk_freeze_anims()
	end

	return var_27_4
end

function CopActionWalk.get_walk_to_pos(arg_28_0)
	return arg_28_0._nav_point_pos(arg_28_0._simplified_path[2])
end

function CopActionWalk._upd_wait(arg_29_0, arg_29_1)
	if arg_29_0._ext_anim.move then
		arg_29_0:_stop_walk()
	end

	if not arg_29_0._end_of_curved_path or not arg_29_0._persistent then
		arg_29_0._curve_path_index = 1

		arg_29_0:_chk_start_anim(arg_29_0._nav_point_pos(arg_29_0._simplified_path[2]))

		if arg_29_0._start_run then
			arg_29_0:_set_updator("_upd_start_anim_first_frame")
		else
			arg_29_0:_set_updator(nil)
		end

		if not arg_29_0._start_run_turn and arg_29_0._ext_base:lod_stage() == 1 and var_0_43(arg_29_0._simplified_path[1], arg_29_0._nav_point_pos(arg_29_0._simplified_path[2])) > 160000 then
			arg_29_0._curve_path = arg_29_0:_calculate_curved_path(arg_29_0._simplified_path, 1, 1, arg_29_0._common_data.fwd)
		else
			arg_29_0._curve_path = {
				arg_29_0._simplified_path[1],
				arg_29_0._nav_point_pos(arg_29_0._simplified_path[2])
			}
		end

		arg_29_0._cur_vel = 0
	end
end

local var_0_46 = {
	stand = {
		fwd = function(arg_30_0)
			return (var_0_24(arg_30_0, 0, 0.6) / 0.6)^0.8
		end,
		bwd = function(arg_31_0)
			local var_31_0 = var_0_24(arg_31_0, 0, 0.8) / 0.8

			return var_31_0 < 0.9 and 0.97 * (1 - (0.9 - var_31_0) / 0.9) or 0.97 + 0.03 * (var_31_0 - 0.9) / 0.1
		end,
		l = function(arg_32_0)
			local var_32_0 = var_0_24(arg_32_0, 0, 0.75) / 0.75

			return var_32_0 < 0.6 and 0.8 * var_32_0 / 0.6 or 0.8 + 0.19999999999999996 * (var_32_0 - 0.6) / 0.4
		end,
		r = function(arg_33_0)
			local var_33_0 = var_0_24(arg_33_0, 0, 0.8) / 0.8

			return var_33_0 < 0.85 and 0.9 * (1 - (0.85 - var_33_0) / 0.85) or 0.9 + 0.1 * (var_33_0 - 0.85) / 0.15
		end
	},
	crouch = {
		fwd = function(arg_34_0)
			return (var_0_24(arg_34_0, 0, 0.4) / 0.4)^0.85
		end,
		bwd = function(arg_35_0)
			return (var_0_24(arg_35_0, 0, 0.4) / 0.4)^0.85
		end,
		l = function(arg_36_0)
			return (var_0_24(arg_36_0, 0, 0.3) / 0.3)^0.85
		end,
		r = function(arg_37_0)
			return (var_0_24(arg_37_0, 0, 0.6) / 0.6)^0.85
		end
	}
}

function CopActionWalk._upd_stop_anim_first_frame(arg_38_0, arg_38_1)
	local var_38_0 = arg_38_0._ext_movement:play_redirect("run_stop_" .. arg_38_0._stop_anim_side)

	if not var_38_0 then
		return
	end

	arg_38_0._machine:set_speed(var_38_0, arg_38_0:_get_current_max_walk_speed(arg_38_0._stop_anim_side) / arg_38_0._walk_anim_velocities[arg_38_0._ext_anim.pose][arg_38_0._stance.name][arg_38_0._haste][arg_38_0._stop_anim_side])

	arg_38_0._stop_anim_init_pos = var_0_7(arg_38_0._last_pos)
	arg_38_0._stop_anim_end_pos = arg_38_0._nav_point_pos(arg_38_0._simplified_path[2])
	arg_38_0._chk_stop_dis = nil

	arg_38_0:_set_updator("_upd_stop_anim")

	arg_38_0._stop_anim_displacement_f = var_0_46[arg_38_0._ext_anim.pose][arg_38_0._stop_anim_side]

	arg_38_0._ext_base:chk_freeze_anims()
	arg_38_0:update(arg_38_1)
end

function CopActionWalk._upd_stop_anim(arg_39_0, arg_39_1)
	local var_39_0 = TimerManager:game():delta_time()
	local var_39_1 = var_0_35
	local var_39_2 = var_0_36

	if not arg_39_0._nav_link_rot and not arg_39_0._end_rot and arg_39_0._attention_pos then
		var_0_10(var_39_2, arg_39_0._common_data.pos, arg_39_0._attention_pos)
	else
		var_39_2 = arg_39_0._stop_anim_fwd
	end

	var_0_1(var_39_1, var_39_2, var_0_29)
	var_0_3(var_39_1, arg_39_0._common_data.rot, var_39_1, var_0_27(1, var_39_0 * 5))
	arg_39_0._ext_movement:set_rotation(var_39_1)

	if arg_39_0._ext_anim.run_stop then
		var_0_14(arg_39_0._last_pos, arg_39_0._stop_anim_init_pos, arg_39_0._stop_anim_end_pos, arg_39_0._stop_anim_displacement_f(arg_39_0._machine:segment_relative_time(var_0_0)))
	else
		if arg_39_0._next_is_nav_link then
			arg_39_0:_set_updator("_upd_nav_link_first_frame")
			arg_39_0:update(arg_39_1)
		else
			arg_39_0._expired = true

			if arg_39_0._end_rot then
				arg_39_0._ext_movement:set_rotation(arg_39_0._end_rot)
			end
		end

		var_0_18(arg_39_0._last_pos, arg_39_0._stop_anim_end_pos)

		arg_39_0._stop_anim_displacement_f = nil
		arg_39_0._stop_anim_end_pos = nil
		arg_39_0._stop_anim_fwd = nil
		arg_39_0._stop_anim_init_pos = nil
		arg_39_0._stop_anim_side = nil
		arg_39_0._stop_dis = nil
	end

	arg_39_0:_set_new_pos(var_39_0)
end

local var_0_47 = {
	_upd_wait = true,
	_upd_start_anim_first_frame = true,
	_upd_start_anim = true
}
local var_0_48 = {
	_upd_nav_link_blend_to_idle = true,
	_upd_nav_link = true,
	_upd_walk_turn = true,
	_upd_stop_anim_first_frame = true,
	_upd_walk_turn_first_frame = true,
	_upd_nav_link_first_frame = true,
	_upd_stop_anim = true
}

function CopActionWalk.stop(arg_40_0)
	local var_40_0 = arg_40_0._simplified_path[#arg_40_0._simplified_path]

	arg_40_0._persistent = false

	if arg_40_0._init_called then
		if var_0_47[arg_40_0._updator] then
			arg_40_0._end_of_curved_path = nil
			arg_40_0._end_of_path = nil
		elseif not arg_40_0._next_is_nav_link then
			arg_40_0._end_of_curved_path = nil
		end

		if #arg_40_0._simplified_path >= 3 and not var_0_48[arg_40_0._updator] and var_0_22(arg_40_0._common_data.pos.z - var_40_0.z) < 100 and not managers.navigation:raycast({
			tracker_from = arg_40_0._common_data.nav_tracker,
			pos_to = var_40_0
		}) then
			arg_40_0._next_is_nav_link = nil
			arg_40_0._end_of_curved_path = nil
			arg_40_0._end_of_path = nil
			arg_40_0._walk_turn = nil
			arg_40_0._curve_path_index = 1

			local var_40_1 = var_0_7(arg_40_0._common_data.pos)

			arg_40_0._curve_path = {
				var_40_1,
				var_40_0
			}
			arg_40_0._simplified_path = {
				var_40_1,
				var_40_0
			}
		end
	end

	for iter_40_0 = 2, #arg_40_0._simplified_path - 2 do
		local var_40_2 = arg_40_0._simplified_path[iter_40_0]

		if var_40_2.x and var_0_22(var_40_2.z - var_40_0.z) < 100 and not managers.navigation:raycast({
			pos_from = var_40_2,
			pos_to = var_40_0
		}) then
			arg_40_0._simplified_path[iter_40_0 + 1] = var_40_0

			for iter_40_1 = iter_40_0 + 2, #arg_40_0._simplified_path do
				arg_40_0._simplified_path[iter_40_1] = nil
			end

			break
		end
	end
end

function CopActionWalk.append_nav_point(arg_41_0, arg_41_1)
	if not arg_41_1.x then
		function arg_41_1.element.value(arg_42_0, arg_42_1)
			return arg_42_0[arg_42_1]
		end

		function arg_41_1.element.nav_link_wants_align_pos(arg_43_0)
			return arg_43_0.from_idle
		end
	end

	var_0_33(arg_41_0._simplified_path, arg_41_1)

	if not arg_41_1.x and #arg_41_0._simplified_path == 2 then
		arg_41_0._next_is_nav_link = arg_41_1
	end

	if arg_41_0._init_called then
		if var_0_47[arg_41_0._updator] then
			arg_41_0._end_of_curved_path = nil
			arg_41_0._end_of_path = nil
		elseif not arg_41_0._next_is_nav_link then
			arg_41_0._end_of_curved_path = nil
		end
	end
end

function CopActionWalk._play_nav_link_anim(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_0._next_is_nav_link

	arg_44_0._old_blocks = arg_44_0._blocks

	arg_44_0:_set_blocks(arg_44_0._anim_block_presets.block_all)

	local var_44_1 = var_0_35

	var_0_2(var_44_1, var_44_0.element:value("rotation"), 0, 0)
	arg_44_0._ext_movement:set_rotation(var_44_1)
	var_0_18(arg_44_0._last_pos, var_44_0.element:value("position"))

	arg_44_0._next_is_nav_link = nil
	arg_44_0._end_of_curved_path = nil
	arg_44_0._end_of_path = nil
	arg_44_0._curve_path_end_rot = nil
	arg_44_0._nav_link_rot = nil

	arg_44_0:_advance_simplified_path()

	if arg_44_0._ext_movement:play_redirect(var_44_0.element:value("so_action")) then
		arg_44_0._nav_link = var_44_0

		if arg_44_0._nav_link_invul and not arg_44_0._nav_link_invul_on then
			arg_44_0._common_data.ext_damage:set_invulnerable(true)

			arg_44_0._nav_link_invul_on = true
		end

		if arg_44_0._sync then
			arg_44_0:_send_nav_point(arg_44_0._simplified_path[1])
		end

		arg_44_0:_set_updator("_upd_nav_link")
		arg_44_0._common_data.unit:set_driving("animation")

		arg_44_0._changed_driving = true

		if arg_44_0._blocks.action then
			arg_44_0._ext_movement:action_request({
				type = "idle",
				client_interrupt = true,
				body_part = 3,
				non_persistent = true
			})
		end
	else
		arg_44_0._simplified_path[1] = var_0_7(arg_44_0._common_data.pos)

		arg_44_0:_set_new_pos(TimerManager:game():delta_time())

		if arg_44_0._sync then
			if alive(var_44_0.c_class) then
				var_0_33(arg_44_0._simplified_path, 2, var_44_0.c_class:end_position())

				arg_44_0._next_is_nav_link = nil
			end

			arg_44_0:_send_nav_point(arg_44_0._nav_point_pos(arg_44_0._simplified_path[2]))
		end

		arg_44_0._cur_vel = 0

		arg_44_0:_set_blocks(arg_44_0._old_blocks)

		arg_44_0._old_blocks = nil

		if arg_44_0._simplified_path[2] then
			arg_44_0:_chk_start_anim(arg_44_0._nav_point_pos(arg_44_0._simplified_path[2]))

			if arg_44_0._start_run then
				arg_44_0:_set_updator("_upd_start_anim_first_frame")
			else
				arg_44_0:_set_updator(nil)
			end

			if not arg_44_0._start_run_turn and arg_44_0._ext_base:lod_stage() == 1 and var_0_43(arg_44_0._simplified_path[1], arg_44_0._nav_point_pos(arg_44_0._simplified_path[2])) > 160000 then
				arg_44_0._curve_path = arg_44_0:_calculate_curved_path(arg_44_0._simplified_path, 1, 1, arg_44_0._common_data.fwd)
			else
				arg_44_0._curve_path = {
					arg_44_0._simplified_path[1],
					arg_44_0._nav_point_pos(arg_44_0._simplified_path[2])
				}
			end

			arg_44_0._curve_path_index = 1

			arg_44_0:update(arg_44_1)
		else
			arg_44_0._end_of_curved_path = true

			arg_44_0:_set_updator("_upd_wait")
		end
	end
end

function CopActionWalk._upd_nav_link(arg_45_0, arg_45_1)
	if arg_45_0._ext_anim.act and not arg_45_0._ext_anim.walk then
		arg_45_0._last_pos = arg_45_0._unit:position()

		arg_45_0._ext_movement:set_m_pos(arg_45_0._last_pos)
		arg_45_0._ext_movement:set_m_rot(arg_45_0._unit:rotation())
	else
		arg_45_0._simplified_path[1] = var_0_7(arg_45_0._common_data.pos)

		arg_45_0._common_data.unit:set_driving("script")

		arg_45_0._changed_driving = nil

		local var_45_0 = arg_45_0._nav_link

		if arg_45_0._sync then
			if alive(var_45_0.c_class) and managers.navigation:raycast({
				tracker_from = arg_45_0._common_data.nav_tracker,
				pos_to = arg_45_0._nav_point_pos(arg_45_0._simplified_path[2])
			}) then
				var_0_33(arg_45_0._simplified_path, 2, var_45_0.c_class:end_position())

				arg_45_0._next_is_nav_link = nil
			elseif not arg_45_0._next_is_nav_link then
				arg_45_0._calculate_simplified_path(nil, arg_45_0._simplified_path, 1, true, true)

				if not arg_45_0._simplified_path[2].x then
					arg_45_0._next_is_nav_link = arg_45_0._simplified_path[2]
				end
			end

			arg_45_0:_send_nav_point(arg_45_0._nav_point_pos(arg_45_0._simplified_path[2]))
		end

		if arg_45_0._nav_link_invul_on then
			arg_45_0._nav_link_invul_on = nil

			arg_45_0._common_data.ext_damage:set_invulnerable(false)
		end

		arg_45_0._nav_link = nil
		arg_45_0._cur_vel = 0
		arg_45_0._last_vel_z = 0

		arg_45_0:_set_blocks(arg_45_0._old_blocks)

		arg_45_0._old_blocks = nil

		arg_45_0:_chk_correct_pose()

		if arg_45_0._simplified_path[2] then
			if var_45_0.element:nav_link_wants_align_pos() then
				arg_45_0:_chk_start_anim(arg_45_0._nav_point_pos(arg_45_0._simplified_path[2]))
			end

			if arg_45_0._start_run then
				arg_45_0:_set_updator("_upd_start_anim_first_frame")
			else
				arg_45_0:_set_updator(nil)
			end

			if not arg_45_0._start_run_turn and arg_45_0._ext_base:lod_stage() == 1 and var_0_43(arg_45_0._simplified_path[1], arg_45_0._nav_point_pos(arg_45_0._simplified_path[2])) > 160000 then
				arg_45_0._curve_path = arg_45_0:_calculate_curved_path(arg_45_0._simplified_path, 1, 1, arg_45_0._common_data.fwd)
			else
				arg_45_0._curve_path = {
					arg_45_0._simplified_path[1],
					arg_45_0._nav_point_pos(arg_45_0._simplified_path[2])
				}
			end

			arg_45_0._curve_path_index = 1

			arg_45_0:update(arg_45_1)
		else
			arg_45_0._end_of_curved_path = true

			arg_45_0:_set_updator("_upd_wait")
		end
	end
end

function CopActionWalk._upd_walk_turn_first_frame(arg_46_0, arg_46_1)
	local var_46_0 = arg_46_0._curve_path[arg_46_0._curve_path_index + 1]
	local var_46_1 = arg_46_0._curve_path[arg_46_0._curve_path_index + 2]

	if not var_46_0 or not var_46_1 then
		arg_46_0._walk_turn = nil

		arg_46_0:_set_updator(nil)
		arg_46_0:update(arg_46_1)

		return
	end

	var_0_18(var_0_37, var_46_1)
	var_0_21(var_0_37, var_46_0)

	local var_46_2 = arg_46_0._machine:segment_relative_time(var_0_0)
	local var_46_3 = var_46_2 < 0.25 or var_46_2 > 0.75
	local var_46_4 = arg_46_0._ext_movement:play_redirect("walk_turn_" .. (var_0_9(arg_46_0._common_data.right, var_0_37) > 0 and "r_" or "l_") .. (var_46_3 and "lf" or "rf"))

	if var_46_4 then
		arg_46_0._cur_vel = arg_46_0:_get_current_max_walk_speed("fwd")

		arg_46_0._machine:set_speed(var_46_4, arg_46_0._cur_vel / arg_46_0._walk_anim_velocities.stand.ntl.walk.fwd)
		arg_46_0._common_data.unit:set_driving("animation")

		arg_46_0._changed_driving = true
		arg_46_0._curve_path_index = arg_46_0._curve_path_index + 1

		if not var_46_3 then
			arg_46_0._walk_turn_blend_to_middle = true
		end

		arg_46_0:_set_updator("_upd_walk_turn")
	else
		arg_46_0._walk_turn = nil

		arg_46_0:_set_updator(nil)
		arg_46_0:update(arg_46_1)
	end
end

function CopActionWalk._upd_walk_turn(arg_47_0, arg_47_1)
	if arg_47_0._ext_anim.walk_turn then
		arg_47_0._last_pos = arg_47_0._unit:position()

		arg_47_0._ext_movement:set_m_pos(arg_47_0._last_pos)
		arg_47_0:_set_new_pos(TimerManager:game():delta_time())
		arg_47_0._ext_movement:set_m_rot(arg_47_0._unit:rotation())
	else
		if arg_47_0._walk_turn_blend_to_middle then
			arg_47_0._machine:set_animation_time_all_segments(0.5)
		end

		arg_47_0._common_data.unit:set_driving("script")

		arg_47_0._changed_driving = nil

		local var_47_0 = arg_47_0._curve_path_index + 2

		while var_47_0 < #arg_47_0._curve_path do
			if not managers.navigation:raycast({
				pos_from = arg_47_0._common_data.pos,
				pos_to = arg_47_0._curve_path[var_47_0]
			}) then
				var_0_34(arg_47_0._curve_path, var_47_0 - 1)
			else
				break
			end
		end

		arg_47_0._curve_path[arg_47_0._curve_path_index] = var_0_7(arg_47_0._common_data.pos)
		arg_47_0._walk_turn = nil
		arg_47_0._walk_turn_blend_to_middle = nil

		arg_47_0:_set_updator(nil)
		arg_47_0:update(arg_47_1)
	end
end

function CopActionWalk._set_updator(arg_48_0, arg_48_1)
	arg_48_0.update = arg_48_0[arg_48_1]
	arg_48_0._updator = arg_48_1

	if not arg_48_1 then
		arg_48_0._last_upd_t = TimerManager:game():time() - 0.001
	end
end

function CopActionWalk.on_nav_link_unregistered(arg_49_0, arg_49_1)
	if arg_49_0._next_is_nav_link and arg_49_0._next_is_nav_link.element._id == arg_49_1 then
		arg_49_0._ext_movement:action_request({
			body_part = 2,
			type = "idle"
		})
	else
		for iter_49_0 = 1, #arg_49_0._simplified_path do
			local var_49_0 = arg_49_0._simplified_path[iter_49_0]

			if not var_49_0.x and (var_49_0.element and var_49_0.element:id() or var_49_0:script_data().element:id()) == arg_49_1 then
				arg_49_0._ext_movement:action_request({
					body_part = 2,
					type = "idle"
				})
			end
		end
	end
end

Hooks:PostHook(CopActionWalk, "_advance_simplified_path", "REAI_advance_simplified_path", function(arg_50_0)
	if arg_50_0._nav_seg and (#arg_50_0._simplified_path == 2 or managers.navigation:get_nav_seg_from_pos(arg_50_0._nav_point_pos(arg_50_0._simplified_path[1]), false) == arg_50_0._nav_seg) then
		arg_50_0._nav_seg = nil
		arg_50_0._intermediate_action_complete = true

		arg_50_0._unit:brain():action_complete_clbk(arg_50_0)

		arg_50_0._intermediate_action_complete = false
	end
end)

function CopActionWalk._husk_needs_speedup(arg_51_0)
	if arg_51_0._ext_movement._queued_actions and var_0_30(arg_51_0._ext_movement._queued_actions) then
		return true
	elseif #arg_51_0._simplified_path > 2 then
		local var_51_0 = arg_51_0._common_data.pos
		local var_51_1 = 0

		for iter_51_0 = 2, #arg_51_0._simplified_path do
			local var_51_2 = arg_51_0._nav_point_pos(arg_51_0._simplified_path[iter_51_0])

			var_51_1 = var_51_1 + var_0_42(var_51_0, var_51_2)

			if var_51_1 > 300 then
				return true
			end

			var_51_0 = var_51_2
		end
	end
end

function CopActionWalk._chk_correct_pose(arg_52_0)
	local var_52_0 = arg_52_0._ext_anim.pose
	local var_52_1 = arg_52_0._common_data.char_tweak.allowed_poses

	if not var_52_1 then
		return
	end

	if not var_52_1[var_52_0] then
		arg_52_0._ext_movement:action_request({
			syncless = true,
			body_part = 4,
			type = var_0_44[var_52_0]
		})
	end

	if var_52_0 == "crouch" and arg_52_0._common_data.is_cool then
		arg_52_0._ext_movement:action_request({
			syncless = true,
			body_part = 4,
			type = "stand"
		})
	end
end
