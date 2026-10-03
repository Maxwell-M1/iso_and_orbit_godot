class_name SettingOptionButton
extends OptionButton
## A drop-down list bound to the integer setting [member key]. An item's value is its id (set in the inspector
## together with the text), so the items can be reordered freely.

## The setting key, for example [code]display/max_fps[/code] (see [GameSettings]).
@export var key: StringName


func _ready() -> void:
	assert(Settings.has_setting(key), "SettingOptionButton \"%s\": unknown setting \"%s\"." % [name, key])
	_show(Settings.get_value(key))
	item_selected.connect(_on_item_selected)
	Settings.changed.connect(_on_setting_changed)


func _show(value: int) -> void:
	var index := get_item_index(value)
	if index == -1:
		push_warning("SettingOptionButton \"%s\": no item with id %d for \"%s\"." % [name, value, key])
	select(index)


func _on_item_selected(index: int) -> void:
	Settings.set_value(key, get_item_id(index))


func _on_setting_changed(changed_key: StringName, value: Variant) -> void:
	if changed_key == key:
		_show(value)
