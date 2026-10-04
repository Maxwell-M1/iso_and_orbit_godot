<!-- translation of docs/en/roadmap.md @ 4e0c524b4d04 -->
# Roteiro

> Esta é uma tradução do [original em inglês](../en/roadmap.md). Onde houver diferenças, a versão em inglês é a correta.

Trabalho planejado, sem ordem específica. Nada aqui foi implementado ainda.

- **`shared/` sem GDScript.** O nível marca os locais com `addons/iso_orbit/points_of_interest/point_of_interest.gd`,
  e dois scripts de props ficam em `shared/world/props/`. Eles precisam de uma forma que uma versão em C# também possa
  usar. Veja [Problemas conhecidos](known-issues.md#arquivos-do-projeto).
- **Um exemplo em C#** em `csharp/`, com os mesmos componentes e uma cena principal sobre `shared/world/world.tscn`.
  Os nomes de classes globais da versão em C# precisam ser diferentes dos de GDScript: `class_name` e `[GlobalClass]`
  compartilham um único namespace.
- **Animações.** Controlar uma mistura parado/corrida (idle/run) num `AnimationTree` a partir de
  `NavigationMover.get_speed()` e manter o ciclo de caminhada no ritmo de `GroundCharacter.get_step_phase()`, o ritmo
  que os sons de passos já seguem.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
