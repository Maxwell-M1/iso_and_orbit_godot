# Click to Move

[← Documentation index (template repository)](../../../docs/en/index.md)

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Click-to-move for isometric and top-down games: click the ground and the character follows a navigation path,
stopping at its reachable end; hold the button and it runs after the cursor. Constant acceleration and
braking, a limited turn rate, an instant turn from a standstill. With the right button held, WASD move the character
relative to the camera. The right button pressed during a run after the cursor leaves the run on its course, so the
player can look around.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Speed, acceleration, braking, turning |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | The math: direction and distance left → velocity |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`, `halt()`, `face()`; returns a velocity, never moves the body |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Mouse and RMB + WASD → mover commands; `cancel()` forgets a press under way |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | The marker at a clicked point |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | A debug line along the remaining path |

No other addon is needed. For a ready-made body with gravity, jump and sprint, add `addons/iso_orbit/ground_character`.

## Setup

1. Copy this folder to `res://addons/iso_orbit/click_to_move/`.
2. Bake a navigation mesh for your level (`NavigationRegion3D`). Set its agent size and climb for the body's capsule
   and steps. With no mesh or an empty path result, the mover runs straight at the requested point; a partial path
   may end at the closest reachable point instead. The body still needs collision geometry and a collision shape.
3. Add `NavigationMover` as a direct child of the character's body. The body calls `compute_velocity(delta)` once per
   physics tick, before `move_and_slide()`:

   ```gdscript
   extends CharacterBody3D

   @onready var mover: NavigationMover = $NavigationMover


   func _physics_process(delta: float) -> void:
   	var planar := mover.compute_velocity(delta)
   	velocity.x = planar.x
   	velocity.z = planar.z
   	if not is_on_floor():
   		velocity += get_gravity() * delta
   	move_and_slide()
   ```

   Assign `NavigationMover.settings` to a `LocomotionSettings` resource before the mover enters the tree, or leave it
   empty to create one with script defaults. Use **Make Unique** when each character needs independent tuning.
   Changing fields of the resource during play works; replacing `mover.settings` after `_ready()` does not update the
   `GroundMotion` instance it already made. `GroundCharacter` from the companion addon handles stairs, jumping and
   ledge guarding if you need those features.

4. For mouse control, add a `Node` with `point_click_move_input.gd` anywhere and set its `mover` and `camera`. It
   needs the input actions `move_to_cursor` (left button), `camera_rotate` (right button) and `move_forward`,
   `move_back`, `move_left`, `move_right` (WASD); a missing one is reported once at the start and is not read after
   that. Clicks hit physics layer 1 (`ground_mask`): keep the
   characters' layer and invisible walls out of it, or clicks land on the character or on the wall. With the orbit
   camera from `addons/iso_orbit/orbit_camera`, connect `hold_pending_changed` to its `set_follow_paused` and
   `run_requested` to its `end_follow_wait`. Looking around on the run (`look_around_while_held`) relies on
   `camera_steer_action` being the action that rotates the camera (the rig's `rotate_action`, both `camera_rotate`).
5. Or command the mover from AI: `move_to(point)`, `steer(direction)`, `stop()`, and listen to `arrived`. It means the
   end of the path was reached, which can be short of the requested point if that point is unreachable.

For the preassembled hero, copy recipe and scene settings, use `docs/en/integration.md` rather than building this
body by hand. The two input modes and the hero's settings are explained in `docs/en/systems/input.md`.

## Documentation

In the template repository: `docs/en/integration.md`, `docs/en/systems/locomotion.md` and
`docs/en/systems/input.md`.

---

*This page matches Iso & Orbit 1.2.0.*
