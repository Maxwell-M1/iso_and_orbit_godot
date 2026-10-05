# Levels

[← Documentation index (template repository)](../../../docs/en/index.md)

**English** · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Levels that change behind a loading screen while the player's character and the interface stay: a level host that
loads the next level in the background, frees the old one and tells the game where to put the character; portals
that lead to other levels, by confirmation or at once; spawn points; and a loading screen with the last frame of the
game blurred behind the name of the place, a progress bar and tips.

Part of Iso & Orbit, a camera and character controller template for Godot 4.7. MIT license (see `LICENSE`).

## Contents

| File | Class | Job |
|---|---|---|
| `level_host.gd` | `LevelHost` (Node3D) | Holds the current level; `change_level(path, spawn_name, title)` loads the next one in the background, swaps it in and reports each step with a signal; re-emits the travellers of the level's portals, also of portals added later, as `portal_entered` and `portal_exited` |
| `level_portal.gd` | `LevelPortal` (Area3D) | A way to another level: reports a traveller entering and leaving, travels on `travel()` or by itself (`auto_travel`), writes its `title` into an optional sign |
| `spawn_point.gd` | `SpawnPoint` (Marker3D) | Where a character appears, by name; it faces along the marker's −Z |
| `loading_screen.gd`, `loading_screen.tscn`, `loading_background.gdshader`, `loading_screen_theme.tres` | `LoadingScreen` (CanvasLayer) | The screen while a level loads: the last frame blurred and darkened, slowly coming closer, the name of the place, a bar that never goes back, tips; no input event reaches the game while it is up |

No other addon is needed: the level host knows nothing about the character, the camera or the interface. Your game
connects them to its signals.

## Setup

1. Copy this folder to `res://addons/iso_orbit/levels/`.
2. In the main scene (the one that stays), add a `Node3D` with `level_host.gd` and put the start level under it as its
   only child. The player's character, the camera and the interface go next to the host, not into a level.
3. Add `loading_screen.tscn` to the main scene and set it as the host's `loading_screen`, or leave that empty to
   change levels without a screen.
4. In every level, add a `Marker3D` with `spawn_point.gd` named `default` (`spawn_name`) on the ground, and more
   points with other names where portals arrive.
5. For a portal, add an `Area3D` with `level_portal.gd` and a collision shape; its `collision_mask` must include the
   character's layer. Set `target_level` (a scene file), `target_spawn` and `title`. Put the character's body in the
   group `player`, or set `traveller_group`.
6. Connect the host's signals in your main script:
   - `level_change_started`: hide what should not be in the loading screen's picture and take the controls away;
   - `level_loaded(level, spawn)`: put the character at `spawn` (with `GroundCharacter.teleport()` it arrives without
     a jerk) and turn the camera;
   - `level_change_finished`: give the controls back;
   - `level_change_failed(path, error)`: give the controls back and show what you hid; the current level stays. After
     a failed load only this signal comes, never `level_change_finished`;
   - `portal_entered(portal)` and `portal_exited(portal)`: show and hide your offer to travel; on confirmation call
     `portal.travel()`.

The host does not announce the start level: set it up in your main script's `_ready()` with `get_current_level()` and
`find_spawn_point()`.

By default a portal asks first: the game shows an offer and calls `travel()`. With `auto_travel` on it travels as soon
as the character walks in, like a door or the edge of a map. The change starts right after the request, not inside it,
so a portal can ask from a physics callback. The game is paused for the load and the swap; the host waits, still
paused, until the navigation map has the new level, then ends the pause and draws a few frames behind the screen
before it fades out, so shaders compile out of sight. The host's settings: `min_loading_time` (0.6 s, the shortest
time the screen stays), `warmup_frames` (3, the frames drawn behind it) and `navigation_timeout` (2 s, the longest wait
for the map); `is_changing()` tells whether a change goes on. `change_level()` returns `ERR_BUSY` while a change goes
on, `ERR_FILE_NOT_FOUND` and `ERR_INVALID_PARAMETER` for a wrong file; a load that fails later keeps the current level
and comes as `level_change_failed`, and the next request loads the file anew. The host ends only the pause it started:
open a window that pauses the game after `level_change_finished`. The screen and the waits go by real time, whatever
`Engine.time_scale` is.

The look of the loading screen is in `loading_screen_theme.tres` (the type variations `LoadingTitle`, `LoadingBar`,
`LoadingTip`). Give the screen's root another theme for another look, or make your own screen from a copy of
`loading_screen.tscn`: the script needs the nodes `Root` and, by unique name, `Background`, `Title`, `Bar` and `Tip`.
There are no tips until you add them to `tips`; each tip is translated, then passed through `tip_format` if code sets
it (`InputNames.format` from the `ui_screens` addon puts in the keys bound now: `{sprint}` shows "Shift").

## Documentation

In the template repository: `docs/en/systems/levels.md` and `docs/en/integration.md`.

---

*This page matches Iso & Orbit 1.2.0.*
