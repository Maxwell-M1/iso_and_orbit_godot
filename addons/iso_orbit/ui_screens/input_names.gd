class_name InputNames
extends RefCounted
## The names of the keys and mouse buttons bound to input actions, for the texts on the screen: whatever the
## Input Map holds now, the hints name it.
##
## A key is named by the letter on it in the player's keyboard layout ([code]W[/code] on a QWERTY keyboard and on a
## Russian one, [code]Z[/code] on an AZERTY one), a mouse button by a short name such as [code]LMB[/code]. The names go
## through the translation, so that a game may name them in each language: the mouse names of [method get_mouse_names]
## and engine key names such as [code]Space[/code].
##
## [method format] puts the names into a text by tokens: [code]{sprint}[/code] is the name of the action
## [code]sprint[/code]; [code]{camera_zoom_in/camera_zoom_out}[/code] names several actions with a slash between them,
## or [code]Wheel[/code] for the two directions of the wheel; [code]{move_forward+move_left+move_back+move_right}[/code]
## writes the names together when each is a single letter ([code]WASD[/code]), else with slashes. A token of an action
## that is not in the Input Map stays as it is, so that the gap shows. An action with no events is named
## [constant UNBOUND], translated.

## A token: action names (a letter or [code]_[/code] first) joined by [code]/[/code] or [code]+[/code], in braces.
const TOKEN_PATTERN := "\\{([A-Za-z_][A-Za-z0-9_]*(?:[/+][A-Za-z_][A-Za-z0-9_]*)*)\\}"

## The name of the wheel turned both ways, for a pair of actions on it.
const WHEEL := "Wheel"

## The translated name of an action with no assigned input events.
const UNBOUND := "Unbound"

## Formats for physical bindings restricted to one side of the keyboard; the placeholder is the translated key name.
const LEFT_KEY := "Left %s"
const RIGHT_KEY := "Right %s"

const _MOUSE_BUTTONS := {
	MOUSE_BUTTON_LEFT: "LMB",
	MOUSE_BUTTON_RIGHT: "RMB",
	MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_WHEEL_UP: "Wheel up",
	MOUSE_BUTTON_WHEEL_DOWN: "Wheel down",
	MOUSE_BUTTON_WHEEL_LEFT: "Wheel left",
	MOUSE_BUTTON_WHEEL_RIGHT: "Wheel right",
	MOUSE_BUTTON_XBUTTON1: "Mouse back",
	MOUSE_BUTTON_XBUTTON2: "Mouse forward",
}

static var _token: RegEx


## [param text] with each token replaced by the names of its actions (see the class description). Translate the text
## first: the translation keeps the tokens, and the names are translated by themselves.
static func format(text: String) -> String:
	if _token == null:
		_token = RegEx.create_from_string(TOKEN_PATTERN)
	var result := ""
	var start := 0
	for found in _token.search_all(text):
		result += text.substr(start, found.get_start() - start) + _format_token(found.get_string(1), found.get_string())
		start = found.get_end()
	return result + text.substr(start)


## The name of the first key or mouse button of [param action]; for an action with neither, its first event as the
## engine writes it; [constant UNBOUND] translated if it has no events, empty if the action is missing.
static func of_action(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	var event := _get_first_named_event(action)
	if event != null:
		return of_event(event)
	var events := InputMap.action_get_events(action)
	return events[0].as_text() if not events.is_empty() else TranslationServer.translate(UNBOUND)


## The name of [param event]: a key with its modifiers ([code]Ctrl+S[/code]) by the player's keyboard layout, a mouse
## button by its short name, both translated; anything else as the engine writes it.
static func of_event(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		var keycode := key.keycode
		var physical := keycode == KEY_NONE and key.physical_keycode != KEY_NONE
		if physical:
			keycode = _get_layout_keycode(key.physical_keycode)
		if keycode == KEY_NONE:
			keycode = key.key_label
		if keycode == KEY_NONE:
			keycode = key.unicode as Key
		var modifiers := _get_modifiers_text(key, keycode)
		var text := TranslationServer.translate(OS.get_keycode_string(keycode))
		# The engine checks location only for physical bindings; logical keys match either side.
		if physical and key.location == KEY_LOCATION_LEFT:
			text = TranslationServer.translate(LEFT_KEY) % text
		elif physical and key.location == KEY_LOCATION_RIGHT:
			text = TranslationServer.translate(RIGHT_KEY) % text
		return modifiers + text
	var button := event as InputEventMouseButton
	if button != null and _MOUSE_BUTTONS.has(button.button_index):
		return _get_modifiers_text(button) + TranslationServer.translate(_MOUSE_BUTTONS[button.button_index])
	return event.as_text()


## The mouse names that go through the translation, [constant WHEEL] among them: a game that translates its interface
## gives them its own words.
static func get_mouse_names() -> PackedStringArray:
	var names := PackedStringArray(_MOUSE_BUTTONS.values())
	names.append(WHEEL)
	return names


static func _format_token(body: String, token: String) -> String:
	var together := body.contains("+")
	var actions := body.split("+" if together else "/")
	var names := PackedStringArray()
	for action in actions:
		if not InputMap.has_action(action):
			return token
		names.append(of_action(action))
	if _is_wheel_pair(actions):
		return TranslationServer.translate(WHEEL)
	if together and Array(names).all(func(name: String) -> bool: return name.length() == 1):
		return "".join(names)
	return "/".join(names)


## Two actions on the wheel without modifiers, one up and one down.
static func _is_wheel_pair(actions: PackedStringArray) -> bool:
	if actions.size() != 2:
		return false
	var buttons := []
	for action in actions:
		var button := _get_first_named_event(action) as InputEventMouseButton
		if button == null or button.get_modifiers_mask() != 0:
			return false
		buttons.append(button.button_index)
	buttons.sort()
	return buttons == [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]


static func _get_first_named_event(action: StringName) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey or event is InputEventMouseButton:
			return event
	return null


## [code]Ctrl+[/code] and the like, translated, before the name of a key or a button; empty without modifiers.
## The modifier that is itself [param keycode] is omitted, so a recorded Shift press is not named Shift+Shift.
static func _get_modifiers_text(event: InputEventWithModifiers, keycode: Key = KEY_NONE) -> String:
	var text := ""
	for pair: Array in [[event.ctrl_pressed, KEY_CTRL], [event.shift_pressed, KEY_SHIFT],
			[event.alt_pressed, KEY_ALT], [event.meta_pressed, KEY_META]]:
		if pair[0] and pair[1] != keycode:
			text += TranslationServer.translate(OS.get_keycode_string(pair[1])) + "+"
	return text


## The key at the place [param physical] in the player's layout. A run without a window has no layouts (and the engine
## reports every question about them): there the place names the key.
static func _get_layout_keycode(physical: Key) -> Key:
	if DisplayServer.get_name() == "headless":
		return physical
	var keycode := DisplayServer.keyboard_get_keycode_from_physical(physical)
	return keycode if keycode != KEY_NONE else physical
