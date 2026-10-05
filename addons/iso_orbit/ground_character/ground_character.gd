class_name GroundCharacter
extends CharacterBody3D
## A character driven by [NavigationMover]: this is where gravity, jumping, sprinting, stairs, [method move_and_slide]
## and turning the model toward the running direction live.
##
## It does not matter who gives the commands: the player through [PointClickMoveInput] and [CharacterActionInput], an
## AI or a script call [method NavigationMover.move_to] and [method jump] and set [member sprint_requested]. So the
## same scene works for both the player and NPCs. [method teleport] puts the character elsewhere at once: at a spawn
## point, on another level.
##
## The character tells what it is doing, so that animations, sounds, effects and the interface do not compute it
## themselves (the character itself knows nothing about them):
## - signals for moments: [signal state_changed], [signal stepped], [signal jumped], [signal left_floor],
##   [signal touched_floor], [signal landed], [signal sprint_changed], [signal stair_taken], [signal teleported];
## - queries for what changes every tick (read them in [code]_process[/code] or [code]_physics_process[/code]):
##   [method get_state], [method get_move_velocity], [method get_move_speed], [method get_locomotion_blend],
##   [method get_local_movement], [method get_local_acceleration], [method get_turn_rate], [method get_air_time],
##   [method get_step_phase], [method get_gait_cycle], [method get_step_foot];
## - the ground around the character: [method get_ground_height].
## [CharacterMonitor] shows all of this as text.
##
## Ground: the body walks up slopes up to [member CharacterBody3D.floor_max_angle] (the body's Floor → Max Angle) and
## steps up and down stairs up to [member max_step_height]. Up is +Y: [member CharacterBody3D.up_direction] must stay
## [code]Vector3.UP[/code].
##
## Fall: the rise of a jump slows down with [member gravity_scale], and the way down follows the fall settings
## ([member fall]): how fast the fall gains speed and the fastest fall. A component can put its own fall in their place
## for a while ([method set_fall_override]), as [CharacterHover] does while the character floats;
## [method get_fall_settings] tells which fall is in effect.
##
## A mistake in the setup (a component in the wrong place, settings that contradict each other) is printed as a warning
## when the character enters the tree; [method get_setup_warnings] returns the same list.

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
## [param fall_speed] is the speed it was falling at as it touched the ground, m/s.
signal touched_floor(fall_speed: float)
## A real landing: [signal touched_floor] at a fall speed of at least [member landing_min_speed]. [param impact_speed]
## is that speed, m/s. Stepping off a bump does not count as a landing.
signal landed(impact_speed: float)
## The character stepped onto a stair: up ([param height] > 0) or down ([param height] < 0). [param height] is the
## height of the stair, m: from the ground the character stood on to the ground of the stair. Emitted at the end of the
## physics tick, before [signal state_changed]. Only stairs that the character steps onto count (see
## [member max_step_height]). A stair low enough for the round bottom of a capsule to climb by itself (up to
## [code]radius × (1 − cos floor_max_angle)[/code]) or for the floor snap to take down
## ([member CharacterBody3D.floor_snap_length]) passes without the signal. It is for sounds and animations: the body
## is put onto the stair at once, and smoothing that on screen is up to the model ([CharacterHover]) or the camera.
signal stair_taken(height: float)
## [method teleport] has put the character elsewhere: what follows it (a camera, a trail) should jump there too, not
## travel.
signal teleported

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
## Ground counts as standable up to this much steeper than [member CharacterBody3D.floor_max_angle], rad: the engine's
## own floor check of the body has the same margin. [LedgeGuard] uses it too.
const FLOOR_ANGLE_MARGIN := 0.01
# How much farther than the movement of the tick a stair is looked for, m.
const _STAIR_LOOK_AHEAD := 0.05
# The step of the search for a place past a stair edge, m.
const _STAIR_SEARCH_STEP := 0.02
# How far down the ground under the body is looked for, m: the body stands on it within the safe margin.
const _SUPPORT_PROBE := 0.05

## The component that computes the horizontal velocity.
@export var mover: NavigationMover

## The model to turn so that it faces along the run (or where [method NavigationMover.get_facing] says, if the
## character walks sideways). Its "face" is the −Z direction. It turns relative to its parent, so the body may stand
## turned in the level: the character starts facing along the body's −Z.
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
## How many times stronger gravity is for the character than in the world: on the rise of a jump, and on the way down
## too unless [member fall] sets another. The character in the game runs faster than a human and with normal gravity
## falls "like a feather"; with 3 it drops from 1.6 m in 0.33 s instead of 0.57 s.
@export_range(0.0, 10.0, 0.05) var gravity_scale := 3.0
## How the character falls ([FallSettings]): how fast the fall gains speed and the fastest fall. Empty: it falls with
## [member gravity_scale], without a limit. A component can put its own fall in its place for a while
## ([method set_fall_override]), as [CharacterHover] does while the character floats.
@export var fall: FallSettings
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
## Count steps: [signal stepped] and the step rhythm ([method get_step_phase], [method get_gait_cycle],
## [method get_step_foot]). Off for a character without legs (on wheels, always floating): then there are no steps,
## and the rhythm stands still at its last values, so leg animations should not follow it. When the steps come back,
## they start as from a standstill: the first step comes after [member first_step_distance]. Components can also stop
## the steps for a while without touching this switch ([method set_steps_suppressed]; [CharacterHover] does it while
## the character floats).
@export var steps_enabled := true:
	set(value):
		steps_enabled = value
		_update_counting_steps()
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
# The horizontal velocity the body was driven with in the last tick and how it changed, per second
# (get_local_acceleration).
var _driven_velocity := Vector3.ZERO
var _acceleration := Vector3.ZERO
# A stair taken in this tick, for stair_taken at its end; the height of the ground at the place found past a stair edge.
var _stair_pending := false
var _stair_height := 0.0
var _place_ground := 0.0
# Jump and floor contact.
var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _was_on_floor := true
var _jumping := false
var _air_time := 0.0
var _fall_speed := 0.0
# The falls that components put in place of the character's own (set_fall_override), in the order they were put in
# place: {source (a WeakRef: the character does not keep a source alive), settings, priority}.
var _fall_overrides: Array[Dictionary] = []
# Steps: whether they are counted now and who stops them (set_steps_suppressed, held weakly too); the stretch of path
# to the next step, its length (first_step_distance from a standstill, stride_length after that) and the step rhythm
# (get_step_phase) at its start and at its end; at the end it is always a whole number, the moment of the step.
var _counting_steps := true
var _step_suppressors: Array[WeakRef] = []
var _to_next_step := 0.0
var _step_segment := 0.0
var _phase_from := 0.0
var _phase_to := 1.0
var _ray_query := PhysicsRayQueryParameters3D.new()


func _ready() -> void:
	assert(mover != null, "GroundCharacter needs the mover property set.")
	for warning in get_setup_warnings():
		push_warning("%s: %s" % [name, warning])
	_to_next_step = first_step_distance
	_step_segment = first_step_distance
	_ray_query.exclude = [get_rid()]
	# A ray that starts inside something finds no ground: that thing's top is higher than where the ray starts.
	_ray_query.hit_from_inside = true
	_model_yaw = _get_model_yaw()


## One tick of the body, in this order: sprint, horizontal velocity, jump and gravity, the ledge guard,
## [method move_and_slide] with stairs, then what the tick changed: floor contact, the stair, steps, the model's turn,
## the state.
func _physics_process(delta: float) -> void:
	_update_sprint(delta)
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	var jumping := _try_jump(delta)
	# The take-off tick already has its share of gravity (_try_jump), in coyote time too.
	if not is_on_floor() and not jumping:
		_apply_gravity(delta)
	# A jump is a deliberate move, including off an edge: the ledge guard does not hold it back (it does not work in
	# the air anyway).
	if ledge_guard != null and not jumping:
		velocity = ledge_guard.constrain(velocity, delta)
	_measure_acceleration(delta)
	# After move_and_slide() the floor has already canceled the fall speed, so remember it beforehand: as it is now, so
	# that a fall that slowed down before the ground (FallSettings.braking_time) counts at the speed it touched at.
	_fall_speed = maxf(0.0, -velocity.y)
	_move_body(delta, jumping)
	_update_floor_contact(delta)
	_report_stair()
	_report_steps(delta)
	_turn_visual(delta)
	_update_state()


## Problems in how the character is set up, one line each; empty if there are none. The same lines are printed as
## warnings when the character enters the tree.
func get_setup_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if mover != null and mover.get_parent() != self:
		warnings.append("The mover must be a child of the character: it moves its parent.")
	if ledge_guard != null:
		if ledge_guard.get_parent() != self:
			warnings.append("The ledge guard must be a child of the character: it checks the ground under its parent.")
		elif ledge_guard.max_drop < max_step_height:
			warnings.append(("LedgeGuard.max_drop (%.2f m) is lower than max_step_height (%.2f m): the guard stops the "
					+ "character at stairs down that it could step down.") % [ledge_guard.max_drop, max_step_height])
	if max_step_height > 0.0 and floor_snap_length >= max_step_height:
		warnings.append(("Floor → Snap Length (%.2f m) is not lower than max_step_height (%.2f m): the floor snap takes "
				+ "stairs down by itself, without stair_taken.") % [floor_snap_length, max_step_height])
	if can_jump and (jump_height <= 0.0 or gravity_scale <= 0.0):
		warnings.append("can_jump is on, but jump_height or gravity_scale is 0: a jump would not leave the ground.")
	if fall != null and fall.max_speed > 0.0 and not _is_landing_speed(fall.max_speed):
		warnings.append(("fall.max_speed (%.2f m/s) is lower than landing_min_speed (%.2f m/s): a fall never gains "
				+ "enough speed to land, and landed comes only if the character is thrown down faster.")
				% [fall.max_speed, landing_min_speed])
	if not up_direction.is_equal_approx(Vector3.UP):
		warnings.append("Up Direction is not +Y: the character supports only +Y as up.")
	return warnings


#region Commands

## Jump as soon as the character is on the ground (or right away if it is on the ground or has just stepped off it).
func jump() -> void:
	if not can_jump:
		return
	_jump_buffer_left = jump_buffer_time if jump_buffer_time > 0.0 else get_physics_process_delta_time()


## Puts the character at [param position] at once (a spawn point, another level) and, if [param facing] is given, turns
## it and the model there (the horizontal part). It stops dead ([method NavigationMover.halt]), and what follows its
## movement sees no jerk: the speed, the acceleration ([method get_local_acceleration]) and the turn rate are zero, and
## the smoothing between physics ticks starts anew at the new place ([method Node.reset_physics_interpolation]), where a
## floating model ([CharacterHover]) snaps too. A jump pressed before is forgotten; stamina is kept. Whether the
## character stands on the ground stays as it was, so put the feet on the ground: above it the character falls. Then
## [signal teleported].
func teleport(position: Vector3, facing := Vector3.ZERO) -> void:
	mover.halt()
	var flat_facing := Vector3(facing.x, 0.0, facing.z)
	if not flat_facing.is_zero_approx():
		mover.face(flat_facing)
		if visual != null:
			# As in _turn_visual(): the node faces along −Z, turned relative to its parent.
			visual.rotation.y = atan2(-flat_facing.x, -flat_facing.z) - _get_visual_parent_yaw()
	velocity = Vector3.ZERO
	_move_velocity = Vector3.ZERO
	_driven_velocity = Vector3.ZERO
	_acceleration = Vector3.ZERO
	_turn_rate = 0.0
	_jump_buffer_left = 0.0
	global_position = position
	_model_yaw = _get_model_yaw()
	reset_physics_interpolation()
	teleported.emit()


## Stops the steps for [param source] (a component, such as [CharacterHover] while the character floats) while
## [param suppressed] is [code]true[/code], without touching [member steps_enabled]. Steps are counted when
## [member steps_enabled] is on and no source stops them ([method is_counting_steps]), so several sources and the
## game's own switch never undo each other. A source lets the steps go when it no longer needs to stop them, also when
## it leaves the tree, as [CharacterHover] does. The character does not keep a source alive: a source that is freed
## lets the steps go by itself, by the next physics tick.
func set_steps_suppressed(source: Object, suppressed: bool) -> void:
	assert(source != null, "set_steps_suppressed needs a source: the component that stops the steps.")
	var held := _step_suppressors.any(func(ref: WeakRef) -> bool: return ref.get_ref() == source)
	if suppressed and not held:
		_step_suppressors.append(weakref(source))
	elif not suppressed and held:
		_step_suppressors = _step_suppressors.filter(func(ref: WeakRef) -> bool: return ref.get_ref() != source)
	_update_counting_steps()


## Makes the character fall by [param settings] in place of its own [member fall], for [param source] (a component,
## such as [CharacterHover] while the character floats), until the source calls this again with [code]null[/code].
## With several sources, the highest [param priority] counts, and of equal ones the source that put its fall in place
## last; a source that only changes its settings or its priority keeps its place. [member fall] itself is not touched,
## so the game's own settings come back once the sources let go. A source lets go when it no longer needs its fall,
## also when it leaves the tree, as [CharacterHover] does (with priority 0). The character does not keep a source
## alive: a source that is freed lets go by itself.
func set_fall_override(source: Object, settings: FallSettings, priority := 0) -> void:
	assert(source != null, "set_fall_override needs a source: the component that puts its fall in place.")
	_fall_overrides = _fall_overrides.filter(func(entry: Dictionary) -> bool: return entry.source.get_ref() != null)
	for i in _fall_overrides.size():
		if _fall_overrides[i].source.get_ref() == source:
			if settings == null:
				_fall_overrides.remove_at(i)
			else:
				_fall_overrides[i].settings = settings
				_fall_overrides[i].priority = priority
			return
	if settings != null:
		_fall_overrides.append({source = weakref(source), settings = settings, priority = priority})

#endregion


#region State for animations, effects and the interface

## What the character is doing now.
func get_state() -> State:
	return _state


## The actual horizontal velocity, m/s: how the body really moves (a wall stops it), on the ground and in the air.
## Unlike [method CharacterBody3D.get_real_velocity] it also counts a stair up, where the body is put on the stair
## past [method move_and_slide], and in a tick of zero length ([member Engine.time_scale] 0) it keeps its value instead
## of 0 / 0.
func get_move_velocity() -> Vector3:
	return _move_velocity


## The length of [method get_move_velocity], m/s.
func get_move_speed() -> float:
	return _move_velocity.length()


## The speed for a 1D blend of animations: 0 standing, 1 at the running speed
## ([member LocomotionSettings.max_speed]), 2 at the full sprint speed; in between, in proportion. Does not depend on
## how the speeds are tuned, so the blend points stay at 0, 1 and 2. Below [constant IDLE_SPEED] it is 0, as the
## character counts as standing.
func get_locomotion_blend() -> float:
	var settings := mover.settings
	var speed := get_move_speed()
	if speed < IDLE_SPEED:
		return 0.0
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
	return _to_model_axes(_move_velocity.normalized()) * get_locomotion_blend()


## How fast the movement speeds up, slows down and turns, m/s², in the model's axes as in
## [method get_local_movement]: x is to the model's right, y is forward. Speeding up forward gives y > 0, braking
## y < 0, a turn to the left x < 0 (the velocity turns to the left). It is how the velocity the body is driven with
## changes (the [member mover]'s, after the [member ledge_guard]), so it is smooth: stairs do not jerk it, and hitting a
## wall does not show in it. For inertia: an item that lags behind ([HandSway]), a model that leans
## ([CharacterHover]).
func get_local_acceleration() -> Vector2:
	return _to_model_axes(_acceleration)


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


## Steps are counted now: [member steps_enabled] is on and no component stops them
## ([method set_steps_suppressed]). Otherwise there is no [signal stepped], and the step rhythm stands still.
func is_counting_steps() -> bool:
	return _counting_steps


## The character is sprinting now.
func is_sprinting() -> bool:
	return mover.sprinting


## Sprinting is not possible now: sprinting is tiring, and the character is exhausted.
func is_exhausted() -> bool:
	return sprint_tires and stamina != null and not stamina.can_spend()


## Initial jump speed for [member jump_height]: v = √(2·g·h).
func get_jump_speed() -> float:
	return sqrt(2.0 * get_gravity().length() * gravity_scale * jump_height)


## The fall settings in effect: of the source that counts ([method set_fall_override]: the highest priority, of equal
## ones the latest), otherwise [member fall]. [code]null[/code]: the character falls with [member gravity_scale],
## without a limit.
func get_fall_settings() -> FallSettings:
	var top := {}
	for entry: Dictionary in _fall_overrides:
		if entry.source.get_ref() != null and (top.is_empty() or entry.priority >= top.priority):
			top = entry
	return top.settings if not top.is_empty() else fall


## The height of the ground under [param point]: of the first surface that a ray going down meets from [param above]
## meters above the point to [param below] meters below it. NAN if there is none, if it is too steep to stand on
## (steeper than [member CharacterBody3D.floor_max_angle]), or if the ray starts inside something (a wall higher than
## [param above]). The ray hits what the body collides with ([member CollisionObject3D.collision_mask]), except the
## body itself. For example, for a model floating over the ground ([CharacterHover]) or for feet that should stand on
## the stairs.
func get_ground_height(point: Vector3, above: float, below: float) -> float:
	_ray_query.from = point + up_direction * above
	_ray_query.to = point - up_direction * below
	_ray_query.collision_mask = collision_mask
	var hit := get_world_3d().direct_space_state.intersect_ray(_ray_query)
	# A ray that starts inside a shape hits it at once, with no normal.
	if hit.is_empty() or hit.normal == Vector3.ZERO or not _is_floor(hit.normal):
		return NAN
	return (hit.position as Vector3).dot(up_direction)

#endregion


#region Sprint, jump and fall

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
	var speed := get_jump_speed()
	if speed <= 0.0:
		# Nothing to push off with: jump_height or gravity_scale is 0.
		return false
	# Within a tick the body moves at the speed it had at the start of the tick, so a jump at speed v would rise
	# v·dt/2 higher. With v − g·dt/2 on the takeoff tick, the positions on every tick lie exactly on the jump parabola.
	velocity.y = speed - get_gravity().length() * gravity_scale * delta / 2.0
	_jumping = true
	jumped.emit()
	return true


## Gravity for a tick in the air. Without fall settings ([method get_fall_settings]) it is the gravity of the place
## times [member gravity_scale], whichever way it pulls. With them the rise of a jump still slows down with
## [member gravity_scale], and the way down follows the settings; gravity along the ground (an area's) pulls as
## without them, and where gravity does not pull down at all, the settings have nothing to shape.
func _apply_gravity(delta: float) -> void:
	var gravity := get_gravity()
	var settings := get_fall_settings()
	var down := -gravity.dot(up_direction)
	if settings == null or down <= 0.0:
		velocity += gravity * gravity_scale * delta
		return
	velocity += (gravity + up_direction * down) * gravity_scale * delta
	var time := delta
	if velocity.y > 0.0:
		var rise := down * gravity_scale
		if velocity.y >= rise * delta:
			velocity.y -= rise * delta
			return
		# The top of the jump comes within this tick: the rest of the tick is already the fall.
		time -= velocity.y / rise
		velocity.y = 0.0
	velocity.y = -settings.get_next_speed(-velocity.y, down * settings.get_gravity_scale(gravity_scale), time)

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
	var start := global_transform
	move_and_slide()
	# The real velocity is the movement of the tick divided by its length: a tick of zero length (Engine.time_scale 0)
	# has none (0 / 0), and the body keeps the velocity it moved with.
	if delta > 0.0:
		var real := get_real_velocity()
		_move_velocity = Vector3(real.x, 0.0, real.z)
	if not jumping:
		_step_down(horizontal, start)


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
	_note_stair(_get_support_height(global_transform))
	global_position = place
	return true


## Keeps the character on the ground going down a stair: if it stood on the ground before the tick (at [param start])
## and is in the air now without a jump, and there is ground no deeper than [member max_step_height] under it (or a
## little farther along [param horizontal], the velocity of the tick), it is put on that ground.
func _step_down(horizontal: Vector3, start: Transform3D) -> void:
	if max_step_height <= 0.0 or not _was_on_floor or is_on_floor() or velocity.y > 0.0:
		return
	var place: Variant = _find_stair_place(0.0, horizontal.normalized(), 0.0)
	if place != null:
		_note_stair(_get_support_height(start))
		global_position = place
		apply_floor_snap()


## Remembers the stair for [signal stair_taken]: from the ground at [param from] to the ground of the place just found.
func _note_stair(from: float) -> void:
	if is_nan(from):
		return
	_stair_pending = true
	_stair_height = _place_ground - from


## The height of the ground that the body placed at [param from] stands on: of the point it touches, the edge of a
## stair too. NAN if the body does not touch the ground there.
func _get_support_height(from: Transform3D) -> float:
	var hit := KinematicCollision3D.new()
	if not test_move(from, -up_direction * _SUPPORT_PROBE, hit) or not _is_floor(hit.get_normal()):
		return NAN
	return hit.get_position().dot(up_direction)


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
			var ground := get_ground_height(hit.get_position() + direction * 0.05, 0.05, 0.1)
			var stair := absf(height) > 0.01 and absf(height) <= max_step_height + 0.01
			if stair and ground - feet <= max_step_height + 0.01:
				_place_ground = ground
				return place
		distance += _STAIR_SEARCH_STEP
	return null


## Whether ground with [param normal] is not too steep to stand on. The engine checks the body's floor with the same
## small margin over [member CharacterBody3D.floor_max_angle].
func _is_floor(normal: Vector3) -> bool:
	return normal.angle_to(up_direction) <= floor_max_angle + FLOOR_ANGLE_MARGIN

#endregion


#region What the tick changed

## Floor contact: [signal left_floor], [signal touched_floor] and [signal landed], the time in the air.
func _update_floor_contact(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		if not _was_on_floor:
			touched_floor.emit(_fall_speed)
			if _is_landing_speed(_fall_speed):
				landed.emit(_fall_speed)
				# The landing itself counts as a step: the next one comes after a full stride.
				_start_step_segment(stride_length)
		_air_time = 0.0
		_jumping = false
	else:
		if _was_on_floor:
			left_floor.emit()
		_air_time += delta
	_was_on_floor = on_floor


## Whether touching the ground at [param speed] is a landing: at least [member landing_min_speed]. A fall limited to
## exactly that speed lands: the body keeps its speed with less precision than the setting.
func _is_landing_speed(speed: float) -> bool:
	return speed >= landing_min_speed or is_equal_approx(speed, landing_min_speed)


## [signal stair_taken], if the body stepped onto a stair in this tick.
func _report_stair() -> void:
	if _stair_pending:
		_stair_pending = false
		stair_taken.emit(_stair_height)


## Steps follow the distance traveled on the ground: while the character stands (or is pressed against a wall) there
## are no steps, and once it starts moving, the first step comes after [member first_step_distance].
func _report_steps(delta: float) -> void:
	# A source that stopped the steps and was freed lets them go by itself.
	_update_counting_steps()
	if not _counting_steps or not is_on_floor():
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


## Whether steps are counted ([method is_counting_steps]). When they come back, the rhythm starts as from a
## standstill.
func _update_counting_steps() -> void:
	_step_suppressors = _step_suppressors.filter(func(ref: WeakRef) -> bool: return ref.get_ref() != null)
	var counting := steps_enabled and _step_suppressors.is_empty()
	if counting and not _counting_steps and is_node_ready():
		_start_step_segment(first_step_distance)
	_counting_steps = counting


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
		# The node faces along −Z; rotated by angle a, this direction is (−sin a, 0, −cos a). The facing is the world's,
		# and the node turns relative to its parent: the body may stand turned in the level.
		var target_yaw := atan2(-facing.x, -facing.z) - _get_visual_parent_yaw()
		visual.rotation.y = rotate_toward(visual.rotation.y, target_yaw, visual_turn_speed * delta)
	var yaw := _get_model_yaw()
	_turn_rate = angle_difference(_model_yaw, yaw) / delta if delta > 0.0 else 0.0
	_model_yaw = yaw


## How the parent of [member visual] is turned in the world around the vertical, from −Z: the model turns relative to
## it.
func _get_visual_parent_yaw() -> float:
	var parent := visual.get_parent_node_3d()
	if parent == null:
		return 0.0
	var forward := -parent.global_basis.z
	return atan2(-forward.x, -forward.z)


## Where the model faces, as a turn around the vertical from −Z: the model itself, or without it where the character
## should face.
func _get_model_yaw() -> float:
	var forward := -visual.global_basis.z if visual != null else mover.get_facing()
	return atan2(-forward.x, -forward.z)


## [param vector] (horizontal) in the model's axes: x is to the right, y is forward.
func _to_model_axes(vector: Vector3) -> Vector2:
	var forward := Vector3.FORWARD.rotated(Vector3.UP, _model_yaw)
	var right := forward.cross(Vector3.UP)
	return Vector2(vector.dot(right), vector.dot(forward))


## How the horizontal velocity the body is driven with changed since the last tick ([method get_local_acceleration]).
func _measure_acceleration(delta: float) -> void:
	var driven := Vector3(velocity.x, 0.0, velocity.z)
	_acceleration = (driven - _driven_velocity) / delta if delta > 0.0 else Vector3.ZERO
	_driven_velocity = driven


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
