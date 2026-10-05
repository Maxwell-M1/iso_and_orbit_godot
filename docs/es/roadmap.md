<!-- translation of docs/en/roadmap.md @ 785e0b204d0a -->
# Hoja de ruta

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/roadmap.md).
> Si hay diferencias, la versión en inglés es la correcta.

Trabajo planificado, sin un orden particular. Nada de esto está implementado todavía.

- **`shared/` sin GDScript.** Los niveles marcan lugares, puntos de aparición y portales con scripts de los
  componentes (`point_of_interest.gd`, `spawn_point.gd`, `level_portal.gd`), y dos scripts de objetos están en
  `shared/world/props/`. Necesitan una forma que también pueda usar una versión en C#. Consulta
  [Problemas conocidos](known-issues.md#archivos-del-proyecto).
- **Un ejemplo en C#** en `csharp/`, con los mismos componentes y una escena principal sobre
  los niveles de `shared/world/`. Los nombres de clase globales de C# deben diferir de los de GDScript:
  `class_name` y `[GlobalClass]` comparten un mismo espacio de nombres.
- **Animaciones.** Un modelo con esqueleto y un `AnimationTree` controlado por lo que informa `GroundCharacter`:
  `get_locomotion_blend()` o `get_local_movement()` para las mezclas de reposo, carrera y sprint, `get_gait_cycle()`
  para mantener el ciclo de carrera acompasado con el suelo, el estado y las señales de contacto con el suelo para los
  saltos y los aterrizajes.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
