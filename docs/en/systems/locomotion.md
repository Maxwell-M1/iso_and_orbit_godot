# Locomotion

How a character runs, stops, turns, sprints, jumps, climbs stairs and keeps away from drops, and how it tells what it
is doing. Four classes, from the bottom up:

| Class | Kind | Job |
|---|---|---|
| `LocomotionSettings` | Resource | Speed, acceleration, braking, turning |
| `GroundMotion` | RefCounted | The math: desired direction and distance left → horizontal velocity |
| `NavigationMover` | Node, child of the body | Paths and commands; returns a velocity, never moves the body |
| `GroundCharacter` | CharacterBody3D | Gravity, jump, sprint, `move_and_slide()`, turning the model |

Two helpers plug into the body: `Stamina` (the sprint reserve) and `LedgeGuard` (no walking off drops).
`CharacterMonitor` shows what the body reports as text.

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
from the mover, handles the jump and gravity, lets `LedgeGuard` correct the velocity, calls `move_and_slide()` with a
stair up before it and a stair down after it, and then reports what the tick changed: floor contact, steps, the
model's turn toward `mover.get_facing()` and the state.

The inspector groups the properties: the parts and the turn first, then Ground, Jump and fall, Sprint and Steps.

| Property | Default | Meaning |
|---|---|---|
| `mover` | — | The `NavigationMover`; required |
| `visual` | — | The node turned to face the way the character goes; its front is −Z |
| `visual_turn_speed` | 1080 °/s | How fast the model turns |
| `max_step_height` | 0.3 m | The highest stair the character steps onto without a jump, and the deepest one it steps down without leaving the ground. 0 disables stepping |
| `ledge_guard` | — | Optional `LedgeGuard`; without it the character falls from any height |
| `can_jump` | on | Jumping allowed; off, `jump()` does nothing |
| `jump_height` | 1 m | Height of the feet at the top of the jump |
| `coyote_time` | 0.1 s | A jump still works this long after walking off an edge |
| `jump_buffer_time` | 0.12 s | A jump pressed this long before landing fires on landing |
| `gravity_scale` | 3 | Gravity multiplier. The character runs faster than a person and would float down at normal gravity: a 1.6 m drop takes 0.33 s instead of 0.57 s |
| `landing_min_speed` | 2.5 m/s | A slower fall (a bump, a ramp) is only `touched_floor`, not `landed` |
| `can_sprint` | on | Sprinting allowed. Turned off on the run, the extra speed is braked away |
| `stamina` | — | Optional `Stamina`; without it sprinting never tires |
| `sprint_tires` | on | Sprinting spends stamina |
| `sprint_duration` | 5 s | How long a full reserve lasts: spends `max_value / sprint_duration` per second |
| `stride_length` | 1.5 m | Distance on the ground between steps |
| `first_step_distance` | 0.3 m | Distance from a standstill to the first step |

The slope limit is the body's own `floor_max_angle` (Floor → Max Angle in the inspector, 45° by default). A steeper
surface is a wall for the body, for the stairs and for the ledge guard alike.

Set `sprint_requested` to ask for a sprint and call `jump()` to jump. `CharacterActionInput` does both for the
player; AI can do the same.

### What the character reports

Animations, effects, sounds and the interface do not have to work out from the velocity what the character is
doing. Moments come as signals; what changes all the time is read with queries, every frame or tick.

| Signal | When |
|---|---|
| `state_changed(state, previous)` | The state changed. At the end of the tick, after the other signals of the tick |
| `stepped(sprinting)` | A foot touched the ground (`get_step_foot()` tells which): every `stride_length` covered on the ground, the first one `first_step_distance` from a standstill. Steps follow the distance, not time: about 3.7 per second running, 5.5 sprinting, none standing against a wall or in the air |
| `jumped` | The character pushed off the ground; `left_floor` follows in the same tick |
| `left_floor` | The character left the ground: by a jump or off an edge. A step down a stair does not count |
| `touched_floor(fall_speed)` | Back on the ground after any time in the air; one for every `left_floor` |
| `landed(impact_speed)` | A `touched_floor` at `landing_min_speed` or faster: a real landing, not a bump |
| `sprint_changed(sprinting)` | Sprinting started or stopped |

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
| `get_move_velocity()`, `get_move_speed()` | The actual horizontal velocity and its length, m/s: what the body really covers. Unlike `get_real_velocity()`, it counts a stair up too |
| `get_locomotion_blend()` | For a 1D blend: 0 standing, 1 at `max_speed`, 2 at the full sprint speed, whatever the speeds are tuned to |
| `get_local_movement()` | For a 2D blend: x to the model's right, y forward, the length is the blend. A run is (0, 1), a sprint (0, 2), a sidestep to the right (1, 0), backing up (0, −0.7) |
| `get_turn_rate()` | How fast the model turns, rad/s: positive to the left, negative to the right |
| `get_air_time()` | Seconds in the air; 0 on the ground |
| `get_step_phase()` | Steps taken as a number: whole at each step, the fraction grows with the distance between steps |
| `get_gait_cycle()` | The cycle of two steps, from 0 to 1: 0 when the left foot touches the ground, 0.5 the right one |
| `get_step_foot()` | The foot of the last step, `Foot.LEFT` or `Foot.RIGHT`. The feet alternate, also across stops |
| `is_sprinting()`, `is_exhausted()`, `get_jump_speed()` | Sprinting now; exhausted; the take-off speed of the jump |
| `is_on_floor()`, `get_floor_angle()`, `velocity.y` | From `CharacterBody3D` itself: on the ground, the slope underfoot, the vertical speed |

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
Step 37 · left foot · cycle 0.03
Stamina 100%

12.35 s  step, right foot
12.62 s  step, left foot
12.80 s  jump
12.80 s  left the ground
12.80 s  Running → Jumping
```

| Property | Default | Meaning |
|---|---|---|
| `character` | — | The `GroundCharacter`; if empty, the parent |
| `history_size` | 6 | How many latest events to show under the state; 0 shows only the state |
| `log_events` | off | Also print every event to the output with its time and the character's name |
| `include_steps` | on | Show and log the steps too: there are several per second |

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
- The round bottom of the capsule rests on a stair edge at an angle, too steep to stand on while the body is far from
  the edge. So the place on a stair is searched a little farther, in steps of 2 cm: the body ends up to a few
  centimeters past where the tick would take it.

Each stair costs about one tick of rolling over its edge, when the horizontal speed drops to about 70%
(`get_move_speed()` shows it, the staff in the hand hardly moves). For a long flight of stairs an invisible ramp
collider is the smoothest.

The navigation mesh must join what the body can climb: in the demo `agent_max_climb` is 0.3 m, the same as
`max_step_height` (see [World and navigation](world-and-navigation.md#physics-layers-and-navigation)).

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

The tests (`tests/movement_checks.gd`, `tests/character_actions_checks.gd`, `tests/character_state_checks.gd`,
`tests/camera_checks.gd`) measure the demo's settings at 60 physics ticks. Their limits are computed from the
settings, so you can change them.

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
- What the character reports: a full run gives the blend 1.00, a full sprint 2.00; a sidestep (1.00, 0.00), backing
  up (0.00, −0.70). States in a run: `RUNNING`, `SPRINTING`, `RUNNING`, `IDLE`. A jump: `jumped`, `left_floor`,
  `JUMPING` for 0.27 s (0.26 s to the top by the formula), `FALLING`, `touched_floor`, `landed`, `IDLE`; 0.52 s in the
  air. Off the platform edge: `left_floor` and straight to `FALLING`. The feet alternate, also after a stop.
- Stairs east of the platform (0.2 m stairs, 0.4 m treads) by a click: up and down without leaving the ground, at a
  median of 5.4 m/s up and 5.5 m/s down, the lowest 3.9 and 5.0 m/s. With `max_step_height` 0 the character stops at
  the first stair. A 0.4 m block stops it, a 30° slope is walked up, a 50° one is not.
- On the mountain trail, the ramp, the meadow and in the maze the character never leaves the ground without a jump.

---

*This page matches Iso & Orbit 1.1.0.*
