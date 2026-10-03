class_name SettingSlider
extends HSlider
## A slider bound to the numeric setting [member key]. The limits and the step are [Range] properties in the inspector.
## It writes the current value to [member value_label].

## The setting key, for example [code]camera/follow_time[/code] (see [GameSettings]).
@export var key: StringName

## Where to show the value. Optional.
@export var value_label: Label

## How to show the value: a format string with one number. It is translated if it contains units.
@export var value_format := "%.1f"

## Text shown instead of zero (for example "instant"), translated. If empty, zero is shown with [member value_format].
@export var zero_text := ""

## While the slider is dragged with the mouse, change the setting only on release (the label changes at once).
## Settings that change the interface itself (scale) need this: otherwise the slider moves out from under the mouse
## while it is dragged. The keyboard and the wheel change the setting at once.
@export var apply_on_release := false

var _dragging := false


func _ready() -> void:
	assert(Settings.has_setting(key), "SettingSlider \"%s\": unknown setting \"%s\"." % [name, key])
	set_value_no_signal(Settings.get_value(key))
	if value_label != null:
		# The label is composed of a translation and a number; it cannot be translated as a whole.
		value_label.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_update_label()
	value_changed.connect(_on_value_changed)
	drag_started.connect(_on_drag_started)
	drag_ended.connect(_on_drag_ended)
	Settings.changed.connect(_on_setting_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_label()


func _on_value_changed(new_value: float) -> void:
	_update_label()
	if not (apply_on_release and _dragging):
		Settings.set_value(key, new_value)


func _on_drag_started() -> void:
	_dragging = true


func _on_drag_ended(_value_changed: bool) -> void:
	_dragging = false
	Settings.set_value(key, value)


func _on_setting_changed(changed_key: StringName, new_value: Variant) -> void:
	if changed_key == key:
		set_value_no_signal(new_value)
		_update_label()


func _update_label() -> void:
	if value_label == null:
		return
	if is_zero_approx(value) and not zero_text.is_empty():
		value_label.text = tr(zero_text)
	else:
		value_label.text = tr(value_format) % value
