# Tests

[← Documentation index](index.md)

The tests run the main scene headless, with real input events and real physics, and compare measurements with
expectations.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Here `godot` is your Godot 4.7.2 executable. On Windows use the `_console.exe` build: the regular one detaches from
the terminal, so you see no output and get no exit code. On a fresh clone, import the project once first, in the
editor or with `godot --headless --path . --import`.

You can use the executable's full path instead of adding it to PATH. In PowerShell a quoted path needs `&`:

```powershell
& 'C:\path\to\Godot_console.exe' --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Replace the example path with your installed Godot 4.7.2 console executable and run from this project's root.

Only some suites, for example while working on the camera: parts of their names after `--`.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

The exit code is 1 if any check fails. At the end the runner prints how many checks passed and failed in each suite.

## Suites

Suites run in the order listed in `tests/run_checks.gd`, sharing one main scene. Choose the ones related to your
change; use the full run before integrating changes across systems.

| Suite | Main checks |
|---|---|
| `movement_checks.gd` | Acceleration, braking, retargeting, turning, reachable and unreachable destinations, routes around obstacles, ramps and ledges |
| `world_checks.gd` | Navigation through the demo terrain, discovery areas, static NPC collisions and hero-display models |
| `hero_look_checks.gd` | Switching all ten hero models, equipment placement, silhouettes and hand movement |
| `character_actions_checks.gd` | Sprint and fatigue, hold/toggle input, rebinding and modifier release, jump buffering/coyote time, fall overrides, character signals and sounds |
| `character_state_checks.gd` | Setup warnings, state and animation data, stairs/slopes, teleportation, floating, interpolation, stopped game time and the monitor panel |
| `input_checks.gd` | Click versus hold, both-button order, both hold modes, key modes, cursor capture, cancellation and missing input actions |
| `camera_checks.gd` | Orbit/zoom and follow at different frame/tick rates, sharp turns, runs toward the camera, manual-orbit wait, pitch/zoom/height alignment and teleportation |
| `camera_arm_checks.gd` | Obstacle clearance, collision layers, ignored groups, optional occlusion pull-in and fading near the target |
| `settings_window_checks.gd` | Pause and focus, every settings tab, property mapping, dependent controls, interface scale, reset and closing |
| `localization_checks.gd` | Translation coverage, preserved action tokens, language changes, names for all 12 rebound actions, open tooltips/windows/loading tips and translation inheritance |
| `level_checks.gd` | Spawn points, travel offers, loading progress and pause, scene replacement, preserved hero state and failure recovery |

For the documented input/camera configurations, start with `movement`, `character_actions`, `input`, `camera` and
`settings_window`. The filter `camera` selects both camera suites. When copying the hero into another project, also
follow the [transfer checklist](integration.md#taking-the-demos-hero-into-your-project): passing this repository's
suite does not prove that every required file and project setting was copied.

## How the tests behave

- They run with the default settings and save nothing: the player's settings are reset to the defaults for the run
  and never overwritten.
- Each check restores what it changed. The suites run one after another on one main scene, while a suite run alone
  gets a fresh one, and a check must pass in both cases. After each check `Engine.time_scale` goes back to 1, so a
  check that crashed while time was slowed or stopped does not leave it so for the next ones.
- Any engine or script error or warning also fails the run: a `Logger` added with `OS.add_logger()` counts them, and
  the runner prints the count as "engine and script errors" and adds it to the failures. A crashed check is cut short
  but the others carry on, and without the counter the crash would pass unnoticed. Only an error a check provokes on
  purpose and announces beforehand (`expect_error()` of the runner, then `take_expected_errors()` to see that it came)
  does not count, as in the check of a scene that cannot be a level. Under heavy CPU load Jolt may add a warning of
  its own, see [Known issues](known-issues.md#tests).
- A run that hangs fails after 1200 s of game time. While a level loads in the background, the frames without a
  window run much faster than on a screen, and game time with them; the level checks wait for a change by real time.
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
| `_error_count()` | How many engine and script errors have come so far, except the expected ones: a check compares the count before and after what it does |
| `_tree.call(&"expect_error", "part of the message")`, `_tree.call(&"take_expected_errors")` | Methods of the runner, not of `check_suite.gd`: the first announces an error the check provokes on purpose, so that it does not count; the second returns the announced errors that have not come and stops expecting them |
| `_find_non_finite(found)` | Collects the 3D nodes of the main scene whose transform is not finite (INF or NaN) |
| `_same_values(a, b)` | Whether two arrays hold the same values; unlike `==`, it does not take a NaN for the same as a NaN |
| `_median()`, `_min()`, `_max()`, `_first_time_at_most()` | Statistics over recorded values |

Do not name the classes that reach the `Settings` autoload (the settings window controls) as types in test scripts.
Test scripts are compiled before the autoload names exist, so such a class fails to compile and breaks the whole game
for that run. Get the settings node with `_tree.root.get_node(^"Settings")` and use duck typing.

---

*This page matches Iso & Orbit 1.2.0.*
