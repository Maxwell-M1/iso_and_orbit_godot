extends Node3D
## The demo game: puts the levels ([LevelHost]), the hero ([PlayableHero]) and the interface together. The hero starts
## at the spawn point of the start level; on a teleport pad an offer to travel comes up ([TravelPrompt]), and the
## loading screen covers the change of the level. The places found are remembered for the session: a level loaded again
## does not announce them anew.

@export var levels: LevelHost
@export var hero: PlayableHero
## The interface over the game: hidden while the level changes, so that the loading screen takes the frame without it.
@export var hud: CanvasLayer
@export var travel_prompt: TravelPrompt

# The places found in this session: the scene file of the level and the path of the place in it.
var _found_places := {}
# The portals that ask first and that the hero stands in, the last one entered at the end: its offer is shown.
var _portals_here: Array[LevelPortal] = []


func _ready() -> void:
	levels.portal_entered.connect(_on_portal_entered)
	levels.portal_exited.connect(_on_portal_exited)
	levels.level_change_started.connect(_on_level_change_started)
	levels.level_loaded.connect(_on_level_loaded)
	levels.level_change_finished.connect(_on_level_change_finished)
	levels.level_change_failed.connect(_on_level_change_failed)
	travel_prompt.confirmed.connect(_on_travel_confirmed)
	if levels.loading_screen != null:
		# The tips name the keys bound now.
		levels.loading_screen.tip_format = InputNames.format
		levels.loading_screen.add_to_group(ActionTexts.GROUP)
	var level := levels.get_current_level()
	if level == null:
		return
	_watch_places(level)
	var spawn := levels.find_spawn_point(&"default", level)
	if spawn != null:
		# At the start the camera keeps the angle it is set up with (OrbitCameraRig.start_yaw).
		hero.place_at(spawn, false)


func _on_portal_entered(portal: LevelPortal) -> void:
	if portal.auto_travel:
		return
	_portals_here.erase(portal)
	_portals_here.append(portal)
	travel_prompt.show_for(portal)


func _on_portal_exited(portal: LevelPortal) -> void:
	_portals_here.erase(portal)
	travel_prompt.hide_for(portal)
	# Out of one of two portals side by side: the offer of the other one stays.
	_offer_portal_here()


func _on_travel_confirmed(portal: LevelPortal) -> void:
	portal.travel()


func _on_level_change_started(_path: String) -> void:
	travel_prompt.dismiss()
	hud.visible = false
	hero.controls_enabled = false


func _on_level_loaded(level: Node3D, spawn: Node3D) -> void:
	# The portals of the old level are gone; those of the new one report the hero if it arrives in one.
	_portals_here.clear()
	_watch_places(level)
	hero.place_at(spawn)
	hud.visible = true


func _on_level_change_finished(_level: Node3D) -> void:
	hero.controls_enabled = true


func _on_level_change_failed(_path: String, _error: Error) -> void:
	hud.visible = true
	hero.controls_enabled = true
	# The hero still stands at the portal: the offer comes back.
	_offer_portal_here()


## Offer the portal the hero stands in, if the offer is not up yet.
func _offer_portal_here() -> void:
	if travel_prompt.get_portal() == null and not _portals_here.is_empty():
		travel_prompt.show_for(_portals_here.back())


## The places of [param level] found before count as found; the others are remembered when they are found.
func _watch_places(level: Node3D) -> void:
	for node in get_tree().get_nodes_in_group(PointOfInterest.GROUP):
		var place := node as PointOfInterest
		if not level.is_ancestor_of(place):
			continue
		var key := "%s:%s" % [level.scene_file_path, level.get_path_to(place)]
		if _found_places.has(key):
			place.mark_discovered()
		else:
			place.discovered.connect(_on_place_discovered.bind(key), CONNECT_ONE_SHOT)


func _on_place_discovered(_title: String, key: String) -> void:
	_found_places[key] = true
