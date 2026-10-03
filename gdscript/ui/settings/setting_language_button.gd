class_name SettingLanguageButton
extends OptionButton
## A drop-down list of languages bound to the string setting [member key] (a language code). It builds the items
## itself: the language of the scenes (English, [member ProjectSettings.internationalization/locale/fallback]) and
## the languages of all the project's translations. A new translation in
## [code]internationalization/locale/translations[/code] appears in the list without editing the scene.
##
## Each language is named in that language and is not translated: Russian is listed under its Russian name, so it can
## be found in the English interface too.

## Language names in the languages themselves. For a language missing from the list, the name comes from
## [method TranslationServer.get_locale_name].
const NATIVE_NAMES := {
	"en": "English",
	"es": "Español",
	"ja": "日本語",
	"pt_BR": "Português (Brasil)",
	"ru": "Русский",
	"tr": "Türkçe",
	"zh_CN": "简体中文",
}

## The setting key, for example [code]interface/language[/code] (see [GameSettings]).
@export var key: StringName


func _ready() -> void:
	assert(Settings.has_setting(key), "SettingLanguageButton \"%s\": unknown setting \"%s\"." % [name, key])
	auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	get_popup().auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	clear()
	for locale: String in get_locales():
		add_item(NATIVE_NAMES.get(locale, TranslationServer.get_locale_name(locale)))
		set_item_metadata(item_count - 1, locale)
	_show(Settings.get_value(key))
	item_selected.connect(_on_item_selected)
	Settings.changed.connect(_on_setting_changed)


## The language codes in the list: first the language of the scenes, then the translations in alphabetical order.
static func get_locales() -> PackedStringArray:
	var source: String = ProjectSettings.get_setting("internationalization/locale/fallback", "en")
	var locales := PackedStringArray([source])
	var translated := TranslationServer.get_loaded_locales()
	translated.sort()
	for locale: String in translated:
		if not locale in locales:
			locales.append(locale)
	return locales


func _show(locale: String) -> void:
	for index in item_count:
		if get_item_metadata(index) == locale:
			select(index)
			return
	push_warning("SettingLanguageButton \"%s\": no language \"%s\" for \"%s\"." % [name, locale, key])


func _on_item_selected(index: int) -> void:
	Settings.set_value(key, get_item_metadata(index))


func _on_setting_changed(changed_key: StringName, value: Variant) -> void:
	if changed_key == key:
		_show(value)
