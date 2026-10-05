# Documentation

**English** · [Español](../es/index.md) · [日本語](../ja/index.md) · [Português (Brasil)](../pt_BR/index.md) · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · [简体中文](../zh_CN/index.md)

A click-to-move character controller and an orbit camera for isometric and top-down RPGs in Godot 4.7, with two demo
levels. Start with the [README](../../README.md) for an overview.

The English documentation is maintained first and is the reference for translations, which may lag behind it.

## First working integration

1. [Run the demo](getting-started.md) to try the default controls.
2. [Transfer the hero](integration.md#taking-the-demos-hero-into-your-project) into a small level in your project.
   Follow the file list, Input Map and navigation steps before changing the character.
3. [Choose a configuration](configurations.md): manual orbit, path-guided mouse movement or camera-follow exploration.
4. Use the [movement](systems/locomotion.md), [input](systems/input.md) and [camera](systems/camera.md) references to
   tune individual properties. [Characters](systems/characters.md) explains replacing the model and adding animation.

## Documentation menu

Choose a page below. Addon setup guides are included after the system references.

### Start

- [Getting started](getting-started.md): requirements, opening the project, what is in the demo.
- [Controls](controls.md): every input, click versus hold, the keys with the right button, the camera.
- [Settings](settings.md): every option in the settings window, its key, its default and what it changes.
- [Configurations](configurations.md): where values come from, exact node paths, three coherent setups and how to
  check the result.

### Code

- [Architecture](architecture.md): the main scene, how data flows through one physics tick, the components and why
  they are split this way.
- [Using it in your project](integration.md): the addons and what each needs, the camera alone, click-to-move, your
  own body, NPCs.
- [Project setup](project-setup.md): physics layers, input actions, groups and project settings the components
  expect.

### Systems

- [Locomotion](systems/locomotion.md): `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `GroundCharacter`,
  what the character reports for animations and the interface, `CharacterMonitor`, stairs and slopes, sprint and
  stamina, the jump, the fall (`FallSettings`), the ledge guard.
- [Camera](systems/camera.md): `OrbitCameraRig` (orbit, zoom curve, follow) and `CameraArm` (obstacles, pull-in,
  fading).
- [Input](systems/input.md): `PointClickMoveInput` (click, hold, keys, the cursor) and `CharacterActionInput`.
- [Characters](systems/characters.md): models and equipment, hero looks, the hand swing, floating, the silhouette.
- [Audio](systems/audio.md): character sounds and how they are synthesized.
- [UI](systems/ui.md): windows, the settings system and window, the HUD, the theme, translations.
- [World and navigation](systems/world-and-navigation.md): the level, places, surfaces and baked textures, the
  mountain, the navigation mesh and how to rebake it.
- [Levels](systems/levels.md): the game shell, the level host and the loading screen, portals and spawn points, the
  playable hero, the island.

### Addon setup guides

- [Click-to-move components](../../addons/iso_orbit/click_to_move/README.md)
- [Ground character](../../addons/iso_orbit/ground_character/README.md)
- [Orbit camera](../../addons/iso_orbit/orbit_camera/README.md)
- [Occluded silhouette](../../addons/iso_orbit/occluded_silhouette/README.md)
- [Points of interest](../../addons/iso_orbit/points_of_interest/README.md)
- [UI screens](../../addons/iso_orbit/ui_screens/README.md)
- [Level transitions](../../addons/iso_orbit/levels/README.md)

### Maintenance

- [Tests](testing.md): running them, what each suite covers, writing a check.
- [Known issues](known-issues.md): limitations and engine quirks, with what to do about them.
- [Glossary](glossary.md): terms used in the code and the documentation.
- [Roadmap](roadmap.md): planned work.

---

*This page matches Iso & Orbit 1.2.0.*
