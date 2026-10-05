extends "res://tests/check_suite.gd"
## Interface languages: English by default; every interface string has a translation into every project language, on
## every level the portals lead to too, keeping the key tokens, and the translations have no strings the game no longer
## shows; picking a language in the settings window at once changes the texts the code composes too, and the language
## names in the list are not translated; the hints name the keys bound now, in the language chosen.

## Strings that scripts translate with tr(): they cannot be found in the scenes.
const SCRIPT_STRINGS: Array[String] = [
	"Speed: %.1f m/s",
	" (%d Hz)",
	"With V-Sync there are never more frames than the monitor's refresh rate%s, and an FPS limit above it has no "
			+ "effect. The smoothest limits are those that divide this rate evenly.",
	# CharacterMonitor: the character's state and events.
	"jump", "left the ground", "Speed %.1f m/s · blend %.2f", "Forward %+.2f · right %+.2f", "Turning %+.0f°/s",
	"On the ground · slope %.0f°", "In the air %.2f s · vertical %+.1f m/s", "Step %d · %s · cycle %.2f",
	"Stamina %d%%", "exhausted", "Standing", "Running", "Sprinting", "Jumping", "Falling", "step, %s",
	"touched the ground at %.1f m/s", "landing at %.1f m/s", "sprint started", "sprint ended", "%.2f s", "left foot",
	"right foot", "No steps", "stair %+.2f m",
	# InputNames: the engine's name of a key that the translations name in their language (the mouse names come from
	# InputNames.get_mouse_names()).
	"Space",
	InputNames.UNBOUND,
	InputNames.LEFT_KEY,
	InputNames.RIGHT_KEY,
]

## Strings without letters (numbers, percentages, degrees) need no translation; the letters in "%d", "%.1f" do not
## count.
var _letters := RegEx.create_from_string("\\p{L}")
var _placeholders := RegEx.create_from_string("%[-+ 0#]*\\d*(\\.\\d+)?[a-zA-Z%]")
## The tokens of the keys ({sprint}): their letters do not count either, and a translation keeps them all.
var _tokens := RegEx.create_from_string(InputNames.TOKEN_PATTERN)


func _checks() -> Array[Callable]:
	return [
		_check_default_language,
		_check_every_string_translated,
		_check_language_switch,
		_check_key_names,
		_check_event_names,
		_check_rebound_interface,
		_check_translation_scope,
	]


func _check_default_language() -> void:
	print("\n== the interface language by default")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var language: String = settings.get_value(GameSettings.LANGUAGE)
	print("setting \"%s\", locale \"%s\", loaded translations %s" % [
		language, TranslationServer.get_locale(), TranslationServer.get_loaded_locales()])
	_expect(language == "en" and TranslationServer.get_locale() == "en", "the interface is in English by default")
	_expect("ru" in TranslationServer.get_loaded_locales(), "the Russian translation is loaded")


func _check_every_string_translated() -> void:
	print("\n== every interface string has a translation")
	var opened := (await _open_settings()) != null
	# Text → where it was found (for the message about a missing translation).
	var strings := {}
	_collect(_main, strings)
	for place: PointOfInterest in _tree.get_nodes_in_group(PointOfInterest.GROUP):
		_add(strings, place.title, place)
	var toast: DiscoveryToast = _main.get_node("Hud/DiscoveryToast")
	_add(strings, toast.text_format, toast)
	var prompt: TravelPrompt = _main.get_node("Hud/TravelPrompt")
	_add(strings, prompt.text_format, prompt)
	var loading: LoadingScreen = _main.get_node("LoadingScreen")
	for tip in loading.tips:
		_add(strings, tip, loading)
	var levels := _collect_levels(strings)
	for text in SCRIPT_STRINGS:
		_add(strings, text, null)
	for text in InputNames.get_mouse_names():
		_add(strings, text, null)
	await _close_settings()
	print("%d strings with letters in the main scene, %d more levels, the settings window and the scripts" % [
		strings.size(), levels])
	_expect(opened and strings.size() > 90, "the strings are collected from the open settings window too")

	for locale: String in TranslationServer.get_loaded_locales():
		var translation := TranslationServer.get_translation_object(locale)
		var missing := PackedStringArray()
		for text: String in strings:
			if translation.get_message(text).is_empty():
				missing.append("\"%s\" (%s)" % [text.c_escape(), strings[text]])
		var unused := PackedStringArray()
		for text: String in translation.get_message_list():
			if not strings.has(text):
				unused.append("\"%s\"" % text.c_escape())
		# A token lost or changed in a translation would show as text, or name another key.
		var tokens_lost := PackedStringArray()
		for text: String in strings:
			var translated := translation.get_message(text)
			if not translated.is_empty() and _get_tokens(translated) != _get_tokens(text):
				tokens_lost.append("\"%s\"" % translated.c_escape())
		print("%s: missing %d%s; unused %d%s; tokens not kept %d%s" % [
			locale, missing.size(), "" if missing.is_empty() else "\n    " + "\n    ".join(missing),
			unused.size(), "" if unused.is_empty() else "\n    " + "\n    ".join(unused),
			tokens_lost.size(), "" if tokens_lost.is_empty() else "\n    " + "\n    ".join(tokens_lost)])
		_expect(missing.is_empty(), "every interface string has a translation to \"%s\"" % locale)
		_expect(unused.is_empty(), "the \"%s\" translation has no strings the game no longer shows" % locale)
		_expect(tokens_lost.is_empty(), "the \"%s\" translation keeps the key tokens of every string" % locale)


func _check_language_switch() -> void:
	print("\n== the language switch in the settings window")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var screen := await _open_settings()
	if screen == null:
		_expect(false, "F10 opens the settings window")
		return
	var language := screen.find_child("Language") as OptionButton
	var follow_time := screen.find_child("FollowTime") as HSlider
	var follow_time_text := screen.find_child("FollowTimeValue") as Label
	var vsync_hint := screen.find_child("VsyncHint") as Label
	var toast: DiscoveryToast = _main.get_node("Hud/DiscoveryToast")
	var speed_label: Label = _main.get_node("Hud/Panel/Lines/SpeedLabel")
	follow_time.value = 0.0
	toast.show_discovery("Windswept Peak")
	var names_before := _item_texts(language)
	var shown_before := language.text
	var english := [follow_time_text.text, vsync_hint.text.left(11), toast.text]

	_select(language, "ru")
	await _frames(2)
	var russian := [follow_time_text.text, vsync_hint.text.left(11), toast.text]
	var russian_locale := TranslationServer.get_locale()
	var names_after := _item_texts(language)
	var shown_after := language.text
	var title_translated := tr("Settings")
	await _close_settings()
	await _frames(2)
	var russian_speed := speed_label.text
	print(("English: %s; after picking Russian: locale %s, %s, speed \"%s\", \"Settings\" -> \"%s\"; " +
			"language list %s -> %s, shown \"%s\" -> \"%s\"") % [
		english, russian_locale, russian, russian_speed, title_translated, names_before, names_after,
		shown_before, shown_after])
	_expect(english == ["instant", "With V-Sync", "Discovered: Windswept Peak"],
			"in English the texts the code composes are English")
	_expect(russian_locale == "ru" and settings.get_value(GameSettings.LANGUAGE) == "ru"
			and title_translated == "Настройки", "picking Russian in the list switches the language")
	_expect(russian == ["сразу", "С V-Sync ка", "Открыто место: Вершина ветров"]
			and russian_speed.begins_with("Скорость"),
			"the texts the code composes follow the language at once: slider value, V-Sync hint, place message, speed")
	_expect(names_before == names_after and "English" in names_after and "Русский" in names_after
			and shown_before == "English" and shown_after == "Русский",
			"language names are written in themselves and are not translated")

	screen = await _open_settings()
	(screen.find_child("Reset") as Button).pressed.emit()
	await _frames(2)
	var reset_follow_time := (screen.find_child("FollowTimeValue") as Label).text
	var after_reset := [TranslationServer.get_locale(), reset_follow_time, toast.text]
	await _close_settings()
	print("after reset: ", after_reset)
	_expect(after_reset == ["en", "1.1 s", "Discovered: Windswept Peak"], "reset brings the interface back to English")
	# The check has shown the place caption: wait until it fades out.
	await _wait_until(func() -> bool: return toast.modulate.a == 0.0, 600)


func _collect(node: Node, strings: Dictionary) -> void:
	# A control that names keys (ActionTexts) shows its texts with the names in: the source texts are its templates.
	for template: Variant in ActionTexts.get_templates(node).values():
		for text: String in (template if template is PackedStringArray else PackedStringArray([template])):
			_add(strings, text, node)
	if node.can_auto_translate() and node.can_translate_messages():
		if node is OptionButton:
			for index in (node as OptionButton).item_count:
				_add(strings, (node as OptionButton).get_item_text(index), node)
		elif node is Label or node is Button or node is Label3D:
			_add(strings, node.get(&"text"), node)
		if node is Control:
			_add(strings, (node as Control).tooltip_text, node)
		if node is TabContainer:
			for index in (node as TabContainer).get_tab_count():
				_add(strings, (node as TabContainer).get_tab_title(index), node)
	# The settings window sliders: the slider itself translates the units and the text shown instead of zero.
	if node is Slider and node.get(&"value_format") != null:
		_add(strings, node.get(&"value_format"), node)
		_add(strings, node.get(&"zero_text"), node)
	for child in node.get_children():
		_collect(child, strings)


## The levels the portals lead to, from the current one on, built outside the tree: their texts, the names of their
## places and of the places their portals lead to. Returns how many levels there were besides the current one.
func _collect_levels(strings: Dictionary) -> int:
	var current := _levels.get_current_level()
	var seen := {current.scene_file_path: true}
	var queue: Array[Node] = [current]
	var built: Array[Node] = []
	while not queue.is_empty():
		var level: Node = queue.pop_front()
		_collect(level, strings)
		for node in level.find_children("*", "Area3D", true, false):
			if node is PointOfInterest:
				_add(strings, (node as PointOfInterest).title, node)
			elif node is LevelPortal:
				var portal := node as LevelPortal
				_add(strings, portal.title, portal)
				if not seen.has(portal.target_level):
					seen[portal.target_level] = true
					var next := (load(portal.target_level) as PackedScene).instantiate()
					built.append(next)
					queue.append(next)
	for level in built:
		level.free()
	return built.size()


func _add(strings: Dictionary, text: String, where: Node) -> void:
	if _letters.search(_tokens.sub(_placeholders.sub(text, "", true), "", true)) != null and not strings.has(text):
		strings[text] = _where(where)


## The key tokens of [param text], sorted, each as often as it occurs.
func _get_tokens(text: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	for found in _tokens.search_all(text):
		tokens.append(found.get_string())
	tokens.sort()
	return tokens


## Where the text was found: the path in the main scene; on a level outside the tree, its file and the path in it.
func _where(node: Node) -> String:
	if node == null:
		return "script"
	if node.is_inside_tree():
		return String(_main.get_path_to(node))
	var level := node
	while level.get_parent() != null:
		level = level.get_parent()
	return "%s:%s" % [level.scene_file_path.get_file(), level.get_path_to(node)]


func _check_key_names() -> void:
	print("\n== the hints name the keys bound now, in the language chosen")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var lines := "Hud/Panel/Lines/"
	var help: Label = _main.get_node(lines + "Help")
	var keys_help: Label = _main.get_node(lines + "KeysHelp")
	var sprint_help: Label = _main.get_node(lines + "SprintHelp")
	var jump_help: Label = _main.get_node(lines + "JumpHelp")
	var loading: LoadingScreen = _main.get_node("LoadingScreen")
	var english := [help.text.get_slice("\n", 3), keys_help.text, sprint_help.text, jump_help.text,
			loading.tip_format.call("{sprint} makes the hero run faster")]
	var formats := [InputNames.format("{move_left/move_right}"), InputNames.format("{move_back+jump}"),
			InputNames.format("{no_such_action} and {sprint"), InputNames.of_event(_key_event(KEY_S, true))]

	# Sprint on Ctrl instead of Shift, as a game that lets the player change the keys would do it.
	var sprint_events := InputMap.action_get_events(&"sprint")
	InputMap.action_erase_events(&"sprint")
	InputMap.action_add_event(&"sprint", _key_event(KEY_CTRL, false))
	_tree.call_group(ActionTexts.GROUP, &"refresh")
	var rebound := sprint_help.text
	settings.set_value(GameSettings.LANGUAGE, "ru")
	await _frames(2)
	var screen := await _open_settings()
	var sprint_switch := screen.find_child("Sprint") as CheckButton if screen != null else null
	var keys_mode := screen.find_child("CameraKeys") as OptionButton if screen != null else null
	var russian := [help.text.get_slice("\n", 0), sprint_help.text, jump_help.text,
			sprint_switch.text if sprint_switch != null else "",
			keys_mode.get_item_text(1) if keys_mode != null else "",
			loading.tip_format.call(tr("{sprint} makes the hero run faster for as long as stamina lasts."))]
	await _close_settings()

	InputMap.action_erase_events(&"sprint")
	for event in sprint_events:
		InputMap.action_add_event(&"sprint", event)
	settings.set_value(GameSettings.LANGUAGE, "en")
	await _frames(2)
	var restored := sprint_help.text
	print("English %s; formats %s; sprint on Ctrl: \"%s\"; Russian %s; back: \"%s\"" % [
		english, formats, rebound, russian, restored])
	_expect(english == ["Wheel — lower or raise the camera", "RMB + WASD — move relative to the camera",
			"Shift — run faster", "Space — jump", "Shift makes the hero run faster"],
			"the hints and the loading tips name the bound keys: the wheel, WASD together, Shift, Space")
	_expect(formats == ["A/D", "S/Space", "{no_such_action} and {sprint", "Ctrl+S"],
			"names joined: by a slash, letters only together; a missing action or a broken token stays as it is")
	_expect(rebound == "Ctrl — run faster" and restored == "Shift — run faster",
			"after the keys change, a refresh of the group names the new key, and the old one again")
	_expect(russian == ["ЛКМ по земле — бежать в точку", "Ctrl — бежать быстрее", "Пробел — прыжок",
			"Бег с ускорением (Ctrl)", "Боком: лицом вперёд, S — спиной", "Ctrl ускоряет бег, пока хватает сил."],
			"in Russian the hints, the settings window (also option items) and the tips name the keys in Russian")


func _check_event_names() -> void:
	print("\n== key bindings: modifiers, labels, unbound actions and wheel directions")
	var logical := _key_event(KEY_W, true)
	logical.keycode = KEY_S
	var label := InputEventKey.new()
	label.key_label = 0x0419 as Key
	var unicode_key := InputEventKey.new()
	unicode_key.unicode = 0x00D1
	var shift := _key_event(KEY_SHIFT)
	shift.shift_pressed = true
	_expect(InputNames.of_event(logical) == "Ctrl+S" and InputNames.of_event(label) == "Й"
			and InputNames.of_event(unicode_key) == "Ñ" and InputNames.of_event(shift) == "Shift",
			"logical keys take precedence; label and Unicode bindings have names; Shift is not Shift+Shift")
	shift.location = KEY_LOCATION_LEFT
	var left_shift := InputNames.of_event(shift)
	shift.location = KEY_LOCATION_RIGHT
	shift.ctrl_pressed = true
	var right_shift := InputNames.of_event(shift)
	shift.keycode = KEY_SHIFT
	_expect(left_shift == "Left Shift" and right_shift == "Ctrl+Right Shift" and InputNames.of_event(shift) == "Ctrl+Shift",
			"physical modifier bindings keep their side; logical bindings match either side")

	var action := &"__input_names_unbound"
	InputMap.add_action(action)
	var empty_name := InputNames.of_action(action)
	var empty_text := InputNames.format("[{__input_names_unbound}]")
	InputMap.erase_action(action)
	_expect(empty_name == "Unbound" and empty_text == "[Unbound]"
			and InputNames.of_action(action).is_empty() and InputNames.format("{__input_names_unbound}") == "{__input_names_unbound}",
			"an unassigned action has a visible name; an unknown action keeps its token without errors")

	var zoom_events := InputMap.action_get_events(&"camera_zoom_in")
	var wheel := _mouse_event(MOUSE_BUTTON_WHEEL_UP)
	wheel.ctrl_pressed = true
	_replace_events(&"camera_zoom_in", [wheel])
	_expect(InputNames.format("{camera_zoom_in/camera_zoom_out}") == "Ctrl+Wheel up/Wheel down",
			"wheel directions with different modifiers are named separately")
	_replace_events(&"camera_zoom_in", zoom_events)


func _check_rebound_interface() -> void:
	print("\n== all bindings changed while the settings, travel offer and loading tip are already open")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var screen := await _open_settings()
	if screen == null:
		_expect(false, "the settings window opens before rebinding")
		return
	var keys_mode := screen.find_child("CameraKeys") as OptionButton
	var selected := keys_mode.selected
	var extra := Label.new()
	extra.text = "Close"
	extra.tooltip_text = "{jump} — jump"
	screen.add_child(extra)
	var prompt: TravelPrompt = _main.get_node("Hud/TravelPrompt")
	var portal := LevelPortal.new()
	portal.title = "Lonely Isle"
	prompt.show_for(portal)
	var badge: Label = prompt.get_node("%Key")
	var loading: LoadingScreen = _main.get_node("LoadingScreen")
	var tips := loading.tips
	var fade_time := loading.fade_time
	loading.tips = PackedStringArray(["{sprint} makes the hero run faster for as long as stamina lasts."])
	loading.fade_time = 0.0
	await loading.open(portal.title)
	var tip: Label = loading.get_node("%Tip")
	_expect(badge.text == "E" and tip.text == "Shift makes the hero run faster for as long as stamina lasts.",
			"the visible travel offer and loading tip initially name the default keys")

	var move := _mouse_event(MOUSE_BUTTON_MIDDLE)
	move.ctrl_pressed = true
	var rotate := _mouse_event(MOUSE_BUTTON_XBUTTON1)
	rotate.alt_pressed = true
	var bindings := {
		&"move_to_cursor": move, &"camera_rotate": rotate,
		&"camera_zoom_in": _key_event(KEY_PAGEUP), &"camera_zoom_out": _key_event(KEY_PAGEDOWN),
		&"move_forward": _key_event(KEY_UP), &"move_left": _key_event(KEY_LEFT),
		&"move_back": _key_event(KEY_DOWN), &"move_right": _key_event(KEY_RIGHT),
		&"sprint": _key_event(KEY_F8), &"jump": _key_event(KEY_J),
		&"interact": _key_event(KEY_F9, true), &"toggle_settings": _key_event(KEY_F6),
	}
	var saved := {}
	for action: StringName in bindings:
		saved[action] = InputMap.action_get_events(action)
		_replace_events(action, [bindings[action]])
	_tree.call_group(ActionTexts.GROUP, &"refresh")
	var lines: Node = _main.get_node("Hud/Panel/Lines")
	_expect((lines.get_node("Help") as Label).text == "Ctrl+MMB on the ground — run there\n"
			+ "Hold Ctrl+MMB — run after the cursor\nAlt+Mouse back + mouse — orbit the camera\n"
			+ "PageUp/PageDown — lower or raise the camera\nHold Alt+Mouse back, then Ctrl+MMB — run where the camera looks",
			"mouse chords and keyboard zoom replace the default buttons and wheel throughout the HUD")
	_expect((lines.get_node("KeysHelp") as Label).text == "Alt+Mouse back + Up/Left/Down/Right — move relative to the camera"
			and (lines.get_node("StrafeHelp") as Label).text == "Ctrl+MMB + Alt+Mouse back + Left/Right — run diagonally"
			and (lines.get_node("LookHelp") as Label).text == "Hold Ctrl+MMB, then Alt+Mouse back — look around on the run"
			and (lines.get_node("SprintHelp") as Label).text == "F8 — run faster"
			and (lines.get_node("JumpHelp") as Label).text == "J — jump"
			and (lines.get_node("MenuHelp") as Label).text == "F6 — settings",
			"all movement, sprint, jump and settings hints name the current bindings")
	_expect((screen.find_child("Sprint") as CheckButton).text == "Sprint (F8)"
			and keys_mode.get_item_text(1) == "Sidestep: face forward, Down backs up"
			and keys_mode.get_item_text(2) == "Turn: face the way you go, Down toward the camera"
			and keys_mode.selected == selected and keys_mode.text == keys_mode.get_item_text(selected)
			and extra.text == "Close" and extra.tooltip_text == "J — jump",
			"open settings, selected option text and a newly added tooltip refresh without changing the selection")
	_expect(badge.text == "Ctrl+F9" and tip.text == "F8 makes the hero run faster for as long as stamina lasts.",
			"the same refresh updates the visible travel key and loading tip")

	settings.set_value(GameSettings.LANGUAGE, "ru")
	await _frames(2)
	_expect(tip.text == "F8 ускоряет бег, пока хватает сил." and badge.text == "Ctrl+F9"
			and (prompt.get_node("%Button") as Button).text == "Телепорт: Одинокий остров"
			and keys_mode.get_item_text(1) == "Боком: лицом вперёд, Down — спиной"
			and extra.text == "Закрыть" and extra.tooltip_text == "J — прыжок",
			"changing the language also translates already open tips, options and tooltips after rebinding")
	_replace_events(&"jump", [])
	_tree.call_group(ActionTexts.GROUP, &"refresh")
	_expect((lines.get_node("JumpHelp") as Label).text == "Не назначено — прыжок"
			and extra.tooltip_text == "Не назначено — прыжок",
			"clearing a binding displays a translated unassigned label")

	await loading.close()
	loading.tips = tips
	loading.fade_time = fade_time
	prompt.dismiss()
	portal.free()
	for action: StringName in saved:
		_replace_events(action, saved[action])
	settings.set_value(GameSettings.LANGUAGE, "en")
	_tree.call_group(ActionTexts.GROUP, &"refresh")
	await _close_settings()
	_expect((lines.get_node("KeysHelp") as Label).text == "RMB + WASD — move relative to the camera"
			and (lines.get_node("JumpHelp") as Label).text == "Space — jump",
			"restoring the bindings restores the original hints from their templates")


func _check_translation_scope() -> void:
	print("\n== action text translation stays local to the managed control")
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var panel := Control.new()
	panel.tooltip_text = "{jump} — jump"
	var caption := Label.new()
	caption.text = "Close"
	panel.add_child(caption)
	var untranslated := Label.new()
	untranslated.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	untranslated.text = "Close"
	untranslated.tooltip_text = "{jump} — jump"
	panel.add_child(untranslated)
	var texts := ActionTexts.new()
	panel.add_child(texts)
	_tree.root.add_child(panel)
	settings.set_value(GameSettings.LANGUAGE, "ru")
	await _frames(2)
	_expect(panel.tooltip_text == "Пробел — прыжок" and caption.atr(caption.text) == "Закрыть"
			and caption.can_auto_translate(),
			"formatting a parent's tooltip does not disable translation of its ordinary child labels")
	_expect(untranslated.text == "Close" and untranslated.tooltip_text == "Пробел — jump",
			"a control with translation explicitly disabled keeps its literal text while its key names update")
	var added := Label.new()
	added.text = "Settings"
	panel.add_child(added)
	texts.refresh()
	_expect(added.atr(added.text) == "Настройки", "children added after the first refresh also inherit translation")
	var sided := _key_event(KEY_SHIFT)
	sided.location = KEY_LOCATION_RIGHT
	_expect(InputNames.of_event(sided) == "Правый Shift", "the location of a modifier is translated too")
	panel.queue_free()
	settings.set_value(GameSettings.LANGUAGE, "en")
	await _frames(2)


static func _replace_events(action: StringName, events: Array) -> void:
	InputMap.action_erase_events(action)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


static func _mouse_event(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


static func _key_event(physical: Key, ctrl := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.ctrl_pressed = ctrl
	return event


func _open_settings() -> Control:
	var ui: UiRoot = _main.get_node("UiRoot")
	_send_key(KEY_F10)
	await _frames(2)
	return ui.get_top_screen()


func _close_settings() -> void:
	_send_key(KEY_ESCAPE)
	await _frames(2)


static func _item_texts(button: OptionButton) -> PackedStringArray:
	var texts := PackedStringArray()
	for index in button.item_count:
		texts.append(button.get_item_text(index))
	return texts


static func _select(button: OptionButton, locale: String) -> void:
	for index in button.item_count:
		if button.get_item_metadata(index) == locale:
			button.select(index)
			button.item_selected.emit(index)
			return
