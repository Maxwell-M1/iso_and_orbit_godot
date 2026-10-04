# Ground Character

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

A ready-made character body for click-to-move: gravity, a jump with coyote time and input buffering (the same height
at any physics tick rate), sprint with stamina, a ledge guard that stops the body at drops, signals for steps, jumps,
landings and sprinting, sounds on those signals, a held item swinging with the steps and switchable models.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Gravity, jump, sprint, `move_and_slide()`, turning the model; signals |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Stops the body at a drop or slides it along the edge |
| `stamina.gd` | `Stamina` (Node) | The sprint reserve |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Sprint and jump keys → the character |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Plays sounds on the character's signals |
| `hand_sway.gd` | `HandSway` (Node) | Swings a hand node with the steps |
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
   body, so the character keeps its speed on ramps, and puts it on physics layer 2, apart from the level.
3. For the keys, add a `Node` with `character_action_input.gd` and set its `character`. It needs the input actions
   `sprint` and `jump`.
4. Optional: `CharacterSounds` with `AudioStreamPlayer3D` children, `HandSway` with the model's hand node,
   `CharacterAppearance` with a list of model scenes. `LedgeGuard.floor_mask` is physics layer 1 by default.

AI can drive the same body: call `NavigationMover.move_to()` and `GroundCharacter.jump()`, set `sprint_requested`.

## Documentation

In the template repository: `docs/en/integration.md`, `docs/en/systems/locomotion.md`, `docs/en/systems/audio.md`
and `docs/en/systems/characters.md`.

---

*This page matches Iso & Orbit 1.1.0.*
