extends "res://tests/check_suite.gd"
## Levels: the meadow's spawn point where the game starts; the teleport pad offers to travel, and walking away hides the
## offer; the key confirms it, with Shift held too, and the change goes behind the loading screen: the name of the
## place, a bar that only grows to the end, at least the shortest time, the game paused and the controls taken away, a
## second request refused, a click and the settings key lost; the old level freed. On the island the hero stands at its
## spawn point facing its way with the camera behind it, runs by a click along the island's navigation, finds a place
## there, keeps its stamina, and the settings still reach it; at the edge, clicks pass the invisible walls and the hero
## does not. A click on the offer brings it back, to the spawn point by the meadow's pad, where the places found before
## stay quiet. A portal added beside the pad, a scene that cannot be a level, a portal that travels by itself with
## nothing to wait for and the navigation ready at once, a change in slow motion, the controls given back as they were,
## and a wrong level file that keeps the level.

const MEADOW := "res://shared/world/world.tscn"
const ISLAND := "res://shared/world/island/island.tscn"

var _loading: LoadingScreen
var _prompt: TravelPrompt


func setup(tree: SceneTree, main: Node3D) -> void:
	super(tree, main)
	_loading = main.get_node("LoadingScreen")
	_prompt = main.get_node("Hud/TravelPrompt")


func _checks() -> Array[Callable]:
	return [
		_check_start,
		_check_prompt,
		_check_travel_by_key,
		_check_island,
		_check_island_edge,
		_check_travel_back_by_click,
		_check_portals_side_by_side,
		_check_failed_change,
		_check_auto_travel,
		_check_slow_motion,
		_check_controls_given_back,
		_check_wrong_level,
	]


## The meadow is the level the game starts on; its spawn point is where the hero stood before the levels came: at the
## origin, facing north.
func _check_start() -> void:
	print("\n== the start: the meadow and its spawn point")
	var level := _levels.get_current_level()
	var spawn := _levels.find_spawn_point()
	print("level %s, spawn \"%s\" at %s facing %s" % [level.scene_file_path, spawn.spawn_name if spawn else "-",
			spawn.global_position if spawn else Vector3.INF, spawn.get_facing() if spawn else Vector3.ZERO])
	_expect(level.scene_file_path == MEADOW and spawn != null and spawn.global_position.is_zero_approx()
			and spawn.get_facing().is_equal_approx(Vector3.FORWARD),
			"the game starts on the meadow, at the origin facing north")
	# A place found before the travel, for the return (_check_travel_back_by_click); the other suites may have found it.
	var circle := _find_place("Ancient Circle")
	if not circle.is_discovered():
		await _teleport(circle.global_position)
		await _ticks(2)
	var toast: DiscoveryToast = _main.get_node("Hud/DiscoveryToast")
	await _wait_until(func() -> bool: return toast.modulate.a == 0.0, 600)


## Walking onto the pad offers to travel to the island with the E key; walking away hides the offer.
func _check_prompt() -> void:
	print("\n== the teleport pad: walking onto it offers to travel, walking away hides the offer")
	var pad := _get_portal()
	await _teleport(pad.global_position + Vector3(0, 0, 3.5))
	await _settle_camera()
	var hidden_before := not _prompt.visible
	var run := await _run_until_arrived(pad.global_position, 5.0)
	await _ticks(2)
	var shown := _prompt.visible and _prompt.get_portal() == pad
	var key := (_prompt.get_node("%Key") as Label).text
	var text := (_prompt.get_node("%Button") as Button).text
	var focus := (_prompt.get_node("%Button") as Button).focus_mode
	await _run_until_arrived(pad.global_position + Vector3(0, 0, 3.5), 5.0)
	await _ticks(2)
	var hidden_after := not _prompt.visible and _prompt.get_portal() == null
	print(("hidden before %s; on the pad (arrived %s): shown %s, key \"%s\", \"%s\", focus mode %d; walked away: " +
			"hidden %s") % [hidden_before, run.arrived, shown, key, text, focus, hidden_after])
	_expect(hidden_before and shown and key == "E" and text == "Teleport to Lonely Isle",
			"on the pad: \"E\" and \"Teleport to Lonely Isle\"")
	_expect(focus == Control.FOCUS_NONE, "the offer never takes the keyboard focus (Space jumps, it does not confirm)")
	_expect(hidden_after, "walking away hides the offer")


## E on the pad, with Shift held (the hero sprints onto the pad): the loading screen with the name of the island and a
## bar that only grows to the end, at least the shortest time; meanwhile the game is paused, the hero takes no input,
## the settings key does not open the settings and a second request is refused; the meadow is freed. On the island the
## hero stands at its spawn point, faces its way, the camera behind it, and nothing is left from the meadow: no
## destination, no marker, no waiting follow.
func _check_travel_by_key() -> void:
	print("\n== the key on the pad, with Shift held: the island behind the loading screen")
	var pad := _get_portal()
	_player.stamina.refill()
	_player.stamina.spend(_player.stamina.max_value * 0.5)
	var stamina_before := _player.stamina.get_ratio()
	await _teleport(pad.global_position)
	await _ticks(2)
	var offered := _prompt.visible
	var meadow: WeakRef = weakref(_levels.get_current_level())
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	_send_key(KEY_E, true)
	var started := await _wait_for_start()
	var busy := _levels.change_level(ISLAND)
	var title := (_loading.get_node("%Title") as Label).text
	var hidden := not (_main.get_node("Hud") as CanvasLayer).visible and not _prompt.visible
	var controls_off := not _hero.controls_enabled
	# A click and the settings key while the screen is up: the game must not get them.
	var center := _tree.root.get_visible_rect().size / 2.0
	_send_button(MOUSE_BUTTON_LEFT, true, center)
	await _frames(1)
	_send_button(MOUSE_BUTTON_LEFT, false, center)
	_send_key(KEY_F10)
	var change := await _wait_for_change()
	await _ticks(2)
	var ui: UiRoot = _main.get_node("UiRoot")
	var settings_opened := ui.has_open_screens()
	var island := _levels.get_current_level()
	var spawn := _levels.find_spawn_point(&"default", island)
	var facing := spawn.get_facing()
	var position_error := _flat_distance(_player.global_position, spawn.global_position)
	var model_angle := _flat_angle(_visual_forward(), facing)
	var camera_angle := _flat_angle(_camera_forward(), facing)
	var orphans_after := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var stamina_after := _player.stamina.get_ratio()
	print(("offered %s; started %s, a second request: %s; title \"%s\", the interface hidden %s, controls off %s; " +
			"%d frames (%.2f s), bar %s, grew only %s, paused %s; the settings opened %s; on %s: %.3f m from the " +
			"spawn point, model %.1f° and camera %.1f° from its facing, destination %s, marker %s, follow waiting %s, " +
			"paused %s, controls %s, screen open %s; the meadow freed %s, orphans %d -> %d; stamina %.2f -> %.2f") % [
		offered, started, error_string(busy), title, hidden, controls_off, change.frames, change.frames * DT,
		_bar_summary(change.bar), change.grew, change.paused, settings_opened, island.scene_file_path, position_error,
		model_angle, camera_angle, _mover.has_destination(), _marker.visible, _rig.is_follow_waiting(), _tree.paused,
		_hero.controls_enabled, _loading.is_open(), meadow.get_ref() == null, orphans_before, orphans_after,
		stamina_before, stamina_after])
	_expect(offered and started and busy == ERR_BUSY,
			"the key on the pad, with Shift held, starts the change; a second request is refused")
	_expect(title == "Lonely Isle" and hidden and controls_off,
			"the loading screen names the island; the interface is hidden and the controls are off")
	_expect(change.paused and change.grew and change.bar[-1] == 1.0 and change.frames * DT >= _levels.min_loading_time,
			"the game is paused meanwhile; the bar only grows, to the end, for at least min_loading_time")
	_expect(island.scene_file_path == ISLAND and meadow.get_ref() == null and orphans_after <= orphans_before,
			"the island is the level now, and the meadow is freed")
	_expect(position_error < 0.05 and model_angle < 1.0 and camera_angle < 1.0,
			"the hero stands at the island's spawn point facing its way, the camera behind it")
	_expect(not _mover.has_destination() and not _marker.visible and not _rig.is_follow_waiting()
			and not settings_opened,
			"the click and the settings key during the change are lost; no destination, no marker, no waiting follow")
	_expect(not _tree.paused and _hero.controls_enabled and not _loading.is_open(),
			"after the change the game runs, the controls are back, the screen is gone")
	_expect(absf(stamina_after - stamina_before) < 0.1, "the stamina is kept")
	_player.stamina.refill()


## On the island: a click runs along the island's navigation; the camp is a place, announced when found; the settings
## still reach the hero.
func _check_island() -> void:
	print("\n== the island: a click run, a place, the settings")
	await _settle_camera()
	var target := _player.global_position + Vector3(-5, 0, -3)
	var screen := _camera.unproject_position(target)
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	for i in 10:
		if not _mover.get_remaining_path().is_empty():
			break
		await _tree.physics_frame
	var path := _mover.get_remaining_path().size()
	var run := await _run_until_arrived(target, 10.0, false)
	var toast: DiscoveryToast = _main.get_node("Hud/DiscoveryToast")
	await _wait_until(func() -> bool: return toast.modulate.a == 0.0, 600)
	var camp := _find_place("Hermit's Camp")
	await _teleport(camp.global_position + Vector3(0, 0, 3))
	await _frames(45)
	var message := toast.text
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	settings.set_value(GameSettings.PATH_LINE, true)
	var path_line := _hero.path_view.visible
	settings.set_value(GameSettings.PATH_LINE, false)
	print("a click run: path points %d, arrived %s, error %.3f m; the camp: discovered %s, message \"%s\"; " % [
		path, run.arrived, run.error, camp.is_discovered(), message] + "the path line setting: %s" % path_line)
	_expect(path > 0 and run.arrived and run.error < 0.05, "a click runs along the island's navigation to the point")
	_expect(camp.is_discovered() and message == "Discovered: Hermit's Camp", "the camp on the island is announced")
	_expect(path_line and not _hero.path_view.visible, "the settings still reach the hero")
	await _wait_until(func() -> bool: return toast.modulate.a == 0.0, 600)


## The island's edge: invisible walls on the bounds layer. A click on the water beyond them lands on no wall (no marker
## in the air), and running at the edge with the ledge guard off, the walls keep the hero on the island.
func _check_island_edge() -> void:
	print("\n== the island's edge: clicks pass the walls, the hero does not")
	var edge: StaticBody3D = _levels.get_current_level().get_node("NavigationRegion3D/Edge")
	# Between the bushes and the boulders of the shore.
	var outward := Vector3(sin(deg_to_rad(74.0)), 0, cos(deg_to_rad(74.0)))
	await _teleport(outward * 9.0)
	_rig.look_along(outward)
	_rig.snap()
	await _settle_camera()
	var water := outward * 17.5 + Vector3(0, -0.6, 0)
	var screen := _camera.unproject_position(water)
	var on_screen := not _camera.is_position_behind(water) and _tree.root.get_visible_rect().has_point(screen)
	var from := _camera.project_ray_origin(screen)
	var to := from + _camera.project_ray_normal(screen) * 100.0
	var space := _camera.get_world_3d().direct_space_state
	var wall_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, edge.collision_layer))
	var click_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, _input.ground_mask))
	_send_motion(screen, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, screen)
	await _tree.physics_frame
	_send_button(MOUSE_BUTTON_LEFT, false, screen)
	await _ticks(20)
	var marker_height := _marker.global_position.y if _marker.visible else 0.0
	_mover.stop()
	await _ticks(30)
	var guard_was: bool = _player.ledge_guard.enabled
	_player.ledge_guard.enabled = false
	_mover.steer(outward)
	var farthest := 0.0
	var lowest := 0.0
	for i in 120:
		await _tree.physics_frame
		farthest = maxf(farthest, _flat_distance(_player.global_position, Vector3.ZERO))
		lowest = minf(lowest, _player.global_position.y)
	_mover.stop()
	_player.ledge_guard.enabled = guard_was
	print(("the water on screen %s; the ray crosses the wall %s, the click ray stops at %s; marker %s at %.2f m; " +
			"running out: at most %.2f m from the middle, lowest %.2f m") % [on_screen, wall_hit.get("collider") == edge,
			click_hit.get("collider", "nothing"), _marker.visible, marker_height, farthest, lowest])
	_expect(on_screen and wall_hit.get("collider") == edge and click_hit.get("collider") != edge
			and marker_height < 0.5, "a click on the water beyond the edge passes the wall: no marker in the air")
	_expect(farthest < 14.5 and lowest > -0.1, "the walls keep the hero on the island, even with the ledge guard off")
	await _teleport(Vector3(0, 0, 6.5))


## A click on the offer at the island's pad brings the hero back: to the spawn point beside the meadow's pad, with the
## pad behind it or to the side; the click does not send the hero anywhere. The places found on the meadow before stay
## quiet.
func _check_travel_back_by_click() -> void:
	print("\n== a click on the offer: back to the meadow, by its pad")
	var pad := _get_portal()
	await _teleport(pad.global_position)
	await _ticks(2)
	var button: Button = _prompt.get_node("%Button")
	var text := button.text
	var center := button.get_global_rect().get_center()
	_send_motion(center, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_LEFT, true, center)
	await _frames(1)
	_send_button(MOUSE_BUTTON_LEFT, false, center)
	var started := await _wait_for_start()
	var destination := _mover.has_destination()
	await _wait_for_change()
	await _ticks(2)
	var meadow := _levels.get_current_level()
	var spawn := _levels.find_spawn_point(&"from_island", meadow)
	var back_pad := _get_portal()
	var to_pad := (back_pad.global_position - spawn.global_position).normalized()
	var position_error := _flat_distance(_player.global_position, spawn.global_position)
	var facing_angle := _flat_angle(_visual_forward(), spawn.get_facing())
	var pad_ahead := spawn.get_facing().dot(to_pad)
	var circle := _find_place("Ancient Circle")
	var found_before := circle.is_discovered()
	var signals := [0]
	var on_discovered := func(_title: String) -> void: signals[0] += 1
	circle.discovered.connect(on_discovered)
	var toast: DiscoveryToast = _main.get_node("Hud/DiscoveryToast")
	await _teleport(circle.global_position)
	await _frames(45)
	circle.discovered.disconnect(on_discovered)
	print(("\"%s\": started %s, a destination from the click %s; on %s: %.3f m from \"from_island\", facing %.1f° " +
			"from it, the pad ahead of it by %.2f; the Ancient Circle: found before %s, signals %d, message shown " +
			"%s") % [text, started, destination, meadow.scene_file_path, position_error, facing_angle, pad_ahead,
			found_before, signals[0], toast.modulate.a > 0.0])
	_expect(text == "Teleport to Green Vale" and started and not destination,
			"a click on the offer travels and does not send the hero anywhere")
	_expect(meadow.scene_file_path == MEADOW and position_error < 0.05 and facing_angle < 1.0 and pad_ahead <= 0.0,
			"back on the meadow by its pad, with the pad behind or to the side")
	_expect(found_before and signals[0] == 0 and toast.modulate.a == 0.0,
			"a place found before the travel is not announced again")


## A portal added to the level while it is in place reports the hero too. Side by side with the pad, the offer is for
## the portal entered last, and stepping out of it while still on the pad brings the pad's offer back.
func _check_portals_side_by_side() -> void:
	print("\n== a portal added beside the pad")
	var pad := _get_portal()
	var level := _levels.get_current_level()
	var added := LevelPortal.new()
	added.title = "Lonely Isle"
	added.target_level = ISLAND
	added.collision_layer = 0
	added.collision_mask = 2
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.1
	cylinder.height = 2.0
	shape.shape = cylinder
	shape.position = Vector3(0, 1, 0)
	added.add_child(shape)
	added.position = level.to_local(pad.global_position + Vector3(1.6, 0, 0))
	level.add_child(added)
	# Which portal is offered at each spot: the pad's, the added one's, or none.
	var offers: Array[String] = []
	for spot: Vector3 in [Vector3(-0.6, 0, 0), Vector3(0.8, 0, 0), Vector3(-0.6, 0, 0), Vector3(0, 0, 3.5)]:
		await _teleport(pad.global_position + spot)
		await _ticks(2)
		var offered := _prompt.get_portal()
		offers.append("pad" if offered == pad else "added" if offered == added else "none" if offered == null else "?")
	added.queue_free()
	await _ticks(2)
	print("offered: on the pad, on both, back on the pad, away: %s" % [offers])
	_expect(offers[0] == "pad" and offers[1] == "added", "a portal added later offers too, the one entered last")
	_expect(offers[2] == "pad" and offers[3] == "none",
			"out of the added portal, still on the pad: the pad's offer is back")


## A scene that is not a level (its root is not a Node3D): the change starts and fails behind the screen, with an error
## reported; the level stays, the game runs, the controls and the interface are back, and on the pad the offer returns.
func _check_failed_change() -> void:
	print("\n== a scene that cannot be a level")
	var pad := _get_portal()
	await _teleport(pad.global_position)
	await _ticks(2)
	var level := _levels.get_current_level()
	var failures := []
	var on_failed := func(_path: String, error: Error) -> void: failures.append(error)
	_levels.level_change_failed.connect(on_failed)
	_tree.call(&"expect_error", "could not be loaded")
	var result := _levels.change_level("res://gdscript/ui/travel_prompt.tscn")
	await _wait_for_change()
	await _ticks(2)
	_levels.level_change_failed.disconnect(on_failed)
	var missed: Array = _tree.call(&"take_expected_errors")
	var hud: CanvasLayer = _main.get_node("Hud")
	print(("%s; failed with %s, the error reported %s; the level kept %s, paused %s, controls %s, interface %s, " +
			"screen open %s; the offer %s") % [error_string(result), failures.map(error_string), missed.is_empty(),
			_levels.get_current_level() == level, _tree.paused, _hero.controls_enabled, hud.visible,
			_loading.is_open(), _prompt.get_portal() == pad])
	_expect(result == OK and failures == [ERR_INVALID_DATA] and missed.is_empty(),
			"the change starts and fails with ERR_INVALID_DATA and an error")
	_expect(_levels.get_current_level() == level and not _tree.paused and _hero.controls_enabled and hud.visible
			and not _loading.is_open(), "the level stays; the game runs, the controls and the interface are back")
	_expect(_prompt.visible and _prompt.get_portal() == pad, "the hero still on the pad gets the offer back")
	await _teleport(pad.global_position + Vector3(0, 0, 3.5))


## A portal with auto_travel travels as soon as the hero enters, without an offer. Here there is nothing to wait for:
## no loading screen, no shortest time, no warm-up, and the island scene is loaded already. The change still starts
## after the request, not inside it (the portal asks from a physics callback, where a level must not leave the tree),
## and when it is over, the navigation map has the new level: paths are found there at once. LevelHost.change_level
## goes back the same way.
func _check_auto_travel() -> void:
	print("\n== a portal that travels by itself, with nothing to wait for")
	var screen := _levels.loading_screen
	var shortest := _levels.min_loading_time
	var warmup := _levels.warmup_frames
	_levels.loading_screen = null
	_levels.min_loading_time = 0.0
	_levels.warmup_frames = 0
	var island_scene := load(ISLAND)
	var navigation_ready: Array[bool] = []
	var on_finished := func(level: Node3D) -> void: navigation_ready.append(_has_navigation_of(level))
	_levels.level_change_finished.connect(on_finished)
	var pad := _get_portal()
	pad.auto_travel = true
	await _teleport(pad.global_position)
	await _ticks(2)
	var started := _levels.is_changing()
	var offered := _prompt.visible
	await _wait_for_change()
	var there := _levels.get_current_level().scene_file_path
	var inside := [false]
	var on_started := func(_path: String) -> void: inside[0] = true
	_levels.level_change_started.connect(on_started)
	var back := _levels.change_level(MEADOW, &"from_island", "Green Vale")
	var started_inside: bool = inside[0]
	await _wait_for_change()
	_levels.level_change_started.disconnect(on_started)
	_levels.level_change_finished.disconnect(on_finished)
	var home := _levels.get_current_level().scene_file_path
	_levels.loading_screen = screen
	_levels.min_loading_time = shortest
	_levels.warmup_frames = warmup
	print(("entered: started %s, offered %s; on %s; change_level back: %s, started inside the call %s, on %s; " +
			"the navigation of the new level when the change was over: %s (the island scene held: %s)") % [started,
			offered, there, error_string(back), started_inside, home, navigation_ready, island_scene != null])
	_expect(started and not offered and there == ISLAND, "auto_travel: the portal travels on entering, with no offer")
	_expect(back == OK and not started_inside and home == MEADOW,
			"change_level returns before the change starts, and the change brings the hero back")
	_expect(navigation_ready == [true, true], "when a change is over, paths are found on the new level at once")
	await _teleport(Vector3.ZERO)


## In slow motion (Engine.time_scale 0.05) a change takes no more frames than at full speed: the screen, its bar and
## the waits of the host go by real time. Both scenes are held loaded, so that the load itself takes no frames.
func _check_slow_motion() -> void:
	print("\n== a change in slow motion")
	var scenes := [load(ISLAND), load(MEADOW)]
	var there := _levels.change_level(ISLAND, &"default", "Lonely Isle")
	var at_full_speed: int = (await _wait_for_change()).frames
	Engine.time_scale = 0.05
	var back := _levels.change_level(MEADOW, &"from_island", "Green Vale")
	var slow_change := await _wait_for_change()
	Engine.time_scale = 1.0
	var over := not _levels.is_changing() and not _loading.is_open()
	var home := _levels.get_current_level().scene_file_path
	print("there: %s, %d frames at full speed; back in slow motion: %s, %d frames, over %s, on %s (scenes held %d)" % [
		error_string(there), at_full_speed, error_string(back), slow_change.frames, over, home, scenes.size()])
	_expect(there == OK and back == OK and over and home == MEADOW and slow_change.frames <= at_full_speed * 2 + 30,
			"in slow motion a change takes no longer than at full speed")
	await _teleport(Vector3.ZERO)


## Taking the controls away and giving them back leaves the input nodes processing as they did before.
func _check_controls_given_back() -> void:
	print("\n== the controls given back as they were")
	_input.process_mode = Node.PROCESS_MODE_ALWAYS
	_actions.process_mode = Node.PROCESS_MODE_PAUSABLE
	_hero.controls_enabled = false
	var off := [_input.process_mode, _actions.process_mode]
	_hero.controls_enabled = false
	_hero.controls_enabled = true
	var back := [_input.process_mode, _actions.process_mode]
	_input.process_mode = Node.PROCESS_MODE_INHERIT
	_actions.process_mode = Node.PROCESS_MODE_INHERIT
	print("the input and the actions: off %s, back %s" % [off, back])
	_expect(off == [Node.PROCESS_MODE_DISABLED, Node.PROCESS_MODE_DISABLED]
			and back == [Node.PROCESS_MODE_ALWAYS, Node.PROCESS_MODE_PAUSABLE],
			"off, the input nodes stop; back, they process as they did before, even after a second \"off\"")


## A wrong level file: no such file, or a file that is not a scene. The change does not start, the level stays.
func _check_wrong_level() -> void:
	print("\n== wrong level files")
	var level := _levels.get_current_level()
	var missing := _levels.change_level("res://shared/world/no_such_level.tscn")
	var not_scene := _levels.change_level("res://gdscript/player/player_locomotion.tres")
	await _frames(2)
	print("a missing file: %s; not a scene: %s; changing %s, screen open %s" % [error_string(missing),
			error_string(not_scene), _levels.is_changing(), _loading.is_open()])
	_expect(missing == ERR_FILE_NOT_FOUND and not_scene == ERR_INVALID_PARAMETER,
			"a missing file and a file that is not a scene are refused")
	_expect(not _levels.is_changing() and not _loading.is_open() and _levels.get_current_level() == level,
			"the level stays, and no loading screen comes")


## Waits until a level change starts (input reaches the game a frame or two later), no longer than [param max_frames].
## Returns whether it has started.
func _wait_for_start(max_frames := 10) -> bool:
	for i in max_frames:
		await _tree.process_frame
		if _levels.is_changing():
			return true
	return false


## Waits until the level change is over, no longer than [param max_msec] of real time (without a window the frames run
## much faster than the level loads): how many frames it took, the bar in every frame, whether it only grew and whether
## the game was paused meanwhile.
func _wait_for_change(max_msec := 30000) -> Dictionary:
	var bar := PackedFloat32Array()
	var grew := true
	var paused := false
	var frames := 0
	# The previous value at full precision: the packed array keeps 32-bit floats.
	var previous := 0.0
	var start := Time.get_ticks_msec()
	while _levels.is_changing() and Time.get_ticks_msec() - start < max_msec:
		await _tree.process_frame
		frames += 1
		var shown := _loading.get_shown_progress()
		grew = grew and shown >= previous
		previous = shown
		bar.append(shown)
		paused = paused or _tree.paused
	return {frames = frames, bar = bar, grew = grew, paused = paused}


## The navigation map has [param level]: the point of the map closest to the hero belongs to a region of the level, and
## a path from the hero to 4 m aside is found.
func _has_navigation_of(level: Node3D) -> bool:
	var map := level.get_world_3d().navigation_map
	var from := _player.global_position
	var regions := level.find_children("*", "NavigationRegion3D", true, false).map(
			func(region: Node) -> RID: return (region as NavigationRegion3D).get_rid())
	var owner := NavigationServer3D.map_get_closest_point_owner(map, from)
	var path := NavigationServer3D.map_get_path(map, from, from + Vector3(4, 0, 0), true)
	return owner in regions and path.size() >= 2


## The portal of the current level.
func _get_portal() -> LevelPortal:
	return _levels.get_current_level().find_children("*", "Area3D", true, false).filter(
			func(node: Node) -> bool: return node is LevelPortal).front()


## The place titled [param title] on the current level.
func _find_place(title: String) -> PointOfInterest:
	for node: Node in _tree.get_nodes_in_group(PointOfInterest.GROUP):
		if (node as PointOfInterest).title == title and _levels.get_current_level().is_ancestor_of(node):
			return node
	return null


## The bar at the start, at a quarter, in the middle and at the end of the change.
static func _bar_summary(bar: PackedFloat32Array) -> String:
	if bar.is_empty():
		return "[]"
	var points := PackedStringArray()
	for share: float in [0.0, 0.25, 0.5, 1.0]:
		points.append("%.2f" % bar[mini(int(share * (bar.size() - 1)), bar.size() - 1)])
	return "[%s]" % ", ".join(points)
