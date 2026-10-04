<!-- translation of docs/en/roadmap.md @ 6c3e4efdec59 -->
# Roteiro

> Esta é uma tradução do [original em inglês](../en/roadmap.md). Onde houver diferenças, a versão em inglês é a correta.

Trabalho planejado, sem ordem específica. Nada aqui foi implementado ainda.

- **`shared/` sem GDScript.** O nível marca os locais com `addons/iso_orbit/points_of_interest/point_of_interest.gd`,
  e dois scripts de props ficam em `shared/world/props/`. Eles precisam de uma forma que uma versão em C# também possa
  usar. Veja [Problemas conhecidos](known-issues.md#arquivos-do-projeto).
- **Um exemplo em C#** em `csharp/`, com os mesmos componentes e uma cena principal sobre `shared/world/world.tscn`.
  Os nomes de classes globais da versão em C# precisam ser diferentes dos de GDScript: `class_name` e `[GlobalClass]`
  compartilham um único namespace.
- **Animações.** Um modelo com rig e um `AnimationTree` controlado pelo que o `GroundCharacter` informa:
  `get_locomotion_blend()` ou `get_local_movement()` para as misturas de parado, corrida e corrida rápida,
  `get_gait_cycle()` para manter o ciclo da corrida em sincronia com o chão, o estado e os sinais de contato com o chão
  para pulos e aterrissagens.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
