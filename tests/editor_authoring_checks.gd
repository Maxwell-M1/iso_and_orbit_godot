extends "res://tests/check_suite.gd"
## Regression checks for authored settings, scene contracts, the start level and whole props.

const PROP := preload("res://shared/world/props/stone_pillar.tscn")


func _checks() -> Array[Callable]:
	return [_check_contracts, _check_initial_level, _check_settings_path, _check_scene_settings,
		_check_follow_exception, _check_settings_sharing, _check_prop_editing, _check_prop_additions,
		_check_animated_prop]


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


func _check_settings_sharing() -> void:
	print("\n== movers share their settings resource and take a new one at once")
	var preset := LocomotionSettings.new()
	var holder := Node3D.new()
	var movers: Array[NavigationMover] = []
	for i in 2:
		var body := Node3D.new()
		var mover := NavigationMover.new()
		mover.settings = preset
		mover.use_navigation = false
		body.add_child(mover)
		holder.add_child(body)
		movers.append(mover)
	_tree.root.add_child(holder)
	_expect(movers[0].settings == preset and movers[1].settings == preset,
		"in the game a mover uses the resource assigned to it, not a copy")
	preset.max_speed = 2.0
	for mover: NavigationMover in movers:
		mover.steer(Vector3.RIGHT)
	for i in 120:
		for mover: NavigationMover in movers:
			mover.compute_velocity(DT)
	var limited := true
	for mover: NavigationMover in movers:
		limited = limited and mover.get_speed() > 1.9 and mover.get_speed() <= 2.001
	_expect(limited, "a change of a shared resource during play reaches every mover that uses it")
	var replacement := LocomotionSettings.new()
	replacement.max_speed = 1.25
	movers[0].settings = replacement
	for i in 120:
		movers[0].compute_velocity(DT)
	_expect(movers[0].get_speed() > 1.2 and movers[0].get_speed() <= 1.251 and movers[1].settings == preset,
		"a resource assigned during play takes effect at once, for that mover only")
	movers[1].settings = null
	_expect(movers[1].settings != null and movers[1].settings.max_speed == LocomotionSettings.new().max_speed,
		"no resource assigned during play: the mover runs on the default settings")
	holder.free()


func _check_prop_editing() -> void:
	print("\n== a prop's root moves and resizes both the model and collision")
	var prop := PROP.instantiate() as StaticProp
	var other := PROP.instantiate() as StaticProp
	_tree.root.add_child(prop)
	_tree.root.add_child(other)
	var mesh := prop.get_node("MeshInstance3D") as MeshInstance3D
	var shape := prop.get_node("CollisionShape3D") as CollisionShape3D
	var before_mesh := mesh.global_position
	var before_shape := shape.global_position
	prop.position += Vector3(2, 1, 3)
	_expect((mesh.global_position - before_mesh).is_equal_approx(Vector3(2, 1, 3))
		and (shape.global_position - before_shape).is_equal_approx(Vector3(2, 1, 3)),
		"moving the root moves its visible geometry and physical geometry together")
	_expect(other.dimensions == Vector3.ZERO and is_equal_approx(other.get_node("CollisionShape3D").shape.height, 3.2),
		"a prop of the size of its parts keeps Dimensions at 0: nothing computed is written into it")
	prop.dimensions = Vector3(0, 4.2, 0)
	var mesh_height: float = mesh.mesh.height * mesh.basis.y.length()
	_expect(is_equal_approx(mesh_height, 4.2) and is_equal_approx(shape.shape.height, 4.2)
		and is_equal_approx(shape.shape.radius, 0.5) and is_equal_approx(mesh.basis.x.length(), 1.0),
		"Dimensions changes the visible pillar height and collider height together, 0 keeps the width of the parts")
	_expect(is_equal_approx(other.get_node("CollisionShape3D").shape.height, 3.2),
		"resizing an instance does not change a sibling's shape")
	var material := StandardMaterial3D.new()
	prop.surface_material = material
	prop.surface_material = null
	_expect(mesh.material_override == null, "clearing the surface override restores authored materials")
	_expect(prop._get_configuration_warnings().is_empty(), "a prop resized by Dimensions has no warning")
	prop.scale = Vector3.ONE * 2.0
	_expect("scale of its root" in " ".join(prop._get_configuration_warnings()), "a scaled root asks for Dimensions")
	prop.free()
	other.free()
	var capsule := CapsuleShape3D.new()
	var resized := StaticProp._resized_shape(capsule, Basis.IDENTITY.scaled(Vector3(1, 2, 1)))
	_expect(resized is ConvexPolygonShape3D,
		"non-uniform capsule resizing preserves stretched round ends in a convex shape")
	var rotation := Basis(Vector3.FORWARD, PI / 4.0)
	var box := StaticProp._resized_shape(BoxShape3D.new(),
		rotation.inverse() * Basis.IDENTITY.scaled(Vector3(1, 2, 1)) * rotation)
	_expect(box is ConvexPolygonShape3D, "a rotated box bakes its shear into collision geometry")
	# A figure: a capsule and a whole character model, a scene of many parts.
	var model_prop := StaticProp.new()
	var capsule_shape := CollisionShape3D.new()
	capsule_shape.shape = CapsuleShape3D.new()
	capsule_shape.position.y = 1.0
	model_prop.add_child(capsule_shape)
	var model := (load("res://shared/characters/models/mage.tscn") as PackedScene).instantiate() as Node3D
	model_prop.add_child(model)
	_tree.root.add_child(model_prop)
	var model_scale := model.global_basis.y.length()
	model_prop.dimensions.y = model_prop.get_natural_size().y * 2.0
	_expect(is_equal_approx(model.global_basis.y.length(), model_scale * 2.0),
		"resizing a compound model scales its whole authored branch")
	model_prop.free()


func _check_prop_additions() -> void:
	print("\n== newly authored parts participate in whole-object resizing")
	var prop := PROP.instantiate() as StaticProp
	_tree.root.add_child(prop)
	var added_mesh := MeshInstance3D.new()
	added_mesh.mesh = CylinderMesh.new()
	added_mesh.position.x = 4.0
	prop.add_child(added_mesh)
	var added_shape := CollisionShape3D.new()
	added_shape.shape = CylinderShape3D.new()
	added_shape.position.x = 4.0
	prop.add_child(added_shape)
	prop.dimensions = prop.get_natural_size() * 2.0
	var original := prop.get_node("MeshInstance3D") as MeshInstance3D
	_expect(original.scale.is_equal_approx(added_mesh.scale), "old and newly added visuals use the same resize ratio")
	_expect(is_equal_approx(added_shape.shape.get_debug_mesh().get_aabb().size.y,
			added_mesh.mesh.height * added_mesh.scale.y),
		"a newly added collider matches its resized visual")
	var material := StandardMaterial3D.new()
	prop.surface_material = material
	_expect(added_mesh.material_override == material, "Surface Material reaches newly added meshes")
	prop.free()


func _check_animated_prop() -> void:
	print("\n== a resized mountain preserves the crystal's animation rest pose")
	var mountain := (load("res://shared/world/mountain/mountain.tscn") as PackedScene).instantiate() as StaticProp
	mountain.dimensions.y = mountain.get_natural_size().y * 2.0
	_tree.root.add_child(mountain)
	var crystal := mountain.get_node("Shrine/CrystalAnchor/Crystal") as MeshInstance3D
	var before := crystal.global_position
	crystal._process(0.0)
	_expect(crystal.global_position.is_equal_approx(before) and is_equal_approx(before.y, 23.5),
		"the first animation frame keeps the preview's resized crystal height")
	await _frames(10)
	_expect(absf(crystal.global_position.y - before.y) <= 0.241,
		"subsequent animation frames bob around the resized rest pose")
	mountain.free()
