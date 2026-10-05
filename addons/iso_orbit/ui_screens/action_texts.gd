class_name ActionTexts
extends Node
## Names the bound keys in the texts of the controls under [member root]: a text written with tokens such as
## [code]{sprint} — run faster[/code] shows [code]Shift — run faster[/code], or whatever key the action has now
## ([method InputNames.format] tells the tokens). The texts stay translatable: the translation keeps the tokens, and
## the names are put in after it.
##
## At the start it takes over each control whose [code]text[/code], [code]tooltip_text[/code] or, in an
## [OptionButton], item text holds a token: it keeps these texts as templates, switches off the control's own
## translation and sets them itself, again when the language changes and on [method refresh]. Controls without tokens
## stay as they are, including descendants that inherit translation. A control that had translation disabled keeps
## its literal template, but the key names are localized. Leave out the controls whose text a script sets: a refresh
## would put the template back.
##
## After the keys change ([method InputMap.action_erase_events] and the like), refresh all of them:
## [code]get_tree().call_group(ActionTexts.GROUP, &"refresh")[/code].

## Nodes that refresh texts containing input bindings. Custom text controls can join it and implement refresh().
const GROUP := &"action_texts"

const _TEMPLATES := &"_action_texts_templates"
const _TRANSLATE := &"_action_texts_translate"

## The node whose subtree holds the texts; empty: the parent.
@export var root: Node

static var _token: RegEx


func _ready() -> void:
	add_to_group(GROUP)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


## Set the texts again, with the keys bound now and in the current language. Controls added since then with tokens are
## taken over too.
func refresh() -> void:
	var start := root if root != null else get_parent()
	if start != null:
		_refresh(start)


## The templates of a control taken over, by property: [code]text[/code], [code]tooltip_text[/code] and, for an
## [OptionButton], [code]items[/code] (an array); empty for any other node. For tools that read the source texts, such
## as a check that every text is translated.
static func get_templates(node: Node) -> Dictionary:
	return node.get_meta(_TEMPLATES, {})


func _refresh(node: Node) -> void:
	var control := node as Control
	if control != null:
		if not control.has_meta(_TEMPLATES):
			_take_over(control)
		if control.has_meta(_TEMPLATES):
			_apply(control, get_templates(control))
	for child in node.get_children():
		_refresh(child)


func _take_over(control: Control) -> void:
	var templates := {}
	var button := control as OptionButton
	# The text of an option button is the text of its chosen item.
	if &"text" in control and button == null:
		templates[&"text"] = control.get(&"text")
	templates[&"tooltip_text"] = control.tooltip_text
	if button != null:
		var items := PackedStringArray()
		for index in button.item_count:
			items.append(button.get_item_text(index))
		templates[&"items"] = items
	if not _has_token(templates):
		return
	control.set_meta(_TEMPLATES, templates)
	control.set_meta(_TRANSLATE, control.can_auto_translate() and control.can_translate_messages())
	# Disable translation only for the text we set. Changing auto_translate_mode would also disable descendants.
	control.set_message_translation(false)
	if button != null:
		button.get_popup().set_message_translation(false)


func _apply(control: Control, templates: Dictionary) -> void:
	var translate: bool = control.get_meta(_TRANSLATE, true)
	for property: StringName in [&"text", &"tooltip_text"]:
		if templates.has(property):
			control.set(property, _format(templates[property], translate))
	var button := control as OptionButton
	if button != null and templates.has(&"items"):
		var items: PackedStringArray = templates[&"items"]
		for index in mini(items.size(), button.item_count):
			button.set_item_text(index, _format(items[index], translate))


func _format(template: String, translate: bool) -> String:
	if template.is_empty():
		return ""
	return InputNames.format(tr(template) if translate else template)


static func _has_token(templates: Dictionary) -> bool:
	if _token == null:
		_token = RegEx.create_from_string(InputNames.TOKEN_PATTERN)
	for value: Variant in templates.values():
		for text: String in (value if value is PackedStringArray else PackedStringArray([value])):
			if _token.search(text) != null:
				return true
	return false
