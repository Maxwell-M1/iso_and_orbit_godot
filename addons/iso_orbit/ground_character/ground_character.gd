class_name GroundCharacter
extends CharacterBody3D
## A character driven by [NavigationMover]: this is where gravity, jumping, sprinting, stairs, [method move_and_slide]
## and turning the model toward the running direction live.
##
## It does not matter who gives the commands: the player through [PointClickMoveInput] and [CharacterActionInput], an
## AI or a script call [method NavigationMover.move_to] and [method jump] and set [member sprint_requested]. So the
## same scene works for both the player and NPCs.
##
## The character tells what it is doing, so that animations, sounds, effects and the interface do not compute it
## themselves (the character itself knows nothing about them):
## - signals for moments: [signal state_changed], [signal stepped], [signal jumped], [signal left_floor],
##   [signal touched_floor], [signal landed], [signal sprint_changed];
## - queries for what changes every tick (read them in [code]_process[/code] or [code]_physics_process[/code]):
##   [method get_state], [method get_move_velocity], [method get_move_speed], [method get_locomotion_blend],
##   [method get_local_movement], [method get_turn_rate], [method get_air_time], [method get_step_phase],
##   [method get_gait_cycle], [method get_step_foot].
## [CharacterMonitor] shows all of this as text.
##
## Ground: the body walks up slopes up to [member CharacterBody3D.floor_max_angle] (the body's Floor → Max Angle) and
## steps up and down stairs up to [member max_step_height].

## [method get_state] changed: [param state] is the new state, [param previous] the old one. Emitted at the end of the
## physics tick, after the other signals of that tick.
signal state_changed(state: State, previous: State)
## A foot touched the ground; [method get_step_foot] tells which one. Steps come every [member stride_length]
## traveled on the ground, so the faster the run, the more frequent the steps. [param sprinting] tells whether the
## character is sprinting.
signal stepped(sprinting: bool)
## The character started ([param sprinting] = [code]true[/code]) or stopped sprinting.
signal sprint_changed(sprinting: bool)
## The character pushed off the ground. [signal left_floor] follows in the same tick.
signal jumped
## The character left the ground: by a jump or off an edge. Going down a stair does not count (see
## [member max_step_height]): the character stays on the ground.
signal left_floor
## The character is back on the ground after any time in the air (every [signal left_floor] is followed by one).
## [param fall_speed] is the speed it was falling at, m/s.
signal touched_floor(fall_speed: float)
## A real landing: [signal touched_floor] at a fall speed of at least [member landing_min_speed]. [param impact_speed]
## is that speed, m/s. Stepping off a bump does not count as a landing.
signal landed(impact_speed: float)

## What the character is doing ([method get_state]).
enum State {
	## Stands on the ground or runs into a wall without moving.
	IDLE,
	## Moves on the ground at any speed, from a first step to a full run.
	RUNNING,
	## Moves on the ground while sprinting.
	SPRINTING,
	## Flies up after a jump, until the top of the jump.
	JUMPING,
	## Is in the air going down: after the top of a jump, or off an edge.
	FALLING,
}

## Which foot touched the ground ([method get_step_foot]).
enum Foot { LEFT, RIGHT }

## Below this horizontal speed the character counts as standing: [constant State.IDLE], no steps.
const IDLE_SPEED := 0.1
# How much farther than the movement of the tick a stair is looked for, m.
const _STAIR_LOOK_AHEAD := 0.05
# The step of the search for a place past a stair edge, m.
const _STAIR_SEARCH_STEP := 0.02

## The component that computes the horizontal velocity.
@export var mover: NavigationMover

## The model to turn so that it faces along the run (or where [method NavigationMover.get_facing] says, if the
## character walks sideways). Its "face" is the −Z direction.
@export var visual: Node3D

## How fast the model turns to catch up with the running direction.
@export_range(30.0, 3600.0, 1.0, "radians_as_degrees") var visual_turn_speed := deg_to_rad(1080.0)

@export_group("Ground")
## The highest stair the character steps onto without a jump, and the deepest one it steps down without leaving the
## ground. 0 disables stepping: then the round bottom of the capsule climbs only about
## [code]radius × (1 − cos floor_max_angle)[/code] (0.1 m for the demo's capsule). The slope limit is the body's own
## [member CharacterBody3D.floor_max_angle].
@export_range(0.0, 1.0, 0.01, "suffix:m") var max_step_height := 0.3
## Keeps the character from walking off cliffs. If not set, the character falls from any height. The guard does not
## hold back a jump.
@export var ledge_guard: LedgeGuard

@export_group("Jump and fall")
## Whether the character can jump. When this is disabled, [method jump] does nothing.
@export var can_jump := true
## Jump height (of the feet), taking [member gravity_scale] into account.
@export_range(0.0, 5.0, 0.05, "suffix:m") var jump_height := 1.0
## How long a jump is still possible after stepping off an edge: a jump pressed slightly late is not lost.
@export_range(0.0, 0.5, 0.01, "suffix:s") var coyote_time := 0.1
## How long to remember a jump press in the air: a jump pressed slightly before landing fires on the ground.
@export_range(0.0, 0.5, 0.01, "suffix:s") var jump_buffer_time := 0.12
## How many times stronger gravity is for the character than in the world. The character in the game runs faster than
## a human and with normal gravity falls "like a feather"; with 3 it drops from 1.6 m in 0.33 s instead of 0.57 s.
@export_range(0.0, 10.0, 0.05) var gravity_scale := 3.0
## A fall slower than this does not count as a landing ([signal landed]), only as [signal touched_floor].
@export_range(0.0, 20.0, 0.1, "suffix:m/s") var landing_min_speed := 2.5

@export_group("Sprint")
## Whether the character can sprint. If this is disabled mid-run, the character immediately sheds the excess speed by
## braking.
@export var can_sprint := true
## Stamina for sprinting. If not set, the character can sprint indefinitely.
@export var stamina: Stamina
## Sprinting is tiring: it spends stamina from [member stamina], and an exhausted character runs normally. When
## disabled, the character can sprint indefinitely.
@export var sprint_tires := true
## How many seconds of sprinting a full stamina reserve lasts.
@export_range(0.5, 60.0, 0.5, "suffix:s") var sprint_duration := 5.0

@export_group("Steps")
## How far to travel on the ground from one step to the next ([signal stepped]). Steps are counted by the distance
## traveled, not by time, so they are more frequent when sprinting, and there are none against a wall where the
## character stands.
@export_range(0.2, 5.0, 0.05, "suffix:m") var stride_length := 1.5
## How far to travel from a standstill to the first step: the step is heard as soon as the character starts moving.
@export_range(0.0, 5.0, 0.05, "suffix:m") var first_step_distance := 0.3

## A sprint is requested (the player holds the key). The character sprints only if it can ([member can_sprint]),
## while it is being led and has stamina.
var sprint_requested := false

# State.
var _state := State.IDLE
var _turn_rate := 0.0
var _model_yaw := 0.0
# The horizontal velocity the body moved with in the last tick (get_move_speed).
var _move_velocity := Vector3.ZERO
# Jump and floor contact.
var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _was_on_floor := true
var _jumping := false
var _air_time := 0.0
var _fall_speed := 0.0
# Steps: the stretch of path to the next step, its length (first_step_distance from a standstill, stride_length after
# that) and the step rhythm (get_step_phase) at its start and at its end; at the end it is always a whole number, the
# moment of the step.
var _to_next_step := 0.0
var _step_segment := 0.0
var _phase_from := 0.0
var _phase_to := 1.0
var _ray_query := PhysicsRayQueryParameters3D.new()


func _ready() -> void:
	assert(mover != null, "GroundCharacter needs the mover property set.")
	_to_next_step = first_step_distance
	_step_segment = first_step_distance
	_ray_query.exclude = [get_rid()]
	_model_yaw = _get_model_yaw()


## One tick of the body, in this order: sprint, horizontal velocity, jump and gravity, the ledge guard,
## [method move_and_slide] with stairs, then what the tick changed: floor contact, steps, the model's turn, the state.
func _physics_process(delta: float) -> void:
	_update_sprint(delta)
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	var jumping := _try_jump(delta)
	if not is_on_floor():
		velocity += get_gravity() * gravity_scale * delta
	# A jump is a deliberate move, including off an edge: the ledge guard does not hold it back (it does not work in
	# the air anyway).
	if ledge_guard != null and not jumping:
		velocity = ledge_guard.constrain(velocity, delta)
	# After move_and_slide() the floor has already canceled the fall speed, so remember it beforehand.
	_fall_speed = maxf(_fall_speed, -velocity.y)
	_move_body(delta, jumping)
	_update_floor_contact(delta)
	_report_steps(delta)
	_turn_visual(delta)
	_update_state()


#region Commands

## Jump as soon as the character is on the ground (or right away if it is on the ground or has just stepped off it).
func jump() -> void:
	if not can_jump:
		return
	_jump_buffer_left = jump_buffer_time if jump_buffer_time > 0.0 else get_physics_process_delta_time()

#endregion


#region State for animations, effects and the interface

## What the character is doing now.
func get_state() -> State:
	return _state


## The actual horizontal velocity, m/s: how the body really moves (a wall stops it), on the ground and in the air.
## Unlike [method CharacterBody3D.get_real_velocity] it also counts a stair up, where the body is put on the stair
## past [method move_and_slide].
func get_move_velocity() -> Vector3:
	return _move_velocity


## The length of [method get_move_velocity], m/s.
func get_move_speed() -> float:
	return _move_velocity.length()


## The speed for a 1D blend of animations: 0 standing, 1 at the running speed
## ([member LocomotionSettings.max_speed]), 2 at the full sprint speed; in between, in proportion. Does not depend on
## how the speeds are tuned, so the blend points stay at 0, 1 and 2.
func get_locomotion_blend() -> float:
	var settings := mover.settings
	var speed := get_move_speed()
	if speed <= settings.max_speed:
		return speed / settings.max_speed
	var sprint := settings.max_speed * settings.sprint_speed_multiplier
	if sprint <= settings.max_speed:
		return 1.0
	return 1.0 + minf((speed - settings.max_speed) / (sprint - settings.max_speed), 1.0)


## The movement in the model's axes, for a 2D blend: x is to the model's right, y is forward, and the length is
## [method get_locomotion_blend]. A run forward gives (0, 1), a sprint (0, 2), a sidestep to the right (1, 0), backing
## up at the backward speed (0, −0.7). Standing gives (0, 0).
func get_local_movement() -> Vector2:
	if _move_velocity.length() < IDLE_SPEED:
		return Vector2.ZERO
	var forward := Vector3.FORWARD.rotated(Vector3.UP, _model_yaw)
	var right := forward.cross(Vector3.UP)
	var direction := _move_velocity.normalized()
	return Vector2(direction.dot(right), direction.dot(forward)) * get_locomotion_blend()


## How fast the model turns, rad/s: positive to the left (counterclockwise seen from above), negative to the right.
func get_turn_rate() -> float:
	return _turn_rate


## How long the character has been in the air, s; 0 on the ground.
func get_air_time() -> float:
	return _air_time


## Step rhythm for animations: how many steps have been taken, as a fraction. A whole value is the moment of a step
## ([signal stepped]); between steps the fractional part grows from 0 to 1 with the distance traveled. While the
## character stands, the value does not change.
func get_step_phase() -> float:
	var progress := clampf(1.0 - _to_next_step / maxf(_step_segment, 0.001), 0.0, 1.0)
	return lerpf(_phase_from, _phase_to, progress)


## Where the character is in the gait cycle (two steps), from 0 to 1: 0 is the moment the left foot touches the
## ground, 0.5 the right one. Driving a looped run animation by it (its length times this value) keeps the feet in
## step with the ground: the cycle follows the distance covered, not time.
func get_gait_cycle() -> float:
	return fposmod(get_step_phase(), 2.0) / 2.0


## The foot of the last step ([signal stepped]). The feet alternate, also across stops: after a stop the next step is
## made by the other foot. The very first step is made by the right foot.
func get_step_foot() -> Foot:
	return Foot.LEFT if posmod(floori(get_step_phase()), 2) == 0 else Foot.RIGHT


## The character is sprinting now.
func is_sprinting() -> bool:
	return mover.sprinting


## Sprinting is not possible now: sprinting is tiring, and the character is exhausted.
func is_exhausted() -> bool:
	return sprint_tires and stamina != null and not stamina.can_spend()


## Initial jump speed for [member jump_height]: v = √(2·g·h).
func get_jump_speed() -> float:
	return sqrt(2.0 * get_gravity().length() * gravity_scale * jump_height)

#endregion


#region Sprint and jump

func _update_sprint(delta: float) -> void:
	var sprinting := sprint_requested and can_sprint and mover.is_moving() and not is_exhausted()
	if sprinting != mover.sprinting:
		mover.sprinting = sprinting
		sprint_changed.emit(sprinting)
	if sprinting and sprint_tires and stamina != null:
		stamina.spend(stamina.max_value / sprint_duration * delta)


## Jumps if the jump is pressed and there is ground underfoot or there was a moment ago. Returns whether it jumped.
func _try_jump(delta: float) -> bool:
	_coyote_left = coyote_time if is_on_floor() else _coyote_left - delta
	if _jump_buffer_left <= 0.0:
		return false
	_jump_buffer_left -= delta
	if _coyote_left <= 0.0 and not is_on_floor():
		return false
	_jump_buffer_left = 0.0
	_coyote_left = 0.0
	# Within a tick the body moves at the speed it had at the start of the tick, so a jump at speed v would rise
	# v·dt/2 higher. With v − g·dt/2 on the takeoff tick, the positions on every tick lie exactly on the jump parabola.
	velocity.y = get_jump_speed() - get_gravity().length() * gravity_scale * delta / 2.0
	_jumping = true
	jumped.emit()
	return true

#endregion


#region Moving the body and stairs

## [method move_and_slide] with stairs: a stair up before it, a stair down after it. Remembers the horizontal velocity
## the body moved with ([method get_move_speed]).
func _move_body(delta: float, jumping: bool) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if not jumping and _step_up(horizontal * delta):
		# The stair has taken the movement of this tick: move_and_slide only settles the body on it.
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		velocity.x = horizontal.x
		velocity.z = horizontal.z
		_move_velocity = horizontal
		return
	move_and_slide()
	var real := get_real_velocity()
	_move_velocity = Vector3(real.x, 0.0, real.z)
	if not jumping:
		_step_down(horizontal)


## Steps onto a stair: if [param motion] (the horizontal movement of this tick) runs into a wall whose top is ground
## no higher than [member max_step_height], the body is put on the top, carried by [param motion]. A slope the body
## can walk up is left to [method move_and_slide]. Returns whether the body stepped up.
func _step_up(motion: Vector3) -> bool:
	if max_step_height <= 0.0 or not is_on_floor() or velocity.y > 0.0 or motion.length_squared() < 0.000001:
		return false
	# A little farther than this tick goes: stair treads are often narrower than the body, and right after one stair
	# the body would touch the edge of the next one without noticing it.
	var look_ahead := motion + motion.normalized() * _STAIR_LOOK_AHEAD
	var hit := KinematicCollision3D.new()
	if not test_move(global_transform, look_ahead, hit) or _is_floor(hit.get_normal()):
		return false
	var place: Variant = _find_stair_place(max_step_height, motion.normalized(), motion.length())
	if place == null:
		return false
	global_position = place
	return true


## Keeps the character on the ground going down a stair: if it stood on the ground before the tick and is in the air
## now without a jump, and there is ground no deeper than [member max_step_height] under it (or a little farther
## along [param horizontal], the velocity of the tick), it is put on that ground.
func _step_down(horizontal: Vector3) -> void:
	if max_step_height <= 0.0 or not _was_on_floor or is_on_floor() or velocity.y > 0.0:
		return
	var place: Variant = _find_stair_place(0.0, horizontal.normalized(), 0.0)
	if place != null:
		global_position = place
		apply_floor_snap()


## Where the body stands on the other side of a stair edge, or [code]null[/code]. The body is lifted by [param lift]
## (as far as a ceiling lets), carried along [param direction] by [param distance] and lowered by up to
## [member max_step_height] below the feet. The place counts if the body stands there on ground no higher or lower than
## [member max_step_height]. The round bottom of a capsule rests on the edge of a stair at an angle, too steep to stand
## on while the body is far from the edge, so the place is searched a little farther, in steps of 2 cm, up to
## [member max_step_height] past [param distance].
func _find_stair_place(lift: float, direction: Vector3, distance: float) -> Variant:
	var hit := KinematicCollision3D.new()
	var start := global_transform
	if lift > 0.0:
		var up := up_direction * lift
		start = start.translated(hit.get_travel() if test_move(start, up, hit) else up)
	var feet := global_position.dot(up_direction)
	var drop := up_direction * ((start.origin - global_position).dot(up_direction) + max_step_height)
	var limit := distance + (max_step_height if direction != Vector3.ZERO else 0.0)
	while distance <= limit + 0.001:
		var ahead := direction * distance
		if test_move(start, ahead, hit):
			return null
		var probe := start.translated(ahead)
		if test_move(probe, -drop, hit) and _is_floor(hit.get_normal()):
			var place := probe.origin + hit.get_travel()
			var height := place.dot(up_direction) - feet
			# The ground itself, a little past the touch point along the way: a stair top, not a steep slope.
			var ground := _floor_height_at(hit.get_position() + direction * 0.05, 0.1) - feet
			if absf(height) > 0.01 and absf(height) <= max_step_height + 0.01 and ground <= max_step_height + 0.01:
				return place
		distance += _STAIR_SEARCH_STEP
	return null


## The height of the ground (not too steep to stand on) under [param point], no deeper than [param depth]; NAN if
## there is none.
func _floor_height_at(point: Vector3, depth: float) -> float:
	_ray_query.from = point + up_direction * 0.05
	_ray_query.to = point - up_direction * depth
	_ray_query.collision_mask = collision_mask
	var hit := get_world_3d().direct_space_state.intersect_ray(_ray_query)
	if hit.is_empty() or not _is_floor(hit.normal):
		return NAN
	return (hit.position as Vector3).dot(up_direction)


func _is_floor(normal: Vector3) -> bool:
	return normal.angle_to(up_direction) <= floor_max_angle + 0.01

#endregion


#region What the tick changed

## Floor contact: [signal left_floor], [signal touched_floor] and [signal landed], the time in the air.
func _update_floor_contact(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		if not _was_on_floor:
			touched_floor.emit(_fall_speed)
			if _fall_speed >= landing_min_speed:
				landed.emit(_fall_speed)
				# The landing itself counts as a step: the next one comes after a full stride.
				_start_step_segment(stride_length)
		_air_time = 0.0
		_fall_speed = 0.0
		_jumping = false
	else:
		if _was_on_floor:
			left_floor.emit()
		_air_time += delta
	_was_on_floor = on_floor


## Steps follow the distance traveled on the ground: while the character stands (or is pressed against a wall) there
## are no steps, and once it starts moving, the first step comes after [member first_step_distance].
func _report_steps(delta: float) -> void:
	if not is_on_floor():
		return
	var speed := get_move_speed()
	if speed < IDLE_SPEED:
		# Stopped: from a standstill the first step again comes after first_step_distance.
		_start_step_segment(first_step_distance)
		return
	_to_next_step -= speed * delta
	if _to_next_step <= 0.0:
		_phase_from = _phase_to
		_phase_to += 1.0
		_to_next_step += stride_length
		_step_segment = stride_length
		stepped.emit(is_sprinting())


## A new stretch of [param length] to the next step that does not start at a step (from a standstill, after a
## landing): the rhythm continues from the same value without a discontinuity and reaches a whole number at the next
## step.
func _start_step_segment(length: float) -> void:
	_phase_from = get_step_phase()
	_phase_to = floorf(_phase_from) + 1.0
	_to_next_step = length
	_step_segment = length


## Turns the model toward [method NavigationMover.get_facing] and measures how fast it turns.
func _turn_visual(delta: float) -> void:
	if visual != null:
		var facing := mover.get_facing()
		# The node faces along −Z; rotated by angle a, this direction is (−sin a, 0, −cos a).
		var target_yaw := atan2(-facing.x, -facing.z)
		visual.rotation.y = rotate_toward(visual.rotation.y, target_yaw, visual_turn_speed * delta)
	var yaw := _get_model_yaw()
	_turn_rate = angle_difference(_model_yaw, yaw) / delta if delta > 0.0 else 0.0
	_model_yaw = yaw


## Where the model faces, as a turn around the vertical from −Z: the model itself, or without it where the character
## should face.
func _get_model_yaw() -> float:
	var forward := -visual.global_basis.z if visual != null else mover.get_facing()
	return atan2(-forward.x, -forward.z)


func _update_state() -> void:
	var state := _compute_state()
	if state == _state:
		return
	var previous := _state
	_state = state
	state_changed.emit(state, previous)


func _compute_state() -> State:
	if not is_on_floor():
		return State.JUMPING if _jumping and velocity.y > 0.0 else State.FALLING
	if get_move_speed() < IDLE_SPEED:
		return State.IDLE
	return State.SPRINTING if is_sprinting() else State.RUNNING

#endregion
