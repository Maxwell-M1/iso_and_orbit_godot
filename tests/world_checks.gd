extends "res://tests/check_suite.gd"
## World: the mountain with a trail and "Windswept Peak", places (camp, hamlet, ruins) discovered with a message, places
## added during the game, characters standing at the places and not letting anyone through, a line of hero mage
## options with a free walkway along it; paths climb exactly the stairs the character steps onto.


func _checks() -> Array[Callable]:
	return [
		_check_mountain,
		_check_places,
		_check_places_added_later,
		_check_route.bind("around the knight at the hamlet", Vector3(-26.6, 0, 22.6), Vector3(-32.6, 0, 22.6), 15.0),
		_check_characters_at_places,
		_check_mage_options,
		_check_navigation_climb,
	]


## The mountain in the northeast: center (27, 0, −28), the summit at 10 m, a spiral trail from (23, 0, −19.4). On the
## summit is the place "Windswept Peak" ([PointOfInterest]).
func _check_mountain() -> void:
	print("\n== the mountain: up the path to the summit, the summit is discovered once, no way up the slopes")
	var center := Vector3(27, 0, -28)
	var summit_spot := center + Vector3(cos(deg_to_rad(85.0)), 0, sin(deg_to_rad(85.0))) * 2.0 + Vector3.UP * 10.0
	var summit: PointOfInterest = _levels.get_current_level().get_node("NavigationRegion3D/Mountain/Shrine/Summit")
	var toast: Label = _main.get_node("Hud/DiscoveryToast")
	var discoveries := [0]
	var on_discovered := func(_title: String) -> void: discoveries[0] += 1
	summit.discovered.connect(on_discovered)

	await _teleport(Vector3(21, 0, -15))
	var climb := await _run_until_arrived(summit_spot, 30.0)
	await _frames(30)
	var toast_text := toast.text
	var toast_shown := toast.modulate.a > 0.9
	var first_count: int = discoveries[0]
	await _teleport(Vector3(21, 0, -15))
	await _teleport(summit_spot)
	await _ticks(10)
	print(("route up: arrived %s in %.1f s, walked %.1f m, end %s, stuck ticks %d; discovered %d, " +
			"again after leaving %d; toast \"%s\" shown %s") % [
		climb.arrived, climb.time, climb.walked, _player.global_position.snapped(Vector3.ONE * 0.01), climb.stuck,
		first_count, discoveries[0], toast_text, toast_shown])
	_expect(climb.arrived and climb.error < 0.05 and absf(_player.global_position.y - 10.0) < 0.1 and climb.stuck < 6,
			"a click on the summit leads up the spiral path, no stuck")
	_expect(climb.walked > 35.0, "the way up is the path around the mountain, not straight up the slope")
	_expect(first_count == 1 and discoveries[0] == 1 and toast_text == "Discovered: Windswept Peak" and toast_shown,
			"reaching the summit discovers it once and shows the message")
	summit.discovered.disconnect(on_discovered)

	# A steep slope without the trail: running straight at the mountain's center (between the start and the end of the
	# trail, angle 100°).
	var foot := center + Vector3(cos(deg_to_rad(100.0)), 0, sin(deg_to_rad(100.0))) * 14.0
	await _teleport(foot)
	_mover.steer(center - foot)
	var highest := 0.0
	for i in 180:
		await _tree.physics_frame
		highest = maxf(highest, _player.global_position.y)
	_mover.stop()
	# Off the trail sideways, outward (the middle of the climb, angle 280°): the ledge guard keeps the character on the
	# trail.
	var path_angle := deg_to_rad(115.0 + 165.0)
	var path_radius := lerpf(9.5, 7.0, 0.5)
	var on_path := center + Vector3(cos(path_angle), 0, sin(path_angle)) * path_radius
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(on_path + Vector3.UP * 30.0, on_path + Vector3.DOWN * 5.0, 1))
	await _teleport(hit.position)
	var path_height: float = hit.position.y
	_mover.steer(Vector3(cos(path_angle), 0, sin(path_angle)))
	var lowest := path_height
	for i in 120:
		await _tree.physics_frame
		lowest = minf(lowest, _player.global_position.y)
	_mover.stop()
	# The guard turns an outward step along the edge, as at a wall: the character slides along the trail but does not
	# fall off it.
	var off_center := Vector2(_player.global_position.x - center.x, _player.global_position.z - center.z).length()
	print(("straight at the slope: highest %.2f m; off the path outwards at %.2f m: lowest %.2f m, " +
			"%.2f m from the axis (path edge %.2f)") % [
		highest, path_height, lowest, off_center, path_radius + 1.5])
	_expect(highest < 0.6, "the steep slope cannot be climbed")
	# The trail edge on the mountain grid (0.5 m cells) may stick out past the nominal edge by one cell.
	_expect(path_height > 4.0 and lowest > path_height - 1.0 and off_center < path_radius + 1.5 + 0.5,
			"the ledge guard keeps the character on the path")
	await _teleport(Vector3.ZERO)


## The camp, the hamlet and the ruins are discovered when you get there, and they show their names.
func _check_places() -> void:
	print("\n== places of interest: discovered on arrival, the message shows the name")
	var toast: Label = _main.get_node("Hud/DiscoveryToast")
	var report := PackedStringArray()
	var ok := true
	for place: PointOfInterest in _tree.get_nodes_in_group(PointOfInterest.GROUP):
		if place.title == "Windswept Peak":
			continue
		var before := place.is_discovered()
		await _teleport(place.global_position)
		# The message appears over fade_time (0.6 s).
		await _frames(45)
		var message := toast.text
		report.append("%s: before %s, now %s, message \"%s\"" % [place.name, before, place.is_discovered(), message])
		ok = ok and not before and place.is_discovered() and message == "Discovered: " + place.title \
				and toast.modulate.a > 0.9
	print(", ".join(report))
	_expect(report.size() == 3 and ok,
			"the camp, the hamlet and the ruins are discovered on arrival and named in the message")
	await _teleport(Vector3.ZERO)


## A place added during the game, as with a level loaded later, is announced too; one marked as found beforehand
## (mark_discovered) stays silent. Without watch_added_places the caption is only for the places there at startup.
func _check_places_added_later() -> void:
	print("\n== places added during the game: announced; one marked as found stays silent; not watched when asked")
	var toast: DiscoveryToast = _main.get_node("Hud/DiscoveryToast")
	await _wait_until(func() -> bool: return toast.modulate.a == 0.0, 600)
	var level := _levels.get_current_level()
	var announced := _add_place(level, "Lookout", Vector3(-8, 0, 0))
	var known := _add_place(level, "Old Well", Vector3(-8, 0, 6))
	known.mark_discovered()
	var signals := [0]
	var on_discovered := func(_title: String) -> void: signals[0] += 1
	known.discovered.connect(on_discovered)
	await _teleport(known.global_position)
	await _frames(45)
	var silent: bool = signals[0] == 0 and toast.modulate.a == 0.0
	await _teleport(announced.global_position)
	await _frames(45)
	var message := toast.text
	var shown := announced.is_discovered() and toast.modulate.a > 0.9
	print("marked as found: signals %d, message shown %s; added later: discovered %s, message \"%s\"" % [
		signals[0], not silent, announced.is_discovered(), message])
	_expect(silent, "a place marked as found does not announce itself")
	_expect(shown and message == "Discovered: Lookout", "a place added during the game is announced")
	await _wait_until(func() -> bool: return toast.modulate.a == 0.0, 600)
	toast.watch_added_places = false
	var unwatched := _add_place(level, "Quiet Hill", Vector3(-8, 0, -6))
	await _teleport(unwatched.global_position)
	await _frames(45)
	var unwatched_shown := toast.modulate.a > 0.0
	toast.watch_added_places = true
	print("not watched: discovered %s, message shown %s" % [unwatched.is_discovered(), unwatched_shown])
	_expect(unwatched.is_discovered() and not unwatched_shown,
			"without watch_added_places a place added later is found, but not announced")
	await _teleport(Vector3.ZERO)
	announced.queue_free()
	known.queue_free()
	unwatched.queue_free()
	await _wait_until(func() -> bool: return toast.modulate.a == 0.0, 600)


## A place of interest with a sphere of radius 1.5 m at [param at], added under [param level].
func _add_place(level: Node3D, title: String, at: Vector3) -> PointOfInterest:
	var place := PointOfInterest.new()
	place.title = title
	place.collision_layer = 0
	place.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5
	shape.shape = sphere
	place.add_child(shape)
	place.position = level.to_local(at)
	level.add_child(place)
	return place


## Characters stand at the points of interest: every place has someone, all of them on the ground (the wizard on the
## summit), each with a title and something in the hands; nobody can walk through a character.
func _check_characters_at_places() -> void:
	print("\n== characters at the places of interest: every place has someone, all stand on the ground")
	var characters: Node3D = _levels.get_current_level().get_node("NavigationRegion3D/Characters")
	var places := _tree.get_nodes_in_group(PointOfInterest.GROUP)
	var space := _player.get_world_3d().direct_space_state
	var visited := {}
	var report := PackedStringArray()
	var complete := characters.get_child_count() == 5
	for character: StaticBody3D in characters.get_children():
		var gear := 0
		for hand: Node in character.find_children("*Hand", "Node3D", true, false):
			gear += hand.get_child_count()
		var title: Label3D = character.get_node("Title")
		var place := _place_of(character.global_position, places)
		var query := PhysicsRayQueryParameters3D.create(character.global_position + Vector3.UP * 3.0,
				character.global_position + Vector3.DOWN * 3.0, 1, [character.get_rid()])
		var ground: Dictionary = space.intersect_ray(query)
		var above_ground := character.global_position.y - (ground.position.y as float) if not ground.is_empty() else INF
		report.append("%s \"%s\" gear %d at \"%s\", %.2f m above ground" % [character.name, title.text, gear,
				place.title if place != null else "-", above_ground])
		complete = complete and gear >= 1 and not title.text.is_empty() and place != null and absf(above_ground) < 0.05
		if place != null:
			visited[place] = true
	print(", ".join(report))
	_expect(complete, "five characters with titles and gear, each stands on the ground at a place of interest")
	_expect(places.size() == 4 and visited.size() == places.size(), "every place of interest has a character")
	var knight: Node3D = characters.get_node("Knight")
	await _teleport(knight.global_position + Vector3(3, 0, 0))
	_mover.steer(Vector3.LEFT)
	await _ticks(90)
	_mover.stop()
	var gap := _flat_distance(_player.global_position, knight.global_position)
	print("ran straight at the knight: stopped %.2f m from the centre" % gap)
	_expect(gap > 0.7, "the character cannot walk through a standing character")


## The place whose area contains [param position], or null.
func _place_of(position: Vector3, places: Array[Node]) -> PointOfInterest:
	for place: PointOfInterest in places:
		var shape: CollisionShape3D = place.get_node("CollisionShape3D")
		if position.distance_to(shape.global_position) < (shape.shape as SphereShape3D).radius:
			return place
	return null


## The line of hero mage options: ten numbered models, each with a staff in the right hand and everything needed to
## become the player's look; one can walk along the line without bumping into anything.
func _check_mage_options() -> void:
	print("\n== mage options for the hero: ten numbered models, each fits the player, the walkway along them is free")
	var gallery: Node3D = _levels.get_current_level().get_node("NavigationRegion3D/MageOptions")
	var report := PackedStringArray()
	var complete := gallery.get_child_count() == 10
	for i in gallery.get_child_count():
		var option: Node3D = gallery.get_child(i)
		var title: Label3D = option.get_node("Title")
		var model: Node3D = option.get_node("Model")
		var hand := model.get_node_or_null("RightHand") as Node3D
		var meshes := model.find_children("*", "GeometryInstance3D", true, false).size()
		var fits := (hand != null and hand.get_child_count() == 1 and model.has_node("Body")
				and model.has_node("EyeRight") and model.has_node("EyeLeft"))
		report.append("%s (%d meshes)" % [title.text, meshes])
		complete = complete and title.text.begins_with("%d · " % (i + 1)) and fits and meshes > 8
	print(", ".join(report))
	_expect(complete, "ten options numbered 1-10, each with Body, eyes and a staff in RightHand")
	var start := Vector3(0.5, 0, 12.6)
	await _teleport(start)
	_mover.steer(Vector3.RIGHT)
	var ticks := 0
	while _player.global_position.x < 21.0 and ticks < 300:
		await _tree.physics_frame
		ticks += 1
	_mover.stop()
	var drift := absf(_player.global_position.z - start.z)
	print("walked along the line to x %.2f in %.2f s, sideways drift %.3f m" % [
		_player.global_position.x, ticks * DT, drift])
	_expect(_player.global_position.x >= 21.0 and ticks * DT < 4.5 and drift < 0.05,
			"the walkway in front of the line is free: straight past all ten at full speed")
	await _teleport(Vector3.ZERO)


## The navigation mesh lets paths climb the stairs the character steps onto, and no higher: its agent_max_climb is
## the character's max_step_height.
func _check_navigation_climb() -> void:
	print("\n== the navigation mesh climbs the character's stairs")
	var region: NavigationRegion3D = _levels.get_current_level().get_node("NavigationRegion3D")
	var climb := region.navigation_mesh.agent_max_climb
	print("agent_max_climb %.2f m, max_step_height %.2f m" % [climb, _player.max_step_height])
	_expect(is_equal_approx(climb, _player.max_step_height),
			"the navigation mesh's agent_max_climb equals the character's max_step_height")
