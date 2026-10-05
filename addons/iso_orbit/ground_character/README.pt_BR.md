<!-- translation of addons/iso_orbit/ground_character/README.md @ 87915285e965 -->
# Personagem terrestre

[← Índice da documentação (repositório do template)](../../../docs/pt_BR/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Um corpo pronto para clicar para mover: gravidade, pulo com tolerância após deixar a borda (coyote time) e entrada
antecipada (mesma altura em qualquer taxa de ticks de física), queda com gravidade e limite de velocidade próprios,
corrida rápida com fôlego, subida e descida de degraus e proteção opcional que para o corpo em desníveis. O corpo
informa o que está fazendo para animações, efeitos e a interface: o
estado e suas mudanças, os passos com o pé, as saídas do chão e as aterrissagens, a velocidade como valor de mistura,
o movimento nos eixos do modelo, o giro e o ciclo da passada. Também incluídos: sons nesses sinais, um painel que
mostra o estado como texto, um item na mão que balança com os passos, flutuação do modelo e modelos trocáveis.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Gravidade, pulo, corrida rápida, degraus, `move_and_slide()`, giro do modelo; estado, sinais e consultas para animação; `teleport()` sem tranco |
| `fall_settings.gd` | `FallSettings` (Resource) | Queda: gravidade, limite de velocidade e frenagem até esse limite |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Para o corpo num desnível ou o faz deslizar ao longo da borda |
| `stamina.gd` | `Stamina` (Node) | A reserva para a corrida rápida |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Teclas de corrida rápida e pulo → o personagem |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Toca sons nos sinais do personagem |
| `hand_sway.gd` | `HandSway` (Node) | Balança um nó de mão com os passos |
| `character_hover.gd` | `CharacterHover` (Node3D) | Eleva o modelo sobre o chão, desliza sobre degraus, oscila e inclina; pode reduzir a velocidade da queda |
| `damped_spring.gd` | `DampedSpring` (RefCounted) | Mola amortecida para um valor, usada na inércia |
| `character_monitor.gd` | `CharacterMonitor` (Label) | Mostra o estado do personagem e os últimos eventos como texto; pode registrar os eventos |
| `character_appearance.gd` | `CharacterAppearance` (Node) | Troca o modelo em tempo de execução |
| `stamina_bar.gd`, `stamina_bar.tscn` | `StaminaBar` (ProgressBar) | Uma barra de HUD para `Stamina` |

Precisa de `addons/iso_orbit/click_to_move`: o corpo é comandado por um `NavigationMover`.

## Configuração

1. Copie esta pasta e `click_to_move` para `res://addons/iso_orbit/`.
2. Monte o personagem:

   ```
   Player           CharacterBody3D com ground_character.gd
   ├── CollisionShape3D
   ├── Visual       Node3D; o modelo dentro fica virado para −Z
   ├── NavigationMover   de click_to_move
   ├── LedgeGuard   opcional
   └── Stamina      opcional
   ```

   Defina `mover`, `visual`, `ledge_guard` e `stamina` do corpo. A demo ativa `floor_constant_speed` para manter a
   velocidade nas rampas e põe o corpo na camada de física 2, separado do nível, colidindo com as camadas 1 e 4
   (nível e muros invisíveis): `get_ground_height()` e, por padrão, `LedgeGuard` procuram chão com a mesma máscara.
   O corpo sobe degraus de até `max_step_height` (0.3 m) e encostas até `floor_max_angle`. Para caminhos pelas
   escadas, gere a malha com `agent_max_climb` igual à altura de degrau desejada e teste o caminho com a colisão
   real. Mantenha `LedgeGuard.max_drop` pelo menos tão alto quanto `max_step_height` e `floor_snap_length` abaixo
   dele se precisar de `stair_taken` ao descer degraus. O corpo pode começar girado no nível: o personagem gira
   apenas `Visual` em relação ao corpo e inicialmente olha ao longo do −Z do corpo; depois,
   `teleport(position, facing)` ou `NavigationMover.face()` mudam a direção.
3. Para as teclas, adicione um `Node` com `character_action_input.gd` e defina o `character` dele. Ele precisa das
   ações `sprint` e `jump`; a falta de uma ação é informada uma vez no início, e ela não é lida depois.
4. Opcional: `CharacterSounds` com filhos `AudioStreamPlayer3D`, `HandSway` com `character` e o nó da mão do modelo,
   `CharacterAppearance` com `slot` e uma lista de cenas de modelos, `CharacterMonitor` num `CanvasLayer` para
   depuração. `LedgeGuard.floor_mask` 0 (padrão) usa a máscara de colisão do corpo e rejeita superfícies íngremes
   demais para ele ficar em pé.
5. Para flutuar, coloque um `Node3D` com `character_hover.gd` entre `Visual` e o modelo (`Visual/Hover/Model`) e
   use-o como `slot` de `CharacterAppearance`, se usar esse componente. Durante a flutuação, ele desativa os
   passos; com `fall` configurado (um `FallSettings`), o personagem pode descer mais devagar. O modelo sobe; o
   corpo e sua forma de colisão não sobem.
6. Opcional: um recurso `FallSettings` no `fall` do corpo, para alterar a gravidade da descida e limitar sua
   velocidade.

Erros de configuração geram avisos na inicialização. O `player.tscn` fornecido tem cápsula de 1.8 m,
`floor_constant_speed` ativo, proteção de bordas, fôlego, recurso de queda para flutuação e um nó de flutuação
inicialmente **desligado**. Seu `NavigationMover` usa `player_locomotion.tres`; `SettingsApplier` da demo pode
alterar propriedades a partir de ajustes salvos ao iniciar. Para copiar o herói jogável, veja
`docs/pt_BR/integration.md`; para adaptar seu modelo e a colisão, veja `docs/pt_BR/systems/characters.md`.

Uma IA pode controlar o mesmo corpo: chame `NavigationMover.move_to()` e `GroundCharacter.jump()`, defina
`sprint_requested`.

## Documentação

No repositório do template: `docs/pt_BR/integration.md`, `docs/pt_BR/systems/locomotion.md`,
`docs/pt_BR/systems/input.md` (`CharacterActionInput`), `docs/pt_BR/systems/audio.md`,
`docs/pt_BR/systems/characters.md` e `docs/pt_BR/systems/levels.md` (teleporte do herói).

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
