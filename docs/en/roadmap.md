# Roadmap

[← Documentation index](index.md)

Planned work, in no particular order. Nothing here is implemented yet.

- **`shared/` without GDScript.** The levels mark places, spawn points and portals with the components' scripts
  (`point_of_interest.gd`, `spawn_point.gd`, `level_portal.gd`), and two prop scripts live in `shared/world/props/`.
  They need a form that a C# version could use too. See [Known issues](known-issues.md#project-files).
- **A C# example** in `csharp/`, with the same components and a game shell on top of the levels in `shared/world/`.
  Global class names of the C# version must differ from the GDScript ones: `class_name` and `[GlobalClass]` share one
  namespace.
- **Animations.** A rigged model and an `AnimationTree` driven by what `GroundCharacter` reports:
  `get_locomotion_blend()` or `get_local_movement()` for the idle, run and sprint blends, `get_gait_cycle()` to keep
  the run cycle in step with the ground, the state and the floor signals for jumps and landings.

---

*This page matches Iso & Orbit 1.2.0.*
