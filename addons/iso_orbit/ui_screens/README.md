# UI Screens

[← Documentation index (template repository)](../../../docs/en/index.md)

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Windows over the game as a stack: open one on top of another, close the top one with Esc, pause the game and show the
mouse cursor while any window is open, give keyboard focus to the window and return it when the window closes. Plus
an FPS counter that keeps working while the game is paused, and the names of the keys bound to input actions for the
texts on the screen.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `ui_root.gd` | `UiRoot` (CanvasLayer) | The window stack: `open()`, `close_top()`, `toggle()`; pause, cursor, focus |
| `ui_screen.gd` | `UiScreen` (Control) | Base of a window: `initial_focus`, the `close_requested` signal |
| `fps_counter.gd`, `fps_counter.tscn` | `FpsCounter` (Label) | Frames per second, also while paused |
| `input_names.gd` | `InputNames` (RefCounted, static) | The key or mouse button of an action, by the player's layout and translated: `of_action()`, `of_event()`; `format()` puts the names into a text by tokens such as `{sprint}` |
| `action_texts.gd` | `ActionTexts` (Node) | Fills in the tokens in the texts of the controls under its parent, again when the language changes and on `refresh()` |

No other addon is needed.

## Setup

1. Copy this folder to `res://addons/iso_orbit/ui_screens/`.
2. Add a `CanvasLayer` with `ui_root.gd` to the main scene. It runs while the game is paused.
3. Make each window a scene whose root extends `UiScreen`. A window never closes itself: it calls `request_close()`
   and `UiRoot` closes it.
4. Open windows with `UiRoot.open(scene)`. To open one with a key, set `settings_screen` to its scene and add the
   input action `toggle_settings` (or set `settings_action`); without it `UiRoot` reports it once at the start, and
   the key does nothing. Esc is the built-in `ui_cancel`.
5. Optional: add `fps_counter.tscn` to your HUD.
6. Optional: write the keys in your texts as action tokens, `{jump} — jump`, and add an `ActionTexts` node to the
   scene (it serves the controls under its parent). After the player changes the keys, call
   `get_tree().call_group(ActionTexts.GROUP, &"refresh")`. Controls that compose their own text can implement
   `refresh()` and join the same group. To name the mouse buttons, "Space" and unassigned actions in other languages,
   give the names of `InputNames.get_mouse_names()`, "Space", `InputNames.UNBOUND`, `InputNames.LEFT_KEY` and
   `InputNames.RIGHT_KEY` entries in your translations. The last two preserve `%s` for the key's name.

`UiRoot` pauses only a running game and ends only its own pause: a game already paused when a window opens (by a
level change, for example) stays with whoever paused it, and if that ends the pause, the game goes on behind the
window.

The look comes from the project theme; `FpsCounter` uses the theme type variation `FpsCounter`.

## Documentation

In the template repository: `docs/en/systems/ui.md` and, for windows during a level change,
`docs/en/systems/levels.md`.

---

*This page matches Iso & Orbit 1.2.0.*
