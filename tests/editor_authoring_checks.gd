extends "res://tests/check_suite.gd"
## Regression checks for authored settings, scene contracts and the start level.


func _checks() -> Array[Callable]:
	return [_check_contracts, _check_initial_level, _check_settings_path, _check_scene_settings,
		_check_follow_exception]


func _check_contracts() -> void:
	print("\n== missing scene requirements produce configuration warnings")
	var mover := NavigationMover.new()
	_expect(not mover._get_configuration_warnings().is_empty(), "an orphan mover warns about its required parent")
	var body := Node3D.new()
	body.add_child(mover)
	_expect(mover._get_configuration_warnings().is_empty(), "a valid mover hierarchy clears the warning")
	body.free()


func _check_initial_level() -> void:
	print("\n== the start level: Initial Level, or else the first 3D child")
	var host := LevelHost.new()
	var marker := Marker3D.new()
	var level := Node3D.new()
	host.add_child(marker)
	host.add_child(level)
	host.initial_level = level
	_tree.root.add_child(host)
	_expect(host.get_current_level() == level, "a helper placed before the level cannot become the initial level")
	host.free()
	host = LevelHost.new()
	level = Node3D.new()
	host.add_child(level)
	_tree.root.add_child(host)
	_expect(host.get_current_level() == level, "without Initial Level the host's only 3D child is the start level")
	host.free()
	host = LevelHost.new()
	level = Node3D.new()
	host.add_child(level)
	_expect(host._get_configuration_warnings().is_empty(), "a host with one 3D child needs no Initial Level")
	host.add_child(Marker3D.new())
	_expect(not host._get_configuration_warnings().is_empty(),
		"with several 3D children the host asks for Initial Level")
	host.initial_level = level
	_expect(host._get_configuration_warnings().is_empty(), "assigning the direct child clears the warning")
	host.free()


func _check_settings_path() -> void:
	print("\n== exported settings path is applied before the file is read")
	var config := ConfigFile.new()
	config.set_value("character", "jump_height", 1.75)
	var fixture := "res://.godot/editor_authoring_settings.cfg"
	_expect(config.save(fixture) == OK, "the isolated settings fixture is writable")
	var settings := GameSettings.new()
	settings.path = fixture
	var packed := PackedScene.new()
	packed.pack(settings)
	var restored := packed.instantiate() as GameSettings
	restored.persistent = false
	_expect(restored.get_value(GameSettings.JUMP_HEIGHT) == 1.75,
		"a deserialized settings node reads its exported path, without reading user preferences first")
	restored.set_scene_defaults({GameSettings.JUMP_HEIGHT: 2.0})
	_expect(restored.get_value(GameSettings.JUMP_HEIGHT) == 1.75,
		"stored preferences take precedence over authored defaults")
	settings.persistent = false
	settings.free()
	restored.free()
	DirAccess.remove_absolute(fixture)


func _check_scene_settings() -> void:
	print("\n== scene-only settings keep authored gameplay values")
	var hero := (load("res://gdscript/player/playable_hero.tscn") as PackedScene).instantiate() as PlayableHero
	hero.character.jump_height = 1.7
	_tree.root.add_child(hero)
	var applier: Node = load("res://gdscript/demo/settings_applier.gd").new()
	applier.hero = hero
	applier.use_saved_settings = false
	_tree.root.add_child(applier)
	var settings: GameSettings = _tree.root.get_node("Settings")
	var previous: float = settings.get_value(GameSettings.JUMP_HEIGHT)
	settings.set_value(GameSettings.JUMP_HEIGHT, 2.0)
	_expect(is_equal_approx(hero.character.jump_height, 1.7),
		"Use Saved Settings off preserves scene values even when user preferences change")
	var captured: Dictionary = applier._capture_scene_defaults()
	_expect(is_equal_approx(captured[GameSettings.JUMP_HEIGHT], 1.7), "authored values supply effective defaults")
	settings.set_value(GameSettings.JUMP_HEIGHT, previous)
	applier.free()
	hero.free()


func _check_follow_exception() -> void:
	print("\n== enabling the camera exception agrees with the displayed angle")
	var settings: GameSettings = _tree.root.get_node("Settings")
	var keys := [GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD, GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD_ANGLE]
	var previous := {}
	for key: StringName in keys:
		previous[key] = settings.get_value(key)
	var hero := (load("res://gdscript/player/playable_hero.tscn") as PackedScene).instantiate() as PlayableHero
	hero.camera_rig.follow_movement = true
	hero.camera_rig.follow_toward_camera_angle = 0.0
	_tree.root.add_child(hero)
	var applier: Node = load("res://gdscript/demo/settings_applier.gd").new()
	applier.hero = hero
	applier.use_saved_settings = false
	_tree.root.add_child(applier)
	var defaults: Dictionary = applier._capture_scene_defaults()
	_expect(not defaults[keys[0]] and defaults[keys[1]] >= 5.0, "an authored disabled mode retains a usable angle")
	settings.set_value(keys[0], false)
	settings.set_value(keys[1], 0.0)
	var slider: Variant = load("res://gdscript/ui/settings/setting_slider.gd").new()
	slider.key = keys[1]
	slider.min_value = 5.0
	slider.max_value = 60.0
	_tree.root.add_child(slider)
	applier.use_saved_settings = true
	settings.changed.connect(applier._apply)
	settings.set_value(keys[0], true)
	_expect(slider.value >= 5.0
		and is_equal_approx(slider.value, rad_to_deg(hero.camera_rig.follow_toward_camera_angle))
		and is_equal_approx(slider.value, settings.get_value(keys[1])),
		"enabling also repairs a saved zero angle and synchronizes Settings, UI and the rig")
	slider.free()
	applier.free()
	hero.free()
	for key: StringName in keys:
		settings.set_value(key, previous[key])
