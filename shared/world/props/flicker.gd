extends Light3D
## Fire flicker: the brightness wanders around the original value following smooth noise.

## How far the brightness departs from the original (a fraction).
@export_range(0.0, 1.0, 0.01) var strength := 0.25
## How fast it flickers.
@export_range(0.1, 20.0, 0.1) var speed := 6.0

var _base_energy := 0.0
var _time := 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	_base_energy = light_energy
	_noise.seed = get_instance_id()
	_noise.frequency = 1.0
	_time = randf() * 100.0


func _process(delta: float) -> void:
	_time += delta * speed
	light_energy = _base_energy * (1.0 + strength * _noise.get_noise_1d(_time))
