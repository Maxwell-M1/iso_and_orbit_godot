# Using it in your project

[← Documentation index](index.md)

Start with the ready-made hero if you want the demo's movement and camera in another project. Use the individual
components if you already have a character controller or need only the camera. The scripts are plain GDScript
classes (`class_name`); there is no editor plugin to enable and no required `Settings` autoload.

| What you want | Start here |
|---|---|
| The working hero, input and camera | [Transfer the demo's hero](#taking-the-demos-hero-into-your-project), then [choose a configuration](configurations.md) |
| A camera for an existing character | [The camera alone](#the-camera-alone) |
| The project's movement with your own model | [The ready-made body](#click-to-move-with-the-ready-made-body), then [model replacement](systems/characters.md) |
| Path movement for your own controller or AI | [Your own body](#your-own-body) and [commanding the mover](#commanding-the-mover) |

The file paths below are relative to the root of the project, where `project.godot` lives. A `res://` path means the
same location inside Godot. Keep the supplied folder layout during the first working integration.

## The addons

| Addon | Classes | Needs |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | Input actions `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`; physics layers for the arm |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | A baked `NavigationRegion3D` in the world (without one the character runs straight at the point). For the input: any `Camera3D` and the actions `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` |
| `ground_character` | `GroundCharacter`, `FallSettings`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterHover`, `DampedSpring`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. For the keys: the actions `sprint` and `jump`. For the sounds: your own, or `shared/audio/character/`. For the hand swing and switchable models: models facing −Z with a hand node |
| `occluded_silhouette` | `OccludedSilhouette`, with its shaders and materials | Nothing: works on any model |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | The player's body in the group `player`, on a physics layer the areas see |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter`, `InputNames`, `ActionTexts` | The built-in `ui_cancel`; the action `toggle_settings` if `UiRoot` opens a window by a key. Key-name formatting reads your Input Map |
| `levels` | `LevelHost`, `LevelPortal`, `SpawnPoint`, `LoadingScreen` | Nothing but the engine. The traveller's body in the group `player`, on a physics layer the portals see |

Each addon folder has a `README.md` with its setup and a copy of the `LICENSE`. Take an addon whole: the classes inside
it reference each other by type, and a file you do not use does no harm. Keep the folders at
`res://addons/iso_orbit/<addon>/`: the scenes and materials in them refer to their files by those paths. To put an addon
elsewhere, move it in the editor's FileSystem dock, which updates the references.

The HUD widgets (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) take their look from theme type variations of the
same names in the demo's theme, `shared/ui/ui_theme.tres`; without them they use the default theme.

Not in the addons, because they are built around this demo: the settings system (`gdscript/settings/game_settings.gd`
and the settings window in `gdscript/ui/settings/`, see [Settings](#settings)), `gdscript/ui/ui_root.tscn` (a `UiRoot`
set up with that window), the playable hero (`gdscript/player/playable_hero.tscn`, built around the demo's character,
see [The playable hero](#the-playable-hero)), the offer to travel (`gdscript/ui/travel_prompt.tscn`), the game shell
`gdscript/main.gd`, and the demo glue `gdscript/demo/hud.gd` and `settings_applier.gd`.

## The camera alone

The camera works with any `Node3D` target and needs only `addons/iso_orbit/orbit_camera/`.

1. Add a `Node3D` with `orbit_camera_rig.gd` to the scene next to the target, not inside it.
2. Give it a child `Node3D` with `camera_arm.gd`, and give that a `Camera3D` child.
3. Set the rig's `target` to the moving body and its `arm` to the arm node. Set the camera's **Current** property.
   Set the arm's `fade_target` to the model root that should turn translucent up close, or leave it empty.
4. Add the input actions and, for the arm, the physics layers from [Project setup](project-setup.md).

Keep the rig, arm, camera and their ancestors at scale `(1, 1, 1)`, and leave the camera's local transform at its
default: the arm sets it at runtime. Use framing properties, not node scale, to change the view.

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

`gdscript/player/player.tscn` is this setup, plus sounds, the hand swing, floating (`Visual/Hover`, off, with a slower
fall), the switchable model and the silhouette. You can instance it and remove what you do not need. Mistakes in the
setup of `GroundCharacter`, `LedgeGuard` and `CharacterHover` are printed as warnings when the game starts.

## The playable hero

`gdscript/player/playable_hero.tscn` is the hero the player controls, assembled: `player.tscn` as `Character` (in the
group `player`), `PointClickMoveInput`, `CharacterActionInput`, the camera rig with its arm and camera, the click marker
and the path line, with their settings and connections. Put it into your game scene once, next to your levels and not
into one of them. Its script, `playable_hero.gd`, uses only the addons' classes:

- `place_at(marker)` and `teleport(position, facing)` put the hero elsewhere at once: the press under way is forgotten,
  the character arrives without a jerk (`GroundCharacter.teleport()`), the camera looks the way the hero faces and
  snaps into place. With `turn_camera` false the camera keeps its angle, as at the start of the demo.
- `controls_enabled = false` disables movement input, sprint and jump. The camera remains controllable and a run to
  an existing click destination continues. Also call `character.mover.stop()` to brake, or `halt()` to stop
  horizontal motion immediately. Pausing the tree is a separate operation.
- The parts are typed properties: `character`, `input`, `actions`, `camera_rig`, `camera_arm`, `camera`,
  `click_marker`, `path_view`, and the character's `sounds`, `appearance`, `hover`, `silhouette`.

For your own model, make a copy of the scene with your character in place of `player.tscn`, or assemble the parts by
hand. The connections that matter for the camera are two: `PointClickMoveInput.hold_pending_changed` to
`OrbitCameraRig.set_follow_paused`, and `PointClickMoveInput.run_requested` to `OrbitCameraRig.end_follow_wait` (the
camera waits after an orbit until a new run). The other four show and hide the click marker; see
[Architecture](architecture.md#connections-made-in-the-scene). Keep the camera's `sharp_turn_speed` at half the
character's turn speed or lower: only `PlayableHero` checks it and warns.

## Taking the demo's hero into your project

Use Godot 4.7.2 with Jolt Physics and Forward+ for the same setup as the tested demo. Start with a small test level;
add your own models, levels and settings after the copied hero works there.

1. **Copy the files, at the same paths.** Into your project, keeping the folders as they are:
   - `addons/iso_orbit/click_to_move/`, `ground_character/`, `orbit_camera/` and `occluded_silhouette/`;
   - `gdscript/player/`: the hero, the character, the hero's script and the character's settings resources;
   - `shared/characters/`: the ten models, their staffs and books, their materials;
   - `shared/audio/character/`: the footsteps, the jump, the landing and the sprint;
   - `shared/world/materials/wood.tres` and `dark_wood.tres`: the wooden parts of the Druid and the Battle Mage are
     made of them. They lie with the world's materials, so copying `shared/characters/` alone misses them.

   Take the `.uid` and `.import` files lying beside these files too: the scenes find their scripts and sounds by these
   ids and by path. Leave out `.godot/`: your editor imports the files itself. The scenes refer to their files by these
   paths, so to keep the files elsewhere, copy them first and then move them in the editor's FileSystem dock, which
   updates the references.
2. **Set up the project** (Project Settings), see [Project setup](project-setup.md):
   - the input actions `move_to_cursor`, `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`, `move_forward`,
     `move_back`, `move_left`, `move_right`, `sprint` and `jump`. Without one, the component that uses it says so
     once at the start, and that key or button does nothing;
   - `navigation/3d/default_cell_height` = 0.025 to match the navigation mesh in the next step. The map and every
     mesh assigned to it must use matching cell sizes;
   - physics interpolation on (`physics/common/physics_interpolation`): the camera follows the character's interpolated
     position. The hero is checked with Jolt Physics (`physics/3d/physics_engine`);
   - the physics layers: the hero's body is on layer 2 and collides with layers 1 and 4, a click looks for the ground
     on layer 1, the camera arm stops at layers 1 and 3. The names do not matter, the numbers do: put your ground and
     walls on layer 1, or change these masks in your copy of the scene.
3. **Build a test level** under a `NavigationRegion3D`. Use a `StaticBody3D` ground with a `BoxShape3D` and a
   visible `BoxMesh`, both 20 × 1 × 20 m, centered at `(0, -0.5, 0)` so the top is at Y = 0. Add a 2 × 2 × 2 m box
   obstacle centered at `(0, 1, -4)`, with matching mesh and collision on layer 1. It blocks the direct route from
   Spawn `(0, 0, 4)` to `(0, 0, -8)`. Add a light and, optionally, a 3 × 0.2 × 3 m step centered at `(5, 0.1, 0)`.
   A visible mesh alone does not provide collision.
4. **Create and bake the navigation mesh.** Select the region, assign a new `NavigationMesh`, and set:

   | Property | Test-level value | Reason |
   |---|---|---|
   | Parsed Geometry Type | Static Colliders | Bake the same geometry that blocks the body |
   | Geometry Collision Mask | layer 1 | Include the floor and obstacle, not the hero |
   | Agent Radius | 0.5 m | Clearance around the 0.35 m radius capsule |
   | Agent Height | 1.8 m | At least the capsule's full height; check your lowest ceiling |
   | `filter_walkable_low_height_spans` | `true` | Exclude floor spans with less clearance than Agent Height |
   | Agent Max Climb | 0.3 m | Matches `Character.max_step_height` |
   | Agent Max Slope | 40° | Below the body's 45° floor limit |
   | Cell Height / Cell Size | 0.025 m / 0.25 m | Fine vertical steps; match the navigation map's settings |

   Keep the floor and obstacle **under the region**, then click **Bake NavigationMesh** and save the scene. The
   demo's existing meshes use an agent height of 1.75 m and leave the low-height filter off. For a new level with
   ceilings, use the full collision height and enable the filter.
   Navigation does not replace physics collision. Without a usable path, this mover can fall back to moving
   straight toward the target; it cannot route around walls in that mode. More detail:
   [World and navigation](systems/world-and-navigation.md#physics-layers-and-navigation).
5. **Instance the hero as a sibling of the region**, named `Hero`. Add a `Marker3D` named `Spawn` at `(0, 0, 4)`.
   Keep the hero's root scale at `(1, 1, 1)` and its camera current. Your scene can be this small:

   ```text
   Game (Node3D)
   ├── NavigationRegion3D
   │   ├── Ground (StaticBody3D with collision and mesh)
   │   └── Obstacle (StaticBody3D with collision and mesh)
   ├── Hero (instance of playable_hero.tscn)
   ├── Spawn (Marker3D)
   └── DirectionalLight3D
   ```

   Attach this script to `Game` and run that scene:

   ```gdscript
   extends Node3D

   @onready var hero: PlayableHero = $Hero


   func _ready() -> void:
       hero.place_at($Spawn, false)
   ```

   `false` preserves the camera's initial 45° orbit; omit it to put the camera behind the marker's −Z direction.
   Place or teleport the **character through the hero API** after startup. The `Hero` root is a stationary container;
   it does not follow the moving body. Use `hero.character.global_position` for the player's current position.
6. **Check the result before customizing.** Click the ground near `(0, 0, -8)`, beyond the obstacle: the hero should
   go around it and stop. Zoom out if needed to see the destination. Hold LMB: it should steer directly and stop on
   release. Test RMB orbit, wheel zoom, RMB + WASD, Shift and Space.
   With the supplied movement resource, normal speed is 5.5 m/s, sprint is 8.25 m/s, jump height is 1 m and a 0.2 m
   step needs no jump. Check the debugger for missing actions, resources or setup warnings.

The copied scene has the demo's default behavior without the settings system: both key modes are `TURN`; camera
follow, pitch/height alignment and floating are off; sprint sounds are off. The Necromancer is the initial model.
Use [Configurations](configurations.md) for exact node paths, the different kinds of defaults and two useful variants.

### Troubleshooting the transfer

| Symptom | Check first |
|---|---|
| Missing global class or resource | Copy all four addon folders and the listed assets at their original paths; let the editor finish importing. Include both wood materials |
| Hero falls through the floor | The floor needs a collision shape on layer 1; a MeshInstance3D alone is visual |
| Clicks do nothing | Input Map action, active camera, `PlayerInput.camera` and the ray's `ground_mask`; an overlapping Control can consume mouse input |
| Hero walks into a wall instead of around it | Bake colliders under the region, check the region/mover navigation layers and inspect the resulting mesh |
| Path crosses a step the hero cannot climb | Match climb to `max_step_height`, use fine vertical cells and rebake; test the actual geometry |
| Scene edits disappear at startup | A copied `SettingsApplier` may overwrite them with saved settings; the standalone hero does not need it |
| Camera turns unexpectedly after changing movement | Compare the character's `turn_speed` and camera's `sharp_turn_speed`; see [Configurations](configurations.md#tuning-without-breaking-the-setup) |

Good to know:

- The addons and `playable_hero.gd` declare global class names (`GroundCharacter`, `NavigationMover`,
  `OrbitCameraRig`, `PlayableHero` and the others in [the table above](#the-addons)). A class of the same name already
  in your project clashes with them: rename one of the two.
- Changing how fast the character turns (`turn_speed` in its `LocomotionSettings`), keep `CameraRig.sharp_turn_speed`
  at half of it or lower: otherwise the camera may take a turnaround toward it for a run to the side and turn. When it
  is not below the turn speed, the hero warns at the start.
- Neither the `Settings` autoload nor the settings window is needed. The HUD is not part of the hero: the stamina bar
  and the place notice are added in the demo's `main.tscn`, see the note on their theme in [The addons](#the-addons).
- The models and the sounds are under the project's MIT license, like the code.

## Levels

Copy `addons/iso_orbit/levels/`. The main scene holds a `LevelHost` with the start level as its only child, the hero
next to it, and `loading_screen.tscn`. Your main script connects the host's signals: on `level_change_started` take the
controls away, on `level_loaded(level, spawn)` put the hero at `spawn`, on `level_change_finished` give the controls
back, on `level_change_failed` give them back too (the level stays, and `level_change_finished` does not come), and on
`portal_entered` and `portal_exited` show and hide your offer to travel. `gdscript/main.gd` does exactly
this. Each level needs a `SpawnPoint` named `default`; portals are `LevelPortal` areas with the path of the
target scene.

With your own level system, take only the playable hero and call `place_at()` where your levels are ready; with your
own character, call `GroundCharacter.teleport()` for the same effect. Details, the defaults and the combinations of
settings: [Levels](systems/levels.md).

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


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
```

This minimal body needs its own collision shape, a floor and a camera to view it; add a model under a `Visual` node.
To face the movement, point that node's −Z along `mover.get_facing()` in world space. `GroundCharacter` already handles
visual facing, including a rotated parent, if you do not need to keep your own body implementation.

`LedgeGuard` is optional and requires `addons/iso_orbit/ground_character/`: add it as a child of the body and apply
`velocity = ledge_guard.constrain(velocity, delta)` before `move_and_slide()`. To sprint, set
`mover.sprinting = true`: the speed limit rises by `LocomotionSettings.sprint_speed_multiplier`. Everything else in
`GroundCharacter` (jump, stamina, stairs, the state and its signals, the smooth model turn) is then up to you.

## Commanding the mover

Anything can drive a character: player input, AI, a cutscene or network code.

| Call | Effect |
|---|---|
| `move_to(point)` | Follow a navigation path toward a global point. An unreachable target can end at the nearest reachable path point; an empty path falls back to direct movement. A target within `retarget_tolerance` (0.1 m) of the current one does not rebuild the path |
| `steer(direction, facing = Vector3.ZERO)` | Run in a direction without a path until told otherwise; with `facing`, look that way while moving (sidestepping) |
| `stop()` | Brake smoothly where the character is |
| `halt()` | Stop instantly, for example after a teleport |
| `face(direction)` | Turn a standing character at once, for example at a spawn point |

To put the whole character elsewhere, call `GroundCharacter.teleport(position, facing)`: it halts the mover, turns the
character and its model, and moves the body without a jerk for what follows it.

Signals: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (the point was abandoned
for `steer()` or `stop()`). Queries: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Details: [Locomotion](systems/locomotion.md).

## An NPC

Instance `player.tscn` (or your own body scene with a mover) and remove the player-only `Silhouette` and
`Appearance` nodes. Do not add the input nodes: call `NavigationMover.move_to()` from your AI and listen to
`arrived`. To use one of the demo's character models, put it under `Visual/Hover` as `Model`. Turning the NPC in the
editor sets where it faces at the start; later, `GroundCharacter.teleport(position, facing)` or
`NavigationMover.face()` turns it. The NPCs standing in the demo level are static bodies, not characters; see
[World and navigation](systems/world-and-navigation.md).

## Settings

The components never read settings: each one reads its own exported properties. To expose them in your settings
menu, set the properties from your own code when a setting changes. `gdscript/demo/settings_applier.gd` is an
example: one `match` maps each settings key to a node property. To reuse the demo's settings system as well, copy
`gdscript/settings/game_settings.gd`, register it as the `Settings` autoload and replace its keys and `DEFAULTS` with
your own, and take the controls from `gdscript/ui/settings/`; see [UI](systems/ui.md#settings).

---

*This page matches Iso & Orbit 1.2.0.*
