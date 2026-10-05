class_name LoadingScreen
extends CanvasLayer
## The screen over the whole game while [LevelHost] changes the level: the last frame of the game, blurred, darkened and
## slowly coming closer; the name of the place, a bar of how far the loading has got, and tips that change every few
## seconds. It comes and goes smoothly, by real time whatever [member Engine.time_scale] is, and while it is up no input
## event reaches the game ([Input] still tells which keys are held).
##
## The look is in the theme of the screen's root ([code]loading_screen_theme.tres[/code]): the title
## ([code]LoadingTitle[/code]), the bar ([code]LoadingBar[/code]) and the tip ([code]LoadingTip[/code]). A game with a
## look of its own gives the root its own theme, or makes its own screen from a copy of
## [code]loading_screen.tscn[/code]: the nodes may move and change, but the script needs the [Control] [code]Root[/code]
## and, by unique name, the [TextureRect] [code]Background[/code], the [Label]s [code]Title[/code] and [code]Tip[/code]
## and the [ProgressBar] [code]Bar[/code].

## Tips shown one after another, in a random order; each is translated.
@export var tips: PackedStringArray

## How long each tip stays.
@export_range(1.0, 30.0, 0.5, "suffix:s") var tip_time := 6.0

## How long the screen takes to come and to go.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_time := 0.35

## How much closer the background comes while the screen is up, as a share of its size, over [member zoom_time].
@export_range(0.0, 0.5, 0.01) var zoom := 0.06

## How long the background takes to come [member zoom] closer.
@export_range(1.0, 60.0, 0.5, "suffix:s") var zoom_time := 12.0

var _open := false
# The progress set and the part of the bar filled; the bar catches up with the progress, never ahead of it.
var _target := 0.0
var _shown := 0.0
var _tip_index := -1
var _tip_left := 0.0
var _fade_tween: Tween
var _zoom_tween: Tween
# When the last frame began, by the clock: the step of a frame while the game time stands still.
var _frame_usec := 0

@onready var _root: Control = $Root
@onready var _background: TextureRect = %Background
@onready var _title: Label = %Title
@onready var _bar: ProgressBar = %Bar
@onready var _tip: Label = %Tip


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	visible = false
	_root.modulate.a = 0.0
	set_process(false)
	set_process_input(false)


## Cover the game: take its last frame (hide beforehand what should not be in the picture), then come up over it with
## the name of the place [param title], which is translated. Returns when the screen covers the game.
func open(title: String) -> void:
	_open = true
	# From now on: the frame is taken a couple of frames later, and the game must not move meanwhile.
	set_process_input(true)
	_title.text = title
	_title.visible = not title.is_empty()
	_target = 0.0
	_shown = 0.0
	_bar.value = 0.0
	_show_tip(false)
	_background.texture = await _capture()
	visible = true
	_frame_usec = Time.get_ticks_usec()
	set_process(true)
	_start_zoom()
	await _fade(1.0)


## Set how far the loading has got, from 0 to 1. The bar never goes back: a smaller value than before is ignored (the
## progress of a load can drop when the loader finds more files to load).
func set_progress(value: float) -> void:
	_target = maxf(_target, clampf(value, 0.0, 1.0))


## Go away: when the bar has caught up with the progress, fade out. Returns when the game is seen again.
func close() -> void:
	while is_processing() and _shown < _target:
		await get_tree().process_frame
	await _fade(0.0)
	visible = false
	set_process(false)
	set_process_input(false)
	if _zoom_tween != null:
		_zoom_tween.kill()
	_background.texture = null
	_open = false


## The screen is up, or coming or going.
func is_open() -> bool:
	return _open


## How much of the bar is filled now, from 0 to 1.
func get_shown_progress() -> float:
	return _shown


## The tip shown now; empty if there are no tips.
func get_tip() -> String:
	return tips[_tip_index] if _tip_index >= 0 and _tip_index < tips.size() else ""


func _input(_event: InputEvent) -> void:
	# The game gets no input while the screen is up: neither the clicks nor the keys of the interface.
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var step := _get_real_step(delta)
	# Quickly while far behind, at least a little every frame, so that the bar gets to the end.
	_shown = move_toward(_shown, _target, maxf((_target - _shown) * 6.0, 0.5) * step)
	_bar.value = _shown
	if tips.size() > 1:
		_tip_left -= step
		if _tip_left <= 0.0:
			_show_tip(true)


## The step of the frame without [member Engine.time_scale]: the screen keeps its pace in slow motion, and with the game
## time stopped it goes by the clock.
func _get_real_step(delta: float) -> float:
	var now := Time.get_ticks_usec()
	var step := delta / Engine.time_scale if Engine.time_scale > 0.0 else minf((now - _frame_usec) / 1000000.0, 0.1)
	_frame_usec = now
	return step


## The last frame of the game, small: shrunk eight times it is already soft, and the shader blurs it the rest of the
## way. [code]null[/code] where no window draws: a run without a window, a minimized window.
func _capture() -> Texture2D:
	if not DisplayServer.window_can_draw():
		return null
	# What was hidden when the screen was asked to open leaves the picture in the next frame drawn.
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return null
	for i in 3:
		image.shrink_x2()
	return ImageTexture.create_from_image(image)


## Another tip, not the one just shown; [param animated]: the old one fades out and the new one in.
func _show_tip(animated: bool) -> void:
	_tip_left = tip_time
	_tip.visible = not tips.is_empty()
	if tips.is_empty():
		return
	var index := randi() % tips.size()
	if index == _tip_index:
		index = (index + 1) % tips.size()
	_tip_index = index
	if not animated:
		_tip.text = tips[index]
		_tip.modulate.a = 1.0
		return
	var tween := create_tween().set_ignore_time_scale()
	tween.tween_property(_tip, ^"modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: _tip.text = tips[_tip_index])
	tween.tween_property(_tip, ^"modulate:a", 1.0, 0.25)


func _start_zoom() -> void:
	if _zoom_tween != null:
		_zoom_tween.kill()
	_background.pivot_offset = _background.size / 2.0
	_background.scale = Vector2.ONE
	_zoom_tween = create_tween().set_ignore_time_scale()
	_zoom_tween.tween_property(_background, ^"scale", Vector2.ONE * (1.0 + zoom), zoom_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _fade(alpha: float) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	if fade_time <= 0.0:
		_root.modulate.a = alpha
		return
	_fade_tween = create_tween().set_ignore_time_scale()
	_fade_tween.tween_property(_root, ^"modulate:a", alpha, fade_time)
	await _fade_tween.finished
