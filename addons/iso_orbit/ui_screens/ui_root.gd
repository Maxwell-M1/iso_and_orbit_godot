class_name UiRoot
extends CanvasLayer
## Windows over the game: they open as a stack, Esc ([code]ui_cancel[/code]) closes the top one, and while at least
## one is open, the game is paused and the mouse cursor is visible. Windows are scenes with a [UiScreen] root.
##
## The node works while paused too ([member Node.process_mode] = [constant Node.PROCESS_MODE_ALWAYS]); the windows
## inherit this from it. Keyboard focus: on opening, [member UiScreen.initial_focus] gets it; on closing, it returns
## to where it was.

## A window has opened (it is already in the tree).
signal screen_opened(screen: UiScreen)
## A window has closed (it is being removed).
signal screen_closed(screen: UiScreen)

## The settings window.
@export var settings_screen: PackedScene

## The input action that opens and closes [member settings_screen].
@export var settings_action := &"toggle_settings"

## Pause the game while at least one window is open.
@export var pause_game := true

var _screens: Array[UiScreen] = []
var _focus_before: Array[Control] = []
var _paused_by_ui := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if settings_screen != null and not InputMap.has_action(settings_action):
		push_error("UiRoot: input action \"%s\" is missing in Project Settings > Input Map." % settings_action)


func _unhandled_input(event: InputEvent) -> void:
	# A missing action is reported once at the start and then not read: the engine would report it at every event.
	if settings_screen != null and InputMap.has_action(settings_action) and event.is_action_pressed(settings_action):
		toggle(settings_screen)
	elif has_open_screens() and InputMap.has_action(&"ui_cancel") and event.is_action_pressed(&"ui_cancel"):
		close_top()
	else:
		return
	get_viewport().set_input_as_handled()


## Open a window from the scene [param scene] on top of the others.
func open(scene: PackedScene) -> UiScreen:
	var screen := scene.instantiate() as UiScreen
	assert(screen != null, "UiRoot: the root of \"%s\" must be a UiScreen." % scene.resource_path)
	_focus_before.append(get_viewport().gui_get_focus_owner())
	_screens.append(screen)
	screen.close_requested.connect(_on_close_requested.bind(screen))
	add_child(screen)
	_update_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	screen._screen_opened()
	screen.focus_initial()
	screen_opened.emit(screen)
	return screen


## Close the top window.
func close_top() -> void:
	if not has_open_screens():
		return
	var screen: UiScreen = _screens.pop_back()
	var focus: Control = _focus_before.pop_back()
	screen._screen_closed()
	remove_child(screen)
	screen.queue_free()
	if is_instance_valid(focus) and focus.is_visible_in_tree():
		focus.grab_focus()
	_update_pause()
	screen_closed.emit(screen)


## If the window from [param scene] is open, close it and everything above it; otherwise open it.
func toggle(scene: PackedScene) -> void:
	var index := _find(scene)
	if index == -1:
		open(scene)
		return
	while _screens.size() > index:
		close_top()


func has_open_screens() -> bool:
	return not _screens.is_empty()


## The top window or [code]null[/code].
func get_top_screen() -> UiScreen:
	return _screens.back() if has_open_screens() else null


func _find(scene: PackedScene) -> int:
	for i in _screens.size():
		if _screens[i].scene_file_path == scene.resource_path:
			return i
	return -1


func _update_pause() -> void:
	if not pause_game:
		return
	var want := has_open_screens()
	if want and not get_tree().paused:
		get_tree().paused = true
		_paused_by_ui = true
	elif not want and _paused_by_ui:
		get_tree().paused = false
		_paused_by_ui = false


func _on_close_requested(screen: UiScreen) -> void:
	# Close only if this is the top window: the lower ones are covered and must not close by themselves.
	if screen == get_top_screen():
		close_top()
