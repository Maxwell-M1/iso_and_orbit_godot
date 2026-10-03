extends "res://tests/check_suite.gd"
## Sprint and fatigue, releasing Shift, the jump, the character's signals (steps, jump, landing, sprint) and the
## sounds on them.


func _checks() -> Array[Callable]:
	return [
		_check_sprint,
		_check_sprint_key_release,
		_check_jump,
		_check_character_events,
		_check_character_sounds,
	]


## Sprint on Shift, through the input action, as for the player. Stamina is spent faster than usual here (2 s instead
## of 5) so that the obstacle-free strip by the south fence is long enough.
func _check_sprint() -> void:
	print("\n== sprint (Shift): faster, stamina runs out, recovers, sprint goes on")
	var stamina := _player.stamina
	var bar: StaminaBar = _main.get_node("Hud/StaminaBar")
	var default_duration := _player.sprint_duration
	_player.sprint_duration = 2.0
	stamina.refill()
	var normal := _mover.settings.max_speed
	var fast := normal * _mover.settings.sprint_speed_multiplier

	await _teleport(Vector3(-30, 0, 34))
	Input.action_press(&"sprint")
	for i in 30:
		await _tree.physics_frame
	var spent_standing := 1.0 - stamina.get_ratio()
	_mover.move_to(Vector3(25, 0, 34))
	var speeds := PackedFloat32Array()
	var exhausted_at := -1.0
	var recovered_at := -1.0
	var bar_shown := false
	var bar_red := false
	var time := 0.0
	while time < 6.5:
		await _tree.physics_frame
		time += DT
		speeds.append(_mover.get_speed())
		if exhausted_at < 0.0 and stamina.is_exhausted():
			exhausted_at = time
		elif exhausted_at > 0.0 and recovered_at < 0.0 and not stamina.is_exhausted():
			recovered_at = time
		if time > 0.5 and exhausted_at < 0.0:
			bar_shown = bar.modulate.a > 0.99
		if exhausted_at > 0.0 and recovered_at < 0.0:
			bar_red = bar.theme_type_variation == bar.exhausted_variation
	Input.action_release(&"sprint")
	_mover.stop()
	var tick := func(seconds: float) -> int: return clampi(roundi(seconds / DT), 0, speeds.size())
	var sprint_top := _max(speeds.slice(0, tick.call(exhausted_at)))
	var tired_top := _max(speeds.slice(tick.call(exhausted_at + 0.5), tick.call(recovered_at)))
	var again_top := _max(speeds.slice(tick.call(recovered_at + 0.5)))
	var expected_rest := stamina.recovery_delay + stamina.recover_ratio * stamina.max_value / stamina.recovery_rate
	print(("Shift while standing spent %.3f; top speed %.2f m/s (normal %.2f, sprint %.2f); exhausted after %.2f s; " +
			"tired top speed %.2f; rested in %.2f s (expected %.2f); then top speed %.2f; " +
			"bar shown %s, red while tired %s") % [
		spent_standing, sprint_top, normal, fast, exhausted_at, tired_top, recovered_at - exhausted_at, expected_rest,
		again_top, bar_shown, bar_red])
	_expect(spent_standing == 0.0, "Shift while standing does not tire")
	_expect(absf(sprint_top - fast) < 0.05, "Shift runs sprint_speed_multiplier times faster")
	_expect(absf(exhausted_at - _player.sprint_duration) < 0.1, "stamina lasts sprint_duration")
	_expect(absf(tired_top - normal) < 0.05, "tired: runs at normal speed, no sprint")
	_expect(absf(recovered_at - exhausted_at - expected_rest) < 0.1, "rests until recover_ratio after recovery_delay")
	_expect(absf(again_top - fast) < 0.05, "rested with Shift still held: sprints again")
	_expect(bar_shown and bar_red, "the stamina bar shows while spending and turns red while tired")
	stamina.refill()
	await _frames(roundi((bar.fade_time + 0.1) / DT))
	_expect(bar.modulate.a < 0.01, "full stamina: the bar fades out")

	_player.can_sprint = false
	await _teleport(Vector3(-30, 0, 34))
	Input.action_press(&"sprint")
	_mover.move_to(Vector3(25, 0, 34))
	var off_speeds := PackedFloat32Array()
	for i in 60:
		await _tree.physics_frame
		off_speeds.append(_mover.get_speed())
	Input.action_release(&"sprint")
	_mover.stop()
	print("can_sprint off: top speed with Shift %.2f, stamina %.2f" % [_max(off_speeds), stamina.get_ratio()])
	_expect(absf(_max(off_speeds) - normal) < 0.05 and stamina.get_ratio() == 1.0, "can_sprint off: Shift does nothing")
	_player.can_sprint = true

	# Without fatigue: the stamina lasts 2 s, yet the sprint goes on for 3 s and spends no stamina.
	_player.sprint_tires = false
	await _teleport(Vector3(-30, 0, 34))
	Input.action_press(&"sprint")
	_mover.move_to(Vector3(25, 0, 34))
	for i in 180:
		await _tree.physics_frame
	var untired_speed := _mover.get_speed()
	Input.action_release(&"sprint")
	_mover.stop()
	print("sprint_tires off: speed after 3 s with Shift %.2f, stamina %.2f" % [untired_speed, stamina.get_ratio()])
	_expect(absf(untired_speed - fast) < 0.05 and stamina.get_ratio() == 1.0,
			"sprint_tires off: sprints on and on, no stamina spent")
	_player.sprint_tires = true

	# Shift as a toggle: on, off, on, and it turns off by itself when the character is exhausted (stamina for 1 s).
	var actions: CharacterActionInput = _main.get_node("PlayerActionInput")
	actions.sprint_mode = CharacterActionInput.SprintMode.TOGGLE
	_player.sprint_duration = 1.0
	await _teleport(Vector3(-30, 0, 34))
	_mover.move_to(Vector3(25, 0, 34))
	_send_key(KEY_SHIFT)
	# Accelerating from a standstill to 8.25 m/s takes 0.53 s.
	for i in 45:
		await _tree.physics_frame
	var toggled_on := _mover.get_speed()
	_send_key(KEY_SHIFT)
	for i in 30:
		await _tree.physics_frame
	var toggled_off := _mover.get_speed()
	_send_key(KEY_SHIFT)
	await _wait_until(func() -> bool: return stamina.is_exhausted(), 120)
	# The character got exhausted in this tick; the input notices it at the start of the next one (the input runs
	# before the character).
	await _tree.physics_frame
	var off_when_tired := not actions.is_sprint_toggled()
	await _wait_until(func() -> bool: return not stamina.is_exhausted(), 300)
	for i in 30:
		await _tree.physics_frame
	var after_rest := _mover.get_speed()
	_mover.stop()
	print("Shift toggles: on %.2f, off %.2f, turned off when tired %s, after the rest %.2f" % [
		toggled_on, toggled_off, off_when_tired, after_rest])
	_expect(absf(toggled_on - fast) < 0.05 and absf(toggled_off - normal) < 0.05,
			"Shift in TOGGLE mode: press on, press off")
	_expect(off_when_tired and absf(after_rest - normal) < 0.05,
			"Shift in TOGGLE mode: tired turns the sprint off for good")
	actions.sprint_mode = CharacterActionInput.SprintMode.HOLD
	_player.sprint_duration = default_duration
	stamina.refill()
	for i in 120:
		await _tree.physics_frame
		if _mover.get_speed() == 0.0:
			break


## Releasing Shift in the "hold" mode, with real keyboard and mouse events: while running, while running with LMB
## held, in the settings window, on a mode change; and a lost release (Shift is released, but there was no event for
## it).
func _check_sprint_key_release() -> void:
	print("\n== Shift released in the HOLD mode: the sprint always ends")
	var actions: CharacterActionInput = _main.get_node("PlayerActionInput")
	var ui: UiRoot = _main.get_node("UiRoot")
	_player.stamina.refill()
	await _teleport(Vector3(-30, 0, 34))
	_mover.move_to(Vector3(25, 0, 34))
	var report := PackedStringArray()

	_send_shift(true)
	await _ticks(20)
	var on := _player.is_sprinting()
	_send_shift(false)
	await _ticks(2)
	report.append("running: on %s, after release %s" % [on, _player.is_sprinting()])
	var ok := on and not _player.is_sprinting()

	_send_shift(true)
	await _ticks(5)
	_send_key(KEY_F10, true)
	await _frames(3)
	_send_shift(false)
	await _frames(3)
	_send_key(KEY_ESCAPE)
	await _frames(2)
	await _ticks(3)
	report.append("released in the settings window: %s, window open %s" % [
		_player.is_sprinting(), ui.has_open_screens()])
	ok = ok and not _player.is_sprinting() and not ui.has_open_screens()

	actions.sprint_mode = CharacterActionInput.SprintMode.TOGGLE
	_send_key(KEY_SHIFT)
	await _ticks(3)
	var toggled := _player.is_sprinting()
	actions.sprint_mode = CharacterActionInput.SprintMode.HOLD
	await _ticks(2)
	report.append("toggled on, then HOLD: %s -> %s" % [toggled, _player.is_sprinting()])
	ok = ok and toggled and not _player.is_sprinting()

	# A lost release: Shift is "held" by the key event, but the mouse reports that the modifier is already released.
	_send_shift(true)
	await _ticks(3)
	_send_motion_with_shift(true)
	await _ticks(3)
	var kept_while_held := _player.is_sprinting()
	_send_motion_with_shift(false)
	await _ticks(2)
	report.append(("lost release: kept while the mouse reports Shift held %s, " +
			"released by a mouse event without Shift %s") % [kept_while_held, not _player.is_sprinting()])
	var lost_ok := kept_while_held and not _player.is_sprinting() and not Input.is_action_pressed(&"sprint")
	_mover.stop()
	await _ticks_until_stopped(120)

	# With LMB held (running after the cursor): when Shift is released, the sprint ends, but running after the cursor
	# does not.
	await _teleport(Vector3(-30, 0, 34))
	_rig.look_along(Vector3.RIGHT)
	await _settle_camera()
	var size := _tree.root.get_visible_rect().size
	var screen := Vector2(size.x * 0.5, size.y * 0.3)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _ticks(20)
	_send_shift(true)
	await _ticks(20)
	var hold_on := _player.is_sprinting()
	_send_shift(false)
	await _ticks(2)
	var hold_running := _mover.is_steering()
	report.append("left button hold: on %s, after release %s, still running %s" % [
		hold_on, _player.is_sprinting(), hold_running])
	ok = ok and hold_on and not _player.is_sprinting() and hold_running
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	await _ticks_until_stopped(120)
	print("; ".join(report))
	_expect(ok, "HOLD: releasing Shift ends the sprint while running, in a left button hold, " +
			"in the settings window and after TOGGLE")
	_expect(lost_ok, "HOLD: a lost Shift release is caught by the modifier state of the next mouse event")
	_player.stamina.refill()


## Shift as a real keyboard event: the key itself has the modifier held while it is pressed (as on Windows).
func _send_shift(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.physical_keycode = KEY_SHIFT
	event.pressed = pressed
	event.shift_pressed = pressed
	Input.parse_input_event(event)


## A one-pixel mouse move with the Shift modifier held or not.
func _send_motion_with_shift(shift: bool) -> void:
	var event := InputEventMouseMotion.new()
	var position := _tree.root.get_visible_rect().size / 2.0
	event.position = _tree.root.get_final_transform() * position
	event.global_position = event.position
	event.relative = Vector2(1, 0)
	event.screen_relative = Vector2(1, 0)
	event.shift_pressed = shift
	Input.parse_input_event(event)


## The jump on Space, through the input action. The 1.6 m platform: x from 22 to 30, z from 14 to 22.
func _check_jump() -> void:
	print("\n== jump (Space)")
	var jumps := [0]
	var on_jumped := func() -> void: jumps[0] += 1
	_player.jumped.connect(on_jumped)
	var gravity := absf(_player.get_gravity().y) * _player.gravity_scale

	await _teleport(Vector3.ZERO)
	_send_key(KEY_SPACE)
	var flight := await _watch_flight()
	var expected_air := 2.0 * _player.get_jump_speed() / gravity
	print("in place: apex %.3f m (jump_height %.2f), %.3f s in the air (expected %.3f)" % [
		flight.apex, _player.jump_height, flight.air_time, expected_air])
	_expect(jumps[0] == 1 and absf(flight.apex - _player.jump_height) < 0.02, "jumps jump_height high")
	_expect(absf(flight.air_time - expected_air) < 2.5 * DT, "stays in the air as long as the physics says")

	# A press shortly before landing is remembered; one that comes too early is not.
	_send_key(KEY_SPACE)
	await _wait_until(func() -> bool: return not _player.is_on_floor(), 10)
	await _wait_until(func() -> bool: return _player.velocity.y < 0.0 and _player.global_position.y < 0.4, 60)
	_send_key(KEY_SPACE)
	var ground_ticks := 0
	for i in 30:
		await _tree.physics_frame
		if jumps[0] == 3:
			break
		if _player.is_on_floor():
			ground_ticks += 1
	var buffered: bool = jumps[0] == 3
	await _wait_until(func() -> bool: return _player.velocity.y <= 0.0, 60)
	_send_key(KEY_SPACE)
	await _watch_flight()
	for i in 10:
		await _tree.physics_frame
	print(("pressed 0.4 m before landing: jumped again %s after %d ticks on the ground; " +
			"pressed at the apex: jumps %d") % [buffered, ground_ticks, jumps[0]])
	_expect(buffered and ground_ticks <= 1, "a press just before landing jumps on landing")
	_expect(jumps[0] == 3, "a press too early is forgotten")

	var guard: LedgeGuard = _player.ledge_guard
	guard.enabled = false
	var coyote := await _jump_after_leaving_edge(3)
	var late := await _jump_after_leaving_edge(9)
	guard.enabled = true
	print("off the edge, guard off: Space 3 ticks after leaving the floor jumps %s, 9 ticks after %s" % [coyote, late])
	_expect(coyote and not late, "coyote_time: a late press still jumps, a too late one does not")

	await _teleport(Vector3(25, 1.6, 17))
	_mover.steer(Vector3.FORWARD)
	for i in 90:
		await _tree.physics_frame
	var held_at := _player.global_position
	_send_key(KEY_SPACE)
	var air_speeds := PackedFloat32Array()
	for i in 120:
		await _tree.physics_frame
		if not _player.is_on_floor():
			air_speeds.append(_flat_speed(_player.velocity))
		elif air_speeds.size() > 3:
			break
	_mover.stop()
	print("ledge guard on, held at z %.2f: Space -> landed at %s, horizontal speed in the air %.2f" % [
		held_at.z, _player.global_position.snapped(Vector3.ONE * 0.01), _median(air_speeds)])
	_expect(held_at.y > 1.55 and _player.global_position.y < 0.05 and _player.global_position.z < 14.0,
			"the ledge guard does not hold a jump: jumps off the edge")
	_expect(absf(_median(air_speeds) - _mover.settings.max_speed) < 0.1, "keeps running speed in the air")

	_player.jump_height = 1.5
	await _teleport(Vector3.ZERO)
	_send_key(KEY_SPACE)
	var high := await _watch_flight()
	print("jump_height 1.5: apex %.3f m" % high.apex)
	_expect(absf(high.apex - 1.5) < 0.02, "jump_height sets the height")
	_player.jump_height = 1.0

	_player.can_jump = false
	await _teleport(Vector3.ZERO)
	var jumps_before: int = jumps[0]
	_send_key(KEY_SPACE)
	for i in 20:
		await _tree.physics_frame
	print("can_jump off: jumps after Space %d, on floor %s" % [jumps[0] - jumps_before, _player.is_on_floor()])
	_expect(jumps[0] == jumps_before and _player.is_on_floor(), "can_jump off: Space does nothing")
	_player.can_jump = true
	_player.jumped.disconnect(on_jumped)
	await _teleport(Vector3.ZERO)


## Waits for the takeoff and the landing. Returns the highest point of the feet and the time in the air.
func _watch_flight() -> Dictionary:
	var apex := _player.global_position.y
	var air_time := 0.0
	for i in 180:
		await _tree.physics_frame
		apex = maxf(apex, _player.global_position.y)
		if not _player.is_on_floor():
			air_time += DT
		elif air_time > 0.0:
			break
	return {apex = apex, air_time = air_time}


## A run north off the platform without the ledge guard; Space [param ticks] ticks after leaving the edge. Whether
## the character jumped.
func _jump_after_leaving_edge(ticks: int) -> bool:
	await _teleport(Vector3(25, 1.6, 15.5))
	var jumped := [false]
	var on_jumped := func() -> void: jumped[0] = true
	_player.jumped.connect(on_jumped)
	_mover.steer(Vector3.FORWARD)
	for i in 120:
		await _tree.physics_frame
		if not _player.is_on_floor():
			break
	for i in ticks - 1:
		await _tree.physics_frame
	_send_key(KEY_SPACE)
	for i in 3:
		await _tree.physics_frame
	_mover.stop()
	for i in 120:
		await _tree.physics_frame
		if _player.is_on_floor() and _player.global_position.y < 0.05:
			break
	_player.jumped.disconnect(on_jumped)
	return jumped[0]


## Character signals: steps by the distance covered (more often while sprinting), jump and landing, the start and the
## end of the sprint. Sounds hook onto them ([CharacterSounds]).
func _check_character_events() -> void:
	print("\n== character events: steps, jump and landing, sprint start and end")
	var events := {steps = 0, sprint_steps = 0, jumps = 0, landings = [], sprint = []}
	var on_stepped := func(sprinting: bool) -> void:
		events.steps += 1
		if sprinting:
			events.sprint_steps += 1
	var on_jumped := func() -> void: events.jumps += 1
	var on_landed := func(speed: float) -> void: events.landings.append(speed)
	var on_sprint := func(sprinting: bool) -> void: events.sprint.append(sprinting)
	_player.stepped.connect(on_stepped)
	_player.jumped.connect(on_jumped)
	_player.landed.connect(on_landed)
	_player.sprint_changed.connect(on_sprint)
	_player.stamina.refill()
	var stride := _player.stride_length

	await _teleport(Vector3(-30, 0, 34))
	await _ticks(30)
	var standing_steps: int = events.steps
	var run := await _run_until_arrived(Vector3(-19, 0, 34), 10.0)
	var run_steps: int = events.steps - standing_steps
	var expected_steps := floori((11.0 - _player.first_step_distance) / stride) + 1

	# A steady run, then a sprint: steps per second grow by the same factor as the speed.
	await _teleport(Vector3(-30, 0, 34))
	_mover.move_to(Vector3(25, 0, 34))
	await _ticks(40)
	var before: int = events.steps
	await _ticks(120)
	var normal_rate: float = (events.steps - before) / 2.0
	Input.action_press(&"sprint")
	await _ticks(40)
	before = events.steps
	var sprint_steps_before: int = events.sprint_steps
	await _ticks(120)
	var sprint_rate: float = (events.steps - before) / 2.0
	var all_sprinting: bool = events.sprint_steps - sprint_steps_before == events.steps - before
	Input.action_release(&"sprint")
	await _ticks(5)
	var sprint_events: Array = events.sprint.duplicate()
	_mover.stop()
	await _ticks_until_stopped(120)

	await _teleport(Vector3.ZERO)
	var steps_before_jump: int = events.steps
	_send_key(KEY_SPACE)
	await _watch_flight()
	await _ticks(5)
	var jump_landings: Array = events.landings.duplicate()
	var steps_in_jump: int = events.steps - steps_before_jump

	_player.ledge_guard.enabled = false
	await _teleport(Vector3(25, 1.6, 15.5))
	events.landings.clear()
	_mover.steer(Vector3.FORWARD)
	await _wait_until(func() -> bool: return not events.landings.is_empty(), 120)
	_mover.stop()
	var drop_landings: Array = events.landings.duplicate()
	_player.ledge_guard.enabled = true

	await _teleport(Vector3(25, 1.6, 18))
	events.landings.clear()
	var ramp := await _run_until_arrived(Vector3(12, 0, 18), 10.0)
	var ramp_landings: int = events.landings.size()

	_player.stepped.disconnect(on_stepped)
	_player.jumped.disconnect(on_jumped)
	_player.landed.disconnect(on_landed)
	_player.sprint_changed.disconnect(on_sprint)
	var drop_expected := sqrt(2.0 * 1.6 * absf(_player.get_gravity().y) * _player.gravity_scale)
	print(("standing: %d steps; 11 m run: %d steps (expected %d, stride %.1f m); " +
			"steps per second %.1f, sprinting %.1f (all flagged sprinting %s); sprint_changed %s; " +
			"jump: jumped %d, landed %s (jump speed %.2f), steps in the air %d; " +
			"off the 1.6 m platform: landed %s (free fall %.2f); down the ramp: %d landings, arrived %s") % [
		standing_steps, run_steps, expected_steps, stride, normal_rate, sprint_rate, all_sprinting, sprint_events,
		events.jumps, jump_landings, _player.get_jump_speed(), steps_in_jump, drop_landings, drop_expected,
		ramp_landings, ramp.arrived])
	_expect(standing_steps == 0 and run.arrived and absi(run_steps - expected_steps) <= 1,
			"steps by the distance run: none standing, one every stride_length")
	var speed_ratio := _mover.settings.sprint_speed_multiplier
	_expect(absf(sprint_rate / normal_rate - speed_ratio) < 0.25 and all_sprinting,
			"sprinting steps come sprint_speed_multiplier times as often and are flagged as sprinting")
	_expect(sprint_events == [true, false], "sprint_changed: true on Shift, false on release")
	_expect(events.jumps == 1 and jump_landings.size() == 1
			and absf(float(jump_landings[0]) - _player.get_jump_speed()) < 0.6 and steps_in_jump == 0,
			"a jump: jumped once, landed once at about the jump speed, no steps in the air")
	_expect(drop_landings.size() == 1 and absf(float(drop_landings[0]) - drop_expected) < 0.6,
			"off a 1.6 m platform: landed at the fall speed")
	_expect(ramp.arrived and ramp_landings == 0, "down the ramp: no landing")


## Character sounds: each signal plays its own sound, and the switches mute their groups. The check emits the signals
## itself, so only [CharacterSounds] is checked; [method _check_character_events] checks that the character emits
## them.
func _check_character_sounds() -> void:
	print("\n== character sounds")
	var sounds: CharacterSounds = _player.get_node("Sounds")
	var loop_stream := sounds.sprint_loop.stream as AudioStreamWAV
	var steps_stream := sounds.footsteps.stream as AudioStreamRandomizer
	# Groups that the default settings turn off are turned on for the check, then restored.
	var enabled_before := [sounds.footsteps_enabled, sounds.jump_enabled, sounds.sprint_enabled]
	sounds.footsteps_enabled = true
	sounds.jump_enabled = true
	sounds.sprint_enabled = true
	await _teleport(Vector3.ZERO)

	_player.stepped.emit(false)
	var step_plays := sounds.footsteps.is_playing() and is_equal_approx(sounds.footsteps.pitch_scale, 1.0)
	_player.stepped.emit(true)
	var sprint_step := is_equal_approx(sounds.footsteps.pitch_scale, sounds.sprint_step_pitch)
	_player.jumped.emit()
	var jump_plays := sounds.jump.is_playing()
	_player.landed.emit(3.0)
	var soft_land := sounds.land.volume_db
	_player.landed.emit(20.0)
	var hard_land := sounds.land.volume_db
	var land_plays := sounds.land.is_playing()
	_player.sprint_changed.emit(true)
	var start_plays := sounds.sprint_start.is_playing() and sounds.is_sprint_loop_playing()
	await _frames(roundi((sounds.sprint_loop_fade + 0.1) / DT))
	var loop_volume := sounds.sprint_loop.volume_db
	_player.sprint_changed.emit(false)
	await _frames(roundi((sounds.sprint_loop_fade + 0.1) / DT))
	var loop_stopped := not sounds.is_sprint_loop_playing()
	print(("loop stream %s, %d step variants; step plays %s, sprint step pitch %s; jump %s; " +
			"landing %.1f dB at 3 m/s, %.1f dB at 20 m/s, plays %s; " +
			"sprint start and loop %s, loop at %.1f dB, stops after the sprint %s") % [
		"looped" if loop_stream != null and loop_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD else "NOT looped",
		steps_stream.streams_count if steps_stream != null else 0, step_plays, sprint_step, jump_plays, soft_land,
		hard_land, land_plays, start_plays, loop_volume, loop_stopped])
	_expect(loop_stream != null and loop_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD
			and steps_stream != null and steps_stream.streams_count == 4,
			"sounds load: the sprint loop is looped, four step variants")
	_expect(step_plays and sprint_step and jump_plays and land_plays and start_plays,
			"every character event plays its sound")
	_expect(is_equal_approx(soft_land, linear_to_db(sounds.min_land_volume)) and is_zero_approx(hard_land),
			"landing is louder the faster the fall")
	_expect(absf(loop_volume - (-14.0)) < 0.5 and loop_stopped,
			"the sprint loop fades in while sprinting and stops after")

	for player: AudioStreamPlayer3D in [sounds.footsteps, sounds.jump, sounds.land, sounds.sprint_start]:
		player.stop()
	sounds.footsteps_enabled = false
	sounds.jump_enabled = false
	sounds.sprint_enabled = false
	_player.stepped.emit(false)
	_player.jumped.emit()
	_player.landed.emit(10.0)
	_player.sprint_changed.emit(true)
	var silent := not (sounds.footsteps.is_playing() or sounds.jump.is_playing() or sounds.land.is_playing()
			or sounds.sprint_start.is_playing() or sounds.is_sprint_loop_playing())
	sounds.footsteps_enabled = enabled_before[0]
	sounds.jump_enabled = enabled_before[1]
	sounds.sprint_enabled = enabled_before[2]
	_player.sprint_changed.emit(false)
	print("all sound groups off: silent %s" % silent)
	_expect(silent, "switched off sound groups stay silent")
