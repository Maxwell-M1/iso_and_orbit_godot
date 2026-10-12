# Editing scenes in the editor

[← Documentation index](index.md)

The demo's scenes are meant to be edited in the editor. Nodes are linked in the Inspector; the components check their
setup and show a warning in the Scene dock while something is missing or wrong; and what the game sets up at the start
(the camera's view, a character's model and the name over its head, the title on a portal's sign, the size of a prop)
shows in the editor too. These previews are never saved: a saved scene holds what you set, so its diff shows only
your changes.

## Links and warnings

A component that works with other nodes has links to them as properties: `PlayableHero.character`,
`GroundCharacter.mover`, `OccludedSilhouette.target` and so on. Set them in the Inspector by dragging a node into the
field. While a link the component needs is empty, or a node stands where it cannot work (a `NavigationMover` not under
the body it moves, a `LevelPortal` without a target scene, an input action missing from the Input Map), the Scene dock
shows a warning sign next to the node; point at it for the reason. The warnings follow your edits: they come and go as
you change a property, add or remove a child, edit a route's curve, a ledge guard's `max_drop` or a character's fall
settings. The scene does not need to be reopened.

The components check themselves in the editor because their scripts are tool scripts. In the editor they only check
and preview: no input, physics or timers run there, and nothing they compute is written into the scene. In the game
they work as they always did.

## The start level

`gdscript/main.tscn` holds the level host, `Levels`, with the start level, `World`, as its child, and
`Levels.initial_level` names it. Without it the host starts on its first `Node3D` child; with several 3D children and
none named it shows a warning. See [Levels](systems/levels.md).

## The camera in the editor

`Hero/CameraRig` shows the view the game starts with: the rig stands at the target, `focus_height` above it, turned
by `start_yaw`, tilted and as far away as `start_zoom` sets, and the arm shows the camera at that distance. Change
these properties to frame the start; the 3D view follows at once.

The game sets the rig's transform, the camera's transform and, under a rig, the arm's `length` every frame, so in the
editor they are previews too: a rig or a camera moved by hand goes back where the game puts it, and under a rig the
arm's `length` is read-only. Saving keeps the values the scene was loaded with, so the preview never shows up in a diff,
and the scene that places the hero never gets a copy of its camera's place. A rig without a target is different: the
game does not move it, so its position is yours and is saved as you set it; only its turn is previewed.

## Settings from the settings window

`SettingsApplier` applies the player's saved settings (F10) over the values set in the scene. The scene's values are
the defaults too: a setting the player has not changed keeps the scene's value, and **Reset all** returns to them.
Turn off `SettingsApplier.use_saved_settings` to run the scene's nodes exactly as set while you tune them in the
Inspector; the settings window then leaves them alone and changes only the engine settings (full screen, frame rate,
V-Sync, physics interpolation, interface scale, language, volume). See [Settings](settings.md).

## Solid props

A solid prop is a scene with a `StaticProp` root, a `StaticBody3D` with `shared/world/props/static_prop.gd`. Its
visible parts and collision shapes are children of the root, grouped, so a click in the 3D view selects the whole
prop.

- **Move** it by the root.
- **Resize** it with `dimensions`, in meters along the prop's own axes: the visible parts and the collision change
  together. 0 on an axis keeps the size of the parts along it, so a new prop, at `(0, 0, 0)`, has the size it was made
  with, and a pillar made taller needs only its height. Do not scale the root, it shows a warning then; do not scale
  its children either, and a mesh made bigger or smaller needs its collision shape changed with it.
- **Recolor** it with `surface_material`: it replaces the material of all its visible parts; empty keeps their own.

The props the levels share are scenes in `shared/world/props/`: `stone_pillar.tscn`, `solid_box.tscn` (the walls,
crates, the platform and its ramp), `grove_tree.tscn`, `rock.tscn` and the solid props of the forest, the camp and the
farmstead (a bush has no collision and is not a `StaticProp`). An instance sets its own `dimensions` and
`surface_material`; edit the prop's scene to change all its instances. A part used once stands right in its level with a
`StaticProp` root of its own: the meadow's ground, the plateau's stairs, the maze's hedges, the figures at the places,
the ten hero looks, the island's ground and edge walls. The hedges keep the size of their meshes: their leaves need a
mesh subdivided into cells of about 25 cm, so a hedge of another size gets a mesh of that size, not `dimensions`.

Edit the parts as usual: move a child, change a mesh or a shape, add a part. The prop takes the change as its new shape:
on the axes where `dimensions` is 0 it takes the new size of the parts, on the others it keeps its stretch. A new prop
is not grouped by itself: select its root and press the Group button of the 3D view's toolbar. Saving keeps the parts as
you made them; the resize is a preview, applied again when the scene opens and when the game starts. A resized shape is
a copy of its own, so resizing one instance never changes another. A round or turned shape stretched unevenly becomes a
convex shape stretched the same way.

Keep moving parts below a plain `Node3D`: a node that animates itself must not be the node the prop resizes. On the
mountain the prop resizes and places `CrystalAnchor`, and its child `Crystal` spins and bobs.

After changing the collision of a prop (moving, resizing or editing it), rebake the navigation mesh, see
[World and navigation](systems/world-and-navigation.md#rebaking-the-navigation-mesh).

## Patrols

The knight on the meadow walks a route. Open `shared/world/world.tscn` and select `Routes/KnightPatrol`, a `Path3D`:
edit its curve in the 3D view with the curve tools, and the knight walks the line drawn there, turning smoothly through
its bends. To round a corner, turn on **Select Control Points** on the toolbar and Shift+drag from the point to pull
out its handles. Keep the line clear of the hedges by about the knight's width: along it he does not look for a way
around them. The knight
(`NavigationRegion3D/Characters/Knight`, an instance of `gdscript/npc/knight_patrol.tscn`) refers to it in **Route**.
From his place by the house he walks to the route's first point, and after the last one he comes back by the shortest
way: these two ways are not part of the drawn line.
The route belongs to the level, so the same character can walk another route on another level. The island's ranger
(`island_patrol.tscn`) walks `Routes/IslandPatrol` on the island. A route with no points, or one inside the
character, shows a warning on the character's root, `Knight`.

In the editor a patrolling character shows its model and the name over its head; neither is saved into the scene. Its
root sets **Model Scene**, **Speaker Name** (over the head and in the subtitles) and **Blocked Line** (what it says when
someone has stood in its way long enough). Its walk is set on `Character/PatrolController` (turn on
**Editable Children**): **Cycle Wait**, the wait at home after a round (10 s); **Waypoint Wait**, the stop at each point
of the curve; **Blocked Delay**, how long someone must stand in the way before the line (2.5 s for the knight);
**Blocking Distance** and **Blocking Angle**, the area in front of him where someone stops him: 1 m ahead, widening by
25° to each side, like the beam of a flashlight. At his sides and behind him nobody stops him. See
[Locomotion](systems/locomotion.md#patrolcontroller-walking-a-route).

## Checking the editor's part

`tests/run_checks.gd` checks the game, but it cannot run the editor. The editor's part, that is the warnings following
the edits, the previews and what the scenes are saved with, has its own checks: open `tests/editor_tool_checks.tscn` and
press **Run Checks** in the Inspector. The result shows in **Status** and **Results** there and in
`.godot/editor_tool_checks/results.json`; the output gets the status line. The checks save their scenes only into that
folder, which every run clears: no scene of the project and none of the player's settings is written. See
[Tests](testing.md#checks-in-the-editor).

---

*This page matches Iso & Orbit 1.3.0.*
