extends "res://tests/check_suite.gd"
## Mouse and keys with real input events: a click, an LMB hold in both modes, LMB + RMB, RMB + WASD and
## LMB + RMB + A/D in all modes, keys dropping the run to a click point, the cursor hiding while running with LMB held.


func _checks() -> Array[Callable]:
	return [
		_check_click_input,
		_check_hold_steer,
		_check_hold_follow_point.bind(false),
		_check_hold_follow_point.bind(true),
		_check_camera_steer_up_the_ramp,
		_check_camera_steer_turn,
		_check_camera_keys,
		_check_keys_drop_click_point,
		_check_hold_hides_cursor,
	]


func _check_click_input() -> void:
	print("\n== click through the camera")
	await _teleport(Vector3.ZERO)
	await _settle_camera()
	var target := Vector3(3, 0, 3)
	var screen := _camera.unproject_position(target)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	# While the button is pressed (for less than hold_delay), it is not clear whether it is a click or a hold: the
	# character stands and there is no marker.
	var moved_while_pressed := false
	for i in 8:
		await _tree.physics_frame
		moved_while_pressed = moved_while_pressed or _mover.is_moving() or _mover.get_speed() > 0.0 or _marker.visible
	# The mouse is moved before the release: the click still goes where the button was pressed.
	var away := screen + Vector2(120, 40)
	_send_motion(away, away - screen)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, false, away)
	await _tree.physics_frame
	await _tree.physics_frame
	print("while pressed: moving or marker %s; after release: destination %s, marker visible %s at %s" % [
		moved_while_pressed, _mover.get_destination().snapped(Vector3.ONE * 0.001), _marker.visible,
		_marker.global_position.snapped(Vector3.ONE * 0.01)])
	_expect(not moved_while_pressed, "while pressed: no run, no marker yet (click or hold is not clear)")
	_expect(_mover.get_destination().distance_to(target) < 0.05,
			"on release the click goes to the ground point where it was pressed")
	_expect(_marker.visible, "marker is shown")
	var run := await _run_until_arrived(target, 10.0, false)
	for i in 30:
		await _tree.physics_frame
	_expect(run.arrived and run.error < 0.05, "arrives at the clicked point")
	_expect(not _marker.visible, "marker fades out on arrival")


func _check_hold_steer() -> void:
	print("\n== hold the button, mode STEER (towards the cursor, no pathfinding)")
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	input.hold_mode = PointClickMoveInput.HoldMode.STEER
	await _teleport(Vector3.ZERO)
	await _settle_camera()
	var size := _tree.root.get_visible_rect().size
	var screen := Vector2(size.x * 0.6, size.y * 0.45)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	var speeds := PackedFloat32Array()
	var point_or_marker := false
	for i in 90:
		await _tree.physics_frame
		speeds.append(_mover.get_speed())
		point_or_marker = point_or_marker or _mover.has_destination() or _marker.visible
	var cursor_ground: Variant = Plane(Vector3.UP, 0.0).intersects_ray(
			_camera.project_ray_origin(screen), _camera.project_ray_normal(screen))
	var to_cursor := Vector3((cursor_ground as Vector3).x - _player.global_position.x, 0.0,
			(cursor_ground as Vector3).z - _player.global_position.z).normalized()
	var steering := _mover.is_steering() and not _mover.has_destination()
	var alignment := _mover.get_heading().dot(to_cursor)
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	var after := PackedFloat32Array()
	for i in 600:
		await _tree.physics_frame
		after.append(_mover.get_speed())
		if _mover.get_speed() == 0.0:
			break
	print("held 1.5 s: speeds (every 10th): %s; heading vs cursor direction %.3f" % [
		_fmt(_every(speeds, 10)), alignment])
	print("after release: stopped in %.2f s, speeds (every 3rd): %s" % [after.size() * DT, _fmt(_every(after, 3))])
	_expect(steering, "runs by direction, not to a point")
	_expect(not point_or_marker, "a hold never runs to the pressed point and never shows a marker")
	_expect(_min(speeds.slice(45)) > 0.9 * _mover.settings.max_speed, "keeps running while held")
	_expect(alignment > 0.99, "runs towards the cursor")
	_expect(not _mover.is_steering() and _mover.get_speed() == 0.0, "stops after release")
	_expect(after.size() * DT <= _mover.settings.stop_time + 0.1, "stops right away, smoothly")
	_expect(not _marker.visible, "no marker")


func _check_hold_follow_point(stop_on_release: bool) -> void:
	print("\n== hold the button, mode FOLLOW_POINT, stop_on_release = %s" % stop_on_release)
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	input.hold_mode = PointClickMoveInput.HoldMode.FOLLOW_POINT
	input.stop_on_release = stop_on_release
	await _teleport(Vector3.ZERO)
	await _settle_camera()
	var size := _tree.root.get_visible_rect().size
	var screen := Vector2(size.x * 0.6, size.y * 0.45)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	var speeds := PackedFloat32Array()
	var lead := PackedFloat32Array()
	var start := _player.global_position
	for i in 90:
		await _tree.physics_frame
		speeds.append(_mover.get_speed())
		lead.append(_flat_distance(_player.global_position, _mover.get_destination()))
	var held_distance := _flat_distance(start, _player.global_position)
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	await _tree.physics_frame
	await _tree.physics_frame
	var release_position := _player.global_position
	var destination_at_release := _mover.get_destination()
	var marker_shown := _marker.visible
	var after := PackedFloat32Array()
	for i in 600:
		await _tree.physics_frame
		after.append(_mover.get_speed())
		if _mover.get_speed() == 0.0 and not _mover.has_destination():
			break
	print("held 1.5 s: moved %.2f m, speeds (every 10th): %s" % [held_distance, _fmt(_every(speeds, 10))])
	print("   target ahead of the player (every 10th tick), m: %s" % _fmt(_every(lead, 10)))
	print("after release: ran %.2f m more in %.2f s, speeds (every 3rd): %s" % [
		_flat_distance(release_position, _player.global_position), after.size() * DT, _fmt(_every(after, 3))])
	# The character starts running when the press becomes a hold (hold_delay 0.2 s) and accelerates for 0.35 s.
	_expect(_min(speeds.slice(45)) > 0.9 * _mover.settings.max_speed, "keeps running while held")
	_expect(not _mover.has_destination() and _mover.get_speed() == 0.0, "stops after release")
	if stop_on_release:
		_expect(after.size() * DT <= _mover.settings.stop_time + 0.1, "stops right away, smoothly")
	else:
		_expect(marker_shown, "marker shows where the player will stop")
		_expect(_flat_distance(_player.global_position, destination_at_release) < 0.05, "runs to the last cursor point")
	input.stop_on_release = false
	input.hold_mode = PointClickMoveInput.HoldMode.STEER


func _check_camera_steer_up_the_ramp() -> void:
	print("\n== left, then right button: run where the camera looks, up the ramp")
	await _teleport(Vector3(10, 0, 18))
	_rig.look_along(Vector3(1, 0, 0))
	await _settle_camera()
	var center := _tree.root.get_visible_rect().size / 2.0
	_send_motion(center, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, center)
	for i in 6:
		await _tree.physics_frame
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	var path_changes := [0]
	var on_path_changed := func() -> void: path_changes[0] += 1
	_mover.path_changed.connect(on_path_changed)
	var steering_ticks := 0
	var time := 0.0
	while time < 5.0 and _player.global_position.x < 25.0:
		await _tree.physics_frame
		time += DT
		if _mover.is_steering():
			steering_ticks += 1
	_mover.path_changed.disconnect(on_path_changed)
	var reached := _player.global_position
	var alignment := _mover.get_heading().dot(Vector3(1, 0, 0))
	_send_button(MOUSE_BUTTON_LEFT, false, center)
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	for i in 60:
		await _tree.physics_frame
	print("reached %s in %.2f s, steering ticks %d, path rebuilds while steering %d, heading vs camera %.3f" % [
		reached.snapped(Vector3.ONE * 0.01), time, steering_ticks, path_changes[0], alignment])
	_expect(steering_ticks > 0 and path_changes[0] == 0, "runs by direction, no path rebuilds")
	_expect(reached.x >= 25.0 and absf(reached.y - 1.6) < 0.05, "climbs the ramp onto the platform")
	_expect(alignment > 0.99, "runs where the camera looks")
	_expect(_mover.get_speed() == 0.0, "stops after release")


func _check_camera_steer_turn() -> void:
	print("\n== right, then left button: run at once where the camera looks, turn with the camera")
	await _teleport(Vector3.ZERO)
	_rig.look_along(Vector3(0, 0, -1))
	await _settle_camera()
	var center := _tree.root.get_visible_rect().size / 2.0
	_send_motion(center, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, true, center)
	await _tree.physics_frame
	await _tree.physics_frame
	var immediate := _mover.is_steering() and not _mover.has_destination()
	var marker_after_press := _marker.visible
	for i in 30:
		await _tree.physics_frame
	# 360 px to the right at 0.25 °/px turns the camera right by 90°: it looks along +X.
	_send_motion(center, Vector2(360, 0))
	for i in 40:
		await _tree.physics_frame
	var alignment := _mover.get_heading().dot(Vector3(1, 0, 0))
	var speed_after_turn := _mover.get_speed()
	_send_button(MOUSE_BUTTON_LEFT, false, center)
	var after := 0
	for i in 600:
		await _tree.physics_frame
		after += 1
		if _mover.get_speed() == 0.0:
			break
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	await _tree.physics_frame
	print(("steering at once %s, marker %s; after 90 deg camera turn: heading vs camera %.3f, speed %.2f; " +
			"stopped %.2f s after releasing left") % [
		immediate, marker_after_press, alignment, speed_after_turn, after * DT])
	_expect(immediate and not marker_after_press, "starts running by the camera at once, without a click point")
	_expect(alignment > 0.99 and speed_after_turn > 0.9 * _mover.settings.max_speed,
			"turns with the camera at full speed")
	_expect(after * DT <= _mover.settings.stop_time + 0.1, "releasing the left button stops the run")


## RMB + WASD and LMB + RMB + A/D in both modes (sidestep and turn). The keys go through input actions.
## The run direction comes from NavigationMover: it does not depend on whether the character is blocked by an obstacle.
func _check_camera_keys() -> void:
	print("\n== keys with the right button (WASD) and with both buttons (A/D): sidestep and turn modes")
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	var keys_before := input.keys_with_camera
	var steer_keys_before := input.keys_with_camera_steer
	await _teleport(Vector3.ZERO)
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	var center := _tree.root.get_visible_rect().size / 2.0
	var look := _camera_forward()
	var f := Vector3(look.x, 0.0, look.z).normalized()
	var r := f.cross(Vector3.UP)
	var run := _mover.settings.max_speed
	var back := run * _mover.settings.backward_speed_multiplier
	# Diagonally backward while facing forward: the backward part is cos 45° of the motion, so the slowdown is partial.
	var back_side := run * lerpf(1.0, _mover.settings.backward_speed_multiplier, cos(PI / 4.0))
	_send_motion(center, Vector2.ZERO)

	Input.action_press(&"move_forward")
	for i in 30:
		await _tree.physics_frame
	Input.action_release(&"move_forward")
	var idle_without_rmb := not _mover.is_moving() and _mover.get_speed() == 0.0
	_expect(idle_without_rmb, "WASD without the right button does nothing")

	# Keys, where the character goes, where it faces, speed.
	var sidestep := [
		[[&"move_forward"], f, f, run],
		[[&"move_left"], -r, f, run],
		[[&"move_right"], r, f, run],
		[[&"move_back"], -f, f, back],
		[[&"move_back", &"move_left"], -(f + r).normalized(), f, back_side],
		[[&"move_forward", &"move_right"], (f + r).normalized(), f, run],
	]
	var turn := [
		[[&"move_forward"], f, f, run],
		[[&"move_left"], -r, -r, run],
		[[&"move_right"], r, r, run],
		[[&"move_back"], -f, -f, run],
		[[&"move_forward", &"move_left"], (f - r).normalized(), (f - r).normalized(), run],
		[[&"move_back", &"move_right"], (r - f).normalized(), (r - f).normalized(), run],
	]
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	input.keys_with_camera = PointClickMoveInput.KeysMode.SIDESTEP
	var sidestep_result := await _run_key_cases(sidestep)
	await _ticks_until_stopped(60)
	for i in 10:
		await _tree.physics_frame
	var face_after_stop := _flat_angle(_visual_forward(), f)
	input.keys_with_camera = PointClickMoveInput.KeysMode.TURN
	var turn_result := await _run_key_cases(turn)
	var stop_time := await _ticks_until_stopped(60)
	print("right button, SIDESTEP: %s; faces %.2f deg off forward after the stop" % [
		sidestep_result.report, face_after_stop])
	print("right button, TURN: %s; stopped in %.2f s" % [turn_result.report, stop_time])
	_expect(sidestep_result.ok and face_after_stop < 2.0,
			"SIDESTEP: faces where the camera looks; A/D sideways, S backward and slower; " +
			"keeps facing so after the stop")
	_expect(turn_result.ok, "TURN: faces the way it goes; A/D turn left and right, S turns to the camera at full speed")
	_expect(stop_time >= 0.0 and stop_time <= _mover.settings.stop_time + 0.1,
			"stops smoothly when the keys are released")

	Input.action_press(&"move_forward")
	for i in 30:
		await _tree.physics_frame
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	var stop_time_rmb := await _ticks_until_stopped(60)
	Input.action_release(&"move_forward")
	input.keys_with_camera = PointClickMoveInput.KeysMode.OFF
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	Input.action_press(&"move_forward")
	for i in 30:
		await _tree.physics_frame
	var idle_when_off := not _mover.is_moving() and _mover.get_speed() == 0.0
	Input.action_release(&"move_forward")
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	input.keys_with_camera = PointClickMoveInput.KeysMode.SIDESTEP
	print("right button released: stopped in %.2f s; OFF: stands %s" % [stop_time_rmb, idle_when_off])
	_expect(stop_time_rmb >= 0.0 and stop_time_rmb <= _mover.settings.stop_time + 0.1,
			"stops smoothly when the right button is released")
	_expect(idle_when_off, "keys_with_camera OFF: right button + W does nothing")

	# RMB alone (to turn the camera) does not cancel the run to a click point, and a click turns the character to face
	# the run again.
	var target := _player.global_position - r * 4.0
	target.y = 0.0
	var screen := _camera.unproject_position(target)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	for i in 3:
		await _tree.physics_frame
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	for i in 27:
		await _tree.physics_frame
	var click_kept := _mover.has_destination() and _mover.get_destination().distance_to(target) < 0.05
	var click_face := _flat_angle(_visual_forward(), _mover.get_heading())
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	_mover.stop()
	await _ticks_until_stopped(60)
	print("click, then the right button alone: still runs to the clicked point %s, faces %.2f deg off the run" % [
		click_kept, click_face])
	_expect(click_kept, "the right button alone does not cancel the run to a clicked point")
	_expect(click_face < 2.0, "a click after sidestepping faces the run again")

	# Both buttons: forward; A/D: diagonally forward, facing forward (SIDESTEP) or along the run (TURN); OFF: without
	# them.
	_send_motion(center, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	_send_button(MOUSE_BUTTON_LEFT, true, center)
	var both := PackedStringArray()
	var both_ok := true
	for mode: int in [PointClickMoveInput.KeysMode.SIDESTEP, PointClickMoveInput.KeysMode.TURN,
			PointClickMoveInput.KeysMode.OFF]:
		input.keys_with_camera_steer = mode as PointClickMoveInput.KeysMode
		for side: Array in [[&"move_left", -1.0], [&"move_right", 1.0]]:
			Input.action_press(side[0])
			for i in 45:
				await _tree.physics_frame
			var diagonal := (f + r * float(side[1])).normalized()
			var expected_run := f if mode == PointClickMoveInput.KeysMode.OFF else diagonal
			var expected_face := diagonal if mode == PointClickMoveInput.KeysMode.TURN else f
			var run_angle := _flat_angle(_mover.get_heading(), expected_run)
			var face_angle := _flat_angle(_visual_forward(), expected_face)
			both_ok = both_ok and run_angle < 1.0 and face_angle < 2.0 and absf(_mover.get_speed() - run) < 0.05
			both.append("%s %s: run %.2f, face %.2f deg" % [
				PointClickMoveInput.KeysMode.keys()[mode], side[0], run_angle, face_angle])
			Input.action_release(side[0])
	input.keys_with_camera_steer = PointClickMoveInput.KeysMode.SIDESTEP
	print("both buttons: %s" % ", ".join(both))
	_expect(both_ok,
			"both buttons + A/D: forward-diagonal facing forward (SIDESTEP) or the run (TURN); OFF ignores A/D")

	# RMB + W, then LMB pressed and released: the walk does not stop.
	Input.action_press(&"move_forward")
	_send_button(MOUSE_BUTTON_LEFT, false, center)
	for i in 30:
		await _tree.physics_frame
	var across := PackedFloat32Array()
	_send_button(MOUSE_BUTTON_LEFT, true, center)
	for i in 20:
		await _tree.physics_frame
		across.append(_mover.get_speed())
	_send_button(MOUSE_BUTTON_LEFT, false, center)
	for i in 20:
		await _tree.physics_frame
		across.append(_mover.get_speed())
	var after_left := _mover.is_steering()
	Input.action_release(&"move_forward")
	_send_button(MOUSE_BUTTON_RIGHT, false, center)
	await _ticks_until_stopped(60)
	print("right button + W, left button pressed and released: lowest speed %.2f, still walking %s" % [
		_min(across), after_left])
	_expect(_min(across) > 0.95 * run and after_left,
			"left button pressed and released over right button + W: the walk goes on without a stop")
	input.keys_with_camera = keys_before
	input.keys_with_camera_steer = steer_keys_before


## Presses the keys of each case [code][keys, where it goes, where it faces, speed][/code] for 45 ticks in a row (the
## next case in the same frame, without a stop) and compares the run direction, the facing and the speed.
func _run_key_cases(cases: Array) -> Dictionary:
	var report := PackedStringArray()
	var ok := true
	for case: Array in cases:
		var keys: Array = case[0]
		for action: StringName in keys:
			Input.action_press(action)
		for i in 45:
			await _tree.physics_frame
		var run_angle := _flat_angle(_mover.get_heading(), case[1])
		var face_angle := _flat_angle(_visual_forward(), case[2])
		var speed_error := absf(_mover.get_speed() - float(case[3]))
		ok = ok and run_angle < 1.0 and face_angle < 2.0 and speed_error < 0.05
		var names := PackedStringArray()
		for action: StringName in keys:
			names.append(String(action).trim_prefix("move_"))
		report.append("%s %.2f/%.2f deg %.2f m/s" % ["+".join(names), run_angle, face_angle, _mover.get_speed()])
		for action: StringName in keys:
			Input.action_release(action)
	return {ok = ok, report = ", ".join(report)}


## The run to a click point is dropped for steering by keys with RMB: the click marker fades out. RMB alone (to turn
## the camera) leaves the run alone, and the marker stays.
func _check_keys_drop_click_point() -> void:
	print("\n== right button + keys drop the run to a click point, its marker fades out")
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	var keys_before := input.keys_with_camera
	input.keys_with_camera = PointClickMoveInput.KeysMode.SIDESTEP
	await _teleport(Vector3.ZERO)
	await _settle_camera()
	var screen := _camera.unproject_position(Vector3(6, 0, 6))
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(2)
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	await _ticks(10)
	var shown := _marker.visible and _mover.has_destination()
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	await _ticks(20)
	var kept_by_right_only := _marker.visible and _mover.has_destination()
	Input.action_press(&"move_left")
	await _ticks(40)
	var by_keys := _mover.is_steering() and not _mover.has_destination()
	var faded := not _marker.visible
	Input.action_release(&"move_left")
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	await _ticks_until_stopped(60)
	print(("after the click: marker and point %s; right button alone: %s; right button + A: by keys %s, " +
			"marker faded %s") % [shown, kept_by_right_only, by_keys, faded])
	_expect(shown, "a click starts the run and shows the marker")
	_expect(kept_by_right_only, "the right button alone (to turn the camera) keeps the run and the marker")
	_expect(by_keys and faded, "right button + A: walking by keys, the click point is dropped and its marker fades out")
	input.keys_with_camera = keys_before


## A headless window does not change the mouse mode (it is always "visible"), so the check looks at what the component
## decided.
func _check_hold_hides_cursor() -> void:
	print("\n== the cursor hides while the left button is held to run")
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	input.hold_mode = PointClickMoveInput.HoldMode.STEER
	await _teleport(Vector3.ZERO)
	await _settle_camera()
	var size := _tree.root.get_visible_rect().size
	var screen := Vector2(size.x * 0.6, size.y * 0.45)
	_send_motion(screen, Vector2.ZERO)

	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	for i in 6:
		await _tree.physics_frame
	var hidden_while_unclear := input.is_cursor_hidden()
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	for i in 3:
		await _tree.physics_frame
	var hidden_after_click := input.is_cursor_hidden()
	for i in 600:
		await _tree.physics_frame
		if not _mover.has_destination():
			break

	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	for i in 16:
		await _tree.physics_frame
	var hidden_while_held := input.is_cursor_hidden()
	_send_key(KEY_F10)
	await _frames(2)
	var hidden_in_menu := input.is_cursor_hidden()
	_send_key(KEY_ESCAPE)
	await _frames(2)
	await _tree.physics_frame
	var hidden_after_menu := input.is_cursor_hidden()
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	for i in 3:
		await _tree.physics_frame
	var hidden_after_release := input.is_cursor_hidden()

	input.hide_cursor_while_held = false
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	for i in 16:
		await _tree.physics_frame
	var hidden_when_off := input.is_cursor_hidden()
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	input.hide_cursor_while_held = true
	for i in 600:
		await _tree.physics_frame
		if _mover.get_speed() == 0.0:
			break
	print(("hidden: while click or hold is unclear %s, after a click %s, while held %s, in the menu %s, " +
			"back from the menu %s, after release %s, setting off %s") % [hidden_while_unclear, hidden_after_click,
			hidden_while_held, hidden_in_menu, hidden_after_menu, hidden_after_release, hidden_when_off])
	_expect(not hidden_while_unclear and not hidden_after_click, "a click does not hide the cursor")
	_expect(hidden_while_held and not hidden_after_release, "hidden while held, shown after release")
	_expect(not hidden_in_menu and hidden_after_menu, "shown in the menu, hidden again if the button is still held")
	_expect(not hidden_when_off, "hide_cursor_while_held off: the cursor stays")
