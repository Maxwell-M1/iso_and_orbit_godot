@tool
class_name PatrolActor
extends Node3D
## A demo character that walks a route of the level: a [GroundCharacter] with a [PatrolController], its model and a
## name over its head. Nothing in it belongs to a level: put an instance into a level and assign [member route], a
## [Path3D] drawn there. Another model ([member model_scene]), name, walking settings or patrol times make another
## character; the knight and the ranger of the island are such variants.
##
## The actor needs no player, camera, settings or interface. What it says is a signal ([signal speech_requested]) that
## the game shows if it wants to. To take the actor into another project, copy this script and patrol_actor.tscn with
## the click_to_move and ground_character folders of the addon, then give it a model scene and a route; the variants
## also need their models.

## The actor says [param line] as [param speaker]: the game shows it, as subtitles for example.
signal speech_requested(speaker: String, line: String)

## The group of the actors in the game: the game finds them in a loaded level by it.
const GROUP := &"patrol_actors"

@export_group("Scene Links")
## The character that walks.
@export var character: GroundCharacter:
	set(value):
		character = value
		update_configuration_warnings()
## Its patrol controller: in the game the actor gives it [member route].
@export var controller: PatrolController:
	set(value):
		controller = value
		update_configuration_warnings()
## The label over the head: it shows [member speaker_name].
@export var title: Label3D:
	set(value):
		title = value
		update_configuration_warnings()
		if is_node_ready():
			_show_name()
@export_group("Patrol Route")
## A [Path3D] of the level to walk: drag it here, and edit its points and handles in the 3D viewport. Without a route
## the character stands. A changed curve is read at the next [method PatrolController.restart]. To tune the walk of one
## character, turn on Editable Children and edit Character/PatrolController.
@export var route: Path3D:
	set(value):
		route = value
		_watch_route()
		update_configuration_warnings()
		if is_node_ready() and not Engine.is_editor_hint() and controller != null:
			controller.route = route
			if controller.enabled:
				controller.restart()
@export_group("Appearance")
## The model: a scene whose [Node3D] root faces −Z. It goes under the character's visual node.
@export var model_scene: PackedScene:
	set(value):
		model_scene = value
		if is_node_ready():
			_update_model()
@export_group("Dialogue")
## The name over the head and in [signal speech_requested]. It is translated where it is shown.
@export var speaker_name := "":
	set(value):
		speaker_name = value
		if is_node_ready():
			_show_name()
## What the actor says when another character has stood in its way for [member PatrolController.blocked_delay]
## seconds. Empty: nothing.
@export_multiline var blocked_line := ""

var _model: Node3D
# In the editor: the route whose curve the warning reads, and the label that shows the name with its text as loaded,
# put back for saving.
var _watched_route: Path3D
var _name_label: Label3D
var _label_text := ""


func _ready() -> void:
	# In the editor too: the model and the name show the character as the game will. Neither is saved.
	_update_model()
	_show_name()
	if Engine.is_editor_hint():
		return
	if controller != null:
		controller.route = route
		add_to_group(GROUP)
		controller.blocked_long_enough.connect(_on_blocked_long_enough)


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE and is_instance_valid(_name_label):
		_name_label.text = _label_text
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_show_name()


func _show_name() -> void:
	if Engine.is_editor_hint() and title != _name_label:
		# Another label: the previous one gets its own text back.
		if is_instance_valid(_name_label):
			_name_label.text = _label_text
		_name_label = title
		if title != null:
			_label_text = title.text
	if title != null:
		title.text = speaker_name


# The model is made from model_scene under the character's visual node and belongs to no scene: it is never saved. In
# the editor it is an internal child, which a copy of the actor does not copy.
func _update_model() -> void:
	if is_instance_valid(_model):
		if _model.get_parent() != null:
			_model.get_parent().remove_child(_model)
		_model.queue_free()
	_model = null
	var slot: Node3D = character.visual if character != null else null
	if model_scene == null or slot == null:
		return
	var instance := model_scene.instantiate()
	if not instance is Node3D:
		instance.free()
		push_warning("PatrolActor.model_scene needs a Node3D root.")
		return
	_model = instance as Node3D
	_model.name = "Model"
	slot.add_child(_model, false, Node.INTERNAL_MODE_BACK if Engine.is_editor_hint() else Node.INTERNAL_MODE_DISABLED)


# The warning reads the route's curve, which tells the actor nothing by itself: in the editor the actor listens to it.
func _watch_route() -> void:
	if not Engine.is_editor_hint() or route == _watched_route:
		return
	if is_instance_valid(_watched_route) and _watched_route.curve_changed.is_connected(update_configuration_warnings):
		_watched_route.curve_changed.disconnect(update_configuration_warnings)
	_watched_route = route
	if route != null:
		route.curve_changed.connect(update_configuration_warnings)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if character == null:
		warnings.append("Assign Character in the Inspector.")
	if controller == null:
		warnings.append("Assign Controller in the Inspector.")
	if title == null:
		warnings.append("Assign Title in the Inspector.")
	if not is_instance_valid(route):
		warnings.append("Assign a separate level Path3D to Route to enable this patrol.")
	elif is_ancestor_of(route):
		warnings.append("Keep the route outside this actor: assign a Path3D belonging to the level.")
	elif route.curve == null or route.curve.point_count == 0:
		warnings.append("The assigned Path3D needs curve points. Draw its route in the 3D viewport.")
	return warnings


func _on_blocked_long_enough(_blocker: CharacterBody3D) -> void:
	if not blocked_line.is_empty():
		speech_requested.emit(speaker_name, blocked_line)
