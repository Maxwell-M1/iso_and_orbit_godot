@tool
class_name SettingCheckButton
extends CheckButton
## A switch bound to the boolean setting [member key]: it shows the setting's value and changes it.
## If the setting is changed elsewhere, the switch updates itself.

## The setting key, for example [code]gameplay/ledge_guard[/code] (see [GameSettings]).
@export var key: StringName:
	set(value):
		key = value
		update_configuration_warnings()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	assert(Settings.has_setting(key), "SettingCheckButton \"%s\": unknown setting \"%s\"." % [name, key])
	set_pressed_no_signal(Settings.get_value(key))
	toggled.connect(_on_toggled)
	Settings.changed.connect(_on_setting_changed)


func _on_toggled(on: bool) -> void:
	Settings.set_value(key, on)


func _on_setting_changed(changed_key: StringName, value: Variant) -> void:
	if changed_key == key:
		set_pressed_no_signal(value)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not GameSettings.DEFAULTS.has(key):
		warnings.append("Choose a known GameSettings key.")
	return warnings
