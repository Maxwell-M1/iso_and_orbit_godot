# Tests

The tests run the main scene headless, with real input events and real physics, and compare measurements with
expectations.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Here `godot` is your Godot 4.7.2 executable. On Windows use the `_console.exe` build: the regular one detaches from
the terminal, so you see no output and get no exit code. On a fresh clone, import the project once first, in the
editor or with `godot --headless --path . --import`.

Only some suites, for example while working on the camera: parts of their names after `--`.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

The exit code is 1 if any check fails. At the end the runner prints how many checks passed and failed in each suite.

## Suites

The suites run in the order of `SUITES` in `tests/run_checks.gd`, on one instance of the main scene.

| Suite | What it covers |
|---|---|
| `movement_checks.gd` | Acceleration and an exact stop, a new click while braking, a turn while braking, a reversal at full speed. Routes: around the trap, through the gap in the wall, the maze, up and down the ramp, onto the platform from the ramp's sides, an unreachable point on a crate. The ledge guard, and falling without it |
| `world_checks.gd` | The mountain: a path from the ground to the top along the trail, the place is discovered once with its message, the slope cannot be climbed off the trail, the guard holds on the trail. The camp, the farmstead and the ruins are discovered with their messages. The NPCs: five with equipment and labels, someone at every place, all standing on the ground, paths go around them, nobody walks through them. The hero looks: ten by number, each with a body, eyes and a staff in the right hand; the walkway along the row is passable at full speed |
| `hero_look_checks.gd` | The player's model: the staff in the right hand while turning; separate silhouette chains for the body and the equipment, also on meshes added later; the outline setting. The hand swing: still when standing; swinging and dipping on the run with the extremes on the steps, in turn; lagging on acceleration; returning after a stop; dipping on landing. The hero look: the default at startup; each of the ten set at runtime with one model, the staff swinging in the new hand and the silhouette on the new meshes |
| `character_actions_checks.gd` | Sprint and fatigue through the input action, the stamina bar. Releasing Shift in hold mode with real events (on the run, with the left button, in the settings window, after toggle mode, a lost release). Toggle mode. Sprint and jump turned off, sprint without fatigue. The jump: height, the buffer, coyote time, a jump off an edge with the guard on, a 1.5 m jump. Character signals: steps by distance and faster when sprinting, none standing or in the air, jump and landing with the fall speed, walking down the ramp without a landing, sprint start and end. A sound for each signal and its switches; the sprint loop loops |
| `character_state_checks.gd` | What the character reports: the states in a run and a sprint, the blend 0, 1 and 2, the movement in the model's axes for a run, a sidestep and backing up, the turn rate. A jump and a fall off an edge: the signals in order and the time in the air; no take-off down the ramp. The feet alternate, the gait cycle at the steps. The stairs east of the platform: up and down by a click without leaving the ground, almost at full speed; without stepping the first stair stops the character. A 0.4 m block, a 30° and a 50° slope. Routes on the level without a false take-off. The monitor panel: off by default, shown by the setting, the state and the events of a jump |
| `input_checks.gd` | A mouse click: no run and no marker while pressed, a run to the pressed point after release. Holding in `STEER` mode: running toward the cursor, never to the pressed point, no marker, a quick stop on release. Holding in `FOLLOW_POINT` mode: running while held; on release a quick stop with `stop_on_release`, otherwise a run to the last cursor point with its marker. Both buttons: up the ramp, turning with the camera. RMB + WASD sidestepping and turning: direction, facing and speed for W, A, D, S and key pairs; nothing without the right button or in the off mode; stopping by the keys and by the button; the right button alone does not interrupt a click. LMB + RMB + A/D in all three modes. The left button pressed and released while walking with RMB + W: the walk goes on without a stop. The keys abandon a run to a clicked point and its marker fades. The cursor hidden while running with the left button held |
| `camera_checks.gd` | Follow mode (off, instant, default, very slow) and its pauses (the right button, an undecided press). Holding the left button with and without the cursor keeping its aim. Orbit and zoom with the mouse: below the middle the wheel levels the camera fast; by default the right button does not tilt, with the setting it does, and turning it off restores the wheel's tilt. Tilt alignment on the run |
| `camera_arm_checks.gd` | Full length in the open. A cliff behind: an immediate stop; walking toward it, the camera comes closer and stays out; with the cliff gone, a return after a pause, smoothly; without the stop, the camera is in the cliff. A fence with a cliff right behind it. A fence right at the camera: the camera comes in front of it; a fence where the waiting camera stands: behind it at once. Bodies on the camera layer stop it, on the characters' layer do not. A fence halfway: behind it by default, in front of it smoothly with pull-in, a short occlusion does not count. A fence at the character: no jump to the character's back. A thin post does not count. A column grazing the arm does not move the camera. Bodies in `camera_ignore` and under a node in it. Fading up close. Walls on the level (maze, mountain, tent, summit stones): the camera does not cut into them. The settings reach the arm |
| `settings_window_checks.gd` | F10, the pause, focus, the released cursor capture; switches reach their nodes; the Controls tab (key modes, the backward slowdown slider); the Sound tab (the volume reaches the `Master` bus, the switches reach the character sounds); the Character tab (hero look, jump height, Shift mode, speed bonus, fatigue and stamina); dependent controls dim; the tilt slider stays within the camera's limits; interface scale; reset; Esc |
| `localization_checks.gd` | English by default. Every interface string, in the scenes, the open settings window and the scripts, has a translation in every language, and no translation entry is unused. Switching the language changes the texts composed by code; language names are not translated; reset returns English |

## How the tests behave

- They run with the default settings and save nothing: the player's settings are reset to the defaults for the run
  and never overwritten.
- Each check restores what it changed. The suites run one after another on one main scene, while a suite run alone
  gets a fresh one, and a check must pass in both cases.
- Any engine or script error also fails the run: a `Logger` added with `OS.add_logger()` counts them, and the runner
  prints the count as "engine and script errors" and adds it to the failures. A crashed check is cut short but the
  others carry on, and without the counter the crash would pass unnoticed. Under heavy CPU load Jolt may add a
  warning of its own, see [Known issues](known-issues.md#tests).
- A run that hangs fails after 600 s of game time.
- Before exiting, the runner removes the main scene and waits 0.1 s. With `--fixed-fps` game time runs faster than
  real time while audio plays in real time, so footsteps played just before the end are still sounding. Exiting at
  once sometimes makes the engine report leaked `AudioStreamPlayback` objects and footstep resources.
- A headless window cannot move the system cursor, so the tests see only the running direction; the cursor itself is
  checked in the game. A headless window also never changes the mouse mode (`Input.mouse_mode` is always `VISIBLE`),
  so for the hidden cursor the tests read `PointClickMoveInput.is_cursor_hidden()`.
- The limits are computed from the components' settings where possible, so tuning `LocomotionSettings` does not
  break the tests by itself.

## Writing a check

A new check is a `_check_…` function in the fitting suite plus a line in that suite's `_checks()`. A new suite is a file
`tests/<topic>_checks.gd` that extends `check_suite.gd`, plus a line in `SUITES`. `check_suite.gd` has the shared
helpers:

| Helper | Does |
|---|---|
| `_teleport(position)` | Puts the player at a point, stopped, and waits a few ticks |
| `_run_until_arrived(target, max_time)` | Commands a run and records the time, speeds, distance walked and stuck ticks until arrival |
| `_check_route(title, from, to, max_time)` | A route: arrived in time without getting stuck, and for a reachable point exactly at it, on the right floor |
| `_ticks(count)`, `_frames(count)`, `_wait_until(condition, max_ticks)` | Waiting |
| `_send_key()`, `_send_button()`, `_send_motion()` | Real input events |
| `_expect(condition, what)` | Counts a passed or failed check and prints it |
| `_median()`, `_min()`, `_max()`, `_first_time_at_most()` | Statistics over recorded values |

Do not name the classes that reach the `Settings` autoload (the settings window controls) as types in test scripts.
Test scripts are compiled before the autoload names exist, so such a class fails to compile and breaks the whole game
for that run. Get the settings node with `_tree.root.get_node(^"Settings")` and use duck typing.

---

*This page matches Iso & Orbit 1.1.0.*
