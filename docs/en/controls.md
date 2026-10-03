# Controls

Mouse and keyboard; there is no gamepad support. Most of the behavior below can be changed in the settings window
(F10), see [Settings](settings.md). How the input works inside: [Input](systems/input.md).

| Input | Action |
|---|---|
| Left click on the ground | Run to that point around obstacles; a marker appears on the ground |
| Hold the left button | Run after the cursor; the cursor hides while you run |
| Left + right button, in any order | Run where the camera looks. Turn the camera with the mouse and the hero turns with it. A / D veer diagonally forward. Release the left button to stop |
| Right button + mouse | Orbit the camera around the hero; the cursor returns to its place afterwards |
| Right button + WASD | Move relative to the camera, sidestepping or turning (see below). Release the keys or the button to stop |
| Mouse wheel | Lower the camera closer to the hero or raise it higher and farther |
| Shift | Sprint while held, or toggle with a press (a setting). With fatigue on, as long as stamina lasts; the stamina bar is at the bottom of the screen |
| Space | Jump |
| F10 | Settings (pauses the game); Esc or F10 closes them |

## Click or hold

Whether a press is a click or a hold is decided after 0.2 s.

- **Click** (released sooner): the hero runs along a path to the point where you pressed, even if the mouse moved
  afterwards, and a marker appears there. The run starts on release. The marker fades when the hero arrives or when
  you take over with a hold or the keys.
- **Hold** (held longer): the hero runs after the cursor at once and never turns toward the point where you pressed.

Until the decision, the hero keeps doing what it was doing.

How the hero follows a held button (Settings → Controls → **Held LMB**):

- **Straight to the cursor** (default): no path search. The hero slides along obstacles and runs up the ramp
  wherever you point it, and stops smoothly on release.
- **To the point along a path**: the hero follows a navigation path to the point under the cursor. Near height
  changes (the ramp, the platform) the path can jump between routes. On release the hero runs on to the last point.

While a held button turns the camera (follow mode), the cursor moves with the world and stays over the spot you aimed
at, so the hero keeps its course. Settings → Camera → **The cursor keeps its aim while the camera turns**.

## Keys with the right button

WASD work only while the right button is held. Without it they do nothing. The mode is chosen separately for the right
button alone (**RMB + WASD**) and for both buttons (**LMB + RMB + A/D**), each with **Off** and two variants:

| | Sidestep | Turn / diagonal (default) |
|---|---|---|
| RMB + W | forward, where the camera looks | the same |
| RMB + A / D | sideways, facing forward | turns left / right and goes there |
| RMB + S | backward, facing forward, slower | turns around and walks toward the camera |
| Two keys (W + A, S + D…) | diagonally, facing forward | diagonally, facing the way it goes |
| LMB + RMB + A / D | diagonally forward, facing forward | diagonally forward, facing the way it goes |

Diagonal movement is as fast as straight movement. Backing up is 30% slower by default (3.85 m/s instead of 5.5;
Settings → Controls → **Backing up (S) slower by**). Moving diagonally backward is slowed partly (S + D sidestepping:
21%), sideways not at all, so the slowdown exists only in the sidestep mode.

After a stop the hero keeps facing where it faced; a click or a hold turns it to face the way it runs again.

Holding the right button alone, without keys, does not interrupt a run to a clicked point, so you can turn the camera
on the run. Release the left button while the right button and W are held and the hero keeps walking by the keys
without stopping. A mode set to **Off** also removes its line from the controls hint.

The keys are bound by physical position, so they are WASD on any keyboard layout.

## Camera

- **Orbit:** right button and mouse. Vertical movement also tilts the camera if Settings → Camera → **RMB tilts the
  camera up and down** is on (off by default).
- **Zoom:** the wheel changes the distance and the tilt together. Below the middle the camera levels out quickly, so
  you see what lies ahead.
- **Follow** (off by default): Settings → Camera → **Turn the camera to follow the run** and **Align the camera
  tilt**. The camera does not follow while the right button is held, or during the first 0.2 s of a left button
  press.
- **Obstacles:** the camera stops at a mountain, a wall or a roof behind it. Optionally it moves in when an obstacle
  hides the hero. Behind obstacles the hero shows as a silhouette.

Details: [Camera](systems/camera.md).

## Sprint and jump

- **Sprint:** 1.5 times faster while Shift is held and the hero is moving. With fatigue, stamina lasts 5 s; when it
  runs out, the hero runs at normal speed until it recovers to 30%, then sprints again by itself if Shift is still
  held. Standing still with Shift held spends nothing. In the toggle mode a press turns sprinting on and the next one
  off; it also turns off when the hero is exhausted.
- **Jump:** 1 m high. A jump pressed shortly before landing fires on landing; a jump pressed shortly after walking off
  an edge still works. The ledge guard does not stop a jump off an edge.

Details: [Locomotion](systems/locomotion.md).

---

*This page matches Iso & Orbit 1.0.0.*
