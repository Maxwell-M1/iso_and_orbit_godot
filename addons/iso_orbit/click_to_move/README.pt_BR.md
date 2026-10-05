<!-- translation of addons/iso_orbit/click_to_move/README.md @ 29860f203673 -->
# Clicar para mover

[← Índice da documentação (repositório do template)](../../../docs/pt_BR/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Clicar para mover em jogos isométricos e de visão de cima: clique no chão e o personagem segue um caminho de
navegação até o fim alcançável; segure o botão e ele corre atrás do cursor. Aceleração e frenagem constantes,
velocidade de giro limitada e giro instantâneo a partir da parada. Com o botão direito segurado, WASD movem o
personagem em relação à câmera. Pressionar o botão direito durante uma corrida atrás do cursor mantém o trajeto,
permitindo olhar em volta.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Velocidade, aceleração, frenagem, giro |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | A matemática: direção e distância restante → velocidade |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`, `halt()`, `face()`; retorna velocidade, nunca move o corpo |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Mouse e botão direito + WASD → comandos ao movimentador; `cancel()` esquece um botão pressionado |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | O marcador no ponto clicado |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | Uma linha de depuração ao longo do caminho restante |

Nenhum outro addon é necessário. Para um corpo pronto com gravidade, pulo e corrida rápida, adicione
`addons/iso_orbit/ground_character`.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/click_to_move/`.
2. Gere uma malha de navegação para o nível (`NavigationRegion3D`). Ajuste tamanho e escalada do agente à cápsula
   e aos degraus do corpo. Sem malha ou com resultado de caminho vazio, o movimentador corre diretamente até o
   ponto solicitado; um caminho parcial pode terminar no ponto alcançável mais próximo. O corpo ainda precisa de
   geometria e forma de colisão.
3. Adicione `NavigationMover` como filho direto do corpo do personagem. O corpo chama `compute_velocity(delta)` uma vez
   por tick de física, antes de `move_and_slide()`:

   ```gdscript
   extends CharacterBody3D

   @onready var mover: NavigationMover = $NavigationMover


   func _physics_process(delta: float) -> void:
   	var planar := mover.compute_velocity(delta)
   	velocity.x = planar.x
   	velocity.z = planar.z
   	if not is_on_floor():
   		velocity += get_gravity() * delta
   	move_and_slide()
   ```

   Atribua a `NavigationMover.settings` um recurso `LocomotionSettings` antes de o movimentador entrar na árvore,
   ou deixe vazio para criar um com os padrões do script. Use **Make Unique** quando cada personagem precisar de
   ajustes independentes. Alterar os campos do recurso durante o jogo funciona; substituir `mover.settings` após
   `_ready()` não atualiza a instância `GroundMotion` já criada. `GroundCharacter`, do addon complementar, cuida de
   degraus, pulo e proteção contra bordas se você precisar desses recursos.

4. Para controle pelo mouse, adicione um `Node` com `point_click_move_input.gd` em qualquer lugar e defina seus
   `mover` e `camera`. Ele precisa das ações de entrada `move_to_cursor` (botão esquerdo), `camera_rotate` (botão
   direito) e `move_forward`, `move_back`, `move_left`, `move_right` (WASD). A falta de uma ação é informada uma vez
   na inicialização e ela não é lida depois. Cliques atingem a camada de física 1 (`ground_mask`): mantenha a
   camada dos personagens e os muros invisíveis fora dela, senão o clique acerta o personagem ou o muro. Com a
   câmera orbital de `addons/iso_orbit/orbit_camera`, conecte `hold_pending_changed` a `set_follow_paused` e
   `run_requested` a `end_follow_wait`. Olhar em volta durante a corrida (`look_around_while_held`) depende de
   `camera_steer_action` ser a mesma ação que gira a câmera (`rotate_action` do rig, ambas `camera_rotate`).
5. Ou comande o movimentador por IA: `move_to(point)`, `steer(direction)`, `stop()`, e escute `arrived`. O sinal
   indica que chegou ao fim do caminho, que pode ficar antes do ponto solicitado se ele for inacessível.

Para a cena do herói já montada e os arquivos a copiar, consulte `docs/pt_BR/integration.md` em vez de construir
o corpo manualmente. Os dois modos de entrada e ajustes do herói estão em `docs/pt_BR/systems/input.md`.

## Documentação

No repositório do template: `docs/pt_BR/integration.md`, `docs/pt_BR/systems/locomotion.md` e
`docs/pt_BR/systems/input.md`.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
