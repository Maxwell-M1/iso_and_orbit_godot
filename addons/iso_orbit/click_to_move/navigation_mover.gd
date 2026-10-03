class_name NavigationMover
extends Node
## Leads the character to a destination along a navigation path: goes around obstacles, accelerates smoothly and
## stops exactly at the point.
##
## The component is added as a child of the character ([Node3D], usually [CharacterBody3D]). It does not move the
## body itself: every physics tick the owner calls [method compute_velocity] and applies the horizontal velocity.
## This way gravity, jumps and [method CharacterBody3D.move_and_slide] stay in one place, in the body.
##
## Two modes:
## - [method move_to]: to a point along a navigation path, stopping exactly at the point;
## - [method steer]: in a given direction directly, without pathfinding, until [method stop] or [method move_to] is
##   called. The character then gets around obstacles by the body sliding along them.
##
## The path comes from [NavigationServer3D] for the character's world map. Path points are passed by distances in the
## horizontal plane: the baked navigation mesh hovers above the ground (with Recast, by about two
## [member NavigationMesh.cell_height]), and a 3D comparison with the character's feet would be off by that height.
## If the world has no navigation, the character runs to the point directly.

## A new destination is accepted.
signal destination_changed(point: Vector3)
## The path is rebuilt (a new point, the map changed, the character was knocked off the path).
signal path_changed
## The character reached the destination and stopped.
signal arrived
## The destination was abandoned before it was reached: the character was steered in a direction ([method steer]) or
## stopped.
signal destination_cancelled

## Acceleration, braking and turning. If not set, the default settings are used.
@export var settings: LocomotionSettings

## Find the path on the navigation mesh. If disabled, or there is no mesh, run to the point directly.
@export var use_navigation := true

## Navigation layers the path may be built on.
@export_flags_3d_navigation var navigation_layers := 1

## A path point counts as passed when the character is closer than this. The larger it is, the earlier the character
## cuts toward the next one.
@export_range(0.05, 2.0, 0.01, "suffix:m") var waypoint_radius := 0.4

## Closer than this to the end of the path, the character counts as arrived and stops at once. Braking itself brings
## it to the point (it does not overshoot the point within a tick), so the threshold is small: a large one would cut
## off the end of braking with a jerk.
@export_range(0.001, 0.5, 0.001, "suffix:m") var arrive_distance := 0.005

## If the new point is closer than this to the current one, the path is not recomputed. Holding the mouse button
## sends a point every tick, and small cursor shifts must not force a new path search.
@export_range(0.0, 1.0, 0.01, "suffix:m") var retarget_tolerance := 0.1

## If the character is carried farther than this from the path (pushed, moved), the path is rebuilt.
@export_range(0.5, 20.0, 0.1, "suffix:m") var max_path_deviation := 2.0

## Sprint: the speed limit is [member LocomotionSettings.sprint_speed_multiplier] times higher.
## The owner decides (for example, by a key and stamina); the component only runs faster.
var sprinting := false

var _motion: GroundMotion
var _body: Node3D
var _destination := Vector3.ZERO
var _has_destination := false
var _steer_direction := Vector3.ZERO
# Where to face when running sideways (from steer()); ZERO means along the movement. It persists after a stop too.
var _facing := Vector3.ZERO
var _path := PackedVector3Array()
var _path_index := 0
var _path_dirty := false


func _ready() -> void:
	_body = get_parent() as Node3D
	assert(_body != null, "NavigationMover must be a child of a Node3D (usually CharacterBody3D).")
	if settings == null:
		settings = LocomotionSettings.new()
	_motion = GroundMotion.new(settings)
	_motion.face(-_body.global_basis.z)
	NavigationServer3D.map_changed.connect(_on_navigation_map_changed)


## Run to [param point] in global coordinates. Can be called at any time, including every tick: the current speed is
## kept, and the character keeps accelerating or turns toward the new point.
func move_to(point: Vector3) -> void:
	_steer_direction = Vector3.ZERO
	_facing = Vector3.ZERO
	if _has_destination and point.distance_to(_destination) < retarget_tolerance:
		return
	_destination = point
	_has_destination = true
	# The path itself is searched for on the next tick: several calls within a tick cost a single search.
	_path_dirty = true
	destination_changed.emit(point)


## Run toward [param direction] (its horizontal part is used) directly, without pathfinding.
## The character runs until [method stop], [method halt] or [method move_to] is called; the direction can change
## every tick. The speed is kept, as when the point changes.
## With [param facing], the character faces there while moving along [param direction], for example sideways. It then
## keeps facing there after [method stop] too, until it is moved again without this parameter.
func steer(direction: Vector3, facing := Vector3.ZERO) -> void:
	var flat := _flat(direction)
	if flat.is_zero_approx():
		return
	_cancel_destination()
	_steer_direction = flat.normalized()
	var flat_facing := _flat(facing)
	_facing = Vector3.ZERO if flat_facing.is_zero_approx() else flat_facing.normalized()


## Stop smoothly where the character is now.
func stop() -> void:
	_cancel_destination()
	_steer_direction = Vector3.ZERO


## Stop instantly, for example on a teleport.
func halt() -> void:
	stop()
	_facing = Vector3.ZERO
	_motion.halt()


## Horizontal velocity for this tick. Call once per physics tick, before [method CharacterBody3D.move_and_slide].
func compute_velocity(delta: float) -> Vector3:
	_motion.speed_scale = (settings.sprint_speed_multiplier if sprinting else 1.0) * _get_backward_scale()
	if is_steering():
		return _motion.step(_steer_direction, INF, delta)
	if not _has_destination:
		# No target: brake with the normal deceleration and keep the direction.
		return _motion.step(Vector3.ZERO, INF, delta)

	var position := _body.global_position
	if _path_dirty or _is_off_path(position):
		_rebuild_path(position)
	_advance_waypoints(position)

	var next_point := _get_next_point()
	var distance_left := _get_distance_left(position, next_point)
	if distance_left <= arrive_distance:
		_arrive()
		return Vector3.ZERO

	var direction := _flat(next_point - position).normalized()
	if direction == Vector3.ZERO:
		# The next path point is right above or below us: keep running the way we were running.
		direction = _motion.heading
	return _motion.step(direction, distance_left, delta)


func has_destination() -> bool:
	return _has_destination


## The character is being led: to a point or in a direction. Whether it is standing or still braking does not matter.
func is_moving() -> bool:
	return _has_destination or is_steering()


## The character runs in the direction given by [method steer], not to a point.
func is_steering() -> bool:
	return _steer_direction != Vector3.ZERO


func get_destination() -> Vector3:
	return _destination


## Running speed, m/s.
func get_speed() -> float:
	return _motion.speed


## Where the run is directed: a unit horizontal vector. When the character stands, where it last ran.
func get_heading() -> Vector3:
	return _motion.heading


## Where the character should face: along the run ([method get_heading]) or where [method steer] told it to
## (running sideways).
func get_facing() -> Vector3:
	return _facing if _facing != Vector3.ZERO else _motion.heading


## The character this component leads.
func get_body() -> Node3D:
	return _body


## The remaining path points (at the navigation mesh height), starting from the next one. Empty when running directly.
func get_remaining_path() -> PackedVector3Array:
	return _path.slice(_path_index)


## Backward (facing against the movement) the character walks slower: fully backward,
## [member LocomotionSettings.backward_speed_multiplier] times the speed; diagonally backward, partially; sideways, as
## usual.
func _get_backward_scale() -> float:
	if _facing == Vector3.ZERO or not is_steering():
		return 1.0
	var backward := clampf(-_facing.dot(_steer_direction), 0.0, 1.0)
	return lerpf(1.0, settings.backward_speed_multiplier, backward)


func _rebuild_path(position: Vector3) -> void:
	_path_dirty = false
	_path_index = 0
	_path.clear()
	if use_navigation:
		var map := _body.get_world_3d().navigation_map
		if NavigationServer3D.map_get_iteration_id(map) == 0:
			# The map is not built yet (the first ticks after loading): run directly for now and try again.
			_path_dirty = true
		else:
			_path = NavigationServer3D.map_get_path(map, position, _destination, true, navigation_layers)
	path_changed.emit()


func _advance_waypoints(position: Vector3) -> void:
	while _path_index < _path.size() - 1 and _flat_distance(position, _path[_path_index]) <= waypoint_radius:
		_path_index += 1


func _get_next_point() -> Vector3:
	# An empty path means there is no navigation: run to the point itself. Otherwise run to the next point of the path;
	# the path ends at the closest reachable point.
	return _destination if _path.is_empty() else _path[_path_index]


## How far to run to the end of the path: to the next point and then along the segments.
func _get_distance_left(position: Vector3, next_point: Vector3) -> float:
	var distance := _flat_distance(position, next_point)
	for i in range(_path_index, _path.size() - 1):
		distance += _flat_distance(_path[i], _path[i + 1])
	return distance


func _is_off_path(position: Vector3) -> bool:
	if _path_index == 0:
		return false
	var from := _flat(_path[_path_index - 1])
	var to := _flat(_path[_path_index])
	var flat_position := _flat(position)
	var closest := Geometry3D.get_closest_point_to_segment(flat_position, from, to)
	return flat_position.distance_to(closest) > max_path_deviation


func _arrive() -> void:
	_clear_destination()
	# The braking profile reaches zero speed exactly at the point; discard what is left over from the discrete step.
	_motion.halt()
	arrived.emit()


func _cancel_destination() -> void:
	if not _has_destination:
		return
	_clear_destination()
	destination_cancelled.emit()


func _clear_destination() -> void:
	_has_destination = false
	_path_dirty = false
	_path.clear()
	_path_index = 0


func _on_navigation_map_changed(map: RID) -> void:
	# The mesh was rebaked or a region was moved: the old path may go through new obstacles.
	if _has_destination and use_navigation and map == _body.get_world_3d().navigation_map:
		_path_dirty = true


static func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
