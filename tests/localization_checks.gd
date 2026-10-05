extends "res://tests/check_suite.gd"
## Interface languages: English by default; every interface string has a translation into every project language, on
## every level the portals lead to too, and the translations have no strings the game no longer shows; picking a
## language in the settings window at once changes the texts the code composes too, and the language names in the list
## are not translated.

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
]

## Strings without letters (numbers, percentages, degrees) need no translation; the letters in "%d", "%.1f" do not
## count.
var _letters := RegEx.create_from_string("\\p{L}")
var _placeholders := RegEx.create_from_string("%[-+ 0#]*\\d*(\\.\\d+)?[a-zA-Z%]")


func _checks() -> Array[Callable]:
	return [
		_check_default_language,
		_check_every_string_translated,
		_check_language_switch,
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
		print("%s: missing %d%s; unused %d%s" % [
			locale, missing.size(), "" if missing.is_empty() else "\n    " + "\n    ".join(missing),
			unused.size(), "" if unused.is_empty() else "\n    " + "\n    ".join(unused)])
		_expect(missing.is_empty(), "every interface string has a translation to \"%s\"" % locale)
		_expect(unused.is_empty(), "the \"%s\" translation has no strings the game no longer shows" % locale)


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
	if node.can_auto_translate():
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
	if _letters.search(_placeholders.sub(text, "", true)) != null and not strings.has(text):
		strings[text] = _where(where)


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
