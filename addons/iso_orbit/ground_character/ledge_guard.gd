class_name LedgeGuard
extends Node
## Keeps the character from walking off a cliff: at the edge it stops, and if it runs at the edge at an angle, it
## slides along it, just as along a wall. Small steps (lower than [member max_drop]) can be stepped off.
##
## The component is added as a child of a [CharacterBody3D]. The body calls [method constrain] every tick before
## [method CharacterBody3D.move_and_slide]; in the air, or when disabled, the component does not change the velocity.
##
## The ground is checked with rays cast down at the point the body reaches within the tick and on a circle of radius
## [member edge_margin] around it. If there is no ground there, the movement is turned along the edge until ground is
## found, and is shortened by the cosine of the turn, as when sliding along a wall. Running straight into the edge
## means stopping.
##
## Ground is what the body can stand on: not steeper than [member CharacterBody3D.floor_max_angle] (with the margin
## [constant GroundCharacter.FLOOR_ANGLE_MARGIN], as the engine's own floor check). A mistake in the setup is printed
## as a warning when the component enters the tree ([method get_setup_warnings]).

## Guard the edge. A disabled component changes nothing.
@export var enabled := true

## The height drop from which an edge counts as a cliff. A lower one is a step, which can be stepped off.
@export_range(0.05, 10.0, 0.05, "suffix:m") var max_drop := 0.5

## The character's center does not come closer to the edge than this. A larger value makes it stop farther from the
## edge.
@export_range(0.0, 1.0, 0.01, "suffix:m") var edge_margin := 0.15

## How many rays on the [member edge_margin] circle check the ground. More rays make the margin on slanted edges more
## accurate.
@export_range(3, 16) var margin_probes := 6

## The height above the feet to cast the ray from: this way it also finds ground slightly above the feet (a ramp, a
## step up).
@export_range(0.0, 2.0, 0.01, "suffix:m") var probe_height := 0.5

## What counts as ground. 0 (the default) takes the body's [member CollisionObject3D.collision_mask]: the guard counts
## as ground exactly what the body stands on.
@export_flags_3d_physics var floor_mask := 0

## How many times to refine the slide angle, twice as finely each time (6 gives a precision of about 1.4°).
@export_range(1, 12) var slide_iterations := 6

var _body: CharacterBody3D
var _query := PhysicsRayQueryParameters3D.new()


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	assert(_body != null, "LedgeGuard must be a child of a CharacterBody3D.")
	_query.exclude = [_body.get_rid()]
	for warning in get_setup_warnings():
		push_warning("%s: %s" % [name, warning])


## Problems in how the guard is set up, one line each; empty if there are none.
func get_setup_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var body := get_parent() as CharacterBody3D
	if body == null:
		warnings.append("LedgeGuard must be a child of a CharacterBody3D.")
	elif floor_mask & ~body.collision_mask != 0:
		warnings.append("floor_mask has layers the body does not collide with: the guard counts as ground something "
				+ "the body falls through. 0 takes the body's mask.")
	return warnings


## The velocity corrected near a cliff: the horizontal part changes, the vertical part stays as is.
func constrain(velocity: Vector3, delta: float) -> Vector3:
	if not enabled or delta <= 0.0 or not _body.is_on_floor():
		return velocity
	var move := Vector3(velocity.x, 0.0, velocity.z) * delta
	var length := move.length()
	if length < 0.0001:
		return velocity
	var feet := _body.global_position
	if _is_safe(feet + move, edge_margin):
		return velocity
	# If the character is already closer to the edge than the margin (it spawned or landed there), do not require the
	# margin: otherwise it would have nowhere to step, even away from the edge.
	var margin := edge_margin if _is_safe(feet, edge_margin) else 0.0
	if margin == 0.0 and _is_safe(feet + move, 0.0):
		return velocity
	var direction := move / length

	# Turn the movement along the edge both ways and take the smaller turn. The closer to a right angle, the shorter
	# the step (cos), and a right angle means standing still: sliding along a wall behaves the same way.
	var best_angle := PI / 2.0
	var best_side := 0.0
	for side: float in [-1.0, 1.0]:
		var angle := _find_slide_angle(feet, direction, length, side, margin)
		if angle < best_angle:
			best_angle = angle
			best_side = side
	if best_side == 0.0:
		return Vector3(0.0, velocity.y, 0.0)
	var slide := direction.rotated(Vector3.UP, best_side * best_angle) * cos(best_angle) * (length / delta)
	return Vector3(slide.x, velocity.y, slide.z)


## The smallest turn of the movement toward [param side] at which there is still ground underfoot.
## On a straight edge, the overshoot past the edge only decreases as the angle grows, so the angle is found by
## bisection.
func _find_slide_angle(feet: Vector3, direction: Vector3, length: float, side: float, margin: float) -> float:
	var low := 0.0
	var high := PI / 2.0
	for i in slide_iterations:
		var angle := (low + high) / 2.0
		if _is_safe(feet + direction.rotated(Vector3.UP, side * angle) * length * cos(angle), margin):
			high = angle
		else:
			low = angle
	return high


## Whether there is ground at [param point] and on a circle of radius [param margin] around it.
func _is_safe(point: Vector3, margin: float) -> bool:
	if not _has_floor(point):
		return false
	if margin <= 0.0:
		return true
	for i in margin_probes:
		if not _has_floor(point + Vector3.FORWARD.rotated(Vector3.UP, TAU * i / margin_probes) * margin):
			return false
	return true


## Whether there is ground under [param point] no more than [member max_drop] below the feet.
func _has_floor(point: Vector3) -> bool:
	var feet := _body.global_position.y
	_query.from = Vector3(point.x, feet + probe_height, point.z)
	_query.to = Vector3(point.x, feet - max_drop, point.z)
	_query.collision_mask = floor_mask if floor_mask != 0 else _body.collision_mask
	var hit := _body.get_world_3d().direct_space_state.intersect_ray(_query)
	if hit.is_empty():
		return false
	# A steep slope is not ground: the character cannot stand on it.
	var steepness := (hit.normal as Vector3).angle_to(_body.up_direction)
	return steepness <= _body.floor_max_angle + GroundCharacter.FLOOR_ANGLE_MARGIN
