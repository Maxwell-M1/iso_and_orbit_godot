@tool
class_name OccludedSilhouette
extends Node
## The character's silhouette through whatever occludes it: puts a chain of passes over the meshes of
## [member target] ([member GeometryInstance3D.material_overlay]), including meshes that appear later (a changed look
## or equipment). The body merges into one flat shape, the equipment in the hands into its own contour on top of it,
## and an outline ([member outline_enabled]) goes around everything. The model's own materials do not change: the same
## model elsewhere in the world has no silhouette.
## The pass shaders and materials are in addons/iso_orbit/occluded_silhouette/; how they share screen pixels through the stencil is in
## silhouette_common.gdshaderinc.

## Whose meshes to outline (usually the character's model node).
@export var target: Node3D:
	set(value):
		target = value
		update_configuration_warnings()

## The invisible pass: where the character itself is visible (silhouette_mask.tres).
@export var mask: Material:
	set(value):
		mask = value
		update_configuration_warnings()

## Body fill (silhouette_body.tres).
@export var body_fill: Material:
	set(value):
		body_fill = value
		update_configuration_warnings()

## Fill for the equipment in the hands (silhouette_gear.tres).
@export var gear_fill: Material:
	set(value):
		gear_fill = value
		update_configuration_warnings()

## Outline around the whole silhouette (silhouette_outline.tres).
@export var outline: Material:
	set(value):
		outline = value
		update_configuration_warnings()

## Meshes under nodes with these names are equipment in the hands; the rest are the body.
@export var gear_nodes: Array[StringName] = [&"RightHand", &"LeftHand"]

## Draw an outline around the silhouette.
@export var outline_enabled := true:
	set(value):
		outline_enabled = value
		_update_outline()

var _body_overlay: Material
var _gear_overlay: Material


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	assert(target != null and mask != null and body_fill != null and gear_fill != null and outline != null,
			"OccludedSilhouette needs target, mask, body_fill, gear_fill and outline.")
	_body_overlay = _chain(body_fill)
	_gear_overlay = _chain(gear_fill)
	_update_outline()
	for node: Node in target.find_children("*", "GeometryInstance3D", true, false):
		_cover(node as GeometryInstance3D)
	get_tree().node_added.connect(_on_node_added)


## The chain of passes over body meshes ([param gear] = [code]false[/code]) or equipment meshes.
func get_overlay(gear: bool) -> Material:
	return _gear_overlay if gear else _body_overlay


## Whether the mesh [param node] is equipment in the hands: it lies under one of the [member gear_nodes] nodes.
func is_gear(node: Node) -> bool:
	var at := node
	while at != null and at != target:
		if at.name in gear_nodes:
			return true
		at = at.get_parent()
	return false


func _chain(fill: Material) -> Material:
	var first := mask.duplicate() as Material
	first.next_pass = fill.duplicate() as Material
	return first


func _update_outline() -> void:
	for overlay: Material in [_body_overlay, _gear_overlay]:
		if overlay != null:
			overlay.next_pass.next_pass = outline if outline_enabled else null


func _cover(mesh: GeometryInstance3D) -> void:
	mesh.material_overlay = get_overlay(is_gear(mesh))


func _on_node_added(node: Node) -> void:
	if node is GeometryInstance3D and target.is_ancestor_of(node):
		_cover(node as GeometryInstance3D)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if target == null:
		warnings.append("Assign Target in the Inspector.")
	if mask == null:
		warnings.append("Assign Mask in the Inspector.")
	if body_fill == null:
		warnings.append("Assign Body Fill in the Inspector.")
	if gear_fill == null:
		warnings.append("Assign Gear Fill in the Inspector.")
	if outline == null:
		warnings.append("Assign Outline in the Inspector.")
	return warnings
