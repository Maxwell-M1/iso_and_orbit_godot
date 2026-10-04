class_name DampedSpring
extends RefCounted
## A damped spring for one value: the value is pulled toward a target and, with damping below 1, overshoots and sways
## around it before it settles. [HandSway] and [CharacterHover] use it for inertia: an item lagging behind in tilt, a
## sag on landing.
##
## Call [method update] every physics tick. A push is a change of [member speed]: for example, a landing at
## [code]impact[/code] m/s pushes the value down with [code]spring.speed -= impact * kick[/code], and the spring brings
## it back.

## The current value.
var value := 0.0
## How fast the value changes now, per second.
var speed := 0.0


## Moves the value [param delta] seconds toward [param target] and returns it. [param frequency] is how many times per
## second the value would sway without damping, Hz: the higher it is, the faster the value returns. [param damping] at
## 1 returns the value without overshoot; below 1 it sways, the lower the longer.
func update(target: float, frequency: float, damping: float, delta: float) -> float:
	var omega := TAU * frequency
	# A stiff or strongly damped spring would overshoot farther each tick and fly apart: such a tick is split into
	# several short ones. A soft spring takes one step.
	var steps := maxi(1, ceili(omega * delta * maxf(1.0, 2.0 * damping)))
	var step := delta / steps
	for i in steps:
		speed += (omega * omega * (target - value) - 2.0 * damping * omega * speed) * step
		value += speed * step
	return value


## Keeps the value within ±[param limit]: at the limit the value stops, and the spring brings it back from there.
func keep_within(limit: float) -> void:
	if absf(value) > limit:
		value = clampf(value, -limit, limit)
		speed = 0.0


## Puts the value at [param at] at rest.
func reset(at := 0.0) -> void:
	value = at
	speed = 0.0
