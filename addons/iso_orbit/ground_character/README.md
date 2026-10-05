# Ground Character

[← Documentation index (template repository)](../../../docs/en/index.md)

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

A ready-made character body for click-to-move: gravity, a jump with coyote time and input buffering (the same height
at any physics tick rate), a fall with its own gravity and speed limit, sprint with stamina, stairs up and down, and
an optional ledge guard that stops the body at drops. The body reports what it is doing for animations, effects and
the interface: the state and its changes, steps with the
foot, take-offs and landings, the speed as a blend value, the movement in the model's axes, turning and the gait
cycle. Also included: sounds on those signals, a panel that shows the state as text, a held item swinging with the
steps, a floating mode for the model and switchable models.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Gravity, jump, sprint, stairs, `move_and_slide()`, turning the model; the state, signals and queries for animations; `teleport()` without a jerk |
| `fall_settings.gd` | `FallSettings` (Resource) | How the character falls: the fall's gravity, the speed limit, braking to it |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Stops the body at a drop or slides it along the edge |
| `stamina.gd` | `Stamina` (Node) | The sprint reserve |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Sprint and jump keys → the character |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Plays sounds on the character's signals |
| `hand_sway.gd` | `HandSway` (Node) | Swings a hand node with the steps |
| `character_hover.gd` | `CharacterHover` (Node3D) | Floats the model above the ground, glides over stairs, sways and leans; can slow the fall |
| `damped_spring.gd` | `DampedSpring` (RefCounted) | A damped spring for one value, for inertia |
| `character_monitor.gd` | `CharacterMonitor` (Label) | Shows the character's state and latest events as text; can log the events |
| `character_appearance.gd` | `CharacterAppearance` (Node) | Swaps the model at runtime |
| `stamina_bar.gd`, `stamina_bar.tscn` | `StaminaBar` (ProgressBar) | A HUD bar for `Stamina` |

Needs `addons/iso_orbit/click_to_move`: the body is driven by a `NavigationMover`.

## Setup

1. Copy this folder and `click_to_move` to `res://addons/iso_orbit/`.
2. Build the character:

   ```
   Player           CharacterBody3D with ground_character.gd
   ├── CollisionShape3D
   ├── Visual       Node3D; the model inside faces −Z
   ├── NavigationMover   from click_to_move
   ├── LedgeGuard   optional
   └── Stamina      optional
   ```

   Set the body's `mover`, `visual`, `ledge_guard` and `stamina`. The demo also sets `floor_constant_speed` on the
   body, so the character keeps its speed on ramps, and puts it on physics layer 2, apart from the level, colliding
   with layers 1 and 4 (the level and its invisible walls): `get_ground_height()` and, by default, `LedgeGuard` look
   for ground with the same mask. The body climbs stairs up to `max_step_height` (0.3 m) and slopes up to its
   `floor_max_angle`; for paths up stairs, bake the navigation mesh with `agent_max_climb` matched to the intended
   step height and test the baked route against the actual collider. Keep `LedgeGuard.max_drop` at least as high as
   `max_step_height`, and `floor_snap_length` below it if you need `stair_taken` on down steps.
   The body may stand turned in the level: the character turns only `Visual`, relative to the body, and starts facing
   along the body's −Z; later, `teleport(position, facing)` or `NavigationMover.face()` turns it.
3. For the keys, add a `Node` with `character_action_input.gd` and set its `character`. It needs the input actions
   `sprint` and `jump`; a missing one is reported once at the start and is not read after that.
4. Optional: `CharacterSounds` with `AudioStreamPlayer3D` children, `HandSway` with its `character` and the model's
   hand node, `CharacterAppearance` with a `slot` and a list of model scenes, `CharacterMonitor` in a `CanvasLayer` for
   a debug panel. `LedgeGuard.floor_mask` 0 (the default) takes the body's collision mask and rejects surfaces too
   steep for the body to stand on.
5. To float, put a `Node3D` with `character_hover.gd` between `Visual` and the model (`Visual/Hover/Model`), and make
   it the `slot` of `CharacterAppearance` if you use that component. While the character floats, the hover turns its
   steps off, and with its `fall` set (a `FallSettings`), the character can come down more slowly. The model rises;
   the body and its collision shape do not.
6. Optional: a `FallSettings` resource in the body's `fall`, for a fall of its own: a different gravity on the way
   down, a speed limit.

Mistakes in the setup are printed as warnings when the game starts. The shipped `player.tscn` has a 1.8 m capsule,
`floor_constant_speed` on, a ledge guard, stamina, a floating fall resource and a hover that starts **off**. Its
`NavigationMover` uses `player_locomotion.tres`; the demo's `SettingsApplier` can change properties from saved
settings at startup. For the playable hero copy recipe, see `docs/en/integration.md`; for fitting your own model and
its collision shape, see `docs/en/systems/characters.md`.

AI can drive the same body: call `NavigationMover.move_to()` and `GroundCharacter.jump()`, set `sprint_requested`.

## Documentation

In the template repository: `docs/en/integration.md`, `docs/en/systems/locomotion.md`, `docs/en/systems/input.md`
(`CharacterActionInput`), `docs/en/systems/audio.md`, `docs/en/systems/characters.md` and `docs/en/systems/levels.md`
(teleporting the hero).

---

*This page matches Iso & Orbit 1.2.0.*
