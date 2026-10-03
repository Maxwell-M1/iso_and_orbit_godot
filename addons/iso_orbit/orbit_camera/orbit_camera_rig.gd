class_name OrbitCameraRig
extends Node3D
## An isometric RPG camera: it hangs above and to the side of the target and follows it.
##
## - Holding the right button and moving the mouse rotates the camera around the target, and with
##   [member mouse_pitch] also changes its pitch. The cursor is hidden meanwhile and then returns to where it was.
## - The wheel lowers the camera closer to the target or raises it higher and farther: the distance and the pitch
##   change together, and below the middle the camera flattens out faster so that what lies ahead is visible
##   ([member flatten_start_zoom]).
## - If [member follow_movement] is on, the camera gradually moves behind the running target on its own, and with
##   [member follow_pitch] it also adjusts the pitch. While the camera is rotated with the mouse, it does not do this.
##
## The node is placed in the scene next to the target, not inside it. Its child is a [CameraArm] with a [Camera3D] at
## the end: the node sets the arm length from the zoom, and the arm shortens near obstacles. Without an arm, the child
## must be the [Camera3D] itself, and it is placed directly at that distance. The position updates every frame from
## the interpolated position of the target, so physics interpolation on the camera itself is off: otherwise it would
## smooth what is already smoothed and lag by a tick.

## The node to follow.
@export var target: Node3D

## The arm with the camera at its end: the node sets its length, and the arm places the camera. If not set, the child
## [CameraArm] is used.
@export var arm: CameraArm

## The camera that the node places itself when there is no arm. If not set, the first child [Camera3D] is used.
@export var camera: Camera3D

@export_group("Input")
## The input action that, while held, lets the mouse rotate the camera.
@export var rotate_action := &"camera_rotate"
## The "lower the camera closer" action (wheel up).
@export var zoom_in_action := &"camera_zoom_in"
## The "raise the camera farther" action (wheel down).
@export var zoom_out_action := &"camera_zoom_out"
## How many degrees of rotation one pixel of mouse movement gives.
@export_range(0.01, 2.0, 0.01, "suffix:°/px") var mouse_sensitivity := 0.25
## Change the camera pitch with vertical mouse movement. Without this, the mouse only rotates the camera around the
## target, and the pitch is set by the wheel (zoom). Turning this off returns the camera to the pitch set by the wheel.
@export var mouse_pitch := false:
	set(value):
		mouse_pitch = value
		if not value:
			_target_pitch_offset = 0.0
## Invert the vertical mouse axis (with [member mouse_pitch]).
@export var invert_pitch := false
## How much the zoom changes per wheel notch (the full range is 1).
@export_range(0.01, 0.5, 0.01) var zoom_step := 0.1

@export_group("Framing")
## Where the camera looks: at this height above the target's origin (on a character, roughly the chest).
@export_range(0.0, 5.0, 0.05, "suffix:m") var focus_height := 1.2
## The distance to the target when the camera is lowered all the way.
@export_range(1.0, 50.0, 0.1, "suffix:m") var near_distance := 5.0
## The distance to the target when the camera is raised all the way.
@export_range(1.0, 100.0, 0.1, "suffix:m") var far_distance := 20.0
## The pitch of the lowered camera: all the way down and already from [member flatten_end_zoom] (negative looks down).
@export_range(-89.0, 0.0, 0.1, "radians_as_degrees") var near_pitch := deg_to_rad(-22.0)
## The pitch of the camera when it is raised all the way.
@export_range(-89.0, 0.0, 0.1, "radians_as_degrees") var far_pitch := deg_to_rad(-55.0)
## Below this zoom, the descending camera flattens out faster: from the pitch here to [member near_pitch] at
## [member flatten_end_zoom], quickly at first and smoothly toward the end. This way, what lies ahead is visible
## already at medium height. Above it, the pitch changes evenly with the zoom, from [member near_pitch] to
## [member far_pitch].
@export_range(0.0, 1.0, 0.01) var flatten_start_zoom := 0.5
## Below this zoom, the camera looks at a shallow angle ([member near_pitch]) and only moves closer.
@export_range(0.0, 1.0, 0.01) var flatten_end_zoom := 0.2
## The pitch limits, including the mouse offset.
@export_range(-89.0, 0.0, 0.1, "radians_as_degrees") var min_pitch := deg_to_rad(-80.0)
@export_range(-89.0, 0.0, 0.1, "radians_as_degrees") var max_pitch := deg_to_rad(-8.0)
## The zoom at start: 0 means the camera is lowered, 1 means it is raised.
@export_range(0.0, 1.0, 0.01) var start_zoom := 0.55
## The rotation of the camera around the target at start.
@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var start_yaw := deg_to_rad(45.0)

@export_group("Follow")
## Turn on its own toward the target's running direction, gradually moving behind it. Does not turn while the camera
## is rotated with the mouse or the follow is paused ([method set_follow_paused]).
@export var follow_movement := false
## While the target runs, gradually bring the camera pitch to [member follow_pitch_angle], at the same rate and in the
## same cases as the follow turn. Works without [member follow_movement] too. The wheel (and the mouse with
## [member mouse_pitch]) changes the pitch as usual, and while running it is adjusted again.
@export var follow_pitch := false
## The pitch to adjust toward (down is negative, -90° is straight from above). The camera does not pitch beyond
## [member min_pitch] and [member max_pitch].
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var follow_pitch_angle := deg_to_rad(-40.0)
## In how many seconds the camera almost finishes turning to follow the run (5% of the angle remains). 0 is instant.
@export_range(0.0, 20.0, 0.05, "or_greater", "suffix:s") var follow_time := 1.5
## Below this speed, the camera does not turn after the target: when standing, starting, or turning around, the
## movement direction is unreliable. From this speed to twice that, the turn smoothly gains strength.
@export_range(0.0, 10.0, 0.05, "suffix:m/s") var follow_min_speed := 1.0

@export_group("Smoothing")
## How fast the camera catches up with mouse rotation. Higher is sharper; 0 means no smoothing.
@export_range(0.0, 100.0, 0.1) var rotation_sharpness := 30.0
## How fast the camera catches up with the wheel zoom.
@export_range(0.0, 100.0, 0.1) var zoom_sharpness := 10.0

var _yaw := 0.0
var _target_yaw := 0.0
var _pitch_offset := 0.0
var _target_pitch_offset := 0.0
var _zoom := 0.0
var _target_zoom := 0.0
var _mouse_motion := Vector2.ZERO
var _rotating := false
var _cursor_before_rotate := Vector2.ZERO
var _follow_paused := false
var _target_velocity := Vector3.ZERO
var _last_target_position := Vector3.ZERO
var _has_target_position := false


func _ready() -> void:
	# Move in _process along the already interpolated target (see the class description); children inherit the mode.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if arm == null:
		arm = _find_child(func(child: Node) -> bool: return child is CameraArm) as CameraArm
	if arm == null and camera == null:
		camera = _find_child(func(child: Node) -> bool: return child is Camera3D) as Camera3D
	assert(arm != null or camera != null, "OrbitCameraRig needs a CameraArm or Camera3D child, or the arm property set.")
	for action: StringName in [rotate_action, zoom_in_action, zoom_out_action]:
		if not InputMap.has_action(action):
			push_error("OrbitCameraRig: input action \"%s\" is missing in Project Settings > Input Map." % action)
	_yaw = start_yaw
	_target_yaw = start_yaw
	_zoom = start_zoom
	_target_zoom = start_zoom
	_apply_transform()
	if arm != null:
		arm.snap()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(rotate_action):
		_begin_rotate()
	elif event.is_action_released(rotate_action):
		_end_rotate()
	elif event is InputEventMouseMotion and _rotating:
		# Accumulate: several events can arrive per frame; they are applied at once in _process.
		_mouse_motion += (event as InputEventMouseMotion).screen_relative
	elif event.is_action_pressed(zoom_in_action):
		_add_zoom(-zoom_step * _get_wheel_factor(event))
	elif event.is_action_pressed(zoom_out_action):
		_add_zoom(zoom_step * _get_wheel_factor(event))
	else:
		return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# The window lost focus or the game was paused (a menu opened) in the middle of rotating: the button release may
	# not reach the node, and the cursor must not be left captured.
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PAUSED) and _rotating:
		_end_rotate()


func _physics_process(delta: float) -> void:
	_track_target_motion(delta)


func _process(delta: float) -> void:
	_apply_mouse_motion()
	_follow_movement(delta)
	_yaw = _smooth(_yaw, _target_yaw, rotation_sharpness, delta)
	_pitch_offset = _smooth(_pitch_offset, _target_pitch_offset, rotation_sharpness, delta)
	_zoom = _smooth(_zoom, _target_zoom, zoom_sharpness, delta)
	_apply_transform()


## Turn the camera so that it looks along [param direction] (its horizontal part), without smoothing.
func look_along(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).is_zero_approx():
		return
	_target_yaw = atan2(-direction.x, -direction.z)
	_yaw = _target_yaw


## Snap into place instantly, for example after the target teleports or [member target] changes.
func snap() -> void:
	_yaw = _target_yaw
	_pitch_offset = _target_pitch_offset
	_zoom = _target_zoom
	# A jump of the target is not running: do not turn toward it.
	_has_target_position = false
	_target_velocity = Vector3.ZERO
	_apply_transform()
	if arm != null:
		arm.snap()


## The camera is being rotated with the mouse right now (the cursor is captured).
func is_rotating() -> bool:
	return _rotating


## Pause or resume the follow turn and the pitch adjustment ([member follow_movement], [member follow_pitch]). For
## example, while it is not yet clear whether this is a click or a hold of the mouse button
## ([signal PointClickMoveInput.hold_pending_changed]).
func set_follow_paused(paused: bool) -> void:
	_follow_paused = paused


func is_follow_paused() -> bool:
	return _follow_paused


func _begin_rotate() -> void:
	_rotating = true
	_mouse_motion = Vector2.ZERO
	_cursor_before_rotate = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _end_rotate() -> void:
	if not _rotating:
		return
	_rotating = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# On capture, the cursor moves to the center of the window; return it to where it was.
	get_viewport().warp_mouse(_cursor_before_rotate)


func _apply_mouse_motion() -> void:
	if _mouse_motion == Vector2.ZERO:
		return
	var radians_per_pixel := deg_to_rad(mouse_sensitivity)
	# Mouse to the right: the view turns right, so the camera moves clockwise (seen from above).
	_target_yaw -= _mouse_motion.x * radians_per_pixel
	if mouse_pitch:
		# Mouse up: the camera lowers and looks at a shallower angle.
		var pitch_direction := 1.0 if invert_pitch else -1.0
		_target_pitch_offset += pitch_direction * _mouse_motion.y * radians_per_pixel
		var base_pitch := _get_base_pitch(_target_zoom)
		_target_pitch_offset = clampf(_target_pitch_offset, min_pitch - base_pitch, max_pitch - base_pitch)
	_mouse_motion = Vector2.ZERO


## The target velocity, from its displacement per physics tick, so any [Node3D] works, not only a [CharacterBody3D].
func _track_target_motion(delta: float) -> void:
	if target == null or delta <= 0.0:
		_has_target_position = false
		_target_velocity = Vector3.ZERO
		return
	var target_position := target.global_position
	if _has_target_position:
		_target_velocity = (target_position - _last_target_position) / delta
	_last_target_position = target_position
	_has_target_position = true


func _follow_movement(delta: float) -> void:
	if not (follow_movement or follow_pitch) or _rotating or _follow_paused:
		return
	var strength := _get_follow_strength()
	if strength <= 0.0:
		return
	# exp(-3) ≈ 0.05: after follow_time, 5% of the angle remains, whatever the FPS.
	var share := 1.0 if follow_time <= 0.0 else 1.0 - exp(-3.0 * strength * delta / follow_time)
	if follow_movement:
		var movement_yaw := atan2(-_target_velocity.x, -_target_velocity.z)
		_target_yaw += angle_difference(_target_yaw, movement_yaw) * share
	if follow_pitch:
		# The pitch is the zoom pitch plus an offset; adjust the offset.
		var wanted_offset := clampf(follow_pitch_angle, min_pitch, max_pitch) - _get_base_pitch(_target_zoom)
		_target_pitch_offset = lerpf(_target_pitch_offset, wanted_offset, share)


## 0: the target stands or barely moves; 1: it runs. In between, the follow turn smoothly gains strength.
func _get_follow_strength() -> float:
	var speed := Vector2(_target_velocity.x, _target_velocity.z).length()
	if follow_min_speed <= 0.0:
		return 1.0 if speed > 0.01 else 0.0
	return clampf(speed / follow_min_speed - 1.0, 0.0, 1.0)


func _add_zoom(amount: float) -> void:
	_target_zoom = clampf(_target_zoom + amount, 0.0, 1.0)
	# The mouse pitch offset must not take the camera beyond the limits at the new zoom.
	var base_pitch := _get_base_pitch(_target_zoom)
	_target_pitch_offset = clampf(_target_pitch_offset, min_pitch - base_pitch, max_pitch - base_pitch)


func _apply_transform() -> void:
	if target != null:
		var focus := target.get_global_transform_interpolated().origin + Vector3.UP * focus_height
		global_position = focus
	var pitch := clampf(_get_base_pitch(_zoom) + _pitch_offset, min_pitch, max_pitch)
	# The default Node3D rotation order is YXZ: pitch first, then rotation around the vertical.
	rotation = Vector3(pitch, _yaw, 0.0)
	var distance := lerpf(near_distance, far_distance, _zoom)
	if arm != null:
		# The arm is a child of the node and updates after it in the same frame.
		arm.length = distance
	else:
		camera.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, distance))


## The pitch for the zoom [param zoom], without the mouse offset and the adjustment.
func _get_base_pitch(zoom: float) -> float:
	if zoom >= flatten_start_zoom or flatten_start_zoom <= flatten_end_zoom:
		return lerpf(near_pitch, far_pitch, zoom)
	# The share squared: right below flatten_start_zoom the camera flattens out quickly, and it approaches near_pitch
	# smoothly.
	var share := clampf(inverse_lerp(flatten_end_zoom, flatten_start_zoom, zoom), 0.0, 1.0)
	return lerpf(near_pitch, lerpf(near_pitch, far_pitch, flatten_start_zoom), share * share)


func _find_child(is_wanted: Callable) -> Node:
	for child: Node in get_children():
		if is_wanted.call(child):
			return child
	return null


static func _get_wheel_factor(event: InputEvent) -> float:
	# On touchpads and mice with smooth scrolling, the event carries a fraction of a notch.
	var button := event as InputEventMouseButton
	if button != null and button.factor > 0.0:
		return button.factor
	return 1.0


## Exponential smoothing that is the same at any FPS.
static func _smooth(from: float, to: float, sharpness: float, delta: float) -> float:
	if sharpness <= 0.0:
		return to
	return lerpf(from, to, 1.0 - exp(-sharpness * delta))
