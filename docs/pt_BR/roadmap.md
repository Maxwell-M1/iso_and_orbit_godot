<!-- translation of docs/en/roadmap.md @ 785e0b204d0a -->
# Roteiro

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/roadmap.md). Onde houver diferenças, a versão em inglês é a correta.

Trabalho planejado, sem ordem específica. Nada aqui foi implementado ainda.

- **`shared/` sem GDScript.** Os níveis marcam lugares, pontos de entrada e portais com scripts dos componentes
  (`point_of_interest.gd`, `spawn_point.gd`, `level_portal.gd`), e dois scripts de objetos ficam em
  `shared/world/props/`. Precisam de uma forma que a versão em C# também possa usar. Veja
  [Problemas conhecidos](known-issues.md#arquivos-do-projeto).
- **Um exemplo em C#** em `csharp/`, com os mesmos componentes e uma cena principal sobre os níveis em
  `shared/world/`.
  Os nomes de classes globais da versão em C# precisam ser diferentes dos de GDScript: `class_name` e `[GlobalClass]`
  compartilham um único namespace.
- **Animações.** Um modelo com rig e um `AnimationTree` controlado pelo que o `GroundCharacter` informa:
  `get_locomotion_blend()` ou `get_local_movement()` para as misturas de parado, corrida e corrida rápida,
  `get_gait_cycle()` para manter o ciclo da corrida em sincronia com o chão, o estado e os sinais de contato com o chão
  para pulos e aterrissagens.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
