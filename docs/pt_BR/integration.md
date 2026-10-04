<!-- translation of docs/en/integration.md @ 15ab3be62c8a -->
# Usando no seu projeto

> Esta é uma tradução do [original em inglês](../en/integration.md).
> Onde houver diferenças, a versão em inglês é a correta.

Os componentes reutilizáveis estão em `addons/iso_orbit/`, uma pasta por parte; a pasta comum os mantém separados dos
seus outros addons. Copie as pastas que precisar para `addons/iso_orbit/` do seu projeto, ligue os nós nas suas cenas e
configure o projeto como descrito em [Configuração do projeto](project-setup.md). Os scripts são classes GDScript comuns
(`class_name`): não há plugin de editor para ativar.

## Os addons

| Addon | Classes | Requisitos |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | Ações de entrada `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`; camadas de física para o braço |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | Um `NavigationRegion3D` com malha gerada no mundo (sem ele o personagem corre direto até o ponto). Para a entrada: qualquer `Camera3D` e as ações `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` |
| `ground_character` | `GroundCharacter`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. Para as teclas: as ações `sprint` e `jump`. Para os sons: os seus próprios, ou `shared/audio/character/`. Para o balanço da mão e os modelos trocáveis: modelos virados para −Z com um nó de mão |
| `occluded_silhouette` | `OccludedSilhouette`, com seus shaders e materiais | Nada: funciona com qualquer modelo |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | O corpo do jogador no grupo `player`, numa camada de física que as áreas enxergam |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter` | O `ui_cancel` embutido; a ação `toggle_settings` se o `UiRoot` abrir uma janela por uma tecla |

Cada pasta de addon tem um `README.md` com sua configuração e uma cópia da `LICENSE`. Leve um addon inteiro: as classes
dentro dele se referenciam por tipo, e um arquivo que você não usa não faz mal. Mantenha as pastas em
`res://addons/iso_orbit/<addon>/`: as cenas e os materiais dentro delas se referem aos seus arquivos por esses caminhos.
Para colocar um addon em outro lugar, mova-o no painel Sistema de Arquivos (FileSystem) do editor, que atualiza as
referências.

Os widgets do HUD (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) pegam a aparência de variações de tipo de tema com os
mesmos nomes no tema da demo, `shared/ui/ui_theme.tres`; sem elas, usam o tema padrão.

Fora dos addons, porque são construídos em torno desta demo: o sistema de configurações
(`gdscript/settings/game_settings.gd` e a janela de configurações em `gdscript/ui/settings/`, veja
[Configurações](#configurações)), `gdscript/ui/ui_root.tscn` (um `UiRoot` configurado com essa janela) e a cola da
demo, `gdscript/demo/hud.gd` e `settings_applier.gd`.

## Só a câmera

A câmera funciona com qualquer alvo `Node3D` e só precisa de `addons/iso_orbit/orbit_camera/`.

1. Adicione um `Node3D` com `orbit_camera_rig.gd` à cena ao lado do alvo, não dentro dele.
2. Dê a ele um filho `Node3D` com `camera_arm.gd`, e dê a esse um filho `Camera3D`.
3. Defina o `target` do rig. Defina o `fade_target` do braço como o nó que deve ficar translúcido quando a câmera
   estiver muito perto, ou deixe-o vazio.
4. Adicione as ações de entrada e, para o braço, as camadas de física de [Configuração do projeto](project-setup.md).

Sem braço, um `Camera3D` filho do rig também funciona: a câmera fica então na distância definida pelo zoom e atravessa
paredes. O rig se atualiza em `_process` a partir da posição interpolada do alvo, então ligue a interpolação de física
no projeto se o alvo se mover em ticks de física. Detalhes: [Câmera](systems/camera.md).

## Clicar para mover com o corpo pronto

Copie `addons/iso_orbit/click_to_move/` e `addons/iso_orbit/ground_character/`.

1. Gere (bake) uma malha de navegação para o seu nível (`NavigationRegion3D` → **Gerar NavigationMesh**, em inglês
   **Bake NavigationMesh**). O raio do agente e a escalada máxima dela devem corresponder ao seu personagem, veja
   [Mundo e navegação](systems/world-and-navigation.md).
2. Crie um `CharacterBody3D` com `ground_character.gd`: uma forma de colisão, um nó `Visual` com o modelo (virado para
   −Z) e estes filhos: `NavigationMover` (um `Node` com `navigation_mover.gd`) e, opcionalmente, `LedgeGuard` e
   `Stamina`. Defina `mover`, `visual`, `ledge_guard` e `stamina` do corpo.
3. Dê ao movimentador um recurso `LocomotionSettings`, ou deixe vazio para usar os padrões.
4. Adicione um `Node` com `point_click_move_input.gd` em qualquer lugar da cena e defina seus `mover` e `camera`.
5. Opcionalmente, adicione `character_action_input.gd` com `character` apontando para o corpo, para corrida rápida e
   pulo.

`gdscript/player/player.tscn` é essa configuração, mais sons, o balanço da mão, o modelo trocável e a silhueta. Você
pode instanciá-lo e remover o que não precisar.

## Seu próprio corpo

Para manter o seu próprio controlador de personagem, leve só `addons/iso_orbit/click_to_move/`. O contrato é curto:

- `NavigationMover` deve ser filho direto do corpo (qualquer `Node3D`). Ele lê a posição do corpo e o mapa de
  navegação do mundo do corpo.
- O corpo chama `mover.compute_velocity(delta)` uma vez por tick de física, antes de `move_and_slide()`, e aplica o X
  e o Z do resultado. O movimentador nunca move o corpo.
- A velocidade vertical fica com o corpo: gravidade, pulos, knockback.

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover
@onready var ledge_guard: LedgeGuard = $LedgeGuard


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity = ledge_guard.constrain(velocity, delta)
	move_and_slide()
	var facing := mover.get_facing()
	$Visual.rotation.y = atan2(-facing.x, -facing.z)
```

`LedgeGuard` é opcional: um filho do corpo, de `addons/iso_orbit/ground_character/`. Para a corrida rápida, defina
`mover.sprinting = true`: o limite de velocidade é multiplicado por `LocomotionSettings.sprint_speed_multiplier`. Todo
o resto do `GroundCharacter` (pulo, fôlego, degraus, o estado e seus sinais, o giro suave do modelo) fica então por
sua conta.

## Comandando o movimentador

Qualquer coisa pode controlar um personagem: a entrada do jogador, IA, uma cutscene ou código de rede.

| Chamada | Efeito |
|---|---|
| `move_to(point)` | Correr até um ponto por um caminho de navegação e parar exatamente ali. Pode ser chamado a cada tick; um ponto a menos de `retarget_tolerance` (0,1 m) do atual não reconstrói o caminho |
| `steer(direction, facing = Vector3.ZERO)` | Correr numa direção sem caminho até nova ordem; com `facing`, olhar nessa direção enquanto se move (passo lateral) |
| `stop()` | Frear suavemente onde o personagem está |
| `halt()` | Parar instantaneamente, por exemplo depois de um teleporte |

Sinais: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (o ponto foi abandonado por
causa de `steer()` ou `stop()`). Consultas: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Detalhes: [Locomoção](systems/locomotion.md).

## Um NPC

Instancie `player.tscn` (ou a cena do seu próprio corpo com um movimentador) e remova os nós `Silhouette` e
`Appearance`, que são só do jogador. Não adicione os nós de entrada: chame `NavigationMover.move_to()` da sua IA e
escute `arrived`. Para usar um dos modelos de personagem da demo, coloque-o sob `Visual` como `Model`. Os NPCs parados
no nível da demo são corpos estáticos, não personagens; veja [Mundo e navegação](systems/world-and-navigation.md).

## Configurações

Os componentes nunca leem configurações: cada um lê as próprias propriedades exportadas. Para expô-las no seu menu de
configurações, defina as propriedades a partir do seu próprio código quando uma configuração mudar.
`gdscript/demo/settings_applier.gd` é um exemplo: um único `match` associa cada chave de configuração a uma propriedade
de nó. Para reutilizar também o sistema de configurações da demo, copie `gdscript/settings/game_settings.gd`,
registre-o como o autoload `Settings`, substitua as chaves e o `DEFAULTS` pelos seus, e pegue os controles de
`gdscript/ui/settings/`; veja [UI](systems/ui.md#configurações).

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
