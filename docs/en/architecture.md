# Architecture

[← Documentation index](index.md)

The demo starts in one scene, `gdscript/main.tscn`: the game shell that holds the current level, the hero and the
interface. Every behavior is a separate node with one job: a component reads its own exported properties, exposes
methods and signals, and is wired to its neighbors in the scene through node references and signal connections. The
few lookups that remain are configurable: `DiscoveryToast` and the demo's shell find places by group, `LevelHost`
finds the portals and spawn points of its level by group, `PointOfInterest` and `LevelPortal` know the player's body
by the group `player` (`player_group`, `traveller_group`), `CharacterAppearance` finds the model and its hand by
exported names, and `CharacterSounds` with an empty `character` property takes its parent.

## The main scene

```
Main (Node3D, main.gd)   the game shell: connects the levels, the hero and the interface
├── Levels             LevelHost: the current level, changed behind the loading screen
│   └── World          shared/world/world.tscn: the start level, its navigation mesh, places, NPCs and the pad
├── Hero               gdscript/player/playable_hero.tscn: PlayableHero, the hero the player controls
│   ├── Character          gdscript/player/player.tscn: GroundCharacter, group "player"
│   │   ├── CollisionShape3D   capsule, radius 0.35 m, height 1.8 m
│   │   ├── Visual             turned to face the way the character goes
│   │   │   └── Hover          CharacterHover: floats the model, off by default
│   │   │       └── Model      the current hero look; its RightHand holds the staff
│   │   ├── Silhouette         OccludedSilhouette: the hero seen through obstacles
│   │   ├── Appearance         CharacterAppearance: swaps Visual/Hover/Model at runtime
│   │   ├── RightHandSway      HandSway: swings the right hand with the steps
│   │   ├── NavigationMover    paths and velocity
│   │   ├── LedgeGuard         keeps the body from walking off a drop
│   │   ├── Stamina            sprint reserve
│   │   └── Sounds             CharacterSounds and five AudioStreamPlayer3D
│   ├── PlayerInput        PointClickMoveInput: mouse and WASD → Character/NavigationMover
│   ├── PlayerActionInput  CharacterActionInput: Shift and Space → Character
│   ├── CameraRig          OrbitCameraRig: follows Character, orbit and zoom
│   │   └── CameraArm      CameraArm: shortens at obstacles
│   │       └── Camera3D
│   ├── ClickMarker        the ring on the ground at a clicked point
│   └── PathView           NavigationPathView: the debug path line, hidden by default
├── Hud                controls hint and speed, FpsCounter, CharacterState, DiscoveryToast, StaminaBar,
│                      TravelPrompt (the offer to travel on a pad)
├── SettingsApplier    settings → node properties (demo only)
├── UiRoot             windows over the game: the settings window
└── LoadingScreen      LoadingScreen: the screen while a level loads
```

`player.tscn` holds only the character. The input nodes live in `playable_hero.tscn`, so the same character scene can
be driven by something else: AI, a cutscene or a network peer. The hero is a sibling of the level host, not a part of
a level: the levels change around it. How a level changes: [Levels](systems/levels.md).

## Data flow

```
mouse, WASD ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (path or            (acceleration, braking,
                                    ──stop()────────────►  direction)          turning: plain math)
                                                               ▲
                                                               │ compute_velocity(delta)
                                                               │ returns a horizontal velocity
Shift, Space ──► CharacterActionInput ──sprint_requested──► GroundCharacter ──► LedgeGuard.constrain()
                                      ──jump()────────────►  (CharacterBody3D)  ──► move_and_slide()
                                                                   │
     signals: state_changed, stepped, jumped, left_floor, touched_floor, landed, sprint_changed, stair_taken,
              teleported
                                                                   ▼
                    CharacterSounds, HandSway, CharacterHover, CharacterMonitor, animations, anything else

mouse ──► OrbitCameraRig ──► CameraArm ──► Camera3D
          (follows the target's interpolated position, orbit, zoom, optional follow)

LevelPortal ──traveller_entered──► LevelHost ──portal_entered──► main.gd ──► TravelPrompt
     ▲                                  │                                       │ E or a click
     └───────────── travel() ───────────┼─────────── main.gd ◄── confirmed ─────┘
                                        ▼
    change_level(): paused, LoadingScreen, threaded load, swap ──level_loaded──► main.gd ──► PlayableHero.place_at()
```

Input never touches the body. It sends commands to the `NavigationMover`. The mover never touches the body either:
it returns a velocity when the body asks for one. The camera and the input do not know about each other.

## One physics tick

1. `CharacterActionInput` runs before the character (`process_physics_priority = -1`): it sets
   `GroundCharacter.sprint_requested` and calls `jump()`, so a key press reaches the body in the same tick.
2. `GroundCharacter._physics_process`, the only place where the body moves:
   1. decides whether the character sprints (requested, allowed, moving, not exhausted) and spends stamina;
   2. calls `mover.compute_velocity(delta)` and takes its X and Z as the horizontal velocity;
   3. starts a jump if one is buffered and the body is on the floor or just left it (coyote time);
   4. applies gravity in the air: the rise of a jump slows down with `gravity_scale`, the way down follows the fall
      settings in effect (`get_fall_settings()`);
   5. lets `LedgeGuard.constrain()` turn the velocity along an edge, unless the character is jumping, and measures
      the acceleration of the velocity it is driven with (`get_local_acceleration()`);
   6. calls `move_and_slide()`, stepping onto a stair before it and down a stair after it (`max_step_height`);
   7. emits `left_floor`, `touched_floor`, `landed`, `stair_taken` and `stepped`, turns `Visual` toward
      `mover.get_facing()` and, if the state changed, emits `state_changed`.
3. `HandSway` and `CharacterHover` run after the body (`process_physics_priority = 1`): they move the hand and the
   model from the body's new state.

`PointClickMoveInput._physics_process` decides in one place who drives the character: a held mouse button, or else
the keys with the right button. It calls `move_to()`, `steer()` or `stop()`. The mover keeps the last command, and
the body picks it up the next time it calls `compute_velocity()`.

Every rendered frame, `OrbitCameraRig._process` places the rig at the target's interpolated transform and its
child `CameraArm` updates right after it. `PointClickMoveInput` has `process_priority = 1`, so it corrects the
cursor position after the camera has settled for the frame.

## Components

The reusable components are in `addons/iso_orbit/`, one folder per part that can be taken on its own. Each script is
named after its class in snake case: `OrbitCameraRig` is `addons/iso_orbit/orbit_camera/orbit_camera_rig.gd`.

| Addon | Class | Job |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig` (Node3D) | Follows a target, orbits with RMB, zooms with the wheel; optionally turns after the run and aligns its tilt and height, smoothly |
| | `CameraArm` (Node3D) | Holds the camera at its end and shortens at obstacles; fades the target up close |
| `click_to_move` | `LocomotionSettings` (Resource) | Speed, acceleration, braking and turning. One resource can be shared by many characters |
| | `GroundMotion` (RefCounted) | Kinematics without nodes: desired direction and distance left → horizontal velocity |
| | `NavigationMover` (Node) | `move_to()` along a navigation path with an exact stop, `steer()` in a direction, `stop()`; returns a velocity, never moves the body |
| | `PointClickMoveInput` (Node) | Mouse and RMB + WASD → mover commands; hides and re-aims the cursor |
| | `ClickMarker` (Node3D) | The marker at a clicked point (`click_marker.tscn`) |
| | `NavigationPathView` (MeshInstance3D) | Draws the mover's remaining path |
| `ground_character` | `GroundCharacter` (CharacterBody3D) | Gravity, jump, sprint with stamina, stairs, `move_and_slide()`, turning the model; reports its state, steps, take-offs and landings for animations, sounds and the interface |
| | `FallSettings` (Resource) | How the character falls: the fall's gravity, the speed limit, braking to it. One resource can be shared by many characters |
| | `LedgeGuard` (Node) | Stops the body at a drop or slides it along the edge |
| | `Stamina` (Node) | A reserve that is spent and recovers; knows nothing about what spends it |
| | `CharacterActionInput` (Node) | Sprint and jump keys → the character |
| | `CharacterSounds` (Node3D) | Plays sounds from the character's signals |
| | `HandSway` (Node) | Swings a hand node with the steps, with inertia on starts, stops, turns and landings |
| | `CharacterHover` (Node3D) | Floats the model above the ground: glides over stairs, sways, leans; turns the steps off and can slow the fall while floating |
| | `DampedSpring` (RefCounted) | A damped spring for one value, for inertia in `HandSway` and `CharacterHover` |
| | `CharacterMonitor` (Label) | Shows the character's state and latest events as text; can log the events to the output |
| | `CharacterAppearance` (Node) | Swaps the character model at runtime |
| | `StaminaBar` (ProgressBar) | The stamina bar of the HUD (`stamina_bar.tscn`) |
| `occluded_silhouette` | `OccludedSilhouette` (Node) | Draws the character as a silhouette where something hides it; its shaders and materials are in the same folder |
| `points_of_interest` | `PointOfInterest` (Area3D) | A place to discover: emits `discovered(title)` the first time the player enters |
| | `DiscoveryToast` (Label) | "Discovered: …" on screen for a few seconds (`discovery_toast.tscn`) |
| `ui_screens` | `UiRoot` (CanvasLayer) | A stack of windows: open, close the top one with Esc, pause, cursor, keyboard focus |
| | `UiScreen` (Control) | Base of a window: `initial_focus`, `close_requested` |
| | `FpsCounter` (Label) | Frames per second, also while paused (`fps_counter.tscn`) |
| | `InputNames` (RefCounted) | The names of the keys bound to input actions, for texts: `{sprint}` → "Shift" |
| | `ActionTexts` (Node) | Puts those names into the texts of the controls under it, also after a language change |
| `levels` | `LevelHost` (Node3D) | Holds the current level and changes it behind the loading screen: a background load, the swap, the navigation map, a warm-up; reports each step with a signal |
| | `LevelPortal` (Area3D) | A way to another level: reports a traveller, travels on `travel()` or by itself |
| | `SpawnPoint` (Marker3D) | Where a character appears on a level, by name |
| | `LoadingScreen` (CanvasLayer) | The last frame blurred, the name of the place, a progress bar and tips (`loading_screen.tscn`) |

`ground_character` needs `click_to_move` (the body drives a `NavigationMover`); the other addons need nothing but
the engine. What each one expects from the project: [Using it in your project](integration.md).

The demo in `gdscript/` assembles them:

| File | Job |
|---|---|
| `main.tscn`, `main.gd` | The game shell: the level host with the start level, the hero, the interface, the loading screen; `main.gd` connects them |
| `player/player.tscn`, `player_locomotion.tres` | The hero's character: a `GroundCharacter` with all its parts, and its running settings |
| `player/playable_hero.tscn`, `.gd` | `PlayableHero`: the character with its input, camera, click marker and path line, ready to put into a game scene |
| `ui/travel_prompt.tscn`, `.gd` | `TravelPrompt`: the offer to travel on a pad, with the key and the name of the place |
| `demo/hud.gd` | The controls hint and the speed readout |
| `demo/settings_applier.gd` | Applies settings to the demo's nodes, one place for "setting → property" |
| `settings/game_settings.gd` | `GameSettings`, the `Settings` autoload: defaults, `user://settings.cfg`, the `changed` signal; applies engine settings itself |
| `ui/ui_root.tscn` | `UiRoot` with the settings window and F10 |
| `ui/settings/settings_screen.tscn`, `.gd` | The settings window |
| `ui/settings/setting_*.gd` | `SettingCheckButton`, `SettingOptionButton`, `SettingSlider`, `SettingLanguageButton`: controls bound to a setting key |

Each system has its own page: [Locomotion](systems/locomotion.md), [Camera](systems/camera.md),
[Input](systems/input.md), [Characters](systems/characters.md), [Audio](systems/audio.md), [UI](systems/ui.md),
[World and navigation](systems/world-and-navigation.md), [Levels](systems/levels.md).

## Connections made in the scene

Node references are exported properties set in `main.tscn`, `playable_hero.tscn` and `player.tscn`. The signal
connections in `playable_hero.tscn`:

| Signal | Connected to | Effect |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | The marker appears at the clicked point |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | A hold replaces the click, the marker fades |
| `Character/NavigationMover.arrived` | `ClickMarker.fade_out` | The character reached the point |
| `Character/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | The point was abandoned |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | The camera does not turn by itself until a press is known to be a click or a hold |
| `PlayerInput.run_requested` | `CameraRig.end_follow_wait` | A new run: the camera, waiting since an orbit, follows again |

`main.gd` connects the level host and the offer to travel in code, see [Levels](systems/levels.md#the-shell).

## Settings

The `Settings` autoload (`GameSettings`) stores values and emits `changed(key, value)`. It applies the engine-level
settings itself: full screen, frame rate cap, V-Sync, physics interpolation, interface scale, language and volume.
Everything else is applied by `gdscript/demo/settings_applier.gd`, which maps each key to a node property. The
components themselves never read settings, see [Settings](settings.md).

## Why it is built this way

- **Only `GroundCharacter` moves the body.** Movement components return a velocity and never call
  `move_and_slide()`. Gravity, jumps and any future knockback are combined in one place and cannot fight each
  other.
- **`GroundMotion` is math without nodes.** Acceleration and braking are a pure function of the state: easy to test
  in isolation and to port to another language line by line.
- **The character knows nothing about the mouse.** It becomes the player's character because `PlayerInput` in the
  playable hero scene (`playable_hero.tscn`) drives its mover. For an NPC, instance `player.tscn` without the
  player-only `Silhouette` and `Appearance` nodes and call `NavigationMover.move_to()` from your AI.
- **The hero is a sibling of the level host, not a part of a level.** A level is a scene of the world only: its
  ground, props, navigation, light and portals. The hero, the camera and the interface stay while the levels change,
  so a new level needs no copy of them, and nothing carried by the hero (stamina, the camera's height) is lost.
- **The level host knows nothing about the hero.** It reports each step of a change with a signal, and the shell puts
  the hero where the new level says. The playable hero works without the level host too.
- **The camera is a sibling of the character, not its child.** It moves in `_process` to the target's interpolated
  position and is not interpolated itself, so with physics interpolation (on by default, Settings → Display) running is
  smooth at any frame rate. For follow mode the camera computes the target's speed from its movement per physics tick,
  so any `Node3D` works as a target; from the same movement it tells a sharp turn from a curve, so a turnaround does
  not swing it. Its springs are computed in short steps and move alike at any frame rate.
- **Components know nothing about the settings.** `LedgeGuard`, `PointClickMoveInput`, `OrbitCameraRig` and the
  others read their own properties; only `settings_applier.gd` and the settings window talk to the `Settings`
  autoload. A component moves to another project without the settings system.
- **Windows follow Godot's conventions.** Layout uses containers only; the look comes from the project theme and
  its type variations, not from overrides on each node. A window asks to be closed with a signal and `UiRoot` closes
  it (calls go down the tree, signals go up). Keys are input actions. Keyboard focus is set when a window opens and
  restored when it closes. While a window is open the game is paused (`UiRoot` runs in `PROCESS_MODE_ALWAYS`) and
  the camera releases a captured cursor.

## Folders

| Folder | Contents |
|---|---|
| `addons/iso_orbit/` | The reusable components, one folder per part |
| `gdscript/` | The demo in GDScript: the main scene, the hero, the settings system and window, the HUD hint |
| `shared/` | Demo content that does not depend on the scripting language: the levels, characters and equipment, world shaders and textures, sounds, the UI theme |
| `l10n/` | Interface translations |
| `tests/` | Headless tests, see [Tests](testing.md) |
| `docs/` | This documentation |

`shared/` is meant to be reused by a future C# version of the demo, which would get its own folder next to `gdscript/`.
Two exceptions remain for now: the levels and the pad use scripts of the components (`world.tscn`, `island.tscn` and
`mountain.tscn` use `point_of_interest.gd`, the levels `spawn_point.gd`, `teleport_pad.tscn` `level_portal.gd`), and
two small prop scripts (`flicker.gd`, `hover_spin.gd`) live in `shared/world/props/`. See
[Known issues](known-issues.md).

---

*This page matches Iso & Orbit 1.2.0.*
