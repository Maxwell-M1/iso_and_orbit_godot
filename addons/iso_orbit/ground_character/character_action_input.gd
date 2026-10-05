class_name CharacterActionInput
extends Node
## Character keys besides the mouse: sprint with [member sprint_action] (Shift) and jump with [member jump_action]
## (Space).
##
## The component only passes input to [GroundCharacter] and decides nothing itself: the character decides whether
## there is enough stamina to sprint and whether it can jump right now.
##
## The release of the sprint key sometimes does not reach the game, and the engine considers the key held until it is
## pressed and released again. This happens when the game window loses focus but the application does not: the game is
## embedded in the editor's Game tab and the focus moved to the editor itself ([method Input.release_pressed_events]
## does not reset the keys then), or a system key combination intercepted the release. If every key of the sprint action
## is a modifier (Shift, Ctrl, Alt, Meta), their real state arrives in every mouse and keyboard event
## ([InputEventWithModifiers]); it is used to release the stuck press ([method _input]).

## How the sprint key turns sprint on.
enum SprintMode {
	## Sprint while the key is held.
	HOLD,
	## One press turns sprint on, the next turns it off. If the character is exhausted, it also turns off on its own.
	TOGGLE,
}

const _MODIFIER_MASKS := {
	KEY_SHIFT: KEY_MASK_SHIFT,
	KEY_CTRL: KEY_MASK_CTRL,
	KEY_ALT: KEY_MASK_ALT,
	KEY_META: KEY_MASK_META,
}

## The character to control.
@export var character: GroundCharacter

## The "sprint" input action.
@export var sprint_action := &"sprint"

## The "jump" input action.
@export var jump_action := &"jump"

## Hold the sprint key, or press it to turn sprint on and off.
@export var sprint_mode := SprintMode.HOLD:
	set(value):
		sprint_mode = value
		_sprint_toggled = false

var _sprint_toggled := false


func _init() -> void:
	# Input comes before the character in the same physics tick: otherwise a press and a release reach it a tick later.
	process_physics_priority = -1


func _ready() -> void:
	assert(character != null, "CharacterActionInput needs the character property set.")
	for action: StringName in [sprint_action, jump_action]:
		if not InputMap.has_action(action):
			push_error("CharacterActionInput: input action \"%s\" is missing in Project Settings > Input Map." % action)


## Checks the held sprint against the real state of the modifier in the event (see the class description). The event
## of the sprint key itself is skipped: it changes the action state anyway, and on some systems (X11) it carries the
## modifiers from before the press.
func _input(event: InputEvent) -> void:
	if sprint_mode != SprintMode.HOLD or not _is_pressed(sprint_action):
		return
	var with_modifiers := event as InputEventWithModifiers
	if with_modifiers == null or event.is_action(sprint_action):
		return
	# Read the current bindings: the action or its keys may have changed since this node became ready.
	var modifiers := _get_modifier_masks(sprint_action)
	if modifiers.is_empty():
		return
	for mask: int in modifiers:
		if (with_modifiers.get_modifiers_mask() & mask) == mask:
			return
	Input.action_release(sprint_action)


func _unhandled_input(event: InputEvent) -> void:
	if _has_action(jump_action) and event.is_action_pressed(jump_action):
		character.jump()
	elif sprint_mode == SprintMode.TOGGLE and _has_action(sprint_action) and event.is_action_pressed(sprint_action):
		_sprint_toggled = not _sprint_toggled
	else:
		return
	get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if sprint_mode == SprintMode.HOLD:
		# By polling, not by events: the key release may have gone to the UI or arrived while the game was paused.
		character.sprint_requested = _is_pressed(sprint_action)
		return
	if _sprint_toggled and character.is_exhausted():
		_sprint_toggled = false
	character.sprint_requested = _sprint_toggled


## Sprint is turned on by a press (in the [constant SprintMode.TOGGLE] mode).
func is_sprint_toggled() -> bool:
	return _sprint_toggled


## Whether [param action] is set and in the Input Map. A missing action is reported once at the start and then not
## read: the engine would report it again at every read.
static func _has_action(action: StringName) -> bool:
	return action != &"" and InputMap.has_action(action)


static func _is_pressed(action: StringName) -> bool:
	return _has_action(action) and Input.is_action_pressed(action)


## The required modifier mask of each binding, including its main key; empty if any binding has a key that is not a
## modifier or an event that is not a key, whose state cannot be inferred from another event's modifiers.
static func _get_modifier_masks(action: StringName) -> Array[int]:
	var masks: Array[int] = []
	if not InputMap.has_action(action):
		return masks
	for event: InputEvent in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event == null:
			return [] as Array[int]
		var key := key_event.keycode
		if key == KEY_NONE:
			key = key_event.physical_keycode
		if key == KEY_NONE:
			key = key_event.key_label
		if not _MODIFIER_MASKS.has(key):
			return [] as Array[int]
		masks.append(_MODIFIER_MASKS[key] | key_event.get_modifiers_mask())
	return masks
