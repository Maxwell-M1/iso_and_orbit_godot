# Camera

[← Documentation index](../index.md)

`OrbitCameraRig` follows a `Node3D` target, turns around it with the mouse, and changes distance and tilt with the
wheel. Its child `CameraArm` places a `Camera3D` along local +Z and keeps it out of nearby geometry. Automatic turning,
tilt alignment, and zoom alignment while the target runs are three independent options.

```text
PlayableHero (stationary root in the template)
├── Character (moving target)
└── CameraRig (OrbitCameraRig; target = ../Character)
    └── CameraArm (CameraArm)
        └── Camera3D (current = true)
```

Keep the rig beside the moving target, not under it: the rig sets its own global position and rotation. Leave the rig,
arm, camera, and their ancestors at scale `(1, 1, 1)` so arm lengths and collision radii remain meaningful. The rig
places the camera each rendered frame from `target.get_global_transform_interpolated()` and disables its own physics
interpolation in `_ready()`; its children inherit that mode by default. Enable project physics interpolation when the
target moves in physics ticks; otherwise the target advances visibly one tick at a time. The template enables it.
`height_follow_time` can smooth the target's vertical steps after interpolation.

The `Camera3D` should start at its default local transform: the arm sets its local position and rotation. The template
marks it **Current** and uses a 45° field of view and 300 world unit far plane. If another current camera enters the
scene later, make this camera current when the hero should own the view. See
[Integration](../integration.md#the-camera-alone) for copying the camera or the entire hero, and
[Project setup](../project-setup.md) for input actions and physics layers.

## Which values are active?

The script values below are reusable component defaults. `gdscript/player/playable_hero.tscn` overrides a few of them;
the demo's `SettingsApplier` then applies saved `Settings` values when the main scene starts. A copied hero scene works
without the demo settings window or autoload, using its scene values.

| Setting | Script default | Playable hero scene / fresh demo |
|---|---:|---:|
| Turn, tilt, zoom alignment on a run | all off | all off |
| `follow_time` | 1.5 s | 1.1 s |
| `follow_pitch_angle`, `follow_pitch_time` | −40°, 1.5 s | −22°, 1.1 s |
| `follow_zoom_level`, `follow_zoom_time` | 0.55, 1.5 s | 0.55, 1.5 s |
| `follow_wait_after_rotate` | off | on |
| `height_follow_time` | 0 s | 0.15 s |

The turn, tilt, and zoom times and goals take effect only when their respective follow switches are enabled.
`height_follow_time` always smooths the target's vertical motion, including in manual orbit. In the demo, a previous
choice saved in `user://settings.cfg` can replace the fresh defaults. The `SettingsApplier` converts the settings
window's positive “tilt down” degrees to a negative pitch, and its 0–100% height to the rig's 0–1 zoom.

Lengths and speeds are in Godot world units (metres when a scene uses the template's 1 unit = 1 m scale). Angles and
angular speeds marked `radians_as_degrees` show degrees in the Inspector, but GDScript assigns radians: use
`deg_to_rad(-22.0)` for `follow_pitch_angle` and `deg_to_rad(360.0)` for `sharp_turn_speed`. The serialized
`-0.383972...` in `playable_hero.tscn` is −22°.

## Orbit, tilt, and zoom

Hold `camera_rotate` (RMB in the template) and move the mouse to orbit. The cursor is captured and returned to its
former position on release; losing focus or pausing releases it too. With `mouse_pitch` off, vertical mouse motion has
no effect and the wheel chooses tilt. Turn it on to tilt with the mouse; `invert_pitch` reverses that axis. Wheel up
lowers the camera, and wheel down raises it. Smooth scrolling can move by a fraction of `zoom_step`.

Zoom is a number from 0 (near) to 1 (far). The default wheel step is 0.1. The arm length interpolates from
`near_distance` 5 to `far_distance` 20 world units. Tilt is shallower up close, following this curve:

| Zoom | Distance | Base tilt |
|---:|---:|---:|
| 0 | 5 | −22° |
| 0.2 (`flatten_end_zoom`) | 8 | −22° |
| 0.5 (`flatten_start_zoom`) | 12.5 | −38.5° |
| 0.55 (`start_zoom`) | 13.25 | −40.15° |
| 1 | 20 | −55° |

Between zoom 0.2 and 0.5, the tilt levels out quickly as the camera comes down, making the ground ahead easier to see.
Below 0.2, only the distance changes. Mouse tilt and follow tilt add an offset to the curve, bounded by `min_pitch` and
`max_pitch` (−80° and −8°). Turning `mouse_pitch` off clears its offset unless `follow_pitch` still holds a tilt.
`rotation_sharpness` and `zoom_sharpness` smooth mouse and wheel changes; 0 makes the corresponding input immediate.

## Follow mode

Set any combination of `follow_movement`, `follow_pitch`, and `follow_zoom` to make the camera turn behind the running
direction, approach a chosen tilt, and approach a chosen zoom level. The rig measures horizontal movement per physics
tick from any `Node3D` target, so it does not require a character velocity property. Below `follow_min_speed` it does
not follow; from that speed to twice it, follow strength grows smoothly. A target that stops starts its next run with a
fresh direction.

Each enabled motion starts and settles smoothly on its own spring. Its time is approximately how long it takes to cover
95% of a change from rest during a full-speed run, provided no turn-speed cap intervenes; 0 requests an immediate
change. When movement stops or follow pauses, a motion already under way brakes rather than cutting off.
`rotation_sharpness` and `zoom_sharpness` set that braking rate. The follow itself moves the camera directly, so input
smoothing does not add a second lag.

| Property | Script default | Effect |
|---|---:|---|
| `follow_movement`, `follow_time` | off, 1.5 s | Turn behind the horizontal run; time to nearly finish the turn |
| `follow_max_turn_speed` | 0 | Maximum automatic yaw speed in °/s; 0 removes the cap, including for an instant turn |
| `follow_toward_camera_angle` | 30° | Ignore runs within this angle of straight toward the camera; full turn strength by twice the angle. 0 removes this exception |
| `sharp_turn_speed` | 360°/s | Ignore passing directions during a sharper turn or reversal, then take up its new direction; 0 disables this guard |
| `teleport_speed` | 50 world units/s | Horizontal movement faster than this between physics ticks is treated as a teleport, not a run |
| `follow_pitch`, `follow_pitch_angle`, `follow_pitch_time` | off, −40°, 1.5 s | Bring tilt to this downward angle, independently of yaw |
| `follow_zoom`, `follow_zoom_level`, `follow_zoom_time` | off, 0.55, 1.5 s | Bring zoom to this 0–1 level, independently of yaw and tilt |
| `follow_min_speed` | 1 world unit/s | Minimum horizontal speed to begin following; full strength at twice this speed |
| `follow_wait_after_rotate` | off | Keep the view after a mouse orbit until the target slows below `follow_min_speed` or a new run is reported |

The toward-camera guard affects **turning only**. A run directly at the camera can still change tilt and zoom if those
options are enabled. The sharp-turn guard also affects turning only: tilt and zoom continue during a reversal, while a
turn already under way can coast to a stop. For the template hero's 720°/s `LocomotionSettings.turn_speed`, the 360°/s
sharp-turn threshold catches reversals while allowing slower curves. If you change character turn speed, keep
`sharp_turn_speed` at half that speed or lower; `PlayableHero` warns when a positive threshold reaches the character
turn speed. Setting `follow_toward_camera_angle` to 0 intentionally permits the camera to turn around behind a run
toward it.

When both tilt and zoom alignment are on, zoom changes the distance while the tilt alignment compensates for the zoom
curve. The view settles at `follow_pitch_angle` and `follow_zoom_level` independently. The wheel and mouse still work
during a run; enabled follow motions bring the view back to their goals. `height_follow_time` is separate: it smooths
how the rig follows the target's **world Y position**, especially on stairs. It does not change the zoom level. At 0 it
tracks the target height exactly; the hero scene's 0.15 s makes 95% of a vertical change in about that time.

### When follow pauses

All three follow motions stop pulling while RMB is held. With `follow_wait_after_rotate` on, ending an orbit after at
least 0.2 s or 2 px of motion keeps the chosen view while the current run continues. This also applies if focus is lost
or the game pauses before RMB is released; a shorter tap does not start a wait. With the option off, follow resumes when
the orbit ends. The wait ends when movement slows below `follow_min_speed`, `end_follow_wait()` reports a new run,
`snap()` is called, the target changes, or a movement exceeds `teleport_speed`. A new run can begin before the old one
stops, so connect the input's `run_requested` signal to `end_follow_wait()` when using this option. Without such a
signal, a continuously moving target can keep the camera waiting indefinitely; leave the option off if the game cannot
report new runs.

`playable_hero.tscn` also connects `PointClickMoveInput.hold_pending_changed` to `set_follow_paused()`. This pauses
follow during the first 0.2 s of an LMB press, while the input decides whether it was a click or a hold. Its
`run_requested` signal ends the post-orbit wait for a new click, hold, or RMB + key run. Pressing RMB during an existing
LMB run can be used to look around; that run does not count as a new one after RMB is released, so the view remains
where the player left it until a later stop or new run. The input's `keep_aim_on_camera_turn` keeps the cursor aimed at
the same world point while the camera moves, preventing the running direction from chasing the camera.

When `Engine.time_scale` is 0, follow motions hold their state and resume when time advances. If you move a target
manually or teleport it a short distance that does not trigger the `teleport_speed` check, call `snap()` to put the
camera and arm into place and reset motion history.

## Properties

| Group | Property | Script default | Meaning |
|---|---|---:|---|
| Target | `target` | none | `Node3D` to follow |
| Target | `arm`, `camera` | none | First matching direct child if unset; use `camera` only without an arm |
| Input | `rotate_action`, `zoom_in_action`, `zoom_out_action` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` | Input Map actions; missing ones report an error at startup |
| Input | `mouse_sensitivity`, `mouse_pitch`, `invert_pitch`, `zoom_step` | 0.25 °/px, off, off, 0.1 | Mouse orbit rate, mouse tilt controls, wheel increment |
| Framing | `focus_height` | 1.2 world units | Aim point above the target origin |
| Framing | `near_distance`, `far_distance` | 5, 20 | Arm lengths at zoom 0 and 1 |
| Framing | `near_pitch`, `far_pitch` | −22°, −55° | Base tilts at zoom 0 and 1 |
| Framing | `flatten_start_zoom`, `flatten_end_zoom` | 0.5, 0.2 | Zoom interval that levels the tilt more quickly |
| Framing | `min_pitch`, `max_pitch` | −80°, −8° | Final tilt limits, including mouse and follow offsets |
| Framing | `start_zoom`, `start_yaw` | 0.55, 45° | Initial zoom and world-axis yaw; `look_along()` can change the yaw later |
| Smoothing | `rotation_sharpness`, `zoom_sharpness` | 30, 10 | Higher values reach mouse/wheel goals faster; 0 is immediate |
| Smoothing | `height_follow_time` | 0 s | Time for vertical target following to cover about 95%; 0 is exact tracking |

`look_along(direction)` immediately points the view along the horizontal part of a **world-space** direction and stops
an automatic turn already under way. `snap()` immediately applies the current yaw, tilt, zoom, target position, and arm
collision response; use it after teleporting. `get_zoom()` returns the current 0–1 zoom. `is_rotating()`,
`is_follow_paused()`, `is_follow_waiting()`, and `is_target_turning_sharply()` report those states.
`set_follow_paused(paused)` and `end_follow_wait()` control the pauses described above.

The rig requires an arm or camera child (or an explicit `arm`/`camera` property); a missing one asserts in a debug
build. It sets its global rotation, so `start_yaw`, `look_along()`, and automatic turning use world axes even if the
stationary hero root is rotated.

## Obstacles, occlusion, and fade

`CameraArm` normally uses `keep_out_of_geometry`: a sphere at the desired camera position must fit outside physics
bodies. If a wall, slope, or roof would contain the camera, the arm shortens immediately. A fence between the target and
a camera that still has room behind the fence does not shorten it. To deliberately move in front of a fence that hides
the target, enable `pull_in_on_occlusion`; the arm waits for sustained occlusion and only pulls in when at least
`min_pull_in_length` remains. Once clear, it waits briefly and returns smoothly. If an obstacle lies on the return path,
it jumps across it rather than flying through it.

### How the arm tells room behind an obstacle from being inside a body

The arm first checks whether the camera sphere fits at its desired end. It can stay behind a fence between the target
and camera when that end is clear. If the end touches or lies inside a body, the arm finds a free place closer to the
target. Jolt shape casts do not report bodies touched or entered at the start of a cast, so the arm checks that starting
space separately; when two bodies are close together, it searches from a point nearer the target. This also keeps the
camera out of a fence with a cliff immediately behind it.

Both the sphere and the visibility rays use `collision_mask` (binary `0b101`, layers 1 and 3). In the template, layer 1
is solid world geometry and layer 3 is camera-only geometry such as `RoofCameraBlocker`; characters on layer 2 and
invisible character bounds on layer 4 do not move the arm. A body in `camera_ignore`, or beneath a node in that group,
is ignored. Set that group on a prop root to affect every instance. These mask numbers matter when copying to another
project; layer names are only labels. With `keep_out_of_geometry` off, the arm no longer protects the camera from
geometry behind it, regardless of the pull-in setting.

The five default `occlusion_points` sample the target's chest, head, knees, and sides. They are relative to the **arm's
start**, which the rig places `focus_height` above the target origin; x is camera-right, y is up, and z is horizontally
toward the camera. `occlusion_share = 0.75` means at least four of the five points must be blocked. Adjust the points
and `focus_height` for a taller or floating model. The template's `CharacterHover` can lift the visible model 0.35 world
units above its body.

`fade_target` is optional. When set, the arm changes the `transparency` of its `GeometryInstance3D` descendants as the
arm becomes shorter than `fade_start_length`, reaching `fade_transparency` at `fade_end_length`. The hero assigns
`Character/Visual`. This close-range fade is distinct from the optional `OccludedSilhouette` addon, which draws a
character through obstacles.

| Property | Script default | Meaning |
|---|---:|---|
| `length`, `camera` | 10, none | Desired arm length (normally set by the rig), and its first direct `Camera3D` child unless assigned |
| `keep_out_of_geometry`, `probe_radius` | on, 0.3 | Keep a camera sphere outside masked bodies |
| `collision_mask`, `ignored_groups` | layers 1 + 3, `camera_ignore` | Bodies considered by collision and occlusion checks, and groups excluded from them |
| `pull_in_on_occlusion`, `min_pull_in_length`, `pull_in_sharpness` | off, 2.5, 10 | Pull-in switch, minimum length, and approach rate (0 is immediate) |
| `occlusion_points`, `occlusion_share`, `occlusion_delay` | five points, 0.75, 0.25 s | Visibility samples, blocked share, and delay before pull-in or return |
| `return_delay`, `return_sharpness` | 0.3 s, 4 | Wait and speed of arm extension (0 sharpness is immediate after the wait) |
| `fade_target`, `fade_start_length`, `fade_end_length`, `fade_transparency` | none, 1.5, 0.7, 0.75 | Optional model fade; full at 0.7 units or closer |
| `debug_draw` | off | Draw desired/current arm lengths, camera sphere, and visibility rays; useful from another camera |

`CameraArm.snap()` recomputes collision and places the camera without return delays. `get_current_length()` gives its
actual length after obstacles; `is_pulled_in_by_occlusion()` reports whether target occlusion is currently moving it
inward.

The behavior above is exercised by [`tests/camera_checks.gd`](../../../tests/camera_checks.gd) and
[`tests/camera_arm_checks.gd`](../../../tests/camera_arm_checks.gd): they cover follow timing, toward-camera and
sharp-turn guards, waiting after mouse orbit, tilt/zoom alignment, vertical stair smoothing, obstacle avoidance,
optional pull-in, ignored groups, and fading.

---

*This page matches Iso & Orbit 1.2.0.*
