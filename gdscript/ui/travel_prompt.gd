class_name TravelPrompt
extends Control
## The offer to travel while the hero stands at a portal that asks first ([LevelPortal]): the key and "Teleport to
## <place>". The key of [member action] or a click on the offer confirms it ([signal confirmed]), and the game travels.
## It is not a window: the game goes on, and walking away hides the offer.

## The player has confirmed the travel through [param portal].
signal confirmed(portal: LevelPortal)

## How to write it: a format string with the place name. Both the string and the name are translated.
@export var text_format := "Teleport to %s"

## The input action that confirms; its key is shown next to the offer.
@export var action := &"interact"

var _portal: LevelPortal

@onready var _key: Label = %Key
@onready var _button: Button = %Button


func _ready() -> void:
	add_to_group(ActionTexts.GROUP)
	# The key is named by the keyboard, and the text is composed of two translations: neither is translated as a whole.
	_key.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_button.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_button.pressed.connect(_on_pressed)
	hide()
	if not InputMap.has_action(action):
		push_error("TravelPrompt: input action \"%s\" is missing in Project Settings > Input Map." % action)


func _shortcut_input(event: InputEvent) -> void:
	# Not a shortcut of the button: that one wants exactly the modifiers of the action, and the key must work with Shift
	# held too (the hero sprints onto the pad).
	# A missing action is reported once at the start and then not read: the engine would report it at every event.
	if is_visible_in_tree() and _portal != null and InputMap.has_action(action) and event.is_action_pressed(action):
		get_viewport().set_input_as_handled()
		_on_pressed()


## Offer to travel through [param portal].
func show_for(portal: LevelPortal) -> void:
	_portal = portal
	refresh()
	show()


## Hide the offer, if it is for [param portal].
func hide_for(portal: LevelPortal) -> void:
	if portal == _portal:
		dismiss()


## Hide the offer.
func dismiss() -> void:
	_portal = null
	hide()


## The portal offered now, or [code]null[/code].
func get_portal() -> LevelPortal:
	return _portal


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


## Update the offered key and destination after the bindings or language change.
func refresh() -> void:
	_key.text = InputNames.of_action(action)
	if _portal != null:
		_update_text()


func _on_pressed() -> void:
	if _portal != null:
		confirmed.emit(_portal)


func _update_text() -> void:
	_button.text = tr(text_format) % tr(_portal.title)
