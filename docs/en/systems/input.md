# Input

[← Documentation index](../index.md)

Two nodes turn player input into commands. Neither moves anything itself.

- `PointClickMoveInput`: the mouse, and WASD with the right button held → `NavigationMover.move_to()`, `steer()`
  and `stop()`.
- `CharacterActionInput`: sprint and jump keys → `GroundCharacter.sprint_requested` and `jump()`.

Both live in the playable hero scene (`playable_hero.tscn`), not in the character scene, so the same character can
be driven by AI instead. For the player's view of the controls, see [Controls](../controls.md). For a copy of the
assembled hero, follow [Using it in your project](../integration.md#taking-the-demos-hero-into-your-project); for
suggested combinations, see [Configurations](../configurations.md).

## PointClickMoveInput

| Input | Command |
|---|---|
| Click on the ground | `move_to(point)`: a ray from the camera on `ground_mask` finds the point |
| Left button held | `steer()` toward the cursor, or `move_to()` the point under it, depending on `hold_mode` |
| Right button, then left, or both within `hold_delay` | `steer()` where the camera looks; A and D veer diagonally forward (`keys_with_camera_steer`) |
| Left button held, then right | No new command: the hold keeps steering by its aim while the right button orbits the camera (`look_around_while_held`) |
| Right button and WASD | `steer()` relative to the camera, sidestepping or turning (`keys_with_camera`); `stop()` on release |

Who drives the character in a tick is decided in one place, `_physics_process`: a held left button first, else the
keys with the right button. So releasing the left button while the right button and W are held does not stop the
character: the keys take over at once.

The other way round, when the right button is released during a run with both buttons, the run keeps the course
where the camera looked (`keep_camera_course`). The cursor takes over when the mouse moves (more than 8 px, and not
in the first `cursor_takeover_delay`, 0.2 s, while the hand may still be turning the camera), and it starts from a
point 4 m ahead of the character along the run. Until then, releasing the left button stops the character on its
course, as if both buttons had been released together, however long the gap between them. People rarely release
two buttons at the same instant. With `keep_camera_course` off, the cursor takes over as soon as the right button is
released, using its position from before the orbit; this can turn the character sharply.

### Looking around on the run

The right button pressed while a hold already runs after the cursor only orbits the camera
(`look_around_while_held`, on): the player is running where they want and wants to look around, not to hand the
run to the camera. Without the setting the character turned at once to where the camera looked, and with the camera
follow off that is rarely the way it runs. The order decides, caught at the moment the right button goes down:

- during a hold that steers by the cursor: looking around;
- before the left press becomes a hold (`hold_delay`, 0.2 s), so both buttons pressed together, or the right button
  first: the run goes where the camera looks, as before;
- during a hold that still keeps the camera's course after the right button was released (`keep_camera_course`):
  the run goes where the camera looks again. Once the mouse has moved and the cursor steers, the next press looks
  around.

It relies on `camera_steer_action` turning the camera, as `OrbitCameraRig.rotate_action` does (both are
`camera_rotate`): while the button is held the mouse does not move the aim. With a different action, or a camera that
does not turn with it, turn `look_around_while_held` off. While looking around the keys do nothing: the hold drives
the run, as without the right button.

While looking around, the aim does not follow the mouse: the aim is the ground point relative to the character's feet
that also keeps the course when the camera turns on its own (`keep_aim_on_camera_turn`). The mouse turns the camera,
and in `STEER` mode the character runs toward the aim. After the right button is released, the cursor returns to
that spot and mouse movement steers again. If a large orbit puts the aim off screen, the component brings it closer
along the same direction to avoid a sudden turn at the window edge.

In `FOLLOW_POINT` mode the point the run goes to stays where it was relative to the character's feet while looking
around and after it until the mouse moves (more than 8 px after `cursor_takeover_delay`, as with
`keep_camera_course`), so the character runs on the same way and does not arrive. The point under the cursor is not
the same when seen from another side, even with the cursor over the same spot of ground: the ray from the camera can
hit a slope or a platform in front of it. A hold that has reached its point (the cursor at the feet) has no point to
keep, so looking around leaves it there. After the release the cursor aims at the same point as seen from the new
camera angle, unless something now hides it.

When the left button is released while the right one still turns the camera, the hidden cursor appears over the spot
it aimed at once the camera lets it go, not where the camera puts it back (where the hidden cursor happened to be when
the right button was pressed).

With `keep_aim_on_camera_turn` off, the cursor stays in place on the screen, and the orbit turns the run with it
(90° for a 90° orbit), as the camera's own turn does. To go from looking around to the run where the camera looks
without a stop, press the left button again with the right one held: a press with the right button down runs after
the camera at once. Off (`look_around_while_held`), the right button steers the run in any order.

### Click or hold

A press becomes a hold after `hold_delay` (0.2 s). Until then the character keeps doing what it was doing (standing,
or running where it was running), and there is no marker and no path to the pressed point.

- **Released earlier: a click.** The character runs along a path to the point where the button was pressed. The
  point is taken at the moment of the press, even if the mouse moved afterwards. The marker appears
  (`destination_picked`). It fades when the character arrives or the run is abandoned for the keys or a hold.
- **Held longer: a hold.** The character runs after the cursor at once (`hold_started`) and does not turn toward the
  pressed point first. Otherwise it would start along the path to that point, and a path around obstacles can lead
  somewhere else entirely than the cursor.

The cost is that a click acts on release, about 0.1 s later than on press. While it is unclear whether a press is a
click or a hold, `hold_pending_changed(true)` pauses the camera's follow mode (connected to
`OrbitCameraRig.set_follow_paused()` in `playable_hero.tscn`), so a short click never moves the camera.

If the right button is already held when the left one is pressed, there is no click: the character runs after the
camera at once.

### Hold modes

`hold_mode` (Settings → Controls → **Held LMB**):

- `STEER` (default): straight toward the cursor, without a path. The character slides along obstacles and runs up
  the ramp wherever you point it. Within `steer_dead_zone` (0.5 m) of the character the direction does not change:
  so close, it is too sensitive to the cursor. On release the character stops smoothly.
- `FOLLOW_POINT`: to the point under the cursor along a navigation path. The path is rebuilt while the point moves,
  so near height changes it can jump from one route to another. On release the character runs on to the last point
  and the marker shows it (`destination_picked`); with `stop_on_release` it brakes where it is. That setting affects
  holds only: a short click still runs to its picked point. An empty path uses a straight run and a partial path may
  end short of the requested point, as explained in [Locomotion](locomotion.md#navigationmover).

### Keys with the right button

The keys work only while the right button is held: the camera turns with the mouse and the cursor is captured.
Without it WASD do nothing. Each mode is `OFF` or one of two variants, set separately for the right button alone
(`keys_with_camera`) and for both buttons (`keys_with_camera_steer`).

| | `SIDESTEP` | `TURN` |
|---|---|---|
| RMB + W | forward, where the camera looks | the same |
| RMB + A / D | sideways, facing forward | turns left / right and goes there |
| RMB + S | backward, facing forward, slower | turns around and walks toward the camera |
| Two keys (W + A, S + D…) | diagonally, facing forward | diagonally, facing the way it goes |
| LMB + RMB + A / D | diagonally forward, facing forward | diagonally forward, facing the way it goes |

The script default is `SIDESTEP` for both; the demo sets `TURN` for both, in its settings and in `playable_hero.tscn`.
`keys_with_camera_steer = OFF` disables A/D while both buttons are held, but the two buttons still run where the
camera looks. To disable that command too requires changing `camera_steer_action`, which also affects look-around
and the right-button keys.

Diagonal movement is as fast as straight movement. Backward movement is slower: `NavigationMover` scales the speed by
how much the movement opposes the facing, see [Locomotion](locomotion.md#navigationmover). The facing is passed as
the second argument of `steer(direction, facing)`: when sidestepping, it is the camera's forward direction. After a
stop the character keeps facing where it faced; a click or a hold turns it to face the way it runs again.

Release the keys or the right button and the character stops smoothly. The right button alone, with no keys, does
not interrupt a run to a clicked point, so you can turn the camera on the run. The keys interrupt it, and the
marker fades. The keys are the actions `move_forward`, `move_back`, `move_left`, `move_right`, bound by physical
position.

### The cursor while the button is held

**Hidden** (`hide_cursor_while_held`, on by default). On the run the cursor would only flicker, especially while the
camera turns and the cursor moves with the world. It hides as soon as a press becomes a hold (a short click does not
touch it) and reappears on release where you aimed. The component keeps its hidden cursor within the game window;
on macOS it uses `MOUSE_MODE_HIDDEN`, and elsewhere `MOUSE_MODE_CONFINED_HIDDEN`, to avoid aim drift caused by the
platform's cursor movement. While the right button orbits the camera, the camera captures the cursor; release it
with the left one still held and the cursor is hidden again. Pausing or switching windows shows it at once.
`is_cursor_hidden()` reports whether this component hid it.

**Keeps its aim** (`keep_aim_on_camera_turn`, on by default). While the left button is held, the running direction comes
from the cursor, a point on the screen. If the camera turns while the cursor stays still on the screen, a different spot
of ground is under the cursor, the character turns after it, the camera turns after the character, and the character
runs in circles. So while the button is held, the component moves the aim with the world: the character keeps
running where you pointed while the camera eases behind it. Moving the mouse still steers. The same aim keeps the
course while the right button orbits the camera to look around on the run.

Off, the cursor steers like a car: hold it to the right of the character and the character veers right until the
cursor is straight ahead. Where the system cannot move the cursor (Wayland, for example), the running direction still
holds, but the cursor stays put.

The cursor is corrected in `_process` after the camera has settled for the frame: the component's
`process_priority` is 1, the camera's 0. The input reads the `Camera3D` directly and knows nothing about the camera
rig.

### Properties

| Property | Default | Meaning |
|---|---|---|
| `mover` | — | The `NavigationMover` to command; required |
| `camera` | — | Camera for rays and directions; if empty, the viewport's current camera |
| `move_action` | `move_to_cursor` | Click and hold |
| `hold_mode` | `STEER` | See above |
| `keep_aim_on_camera_turn` | on | See above |
| `hide_cursor_while_held` | on | See above |
| `camera_steer_action` | `camera_rotate` | With it held, a hold runs where the camera looks (pressed first or before the press becomes a hold, see `look_around_while_held`). Empty turns off running where the camera looks, looking around and the keys, which work only with it held |
| `look_around_while_held` | on | Pressed during a hold that runs after the cursor, the camera button only turns the camera, and the run keeps its course. Off: both buttons run where the camera looks in any order |
| `keep_camera_course` | on | After the camera button is released during a hold, keep the camera's course until the mouse moves; then the cursor, put ahead of the character along the run, steers. Off: the cursor takes over at once from where it was |
| `cursor_takeover_delay` | 0.2 s | With `keep_camera_course`: mouse movement this soon after the camera button is released does not take the run over yet |
| `ground_mask` | layer 1 | Physics layers you can click on. Must not include the characters' layer, nor the invisible walls (layer 4, `bounds`) |
| `hold_delay` | 0.2 s | When a press becomes a hold |
| `steer_dead_zone` | 0.5 m | `STEER`: no direction change with the cursor this close to the character |
| `stop_on_release` | off | `FOLLOW_POINT`: brake to a stop on release instead of running on to the last point |
| `ray_length` | 1000 m | Length of the ray from the camera |
| `keys_with_camera` | `SIDESTEP` (`TURN` in the demo) | RMB + WASD mode |
| `keys_with_camera_steer` | `SIDESTEP` (`TURN` in the demo) | LMB + RMB + A/D mode |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | The keys |

`ground_mask` selects physical surfaces for the click ray. `NavigationMover.navigation_layers` selects walkable
navigation regions for the route; they are separate masks. Keep the character and invisible walls out of the click
mask, or the ray can pick them instead of the ground.

The table shows component defaults, with the hero scene's `TURN` overrides called out. In the demo,
`SettingsApplier` applies saved values at startup to `hold_mode`, cursor hiding, both key modes, looking around and
aim keeping. A copied `playable_hero.tscn` without that settings system keeps its scene values.

Signals: `destination_picked(point)`, `hold_started`, `hold_pending_changed(pending)`, and `run_requested`: the
player sent the character on a new run, with a click to a new point, a press that became a hold, or the keys with the
right button that started a walk. It does not fire for a click at the point the character is already running to, nor
when the keys carry on a hold that has just ended. In `playable_hero.tscn` it ends the camera's wait after an orbit
(`CameraRig.end_follow_wait()`, see [Camera](camera.md#follow-mode)).

`cancel()` forgets the press under way: a click not yet released does not run to its point, a run that the held button
or the keys with the right button drive stops smoothly (also in `FOLLOW_POINT` mode: it does not run on to the last
point), and a hidden cursor appears where the aim was. A button that stays held counts only from its next press; the
keys with the right button are read every tick and walk again at once. A run to a clicked point belongs to the mover and
goes on (`NavigationMover.halt()` stops it too). The playable hero calls it before a teleport and when its controls are
taken away.

The component checks at startup that its input actions exist and reports a missing one as an error. A missing action
is not read afterwards: its keys or buttons do nothing, and the engine reports nothing more. Without some of the
movement keys, the others still walk. `CharacterActionInput` and the camera rig do the same.

## CharacterActionInput

| Property | Default | Meaning |
|---|---|---|
| `character` | — | The `GroundCharacter` to command |
| `sprint_action` | `sprint` | Shift |
| `jump_action` | `jump` | Space |
| `sprint_mode` | `HOLD` | `HOLD`: sprint while the key is held. `TOGGLE`: a press turns sprinting on, the next one off; it also turns off by itself when the character is exhausted and does not come back after rest |

The component only passes input on; the character decides whether there is stamina for a sprint and whether it can
jump now. It runs in the physics tick before the character (`process_physics_priority = -1`), so a press and a
release reach the character without an extra tick of delay. `is_sprint_toggled()` tells the `TOGGLE` state.

### Shift does not stick

In `HOLD` mode the sprint request is read every physics tick, so releasing Shift normally ends it immediately.
Sometimes a release never reaches an embedded Game tab or is intercepted by the system. When every key bound to
`sprint_action` is a modifier (Shift, Ctrl, Alt or Meta), `CharacterActionInput` also checks the modifiers carried by
later mouse and keyboard events and releases a stale sprint press. It reads the current bindings, so rebinding during
play is covered. For non-modifier sprint bindings, only the regular action state is available.

---

*This page matches Iso & Orbit 1.2.0.*
