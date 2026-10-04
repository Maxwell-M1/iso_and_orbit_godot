class_name FallSettings
extends Resource
## How a [GroundCharacter] falls: how fast the fall gains speed, the fastest fall, and how a faster fall slows down to
## it.
##
## The character falls by its own [member GroundCharacter.fall]. A component can put its own fall in its place for a
## while ([method GroundCharacter.set_fall_override]), as [CharacterHover] does with its [member CharacterHover.fall]
## while the character floats. Only the way down changes: after the top of a jump and off an edge. The rise of a jump
## keeps [member GroundCharacter.gravity_scale], so a jump is [member GroundCharacter.jump_height] high whatever the
## fall.
##
## A separate resource, so that the same fall can be given to several characters and tuned in the inspector while the
## game is running. A new resource changes nothing: the character's own gravity and no limit.

## How many times stronger gravity is for the falling character than in the world, as
## [member GroundCharacter.gravity_scale] is for the rise: how fast the fall gains speed. Lower than the character's
## own scale, the character comes down more slowly than it goes up. 0 takes the character's own scale, so that only
## the limit changes.
@export_range(0.0, 10.0, 0.05) var gravity_scale := 0.0

## The fastest fall, m/s: the fall gains speed up to it and then goes on at it. 0 is no limit. A fall that gains speed
## only up to a limit below [member GroundCharacter.landing_min_speed] never lands
## ([signal GroundCharacter.landed]), it only touches the ground.
@export_range(0.0, 50.0, 0.1, "or_greater", "suffix:m/s") var max_speed := 0.0

## In how long a fall faster than [member max_speed] slows down to it (95% of the excess speed is gone): after the
## character is thrown down, or when these settings come into effect mid-fall (floating turned on, for example). 0 is
## at once.
@export_range(0.0, 2.0, 0.01, "suffix:s") var braking_time := 0.3


## The gravity scale of the fall for a character whose own scale is [param own]: [member gravity_scale], or
## [param own] if it is 0.
func get_gravity_scale(own: float) -> float:
	return gravity_scale if gravity_scale > 0.0 else own


## The fall speed after falling [param delta] seconds at [param speed], m/s (downward is positive), when the fall gains
## [param acceleration], m/s² (the gravity times [method get_gravity_scale]): it grows up to [member max_speed]; above
## [member max_speed] it comes down to it in [member braking_time].
func get_next_speed(speed: float, acceleration: float, delta: float) -> float:
	if max_speed <= 0.0:
		return speed + acceleration * delta
	if speed <= max_speed:
		return minf(speed + acceleration * delta, max_speed)
	if braking_time <= 0.0:
		return max_speed
	# exp(-3) ≈ 0.05: in braking_time, 5% of the excess remains.
	return max_speed + (speed - max_speed) * exp(-3.0 * delta / braking_time)
