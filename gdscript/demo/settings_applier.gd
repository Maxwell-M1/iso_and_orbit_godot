@tool
extends Node
## Applies the game settings (the [code]Settings[/code] autoload) to the demo nodes: at startup and on every change.
## The game components know nothing about settings: the "setting → property" mapping is gathered here.
## [GameSettings] applies the engine settings (FPS, V-Sync, interpolation, UI scale, language, volume) itself.

## Apply the player's saved settings over the values set in the scene; the scene's values are also what the settings
## window resets to. Off: the scene's nodes keep the values set in the scene, and the settings window does not change
## them; [GameSettings] still applies the engine settings (full screen, frame rate, V-Sync, interpolation, interface
## scale, language, volume).
@export var use_saved_settings := true

## The hero the settings are for: its character with the character's parts, its input and its camera.
@export var hero: PlayableHero:
	set(value):
		hero = value
		update_configuration_warnings()

## The controls hint.
@export var help_panel: Control

@export var fps_counter: Control

## The panel with the character's state and events.
@export var character_state: Control

## Hint lines about looking around on the run, the keys with RMB, sprint and jump: they hide when these are turned off.
@export var look_help: Control
@export var keys_help: Control
@export var strafe_help: Control
@export var sprint_help: Control
@export var jump_help: Control

# The parts of the hero the settings change.
var _player: GroundCharacter
var _player_actions: CharacterActionInput
var _ledge_guard: LedgeGuard
var _player_input: PointClickMoveInput
var _camera_rig: OrbitCameraRig
var _camera_arm: CameraArm
var _character_sounds: CharacterSounds
var _player_appearance: CharacterAppearance
var _player_hover: CharacterHover
var _player_silhouette: OccludedSilhouette
var _path_view: Node3D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if hero != null:
		_player = hero.character
		_player_actions = hero.actions
		_ledge_guard = hero.character.ledge_guard
		_player_input = hero.input
		_camera_rig = hero.camera_rig
		_camera_arm = hero.camera_arm
		_character_sounds = hero.sounds
		_player_appearance = hero.appearance
		_player_hover = hero.hover
		_player_silhouette = hero.silhouette
		_path_view = hero.path_view
	if not use_saved_settings:
		return
	Settings.set_scene_defaults(_capture_scene_defaults())
	for key: StringName in GameSettings.DEFAULTS:
		_apply(key, Settings.get_value(key))
	Settings.changed.connect(_apply)


func _apply(key: StringName, value: Variant) -> void:
	match key:
		GameSettings.LEDGE_GUARD:
			if _ledge_guard != null:
				_ledge_guard.enabled = value
		GameSettings.HOLD_MODE:
			if _player_input != null:
				_player_input.hold_mode = int(value) as PointClickMoveInput.HoldMode
		GameSettings.HIDE_CURSOR_ON_HOLD:
			if _player_input != null:
				_player_input.hide_cursor_while_held = value
		GameSettings.CAMERA_KEYS_MODE:
			if _player_input != null:
				_player_input.keys_with_camera = int(value) as PointClickMoveInput.KeysMode
			if keys_help != null:
				keys_help.visible = int(value) != PointClickMoveInput.KeysMode.OFF
		GameSettings.CAMERA_STEER_KEYS_MODE:
			if _player_input != null:
				_player_input.keys_with_camera_steer = int(value) as PointClickMoveInput.KeysMode
			if strafe_help != null:
				strafe_help.visible = int(value) != PointClickMoveInput.KeysMode.OFF
		GameSettings.LOOK_AROUND:
			if _player_input != null:
				_player_input.look_around_while_held = value
			if look_help != null:
				look_help.visible = value
		GameSettings.BACKWARD_SLOWDOWN:
			if _player != null:
				_player.mover.settings.backward_speed_multiplier = 1.0 - value / 100.0
		GameSettings.JUMP:
			if _player != null:
				_player.can_jump = value
			if jump_help != null:
				jump_help.visible = value
		GameSettings.SPRINT:
			if _player != null:
				_player.can_sprint = value
			if sprint_help != null:
				sprint_help.visible = value
		GameSettings.JUMP_HEIGHT:
			if _player != null:
				_player.jump_height = value
		GameSettings.SPRINT_MODE:
			if _player_actions != null:
				_player_actions.sprint_mode = int(value) as CharacterActionInput.SprintMode
		GameSettings.FATIGUE:
			if _player != null:
				_player.sprint_tires = value
		GameSettings.SPRINT_DURATION:
			if _player != null:
				_player.sprint_duration = value
		GameSettings.CHARACTER_LOOK:
			if _player_appearance != null:
				_player_appearance.set_look(int(value))
		GameSettings.CHARACTER_HOVER:
			if _player_hover != null:
				_player_hover.enabled = value
		GameSettings.SILHOUETTE_OUTLINE:
			if _player_silhouette != null:
				_player_silhouette.outline_enabled = value
		GameSettings.SPRINT_BONUS:
			if _player != null:
				# The player has its own running settings (player_locomotion.tres), not shared with NPCs.
				_player.mover.settings.sprint_speed_multiplier = 1.0 + value / 100.0
		GameSettings.CAMERA_KEEP_AIM:
			if _player_input != null:
				_player_input.keep_aim_on_camera_turn = value
		GameSettings.CAMERA_MOUSE_PITCH:
			if _camera_rig != null:
				_camera_rig.mouse_pitch = value
		GameSettings.CAMERA_KEEP_OUT:
			if _camera_arm != null:
				_camera_arm.keep_out_of_geometry = value
		GameSettings.CAMERA_PULL_IN:
			if _camera_arm != null:
				_camera_arm.pull_in_on_occlusion = value
		GameSettings.CAMERA_FOLLOW:
			if _camera_rig != null:
				_camera_rig.follow_movement = value
		GameSettings.CAMERA_FOLLOW_TIME:
			if _camera_rig != null:
				_camera_rig.follow_time = value
		GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD, GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD_ANGLE:
			if _camera_rig != null:
				# The switch and the angle make one property of the camera: off, the angle is 0, and the camera turns
				# behind any run.
				var on: bool = Settings.get_value(GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD)
				var angle: float = Settings.get_value(GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD_ANGLE)
				var valid_angle := _follow_exception_angle(angle)
				if not is_equal_approx(angle, valid_angle):
					Settings.set_value(GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD_ANGLE, valid_angle)
				angle = valid_angle
				_camera_rig.follow_toward_camera_angle = deg_to_rad(angle) if on else 0.0
		GameSettings.CAMERA_ALIGN_PITCH_TIME:
			if _camera_rig != null:
				_camera_rig.follow_pitch_time = value
		GameSettings.CAMERA_ALIGN_PITCH:
			if _camera_rig != null:
				_camera_rig.follow_pitch = value
		GameSettings.CAMERA_ALIGN_PITCH_ANGLE:
			if _camera_rig != null:
				# The setting is how many degrees the camera looks down; on the camera, a downward pitch is negative.
				_camera_rig.follow_pitch_angle = -deg_to_rad(value)
		GameSettings.CAMERA_ALIGN_HEIGHT:
			if _camera_rig != null:
				_camera_rig.follow_zoom = value
		GameSettings.CAMERA_ALIGN_HEIGHT_LEVEL:
			if _camera_rig != null:
				# The setting is in percent of the wheel's range; on the camera, the zoom goes from 0 to 1.
				_camera_rig.follow_zoom_level = value / 100.0
		GameSettings.CAMERA_ALIGN_HEIGHT_TIME:
			if _camera_rig != null:
				_camera_rig.follow_zoom_time = value
		GameSettings.SOUND_FOOTSTEPS:
			if _character_sounds != null:
				_character_sounds.footsteps_enabled = value
		GameSettings.SOUND_JUMP:
			if _character_sounds != null:
				_character_sounds.jump_enabled = value
		GameSettings.SOUND_SPRINT:
			if _character_sounds != null:
				_character_sounds.sprint_enabled = value
		GameSettings.PATH_LINE:
			if _path_view != null:
				_path_view.visible = value
		GameSettings.HELP:
			if help_panel != null:
				help_panel.visible = value
		GameSettings.FPS_COUNTER:
			if fps_counter != null:
				fps_counter.visible = value
		GameSettings.CHARACTER_STATE:
			if character_state != null:
				character_state.visible = value


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if hero == null:
		warnings.append("Assign Hero in the Inspector.")
	return warnings


func _get_property_list() -> Array[Dictionary]:
	return [{"name": "settings_source", "type": TYPE_STRING,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY}]


func _get(property: StringName) -> Variant:
	if property == &"settings_source":
		return "Scene defaults, then saved Settings preferences" if use_saved_settings else "Authored scene values"
	return null


func _capture_scene_defaults() -> Dictionary:
	var values := {}
	if _ledge_guard != null:
		values[GameSettings.LEDGE_GUARD] = _ledge_guard.enabled
	if _player_input != null:
		values.merge({GameSettings.HOLD_MODE: int(_player_input.hold_mode),
			GameSettings.HIDE_CURSOR_ON_HOLD: _player_input.hide_cursor_while_held,
			GameSettings.CAMERA_KEYS_MODE: int(_player_input.keys_with_camera),
			GameSettings.CAMERA_STEER_KEYS_MODE: int(_player_input.keys_with_camera_steer),
			GameSettings.LOOK_AROUND: _player_input.look_around_while_held,
			GameSettings.CAMERA_KEEP_AIM: _player_input.keep_aim_on_camera_turn})
	if _player != null:
		values.merge({GameSettings.JUMP: _player.can_jump, GameSettings.SPRINT: _player.can_sprint,
			GameSettings.JUMP_HEIGHT: _player.jump_height, GameSettings.FATIGUE: _player.sprint_tires,
			GameSettings.SPRINT_DURATION: _player.sprint_duration,
			GameSettings.SPRINT_BONUS: (_player.mover.settings.sprint_speed_multiplier - 1.0) * 100.0,
			GameSettings.BACKWARD_SLOWDOWN: (1.0 - _player.mover.settings.backward_speed_multiplier) * 100.0})
	if _player_actions != null:
		values[GameSettings.SPRINT_MODE] = int(_player_actions.sprint_mode)
	if _player_appearance != null:
		values[GameSettings.CHARACTER_LOOK] = _player_appearance.get_look()
	if _player_hover != null:
		values[GameSettings.CHARACTER_HOVER] = _player_hover.enabled
	if _player_silhouette != null:
		values[GameSettings.SILHOUETTE_OUTLINE] = _player_silhouette.outline_enabled
	if _camera_rig != null:
		values.merge({GameSettings.CAMERA_MOUSE_PITCH: _camera_rig.mouse_pitch,
			GameSettings.CAMERA_FOLLOW: _camera_rig.follow_movement,
			GameSettings.CAMERA_FOLLOW_TIME: _camera_rig.follow_time,
			GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD: _camera_rig.follow_toward_camera_angle > 0.0,
			GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD_ANGLE:
					_follow_exception_angle(rad_to_deg(_camera_rig.follow_toward_camera_angle)),
			GameSettings.CAMERA_ALIGN_PITCH: _camera_rig.follow_pitch,
			GameSettings.CAMERA_ALIGN_PITCH_ANGLE: -rad_to_deg(_camera_rig.follow_pitch_angle),
			GameSettings.CAMERA_ALIGN_PITCH_TIME: _camera_rig.follow_pitch_time,
			GameSettings.CAMERA_ALIGN_HEIGHT: _camera_rig.follow_zoom,
			GameSettings.CAMERA_ALIGN_HEIGHT_LEVEL: _camera_rig.follow_zoom_level * 100.0,
			GameSettings.CAMERA_ALIGN_HEIGHT_TIME: _camera_rig.follow_zoom_time})
	if _camera_arm != null:
		values[GameSettings.CAMERA_KEEP_OUT] = _camera_arm.keep_out_of_geometry
		values[GameSettings.CAMERA_PULL_IN] = _camera_arm.pull_in_on_occlusion
	if _character_sounds != null:
		values.merge({GameSettings.SOUND_FOOTSTEPS: _character_sounds.footsteps_enabled,
			GameSettings.SOUND_JUMP: _character_sounds.jump_enabled,
			GameSettings.SOUND_SPRINT: _character_sounds.sprint_enabled})
	for pair: Array in [[GameSettings.PATH_LINE, _path_view], [GameSettings.HELP, help_panel],
			[GameSettings.FPS_COUNTER, fps_counter], [GameSettings.CHARACTER_STATE, character_state]]:
		if pair[1] != null:
			values[pair[0]] = pair[1].visible
	return values


## Keep a usable threshold even when the scene represents the disabled mode with zero.
static func _follow_exception_angle(angle: float) -> float:
	var usable: float = angle if angle > 0.0 else GameSettings.DEFAULTS[GameSettings.CAMERA_FOLLOW_EXCEPT_TOWARD_ANGLE]
	return clampf(usable, 5.0, 60.0)
