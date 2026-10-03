# Roadmap

Planned work, in no particular order. Nothing here is implemented yet.

- **`shared/` without GDScript.** The level marks places with
  `addons/iso_orbit/points_of_interest/point_of_interest.gd`, and two prop scripts live in `shared/world/props/`. They
  need a form that a C# version could use too. See [Known issues](known-issues.md#project-files).
- **A C# example** in `csharp/`, with the same components and a main scene on top of `shared/world/world.tscn`.
  Global class names of the C# version must differ from the GDScript ones: `class_name` and `[GlobalClass]` share one
  namespace.
- **Animations.** Drive an idle/run blend in an `AnimationTree` from `NavigationMover.get_speed()`, and keep the walk
  cycle in step with `GroundCharacter.get_step_phase()`, the rhythm the footstep sounds already follow.

---

*This page matches Iso & Orbit 1.0.0.*
