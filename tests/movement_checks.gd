extends "res://tests/check_suite.gd"
## Running on open ground and along routes: acceleration and a stop exactly at the point, a new click while braking,
## a reversal at full speed, going around obstacles (a trap, a door in a wall, a maze, a ramp, an unreachable point),
## the ledge guard and a fall from the platform.


func _checks() -> Array[Callable]:
	return [
		_check_start_and_stop,
		_check_reclick_while_braking,
		_check_turn_while_braking,
		_check_reverse_at_full_speed,
		_check_route.bind("around U trap", Vector3(12, 0, -6), Vector3(12, 0, -21), 20.0),
		_check_route.bind("through the door", Vector3.ZERO, Vector3(-1.5, 0, 14), 20.0),
		_check_route.bind("into the maze", Vector3.ZERO, Vector3(-16, 0, 20), 30.0),
		_check_route.bind("up the ramp", Vector3(10, 0, 18), Vector3(26, 1.6, 18), 20.0),
		_check_route.bind("unreachable crate top", Vector3.ZERO, Vector3(18, 1.2, -2), 20.0, false),
		_check_route.bind("down the ramp, ledge guard on", Vector3(25, 1.6, 18), Vector3(10, 0, 18), 20.0),
		# From the side the ramp is a wall up to 1.6 m high: the path must go around to its front, not climb its side.
		_check_route.bind("from beside the ramp (north) onto the platform",
				Vector3(19, 0, 15.7), Vector3(27, 1.6, 17), 10.0),
		_check_route.bind("from beside the ramp (south) onto the platform",
				Vector3(19, 0, 20.3), Vector3(27, 1.6, 17), 10.0),
		_check_ledge_guard,
	]


func _check_start_and_stop() -> void:
	print("\n== start and stop on open ground")
	await _teleport(Vector3.ZERO)
	var target := Vector3(8, 0, -2)
	var run := await _run_until_arrived(target, 10.0)
	var speeds: PackedFloat32Array = run.speeds
	var max_speed := _max(speeds)
	var reach_time := -1.0
	for i in speeds.size():
		if speeds[i] >= 0.95 * _mover.settings.max_speed:
			reach_time = (i + 1) * DT
			break
	print("speed profile, first 14 ticks: ", _fmt(speeds.slice(0, 14)))
	print("speed profile, last 16 ticks:  ", _fmt(speeds.slice(-16)))
	print("max speed %.2f, 95%% reached at %.3f s, arrival %.3f s, final error %.4f m, backtrack %.4f m" % [
		max_speed, reach_time, run.time, run.error, run.backtrack])
	# The limits come from the character settings: with constant acceleration, 95% of the speed is reached in 0.95 of
	# the acceleration time.
	var settings := _mover.settings
	_expect(run.arrived, "arrived")
	_expect(absf(reach_time - 0.95 * settings.acceleration_time) <= 2.0 * DT,
			"reaches full speed in acceleration_time (%.2f s)" % settings.acceleration_time)
	_expect(run.error < 0.05, "stops at the clicked point")
	_expect(run.backtrack < 0.002, "no overshoot")
	var stop_ticks := 0
	for i in range(speeds.size() - 1, -1, -1):
		if speeds[i] >= 0.95 * max_speed:
			break
		stop_ticks += 1
	print("braking from 95%% to stop: %.3f s" % (stop_ticks * DT))
	_expect(absf(stop_ticks * DT - 0.95 * settings.stop_time) <= 3.0 * DT,
			"stops in stop_time (%.2f s)" % settings.stop_time)


func _check_reclick_while_braking() -> void:
	print("\n== new click while braking, same direction")
	await _teleport(Vector3.ZERO)
	_arrived = false
	_mover.move_to(Vector3(8, 0, -2))
	await _wait_until_braking()
	var speed_at_click := _mover.get_speed()
	_mover.move_to(Vector3(16, 0, -4))
	var after := PackedFloat32Array()
	for i in 20:
		await _tree.physics_frame
		after.append(_mover.get_speed())
	print("speed at re-click %.2f, next ticks: %s" % [speed_at_click, _fmt(after)])
	_expect(speed_at_click > 0.5, "re-click happened while still moving")
	_expect(_min(after) >= speed_at_click - 0.01, "speed is kept and grows from the current value")
	var run := await _run_until_arrived(Vector3(16, 0, -4), 10.0, false)
	_expect(run.arrived and run.error < 0.05, "arrives at the second point")


func _check_turn_while_braking() -> void:
	print("\n== new click while braking, 90 degrees to the side")
	await _teleport(Vector3.ZERO)
	_mover.move_to(Vector3(8, 0, -2))
	await _wait_until_braking()
	var turn_start := _player.global_position
	_mover.move_to(turn_start + Vector3(-2, 0, -8).normalized() * 6.0)
	var speeds := PackedFloat32Array()
	for i in 30:
		await _tree.physics_frame
		speeds.append(_mover.get_speed())
	print("speeds after side click: ", _fmt(speeds))
	var run := await _run_until_arrived(turn_start + Vector3(-2, 0, -8).normalized() * 6.0, 10.0, false)
	_expect(run.arrived and run.error < 0.05, "arrives after the turn")


## Waits until the character accelerates to full speed and then, while braking, drops it by half.
func _wait_until_braking() -> void:
	var peaked := false
	for i in 600:
		await _tree.physics_frame
		if _mover.get_speed() >= 0.95 * _mover.settings.max_speed:
			peaked = true
		elif peaked and _mover.get_speed() < 0.5 * _mover.settings.max_speed:
			return


func _check_reverse_at_full_speed() -> void:
	print("\n== click behind the player at full speed")
	await _teleport(Vector3(-6, 0, 0))
	_mover.move_to(Vector3(8, 0, 0))
	for i in 600:
		await _tree.physics_frame
		if _player.global_position.x > -1.0:
			break
	var turn_start := _player.global_position
	var back := Vector3(-8, 0, 0)
	_mover.move_to(back)
	var speeds := PackedFloat32Array()
	var max_forward := 0.0
	var max_side := 0.0
	var reversed_at := -1.0
	for i in 60:
		await _tree.physics_frame
		speeds.append(_mover.get_speed())
		var offset := _player.global_position - turn_start
		max_forward = maxf(max_forward, offset.x)
		max_side = maxf(max_side, absf(offset.z))
		if reversed_at < 0.0 and _player.velocity.x < -0.9 * _mover.settings.max_speed:
			reversed_at = (i + 1) * DT
	print("speeds: ", _fmt(_every(speeds, 2)))
	print("carried forward %.2f m, side swing %.2f m, back at 90%% speed after %.2f s" % [
		max_forward, max_side, reversed_at])
	# The limits grow with the acceleration and stop times: the slower the braking, the farther it carries on.
	var settings := _mover.settings
	var arc_limit := settings.max_speed * settings.stop_time
	_expect(max_forward < arc_limit and max_side < arc_limit, "turns around in an arc under %.2f m" % arc_limit)
	_expect(reversed_at > 0.0 and reversed_at < settings.stop_time + settings.acceleration_time + 0.15,
			"runs back at speed quickly")
	var run := await _run_until_arrived(back, 10.0, false)
	_expect(run.arrived and run.error < 0.05, "arrives behind")


## The 8 × 8 m platform, 1.6 m high: x from 22 to 30, z from 14 to 22. Running north leads to the edge z = 14.
func _check_ledge_guard() -> void:
	print("\n== ledge guard on the 1.6 m platform")
	var guard: LedgeGuard = _player.ledge_guard
	guard.enabled = true

	await _teleport(Vector3(25, 1.6, 17))
	_mover.steer(Vector3.FORWARD)
	for i in 120:
		await _tree.physics_frame
	var stop := _player.global_position
	var stop_speed := _flat_speed(_player.get_real_velocity())
	print("straight at the edge: stopped at z %.3f (edge 14, margin %.2f), y %.3f, speed %.2f, on floor %s" % [
		stop.z, guard.edge_margin, stop.y, stop_speed, _player.is_on_floor()])
	_expect(stop.z >= 14.0 + 0.85 * guard.edge_margin and absf(stop.y - 1.6) < 0.02 and _player.is_on_floor(),
			"stops edge_margin before the edge, stays on top")
	_expect(stop_speed < 0.05, "does not creep over the edge")

	await _teleport(Vector3(23, 1.6, 17))
	_mover.steer(Vector3(1, 0, -1))
	var slide_speeds := PackedFloat32Array()
	var lowest := 1.6
	for i in 150:
		await _tree.physics_frame
		lowest = minf(lowest, _player.global_position.y)
		if _player.global_position.z < 14.3 and _player.global_position.x < 29.0:
			slide_speeds.append(_flat_speed(_player.get_real_velocity()))
	var corner := _player.global_position
	var wall_slide := _mover.settings.max_speed * cos(PI / 4.0)
	var slide := _median(slide_speeds)
	print(("45 degrees to the edge: slide speed %.2f m/s (wall slide %.2f), %d ticks along the edge, " +
			"lowest y %.3f, end %s") % [
		slide, wall_slide, slide_speeds.size(), lowest, corner.snapped(Vector3.ONE * 0.01)])
	_expect(absf(slide - wall_slide) < 0.4, "slides along the edge like along a wall")
	_expect(lowest > 1.58 and corner.x <= 30.0 and corner.z >= 14.0, "slides into the corner and stays on top")

	guard.enabled = false
	await _teleport(Vector3(25, 1.6, 17))
	_mover.steer(Vector3.FORWARD)
	var left_at := -1.0
	var landed_at := -1.0
	var time := 0.0
	while time < 3.0 and landed_at < 0.0:
		await _tree.physics_frame
		time += DT
		if left_at < 0.0 and _player.global_position.y < 1.59:
			left_at = time
		elif left_at > 0.0 and _player.is_on_floor() and _player.global_position.y < 0.05:
			landed_at = time
	var fall_time := landed_at - left_at
	var expected := sqrt(2.0 * 1.6 / (absf(_player.get_gravity().y) * _player.gravity_scale))
	print("guard off: fell 1.6 m in %.2f s (free fall with gravity_scale %.1f: %.2f s)" % [
		fall_time, _player.gravity_scale, expected])
	_expect(left_at > 0.0 and landed_at > 0.0, "guard off: runs off the edge and lands")
	_expect(absf(fall_time - expected) < 0.1, "falls fast (gravity_scale)")
	guard.enabled = true
	await _teleport(Vector3.ZERO)
