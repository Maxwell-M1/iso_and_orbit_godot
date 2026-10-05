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
@export_file("*.tscn", "*.scn") var target_level := ""

## The spawn point to arrive at on [member target_level] ([member SpawnPoint.spawn_name]).
@export var target_spawn := &"default"

## The name of the place the portal leads to, for a prompt and the loading screen. It is translated where it is shown.
@export var title := "":
	set(value):
		title = value
		if title_label != null:
			title_label.text = title

## A sign over the portal that shows [member title], if needed: the portal writes the title into it.
@export var title_label: Label3D:
	set(value):
		title_label = value
		if title_label != null:
			title_label.text = title

## Who can travel: a body in this group.
@export var traveller_group := &"player"

## Travel as soon as a traveller enters, without asking: a door, the edge of a map. Off: the game asks first and calls
## [method travel].
@export var auto_travel := false

var _travellers: Array[Node3D] = []


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


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
