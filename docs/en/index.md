# Documentation

**English** · [Español](../es/index.md) · [日本語](../ja/index.md) · [Português (Brasil)](../pt_BR/index.md) · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · [简体中文](../zh_CN/index.md)

A click-to-move character controller and an orbit camera for isometric and top-down RPGs in Godot 4.7, with a demo
level. Start with the [README](../../README.md) for an overview.

The English documentation is the original. The translations follow it and may lag behind; where they differ, the
English page is correct.

## Start

- [Getting started](getting-started.md): requirements, opening the project, what is in the demo.
- [Controls](controls.md): every input, click versus hold, the keys with the right button, the camera.
- [Settings](settings.md): every option in the settings window, its key, its default and what it changes.

## Code

- [Architecture](architecture.md): the main scene, how data flows through one physics tick, the components and why
  they are split this way.
- [Using it in your project](integration.md): the addons and what each needs, the camera alone, click-to-move, your
  own body, NPCs.
- [Project setup](project-setup.md): physics layers, input actions, groups and project settings the components
  expect.

## Systems

- [Locomotion](systems/locomotion.md): `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `GroundCharacter`,
  sprint and stamina, the jump, the ledge guard.
- [Camera](systems/camera.md): `OrbitCameraRig` (orbit, zoom curve, follow) and `CameraArm` (obstacles, pull-in,
  fading).
- [Input](systems/input.md): `PointClickMoveInput` (click, hold, keys, the cursor) and `CharacterActionInput`.
- [Characters](systems/characters.md): models and equipment, hero looks, the hand swing, the silhouette.
- [Audio](systems/audio.md): character sounds and how they are synthesized.
- [UI](systems/ui.md): windows, the settings system and window, the HUD, the theme, translations.
- [World and navigation](systems/world-and-navigation.md): the level, places, surfaces and baked textures, the
  mountain, the navigation mesh and how to rebake it.

## Maintenance

- [Tests](testing.md): running them, what each suite covers, writing a check.
- [Known issues](known-issues.md): limitations and engine quirks, with what to do about them.
- [Glossary](glossary.md): terms used in the code and the documentation.
- [Roadmap](roadmap.md): planned work.

---

*This page matches Iso & Orbit 1.1.0.*
