# Click to Move

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Click-to-move for isometric and top-down games: click the ground and the character runs there along the navigation
mesh, stopping exactly at the point; hold the button and it runs after the cursor. Constant acceleration and
braking, a limited turn rate, an instant turn from a standstill. With the right button held, WASD move the character
relative to the camera.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Speed, acceleration, braking, turning |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | The math: direction and distance left → velocity |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`; returns a velocity, never moves the body |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Mouse and RMB + WASD → mover commands |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | The marker at a clicked point |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | A debug line along the remaining path |

No other addon is needed. For a ready-made body with gravity, jump and sprint, add `addons/iso_orbit/ground_character`.

## Setup

1. Copy this folder to `res://addons/iso_orbit/click_to_move/`.
2. Bake a navigation mesh for your level (`NavigationRegion3D`). Without one the character runs straight at the
   point.
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

4. For mouse control, add a `Node` with `point_click_move_input.gd` anywhere and set its `mover` and `camera`. It
   needs the input actions `move_to_cursor` (left button), `camera_rotate` (right button) and `move_forward`,
   `move_back`, `move_left`, `move_right` (WASD), and clicks hit physics layer 1 (`ground_mask`).
5. Or command the mover from AI: `move_to(point)`, `steer(direction)`, `stop()`, and listen to `arrived`.

## Documentation

In the template repository: `docs/en/integration.md`, `docs/en/systems/locomotion.md` and
`docs/en/systems/input.md`.

---

*This page matches Iso & Orbit 1.1.0.*
