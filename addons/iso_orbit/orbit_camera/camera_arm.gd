class_name CameraArm
extends Node3D
## The arm that holds the camera: the camera hangs at the end of an arm of length [member length] (the node's local
## +Z axis) and looks along it toward the start of the arm. The length is set by whoever holds the arm (for example,
## [OrbitCameraRig] with the wheel), and the arm shortens near obstacles:
##
## - [member keep_out_of_geometry]: the camera does not go inside bodies; it rests against a hill or wall behind it
##   and moves toward the start of the arm while there is no room behind it;
## - [member pull_in_on_occlusion]: if an obstacle hides the target but the camera has enough room behind it (a tall
##   fence), the camera moves closer than the obstacle, but not closer to the target than [member min_pull_in_length].
##
## The camera is a sphere of radius [member probe_radius]: it does not come right up against a wall. The arm rests
## against a body behind it instantly, approaches an obstacle that hides the target quickly and smoothly
## ([member pull_in_sharpness]), and lengthens back smoothly and with a delay ([member return_delay],
## [member return_sharpness]), so the camera does not jerk back and forth. When the camera comes very close, the
## target becomes semi-transparent ([member fade_target]).
##
## The node is placed as a child of whatever rotates and moves it, and the camera as a child of the node. The arm is
## blocked by bodies on the [member collision_mask] layers; bodies in the [member ignored_groups] groups (or under a
## node in such a group) do not block it. It is convenient to set the group once in a prop scene: then all its
## instances have it.

## How many times one query skips bodies from [member ignored_groups] before giving up; also how many walls the search
## for free space tries.
const _MAX_IGNORED_HITS := 8

## Arm length without obstacles: the camera hangs at this distance from the start of the arm.
@export_range(0.0, 100.0, 0.01, "or_greater", "suffix:m") var length := 10.0

## The camera at the end of the arm. If not set, the first child [Camera3D] is used.
@export var camera: Camera3D

@export_group("Collision")
## Do not go inside bodies: if a hill or wall is behind the camera, the camera rests against it and moves toward the
## start of the arm while there is no room behind it.
@export var keep_out_of_geometry := true
## Radius of the camera sphere: the camera does not come closer than this to a wall.
@export_range(0.01, 2.0, 0.01, "suffix:m") var probe_radius := 0.3
## Physics layers whose bodies block the arm. It is better not to include characters: the camera should not jump
## because of passersby. By default, "world" and "camera": the second one holds bodies only for the camera (a roof
## without collision for characters).
@export_flags_3d_physics var collision_mask := 0b101
## Bodies in these groups or under a node in such a group do not block the arm. It is convenient to set the group once
## in a prop scene (for example, a tree): then all its instances have it; or on a folder node: then all its children
## have it.
@export var ignored_groups: Array[StringName] = [&"camera_ignore"]

@export_group("Occlusion")
## Move closer if the target is hidden by an obstacle behind which the camera has enough room (a tall fence). Without
## this, the camera stays in place, and the target is visible only through the obstacle (if something draws that).
@export var pull_in_on_occlusion := false
## Because of a hidden target, the camera does not come closer than this to the target: if there is less room in front
## of the obstacle (the target stands right at a wall), the camera stays where it was. Otherwise, at every wall it
## would jump right up to the target and back.
@export_range(0.0, 20.0, 0.1, "suffix:m") var min_pull_in_length := 2.5
## How fast the camera approaches an obstacle that hides the target. Higher is sharper; 0 is instant. The camera
## always rests against a body behind it instantly.
@export_range(0.0, 50.0, 0.1) var pull_in_sharpness := 10.0
## The target points to which the line of sight is checked, relative to the start of the arm: x is to the right of the
## camera, y is up, z is toward the camera (horizontally). On a character, the start of the arm is roughly the chest.
@export var occlusion_points := PackedVector3Array([
	Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.5, 0.0), Vector3(0.0, -0.8, 0.0),
	Vector3(-0.3, 0.0, 0.0), Vector3(0.3, 0.0, 0.0),
])
## The target is hidden if this share of the [member occlusion_points] points is hidden. Lower: even a tree trunk
## jerks the camera; higher: the camera waits until the target is hidden completely.
@export_range(0.0, 1.0, 0.01) var occlusion_share := 0.75
## How many seconds the target must stay hidden for the camera to move in, and visible for it to let go: the character
## runs past a pole, and the camera does not even budge.
@export_range(0.0, 2.0, 0.01, "suffix:s") var occlusion_delay := 0.25

@export_group("Return")
## How many seconds the arm waits before lengthening back once the obstacle is gone.
@export_range(0.0, 3.0, 0.01, "suffix:s") var return_delay := 0.3
## How fast the arm lengthens back. Higher is sharper; 0 is instant.
@export_range(0.0, 50.0, 0.1) var return_sharpness := 4.0

@export_group("Fade")
## What to make semi-transparent when the camera comes very close (usually the character model). Not set: nothing.
@export var fade_target: Node3D
## When the arm is shorter than this, the target starts to become more transparent.
@export_range(0.0, 10.0, 0.01, "suffix:m") var fade_start_length := 1.5
## At this length and shorter, the target is transparent by [member fade_transparency].
@export_range(0.0, 10.0, 0.01, "suffix:m") var fade_end_length := 0.7
## How transparent the target is right at the camera: 0 is opaque, 1 is invisible.
@export_range(0.0, 1.0, 0.01) var fade_transparency := 0.75

@export_group("Debug")
## Draw the arm (gray: length without obstacles), the camera sphere, and the rays to the target points (red: hidden).
@export var debug_draw := false:
	set(value):
		debug_draw = value
		if not value and _debug_mesh != null:
			_debug_mesh.queue_free()
			_debug_mesh = null

var _space: PhysicsDirectSpaceState3D
var _ray_query := PhysicsRayQueryParameters3D.new()
var _shape_query := PhysicsShapeQueryParameters3D.new()
var _sphere := SphereShape3D.new()
var _touch_sphere := SphereShape3D.new()
# Bodies from ignored_groups found this frame: all queries of the frame skip them.
var _ignored: Array[RID] = []
# How much the obstacles allow the arm (INF: no limit). Toward an obstacle: instantly; back: smoothly.
var _limit := INF
var _return_wait := 0.0
var _occluded := false
var _pulled_in := false
var _occlusion_timer := 0.0
var _current_length := 0.0
var _fade := 0.0
var _debug_mesh: MeshInstance3D
var _debug_lines := PackedVector3Array()
var _debug_colors := PackedColorArray()


func _ready() -> void:
	if camera == null:
		for child: Node in get_children():
			if child is Camera3D:
				camera = child as Camera3D
				break
	assert(camera != null, "CameraArm needs a Camera3D child or the camera property set.")
	_ray_query.hit_from_inside = false
	_ray_query.hit_back_faces = false
	_shape_query.shape = _sphere
	_current_length = length
	_place_camera()


func _process(delta: float) -> void:
	_update(delta, false)


## Snap into place immediately, without delays or a smooth return: for example, after the target teleports.
func snap() -> void:
	_update(0.0, true)


## The current arm length, accounting for obstacles and the smooth return.
func get_current_length() -> float:
	return _current_length


## The camera is moving closer or has already moved closer because the target is hidden
## ([member pull_in_on_occlusion]).
func is_pulled_in_by_occlusion() -> bool:
	return _pulled_in


func _update(delta: float, instant: bool) -> void:
	if not is_inside_tree():
		return
	_space = get_world_3d().direct_space_state
	_ignored.clear()
	_debug_lines.clear()
	_debug_colors.clear()
	_sphere.radius = probe_radius
	_touch_sphere.radius = probe_radius + 0.05
	var origin := global_position
	var direction := global_basis.z.normalized()
	var free := length
	if keep_out_of_geometry:
		free = _get_free_length(origin, direction, length)
	var wanted := free
	_pulled_in = false
	if pull_in_on_occlusion:
		var hidden := _is_target_hidden(origin, origin + direction * free)
		_update_occlusion(hidden, delta, instant)
		# Move in only while the target is also hidden right now: otherwise, in the pause before "visible", the camera
		# would move to another body on the arm. The return pause holds the camera for a target that flickers.
		if _occluded and hidden:
			var pulled := free * _sweep(origin, origin + direction * free)
			if pulled >= min_pull_in_length:
				wanted = pulled
				_pulled_in = true
	else:
		_occluded = false
		_occlusion_timer = 0.0
	_update_limit(wanted if wanted < length else INF, free if free < length else INF, delta, instant)
	_current_length = maxf(minf(length, _limit), 0.0)
	_place_camera()
	_update_fade()
	if debug_draw:
		_add_debug_line(origin, origin + direction * length, Color(0.6, 0.6, 0.6))
		_add_debug_line(origin, origin + direction * _current_length, Color(0.2, 0.9, 0.3))
		_add_debug_sphere(origin + direction * _current_length, Color(0.2, 0.9, 0.3))
		_draw_debug()


## Where the free space for the camera ends on an arm of length [param full]. The arm shortens only if the camera
## cannot stand at the very end of the arm: the sphere there touches a body, or the end of the arm is inside a body.
## Then the camera moves toward the start of the arm and stands in front of that body. Bodies that the arm only passes
## by (a column or a fence between the camera and the target) do not shorten the arm: that is the job of
## [member pull_in_on_occlusion].
func _get_free_length(origin: Vector3, direction: Vector3, full: float) -> float:
	if full <= 0.0:
		return full
	var end := origin + direction * full
	# The last obstacle in front of the camera: a ray from the camera to the start of the arm. From inside a body, the
	# ray does not see its walls, so it finds the far wall of the obstacle in front of the camera, not the wall of the
	# body the camera sits in.
	var behind := _cast_ray(end, origin)
	var behind_at := 0.0
	if not behind.is_empty():
		behind_at = (behind.position as Vector3 - origin).dot(direction)
	# What keeps the camera from standing at the end of the arm: the bodies that the sphere touches there (except the
	# obstacle in front of the camera), and the body that contains the end of the arm (a ray from that wall to the end
	# of the arm enters it and never exits).
	var blockers := _touching(end)
	if not behind.is_empty():
		blockers.erase(behind.rid)
	var containing := _cast_ray(origin + direction * minf(behind_at + 0.01, full), end)
	if not containing.is_empty() and not blockers.has(containing.rid):
		blockers.append(containing.rid)
	if blockers.is_empty():
		return full
	# The sphere moves toward the end of the arm from this wall (or from the start of the arm) and stops in front of
	# the first of the blocking bodies; it passes the other bodies.
	var start := 0.0
	var wall := behind
	for attempt in _MAX_IGNORED_HITS:
		if wall.is_empty():
			start = 0.0
			break
		var wall_at := (wall.position as Vector3 - origin).dot(direction)
		# The sphere starts its path offset from the wall by its radius: otherwise it would touch the wall from the
		# very start.
		var facing := maxf((wall.normal as Vector3).dot(direction), 0.25)
		start = minf(wall_at + probe_radius * 1.05 / facing, full)
		# Physics does not see the bodies that the sphere touches at the start of its path. If a blocking body is
		# already there (it stands right behind the wall), there is no room behind this wall: look for room behind an
		# obstacle closer to the start of the arm.
		if not _touches_any(origin + direction * start, blockers):
			break
		wall = _cast_ray(origin + direction * maxf(wall_at - 0.01, 0.0), origin)
	var from := origin + direction * start
	var result := start + (full - start) * _sweep(from, end, blockers)
	# The sphere may have stopped inside a body it passed (a fence right in front of a cliff): then it stops in front
	# of the first body on its path.
	if not _touching(origin + direction * result).is_empty():
		result = start + (full - start) * _sweep(from, end)
	return result


## The target is hidden if the share [member occlusion_share] of its points is not visible from [param camera_point].
func _is_target_hidden(origin: Vector3, camera_point: Vector3) -> bool:
	if occlusion_points.is_empty():
		return false
	var back := Vector3(global_basis.z.x, 0.0, global_basis.z.z)
	if back.is_zero_approx():
		back = Vector3(-global_basis.y.x, 0.0, -global_basis.y.z)
	back = back.normalized()
	var right := Vector3.UP.cross(back)
	var hidden := 0
	for offset: Vector3 in occlusion_points:
		var point := origin + right * offset.x + Vector3.UP * offset.y + back * offset.z
		var blocked := not _cast_ray(camera_point, point).is_empty()
		if blocked:
			hidden += 1
		if debug_draw:
			_add_debug_line(camera_point, point, Color(0.95, 0.25, 0.2) if blocked else Color(0.3, 0.6, 1.0))
	return hidden >= maxi(1, ceili(occlusion_share * occlusion_points.size() - 0.001))


## Whether the target is hidden or visible changes only if the new state holds for [member occlusion_delay] seconds.
func _update_occlusion(hidden: bool, delta: float, instant: bool) -> void:
	if instant or hidden == _occluded:
		_occluded = hidden
		_occlusion_timer = 0.0
		return
	_occlusion_timer += delta
	if _occlusion_timer >= occlusion_delay:
		_occluded = hidden
		_occlusion_timer = 0.0


## How much the obstacles allow the arm: [param wanted] includes moving in toward a hidden target, [param hard] is
## resting against what is behind. Against a body behind, the arm shortens instantly; toward an obstacle that hides
## the target, by [member pull_in_sharpness]; back, smoothly after [member return_delay].
func _update_limit(wanted: float, hard: float, delta: float, instant: bool) -> void:
	if instant:
		_limit = wanted
		_return_wait = 0.0
		return
	# While an obstacle holds the arm, the return delay does not run: it counts from the moment there is more room.
	if wanted <= _limit + 0.01:
		if wanted < _limit and pull_in_sharpness > 0.0:
			_limit = lerpf(minf(_limit, length), wanted, 1.0 - exp(-pull_in_sharpness * delta))
		else:
			_limit = minf(_limit, wanted)
		_limit = minf(_limit, hard)
		_return_wait = return_delay
		return
	if _return_wait > 0.0:
		_return_wait -= delta
		return
	var target := minf(wanted, length)
	_limit = target if return_sharpness <= 0.0 else lerpf(_limit, target, 1.0 - exp(-return_sharpness * delta))
	if _limit >= length - 0.001 and wanted >= length:
		_limit = INF


func _place_camera() -> void:
	if camera != null:
		camera.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, _current_length))


func _update_fade() -> void:
	if fade_target == null:
		return
	var fade := 0.0
	if fade_start_length > fade_end_length:
		fade = clampf(inverse_lerp(fade_start_length, fade_end_length, _current_length), 0.0, 1.0)
	fade *= fade_transparency
	if fade == 0.0 and _fade == 0.0:
		return
	_fade = fade
	# Every frame while the target is transparent: the meshes may have changed (another look, equipment).
	for mesh: Node in fade_target.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).transparency = fade


## A ray from [param from] to [param to] against [member collision_mask], skipping bodies from [member ignored_groups].
func _cast_ray(from: Vector3, to: Vector3) -> Dictionary:
	_ray_query.from = from
	_ray_query.to = to
	_ray_query.collision_mask = collision_mask
	for attempt in _MAX_IGNORED_HITS:
		_ray_query.exclude = _ignored
		var hit := _space.intersect_ray(_ray_query)
		if hit.is_empty() or not _is_ignored(hit.collider):
			return hit
		_ignored.append(hit.rid)
	return {}


## The share of the path from [param from] to [param to] that the camera sphere covers without touching anything. If
## the list [param only] is set, only these bodies stop the sphere; it passes the others. The sphere does not see the
## bodies it touches already at the start of the path (that is how physics works): so the path starts in free space.
func _sweep(from: Vector3, to: Vector3, only: Array[RID] = []) -> float:
	_shape_query.collision_mask = collision_mask
	var passed: Array[RID] = []
	var safe := 1.0
	for attempt in _MAX_IGNORED_HITS:
		var exclude: Array[RID] = _ignored.duplicate()
		exclude.append_array(passed)
		_shape_query.exclude = exclude
		_shape_query.transform = Transform3D(Basis.IDENTITY, from)
		_shape_query.motion = to - from
		var fractions := _space.cast_motion(_shape_query)
		safe = fractions[0]
		if fractions[1] >= 1.0 or (ignored_groups.is_empty() and only.is_empty()):
			return safe
		# What the sphere touched: skip the bodies from ignored_groups and those not in [param only], and continue. At
		# the contact point, the sphere only touches the body, and the intersection check may miss it: use a slightly
		# larger sphere.
		_shape_query.shape = _touch_sphere
		_shape_query.transform = Transform3D(Basis.IDENTITY, from + (to - from) * fractions[1])
		_shape_query.motion = Vector3.ZERO
		var touches := _space.intersect_shape(_shape_query, 8)
		_shape_query.shape = _sphere
		var stops := touches.is_empty()
		for touch: Dictionary in touches:
			var rid: RID = touch.rid
			if _is_ignored(touch.collider):
				_ignored.append(rid)
			elif not only.is_empty() and not only.has(rid):
				passed.append(rid)
			else:
				stops = true
		if stops:
			return safe
	return safe


## The bodies that the camera sphere touches at the point [param center], except bodies from [member ignored_groups].
func _touching(center: Vector3) -> Array[RID]:
	_shape_query.transform = Transform3D(Basis.IDENTITY, center)
	_shape_query.motion = Vector3.ZERO
	_shape_query.exclude = _ignored
	_shape_query.collision_mask = collision_mask
	var result: Array[RID] = []
	for touch: Dictionary in _space.intersect_shape(_shape_query, 8):
		if _is_ignored(touch.collider):
			_ignored.append(touch.rid)
		else:
			result.append(touch.rid)
	return result


## The camera sphere at the point [param center] touches one of the [param bodies].
func _touches_any(center: Vector3, bodies: Array[RID]) -> bool:
	for rid: RID in _touching(center):
		if bodies.has(rid):
			return true
	return false


## The body [param collider] or a node above it is in one of the [member ignored_groups] groups.
func _is_ignored(collider: Object) -> bool:
	if ignored_groups.is_empty():
		return false
	var node := collider as Node
	while node != null:
		for group: StringName in ignored_groups:
			if node.is_in_group(group):
				return true
		node = node.get_parent()
	return false


func _add_debug_line(from: Vector3, to: Vector3, color: Color) -> void:
	_debug_lines.append_array([from, to])
	_debug_colors.append_array([color, color])


func _add_debug_sphere(center: Vector3, color: Color) -> void:
	const SEGMENTS := 24
	# Three circles in the XY, XZ and YZ planes.
	for plane: Basis in [Basis.IDENTITY, Basis(Vector3.RIGHT, PI / 2.0), Basis(Vector3.UP, PI / 2.0)]:
		for i in SEGMENTS:
			var from := Vector3(cos(TAU * i / SEGMENTS), sin(TAU * i / SEGMENTS), 0.0)
			var to := Vector3(cos(TAU * (i + 1) / SEGMENTS), sin(TAU * (i + 1) / SEGMENTS), 0.0)
			_add_debug_line(center + plane * from * probe_radius, center + plane * to * probe_radius, color)


func _draw_debug() -> void:
	if _debug_mesh == null:
		_debug_mesh = MeshInstance3D.new()
		_debug_mesh.name = "ArmDebug"
		_debug_mesh.top_level = true
		_debug_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_debug_mesh.mesh = ImmediateMesh.new()
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		material.no_depth_test = true
		_debug_mesh.material_override = material
		add_child(_debug_mesh, false, Node.INTERNAL_MODE_BACK)
	_debug_mesh.global_transform = Transform3D.IDENTITY
	var mesh := _debug_mesh.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if _debug_lines.is_empty():
		return
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in _debug_lines.size():
		mesh.surface_set_color(_debug_colors[i])
		mesh.surface_add_vertex(_debug_lines[i])
	mesh.surface_end()
