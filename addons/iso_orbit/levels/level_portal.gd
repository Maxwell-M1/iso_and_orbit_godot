@tool
class_name LevelPortal
extends Area3D
## A way to another level: a door, a teleport pad, the edge of a map. When a traveller (a body in
## [member traveller_group], usually the player) enters the area, the portal tells so ([signal traveller_entered]). Then
## the game asks the player and calls [method travel], or the portal travels by itself ([member auto_travel]).
## [LevelHost] connects the portals of its level: a request to travel changes the level.
##
## The area must see the traveller's layer ([member CollisionObject3D.collision_mask]); a layer of its own is not
## needed. The level is named by the path of its scene, not by a loaded scene, so two levels can lead to each other.

## A traveller has entered the area.
signal traveller_entered(body: Node3D)
## A traveller has left the area.
signal traveller_exited(body: Node3D)
## Travel to [member target_level] is asked for: by [method travel], or on entering with [member auto_travel].
signal travel_requested(portal: LevelPortal)

## The group that contains all portals.
const GROUP := &"level_portals"

## The level to travel to: its scene file.
@export_file("*.tscn", "*.scn") var target_level := "":
	set(value):
		target_level = value
		update_configuration_warnings()

## The spawn point to arrive at on [member target_level] ([member SpawnPoint.spawn_name]).
@export var target_spawn := &"default":
	set(value):
		target_spawn = value
		update_configuration_warnings()

## The name of the place the portal leads to, for a prompt and the loading screen. It is translated where it is shown.
@export var title := "":
	set(value):
		title = value
		_show_title()

## A sign over the portal that shows [member title], if needed: the portal writes the title into it.
@export var title_label: Label3D:
	set(value):
		title_label = value
		_show_title()

## Who can travel: a body in this group.
@export var traveller_group := &"player"

## Travel as soon as a traveller enters, without asking: a door, the edge of a map. Off: the game asks first and calls
## [method travel].
@export var auto_travel := false

var _travellers: Array[Node3D] = []
# In the editor: the sign that shows the title, and its text as loaded, put back for saving.
var _sign: Label3D
var _sign_text := ""


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	# In the editor the sign shows the title too; the scene keeps the sign's own text.
	if what == NOTIFICATION_EDITOR_PRE_SAVE and is_instance_valid(_sign):
		_sign.text = _sign_text
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_show_title()


## Ask to travel to [member target_level]: the level host changes the level.
func travel() -> void:
	travel_requested.emit(self)


## A traveller is inside the area now.
func has_traveller() -> bool:
	return not _travellers.is_empty()


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(traveller_group) or body in _travellers:
		return
	_travellers.append(body)
	traveller_entered.emit(body)
	if auto_travel:
		travel()


func _on_body_exited(body: Node3D) -> void:
	if body not in _travellers:
		return
	_travellers.erase(body)
	traveller_exited.emit(body)


func _show_title() -> void:
	if Engine.is_editor_hint() and title_label != _sign:
		# Another sign: the previous one gets its own text back.
		if is_instance_valid(_sign):
			_sign.text = _sign_text
		_sign = title_label
		if title_label != null:
			_sign_text = title_label.text
	if title_label != null:
		title_label.text = title


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if target_level.is_empty() or not ResourceLoader.exists(target_level):
		warnings.append("Choose an existing target level scene.")
	if target_spawn == &"":
		warnings.append("Choose the destination spawn name.")
	return warnings
