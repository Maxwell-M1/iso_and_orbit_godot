class_name UiScreen
extends Control
## A window shown by [UiRoot]: the root of the window scene, stretched over the whole screen.
##
## A window does not close itself but asks for it with the [signal close_requested] signal, and [UiRoot] closes it
## (calls go down the tree, signals go up). This way [UiRoot] always knows which windows are open,
## and correctly returns the focus and lifts the pause.

## The window asks to be closed (a "Close" button and the like). [UiRoot] handles Esc.
signal close_requested

## What gets the keyboard focus when the window opens.
@export var initial_focus: Control


## [UiRoot] has shown the window: it is already in the tree. Override this if the window needs to update something.
func _screen_opened() -> void:
	pass


## [UiRoot] is closing the window: right after this, the window is removed.
func _screen_closed() -> void:
	pass


## Ask [UiRoot] to close the window.
func request_close() -> void:
	close_requested.emit()


## Give the focus to [member initial_focus] (or to the first control that accepts it), so that the window can be
## controlled from the keyboard and a gamepad.
func focus_initial() -> void:
	var target := initial_focus if initial_focus != null else find_next_valid_focus()
	if target != null and target.is_visible_in_tree():
		target.grab_focus()
