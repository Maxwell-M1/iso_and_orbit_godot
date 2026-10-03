# Camera

Two nodes: `OrbitCameraRig` follows a target, orbits and zooms; its child `CameraArm` holds the `Camera3D` at the
end of an arm and shortens the arm at obstacles.

```
CameraRig (OrbitCameraRig)     placed at the target, turned by yaw and pitch
└── CameraArm (CameraArm)      arm along local +Z; the rig sets its length from the zoom
    └── Camera3D               at the end of the arm, looking back along it
```

The rig is a sibling of the target, not its child. It moves in `_process` to the target's interpolated position,
and its own physics interpolation is off: otherwise it would smooth an already smoothed position and lag a tick
behind. With physics interpolation on in the project, the camera and the character move smoothly at any frame rate.

## OrbitCameraRig

- **Orbit.** Hold the right button (`camera_rotate`) and move the mouse. The cursor is captured while you orbit and
  returns to where it was when you release the button. If the window loses focus or the game pauses mid-orbit, the
  rig releases the cursor itself.
- **Tilt with the mouse** (`mouse_pitch`, off by default). Vertical mouse movement with the right button also tilts
  the camera. Off, the tilt comes from the zoom only.
- **Zoom.** The wheel moves the camera down and closer or up and farther. Distance and tilt change together.
- **Follow** (`follow_movement`, `follow_pitch`, both off by default). The camera gradually turns behind the
  running target and eases its tilt to `follow_pitch_angle`.

### The zoom curve

The zoom is a value from 0 (closest) to 1 (farthest); each wheel notch changes it by `zoom_step` (0.1). Distance
goes from `near_distance` (5 m) to `far_distance` (20 m). The tilt goes from `near_pitch` (−22°) to `far_pitch`
(−55°), but not evenly: from the top down to `flatten_start_zoom` (0.5, 12.5 m, −38.5°) it changes evenly, and below
that the camera levels out quickly, so that ahead of the character is visible already at a medium height. From
`flatten_end_zoom` (0.2, 8 m) the camera looks at −22° and only moves closer.

The demo starts at `start_zoom` 0.55. One notch down from there: −33.5°, two: −26°, three (8.75 m): −22.5°.

The tilt is the zoom tilt plus an offset. The mouse (with `mouse_pitch`) and follow mode change the offset, so the
wheel and the mouse work as usual and on the run the tilt eases back to the chosen angle. Turning `mouse_pitch` off
clears the offset. The tilt never goes past `min_pitch` (−80°) and `max_pitch` (−8°).

### Follow mode

| Property | Default | Meaning |
|---|---|---|
| `follow_movement` | off | Turn the camera behind the running target |
| `follow_pitch` | off | Ease the tilt to `follow_pitch_angle` on the run, at the same rate and in the same cases as the turn; works without `follow_movement` |
| `follow_pitch_angle` | −40° | Target tilt (down is negative), limited by `min_pitch` and `max_pitch` |
| `follow_time` | 1.5 s | Time to turn nearly all the way (5% of the angle is left); 0 is instant |
| `follow_min_speed` | 1 m/s | Below this speed the camera does not turn: standing or pivoting, the direction is unreliable. Between this speed and twice it the turn gains strength smoothly |

The demo's settings use different defaults: catch-up time 1.1 s and tilt 22° down.

The camera does not follow:

- while the right button is held: the mouse controls the camera, including when running with both buttons;
- for the first 0.2 s after a left button press, until it is clear whether it is a click or a hold. The pause comes
  from `PointClickMoveInput.hold_pending_changed`, connected in `main.tscn` to `CameraRig.set_follow_paused()`.

The target's speed is measured by the rig from the target's movement per physics tick, so any `Node3D` can be the
target.

When the camera turns while the left button is held, the cursor would point at a different spot on the ground and
the character would turn after it, and the camera after the character: the character would run in circles. So while
the button is held, the input moves the system cursor along with the world. See
[Input](input.md#the-cursor-while-the-button-is-held).

### Properties

| Group | Property | Default | Meaning |
|---|---|---|---|
| | `target` | — | What to follow |
| | `arm` | — | The `CameraArm`; if empty, the first `CameraArm` child |
| | `camera` | — | Used without an arm; if empty, the first `Camera3D` child |
| Input | `rotate_action`, `zoom_in_action`, `zoom_out_action` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` | Input actions |
| | `mouse_sensitivity` | 0.25 °/px | Orbit speed |
| | `mouse_pitch` | off | Vertical mouse movement tilts the camera |
| | `invert_pitch` | off | Invert that tilt |
| | `zoom_step` | 0.1 | Zoom change per wheel notch |
| Framing | `focus_height` | 1.2 m | Height above the target's origin the camera looks at |
| | `near_distance`, `far_distance` | 5 m, 20 m | Arm length at the closest and farthest zoom |
| | `near_pitch`, `far_pitch` | −22°, −55° | Tilt at the closest and farthest zoom |
| | `flatten_start_zoom`, `flatten_end_zoom` | 0.5, 0.2 | Where the tilt starts leveling out faster, and where it is level |
| | `min_pitch`, `max_pitch` | −80°, −8° | Tilt limits |
| | `start_zoom`, `start_yaw` | 0.55, 45° | Initial zoom and direction |
| Follow | see above | | |
| Smoothing | `rotation_sharpness`, `zoom_sharpness` | 30, 10 | How fast the camera reaches the wanted yaw, tilt and zoom |

Methods: `look_along(direction)` turns the camera to look along a direction at once; `snap()` jumps to the wanted
position, for example after teleporting the target; `is_rotating()`; `set_follow_paused(paused)`.

## CameraArm

The wheel sets the arm length; the arm shortens at obstacles and returns to that length when there is room.

- **Stop at what is behind** (`keep_out_of_geometry`, on by default). A mountain, a wall or a roof behind the camera:
  the camera does not go inside but moves toward the target. Walk toward the mountain and the camera comes closer to the
  target without entering the slope; walk away, and it goes back once there is room behind it. The arm shortens only if
  the camera cannot stand at its end. A column or a fence between the camera and the target, with room behind it, does
  not move the camera: the character shows through as a silhouette.
- **Move in when the target is hidden** (`pull_in_on_occlusion`, off by default). A fence or a wall hides the target
  almost entirely: the camera smoothly moves in front of the obstacle, but never closer than `min_pull_in_length`
  (2.5 m) to the target. If the character stands right at the wall, the camera stays put instead of jumping to the
  character's back.
- **Fade up close.** When the arm is very short, `fade_target` turns translucent.

| Property | Default | Meaning |
|---|---|---|
| `length` | 10 m | Arm length; set by the rig from the zoom |
| `camera` | — | The camera; if empty, the first `Camera3D` child |
| `keep_out_of_geometry` | on | Stop at bodies behind the camera |
| `probe_radius` | 0.3 m | The camera is a sphere of this radius and keeps that far from walls |
| `collision_mask` | layers 1 and 3 | Bodies that stop the arm: `world` and `camera`. Characters (layer 2) do not |
| `ignored_groups` | `camera_ignore` | Bodies in these groups, or under a node in them, do not stop the arm |
| `pull_in_on_occlusion` | off | Move in when the target is hidden |
| `min_pull_in_length` | 2.5 m | The camera does not move closer than this because of a hidden target; with less room in front of the obstacle it stays put |
| `pull_in_sharpness` | 10 | How fast the camera moves in front of a hiding obstacle (0 is instant). It always stops at a body behind at once |
| `occlusion_points` | chest, head, knees, sides | Points of the target checked for visibility, relative to the arm's start: right, up, toward the camera |
| `occlusion_share` | 0.75 | The target is hidden when this share of the points is hidden. A thin post or a trunk hides three of five and does not count |
| `occlusion_delay` | 0.25 s | How long the target must stay hidden for the camera to move in, and visible for it to move back |
| `return_delay`, `return_sharpness` | 0.3 s, 4 | The arm shortens at once but grows back after a pause and smoothly, so the camera does not twitch among columns |
| `fade_target` | — | What turns translucent up close (`Player/Visual` in the demo) |
| `fade_start_length`, `fade_end_length`, `fade_transparency` | 1.5 m, 0.7 m, 0.75 | The target starts fading at the first length and is 75% transparent at the second |
| `debug_draw` | off | Draw the arm (gray: the wheel length, green: the current one), the camera sphere and the rays to the target's points (red: hidden). Visible from another camera |

Methods: `snap()`, `get_current_length()`, `is_pulled_in_by_occlusion()`.

### Bodies only for the camera

Put them on physics layer 3 (`camera`). Characters do not collide with them, and clicks and navigation do not see
them. The roof of the house (`RoofCameraBlocker` in `shared/world/props/house.tscn`) has such a body: the camera
stops at the roof, but nobody can climb onto it or path across it.

### The `camera_ignore` group

The group also applies to everything under a node in it. Set it once on a prop scene's root, so every instance in the
level has it, or on a level folder node. The demo does not need it: tree trunks (up to 2.4 m) are below the camera
even at the closest zoom (3 m above the ground).

### How the arm tells room behind an obstacle from being inside a body

First the arm checks whether the camera can stand at the arm's end: the sphere touches nothing there, and the end
is not inside a body. A ray from the camera to the target does not see the faces of a body it starts inside, so it
finds the far face of the obstacle in front of the camera. A ray from that face to the arm's end enters the body the
camera is in and never leaves it. If something is in the way, the sphere is cast from that face toward the camera and
stops in front of the body that is in the way, passing others by. A column that the arm only grazes does not move the
camera.

Jolt does not report bodies that the sphere touches at the start of a cast. So if another body stands right behind
the face (a fence with a cliff behind it), free space is searched closer to the target.

## Measured behavior

From `tests/camera_checks.gd` and `tests/camera_arm_checks.gd`:

- Follow with the run at 90° to the camera: `follow_time` 0 turns 95% in 0.17 s, the demo's 1.1 in 1.23 s; at 10 it
  has turned only 39° of 90° after 2 s. Standing, it does not turn. With the right button held it does not turn and
  continues after release.
- Holding the left button with follow on (1.1 s): for the first 0.2 s the camera stays put (a short click does not
  move it), then in 1.25 s it turns 27.1° of the 28.3° behind the run while the running direction changes by 0.01°;
  with "instant", too. Moving the mouse 150 px turns the run by 25°, and the new direction holds. With
  `keep_aim_on_camera_turn` off the character curls 77.6° in 1.25 s.
- Tilt alignment: a camera lowered by the wheel (22.5° down) eases to 55° at `follow_time` 0.5, 95% of the way in
  about 0.65 s, without turning after the run if the turn is off. 89° is clamped to the camera's 80° limit. Holding
  the left button with follow and a 20° tilt: the tilt goes from 80° to 22.5° in 1.25 s, on its way to 20°, and the
  running direction changes by 0.01°.
- The arm: full length in the open; a cliff behind stops it at once; walking toward the cliff, the camera moves closer
  and stays out of it; with the cliff gone, the arm returns after a pause, smoothly. A fence with a cliff right behind
  it: the camera stops in front of the fence. A fence halfway between the camera and the character: by default the
  camera stays behind it; with pull-in it moves in front of it smoothly, and a short occlusion does not count. A fence
  right at the character: the camera does not jump to the character's back. A thin post does not count, a column grazing
  the arm does not move the camera, bodies in `camera_ignore` do not stop it, and up close the character is translucent.

---

*This page matches Iso & Orbit 1.0.0.*
