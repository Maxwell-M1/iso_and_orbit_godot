# Using it in your project

The reusable components are in `addons/iso_orbit/`, one folder per part; the common folder keeps them apart from your
other addons. Copy the folders you need into `addons/iso_orbit/` of your project, wire the nodes in your scenes and set
up the project as described in [Project setup](project-setup.md). The scripts are plain GDScript classes (`class_name`):
there is no editor plugin to enable.

## The addons

| Addon | Classes | Needs |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | Input actions `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`; physics layers for the arm |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | A baked `NavigationRegion3D` in the world (without one the character runs straight at the point). For the input: any `Camera3D` and the actions `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` |
| `ground_character` | `GroundCharacter`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. For the keys: the actions `sprint` and `jump`. For the sounds: your own, or `shared/audio/character/`. For the hand swing and switchable models: models facing −Z with a hand node |
| `occluded_silhouette` | `OccludedSilhouette`, with its shaders and materials | Nothing: works on any model |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | The player's body in the group `player`, on a physics layer the areas see |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter` | The built-in `ui_cancel`; the action `toggle_settings` if `UiRoot` opens a window by a key |

Each addon folder has a `README.md` with its setup and a copy of the `LICENSE`. Take an addon whole: the classes inside
it reference each other by type, and a file you do not use does no harm. Keep the folders at
`res://addons/iso_orbit/<addon>/`: the scenes and materials in them refer to their files by those paths. To put an addon
elsewhere, move it in the editor's FileSystem dock, which updates the references.

The HUD widgets (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) take their look from theme type variations of the
same names in the demo's theme, `shared/ui/ui_theme.tres`; without them they use the default theme.

Not in the addons, because they are built around this demo: the settings system (`gdscript/settings/game_settings.gd`
and the settings window in `gdscript/ui/settings/`, see [Settings](#settings)), `gdscript/ui/ui_root.tscn` (a `UiRoot`
set up with that window), and the demo glue `gdscript/demo/hud.gd` and `settings_applier.gd`.

## The camera alone

The camera works with any `Node3D` target and needs only `addons/iso_orbit/orbit_camera/`.

1. Add a `Node3D` with `orbit_camera_rig.gd` to the scene next to the target, not inside it.
2. Give it a child `Node3D` with `camera_arm.gd`, and give that a `Camera3D` child.
3. Set the rig's `target`. Set the arm's `fade_target` to the node that should turn translucent when the camera is
   very close, or leave it empty.
4. Add the input actions and, for the arm, the physics layers from [Project setup](project-setup.md).

Without an arm, a `Camera3D` child of the rig works too: the camera then stays at the distance set by the zoom and
goes through walls. The rig updates in `_process` from the target's interpolated position, so turn physics
interpolation on in the project if the target moves in physics ticks. Details: [Camera](systems/camera.md).

## Click to move with the ready-made body

Copy `addons/iso_orbit/click_to_move/` and `addons/iso_orbit/ground_character/`.

1. Bake a navigation mesh for your level (`NavigationRegion3D` → **Bake NavigationMesh**). Its agent radius and max
   climb should match your character, see [World and navigation](systems/world-and-navigation.md).
2. Make a `CharacterBody3D` with `ground_character.gd`: a collision shape, a `Visual` node with the model (facing
   −Z), and these children: `NavigationMover` (a `Node` with `navigation_mover.gd`), optionally `LedgeGuard` and
   `Stamina`. Set the body's `mover`, `visual`, `ledge_guard` and `stamina`.
3. Give the mover a `LocomotionSettings` resource, or leave it empty for the defaults.
4. Add a `Node` with `point_click_move_input.gd` anywhere in the scene and set its `mover` and `camera`.
5. Optionally add `character_action_input.gd` with `character` set to the body, for sprint and jump.

`gdscript/player/player.tscn` is this setup, plus sounds, the hand swing, the switchable model and the silhouette.
You can instance it and remove what you do not need.

## Your own body

To keep your own character controller, take only `addons/iso_orbit/click_to_move/`. The contract is short:

- `NavigationMover` must be a direct child of the body (any `Node3D`). It reads the body's position and the
  navigation map of the body's world.
- The body calls `mover.compute_velocity(delta)` once per physics tick, before `move_and_slide()`, and applies the
  X and Z of the result. The mover never moves the body.
- The vertical velocity stays with the body: gravity, jumps, knockback.

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover
@onready var ledge_guard: LedgeGuard = $LedgeGuard


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity = ledge_guard.constrain(velocity, delta)
	move_and_slide()
	var facing := mover.get_facing()
	$Visual.rotation.y = atan2(-facing.x, -facing.z)
```

`LedgeGuard` is optional: a child of the body, from `addons/iso_orbit/ground_character/`. To sprint, set
`mover.sprinting = true`: the speed limit rises by `LocomotionSettings.sprint_speed_multiplier`. Everything else in
`GroundCharacter` (jump, stamina, step signals, the smooth model turn) is then up to you.

## Commanding the mover

Anything can drive a character: player input, AI, a cutscene or network code.

| Call | Effect |
|---|---|
| `move_to(point)` | Run to a point along a navigation path and stop exactly there. Can be called every tick; a point closer than `retarget_tolerance` (0.1 m) to the current one does not rebuild the path |
| `steer(direction, facing = Vector3.ZERO)` | Run in a direction without a path until told otherwise; with `facing`, look that way while moving (sidestepping) |
| `stop()` | Brake smoothly where the character is |
| `halt()` | Stop instantly, for example after a teleport |

Signals: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (the point was abandoned
for `steer()` or `stop()`). Queries: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Details: [Locomotion](systems/locomotion.md).

## An NPC

Instance `player.tscn` (or your own body scene with a mover) and remove the player-only `Silhouette` and
`Appearance` nodes. Do not add the input nodes: call `NavigationMover.move_to()` from your AI and listen to
`arrived`. To use one of the demo's character models, put it under `Visual` as `Model`. The NPCs standing in the
demo level are static bodies, not characters; see [World and navigation](systems/world-and-navigation.md).

## Settings

The components never read settings: each one reads its own exported properties. To expose them in your settings
menu, set the properties from your own code when a setting changes. `gdscript/demo/settings_applier.gd` is an
example: one `match` maps each settings key to a node property. To reuse the demo's settings system as well, copy
`gdscript/settings/game_settings.gd`, register it as the `Settings` autoload and replace its keys and `DEFAULTS` with
your own, and take the controls from `gdscript/ui/settings/`; see [UI](systems/ui.md#settings).

---

*This page matches Iso & Orbit 1.0.0.*
