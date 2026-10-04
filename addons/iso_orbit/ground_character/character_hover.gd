class_name CharacterHover
extends Node3D
## Makes a [GroundCharacter] float: the model hangs [member height] above the ground, glides over stairs instead of
## jumping onto them, sways gently up and down, leans toward the movement and into the acceleration, and sags as the
## character touches the ground. Only the model moves; the body walks as usual: slopes, stairs, jumps and the ledge
## guard work the same. Only its fall can change: a floating character may come down more slowly ([member fall]).
##
## The node goes between the node that the character turns ([member GroundCharacter.visual]) and the model:
## [code]Visual/Hover/Model[/code]. It moves itself (rises and tilts), and the model under it follows, so the character
## and the hover never write the same node. New looks of [CharacterAppearance] must go under the hover too
## ([member CharacterAppearance.slot]).
##
## A floating character has no legs: while it floats, the hover stops its steps
## ([method GroundCharacter.set_steps_suppressed]): no [signal GroundCharacter.stepped], no footstep sounds, no step
## swing of [HandSway]. Once the model has settled on the ground, the hover lets the steps go, and they are counted
## again if [member GroundCharacter.steps_enabled] is on. [member steps_while_floating] keeps the steps.
##
## The fall: with [member fall] set, the character falls by it while the model floats
## ([method GroundCharacter.set_fall_override] with priority 0, put in place at the start of each rise): after the top
## of a jump and off an edge it gains speed more slowly, up to a limit, and touches the ground softly. The rise of a
## jump stays the same. Once the model has settled, the character falls by its own settings again. A fall that the
## game puts in place with a higher priority wins over the hover's.
##
## The glide over stairs: the model floats over the ground a little ahead of the body, as far as the body runs in a
## third of [member glide_time], and settles at its height in that time. So it starts to rise before a stair, goes up
## a flight along a smooth line, follows a ramp without lag, and stays level before a ledge or a wall that the body
## will not pass. In the air and on the tick of landing it moves with the body; what was left of the glide at the
## take-off fades out. The ground is checked with rays: up to seven per tick while the character floats and runs, one
## while it stands, none in the air or while it does not float.
##
## Runs in the physics tick after the character (its priority is higher), so physics interpolation smooths the model
## just as it smooths the body. When the character is teleported and its physics interpolation is reset
## ([method Node.reset_physics_interpolation]), the model is put in place at once. A mistake in the setup is printed as
## a warning when the node enters the tree ([method get_setup_warnings]).

## The model started to rise ([param floating] is [code]true[/code]) or has settled back onto the ground.
signal floating_changed(floating: bool)

# A horizontal move of the body farther than this in one tick is a teleport: the model is put in place at once, m.
const _TELEPORT_DISTANCE := 1.0
# The way ahead is checked in pieces no longer than this, and in no more pieces than this, m.
const _GROUND_PIECE := 0.15
const _MAX_GROUND_PIECES := 6
# A little above the ground the body stands on and a little higher than a stair is still ground, m.
const _GROUND_MARGIN := 0.02
# Slopes steeper than this are followed as if they were this steep: a slope near 90° would let a piece of the way
# rise as high as a wall.
const _MAX_SLOPE := deg_to_rad(60.0)
# In about how long the sway follows a change of speed, s.
const _MOTION_SMOOTHING := 0.25

## The character to make float. If not set, the nearest [GroundCharacter] above this node.
@export var character: GroundCharacter

## Float. Turned on, the model rises in [member rise_time]; turned off, it settles back onto the ground in the same
## time. Set before the first physics tick (in the scene, or by the game's settings at startup), it takes effect at
## once.
@export var enabled := true:
	set(value):
		if value == enabled:
			return
		enabled = value
		if _ticked:
			_update_floating()
		elif is_node_ready():
			snap()
		else:
			_share = 1.0 if value else 0.0

## How high above the ground the model floats: its origin (the feet) above the ground under it, m.
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:m") var height := 0.35

## How long the model takes to rise to [member height] when floating is turned on, and to settle when it is turned off:
## it starts and ends the move softly. 0 is at once.
@export_range(0.0, 3.0, 0.01, "suffix:s") var rise_time := 0.5

## Keep the steps while floating: [signal GroundCharacter.stepped] with its rhythm, the footstep sounds, the step
## swing. Off, the hover stops the steps while the character floats.
@export var steps_while_floating := false:
	set(value):
		steps_while_floating = value
		_update_steps()

## How the character falls while it floats ([FallSettings]): more slowly, for example, with a weaker gravity and a
## speed limit. It is put in place of the character's own fall ([member GroundCharacter.fall]) from the start of the
## rise until the model has settled on the ground. Empty: the character falls as it does without floating.
@export var fall: FallSettings:
	set(value):
		fall = value
		_update_fall()

@export_group("Glide")
## In how long the model settles at a new height of the ground (95% of the way): the longer, the smoother it glides
## over stairs. The ground is looked for ahead as far as the body runs in a third of this time, but not farther than
## 0.9 m: a longer time at a high speed lets the model lag behind a little on a ramp. 0 follows the ground under the
## body exactly, with every stair.
@export_range(0.0, 1.0, 0.01, "suffix:s") var glide_time := 0.3

@export_group("Sway")
## How far the model sways up and down from [member height] while the character stands, m. Never deeper than the
## height itself: the model does not dip into the ground.
@export_range(0.0, 0.5, 0.005, "suffix:m") var bob_height := 0.04
## How long one sway up and down takes while the character stands. The sway runs on time, so the model sways in place
## too.
@export_range(0.5, 10.0, 0.05, "suffix:s") var bob_period := 2.4
## The sway at the running speed, as a share of [member bob_height]: below 1 it calms down while running. Between
## standing and running it changes in proportion to the speed.
@export_range(0.0, 2.0, 0.05) var run_bob_scale := 0.5
## How many times faster the model sways at the running speed. Between standing and running it changes in proportion
## to the speed.
@export_range(0.25, 4.0, 0.05) var run_bob_rate := 1.5
## Start at a random point of the sway, so that several floating characters do not sway in unison.
@export var random_bob_phase := true

@export_group("Tilt")
## How far the model leans toward the movement at the running speed: forward when running, to the side when moving
## sideways, back when backing up.
@export_range(0.0, 45.0, 0.5, "radians_as_degrees") var run_lean := deg_to_rad(8.0)
## How many times the lean may exceed the lean at the running speed (sprint).
@export_range(1.0, 3.0, 0.05) var max_lean_scale := 1.5
## The point the model tilts around: this high above its feet, m. About the waist, so that the feet do not swing wide.
@export_range(0.0, 3.0, 0.01, "suffix:m") var tilt_pivot_height := 0.9

@export_group("Inertia")
## Tilt per 1 m/s² of acceleration ([method GroundCharacter.get_local_acceleration]), as in [HandSway]: positive lags
## behind (back when speeding up, outward in turns), like a weight on a string; negative tilts into the acceleration
## (forward when speeding up, back when braking, into a turn), as a hovering craft does.
@export_range(-5.0, 5.0, 0.01, "radians_as_degrees") var tilt_per_acceleration := deg_to_rad(-0.25)
## The acceleration does not tilt the model more than this, in any direction.
@export_range(0.0, 60.0, 0.5, "radians_as_degrees") var max_inertia_tilt := deg_to_rad(15.0)
## Downward push of the model when the character touches the ground ([signal GroundCharacter.touched_floor]), per
## 1 m/s of fall speed: a slow touchdown sags the model a little, a hard landing more.
@export_range(0.0, 0.5, 0.005) var landing_kick := 0.05
## Downward push of the model when the character pushes off for a jump.
@export_range(0.0, 2.0, 0.01, "suffix:m/s") var jump_kick := 0.3
## The model does not sag (or bounce up) more than this, and never more than its height above the ground.
@export_range(0.0, 0.5, 0.005, "suffix:m") var max_drop := 0.15
## Spring frequency of the sag and of both tilts: the higher, the faster the model returns.
@export_range(0.1, 10.0, 0.05, "suffix:Hz") var spring_frequency := 1.5
## Spring damping: at 1 the model returns without swaying; below 1 it sways.
@export_range(0.05, 2.0, 0.01) var spring_damping := 0.5

# How far the rise has gone: 0 on the ground, 1 at full height (linear; the model moves by its eased value).
var _share := 0.0
# The first physics tick has passed: from then on, turning floating on or off is a rise or a settling.
var _ticked := false
var _floating := false
var _suppressing_steps := false
# The fall put in place of the character's own while floating (GroundCharacter.set_fall_override), or null.
var _applied_fall: FallSettings
# The height of the ground that the model floats over (smoothed, in the world); whether it still has to be found (after
# a snap); the body a tick ago and whether it was in the air.
var _base := 0.0
var _base_unknown := true
var _last_position := Vector3.ZERO
var _in_air := false
# The sway: the point of its cycle (0 to 1) and the movement (0 standing, 1 running), smoothed.
var _bob_phase := 0.0
var _motion := 0.0
var _height_now := 0.0
var _rest := Transform3D.IDENTITY
var _snapping := false
var _pitch := DampedSpring.new()
var _roll := DampedSpring.new()
var _drop := DampedSpring.new()


func _init() -> void:
	# After the character's body: its position and velocity for this tick are already computed.
	process_physics_priority = 1


func _ready() -> void:
	if character == null:
		character = _find_character()
	assert(character != null,
			"CharacterHover needs a GroundCharacter: set the character property or put the node under one.")
	for warning in get_setup_warnings():
		push_warning("%s: %s" % [name, warning])
	_rest = transform
	_bob_phase = randf() if random_bob_phase else 0.0
	character.touched_floor.connect(_on_touched_floor)
	character.jumped.connect(_on_jumped)
	snap()


func _enter_tree() -> void:
	# Back in the tree while floating: the steps stop again, and the fall is put in place again.
	_update_steps()
	_update_fall()


func _exit_tree() -> void:
	# Out of the tree the hover does not move the model: it lets the steps and the fall go.
	_set_suppressing_steps(false)
	_set_fall(null)


func _notification(what: int) -> void:
	# The character was teleported and its interpolation reset (the notification goes down to its children).
	if what == NOTIFICATION_RESET_PHYSICS_INTERPOLATION and not _snapping and is_node_ready():
		snap()


func _physics_process(delta: float) -> void:
	_ticked = true
	var body_position := character.global_position
	if Vector2(body_position.x - _last_position.x, body_position.z - _last_position.z).length() > _TELEPORT_DISTANCE:
		snap()
		return
	var previous_feet := _last_position.y
	_last_position = body_position
	var target := 1.0 if enabled else 0.0
	_share = move_toward(_share, target, delta / rise_time) if rise_time > 0.0 else target
	_update_floating()
	if not _floating:
		_rest_in_place()
		return
	_update_ground(delta, previous_feet)
	var bob := _update_bob(delta)
	_update_springs(delta)
	_apply(bob)


## Whether the model floats now: from the start of the rise until it has settled back onto the ground.
func is_floating() -> bool:
	return _floating


## How high above the body's feet the model is now, m: [member height] with the sway, the glide over stairs and the
## sag while floating, 0 on the ground.
func get_hover_height() -> float:
	return _height_now


## Puts the model in its place at once, without the rise, the glide and the springs: after the character is
## teleported, for example. Resetting the character's physics interpolation does it too, and so does a move of more
## than a meter in one tick. Floating or not follows [member enabled].
func snap() -> void:
	if character == null:
		return
	_share = 1.0 if enabled else 0.0
	_update_floating()
	_last_position = character.global_position
	_base = _last_position.y
	_base_unknown = true
	_in_air = not character.is_on_floor()
	_motion = 0.0
	_reset_springs()
	if _floating:
		_apply(_get_bob())
	else:
		_rest_in_place()
	_snapping = true
	reset_physics_interpolation()
	_snapping = false


## Problems in how the hover is set up, one line each; empty if there are none.
func get_setup_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var target := character if character != null else _find_character()
	if target == null:
		warnings.append("No GroundCharacter: set the character property or put the node under one.")
		return warnings
	if target.visual == null or not target.visual.is_ancestor_of(self):
		warnings.append("The hover must be under the character's visual node: the model turns with that node.")
	if get_child_count() == 0:
		warnings.append("Nothing to lift: put the model under the hover.")
	for node in target.find_children("*", "", true, false):
		if node is CharacterHover and node != self:
			warnings.append("Another CharacterHover on the same character: the model would rise twice.")
		elif node is CharacterAppearance:
			var slot := (node as CharacterAppearance).slot
			if slot != null and slot != self and not is_ancestor_of(slot):
				warnings.append("CharacterAppearance.slot is not the hover: new looks would not float.")
	return warnings


## At the start of the rise and once the model has settled: whether it floats, the steps, the fall,
## [signal floating_changed].
func _update_floating() -> void:
	var floating := enabled or _share > 0.0
	if floating == _floating:
		return
	_floating = floating
	if not floating:
		# The next rise starts from rest.
		_reset_springs()
	_update_steps()
	_update_fall()
	floating_changed.emit(floating)


## While the model floats in the tree, the steps are stopped (unless [member steps_while_floating]).
func _update_steps() -> void:
	_set_suppressing_steps(_floating and not steps_while_floating and is_inside_tree())


func _set_suppressing_steps(suppress: bool) -> void:
	if character != null and suppress != _suppressing_steps:
		_suppressing_steps = suppress
		character.set_steps_suppressed(self, suppress)


## While the model floats in the tree, the character falls by [member fall].
func _update_fall() -> void:
	_set_fall(fall if _floating and is_inside_tree() else null)


func _set_fall(settings: FallSettings) -> void:
	if character != null and settings != _applied_fall:
		_applied_fall = settings
		character.set_fall_override(self, settings)


## The height of the ground that the model floats over. In the air, and on the tick of landing, it moves along with
## the body, and what was left of the glide at the take-off fades out. On the ground it moves toward the ground ahead
## of the body, so that only the stairs are smoothed.
func _update_ground(delta: float, previous_feet: float) -> void:
	var feet := character.global_position.y
	var on_floor := character.is_on_floor()
	if not on_floor or _in_air:
		_base += feet - previous_feet
	_in_air = not on_floor
	# exp(-3) ≈ 0.05: in glide_time, 5% of the way remains.
	var time := glide_time / 3.0
	if time <= 0.0 or _base_unknown:
		_base = _find_ground(Vector3.ZERO) if on_floor else feet
		_base_unknown = false
		return
	var weight := 1.0 - exp(-delta / time)
	if on_floor:
		# Looking ahead as far as the smoothing lags behind cancels its lag on a ramp. Moved by a share of the way each
		# tick, it lags behind a steady climb by delta * (1 - weight) / weight seconds, a little less than the time.
		var lead := delta * (1.0 - weight) / weight
		var ahead := (character.get_move_velocity() * lead).limit_length(_GROUND_PIECE * _MAX_GROUND_PIECES)
		_base = lerpf(_base, _find_ground(ahead), weight)
	else:
		_base = lerpf(_base, feet, weight)


## The height of the ground under the body, or [param ahead] farther along its way. The way is checked in pieces of
## up to [constant _GROUND_PIECE] from the body on, and on each the ground may rise or drop no more than a stair or the
## steepest slope allows: the search stops before a ledge, a gap or a wall that the body will not pass, and the model
## does not dip or rise there.
func _find_ground(ahead: Vector3) -> float:
	var feet := character.global_position
	var slope := _GROUND_PIECE * tan(minf(character.floor_max_angle, _MAX_SLOPE))
	var reach := maxf(character.max_step_height, slope) + _GROUND_MARGIN
	var ground := character.get_ground_height(feet, _GROUND_MARGIN, reach)
	if is_nan(ground):
		ground = feet.y
	var count := ceili(ahead.length() / _GROUND_PIECE)
	for i in range(1, count + 1):
		var point := feet + ahead * (float(i) / count)
		point.y = ground
		var next := character.get_ground_height(point, reach, reach)
		if is_nan(next):
			break
		ground = next
	return ground


## Advances the sway by [param delta] and returns its offset, m. Its rate and size follow the speed smoothly: from
## standing ([member bob_period], [member bob_height]) to running ([member run_bob_rate], [member run_bob_scale]).
func _update_bob(delta: float) -> float:
	var moving := minf(character.get_locomotion_blend(), 1.0)
	_motion = lerpf(_motion, moving, 1.0 - exp(-delta / _MOTION_SMOOTHING))
	# The point of the cycle grows with time: a change of the rate never makes the sway jump.
	var rate := lerpf(1.0, run_bob_rate, _motion) / maxf(bob_period, 0.1)
	_bob_phase = fposmod(_bob_phase + delta * rate, 1.0)
	return _get_bob()


func _get_bob() -> float:
	return sin(TAU * _bob_phase) * minf(bob_height * lerpf(1.0, run_bob_scale, _motion), height)


## The lean toward the movement, the tilt from the acceleration and the sag, on springs.
func _update_springs(delta: float) -> void:
	var lean := character.get_local_movement().limit_length(max_lean_scale) * run_lean
	var inertia := (character.get_local_acceleration() * tilt_per_acceleration).limit_length(max_inertia_tilt)
	# Rotation around X tilts the top back, around Z to the left: leaning toward the movement forward (+y) and to the
	# right (+x) is negative, while the inertia, as in HandSway, turns the top back and to the left (positive).
	_pitch.update(inertia.y - lean.y, spring_frequency, spring_damping, delta)
	_roll.update(inertia.x - lean.x, spring_frequency, spring_damping, delta)
	_drop.update(0.0, spring_frequency, spring_damping, delta)
	_drop.keep_within(minf(max_drop, _get_lift() * height))


## Raises and tilts the node: [member height] above the ground with the sway [param bob], tilted around
## [member tilt_pivot_height] in the axes of the character's facing, all in proportion to how far the rise has gone.
func _apply(bob: float) -> void:
	var lift := _get_lift()
	_height_now = lift * (_base - character.global_position.y + height + bob) + _drop.value
	var tilt := Basis.from_euler(Vector3(_pitch.value * lift, 0.0, _roll.value * lift))
	var pivot := Vector3.UP * tilt_pivot_height
	# In the parent's axes, so that a turn of the node itself (for a model that faces another way) does not turn the
	# lean.
	transform = Transform3D(tilt, Vector3.UP * _height_now + pivot - tilt * pivot) * _rest


## How far the rise has gone, eased: it starts and ends softly.
func _get_lift() -> float:
	return smoothstep(0.0, 1.0, _share)


## On the ground: the node in its place, the ground under the body.
func _rest_in_place() -> void:
	_base = character.global_position.y
	_base_unknown = true
	_in_air = not character.is_on_floor()
	_height_now = 0.0
	if transform != _rest:
		transform = _rest


func _reset_springs() -> void:
	for spring: DampedSpring in [_pitch, _roll, _drop]:
		spring.reset()


func _find_character() -> GroundCharacter:
	var node := get_parent()
	while node != null and not node is GroundCharacter:
		node = node.get_parent()
	return node as GroundCharacter


func _on_touched_floor(fall_speed: float) -> void:
	if _floating:
		_drop.speed -= fall_speed * landing_kick


func _on_jumped() -> void:
	if _floating:
		_drop.speed -= jump_kick
