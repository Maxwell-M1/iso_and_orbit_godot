# Orbit Camera

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

An orbit camera for isometric and top-down games: it follows a target, orbits with the right mouse button, zooms
with the wheel (distance and pitch change together) and can turn behind the running target by itself. The camera
sits at the end of an arm that stops at walls behind it and can move in when an obstacle hides the target.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig` (Node3D) | Follows the target, orbit, zoom, follow mode |
| `camera_arm.gd` | `CameraArm` (Node3D) | Holds the camera and shortens at obstacles; fades the target up close |

No other addon is needed.

## Setup

1. Copy this folder to `res://addons/iso_orbit/orbit_camera/`.
2. Add the input actions (the names are exported properties, so you can use your own): `camera_rotate` (right mouse
   button), `camera_zoom_in` (wheel up), `camera_zoom_out` (wheel down).
3. Build the camera next to the target, not inside it:

   ```
   CameraRig    Node3D with orbit_camera_rig.gd, target = your character
   └── CameraArm    Node3D with camera_arm.gd
       └── Camera3D
   ```

4. Physics layers: the arm stops at bodies on layers 1 and 3 (`collision_mask`). Put level geometry on one of them
   and keep characters off them. Bodies in the group `camera_ignore` (or under a node in it) never stop the arm.
5. If the target moves in physics ticks, turn on physics interpolation in the project: the rig follows the target's
   interpolated position.

Without an arm, a `Camera3D` child of the rig works too: it stays at the distance set by the zoom and goes
through walls.

## Documentation

In the template repository: `docs/en/systems/camera.md` (every property, the zoom curve, follow mode, how the arm
works) and `docs/en/project-setup.md`.

---

*This page matches Iso & Orbit 1.1.0.*
