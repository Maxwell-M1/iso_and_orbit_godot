extends "res://tests/check_suite.gd"
## Camera: the follow and its pauses (while RMB is held and while it is not yet clear whether it is a click or a hold),
## the cursor keeping its aim while the camera turns, rotation and zoom with the mouse (RMB pitch only with the
## setting), leveling the pitch on the run.


func _checks() -> Array[Callable]:
	return [
		_check_camera_follow,
		_check_camera_follow_pauses,
		_check_camera,
		_check_camera_pitch_follow,
	]


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
	print("follow_time %.1f: angle (every 15th tick) %s; 95%% of the turn in %.2f s" % [
		default_time, _fmt(_every(normal, 15)), normal_at])
	_expect(absf(normal_at - default_time) <= 0.3, "follow_time %.1f turns 95%% in about that time" % default_time)
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
	_expect(slow[-1] > 40.0 and slow[-1] < 70.0, "follow_time 10 turns very slowly")
	_rig.follow_movement = false
	_rig.follow_time = default_time


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
	for i in 12:
		await _tree.physics_frame
	var center := _tree.root.get_visible_rect().size / 2.0
	_send_motion(center, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	# The camera still finishes a turn it has started with its smoothing (rotation_sharpness): a couple of degrees.
	for i in 10:
		await _tree.physics_frame
	var rotate_before := _camera_angle_to(Vector3.RIGHT)
	for i in 20:
		await _tree.physics_frame
	var rotate_during := _camera_angle_to(Vector3.RIGHT)
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	for i in 30:
		await _tree.physics_frame
	var rotate_after := _camera_angle_to(Vector3.RIGHT)
	print("right button held: angle %.1f -> %.1f deg; 0.5 s after release %.1f deg" % [
		rotate_before, rotate_during, rotate_after])
	_expect(absf(rotate_during - rotate_before) < 0.3, "does not turn while the right button rotates the camera")
	_expect(rotate_after < rotate_during - 20.0, "turns again after the right button is released")
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
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
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


## Runs after [method _check_camera]: the pitch set by the wheel levels out on the run.
func _check_camera_pitch_follow() -> void:
	print("\n== camera levels its pitch on the run")
	var default_time := _rig.follow_time
	var run := await _watch_pitch_on_run(55.0, 0.5, 2.0)
	print("to 55 deg, follow_time 0.5, turning off: pitch (every 6th tick) %s; camera angle to the run %.1f deg" % [
		_fmt(_every(run.pitches, 6)), run.yaw_angle])
	_expect(absf(run.pitches[-1] - 55.0) < 0.3, "levels the pitch set by the wheel to the chosen angle")
	_expect(absf(run.yaw_angle - 90.0) < 0.5, "follow_movement off: levels the pitch only, does not turn")
	var limited := await _watch_pitch_on_run(89.0, 0.5, 2.0)
	var limit := -rad_to_deg(_rig.min_pitch)
	print("to 89 deg: pitch %.1f -> %.1f deg (camera limit %.1f)" % [limited.pitches[0], limited.pitches[-1], limit])
	_expect(absf(limited.pitches[-1] - limit) < 0.3, "does not tilt past the camera limit")

	var held := await _hold_and_watch(default_time, true, Vector2.ZERO, 20.0)
	print(("hold, follow_time %.1f, pitch 20 deg: pitch %.1f -> %.1f deg in 1.25 s; camera %.1f deg behind the run; " +
			"heading turned %.2f deg") % [
		default_time, held.pitch_at_hold, held.pitch_after, held.camera_lag, held.heading_turn])
	_expect(absf(held.pitch_after - 20.0) < 0.25 * absf(held.pitch_at_hold - 20.0)
			and held.camera_lag < 0.25 * held.initial_lag,
			"on a left-button hold the camera turns behind the run and levels its pitch")
	_expect(held.heading_turn < 1.0, "the cursor keeps the aim while the pitch changes")
	_rig.follow_time = default_time


## The character stands at (-8, 0, 0) with the camera looking north, then runs east; the camera levels its pitch to
## [param angle] degrees down, with the follow off. Returns the camera pitch (degrees down) on every tick from the
## start of the run and the angle between the camera's view and the run at the end.
func _watch_pitch_on_run(angle: float, follow_time: float, seconds: float) -> Dictionary:
	_rig.follow_pitch = false
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	_rig.follow_pitch = true
	_rig.follow_pitch_angle = -deg_to_rad(angle)
	_rig.follow_time = follow_time
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
