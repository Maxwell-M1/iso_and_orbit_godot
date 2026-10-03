# Project setup

What the components expect from `project.godot` and the scene. When you move components to another project, copy
the parts of this setup that they use.

## Physics layers

| Layer | Name | What is on it | Who reads it |
|---|---|---|---|
| 1 | `world` | Ground, walls, props, the mountain, the NPCs standing in the level | Click raycast (`PointClickMoveInput.ground_mask`), `LedgeGuard.floor_mask`, `CameraArm.collision_mask`, navigation mesh baking |
| 2 | `characters` | The player's body (`collision_layer = 2`) | `PointOfInterest` areas (`collision_mask = 2`); the camera arm ignores it |
| 3 | `camera` | Bodies that only stop the camera, such as `RoofCameraBlocker` in `shared/world/props/house.tscn` | `CameraArm.collision_mask` only |

`CameraArm.collision_mask` defaults to layers 1 and 3 (`0b101`). Characters on layer 2 never push the camera. A
body on layer 3 stops the camera but is invisible to clicks, navigation and characters, so you can keep the camera
out of a roof without letting anyone path onto it.

Navigation layer 1 is named `ground`; `NavigationMover.navigation_layers` defaults to it.

## Input actions

| Action | Default | Used by |
|---|---|---|
| `move_to_cursor` | Left mouse button | `PointClickMoveInput.move_action` |
| `camera_rotate` | Right mouse button | `OrbitCameraRig.rotate_action`, `PointClickMoveInput.camera_steer_action` |
| `camera_zoom_in` | Wheel up | `OrbitCameraRig.zoom_in_action` |
| `camera_zoom_out` | Wheel down | `OrbitCameraRig.zoom_out_action` |
| `move_forward`, `move_back`, `move_left`, `move_right` | W, S, A, D | `PointClickMoveInput`, with the right button held |
| `sprint` | Shift | `CharacterActionInput.sprint_action` |
| `jump` | Space | `CharacterActionInput.jump_action` |
| `toggle_settings` | F10 | `UiRoot.settings_action` |
| `ui_cancel` | Esc (built in) | `UiRoot`: closes the top window |

The keys are bound by physical position, so WASD stays in place on any keyboard layout. Each component takes the
action name as an exported property, so you can use your own actions instead.

## Groups

| Group | Meaning |
|---|---|
| `player` | The player's body. `PointOfInterest` reacts only to bodies in this group (`player_group`). Set on `Player` in `main.tscn` |
| `camera_ignore` | Bodies the camera arm passes through (`CameraArm.ignored_groups`). Applies to everything under a node in the group, so set it once on a prop scene's root or on a level folder node. The demo does not use it |
| `points_of_interest` | Added by each `PointOfInterest` itself; `DiscoveryToast` finds the places through it |

## Autoload

`Settings` → `res://gdscript/settings/game_settings.gd`. Needed only by the settings window, its controls and
`gdscript/demo/settings_applier.gd`. Components work without it. See [Settings](settings.md).

## Other project settings

| Setting | Value | Notes |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | The demo |
| `physics/3d/physics_engine` | Jolt Physics | Built into the engine; the camera arm and the tests are checked with it |
| `navigation/3d/default_cell_height` | 0.025 | Must not exceed the navigation mesh's cell height, which is 0.025 m so that the mesh does not join ledges the body cannot climb; see [World and navigation](systems/world-and-navigation.md) |
| `display/window/stretch/mode` | `canvas_items` | The interface scale setting scales all 2D through `content_scale_factor` and leaves the 3D view alone |
| `display/window/stretch/aspect` | `expand` | Any window shape |
| `gui/theme/custom` | `res://shared/ui/ui_theme.tres` | Look of all windows and HUD elements |
| `internationalization/locale/translations` | `res://l10n/ui/*.po` | Interface translations; see [UI](systems/ui.md) |
| `rendering/rendering_device/driver.windows` | `d3d12` | Direct3D 12 on Windows |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 5 (Ultra) | Soft shadows; the sun in `world.tscn` also has `shadow_blur = 1.25` and a 70 m shadow distance |
| `rendering/anti_aliasing/quality/msaa_3d` | 2 (4×) | Multisample anti-aliasing |

Physics runs at the default 60 ticks per second. Physics interpolation is off in `project.godot` and switched at
runtime by a setting (Settings → Display).

## Saved data

Settings are saved to `user://settings.cfg`, in the project's user data folder (in the editor: Project → Open User
Data Folder). Delete the file to return to the defaults, or use **Reset all** in the settings window.

---

*This page matches Iso & Orbit 1.0.0.*
