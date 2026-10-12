@tool
extends CanvasLayer
## The controls hint and the character's speed: how fast it really moves (a wall stops it). The settings (F10) decide
## what to show.

@export var character: GroundCharacter:
	set(value):
		character = value
		update_configuration_warnings()

@onready var _speed_label: Label = %SpeedLabel


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# The text is composed of a translation and a number; it cannot be translated as a whole.
	_speed_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _speed_label.is_visible_in_tree():
		_speed_label.text = tr("Speed: %.1f m/s") % character.get_move_speed()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if character == null:
		warnings.append("Assign Character in the Inspector.")
	return warnings
