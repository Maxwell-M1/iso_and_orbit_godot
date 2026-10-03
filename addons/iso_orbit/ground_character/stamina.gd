class_name Stamina
extends Node
## Stamina: it is spent on tiring actions (sprinting) and recovers while the character does not spend it.
##
## When stamina runs out, the character is exhausted: stamina cannot be spent until it recovers to
## [member recover_ratio]. This way fatigue builds up: sprinting for long is not possible, and an exhausted character
## only runs normally for a while.
##
## The component knows nothing about what stamina is spent on: the owner asks [method can_spend] and calls
## [method spend]. Stamina recovers by itself, [member recovery_delay] after it was last spent.

## Stamina changed. [param ratio] is the fraction of the full amount, from 0 to 1.
signal changed(ratio: float)
## The character became exhausted ([param exhausted] = [code]true[/code]) or has rested enough to spend stamina again.
signal exhausted_changed(exhausted: bool)

## The full amount of stamina.
@export_range(1.0, 1000.0, 1.0) var max_value := 100.0

## How much stamina recovers per second.
@export_range(0.1, 1000.0, 0.1, "suffix:/s") var recovery_rate := 12.5

## How many seconds after spending stamina starts to recover.
@export_range(0.0, 10.0, 0.05, "suffix:s") var recovery_delay := 1.0

## An exhausted character can spend stamina again once it has recovered this fraction of the full amount.
@export_range(0.0, 1.0, 0.01) var recover_ratio := 0.3

var _value := 0.0
var _exhausted := false
var _since_spent := INF


func _ready() -> void:
	_value = max_value


func _physics_process(delta: float) -> void:
	_since_spent += delta
	if _since_spent < recovery_delay or _value >= max_value:
		return
	_value = minf(_value + recovery_rate * delta, max_value)
	if _exhausted and get_ratio() >= recover_ratio:
		_set_exhausted(false)
	changed.emit(get_ratio())


## Whether stamina can be spent now: it is not empty and the character is not exhausted.
func can_spend() -> bool:
	return not _exhausted and _value > 0.0


## Spend [param amount] of stamina. No more than what is left is spent; when it runs out, the character is exhausted.
func spend(amount: float) -> void:
	if amount <= 0.0 or not can_spend():
		return
	_since_spent = 0.0
	_value = maxf(_value - amount, 0.0)
	if _value == 0.0:
		_set_exhausted(true)
	changed.emit(get_ratio())


## How much stamina is left, as a fraction of the full amount.
func get_ratio() -> float:
	return _value / max_value


func is_exhausted() -> bool:
	return _exhausted


## Restore all stamina at once, for example when the character spawns.
func refill() -> void:
	_value = max_value
	_since_spent = INF
	_set_exhausted(false)
	changed.emit(1.0)


func _set_exhausted(exhausted: bool) -> void:
	if exhausted != _exhausted:
		_exhausted = exhausted
		exhausted_changed.emit(exhausted)
