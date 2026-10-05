# Orbit Camera

[← Documentation index (template repository)](../../../docs/en/index.md)

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

An orbit camera for isometric and top-down games. It follows any `Node3D`, orbits with the mouse, and zooms with the
wheel. On a run it can independently turn behind the target, align its tilt, and return to a chosen zoom. Its arm keeps
the camera out of walls and can optionally pull it in when an obstacle hides the target.

Part of Iso & Orbit for Godot 4.7. MIT license (see `LICENSE`). This folder needs no other addon when used on its own.

| Script | Class | Job |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig` (`Node3D`) | Target following, input, zoom, and optional running alignment |
| `camera_arm.gd` | `CameraArm` (`Node3D`) | Camera placement, obstacle response, and optional close-range fade |

## Put it in a scene

1. Copy this folder to `res://addons/iso_orbit/orbit_camera/`.
2. In **Project Settings → Input Map**, add `camera_rotate` (right mouse button), `camera_zoom_in` (wheel up), and
   `camera_zoom_out` (wheel down). The rig's exported action names can be changed. A missing action reports an error at
   startup and cannot trigger input.
3. Add the nodes below beside the moving target. Assign `CameraRig.target` to your character or other `Node3D`. Leave
   the camera subtree and its ancestors unscaled.

   ```text
   Scene
   ├── Character (moving target)
   └── CameraRig (Node3D + orbit_camera_rig.gd; target = ../Character)
       └── CameraArm (Node3D + camera_arm.gd)
           └── Camera3D (Current = on)
   ```

   The rig and arm find their first direct `CameraArm` and `Camera3D` children, respectively; you can also set the
   exported `arm` and `camera` references. Leave `Camera3D` at its default local transform because the arm places it.
   Make it current when this should be the active view. For the template's framing, set its FOV to 45° and far plane to
   300 world units.
4. Put solid world collision on physics layer 1. The arm's default `collision_mask` is layers 1 and 3 (`0b101`); layer 3
   can hold camera-only blockers such as roofs. Keep characters off that mask so they do not push the camera. Add
   `camera_ignore` to a body or an ancestor to exclude it. Optionally set `CameraArm.fade_target` to a model root so it
   becomes translucent when the arm is very short.
5. If the target moves in physics ticks, enable **Project Settings → Physics → Common → Physics Interpolation**. The rig
   follows the target's interpolated position each rendered frame and turns off its own interpolation. Its arm and
   camera inherit that mode by default.

The script defaults give manual orbit: all three running alignment switches are off, even though their times and goals
have values. For the template hero's tuned optional follow, use `follow_time = 1.1` s, `follow_pitch_angle = -22°`,
`follow_pitch_time = 1.1` s, `follow_zoom_level = 0.55`, `follow_zoom_time = 1.5` s, `follow_wait_after_rotate = true`,
and `height_follow_time = 0.15` s. Enable `follow_movement` to turn behind a run; enable `follow_pitch` and/or
`follow_zoom` only if you want those alignments. The template hero leaves all three off initially. Set angle values in
degrees in the Inspector; in GDScript, assign radians with `deg_to_rad()`.

With `follow_wait_after_rotate` on, follow stays paused after a deliberate mouse orbit until the target slows or a new
run begins. If your input starts another run before the target stops, call `end_follow_wait()` then. The template
connects `PointClickMoveInput.run_requested` to it, and `hold_pending_changed` to `set_follow_paused()`, in
`gdscript/player/playable_hero.tscn`. If your target moves continuously and cannot report a new run, leave the wait
option off. Keep `sharp_turn_speed` at half the character's turn speed or lower so a reversal does not pull the camera
through passing directions; the template pairs 360°/s with the hero's 720°/s turn.

Without an arm, a direct `Camera3D` child of the rig also works. It stays at the zoom distance and can pass through
walls; obstacle response and fade require `CameraArm`.

For the zoom curve, all properties, occlusion behavior, and tested interactions, see
[Camera](../../../docs/en/systems/camera.md). For transferring the ready-made hero, see
[Integration](../../../docs/en/integration.md#taking-the-demos-hero-into-your-project) and
[Project setup](../../../docs/en/project-setup.md).

---

*This page matches Iso & Orbit 1.2.0.*
