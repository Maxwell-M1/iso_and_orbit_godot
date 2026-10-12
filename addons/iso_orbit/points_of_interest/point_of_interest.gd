@tool
class_name PointOfInterest
extends Area3D
## A place worth finding: when the player enters the area for the first time, the place is discovered
## ([signal discovered]).
##
## The interface shows the on-screen message ([DiscoveryToast]); it finds all places by the group [constant GROUP],
## so a place can be put into any world scene without links to the interface. The area must see the characters'
## layer ([member CollisionObject3D.collision_mask]).

## The player has entered the area for the first time.
signal discovered(title: String)

## The group that contains all places.
const GROUP := &"points_of_interest"

## The place name shown on screen.
@export var title := "":
	set(value):
		title = value
		update_configuration_warnings()

## Who counts as the player: a body in this group.
@export var player_group := &"player"

var _discovered := false


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func is_discovered() -> bool:
	return _discovered


## Count the place as found without [signal discovered]: the player found it before, on an earlier visit to a level
## loaded again or in a saved game. The place itself remembers only while it exists, so keeping what was found across
## levels is up to the game.
func mark_discovered() -> void:
	_discovered = true


func _on_body_entered(body: Node3D) -> void:
	if _discovered or not body.is_in_group(player_group):
		return
	_discovered = true
	discovered.emit(title)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if title.is_empty():
		warnings.append("Give this place a title.")
	if collision_mask == 0 or get_child_count() == 0:
		warnings.append("Add a collision shape and enable the travellers' collision layer.")
	return warnings
