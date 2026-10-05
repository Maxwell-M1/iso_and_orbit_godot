# Occluded Silhouette

[← Documentation index (template repository)](../../../docs/en/index.md)

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Shows a character through whatever hides it: the body as one flat shape, the items in its hands outlined on top,
and a rim around everything. Where the character is visible, nothing is drawn. The model's own materials stay
untouched, so the same model elsewhere has no silhouette.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Job |
|---|---|
| `occluded_silhouette.gd` | `OccludedSilhouette` (Node): puts the passes on every mesh of the model as `material_overlay`, including meshes added later |
| `silhouette_mask.gdshader`, `.tres` | Marks where the character is visible itself |
| `silhouette_body.gdshader`, `.tres` | The flat body fill |
| `silhouette_gear.gdshader`, `.tres` | The lighter fill of the items in hand |
| `silhouette_outline.gdshader`, `.tres` | The rim around the whole shape |
| `silhouette_common.gdshaderinc` | Shared code: depth in meters, the stencil layout |

No other addon is needed.

## Setup

1. Copy this folder to `res://addons/iso_orbit/occluded_silhouette/`; the materials refer to the shaders by that path.
2. Add a `Node` with `occluded_silhouette.gd` to the character. Set `target` to the node that holds the model (the
   shipped hero uses `Character/Visual`) and
   assign `silhouette_mask.tres`, `silhouette_body.tres`, `silhouette_gear.tres` and `silhouette_outline.tres` to
   `mask`, `body_fill`, `gear_fill` and `outline`.
3. Meshes under nodes named in `gear_nodes` (`RightHand`, `LeftHand`) count as items in hand. On a model without those
   nodes, all meshes get the body fill; change the names if your equipment uses a different hierarchy.

The colors are the `color` parameters of the materials, the rim width is `width` in `silhouette_outline.tres`, and
`outline_enabled` turns the rim off. The silhouette needs an obstacle at least 30 cm in front of the character
(`min_gap`, a parameter of the body, gear and outline materials from `silhouette_common.gdshaderinc`: change it in all
three).

The component assigns each mesh's `material_overlay`, including meshes added later when a look changes. If your
model already uses that property for another effect, choose which overlay should own it. The materials are copied
into pass chains when the component becomes ready, so set colors and `min_gap` in the materials before starting the
scene; `outline_enabled` can change during play.

Uses the stencil buffer, which is experimental in Godot 4.5+. Tested with the Forward+ renderer.

## Documentation

In the template repository: `docs/en/systems/characters.md` (including replacing the model) and
`docs/en/integration.md` (copying the playable hero).

---

*This page matches Iso & Orbit 1.2.0.*
