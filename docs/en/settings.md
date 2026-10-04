# Settings

F10 opens the settings window and pauses the game; Esc or F10 closes it. Changes apply at once and are saved to
`user://settings.cfg` when the window closes and when the game exits. **Reset all** returns every setting to its
default.

The defaults are in `DEFAULTS` in `gdscript/settings/game_settings.gd`. The demo applies them to node properties in
`gdscript/demo/settings_applier.gd`; the components' own property defaults can differ, as noted below. How the
settings system works and how to add a setting: [UI](systems/ui.md#settings).

## Controls

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **Held LMB**: Straight to the cursor / To the point along a path | `gameplay/hold_mode` | Straight to the cursor | `PointClickMoveInput.hold_mode` |
| **RMB + WASD**: Off / Sidestep / Turn | `gameplay/camera_keys_mode` | Turn | `PointClickMoveInput.keys_with_camera` (component default: sidestep) |
| **LMB + RMB + A/D**: Off / Sidestep / Diagonal | `gameplay/camera_steer_keys_mode` | Diagonal | `PointClickMoveInput.keys_with_camera_steer` (component default: sidestep) |
| **Backing up (S) slower by** 0…80%, only with sidestep | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − value |
| **Hide the cursor while running with LMB held** | `gameplay/hide_cursor_on_hold` | on | `PointClickMoveInput.hide_cursor_while_held` |

## Character

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **Hero look**: one of ten | `character/look` | 10 · Battle Mage | `CharacterAppearance.set_look()` |
| **Don't fall off ledges** | `gameplay/ledge_guard` | on | `LedgeGuard.enabled` |
| **Jump (Space)** | `character/jump` | on | `GroundCharacter.can_jump` |
| **Jump height** 0.5…1.5 m | `character/jump_height` | 1.0 m | `GroundCharacter.jump_height` |
| **Sprint (Shift)** | `character/sprint` | on | `GroundCharacter.can_sprint` |
| **Shift**: Hold / Press: on, again: off | `character/sprint_mode` | Hold | `CharacterActionInput.sprint_mode` |
| **Speed bonus** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + value |
| **Sprint fatigue** | `character/fatigue` | on | `GroundCharacter.sprint_tires` |
| **Stamina lasts** 3…10 s | `character/sprint_duration` | 5.0 s | `GroundCharacter.sprint_duration` |

The ledge guard key stayed `gameplay/ledge_guard` after the switch moved to the Character tab, so a saved choice is
not lost.

## Camera

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **RMB tilts the camera up and down** | `camera/mouse_pitch` | off | `OrbitCameraRig.mouse_pitch` |
| **Turn the camera to follow the run** | `camera/follow` | off | `OrbitCameraRig.follow_movement` |
| **Align the camera tilt** | `camera/align_pitch` | off | `OrbitCameraRig.follow_pitch` |
| **Tilt down** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −value (component default: −40°) |
| **Catch up in** 0…10 s ("instant" at 0), for the turn and the tilt | `camera/follow_time` | 1.1 s | `OrbitCameraRig.follow_time` (component default: 1.5 s) |
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

Full screen does not work while the game runs inside the editor's Game tab, where the window belongs to the editor. To
try it from the editor, turn off **Embed Game on Next Play** in the Game tab's menu.

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
| **Character path line** | `interface/path_line` | off | `PathView` visibility |

The interface scale changes the hint, the FPS counter, the stamina bar and the windows, not the 3D view. 100% is the
size as authored in the scenes.

## Sound

| Setting | Key | Default | Applied to |
|---|---|---|---|
| **Volume** 0…100% ("off" at 0) | `sound/volume` | 100% | `Master` bus volume; 0 mutes it |
| **Footsteps** | `sound/footsteps` | on | `CharacterSounds.footsteps_enabled` |
| **Jump and landing** | `sound/jump` | on | `CharacterSounds.jump_enabled` |
| **Sprint start and sprinting** | `sound/sprint` | off | `CharacterSounds.sprint_enabled` |

## Dependent settings

Controls that make no sense without another setting are dimmed and cannot be changed: the backward slowdown without
the sidestep mode for RMB + WASD, the jump height without the jump, everything about sprint without sprint, the
stamina duration without fatigue, the tilt angle without tilt alignment, and the catch-up time without either follow
or tilt alignment.

---

*This page matches Iso & Orbit 1.0.0.*
