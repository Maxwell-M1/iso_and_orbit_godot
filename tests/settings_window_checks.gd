extends "res://tests/check_suite.gd"
## The settings window (F10): pause, keyboard focus, the released cursor, every tab reaches the nodes, dependent
## controls turn pale, reset to the default values, Esc.


func _checks() -> Array[Callable]:
	return [
		_check_settings_window,
	]


func _check_settings_window() -> void:
	print("\n== settings window (F10)")
	var ui: UiRoot = _main.get_node("UiRoot")
	var center := _tree.root.get_visible_rect().size / 2.0
	_send_motion(center, Vector2.ZERO)
	_send_button(MOUSE_BUTTON_RIGHT, true, center)
	await _frames(2)
	var rotating_before := _rig.is_rotating()
	_send_key(KEY_F10)
	await _frames(2)
	var screen := ui.get_top_screen()
	var opened := screen != null
	print("window open %s, paused %s, focus on %s; camera was rotating %s, now %s, mouse mode %d" % [
		opened, _tree.paused, _tree.root.gui_get_focus_owner(), rotating_before, _rig.is_rotating(), Input.mouse_mode])
	_expect(opened and _tree.paused, "F10 opens the settings window and pauses the game")
	if not opened:
		return
	_expect(_tree.root.gui_get_focus_owner() == screen.initial_focus, "keyboard focus is on the first setting")
	_expect(rotating_before and not _rig.is_rotating() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
			"opening the window ends camera rotation and frees the cursor")
	_send_button(MOUSE_BUTTON_RIGHT, false, center)

	(screen.find_child("LedgeGuard") as CheckButton).button_pressed = false
	# A headless window has no window mode to change, so only the setting is checked.
	var settings: GameSettings = _tree.root.get_node(^"Settings")
	var fullscreen := screen.find_child("Fullscreen") as CheckButton
	var fullscreen_available := not fullscreen.disabled
	fullscreen.button_pressed = true
	var max_fps := screen.find_child("MaxFps") as OptionButton
	max_fps.select(1)
	max_fps.item_selected.emit(1)
	var interpolation_default: bool = GameSettings.DEFAULTS[GameSettings.PHYSICS_INTERPOLATION]
	(screen.find_child("PhysicsInterpolation") as CheckButton).button_pressed = not interpolation_default
	(screen.find_child("FpsCounter") as CheckButton).button_pressed = false
	(screen.find_child("HideCursor") as CheckButton).button_pressed = false
	(screen.find_child("LookAround") as CheckButton).button_pressed = false
	var input := _input
	var look_help: Control = _main.get_node("Hud/Panel/Lines/LookHelp")
	var follow_time := screen.find_child("FollowTime") as HSlider
	var follow_time_text := screen.find_child("FollowTimeValue") as Label
	var slider_locked := not follow_time.editable
	var pitch_angle := screen.find_child("AlignPitchAngle") as HSlider
	var pitch_time := screen.find_child("AlignPitchTime") as HSlider
	var pitch_slider_locked := not pitch_angle.editable and not pitch_time.editable
	(screen.find_child("AlignPitch") as CheckButton).button_pressed = true
	var pitch_unlocked := pitch_angle.editable and pitch_time.editable
	var turn_speed_still_locked := not follow_time.editable
	pitch_angle.value = 60.0
	pitch_time.value = 2.0
	var pitch_text := (screen.find_child("AlignPitchValue") as Label).text
	(screen.find_child("CameraFollow") as CheckButton).button_pressed = true
	follow_time.value = 0.0
	var fps_counter: Control = _main.get_node("Hud/FpsCounter")
	print(("after the clicks: ledge guard %s, max_fps %d, interpolation %s, FPS counter %s, follow %s in %.1f s " +
			"(\"%s\"), slider locked while off %s") % [
		_player.ledge_guard.enabled, Engine.max_fps, _tree.physics_interpolation, fps_counter.visible,
		_rig.follow_movement, _rig.follow_time, follow_time_text.text, slider_locked])
	_expect(not _player.ledge_guard.enabled, "the ledge guard switch reaches the character")
	_expect(fullscreen_available and settings.get_value(GameSettings.FULLSCREEN),
			"the fullscreen switch is available outside the editor and changes its setting")
	_expect(Engine.max_fps == 30, "the FPS limit is applied")
	_expect(_tree.physics_interpolation != interpolation_default, "the physics interpolation switch reaches the engine")
	_expect(not fps_counter.visible, "the FPS counter hides")
	_expect(not input.hide_cursor_while_held, "the hide-cursor switch reaches the input")
	_expect(not input.look_around_while_held and not look_help.visible,
			"the look-around switch reaches the input, and its hint line hides")
	_expect(slider_locked and follow_time.editable and _rig.follow_movement and _rig.follow_time == 0.0
			and follow_time_text.text == "instant", "camera follow and its speed reach the camera")
	print(("pitch: sliders locked while off %s, unlocked by it %s (the turn's speed still locked %s), follow_pitch %s " +
			"at %.1f deg (\"%s\") in %.1f s, slider %.0f..%.0f, camera limits %.1f..%.1f") % [
		pitch_slider_locked, pitch_unlocked, turn_speed_still_locked, _rig.follow_pitch,
		rad_to_deg(_rig.follow_pitch_angle), pitch_text, _rig.follow_pitch_time, pitch_angle.min_value,
		pitch_angle.max_value, -rad_to_deg(_rig.max_pitch), -rad_to_deg(_rig.min_pitch)])
	_expect(pitch_slider_locked and pitch_unlocked and turn_speed_still_locked and _rig.follow_pitch
			and is_equal_approx(_rig.follow_pitch_angle, deg_to_rad(-60.0)) and pitch_text == "60°"
			and is_equal_approx(_rig.follow_pitch_time, 2.0),
			"pitch alignment, its angle and its own speed reach the camera; the turn keeps its speed")
	_expect(is_equal_approx(pitch_angle.min_value, -rad_to_deg(_rig.max_pitch))
			and is_equal_approx(pitch_angle.max_value, -rad_to_deg(_rig.min_pitch)),
			"the pitch slider spans the camera limits")

	# The height: its level and its own speed, locked while it is off.
	var height_level := screen.find_child("AlignHeightLevel") as HSlider
	var height_time := screen.find_child("AlignHeightTime") as HSlider
	var height_locked := not height_level.editable and not height_time.editable
	(screen.find_child("AlignHeight") as CheckButton).button_pressed = true
	var height_unlocked := height_level.editable and height_time.editable
	height_level.value = 80.0
	height_time.value = 2.5
	var height_text := (screen.find_child("AlignHeightValue") as Label).text
	var height_time_text := (screen.find_child("AlignHeightTimeValue") as Label).text
	print("height: locked while off %s, unlocked by it %s, follow_zoom %s to %.2f (\"%s\") in %.1f s (\"%s\"), slider %.0f..%.0f" % [
		height_locked, height_unlocked, _rig.follow_zoom, _rig.follow_zoom_level, height_text, _rig.follow_zoom_time,
		height_time_text, height_level.min_value, height_level.max_value])
	_expect(height_locked and height_unlocked and _rig.follow_zoom and is_equal_approx(_rig.follow_zoom_level, 0.8)
			and height_text == "80%" and is_equal_approx(_rig.follow_zoom_time, 2.5) and height_time_text == "2.5 s"
			and is_equal_approx(height_level.min_value, 0.0) and is_equal_approx(height_level.max_value, 100.0),
			"height alignment, its level over the whole wheel range and its own speed reach the camera")

	var keys_help: Control = _main.get_node("Hud/Panel/Lines/KeysHelp")
	var strafe_help: Control = _main.get_node("Hud/Panel/Lines/StrafeHelp")
	var backward := screen.find_child("BackwardSlowdown") as HSlider
	backward.value = 50.0
	var backward_text := (screen.find_child("BackwardSlowdownValue") as Label).text
	print("backward slowdown 50%% (\"%s\"): backward_speed_multiplier %.2f" % [
		backward_text, _mover.settings.backward_speed_multiplier])
	_expect(is_equal_approx(_mover.settings.backward_speed_multiplier, 0.5) and backward_text == "50%",
			"the backward slowdown slider reaches the locomotion settings")
	var look := screen.find_child("Look") as OptionButton
	var appearance: CharacterAppearance = _player.get_node("Appearance")
	var look_default := look.get_selected_id()
	var expected_look: int = GameSettings.DEFAULTS[GameSettings.CHARACTER_LOOK]
	look.select(look.get_item_index(5))
	look.item_selected.emit(look.get_item_index(5))
	var look_applied := appearance.get_look()
	look.select(look.get_item_index(look_default))
	look.item_selected.emit(look.get_item_index(look_default))
	print("look list: %d items, selected %d by default; picking 5 gives the hero look %d, back to %d" % [
		look.item_count, look_default, look_applied, appearance.get_look()])
	_expect(look.item_count == 10 and look_default == expected_look and look_applied == 5
			and appearance.get_look() == expected_look,
			"the Character tab picks the hero look from the ten options")
	var camera_keys := screen.find_child("CameraKeys") as OptionButton
	var camera_steer_keys := screen.find_child("CameraSteerKeys") as OptionButton
	camera_keys.select(2)
	camera_keys.item_selected.emit(2)
	var turn_applied := input.keys_with_camera == PointClickMoveInput.KeysMode.TURN
	var backward_locked_by_turn := not backward.editable
	camera_keys.select(0)
	camera_keys.item_selected.emit(0)
	camera_steer_keys.select(2)
	camera_steer_keys.item_selected.emit(2)
	var steer_turn_applied := input.keys_with_camera_steer == PointClickMoveInput.KeysMode.TURN
	camera_steer_keys.select(0)
	camera_steer_keys.item_selected.emit(0)
	print(("controls tab: right button keys %s (hint %s), both buttons keys %s (hint %s); " +
			"backward slider locked by TURN %s") % [
		input.keys_with_camera, keys_help.visible, input.keys_with_camera_steer, strafe_help.visible,
		backward_locked_by_turn])
	_expect(turn_applied and steer_turn_applied and input.keys_with_camera == PointClickMoveInput.KeysMode.OFF
			and input.keys_with_camera_steer == PointClickMoveInput.KeysMode.OFF and not keys_help.visible
			and not strafe_help.visible, "both key lists reach the input, OFF hides their hints")
	_expect(backward_locked_by_turn and not backward.editable,
			"the backward slowdown works only for sidestepping with the right button")

	var jump_help: Control = _main.get_node("Hud/Panel/Lines/JumpHelp")
	var sprint_help: Control = _main.get_node("Hud/Panel/Lines/SprintHelp")
	var sprint_bonus := screen.find_child("SprintBonus") as HSlider
	var actions := _actions
	var jump_height := screen.find_child("JumpHeight") as HSlider
	var sprint_mode := screen.find_child("SprintMode") as OptionButton
	var fatigue := screen.find_child("Fatigue") as CheckButton
	var duration := screen.find_child("SprintDuration") as HSlider
	jump_height.value = 1.5
	sprint_mode.select(1)
	sprint_mode.item_selected.emit(1)
	duration.value = 8.0
	fatigue.button_pressed = false
	var duration_locked := not duration.editable
	print(("character tab: jump_height %.1f, Shift mode %d, sprint_tires %s, sprint_duration %.1f, " +
			"duration slider locked without fatigue %s") % [
		_player.jump_height, actions.sprint_mode, _player.sprint_tires, _player.sprint_duration, duration_locked])
	_expect(is_equal_approx(_player.jump_height, 1.5) and actions.sprint_mode == CharacterActionInput.SprintMode.TOGGLE
			and not _player.sprint_tires and is_equal_approx(_player.sprint_duration, 8.0) and duration_locked,
			"jump height, Shift mode, fatigue and its duration reach the character; no fatigue locks the duration")
	var bonus_unlocked := sprint_bonus.editable
	(screen.find_child("Jump") as CheckButton).button_pressed = false
	(screen.find_child("Sprint") as CheckButton).button_pressed = false
	var bonus_locked := not sprint_bonus.editable and sprint_mode.disabled and fatigue.disabled \
			and not jump_height.editable
	sprint_bonus.value = 80.0
	var bonus_text := (screen.find_child("SprintBonusValue") as Label).text
	print(("character tab: can_jump %s, jump hint %s; can_sprint %s, sprint hint %s, bonus slider %s -> %s; " +
			"bonus 80%% (\"%s\") -> multiplier %.2f") % [
		_player.can_jump, jump_help.visible, _player.can_sprint, sprint_help.visible,
		"unlocked" if bonus_unlocked else "locked", "locked" if bonus_locked else "unlocked", bonus_text,
		_mover.settings.sprint_speed_multiplier])
	_expect(not _player.can_jump and not jump_help.visible, "the jump switch reaches the character, its hint hides")
	_expect(not _player.can_sprint and not sprint_help.visible and bonus_unlocked and bonus_locked,
			"the sprint switch reaches the character, its hint hides, its controls lock (and jump height without jump)")
	_expect(is_equal_approx(_mover.settings.sprint_speed_multiplier, 1.8) and bonus_text == "+80%",
			"sprint bonus 80% makes the sprint 1.8 times faster")
	var hover_switch := screen.find_child("Hover") as CheckButton
	var footsteps := screen.find_child("SoundFootsteps") as CheckButton
	var hover: CharacterHover = _player.get_node("Visual/Hover")
	var walking := not hover.enabled and not footsteps.disabled
	hover_switch.button_pressed = true
	var floating := hover.enabled and footsteps.disabled
	hover_switch.button_pressed = false
	var walking_again := not hover.enabled and not footsteps.disabled
	print("character tab: walking %s, the floating switch on: floating with the footsteps sound locked %s, off: walking %s" % [
		walking, floating, walking_again])
	_expect(walking and floating and walking_again,
			"the floating switch reaches the hero; the footsteps sound switch locks while the hero floats")

	var master := AudioServer.get_bus_index(&"Master")
	var volume := screen.find_child("SoundVolume") as HSlider
	var volume_default := AudioServer.get_bus_volume_db(master)
	volume.value = 50.0
	var volume_half := AudioServer.get_bus_volume_db(master)
	volume.value = 0.0
	var muted := AudioServer.is_bus_mute(master)
	var volume_text := (screen.find_child("SoundVolumeValue") as Label).text
	print("volume: 100%% -> %.1f dB, 50%% -> %.1f dB, 0%% -> muted %s (\"%s\")" % [
		volume_default, volume_half, muted, volume_text])
	_expect(is_zero_approx(volume_default) and absf(volume_half - linear_to_db(0.5)) < 0.01 and muted
			and volume_text == "off",
			"the volume slider sets the Master bus: 50% is 6 dB down, 0 mutes")
	var sounds: CharacterSounds = _player.get_node("Sounds")
	# Each switch goes to the position opposite to its default value.
	var sound_switches := {
		SoundFootsteps = GameSettings.SOUND_FOOTSTEPS, SoundJump = GameSettings.SOUND_JUMP,
		SoundSprint = GameSettings.SOUND_SPRINT,
	}
	var flipped := []
	for name: String in sound_switches:
		var flip: bool = not GameSettings.DEFAULTS[sound_switches[name]]
		(screen.find_child(name) as CheckButton).button_pressed = flip
		flipped.append(flip)
	print("sound tab, every switch flipped from its default: footsteps %s, jump %s, sprint %s" % [
		sounds.footsteps_enabled, sounds.jump_enabled, sounds.sprint_enabled])
	_expect([sounds.footsteps_enabled, sounds.jump_enabled, sounds.sprint_enabled] == flipped,
			"the sound switches reach the character sounds")

	var ui_scale := screen.find_child("UiScale") as HSlider
	var ui_scale_text := screen.find_child("UiScaleValue") as Label
	var scale_default := _tree.root.content_scale_factor
	var expected_scale: float = GameSettings.DEFAULTS[GameSettings.UI_SCALE] / 100.0
	ui_scale.drag_started.emit()
	ui_scale.value = 80.0
	var scale_while_dragging := _tree.root.content_scale_factor
	var text_while_dragging := ui_scale_text.text
	ui_scale.drag_ended.emit(true)
	var scale_after_drag := _tree.root.content_scale_factor
	ui_scale.value = 100.0
	var scale_at_once := _tree.root.content_scale_factor
	print(("UI scale: default %.2f, while dragging to 80%% %.2f (\"%s\"), after release %.2f, " +
			"by keys to 100%% %.2f; slider %d..%d") % [
		scale_default, scale_while_dragging, text_while_dragging, scale_after_drag, scale_at_once, ui_scale.min_value,
		ui_scale.max_value])
	_expect(is_equal_approx(scale_default, expected_scale) and is_equal_approx(ui_scale.min_value, 50.0)
			and is_equal_approx(ui_scale.max_value, 100.0), "UI scale: 50-100%, the default of the settings at start")
	_expect(is_equal_approx(scale_while_dragging, expected_scale) and text_while_dragging == "80%"
			and is_equal_approx(scale_after_drag, 0.8),
			"UI scale changes when the dragged slider is released, the label at once")
	_expect(is_equal_approx(scale_at_once, 1.0), "UI scale changes at once from the keyboard")

	(screen.find_child("Reset") as Button).pressed.emit()
	await _frames(1)
	var keys_default: int = GameSettings.DEFAULTS[GameSettings.CAMERA_KEYS_MODE]
	var steer_keys_default: int = GameSettings.DEFAULTS[GameSettings.CAMERA_STEER_KEYS_MODE]
	_expect(_player.ledge_guard.enabled and not settings.get_value(GameSettings.FULLSCREEN) and Engine.max_fps == 0
			and _tree.physics_interpolation == interpolation_default
			and fps_counter.visible
			and not _rig.follow_movement and not _rig.follow_pitch and input.hide_cursor_while_held
			and input.look_around_while_held == GameSettings.DEFAULTS[GameSettings.LOOK_AROUND]
			and look_help.visible == GameSettings.DEFAULTS[GameSettings.LOOK_AROUND]
			and max_fps.get_selected_id() == 0 and not pitch_angle.editable and not pitch_time.editable
			and not follow_time.editable
			and is_equal_approx(_rig.follow_pitch_time, GameSettings.DEFAULTS[GameSettings.CAMERA_ALIGN_PITCH_TIME])
			and not _rig.follow_zoom and not height_level.editable and not height_time.editable
			and is_equal_approx(_rig.follow_zoom_level, GameSettings.DEFAULTS[GameSettings.CAMERA_ALIGN_HEIGHT_LEVEL] / 100.0)
			and is_equal_approx(_rig.follow_zoom_time, GameSettings.DEFAULTS[GameSettings.CAMERA_ALIGN_HEIGHT_TIME])
			and is_equal_approx(_tree.root.content_scale_factor, expected_scale)
			and _player.can_jump and _player.can_sprint and jump_help.visible and sprint_help.visible
			and is_equal_approx(_mover.settings.sprint_speed_multiplier, 1.5) and sprint_bonus.editable
			and is_equal_approx(_player.jump_height, 1.0)
			and actions.sprint_mode == CharacterActionInput.SprintMode.HOLD
			and _player.sprint_tires and is_equal_approx(_player.sprint_duration, 5.0) and jump_height.editable
			and not sprint_mode.disabled and not fatigue.disabled and duration.editable
			and input.keys_with_camera == keys_default and keys_help.visible == (keys_default != 0)
			and input.keys_with_camera_steer == steer_keys_default and strafe_help.visible == (steer_keys_default != 0)
			and camera_keys.get_selected_id() == keys_default and camera_steer_keys.get_selected_id() == steer_keys_default
			and [sounds.footsteps_enabled, sounds.jump_enabled, sounds.sprint_enabled] == flipped.map(
				func(flip: bool) -> bool: return not flip)
			and not AudioServer.is_bus_mute(master) and is_zero_approx(AudioServer.get_bus_volume_db(master))
			and is_equal_approx(_mover.settings.backward_speed_multiplier, 0.7)
			and not hover.enabled and not footsteps.disabled
			and backward.editable == (keys_default == PointClickMoveInput.KeysMode.SIDESTEP),
			"reset brings back the defaults, controls follow")

	_send_key(KEY_ESCAPE)
	await _frames(2)
	print("after Esc: window open %s, paused %s" % [ui.has_open_screens(), _tree.paused])
	_expect(not ui.has_open_screens() and not _tree.paused, "Esc closes the window and resumes the game")
