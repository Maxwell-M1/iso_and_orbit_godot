extends UiScreen
## The settings window (F10): the "Controls", "Character", "Camera", "Display", "Interface" and "Sound" tabs.
##
## Each control is bound to its setting by itself ([SettingCheckButton], [SettingOptionButton], [SettingSlider],
## [SettingLanguageButton]), so the window only shows the dependencies between them and the hints. A new setting is a
## new control in the scene with a key from [GameSettings]; the window code does not need to change.
##
## The tab pages are [ScrollContainer]s: a long tab scrolls (following the keyboard focus too), and the window does
## not grow. The window height is the [member Control.custom_minimum_size] of the [TabContainer].

## Settings that decide whether other controls of the window can be changed (see [method _update_dependent_rows]).
const _DEPENDENCY_KEYS: Array[StringName] = [
	GameSettings.CAMERA_KEYS_MODE, GameSettings.JUMP, GameSettings.SPRINT, GameSettings.FATIGUE,
	GameSettings.CAMERA_FOLLOW, GameSettings.CAMERA_ALIGN_PITCH,
]

@onready var _follow_time_row: Control = %FollowTimeRow
@onready var _follow_time: SettingSlider = %FollowTime
@onready var _align_pitch_row: Control = %AlignPitchRow
@onready var _align_pitch_angle: SettingSlider = %AlignPitchAngle
@onready var _backward_slowdown_row: Control = %BackwardSlowdownRow
@onready var _backward_slowdown: SettingSlider = %BackwardSlowdown
@onready var _jump_height_row: Control = %JumpHeightRow
@onready var _jump_height: SettingSlider = %JumpHeight
@onready var _sprint_mode_row: Control = %SprintModeRow
@onready var _sprint_mode: OptionButton = %SprintMode
@onready var _sprint_bonus_row: Control = %SprintBonusRow
@onready var _sprint_bonus: SettingSlider = %SprintBonus
@onready var _fatigue: CheckButton = %Fatigue
@onready var _sprint_duration_row: Control = %SprintDurationRow
@onready var _sprint_duration: SettingSlider = %SprintDuration
@onready var _vsync_hint: Label = %VsyncHint
@onready var _fullscreen: CheckButton = %Fullscreen


func _ready() -> void:
	Settings.changed.connect(_on_setting_changed)
	_update_dependent_rows()
	# Inside the editor (the Game tab or its floating window) the window belongs to the editor, and the game cannot
	# change its mode.
	_set_enabled(_fullscreen, not Engine.is_embedded_in_editor())
	# The code composes the V-Sync hint from a translation and the monitor's refresh rate.
	_vsync_hint.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_update_vsync_hint()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_vsync_hint()


func _screen_closed() -> void:
	Settings.save()


func _on_reset_pressed() -> void:
	Settings.reset_to_defaults()


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key in _DEPENDENCY_KEYS:
		_update_dependent_rows()
	elif key == GameSettings.VSYNC or key == GameSettings.MAX_FPS:
		_update_vsync_hint()


## Controls that make sense only with another setting: the backward slowdown with sidestepping on RMB (only there
## does S move the character backward), the jump height with jumping, everything about the sprint with the sprint,
## the stamina also with fatigue; the pitch when the camera aligns it, the camera speed when the camera follows the
## run or aligns the pitch.
func _update_dependent_rows() -> void:
	var camera_keys: int = Settings.get_value(GameSettings.CAMERA_KEYS_MODE)
	var jump: bool = Settings.get_value(GameSettings.JUMP)
	var sprint: bool = Settings.get_value(GameSettings.SPRINT)
	var fatigue: bool = Settings.get_value(GameSettings.FATIGUE)
	var follow: bool = Settings.get_value(GameSettings.CAMERA_FOLLOW)
	var align_pitch: bool = Settings.get_value(GameSettings.CAMERA_ALIGN_PITCH)
	_set_enabled(_backward_slowdown, camera_keys == PointClickMoveInput.KeysMode.SIDESTEP, _backward_slowdown_row)
	_set_enabled(_jump_height, jump, _jump_height_row)
	_set_enabled(_sprint_mode, sprint, _sprint_mode_row)
	_set_enabled(_sprint_bonus, sprint, _sprint_bonus_row)
	_set_enabled(_fatigue, sprint)
	_set_enabled(_sprint_duration, sprint and fatigue, _sprint_duration_row)
	_set_enabled(_align_pitch_angle, align_pitch, _align_pitch_row)
	_set_enabled(_follow_time, follow or align_pitch, _follow_time_row)


## A disabled control cannot be changed, and its row is paler (a button without a row looks disabled anyway).
static func _set_enabled(control: Control, enabled: bool, row: Control = null) -> void:
	if control is Slider:
		(control as Slider).editable = enabled
	elif control is BaseButton:
		(control as BaseButton).disabled = not enabled
	if row != null:
		row.modulate.a = 1.0 if enabled else 0.5


func _update_vsync_hint() -> void:
	var refresh := roundi(DisplayServer.screen_get_refresh_rate())
	var monitor := tr(" (%d Hz)") % refresh if refresh > 0 else ""
	_vsync_hint.text = tr("With V-Sync there are never more frames than the monitor's refresh rate%s, and an FPS "
			+ "limit above it has no effect. The smoothest limits are those that divide this rate evenly.") % monitor
