@tool
extends Node3D
## Checks of the tool code in the editor itself: its callbacks, the warnings and what the scenes are saved with. Open
## editor_tool_checks.tscn and press Run Checks in the Inspector; the results show there, in the output and in
## .godot/editor_tool_checks/results.json. The fixtures go only into that folder, which every run clears: no scene of
## the project and no player preference is written.

const PILLAR := preload("res://shared/world/props/stone_pillar.tscn")
const KNIGHT := preload("res://gdscript/npc/knight_patrol.tscn")
const PAD := preload("res://shared/world/props/teleport_pad.tscn")
const OUT := "res://.godot/editor_tool_checks/"

## Run all the checks. Only in the editor.
@export_tool_button("Run Checks", "Play") var run_checks := _run
## How the last run went: not run, running, passed or failed. Shown in the Inspector, never saved.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var status := "not run"
## One line per check of the last run. Shown in the Inspector, never saved.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var results := PackedStringArray()

var _warning_updates := {}


func _expect(value: bool, description: String) -> void:
	results.append(("PASS: " if value else "FAIL: ") + description)


func _run() -> void:
	if not Engine.is_editor_hint() or status == "running":
		return
	status = "running"
	results = PackedStringArray()
	_clear(OUT)
	DirAccess.make_dir_recursive_absolute(OUT)
	await _check_dependent_warning()
	await _check_fall_resource_updates()
	await _check_child_warnings()
	_check_input_warnings()
	_check_portal_sign()
	await _check_hover_switch()
	await _check_camera_save()
	await _check_arm_without_tool()
	await _check_saved_source()
	await _check_inheritance()
	await _check_live_authoring()
	await _check_patrol_body_warning()
	_check_patrol_actor_preview()
	_check_copied_actor()
	await _check_patrol_switch()
	var failed := Array(results).any(func(result: String) -> bool: return result.begins_with("FAIL"))
	status = "failed" if failed else "passed"
	var file := FileAccess.open(OUT + "results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": status, "results": results}, "\t"))
	print("EDITOR_TOOL_CHECKS: ", status, " ", results.size(), " checks")


## Deletes what an earlier run left in [param dir].
func _clear(dir: String) -> void:
	for file: String in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + file)
	for sub: String in DirAccess.get_directories_at(dir):
		_clear(dir + sub + "/")
		DirAccess.remove_absolute(dir + sub)


func _save(node: Node, path: String) -> void:
	# The editor sends these notifications around packing and saving a scene (Godot 4.7.2, EditorNode::_save_scene).
	node.propagate_notification(NOTIFICATION_EDITOR_PRE_SAVE)
	var packed := PackedScene.new()
	_expect(packed.pack(node) == OK and ResourceSaver.save(packed, path) == OK, "save the isolated fixture")
	node.propagate_notification(NOTIFICATION_EDITOR_POST_SAVE)


func _load_prop(path: String) -> StaticProp:
	var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
	var prop := packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as StaticProp
	add_child(prop)
	return prop


func _load(path: String) -> Node:
	var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
	return packed.instantiate()


func _warned(node: Node) -> void:
	_warning_updates[node] = int(_warning_updates.get(node, 0)) + 1


func _warnings_text(node: Node) -> String:
	return " ".join(node._get_configuration_warnings())


func _check_dependent_warning() -> void:
	get_tree().node_configuration_warning_changed.connect(_warned)
	var character := GroundCharacter.new()
	var mover := NavigationMover.new()
	var guard := LedgeGuard.new()
	character.mover = mover
	character.ledge_guard = guard
	character.max_step_height = 0.3
	character.add_child(mover)
	character.add_child(guard)
	add_child(character)
	_warning_updates.clear()
	guard.max_drop = 0.05
	_expect(_warning_updates.get(character, 0) > 0 and "lower than max_step_height" in _warnings_text(character),
		"editing a dependent node publishes the new character warning")
	_warning_updates.clear()
	guard.max_drop = 0.5
	_expect(_warning_updates.get(character, 0) > 0 and not "lower than max_step_height" in _warnings_text(character),
		"fixing the dependent value clears the warning immediately")
	var replacement := LedgeGuard.new()
	character.add_child(replacement)
	character.ledge_guard = replacement
	_warning_updates.clear()
	guard.max_drop = 0.05
	_expect(_warning_updates.get(character, 0) == 0, "replacing the dependency disconnects the old node")
	replacement.max_drop = 0.05
	_expect(_warning_updates.get(character, 0) > 0, "the replacement node refreshes the owner warning")
	character.free()
	# The same connection when the character comes from a scene file: the guard is assigned while the scene loads.
	var hero := (load("res://gdscript/player/player.tscn") as PackedScene).instantiate(
		PackedScene.GEN_EDIT_STATE_MAIN) as GroundCharacter
	add_child(hero)
	_warning_updates.clear()
	hero.ledge_guard.max_drop = 0.05
	_expect(_warning_updates.get(hero, 0) > 0, "a character loaded from its scene listens to its ledge guard")
	hero.free()
	get_tree().node_configuration_warning_changed.disconnect(_warned)


func _check_fall_resource_updates() -> void:
	get_tree().node_configuration_warning_changed.connect(_warned)
	var character := GroundCharacter.new()
	var mover := NavigationMover.new()
	character.mover = mover
	character.add_child(mover)
	var previous := FallSettings.new()
	character.fall = previous
	add_child(character)
	_warning_updates.clear()
	previous.max_speed = 1.0
	_expect(_warning_updates.get(character, 0) > 0 and "lower than landing_min_speed" in _warnings_text(character),
		"the fall resource refreshes the dependent warning")
	var replacement := FallSettings.new()
	character.fall = replacement
	_warning_updates.clear()
	previous.max_speed = 0.5
	_expect(_warning_updates.get(character, 0) == 0, "replacing FallSettings disconnects the old resource")
	replacement.max_speed = 0.5
	_expect(_warning_updates.get(character, 0) > 0, "the replacement fall resource remains observable")
	character.free()
	get_tree().node_configuration_warning_changed.disconnect(_warned)


## The Scene dock rechecks a node whose own children change: the arm's warning about its camera needs no connection.
func _check_child_warnings() -> void:
	get_tree().node_configuration_warning_changed.connect(_warned)
	var arm := CameraArm.new()
	add_child(arm)
	await get_tree().process_frame
	_warning_updates.clear()
	var unrelated := Node.new()
	get_tree().root.add_child(unrelated)
	await get_tree().process_frame
	_expect(_warning_updates.get(arm, 0) == 0, "unrelated editor tree changes do not refresh component warnings")
	unrelated.free()
	var view := Camera3D.new()
	arm.add_child(view)
	_expect(arm._get_configuration_warnings().is_empty(), "a camera child satisfies the arm's warning")
	arm.remove_child(view)
	_expect(not arm._get_configuration_warnings().is_empty(), "without the child the warning is back")
	view.free()
	arm.free()
	get_tree().node_configuration_warning_changed.disconnect(_warned)


## In the editor the input map holds only the editor's own actions: the warnings read the project's actions.
func _check_input_warnings() -> void:
	var input := PointClickMoveInput.new()
	add_child(input)
	_expect(not "Add input action" in _warnings_text(input),
		"the project's input actions count as present in the editor")
	input.move_forward_action = &"no_such_action"
	_expect("no_such_action" in _warnings_text(input), "a missing input action is reported")
	input.free()
	var ui := UiRoot.new()
	ui.settings_action = &"no_such_action"
	add_child(ui)
	_expect(_warnings_text(ui).is_empty(), "without a settings window its action is not checked")
	ui.settings_screen = PAD
	_expect("no_such_action" in _warnings_text(ui), "with a settings window its missing action is reported")
	ui.free()


## The portal's sign shows its title in the editor: the title is a preview, and the scene keeps the sign's own text.
func _check_portal_sign() -> void:
	var pad := PAD.instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as LevelPortal
	pad.title = "Nowhere"
	add_child(pad)
	_expect(pad.title_label.text == "Nowhere", "the portal's sign shows the title in the editor")
	_save(pad, OUT + "pad.tscn")
	var text := FileAccess.get_file_as_string(OUT + "pad.tscn")
	_expect(text.contains('title = "Nowhere"') and not text.contains('text = "Nowhere"'),
		"the scene keeps the title and not a copy of it in the sign")
	pad.free()


## Switches whose reaction belongs to the game: in the editor they change only their own value.
func _check_hover_switch() -> void:
	var character := GroundCharacter.new()
	var mover := NavigationMover.new()
	var visual := Node3D.new()
	character.mover = mover
	character.visual = visual
	character.add_child(mover)
	character.add_child(visual)
	var hover := CharacterHover.new()
	hover.character = character
	hover.transform = Transform3D(Basis(Vector3.UP, 0.5), Vector3(0.1, 0.2, 0.3))
	visual.add_child(hover)
	add_child(character)
	await get_tree().process_frame
	var placed := hover.transform
	hover.enabled = false
	hover.enabled = true
	_expect(hover.transform.is_equal_approx(placed),
		"turning floating off and on in the editor leaves the model as set")
	character.free()


func _check_camera_save() -> void:
	var fixture := Node3D.new()
	fixture.name = "CameraFixture"
	var target := Node3D.new()
	target.name = "Target"
	target.position = Vector3(5, 2, -3)
	fixture.add_child(target)
	target.owner = fixture
	var rig := OrbitCameraRig.new()
	rig.name = "Rig"
	var authored_rig := Transform3D(Basis.from_euler(Vector3(0.1, 0.2, 0.3)), Vector3(-3, 1, 6))
	rig.transform = authored_rig
	rig.target = target
	rig.near_distance = 4.0
	rig.far_distance = 20.0
	rig.start_zoom = 0.5
	fixture.add_child(rig)
	rig.owner = fixture
	var arm := CameraArm.new()
	arm.name = "Arm"
	arm.length = 7.0
	rig.add_child(arm)
	arm.owner = fixture
	rig.arm = arm
	var view := Camera3D.new()
	view.name = "View"
	var authored_view := Transform3D(Basis.from_euler(Vector3(0.2, 0.3, 0.1)), Vector3(1, 2, 3))
	view.transform = authored_view
	arm.add_child(view)
	view.owner = fixture
	add_child(fixture)
	await get_tree().process_frame
	await get_tree().process_frame
	var start := Vector3(0, 0, 12)
	_expect(rig.global_position.is_equal_approx(target.global_position + Vector3.UP * rig.focus_height)
		and view.position.is_equal_approx(start),
		"the preview frames the target at the start distance of the game")
	_expect(is_equal_approx(arm.length, 7.0), "the preview leaves the arm's own length as set")
	var path := OUT + "camera.tscn"
	_save(fixture, path)
	var saved := _load(path)
	_expect((saved.get_node("Rig") as Node3D).transform.is_equal_approx(authored_rig),
		"saving keeps the rig's transform as it was loaded")
	_expect(is_equal_approx((saved.get_node("Rig/Arm") as CameraArm).length, 7.0), "saving keeps the arm length")
	_expect((saved.get_node("Rig/Arm/View") as Node3D).transform.is_equal_approx(authored_view),
		"saving keeps the camera's transform as it was loaded")
	_expect(not rig.transform.is_equal_approx(authored_rig) and view.position.is_equal_approx(start),
		"after saving the preview is back at once")
	saved.free()
	view.transform = Transform3D(Basis.from_euler(Vector3(0.4, 0.1, 0.2)), Vector3(3, 4, 5))
	rig.transform = Transform3D(Basis.IDENTITY, Vector3(9, 9, 9))
	await get_tree().process_frame
	_expect(view.transform.is_equal_approx(Transform3D(Basis.IDENTITY, start))
		and rig.global_position.is_equal_approx(target.global_position + Vector3.UP * rig.focus_height),
		"a rig or camera moved by hand goes back where the game puts it")
	_save(fixture, path)
	saved = _load(path)
	_expect((saved.get_node("Rig") as Node3D).transform.is_equal_approx(authored_rig)
		and (saved.get_node("Rig/Arm/View") as Node3D).transform.is_equal_approx(authored_view),
		"a move by hand or its undo never becomes the saved transform")
	saved.free()
	rig.scale = Vector3.ONE * 1.5
	await get_tree().process_frame
	_save(fixture, path)
	saved = _load(path)
	var saved_basis := (saved.get_node("Rig") as Node3D).transform.basis
	_expect(saved_basis.get_scale().is_equal_approx(Vector3.ONE * 1.5)
		and saved_basis.orthonormalized().is_equal_approx(authored_rig.basis.orthonormalized()),
		"a scale set by hand is saved, with the rig turned as loaded")
	saved.free()
	rig.scale = Vector3.ONE
	rig.target = null
	await get_tree().process_frame
	_expect(rig.position.is_equal_approx(authored_rig.origin), "without a target the rig stands where it was placed")
	rig.position = Vector3(2, 0, 2)
	await get_tree().process_frame
	_save(fixture, path)
	saved = _load(path)
	var saved_rig := (saved.get_node("Rig") as Node3D).transform
	_expect(saved_rig.origin.is_equal_approx(Vector3(2, 0, 2)) and saved_rig.basis.is_equal_approx(authored_rig.basis),
		"without a target the rig is saved where it is placed, turned as loaded")
	saved.free()
	rig.target = target
	await get_tree().process_frame
	_save(fixture, path)
	saved = _load(path)
	_expect((saved.get_node("Rig") as Node3D).position.is_equal_approx(Vector3(2, 0, 2)),
		"framing a target again keeps the placed position for saving")
	saved.free()
	fixture.free()
	# A rig without an arm places its camera itself.
	var plain := OrbitCameraRig.new()
	var direct := Camera3D.new()
	direct.transform = authored_view
	plain.add_child(direct)
	add_child(plain)
	await get_tree().process_frame
	var distance := lerpf(plain.near_distance, plain.far_distance, plain.start_zoom)
	_expect(direct.position.is_equal_approx(Vector3(0, 0, distance)), "a rig without an arm previews its camera")
	plain.propagate_notification(NOTIFICATION_EDITOR_PRE_SAVE)
	_expect(direct.transform.is_equal_approx(authored_view), "and gives it back its own transform for saving")
	plain.propagate_notification(NOTIFICATION_EDITOR_POST_SAVE)
	plain.free()


## An arm whose script extends CameraArm without @tool does not run in the editor: the rig places the camera itself.
func _check_arm_without_tool() -> void:
	var script := GDScript.new()
	script.source_code = "extends CameraArm\n"
	_expect(script.reload() == OK, "a script that extends CameraArm without @tool")
	var rig := OrbitCameraRig.new()
	var arm := Node3D.new()
	arm.set_script(script)
	var view := Camera3D.new()
	var authored_view := Transform3D(Basis.IDENTITY, Vector3(1, 2, 3))
	view.transform = authored_view
	arm.add_child(view)
	rig.add_child(arm)
	rig.camera = view
	add_child(rig)
	await get_tree().process_frame
	var distance := lerpf(rig.near_distance, rig.far_distance, rig.start_zoom)
	_expect(view.position.is_equal_approx(Vector3(0, 0, distance)),
		"the rig shows the camera of an arm that is not a tool script")
	rig.propagate_notification(NOTIFICATION_EDITOR_PRE_SAVE)
	_expect(view.transform.is_equal_approx(authored_view), "and gives the camera back its own transform for saving")
	rig.propagate_notification(NOTIFICATION_EDITOR_POST_SAVE)
	rig.free()


func _check_saved_source() -> void:
	var prop := PILLAR.instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as StaticProp
	add_child(prop)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.ORANGE
	prop.dimensions.y = 6.4
	prop.surface_material = material
	_save(prop, OUT + "source.tscn")
	_expect(is_equal_approx(prop.get_node("CollisionShape3D").shape.height, 6.4),
		"post-save restores the resized preview")
	prop.free()
	prop = _load_prop(OUT + "source.tscn")
	prop.surface_material = null
	_expect(prop.get_node("MeshInstance3D").material_override == null,
		"reopen and clear Surface Material restores authored materials")
	_expect(is_equal_approx(prop.get_node("CollisionShape3D").shape.height, 6.4), "reopen applies Dimensions once")
	_save(prop, OUT + "source_cleared.tscn")
	prop.free()
	prop = _load_prop(OUT + "source_cleared.tscn")
	_expect(prop.get_node("MeshInstance3D").material_override == null
		and is_equal_approx(prop.get_node("CollisionShape3D").shape.height, 6.4),
		"a second save/reopen preserves the cleared material and size")
	prop.free()


func _check_inheritance() -> void:
	var base_text := FileAccess.get_file_as_string("res://shared/world/props/stone_pillar.tscn")
	# A copy under another path, without the uid of the prop's scene: that would lead back to the prop itself.
	var header := base_text.get_slice("\n", 0)
	base_text = RegEx.create_from_string(' uid="[^"]*"').sub(header, "") + base_text.substr(header.length())
	var file := FileAccess.open(OUT + "base.tscn", FileAccess.WRITE)
	file.store_string(base_text)
	file.close()
	file = FileAccess.open(OUT + "variant.tscn", FileAccess.WRITE)
	file.store_string('[gd_scene format=3]\n[ext_resource type="PackedScene" path="' + OUT
		+ 'base.tscn" id="1"]\n[node name="Variant" instance=ExtResource("1")]\n')
	file.close()
	var prop := _load_prop(OUT + "variant.tscn")
	_save(prop, OUT + "variant.tscn")
	_expect(not FileAccess.get_file_as_string(OUT + "variant.tscn").contains("shape ="),
		"an unchanged inheritor does not freeze the base shape")
	prop.free()
	file = FileAccess.open(OUT + "base.tscn", FileAccess.WRITE)
	file.store_string(base_text.replace("height = 3.2", "height = 5.0"))
	file.close()
	prop = _load_prop(OUT + "variant.tscn")
	var mesh := prop.get_node("MeshInstance3D") as MeshInstance3D
	_expect(is_equal_approx(prop.get_node("CollisionShape3D").shape.height, 5.0)
		and is_equal_approx(mesh.mesh.height * mesh.scale.y, 5.0),
		"editing the base changes both inherited visual and collision")
	prop.dimensions.y = 8.0
	_save(prop, OUT + "variant.tscn")
	_expect(not FileAccess.get_file_as_string(OUT + "variant.tscn").contains("shape ="),
		"a resized inheritor stores Dimensions without a computed shape override")
	prop.free()
	prop = _load_prop(OUT + "variant.tscn")
	_expect(is_equal_approx(prop.get_node("CollisionShape3D").shape.height, 8.0),
		"a resized inheritor reopens with matching collision")
	prop.free()


func _check_live_authoring() -> void:
	var prop := PILLAR.instantiate() as StaticProp
	add_child(prop)
	var mesh := MeshInstance3D.new()
	mesh.mesh = CylinderMesh.new()
	mesh.position.x = 4.0
	prop.add_child(mesh)
	var collision := CollisionShape3D.new()
	collision.shape = CylinderShape3D.new()
	collision.position.x = 4.0
	prop.add_child(collision)
	await get_tree().process_frame
	await get_tree().process_frame
	prop.dimensions = prop.get_natural_size() * 2.0
	_expect(mesh.scale.is_equal_approx(prop.get_node("MeshInstance3D").scale)
		and is_equal_approx(collision.shape.get_debug_mesh().get_aabb().size.y, mesh.mesh.height * mesh.scale.y),
		"added visuals and collision resize together in the editor")
	prop.surface_material = StandardMaterial3D.new()
	_expect(mesh.material_override == prop.surface_material, "added visual receives Surface Material in the editor")
	var later_shape := CollisionShape3D.new()
	prop.add_child(later_shape)
	await get_tree().process_frame
	await get_tree().process_frame
	later_shape.shape = BoxShape3D.new()
	await get_tree().process_frame
	await get_tree().process_frame
	prop.dimensions *= 2.0
	_expect(later_shape.shape.get_debug_mesh().get_aabb().size.y > 1.5,
		"a shape assigned after adding an empty collider participates in resizing")
	prop.free()


## A controller reads its siblings, which the Scene dock does not recheck: it listens to its body.
func _check_patrol_body_warning() -> void:
	get_tree().node_configuration_warning_changed.connect(_warned)
	var body := CharacterBody3D.new()
	var mover := NavigationMover.new()
	var controller := PatrolController.new()
	body.add_child(mover)
	body.add_child(controller)
	add_child(body)
	await get_tree().process_frame
	_expect(controller._get_configuration_warnings().is_empty(), "a controller beside the body's mover has no warning")
	_warning_updates.clear()
	body.remove_child(mover)
	_expect(_warning_updates.get(controller, 0) > 0 and not controller._get_configuration_warnings().is_empty(),
		"taking the mover from the body refreshes the controller's warning")
	_warning_updates.clear()
	body.add_child(mover)
	_expect(_warning_updates.get(controller, 0) > 0 and controller._get_configuration_warnings().is_empty(),
		"giving the body its mover back clears it")
	body.free()
	get_tree().node_configuration_warning_changed.disconnect(_warned)


## The name over a patrolling character's head is a preview too: the scene keeps the label's own text.
func _check_patrol_actor_preview() -> void:
	var knight := KNIGHT.instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as PatrolActor
	add_child(knight)
	_expect(knight.title.text == "Knight", "the patrol actor shows its name over the head in the editor")
	_save(knight, OUT + "knight.tscn")
	var text := FileAccess.get_file_as_string(OUT + "knight.tscn")
	_expect(not text.contains("text =") and not text.contains('name="Title"'),
		"saving the knight adds nothing to its inherited label")
	_expect(knight.title.text == "Knight", "the name shows again after saving")
	knight.free()


## A copy of a patrolling character (Duplicate, copy and paste) makes its own model and does not copy the original's.
func _check_copied_actor() -> void:
	var knight := KNIGHT.instantiate(PackedScene.GEN_EDIT_STATE_MAIN) as PatrolActor
	add_child(knight)
	var copy := knight.duplicate() as PatrolActor
	add_child(copy)
	var models := copy.character.visual.get_children(true).filter(func(node: Node) -> bool: return node is Node3D)
	_expect(models.size() == 1, "a copy of a patrolling character shows one model")
	copy.free()
	knight.free()


## Walking is the game's: a patrol turned off and on in the editor starts nothing.
func _check_patrol_switch() -> void:
	var body := CharacterBody3D.new()
	var mover := NavigationMover.new()
	var controller := PatrolController.new()
	body.add_child(mover)
	body.add_child(controller)
	add_child(body)
	await get_tree().process_frame
	controller.enabled = false
	controller.enabled = true
	_expect(controller.get_state() == PatrolController.State.IDLE,
		"turning a patrol off and on in the editor starts nothing")
	body.free()
