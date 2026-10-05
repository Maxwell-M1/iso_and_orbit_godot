extends "res://tests/check_suite.gd"
## Mouse and keys with real input events: a click, an LMB hold in both modes, LMB + RMB (and RMB released a moment
## before LMB), RMB over a run after the cursor looking around, RMB + WASD and LMB + RMB + A/D in all modes, keys
## dropping the run to a click point, the signal of a new run, the cursor hiding while running with LMB held.


func _checks() -> Array[Callable]:
	return [
		_check_click_input,
		_check_hold_steer,
		_check_hold_follow_point.bind(false),
		_check_hold_follow_point.bind(true),
		_check_camera_steer_up_the_ramp,
		_check_camera_steer_turn,
		_check_camera_steer_release,
		_check_look_around,
		_check_look_around_order,
		_check_camera_keys,
		_check_keys_drop_click_point,
		_check_run_requested,
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
	# The character starts running when the press becomes a hold (hold_delay 0.2 s) and reaches full speed in
	# acceleration_time.
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


## LMB + RMB drive the run where the camera looks. Released one after the other, RMB first, with any gap and without
## the mouse moving, they stop the character on its course: no turn toward the cursor left where it was before and, in
## FOLLOW_POINT, no run on to the point under it. LMB held on keeps the course until the mouse moves; then the cursor
## steers from straight ahead, and a small movement turns the run a little. Without keep_camera_course the cursor takes
## the run over at once from where it was.
func _check_camera_steer_release() -> void:
	print("\n== both buttons released one after the other, the right one first")
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	var stop_time := _mover.settings.stop_time + 0.1
	var report := PackedStringArray()
	var on_course := true
	for mode: int in [PointClickMoveInput.HoldMode.STEER, PointClickMoveInput.HoldMode.FOLLOW_POINT]:
		input.hold_mode = mode as PointClickMoveInput.HoldMode
		for ticks: int in [6, 18, 45]:
			var run := await _release_camera_steer_first(ticks)
			on_course = on_course and run.turn < 2.0 and run.stop >= 0.0 and run.stop <= stop_time
			report.append("%s, LMB %.2f s later: turned %.2f deg, stopped %.2f s after LMB" % [
				PointClickMoveInput.HoldMode.keys()[mode], ticks * DT, run.turn, run.stop])
	input.hold_mode = PointClickMoveInput.HoldMode.STEER
	var nudged := await _release_camera_steer_first(45, Vector2(40, 0))
	input.keep_camera_course = false
	var at_once := await _release_camera_steer_first(6)
	input.keep_camera_course = true
	print("%s; LMB held on, the mouse 40 px to the right after 0.33 s: turned %.1f deg; keep_camera_course off: " % [
		"; ".join(report), nudged.turn] + "turned %.1f deg" % at_once.turn)
	_expect(on_course, "released one after the other with any gap, the buttons stop the run on its course, in both modes")
	_expect(nudged.turn > 3.0 and nudged.turn < 30.0,
			"LMB held on: the mouse takes the run over, from straight ahead and not from the old cursor")
	_expect(at_once.turn > 10.0, "keep_camera_course off: the cursor takes the run over at once, from where it was")


## From (-8, 0, 0), the camera looking east, the cursor low on the left of the window: RMB, then LMB too, so the run
## goes where the camera looks; RMB is released, and LMB [param ticks] ticks later. With [param nudge], the mouse moves
## by it 20 ticks after the RMB release. Returns the largest turn of the run from its direction at the RMB release
## (degrees) and how soon the character stopped after the LMB release (s; −1: it did not).
func _release_camera_steer_first(ticks: int, nudge := Vector2.ZERO) -> Dictionary:
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.RIGHT)
	await _settle_camera()
	var size := _tree.root.get_visible_rect().size
	var screen := Vector2(size.x * 0.3, size.y * 0.8)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(40)
	var heading := _mover.get_heading()
	var turn := 0.0
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	for i in ticks:
		if i == 20 and nudge != Vector2.ZERO:
			_send_motion(screen + nudge, nudge)
		await _tree.physics_frame
		turn = maxf(turn, _flat_angle(heading, _mover.get_heading()))
	_send_button(MOUSE_BUTTON_LEFT, false, screen + nudge)
	var stop := -1.0
	for i in 600:
		await _tree.physics_frame
		turn = maxf(turn, _flat_angle(heading, _mover.get_heading()))
		if not _mover.is_moving() and _mover.get_speed() == 0.0:
			stop = (i + 1) * DT
			break
	return {turn = turn, stop = stop}


## LMB held runs after the cursor, and RMB pressed then only turns the camera, to look around: the run keeps its
## course while the camera turns and after RMB is released, in both modes, and the mouse then steers it on from where it
## aimed, a little for a small movement. In FOLLOW_POINT beside the ramp, the camera turned so that the ramp is in front
## of the point the run goes to: the run does not turn onto the ramp. An aim far ahead that ends up behind the camera
## comes closer, and the course stays. Without look_around_while_held, RMB sends the run where the camera looks; without
## keep_aim_on_camera_turn, the cursor stays in place on the screen, and the camera turn turns the run.
func _check_look_around() -> void:
	print("\n== the left button runs after the cursor, then the right one: looking around, the run keeps its course")
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	var report := PackedStringArray()
	var kept := true
	for mode: int in [PointClickMoveInput.HoldMode.STEER, PointClickMoveInput.HoldMode.FOLLOW_POINT]:
		input.hold_mode = mode as PointClickMoveInput.HoldMode
		var look := await _look_around(Vector3.FORWARD, Vector3(6, 0, 0), Vector2(-360, 0))
		kept = kept and look.during < 2.0 and look.after < 2.0 and look.camera > 80.0
		report.append("%s: the camera turned %.0f deg, the run %.2f deg, after RMB %.2f deg" % [
			PointClickMoveInput.HoldMode.keys()[mode], look.camera, look.during, look.after])
	var ramp := await _look_around(Vector3.FORWARD, Vector3(8, 0, 2), Vector2(-480, 0), Vector2.ZERO,
			Vector3(10, 0, 18))
	input.hold_mode = PointClickMoveInput.HoldMode.STEER
	var nudged := await _look_around(Vector3.FORWARD, Vector3(6, 0, 0), Vector2(-360, 0), Vector2(40, 0))
	var far := await _look_around(Vector3.RIGHT, Vector3(14, 0, 0), Vector2(720, 0))
	input.look_around_while_held = false
	var steered := await _look_around(Vector3.FORWARD, Vector3(6, 0, 0), Vector2(-360, 0))
	input.look_around_while_held = true
	input.keep_aim_on_camera_turn = false
	var curled := await _look_around(Vector3.FORWARD, Vector3(6, 0, 0), Vector2(-360, 0))
	input.keep_aim_on_camera_turn = true
	print(("%s; FOLLOW_POINT beside the ramp, the camera turned %.0f deg: the run %.2f deg, after RMB %.2f deg, rose " +
			"%.2f m; the mouse 40 px to the right after RMB: the run turned %.1f deg; an aim 14 m ahead, the camera " +
			"turned %.0f deg: the run %.2f deg, after RMB %.2f deg; look_around_while_held off: %.1f deg; " +
			"keep_aim_on_camera_turn off: %.1f deg") % ["; ".join(report), ramp.camera, ramp.during, ramp.after,
		ramp.rise, nudged.nudge, far.camera, far.during, far.after, steered.during, curled.during])
	_expect(kept, "RMB over a run after the cursor only turns the camera: the run keeps its course, in both modes")
	_expect(ramp.during < 2.0 and ramp.after < 5.0 and ramp.rise < 0.05,
			"FOLLOW_POINT: the point under the cursor seen from another side does not send the run onto the ramp")
	_expect(nudged.nudge > 2.0 and nudged.nudge < 30.0, "after RMB the mouse steers on from where the run aimed")
	_expect(far.camera > 170.0 and far.during < 2.0 and far.after < 2.0,
			"an aim that ends up behind the camera comes closer, and the run keeps its course")
	_expect(steered.during > 45.0, "look_around_while_held off: RMB sends the run where the camera looks")
	_expect(curled.during > 45.0,
			"keep_aim_on_camera_turn off: the cursor stays in place on the screen, and the camera turn turns the run")


## From [param from], the camera looking along [param view]: LMB is held over the ground at [param aim] from the
## character, and the run goes after the cursor; RMB turns the camera by [param orbit] (px) and is released, LMB held
## on for 1 s. With [param nudge], the mouse moves by it after that. Returns how far the camera turned
## ([code]camera[/code]), the largest turn of the run from its direction at the RMB press while RMB is held
## ([code]during[/code]) and after it is released ([code]after[/code]), and the turn the nudge made
## ([code]nudge[/code]), in degrees; how far the character rose after the release ([code]rise[/code], m).
func _look_around(view: Vector3, aim: Vector3, orbit: Vector2, nudge := Vector2.ZERO,
		from := Vector3(-8, 0, 0)) -> Dictionary:
	await _teleport(from)
	_rig.look_along(view)
	await _settle_camera()
	var screen := _camera.unproject_position(_player.global_position + aim)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(40)
	var heading := _mover.get_heading()
	var camera_before := _camera_forward()
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	await _ticks(2)
	_send_motion(screen, orbit)
	var during := 0.0
	for i in 40:
		await _tree.physics_frame
		during = maxf(during, _flat_angle(heading, _mover.get_heading()))
	var camera := _flat_angle(camera_before, _camera_forward())
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	var after := 0.0
	var ground := _player.global_position.y
	var rise := 0.0
	for i in 60:
		await _tree.physics_frame
		after = maxf(after, _flat_angle(heading, _mover.get_heading()))
		rise = maxf(rise, _player.global_position.y - ground)
	var turn := 0.0
	if nudge != Vector2.ZERO:
		var before := _mover.get_heading()
		_send_motion(screen + nudge, nudge)
		await _ticks(20)
		turn = _flat_angle(before, _mover.get_heading())
	_send_button(MOUSE_BUTTON_LEFT, false, screen + nudge)
	await _ticks_until_stopped(120)
	return {camera = camera, during = during, after = after, nudge = turn, rise = rise}


## Which press order looks around and which runs where the camera looks: RMB pressed within hold_delay of LMB (both
## together) runs where the camera looks; RMB pressed again while the run still keeps the camera's course steers it
## again, and after the cursor has taken the run over it looks around. While looking around the keys do nothing, and
## LMB released stops the run. In FOLLOW_POINT, a hold with the cursor at the feet, which only creeps after its point,
## does not run off when RMB looks around.
func _check_look_around_order() -> void:
	print("\n== the press order: looking around or running where the camera looks")
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	var center := _tree.root.get_visible_rect().size / 2.0

	# Both together: LMB, and RMB within hold_delay. The camera looks north, the cursor is to the east.
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	var east := _camera.unproject_position(_player.global_position + Vector3(6, 0, 0))
	_send_motion(east, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, east)
	await _ticks(6)
	_send_button(MOUSE_BUTTON_RIGHT, true, east)
	await _ticks(40)
	var chord := _flat_angle(_mover.get_heading(), _camera_forward())
	_send_button(MOUSE_BUTTON_LEFT, false, east)
	_send_button(MOUSE_BUTTON_RIGHT, false, east)
	await _ticks_until_stopped(120)

	# RMB, then LMB: the run goes where the camera looks; RMB released and pressed again before the mouse moves.
	var again := await _press_right_again(false)
	# The same, but the mouse moves after the release, and the cursor takes the run over first.
	var after_cursor := await _press_right_again(true)

	# Looking around: D held for 0.5 s, then LMB released with RMB still held.
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.FORWARD)
	await _settle_camera()
	east = _camera.unproject_position(_player.global_position + Vector3(6, 0, 0))
	_send_motion(east, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, east)
	await _ticks(40)
	var heading := _mover.get_heading()
	_send_button(MOUSE_BUTTON_RIGHT, true, east)
	await _ticks(2)
	Input.action_press(&"move_right")
	await _ticks(30)
	var keys_turn := _flat_angle(heading, _mover.get_heading())
	Input.action_release(&"move_right")
	await _ticks(2)
	_send_button(MOUSE_BUTTON_LEFT, false, east)
	var stop := await _ticks_until_stopped(60)
	_send_button(MOUSE_BUTTON_RIGHT, false, east)
	await _ticks(2)

	# FOLLOW_POINT with the cursor at the feet: the character creeps after the point that moves with it; RMB does not
	# send it off.
	input.hold_mode = PointClickMoveInput.HoldMode.FOLLOW_POINT
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.RIGHT)
	await _settle_camera()
	var feet := _camera.unproject_position(_player.global_position + Vector3(0.05, 0, 0))
	_send_motion(feet, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, feet)
	await _ticks(20)
	var speed_before := 0.0
	for i in 20:
		await _tree.physics_frame
		speed_before = maxf(speed_before, _mover.get_speed())
	_send_button(MOUSE_BUTTON_RIGHT, true, feet)
	var fastest := 0.0
	for i in 40:
		await _tree.physics_frame
		fastest = maxf(fastest, _mover.get_speed())
	_send_button(MOUSE_BUTTON_RIGHT, false, feet)
	for i in 30:
		await _tree.physics_frame
		fastest = maxf(fastest, _mover.get_speed())
	_send_button(MOUSE_BUTTON_LEFT, false, feet)
	input.hold_mode = PointClickMoveInput.HoldMode.STEER
	await _ticks_until_stopped(120)
	_send_motion(center, Vector2.ZERO)

	print(("LMB, RMB 0.1 s later: the run %.2f deg off the camera; RMB pressed again on the camera's course: the run " +
			"turned %.1f deg with the camera, after the cursor took over: %.2f deg; looking around, D for 0.5 s: " +
			"turned %.2f deg; LMB released: stopped in %.2f s; FOLLOW_POINT at the feet: at most %.2f m/s before RMB, " +
			"%.2f m/s after") % [chord, again, after_cursor, keys_turn, stop, speed_before, fastest])
	_expect(chord < 2.0, "LMB and RMB pressed together (within hold_delay): the run goes where the camera looks")
	_expect(again > 45.0, "RMB pressed again while the run keeps the camera's course: it steers by the camera again")
	_expect(after_cursor < 2.0, "RMB pressed after the cursor has taken the run over: looking around")
	_expect(keys_turn < 1.0, "while looking around the keys do nothing")
	_expect(stop >= 0.0 and stop <= _mover.settings.stop_time + 0.1, "LMB released while looking around stops the run")
	_expect(speed_before < 0.5 * _mover.settings.max_speed and fastest < speed_before + 0.1,
			"FOLLOW_POINT: a hold with the cursor at the feet does not run off when RMB looks around")


## From (-8, 0, 0), the camera looking east: RMB, then LMB, the run goes where the camera looks; RMB is released, and
## 0.33 s later pressed again and the camera turned by 90°. With [param mouse_first], the mouse moves 40 px before that,
## and the cursor takes the run over. Returns how far the run turned while RMB was held again, degrees.
func _press_right_again(mouse_first: bool) -> float:
	await _teleport(Vector3(-8, 0, 0))
	_rig.look_along(Vector3.RIGHT)
	await _settle_camera()
	var screen := _tree.root.get_visible_rect().size / 2.0
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(30)
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	await _ticks(20)
	if mouse_first:
		_send_motion(screen + Vector2(0, -40), Vector2(0, -40))
		screen += Vector2(0, -40)
		await _ticks(10)
	var heading := _mover.get_heading()
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	await _ticks(2)
	_send_motion(screen, Vector2(-360, 0))
	var turn := 0.0
	for i in 40:
		await _tree.physics_frame
		turn = maxf(turn, _flat_angle(heading, _mover.get_heading()))
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	await _ticks_until_stopped(120)
	return turn


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


## run_requested: once for a click that sends the character to a point, once for a press that becomes a hold, once
## for a walk with the keys and RMB, once for a hold over that walk; not for a click at the point the character is
## already running to, not for RMB alone, and not when the keys carry on a hold that has just ended.
func _check_run_requested() -> void:
	print("\n== the signal of a new run: a click, a hold, the keys with the right button")
	var input: PointClickMoveInput = _main.get_node("PlayerInput")
	var keys_before := input.keys_with_camera
	input.keys_with_camera = PointClickMoveInput.KeysMode.TURN
	var counts := [0]
	var count := func() -> void: counts[0] += 1
	input.run_requested.connect(count)
	await _teleport(Vector3.ZERO)
	await _settle_camera()
	var target := Vector3(3, 0, 3)
	var steps := PackedInt32Array()
	for again: bool in [false, true]:
		# A click, and while the character runs there, a click at the same point.
		var screen := _camera.unproject_position(target)
		_send_motion(screen, Vector2.ZERO)
		_send_button(MOUSE_BUTTON_LEFT, true, screen)
		await _tree.physics_frame
		_send_button(MOUSE_BUTTON_LEFT, false, screen)
		# The release is noticed in the next tick.
		await _ticks(3)
		steps.append(counts[0])
	await _ticks_until_stopped(240)
	var screen := _camera.unproject_position(target)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(30)
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	await _ticks(3)
	await _ticks_until_stopped(120)
	steps.append(counts[0])
	_send_button(MOUSE_BUTTON_RIGHT, true, screen)
	await _ticks(10)
	steps.append(counts[0])
	Input.action_press(&"move_forward")
	await _ticks(20)
	steps.append(counts[0])
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(20)
	steps.append(counts[0])
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	await _ticks(20)
	steps.append(counts[0])
	Input.action_release(&"move_forward")
	_send_button(MOUSE_BUTTON_RIGHT, false, screen)
	await _ticks_until_stopped(60)
	input.run_requested.disconnect(count)
	input.keys_with_camera = keys_before
	var each := PackedInt32Array([steps[0]])
	for i in range(1, steps.size()):
		each.append(steps[i] - steps[i - 1])
	print(("run_requested: a click %d, the same point again %d, a hold %d, the right button alone %d, the keys %d, a " +
			"hold over the keys %d, the keys carrying on after it %d") % Array(each))
	_expect(each == PackedInt32Array([1, 0, 1, 0, 1, 1, 0]),
			"run_requested: once for every new run; not for the same point, the right button alone or the keys carrying on")


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
