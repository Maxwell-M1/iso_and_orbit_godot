# Points of Interest

[← Documentation index (template repository)](../../../docs/en/index.md)

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Places to discover: an area that reports the first time the player enters it, and an on-screen message
"Discovered: …" that finds every place by itself.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest` (Area3D) | Emits `discovered(title)` the first time a body in the group `player` enters; joins the group `points_of_interest`; `is_discovered()` tells whether it is found; `mark_discovered()` counts it as found without the signal (a level loaded again, a saved game) |
| `discovery_toast.gd`, `discovery_toast.tscn` | `DiscoveryToast` (Label) | Shows "Discovered: …" for a few seconds when any place is discovered, also a place of a level loaded later (`watch_added_places`; off: only the places there at startup) |

No other addon is needed.

## Setup

1. Copy this folder to `res://addons/iso_orbit/points_of_interest/`.
2. Put the player's body in the group `player` (or set `player_group`).
3. For each place, add an `Area3D` with `point_of_interest.gd` and a collision shape, set its `title`, and make its
   `collision_mask` include the player's physics layer.
4. Add `discovery_toast.tscn` to your HUD. It connects to every place in the scene at startup, and to the places
   added later unless `watch_added_places` is off; no wiring needed.

A place remembers that it was found only while it exists: when its level is freed, the place goes with it, and the
same level loaded again has it not found. Remembering what was found is the game's job: the template's
`gdscript/main.gd` keeps the found places per level and calls `mark_discovered()` when a level is loaded again.

The message text and the titles go through the translation server, so they can be localized. The look comes from the
theme type variation `DiscoveryToast`.

## Documentation

In the template repository: `docs/en/systems/world-and-navigation.md`, `docs/en/systems/ui.md` and
`docs/en/systems/levels.md`.

---

*This page matches Iso & Orbit 1.2.0.*
