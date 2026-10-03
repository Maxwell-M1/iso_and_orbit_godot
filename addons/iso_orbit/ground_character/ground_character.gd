class_name GroundCharacter
extends CharacterBody3D
## A character driven by [NavigationMover]: this is where gravity, jumping, sprinting, [method move_and_slide] and
## turning the model toward the running direction live.
##
## It does not matter who gives the commands: the player through [PointClickMoveInput] and [CharacterActionInput], an
## AI or a script call [method NavigationMover.move_to] and [method jump] and set [member sprint_requested]. So the
## same scene works for both the player and NPCs.
##
## The character reports what happens to it with signals ([signal stepped], [signal jumped], [signal landed],
## [signal sprint_changed]): sounds ([CharacterSounds]), dust from under the feet and animations hook onto them. The
## character itself knows nothing about sounds.

## The character pushed off the ground.
signal jumped
## The character landed. [param impact_speed] is the speed at which it was falling, m/s. Stepping off a stair or a
## bump (slower than [member landing_min_speed]) does not count as a landing.
signal landed(impact_speed: float)
## A foot touched the ground. Steps come every [member stride_length] traveled on the ground, so the faster the run,
## the more frequent the steps. [param sprinting] tells whether the character is sprinting.
signal stepped(sprinting: bool)
## The character started ([param sprinting] = [code]true[/code]) or stopped sprinting.
signal sprint_changed(sprinting: bool)

## The component that computes the horizontal velocity.
@export var mover: NavigationMover

## The model to turn so that it faces along the run (or where [method NavigationMover.get_facing] says, if the
## character walks sideways). Its "face" is the −Z direction.
@export var visual: Node3D

## How fast the model turns to catch up with the running direction.
@export_range(30.0, 3600.0, 1.0, "radians_as_degrees") var visual_turn_speed := deg_to_rad(1080.0)

## How many times stronger gravity is for the character than in the world. The character in the game runs faster than
## a human and with normal gravity falls "like a feather"; with 3 it drops from 1.6 m in 0.33 s instead of 0.57 s.
@export_range(0.0, 10.0, 0.05) var gravity_scale := 3.0

## Keeps the character from walking off cliffs. If not set, the character falls from any height. The guard does not
## hold back a jump.
@export var ledge_guard: LedgeGuard

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

@export_group("Jump")
## Whether the character can jump. When this is disabled, [method jump] does nothing.
@export var can_jump := true
## Jump height (of the feet), taking [member gravity_scale] into account.
@export_range(0.0, 5.0, 0.05, "suffix:m") var jump_height := 1.0
## How long a jump is still possible after stepping off an edge: a jump pressed slightly late is not lost.
@export_range(0.0, 0.5, 0.01, "suffix:s") var coyote_time := 0.1
## How long to remember a jump press in the air: a jump pressed slightly before landing fires on the ground.
@export_range(0.0, 0.5, 0.01, "suffix:s") var jump_buffer_time := 0.12
## A fall slower than this does not count as a landing ([signal landed]): stepping off a stair is not a jump.
@export_range(0.0, 20.0, 0.1, "suffix:m/s") var landing_min_speed := 2.5

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

var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _was_on_floor := true
var _to_next_step := 0.0
# The stretch of path to the next step: its length (first_step_distance from a standstill, stride_length after that)
# and the step rhythm (get_step_phase) at its start and at its end; at the end it is always a whole number, the
# moment of the step.
var _step_segment := 0.0
var _phase_from := 0.0
var _phase_to := 1.0


func _ready() -> void:
	assert(mover != null, "GroundCharacter needs the mover property set.")
	_to_next_step = first_step_distance
	_step_segment = first_step_distance


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
	var fall_speed := -velocity.y
	move_and_slide()
	_report_landing(fall_speed)
	_report_steps(delta)
	_turn_visual(delta)


## Jump as soon as the character is on the ground (or right away if it is on the ground or has just stepped off it).
func jump() -> void:
	if not can_jump:
		return
	_jump_buffer_left = jump_buffer_time if jump_buffer_time > 0.0 else get_physics_process_delta_time()


## The character is sprinting now.
func is_sprinting() -> bool:
	return mover.sprinting


## Sprinting is not possible now: sprinting is tiring, and the character is exhausted.
func is_exhausted() -> bool:
	return sprint_tires and stamina != null and not stamina.can_spend()


## Step rhythm for animations: how many steps have been taken, as a fraction. A whole value is the moment of a step
## ([signal stepped]); between steps the fractional part grows from 0 to 1 with the distance traveled. While the
## character stands, the value does not change.
func get_step_phase() -> float:
	var progress := clampf(1.0 - _to_next_step / maxf(_step_segment, 0.001), 0.0, 1.0)
	return lerpf(_phase_from, _phase_to, progress)


## Initial jump speed for [member jump_height]: v = √(2·g·h).
func get_jump_speed() -> float:
	return sqrt(2.0 * get_gravity().length() * gravity_scale * jump_height)


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
	jumped.emit()
	return true


func _report_landing(fall_speed: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and fall_speed >= landing_min_speed:
		landed.emit(fall_speed)
		# The landing itself counts as a step: the next one comes after a full stride.
		_start_step_segment(stride_length)
	_was_on_floor = on_floor


## Steps follow the distance traveled on the ground: while the character stands (or is pressed against a wall) there
## are no steps, and once it starts moving, the first step comes after [member first_step_distance].
func _report_steps(delta: float) -> void:
	if not is_on_floor():
		return
	var real := get_real_velocity()
	var speed := Vector2(real.x, real.z).length()
	if speed < 0.1:
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


func _turn_visual(delta: float) -> void:
	if visual == null:
		return
	var facing := mover.get_facing()
	# The node faces along −Z; rotated by angle a, this direction is (−sin a, 0, −cos a).
	var target_yaw := atan2(-facing.x, -facing.z)
	visual.rotation.y = rotate_toward(visual.rotation.y, target_yaw, visual_turn_speed * delta)
