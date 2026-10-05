# Getting started

[← Documentation index](index.md)

## Requirements

- Godot 4.7.2. The standard build is sufficient: the project uses GDScript and does not need a .NET SDK.
- Nothing else for the demo: Jolt Physics is built into the engine, the renderer is Forward+, and all assets are in
  the repository.

## Open and run

1. Clone the repository.
2. In the Project Manager, choose **Import** and pick `project.godot`, then open the project. The first import takes
   a moment, since the `.godot/` cache is not in the repository.
3. Press F5. The main scene is `res://gdscript/main.tscn`.

The demo loads your previously saved settings. Use **F10 → Reset all** for the defaults described here. In a fresh
clone, wait for imports to finish before opening scripts or running tests. Do not copy a `.godot/` cache from another
project.

## What you see

The hero stands at the spawn point in the middle of a fenced glade. The controls are listed in the top-left corner,
the frame rate in the top-right one.

- **Left click** on the ground: the hero runs there around obstacles, and a marker shows the point.
- **Hold the left button**: the hero runs after the cursor.
- **Right button + mouse**: orbit the camera. **Wheel**: zoom.
- **Right button, then left**: run where the camera looks. **Left button held, then right**: look around on the
  run. **Right button + WASD**: move relative to the camera.
- **Shift** sprints, **Space** jumps, **F10** opens the settings.

The full list is in [Controls](controls.md).

Places to walk to:

- **Ancient Circle**, the ring of columns north-west of the spawn. Walk between the columns and the hero shows as a
  silhouette behind them.
- **Travelers' Camp** in the east and **Farmstead by the Well** in the south-west, with NPCs.
- **Windswept Peak**, the mountain in the north-east: click its top and the hero takes the spiral trail.
- The hedge maze, the platform with its ramp and stairs, and the U-shaped trap near the spawn, for testing pathfinding.
- The ten hero looks in a row by the south wall. Pick one in Settings → Character → **Hero look**.
- **The teleport pad** by the Ancient Circle, with a spinning crystal: step onto it and press E or click the offer to
  travel to **Lonely Isle** and its **Hermit's Camp**. A pad on the island ("Teleport to Green Vale") brings you back.

## Settings

F10 opens the settings window and pauses the game; Esc or F10 closes it. Settings are saved to
`user://settings.cfg` and apply at once. To hide the controls hint, turn off Settings → Interface → **Controls hint
and speed**. The interface language is chosen on the same tab. All settings: [Settings](settings.md).

## Run the tests

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Here `godot` is your Godot 4.7.2 executable. On Windows use the `_console.exe` build to see the output and get the
exit code. On a fresh clone, import the project once first, in the editor or with
`godot --headless --path . --import`. Details: [Tests](testing.md).

## Next

- [Transfer the ready-made hero](integration.md#taking-the-demos-hero-into-your-project): exact files, a test level and
  the checks for a working integration.
- [Configurations](configurations.md): the supplied default and two useful movement/camera variations.
- [Architecture](architecture.md): what each node does and how they are wired.
- [Project setup](project-setup.md): physics layers, input actions and optional demo settings.

---

*This page matches Iso & Orbit 1.2.0.*
