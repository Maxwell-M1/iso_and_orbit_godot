# Known issues

[← Documentation index](index.md)

Limitations of the project and engine quirks it works around. Each entry says what you see and what to do.

## Limitations

- **Mouse and keyboard only.** There is no gamepad support.
- **No in-game key rebinding.** Change bindings in Project Settings → Input Map or through `InputMap` in code.
  The interface can refresh key names, but there is no rebinding screen, conflict detection or binding persistence.
  See [key names in texts](systems/ui.md#key-names-in-texts).
- **No animations.** The models are static primitives; only the held item swings with the steps (`HandSway`).
  `GroundCharacter` reports what an `AnimationTree` needs: the state, the speed as a blend value, the movement in the
  model's axes and the gait cycle, see [Locomotion](systems/locomotion.md#what-the-character-reports).
- **A capsule on stairs.** The round bottom of the capsule rolls over each stair edge: on stairs the horizontal speed
  drops to about 70% for one tick per stair, and the body is put up to a few centimeters ahead onto the stair. For a
  long flight of stairs an invisible ramp collider is smoother, see
  [Locomotion](systems/locomotion.md#stairs-and-slopes).
- **A floating model is cosmetic.** `CharacterHover` lifts the model, not the body: under a low ceiling the model can
  sink into it, and the camera's focus and the arm's checks stay at the body's height. Over a gap the model falls with
  the body.
- **Up is +Y.** The character and its components support only `Vector3.UP` as up.
- **No avoidance between characters.** `NavigationMover` follows a path and does not use navigation avoidance, so
  moving characters do not steer around each other. The player's body is on layer 2 and collides only with layers 1
  and 4, so two characters made from `player.tscn` pass through each other; add layer 2 to their `collision_mask` if
  they should block each other. The NPCs in the demo stand still and are baked into the navigation mesh as obstacles.
- **The navigation mesh is baked in advance.** Moving an obstacle at runtime does not change paths. After editing the
  level, rebake the mesh ([World and navigation](systems/world-and-navigation.md#rebaking-the-navigation-mesh)).
- **Tested engine and renderer.** Use Godot 4.7.2, Jolt Physics and Forward+ for the verified setup. Compatibility
  with other versions and renderers is not established by the test suite. The silhouette requires stencil support.

## Input

- **A click acts on release.** A press becomes a click or a hold only after 0.2 s (`hold_delay`) or on release, so a
  click is about 0.1 s later than it would be on press. This is deliberate: otherwise a hold would first send the hero
  along a path to the pressed point. See [Input](systems/input.md#click-or-hold).
- **The cursor may not keep its aim on some systems.** Keeping the aim while the camera turns moves the system cursor
  (`Viewport.warp_mouse()`). Where the system does not allow that (Wayland, for example), the running direction
  still holds but the cursor stays where it was on the screen.
- **"To the point along a path" can switch routes.** In this hold mode the path is rebuilt as the point under the
  cursor moves, and near height changes (the ramp, the platform) it can jump from one route to another. The default
  mode, straight to the cursor, has no such problem.
- **Shift can stick when the game runs inside the editor.** When the game is embedded in the editor's Game tab and the
  focus moves to the editor, the engine does not reset pressed keys. `CharacterActionInput` releases a stuck sprint at
  the next mouse or keyboard event, as long as the sprint action is on modifier keys. If Windows Sticky Keys turns on
  (five Shift presses in a row), Shift sticks in the system itself; turn Sticky Keys off in the Windows settings. See
  [Input](systems/input.md#shift-does-not-stick).

## Camera

- **A body right behind an obstacle.** Jolt does not report bodies that a shape cast touches at its start. When
  another body stands right behind the obstacle the camera is in (a fence with a cliff behind it), the arm looks for
  free space closer to the target instead. See
  [Camera](systems/camera.md#how-the-arm-tells-room-behind-an-obstacle-from-being-inside-a-body).
- **Steps in the motion without physics interpolation.** Physics interpolation is on by default. Turned off (Settings →
  Display), the character and the camera move tick by tick, 60 times a second: on a fast monitor this looks uneven, and
  with the camera following the run the character wobbles on turns.

## Tests

- **A rare Jolt warning fails a run.** Under heavy CPU load, for example in the first run right after a fresh import,
  Jolt Physics may print "Jolt Physics job system exceeded the maximum number of jobs. This should not happen." The
  test runner counts every engine warning and error as a failure, so the run ends with exit code 1 and "engine and
  script errors: 1" although every check passed. The warning comes from the engine's physics job system, not from
  the project: run the tests again, on a machine that is not busy.

## Rendering

- **The silhouette uses an experimental engine feature.** The stencil buffer is experimental in Godot 4.5+ and can
  only be read in a transparent pass. If a future engine version changes it, the silhouette is the place to look.
- **The projection is flipped in Y in Godot 4.7** (D3D12 and Vulkan): `PROJECTION_MATRIX[1][1]` is negative in
  shaders. The silhouette rim takes `abs()` of it; without that the rim mesh shrinks and the rim disappears.

## Project files

- **Rounded rotations make "non-uniform scale" warnings.** A rotation written to a `.tscn` with 4 digits makes the
  basis axis lengths differ by more than 1e-5, and the engine reports a non-uniform scale on bodies and shapes. Write
  `Transform3D` numbers at full precision (9 significant digits).
- **`shared/` is not fully language-neutral yet.** The levels and the pad use scripts of the components: `world.tscn`,
  `island.tscn` and `mountain.tscn` use `addons/iso_orbit/points_of_interest/point_of_interest.gd`, both levels
  `addons/iso_orbit/levels/spawn_point.gd`, and `shared/world/props/teleport_pad.tscn`
  `addons/iso_orbit/levels/level_portal.gd`. Two small prop scripts live in `shared/world/props/` too. A C# version
  would need its own scripts for places, spawn points and portals, or a scene-only way to mark them.
- **Leaked resources reported on exit.** If a script exits right after footsteps play, the engine may report leaked
  `AudioStreamPlayback` objects: with `--fixed-fps` game time runs ahead of real time while the sounds still play.
  Free the scene and wait a moment before quitting; `tests/run_checks.gd` waits 0.1 s.

---

*This page matches Iso & Orbit 1.2.0.*
