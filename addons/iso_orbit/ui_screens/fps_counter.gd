class_name FpsCounter
extends Label
## Frames per second in the corner of the screen. It works while paused too; the color and size are the theme
## variation [code]FpsCounter[/code].

var _shown := -1


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	# A hidden counter counts nothing.
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(is_visible_in_tree())


func _process(_delta: float) -> void:
	# The engine recomputes FPS once per second; change the text only when the number has changed.
	var fps := roundi(Engine.get_frames_per_second())
	if fps != _shown:
		_shown = fps
		text = str(fps)
