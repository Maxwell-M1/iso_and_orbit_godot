class_name StaminaBar
extends ProgressBar
## The character's stamina bar ([Stamina]). It is visible while stamina is not full, and once stamina has recovered,
## it fades out smoothly. While the character is exhausted, the bar has another theme variation
## ([member exhausted_variation]).

## Whose stamina to show.
@export var stamina: Stamina

## How many seconds the bar takes to fade out once stamina has recovered.
@export_range(0.0, 5.0, 0.05, "suffix:s") var fade_time := 0.6

## The theme variation while the character has stamina.
@export var normal_variation := &"StaminaBar"

## The theme variation while the character is exhausted.
@export var exhausted_variation := &"StaminaBarExhausted"


func _ready() -> void:
	if stamina == null:
		hide()
		set_process(false)
		return
	stamina.changed.connect(_on_stamina_changed)
	stamina.exhausted_changed.connect(_on_exhausted_changed)
	_on_stamina_changed(stamina.get_ratio())
	_on_exhausted_changed(stamina.is_exhausted())
	modulate.a = 0.0 if _is_full() else 1.0


func _process(delta: float) -> void:
	# It appears at once, as soon as stamina starts being spent, and fades out smoothly.
	if not _is_full():
		modulate.a = 1.0
	elif fade_time <= 0.0:
		modulate.a = 0.0
	else:
		modulate.a = move_toward(modulate.a, 0.0, delta / fade_time)


func _on_stamina_changed(fraction: float) -> void:
	value = fraction * max_value


func _on_exhausted_changed(exhausted: bool) -> void:
	theme_type_variation = exhausted_variation if exhausted else normal_variation


func _is_full() -> bool:
	return value >= max_value
