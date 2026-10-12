@tool
class_name PatrolController
extends Node
## Walks a character (a [CharacterBody3D] with a [NavigationMover]) along a route drawn in the level: a [Path3D], along
## the line the editor draws for its curve. The controller only leads the mover: the character's own script still
## computes the velocity and moves the body. Along the line the character steers at a point that slides ahead of it
## ([member look_ahead]), without pathfinding, so draw the line where the character fits; navigation leads it from
## where the patrol starts to the line and back.
##
## The route belongs to the level, not to the character: draw a [Path3D] on walkable ground outside the character and
## assign it to [member route]; several patrols can share one. A copy of the character with another route is another
## patrol. When a patrol starts ([method restart]), points are taken on the drawn line every [member sample_spacing]:
## the same line a [PathFollow3D] follows, shaped by the curve's points, their handles and its Bake Interval, so the
## character walks the route as the editor shows it. No [PathFollow3D] moves the body. A script can give the points
## itself instead ([method set_route_points]).
##
## After the last point the character can come back to where it started ([member return_to_start]), wait
## ([member cycle_wait]) and go again ([member repeat]). A character in front of it stops it: one in an area like the
## beam of a flashlight, up to [member blocking_distance] ahead and widening by [member blocking_angle] to each side,
## not one at the side or behind. The patrol waits for the same point instead of skipping it and, after
## [member blocked_delay], reports [signal blocked_long_enough]; what that means (a line of dialogue, for example) is up
## to the game. To be stopped by other characters, the body's collision mask must include their layer. With navigation
## on ([member NavigationMover.use_navigation]), a patrol waits for the navigation map before it starts.

## One round of the route is done: the character is back at the start (with [member return_to_start]) or at the last
## point.
signal cycle_completed
## [param blocker] has stood in the way for [member blocked_delay] seconds without a break. Once per stop.
signal blocked_long_enough(blocker: CharacterBody3D)

## What the patrol is doing: standing without a route or turned off, waiting for the navigation map, walking, stopped
## by a character in the way, or waiting at a point or after a round.
enum State { IDLE, WAITING_FOR_NAVIGATION, MOVING, BLOCKED, WAITING }

# How finely the drawn line is traced before the points are taken on it, in the curve's own units (_sample_line).
const LINE_STEP := 0.05

## The character to walk. If not set, the parent, when it is a [CharacterBody3D].
@export var character: CharacterBody3D:
	set(value):
		character = value
		_watch_body()
		update_configuration_warnings()
## The character's [NavigationMover], its direct child. If not set, the character's first [NavigationMover] child.
@export var mover: NavigationMover:
	set(value):
		mover = value
		update_configuration_warnings()
## The route: a [Path3D] of the level, drawn with the editor's curve tools. The character walks the line the editor
## draws for it. Several patrols can share one. A change takes effect at the next [method restart].
@export var route: Path3D
## The longest step between the points taken on the route's line: shorter ones follow its bends more closely and keep
## the turns smoother.
@export_range(0.1, 4.0, 0.05, "suffix:m") var sample_spacing := 0.25
## How far ahead the character aims while it walks the route's line: at the point of the line this far from it. The
## point slides along the line, so the character turns smoothly through the bends instead of from point to point; a
## longer distance turns more gently and cuts the bends more. The points to stop at are reached exactly.
@export_range(0.25, 4.0, 0.05, "suffix:m") var look_ahead := 0.75
## Walk the route. Turned off, the character stops where it is; turned on, a new patrol starts from there.
@export var enabled := true:
	set(value):
		if enabled == value:
			return
		enabled = value
		if is_node_ready() and not Engine.is_editor_hint():
			if enabled:
				restart()
			else:
				_halt()
## Go again after [member cycle_wait] once a round is done. Off: the patrol stops after one round.
@export var repeat := true
## After the last point, come back to where the patrol started.
@export var return_to_start := true
## How long to wait at the start after a round, in game time: a paused game pauses the wait too.
@export_range(0.0, 120.0, 0.1, "suffix:s") var cycle_wait := 10.0
## How long to stop at each control point of the curve before going on. The points sampled between them have no stop.
@export_range(0.0, 30.0, 0.1, "suffix:s") var waypoint_wait := 0.0
## How long a character must stand in the way, without a break, before [signal blocked_long_enough].
@export_range(0.0, 60.0, 0.1, "suffix:s") var blocked_delay := 6.0
## How far in front of the body another character stops it, from the front of the body's collision shape. Only in
## front, where the character faces: one at the side or behind does not stop it.
@export_range(0.05, 5.0, 0.05, "suffix:m") var blocking_distance := 1.0
## How much the area in front widens to each side, as an angle from where the character faces: like the beam of a
## flashlight, as wide as the body at its front and wider farther out. 0: as wide as the body all along.
@export_range(0.0, 60.0, 0.1, "radians_as_degrees") var blocking_angle := deg_to_rad(25.0)

var _state := State.IDLE
var _points := PackedVector3Array()
var _pause_points := PackedByteArray()
var _script_points := PackedVector3Array()
var _home := Vector3.ZERO
var _index := 0
var _cycles := 0
var _arrived := false
var _wait_left := 0.0
var _cycle_finished := false
var _blocked_time := 0.0
var _block_reported := false
# The query for the area in front (_find_blocker); its shape is built again when the area's settings change.
var _beam_query := PhysicsShapeQueryParameters3D.new()
var _beam_size := Vector2(-1.0, -1.0)
# In the editor: the body whose children the warning reads (_watch_body).
var _watched_body: Node


func _init() -> void:
	# Decide whether to stop or move before the body computes this tick's velocity.
	# Only in the game: in the editor the value would be saved into the scene.
	if not Engine.is_editor_hint():
		process_physics_priority = -2


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if character == null:
		character = get_parent() as CharacterBody3D
	if mover == null and character != null:
		mover = _find_mover(character)
	assert(character != null and mover != null and mover.get_parent() == character,
			"PatrolController needs a CharacterBody3D with its NavigationMover as a direct child.")
	mover.arrived.connect(_on_arrived)
	if enabled:
		# Other children may become ready after this controller, including the character's mover.
		_start_if_enabled.call_deferred()


func _start_if_enabled() -> void:
	if enabled:
		restart()


## Use a script-defined route in world coordinates. Each supplied position is an optional pause point.
## Clears the Path3D assignment and starts immediately if ready and enabled. The input array is copied.
func set_route_points(points: PackedVector3Array) -> void:
	route = null
	_script_points = points.duplicate()
	if is_node_ready() and enabled:
		restart()


## Start a new patrol at the body's current position. Capture the current curve shape and its world transform.
## Without a route, the controller stays idle: an unconfigured character can safely be placed in a level.
func restart() -> void:
	mover.halt()
	_points.clear()
	_pause_points.clear()
	if is_instance_valid(route):
		_read_curve()
	else:
		_points = _script_points.duplicate()
		_pause_points.resize(_points.size())
		_pause_points.fill(1)
	_home = character.global_position
	_index = 0
	_arrived = false
	_wait_left = 0.0
	_cycle_finished = false
	_reset_block()
	if _points.is_empty():
		_state = State.IDLE
		return
	_state = State.WAITING_FOR_NAVIGATION


func _read_curve() -> void:
	var curve := route.curve
	if curve == null or curve.point_count == 0:
		return
	var to_world := route.global_transform
	_points.append(to_world * curve.get_point_position(0))
	_pause_points.append(1)
	if curve.point_count < 2:
		return
	# The line the editor draws, and PathFollow3D follows: the curve's baked points joined smoothly
	# (sample_baked with cubic on). With a long Bake Interval it rounds the corners that the handles leave sharp.
	# The control points are baked points themselves, in order: found one after another, they stay the pause
	# points even on a crossing or looping curve. The offsets are measured the way Curve3D measures them.
	var baked := curve.get_baked_points()
	var offsets := PackedFloat32Array()
	offsets.resize(baked.size())
	for index in range(1, baked.size()):
		offsets[index] = offsets[index - 1] + baked[index - 1].distance_to(baked[index])
	var segments := curve.point_count if curve.closed else curve.point_count - 1
	var first := 0
	for segment in segments:
		var anchor := (segment + 1) % curve.point_count
		var last := first + 1
		while last < baked.size() - 1 and baked[last] != curve.get_point_position(anchor):
			last += 1
		_sample_line(curve, to_world, offsets[first], offsets[last], to_world * curve.get_point_position(anchor))
		first = last


# Adds the points between two control points: the drawn line between their offsets, traced every LINE_STEP and taken
# in world space every sample_spacing at most, so a moved, turned or scaled route keeps the same density. The control
# point at the end is added exactly.
func _sample_line(curve: Curve3D, to_world: Transform3D, from: float, to: float, end: Vector3) -> void:
	var line := PackedVector3Array([_points[-1]])
	var traced := maxi(1, ceili((to - from) / LINE_STEP))
	for step in range(1, traced):
		line.append(to_world * curve.sample_baked(lerpf(from, to, float(step) / traced), true))
	line.append(end)
	var lengths := PackedFloat32Array([0.0])
	for index in range(1, line.size()):
		lengths.append(lengths[-1] + line[index - 1].distance_to(line[index]))
	var steps := maxi(1, ceili(lengths[-1] / maxf(sample_spacing, 0.05)))
	var along := 1
	for step in range(1, steps):
		var distance := lengths[-1] * step / steps
		while lengths[along] < distance:
			along += 1
		var weight := inverse_lerp(lengths[along - 1], lengths[along], distance)
		_points.append(line[along - 1].lerp(line[along], weight))
		_pause_points.append(0)
	_points.append(end)
	_pause_points.append(1)


## Stop instantly and disable the patrol. Setting enabled to true starts it again.
func stop() -> void:
	enabled = false
	_halt()


func _halt() -> void:
	mover.halt()
	_state = State.IDLE
	_arrived = false
	_reset_block()


## What the patrol is doing now.
func get_state() -> State:
	return _state


## The number of the point the character walks to now, among the points sampled from the route (0 is its start).
func get_waypoint_index() -> int:
	return _index


## Completed patrols since this controller entered the scene; restarting does not clear this counter.
func get_completed_cycles() -> int:
	return _cycles


## How long a character has stood in the way without a break, s; 0 while the patrol is not blocked.
func get_blocked_time() -> float:
	return _blocked_time


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not enabled:
		if _state != State.IDLE:
			stop()
		return
	if delta <= 0.0 or _state == State.IDLE:
		return
	if _state == State.WAITING_FOR_NAVIGATION:
		if mover.use_navigation:
			var map := character.get_world_3d().navigation_map
			if NavigationServer3D.map_get_iteration_id(map) == 0:
				return
		_move_to_current()
		return
	if _state == State.WAITING:
		_wait_left = maxf(0.0, _wait_left - delta)
		if _wait_left <= 0.0:
			if _cycle_finished:
				_index = 0
				_cycle_finished = false
			_move_to_current()
		return
	if _arrived:
		_arrived = false
		var pause := waypoint_wait if _index < _pause_points.size() and _pause_points[_index] else 0.0
		_index += 1
		if _index >= _points.size() + int(return_to_start):
			_cycles += 1
			cycle_completed.emit()
			if not enabled:
				return
			if not repeat:
				stop()
				return
			_cycle_finished = true
			_wait(cycle_wait)
		else:
			_wait(pause)
		return
	if _state == State.MOVING:
		_lead()
	var blocker := _find_blocker()
	if blocker != null:
		if _state != State.BLOCKED:
			mover.halt()
			_state = State.BLOCKED
		_blocked_time += delta
		if not _block_reported and _blocked_time >= blocked_delay:
			_block_reported = true
			blocked_long_enough.emit(blocker)
	elif _state == State.BLOCKED:
		_reset_block()
		_move_to_current()


func _move_to_current() -> void:
	_state = State.MOVING
	_lead()


# Leads the mover, every tick of the walk. From where the patrol started to the route's first point, and after the
# last point back there, navigation finds the way. Along the route the character steers straight at the point of the
# line ahead that is look_ahead away from it (_aim): the direction changes a little every tick, so the character turns
# smoothly through the bends and keeps to the line as drawn. Once the next point to stop at is that near, the mover is
# sent there to brake and arrive exactly.
func _lead() -> void:
	var position := character.global_position
	if _index == 0 and waypoint_wait <= 0.0 and _points.size() > 1 \
			and Vector2(position.x - _points[0].x, position.z - _points[0].z).length() <= look_ahead:
		_index = 1
	if _index == 0 or _index >= _points.size():
		mover.move_to(_home if _index == _points.size() else _points[0])
		return
	var stop := _points.size() - 1
	if waypoint_wait > 0.0:
		stop = _index
		while stop < _points.size() - 1 and not _pause_points[stop]:
			stop += 1
	_advance(position, stop)
	var aim := _aim(position, stop)
	if aim == _points[stop]:
		mover.move_to(aim)
	else:
		mover.steer(aim - position)


# Moves _index on to the segment nearest to the character among its own and the next ones within look_ahead along the
# line: cutting a bend a little, the character comes nearer to the next segments before it passes the end of its own.
func _advance(position: Vector3, stop: int) -> void:
	var nearest := _distance_to_segment(position, _index)
	var along := 0.0
	var next := _index + 1
	while next <= stop and along <= look_ahead:
		along += _points[next - 1].distance_to(_points[next])
		var distance := _distance_to_segment(position, next)
		if distance < nearest:
			nearest = distance
			_index = next
		next += 1


# Distance seen from above to the segment from point index - 1 to point index.
func _distance_to_segment(position: Vector3, index: int) -> float:
	var flat := Vector2(position.x, position.z)
	return flat.distance_to(Geometry2D.get_closest_point_to_segment(flat, Vector2(_points[index - 1].x,
			_points[index - 1].z), Vector2(_points[index].x, _points[index].z)))


# Where the line, followed on from the character's place on its segment, first gets look_ahead away from the character
# (seen from above): it moves on smoothly as the character walks, also when the character takes the next segment. The
# point stop if the line ends nearer; the nearest point of the line ahead if the character is farther than look_ahead.
func _aim(position: Vector3, stop: int) -> Vector3:
	var flat := Vector2(position.x, position.z)
	var from := Geometry3D.get_closest_point_to_segment(position, _points[_index - 1], _points[_index])
	for next in range(_index, stop + 1):
		var to := _points[next]
		var start := Vector2(from.x - flat.x, from.z - flat.y)
		var end := Vector2(to.x - flat.x, to.z - flat.y)
		if end.length() >= look_ahead:
			# The farther root of |start + (end - start)·t| = look_ahead: where the segment leaves the circle.
			var along := end - start
			var a := along.length_squared()
			var b := 2.0 * start.dot(along)
			var c := start.length_squared() - look_ahead * look_ahead
			var t := 1.0 if a <= 0.0 else clampf((-b + sqrt(maxf(b * b - 4.0 * a * c, 0.0))) / (2.0 * a), 0.0, 1.0)
			return from.lerp(to, t)
		from = to
	return _points[stop]


func _wait(duration: float) -> void:
	_state = State.WAITING
	_wait_left = duration
	_reset_block()


func _on_arrived() -> void:
	if _state == State.MOVING:
		_arrived = true


# Another character in the area in front of the body, where it faces: from the front of the body to
# blocking_distance farther, widening by blocking_angle to each side, as high as the body. Ones at the side or behind
# are outside it.
func _find_blocker() -> CharacterBody3D:
	var facing := mover.get_facing()
	if facing.is_zero_approx():
		return null
	if _beam_size != Vector2(blocking_distance, blocking_angle):
		_beam_size = Vector2(blocking_distance, blocking_angle)
		_beam_query.shape = _beam_shape()
	_beam_query.transform = Transform3D(Basis.looking_at(facing, Vector3.UP, true), character.global_position)
	_beam_query.collision_mask = character.collision_mask
	_beam_query.exclude = [character.get_rid()]
	for hit: Dictionary in character.get_world_3d().direct_space_state.intersect_shape(_beam_query, 8):
		var other := hit.collider as CharacterBody3D
		if other != null:
			return other
	return null


# The area in front, in a space where the body stands at the origin and faces +Z: a slab from the front of the body's
# collision shapes, as wide as they are, to blocking_distance farther, where each side has spread by blocking_angle.
func _beam_shape() -> ConvexPolygonShape3D:
	var bounds := AABB()
	for owner_id in character.get_shape_owners():
		var owner_transform := character.shape_owner_get_transform(owner_id)
		for index in character.shape_owner_get_shape_count(owner_id):
			var box := owner_transform * character.shape_owner_get_shape(owner_id, index).get_debug_mesh().get_aabb()
			bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
	var radius := maxf(bounds.size.x, bounds.size.z) * 0.5
	var reach := radius + blocking_distance
	var spread := radius + blocking_distance * tan(blocking_angle)
	var points := PackedVector3Array()
	for height: float in [bounds.position.y, bounds.end.y]:
		points.append_array([Vector3(-radius, height, radius), Vector3(radius, height, radius),
				Vector3(-spread, height, reach), Vector3(spread, height, reach)])
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	return shape


func _reset_block() -> void:
	_blocked_time = 0.0
	_block_reported = false


static func _find_mover(body: Node) -> NavigationMover:
	for child: Node in body.get_children():
		if child is NavigationMover:
			return child
	return null


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_PARENTED:
		_watch_body()
	elif what == NOTIFICATION_UNPARENTED:
		# The old parent is still set here; out of the tree there is no warning to show.
		_watch(null)


# The warning reads the body's children, the controller's siblings. The Scene dock rechecks a node when its own
# children change, not its siblings, so in the editor the controller listens to the body itself.
func _watch_body() -> void:
	if Engine.is_editor_hint():
		_watch(character if character != null else get_parent() as CharacterBody3D)


func _watch(body: Node) -> void:
	if body == _watched_body:
		return
	var callback := update_configuration_warnings
	if is_instance_valid(_watched_body) and _watched_body.child_order_changed.is_connected(callback):
		_watched_body.child_order_changed.disconnect(callback)
	_watched_body = body
	if body != null:
		body.child_order_changed.connect(callback)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var body := character if character != null else get_parent() as CharacterBody3D
	if body == null:
		warnings.append("Assign Character or place the controller under a CharacterBody3D.")
		return warnings
	var driver := mover if mover != null else _find_mover(body)
	if driver == null or driver.get_parent() != body:
		warnings.append("The character needs its own NavigationMover as a direct child.")
	return warnings
