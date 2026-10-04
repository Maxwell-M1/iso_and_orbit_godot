<!-- translation of docs/en/roadmap.md @ 6c3e4efdec59 -->
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
- **Animaciones.** Un modelo con esqueleto y un `AnimationTree` controlado por lo que informa `GroundCharacter`:
  `get_locomotion_blend()` o `get_local_movement()` para las mezclas de reposo, carrera y sprint, `get_gait_cycle()`
  para mantener el ciclo de carrera acompasado con el suelo, el estado y las señales de contacto con el suelo para los
  saltos y los aterrizajes.

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
