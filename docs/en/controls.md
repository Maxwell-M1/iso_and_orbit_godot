# Controls

[← Documentation index](index.md)

Mouse and keyboard; there is no gamepad support. Most of the behavior below can be changed in the settings window
(F10), see [Settings](settings.md). How the input works inside: [Input](systems/input.md).

The keys and buttons on this page, and everywhere else in this documentation, are the demo's defaults, set in Project
Settings → Input Map. The hints in the game, in the settings window and on the loading screen name the keys bound
there now: after a change they name the new ones (see [Key names in texts](systems/ui.md#key-names-in-texts)).

| Input | Action |
|---|---|
| Left click on the ground | Run to that point around obstacles; a marker appears on the ground |
| Hold the left button | Run after the cursor; the cursor hides while you run |
| Hold the left button, then the right one | Look around on the run: the mouse turns the camera, and the hero keeps its course. Release the right button and steer on with the mouse |
| Hold the right button, then the left one, or both at once | Run where the camera looks. Turn the camera with the mouse and the hero turns with it. A / D veer diagonally forward. Release the left button to stop, or both buttons in any order |
| Right button + mouse | Orbit the camera around the hero; the cursor returns to its place afterwards |
| Right button + WASD | Move relative to the camera, sidestepping or turning (see below). Release the keys or the button to stop |
| Mouse wheel | Lower the camera closer to the hero or raise it higher and farther |
| Shift | Sprint while held, or toggle with a press (a setting). With fatigue on, as long as stamina lasts; the stamina bar is at the bottom of the screen |
| Space | Jump |
| E | On a teleport pad: travel to the place it leads to. A click on the offer does the same |
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

While the left button is held and the camera turns on its own (follow mode), the cursor moves with the world and stays
over the spot you aimed at, so the hero keeps its course. So does a turn of the camera with the right button while you
look around on the run. Settings → Camera → **The cursor keeps its aim while the camera turns**.

## Both buttons: what happens when

The right button always turns the camera. Whether it also steers the run depends on the order of the presses. With
the default settings:

| You press | The hero | The camera |
|---|---|---|
| The left button, held | Runs straight toward the cursor | Stays where it is (the follow is off by default) |
| ...then the right button too, and move the mouse | Keeps running the same way: looking around does not steer. The keys do nothing meanwhile | Orbits around the hero |
| ...then release the right button, the left one still held | Runs on the same way. The hidden cursor is over the spot it aimed at, and the mouse steers on from there | Stays as you left it |
| ...or release the left button first | Stops smoothly; the cursor appears over the spot it aimed at when you release the right button | Orbits until you release the right button |
| The right button, then the left one, or both within 0.2 s | Runs where the camera looks and turns with it; A / D veer diagonally forward | Turns with the mouse |
| ...then release the right button, the left one still held | Keeps the camera's course until you move the mouse; then the cursor, put 4 m ahead of the hero, steers | Stays as you left it |
| ...and press the right button again before you move the mouse | Runs where the camera looks again. Once the mouse has moved and the cursor steers, the right button looks around instead | Turns with the mouse |
| Release the left button | Stops smoothly, in about a quarter of a second. With the right button and W held, walks on by the keys instead | — |
| Release both buttons, in any order and with any gap, the mouse still in between | Stops on its course, without turning toward the cursor | — |
| A click, then the right button | Runs on to the clicked point | Orbits around the hero |
| The right button and WASD | Walks relative to the camera, turning to face the way it goes | Turns with the mouse |

To go from looking around to running where the camera looks without a stop, press the left button again while
holding the right one.

### What the settings change

- **RMB while running with LMB only turns the camera** (Controls), off: the right button steers the run in any order.
  Pressed during a run after the cursor, it turns the hero at once to where the camera looks.
- **The cursor keeps its aim while the camera turns** (Camera), off: while you look around, the cursor stays in place
  on the screen, so the run turns with the camera, along an arc. A camera that follows the run turns it the same way.
- **Held LMB → To the point along a path** (Controls): the hero runs to the point under the cursor along a path. While
  you look around, and after it until you move the mouse, the point it runs to stays where it was relative to the
  hero, not under the cursor: seen from another side, the cursor may be over the ramp or the platform. Release the left
  button and the hero runs on to the last point.
- **Hide the cursor while running with LMB held** (Controls), off: after you look around, the cursor jumps from where
  it was before to the spot it aimed at, which has moved on the screen with the turn of the camera.
- **Turn the camera to follow the run**, **Align the camera tilt on the run**, **Align the camera height on the run**
  (Camera): the camera eases behind a run after the cursor or to a clicked point, but not while the right button is
  held. After you turn it with the right button, also while looking around on the run, it stays as you left it until
  the hero stops or you start a new run with the left button (a click to a new point or a new hold). Walks by the keys
  are never followed: the keys need the right button.
- **RMB + WASD** and **LMB + RMB + A/D** (Controls): how the keys move the hero, see below.

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

A mode set to **Off** also removes its line from the controls hint. What the buttons do together with the keys:
[Both buttons: what happens when](#both-buttons-what-happens-when).

The movement keys use the physical positions of WASD on a US QWERTY keyboard. Their displayed letters follow the
keyboard layout; for example, the same positions are ZQSD on AZERTY. Change bindings in Project Settings → Input Map;
the demo does not yet have an in-game rebinding menu.

## Camera

- **Orbit:** right button and mouse. Vertical movement also tilts the camera if Settings → Camera → **RMB tilts the
  camera up and down** is on (off by default).
- **Zoom:** the wheel changes the distance and the tilt together. Below the middle the camera levels out quickly, so
  you see what lies ahead.
- **Follow** (off by default): Settings → Camera → **Turn the camera to follow the run**, **Align the camera tilt
  on the run** and **Align the camera height on the run**. The camera does not follow while the right button is
  held, or during the first 0.2 s of a left button press. After you turn the camera with the right button, also
  while looking around on the run, it stays as you left it until the hero stops or you start a new run with the left
  button (a click or a hold): it does not swing around while the hero brakes or runs on to a clicked point. The keys
  need the right button, so walks by the keys are never followed.
- **Obstacles:** the camera stops at a mountain, a wall or a roof behind it. Optionally it moves in when an obstacle
  hides the hero. Behind obstacles the hero shows as a silhouette.

Details: [Camera](systems/camera.md).

## Teleport

A glowing pad by the Ancient Circle leads to Lonely Isle, and a pad on the island leads back. Step onto it and the
offer "E Teleport to …" appears at the bottom of the screen; walking off the pad hides it. Press E (with Shift held
too, after a sprint onto the pad) or click the offer:
the loading screen covers the change, and the hero arrives beside the other pad, the camera behind it, with the
controls back. A left button held across the change counts only from its next press; keys still held (the right
button with W, A, S or D, or Shift) work again at once. Details: [Levels](systems/levels.md).

## Sprint and jump

- **Sprint:** 1.5 times faster while Shift is held and the hero is moving. With fatigue, stamina lasts 5 s; when it
  runs out, the hero runs at normal speed until it recovers to 30%, then sprints again by itself if Shift is still
  held. Standing still with Shift held spends nothing. In the toggle mode a press turns sprinting on and the next one
  off; it also turns off when the hero is exhausted.
- **Jump:** 1 m high. A jump pressed shortly before landing fires on landing; a jump pressed shortly after walking off
  an edge still works. The ledge guard does not stop a jump off an edge.

Details: [Locomotion](systems/locomotion.md).

---

*This page matches Iso & Orbit 1.2.0.*
