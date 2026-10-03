class_name CharacterAppearance
extends Node
## The character's look: which model sits in the model node. A look is a number in the [member models] list, starting
## from 1.
##
## [method set_look] changes the model on the fly: it removes the old one, puts the new one in its place under the
## same name and gives the new model's hand to [HandSway] (the staff sways in time with the steps again). The
## silhouette ([OccludedSilhouette]) picks up the new meshes by itself. The model must face −Z and hold the item in
## the [member hand_path] node.

## The look changed; [param model] is the new model.
signal look_changed(model: Node3D)

## The node that holds the model (for the player, Visual: [GroundCharacter] turns it).
@export var slot: Node3D

## Name of the model node inside [member slot].
@export var model_name := &"Model"

## Models to choose from. The look number is the position in the list, starting from 1.
@export var models: Array[PackedScene] = []

## Who gets the new model's hand. If not set, the hand does not sway.
@export var hand_sway: HandSway

## Where in the model the hand holding the item is.
@export var hand_path := ^"RightHand"


## Set look number [param number] (starting from 1; outside the list, the nearest end of it).
func set_look(number: int) -> void:
	assert(slot != null and not models.is_empty(), "CharacterAppearance needs slot and models.")
	var scene := models[clampi(number, 1, models.size()) - 1]
	var current := get_model()
	if current != null and current.scene_file_path == scene.resource_path:
		return
	var model := scene.instantiate() as Node3D
	if current != null:
		slot.remove_child(current)
		current.queue_free()
	model.name = model_name
	slot.add_child(model)
	# The model appears in place at once: without this, physics interpolation would drag it from the origin.
	model.reset_physics_interpolation()
	if hand_sway != null:
		hand_sway.hand = model.get_node_or_null(hand_path) as Node3D
	look_changed.emit(model)


## The number of the current look (starting from 1), or 0 if the model in place is not from the list.
func get_look() -> int:
	var current := get_model()
	if current == null:
		return 0
	for i in models.size():
		if models[i].resource_path == current.scene_file_path:
			return i + 1
	return 0


## The current model, or null.
func get_model() -> Node3D:
	return slot.get_node_or_null(NodePath(model_name)) as Node3D
