<!-- translation of addons/iso_orbit/click_to_move/README.md @ fabef0a2f5e6 -->
# Clicar para mover

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Clicar para mover em jogos isométricos e de visão de cima: clique no chão e o personagem corre até lá pela malha de
navegação, parando exatamente no ponto; segure o botão e ele corre atrás do cursor. Aceleração e frenagem constantes,
velocidade de giro limitada, giro instantâneo a partir da parada. Com o botão direito segurado, WASD movem o
personagem em relação à câmera.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Velocidade, aceleração, frenagem, giro |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | A matemática: direção e distância restante → velocidade |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`; retorna uma velocidade, nunca move o corpo |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Mouse e BDM + WASD → comandos ao movimentador |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | O marcador no ponto clicado |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | Uma linha de depuração ao longo do caminho restante |

Nenhum outro addon é necessário. Para um corpo pronto com gravidade, pulo e corrida rápida, adicione
`addons/iso_orbit/ground_character`.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/click_to_move/`.
2. Gere (bake) uma malha de navegação para o seu nível (`NavigationRegion3D`). Sem ela, o personagem corre direto até
   o ponto.
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

4. Para controle pelo mouse, adicione um `Node` com `point_click_move_input.gd` em qualquer lugar e defina seus
   `mover` e `camera`. Ele precisa das ações de entrada `move_to_cursor` (botão esquerdo), `camera_rotate` (botão
   direito) e `move_forward`, `move_back`, `move_left`, `move_right` (WASD), e os cliques atingem a camada de física 1
   (`ground_mask`).
5. Ou comande o movimentador por IA: `move_to(point)`, `steer(direction)`, `stop()`, e escute `arrived`.

## Documentação

No repositório do template: `docs/pt_BR/integration.md`, `docs/pt_BR/systems/locomotion.md` e
`docs/pt_BR/systems/input.md`.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
