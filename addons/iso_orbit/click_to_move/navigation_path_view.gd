class_name NavigationPathView
extends MeshInstance3D
## A debug line of the remaining path of a [NavigationMover]: it shows how the character goes around obstacles.
##
## The line follows the path points at the height of the navigation mesh, that is, slightly above the ground.

## Whose path to draw.
@export var mover: NavigationMover

## The line color.
@export var color := Color(1.0, 0.85, 0.25)

var _lines := ImmediateMesh.new()


func _ready() -> void:
	assert(mover != null, "NavigationPathView needs the mover property set.")
	# The line is built every frame in world coordinates and must neither be smoothed nor move with the parent.
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = _lines
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.no_depth_test = true
	material_override = material


func _process(_delta: float) -> void:
	_lines.clear_surfaces()
	if not visible:
		return
	var path := mover.get_remaining_path()
	if path.is_empty():
		return
	# The first point is the character itself as drawn in this frame, at the height of the next path point.
	var start := mover.get_body().get_global_transform_interpolated().origin
	start.y = path[0].y
	_lines.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	_lines.surface_add_vertex(start)
	for point: Vector3 in path:
		_lines.surface_add_vertex(point)
	_lines.surface_end()
