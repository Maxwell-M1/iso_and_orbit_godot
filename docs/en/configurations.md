# Configuring the playable hero

[← Documentation index](index.md)

Start from `gdscript/player/playable_hero.tscn` after completing the [transfer guide](integration.md). The three setups
below retain the supplied character size, movement resource and camera collision settings. They change how you
control and view the hero, without introducing arbitrary speed or smoothing values.

| Setup | Use it for | Main tradeoff |
|---|---|---|
| [Default: manual orbit](#default-manual-orbit) | A stable view of an area, with both click movement and direct steering | The player chooses the camera direction |
| [Path-guided mouse movement](#path-guided-mouse-movement) | Moving around baked obstacles while holding the mouse | Paths can switch near ramps and overlapping heights |
| [Camera-follow exploration](#camera-follow-exploration) | Longer journeys where the camera should return behind the run | The view rotates as the route changes |

## Where to change a setting

There are three sources of values. Check which one you are editing:

| Source | When it applies | Example |
|---|---|---|
| Script defaults | A newly added component with no scene override | `PointClickMoveInput.keys_with_camera` starts as `SIDESTEP` |
| Saved scene or resource | An instance of the supplied scene | `playable_hero.tscn` selects `TURN`; its camera uses a 1.1 s follow time |
| Demo settings | `SettingsApplier` runs at startup and when a menu setting changes | `user://settings.cfg` can turn camera follow on even though the scene has it off |

In the demo, start with **Settings → Reset all** before comparing configurations. Menu changes are saved; changes to
the running scene's **Remote** inspector are temporary. For a standalone hero, edit the copied scenes or create an
inherited scene from `playable_hero.tscn` and save each variant separately. Enable **Editable Children** on scene
instances when you need to reach nested nodes. Do not copy `SettingsApplier` unless you want it to own these values.

Paths below are relative to the hero instance:

| What to tune | Node or resource |
|---|---|
| Click, hold, keys and cursor | `PlayerInput` (`PointClickMoveInput`) |
| Sprint key mode and jump input | `PlayerActionInput` (`CharacterActionInput`) |
| Speed, acceleration, braking, turn rate | `Character/NavigationMover` → `settings`, normally `player_locomotion.tres` |
| Jump, gravity, stairs and stamina use | `Character` (`GroundCharacter`) |
| Ledge protection / stamina recovery | `Character/LedgeGuard` / `Character/Stamina` |
| Orbit, follow, pitch and zoom | `CameraRig` (`OrbitCameraRig`) |
| Camera obstacles and fading | `CameraRig/CameraArm` (`CameraArm`) |
| Floating model | `Character/Visual/Hover` (`CharacterHover`) |

The rig's angle fields and the movement resource's turn rate are shown in **degrees in the Inspector**, but
GDScript assignments use **radians** (`deg_to_rad(30.0)`). `Camera3D.fov` is different: it uses degrees in code too.
Downward camera pitch is negative. The demo's **Tilt down** slider uses positive degrees, and
**Height** uses percent: 55% in the menu is `follow_zoom_level = 0.55`, not a height in meters.

## Default: manual orbit

This is the supplied hero scene, and the demo after Reset all. You can click to route around obstacles, hold LMB to
steer directly, or hold RMB with WASD to move relative to the camera. The camera follows the body's position but
does not rotate behind the run automatically.

| Part | Values to retain |
|---|---|
| Movement resource | `max_speed = 5.5`, `sprint_speed_multiplier = 1.5`, `acceleration_time = 0.18`, `stop_time = 0.22`, `turn_speed = 720°/s` |
| Character | `jump_height = 1.0`, `gravity_scale = 3.0`, `max_step_height = 0.3`, `sprint_tires = true`, `sprint_duration = 5.0` |
| Input | `hold_mode = STEER`, `hold_delay = 0.2`, both key modes `TURN`, `look_around_while_held = true`, `keep_aim_on_camera_turn = true` |
| Camera | `follow_movement = false`, `follow_pitch = false`, `follow_zoom = false`, `mouse_pitch = false`; target-height smoothing remains active at `height_follow_time = 0.15 s` |
| Initial view | `start_yaw = 45°`, `start_zoom = 0.55`, camera FOV 45° |
| Camera arm | `keep_out_of_geometry = true`, `pull_in_on_occlusion = false`, collision layers 1 and 3 |

Keep the ledge guard enabled and the supplied `Visual` as the camera arm's fade target. Behind a wall the silhouette
keeps the hero visible; the arm prevents the camera from entering geometry. These are different functions.

**Check it:** click beyond a wall with a route around it, hold the mouse into the wall, then orbit while moving.
A click should follow a route; a hold should slide or stop against collision. Looking around should preserve the
run's course. Test a 0.2 m stair and a jump separately before changing the movement values.

## Path-guided mouse movement

Start from the default. Change these properties on `PlayerInput`:

| Property | Value | Effect |
|---|---|---|
| `hold_mode` | `FOLLOW_POINT` | A held mouse button updates a navigation destination instead of steering straight |
| `stop_on_release` | `true` | Releasing a held run brakes at the current position |
| `keys_with_camera` | `OFF` | Disables RMB + WASD |
| `keys_with_camera_steer` | `OFF` | Disables A/D steering while both mouse buttons are held |

Keep all three camera-follow switches off, so the camera direction stays under manual control. The default movement
resource already accelerates and stops quickly; there is no need to alter its speed for this input style.

Short clicks still run to completion. `stop_on_release` affects **holds only** and is not exposed in the demo menu;
set it in the scene or code. Setting both key modes to Off does **not** disable both-button movement: RMB followed
by LMB still runs straight in the camera's direction, without a navigation path.

Use this setup for levels with a reliable baked mesh and mostly unambiguous ground under the cursor. Near a ramp or
platform, the ray can select a different height and rebuild the route. For precise direct control over such terrain,
use the default `STEER` mode instead. An empty path is not a safe "do not move" result in this controller; inspect
the navigation mesh when the hero heads directly into an obstacle.

**Check it:** hold on the far side of a wall, move the cursor to another reachable point, and release midway.
The hero should route around the wall, retarget and brake on release. Then make a short click and verify that it
continues to the destination.

## Camera-follow exploration

Start from the default `STEER` and `TURN` input modes. Enable these properties on `CameraRig`:

| Property | Value | Reason |
|---|---|---|
| `follow_movement` | `true` | Turns behind a click or cursor-driven run |
| `follow_time` | 1.1 s | The supplied scene's tuned turn time; approaches the new direction smoothly |
| `follow_toward_camera_angle` | 30° | A run almost directly toward the camera does not swing the view around |
| `sharp_turn_speed` | 360°/s | Half the supplied character's 720°/s turn rate; avoids following the intermediate directions of a turnaround |
| `follow_wait_after_rotate` | `true` | Keeps a manually chosen view until a stop or a new run |
| `follow_pitch` / `follow_pitch_angle` / `follow_pitch_time` | `true` / −22° / 1.1 s | Returns to a shallow view of the route ahead |
| `follow_zoom` / `follow_zoom_level` / `follow_zoom_time` | `true` / 0.55 / 1.5 s | Returns to the supplied starting zoom while moving |

The angles, zoom and timings come from the shipped scene and demo settings. Turning, pitch alignment and zoom
alignment are independent. If the player should keep the zoom they chose with the wheel, leave `follow_zoom` off;
leave `follow_pitch` off too if the wheel should keep controlling pitch in the usual way.

In the demo these are the Camera tab's **Turn the camera to follow the run**, **Align the camera tilt on the run**
and **Align the camera height on the run** switches. Their default target values already match the table.

RMB orbit takes priority over automatic follow. Because WASD requires RMB, the camera does not automatically turn
behind RMB + WASD movement. After an orbit, releasing RMB alone does not end the wait: stop, click a new
destination or start a new hold. Keep the scene's `run_requested → end_follow_wait` connection and
`keep_aim_on_camera_turn = true`; otherwise the follow can keep waiting or camera motion can steer the held cursor.

**Check it:** run across the view, turn 90°, then reverse toward the camera. The first turn should bring the camera
behind the route; the reversal should not spin it around. Orbit manually during a run and release RMB: the chosen
view should stay until a stop or new run. Test the same sequence near a wall to check the camera arm.

For a standalone hero, this is the code equivalent of enabling the profile. Run it from your game scene's `_ready()`
after the hero's children are ready:

```gdscript
extends Node3D

@onready var hero: PlayableHero = $Hero


func _ready() -> void:
    hero.place_at($Spawn, false)
    var rig := hero.camera_rig
    rig.follow_movement = true
    rig.follow_time = 1.1
    rig.follow_toward_camera_angle = deg_to_rad(30.0)
    rig.sharp_turn_speed = deg_to_rad(360.0)
    rig.follow_wait_after_rotate = true
    rig.follow_pitch = true
    rig.follow_pitch_angle = deg_to_rad(-22.0)
    rig.follow_pitch_time = 1.1
    rig.follow_zoom = true
    rig.follow_zoom_level = 0.55
    rig.follow_zoom_time = 1.5
```

This example assumes the unmodified hero's movement and input settings. In the full demo, use the settings menu or
`Settings.set_value()` instead, so the saved settings and the controls remain consistent.

## Optional: a floating hero

Any of these configurations can use the existing floating setup: set `Character/Visual/Hover.enabled = true`, or enable
**Character → Float above the ground** in the demo. Retain `height = 0.35 m`, `glide_time = 0.3 s` and the assigned
`player_floating_fall.tres` (fall gravity scale 0.5, maximum fall speed 2 m/s).

The model floats; the collision body still traverses stairs and falls. This does not cross gaps or provide flight.
The jump rises to the same height, then descends more slowly. Footstep events stop while floating, and a gentle
2 m/s touchdown is below the default 2.5 m/s landing-event threshold. The body's collider does not grow with the
raised model: test low ceilings. Model and fall details: [Characters](systems/characters.md) and
[Locomotion](systems/locomotion.md).

## Tuning without breaking the setup

- **Keep resources private when values should differ.** In the Inspector, make the mover's settings resource
  unique and save it under a new name before editing one character. Assign another resource before the mover
  enters the scene tree. At runtime, edit fields of the existing resource: replacing `mover.settings` after
  `_ready()` does not replace the resource already held by `GroundMotion`.
- **Change speed and braking together.** `acceleration_time` and `stop_time` are times at base speed. Sprint uses the
  same acceleration and braking, so the 1.5× sprint takes 1.5× as long to stop: about 0.33 s rather than 0.22 s.
  The ideal straight-line stopping distance is about 0.61 m at 5.5 m/s and 1.36 m at 8.25 m/s. Leave room at edges.
- **Match camera turn detection to movement.** Keep `sharp_turn_speed` at half of `LocomotionSettings.turn_speed`
  or lower. Do not lower the character's turn speed without reviewing this camera threshold.
- **Match the body, guard and navigation.** Changing capsule size, maximum step height or slope limit requires
  reviewing navigation radius/height/climb/slope and rebaking. The guard's drop limit must still allow intended
  stairs. Physics layers and navigation layers are separate settings.
- **Change one behavior, then repeat its check.** Use the demo's **Character path line** and **Character state and
  events** panels to see whether a problem is routing, collision, input or camera behavior. Keep a saved baseline
  scene instead of trying to reconstruct it from memory.

Full property references: [Input](systems/input.md), [Locomotion](systems/locomotion.md) and
[Camera](systems/camera.md).

---

*This page matches Iso & Orbit 1.2.0.*
