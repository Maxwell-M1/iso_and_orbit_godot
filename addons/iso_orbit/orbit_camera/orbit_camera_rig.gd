class_name OrbitCameraRig
extends Node3D
## An isometric RPG camera: it hangs above and to the side of the target and follows it.
##
## - Holding the right button and moving the mouse rotates the camera around the target, and with
##   [member mouse_pitch] also changes its pitch. The cursor is hidden meanwhile and then returns to where it was.
## - The wheel lowers the camera closer to the target or raises it higher and farther: the distance and the pitch
##   change together, and below the middle the camera flattens out faster so that what lies ahead is visible
##   ([member flatten_start_zoom]).
## - The follow: while the target runs, the camera on its own turns behind it ([member follow_movement]), brings its
##   pitch to [member follow_pitch_angle] ([member follow_pitch]) and its height (the zoom) to
##   [member follow_zoom_level] ([member follow_zoom]), each in its own time. Every one of these moves starts and ends
##   smoothly, the turn is never faster than [member follow_max_turn_speed], and a run that comes at the camera within
##   [member follow_toward_camera_angle] of straight does not turn it. While the camera is rotated with the mouse, it
##   does not follow, and afterwards it waits until the target stops or a new run starts
##   ([member follow_wait_after_rotate]).
##
## The node is placed in the scene next to the target, not inside it. Its child is a [CameraArm] with a [Camera3D] at
## the end: the node sets the arm length from the zoom, and the arm shortens near obstacles. Without an arm, the child
## must be the [Camera3D] itself, and it is placed directly at that distance. The position updates every frame from
## the interpolated position of the target, so physics interpolation on the camera itself is off: otherwise it would
## smooth what is already smoothed and lag by a tick. The height can follow the target smoothly
## ([member height_follow_time]): on stairs the camera glides instead of jerking up with every stair.

# The direction of the target's run is smoothed over about this time, s: on stairs the body is put onto every stair at
# once, and the direction would shake the camera.
const _HEADING_SMOOTHING := 0.1
# (1 + x)·exp(−x) = 0.05 at x ≈ 4.74: a critically damped spring at rest settles 95% of the way in 4.74 / ω seconds.
const _SETTLE := 4.74
# A press of the rotate button shorter than this, s, during which the mouse moved less than _TAP_MOTION, px, is a tap:
# the camera was not rotated, and the follow does not wait after it (follow_wait_after_rotate).
const _TAP_TIME := 0.2
const _TAP_MOTION := 2.0


## One move of the follow (the turn, the pitch or the height) on a critically damped spring: it starts from rest,
## speeds up, slows down and stops at its goal without going past it.
class _FollowSpring:
	## How fast the followed value moves now, per second.
	var speed := 0.0

	## One frame. The goal is [param error] away; at full pull the spring settles 95% of the way there in
	## [param time] seconds from rest. It pulls with the share [param pull] of its stiffness. [param running] (0 to 1)
	## blends its damping from [param brake] (how fast a move brakes when the target stops or the follow is paused,
	## 1/s; INF stops it at once) to that of the running spring. The speed stays within [param max_speed] (0: no
	## limit). Returns how far the value moves. The spring is computed in short steps, so it stays calm at any FPS.
	func step(error: float, time: float, pull: float, running: float, brake: float, max_speed: float,
			delta: float) -> float:
		if delta <= 0.0:
			# A frame of zero length (Engine.time_scale 0) moves nothing, and the speed stays: an instant spring or
			# brake (INF) would give INF · 0 below.
			return 0.0
		var omega := _SETTLE / time if time > 0.0 else INF
		if omega * delta > 6.0:
			# Instant, or so fast that it is the same: straight to the goal, or as far as max_speed lets.
			speed = 0.0
			if pull <= 0.0:
				return 0.0
			return clampf(error, -max_speed * delta, max_speed * delta) if max_speed > 0.0 else error
		var steps := maxi(1, ceili(omega * delta / 0.2))
		var h := delta / steps
		var damping := lerpf(exp(-brake * h), exp(-2.0 * omega * h), running)
		var moved := 0.0
		for i in steps:
			speed = speed * damping + pull * omega * omega * error * h
			if max_speed > 0.0:
				speed = clampf(speed, -max_speed, max_speed)
			moved += speed * h
			error -= speed * h
		return moved

## The node to follow. A new target starts the follow afresh: the jump to it is not a run.
@export var target: Node3D:
	set(value):
		target = value
		_forget_target_motion()

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
## target, and the pitch is set by the wheel (zoom). Turning this off returns the camera to the pitch set by the wheel,
## unless [member follow_pitch] holds the pitch.
@export var mouse_pitch := false:
	set(value):
		mouse_pitch = value
		if not value and not follow_pitch:
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
## is rotated with the mouse, after that until the target stops or runs anew ([member follow_wait_after_rotate]), and
## while the follow is paused ([method set_follow_paused]).
@export var follow_movement := false
## In how many seconds the camera almost finishes a turn behind the run (95% of the angle): the turn starts and ends
## smoothly, without overshooting. 0 is instant.
@export_range(0.0, 20.0, 0.05, "or_greater", "suffix:s") var follow_time := 1.5
## The fastest the camera turns on its own: a long turn goes at this speed in the middle, and an instant one
## ([member follow_time] 0) turns at this speed all the way. 0 is no limit.
@export_range(0.0, 1440.0, 1.0, "radians_as_degrees") var follow_max_turn_speed := 0.0
## A run that comes at the camera straight or within this angle of straight does not turn it: the camera does not whip
## around when the target runs toward it. Within twice the angle the turn gains strength smoothly; a run farther from
## straight at the camera turns it fully. 0 turns it behind any run.
@export_range(0.0, 60.0, 0.5, "radians_as_degrees") var follow_toward_camera_angle := deg_to_rad(30.0)
## A target that moves faster than this between two physics ticks is taken to have been teleported: the jump is not a
## run, and the follow does not turn toward it.
@export_range(1.0, 1000.0, 1.0, "or_greater", "suffix:m/s") var teleport_speed := 50.0
## While the target runs, gradually bring the camera pitch to [member follow_pitch_angle], in
## [member follow_pitch_time], in the same cases as the follow turn. Works without [member follow_movement] too. The
## wheel (and the mouse with [member mouse_pitch]) changes the pitch as usual, and while running it is adjusted again.
## Turning this off returns the camera to the pitch of the wheel, unless [member mouse_pitch] is on.
@export var follow_pitch := false:
	set(value):
		follow_pitch = value
		if not value and not mouse_pitch:
			# Only the follow set the pitch offset: without it, the pitch is the wheel's again.
			_target_pitch_offset = 0.0
## The pitch to adjust toward (down is negative, -90° is straight from above). The camera does not pitch beyond
## [member min_pitch] and [member max_pitch].
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var follow_pitch_angle := deg_to_rad(-40.0)
## In how many seconds the camera almost reaches [member follow_pitch_angle] (95% of the way), smoothly. 0 is instant.
@export_range(0.0, 20.0, 0.05, "or_greater", "suffix:s") var follow_pitch_time := 1.5
## While the target runs, gradually bring the camera height (the zoom: the distance, and the pitch with it unless
## [member follow_pitch] holds the pitch) to [member follow_zoom_level], in [member follow_zoom_time], in the same
## cases as the follow turn. Works without the turn and the pitch too. The wheel changes the height as usual, and while
## running it is adjusted again.
@export var follow_zoom := false
## The height to adjust toward, as the zoom: 0 is the camera lowered all the way, 1 raised all the way.
@export_range(0.0, 1.0, 0.01) var follow_zoom_level := 0.55
## In how many seconds the camera almost reaches [member follow_zoom_level] (95% of the way), smoothly. 0 is instant.
@export_range(0.0, 20.0, 0.05, "or_greater", "suffix:s") var follow_zoom_time := 1.5
## Below this speed, the camera does not follow the target: when standing, starting, or turning around, the movement
## direction is unreliable. From this speed to twice that, the follow smoothly gains strength.
@export_range(0.0, 10.0, 0.05, "suffix:m/s") var follow_min_speed := 1.0
## After the camera has been rotated with the mouse, the follow (the turn, the pitch and the height) waits: the camera
## stays where the mouse left it until the target stops (slows below [member follow_min_speed]) or a new run starts
## ([method end_follow_wait]). This way the camera does not swing around while the target brakes after the button is
## released, nor while it runs on to a clicked point. A short tap of the button that does not turn the camera does
## not count; a teleport, [method snap] and a new [member target] end the wait. Whoever drives the target reports new
## runs; without that the follow waits until the target stops, so for a target that never stops, leave this off. Off:
## the follow resumes as soon as the button is released.
@export var follow_wait_after_rotate := false:
	set(value):
		follow_wait_after_rotate = value
		if not value:
			_follow_waiting = false

@export_group("Smoothing")
## How fast the camera catches up with mouse rotation. Higher is sharper; 0 means no smoothing.
@export_range(0.0, 100.0, 0.1) var rotation_sharpness := 30.0
## How fast the camera catches up with the wheel zoom.
@export_range(0.0, 100.0, 0.1) var zoom_sharpness := 10.0
## In how many seconds the camera almost catches up with the target's height (5% of the change remains). A character
## is put onto every stair at once, and the camera glides up and down a flight instead of following each jerk; it also
## rises and falls a little behind the target in a jump. 0 follows the height exactly.
@export_range(0.0, 2.0, 0.01, "suffix:s") var height_follow_time := 0.0

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
# The follow waits after a mouse rotation (follow_wait_after_rotate); how long the rotate button has been held, s, and
# how far the mouse has moved meanwhile, px.
var _follow_waiting := false
var _rotate_time := 0.0
var _rotate_motion := 0.0
# The target's velocity from its movement per physics tick, and the direction of its run, smoothed
# (_HEADING_SMOOTHING).
var _target_velocity := Vector3.ZERO
var _heading := Vector2.ZERO
var _last_target_position := Vector3.ZERO
var _has_target_position := false
# The three moves of the follow.
var _turn := _FollowSpring.new()
var _pitch_follow := _FollowSpring.new()
var _zoom_follow := _FollowSpring.new()
# The target's height that the camera follows (height_follow_time).
var _follow_height := 0.0
var _has_follow_height := false


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
	if _has_action(rotate_action) and event.is_action_pressed(rotate_action):
		_begin_rotate()
	elif _has_action(rotate_action) and event.is_action_released(rotate_action):
		_end_rotate()
	elif event is InputEventMouseMotion and _rotating:
		# Accumulate: several events can arrive per frame; they are applied at once in _process.
		_mouse_motion += (event as InputEventMouseMotion).screen_relative
		_rotate_motion += (event as InputEventMouseMotion).screen_relative.length()
	elif _has_action(zoom_in_action) and event.is_action_pressed(zoom_in_action):
		_add_zoom(-zoom_step * _get_wheel_factor(event))
	elif _has_action(zoom_out_action) and event.is_action_pressed(zoom_out_action):
		_add_zoom(zoom_step * _get_wheel_factor(event))
	else:
		return
	get_viewport().set_input_as_handled()


## Whether [param action] is set and in the Input Map. A missing action is reported once at the start and then not
## read: the engine would report it again at every event.
static func _has_action(action: StringName) -> bool:
	return action != &"" and InputMap.has_action(action)


func _notification(what: int) -> void:
	# The window lost focus or the game was paused (a menu opened) in the middle of rotating: the button release may
	# not reach the node, and the cursor must not be left captured.
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PAUSED) and _rotating:
		_end_rotate()


func _physics_process(delta: float) -> void:
	_track_target_motion(delta)


func _process(delta: float) -> void:
	if _rotating:
		_rotate_time += delta
	_apply_mouse_motion()
	_follow_movement(delta)
	_yaw = _smooth(_yaw, _target_yaw, rotation_sharpness, delta)
	_pitch_offset = _smooth(_pitch_offset, _target_pitch_offset, rotation_sharpness, delta)
	_zoom = _smooth(_zoom, _target_zoom, zoom_sharpness, delta)
	# The yaw stays within one turn, so that it keeps its precision in a long game; both values move together.
	var wrapped := wrapf(_target_yaw, -PI, PI)
	_yaw += wrapped - _target_yaw
	_target_yaw = wrapped
	_follow_target_height(delta)
	_apply_transform()


## Turn the camera so that it looks along [param direction] (its horizontal part), without smoothing. A follow turn
## under way stops there.
func look_along(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).is_zero_approx():
		return
	_target_yaw = atan2(-direction.x, -direction.z)
	_yaw = _target_yaw
	_turn.speed = 0.0


## Snap into place instantly, for example after the target teleports or [member target] changes.
func snap() -> void:
	_yaw = _target_yaw
	_pitch_offset = _target_pitch_offset
	_zoom = _target_zoom
	_forget_target_motion()
	_has_follow_height = false
	_apply_transform()
	if arm != null:
		arm.snap()


## The camera is being rotated with the mouse right now (the cursor is captured).
func is_rotating() -> bool:
	return _rotating


## The zoom (the camera height) now: 0 is the camera lowered all the way, 1 raised all the way.
func get_zoom() -> float:
	return _zoom


## Pause or resume the follow: the turn, the pitch and the height ([member follow_movement], [member follow_pitch],
## [member follow_zoom]). For example, while it is not yet clear whether this is a click or a hold of the mouse
## button ([signal PointClickMoveInput.hold_pending_changed]). Paused, the follow does not pull, and a move under way
## brakes as fast as the smoothing of the mouse and the wheel settles; resumed, it starts again smoothly.
func set_follow_paused(paused: bool) -> void:
	_follow_paused = paused


func is_follow_paused() -> bool:
	return _follow_paused


## Ends the wait after a mouse rotation ([member follow_wait_after_rotate]): the follow works again. Call it when a new
## run starts, for example from [signal PointClickMoveInput.run_requested].
func end_follow_wait() -> void:
	_follow_waiting = false


## The follow waits after a mouse rotation ([member follow_wait_after_rotate]).
func is_follow_waiting() -> bool:
	return _follow_waiting


func _begin_rotate() -> void:
	_rotating = true
	_rotate_time = 0.0
	_rotate_motion = 0.0
	_mouse_motion = Vector2.ZERO
	_cursor_before_rotate = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _end_rotate() -> void:
	if not _rotating:
		return
	_rotating = false
	if follow_wait_after_rotate and (_rotate_time >= _TAP_TIME or _rotate_motion >= _TAP_MOTION):
		_follow_waiting = true
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
		_set_target_pitch_offset(_target_pitch_offset + pitch_direction * _mouse_motion.y * radians_per_pixel)
	_mouse_motion = Vector2.ZERO


## The target velocity, from its displacement per physics tick, so any [Node3D] works, not only a [CharacterBody3D];
## and the direction of the run, smoothed a little, so that it does not shake on a staircase. A move faster than
## [member teleport_speed] is a teleport, not a run.
func _track_target_motion(delta: float) -> void:
	if target == null or delta <= 0.0:
		_forget_target_motion()
		return
	var target_position := target.global_position
	if _has_target_position:
		var velocity := (target_position - _last_target_position) / delta
		var run := Vector2(velocity.x, velocity.z)
		if run.length() > teleport_speed:
			_forget_target_motion()
		else:
			_target_velocity = velocity
			_heading = _heading.lerp(run, 1.0 - exp(-delta / _HEADING_SMOOTHING))
	_last_target_position = target_position
	_has_target_position = true


## The follow forgets how the target moved, and its moves stop where they are: after a teleport, a new target or a
## snap. It starts afresh, so a wait after a mouse rotation is over too.
func _forget_target_motion() -> void:
	_has_target_position = false
	_target_velocity = Vector3.ZERO
	_heading = Vector2.ZERO
	_follow_waiting = false
	for spring: _FollowSpring in [_turn, _pitch_follow, _zoom_follow]:
		spring.speed = 0.0


## The follow: the height, the pitch and the turn move toward their goals, each on its spring ([_FollowSpring]),
## pulled as strongly as the target runs ([method _get_follow_strength]). When the target stops, while the mouse turns
## the camera, while the follow waits after that and while it is paused, they do not pull, and a move under way brakes
## as fast as the smoothing of the mouse and the wheel settles.
func _follow_movement(delta: float) -> void:
	var running := _get_follow_strength()
	if running <= 0.0:
		# The target stands (or barely moves): the wait after a mouse rotation is over.
		_follow_waiting = false
	var strength := 0.0 if _rotating or _follow_waiting or _follow_paused else running
	var rotation_brake := _get_brake(rotation_sharpness)
	# A move that is turned off stops where it is; turned on again, it starts from rest.
	if not follow_zoom:
		_zoom_follow.speed = 0.0
	if not follow_pitch:
		_pitch_follow.speed = 0.0
	if not follow_movement:
		_turn.speed = 0.0
	# The follow is smooth by itself: it moves the wanted values and the camera's own together, and the smoothing that
	# follows (rotation_sharpness, zoom_sharpness) is left for the mouse and the wheel.
	if follow_zoom:
		var zoom_before := _target_zoom
		var base_before := _get_base_pitch(_target_zoom)
		_set_target_zoom(_target_zoom + _zoom_follow.step(follow_zoom_level - _target_zoom, follow_zoom_time, strength,
				strength, _get_brake(zoom_sharpness), 0.0, delta))
		_zoom = clampf(_zoom + _target_zoom - zoom_before, 0.0, 1.0)
		if follow_pitch:
			# The height changes the pitch of the zoom; the pitch that the follow holds stays where it is.
			_move_pitch_offset(base_before - _get_base_pitch(_target_zoom))
	if follow_pitch:
		# The pitch is the zoom pitch plus an offset; adjust the offset.
		var wanted := clampf(follow_pitch_angle, min_pitch, max_pitch) - _get_base_pitch(_target_zoom)
		_move_pitch_offset(_pitch_follow.step(wanted - _target_pitch_offset, follow_pitch_time, strength, strength,
				rotation_brake, 0.0, delta))
	if follow_movement:
		var error := 0.0
		var weight := 0.0
		if not _heading.is_zero_approx():
			error = angle_difference(_target_yaw, atan2(-_heading.x, -_heading.y))
			weight = _get_turn_weight(absf(error))
		var turn := _turn.step(error, follow_time, strength * weight, strength, rotation_brake, follow_max_turn_speed,
				delta)
		_target_yaw += turn
		_yaw += turn


## 0: the target stands or barely moves; 1: it runs. In between, the follow smoothly gains strength.
func _get_follow_strength() -> float:
	var speed := Vector2(_target_velocity.x, _target_velocity.z).length()
	if follow_min_speed <= 0.0:
		return 1.0 if speed > 0.01 else 0.0
	return clampf(speed / follow_min_speed - 1.0, 0.0, 1.0)


## How strongly the camera turns behind a run at [param angle] from where it looks: not at all for a run that comes
## at the camera within [member follow_toward_camera_angle] of straight, fully for one farther than twice that, and
## smoothly in between.
func _get_turn_weight(angle: float) -> float:
	if follow_toward_camera_angle <= 0.0:
		return 1.0
	return smoothstep(PI - follow_toward_camera_angle, PI - 2.0 * follow_toward_camera_angle, angle)


## How fast a move of the follow brakes when nothing pulls it, 1/s: as fast as the smoothing of the input with
## [param sharpness] settles; without that smoothing, at once.
static func _get_brake(sharpness: float) -> float:
	return sharpness if sharpness > 0.0 else INF


func _add_zoom(amount: float) -> void:
	_set_target_zoom(_target_zoom + amount)


func _set_target_zoom(zoom: float) -> void:
	_target_zoom = clampf(zoom, 0.0, 1.0)
	# The pitch offset must not take the camera beyond the limits at the new zoom.
	_set_target_pitch_offset(_target_pitch_offset)


func _set_target_pitch_offset(offset: float) -> void:
	var base_pitch := _get_base_pitch(_target_zoom)
	_target_pitch_offset = clampf(offset, min_pitch - base_pitch, max_pitch - base_pitch)


## Moves the pitch offset by [param change] for the follow: the wanted one and the camera's own together.
func _move_pitch_offset(change: float) -> void:
	var before := _target_pitch_offset
	_set_target_pitch_offset(_target_pitch_offset + change)
	_pitch_offset += _target_pitch_offset - before


## Follows the height of the target smoothly ([member height_follow_time]), from its interpolated position.
func _follow_target_height(delta: float) -> void:
	if target == null:
		return
	var height := target.get_global_transform_interpolated().origin.y
	if not _has_follow_height or height_follow_time <= 0.0:
		_follow_height = height
		_has_follow_height = true
		return
	# exp(-3) ≈ 0.05: after height_follow_time, 5% of the change remains, whatever the FPS.
	_follow_height = lerpf(_follow_height, height, 1.0 - exp(-3.0 * delta / height_follow_time))


func _apply_transform() -> void:
	if target != null:
		var focus := target.get_global_transform_interpolated().origin
		if _has_follow_height:
			focus.y = _follow_height
		global_position = focus + Vector3.UP * focus_height
	var pitch := clampf(_get_base_pitch(_zoom) + _pitch_offset, min_pitch, max_pitch)
	# The default Node3D rotation order is YXZ: pitch first, then rotation around the vertical. In the world's axes, like
	# the position: the rig may be under a turned node.
	global_rotation = Vector3(pitch, _yaw, 0.0)
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
