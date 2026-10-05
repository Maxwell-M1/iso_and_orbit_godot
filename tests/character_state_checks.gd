extends "res://tests/check_suite.gd"
## What the character reports about itself, for animations and the interface: the state and its changes, the blend of
## speeds, movement and acceleration in the model's axes, turning, floor contact and time in the air, feet and the gait
## cycle, the steps switch, a teleport mid-run, a body turned in the level. Stairs and slopes: up and down a staircase
## without leaving the ground with the real height of every stair, a block too high, a gentle and a steep slope. Routes
## on the level without a false take-off. Floating (CharacterHover): the height and the sway, no steps, a glide over the
## stairs, a ramp without lag, a jump, a ledge and a wall, a slower fall, turning it off and on, a short teleport with
## physics interpolation on and off. While time stands still, the running hero stays as it is. The monitor panel shows
## the state and the latest events. The demo's character is set up without warnings.

## A clear strip along the south fence: the character runs here, and the checks put their obstacles here.
const STRIP_Z := 34.0


func _checks() -> Array[Callable]:
	return [
		_check_setup,
		_check_run_and_sprint,
		_check_jump_and_fall,
		_check_feet,
		_check_steps_switch,
		_check_sidestep_and_turn,
		_check_acceleration,
		_check_teleport,
		_check_turned_body,
		_check_stairs,
		_check_slopes_and_high_block,
		_check_level_routes,
		_check_hover,
		_check_hover_fall,
		_check_hover_toggle,
		_check_hover_teleport,
		_check_time_stopped,
		_check_monitor,
	]


## The demo's character, its ledge guard and its hover have no setup warnings, and mistakes in the setup give them,
## also a fall limited below the landing speed and a jump with nothing to push off with. The spring of the inertia
## stays calm at its stiffest settings, strongly and barely damped.
func _check_setup() -> void:
	print("\n== setup warnings and the spring")
	var hover: CharacterHover = _player.get_node("Visual/Hover")
	var guard := _player.ledge_guard
	var clean := [_player.get_setup_warnings(), guard.get_setup_warnings(), hover.get_setup_warnings()]
	var max_drop := guard.max_drop
	guard.max_drop = _player.max_step_height - 0.1
	var low_guard := _player.get_setup_warnings()
	guard.max_drop = max_drop
	# A fall limited below the landing speed: a fall would never land.
	var own_fall := _player.fall
	var slow_fall := FallSettings.new()
	slow_fall.max_speed = _player.landing_min_speed - 0.5
	_player.fall = slow_fall
	var never_lands := _player.get_setup_warnings()
	_player.fall = own_fall
	# A jump with nothing to push off with.
	var jump_height := _player.jump_height
	_player.jump_height = 0.0
	var flat_jump := _player.get_setup_warnings()
	_player.jump_height = jump_height
	# The guard would count layer 3 as ground, and the body falls through it.
	guard.floor_mask = _player.collision_mask | 0b100
	var wide_mask := guard.get_setup_warnings()
	guard.floor_mask = 0
	# A second hover outside the tree: not under the character's visual node and with no model.
	var stray := CharacterHover.new()
	stray.character = _player
	var misplaced := "\n".join(stray.get_setup_warnings())
	stray.free()
	# From 1 toward 0 for 10 s at 10 Hz, the stiffest spring the components allow.
	var springs := []
	for damping: float in [2.0, 0.05]:
		var spring := DampedSpring.new()
		spring.value = 1.0
		var largest := 0.0
		for i in 600:
			largest = maxf(largest, absf(spring.update(0.0, 10.0, damping, DT)))
		springs.append([largest, absf(spring.value)])
	print("demo: %s; a guard lower than a stair: %s; a guard's mask wider than the body's: %s; a fall limited below the landing speed: %s; jump_height 0: %s; a stray hover: %s; a 10 Hz spring damped 2 and 0.05: largest %.3f and %.3f, at the end %.5f and %.5f" % [
		clean, low_guard, wide_mask, never_lands, flat_jump, misplaced.replace("\n", " / "), springs[0][0],
		springs[1][0], springs[0][1], springs[1][1]])
	_expect(clean.all(func(warnings: PackedStringArray) -> bool: return warnings.is_empty()),
			"the demo's character, ledge guard and hover have no setup warnings")
	_expect(low_guard.size() == 1 and wide_mask.size() == 1 and never_lands.size() == 1
			and never_lands[0].contains("landing_min_speed") and flat_jump.size() == 1
			and flat_jump[0].contains("jump_height") and misplaced.contains("visual node")
			and misplaced.contains("Nothing to lift"),
			"a guard lower than a stair, a guard's mask wider than the body's, a fall that never lands, a jump with nothing to push off with and a stray hover are warned about")
	_expect(springs[0][0] <= 1.0 and springs[1][0] < 1.1 and springs[0][1] < 0.001 and springs[1][1] < 0.001,
			"the spring stays calm and settles at 10 Hz, strongly and barely damped")


## Standing, running, sprinting and standing again: the states in this order, the blend 0, 1 and 2.
func _check_run_and_sprint() -> void:
	print("\n== state and blend: standing, running, sprinting")
	await _teleport(Vector3(-30, 0, STRIP_Z))
	await _ticks(5)
	var states := []
	var on_state := func(state: GroundCharacter.State, _previous: GroundCharacter.State) -> void: states.append(state)
	_player.state_changed.connect(on_state)
	var standing := [_player.get_state(), _player.get_locomotion_blend(), _player.get_local_movement()]
	_mover.move_to(Vector3(25, 0, STRIP_Z))
	await _ticks(60)
	var running := [_player.get_locomotion_blend(), _player.get_local_movement(), _player.get_move_speed()]
	Input.action_press(&"sprint")
	await _ticks(60)
	var sprinting := [_player.get_locomotion_blend(), _player.get_local_movement(), _player.get_move_speed()]
	Input.action_release(&"sprint")
	await _ticks(60)
	_mover.stop()
	await _ticks_until_stopped(120)
	await _ticks(2)
	_player.state_changed.disconnect(on_state)
	var names := states.map(func(state: int) -> String: return GroundCharacter.State.keys()[state])
	print("standing: %s, blend %.2f, local %s; running %.2f m/s: blend %.3f, local %s; sprinting %.2f m/s: blend %.3f, local %s; states %s" % [
		GroundCharacter.State.keys()[standing[0]], standing[1], standing[2], running[2], running[0], running[1],
		sprinting[2], sprinting[0], sprinting[1], names])
	_expect(standing[0] == GroundCharacter.State.IDLE and standing[1] == 0.0 and standing[2] == Vector2.ZERO,
			"standing: IDLE, blend 0, no movement")
	_expect(absf(running[0] - 1.0) < 0.01 and absf(running[1].y - 1.0) < 0.01 and absf(running[1].x) < 0.01,
			"a full run: blend 1, movement straight forward")
	_expect(absf(sprinting[0] - 2.0) < 0.01 and absf(sprinting[1].y - 2.0) < 0.01, "a full sprint: blend 2")
	_expect(names == ["RUNNING", "SPRINTING", "RUNNING", "IDLE"],
			"the states follow in order: running, sprinting, running, standing")


## A jump in place: the signals in order, rising and falling, the time in the air. Off the platform edge without a
## jump: straight into falling. Down the ramp: the character never leaves the ground.
func _check_jump_and_fall() -> void:
	print("\n== jump and fall: signals in order, time in the air")
	var events := []
	var connections := _record_events(events)
	await _teleport(Vector3(-20, 0, STRIP_Z))
	await _ticks(5)
	events.clear()
	_player.jump()
	var top_air_time := 0.0
	var rising_time := 0.0
	for i in 90:
		await _tree.physics_frame
		if _player.get_state() == GroundCharacter.State.JUMPING:
			rising_time += DT
		top_air_time = maxf(top_air_time, _player.get_air_time())
		if _player.is_on_floor() and i > 5:
			break
	await _ticks(2)
	var jump_events := events.duplicate()
	var air_after := _player.get_air_time()
	var expected_rise := _player.get_jump_speed() / (_player.get_gravity().length() * _player.gravity_scale)

	_player.ledge_guard.enabled = false
	await _teleport(Vector3(25, 1.6, 15.5))
	events.clear()
	_mover.steer(Vector3.FORWARD)
	for i in 90:
		await _tree.physics_frame
		if _player.global_position.y < 0.05 and _player.is_on_floor():
			break
	_mover.stop()
	_player.ledge_guard.enabled = true
	await _ticks(2)
	var drop_events := events.duplicate()

	await _teleport(Vector3(25, 1.6, 18))
	events.clear()
	await _run_until_arrived(Vector3(12, 0, 18), 10.0)
	var ramp_events := events.duplicate()
	_disconnect_all(connections)
	print("jump: %s; rising %.2f s (to the top %.2f s), longest in the air %.2f s, after landing %.2f s" % [
		jump_events, rising_time, expected_rise, top_air_time, air_after])
	print("off the platform: %s; down the ramp: %s" % [drop_events, ramp_events])
	_expect(jump_events == ["jumped", "left_floor", "JUMPING", "FALLING", "touched_floor", "landed", "IDLE"],
			"a jump: jumped, left the ground, rising, falling, touched the ground, landed, standing")
	_expect(absf(rising_time - expected_rise) < 2.0 * DT, "the character rises until the top of the jump")
	_expect(top_air_time > 0.45 and air_after == 0.0, "the time in the air grows and is 0 on the ground")
	_expect(drop_events == ["RUNNING", "left_floor", "FALLING", "touched_floor", "landed", "RUNNING"]
			or drop_events == ["RUNNING", "left_floor", "FALLING", "touched_floor", "landed", "IDLE"],
			"off an edge: no jump, straight into falling, then a landing")
	_expect(not ramp_events.has("left_floor"), "down the ramp: the character stays on the ground")


## Steps alternate the feet, also across a stop; the gait cycle is 0.5 at a right step and 0 at a left one and grows
## between steps.
func _check_feet() -> void:
	print("\n== feet and the gait cycle")
	await _teleport(Vector3(-30, 0, STRIP_Z))
	await _ticks(5)
	var last_foot := _player.get_step_foot()
	var steps := []
	var on_step := func(_sprinting: bool) -> void:
		steps.append([_player.get_step_foot(), _player.get_gait_cycle()])
	_player.stepped.connect(on_step)
	_mover.move_to(Vector3(-15, 0, STRIP_Z))
	var cycles := PackedFloat32Array()
	var backward := 0
	for i in 150:
		await _tree.physics_frame
		var cycle := _player.get_gait_cycle()
		if not cycles.is_empty():
			var change := fposmod(cycle - cycles[-1], 1.0)
			if change > 0.5:
				backward += 1
		cycles.append(cycle)
	_mover.stop()
	await _ticks_until_stopped(120)
	_player.stepped.disconnect(on_step)
	var feet := steps.map(func(step: Array) -> String: return "L" if step[0] == GroundCharacter.Foot.LEFT else "R")
	var cycle_at_steps := steps.map(func(step: Array) -> String: return "%.2f" % step[1])
	print("steps: %s; cycle at the steps: %s; the cycle went back %d times" % [
		"".join(feet), " ".join(cycle_at_steps), backward])
	var alternating := steps.size() >= 6
	var matching := true
	# A step happens within a tick, so at the step the cycle is past its point by at most one tick of movement.
	var tick_share := _mover.settings.max_speed * DT / _player.stride_length / 2.0 + 0.001
	var previous := last_foot
	for i in steps.size():
		var foot: GroundCharacter.Foot = steps[i][0]
		alternating = alternating and foot != previous
		previous = foot
		var expected := 0.5 if foot == GroundCharacter.Foot.RIGHT else 0.0
		matching = matching and fposmod(steps[i][1] - expected, 1.0) < tick_share
	_expect(alternating, "the feet alternate, also after a stop")
	_expect(matching, "the gait cycle is 0.5 at a right step and 0 at a left one")
	_expect(backward == 0, "between steps the gait cycle only grows")


## Without steps the character runs as usual, but there are no steps and the step rhythm stands still. Turned back on
## mid-run, the steps start as from a standstill: the first one comes after first_step_distance. A source that stops
## the steps and is dropped lets them go by itself.
func _check_steps_switch() -> void:
	print("\n== the steps switch")
	await _teleport(Vector3(-30, 0, STRIP_Z))
	var steps := PackedFloat32Array()
	var on_step := func(_sprinting: bool) -> void: steps.append(_player.global_position.x)
	_player.stepped.connect(on_step)
	_player.steps_enabled = false
	var phase := _player.get_step_phase()
	_mover.steer(Vector3.RIGHT)
	await _ticks(60)
	var steps_off := steps.size()
	var phase_still := _player.get_step_phase() == phase
	var speed := _player.get_move_speed()
	var turned_on_at := _player.global_position.x
	_player.steps_enabled = true
	await _ticks(30)
	_mover.stop()
	await _ticks_until_stopped(120)
	_player.stepped.disconnect(on_step)
	# A source that stops the steps and is dropped without letting them go: the character does not keep it alive.
	var dropped := [RefCounted.new()]
	_player.set_steps_suppressed(dropped[0], true)
	var stopped_by_it := not _player.is_counting_steps()
	dropped.clear()
	await _ticks(1)
	var let_go := _player.is_counting_steps()
	var first := steps[0] - turned_on_at if not steps.is_empty() else -1.0
	print("steps off: %d steps in 1 s at %.2f m/s, the rhythm stood still %s; turned on: the first step after %.2f m (first_step_distance %.2f); a dropped source stopped them %s and let them go %s" % [
		steps_off, speed, phase_still, first, _player.first_step_distance, stopped_by_it, let_go])
	_expect(steps_off == 0 and phase_still and speed > 0.95 * _mover.settings.max_speed,
			"steps off: the character runs, with no steps and a still rhythm")
	_expect(first >= _player.first_step_distance - 0.001 and first < _player.first_step_distance + speed * DT + 0.001,
			"turned back on, the first step comes after first_step_distance")
	_expect(stopped_by_it and let_go, "a source that stops the steps and is dropped lets them go by itself")


## A sidestep and backing up in the model's axes; the turn rate: positive to the left, no more than the model's turn
## speed, 0 when running straight.
func _check_sidestep_and_turn() -> void:
	print("\n== movement in the model's axes and turning")
	await _teleport(Vector3(-30, 0, STRIP_Z))
	_mover.steer(Vector3.RIGHT, Vector3.FORWARD)
	await _ticks(40)
	var sidestep := _player.get_local_movement()
	_mover.steer(Vector3.BACK, Vector3.FORWARD)
	await _ticks(40)
	var back := _player.get_local_movement()
	_mover.stop()
	await _ticks_until_stopped(120)
	# Running east, then a click to the north: the model turns to the left.
	_mover.steer(Vector3.RIGHT)
	await _ticks(40)
	var straight := _player.get_turn_rate()
	_mover.steer(Vector3.FORWARD)
	var rates := PackedFloat32Array()
	for i in 20:
		await _tree.physics_frame
		rates.append(_player.get_turn_rate())
	_mover.stop()
	await _ticks_until_stopped(120)
	var backward_share := _mover.settings.backward_speed_multiplier
	print("sidestep right: %s; backing up: %s (backward speed %.2f); turn rate straight %.2f, turning left: max %.0f°/s, min %.0f°/s (model %.0f°/s)" % [
		sidestep, back, backward_share, straight, rad_to_deg(_max(rates)), rad_to_deg(_min(rates)),
		rad_to_deg(_player.visual_turn_speed)])
	_expect(absf(sidestep.x - 1.0) < 0.01 and absf(sidestep.y) < 0.01, "a sidestep to the right: (1, 0)")
	_expect(absf(back.y + backward_share) < 0.01 and absf(back.x) < 0.01,
			"backing up: straight back at the backward speed")
	_expect(straight == 0.0, "running straight: no turning")
	_expect(_max(rates) > 0.0 and _min(rates) >= 0.0 and _max(rates) <= _player.visual_turn_speed + 0.01,
			"turning left: a positive rate no faster than the model turns")


## The acceleration in the model's axes: forward at the mover's rate when speeding up, backward when braking, to the
## left in a left turn.
func _check_acceleration() -> void:
	print("\n== acceleration in the model's axes")
	await _teleport(Vector3(-30, 0, STRIP_Z))
	_mover.steer(Vector3.RIGHT)
	var speeding := PackedFloat32Array()
	for i in 40:
		await _tree.physics_frame
		speeding.append(_player.get_local_acceleration().y)
	# Running east, then to the north: a turn to the left.
	_mover.steer(Vector3.FORWARD)
	var sideways := PackedFloat32Array()
	for i in 20:
		await _tree.physics_frame
		sideways.append(_player.get_local_acceleration().x)
	await _ticks(30)
	_mover.stop()
	var braking := PackedFloat32Array()
	for i in 40:
		await _tree.physics_frame
		braking.append(_player.get_local_acceleration().y)
	await _ticks_until_stopped(120)
	var settings := _mover.settings
	var speed_up := settings.max_speed / settings.acceleration_time
	var slow_down := settings.max_speed / settings.stop_time
	print("speeding up: up to %.1f m/s² forward (mover %.1f); turning left: sideways %.1f..%.1f m/s²; braking: down to %.1f m/s² (mover %.1f)" % [
		_max(speeding), speed_up, _min(sideways), _max(sideways), _min(braking), -slow_down])
	_expect(absf(_max(speeding) - speed_up) < 0.05 * speed_up and _min(speeding) > -0.01,
			"speeding up: forward at the mover's acceleration")
	_expect(_min(sideways) < -0.3 * speed_up and _max(sideways) < 0.1 * speed_up, "a left turn: to the left")
	_expect(absf(_min(braking) + slow_down) < 0.05 * slow_down and _max(braking) < 0.01,
			"braking: backward at the mover's deceleration")


## A teleport in the middle of a run, with a jump just pressed: the character stands at the new place at once, on screen
## too, faces where it was told, does not jump, and what follows its movement sees no jerk; the signal comes once.
## Without a facing it keeps facing where it faced.
func _check_teleport() -> void:
	print("\n== a teleport mid-run: stands at once, faces where told, no jerk")
	await _teleport(Vector3(-30, 0, STRIP_Z))
	var teleports := [0]
	var on_teleport := func() -> void: teleports[0] += 1
	_player.teleported.connect(on_teleport)
	_mover.steer(Vector3.RIGHT)
	await _ticks(60)
	var speed_before := _player.get_move_speed()
	var target := Vector3(-18, 0, STRIP_Z)
	_player.jump()
	# Against the run: the model would otherwise take a while to turn around.
	_player.teleport(target, Vector3.LEFT)
	var shown_at := _player.get_global_transform_interpolated().origin
	var facing_at_once := _flat_angle(_visual_forward(), Vector3.LEFT)
	var heading_at_once := _flat_angle(_mover.get_heading(), Vector3.LEFT)
	var jerk := 0.0
	var turn := 0.0
	var drift := 0.0
	var left_floor := false
	for i in 30:
		await _tree.physics_frame
		jerk = maxf(jerk, _player.get_local_acceleration().length())
		turn = maxf(turn, absf(_player.get_turn_rate()))
		drift = maxf(drift, _player.global_position.distance_to(target))
		left_floor = left_floor or not _player.is_on_floor()
	var facing_after := _flat_angle(_visual_forward(), Vector3.LEFT)
	_player.teleport(target + Vector3(0, 0, -3))
	await _ticks(10)
	var kept_facing := _flat_angle(_visual_forward(), Vector3.LEFT)
	_player.teleported.disconnect(on_teleport)
	print(("running at %.1f m/s, teleported: shown %.3f m from the target at once, model %.1f° and heading %.1f° from " +
			"the facing; next 0.5 s: acceleration up to %.2f m/s², turning up to %.1f°/s, drift %.3f m, left the " +
			"ground %s, model %.1f° from the facing; signals %d; without a facing: %.1f°") % [speed_before,
			shown_at.distance_to(target), facing_at_once, heading_at_once, jerk, rad_to_deg(turn), drift, left_floor,
			facing_after, teleports[0], kept_facing])
	_expect(speed_before > 5.0 and shown_at.distance_to(target) < 0.001 and drift < 0.001 and not left_floor,
			"the character stands at the new place at once, on screen too, and the jump pressed before is forgotten")
	_expect(facing_at_once < 0.5 and heading_at_once < 0.5 and facing_after < 0.5,
			"the model and the heading face where they were told at once")
	_expect(jerk < 0.01 and turn < 0.01, "no acceleration and no turning after the teleport")
	_expect(teleports[0] == 2 and kept_facing < 0.5, "teleported comes once per teleport; without a facing it is kept")


## The staircase east of the platform (0.2 m stairs): a click on the platform leads up the stairs and back down
## without leaving the ground and almost at full speed, and each stair is reported with its height. Without stepping
## the character stops at the first stair.
func _check_stairs() -> void:
	print("\n== stairs up and down")
	var events := []
	var connections := _record_events(events)
	var stairs := PackedFloat32Array()
	var on_stair := func(height: float) -> void: stairs.append(height)
	_player.stair_taken.connect(on_stair)
	var bottom := Vector3(36, 0, 18)
	var top := Vector3(26, 1.6, 18)
	await _teleport(bottom)
	events.clear()
	var up := await _run_on_stairs(top)
	var up_events := events.duplicate()
	var up_stairs := stairs.duplicate()
	events.clear()
	stairs.clear()
	var down := await _run_on_stairs(bottom)
	var down_events := events.duplicate()
	var down_stairs := stairs.duplicate()
	_disconnect_all(connections)
	_player.stair_taken.disconnect(on_stair)

	var step_height := _player.max_step_height
	_player.max_step_height = 0.0
	await _teleport(bottom)
	_mover.steer(Vector3.LEFT)
	var highest := 0.0
	for i in 120:
		await _tree.physics_frame
		highest = maxf(highest, _player.global_position.y)
	_mover.stop()
	_player.max_step_height = step_height
	await _teleport(Vector3.ZERO)
	var max_speed := _mover.settings.max_speed
	print("up: arrived %s, on the stairs %s, speed median %.2f min %.2f, events %s" % [up.arrived, up.on_stairs,
		up.median, up.lowest, up_events])
	print("down: arrived %s, on the stairs %s, speed median %.2f min %.2f, events %s" % [down.arrived,
		down.on_stairs, down.median, down.lowest, down_events])
	print("without stepping: highest %.2f m" % highest)
	print("stairs reported up: %s; down: %s" % [_fmt(up_stairs), _fmt(down_stairs)])
	_expect(up.arrived and up.on_stairs and down.arrived and down.on_stairs,
			"a click on the platform leads up the stairs, a click below leads down them")
	_expect(not up_events.has("left_floor") and not down_events.has("left_floor"),
			"up and down the stairs the character stays on the ground")
	_expect(up.median > 0.95 * max_speed and down.median > 0.95 * max_speed
			and up.lowest > 0.6 * max_speed and down.lowest > 0.6 * max_speed,
			"on the stairs the character keeps running")
	_expect(highest < 0.15, "with max_step_height 0 the character stops at the first stair")
	_expect(up_stairs.size() == 8 and _min(up_stairs) > 0.18 and _max(up_stairs) < 0.22
			and down_stairs.size() == 8 and _max(down_stairs) < -0.18 and _min(down_stairs) > -0.22,
			"every stair is reported once with its height: +0.2 m up, -0.2 m down")


## Runs to [param target] and measures the speed while the character is on the stairs (x from 30 to 32.8).
func _run_on_stairs(target: Vector3) -> Dictionary:
	_arrived = false
	_mover.move_to(target)
	var speeds := PackedFloat32Array()
	var time := 0.0
	while not _arrived and time < 10.0:
		await _tree.physics_frame
		time += DT
		var position := _player.global_position
		if position.x > 30.2 and position.x < 32.6 and absf(position.z - 18.0) < 1.5:
			speeds.append(_player.get_move_speed())
	return {
		arrived = _arrived and _player.global_position.distance_to(target) < 0.05,
		on_stairs = speeds.size() > 10,
		median = _median(speeds),
		lowest = _min(speeds),
	}


## A block 0.4 m high (above max_step_height) stops the character; a 30° slope can be walked up, a 50° one cannot
## (the body's floor_max_angle is 45°).
func _check_slopes_and_high_block() -> void:
	print("\n== a block too high, a gentle and a steep slope")
	var box := BoxShape3D.new()
	box.size = Vector3(1, 0.4, 3)
	var block := await _add_body(box, Vector3(-10, 0.2, STRIP_Z))
	await _teleport(Vector3(-13, 0, STRIP_Z))
	var at_block := await _highest_while_steering(Vector3.RIGHT, 60)
	_free_body(block)
	var gentle := await _add_body(_wedge(30.0), Vector3(-10, 0, STRIP_Z))
	await _teleport(Vector3(-13, 0, STRIP_Z))
	var on_gentle := await _highest_while_steering(Vector3.RIGHT, 90)
	_free_body(gentle)
	var steep := await _add_body(_wedge(50.0), Vector3(-10, 0, STRIP_Z))
	await _teleport(Vector3(-13, 0, STRIP_Z))
	var on_steep := await _highest_while_steering(Vector3.RIGHT, 90)
	_free_body(steep)
	await _teleport(Vector3.ZERO)
	print("0.4 m block: highest %.2f m; 30° slope: %.2f m; 50° slope: %.2f m (floor_max_angle %.0f°)" % [
		at_block, on_gentle, on_steep, rad_to_deg(_player.floor_max_angle)])
	_expect(at_block < 0.05, "a block higher than max_step_height stops the character")
	_expect(on_gentle > 1.5, "a 30° slope can be walked up")
	_expect(on_steep < 0.1, "a 50° slope cannot")


## A wedge 4 m long and 2 m wide rising toward +x at [param angle] degrees, from the ground at x = 0.
static func _wedge(angle: float) -> ConvexPolygonShape3D:
	var shape := ConvexPolygonShape3D.new()
	var height := 4.0 * tan(deg_to_rad(angle))
	shape.points = PackedVector3Array([
		Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(4, 0, -1), Vector3(4, 0, 1),
		Vector3(4, height, -1), Vector3(4, height, 1),
	])
	return shape


func _highest_while_steering(direction: Vector3, ticks: int) -> float:
	_mover.steer(direction)
	var highest := 0.0
	for i in ticks:
		await _tree.physics_frame
		highest = maxf(highest, _player.global_position.y)
	_mover.stop()
	await _ticks_until_stopped(120)
	return highest


func _add_body(shape: Shape3D, position: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	body.position = position
	_main.add_child(body)
	await _ticks(1)
	return body


func _free_body(body: Node) -> void:
	body.queue_free()


## Routes on the level by a click: up the mountain trail, up the ramp, across the meadow and through the maze. The
## character never leaves the ground and never falls on the way.
func _check_level_routes() -> void:
	print("\n== routes on the level: no false take-off")
	var events := []
	var connections := _record_events(events)
	var routes := [
		["the mountain trail", Vector3(21, 0, -15), Vector3(27.17, 10, -26.01)],
		["up the ramp", Vector3(10, 0, 18), Vector3(26, 1.6, 18)],
		["to the camp", Vector3(0, 0, 6), Vector3(29, 0, -3)],
		["into the maze", Vector3.ZERO, Vector3(-16, 0, 20)],
	]
	var false_events := PackedStringArray()
	for route: Array in routes:
		await _teleport(route[1])
		events.clear()
		var run := await _run_until_arrived(route[2], 30.0)
		var air := events.filter(func(event: String) -> bool:
			return event in ["left_floor", "touched_floor", "landed", "FALLING", "JUMPING"])
		print("%s: arrived %s in %.1f s, events %s" % [route[0], run.arrived, run.time, events])
		if not run.arrived or not air.is_empty():
			false_events.append("%s: %s" % [route[0], air])
	_disconnect_all(connections)
	await _teleport(Vector3.ZERO)
	_expect(false_events.is_empty(), "on the trail, the ramp, the meadow and in the maze the character stays on the ground")


## Floating, turned on by the setting: the model hangs at its height and sways, and the steps stop. For the shape of
## its path the sway is off: over the stairs the model glides much more smoothly than the body jumps and never moves
## against the way; along the ramp it keeps its height over the ground without lag, only rounding the bends at its
## ends a little; in a jump, and as it lands, it moves exactly
## with the body, and with the pushes on it sags a little on landing and stays above the ground; it neither dips before
## a guarded ledge nor rises before a block too high or a terrace behind a wall.
func _check_hover() -> void:
	print("\n== floating: height and sway, no steps, stairs, ramp, jump, ledge, walls")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var hover: CharacterHover = _player.get_node("Visual/Hover")
	var off_by_default := not hover.enabled and not hover.is_floating() and _player.is_counting_steps() \
			and hover.transform == Transform3D.IDENTITY
	var changes := []
	var on_change := func(floating: bool) -> void: changes.append(floating)
	hover.floating_changed.connect(on_change)
	var steps := [0]
	var on_step := func(_sprinting: bool) -> void: steps[0] += 1
	_player.stepped.connect(on_step)
	settings.set_value(GameSettings.CHARACTER_HOVER, true)
	var steps_stopped := hover.is_floating() and not _player.is_counting_steps() and _player.steps_enabled
	await _teleport(Vector3(-30, 0, STRIP_Z))
	await _ticks(60)
	var standing := PackedFloat32Array()
	for i in 180:
		await _tree.physics_frame
		standing.append(hover.get_hover_height())

	var bob := hover.bob_height
	hover.bob_height = 0.0
	await _teleport(Vector3(36, 0, 18))
	var up := await _float_route(hover, Vector3(26, 1.6, 18))
	var down := await _float_route(hover, Vector3(36, 0, 18))
	await _teleport(Vector3(10, 0, 18))
	# The ramp rises 1.6 m from x 16 to x 22 at 15°; its middle half is from x 17.5 to x 20.5.
	var ramp_up := await _float_route(hover, Vector3(26, 1.6, 18), Vector2(17.5, 20.5))
	var ramp_down := await _float_route(hover, Vector3(10, 0, 18), Vector2(17.5, 20.5))
	var kicks := [hover.jump_kick, hover.landing_kick]
	hover.jump_kick = 0.0
	hover.landing_kick = 0.0
	var plain_jump := await _float_jump(hover)
	hover.jump_kick = kicks[0]
	hover.landing_kick = kicks[1]
	var pushed_jump := await _float_jump(hover)
	# The platform's north edge, with the ledge guard on: the character stops there.
	await _teleport(Vector3(25, 1.6, 18))
	var at_ledge := await _float_steering(hover, Vector3.FORWARD)
	var block_shape := BoxShape3D.new()
	block_shape.size = Vector3(1, 0.4, 3)
	var block := await _add_body(block_shape, Vector3(-10, 0.2, STRIP_Z))
	await _teleport(Vector3(-14, 0, STRIP_Z))
	var at_block := await _float_steering(hover, Vector3.RIGHT)
	_free_body(block)
	# A wall 1.5 m high with a terrace 0.25 m high right behind it, out of the character's reach.
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(0.2, 1.5, 3)
	var wall := await _add_body(wall_shape, Vector3(-10, 0.75, STRIP_Z))
	var terrace_shape := BoxShape3D.new()
	terrace_shape.size = Vector3(2, 0.25, 3)
	var terrace := await _add_body(terrace_shape, Vector3(-8.9, 0.125, STRIP_Z))
	await _teleport(Vector3(-14, 0, STRIP_Z))
	var at_wall := await _float_steering(hover, Vector3.RIGHT)
	_free_body(wall)
	_free_body(terrace)
	hover.bob_height = bob
	_player.stepped.disconnect(on_step)
	hover.floating_changed.disconnect(on_change)
	settings.set_value(GameSettings.CHARACTER_HOVER, false)
	await _ticks(60)
	await _teleport(Vector3.ZERO)

	var height := hover.height
	print("off by default %s; on: floating with the steps stopped %s, events %s; standing %.3f..%.3f m (height %.2f, sway %.2f); steps while floating %d" % [
		off_by_default, steps_stopped, changes, _min(standing), _max(standing), height, bob, steps[0]])
	print("without the sway:")
	for route: Array in [["stairs up", up], ["stairs down", down], ["ramp up", ramp_up], ["ramp down", ramp_down]]:
		var run: Dictionary = route[1]
		print("%s: arrived %s; jerk body %.3f model %.3f; model against the way %.4f m; lowest over the ground %.3f m, in the middle %.3f m" % [
			route[0], run.arrived, run.body_jerk, run.model_jerk, run.against, run.clearance, run.middle_clearance])
	print("a jump without the pushes: off the height in the air up to %.4f m, after landing %.4f..%.4f m; with them: %.4f m, %.4f..%.4f m" % [
		plain_jump.in_air, plain_jump.low, plain_jump.high, pushed_jump.in_air, pushed_jump.low, pushed_jump.high])
	print("height over the body at the guarded ledge %.3f..%.3f m, at the block %.3f..%.3f m, at the wall %.3f..%.3f m" % [
		at_ledge.x, at_ledge.y, at_block.x, at_block.y, at_wall.x, at_wall.y])
	_expect(off_by_default and steps_stopped and changes == [true],
			"floating is off by default; the setting turns it on and stops the steps, without the steps switch")
	_expect(_min(standing) > height - bob - 0.005 and _max(standing) < height + bob + 0.005
			and _max(standing) - _min(standing) > bob, "standing, the model hangs at its height and sways")
	_expect(steps[0] == 0, "no steps while floating")
	var glides := true
	for run: Dictionary in [up, down]:
		glides = glides and run.arrived and run.model_jerk < 0.4 * run.body_jerk and run.against < 0.001 \
				and run.clearance > 0.4 * height
	# Along the line of the stairs, so over the edge of a stair the model is lower by about half a stair.
	_expect(glides, "over the stairs the model glides: smoother than the body, never against the way, above the stairs")
	_expect(ramp_up.arrived and ramp_down.arrived and ramp_up.middle_clearance > height - 0.01
			and ramp_down.middle_clearance > height - 0.01 and ramp_up.clearance > height - 0.08
			and ramp_down.clearance > height - 0.08,
			"along the ramp the model keeps its height over the ground; at the bends it dips less than 8 cm")
	_expect(plain_jump.in_air < 0.002 and plain_jump.low > -0.002 and plain_jump.high < 0.002,
			"in a jump and as it lands, the model moves exactly with the body")
	_expect(pushed_jump.low < -0.01 and pushed_jump.low > -hover.max_drop and height + pushed_jump.low > 0.0,
			"with the pushes the model sags a little on landing and stays above the ground")
	_expect(at_ledge.x > height - 0.01 and at_block.y < height + 0.01 and at_wall.y < height + 0.01,
			"the model neither dips before a guarded ledge nor rises before a block too high or a terrace behind a wall")


## Runs to [param target] floating: how the body and the model move ([method _check_hover]); the lowest height of the
## model over the ground is also measured while the body's x is within [param middle].
func _float_route(hover: CharacterHover, target: Vector3, middle := Vector2.ZERO) -> Dictionary:
	_arrived = false
	_mover.move_to(target)
	var climbing := target.y > _player.global_position.y
	var body := PackedFloat32Array()
	var model := PackedFloat32Array()
	var clearance := INF
	var middle_clearance := INF
	var time := 0.0
	while not _arrived and time < 10.0:
		await _tree.physics_frame
		time += DT
		var feet := _player.global_position.y
		body.append(feet)
		model.append(feet + hover.get_hover_height())
		var ground := _player.get_ground_height(_player.global_position, 0.3, 0.6)
		if not is_nan(ground):
			clearance = minf(clearance, model[-1] - ground)
			var x := _player.global_position.x
			if x > middle.x and x < middle.y:
				middle_clearance = minf(middle_clearance, model[-1] - ground)
	var against := 0.0
	var body_jerk := 0.0
	var model_jerk := 0.0
	for i in range(1, model.size()):
		against = maxf(against, model[i - 1] - model[i] if climbing else model[i] - model[i - 1])
		if i >= 2:
			body_jerk = maxf(body_jerk, absf(body[i] - 2.0 * body[i - 1] + body[i - 2]))
			model_jerk = maxf(model_jerk, absf(model[i] - 2.0 * model[i - 1] + model[i - 2]))
	return {
		arrived = _arrived,
		against = against,
		body_jerk = body_jerk,
		model_jerk = model_jerk,
		clearance = clearance,
		middle_clearance = middle_clearance,
	}


## A jump in place, floating: how far the model is from its height, m, in the air (the most either way) and after
## landing (the lowest and the highest).
func _float_jump(hover: CharacterHover) -> Dictionary:
	await _teleport(Vector3(-20, 0, STRIP_Z))
	await _ticks(30)
	_player.jump()
	var in_air := 0.0
	var low := INF
	var high := -INF
	var was_in_air := false
	for i in 120:
		await _tree.physics_frame
		var off := hover.get_hover_height() - hover.height
		if not _player.is_on_floor():
			was_in_air = true
			in_air = maxf(in_air, absf(off))
		elif was_in_air:
			low = minf(low, off)
			high = maxf(high, off)
	return {in_air = in_air, low = low, high = high}


## Steers in [param direction] for 1.5 s floating: the lowest (x) and the highest (y) height of the model over the
## body, m.
func _float_steering(hover: CharacterHover, direction: Vector3) -> Vector2:
	_mover.steer(direction)
	var heights := PackedFloat32Array()
	for i in 90:
		await _tree.physics_frame
		heights.append(hover.get_hover_height())
	_mover.stop()
	await _ticks_until_stopped(120)
	return Vector2(_min(heights), _max(heights))


## Floating with a slower fall (the demo's hover has one): a jump rises as on foot and comes down at the hover's
## limit, touching the ground softly: no landing, a small sag of the model. Floating turned on mid-fall slows the fall
## down smoothly; turned off mid-fall, the fall stays slow until the model has settled and then speeds up as on foot.
## With an empty fall the floating character falls as it does on foot.
func _check_hover_fall() -> void:
	print("\n== floating: a slower fall")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var hover: CharacterHover = _player.get_node("Visual/Hover")
	var slow := hover.fall
	if slow == null:
		_expect(false, "the demo's hover has a fall of its own")
		return
	var on_foot_jump := await _record_jump(Vector3(-20, 0, STRIP_Z))
	var touchdowns := PackedFloat32Array()
	var on_touched := func(speed: float) -> void: touchdowns.append(speed)
	var landings := [0]
	var on_landed := func(_speed: float) -> void: landings[0] += 1
	_player.touched_floor.connect(on_touched)
	_player.landed.connect(on_landed)
	var bob := hover.bob_height
	hover.bob_height = 0.0
	var on_foot := _player.get_fall_settings() == _player.fall
	settings.set_value(GameSettings.CHARACTER_HOVER, true)
	var put_in_place := slow != null and _player.get_fall_settings() == slow
	await _teleport(Vector3(-20, 0, STRIP_Z))
	await _ticks(40)

	# A jump in place: up as on foot, down at the limit, a soft touchdown.
	_player.jump()
	var apex := 0.0
	for i in 180:
		await _tree.physics_frame
		apex = maxf(apex, _player.global_position.y)
		if i > 5 and _player.is_on_floor():
			break
	var sag := 0.0
	for i in 60:
		await _tree.physics_frame
		sag = minf(sag, hover.get_hover_height() - hover.height)
	var soft := touchdowns.duplicate()
	var soft_landings: int = landings[0]

	# Turned on mid-fall, falling from 8 m at 6 m/s.
	settings.set_value(GameSettings.CHARACTER_HOVER, false)
	await _ticks(40)
	await _teleport(Vector3(-20, 8, STRIP_Z))
	await _wait_until(func() -> bool: return -_player.velocity.y > 6.0, 60)
	var braking := PackedFloat32Array([-_player.velocity.y])
	settings.set_value(GameSettings.CHARACTER_HOVER, true)
	for i in roundi(2.0 * slow.braking_time / DT):
		await _tree.physics_frame
		braking.append(-_player.velocity.y)
	var largest_drop := 0.0
	for i in range(1, braking.size()):
		largest_drop = maxf(largest_drop, braking[i - 1] - braking[i])

	# Turned off mid-fall: slow while the model settles, then as on foot.
	settings.set_value(GameSettings.CHARACTER_HOVER, false)
	var settling := PackedFloat32Array()
	var after := PackedFloat32Array()
	for i in roundi(hover.rise_time / DT) + 10:
		await _tree.physics_frame
		if hover.is_floating():
			settling.append(-_player.velocity.y)
		else:
			after.append(-_player.velocity.y)
	var gain := (after[-1] - after[0]) / ((after.size() - 1) * DT) if after.size() > 1 else 0.0
	var on_foot_gain := _player.get_gravity().length() * _player.gravity_scale

	# An empty fall: the floating character falls as on foot, tick by tick.
	await _teleport(Vector3(-20, 0, STRIP_Z))
	settings.set_value(GameSettings.CHARACTER_HOVER, true)
	await _ticks(40)
	hover.fall = null
	var own_again := _player.get_fall_settings() == _player.fall
	var floating_jump := await _record_jump(Vector3(-20, 0, STRIP_Z))
	hover.fall = slow
	var slow_again := _player.get_fall_settings() == slow
	settings.set_value(GameSettings.CHARACTER_HOVER, false)
	await _ticks(60)
	hover.bob_height = bob
	_player.touched_floor.disconnect(on_touched)
	_player.landed.disconnect(on_landed)
	await _teleport(Vector3.ZERO)

	print("on foot the own fall %s, floating the hover's %s (gravity %.2f, limit %.1f m/s, braking %.2f s)" % [
		on_foot, put_in_place, slow.gravity_scale, slow.max_speed, slow.braking_time])
	print("a jump: top %.3f m, touched the ground at %s, landings %d, the model sagged %.3f m" % [apex, _fmt(soft),
		soft_landings, sag])
	print("turned on mid-fall: %s (every 3rd tick), the largest drop in a tick %.2f m/s" % [_fmt(_every(braking, 3)),
		largest_drop])
	print("turned off mid-fall: %d ticks while settling at %.3f..%.3f m/s, then speeding up at %.1f m/s² (on foot %.1f)" % [
		settling.size(), _min(settling), _max(settling), gain, on_foot_gain])
	print("an empty fall: own settings %s; a jump of %d ticks, %.6f m/s off the one on foot (%d ticks) at most; the hover's fall back %s" % [
		own_again, floating_jump.size(), _largest_difference(on_foot_jump, floating_jump), on_foot_jump.size(),
		slow_again])
	_expect(on_foot and put_in_place, "on foot the character falls by its own settings, floating by the hover's")
	_expect(absf(apex - _player.jump_height) < 0.02 and soft.size() == 1
			and absf(soft[0] - slow.max_speed) < 0.001 and soft_landings == 0,
			"floating, a jump rises as on foot and comes down at the hover's limit: no landing")
	# A spring pushed at v goes no deeper than about v / (2π·frequency); a quarter of that is surely a sag.
	var sag_expected := hover.landing_kick * slow.max_speed / (TAU * hover.spring_frequency)
	_expect(sag < -0.25 * sag_expected and sag > -hover.max_drop, "the model sags a little on the soft touchdown")
	_expect(largest_drop < 0.2 * (braking[0] - slow.max_speed) and absf(braking[-1] - slow.max_speed) < 0.02,
			"turned on mid-fall, floating slows the fall down smoothly to the limit")
	_expect(absi(settling.size() - roundi(hover.rise_time / DT)) <= 1 and absf(_min(settling) - slow.max_speed) < 0.02
			and absf(_max(settling) - slow.max_speed) < 0.02 and absf(gain - on_foot_gain) < 0.02 * on_foot_gain,
			"turned off mid-fall, the fall stays slow until the model has settled, then speeds up as on foot")
	_expect(own_again and _largest_difference(on_foot_jump, floating_jump) < 0.000001 and slow_again,
			"with an empty fall the floating character falls exactly as on foot")


## Floating turned off mid-run: the model settles smoothly in rise_time, and then the steps come back; turned on again,
## it rises smoothly and the steps stop at once. The game's own switch of the steps is kept, and steps_while_floating
## keeps the steps. A hover turned on before the first physics tick floats at once and puts its fall in place, and out
## of the tree it lets the steps and the fall go.
func _check_hover_toggle() -> void:
	print("\n== floating turned off and on mid-run, the steps, and at the start")
	var hover: CharacterHover = _player.get_node("Visual/Hover")
	var changes := []
	var on_change := func(floating: bool) -> void: changes.append(floating)
	hover.floating_changed.connect(on_change)
	hover.enabled = true
	await _teleport(Vector3(-30, 0, STRIP_Z))
	_mover.steer(Vector3.RIGHT)
	await _ticks(30)
	changes.clear()
	var last := _player.global_position.y + hover.get_hover_height()
	var largest := 0.0
	hover.enabled = false
	var settled := -1
	var steps_at_settle := false
	for i in 50:
		await _tree.physics_frame
		var model := _player.global_position.y + hover.get_hover_height()
		largest = maxf(largest, absf(model - last))
		last = model
		if settled < 0 and not hover.is_floating():
			settled = i + 1
			steps_at_settle = _player.is_counting_steps()
	hover.enabled = true
	var stopped_at_once := not _player.is_counting_steps()
	for i in 40:
		await _tree.physics_frame
		var model := _player.global_position.y + hover.get_hover_height()
		largest = maxf(largest, absf(model - last))
		last = model
	_mover.stop()
	await _ticks_until_stopped(120)
	# The game turns the steps off while the hero floats: they stay off after it settles.
	_player.steps_enabled = false
	hover.enabled = false
	await _ticks(40)
	var switch_kept := not _player.is_counting_steps() and not _player.steps_enabled
	_player.steps_enabled = true
	var switch_back := _player.is_counting_steps()
	hover.steps_while_floating = true
	hover.enabled = true
	await _ticks(2)
	var kept_while_floating := hover.is_floating() and _player.is_counting_steps()
	hover.steps_while_floating = false
	var stopped_again := not _player.is_counting_steps()
	hover.enabled = false
	await _ticks(40)
	hover.floating_changed.disconnect(on_change)
	var steps_back := _player.is_counting_steps() and not hover.is_floating()

	# A second hero, its hover turned on before its first tick.
	var second: GroundCharacter = (load("res://gdscript/player/player.tscn") as PackedScene).instantiate()
	second.position = Vector3(-30, 0, 30)
	_main.add_child(second)
	var second_hover: CharacterHover = second.get_node("Visual/Hover")
	second_hover.enabled = true
	var at_once := second_hover.get_hover_height()
	var fall_at_once := second.get_fall_settings() == second_hover.fall
	await _ticks(1)
	var after_tick := second_hover.get_hover_height()
	var visual := second_hover.get_parent()
	visual.remove_child(second_hover)
	var let_go := second.is_counting_steps() and second.get_fall_settings() == second.fall
	visual.add_child(second_hover)
	var taken_back := not second.is_counting_steps() and second.get_fall_settings() == second_hover.fall
	second.queue_free()
	await _ticks(1)
	await _teleport(Vector3.ZERO)
	var rise_ticks := roundi(hover.rise_time / DT)
	print("turned off mid-run: largest move of the model in a tick %.3f m; settled after %d ticks (rise_time %d ticks), steps then %s; on again: steps stopped at once %s; events %s" % [
		largest, settled, rise_ticks, steps_at_settle, stopped_at_once, changes])
	print("the steps switched off while floating stay off %s, and back on %s; kept with steps_while_floating %s, stopped without it %s; back at the end %s" % [
		switch_kept, switch_back, kept_while_floating, stopped_again, steps_back])
	print("a hover on before its first tick: %.3f m at once, %.3f m after a tick, its fall put in place %s; out of the tree the steps and the fall are let go %s, back in it taken again %s" % [
		at_once, after_tick, fall_at_once, let_go, taken_back])
	_expect(largest < 0.03 and absi(settled - rise_ticks) <= 1,
			"turned off and on mid-run, the model moves smoothly in rise_time")
	_expect(steps_at_settle and stopped_at_once and changes == [false, true, false, true, false] and steps_back,
			"the steps come back once the model settles, and stop at once when it rises")
	_expect(switch_kept and switch_back and kept_while_floating and stopped_again,
			"the game's steps switch is kept; steps_while_floating keeps the steps")
	var height_range := hover.bob_height + 0.005
	_expect(absf(at_once - hover.height) <= height_range and absf(after_tick - hover.height) <= height_range
			and fall_at_once and let_go and taken_back,
			"a hover turned on before its first tick floats at once; out of the tree it lets the steps and the fall go")


## A character whose body stands turned in the level, as an NPC turned in the editor (here by 120°): it starts facing
## along the body's −Z without turning its model, runs with the model along the run (which counts as running forward),
## and a teleport with a facing turns the model there at once. The model turns relative to the body.
func _check_turned_body() -> void:
	print("\n== a character turned in the level: the model faces where it runs")
	var npc := (load("res://gdscript/player/player.tscn") as PackedScene).instantiate() as GroundCharacter
	npc.rotation.y = deg_to_rad(120.0)
	npc.position = Vector3(-24, 0, STRIP_Z)
	_levels.get_current_level().add_child(npc)
	var model_forward := func() -> Vector3:
		var look := -npc.visual.global_basis.z
		return Vector3(look.x, 0.0, look.z).normalized()
	var body_forward := -npc.global_basis.z
	await _ticks(10)
	var standing := _flat_angle(model_forward.call(), body_forward)
	npc.mover.steer(Vector3.RIGHT)
	await _ticks(40)
	var running := _flat_angle(model_forward.call(), Vector3.RIGHT)
	var local := npc.get_local_movement()
	npc.mover.stop()
	await _ticks(30)
	npc.teleport(Vector3(-24, 0, STRIP_Z), Vector3.BACK)
	var teleported := _flat_angle(model_forward.call(), Vector3.BACK)
	await _ticks(5)
	var kept := _flat_angle(model_forward.call(), Vector3.BACK)
	npc.queue_free()
	await _ticks(2)
	print(("standing: %.1f deg from the body's facing; running: %.1f deg from the run, local movement %s; " +
			"teleported: %.1f deg from the facing, %.1f deg 5 ticks later") % [standing, running, local.snappedf(0.01),
			teleported, kept])
	_expect(standing < 1.0, "at the start the model faces along the turned body and does not turn")
	_expect(running < 3.0 and absf(local.x) < 0.05 and local.y > 0.9,
			"on the run the model faces the run, which counts as running forward")
	_expect(teleported < 1.0 and kept < 1.0, "a teleport with a facing turns the model there at once, and it stays")


## A floating character teleported a short way (0.8 m aside, onto a block 0.2 m high), with physics interpolation on and
## off: the floating model is put in place at once, instead of sinking into the block and rising after it. The hover
## hears the teleport by its signal: resetting the interpolation sends nothing while the interpolation is off.
func _check_hover_teleport() -> void:
	print("\n== a short teleport of a floating character, physics interpolation on and off")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var hover: CharacterHover = _player.get_node("Visual/Hover")
	settings.set_value(GameSettings.CHARACTER_HOVER, true)
	var box := BoxShape3D.new()
	box.size = Vector3(2, 0.2, 3)
	var block := await _add_body(box, Vector3(-9, 0.1, STRIP_Z))
	var report := PackedStringArray()
	var in_place := true
	for interpolation: bool in [true, false]:
		_tree.physics_interpolation = interpolation
		await _teleport(Vector3(-10.6, 0, STRIP_Z))
		await _ticks(90)
		var settled := hover.global_position.y - _player.global_position.y
		_player.teleport(Vector3(-9.8, 0.2, STRIP_Z))
		await _tree.physics_frame
		var after := hover.global_position.y - _player.global_position.y
		report.append("interpolation %s: %.3f m over the feet, %.3f m right after the teleport" % [interpolation,
				settled, after])
		in_place = in_place and absf(after - settled) < 0.05
	_tree.physics_interpolation = settings.get_value(GameSettings.PHYSICS_INTERPOLATION)
	settings.set_value(GameSettings.CHARACTER_HOVER, false)
	_free_body(block)
	await _ticks(60)
	await _teleport(Vector3.ZERO)
	print("; ".join(report))
	_expect(in_place, "a short teleport puts the floating model in place at once, with physics interpolation on and off")


## Time stands still (Engine.time_scale 0): the physics ticks go on with a zero step. The running hero stays as it is,
## on foot and floating: its place, speed, state and step rhythm, the staff in its hand and the floating model do not
## change, no node of the scene gets a non-finite transform, and no errors come. When time goes on, the hero runs on,
## on foot in step with the staff swaying.
func _check_time_stopped() -> void:
	print("\n== time stands still: the running hero stays as it is and runs on afterwards")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var hover: CharacterHover = _player.get_node("Visual/Hover")
	var hand: Node3D = _player.get_node("Visual/Hover/Model/RightHand")
	var steps := [0]
	var on_step := func(_sprinting: bool) -> void: steps[0] += 1
	_player.stepped.connect(on_step)
	var report := PackedStringArray()
	var still := true
	var clean := true
	var runs_on := true
	for floating: bool in [false, true]:
		settings.set_value(GameSettings.CHARACTER_HOVER, floating)
		await _teleport(Vector3(-30, 0, STRIP_Z))
		_mover.steer(Vector3.RIGHT)
		await _ticks(40)
		Engine.time_scale = 0.0
		# The tick in which the scale changes still runs at full speed.
		await _tree.physics_frame
		var before := _get_frozen_state(hover, hand)
		var errors := _error_count()
		var broken := {}
		for i in 6:
			await _tree.physics_frame
			_find_non_finite(broken)
		var kept := _same_values(_get_frozen_state(hover, hand), before)
		errors = _error_count() - errors
		Engine.time_scale = 1.0
		steps[0] = 0
		var start := _player.global_position
		var rest := hand.transform
		var swing := 0.0
		for i in 60:
			await _tree.physics_frame
			swing = maxf(swing, hand.transform.origin.distance_to(rest.origin))
			_find_non_finite(broken)
		var ran := _flat_distance(start, _player.global_position)
		_mover.stop()
		await _ticks_until_stopped(60)
		report.append(("%s: at %.2f m/s %s, kept %s, non-finite %s, errors %d; then ran %.2f m, %d steps, the hand " +
				"swung %.3f m, step rhythm %.2f") % ["floating" if floating else "on foot", before[1].length(),
				GroundCharacter.State.keys()[before[2]], kept, broken.keys(), errors, ran, steps[0], swing,
				_player.get_step_phase()])
		still = still and kept and before[1].length() > 5.0
		clean = clean and broken.is_empty() and errors == 0
		runs_on = runs_on and ran > 4.5 and is_finite(_player.get_step_phase())
		if not floating:
			runs_on = runs_on and steps[0] >= 2 and swing > 0.02
	_player.stepped.disconnect(on_step)
	settings.set_value(GameSettings.CHARACTER_HOVER, false)
	await _ticks(60)
	await _teleport(Vector3.ZERO)
	print("; ".join(report))
	_expect(still, "time stopped: the running hero keeps its place, speed, state and step rhythm, the staff and the "
			+ "floating model stay where they are")
	_expect(clean, "no node gets a non-finite transform, and no errors come")
	_expect(runs_on, "when time goes on, the hero runs on, on foot in step with the staff swaying")


## What a zero step must not change ([method _check_time_stopped]): the body's place, velocity, state and step rhythm,
## the hand and the floating model.
func _get_frozen_state(hover: CharacterHover, hand: Node3D) -> Array:
	return [_player.global_position, _player.get_move_velocity(), _player.get_state(), _player.get_step_phase(),
		hand.transform, hover.transform]


## The monitor panel: hidden by default, the setting shows it; it names the state and lists the latest events.
func _check_monitor() -> void:
	print("\n== the character monitor")
	var panel: Control = _main.get_node("Hud/CharacterState")
	var monitor: CharacterMonitor = panel.get_node("Monitor")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	# Room for the events of one jump and the state changes around it.
	var history_size := monitor.history_size
	monitor.history_size = 10
	var hidden := not panel.visible
	settings.set_value(GameSettings.CHARACTER_STATE, true)
	var shown := panel.visible
	await _teleport(Vector3(-20, 0, STRIP_Z))
	_player.jump()
	await _ticks(10)
	await _frames(1)
	var in_air := monitor.text
	await _ticks(60)
	await _frames(1)
	var events := monitor.get_event_lines()
	_player.steps_enabled = false
	var no_steps := "\n".join(monitor.get_state_lines()).contains("No steps")
	_player.steps_enabled = true
	settings.set_value(GameSettings.CHARACTER_STATE, false)
	monitor.history_size = history_size
	print("hidden by default %s, shown by the setting %s; in the air:\n%s\nevents:\n%s" % [hidden, shown, in_air,
		"\n".join(events)])
	_expect(hidden and shown and not panel.visible, "the panel is off by default and the setting shows it")
	_expect(in_air.begins_with("Jumping") and in_air.contains("In the air"), "in a jump the panel says so")
	var listed := "\n".join(events)
	_expect(listed.contains("jump") and listed.contains("left the ground") and listed.contains("Jumping → Falling")
			and listed.contains("touched the ground at") and listed.contains("landing at"),
			"the events of the jump are in the list")
	_expect(events.size() <= 10 and not monitor.log_events,
			"the list keeps only the latest events; the log to the output is off by default")
	_expect(no_steps, "without steps the panel says so")


## Records the character's events into [param events] in order: signal names and the names of new states. Returns
## the connections for [method _disconnect_all].
func _record_events(events: Array) -> Array:
	var connections := [
		[_player.jumped, func() -> void: events.append("jumped")],
		[_player.left_floor, func() -> void: events.append("left_floor")],
		[_player.touched_floor, func(_speed: float) -> void: events.append("touched_floor")],
		[_player.landed, func(_speed: float) -> void: events.append("landed")],
		[_player.state_changed, func(state: int, _previous: int) -> void:
			events.append(GroundCharacter.State.keys()[state])],
	]
	for connection: Array in connections:
		(connection[0] as Signal).connect(connection[1])
	return connections


func _disconnect_all(connections: Array) -> void:
	for connection: Array in connections:
		(connection[0] as Signal).disconnect(connection[1])
