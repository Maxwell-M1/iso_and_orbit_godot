# Locomotion

[← Documentation index](../index.md)

How a character runs, stops, turns, sprints, jumps, climbs stairs and keeps away from drops. For the assembled hero and
the files needed to reuse it, start with
[Using it in your project](../integration.md#taking-the-demos-hero-into-your-project).
For ready-made control choices, see [Configurations](../configurations.md). Four classes divide the work:

| Class | Kind | Job |
|---|---|---|
| `LocomotionSettings` | Resource | Speed, acceleration, braking, turning |
| `GroundMotion` | RefCounted | The math: desired direction and distance left → horizontal velocity |
| `NavigationMover` | Node, child of the body | Paths and commands; returns a velocity, never moves the body |
| `GroundCharacter` | CharacterBody3D | Gravity, jump, sprint, `move_and_slide()`, turning the model |

Two helpers plug into the body: `Stamina` (the sprint reserve) and `LedgeGuard` (no walking off drops). A
`FallSettings` resource tells it how to fall. `CharacterMonitor` shows what the body reports as text.
`CharacterHover` makes the model float above the ground, see
[Characters](characters.md#characterhover-floating-above-the-ground).

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

These are the `LocomotionSettings` script defaults and the values in the shipped
`gdscript/player/player_locomotion.tres`. That separate resource lets the demo's settings change this hero's sprint
and backward speed without changing other characters.

| Property | Default | Meaning |
|---|---|---|
| `max_speed` | 5.5 m/s | Running speed |
| `acceleration_time` | 0.18 s | From standstill to `max_speed` |
| `stop_time` | 0.22 s | From `max_speed` to a stop; the braking distance is `max_speed × stop_time / 2` (about 0.61 m) |
| `turn_speed` | 720 °/s | How fast the running direction turns. Keep the camera's `sharp_turn_speed` at half of it or lower (see [Camera](camera.md#follow-mode)) |
| `turn_slowdown` | 0.75 | Speed lost while the direction catches up: 0 keeps the speed (wide arc), 1 brakes to zero for a turn of 90° or more |
| `pivot_speed` | 1 m/s | Below this the character turns instantly |
| `max_braking_multiplier` | 3 | How much harder than usual the character may brake for a point right in front of it |
| `sprint_speed_multiplier` | 1.5 | Multiplier of base speed while sprinting (8.25 m/s with defaults); acceleration and braking stay the same |
| `backward_speed_multiplier` | 0.7 | Share of the speed left when moving backward (facing against the movement) |

Because sprint raises only the speed limit, it takes longer and farther to stop from full sprint: about 1.36 m at
8.25 m/s with the default braking rate, versus about 0.61 m at 5.5 m/s. A clicked point very close ahead can invoke
`max_braking_multiplier` to stop sooner.

The demo's `SettingsApplier` changes `sprint_speed_multiplier` and `backward_speed_multiplier` at startup and when the
player changes a setting; saved settings can override the values above. The addon itself has no settings system. To
tune a running demo, use Scene dock → Remote → `Hero/Character/NavigationMover` → `settings`. The code reads the
resource fields every tick, but Remote inspector edits are not saved: copy the result into the `.tres` file. Use a
separate resource per character when runtime changes should not affect others. Assign it before the mover enters the
scene tree, or use **Make Unique** in the editor: after `_ready()`, `GroundMotion` holds the original resource, so
replacing `mover.settings` then does not replace the motion settings. Edit fields of the existing resource at runtime.

One resource can be shared by several characters, for example all NPCs of one kind.

## NavigationMover

A child of the body (any `Node3D`, usually a `CharacterBody3D`). Two modes:

- `move_to(point)`: to a point along a navigation path, around obstacles, with an exact stop at the path's end. The
  path comes from `NavigationServer3D` for the body's world. With an empty path result, including a world without a
  navigation mesh, the mover runs straight at the requested point.
- `steer(direction, facing = Vector3.ZERO)`: in a direction, without a path, until `stop()`, `halt()` or
  `move_to()`. Obstacles are handled by the body sliding along them. With `facing`, the character looks that way
  while moving: sidestepping and backing up. The facing stays after `stop()`; `move_to()`, `steer()` without it,
  `halt()` and `face()` clear it.

The body calls `compute_velocity(delta)` once per physics tick, before `move_and_slide()`. `stop()` brakes smoothly,
`halt()` stops at once (a teleport), and `face(direction)` turns a standing character without a run, at a spawn point
for example: the mover's heading and facing change at once, and a `GroundCharacter` turns its model after them at
`visual_turn_speed` (only `GroundCharacter.teleport(position, facing)` turns the model at once too). A run under way
turns back to where it goes.

| Property | Default | Meaning |
|---|---|---|
| `settings` | — | `LocomotionSettings`; the mover creates one with script defaults at `_ready()` if empty |
| `use_navigation` | on | Search a path; off, or no navigation in the world: run straight to the point |
| `navigation_layers` | 1 | Navigation layers the path may use |
| `waypoint_radius` | 0.4 m | A path point counts as passed closer than this; larger cuts corners earlier |
| `arrive_distance` | 0.005 m | Closer than this to the end the character stops at once. Braking itself brings it to the point, so the threshold is tiny |
| `retarget_tolerance` | 0.1 m | A new point closer than this to the current one does not rebuild the path. A held button sends a point every tick |
| `max_path_deviation` | 2 m | Pushed farther than this off the path, the character gets a new path |
| `sprinting` | off | Raise the speed limit by `sprint_speed_multiplier`. The owner decides when; a `GroundCharacter` sets it every tick, so with one set its `sprint_requested` instead |

Signals: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled`.

`arrived` means the character reached the path's end. A navigation path may end at the closest reachable point
instead of the requested destination, so compare positions if your game requires the exact requested point. A
straight fallback has no obstacle avoidance beyond the body's collision sliding.

| Query | Returns |
|---|---|
| `is_moving()` | The character is being led, to a point or in a direction. It tells the command, not the motion: true while the character still stands at the start, false while it brakes after `stop()` |
| `is_steering()` | It runs in a direction from `steer()`, not to a point |
| `has_destination()`, `get_destination()` | A point from `move_to()` is being run to (until it is reached or cancelled); that point |
| `get_speed()` | The running speed, m/s |
| `get_heading()` | Where the run is directed, a unit horizontal vector; when the character stands, where it last ran |
| `get_facing()` | Where the character should face: along the run (`get_heading()`) or where `steer()` told it to |
| `get_body()` | The body it leads, its parent |
| `get_remaining_path()` | The path points left, from the next one, at the navigation mesh height; empty when running straight |

**Path points are compared in the horizontal plane.** A Recast navigation mesh hangs above the ground by about two
cell heights (0.05 m here). Comparing 3D distances with the character's feet would be off by that much, which is why
the mover follows the path itself instead of using `NavigationAgent3D`.

**Backing up is slower.** When `steer()` gets a `facing`, the speed is scaled by how much the movement opposes the
facing: straight back gets the full `backward_speed_multiplier`, diagonally back a part of it (S + D while
sidestepping: 21% slower), sideways none. So the slowdown exists only in the sidestep mode of the keys, see
[Input](input.md).

## GroundCharacter

The only place where the body moves. In each physics tick it updates the sprint state, takes the horizontal velocity
from the mover, handles the jump and gravity, lets `LedgeGuard` correct the velocity, calls `move_and_slide()` with a
stair up before it and a stair down after it, and then reports what the tick changed: floor contact, the stair taken,
steps, the model's turn toward `mover.get_facing()` and the state.

The inspector groups the properties: the parts and the turn first, then Ground, Jump and fall, Sprint and Steps.

| Property | Default | Meaning |
|---|---|---|
| `mover` | — | The `NavigationMover`; required |
| `visual` | — | The node turned to face the way the character goes, relative to the body; its front is −Z |
| `visual_turn_speed` | 1080 °/s | How fast the model turns |
| `max_step_height` | 0.3 m | The highest stair the character steps onto without a jump, and the deepest one it steps down without leaving the ground. 0 disables stepping |
| `ledge_guard` | — | Optional `LedgeGuard`; without it the character falls from any height |
| `can_jump` | on | Jumping allowed; off, `jump()` does nothing |
| `jump_height` | 1 m | Height of the feet at the top of the jump |
| `coyote_time` | 0.1 s | A jump still works this long after walking off an edge |
| `jump_buffer_time` | 0.12 s | A jump pressed this long before landing fires on landing |
| `gravity_scale` | 3 | Gravity multiplier: on the rise of a jump, and on the way down too unless `fall` sets another. The character runs faster than a person and would float down at normal gravity: a 1.6 m drop takes 0.33 s instead of 0.57 s |
| `fall` | — | A `FallSettings`: how fast the fall gains speed and the fastest fall, see [The fall](#the-fall). Empty: with `gravity_scale`, without a limit |
| `landing_min_speed` | 2.5 m/s | A slower fall (a bump, a ramp) is only `touched_floor`, not `landed` |
| `can_sprint` | on | Sprinting allowed. Turned off on the run, the extra speed is braked away |
| `stamina` | — | Optional `Stamina`; without it sprinting never tires |
| `sprint_tires` | on | Sprinting spends stamina |
| `sprint_duration` | 5 s | How long a full reserve lasts: spends `max_value / sprint_duration` per second |
| `steps_enabled` | on | Count steps: `stepped` and the step rhythm. Off for a character without legs. When the steps come back, the first one comes after `first_step_distance` |
| `stride_length` | 1.5 m | Distance on the ground between steps |
| `first_step_distance` | 0.3 m | Distance from a standstill to the first step |

The slope limit is the body's own `floor_max_angle` (Floor → Max Angle in the inspector, 45° by default). A steeper
surface is a wall for the body, for the stairs and for the ledge guard alike. Up is +Y: `up_direction` must stay
`Vector3.UP`.

When changing the body's size or a level's stairs, tune these together: keep `max_step_height` no lower than the
stair height, `LedgeGuard.max_drop` at least as high as `max_step_height`, and the navigation mesh's
`agent_max_climb` at the step height you intend to traverse. Rebake the mesh after changing its settings. The mesh
is a route planner; the capsule, floor slope, ceiling clearance and collision geometry still decide whether the
body can actually take that route. Keep `floor_snap_length` shorter than `max_step_height` if you want
`stair_taken` for down steps. The demo uses a 1.8 m tall, 0.35 m radius capsule, 0.3 m steps, a 0.5 m guarded drop
and a navigation mesh with 0.3 m max climb and 0.025 m cell height; see
[World and navigation](world-and-navigation.md#physics-layers-and-navigation).

The body may stand turned in the level, like an NPC turned in the editor or the `PlayableHero` root: the character
turns only `visual`, relative to the body, and starts facing along the body's −Z, where the mover takes its starting
heading from. Later, `teleport(position, facing)` or `NavigationMover.face()` sets where it faces.

A component can stop the steps for a while without touching `steps_enabled`: `set_steps_suppressed(self, true)`, and
`false` to let them go (`CharacterHover` does it while the character floats). Steps are counted when `steps_enabled`
is on and no component stops them (`is_counting_steps()`), so the game's switch and several components never undo
each other. The character does not keep a component alive: one that is freed lets the steps go by itself, by the
next tick. The fall works the same way, see [The fall](#the-fall).

Mistakes in the setup are printed as warnings when the character enters the tree, and `get_setup_warnings()` returns
the same list: the mover or the ledge guard is not a child of the body; `LedgeGuard.max_drop` is lower than
`max_step_height`, so the guard would stop the character at stairs it can step down; the floor snap is as long as a
stair, so it takes stairs down by itself, without `stair_taken`; `can_jump` is on, but `jump_height` or
`gravity_scale` is 0, so a jump would not leave the ground (such a jump does nothing, without `jumped`);
`fall.max_speed` is lower than `landing_min_speed`, so a fall would never land; `up_direction` is not +Y.
`LedgeGuard` and `CharacterHover` check their own setup the same way.

Set `sprint_requested` to ask for a sprint and call `jump()` to jump. `CharacterActionInput` does both for the
player; AI can do the same.

`teleport(position, facing)` puts the character elsewhere at once: at a spawn point, on another level. It stops dead
(`NavigationMover.halt()`), and what follows its movement sees no jerk: the speed, the acceleration and the turn rate
are zero, the smoothing between physics ticks starts anew at the new place (a floating model snaps there too), and a
jump pressed before is forgotten. With `facing` the character and its model turn there at once. Stamina is kept, and
whether the character stands on the ground stays as it was, so put the feet on the ground. Then the signal
`teleported`, for what should jump along: a camera, a trail. In the checks, a teleport in the middle of a run at
5.5 m/s leaves the character standing at the new place in the same frame, with no acceleration and no turning
afterwards.

The teleport does not touch the player's input or the camera. For the player's hero use `PlayableHero.teleport()` or
`place_at()` (see [Levels](levels.md#the-playable-hero)): they also forget the press under way, turn the camera if
asked and snap it into place. With `GroundCharacter.teleport()` alone, call `PointClickMoveInput.cancel()` first (a
mouse button still held would send the character on again in the next tick), and connect `teleported` to
`OrbitCameraRig.snap()`.

While time stands still (`Engine.time_scale` 0), the physics ticks go on with a zero step, and the character stays as
it is: its place, its velocity (`get_move_velocity()`), its state and the step rhythm keep their values, the
acceleration and the turn rate are 0, and a floating model and a swaying hand stay where they are. When time goes on,
the run goes on from there, in step. In the checks, a hero running at 5.5 m/s, on foot and floating, stays exactly as
it was, with no error, and runs on afterwards. Input given meanwhile still reaches the character: the sprint key
switches the sprint of a running character (`sprint_changed`), and a jump pressed on the ground is taken at once
(`jumped`). If nothing should change, take the controls away for that time (`PlayableHero.controls_enabled`).

### What the character reports

Animations, effects, sounds and the interface do not have to work out from the velocity what the character is
doing. Moments come as signals; what changes all the time is read with queries, every frame or tick.

| Signal | When |
|---|---|
| `state_changed(state, previous)` | The state changed. At the end of the tick, after the other signals of the tick |
| `stepped(sprinting)` | A foot touched the ground (`get_step_foot()` tells which): every `stride_length` covered on the ground, the first one `first_step_distance` from a standstill. Steps follow the distance, not time: about 3.7 per second running, 5.5 sprinting, none standing against a wall or in the air |
| `jumped` | The character pushed off the ground; `left_floor` follows in the same tick |
| `left_floor` | The character left the ground: by a jump or off an edge. A step down a stair does not count |
| `touched_floor(fall_speed)` | Back on the ground after any time in the air; one for every `left_floor`. `fall_speed` is the speed at the touch |
| `landed(impact_speed)` | A `touched_floor` at `landing_min_speed` or faster: a real landing, not a bump |
| `sprint_changed(sprinting)` | Sprinting started or stopped |
| `stair_taken(height)` | The character stepped onto a stair: the stair's height from ground to ground, positive up, negative down (±0.2 m on the demo's stairs). At the end of the tick, before `state_changed`. A stair low enough for the capsule to climb by itself (up to `radius × (1 − cos floor_max_angle)`, 0.1 m for the demo's capsule) or for the floor snap to take down (`floor_snap_length`) passes without it |
| `teleported` | `teleport()` has put the character elsewhere, at its end: what follows the character (a camera, a trail) should jump there too, not travel |

| State (`GroundCharacter.State`) | When |
|---|---|
| `IDLE` | On the ground, slower than `IDLE_SPEED` (0.1 m/s), also when running into a wall |
| `RUNNING` | On the ground, moving at any speed, not sprinting |
| `SPRINTING` | On the ground, sprinting |
| `JUMPING` | In the air after a jump, until the top |
| `FALLING` | In the air going down: after the top of a jump or off an edge |

| Query | Returns |
|---|---|
| `get_state()` | The state |
| `get_move_velocity()`, `get_move_speed()` | The actual horizontal velocity and its length, m/s: what the body really covers. Unlike `get_real_velocity()`, it counts a stair up too, and while time stands still (`Engine.time_scale` 0) it keeps its value |
| `get_locomotion_blend()` | For a 1D blend: 0 standing (below `IDLE_SPEED`), 1 at `max_speed`, 2 at the full sprint speed, whatever the speeds are tuned to |
| `get_local_movement()` | For a 2D blend: x to the model's right (negative to the left), y forward (negative back), the length is the blend. A run is (0, 1), a sprint (0, 2), a sidestep to the right (1, 0), to the left (−1, 0), forward and to the left (−0.71, 0.71), backing up (0, −0.7) |
| `get_local_acceleration()` | How fast the movement speeds up, brakes and turns, m/s², in the same axes: speeding up gives y > 0, braking y < 0, a turn to the left x < 0. It comes from the velocity the body is driven with, so stairs do not jerk it and hitting a wall does not show in it |
| `get_turn_rate()` | How fast the model turns, rad/s: positive to the left, negative to the right |
| `get_air_time()` | Seconds in the air; 0 on the ground |
| `get_step_phase()` | Steps taken as a number: whole at each step, the fraction grows with the distance between steps |
| `get_gait_cycle()` | The cycle of two steps, from 0 to 1: 0 when the left foot touches the ground, 0.5 the right one |
| `get_step_foot()` | The foot of the last step, `Foot.LEFT` or `Foot.RIGHT`. The feet alternate, also across stops |
| `is_sprinting()`, `is_exhausted()`, `get_jump_speed()` | Sprinting now; exhausted; the take-off speed of the jump |
| `is_on_floor()`, `get_floor_angle()`, `velocity.y` | From `CharacterBody3D` itself: on the ground, the slope underfoot, the vertical speed |
| `get_ground_height(point, above, below)` | The height of ground the character can stand on under a point: one ray from `above` meters over the point to `below` under it, against the body's collision mask; NAN if there is no such ground there, or if the ray starts inside something (a wall higher than `above`) |
| `is_counting_steps()` | Steps are counted now: `steps_enabled` is on and no component stops them |
| `get_fall_settings()` | The fall in effect: highest override priority, then most recent at equal priority; otherwise `fall`. Null means `gravity_scale` without a speed limit |

Which one for what:

- **A blend of animations:** `get_locomotion_blend()` for a `BlendSpace1D` with points at 0, 1 and 2,
  `get_local_movement()` for a `BlendSpace2D` with sidesteps and backing up. They are its exact inputs.
- **Effects that follow the speed:** `get_move_velocity()`, not `get_real_velocity()`. The real velocity drops at
  every stair up, where the body is put onto the stair past `move_and_slide()`, and while time stands still it is
  0 / 0, NaN: the movement of a tick divided by its zero length.
- **Inertia** (an item that lags behind, a model that leans into a start or a turn, a cloak):
  `get_local_acceleration()`.
- **Leaning into turns, turning in place:** `get_turn_rate()`. It is a speed, not an angle: it shows while the model
  turns, flickers from tick to tick, and goes back to 0 once the model faces the way. Smooth it before use.
- **A short drop or a hard fall:** `get_air_time()`. Skip the fall animation when the character has been in the air
  for only a moment, or make the landing stronger the longer it fell.
- **`touched_floor` or `landed`:** `touched_floor` ends any time in the air, so switch the air animation back on it.
  `landed` is a real landing only: a camera shake, a landing sound, a crouch.
- **Footprints, dust, a sound from the right foot:** `get_step_foot()` in a `stepped` handler.
- **A stair sound or a step-up animation:** `stair_taken(height)`. Not for smoothing: the body is already on the
  stair.
- **Feet that stand on the stairs, a model over the ground:** `get_ground_height()`.

**Without steps** (`is_counting_steps()` is false) there is no `stepped`, and `get_step_phase()`, `get_gait_cycle()` and
`get_step_foot()` stand still at their last values, so leg animations should not follow them then. The character
runs, jumps and climbs stairs as usual.

`HandSway` follows the step phase; an animation can do the same. The usual way to drive an `AnimationTree` is to set
its blends from the queries every frame and switch the state machine on the signals:

```gdscript
@export var character: GroundCharacter
@export var tree: AnimationTree


func _ready() -> void:
	character.state_changed.connect(_on_state_changed)
	character.landed.connect(func(_speed: float) -> void:
		tree.set("parameters/land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE))


func _process(_delta: float) -> void:
	# A BlendSpace1D with idle at 0, run at 1 and sprint at 2; for sidesteps, a BlendSpace2D and get_local_movement().
	tree.set("parameters/ground/blend_position", character.get_locomotion_blend())


func _on_state_changed(state: GroundCharacter.State, _previous: GroundCharacter.State) -> void:
	var in_air := state == GroundCharacter.State.JUMPING or state == GroundCharacter.State.FALLING
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	playback.travel("air" if in_air else "ground")
```

To keep the feet in step with the ground, play the run cycle by distance rather than by time: set its position to
`get_gait_cycle()` times its length (a `TimeSeek` node, or a paused `AnimationPlayer` with `seek()`). The cycle
should start with the left foot touching the ground.

### CharacterMonitor: the state as text

A `Label` that shows what a `GroundCharacter` is doing and its latest events, for tuning animations or as a debug
overlay. In the demo it is `Hud/CharacterState/Monitor`, shown by Settings (F10) → Interface → **Character state and
events**. The text comes only from the signals and queries above, so the script is also an example of using them.

```
Running
Speed 5.5 m/s · blend 1.00
Forward +1.00 · right +0.00
Turning +0°/s
On the ground · slope 0°
Step 38 · left foot · cycle 0.03
Stamina 100%

11.83 s  Jumping → Falling
12.08 s  touched the ground at 7.8 m/s
12.08 s  landing at 7.8 m/s
12.08 s  Falling → Running
12.35 s  step, right foot
12.62 s  step, left foot
```

Line by line:

1. The state, as `get_state()` gives it.
2. The actual speed (`get_move_speed()`) and the blend.
3. The movement in the model's axes, signed: forward +1.00 is a full run, −0.70 backing up; right −1.00 is a sidestep
   to the left.
4. How fast the model turns, in degrees per second, positive to the left. It is a speed, not an angle: it shows while
   the model turns and drops back to 0 once the model faces the way.
5. On the ground with the slope underfoot, or in the air with the time there and the vertical speed.
6. The number of steps, the foot of the last step and the gait cycle; "No steps" while steps are not counted.
7. Stamina, and "exhausted" while the character cannot sprint.

Under them, the latest events, oldest first, with the time since the start: steps with the foot, stairs with their
height, jumps, take-offs, landings with the fall speed, the sprint and the changes of state. While it is visible, the
panel rebuilds its text every frame; hidden, it skips that, but still records the events
(and prints them with `log_events`).

| Property | Default | Meaning |
|---|---|---|
| `character` | — | The `GroundCharacter`; if empty, the parent |
| `history_size` | 6 | How many latest events to show under the state; 0 shows only the state |
| `log_events` | off | Also print every event to the output with its time and the character's name |
| `include_steps` | on | Show and log the steps and the stairs too: there are several per second |

Methods: `get_text_now()`, `get_state_lines()`, `get_event_lines()`, `get_state_name(state, translated)`. The phrases
go through `tr()`, so the panel speaks the interface language; the log in the output stays in English.

### Stairs and slopes

**Slopes** are `move_and_slide()`'s own job: the body walks up a surface no steeper than `floor_max_angle` and stops
at a steeper one. With `floor_constant_speed`, which the demo's body has on, it keeps its speed on a ramp.

**Stairs.** A capsule climbs a ledge by itself only up to `radius × (1 − cos floor_max_angle)`, 0.1 m for the
0.35 m capsule. Higher stairs, up to `max_step_height`, the body climbs itself:

- **Up.** If the movement of the tick, looked at 5 cm farther, runs into something too steep to stand on, the body
  tries a stair: up by `max_step_height` (or as far as a ceiling lets), forward by the movement of the tick, down onto
  ground. A ray checks the top: it must be ground no higher than `max_step_height` above the feet, so a 0.4 m block or
  a steep slope is not a stair. The body is put on the stair, and `move_and_slide()` only settles it there.
- **Down.** If the body stood on the ground before the tick and is in the air after it without a jump, and there is
  ground no deeper than `max_step_height` under it, the body is put on that ground: no `left_floor`, no falling.
- Each stair the body steps onto is reported with `stair_taken(height)`: its real height from the ground the body
  stood on to the ground of the stair, +0.2 m for each of the demo's stairs up, −0.2 m down.
- The round bottom of the capsule rests on a stair edge at an angle, too steep to stand on while the body is far from
  the edge. So the place on a stair is searched a little farther, in steps of 2 cm: the body ends up to a few
  centimeters past where the tick would take it.

Each stair costs about one tick of rolling over its edge, when the horizontal speed drops to about 70%
(`get_move_speed()` shows it; the staff in the hand does not notice it, since `HandSway` follows
`get_local_acceleration()`). For a long flight of stairs an invisible ramp collider is the smoothest.

The body goes up a stair at once: up a 0.2 m stair, about 0.1 m in one tick and the rest over the next two or three
ticks while the capsule rolls over the edge. Physics interpolation spreads it over the frames, but on screen it is
still a short jerk. A floating model glides over the stairs instead (`CharacterHover`), and the camera's
`height_follow_time` smooths the climb for the view (0.15 s in the demo, see [Camera](camera.md#properties)).

The navigation mesh must join what the body can climb: in the demo `agent_max_climb` is 0.3 m, the same as
`max_step_height` (see [World and navigation](world-and-navigation.md#physics-layers-and-navigation)).

### The jump

The take-off speed is `v = √(2·g·h)`. In the take-off tick the body gets `v − g·dt/2` and no other gravity, also in
coyote time: then its positions at every tick lie exactly on the parabola, and the jump height does not depend on the
tick rate. With plain `v` the jump would be `v·dt/2` higher, 1.064 m instead of 1 m at 60 ticks. In the demo a 1 m
jump takes 0.52 s with `gravity_scale` 3.

In the air the character keeps running as it was, and the controls stay the same. The ledge guard does not hold a
jump: jumping off a platform edge is a deliberate step, not an accident.

### The fall

The way down, after the top of a jump and off an edge, follows a `FallSettings` resource: the character's own `fall`,
or one that a component has put in its place. The rise of a jump does not change: it slows down with `gravity_scale`,
so the jump is `jump_height` high whatever the fall. Without any fall settings the character falls exactly as it
always did: gravity times `gravity_scale`, whichever way the gravity of the place pulls, without a limit. With them,
gravity along the ground (an area's) still pulls as before, and where gravity does not pull down at all (an
updraft), the settings have nothing to shape.

| Property | Default | Meaning |
|---|---|---|
| `gravity_scale` | 0 | How many times stronger gravity is than in the world on the way down: how fast the fall gains speed. Lower than the character's own, it comes down more slowly than it goes up. 0 takes the character's own `gravity_scale`, so a new resource changes nothing and a limit alone keeps the fall's gravity |
| `max_speed` | 0 m/s | The fastest fall: the fall gains speed up to it, then goes on at it. 0 is no limit |
| `braking_time` | 0.3 s | In how long a fall faster than `max_speed` slows down to it (95% of the excess speed): after the character is thrown down, or when the settings come into effect mid-fall. 0 is at once |

A component can put its own fall in place of `fall` for a while: `set_fall_override(self, settings, priority)`, and
`null` to give it back. With several components, the highest priority counts (0 by default), and of equal ones the
component that put its fall in place last; a component that only changes its settings or its priority keeps its
place. `fall` itself is not touched, so the game's own settings come back once the components let go. The character
does not keep a component alive: one that is freed lets go by itself. `get_fall_settings()` returns the fall in
effect. `CharacterHover` puts its own `fall` in place with priority 0 each time the model starts to rise, see
[Characters](characters.md#the-fall); a fall that the game puts in place with priority 1, a spell of slow falling for
example, wins over it whenever floating is turned on.

`touched_floor` and `landed` report the speed at the moment of touching the ground. A fall that gains speed only up
to a limit below `landing_min_speed` ends in `touched_floor` only; `landed` comes only if the character was thrown
down faster and touches the ground before it has slowed down. For the character's own `fall` that is a setup warning:
the landing sound and effects would never come after a jump. For a floating character it is what the demo wants, a
soft touchdown. A limit of exactly `landing_min_speed` lands.

The demo's hero has no `fall` of its own. Its hover has `gdscript/player/player_floating_fall.tres`: gravity scale
0.5 instead of the body's 3, and a 2 m/s maximum downward speed, so a floating hero is 0.95 s in the air after a
1 m jump instead of 0.52 s, and
touches the ground at 2 m/s instead of 7.8 m/s. `FallSettings.get_next_speed(speed, acceleration, delta)` and
`get_gravity_scale(own)` are the step itself, for a body of your own.

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
| `max_drop` | 0.5 m | A drop deeper than this is guarded; a shallower one may be crossed. Only drops within `GroundCharacter.max_step_height` are stepped down without falling |
| `edge_margin` | 0.15 m | How close the character's center may come to the edge |
| `margin_probes` | 6 | Rays around the `edge_margin` circle |
| `probe_height` | 0.5 m | Rays start this high above the feet, to find ground slightly above them (a ramp) |
| `floor_mask` | 0 | What counts as ground; 0 takes the body's collision mask, so the guard counts as ground exactly what the body stands on |
| `slide_iterations` | 6 | Halvings of the slide angle; 6 gives about 1.4° |

On open ground that is 7 rays per tick, up to 98 at an edge. In the air the guard does nothing. A path from the
platform down follows the ramp, and the guard does not get in its way. Ground is what the body can stand on: no
steeper than its `floor_max_angle`, with the same small margin as the engine's own floor check
(`GroundCharacter.FLOOR_ANGLE_MARGIN`). A `floor_mask` with layers the body does not collide with is reported as a
setup warning: the guard would count as ground what the body falls through.

## Measured behavior

The scene checks in `tests/movement_checks.gd`, `tests/character_actions_checks.gd` and
`tests/character_state_checks.gd` exercise the shipped hero at 60 physics ticks:

- With the default 5.5 m/s run and 0.18 s acceleration, it reaches 95% speed in 0.18 s; normal stopping from
  95% takes about 0.20 s. A new target while braking preserves speed, and a reverse click turns through an arc.
- Sprint reaches 8.25 m/s. Stamina with a 2 s duration in the test exhausts, recovers past its threshold and lets a
  still held sprint request resume.
- A 1 m jump reaches 1.000 m and spends about 0.52 s in the air. Buffered presses just before landing fire, and a
  press just after leaving an edge works within coyote time.
- The demo's 0.2 m stairs are traversed in both directions without leaving the ground; `stair_taken` reports each
  step. A 0.4 m block and a 50° slope stop the body. The guard stops a run over the platform edge and slides an
  angled run along it.
- With the hover's 0.5 fall gravity and 2 m/s limit, jump height stays 1 m but touchdown is 2 m/s, below the
  default 2.5 m/s landing threshold. These results depend on the shipped capsule, colliders, mesh and settings;
  test changed geometry and values in your own level.

---

*This page matches Iso & Orbit 1.2.0.*
