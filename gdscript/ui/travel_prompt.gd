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
	# The key is named by the keyboard, and the text is composed of two translations: neither is translated as a whole.
	_key.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_button.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_button.pressed.connect(_on_pressed)
	hide()


func _shortcut_input(event: InputEvent) -> void:
	# Not a shortcut of the button: that one wants exactly the modifiers of the action, and the key must work with Shift
	# held too (the hero sprints onto the pad).
	if is_visible_in_tree() and _portal != null and event.is_action_pressed(action):
		get_viewport().set_input_as_handled()
		_on_pressed()


## Offer to travel through [param portal].
func show_for(portal: LevelPortal) -> void:
	_portal = portal
	_key.text = _get_key_name()
	_update_text()
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
	if what == NOTIFICATION_TRANSLATION_CHANGED and _portal != null:
		_update_text()


func _on_pressed() -> void:
	if _portal != null:
		confirmed.emit(_portal)


func _update_text() -> void:
	_button.text = tr(text_format) % tr(_portal.title)


## The key of [member action] by its Latin letter, the way the other hints name the keys (WASD), whatever the layout.
func _get_key_name() -> String:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	return ""
