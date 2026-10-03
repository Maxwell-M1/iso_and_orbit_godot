extends Node3D
## Slowly spins and bobs up and down (the crystal on the peak). It moves every frame, so the node does not need
## physics interpolation.

@export_range(-360.0, 360.0, 1.0, "radians_as_degrees") var spin_speed := deg_to_rad(35.0)
@export_range(0.0, 2.0, 0.01, "suffix:m") var bob_height := 0.12
@export_range(0.1, 20.0, 0.1, "suffix:s") var bob_period := 3.0

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_base_y = position.y


func _process(delta: float) -> void:
	_time += delta
	rotate_y(spin_speed * delta)
	position.y = _base_y + sin(TAU * _time / bob_period) * bob_height
