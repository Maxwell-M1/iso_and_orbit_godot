extends "res://tests/check_suite.gd"
## Camera: the follow (smooth, without going past the run, still for a run toward the camera, within the speed limit,
## steady on the stairs, not fooled by a teleport) and its pauses (while RMB is held, after that until the stop or a new
## run, also after looking around on a run, and while it is not yet clear whether it is a click or a hold), the cursor
## keeping its aim while the camera turns, rotation and zoom with the mouse (RMB pitch only with the setting), aligning
## the pitch and the height on the run, gliding up the stairs, the follow while time stands still.


func _checks() -> Array[Callable]:
	return [
		_check_camera_follow,
		_check_camera_follow_toward,
		_check_camera_follow_stairs,
		_check_camera_follow_pauses,
		_check_camera_waits_after_rotate,
		_check_look_around_waits,
		_check_camera,
		_check_camera_pitch_follow,
		_check_camera_zoom_follow,
		_check_height_follow,
		_check_follow_time_stopped,
	]


## The follow turn: off, the camera does not turn by itself; at 0 it turns at once; at the demo's time it turns 95% in
## about that time, smoothly: it speeds up and slows down without jerks and never goes past the run; standing, it does
## not drift; at 10 s it turns very slowly.
func _check_camera_follow() -> void:
	print("\n== camera follows the run: off, instant, default, very slow")
	var default_time := _rig.follow_time
	var off := await _watch_camera_on_run(false, default_time, 2.0)
	print("off: camera angle to the run %.1f -> %.1f deg" % [off[0], off[-1]])
	_expect(absf(off[-1] - off[0]) < 0.5, "off by default: the camera does not turn by itself")

	var instant := await _watch_camera_on_run(true, 0.0, 1.0)
	var instant_at := _first_time_at_most(instant, 4.5)
	print("follow_time 0: angle (every 3rd tick) %s; 95%% of the turn in %.2f s" % [
		_fmt(_every(instant.slice(0, 30), 3)), instant_at])
	_expect(instant_at > 0.0 and instant_at <= 0.3, "follow_time 0 turns behind the run at once")

	var normal := await _watch_camera_on_run(true, default_time, 3.0)
	var normal_at := _first_time_at_most(normal, 4.5)
	var motion := _turn_motion(normal)
	print(("follow_time %.1f: angle (every 15th tick) %s; 95%% of the turn in %.2f s; turning up to %.0f deg/s, the " +
			"turn speed changing by up to %.0f deg/s^2; back up to %.3f deg") % [default_time, _fmt(_every(normal, 15)),
		normal_at, motion.fastest, motion.sharpest, motion.back])
	_expect(absf(normal_at - default_time) <= 0.3, "follow_time %.1f turns 95%% in about that time" % default_time)
	_expect(motion.sharpest < 2000.0 and motion.back < 0.05,
			"the turn speeds up and slows down smoothly and never goes past the run")
	for i in 600:
		await _tree.physics_frame
		if _mover.get_speed() == 0.0:
			break
	for i in 10:
		await _tree.physics_frame
	var standing := _camera_angle_to(Vector3.RIGHT)
	for i in 60:
		await _tree.physics_frame
	var standing_drift := absf(_camera_angle_to(Vector3.RIGHT) - standing)
	print("standing after the run: camera drift %.3f deg in 1 s" % standing_drift)
	_expect(standing_drift < 0.05, "does not turn while the player stands")

	var slow := await _watch_camera_on_run(true, 10.0, 2.0)
	print("follow_time 10: angle after 1 s %.1f deg, after 2 s %.1f deg" % [slow[59], slow[-1]])
	_expect(slow[-1] > 60.0 and slow[-1] < 85.0, "follow_time 10 turns very slowly")
	_rig.follow_movement = false
	_rig.follow_time = default_time


## How the camera turned, from its angle to the run on every tick ([param angles], degrees): the fastest turn, deg/s,
## the sharpest change of the turn speed, deg/s², and the most it turned back, degrees (going past the run and back).
func _turn_motion(angles: PackedFloat32Array) -> Dictionary:
	var fastest := 0.0
	var sharpest := 0.0
	var back := 0.0
	var rate := 0.0
	for i in range(1, angles.size()):
		var new_rate := (angles[i - 1] - angles[i]) / DT
		fastest = maxf(fastest, new_rate)
		back = maxf(back, angles[i] - angles[i - 1])
		if i >= 2:
			sharpest = maxf(sharpest, absf(new_rate - rate) / DT)
		rate = new_rate
	return {fastest = fastest, sharpest = sharpest, back = back}


## A run toward the camera: straight at it, or within follow_toward_camera_angle of straight, it does not turn the
## camera; farther off it turns it behind the run; with the angle 0 even a run straight at it does. With
## follow_max_turn_speed the camera never turns faster, also when the turn is instant. A teleport is not a run: the
## camera does not turn toward the jump.
func _check_camera_follow_toward() -> void:
	print("
== the follow toward the camera, the speed limit, a teleport")
	var angle := _rig.follow_toward_camera_angle
	var straight := await _turn_toward_camera(0.0, 1.0)
	var inside := await _turn_toward_camera(rad_to_deg(angle) * 0.6, 1.0)
	var outside := await _turn_toward_camera(rad_to_deg(angle) * 2.0, 1.5)
	_rig.follow_toward_camera_angle = 0.0
	var any_run := await _turn_toward_camera(0.0, 1.0)
	_rig.follow_toward_camera_angle = angle

	var default_time := _rig.follow_time
	_rig.follow_max_turn_speed = deg_to_rad(60.0)
	var limited := await _watch_camera_on_run(true, 0.3, 3.0)
	var limited_motion := _turn_motion(limited)
	var instant_limited := await _watch_camera_on_run(true, 0.0, 3.0)
	var instant_motion := _turn_motion(instant_limited)
	_rig.follow_max_turn_speed = 0.0
	_rig.follow_time = default_time

	# A teleport 20 m to the north while the follow is on, without snap().
	_rig.follow_movement = true
	var view := _camera_forward()
	await _teleport(_player.global_position + Vector3(0, 0, -20))
	for i in 30:
		await _tree.physics_frame
	var teleport_turn := _flat_angle(view, _camera_forward())
	_rig.follow_movement = false
	print(("follow_toward_camera_angle %.0f deg: a run straight at the camera turned it %.1f deg in 1 s, %.0f deg off " +
			"straight %.1f deg, %.0f deg off %.1f deg in 1.5 s; with 0, straight at it %.1f deg in 1 s") % [
		rad_to_deg(angle), straight, rad_to_deg(angle) * 0.6, inside, rad_to_deg(angle) * 2.0, outside, any_run])
	print(("follow_max_turn_speed 60 deg/s: follow_time 0.3 up to %.1f deg/s, 95%% in %.2f s; instant up to %.1f " +
			"deg/s, 95%% in %.2f s; a teleport of 20 m turned the camera %.2f deg") % [limited_motion.fastest,
		_first_time_at_most(limited, 4.5), instant_motion.fastest, _first_time_at_most(instant_limited, 4.5),
		teleport_turn])
	_expect(straight < 1.0 and inside < 1.0 and outside > 60.0 and any_run > 120.0,
			"a run toward the camera within the angle does not turn it, a run farther off does, and 0 follows every run")
	_expect(limited_motion.fastest <= 60.5 and _first_time_at_most(limited, 4.5) > 1.3
			and instant_motion.fastest <= 60.5 and _first_time_at_most(instant_limited, 4.5) > 1.3,
			"follow_max_turn_speed: the camera never turns faster, also when the turn is instant")
	_expect(teleport_turn < 0.5, "a teleport is not a run: the camera does not turn toward the jump")


## The character at the west end of the strip by the south fence runs east; the camera looks west, turned by
## [param off_straight] degrees: 0 is straight at it. Returns how many degrees the camera turned in [param seconds].
func _turn_toward_camera(off_straight: float, seconds: float) -> float:
	_rig.follow_movement = false
	await _teleport(Vector3(-30, 0, 34))
	_rig.look_along(Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(off_straight)))
	await _settle_camera()
	_rig.follow_movement = true
	var view := _camera_forward()
	_mover.steer(Vector3.RIGHT)
	for i in roundi(seconds / DT):
		await _tree.physics_frame
	var turned := _flat_angle(view, _camera_forward())
	_mover.stop()
	_rig.follow_movement = false
	await _ticks_until_stopped(120)
	return turned


## Up the stairs east of the platform with the follow on, the camera looking along the run: the body is put onto every
## stair at once, and still the camera turns smoothly.
func _check_camera_follow_stairs() -> void:
	print("\n== the follow up the stairs")
	await _teleport(Vector3(36, 0, 18))
	_rig.look_along(Vector3.LEFT)
	await _settle_camera()
	_rig.follow_movement = true
	_arrived = false
	_mover.move_to(Vector3(26, 1.6, 18))
	var yaws := PackedFloat32Array()
	while not _arrived and yaws.size() < 300:
		await _tree.physics_frame
		yaws.append(rad_to_deg(_rig.rotation.y))
	_rig.follow_movement = false
	var sharpest := 0.0
	for i in range(2, yaws.size()):
		var rate := angle_difference(deg_to_rad(yaws[i - 1]), deg_to_rad(yaws[i])) / DT
		var previous := angle_difference(deg_to_rad(yaws[i - 2]), deg_to_rad(yaws[i - 1])) / DT
		sharpest = maxf(sharpest, rad_to_deg(absf(rate - previous)) / DT)
	print("up the stairs: arrived %s; the camera's turn speed changing by up to %.0f deg/s^2" % [_arrived, sharpest])
	_expect(_arrived and sharpest < 200.0, "up the stairs the camera turns smoothly")


## The character stands at (-8, 0, 0) with the camera looking north, then runs east. Returns the angle between the
## camera's view and the run (degrees) on every tick.
func _watch_camera_on_run(follow: bool, follow_time: float, seconds: float) -> PackedFloat32Array:
	_rig.follow_movement = false
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	_rig.follow_movement = follow
	_rig.follow_time = follow_time
	_mover.move_to(Vector3(8, 0, 0))
	var angles := PackedFloat32Array()
	for i in roundi(seconds / DT):
		await _tree.physics_frame
		angles.append(_camera_angle_to(Vector3.RIGHT))
	return angles


func _check_camera_follow_pauses() -> void:
	print("\n== camera follow pauses: right button rotates the camera, left button steers by the cursor")
	var default_time := _rig.follow_time
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	_rig.follow_movement = true
	_rig.follow_time = 0.5
	_mover.move_to(Vector3(8, 0, 0))
	for i in 18:
		await _tree.physics_frame
	var center := _tree.root.get_visible_rect().size / 2.0
	_send_motion(center, Vector2.ZERO)
	var angles := PackedFloat32Array()
	for i in 2:
		angles.append(_camera_angle_to(Vector3.RIGHT))
		await _tree.physics_frame
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	# A turn under way brakes as fast as the smoothing of the mouse settles (rotation_sharpness): a few degrees.
	for i in 10:
		angles.append(_camera_angle_to(Vector3.RIGHT))
		await _tree.physics_frame
	var turning := (angles[0] - angles[1]) / DT
	var after_press := (angles[2] - angles[3]) / DT
	var stopped := absf(angles[-2] - angles[-1]) / DT
	var rotate_before := _camera_angle_to(Vector3.RIGHT)
	for i in 20:
		await _tree.physics_frame
	var rotate_during := _camera_angle_to(Vector3.RIGHT)
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	for i in 30:
		await _tree.physics_frame
	var waited := _rig.is_follow_waiting()
	var rotate_waiting := _camera_angle_to(Vector3.RIGHT)
	# A click on the ground ahead starts a new run, and the camera turns behind it again.
	var ahead := _camera.unproject_position(_player.global_position + Vector3(6, 0, 0))
	_send_motion(ahead, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, ahead)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, false, ahead)
	for i in 30:
		await _tree.physics_frame
	var rotate_after := _camera_angle_to(Vector3.RIGHT)
	print(("right button pressed while turning at %.0f deg/s: %.0f deg/s in the tick after the press, %.1f deg/s " +
			"0.15 s later; held: angle %.1f -> %.1f deg; 0.5 s after release, the run going on: %.1f deg, waiting %s; " +
			"0.5 s after a click ahead: %.1f deg") % [turning, after_press, stopped, rotate_before, rotate_during,
		rotate_waiting, waited, rotate_after])
	_expect(turning > 20.0 and after_press > 0.3 * turning and stopped < 0.05 * turning,
			"pressed mid-turn, the camera brakes quickly but does not stop dead")
	_expect(absf(rotate_during - rotate_before) < 0.3, "does not turn while the right button rotates the camera")
	_expect(waited and absf(rotate_waiting - rotate_during) < 0.3,
			"after the right button is released, the camera waits while the run goes on")
	_expect(rotate_during > 5.0 and rotate_after < 0.25 * rotate_during,
			"a click starts a new run, and the camera turns behind it again")
	for i in 600:
		await _tree.physics_frame
		if not _mover.has_destination():
			break

	# A short click: the camera waits only while the button is pressed.
	var size := _tree.root.get_visible_rect().size
	var click_at := Vector2(size.x * 0.4, size.y * 0.6)
	_send_motion(click_at, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, click_at)
	await _tree.physics_frame
	await _tree.physics_frame
	var paused_on_click := _rig.is_follow_paused()
	_send_button(MOUSE_BUTTON_LEFT, false, click_at)
	for i in 3:
		await _tree.physics_frame
	var paused_after_click := _rig.is_follow_paused()
	print("click: paused while pressed %s, after release %s" % [paused_on_click, paused_after_click])
	_expect(paused_on_click and not paused_after_click,
			"a click pauses the follow only while it is not clear: click or hold")
	for i in 600:
		await _tree.physics_frame
		if not _mover.has_destination():
			break

	var held := await _hold_and_watch(default_time, true, Vector2(150, 0))
	print(("hold, follow_time %.1f: click window camera turn %.2f deg; from the hold start camera turned %.1f deg, " +
			"left %.1f of %.1f deg behind the run; heading turned %.2f deg; mouse +150 px turned the run %.1f deg, " +
			"then drift %.2f deg") % [default_time, held.click_window_turn, held.camera_turn, held.camera_lag,
			held.initial_lag, held.heading_turn, held.nudge_turn, held.nudge_drift])
	_expect(held.paused_on_press and held.click_window_turn < 0.3, "camera waits while it is not clear: click or hold")
	_expect(not held.paused_while_held and held.camera_lag < 0.25 * held.initial_lag,
			"camera turns behind the run as soon as the hold starts")
	_expect(held.heading_turn < 1.0, "the cursor keeps the aim: the run goes straight while the camera turns")
	_expect(held.nudge_turn > 10.0 and held.nudge_drift < 1.0, "moving the mouse still steers, the new direction holds")

	var instant := await _hold_and_watch(0.0, true)
	print("hold, follow_time 0: heading turned %.2f deg, camera %.1f deg behind the run" % [
		instant.heading_turn, instant.camera_lag])
	_expect(instant.heading_turn < 1.0 and instant.camera_lag < 2.0,
			"follow_time 0: camera snaps behind, the run stays straight")

	var curling := await _hold_and_watch(default_time, false)
	print("hold, keep_aim_on_camera_turn off: heading turned %.1f deg in 1.25 s" % curling.heading_turn)
	_expect(curling.heading_turn > 45.0, "keep_aim_on_camera_turn off: the cursor stays and the run curls")
	_rig.follow_movement = false
	_rig.follow_time = default_time


## Holds LMB with the cursor to the right of and above the character (STEER mode), with the follow on.
## Measures how the camera and the run direction turned; with [param nudge], moves the mouse after that.
## With [param pitch] above zero, the camera also levels its pitch to that many degrees down.
## A headless window does not move the cursor, so the "system" cursor stays where the events put it.
func _hold_and_watch(follow_time: float, keep_aim: bool, nudge := Vector2.ZERO, pitch := 0.0) -> Dictionary:
	var input := _input
	input.hold_mode = PointClickMoveInput.HoldMode.STEER
	input.keep_aim_on_camera_turn = keep_aim
	_rig.follow_movement = false
	await _teleport(Vector3(-4, 0, 6))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	_rig.follow_movement = true
	_rig.follow_time = follow_time
	if pitch > 0.0:
		_rig.follow_pitch = true
		_rig.follow_pitch_angle = -deg_to_rad(pitch)
		_rig.follow_pitch_time = follow_time
	var size := _tree.root.get_visible_rect().size
	var screen := Vector2(size.x * 0.6, size.y * 0.45)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	var camera_at_press := _camera_forward()
	await _tree.physics_frame
	await _tree.physics_frame
	var paused_on_press := _rig.is_follow_paused()
	# Until hold_delay (12 ticks) has passed, this may still be a click.
	for i in 9:
		await _tree.physics_frame
	var click_window_turn := _flat_angle(camera_at_press, _camera_forward())
	for i in 5:
		await _tree.physics_frame
	var paused_while_held := _rig.is_follow_paused()
	var camera_at_hold := _camera_forward()
	var pitch_at_hold := _camera_pitch()
	var initial_lag := _flat_angle(camera_at_hold, _mover.get_heading())
	var heading_turn := await _heading_turn_over(75)
	var result := {
		paused_on_press = paused_on_press,
		click_window_turn = click_window_turn,
		paused_while_held = paused_while_held,
		initial_lag = initial_lag,
		camera_turn = _flat_angle(camera_at_hold, _camera_forward()),
		camera_lag = _flat_angle(_camera_forward(), _mover.get_heading()),
		heading_turn = heading_turn,
		pitch_at_hold = pitch_at_hold,
		pitch_after = _camera_pitch(),
	}
	if nudge != Vector2.ZERO:
		var heading_before := _mover.get_heading()
		_send_motion(screen + nudge, nudge)
		for i in 15:
			await _tree.physics_frame
		result.nudge_turn = _flat_angle(heading_before, _mover.get_heading())
		result.nudge_drift = await _heading_turn_over(30)
		screen += nudge
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	for i in 600:
		await _tree.physics_frame
		if _mover.get_speed() == 0.0:
			break
	_rig.follow_movement = false
	_rig.follow_pitch = false
	input.keep_aim_on_camera_turn = true
	return result


## How much the run direction turned over [param ticks] ticks (the sum of the turns, in degrees).
func _heading_turn_over(ticks: int) -> float:
	var turn := 0.0
	var previous := _mover.get_heading()
	for i in ticks:
		await _tree.physics_frame
		var heading := _mover.get_heading()
		turn += _flat_angle(previous, heading)
		previous = heading
	return turn


## After the camera has been rotated with the right button, the follow waits. RMB + D walks to the camera's right with
## the turn and the tilt alignment on; RMB released a moment before D: while the character brakes, the camera neither
## turns nor tilts, and after the stop the wait is over. With follow_wait_after_rotate off, the camera swings behind
## the braking run and tilts. A tap of the button does not start the wait; turning the setting off, snap() and a
## teleport end it. A hold that goes on after RMB, steered by the mouse, is not a new run: the wait lasts until the stop.
func _check_camera_waits_after_rotate() -> void:
	print("\n== the follow waits after the camera has been rotated with the right button")
	var input := _input
	var keys_before := input.keys_with_camera
	var pitch_angle := _rig.follow_pitch_angle
	input.keys_with_camera = PointClickMoveInput.KeysMode.TURN
	_rig.follow_movement = true
	_rig.follow_pitch = true
	# Not the pitch of the wheel at the start (about 40°): the alignment has work to do.
	_rig.follow_pitch_angle = -deg_to_rad(20.0)
	var waiting := await _brake_after_rotate()
	_rig.follow_wait_after_rotate = false
	var resumed := await _brake_after_rotate()
	_rig.follow_wait_after_rotate = true

	# A run to the east; the teleport below jumps 3 m back along it, where the ground is clear.
	_mover.steer(Vector3.RIGHT)
	await _ticks(30)
	var after_tap := await _press_right(1)
	var after_press := await _press_right(15)
	_rig.follow_wait_after_rotate = false
	var off_ends := not _rig.is_follow_waiting()
	_rig.follow_wait_after_rotate = true
	await _press_right(15)
	_rig.snap()
	var snap_ends := not _rig.is_follow_waiting()
	await _press_right(15)
	_player.global_position += Vector3(-3, 0, 0)
	await _ticks(2)
	var teleport_ends := not _rig.is_follow_waiting()
	_mover.stop()
	await _ticks_until_stopped(60)

	# LMB + RMB, then RMB released and LMB held on, the mouse steering: the same run goes on.
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.RIGHT)
	await _settle_camera()
	var size := _tree.root.get_visible_rect().size
	var screen := Vector2(size.x * 0.5, size.y * 0.3)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(30)
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	await _ticks(20)
	_send_motion(screen + Vector2(60, 0), Vector2(60, 0))
	await _ticks(30)
	var waits_on_hold := _rig.is_follow_waiting()
	_send_button(MOUSE_BUTTON_LEFT, false, screen + Vector2(60, 0))
	await _ticks_until_stopped(60)
	await _ticks(2)
	var ends_at_stop := not _rig.is_follow_waiting()
	input.keys_with_camera = keys_before
	_rig.follow_movement = false
	_rig.follow_pitch = false
	_rig.follow_pitch_angle = pitch_angle

	print(("RMB + D, RMB released 0.1 s before D: while braking the camera turned %.2f deg and tilted %.2f deg, " +
			"waiting %s, after the stop %s; with follow_wait_after_rotate off: turned %.1f deg, tilted %.1f deg. " +
			"Waiting after a tap %s, after 0.25 s %s; ended by turning the setting off %s, by snap() %s, by a teleport " +
			"%s. LMB held on after RMB, the mouse steering: waiting %s, over at the stop %s") % [waiting.turned,
		waiting.tilted, waiting.waited, waiting.waiting_after_stop, resumed.turned, resumed.tilted, after_tap,
		after_press, off_ends, snap_ends, teleport_ends, waits_on_hold, ends_at_stop])
	_expect(waiting.waited and waiting.turned < 0.3 and waiting.tilted < 0.3,
			"the camera neither turns nor tilts while the character brakes after the right button is released")
	_expect(not waiting.waiting_after_stop, "the wait is over when the character stops")
	_expect(not resumed.waited and resumed.turned > 10.0 and resumed.tilted > 2.0,
			"follow_wait_after_rotate off: the camera swings behind the braking run and tilts")
	_expect(not after_tap and after_press, "a tap of the right button does not start the wait, a press does")
	_expect(off_ends and snap_ends and teleport_ends, "turning the setting off, snap() and a teleport end the wait")
	_expect(waits_on_hold and ends_at_stop,
			"a hold that goes on after the right button is not a new run: the wait lasts until the stop")


## The follow turns the camera behind a run after the cursor. RMB pressed over that run looks around, and after it is
## released, LMB held on, the camera stays where it was left while the run keeps its course; a click ahead while the
## character still brakes starts a new run and brings the follow back.
func _check_look_around_waits() -> void:
	print("\n== looking around on a run after the cursor with the follow on: the camera waits after the right button")
	var default_time := _rig.follow_time
	_rig.follow_movement = true
	_rig.follow_time = 0.5
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	var screen := _camera.unproject_position(_player.global_position + Vector3(6, 0, 0))
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(60)
	var behind := _camera_angle_to(Vector3.RIGHT)
	var heading := _mover.get_heading()
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	await _ticks(2)
	# 240 px to the left at 0.25 °/px: the camera looks 60° to the left of the run.
	_send_motion(screen, Vector2(-240, 0))
	await _ticks(30)
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	await _ticks(10)
	var left_at := _camera_angle_to(Vector3.RIGHT)
	await _ticks(60)
	var stays := _camera_angle_to(Vector3.RIGHT)
	var run_turn := _flat_angle(heading, _mover.get_heading())
	var waiting := _rig.is_follow_waiting()
	# A click ahead while the character still brakes: a new run, and the follow comes back without waiting for the stop.
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	await _ticks(2)
	var ahead := _camera.unproject_position(_player.global_position + _mover.get_heading() * 8.0)
	_send_motion(ahead, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, ahead)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, false, ahead)
	await _ticks(2)
	var speed_at_new_run := _mover.get_speed()
	var waiting_on_new_run := _rig.is_follow_waiting()
	await _ticks(60)
	var new_run_lag := _flat_angle(_camera_forward(), _mover.get_heading())
	await _ticks_until_stopped(180)
	_rig.follow_movement = false
	_rig.follow_time = default_time
	print(("the camera %.1f deg off the run before RMB; left %.1f deg off, 1 s later %.1f deg, waiting %s, the run " +
			"turned %.2f deg from before RMB; a click ahead at %.1f m/s: waiting %s, the camera %.1f deg off the run " +
			"1 s later") % [behind, left_at, stays, waiting, run_turn, speed_at_new_run, waiting_on_new_run,
		new_run_lag])
	_expect(behind < 5.0, "the follow turns the camera behind the run after the cursor")
	_expect(left_at > 50.0 and absf(stays - left_at) < 1.0 and waiting and run_turn < 2.0,
			"after looking around, the camera stays where it was left while the run keeps its course with LMB held")
	_expect(speed_at_new_run > _rig.follow_min_speed and not waiting_on_new_run and new_run_lag < 5.0,
			"a new run before the stop (a click ahead) brings the follow back")


## Presses the right button for [param ticks] ticks without moving the mouse. Returns whether the follow waits after
## the release.
func _press_right(ticks: int) -> bool:
	var center := _tree.root.get_visible_rect().size / 2.0
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	await _ticks(ticks)
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	await _tree.physics_frame
	return _rig.is_follow_waiting()


## From (-8, 0, 0), the camera looking north: RMB + D walk to the east for 1 s, the mouse turning the camera a little at
## first; then RMB is released, and D 0.1 s later. Returns how far the camera turned and tilted from the release until
## the character has stood for 0.2 s (degrees), and whether the follow waited after the release and after the stop.
func _brake_after_rotate() -> Dictionary:
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	var center := _tree.root.get_visible_rect().size / 2.0
	_send_motion(center, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	Input.action_press(&"move_right")
	for i in 20:
		_send_motion(center, Vector2(2, 0))
		await _tree.physics_frame
	# The mouse smoothing settles before the release: whatever the camera does after it is the follow's.
	await _ticks(40)
	var yaw := _rig.rotation.y
	var pitch := _rig.rotation.x
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	await _ticks(6)
	Input.action_release(&"move_right")
	var waited := _rig.is_follow_waiting()
	await _ticks_until_stopped(60)
	await _ticks(12)
	return {
		turned = rad_to_deg(absf(angle_difference(yaw, _rig.rotation.y))),
		tilted = rad_to_deg(absf(_rig.rotation.x - pitch)),
		waited = waited,
		waiting_after_stop = _rig.is_follow_waiting(),
	}


## The horizontal angle between the camera's view and [param direction], in degrees.
func _camera_angle_to(direction: Vector3) -> float:
	return _flat_angle(_camera_forward(), direction)


func _check_camera() -> void:
	print("\n== camera")
	await _settle_camera()
	var distance_before := _camera.position.z
	var pitch_before := _rig.rotation.x
	# One wheel click is 0.1 of zoom: from the start (0.55) down through the middle.
	var pitches := PackedFloat32Array([_camera_pitch()])
	for i in 3:
		_send_button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(576, 400))
		_send_button(MOUSE_BUTTON_WHEEL_UP, false, Vector2(576, 400))
		await _settle_camera()
		pitches.append(_camera_pitch())
	var distance_after_zoom := _camera.position.z
	var pitch_after_zoom := _rig.rotation.x
	print("zoom: distance %.2f -> %.2f; looks down by click %s deg" % [distance_before, distance_after_zoom,
		_fmt(pitches)])
	_expect(distance_after_zoom < distance_before - 1.0, "wheel up lowers the camera closer")
	_expect(pitch_after_zoom > pitch_before, "lowered camera looks flatter")
	_expect(pitches[2] < 30.0 and pitches[3] < 25.0,
			"below the middle the camera levels out fast: two clicks down under 30 degrees, three under 25")

	var level := await _drag_camera(Vector2(100, -40))
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	settings.set_value(GameSettings.CAMERA_MOUSE_PITCH, true)
	var tilted := await _drag_camera(Vector2(0, -40))
	settings.set_value(GameSettings.CAMERA_MOUSE_PITCH, false)
	await _settle_camera()
	var pitch_back := rad_to_deg(_rig.rotation.x - pitch_after_zoom)
	print(("drag by default: yaw %+.1f deg, pitch %+.1f deg; with mouse pitch on: pitch %+.1f deg; " +
			"after it is off again: %+.2f deg from the wheel pitch") % [level.x, level.y, tilted.y, pitch_back])
	_expect(absf(level.x + 25.0) < 0.5 and absf(level.y) < 0.01,
			"by default dragging right by 100 px turns the view by 25 degrees and up does not tilt it")
	_expect(absf(tilted.y - 10.0) < 0.5, "with mouse pitch on dragging up by 40 px lowers the camera by 10 degrees")
	_expect(absf(pitch_back) < 0.01, "turning mouse pitch off returns the camera to the pitch of the wheel")


## Drags the mouse with RMB held by [param motion] (in two events per frame) and waits until the camera settles.
## Returns how many degrees it turned (x) and lowered, looking flatter (y).
func _drag_camera(motion: Vector2) -> Vector2:
	var yaw_before := _rig.rotation.y
	var pitch_before := _rig.rotation.x
	_send_button(MOUSE_BUTTON_RIGHT, true, Vector2(576, 400))
	_send_motion(Vector2(576, 400), motion / 2.0)
	_send_motion(Vector2(576, 400), motion / 2.0)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_RIGHT, false, Vector2(576, 400))
	await _settle_camera()
	return Vector2(rad_to_deg(angle_difference(yaw_before, _rig.rotation.y)),
			rad_to_deg(_rig.rotation.x - pitch_before))


## Runs after [method _check_camera]: the pitch set by the wheel levels out on the run, smoothly and without going
## past the angle.
func _check_camera_pitch_follow() -> void:
	print("\n== camera levels its pitch on the run")
	var default_time := _rig.follow_time
	var default_pitch_time := _rig.follow_pitch_time
	var run := await _watch_pitch_on_run(55.0, 0.5, 2.0)
	var past := _max(run.pitches) - 55.0
	print(("to 55 deg, follow_pitch_time 0.5, turning off: pitch (every 6th tick) %s; past the angle by %.3f deg; " +
			"camera angle to the run %.1f deg") % [_fmt(_every(run.pitches, 6)), past, run.yaw_angle])
	_expect(absf(run.pitches[-1] - 55.0) < 0.3 and past < 0.05,
			"levels the pitch set by the wheel to the chosen angle, without going past it")
	_expect(absf(run.yaw_angle - 90.0) < 0.5, "follow_movement off: levels the pitch only, does not turn")
	var limited := await _watch_pitch_on_run(89.0, 0.5, 2.0)
	var limit := -rad_to_deg(_rig.min_pitch)
	print("to 89 deg, starting from %.1f deg after the alignment was off: pitch -> %.1f deg (camera limit %.1f)" % [
		limited.pitches[0], limited.pitches[-1], limit])
	_expect(absf(limited.pitches[-1] - limit) < 0.3, "does not tilt past the camera limit")
	_expect(absf(limited.pitches[0] - run.pitches[0]) < 0.1,
			"turned off, the tilt alignment gives the camera back the pitch of the wheel")

	var held := await _hold_and_watch(default_time, true, Vector2.ZERO, 60.0)
	print(("hold, follow_time %.1f, pitch 60 deg: pitch %.1f -> %.1f deg in 1.25 s; camera %.1f deg behind the run; " +
			"heading turned %.2f deg") % [
		default_time, held.pitch_at_hold, held.pitch_after, held.camera_lag, held.heading_turn])
	_expect(absf(held.pitch_after - 60.0) < 0.25 * absf(held.pitch_at_hold - 60.0)
			and held.camera_lag < 0.25 * held.initial_lag,
			"on a left-button hold the camera turns behind the run and levels its pitch")
	_expect(held.heading_turn < 1.0, "the cursor keeps the aim while the pitch changes")
	_rig.follow_time = default_time
	_rig.follow_pitch_time = default_pitch_time


## The character stands at (-8, 0, 0) with the camera looking north, then runs east; the camera levels its pitch to
## [param angle] degrees down in [param pitch_time], with the follow off. Returns the camera pitch (degrees down) on
## every tick from the start of the run and the angle between the camera's view and the run at the end.
func _watch_pitch_on_run(angle: float, pitch_time: float, seconds: float) -> Dictionary:
	_rig.follow_pitch = false
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	_rig.follow_pitch = true
	_rig.follow_pitch_angle = -deg_to_rad(angle)
	_rig.follow_pitch_time = pitch_time
	var pitches := PackedFloat32Array([_camera_pitch()])
	_mover.move_to(Vector3(8, 0, 0))
	for i in roundi(seconds / DT):
		await _tree.physics_frame
		pitches.append(_camera_pitch())
	var yaw_angle := _camera_angle_to(Vector3.RIGHT)
	_rig.follow_pitch = false
	for i in 600:
		await _tree.physics_frame
		if not _mover.has_destination():
			break
	return {pitches = pitches, yaw_angle = yaw_angle}


## How far down the camera looks, in degrees.
func _camera_pitch() -> float:
	return -rad_to_deg(_rig.rotation.x)


## The height on the run: standing, the camera keeps the height the wheel set; running, it reaches follow_zoom_level
## smoothly, 95% of the way in about follow_zoom_time, never past it. With the pitch aligned too, the pitch stays at
## its angle while the height changes. The wheel changes the height as usual, and on the run it comes back; 0 is
## instant.
func _check_camera_zoom_follow() -> void:
	print("\n== camera aligns its height on the run")
	var defaults := [_rig.follow_zoom_level, _rig.follow_zoom_time, _rig.follow_pitch_angle, _rig.follow_pitch_time]
	# The strip by the south fence.
	await _teleport(Vector3(-30, 0, 34))
	_rig.look_along(Vector3.RIGHT)
	await _settle_camera()
	var start := _rig.get_zoom()
	_rig.follow_zoom = true
	_rig.follow_zoom_level = 0.9
	_rig.follow_zoom_time = 0.8
	await _ticks(60)
	var standing := absf(_rig.get_zoom() - start)
	var raised := await _zooms_on_run(2.0)
	var way := 0.9 - start
	var reached_at := -1.0
	for i in raised.size():
		if reached_at < 0.0 and absf(0.9 - raised[i]) <= 0.05 * absf(way):
			reached_at = (i + 1) * DT
	var moved_at := -1.0
	for i in raised.size():
		if moved_at < 0.0 and absf(raised[i] - start) > 0.001:
			moved_at = (i + 1) * DT
	# In its first 0.1 s the height covers only a little of the way: it starts smoothly (a pull straight to the level,
	# without the spring, would cover about a third of it).
	var first := absf(raised[mini(roundi(moved_at / DT) + 5, raised.size() - 1)] - start) / absf(way)

	# The pitch aligned too: it stays at 40° while the height goes down.
	_rig.follow_pitch = true
	_rig.follow_pitch_angle = -deg_to_rad(40.0)
	_rig.follow_pitch_time = 0.3
	await _zooms_on_run(1.0)
	_rig.follow_zoom_level = 0.3
	var pitches := PackedFloat32Array()
	var lowered := PackedFloat32Array()
	_mover.steer(Vector3.LEFT)
	for i in 120:
		await _tree.physics_frame
		pitches.append(_camera_pitch())
		lowered.append(_rig.get_zoom())
	_mover.stop()
	await _ticks_until_stopped(120)
	_rig.follow_pitch = false

	# The wheel while standing: two clicks down; on the run the height comes back.
	for i in 2:
		_send_button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(576, 400))
		_send_button(MOUSE_BUTTON_WHEEL_UP, false, Vector2(576, 400))
	await _settle_camera()
	var wheeled := _rig.get_zoom()
	var back := await _zooms_on_run(2.0)
	# Instant.
	_rig.follow_zoom_time = 0.0
	_rig.follow_zoom_level = 0.6
	var instant := await _zooms_on_run(0.5)
	_rig.follow_zoom = false
	_rig.follow_zoom_level = defaults[0]
	_rig.follow_zoom_time = defaults[1]
	_rig.follow_pitch_angle = defaults[2]
	_rig.follow_pitch_time = defaults[3]
	await _teleport(Vector3.ZERO)

	print(("from %.2f, standing 1 s: changed by %.4f; on the run to 0.9 in follow_zoom_time 0.8: moved after %.2f s, " +
			"%.0f%% of the way in its first 0.1 s, 95%% in %.2f s from the start of the run, highest %.3f; with the " +
			"pitch at 40 deg, down to %.2f: pitch %.2f..%.2f deg; the wheel down to %.2f, after the run %.3f; " +
			"follow_zoom_time 0: %.3f after %d ticks") % [start, standing, moved_at, first * 100.0, reached_at,
		_max(raised), lowered[-1], _min(pitches), _max(pitches), wheeled, back[-1], instant[-1], instant.size()])
	_expect(standing < 0.001, "standing, the camera keeps the height the wheel set")
	_expect(absf(raised[-1] - 0.9) < 0.005 and _max(raised) <= 0.9001 and absf(reached_at - 0.8) < 0.35
			and first < 0.2,
			"on the run the height reaches the level smoothly, in about follow_zoom_time, never past it")
	_expect(absf(lowered[-1] - 0.3) < 0.01 and _max(pitches) - _min(pitches) < 0.2,
			"with the pitch aligned too, the pitch stays at its angle while the height changes")
	_expect(wheeled < 0.25 and absf(back[-1] - 0.3) < 0.01,
			"the wheel changes the height as usual, and on the run it comes back")
	_expect(absf(instant[-1] - 0.6) < 0.001, "follow_zoom_time 0: the height is reached at once")


## Runs east for [param seconds]: the zoom of the camera on every tick.
func _zooms_on_run(seconds: float) -> PackedFloat32Array:
	var zooms := PackedFloat32Array()
	_mover.steer(Vector3.RIGHT)
	for i in roundi(seconds / DT):
		await _tree.physics_frame
		zooms.append(_rig.get_zoom())
	_mover.stop()
	await _ticks_until_stopped(120)
	return zooms


## Up the staircase east of the platform: the character is put onto every stair at once, and with the demo's
## height_follow_time the camera rises along a smooth line: the change of its rise per frame is much smaller than
## without it, and on the platform it ends at the same height.
func _check_height_follow() -> void:
	print("\n== the camera glides up the stairs")
	var follow_time := _rig.height_follow_time
	var jerks := PackedFloat32Array()
	var ends := PackedFloat32Array()
	for time: float in [0.0, follow_time]:
		_rig.height_follow_time = time
		await _teleport(Vector3(36, 0, 18))
		_rig.snap()
		_arrived = false
		_mover.move_to(Vector3(26, 1.6, 18))
		var heights := PackedFloat32Array()
		while not _arrived and heights.size() < 300:
			await _tree.process_frame
			heights.append(_rig.global_position.y)
		await _settle_camera()
		var jerk := 0.0
		for i in range(2, heights.size()):
			jerk = maxf(jerk, absf(heights[i] - 2.0 * heights[i - 1] + heights[i - 2]))
		jerks.append(jerk)
		ends.append(_rig.global_position.y - _player.global_position.y)
	_rig.height_follow_time = follow_time
	await _teleport(Vector3.ZERO)
	print("height_follow_time 0: the rise per frame changes by up to %.3f m; %.2f s: by up to %.3f m; above the character at the end %.2f and %.2f m" % [
		jerks[0], follow_time, jerks[1], ends[0], ends[1]])
	_expect(follow_time > 0.0 and jerks[1] < 0.4 * jerks[0],
			"with the demo's height_follow_time the camera glides up the stairs")
	_expect(is_equal_approx(ends[0], _rig.focus_height) and is_equal_approx(ends[1], _rig.focus_height),
			"after the stairs the camera is at its height over the character")


## Time stands still (Engine.time_scale 0) while the camera follows a run with its turn, pitch and height: with the
## follow instant (times 0), and with the demo's times and no smoothing of the mouse and the wheel (sharpness 0). The
## camera stays where it is, no node of the scene gets a non-finite transform, and no errors come; when time goes on,
## the camera, turned away meanwhile, turns behind the run again.
func _check_follow_time_stopped() -> void:
	print("\n== time stands still while the camera follows the run")
	var defaults := [_rig.follow_movement, _rig.follow_pitch, _rig.follow_zoom, _rig.follow_time,
			_rig.follow_pitch_time, _rig.follow_zoom_time, _rig.follow_zoom_level, _rig.rotation_sharpness,
			_rig.zoom_sharpness]
	await _teleport(Vector3(-30, 0, 34))
	await _settle_camera()
	_rig.follow_movement = true
	_rig.follow_pitch = true
	_rig.follow_zoom = true
	# The height stays where it is: the move is computed all the same.
	_rig.follow_zoom_level = _rig.get_zoom()
	var report := PackedStringArray()
	var still := true
	var clean := true
	var follows := true
	for instant: bool in [true, false]:
		_rig.follow_time = 0.0 if instant else defaults[3]
		_rig.follow_pitch_time = 0.0 if instant else defaults[4]
		_rig.follow_zoom_time = 0.0 if instant else defaults[5]
		_rig.rotation_sharpness = defaults[7] if instant else 0.0
		_rig.zoom_sharpness = defaults[8] if instant else 0.0
		await _teleport(Vector3(-30, 0, 34))
		_mover.steer(Vector3.RIGHT)
		await _ticks(40)
		Engine.time_scale = 0.0
		var errors := _error_count()
		var broken := {}
		var before := []
		for i in 8:
			await _tree.physics_frame
			_find_non_finite(broken)
			if i == 1:
				# The frame in which the scale changed ran at full speed, and the first frame without time caught up
				# with its tick: from here on the camera stays.
				before = [_rig.global_transform, _camera.global_transform]
		var kept := _same_values([_rig.global_transform, _camera.global_transform], before)
		errors = _error_count() - errors
		# Turned away from the run: when time goes on, the follow turns the camera behind it again.
		_rig.look_along(Vector3.FORWARD)
		Engine.time_scale = 1.0
		await _ticks(90)
		var behind := _camera_angle_to(Vector3.RIGHT)
		_find_non_finite(broken)
		_mover.stop()
		await _ticks_until_stopped(60)
		report.append("%s: kept %s, non-finite %s, errors %d; then %.1f deg from behind the run" % [
			"instant" if instant else "no smoothing", kept, broken.keys(), errors, behind])
		still = still and kept
		clean = clean and broken.is_empty() and errors == 0
		follows = follows and behind < 15.0
	_rig.follow_movement = defaults[0]
	_rig.follow_pitch = defaults[1]
	_rig.follow_zoom = defaults[2]
	_rig.follow_time = defaults[3]
	_rig.follow_pitch_time = defaults[4]
	_rig.follow_zoom_time = defaults[5]
	_rig.follow_zoom_level = defaults[6]
	_rig.rotation_sharpness = defaults[7]
	_rig.zoom_sharpness = defaults[8]
	await _teleport(Vector3.ZERO)
	print("; ".join(report))
	_expect(still, "time stopped: the following camera stays where it is, also instant and without smoothing")
	_expect(clean, "no node gets a non-finite transform, and no errors come")
	_expect(follows, "when time goes on, the camera turns behind the run again")
