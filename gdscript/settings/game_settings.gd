class_name GameSettings
extends Node
## Game settings. The instance is the [code]Settings[/code] autoload; the keys are constants of this class
## ([code]GameSettings.LEDGE_GUARD[/code]), so they can be used in [code]match[/code].
##
## Values are stored in [member path] (a [ConfigFile]; the section and the key are the parts of the name before and
## after "/"). The class itself applies the engine settings (full screen, FPS, V-Sync, physics interpolation, UI scale,
## language, volume); the scene applies the settings of scene nodes: it reads [method get_value] and listens to
## [signal changed]. This way the game components know nothing about settings.
##
## A new setting: a constant with the key, a default value in [constant DEFAULTS] and, if the engine applies it,
## a branch in [method _apply_to_engine].

## A setting value has changed (through [method set_value] or [method reset_to_defaults]).
signal changed(key: StringName, value: Variant)

## On the "Character" tab, but the key stays the same: this way an already saved choice is not lost.
const LEDGE_GUARD := &"gameplay/ledge_guard"
const HOLD_MODE := &"gameplay/hold_mode"
const HIDE_CURSOR_ON_HOLD := &"gameplay/hide_cursor_on_hold"
## RMB + WASD: off, sidestep or turn (PointClickMoveInput.KeysMode).
const CAMERA_KEYS_MODE := &"gameplay/camera_keys_mode"
## LMB + RMB + A/D: off, sidestep or diagonal (PointClickMoveInput.KeysMode).
const CAMERA_STEER_KEYS_MODE := &"gameplay/camera_steer_keys_mode"
## How much slower, in percent, the character walks backward.
const BACKWARD_SLOWDOWN := &"gameplay/backward_slowdown"
const JUMP := &"character/jump"
const JUMP_HEIGHT := &"character/jump_height"
const SPRINT := &"character/sprint"
const SPRINT_MODE := &"character/sprint_mode"
## How much faster, in percent, the sprint is than normal running.
const SPRINT_BONUS := &"character/sprint_bonus"
const FATIGUE := &"character/fatigue"
## How many seconds of sprinting a full stamina reserve lasts.
const SPRINT_DURATION := &"character/sprint_duration"
## Hero look: the number of the variant in the lineup of variants, starting from 1 (the player's CharacterAppearance).
const CHARACTER_LOOK := &"character/look"
## RMB pitches the camera with vertical mouse movement (OrbitCameraRig.mouse_pitch).
const CAMERA_MOUSE_PITCH := &"camera/mouse_pitch"
const CAMERA_FOLLOW := &"camera/follow"
const CAMERA_FOLLOW_TIME := &"camera/follow_time"
const CAMERA_ALIGN_PITCH := &"camera/align_pitch"
## How far the camera looks down, in degrees: 0 is horizontal, 90 is straight from above.
const CAMERA_ALIGN_PITCH_ANGLE := &"camera/align_pitch_angle"
const CAMERA_KEEP_AIM := &"camera/keep_aim"
## The camera stops against what is behind it instead of going inside (CameraArm.keep_out_of_geometry).
const CAMERA_KEEP_OUT := &"camera/keep_out_of_geometry"
## The camera moves closer if an obstacle hides the character (CameraArm.pull_in_on_occlusion).
const CAMERA_PULL_IN := &"camera/pull_in_on_occlusion"
## The window takes the whole screen. Inside the editor (the Game tab or its floating window) the window mode does not
## change.
const FULLSCREEN := &"display/fullscreen"
const MAX_FPS := &"display/max_fps"
const VSYNC := &"display/vsync"
const PHYSICS_INTERPOLATION := &"display/physics_interpolation"
## The outline of the character's silhouette behind obstacles (OccludedSilhouette.outline_enabled).
const SILHOUETTE_OUTLINE := &"display/silhouette_outline"
## The scale of the whole interface in percent: 100 is as designed in the scenes, 50 is half the size.
const UI_SCALE := &"interface/ui_scale"
const FPS_COUNTER := &"interface/fps_counter"
## Interface language: the language code ([code]en[/code], [code]ru[/code]) for [method TranslationServer.set_locale].
## English is the language of the scenes and scripts themselves; the others are translations from [code]l10n/ui/[/code].
const LANGUAGE := &"interface/language"
## Overall sound volume in percent (the Master bus).
const SOUND_VOLUME := &"sound/volume"
const SOUND_FOOTSTEPS := &"sound/footsteps"
## Jump and landing.
const SOUND_JUMP := &"sound/jump"
## Sprint start and sprinting.
const SOUND_SPRINT := &"sound/sprint"
const HELP := &"interface/help"
const PATH_LINE := &"interface/path_line"
## The panel with what the character is doing and its latest events ([CharacterMonitor]).
const CHARACTER_STATE := &"interface/character_state"

## Default values; their type is the type of the setting.
const DEFAULTS := {
	LEDGE_GUARD: true,
	HOLD_MODE: 0,  # PointClickMoveInput.HoldMode.STEER
	HIDE_CURSOR_ON_HOLD: true,
	CAMERA_KEYS_MODE: 2,  # PointClickMoveInput.KeysMode.TURN
	CAMERA_STEER_KEYS_MODE: 2,  # PointClickMoveInput.KeysMode.TURN
	BACKWARD_SLOWDOWN: 30.0,  # LocomotionSettings.backward_speed_multiplier = 0.7
	JUMP: true,
	JUMP_HEIGHT: 1.0,
	SPRINT: true,
	SPRINT_MODE: 0,  # CharacterActionInput.SprintMode.HOLD
	SPRINT_BONUS: 50.0,  # LocomotionSettings.sprint_speed_multiplier = 1.5
	FATIGUE: true,
	SPRINT_DURATION: 5.0,
	CHARACTER_LOOK: 10,  # battle mage
	CAMERA_MOUSE_PITCH: false,
	CAMERA_FOLLOW: false,
	CAMERA_FOLLOW_TIME: 1.1,
	CAMERA_ALIGN_PITCH: false,
	CAMERA_ALIGN_PITCH_ANGLE: 22.0,
	CAMERA_KEEP_AIM: true,
	CAMERA_KEEP_OUT: true,
	CAMERA_PULL_IN: false,
	FULLSCREEN: false,
	MAX_FPS: 0,  # 0 means no limit
	VSYNC: false,
	PHYSICS_INTERPOLATION: true,  # as physics/common/physics_interpolation in project.godot
	SILHOUETTE_OUTLINE: true,
	UI_SCALE: 75.0,
	FPS_COUNTER: true,
	LANGUAGE: "en",
	SOUND_VOLUME: 100.0,
	SOUND_FOOTSTEPS: true,
	SOUND_JUMP: true,
	SOUND_SPRINT: false,
	HELP: true,
	PATH_LINE: false,
	CHARACTER_STATE: false,
}

## Keys that no longer exist: they are removed from the file on load.
const _OBSOLETE_KEYS: Array[StringName] = [&"gameplay/camera_keys", &"gameplay/camera_strafe", &"gameplay/side_keys"]

## Where to store the settings.
@export var path := "user://settings.cfg"

## Whether to save changes to disk. Checks turn it off so as not to touch the player's settings.
var persistent := true

var _config := ConfigFile.new()
var _dirty := false


func _init() -> void:
	# Load before the _ready() of scene nodes: they need the settings from the first frame.
	var error := _config.load(path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Settings: can't read %s (%s), using defaults." % [path, error_string(error)])
	for key: StringName in _OBSOLETE_KEYS:
		if _config.has_section_key(_section(key), _name(key)):
			_config.erase_section_key(_section(key), _name(key))
			_dirty = true


func _ready() -> void:
	for key: StringName in DEFAULTS:
		_apply_to_engine(key, get_value(key))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		save()


func has_setting(key: StringName) -> bool:
	return DEFAULTS.has(key)


func get_value(key: StringName) -> Variant:
	assert(has_setting(key), "Unknown setting \"%s\"." % key)
	var default: Variant = DEFAULTS[key]
	var value: Variant = _config.get_value(_section(key), _name(key), default)
	# The file may have been edited by hand: a value of the wrong type is replaced with the default value (an integer
	# where a float is expected is converted).
	if typeof(value) == typeof(default):
		return value
	if typeof(default) == TYPE_FLOAT and typeof(value) == TYPE_INT:
		return float(value)
	return default


func set_value(key: StringName, value: Variant) -> void:
	assert(has_setting(key), "Unknown setting \"%s\"." % key)
	if typeof(DEFAULTS[key]) == TYPE_FLOAT:
		value = float(value)
	if get_value(key) == value:
		return
	_config.set_value(_section(key), _name(key), value)
	_dirty = true
	_apply_to_engine(key, value)
	changed.emit(key, value)


func reset_to_defaults() -> void:
	for key: StringName in DEFAULTS:
		set_value(key, DEFAULTS[key])


## Write the changes to disk. The settings window calls it on closing; on exiting the game, it happens by itself.
func save() -> void:
	if not _dirty or not persistent:
		return
	var error := _config.save(path)
	if error != OK:
		push_warning("Settings: can't save %s (%s)." % [path, error_string(error)])
		return
	_dirty = false


func _apply_to_engine(key: StringName, value: Variant) -> void:
	match key:
		FULLSCREEN:
			_apply_fullscreen(value)
		MAX_FPS, VSYNC:
			_apply_frame_rate()
		PHYSICS_INTERPOLATION:
			get_tree().physics_interpolation = value
		UI_SCALE:
			# In the canvas_items stretch mode, this is the scale of all 2D over the game; the 3D view does not change.
			get_tree().root.content_scale_factor = value / 100.0
		SOUND_VOLUME:
			_apply_volume(value)
		LANGUAGE:
			TranslationServer.set_locale(value)


## Only switches between full screen and a window: a window that is already maximized stays so at startup.
static func _apply_fullscreen(on: bool) -> void:
	var mode := DisplayServer.window_get_mode()
	var fullscreen := mode in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	if on != fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


## With V-Sync, an FPS limit at the monitor's refresh rate or above only conflicts with V-Sync (240 on a 240 Hz monitor
## gave about 220 frames), so in that case V-Sync alone limits the frames.
func _apply_frame_rate() -> void:
	var vsync: bool = get_value(VSYNC)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	var limit: int = get_value(MAX_FPS)
	var refresh := roundi(DisplayServer.screen_get_refresh_rate())
	if vsync and refresh > 0 and limit >= refresh:
		limit = 0
	Engine.max_fps = limit


## Volume of the Master bus: the percentage is a fraction of the amplitude (50% is 6 dB quieter); 0 mutes the bus
## completely.
static func _apply_volume(percent: float) -> void:
	var bus := AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_mute(bus, percent <= 0.0)
	if percent > 0.0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(percent / 100.0))


static func _section(key: StringName) -> String:
	return String(key).get_slice("/", 0)


static func _name(key: StringName) -> String:
	return String(key).get_slice("/", 1)
