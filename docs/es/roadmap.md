<!-- translation of docs/en/roadmap.md @ 4e0c524b4d04 -->
# Hoja de ruta

> Esta es una traducción del [original en inglés](../en/roadmap.md).
> Si hay diferencias, la versión en inglés es la correcta.

Trabajo planificado, sin un orden particular. Nada de esto está implementado todavía.

- **`shared/` sin GDScript.** El nivel marca los lugares con
  `addons/iso_orbit/points_of_interest/point_of_interest.gd`, y dos scripts de props viven en
  `shared/world/props/`. Necesitan una forma que también pueda usar una versión en C#. Ver
  [Problemas conocidos](known-issues.md#archivos-del-proyecto).
- **Un ejemplo en C#** en `csharp/`, con los mismos componentes y una escena principal sobre
  `shared/world/world.tscn`. Los nombres de clase globales de la versión en C# deben diferir de los de GDScript:
  `class_name` y `[GlobalClass]` comparten un mismo espacio de nombres.
- **Animaciones.** Controlar una mezcla de reposo y carrera en un `AnimationTree` con
  `NavigationMover.get_speed()`, y mantener el ciclo de caminata al paso de `GroundCharacter.get_step_phase()`, el
  ritmo que ya siguen los sonidos de los pasos.

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
