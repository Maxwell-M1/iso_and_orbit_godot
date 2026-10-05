class_name LevelHost
extends Node3D
## Holds the current level, the scene of the world: its ground, props, navigation and light. The level changes here
## ([method change_level]), behind a loading screen ([member loading_screen]), while the rest of the game stays: the
## player's character and the interface are siblings of the host, not parts of a level. A child placed in the editor
## is the level the game starts on; the host does not announce it, the game sets it up itself
## ([method get_current_level], [method find_spawn_point]).
##
## A change starts after the request, not inside it (a portal asks from a physics callback, where a level must not
## leave the tree), and goes like this:
## 1. [signal level_change_started]: the game hides what should not be in the picture and takes the controls away.
## 2. The game is paused ([member SceneTree.paused]), unless it already is, and the loading screen covers it.
## 3. The level scene loads in the background ([method ResourceLoader.load_threaded_request]); the screen shows how far.
## 4. The old level is removed and freed, the new one takes its place, and [signal level_loaded] tells the game where to
##    put the character: at the spawn point ([SpawnPoint]) asked for.
## 5. The navigation map takes in the new level ([member navigation_timeout]). Then the pause ends, and behind the
##    screen the first frames are drawn ([member warmup_frames]): shaders compile and the character settles before
##    anyone sees it.
## 6. The screen goes away, and [signal level_change_finished]: the controls come back.
##
## The host ends only the pause it started, and the level changes while the game stands still, even if something let
## the game go on meanwhile. A window that pauses the game (a menu) opens after [signal level_change_finished]: opened
## during the change, it finds the game paused, leaves the pause to the host, and the game goes on behind it. The waits
## of the host go by real time, whatever [member Engine.time_scale] is.
##
## The host connects the portals of the current level ([LevelPortal]), those added to it later too: their request to
## travel changes the level, and their travellers coming and going come out of the host ([signal portal_entered],
## [signal portal_exited]), so the game connects to one node, not to every level. The host knows nothing about the
## player, the camera or the interface: the game connects them to its signals.

## A change of the level to [param path] has started; the old level is still in place.
signal level_change_started(path: String)
## The new [param level] is in place, and the old one is gone. Put the character at [param spawn]: the [SpawnPoint]
## asked for, or the level itself if it has no spawn point. The loading screen still covers the game.
signal level_loaded(level: Node3D, spawn: Node3D)
## The change is over: the loading screen is gone, and [param level] is the current one.
signal level_change_finished(level: Node3D)
## The level at [param path] could not be loaded or is not a [Node3D] scene: the current level stays.
signal level_change_failed(path: String, error: Error)
## A traveller has entered [param portal] of the current level.
signal portal_entered(portal: LevelPortal)
## A traveller has left [param portal] of the current level.
signal portal_exited(portal: LevelPortal)

# How much of the bar each stage fills: the files, the level built, the navigation; the warm-up fills the rest.
const _FILES_SHARE := 0.85
const _BUILT_SHARE := 0.9
const _NAVIGATION_SHARE := 0.95

## The screen over the game while a level loads. Without it the level changes in front of the player.
@export var loading_screen: LoadingScreen

## The loading screen stays at least this long, so that a fast load does not flash it.
@export_range(0.0, 5.0, 0.05, "suffix:s") var min_loading_time := 0.6

## How many frames to draw the new level behind the screen before it goes: the shaders of the new level compile then,
## not in front of the player.
@export_range(0, 30, 1) var warmup_frames := 3

## The longest wait for the navigation map to take in the new level, with the game still paused, by the clock: until
## then a path would be searched on the old map, or on none. The wait ends as soon as every navigation region of the
## new level is in its map. 0: do not wait.
@export_range(0.0, 10.0, 0.1, "suffix:s") var navigation_timeout := 2.0

var _level: Node3D
var _changing := false
# The host has paused the game for the change under way: it ends only its own pause.
var _paused_here := false
# The level file of the change under way, until its background load is collected.
var _loading_path := ""


func _ready() -> void:
	for child in get_children():
		if child is Node3D:
			_level = child
			break
	if _level != null:
		_connect_portals(_level)
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	# Gone in the middle of a change (the game scene changed, for example): the change ends here, and so does the pause
	# of the host. A load that is over is collected; one still going is left to the loader.
	if _changing:
		_changing = false
		_resume()
		_collect(_loading_path)


## The level the game is on now; [code]null[/code] before the first one.
func get_current_level() -> Node3D:
	return _level


## A change is going on: from [signal level_change_started] to [signal level_change_finished] or
## [signal level_change_failed].
func is_changing() -> bool:
	return _changing


## Change the level to the scene at [param path] and arrive at the spawn point [param spawn_name]; [param title] is the
## name of the place for the loading screen. Returns at once: [constant OK] if the change has started (its steps come
## after the call, over the next frames, see the class description), [constant ERR_BUSY] while another change goes on,
## [constant ERR_FILE_NOT_FOUND] if there is no such file, [constant ERR_INVALID_PARAMETER] if it is not a scene. A
## load that fails later keeps the current level and comes as [signal level_change_failed].
func change_level(path: String, spawn_name := &"default", title := "") -> Error:
	if _changing:
		return ERR_BUSY
	var file := _get_file(path)
	if file.is_empty() or not ResourceLoader.exists(file):
		return ERR_FILE_NOT_FOUND
	if file.get_extension().to_lower() not in ResourceLoader.get_recognized_extensions_for_type("PackedScene"):
		return ERR_INVALID_PARAMETER
	var error := ResourceLoader.load_threaded_request(file)
	if error != OK:
		return error
	_changing = true
	_loading_path = file
	_change.call_deferred(file, spawn_name, title)
	return OK


## The spawn point named [param spawn_name] on [param level] (the current one if not given), or the "default" one if
## there is none by that name; [code]null[/code] if there is neither.
func find_spawn_point(spawn_name := &"default", level: Node3D = null) -> SpawnPoint:
	if level == null:
		level = _level
	if level == null:
		return null
	var fallback: SpawnPoint = null
	for node in get_tree().get_nodes_in_group(SpawnPoint.GROUP):
		var point := node as SpawnPoint
		if point == null or not level.is_ancestor_of(point):
			continue
		if point.spawn_name == spawn_name:
			return point
		if point.spawn_name == &"default":
			fallback = point
	return fallback


func _change(path: String, spawn_name: StringName, title: String) -> void:
	# By real time, which goes on while the game is paused or slowed down.
	var shown_long_enough := get_tree().create_timer(min_loading_time, true, false, true)
	level_change_started.emit(path)
	_pause()
	_set_progress(0.0)
	if loading_screen != null:
		await loading_screen.open(title)

	var progress := [0.0]
	var status := ResourceLoader.load_threaded_get_status(path, progress)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_set_progress(progress[0] * _FILES_SHARE)
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(path, progress)
	var level := _build(path, status)
	if level == null:
		var error := ERR_CANT_OPEN if status != ResourceLoader.THREAD_LOAD_LOADED else ERR_INVALID_DATA
		push_error("LevelHost: the level \"%s\" could not be loaded (%s)." % [path, error_string(error)])
		_resume()
		if loading_screen != null:
			await loading_screen.close()
		_changing = false
		level_change_failed.emit(path, error)
		return
	_set_progress(_BUILT_SHARE)

	# Paused again if something let the game go on meanwhile (a window closed): the level changes while it stands still.
	_pause()
	var had_navigation := _level != null and _has_navigation(_level)
	_swap(level)
	var spawn: Node3D = find_spawn_point(spawn_name, level)
	if spawn == null or (spawn as SpawnPoint).spawn_name != spawn_name:
		push_warning("LevelHost: \"%s\" has no spawn point \"%s\"; the character arrives at %s." % [path, spawn_name,
				"\"default\"" if spawn != null else "the origin of the level"])
		if spawn == null:
			spawn = level
	level_loaded.emit(level, spawn)
	# The navigation server goes on while the game is paused: the game goes on with the new map in place.
	if had_navigation or _has_navigation(level):
		await _wait_for_navigation(level)
	_set_progress(_NAVIGATION_SHARE)
	_resume()

	for i in warmup_frames:
		await get_tree().process_frame
	if shown_long_enough.time_left > 0.0:
		await shown_long_enough.timeout
	_set_progress(1.0)
	if loading_screen != null:
		await loading_screen.close()
	_changing = false
	level_change_finished.emit(level)


## The loaded level scene, built: its root, if it is a [Node3D]; otherwise [code]null[/code].
func _build(path: String, status: ResourceLoader.ThreadLoadStatus) -> Node3D:
	# Collected even when the load has failed: until then the loader keeps the failure, and the next request of the
	# file would fail too, even after the file is mended.
	var scene := _collect(path) as PackedScene
	if status != ResourceLoader.THREAD_LOAD_LOADED or scene == null:
		return null
	var root := scene.instantiate()
	if root != null and not root is Node3D:
		root.free()
		return null
	return root as Node3D


## Takes the result of the background load of [param path] from the loader, if the load is over: the resource, or
## [code]null[/code] if the load has failed. A load still going is left alone.
func _collect(path: String) -> Resource:
	if path.is_empty():
		return null
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		return null
	_loading_path = ""
	return ResourceLoader.load_threaded_get(path)


## The old level leaves (it is freed at the end of the frame), the new one takes its place.
func _swap(level: Node3D) -> void:
	if _level != null:
		# Its portals report the traveller leaving as the level goes: that is not the traveller walking away.
		_disconnect_portals(_level)
		remove_child(_level)
		_level.queue_free()
	_level = level
	add_child(level)
	_connect_portals(level)


## Pauses the game for the change, unless it is paused already.
func _pause() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		_paused_here = true


## Ends the pause the host has started.
func _resume() -> void:
	if _paused_here:
		_paused_here = false
		get_tree().paused = false


## Waits until the navigation map of this world has taken in the change of [param level], but not longer than
## [member navigation_timeout]: the map has changed since the old level left, and every region of the new level is in
## its map.
func _wait_for_navigation(level: Node3D) -> void:
	if navigation_timeout <= 0.0:
		return
	var map := get_world_3d().navigation_map
	var changed := [false]
	var on_changed := func(changed_map: RID) -> void: changed[0] = changed[0] or changed_map == map
	NavigationServer3D.map_changed.connect(on_changed)
	var regions := _get_regions(level)
	# By the clock: the navigation server builds the map in threads of its own, whatever the pace of the frames.
	var deadline := Time.get_ticks_msec() + roundi(navigation_timeout * 1000.0)
	while Time.get_ticks_msec() < deadline and not (changed[0] and _are_in_maps(regions)):
		await get_tree().process_frame
	NavigationServer3D.map_changed.disconnect(on_changed)


func _set_progress(value: float) -> void:
	if loading_screen != null:
		loading_screen.set_progress(value)


func _connect_portals(level: Node3D) -> void:
	for portal in _get_portals(level):
		_connect_portal(portal)


func _connect_portal(portal: LevelPortal) -> void:
	# A portal that leaves the level and comes back is connected already.
	if portal.travel_requested.is_connected(_on_travel_requested):
		return
	portal.travel_requested.connect(_on_travel_requested)
	portal.traveller_entered.connect(_on_traveller_entered.bind(portal))
	portal.traveller_exited.connect(_on_traveller_exited.bind(portal))


func _disconnect_portals(level: Node3D) -> void:
	for portal in _get_portals(level):
		for portal_signal: Signal in [portal.travel_requested, portal.traveller_entered, portal.traveller_exited]:
			for connection: Dictionary in portal_signal.get_connections():
				var callable: Callable = connection.callable
				if callable.get_object() == self:
					portal_signal.disconnect(callable)


func _get_portals(level: Node3D) -> Array[LevelPortal]:
	var portals: Array[LevelPortal] = []
	for node in get_tree().get_nodes_in_group(LevelPortal.GROUP):
		if level.is_ancestor_of(node):
			portals.append(node as LevelPortal)
	return portals


func _on_node_added(node: Node) -> void:
	# A portal put into the level while it is in place: one that opens after a quest, for example.
	if node is LevelPortal and _level != null and _level.is_ancestor_of(node):
		_connect_portal(node)


func _on_travel_requested(portal: LevelPortal) -> void:
	var error := change_level(portal.target_level, portal.target_spawn, portal.title)
	if error != OK and error != ERR_BUSY:
		push_error("LevelHost: the portal \"%s\" leads to \"%s\": %s." % [portal.name, portal.target_level,
				error_string(error)])


func _on_traveller_entered(_body: Node3D, portal: LevelPortal) -> void:
	portal_entered.emit(portal)


func _on_traveller_exited(_body: Node3D, portal: LevelPortal) -> void:
	portal_exited.emit(portal)


static func _has_navigation(level: Node3D) -> bool:
	return not level.find_children("*", "NavigationRegion3D", true, false).is_empty()


## The navigation regions of [param level] that take part in navigation: on, with a navigation mesh that has polygons.
static func _get_regions(level: Node3D) -> Array[NavigationRegion3D]:
	var regions: Array[NavigationRegion3D] = []
	for node in level.find_children("*", "NavigationRegion3D", true, false):
		var region := node as NavigationRegion3D
		if region.enabled and region.navigation_layers != 0 and region.navigation_mesh != null \
				and region.navigation_mesh.get_polygon_count() > 0:
			regions.append(region)
	return regions


## Every one of [param regions] is in its navigation map: the map's closest point to a point of the region belongs to
## one of them. Before that the map holds what it had before the change, or nothing.
static func _are_in_maps(regions: Array[NavigationRegion3D]) -> bool:
	var ids: Array[RID] = []
	for region in regions:
		ids.append(region.get_rid())
	for region in regions:
		var id := region.get_rid()
		if NavigationServer3D.region_get_iteration_id(id) == 0:
			return false
		var point := NavigationServer3D.region_get_random_point(id, region.navigation_layers, false)
		if NavigationServer3D.map_get_closest_point_owner(region.get_navigation_map(), point) not in ids:
			return false
	return true


## The file of [param path]: a "uid://" path (so the inspector keeps a picked file) becomes the file path; empty if
## there is no such resource.
static func _get_file(path: String) -> String:
	if not path.begins_with("uid://"):
		return path
	var id := ResourceUID.text_to_id(path)
	return ResourceUID.get_id_path(id) if ResourceUID.has_id(id) else ""
