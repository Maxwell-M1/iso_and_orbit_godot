# Levels

[← Documentation index](../index.md)

How the game changes levels: the level host and its loading screen, portals and spawn points, the playable hero that
moves between the levels, and the demo's two levels. The component is `addons/iso_orbit/levels/`; the hero, the offer
to travel and the game shell are demo files built from the components.

## The shell

`gdscript/main.tscn` is the scene that stays while the game runs. The current level is a child of the level host; the
hero and the interface are its siblings, so the levels change around them.

| Node | Class | Job |
|---|---|---|
| `Levels` | `LevelHost` | Holds the current level as its only child and changes it |
| `Levels/World` | | The start level, `shared/world/world.tscn`, placed in the editor |
| `Hero` | `PlayableHero` | The player's character with its input, camera, click marker and path line |
| `Hud/TravelPrompt` | `TravelPrompt` | The offer to travel on a pad |
| `LoadingScreen` | `LoadingScreen` | The screen while a level loads |

`gdscript/main.gd` connects them:

| Signal | What the shell does |
|---|---|
| `LevelHost.portal_entered(portal)` | Shows the offer for the portal, unless it travels by itself. In two portals at once, the offer is for the one entered last |
| `LevelHost.portal_exited(portal)` | Hides that offer; if the hero still stands in another portal, offers that one |
| `TravelPrompt.confirmed(portal)` | `portal.travel()` |
| `LevelHost.level_change_started` | Hides the offer and the HUD, takes the hero's controls away |
| `LevelHost.level_loaded(level, spawn)` | Marks the places found before as found, puts the hero at `spawn` with the camera behind it, shows the HUD under the screen |
| `LevelHost.level_change_finished` | Gives the controls back |
| `LevelHost.level_change_failed` | Shows the HUD, gives the controls back and offers the portal again if the hero still stands in it |

At the start the shell puts the hero at the start level's `default` spawn point with the camera at its own start
angle (`OrbitCameraRig.start_yaw`); on arrival through a portal the camera looks the way the spawn point faces. The
places found are remembered for the session by the level's file and the place's path in it: a level loaded again marks
them with `PointOfInterest.mark_discovered()`, and they are not announced a second time. A saved game would keep the
same list.

The hero instance survives the change, preserving stamina, appearance and floating state. Teleportation clears its
movement and resets camera tracking; the player's settings remain in the `Settings` autoload.

## A level change

The player stands on the pad and presses E or clicks the offer:

1. The portal asks to travel; the level host checks the file, asks the loader for it and answers at once. The change
   itself starts right after, not inside the request: a portal asks from a physics callback, where a level must not
   leave the tree. It begins with `level_change_started`.
2. The game is paused, unless it already is. While paused, the camera lets go of the cursor and the input shows it.
3. The loading screen takes the next drawn frame (the HUD is already hidden), blurs and darkens it, and fades in over
   0.35 s. The frame slowly comes 6% closer, the name of the place and a tip appear, and the bar starts.
4. The level scene loads in the background (`ResourceLoader.load_threaded_request`). Its files fill the bar up to 85%,
   the built level 90%.
5. The old level leaves the tree and is freed; the new one takes its place; `level_loaded` tells the shell where to put
   the hero. Its portals are connected; the old level's portals were disconnected before it left. If something has
   ended the pause meanwhile (a window closed), the host pauses the game again for the swap.
6. Still paused, the host waits until the navigation map has taken in the new level (95%): every navigation region of
   the level is in its map, but not longer than `navigation_timeout` by the clock. The navigation server works while
   the game is paused, so from the first frame of the game paths are found on the new level.
7. The pause ends, and the host draws `warmup_frames` frames behind the screen: the new level's shaders compile, the
   hero settles on the ground.
8. When `min_loading_time` has passed since the start, the bar fills to the end and the screen fades out; then
   `level_change_finished`.

The level host's settings:

| Property | Default | Meaning |
|---|---|---|
| `loading_screen` | empty; the demo sets its `LoadingScreen` | The screen over the game while a level loads. Empty: the level changes in front of the player |
| `min_loading_time` | 0.6 s | The screen stays at least this long, so that a fast load does not flash it |
| `warmup_frames` | 3 | Frames drawn behind the screen before it goes, so that the shaders of the new level compile out of sight |
| `navigation_timeout` | 2 s | The longest wait for the navigation map, by the clock; the wait ends as soon as every region of the new level is in the map. 0: do not wait; until the map takes in the level, a path would be searched on the old one, or on none |

The level host's signals and methods:

| Signal or method | Meaning |
|---|---|
| `level_change_started(path)` | A change has started; the old level is still in place |
| `level_loaded(level, spawn)` | The new level is in place, the old one is gone; put the character at `spawn`. The screen still covers the game |
| `level_change_finished(level)` | The change is over, the screen is gone |
| `level_change_failed(path, error)` | The level could not be changed, the current one stays: `ERR_CANT_OPEN` when the load failed, `ERR_INVALID_DATA` when the scene's root is not a `Node3D`. Comes instead of `level_change_finished` |
| `portal_entered(portal)`, `portal_exited(portal)` | A traveller has entered or left a portal of the current level |
| `change_level(path, spawn_name = &"default", title = "")` | Starts a change and returns at once, see below |
| `get_current_level()` | The level the game is on; `null` before the first one |
| `is_changing()` | A change goes on: from an accepted `change_level()` until `level_change_finished` or `level_change_failed` |
| `find_spawn_point(spawn_name = &"default", level = null)` | A spawn point of a level, see [Spawn points](#spawn-points) |

The start level placed in the editor is not announced: no `level_loaded` comes for it, and the game sets it up in its
`_ready()` with `get_current_level()` and `find_spawn_point()`, as `gdscript/main.gd` does.

A request while a change goes on is refused (`ERR_BUSY`), so a second press of E or a portal entered during the change
does nothing. `change_level()` checks the file at once: a missing file returns `ERR_FILE_NOT_FOUND`, a file that is not
a scene `ERR_INVALID_PARAMETER`, and nothing happens. A scene that fails to load, or whose root is not a `Node3D`,
keeps the current level: an error message goes to the output, the pause ends, the screen fades out without waiting for
`min_loading_time`, and then `level_change_failed` comes. The failed load is collected, so a later request loads the
file anew, after a fix for example.

The host ends only the pause it started. Open a window that pauses the game (a menu) only after
`level_change_finished`: opened during the change, it finds the game paused and leaves the pause to the host, which
ends it, so the game goes on behind the window. In the demo the rule holds by itself: the loading screen lets no input
through, F10 included, until it closes. A window closed during the change does no harm: the host pauses the game again
for the swap. If the host leaves the tree in the middle of a change (the game scene changes), the change ends with it,
and so does its pause.

The screen, its bar and `min_loading_time` go by real time, whatever `Engine.time_scale` is: in slow motion a change
takes as long as at full speed.

Warm-up hides some first-use work behind the screen; it is not a guarantee against later shader or asset stalls.
Measure transitions with your actual level content and target renderer.

## Portals

`LevelPortal` is an `Area3D`: a pad, a door, the edge of a map. It needs a collision shape and a `collision_mask` that
sees the traveller's layer (2, the characters); a layer of its own is not needed. The level host connects the portals
of the current level, also those added to it later: a portal that opens after a quest, for example.

| Property | Default | Meaning |
|---|---|---|
| `target_level` | | The scene file of the level to travel to. A path, not a loaded scene, so two levels can lead to each other; a path picked in the inspector as `uid://` works too |
| `target_spawn` | `default` | The spawn point to arrive at |
| `title` | | The name of the place the portal leads to: for the offer, the loading screen and the sign. Translated where it is shown |
| `title_label` | | A `Label3D` over the portal that shows `title`; the portal writes the title into it |
| `traveller_group` | `player` | Who can travel: a body in this group |
| `auto_travel` | off | Travel as soon as a traveller enters, without an offer |

The combinations:

- **The default, the demo's pads:** the portal reports a traveller entering and leaving (`traveller_entered`,
  `traveller_exited`), the level host passes this on as `portal_entered` and `portal_exited`, and the game decides
  what to offer. The shell shows "E Teleport to <place>"; walking away hides it. E works with Shift or another
  modifier held too, since the hero often sprints onto the pad. `travel()` starts the change.
- **`auto_travel` on:** a door or the edge of a map. The portal travels the moment a traveller enters; the shell shows
  no offer for it.
- **No loading screen:** leave `LevelHost.loading_screen` empty. The level still loads in the background and the game
  is still paused for the swap and the navigation, but the player sees the swap.
- **A portal used by code:** `LevelHost.change_level(path, spawn_name, title)` does the same as a portal; a cutscene or
  a menu can call it.

`travel()`, and `auto_travel` on entering, emit `travel_requested(portal)`; the level host connects it, a game without
the host connects it itself. `has_traveller()` tells whether a traveller stands in the portal now. Every portal is in
the group `level_portals`.

A character that arrives inside a portal's area would be offered to travel back at once. Inside an `auto_travel`
portal it is seen when the physics runs again, during the warm-up, while the change still goes on: its request gets
`ERR_BUSY`, which the host ignores, and the character stays without travelling until it walks out and in again; if the
change is already over, it travels back at once. So spawn points stand beside the pads, out of the portals' areas.

## Spawn points

`SpawnPoint` is a `Marker3D` with a `spawn_name`, `default` by default. A character appears where the marker is and
faces along its −Z, the forward direction of a node (the gizmo's blue axis points the other way); `get_facing()` gives
that direction, horizontal. Put the marker on the ground: the character's feet go there, and above the ground it would
fall. Every spawn point is in the group `spawn_points`.

`LevelHost.find_spawn_point(name, level)` returns the point of `level` (the current level if not given; it must be in
the tree) with that name, or the `default` one when there is none by that name, or `null` if there is neither. During
a change a missing point is also a warning in the output, and with no point at all the host passes the level itself as
`spawn`: the character arrives at the level's origin. Every level needs a `default` point: the game starts there, and
a portal without `target_spawn` arrives there. The name is `spawn_name`, not the node's name: the demo's `default`
points are the nodes `Start` and `Arrival`. Give the other points names of their own: a second point left as `default`
is another `default`, and asked for by that name, the first in tree order wins.

## The loading screen

`LoadingScreen` is a `CanvasLayer` on layer 20, above the windows, that works while the game is paused. While it is
up no input event reaches the game, so neither a click nor F10 does anything (`Input` still tells which keys are
held).

| Property | Default | Meaning |
|---|---|---|
| `tips` | empty; the demo sets six control tips on its instance in `gdscript/main.tscn` | Shown one at a time in a random order; each is translated, then passed through `tip_format` |
| `tip_format` | empty (a `Callable`, set by code); the demo sets `InputNames.format` in `gdscript/main.gd` | Turns a translated tip into the text shown. The demo's tips name keys by tokens such as `{sprint}`, and `InputNames.format` puts in the keys bound now, see [Key names in texts](ui.md#key-names-in-texts). Empty: a tip is shown as translated |
| `tip_time` | 6 s | How long each tip stays; then it fades out over 0.25 s, the text changes, and the next one fades in over 0.25 s |
| `fade_time` | 0.35 s | How long the screen takes to come and to go |
| `zoom` | 0.06 | How much closer the background comes, as a share of its size |
| `zoom_time` | 12 s | How long it takes to come that close |

The background is the last frame of the game, shrunk eight times and blurred a little more by a shader
(`loading_background.gdshader`: the blur, the darkening, darker corners and a darker bottom under the text). Where no
window draws (a run without a window, a minimized window) there is no frame, and the screen is a plain dark color.
The bar fills toward the progress quickly while far behind and never goes back, also when the loader reports less
than before.

The look is in `loading_screen_theme.tres`, the theme of the screen's root: the type variations `LoadingTitle` (44 px,
warm white with a shadow), `LoadingBar` (a thin gold bar) and `LoadingTip` (18 px). Give the root another theme for
another look, or make your own screen from a copy of `loading_screen.tscn`: the nodes may move and change, but the
script needs the `Control` `Root` and, by unique name, the `TextureRect` `Background`, the `Label`s `Title` and `Tip`
and the `ProgressBar` `Bar`. A script that extends `LoadingScreen` can override `open()`, `set_progress()` and
`close()`; the scene still needs those nodes. The queries: `is_open()` (the screen is up, or coming or going),
`get_shown_progress()` (how much of the bar is filled, 0 to 1) and `get_tip()` (the source template of the tip shown,
empty without tips). `refresh()` translates and formats that tip again without restarting its timer. The demo adds
the loading screen to `ActionTexts.GROUP`, so refreshing key names also updates an already visible loading tip.

## The playable hero

`gdscript/player/playable_hero.tscn` is the hero the player controls, ready to put into a game scene: the character
(`player.tscn`, in the group `player`), `PointClickMoveInput`, `CharacterActionInput`, the camera rig with its arm and
camera, the click marker and the path line, with their settings and their six connections inside the scene. The
character scene itself has none of this, so an AI can drive the same `player.tscn`.

`PlayableHero` (`playable_hero.gd`) gives the parts as typed properties (`character`, `input`, `actions`,
`camera_rig`, `camera_arm`, `camera`, `click_marker`, `path_view`, and of the character `sounds`, `appearance`,
`hover`, `silhouette`) and three things to do with them:

| Call | Effect |
|---|---|
| `teleport(position, facing = Vector3.ZERO, turn_camera = true)` | The press under way is forgotten (`PointClickMoveInput.cancel()`), the character is put there at once (`GroundCharacter.teleport()`), the camera looks along `facing` if asked, snaps into place and follows from scratch. With `facing` left at `Vector3.ZERO` the character keeps its facing and the camera its direction |
| `place_at(marker, turn_camera = true)` | `teleport()` to a marker, facing along its −Z |
| `controls_enabled` | Off: the press under way is forgotten, the sprint key is let go, and the input nodes stop; the camera stays the player's. A run to a clicked point goes on: stop it with `character.mover.stop()` or `teleport()`. On: the controls come back, and the input nodes process as they did before |

The root of the hero is never moved: the character moves inside it, and the camera follows the character. The hero
works without the levels component too: a game with its own level system calls `place_at()` where its levels are
ready.

## The demo's levels

**The meadow** (`shared/world/world.tscn`, see [World and navigation](world-and-navigation.md)) has, under `Travel`:
the spawn point `Start` (`default`) at the origin facing north; the pad
`IslandPad` by the Ancient Circle, 12 m north of the start and in view from it, leading to the island; and the spawn
point `FromIsland` (`from_island`) beside the pad, facing east, with the pad to the hero's left, a little behind.

**Lonely Isle** (`shared/world/island/island.tscn`) is a round island 30 m across in a lake, made of the meadow's
props, materials and shaders, with no files of its own besides two materials:

- the grass is `island_ground.tres`: the meadow's ground with its dirt roads turned off (`roads`), since the roads are
  drawn in world coordinates and belong to the meadow;
- the lake is `lake_water.tres`: the well's still water in a lighter blue with a stronger ripple, a 600 m plane to the
  horizon;
- a rocky shore under the grass edge and boulders in the shallows;
- invisible walls in a ring at 14.5 m (`Edge`, 24 boxes) keep the hero on the island; they are on the physics layer
  `bounds` (4), which the character collides with and clicks and the camera do not see, so a click on the water lands
  on no wall and the camera passes through them; the island's navigation mesh is baked from layers 1 and 4, so paths
  keep off the walls;
- Hermit's Camp in the north: a tent, a campfire and barrels, a place that is discovered (its `PointOfInterest` is
  under `Places`);
- the spawn point `Arrival` (`default`) in the south facing north, toward the camp, and the pad `HomePad` back to the
  meadow (spawn point `from_island`), to the left of the hero's back;
- its own navigation mesh, baked the same way as the meadow's (see [Rebaking the navigation
  mesh](world-and-navigation.md#rebaking-the-navigation-mesh)).

Both levels share the environment, `shared/world/world_environment.tres`: the sky, the fog and the ambient light. Each
level has its own copy of the sun (`Sun`).

The pads (`shared/world/props/teleport_pad.tscn`) are one scene: a `LevelPortal` with a stone disc, a glowing inlay, a
spinning crystal above head height, a light and a sign with the name of the place. They have no collision, so the
navigation meshes under them did not change.

## Adding a level

1. Make a scene with a `Node3D` root: the level's light and environment, a `NavigationRegion3D` with the ground and
   the props, and a `SpawnPoint` with `spawn_name` `default` on the ground. Invisible walls at the edge go on layer 4
   (`bounds`).
2. Create a unique `NavigationMesh` and bake it for this level: use static colliders, physics layer 1 and also layer
   4 if it has invisible edge walls. Match the map's 0.025 m cell height and 0.25 m cell size; start with radius
   0.5 m, maximum climb 0.3 m and maximum slope 40°. For the supplied 1.8 m capsule, use agent height 1.8 m and enable
   `filter_walkable_low_height_spans` to exclude low ceilings. If you copy a demo mesh resource, make it unique
   before rebaking and review its height/filter settings. See
   [World and navigation](world-and-navigation.md#physics-layers-and-navigation).
3. Add a portal to it from another level: an instance of `teleport_pad.tscn`, or your own `LevelPortal`, with
   `target_level` set to the new scene, and a portal back. Put a spawn point beside each pad and name it in the other
   pad's `target_spawn`.
4. Add the titles of its portals and places to the translations: `localization_checks.gd` walks every level the
   portals lead to from the start level and reports a missing string. A level reached only by `change_level()` from
   code is not checked.

---

*This page matches Iso & Orbit 1.2.0.*
