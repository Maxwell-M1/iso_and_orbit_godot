<!-- translation of addons/iso_orbit/ground_character/README.md @ 9b116d7ff0dd -->
# Personagem terrestre

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Um corpo de personagem pronto para clicar para mover: gravidade, pulo com coyote time e buffer de entrada (a mesma
altura em qualquer taxa de ticks de física), corrida rápida com fôlego, subida e descida de degraus, uma proteção de
bordas que para o corpo em desníveis. O corpo informa o que está fazendo para animações, efeitos e a interface: o
estado e suas mudanças, os passos com o pé, as saídas do chão e as aterrissagens, a velocidade como valor de mistura,
o movimento nos eixos do modelo, o giro e o ciclo da passada. Também incluídos: sons nesses sinais, um painel que
mostra o estado como texto, um item na mão que balança com os passos e modelos trocáveis.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Gravidade, pulo, corrida rápida, degraus, `move_and_slide()`, giro do modelo; o estado, sinais e consultas para animações |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Para o corpo num desnível ou o faz deslizar ao longo da borda |
| `stamina.gd` | `Stamina` (Node) | A reserva para a corrida rápida |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Teclas de corrida rápida e pulo → o personagem |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Toca sons nos sinais do personagem |
| `hand_sway.gd` | `HandSway` (Node) | Balança um nó de mão com os passos |
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

   Defina `mover`, `visual`, `ledge_guard` e `stamina` do corpo. A demo também define `floor_constant_speed` no corpo,
   para que o personagem mantenha a velocidade em rampas, e o coloca na camada de física 2, separado do nível. O corpo
   sobe degraus de até `max_step_height` (0,3 m) e encostas de até o seu `floor_max_angle`; para caminhos que sobem
   escadas, gere a malha de navegação com `agent_max_climb` igual a `max_step_height`.
3. Para as teclas, adicione um `Node` com `character_action_input.gd` e defina o `character` dele. Ele precisa das
   ações de entrada `sprint` e `jump`.
4. Opcional: `CharacterSounds` com filhos `AudioStreamPlayer3D`, `HandSway` com o nó da mão do modelo,
   `CharacterAppearance` com uma lista de cenas de modelos, `CharacterMonitor` num `CanvasLayer` para um painel de
   depuração. `LedgeGuard.floor_mask` é a camada de física 1 por padrão.

Uma IA pode controlar o mesmo corpo: chame `NavigationMover.move_to()` e `GroundCharacter.jump()`, defina
`sprint_requested`.

## Documentação

No repositório do template: `docs/pt_BR/integration.md`, `docs/pt_BR/systems/locomotion.md`,
`docs/pt_BR/systems/audio.md` e `docs/pt_BR/systems/characters.md`.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
