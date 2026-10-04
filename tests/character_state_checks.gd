extends "res://tests/check_suite.gd"
## What the character reports about itself, for animations and the interface: the state and its changes, the blend
## of speeds, movement in the model's axes, turning, floor contact and time in the air, feet and the gait cycle. Stairs
## and slopes: up and down a staircase without leaving the ground, a block too high, a gentle and a steep slope. Routes
## on the level without a false take-off. The monitor panel shows the state and the latest events.

## A clear strip along the south fence: the character runs here, and the checks put their obstacles here.
const STRIP_Z := 34.0


func _checks() -> Array[Callable]:
	return [
		_check_run_and_sprint,
		_check_jump_and_fall,
		_check_feet,
		_check_sidestep_and_turn,
		_check_stairs,
		_check_slopes_and_high_block,
		_check_level_routes,
		_check_monitor,
	]


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


## The staircase east of the platform (0.2 m stairs): a click on the platform leads up the stairs and back down
## without leaving the ground and almost at full speed. Without stepping the character stops at the first stair.
func _check_stairs() -> void:
	print("\n== stairs up and down")
	var events := []
	var connections := _record_events(events)
	var bottom := Vector3(36, 0, 18)
	var top := Vector3(26, 1.6, 18)
	await _teleport(bottom)
	events.clear()
	var up := await _run_on_stairs(top)
	var up_events := events.duplicate()
	events.clear()
	var down := await _run_on_stairs(bottom)
	var down_events := events.duplicate()
	_disconnect_all(connections)

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
	_expect(up.arrived and up.on_stairs and down.arrived and down.on_stairs,
			"a click on the platform leads up the stairs, a click below leads down them")
	_expect(not up_events.has("left_floor") and not down_events.has("left_floor"),
			"up and down the stairs the character stays on the ground")
	_expect(up.median > 0.95 * max_speed and down.median > 0.95 * max_speed
			and up.lowest > 0.6 * max_speed and down.lowest > 0.6 * max_speed,
			"on the stairs the character keeps running")
	_expect(highest < 0.15, "with max_step_height 0 the character stops at the first stair")


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
