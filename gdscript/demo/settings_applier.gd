extends Node
## Applies the game settings (the [code]Settings[/code] autoload) to the demo nodes: at startup and on every change.
## The game components know nothing about settings: the "setting → property" mapping is gathered here.
## [GameSettings] applies the engine settings (FPS, V-Sync, interpolation, UI scale, language, volume) itself.

@export var player: GroundCharacter
@export var player_actions: CharacterActionInput
@export var ledge_guard: LedgeGuard
@export var player_input: PointClickMoveInput
@export var camera_rig: OrbitCameraRig
@export var camera_arm: CameraArm
@export var character_sounds: CharacterSounds

## The player's look.
@export var player_appearance: CharacterAppearance

## The player's silhouette behind obstacles.
@export var player_silhouette: OccludedSilhouette

## The character's path line.
@export var path_view: Node3D

## The controls hint.
@export var help_panel: Control

@export var fps_counter: Control

## The panel with the character's state and events.
@export var character_state: Control

## Hint lines about the keys with RMB, sprint and jump: they hide when these are turned off.
@export var keys_help: Control
@export var strafe_help: Control
@export var sprint_help: Control
@export var jump_help: Control


func _ready() -> void:
	for key: StringName in GameSettings.DEFAULTS:
		_apply(key, Settings.get_value(key))
	Settings.changed.connect(_apply)


func _apply(key: StringName, value: Variant) -> void:
	match key:
		GameSettings.LEDGE_GUARD:
			if ledge_guard != null:
				ledge_guard.enabled = value
		GameSettings.HOLD_MODE:
			if player_input != null:
				player_input.hold_mode = int(value) as PointClickMoveInput.HoldMode
		GameSettings.HIDE_CURSOR_ON_HOLD:
			if player_input != null:
				player_input.hide_cursor_while_held = value
		GameSettings.CAMERA_KEYS_MODE:
			if player_input != null:
				player_input.keys_with_camera = int(value) as PointClickMoveInput.KeysMode
			if keys_help != null:
				keys_help.visible = int(value) != PointClickMoveInput.KeysMode.OFF
		GameSettings.CAMERA_STEER_KEYS_MODE:
			if player_input != null:
				player_input.keys_with_camera_steer = int(value) as PointClickMoveInput.KeysMode
			if strafe_help != null:
				strafe_help.visible = int(value) != PointClickMoveInput.KeysMode.OFF
		GameSettings.BACKWARD_SLOWDOWN:
			if player != null:
				player.mover.settings.backward_speed_multiplier = 1.0 - value / 100.0
		GameSettings.JUMP:
			if player != null:
				player.can_jump = value
			if jump_help != null:
				jump_help.visible = value
		GameSettings.SPRINT:
			if player != null:
				player.can_sprint = value
			if sprint_help != null:
				sprint_help.visible = value
		GameSettings.JUMP_HEIGHT:
			if player != null:
				player.jump_height = value
		GameSettings.SPRINT_MODE:
			if player_actions != null:
				player_actions.sprint_mode = int(value) as CharacterActionInput.SprintMode
		GameSettings.FATIGUE:
			if player != null:
				player.sprint_tires = value
		GameSettings.SPRINT_DURATION:
			if player != null:
				player.sprint_duration = value
		GameSettings.CHARACTER_LOOK:
			if player_appearance != null:
				player_appearance.set_look(int(value))
		GameSettings.SILHOUETTE_OUTLINE:
			if player_silhouette != null:
				player_silhouette.outline_enabled = value
		GameSettings.SPRINT_BONUS:
			if player != null:
				# The player has its own running settings (player_locomotion.tres), not shared with NPCs.
				player.mover.settings.sprint_speed_multiplier = 1.0 + value / 100.0
		GameSettings.CAMERA_KEEP_AIM:
			if player_input != null:
				player_input.keep_aim_on_camera_turn = value
		GameSettings.CAMERA_MOUSE_PITCH:
			if camera_rig != null:
				camera_rig.mouse_pitch = value
		GameSettings.CAMERA_KEEP_OUT:
			if camera_arm != null:
				camera_arm.keep_out_of_geometry = value
		GameSettings.CAMERA_PULL_IN:
			if camera_arm != null:
				camera_arm.pull_in_on_occlusion = value
		GameSettings.CAMERA_FOLLOW:
			if camera_rig != null:
				camera_rig.follow_movement = value
		GameSettings.CAMERA_FOLLOW_TIME:
			if camera_rig != null:
				camera_rig.follow_time = value
		GameSettings.CAMERA_ALIGN_PITCH:
			if camera_rig != null:
				camera_rig.follow_pitch = value
		GameSettings.CAMERA_ALIGN_PITCH_ANGLE:
			if camera_rig != null:
				# The setting is how many degrees the camera looks down; on the camera, a downward pitch is negative.
				camera_rig.follow_pitch_angle = -deg_to_rad(value)
		GameSettings.SOUND_FOOTSTEPS:
			if character_sounds != null:
				character_sounds.footsteps_enabled = value
		GameSettings.SOUND_JUMP:
			if character_sounds != null:
				character_sounds.jump_enabled = value
		GameSettings.SOUND_SPRINT:
			if character_sounds != null:
				character_sounds.sprint_enabled = value
		GameSettings.PATH_LINE:
			if path_view != null:
				path_view.visible = value
		GameSettings.HELP:
			if help_panel != null:
				help_panel.visible = value
		GameSettings.FPS_COUNTER:
			if fps_counter != null:
				fps_counter.visible = value
		GameSettings.CHARACTER_STATE:
			if character_state != null:
				character_state.visible = value
