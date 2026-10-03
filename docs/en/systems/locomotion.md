# Locomotion

How a character runs, stops, turns, sprints, jumps and keeps away from drops. Four classes, from the bottom up:

| Class | Kind | Job |
|---|---|---|
| `LocomotionSettings` | Resource | Speed, acceleration, braking, turning |
| `GroundMotion` | RefCounted | The math: desired direction and distance left → horizontal velocity |
| `NavigationMover` | Node, child of the body | Paths and commands; returns a velocity, never moves the body |
| `GroundCharacter` | CharacterBody3D | Gravity, jump, sprint, `move_and_slide()`, turning the model |

Two helpers plug into the body: `Stamina` (the sprint reserve) and `LedgeGuard` (no walking off drops).

## How running feels

- **Constant acceleration and braking.** Speed changes at a fixed rate, from `acceleration_time` and `stop_time`.
- **An exact stop.** Near the target the speed is limited to `√(2 · braking · distance left)`: the character starts
  braking exactly where it can still stop at the point, and never overshoots it.
- **No reset on a new target.** A new click while braking keeps the current speed; the character accelerates again
  from there.
- **Limited turn rate.** On the run the direction turns at `turn_speed`. While the direction has not caught up,
  `turn_slowdown` takes off some speed, so a sharp turn is a tight arc, not a wide drift.
- **Instant turn from a standstill.** Below `pivot_speed` the character turns at once, so a start in any direction
  has no arc and no delay.
- **Hard braking when needed.** If the stop point is set right in front of a running character, it may brake up to
  `max_braking_multiplier` times harder than usual.

## LocomotionSettings

The demo uses `gdscript/player/player_locomotion.tres`. It changes two of the script defaults.

| Property | Demo | Script default | Meaning |
|---|---|---|---|
| `max_speed` | 5.5 m/s | 5.5 m/s | Running speed |
| `acceleration_time` | 0.35 s | 0.18 s | From standstill to `max_speed` |
| `stop_time` | 0.4 s | 0.22 s | From `max_speed` to a stop; the braking distance is `max_speed × stop_time / 2` (1.1 m in the demo) |
| `turn_speed` | 720 °/s | 720 °/s | How fast the running direction turns |
| `turn_slowdown` | 0.75 | 0.75 | Speed lost while the direction catches up: 0 keeps the speed (wide arc), 1 brakes to zero for a turn of 90° or more |
| `pivot_speed` | 1 m/s | 1 m/s | Below this the character turns instantly |
| `max_braking_multiplier` | 3 | 3 | How much harder than usual the character may brake for a point right in front of it |
| `sprint_speed_multiplier` | 1.5 | 1.5 | Speed limit while sprinting (8.25 m/s); acceleration and braking stay the same |
| `backward_speed_multiplier` | 0.7 | 0.7 | Share of the speed left when moving backward (facing against the movement) |

The settings window changes `sprint_speed_multiplier` and `backward_speed_multiplier` at runtime. The rest are tuned
in the resource. To tune while the game runs: Scene dock → Remote → `Player/NavigationMover` → `settings`. The code
reads them every tick, but changes made there are not saved, so copy the result into the `.tres` file.

One resource can be shared by several characters, for example all NPCs of one kind.

## NavigationMover

A child of the body (any `Node3D`, usually a `CharacterBody3D`). Two modes:

- `move_to(point)`: to a point along a navigation path, around obstacles, with an exact stop. The path comes from
  `NavigationServer3D` for the body's world. Without a navigation map the character runs straight at the point.
- `steer(direction, facing = Vector3.ZERO)`: in a direction, without a path, until `stop()`, `halt()` or
  `move_to()`. Obstacles are handled by the body sliding along them. With `facing`, the character looks that way
  while moving: sidestepping and backing up. The facing stays after a stop, until a command without it.

The body calls `compute_velocity(delta)` once per physics tick, before `move_and_slide()`.

| Property | Default | Meaning |
|---|---|---|
| `settings` | — | `LocomotionSettings`; defaults if empty |
| `use_navigation` | on | Search a path; off, or no navigation in the world: run straight to the point |
| `navigation_layers` | 1 | Navigation layers the path may use |
| `waypoint_radius` | 0.4 m | A path point counts as passed closer than this; larger cuts corners earlier |
| `arrive_distance` | 0.005 m | Closer than this to the end the character stops at once. Braking itself brings it to the point, so the threshold is tiny |
| `retarget_tolerance` | 0.1 m | A new point closer than this to the current one does not rebuild the path. A held button sends a point every tick |
| `max_path_deviation` | 2 m | Pushed farther than this off the path, the character gets a new path |
| `sprinting` | off | Raise the speed limit by `sprint_speed_multiplier`. The owner decides when |

Signals: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled`.

**Path points are compared in the horizontal plane.** A Recast navigation mesh hangs above the ground by about two
cell heights (0.05 m here). Comparing 3D distances with the character's feet would be off by that much, which is why
the mover follows the path itself instead of using `NavigationAgent3D`.

**Backing up is slower.** When `steer()` gets a `facing`, the speed is scaled by how much the movement opposes the
facing: straight back gets the full `backward_speed_multiplier`, diagonally back a part of it (S + D while
sidestepping: 21% slower), sideways none. So the slowdown exists only in the sidestep mode of the keys, see
[Input](input.md).

## GroundCharacter

The only place where the body moves. In each physics tick it updates the sprint state, takes the horizontal velocity
from the mover, handles the jump and gravity, lets `LedgeGuard` correct the velocity, calls `move_and_slide()`,
reports steps and landings and turns `visual` toward `mover.get_facing()`.

| Property | Default | Meaning |
|---|---|---|
| `mover` | — | The `NavigationMover`; required |
| `visual` | — | The node turned to face the way the character goes; its front is −Z |
| `visual_turn_speed` | 1080 °/s | How fast the model turns |
| `gravity_scale` | 3 | Gravity multiplier. The character runs faster than a person and would float down at normal gravity: a 1.6 m drop takes 0.33 s instead of 0.57 s |
| `ledge_guard` | — | Optional `LedgeGuard`; without it the character falls from any height |
| `can_sprint` | on | Sprinting allowed. Turned off on the run, the extra speed is braked away |
| `stamina` | — | Optional `Stamina`; without it sprinting never tires |
| `sprint_tires` | on | Sprinting spends stamina |
| `sprint_duration` | 5 s | How long a full reserve lasts: spends `max_value / sprint_duration` per second |
| `can_jump` | on | Jumping allowed; off, `jump()` does nothing |
| `jump_height` | 1 m | Height of the feet at the top of the jump |
| `coyote_time` | 0.1 s | A jump still works this long after walking off an edge |
| `jump_buffer_time` | 0.12 s | A jump pressed this long before landing fires on landing |
| `landing_min_speed` | 2.5 m/s | Slower falls (a step down, a ramp) do not count as landings |
| `stride_length` | 1.5 m | Distance on the ground between steps |
| `first_step_distance` | 0.3 m | Distance from a standstill to the first step |

Set `sprint_requested` to ask for a sprint and call `jump()` to jump. `CharacterActionInput` does both for the
player; AI can do the same.

### Signals

| Signal | When |
|---|---|
| `stepped(sprinting)` | A foot touched the ground: every `stride_length` covered on the ground, the first one `first_step_distance` from a standstill. Steps follow the distance, not time: about 3.7 per second running, 5.5 sprinting, none standing against a wall or in the air |
| `jumped` | The character pushed off the ground |
| `landed(impact_speed)` | The character landed; `impact_speed` is the fall speed in m/s |
| `sprint_changed(sprinting)` | Sprinting started or stopped |

`get_step_phase()` returns the step rhythm as a number of steps taken: an integer at each step, the fraction growing
from 0 to 1 with the distance between steps. `HandSway` uses it; an animation can too. Other queries:
`is_sprinting()`, `is_exhausted()`, `get_jump_speed()`.

### The jump

The take-off speed is `v = √(2·g·h)`. In the take-off tick the body gets `v − g·dt/2`: then its positions at every
tick lie exactly on the parabola, and the jump height does not depend on the tick rate. With plain `v` the jump would
be `v·dt/2` higher, 1.064 m instead of 1 m at 60 ticks. In the demo a 1 m jump takes 0.52 s with `gravity_scale` 3.

In the air the character keeps running as it was, and the controls stay the same. The ledge guard does not hold a
jump: jumping off a platform edge is a deliberate step, not an accident.

## Sprint and stamina

While sprint is requested and the character is being driven (a click, a held button, both buttons, keys), it runs
`sprint_speed_multiplier` times faster and spends stamina. Standing still with Shift held spends nothing. When the
reserve runs out, the character is exhausted: it runs at normal speed until stamina recovers to `recover_ratio`, and
then sprints again on its own if Shift is still held.

`Stamina` knows nothing about what spends it:

| Property | Default | Meaning |
|---|---|---|
| `max_value` | 100 | Full reserve |
| `recovery_rate` | 12.5 per second | From empty to full in 8 s |
| `recovery_delay` | 1 s | Recovery starts this long after the last spending |
| `recover_ratio` | 0.3 | An exhausted character sprints again after recovering this share (1 + 2.4 s) |

Methods: `spend(amount)`, `can_spend()`, `get_ratio()`, `is_exhausted()`, `refill()`. Signals: `changed(ratio)`,
`exhausted_changed(exhausted)`. The HUD's `StaminaBar` listens to them.

## LedgeGuard

Keeps the character from walking off a drop. The body calls `constrain(velocity, delta)` before `move_and_slide()`.
If the body would end the tick over a drop, the movement is turned along the edge to the nearest direction with
ground under it and shortened by the cosine of the turn, exactly like sliding along a wall. Running straight at the
edge stops the character.

| Property | Default | Meaning |
|---|---|---|
| `enabled` | on | Guard edges |
| `max_drop` | 0.5 m | A lower drop is a step and can be walked down; a higher one is a ledge |
| `edge_margin` | 0.15 m | How close the character's center may come to the edge |
| `margin_probes` | 6 | Rays around the `edge_margin` circle |
| `probe_height` | 0.5 m | Rays start this high above the feet, to find ground slightly above them (a ramp) |
| `floor_mask` | layer 1 | What counts as ground |
| `slide_iterations` | 6 | Halvings of the slide angle; 6 gives about 1.4° |

On open ground that is 7 rays per tick, up to 98 at an edge. In the air the guard does nothing. A path from the
platform down follows the ramp, and the guard does not get in its way.

## Measured behavior

The tests (`tests/movement_checks.gd`, `tests/character_actions_checks.gd`, `tests/camera_checks.gd`) measure the
demo's settings at 60 physics ticks. Their limits are computed from the settings, so you can change them.

- 95% of full speed in 0.33 s; from 95% to a stop in 0.35 s; the stop is exactly at the clicked point.
- A new click farther away while braking: from 2.66 m/s the speed grows again at once, never dropping to zero.
- A click behind the character at full speed: it carries on 0.34 m, the arc goes 0.63 m sideways, and after 0.28 s
  it runs back.
- Straight at the platform edge: a stop 0.15 m from the edge at zero speed. At 45°: a slide along the edge at
  3.89 m/s (5.5 × cos 45°, as along a wall) to the platform's corner, at the same height. Without the guard: a fall
  of 1.6 m in 0.35 s.
- Sprint: 8.25 m/s. With `sprint_duration` 2 s (50 per second), stamina runs out after 2.02 s, then 5.5 m/s; 3.38 s
  later the character has recovered (1 + 2.4 s) and sprints at 8.25 m/s again with Shift still held.
- Jump: top at 1.000 m, 0.517 s in the air (0.522 by the formula). Pressed 0.4 m above the ground, the jump fires in
  the tick after landing; pressed at the top, it is forgotten. Space 3 ticks after walking off an edge jumps, 9 ticks
  after does not.

---

*This page matches Iso & Orbit 1.0.0.*
