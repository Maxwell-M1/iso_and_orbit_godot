extends "res://tests/check_suite.gd"
## Patrols use the real baked levels. The knight walks the line drawn for its route once, returns, waits ten seconds,
## and repeats. A character blocking it causes an immediate stop and one translated subtitle after 2.5 continuous
## seconds. The island's differently configured actor uses the same controller and waits at curve control points.
## Additional copies use external transformed curves, their handles, and script-defined routes without demo input.
## A route's points lie on the line the editor draws, whatever its Bake Interval.

const MEADOW := "res://shared/world/world.tscn"
const ISLAND := "res://shared/world/island/island.tscn"


func _checks() -> Array[Callable]:
	return [_check_knight_cycle, _check_blocking, _check_blocking_area, _check_island_patrol, _check_external_routes,
		_check_closed_curve, _check_drawn_line, _check_missing_links]


func _knight() -> PatrolActor:
	return _levels.get_current_level().get_node("NavigationRegion3D/Characters/Knight") as PatrolActor


func _start_at_home(actor: PatrolActor) -> void:
	actor.controller.stop()
	actor.character.teleport(actor.global_position)
	actor.controller.enabled = true
	actor.controller.restart()


func _check_knight_cycle() -> void:
	print("\n== the knight walks the line drawn for its route, returns home, waits ten seconds and repeats")
	if _levels.get_current_level().scene_file_path != MEADOW:
		_levels.change_level(MEADOW)
		await _levels.level_change_finished
	var actor := _knight()
	await _teleport(Vector3.ZERO)

	_start_at_home(actor)
	var before := actor.controller.get_completed_cycles()
	var drawn := _drawn_line(actor.route)
	var corners := PackedVector3Array()
	var closest := PackedFloat32Array()
	for point in actor.route.curve.point_count:
		corners.append(actor.route.to_global(actor.route.curve.get_point_position(point)))
		closest.append(INF)
	var farthest := 0.0
	var joined := false
	var yaw := NAN
	var turn := NAN
	var sharpest_turn := 0.0
	var turn_change := 0.0
	for i in 5400:
		await _tree.physics_frame
		var position := actor.character.global_position
		var index := actor.controller.get_waypoint_index()
		var size := (actor.controller.get("_points") as PackedVector3Array).size()
		var forward := -actor.character.visual.global_basis.z
		var new_yaw := atan2(forward.x, forward.z)
		# Along the route only, from where the knight has come onto the line: the ways from home to its first point
		# and back are not part of the drawn line.
		var off := _distance_to_line(position, drawn)
		joined = joined or (index >= 1 and off < 0.1)
		if joined and index < size:
			farthest = maxf(farthest, off)
			for point in corners.size():
				closest[point] = minf(closest[point], _flat_distance(position, corners[point]))
		if joined and index < size - 1 and actor.controller.get_state() == PatrolController.State.MOVING \
				and not is_nan(yaw):
			var new_turn := absf(rad_to_deg(angle_difference(yaw, new_yaw)))
			sharpest_turn = maxf(sharpest_turn, new_turn)
			if not is_nan(turn):
				turn_change = maxf(turn_change, absf(new_turn - turn))
			turn = new_turn
		else:
			turn = NAN
		yaw = new_yaw
		if actor.controller.get_completed_cycles() > before:
			break
	var home := actor.character.global_position
	_expect(farthest < 0.4, "the knight keeps within 0.4 m of the line the editor draws for its route")
	_expect(_max(closest.slice(1)) < 0.4, "the knight passes every point of its route")
	_expect(sharpest_turn < 6.0 and turn_change < 3.0,
			"the knight turns smoothly along its route, not in jerks from point to point")
	_expect(actor.controller.get_completed_cycles() == before + 1
			and _flat_distance(home, actor.global_position) < 0.05,
			"one patrol ends at the original position by the house and well")
	_expect(actor.controller.get_state() == PatrolController.State.WAITING, "the knight waits after returning home")
	await _ticks(594)
	_expect(actor.controller.get_state() == PatrolController.State.WAITING
			and _flat_distance(home, actor.character.global_position) < 0.001,
			"after 9.9 seconds the knight still stands at home")
	await _ticks(14)
	_expect(actor.controller.get_state() == PatrolController.State.MOVING and actor.character.get_move_speed() > 0.1,
			"after ten seconds the next patrol starts")
	actor.controller.stop()
	actor.character.teleport(actor.global_position)


func _check_blocking() -> void:
	print("\n== blocked by the hero: stop, subtitle after 2.5 seconds, no spam, resume the same destination")
	var actor := _knight()
	var subtitles: SubtitleDisplay = _main.get_node("Hud/Subtitles")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	settings.set_value(GameSettings.LANGUAGE, "ru")
	subtitles.clear()
	actor.controller.stop()
	actor.character.teleport(actor.global_position)
	var direction := Vector3(5.6, 0, -10.1).normalized()
	await _teleport(actor.global_position + direction * 0.9)
	var speeches := [0]
	var spoken_at := [0.0]
	var on_speech := func(_speaker: String, _line: String):
		speeches[0] += 1
		spoken_at[0] = actor.controller.get_blocked_time()
	_expect(is_equal_approx(actor.controller.blocked_delay, 2.5), "the knight's authored speech delay is 2.5 seconds")
	actor.speech_requested.connect(on_speech)
	actor.controller.enabled = true
	actor.controller.restart()
	await _wait_until(func() -> bool: return actor.controller.get_state() == PatrolController.State.BLOCKED, 120)
	var stopped := actor.character.global_position
	_expect(actor.controller.get_state() == PatrolController.State.BLOCKED and actor.character.get_move_speed() < 0.01,
			"the knight stops before reaching the hero")
	# Both bodies must collide: a moving hero cannot simply walk through the waiting knight.
	_mover.steer(-direction)
	await _ticks(60)
	_mover.stop()
	await _ticks_until_stopped(60)
	_expect(_flat_distance(_player.global_position, actor.character.global_position) > 0.68
			and _flat_distance(stopped, actor.character.global_position) < 0.005,
			"the hero cannot walk through the knight, and the knight does not push the hero")
	await _wait_until(func() -> bool: return actor.controller.get_blocked_time() >= 2.5 - 2.0 * DT, 300)
	_expect(speeches[0] == 0 and not subtitles.visible, "no subtitle before 2.5 continuous blocked seconds")
	await _ticks(4)
	var caption := subtitles.get_node("Caption") as Label
	_expect(speeches[0] == 1 and subtitles.visible
			and caption.text == "Рыцарь: Дай пройти. Ты знаешь, кто мой отец?",
			"after 2.5 seconds the knight asks the exact Russian question")
	_expect(spoken_at[0] >= 2.5 and spoken_at[0] <= 2.5 + DT + 0.0001,
			"speech starts on the first physics tick reaching the 2.5-second threshold")
	await _ticks(120)
	_expect(speeches[0] == 1, "a continuous obstruction does not repeat the line")
	settings.set_value(GameSettings.LANGUAGE, "en")
	await _frames(2)
	_expect(caption.text == "Knight: Let me through. Do you know who my father is?",
			"the visible subtitle follows a language change")
	await _teleport(Vector3.ZERO)
	await _ticks(30)
	_expect(actor.controller.get_state() == PatrolController.State.MOVING
			and actor.controller.get_waypoint_index() == 0 and actor.character.get_move_speed() > 1.0,
			"when the hero leaves, the knight resumes the interrupted route point")
	_expect(actor.controller.get_blocked_time() == 0.0, "clearing the obstruction resets its continuous timer")
	actor.speech_requested.disconnect(on_speech)
	actor.controller.stop()
	actor.character.teleport(actor.global_position)
	subtitles.clear()
	await _teleport(Vector3.ZERO)


func _check_blocking_area() -> void:
	print("\n== only a character in front stops a patrol: a meter ahead and a little to the sides, like a flashlight")
	var fixture := Node3D.new()
	fixture.position = Vector3(-80, 0, 80)
	_tree.root.add_child(fixture)
	var floor := StaticBody3D.new()
	floor.position.y = -0.5
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = BoxShape3D.new()
	(floor_shape.shape as BoxShape3D).size = Vector3(40, 1, 40)
	floor.add_child(floor_shape)
	fixture.add_child(floor)
	var actor: PatrolActor = load("res://gdscript/npc/patrol_actor.tscn").instantiate()
	actor.controller.enabled = false
	fixture.add_child(actor)
	actor.character.mover.use_navigation = false
	# A character standing still, as wide as the actor: a capsule 0.35 m in radius on the characters' layer.
	var other := CharacterBody3D.new()
	other.collision_layer = 2
	other.collision_mask = 0
	# Away from the actor at first: overlapping it, the other would push it aside on the first tick.
	other.position = Vector3(30, 0, 0)
	var other_shape := CollisionShape3D.new()
	other_shape.shape = CapsuleShape3D.new()
	(other_shape.shape as CapsuleShape3D).radius = 0.35
	(other_shape.shape as CapsuleShape3D).height = 1.8
	other_shape.position.y = 0.9
	other.add_child(other_shape)
	fixture.add_child(other)
	var stopped := {}
	var gaps := {}
	# The actor starts at the fixture's origin facing +X and walks 10 m along +X.
	for place: Array in [["ahead", Vector3(4, 0, 0)], ["a little to the side", Vector3(4, 0, 0.75)],
			["at the side", Vector3(4, 0, 1.6)], ["behind", Vector3(-0.9, 0, 0)]]:
		other.position = place[1]
		actor.character.teleport(fixture.to_global(Vector3.ZERO), Vector3.RIGHT)
		actor.controller.set_route_points(PackedVector3Array([fixture.to_global(Vector3(10, 0, 0))]))
		actor.controller.enabled = true
		stopped[place[0]] = false
		for tick in 360:
			await _tree.physics_frame
			if actor.controller.get_state() == PatrolController.State.BLOCKED:
				stopped[place[0]] = true
				gaps[place[0]] = _flat_distance(actor.character.global_position, other.global_position) - 0.7
				break
			if fixture.to_local(actor.character.global_position).x > 8.0:
				break
		actor.controller.stop()
	_expect(stopped["ahead"] and gaps["ahead"] > 0.9 and gaps["ahead"] <= 1.01,
			"a character on the way stops the patrol a meter before it")
	_expect(stopped["a little to the side"], "a character a little to the side in front stops it too, as in a beam")
	_expect(not stopped["at the side"] and not stopped["behind"],
			"a character at the side or behind does not stop it")
	fixture.queue_free()
	await _frames(2)


func _check_island_patrol() -> void:
	print("\n== the island ranger uses the same reusable controller with different waits")
	_levels.change_level(ISLAND)
	await _levels.level_change_finished
	var actor: PatrolActor = _levels.get_current_level().get_node("NavigationRegion3D/IslandPatrol")
	await _teleport(Vector3(0, 0, -11))
	_start_at_home(actor)
	var before := actor.controller.get_completed_cycles()
	var reached := 0
	var previous := -1
	var wait_ticks := 0
	var point_waits := PackedInt32Array()
	for i in 3600:
		await _tree.physics_frame
		var index := actor.controller.get_waypoint_index()
		if index != previous:
			previous = index
			reached += 1
		if actor.controller.get_state() == PatrolController.State.WAITING:
			wait_ticks += 1
		elif wait_ticks > 0:
			point_waits.append(wait_ticks)
			wait_ticks = 0
		if actor.controller.get_completed_cycles() > before:
			break
	_expect(actor.controller.get_completed_cycles() == before + 1
			and _flat_distance(actor.character.global_position, actor.global_position) < 0.05 and reached >= 5,
			"the island ranger completes the route and returns to its start")
	_expect(point_waits.size() == 4 and Array(point_waits).all(func(ticks: int) -> bool: return ticks >= 59),
			"the same controller applies the island's one-second pauses at route points")
	_expect(actor.controller.cycle_wait == 3.0 and actor.model_scene.resource_path.ends_with("ranger.tscn"),
			"model and patrol waits are configured per actor, without a second movement implementation")
	actor.controller.stop()
	_levels.change_level(MEADOW)
	await _levels.level_change_finished
	await _teleport(Vector3.ZERO)


func _check_external_routes() -> void:
	print("\n== reusable actor instances use level-owned, transformed curves and independent patrol state")
	var fixture := Node3D.new()
	fixture.position = Vector3(80, 0, 80)
	_tree.root.add_child(fixture)
	var floor := StaticBody3D.new()
	floor.position.y = -0.5
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(50, 1, 50)
	shape.shape = box
	floor.add_child(shape)
	fixture.add_child(floor)
	var scene: PackedScene = load("res://gdscript/npc/knight_patrol.tscn")
	var idle: PatrolActor = scene.instantiate()
	idle.position.x = -20.0
	fixture.add_child(idle)
	await _ticks(5)
	_expect(idle.controller.get_state() == PatrolController.State.IDLE and not idle.has_node("Route")
			and not idle._get_configuration_warnings().is_empty(),
			"the copyable knight contains no route and safely stays idle until one is assigned")
	idle.queue_free()
	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO, Vector3.ZERO, Vector3(0, 0, 5))
	curve.add_point(Vector3(8, 0, 0), Vector3(0, 0, 5))
	var actors: Array[PatrolActor] = []
	var paths: Array[Path3D] = []
	for index in 2:
		var path := Path3D.new()
		path.position = Vector3(3 - index * 16, 0, -3)
		path.rotation.y = PI / 2.0
		path.scale = Vector3(1.1, 1.0, 0.8)
		path.curve = curve
		fixture.add_child(path)
		paths.append(path)
		var actor: PatrolActor = scene.instantiate()
		actor.position.x = -index * 16.0
		actor.route = path
		actor.character.mover.use_navigation = false
		actor.controller.repeat = false
		actor.controller.enabled = false
		actor.controller.waypoint_wait = index * 0.2
		fixture.add_child(actor)
		actors.append(actor)
	_expect(actors[0].controller.route == paths[0] and actors[1].controller.route == paths[1],
			"two instances of the same knight scene give their controllers their own routes of the level")
	var middle: Array[Vector3] = [paths[0].to_global(curve.sample(0, 0.5)), paths[1].to_global(curve.sample(0, 0.5))]
	var visited := [false, false]
	var minimum_speed := INF
	for actor in actors:
		actor.controller.enabled = true
	for tick in 1800:
		await _tree.physics_frame
		for index in 2:
			var actor := actors[index]
			if _flat_distance(actor.character.global_position, middle[index]) < 0.7:
				visited[index] = true
		var local := paths[0].to_local(actors[0].character.global_position)
		if local.x > 1.0 and local.x < 7.0 and local.z > 1.0:
			minimum_speed = minf(minimum_speed, actors[0].character.get_move_speed())
		if actors.all(func(actor: PatrolActor) -> bool: return actor.controller.get_completed_cycles() == 1):
			break
	_expect(visited[0] and visited[1], "both actors follow the curve handles with translated, rotated and scaled paths")
	_expect(minimum_speed > 0.8 and minimum_speed < INF, "generated curve samples preserve a continuous walk")
	var returned := true
	for actor in actors:
		returned = returned and actor.controller.get_completed_cycles() == 1 \
				and _flat_distance(actor.character.global_position, actor.global_position) < 0.05
	_expect(returned,
			"each actor returns to its own home and completes its own cycle")
	_expect(curve.point_count == 2 and curve.get_point_out(0) == Vector3(0, 0, 5)
			and paths[0].curve == paths[1].curve, "sampling leaves a shared Curve3D resource unchanged")
	# The editor can change a route without changing the actor scene. A restart captures the new shape.
	curve.set_point_position(1, Vector3(10, 0, 0))
	actors[0].controller.enabled = true
	var end := paths[0].to_global(curve.get_point_position(1))
	var saw_new_end := false
	for tick in 1800:
		await _tree.physics_frame
		saw_new_end = saw_new_end or _flat_distance(actors[0].character.global_position, end) < 0.05
		if actors[0].controller.get_completed_cycles() == 2:
			break
	_expect(saw_new_end and actors[0].controller.get_completed_cycles() == 2,
			"restarting captures edits to the level curve without rebuilding the character")
	var programmed := PackedVector3Array([fixture.to_global(Vector3(0, 0, 6)), fixture.to_global(Vector3(5, 0, 6))])
	actors[0].controller.set_route_points(programmed)
	programmed[1] = fixture.to_global(Vector3(22, 0, 22))
	actors[0].controller.enabled = true
	var saw_script_end := false
	for tick in 1800:
		await _tree.physics_frame
		saw_script_end = saw_script_end or _flat_distance(actors[0].character.global_position,
				fixture.to_global(Vector3(5, 0, 6))) < 0.05
		if actors[0].controller.get_completed_cycles() == 3:
			break
	_expect(saw_script_end and actors[0].controller.route == null and actors[0].controller.get_completed_cycles() == 3,
			"the same controller accepts a copied array of world positions instead of an editor curve")
	fixture.queue_free()
	await _frames(2)


func _check_closed_curve() -> void:
	print("\n== the native closed-curve option includes the last-to-first segment")
	var fixture := Node3D.new()
	_tree.root.add_child(fixture)
	var path := Path3D.new()
	path.curve = Curve3D.new()
	path.curve.add_point(Vector3.ZERO)
	path.curve.add_point(Vector3(6, 0, 0))
	path.curve.add_point(Vector3(6, 0, -6), Vector3.ZERO, Vector3(0, 0, -5))
	path.curve.set_point_in(0, Vector3(0, 0, -5))
	path.curve.closed = true
	fixture.add_child(path)
	var actor: PatrolActor = load("res://gdscript/npc/patrol_actor.tscn").instantiate()
	actor.route = path
	actor.controller.enabled = false
	fixture.add_child(actor)
	actor.controller.restart()
	var points: PackedVector3Array = actor.controller.get("_points")
	_expect(points.size() > 10 and points[-1].is_equal_approx(Vector3.ZERO)
			and Array(points).any(func(point: Vector3) -> bool: return point.z < -6.0),
			"a closed curve samples its closing segment and its handles, not a straight shortcut home")
	fixture.queue_free()
	await _frames(2)


func _check_drawn_line() -> void:
	print("\n== a route's points lie on the line the editor draws, shaped by the points, handles and Bake Interval")
	var fixture := Node3D.new()
	_tree.root.add_child(fixture)
	var path := Path3D.new()
	path.position = Vector3(40, 0, -30)
	path.rotation.y = 0.6
	path.scale = Vector3(1.2, 1.0, 0.9)
	path.curve = Curve3D.new()
	for point: Vector3 in [Vector3.ZERO, Vector3(8, 0, 0), Vector3(8, 0, -3), Vector3(0, 0, -3)]:
		path.curve.add_point(point)
	# No handles: a Bake Interval longer than every side makes the editor draw the U-turn round.
	path.curve.bake_interval = 20.0
	fixture.add_child(path)
	var actor: PatrolActor = load("res://gdscript/npc/patrol_actor.tscn").instantiate()
	actor.route = path
	actor.controller.enabled = false
	fixture.add_child(actor)
	var corners := PackedVector3Array()
	for point in path.curve.point_count:
		corners.append(path.to_global(path.curve.get_point_position(point)))
	actor.controller.restart()
	var points: PackedVector3Array = actor.controller.get("_points")
	var pauses: PackedByteArray = actor.controller.get("_pause_points")
	var drawn := _drawn_line(path)
	var off_drawn := 0.0
	var off_straight := 0.0
	var longest := 0.0
	var paused := PackedVector3Array()
	for index in points.size():
		off_drawn = maxf(off_drawn, _distance_to_line(points[index], drawn))
		off_straight = maxf(off_straight, _distance_to_line(points[index], corners))
		if index > 0:
			longest = maxf(longest, points[index - 1].distance_to(points[index]))
		if pauses[index]:
			paused.append(points[index])
	_expect(off_drawn < 0.01 and off_straight > 0.5,
			"with a long Bake Interval the points follow the round line the editor draws, not the straight sides")
	_expect(longest <= actor.controller.sample_spacing + 0.001, "the points are at most Sample Spacing apart")
	_expect(paused.size() == corners.size() and range(corners.size()).all(
			func(index: int) -> bool: return paused[index].is_equal_approx(corners[index])),
			"the control points are the pause points, exactly and in order")
	path.curve.bake_interval = 0.1
	actor.controller.restart()
	off_straight = 0.0
	for point: Vector3 in actor.controller.get("_points"):
		off_straight = maxf(off_straight, _distance_to_line(point, corners))
	_expect(off_straight < 0.05, "with a short Bake Interval the same points give the straight sides, as drawn")
	fixture.queue_free()
	await _frames(2)


# The line the editor draws for a route: the curve's baked points joined smoothly, in world space, every 5 cm.
static func _drawn_line(route: Path3D) -> PackedVector3Array:
	var length := route.curve.get_baked_length()
	var count := maxi(1, ceili(length / 0.05))
	var line := PackedVector3Array()
	for index in count + 1:
		line.append(route.to_global(route.curve.sample_baked(length * index / count, true)))
	return line


static func _distance_to_line(point: Vector3, line: PackedVector3Array) -> float:
	var flat := Vector2(point.x, point.z)
	var nearest := INF
	for index in line.size() - 1:
		var closest := Geometry2D.get_closest_point_to_segment(flat, Vector2(line[index].x, line[index].z),
				Vector2(line[index + 1].x, line[index + 1].z))
		nearest = minf(nearest, flat.distance_to(closest))
	return nearest


func _check_missing_links() -> void:
	print("\n== an unfinished actor reports its missing scene links without starting gameplay")
	var actor := PatrolActor.new()
	_tree.root.add_child(actor)
	_expect(not actor._get_configuration_warnings().is_empty() and not actor.is_in_group(PatrolActor.GROUP),
			"an actor without a controller stays inert and reports its configuration")
	actor.queue_free()
	await _frames(2)
