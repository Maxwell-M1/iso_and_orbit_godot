class_name HandSway
extends Node
## Brings the model's "invisible hand" to life: the item in it (a staff) moves as it would in the hand of a walking
## person.
##
## - In time with the steps ([method GroundCharacter.get_step_phase]) the hand swings back and forth, the item lags
##   slightly behind in tilt, and the hand dips on every step. The swing grows with speed (more when sprinting); when
##   the character stands or is in the air, the hand smoothly returns to its place.
## - While running, the item leans forward.
## - Inertia: when accelerating, braking and turning, the item lags behind and sways on a spring; on landing and on
##   the jump push-off, the hand sags.
##
## Moves the hand node relative to its position in the model. Runs in the physics tick after the character (the node
## is its child or has a higher priority), so physics interpolation smooths the movement, just as it does for the body.

## The character whose steps and speed to track.
@export var character: GroundCharacter

## The hand node in the model (for example, [code]Visual/Model/RightHand[/code]). The model faces −Z. When the model
## is changed ([CharacterAppearance]), assign the new model's hand: its current position becomes the hand's place.
@export var hand: Node3D:
	set(value):
		hand = value
		if hand != null:
			_rest = hand.transform

@export_group("Swing")
## How far the hand moves forward and back from the middle position during a normal run.
@export_range(0.0, 0.5, 0.005, "suffix:m") var swing_distance := 0.07
## How much the item lags behind in tilt meanwhile: with the hand in front, the top leans back.
@export_range(0.0, 45.0, 0.5, "radians_as_degrees") var swing_tilt := deg_to_rad(7.0)
## How far the hand dips on a step.
@export_range(0.0, 0.2, 0.005, "suffix:m") var step_drop := 0.025
## Forward lean of the item during a normal run.
@export_range(0.0, 45.0, 0.5, "radians_as_degrees") var run_lean := deg_to_rad(6.0)
## How many times the swing may exceed the swing of a normal run (sprint).
@export_range(1.0, 3.0, 0.05) var max_swing_scale := 1.5
## How fast the swing catches up with the speed, 1/s.
@export_range(0.5, 30.0, 0.5) var swing_response := 8.0

@export_group("Inertia")
## Item tilt per 1 m/s² of body acceleration: back when speeding up, forward when braking, outward in turns.
@export_range(0.0, 5.0, 0.01, "radians_as_degrees") var tilt_per_acceleration := deg_to_rad(0.45)
## Inertia does not tilt the item more than this.
@export_range(0.0, 60.0, 0.5, "radians_as_degrees") var max_inertia_tilt := deg_to_rad(14.0)
## Downward kick of the hand on landing, per 1 m/s of fall speed.
@export_range(0.0, 0.5, 0.005) var landing_kick := 0.06
## Downward kick of the hand when the character pushes off for a jump.
@export_range(0.0, 2.0, 0.01, "suffix:m/s") var jump_kick := 0.3
## The hand does not sag more than this.
@export_range(0.0, 0.5, 0.005, "suffix:m") var max_drop := 0.08
## Spring frequency: the higher it is, the faster the item returns.
@export_range(0.1, 10.0, 0.05, "suffix:Hz") var spring_frequency := 1.8
## Spring damping: at 1 the item returns without swaying; below 1 it sways.
@export_range(0.05, 2.0, 0.01) var spring_damping := 0.45

## A damped spring: the value is pulled toward the target and, if damping is below 1, oscillates around it.
class Spring:
	var value := 0.0
	var speed := 0.0

	func update(target: float, frequency: float, damping: float, delta: float) -> float:
		var omega := TAU * frequency
		speed += (omega * omega * (target - value) - 2.0 * damping * omega * speed) * delta
		value += speed * delta
		return value


var _rest := Transform3D.IDENTITY
var _swing_scale := 0.0
var _last_velocity := Vector3.ZERO
var _pitch := Spring.new()
var _roll := Spring.new()
var _drop := Spring.new()


func _init() -> void:
	# After the character's body: its velocity and steps for this tick are already computed.
	process_physics_priority = 1


func _ready() -> void:
	assert(character != null, "HandSway needs the character property set.")
	character.landed.connect(_on_landed)
	character.jumped.connect(_on_jumped)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(hand):
		return
	var velocity := character.get_real_velocity()
	var on_floor := character.is_on_floor()
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	var full_speed := character.mover.settings.max_speed
	var target_scale := clampf(planar.length() / full_speed, 0.0, max_swing_scale) if on_floor else 0.0
	_swing_scale = lerpf(_swing_scale, target_scale, 1.0 - exp(-swing_response * delta))

	# Body acceleration in the model's axes: −Z is forward, +X is right.
	var acceleration := (planar - _last_velocity) / delta
	_last_velocity = planar
	var local := hand.get_parent_node_3d().global_basis.orthonormalized().inverse() * acceleration
	var forward_acceleration := -local.z
	var right_acceleration := local.x
	# Accelerating forward tilts the top back (+X rotation); accelerating right tilts the top left (+Z rotation).
	var pitch_target := clampf(forward_acceleration * tilt_per_acceleration, -max_inertia_tilt, max_inertia_tilt)
	var roll_target := clampf(right_acceleration * tilt_per_acceleration, -max_inertia_tilt, max_inertia_tilt)
	_pitch.update(pitch_target, spring_frequency, spring_damping, delta)
	_roll.update(roll_target, spring_frequency, spring_damping, delta)
	_drop.update(0.0, spring_frequency, spring_damping, delta)
	_drop.value = clampf(_drop.value, -max_drop, max_drop)

	# A step is the extreme position of the hand (cos = ±1) and the lowest point; halfway between steps the hand is in
	# the middle.
	var phase := character.get_step_phase()
	var swing := cos(PI * phase) * _swing_scale
	var dip := (1.0 + cos(TAU * phase)) * 0.5 * _swing_scale
	var pitch := swing * swing_tilt - minf(_swing_scale, 1.0) * run_lean + _pitch.value
	var offset := Vector3(0.0, -dip * step_drop + _drop.value, -swing * swing_distance)
	var tilt := Basis.from_euler(Vector3(pitch, 0.0, _roll.value))
	hand.transform = Transform3D(tilt * _rest.basis, _rest.origin + offset)


func _on_landed(impact_speed: float) -> void:
	_drop.speed -= impact_speed * landing_kick


func _on_jumped() -> void:
	_drop.speed -= jump_kick
