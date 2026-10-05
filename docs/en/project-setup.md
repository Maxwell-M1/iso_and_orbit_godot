# Project setup

[← Documentation index](index.md)

What the components expect from `project.godot` and the scene. When you move components to another project, copy
the parts of this setup that they use.

For the assembled hero, follow [the transfer steps](integration.md#taking-the-demos-hero-into-your-project) first.
It needs the movement/camera/sprint/jump actions, matching navigation settings and collision layers. The demo's
autoload, UI theme, translations, display settings and level system are optional.

## Physics layers

| Layer | Name | What is on it | Who reads it |
|---|---|---|---|
| 1 | `world` | Ground, walls, props, the mountain, the NPCs standing in the level | Click raycast (`PointClickMoveInput.ground_mask`), the player's body and its `LedgeGuard` (whose `floor_mask` 0 takes the body's mask), `CameraArm.collision_mask`, navigation mesh baking |
| 2 | `characters` | The player's body (`collision_layer = 2`) | `PointOfInterest` and `LevelPortal` areas (`collision_mask = 2`); the camera arm ignores it |
| 3 | `camera` | Bodies that only stop the camera, such as `RoofCameraBlocker` in `shared/world/props/house.tscn` | `CameraArm.collision_mask` only |
| 4 | `bounds` | Invisible walls at the edge of a level, such as the island's `Edge` | The player's body (`collision_mask` = layers 1 and 4) and its `LedgeGuard`, navigation mesh baking where the mesh asks for it (the island's) |

`CameraArm.collision_mask` defaults to layers 1 and 3 (`0b101`). Characters on layer 2 never push the camera. A
body on layer 3 stops the camera but is invisible to clicks, navigation and characters, so you can keep the camera
out of a roof without letting anyone path onto it. A body on layer 4 is the other way round: it stops characters, but
clicks and the camera pass through it, so a click on the ground or water behind an invisible wall does not land on
the wall.

Navigation layer 1 is named `ground`; `NavigationMover.navigation_layers` defaults to it.
Physics layers and navigation layers are separate: a collider's physics layer decides what rays and bodies hit;
the region's navigation layers decide which paths the mover can query. In code, masks are bit fields: layers 1 and
4 are `1 | 8 = 9`, while layers 1 and 3 are `1 | 4 = 5`. In the Inspector, tick the numbered boxes.

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
| `interact` | E | `TravelPrompt.action`: confirms the offer to travel on a pad (demo) |
| `ui_cancel` | Esc (built in) | `UiRoot`: closes the top window |

Add these actions under **Project → Project Settings → Input Map**, using physical key events for the letters.
The standalone hero needs the first seven rows (ten actions); `toggle_settings`, `interact` and `ui_cancel` belong
to the optional UI and travel setup. You can also merge the required entries from this project's `[input]` section
into your own `project.godot`; do not replace your whole project file.

The keys are bound by physical position, so WASD stays in place on any keyboard layout. Each component takes the
action name as an exported property, so you can use your own actions instead. A missing action is reported once at the
start by the component that uses it (the window root and the demo's travel offer too) and is not read afterwards: its
keys or buttons do nothing, with no more errors, and the movement keys that exist still walk.

The HUD, settings and loading tips derive key names from those actions. After changing `InputMap` during play, call
`get_tree().call_group(ActionTexts.GROUP, &"refresh")` if you use these text components. The demo has no key-rebinding
menu or saved key bindings; see [key names in texts](systems/ui.md#key-names-in-texts).

## Groups

| Group | Meaning |
|---|---|
| `player` | The player's body. `PointOfInterest` (`player_group`) and `LevelPortal` (`traveller_group`) react only to bodies in this group. Set on `Character` in `playable_hero.tscn` |
| `camera_ignore` | Bodies the camera arm passes through (`CameraArm.ignored_groups`). Applies to everything under a node in the group, so set it once on a prop scene's root or on a level folder node. The demo does not use it |
| `points_of_interest` | Added by each `PointOfInterest` itself; `DiscoveryToast` and the demo's shell find the places through it |
| `level_portals`, `spawn_points` | Added by each `LevelPortal` and `SpawnPoint` itself; `LevelHost` finds those of its level through them |

## Autoload

`Settings` → `res://gdscript/settings/game_settings.gd`. Needed only by the settings window, its controls and
`gdscript/demo/settings_applier.gd`. Components work without it. See [Settings](settings.md).

## Other project settings

| Setting | Value | Notes |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | The demo |
| `physics/3d/physics_engine` | Jolt Physics | Built into the engine; the camera arm and the tests are checked with it |
| `navigation/3d/default_cell_height` | 0.025 | Match the mesh's `cell_height`. The demo uses fine vertical cells for stairs; a new mesh/map pair must agree too. See [World and navigation](systems/world-and-navigation.md) |
| `display/window/stretch/mode` | `canvas_items` | The interface scale setting scales all 2D through `content_scale_factor` and leaves the 3D view alone |
| `display/window/stretch/aspect` | `expand` | Any window shape |
| `gui/theme/custom` | `res://shared/ui/ui_theme.tres` | Look of all windows and HUD elements |
| `internationalization/locale/translations` | `res://l10n/ui/*.po` | Interface translations; see [UI](systems/ui.md) |
| `rendering/rendering_device/driver.windows` | `d3d12` | Direct3D 12 on Windows |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 5 (Ultra) | Soft shadows; the sun in `world.tscn` also has `shadow_blur = 1.25` and a 70 m shadow distance |
| `rendering/anti_aliasing/quality/msaa_3d` | 2 (4×) | Multisample anti-aliasing |

Physics runs at the default 60 ticks per second. Physics interpolation is on in `project.godot`
(`physics/common/physics_interpolation`) and switched at runtime by a setting (Settings → Display).

## Saved data

Settings are saved to `user://settings.cfg`, in the project's user data folder (in the editor: Project → Open User
Data Folder). Delete the file to return to the defaults, or use **Reset all** in the settings window.

---

*This page matches Iso & Orbit 1.2.0.*
