# Points of Interest

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Places to discover: an area that reports the first time the player enters it, and an on-screen message
"Discovered: …" that finds every place by itself.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest` (Area3D) | Emits `discovered(title)` the first time a body in the group `player` enters; joins the group `points_of_interest` |
| `discovery_toast.gd`, `discovery_toast.tscn` | `DiscoveryToast` (Label) | Shows "Discovered: …" for a few seconds when any place is discovered |

No other addon is needed.

## Setup

1. Copy this folder to `res://addons/iso_orbit/points_of_interest/`.
2. Put the player's body in the group `player` (or set `player_group`).
3. For each place, add an `Area3D` with `point_of_interest.gd` and a collision shape, set its `title`, and make its
   `collision_mask` include the player's physics layer.
4. Add `discovery_toast.tscn` to your HUD. It connects to every place in the scene at startup; no wiring needed.

The message text and the titles go through the translation server, so they can be localized. The look comes from the
theme type variation `DiscoveryToast`.

## Documentation

In the template repository: `docs/en/systems/world-and-navigation.md` and `docs/en/systems/ui.md`.

---

*This page matches Iso & Orbit 1.0.0.*
