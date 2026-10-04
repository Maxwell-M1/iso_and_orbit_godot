class_name PointClickMoveInput
extends Node
## Mouse controls familiar from isometric RPGs: a click on the ground runs to that point, a held button runs after
## the cursor, and the same button together with the camera button runs where the camera looks. The WASD keys also
## work with the camera button.
##
## The component only translates input into [NavigationMover] commands; it moves nothing itself.
##
## - Click: the point under the cursor at the moment of the press is found by a physics ray from the camera (layers
##   [member ground_mask]), and a path around obstacles is built to it. The character starts running there when the
##   button is released before [member hold_delay]: while it is not clear whether this is a click or a hold, the
##   character keeps doing what it was doing, and the point marker and the path do not appear. Otherwise, during a
##   hold, it would have time to turn onto the path to the press point, and the path may lead in a completely
##   different direction than the cursor later does.
## - Holding [member move_action] longer than [member hold_delay]: according to [member hold_mode], straight toward
##   the cursor or along a path to the point under the cursor. The camera follows the character, so the cursor always
##   points ahead, and the character runs while the button is held. If the camera turns on its own meanwhile, the
##   cursor stays over the same ground point ([member keep_aim_on_camera_turn]). While running, the cursor is hidden
##   ([member hide_cursor_while_held]).
## - Holding together with [member camera_steer_action] (RMB by default, which rotates the camera): straight where
##   the camera looks; turn the camera, and the character turns too. The left and right keys (A, D) send the run
##   diagonally forward, facing forward or facing the direction of movement ([member keys_with_camera_steer]). When
##   RMB is released first, the run keeps going where the camera looked until the mouse moves, and then the cursor
##   steers it from straight ahead ([member keep_camera_course]): the buttons released one after the other stop the
##   character as if released together.
## - Only [member camera_steer_action] and the WASD keys: walk relative to the camera ([member keys_with_camera]),
##   sideways (facing forward: A and D move sideways, S moves backward, back first) or with turning (facing the
##   direction of movement: A and D move left and right, S moves toward the camera). Releasing the keys or RMB stops.
##
## Who drives the character in a tick is decided in one place ([method _physics_process]): the held mouse button,
## otherwise the keys with RMB. So, for example, if LMB is released while RMB and W are held, the character does not
## stop but keeps walking by the keys.
##
## The cursor is adjusted in [method Node._process] after the camera has settled in place this frame, so the
## component's [member Node.process_priority] is 1 by default, higher than the camera's (0).

## The player picked the point where the character will stop: clicked the ground or released the button after a hold
## in the [constant HoldMode.FOLLOW_POINT] mode.
signal destination_picked(point: Vector3)
## The button is held longer than [member hold_delay]: the character runs after the cursor or after the camera.
signal hold_started
## The button was pressed, and it is not yet clear whether this is a click or a hold ([param pending] =
## [code]true[/code]); it became clear: released or held longer than [member hold_delay] ([code]false[/code]). While
## it is unclear, the camera should not turn on its own ([method OrbitCameraRig.set_follow_paused]): a short click
## must not move the cursor, and by the start of the hold the cursor must point where the press was.
signal hold_pending_changed(pending: bool)
## The player sent the character on a new run: a click to a new point, a press that became a hold, or the keys with
## [member camera_steer_action] that started a walk. Not when the keys take over a hold that has just ended, nor for a
## click at the point the character is already running to. For example, the camera follow that waits after the camera
## has been rotated ([member OrbitCameraRig.follow_wait_after_rotate]) works again from a new run
## ([method OrbitCameraRig.end_follow_wait]).
signal run_requested

## How the keys walk with RMB held ([member keys_with_camera]) and with both buttons held
## ([member keys_with_camera_steer]).
enum KeysMode {
	## The keys do not work.
	OFF,
	## Sideways: the character always faces where the camera looks. With RMB: W is forward, A and D are sideways, S is
	## backward (back first). With both buttons: A and D send the run diagonally forward, facing forward.
	SIDESTEP,
	## With turning: the character faces where it walks. With RMB: W is forward, A and D are left and right, S is
	## toward the camera, facing it. With both buttons: A and D send the run diagonally forward, facing the direction of
	## movement.
	TURN,
}

## How to run while [member move_action] is held.
enum HoldMode {
	## Straight toward the cursor, without pathfinding. The character slides around obstacles, and the player decides
	## where to run. After the button is released, the character stops smoothly.
	STEER,
	## To the point under the cursor along a navigation path, around obstacles. The path is recomputed while the point
	## moves, so near height changes (a ramp, a platform) it may jump. After the release, the character runs to the
	## last point (or stops, see [member stop_on_release]).
	FOLLOW_POINT,
}

## How close to the window edge the hidden system cursor may come before it is returned to the center (see
## [method _is_cursor_roaming]).
const _EDGE_MARGIN := 8.0
## How long after the system cursor is moved mouse positions from before the move may still arrive: in the editor's
## Game view on macOS the cursor moves a frame or two later.
const _LATE_POSITIONS_MSEC := 250
## How far, px, the mouse has to move to take over a run that keeps the camera's course ([member keep_camera_course]):
## a hand releasing a button moves the mouse a little.
const _CURSOR_TAKEOVER_DISTANCE := 8.0
## How far ahead of the character, m, the cursor is put when it takes over the camera's course.
const _AIM_AHEAD := 4.0

## What to drive.
@export var mover: NavigationMover

## The camera to cast the ray from and whose view direction is used. If not set, the window's current camera is used.
@export var camera: Camera3D

## The "run to the cursor" input action.
@export var move_action := &"move_to_cursor"

## How the character runs while [member move_action] is held.
@export var hold_mode := HoldMode.STEER

## While the button is pressed and the camera turns on its own (following the run) or zooms, move the cursor together
## with the world: it stays over the same ground point, the character runs where it was aimed, and the mouse turns it
## as usual. If turned off, the cursor stays in place on the screen, and a camera turn turns the character: it runs
## along an arc until the cursor is right in front of it.
## This requires moving the cursor ([method Viewport.warp_mouse]); where the system cannot do that, the cursor stays in
## place, but the running direction is still kept.
@export var keep_aim_on_camera_turn := true

## Hide the system cursor while the character runs with [member move_action] held (from the moment the press became
## a hold): while running it only flickers, especially when the camera turns and the cursor moves with the world. The
## hidden cursor does not leave the window, and after the button is released it appears where the aim was.
@export var hide_cursor_while_held := true

## The action that, together with holding [member move_action], drives the character where the camera looks.
## An empty name disables it.
@export var camera_steer_action := &"camera_rotate"

## When [member camera_steer_action] is released while both buttons drive the run, keep running where the camera looked
## until the mouse moves; then the cursor takes the run over, put ahead of the character along the run. If
## [member move_action] is released before that, the character stops, as if both buttons had been released together.
## Without this the cursor takes over at once from where it was before the camera was rotated: the character turns
## toward a spot the player no longer means (and in the [constant HoldMode.FOLLOW_POINT] mode runs on there after the
## release).
@export var keep_camera_course := true

## With [member keep_camera_course]: mouse movement in this time after [member camera_steer_action] is released does not
## hand the run to the cursor yet: the hand may still be turning the camera.
@export_range(0.0, 1.0, 0.01, "suffix:s") var cursor_takeover_delay := 0.2

## Physics layers that can be clicked. The character layer must not be included.
@export_flags_3d_physics var ground_mask := 1

## How long to hold the button for a click to become a hold. If it is released earlier, it is a click, and the
## character runs to the press point; while it is unclear, the character keeps doing what it was doing.
@export_range(0.0, 1.0, 0.01, "suffix:s") var hold_delay := 0.2

## In the [constant HoldMode.STEER] mode: if the cursor is closer than this to the character (along the ground), the
## direction does not change: near the character, it is too sensitive to cursor movement.
@export_range(0.0, 3.0, 0.01, "suffix:m") var steer_dead_zone := 0.5

## In the [constant HoldMode.FOLLOW_POINT] mode: after the button is released, stop smoothly right away instead of
## running to the last point under the cursor.
@export var stop_on_release := false

## The length of the ray from the camera.
@export_range(1.0, 5000.0, 1.0, "suffix:m") var ray_length := 1000.0

@export_group("Keys")
## How the WASD keys walk with [member camera_steer_action] held (without [member move_action]).
@export var keys_with_camera := KeysMode.SIDESTEP
## How the left and right keys steer the run with [member move_action] and [member camera_steer_action] held.
@export var keys_with_camera_steer := KeysMode.SIDESTEP
## The "forward" input action (W): where the camera looks.
@export var move_forward_action := &"move_forward"
## The "back" input action (S): toward the camera.
@export var move_back_action := &"move_back"
## The "left" input action (A).
@export var move_left_action := &"move_left"
## The "right" input action (D).
@export var move_right_action := &"move_right"

var _cursor := Vector2.ZERO
var _click_position := Vector2.ZERO
var _click_pending := false
# The ground point under the press, or null. Run there only if the press turns out to be a click.
var _click_point: Variant = null
var _held := false
var _held_time := 0.0
var _holding := false
var _hold_pending := false
# Where the cursor aims during a hold: a ground point relative to the character's feet. Also where the system cursor
# was in the previous frame, to tell mouse movement from a camera turn.
var _aim_offset := Vector3.ZERO
var _has_aim := false
var _mouse_seen := Vector2.ZERO
# We hid the cursor (not the camera or the UI), so showing it again is also up to us.
var _cursor_hidden := false
# The mouse mode that hides the cursor. Not just hidden but confined to the window: otherwise the invisible cursor goes
# past the window edge and appears there. On macOS the engine confines the cursor itself: it detaches the cursor from
# the mouse and moves it by the mouse event deltas, and a shift by warp_mouse() gets into the next delta once more. Every
# aim correction in _keep_aim() would then count twice, as mouse movement, and with the camera following the run the
# aim would drift further in the direction of the turn until the cursor got stuck at the window edge. So there the
# cursor is only hidden, and the component keeps it in the window (see _is_cursor_roaming()).
var _hidden_mouse_mode := Input.MOUSE_MODE_HIDDEN if OS.has_feature("macos") else Input.MOUSE_MODE_CONFINED_HIDDEN
# After _recenter_system_cursor(): where the system cursor was before the move (and has gone since, by late positions),
# and until when mouse positions from before the move may still arrive (see _mouse_moved()).
var _late_position := Vector2.ZERO
var _late_until_msec := 0
# The keys with RMB drive the character: when they are released, stopping it is also up to us.
var _keys_steering := false
# keep_camera_course: where the hold went with the camera button in its last tick, and where the character faced; after
# the button is released, the run keeps this course until the cursor takes over (ZERO: no course). How long ago the
# button was released, s, and how far the mouse has moved since cursor_takeover_delay, px.
var _course := Vector3.ZERO
var _course_facing := Vector3.ZERO
var _course_age := 0.0
var _course_drift := Vector2.ZERO


func _init() -> void:
	process_priority = 1


func _ready() -> void:
	assert(mover != null, "PointClickMoveInput needs the mover property set.")
	for action: StringName in [move_action, camera_steer_action, move_forward_action, move_back_action,
			move_left_action, move_right_action]:
		if action != &"" and not InputMap.has_action(action):
			push_error("PointClickMoveInput: input action \"%s\" is missing in Project Settings > Input Map." % action)


func _unhandled_input(event: InputEvent) -> void:
	# Only the press: the release is checked by polling in _physics_process, because the UI may intercept it, and then
	# the character would run after the cursor forever.
	if not event.is_action_pressed(move_action):
		return
	_held = true
	_holding = false
	_click_point = null
	_course = Vector3.ZERO
	if _is_camera_steer_pressed():
		# The camera button is already held: run after the camera right away, without clicking a point.
		_click_pending = false
		_held_time = hold_delay
	else:
		# Aim the click exactly where the mouse was at the moment of the press. With a captured cursor, the event
		# carries the center of the window, so in that case use the last cursor position before the capture.
		var mouse_event := event as InputEventMouse
		_click_position = mouse_event.position if mouse_event != null and not _is_cursor_captured() else _cursor
		_click_pending = true
		_held_time = 0.0
		_set_hold_pending(true)
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# A menu opened, the focus switched to another window, or the node left the scene in the middle of a run: the
	# cursor is needed right away, not after the button is released.
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE]:
		_show_cursor()


func _process(delta: float) -> void:
	_update_cursor_visibility()
	if _is_cursor_captured():
		# The camera is being rotated: the cursor is captured and sits in the center of the window. Afterwards the
		# camera returns it where it was, and the aim starts anew from _cursor.
		_has_aim = false
		return
	var mouse := get_viewport().get_mouse_position()
	var on_course := _held and _course != Vector3.ZERO and not _is_camera_steer_pressed()
	if on_course and _course_age == 0.0:
		_aim_ahead(mouse)
		mouse = get_viewport().get_mouse_position()
	var moved := Vector2.ZERO
	# Track the aim from the press itself: in the frame where the click becomes a hold, the camera may already have
	# turned.
	if _held and keep_aim_on_camera_turn:
		moved = _keep_aim(mouse)
	else:
		moved = mouse - _mouse_seen
		_cursor = mouse
		_mouse_seen = mouse
		_late_until_msec = 0
		_has_aim = false
		if _is_cursor_roaming():
			# On macOS the engine does not keep the hidden cursor in the window (see _hidden_mouse_mode): bring it back.
			_cursor = _clamp_to_window(mouse)
			if _cursor != mouse:
				get_viewport().warp_mouse(_cursor)
	if on_course:
		_course_age += delta
		if _course_age > cursor_takeover_delay:
			_course_drift += moved
			if _course_drift.length() > _CURSOR_TAKEOVER_DISTANCE:
				# The player steers with the mouse again: the cursor takes the run over.
				_course = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if _click_pending:
		# Take the point right away (the camera and the character are still where they were at the press), but run
		# there on release.
		_click_pending = false
		_click_point = _pick_point(_click_position, false)

	var was_holding := _holding
	if _held:
		_update_hold(delta)
	if _holding:
		_keys_steering = false
		_steer_while_held()
	else:
		# The mouse button was released in this tick: the keys with RMB pick up the run immediately, without stopping.
		_steer_by_keys(was_holding)


## The cursor is hidden while running with the button held ([member hide_cursor_while_held]).
func is_cursor_hidden() -> bool:
	return _cursor_hidden


## The button is held: released means a click or the end of a hold; held longer than [member hold_delay] means a hold.
func _update_hold(delta: float) -> void:
	if not Input.is_action_pressed(move_action):
		_release()
		return
	_held_time += delta
	if _held_time >= hold_delay and not _holding:
		_holding = true
		_click_point = null
		_set_hold_pending(false)
		hold_started.emit()
		run_requested.emit()


func _steer_while_held() -> void:
	if _is_camera_steer_pressed():
		var strafe := 0.0
		if keys_with_camera_steer != KeysMode.OFF:
			strafe = Input.get_axis(move_left_action, move_right_action)
		var facing := _camera_relative(1.0, 0.0) if keys_with_camera_steer == KeysMode.SIDESTEP else Vector3.ZERO
		var direction := _camera_relative(1.0, strafe)
		_steer(direction, facing)
		if keep_camera_course:
			_course = direction
			_course_facing = facing
			_course_age = 0.0
			_course_drift = Vector2.ZERO
	elif _course != Vector3.ZERO:
		# The camera button has been released: keep its course until the mouse moves (see _process()).
		_steer(_course, _course_facing)
	elif hold_mode == HoldMode.STEER:
		_steer(_get_cursor_direction())
	else:
		var aimed: Variant = _pick_point(_cursor, true)
		if aimed != null:
			mover.move_to(aimed)


## The keys with RMB held: walk relative to the camera. When they are released, stop, but only if we were driving: RMB
## alone (to rotate the camera) does not affect a run to a clicked point. [param after_hold]: a hold ended in this tick,
## and the keys only carry its run on.
func _steer_by_keys(after_hold: bool) -> void:
	var keys := _get_keys()
	if keys != Vector2.ZERO:
		if not _keys_steering and not after_hold:
			run_requested.emit()
		_keys_steering = true
		var direction := _camera_relative(keys.y, keys.x)
		# Sideways: face forward, away from the camera (and then backward is back first); with turning: face the
		# direction of movement.
		var facing := _camera_relative(1.0, 0.0) if keys_with_camera == KeysMode.SIDESTEP else Vector3.ZERO
		mover.steer(direction, facing)
	elif _keys_steering:
		_keys_steering = false
		mover.stop()


## The keys with RMB: x is right, y is forward; [constant Vector2.ZERO] if they are not being used to walk now.
func _get_keys() -> Vector2:
	if keys_with_camera == KeysMode.OFF or not _is_camera_steer_pressed():
		return Vector2.ZERO
	return Input.get_vector(move_left_action, move_right_action, move_back_action, move_forward_action)


func _release() -> void:
	_held = false
	_course = Vector3.ZERO
	_set_hold_pending(false)
	if not _holding:
		_run_to_click_point()
		return
	_holding = false
	# A run in a direction has nowhere to "run to": stop. A run to a point continues to it, unless asked otherwise.
	if stop_on_release or not mover.has_destination():
		mover.stop()
	else:
		destination_picked.emit(mover.get_destination())


## A short click: run to where the press was.
func _run_to_click_point() -> void:
	if _click_point == null:
		return
	var point: Vector3 = _click_point
	_click_point = null
	var before: Variant = mover.get_destination() if mover.has_destination() else null
	mover.move_to(point)
	# A click at the point the character is already running to changes nothing (NavigationMover.retarget_tolerance).
	if before == null or mover.get_destination() != before:
		run_requested.emit()
	destination_picked.emit(point)


## The cursor stays over the same ground point (relative to the character's feet) however the camera moves, and mouse
## movement moves it as usual. The system cursor is moved there too (a hidden one only when it is shown again, see
## [method _is_cursor_roaming]). Returns the mouse movement since the previous frame.
func _keep_aim(mouse: Vector2) -> Vector2:
	var view := _get_camera()
	if view == null:
		var moved_on_screen := mouse - _mouse_seen
		_cursor = mouse
		_mouse_seen = mouse
		return moved_on_screen
	# The feet are where the camera sees them: the camera is placed by the interpolated position.
	var feet := mover.get_body().get_global_transform_interpolated().origin
	var moved := _mouse_moved(mouse)
	# Without an aim (the press itself, right after the camera was rotated, the cursor above the horizon) the cursor
	# moves on the screen.
	var cursor := _cursor + moved
	if _has_aim and not view.is_position_behind(feet + _aim_offset):
		# Where the aim ended up on the screen after the camera moved, plus the mouse movement during the frame.
		cursor = view.unproject_position(feet + _aim_offset) + moved
	cursor = _clamp_to_window(cursor)
	if _is_cursor_roaming():
		# The hidden system cursor only measures the mouse movement: keep it away from the window edges, where it would
		# stop or leave the window.
		if not get_viewport().get_visible_rect().grow(-_EDGE_MARGIN).has_point(_mouse_seen):
			_recenter_system_cursor()
	# Do not move it by less than a pixel: the system cursor sits on whole window pixels.
	elif cursor.distance_to(mouse) > 1.0:
		get_viewport().warp_mouse(cursor)
		# Warping rounds to a window pixel (and where it is not supported, the cursor does not move); from now on,
		# count as mouse movement only what moved after the warp.
		_mouse_seen = get_viewport().get_mouse_position()
	_cursor = cursor
	var aim: Variant = _ground_point(cursor, feet.y)
	_has_aim = aim != null
	if _has_aim:
		_aim_offset = (aim as Vector3) - feet
	return moved


## [member keep_camera_course]: the camera button has just been released, and the cursor is put ahead of the character
## along the course. It is still where it was before the camera was rotated, and when it takes the run over, the
## character would turn toward a spot the player no longer means.
func _aim_ahead(mouse: Vector2) -> void:
	_aim_offset = _course * _AIM_AHEAD
	_has_aim = true
	_mouse_seen = mouse
	if keep_aim_on_camera_turn:
		# _keep_aim() puts the cursor there in this frame.
		return
	var view := _get_camera()
	if view == null:
		return
	var feet := mover.get_body().get_global_transform_interpolated().origin
	_cursor = _clamp_to_window(view.unproject_position(feet + _aim_offset))
	get_viewport().warp_mouse(_cursor)
	_mouse_seen = get_viewport().get_mouse_position()


## The mouse movement since the previous frame. After [method _recenter_system_cursor], a position closer to where the
## system cursor was before the move is a late one. Its movement is not counted: the move puts the cursor in the center
## anyway, and that movement is lost; counted, it would turn the aim there and back.
func _mouse_moved(mouse: Vector2) -> Vector2:
	if Time.get_ticks_msec() < _late_until_msec and mouse.distance_to(_late_position) < mouse.distance_to(_mouse_seen):
		_late_position = mouse
		return Vector2.ZERO
	var moved := mouse - _mouse_seen
	_mouse_seen = mouse
	return moved


## The hidden system cursor goes to the center of the window, as far from its edges as possible.
func _recenter_system_cursor() -> void:
	_late_position = _mouse_seen
	_late_until_msec = Time.get_ticks_msec() + _LATE_POSITIONS_MSEC
	get_viewport().warp_mouse((get_viewport().get_visible_rect().size / 2.0).floor())
	_mouse_seen = get_viewport().get_mouse_position()


## The hidden system cursor does not follow the aim every frame. Nobody sees it, and where the system moves it late
## (in the editor's Game view on macOS, a frame or two after [method Viewport.warp_mouse], while mouse positions from
## before the move keep arriving), the aim would jump back and forth while the camera turns, and the character would
## twitch. So the component moves its own cursor by the mouse movement, returns the system cursor to the center of the
## window when it comes to the window edge, and puts it where the aim is when it shows it again.
func _is_cursor_roaming() -> bool:
	return _cursor_hidden and Input.mouse_mode == _hidden_mouse_mode


## Hides the cursor while running with the button held ([member hide_cursor_while_held]) and shows it afterward. Only
## a visible cursor is hidden: a captured one (the camera is being rotated) is left alone, and when the camera releases
## it (and makes it visible), it is hidden again if the button is still held.
func _update_cursor_visibility() -> void:
	if not (_holding and hide_cursor_while_held):
		if _is_cursor_roaming():
			# The system cursor was not following the aim: it appears where the aim is.
			get_viewport().warp_mouse(_cursor)
		_show_cursor()
	elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = _hidden_mouse_mode
		_cursor_hidden = true


func _show_cursor() -> void:
	if not _cursor_hidden:
		return
	_cursor_hidden = false
	# The mode may have been changed without us (camera capture, a menu): then it is no longer ours.
	if Input.mouse_mode == _hidden_mouse_mode:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _set_hold_pending(pending: bool) -> void:
	if pending != _hold_pending:
		_hold_pending = pending
		hold_pending_changed.emit(pending)


func _steer(direction: Vector3, facing := Vector3.ZERO) -> void:
	if direction != Vector3.ZERO:
		mover.steer(direction, facing)


## A horizontal direction relative to the camera: [param forward] is forward, where it looks, and [param right] is to
## the right. The length is 1 for any shares: diagonally is not faster than straight.
func _camera_relative(forward: float, right: float) -> Vector3:
	var view := _get_camera()
	if view == null:
		return Vector3.ZERO
	var basis := view.global_basis
	return (_flat(-basis.z).normalized() * forward + _flat(basis.x).normalized() * right).normalized()


## Where the cursor points from the character, horizontally; [constant Vector3.ZERO] if the cursor is right at the
## character. The ray is intersected with a horizontal plane at feet height, not with the geometry: this way the
## direction does not jump when the cursor moves from the ground onto an obstacle and back.
func _get_cursor_direction() -> Vector3:
	var view := _get_camera()
	if view == null:
		return Vector3.ZERO
	var feet := mover.get_body().global_position
	var hit: Variant = _ground_point(_cursor, feet.y)
	if hit == null:
		# The cursor is above the horizon: run in the direction the ray goes.
		return _flat(view.project_ray_normal(_cursor)).normalized()
	var offset := _flat((hit as Vector3) - feet)
	return offset.normalized() if offset.length() >= steer_dead_zone else Vector3.ZERO


## Where the ray from the camera through [param screen_position] intersects the horizontal plane at height
## [param height]; [code]null[/code] if the ray is above the horizon.
func _ground_point(screen_position: Vector2, height: float) -> Variant:
	var view := _get_camera()
	return Plane(Vector3.UP, height).intersects_ray(
			view.project_ray_origin(screen_position), view.project_ray_normal(screen_position))


## The world point under [param screen_position], or [code]null[/code] if there is nothing under the cursor.
## With [param allow_horizon], a ray into the sky is intersected with the horizontal plane at the character's height.
func _pick_point(screen_position: Vector2, allow_horizon: bool) -> Variant:
	var view := _get_camera()
	if view == null:
		return null
	var origin := view.project_ray_origin(screen_position)
	var direction := view.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * ray_length, ground_mask)
	var hit := view.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit.position
	if allow_horizon:
		return _ground_point(screen_position, mover.get_body().global_position.y)
	return null


func _clamp_to_window(screen_position: Vector2) -> Vector2:
	return screen_position.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size - Vector2.ONE)


func _get_camera() -> Camera3D:
	return camera if camera != null else get_viewport().get_camera_3d()


func _is_camera_steer_pressed() -> bool:
	return camera_steer_action != &"" and Input.is_action_pressed(camera_steer_action)


static func _is_cursor_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


static func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
