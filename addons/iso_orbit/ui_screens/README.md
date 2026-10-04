# UI Screens

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Windows over the game as a stack: open one on top of another, close the top one with Esc, pause the game and show the
mouse cursor while any window is open, give keyboard focus to the window and return it when the window closes. Plus
an FPS counter that keeps working while the game is paused.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `ui_root.gd` | `UiRoot` (CanvasLayer) | The window stack: `open()`, `close_top()`, `toggle()`; pause, cursor, focus |
| `ui_screen.gd` | `UiScreen` (Control) | Base of a window: `initial_focus`, the `close_requested` signal |
| `fps_counter.gd`, `fps_counter.tscn` | `FpsCounter` (Label) | Frames per second, also while paused |

No other addon is needed.

## Setup

1. Copy this folder to `res://addons/iso_orbit/ui_screens/`.
2. Add a `CanvasLayer` with `ui_root.gd` to the main scene. It runs while the game is paused.
3. Make each window a scene whose root extends `UiScreen`. A window never closes itself: it calls `request_close()`
   and `UiRoot` closes it.
4. Open windows with `UiRoot.open(scene)`. To open one with a key, set `settings_screen` to its scene and add the
   input action `toggle_settings` (or set `settings_action`). Esc is the built-in `ui_cancel`.
5. Optional: add `fps_counter.tscn` to your HUD.

The look comes from the project theme; `FpsCounter` uses the theme type variation `FpsCounter`.

## Documentation

In the template repository: `docs/en/systems/ui.md`.

---

*This page matches Iso & Orbit 1.1.0.*
