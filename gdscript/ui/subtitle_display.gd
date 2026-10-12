class_name SubtitleDisplay
extends PanelContainer
## A line said by a character, shown for [member display_time] with the speaker's name: "Knight: Let me through."
## The name, the line and the way they are joined ("%s: %s") are translated. The game connects the speech signal of a
## character to [method show_line]; the characters know nothing about the display. It never takes the player's input.

## How long a line stays on screen.
@export_range(1.0, 30.0, 0.5, "suffix:s") var display_time := 5.0

var _speaker := ""
var _line := ""
var _remaining := 0.0

@onready var _caption: Label = $Caption


func _ready() -> void:
	# The caption is put together from translations; it cannot be translated as a whole.
	_caption.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	hide()


## Show [param line] said by [param speaker] (without a name if [param speaker] is empty) instead of the line shown now.
## An empty line hides the line shown now.
func show_line(speaker: String, line: String) -> void:
	if line.is_empty():
		clear()
		return
	_speaker = speaker
	_line = line
	_remaining = display_time
	_refresh()
	show()


## Hide the line now.
func clear() -> void:
	_remaining = 0.0
	_speaker = ""
	_line = ""
	hide()


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= 0.0:
		clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


func _refresh() -> void:
	if _line.is_empty():
		_caption.text = ""
	elif _speaker.is_empty():
		_caption.text = tr(_line)
	else:
		_caption.text = tr("%s: %s") % [tr(_speaker), tr(_line)]
