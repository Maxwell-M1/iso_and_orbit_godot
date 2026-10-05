# Settings

[← Documentation index](index.md)

F10 opens the settings window and pauses the game; Esc or F10 closes it. Changes apply at once (only the interface
scale, dragged with the mouse, waits for the release) and are saved to `user://settings.cfg` when the window closes
and when the game exits. **Reset all** returns every setting to its default.

The defaults are in `DEFAULTS` in `gdscript/settings/game_settings.gd`. The demo applies them to node properties in
`gdscript/demo/settings_applier.gd`; the components' own property defaults can differ, as noted below. How the
settings system works and how to add a setting: [UI](systems/ui.md#settings).

For a standalone copied hero, use [Configurations](configurations.md) to find the Inspector properties and choose
a coherent setup. This page describes the **demo menu**. Labels below use the original bindings; the running menu
substitutes the current keys from `InputMap`.

## Controls

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **Held LMB**: Straight to the cursor / To the point along a path | `gameplay/hold_mode` | Straight to the cursor | `PointClickMoveInput.hold_mode` |
| **RMB + WASD**: Off / Sidestep / Turn | `gameplay/camera_keys_mode` | Turn | `PointClickMoveInput.keys_with_camera` (component default: sidestep); Off also hides the hint line about RMB + WASD |
| **LMB + RMB + A/D**: Off / Sidestep / Diagonal | `gameplay/camera_steer_keys_mode` | Diagonal | `PointClickMoveInput.keys_with_camera_steer` (component default: sidestep); Off also hides the hint line about LMB + RMB + A/D |
| **Backing up (S) slower by** 0…80%, only with sidestep | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − value / 100 |
| **Hide the cursor while running with LMB held** | `gameplay/hide_cursor_on_hold` | on | `PointClickMoveInput.hide_cursor_while_held` |
| **RMB while running with LMB only turns the camera** | `gameplay/look_around` | on | `PointClickMoveInput.look_around_while_held`; also hides the hint line about looking around |

## Character

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **Hero look**: one of ten | `character/look` | 8 · Necromancer | `CharacterAppearance.set_look()` |
| **Float above the ground** | `character/hover` | off | `CharacterHover.enabled` on `Hero/Character/Visual/Hover` (component default: on; `player.tscn` turns it off); while the hero floats, the hover turns its steps off and slows its fall (`player_floating_fall.tres`) |
| **Don't fall off ledges** | `gameplay/ledge_guard` | on | `LedgeGuard.enabled` |
| **Jump (Space)** | `character/jump` | on | `GroundCharacter.can_jump`; also hides the hint line about the jump |
| **Jump height** 0.5…1.5 m | `character/jump_height` | 1.0 m | `GroundCharacter.jump_height` |
| **Sprint (Shift)** | `character/sprint` | on | `GroundCharacter.can_sprint`; also hides the hint line about sprint |
| **Shift**: Hold / Press: on, again: off | `character/sprint_mode` | Hold | `CharacterActionInput.sprint_mode` |
| **Speed bonus** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + value / 100 |
| **Sprint fatigue** | `character/fatigue` | on | `GroundCharacter.sprint_tires` |
| **Stamina lasts** 3…10 s | `character/sprint_duration` | 5.0 s | `GroundCharacter.sprint_duration` |

The ledge guard uses the saved key `gameplay/ledge_guard` even though its control is on the Character tab.

## Camera

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **RMB tilts the camera up and down** | `camera/mouse_pitch` | off | `OrbitCameraRig.mouse_pitch` |
| **Turn the camera to follow the run** | `camera/follow` | off | `OrbitCameraRig.follow_movement` |
| **Turn in** 0…10 s ("instant" at 0) | `camera/follow_time` | 1.1 s | `OrbitCameraRig.follow_time` (component default: 1.5 s) |
| **Except a run toward the camera** | `camera/follow_except_toward` | on | `OrbitCameraRig.follow_toward_camera_angle`: off sets it to 0, and the camera turns behind any run, also one straight at it |
| **Angle** 5…60° | `camera/follow_except_toward_angle` | 30° | `OrbitCameraRig.follow_toward_camera_angle` = value while the exception is on (the component default is 30° too) |
| **Align the camera tilt on the run** | `camera/align_pitch` | off | `OrbitCameraRig.follow_pitch` |
| **Tilt down** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −value (component default: −40°) |
| **Align the tilt in** 0…10 s ("instant" at 0) | `camera/align_pitch_time` | 1.1 s | `OrbitCameraRig.follow_pitch_time` (component default: 1.5 s) |
| **Align the camera height on the run** | `camera/align_height` | off | `OrbitCameraRig.follow_zoom` |
| **Height** 0…100% | `camera/align_height_level` | 55% | `OrbitCameraRig.follow_zoom_level` = value / 100: 0% is the camera lowered all the way, 100% raised all the way |
| **Align the height in** 0…10 s ("instant" at 0) | `camera/align_height_time` | 1.5 s | `OrbitCameraRig.follow_zoom_time` |
| **The cursor keeps its aim while the camera turns** | `camera/keep_aim` | on | `PointClickMoveInput.keep_aim_on_camera_turn` |
| **The camera stops at obstacles behind it** | `camera/keep_out_of_geometry` | on | `CameraArm.keep_out_of_geometry` |
| **Move in when the character is hidden** | `camera/pull_in_on_occlusion` | off | `CameraArm.pull_in_on_occlusion` |

## Display

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **Fullscreen** | `display/fullscreen` | off | `DisplayServer.window_set_mode()` |
| **FPS limit**: 24, 30, 60, 120, 240, Unlimited | `display/max_fps` | Unlimited | `Engine.max_fps` |
| **Vertical sync (V-Sync)** | `display/vsync` | off | `DisplayServer.window_set_vsync_mode()` |
| **Physics interpolation (character and camera)** | `display/physics_interpolation` | on | `SceneTree.physics_interpolation` |
| **Silhouette outline behind obstacles** | `display/silhouette_outline` | on | `OccludedSilhouette.outline_enabled` |

Full screen does not work while the game runs inside the editor, in the Game tab or in its floating window (**Make Game
Workspace Floating on Next Play**): the window belongs to the editor, so the switch is disabled there. To try it from
the editor, turn off **Embed Game on Next Play** in the Game tab's menu: the game then opens in its own window.

With V-Sync there are never more frames than the monitor's refresh rate, so an FPS limit at or above that rate is not
set at all: it would fight V-Sync and give fewer frames than the monitor shows (a 240 limit on a 240 Hz monitor gave
about 220).

Without physics interpolation the character and the camera move in steps, tick by tick (60 per second): the camera
follows the target's `get_global_transform_interpolated()`, which without interpolation is simply its position at the
last tick. On a monitor faster than 60 Hz this shows, and with the camera following the run the character also wobbles
on turns: the camera turns every frame, the character only every tick.

## Interface

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **Language**: English, Español, 日本語, Português (Brasil), Русский, Türkçe, 简体中文 | `interface/language` | English | `TranslationServer.set_locale()` |
| **Interface scale** 50…100% | `interface/ui_scale` | 75% | Root window `content_scale_factor` |
| **FPS counter** | `interface/fps_counter` | on | `Hud/FpsCounter` visibility |
| **Controls hint and speed** | `interface/help` | on | `Hud/Panel` visibility |
| **Character path line** | `interface/path_line` | off | `Hero/PathView` visibility |
| **Character state and events** | `interface/character_state` | off | `Hud/CharacterState` visibility (`CharacterMonitor`) |

The interface scale changes the hint, the FPS counter, the stamina bar, the character state panel, the "Discovered: …"
message, the offer to travel, the loading screen and the windows, not the 3D view. 100% is the size as authored in the
scenes. Dragged with the mouse, the slider applies the scale on release, so that the slider does not move away from
under the cursor; the keyboard and the wheel apply it at once.

## Sound

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **Volume** 0…100% ("off" at 0) | `sound/volume` | 100% | `Master` bus volume; 0 mutes it |
| **Footsteps** | `sound/footsteps` | on | `CharacterSounds.footsteps_enabled` |
| **Jump and landing** | `sound/jump` | on | `CharacterSounds.jump_enabled` |
| **Sprint start and sprinting** | `sound/sprint` | off | `CharacterSounds.sprint_enabled` (component default: on) |

## Dependent settings

Controls that make no sense without another setting are dimmed and cannot be changed: the backward slowdown without
the sidestep mode for RMB + WASD, the jump height without the jump, everything about sprint without sprint, the
stamina duration without fatigue, the turn's time without the turn, the tilt angle and its time without tilt
alignment, the height and its time without height alignment, and the footsteps sound while the hero floats (it has no
steps then).

---

*This page matches Iso & Orbit 1.2.0.*
