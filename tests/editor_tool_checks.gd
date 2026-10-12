@tool
extends Node3D
## Checks of the tool code in the editor itself: its callbacks, the warnings and what the scenes are saved with. Open
## editor_tool_checks.tscn and press Run Checks in the Inspector; the results show there, in the output and in
## .godot/editor_tool_checks/results.json. The fixtures go only into that folder, which every run clears: no scene of
## the project and no player preference is written.

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
