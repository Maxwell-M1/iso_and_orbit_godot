# Input

Two nodes turn player input into commands. Neither moves anything itself.

- `PointClickMoveInput`: the mouse, and WASD with the right button held → `NavigationMover.move_to()`, `steer()`
  and `stop()`.
- `CharacterActionInput`: sprint and jump keys → `GroundCharacter.sprint_requested` and `jump()`.

Both live in `main.tscn`, not in the character scene, so the same character can be driven by AI instead. For the
player's view of the controls, see [Controls](../controls.md).

## PointClickMoveInput

| Input | Command |
|---|---|
| Click on the ground | `move_to(point)`: a ray from the camera on `ground_mask` finds the point |
| Left button held | `steer()` toward the cursor, or `move_to()` the point under it, depending on `hold_mode` |
| Left and right buttons held | `steer()` where the camera looks; A and D veer diagonally forward (`keys_with_camera_steer`) |
| Right button and WASD | `steer()` relative to the camera, sidestepping or turning (`keys_with_camera`); `stop()` on release |

Who drives the character in a tick is decided in one place, `_physics_process`: a held left button first, else the
keys with the right button. So releasing the left button while the right button and W are held does not stop the
character: the keys take over at once.

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
click or a hold, `hold_pending_changed(true)` pauses the camera's follow mode, so a short click never moves the
camera.

If the right button is already held when the left one is pressed, there is no click: the character runs after the
camera at once.

### Hold modes

`hold_mode` (Settings → Controls → **Held LMB**):

- `STEER` (default): straight toward the cursor, without a path. The character slides along obstacles and runs up
  the ramp wherever you point it. Within `steer_dead_zone` (0.5 m) of the character the direction does not change:
  so close, it is too sensitive to the cursor. On release the character stops smoothly.
- `FOLLOW_POINT`: to the point under the cursor along a navigation path. The path is rebuilt while the point moves,
  so near height changes (the ramp, the platform) it can jump from one route to another. On release the character
  runs on to the last point and the marker shows it (`destination_picked`); with `stop_on_release` it brakes to a
  stop where it is.

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

The script default is `SIDESTEP` for both; the demo's settings default to `TURN` for both.

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
touch it) and reappears on release where you aimed. The mouse mode meanwhile is `MOUSE_MODE_CONFINED_HIDDEN`: a plain
hidden cursor could leave the window and appear at its edge. On macOS the engine confines the cursor by moving it on its
own and counts every move that keeps the aim (below) a second time, so the aim drifts off. There the mode is
`MOUSE_MODE_HIDDEN`. The hidden system cursor does not follow the aim on any system: nobody sees it, and in the editor's
Game tab on macOS each such move reaches it a frame or two late, so the character would twitch on turns. The component
moves its own cursor by the mouse movement, returns the system cursor to the center of the window when it reaches the
edge, and on release puts it where you aimed. While the right button orbits the camera, the camera captures the cursor;
release the right button with the left one still held and the cursor is hidden again. Pausing (the settings window) or
switching to another window shows it at once. `is_cursor_hidden()` tells whether the component has hidden it.

**Keeps its aim** (`keep_aim_on_camera_turn`, on by default). While the left button is held, the running direction comes
from the cursor, a point on the screen. If the camera turns while the cursor stays still on the screen, a different spot
of ground is under the cursor, the character turns after it, the camera turns after the character, and the character
runs in circles (77.6° in 1.25 s with the demo's 1.1 s catch-up time; with "instant" it just spins). So while the button
is held, the component moves the cursor with the world (the visible system cursor with `Viewport.warp_mouse()`, a hidden
one only on release): the cursor stays over the same spot of ground, the character runs where you aimed, and the camera
eases behind it. Moving the mouse turns the character as usual. After release the cursor is left alone.

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
| `camera_steer_action` | `camera_rotate` | With it held, a hold runs where the camera looks; empty disables |
| `ground_mask` | layer 1 | Physics layers you can click on. Must not include the characters' layer |
| `hold_delay` | 0.2 s | When a press becomes a hold |
| `steer_dead_zone` | 0.5 m | `STEER`: no direction change with the cursor this close to the character |
| `stop_on_release` | off | `FOLLOW_POINT`: brake to a stop on release instead of running on to the last point |
| `ray_length` | 1000 m | Length of the ray from the camera |
| `keys_with_camera` | `SIDESTEP` | RMB + WASD mode |
| `keys_with_camera_steer` | `SIDESTEP` | LMB + RMB + A/D mode |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | The keys |

Signals: `destination_picked(point)`, `hold_started`, `hold_pending_changed(pending)`.

The component checks at startup that its input actions exist and reports a missing one as an error.

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

In `HOLD` mode the sprint is read every tick from `Input.is_action_pressed()`, so releasing Shift ends it. This is
checked with real events: on the run, while running with the left button held, releasing it in the settings window,
after switching modes.

But the release itself sometimes never reaches the game, and the engine considers Shift held until it is pressed
again. This happens when the game is embedded in the editor's Game tab and the focus moves to the editor
(`Input.release_pressed_events()` skips the reset while the editor window has focus), or when a system shortcut
swallows the release. For this case the component checks the sprint against the real state of Shift that every mouse
and keyboard event carries (`shift_pressed`; on Windows it comes from `GetKeyboardState`). If any mouse or keyboard
event other than the sprint key itself says Shift is up, the stuck press is released. This works when every key
bound to the sprint action is a modifier (Shift, Ctrl, Alt, Meta).

If Windows turns on Sticky Keys (five Shift presses in a row), Shift sticks in the system itself; turn that off in
the Windows settings.

---

*This page matches Iso & Orbit 1.0.0.*
