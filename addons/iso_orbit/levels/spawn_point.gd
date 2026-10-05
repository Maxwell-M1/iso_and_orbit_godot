class_name SpawnPoint
extends Marker3D
## Where a character appears on a level: at the start of the game or on arrival through a [LevelPortal]. The character
## stands where the marker is and faces along its −Z, the forward direction of a node (the blue axis of the gizmo points
## the other way). [LevelHost] finds the point by [member spawn_name] among the points of the level.
##
## Put the marker on the ground: the character's feet go there. Keep it out of portal areas and places: a character that
## appears inside a portal would be asked at once whether to travel back.

## The group that contains all spawn points.
const GROUP := &"spawn_points"

## The name portals and [method LevelHost.change_level] ask for. Every level needs a "default" one: there the game
## starts, and a character arrives there when the name asked for is not on the level.
@export var spawn_name := &"default"


func _init() -> void:
	add_to_group(GROUP)


## Where a character that appears here faces: −Z of the marker, horizontally.
func get_facing() -> Vector3:
	var forward := -global_basis.z
	return Vector3(forward.x, 0.0, forward.z).normalized()
