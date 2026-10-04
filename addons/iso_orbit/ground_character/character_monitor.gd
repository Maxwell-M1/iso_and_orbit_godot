class_name CharacterMonitor
extends Label
## Shows as text what a [GroundCharacter] is doing right now and its latest events: for tuning animations, effects and
## the interface, or for a debug overlay. It can also print the events to the output with their time, as a log.
##
## The text comes only from the character's public queries and signals, so the script is also an example of reading
## them. The lines go through [method Object.tr]: with translations of these phrases the panel speaks the game's
## language, the log in the output stays in English.

## The character to watch. If not set, the parent is used when it is a [GroundCharacter].
@export var character: GroundCharacter

## How many latest events to show under the state. 0 shows only the state.
@export_range(0, 50) var history_size := 6

## Print every event to the output ([method @GlobalScope.print]) with its time and the character's name.
@export var log_events := false

## Show and log steps and stairs too: there are several per second.
@export var include_steps := true

var _events: Array[Dictionary] = []


func _ready() -> void:
	if character == null:
		character = get_parent() as GroundCharacter
	assert(character != null,
			"CharacterMonitor needs a GroundCharacter: set the character property or make it the parent.")
	# Lines are composed of translated phrases and numbers; the whole text cannot be translated at once.
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	character.state_changed.connect(_on_state_changed)
	character.stepped.connect(_on_stepped)
	character.jumped.connect(_add_event.bind("jump"))
	character.left_floor.connect(_add_event.bind("left the ground"))
	character.touched_floor.connect(_on_touched_floor)
	character.landed.connect(_on_landed)
	character.sprint_changed.connect(_on_sprint_changed)
	character.stair_taken.connect(_on_stair_taken)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		text = get_text_now()


## The whole text: the state lines and then the latest events, oldest first.
func get_text_now() -> String:
	var lines := get_state_lines()
	if not _events.is_empty():
		lines.append("")
		lines.append_array(get_event_lines())
	return "\n".join(lines)


## The current state, line by line: what the character does, speed and blend, movement in the model's axes, turning,
## ground or air, steps, stamina.
func get_state_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append(get_state_name(character.get_state(), true))
	lines.append(tr("Speed %.1f m/s · blend %.2f") % [character.get_move_speed(), character.get_locomotion_blend()])
	var local := character.get_local_movement()
	lines.append(tr("Forward %+.2f · right %+.2f") % [_signed(local.y, 0.01), _signed(local.x, 0.01)])
	lines.append(tr("Turning %+.0f°/s") % _signed(rad_to_deg(character.get_turn_rate()), 1.0))
	if character.is_on_floor():
		lines.append(tr("On the ground · slope %.0f°") % rad_to_deg(character.get_floor_angle()))
	else:
		lines.append(tr("In the air %.2f s · vertical %+.1f m/s") % [character.get_air_time(),
			_signed(character.velocity.y, 0.1)])
	if character.is_counting_steps():
		lines.append(tr("Step %d · %s · cycle %.2f") % [floori(character.get_step_phase()),
			_get_foot_name(character.get_step_foot(), true), character.get_gait_cycle()])
	else:
		lines.append(tr("No steps"))
	if character.stamina != null:
		var stamina := tr("Stamina %d%%") % roundi(character.stamina.get_ratio() * 100.0)
		if character.is_exhausted():
			stamina += " · " + tr("exhausted")
		lines.append(stamina)
	return lines


## The latest events, oldest first, as they are shown.
func get_event_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for event: Dictionary in _events:
		lines.append(_format_event(event, true))
	return lines


## The name of [param state] as the panel shows it; [param translated] = [code]false[/code] gives the English one.
func get_state_name(state: GroundCharacter.State, translated := false) -> String:
	var names: Array[String] = ["Standing", "Running", "Sprinting", "Jumping", "Falling"]
	return _text(names[state], translated)


func _on_state_changed(state: GroundCharacter.State, previous: GroundCharacter.State) -> void:
	_add_event("%s → %s", [previous, state], &"state")


func _on_stepped(_sprinting: bool) -> void:
	if include_steps:
		_add_event("step, %s", [character.get_step_foot()], &"foot")


func _on_touched_floor(fall_speed: float) -> void:
	_add_event("touched the ground at %.1f m/s", [fall_speed])


func _on_landed(impact_speed: float) -> void:
	_add_event("landing at %.1f m/s", [impact_speed])


func _on_stair_taken(height: float) -> void:
	if include_steps:
		_add_event("stair %+.2f m", [height])


func _on_sprint_changed(sprinting: bool) -> void:
	_add_event("sprint started" if sprinting else "sprint ended")


## Remembers an event: a phrase with values, where [param kind] tells how to show the values (as states or as a foot).
## The time is counted from the start of the game.
func _add_event(phrase: String, values := [], kind := &"") -> void:
	var event := {time = Time.get_ticks_msec() / 1000.0, phrase = phrase, values = values, kind = kind}
	if log_events:
		print("%s: %s" % [character.name, _format_event(event, false)])
	if history_size <= 0:
		return
	_events.append(event)
	while _events.size() > history_size:
		_events.pop_front()


func _format_event(event: Dictionary, translated: bool) -> String:
	var values: Array = event.values.duplicate()
	for i in values.size():
		if event.kind == &"state":
			values[i] = get_state_name(values[i], translated)
		elif event.kind == &"foot":
			values[i] = _get_foot_name(values[i], translated)
	# A change of state is only two names and an arrow: nothing to translate.
	var phrase: String = event.phrase if event.kind == &"state" else _text(event.phrase, translated)
	if not values.is_empty():
		phrase = phrase % values
	return _text("%.2f s", translated) % event.time + "  " + phrase


func _get_foot_name(foot: GroundCharacter.Foot, translated: bool) -> String:
	return _text("left foot" if foot == GroundCharacter.Foot.LEFT else "right foot", translated)


func _text(phrase: String, translated: bool) -> String:
	return tr(phrase) if translated else phrase


## [param value] rounded to [param step], so that a value that rounds to zero shows as +0 and not as −0.
static func _signed(value: float, step: float) -> float:
	return snappedf(value, step) + 0.0
