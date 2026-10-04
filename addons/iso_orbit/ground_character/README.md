# Ground Character

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

A ready-made character body for click-to-move: gravity, a jump with coyote time and input buffering (the same height
at any physics tick rate), sprint with stamina, stairs up and down, a ledge guard that stops the body at drops. The
body reports what it is doing for animations, effects and the interface: the state and its changes, steps with the
foot, take-offs and landings, the speed as a blend value, the movement in the model's axes, turning and the gait
cycle. Also included: sounds on those signals, a panel that shows the state as text, a held item swinging with the
steps and switchable models.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Gravity, jump, sprint, stairs, `move_and_slide()`, turning the model; the state, signals and queries for animations |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Stops the body at a drop or slides it along the edge |
| `stamina.gd` | `Stamina` (Node) | The sprint reserve |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Sprint and jump keys → the character |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Plays sounds on the character's signals |
| `hand_sway.gd` | `HandSway` (Node) | Swings a hand node with the steps |
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
   body, so the character keeps its speed on ramps, and puts it on physics layer 2, apart from the level. The body
   climbs stairs up to `max_step_height` (0.3 m) and slopes up to its `floor_max_angle`; for paths up stairs, bake the
   navigation mesh with `agent_max_climb` equal to `max_step_height`.
3. For the keys, add a `Node` with `character_action_input.gd` and set its `character`. It needs the input actions
   `sprint` and `jump`.
4. Optional: `CharacterSounds` with `AudioStreamPlayer3D` children, `HandSway` with the model's hand node,
   `CharacterAppearance` with a list of model scenes, `CharacterMonitor` in a `CanvasLayer` for a debug panel.
   `LedgeGuard.floor_mask` is physics layer 1 by default.

AI can drive the same body: call `NavigationMover.move_to()` and `GroundCharacter.jump()`, set `sprint_requested`.

## Documentation

In the template repository: `docs/en/integration.md`, `docs/en/systems/locomotion.md`, `docs/en/systems/audio.md`
and `docs/en/systems/characters.md`.

---

*This page matches Iso & Orbit 1.1.0.*
