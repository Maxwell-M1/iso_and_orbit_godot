<!-- translation of docs/en/integration.md @ 502ddfce7182 -->
# Usando no seu projeto

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/integration.md).
> Onde houver diferenças, a versão em inglês é a correta.

Comece pelo herói pronto se quiser o movimento e a câmera da demo em outro projeto. Use os componentes separados se
já tiver um controlador de personagem ou precisar apenas da câmera. Os scripts são classes GDScript comuns
(`class_name`): não há plugin de editor para ativar nem autoload `Settings` obrigatório.

| O que você quer | Por onde começar |
|---|---|
| Herói com entrada e câmera funcionando | [Transfira o herói da demo](#transferindo-o-herói-da-demo-para-o-seu-projeto) e [escolha uma configuração](configurations.md) |
| Uma câmera para um personagem existente | [Só a câmera](#só-a-câmera) |
| O movimento do projeto com seu próprio modelo | [O corpo pronto](#clicar-para-mover-com-o-corpo-pronto) e depois [a troca do modelo](systems/characters.md) |
| Movimento por caminhos com seu controlador ou IA | [Seu próprio corpo](#seu-próprio-corpo) e [os comandos do movimentador](#comandando-o-movimentador) |

Os caminhos de arquivo abaixo partem da raiz do projeto, onde fica `project.godot`. Um caminho `res://` indica o
mesmo local dentro do Godot. Mantenha a organização das pastas na primeira integração funcional.

## Os addons

| Addon | Classes | Requisitos |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | Ações de entrada `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`; camadas de física para o braço |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | Um `NavigationRegion3D` com malha gerada no mundo (sem ele o personagem corre direto até o ponto). Para a entrada: qualquer `Camera3D` e as ações `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` |
| `ground_character` | `GroundCharacter`, `FallSettings`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterHover`, `DampedSpring`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. Para as teclas: ações `sprint` e `jump`. Para os sons: os seus próprios ou `shared/audio/character/`. Para o balanço da mão e modelos trocáveis: modelos voltados para −Z com um nó de mão |
| `occluded_silhouette` | `OccludedSilhouette`, com seus shaders e materiais | Nada: funciona com qualquer modelo |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | O corpo do jogador no grupo `player`, numa camada de física que as áreas enxergam |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter`, `InputNames`, `ActionTexts` | O `ui_cancel` embutido; a ação `toggle_settings` se `UiRoot` abrir uma janela por tecla. A formatação dos nomes das teclas lê o Mapa de Entrada |
| `levels` | `LevelHost`, `LevelPortal`, `SpawnPoint`, `LoadingScreen` | Apenas o motor. O corpo viajante deve estar no grupo `player`, numa camada de física detectada pelos portais |

Cada pasta de addon tem um `README.md` com sua configuração e uma cópia da `LICENSE`. Leve um addon inteiro: as classes
dentro dele se referenciam por tipo, e um arquivo que você não usa não faz mal. Mantenha as pastas em
`res://addons/iso_orbit/<addon>/`: as cenas e os materiais dentro delas se referem aos seus arquivos por esses caminhos.
Para colocar um addon em outro lugar, mova-o no painel Sistema de Arquivos (FileSystem) do editor, que atualiza as
referências.

Os widgets do HUD (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) pegam a aparência de variações de tipo de tema com os
mesmos nomes no tema da demo, `shared/ui/ui_theme.tres`; sem elas, usam o tema padrão.

Fora dos addons, por serem específicos desta demo: o sistema de configurações (`gdscript/settings/game_settings.gd`
e a janela em `gdscript/ui/settings/`, veja [Configurações](#configurações)), `gdscript/ui/ui_root.tscn` (um `UiRoot`
com essa janela), o herói jogável (`gdscript/player/playable_hero.tscn`, montado em torno do personagem da demo;
veja [O herói jogável](#o-herói-jogável)), a oferta de viagem (`gdscript/ui/travel_prompt.tscn`), a cena principal
`gdscript/main.gd` e o código de ligação da demo `gdscript/demo/hud.gd` e `settings_applier.gd`.

## Só a câmera

A câmera funciona com qualquer alvo `Node3D` e só precisa de `addons/iso_orbit/orbit_camera/`.

1. Adicione um `Node3D` com `orbit_camera_rig.gd` à cena ao lado do alvo, não dentro dele.
2. Dê a ele um filho `Node3D` com `camera_arm.gd`, e dê a esse um filho `Camera3D`.
3. Defina `target` do rig como o corpo em movimento e `arm` como o nó do braço. Ative **Current** na câmera.
   Defina `fade_target` do braço como a raiz do modelo que deve ficar translúcida de perto, ou deixe vazio.
4. Adicione as ações de entrada e, para o braço, as camadas de física de [Configuração do projeto](project-setup.md).

Mantenha rig, braço, câmera e seus ancestrais na escala `(1, 1, 1)` e deixe a transformação local da câmera no padrão:
o braço a define durante a execução. Ajuste a composição da visão pelas propriedades, não pela escala dos nós.

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

`gdscript/player/player.tscn` é essa configuração, mais sons, balanço da mão, flutuação (`Visual/Hover`, desligada,
com queda mais lenta), modelo trocável e silhueta. Você pode instanciá-lo e retirar o que não precisar. Erros de
configuração em `GroundCharacter`, `LedgeGuard` e `CharacterHover` geram avisos na inicialização do jogo.

## O herói jogável

`gdscript/player/playable_hero.tscn` já reúne o herói controlado pelo jogador: `player.tscn` como `Character` (no
grupo `player`), `PointClickMoveInput`, `CharacterActionInput`, o rig da câmera com braço e câmera, o marcador de
clique e a linha do caminho, com suas configurações e conexões. Coloque-o uma única vez na cena do jogo, ao lado
dos níveis, não dentro de um deles. Seu script, `playable_hero.gd`, usa apenas as classes dos addons:

- `place_at(marker)` e `teleport(position, facing)` colocam o herói imediatamente em outro lugar: esquecem um
  botão que ainda esteja pressionado, posicionam o personagem sem tranco (`GroundCharacter.teleport()`), apontam a
  câmera para a direção em que ele olha e a reposicionam de imediato. Com `turn_camera` falso, a câmera mantém
  seu ângulo, como no início da demo.
- `controls_enabled = false` desativa a entrada de movimento, a corrida rápida e o pulo. A câmera continua sob
  controle, e uma corrida até o destino de um clique anterior continua. Chame também `character.mover.stop()` para
  frear ou `halt()` para parar imediatamente o movimento horizontal. Pausar a árvore de cenas é outra operação.
- As partes são propriedades tipadas: `character`, `input`, `actions`, `camera_rig`, `camera_arm`, `camera`,
  `click_marker`, `path_view` e, no personagem, `sounds`, `appearance`, `hover`, `silhouette`.

Para usar outro modelo, copie a cena e substitua `player.tscn` pelo seu personagem ou monte as partes manualmente.
Duas conexões da câmera são essenciais: `PointClickMoveInput.hold_pending_changed` com
`OrbitCameraRig.set_follow_paused` e `PointClickMoveInput.run_requested` com `OrbitCameraRig.end_follow_wait` (a câmera
espera uma nova corrida após ser girada manualmente). Outras quatro mostram e ocultam o marcador de clique; veja
[Arquitetura](architecture.md#conexões-feitas-na-cena). Mantenha `sharp_turn_speed` da câmera na metade da velocidade
de giro do personagem ou menos: apenas `PlayableHero` verifica isso e emite aviso.

## Transferindo o herói da demo para o seu projeto

Use Godot 4.7.2 com Jolt Physics e Forward+ para reproduzir a configuração da demo testada. Comece por um nível de
teste pequeno; adicione seus modelos, níveis e configurações depois que o herói copiado funcionar nele.

1. **Copie os arquivos, mantendo os caminhos.** Leve estas pastas para o seu projeto:
   - `addons/iso_orbit/click_to_move/`, `ground_character/`, `orbit_camera/` e `occluded_silhouette/`;
   - `gdscript/player/`: herói, personagem, script do herói e recursos de configuração do personagem;
   - `shared/characters/`: os dez modelos, seus cajados e livros, seus materiais;
   - `shared/audio/character/`: passos, pulo, aterrissagem e corrida rápida;
   - `shared/world/materials/wood.tres` e `dark_wood.tres`: as partes de madeira do Druida e do Mago de Batalha
     usam esses materiais. Eles ficam junto dos materiais do mundo, então copiar só `shared/characters/` não basta.

   Copie também os arquivos `.uid` e `.import` ao lado desses arquivos: as cenas encontram scripts e sons por seus
   identificadores e caminhos. Deixe `.godot/` de fora: o seu editor importará os arquivos. Como as cenas se
   referem aos arquivos por esses caminhos, se quiser guardá-los em outro lugar, copie primeiro e depois mova-os
   no painel FileSystem do editor, que atualiza as referências.
2. **Configure o projeto** em Project Settings; veja [Configuração do projeto](project-setup.md):
   - as ações `move_to_cursor`, `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`, `move_forward`, `move_back`,
     `move_left`, `move_right`, `sprint` e `jump`. Se faltar alguma, o componente que a usa avisa uma vez na
     inicialização, e essa tecla ou botão não funciona;
   - `navigation/3d/default_cell_height` = 0.025, para corresponder à malha de navegação do próximo passo. O mapa
     e todas as malhas atribuídas a ele precisam usar os mesmos tamanhos de célula;
   - interpolação de física ativada (`physics/common/physics_interpolation`): a câmera acompanha a posição
     interpolada do personagem. O herói foi testado com Jolt Physics (`physics/3d/physics_engine`);
   - camadas de física: o corpo do herói fica na camada 2 e colide com as camadas 1 e 4; o clique procura o chão
     na camada 1; o braço da câmera para nas camadas 1 e 3. Os nomes não importam, mas os números sim: ponha chão
     e paredes na camada 1 ou altere essas máscaras na sua cópia da cena.
3. **Monte um nível de teste** sob um `NavigationRegion3D`. Crie um chão `StaticBody3D` com `BoxShape3D` e `BoxMesh`
   visível, ambos de 20 × 1 × 20 m, centrados em `(0, -0.5, 0)` para que o topo fique em Y = 0. Adicione um
   obstáculo em caixa de 2 × 2 × 2 m, centrado em `(0, 1, -4)`, com malha e colisão correspondentes na camada 1.
   Ele bloqueia o caminho direto do ponto de entrada em `(0, 0, 4)` até `(0, 0, -8)`. Adicione uma luz e, opcionalmente,
   um degrau de 3 × 0.2 × 3 m centrado em `(5, 0.1, 0)`. A malha visível sozinha não fornece colisão.
4. **Crie e gere a malha de navegação.** Selecione a região, atribua um novo `NavigationMesh` e defina:

   | Propriedade | Valor do nível de teste | Motivo |
   |---|---|---|
   | Parsed Geometry Type | Static Colliders | Gerar a partir da mesma geometria que bloqueia o corpo |
   | Geometry Collision Mask | camada 1 | Incluir chão e obstáculo, não o herói |
   | Agent Radius | 0.5 m | Folga em torno da cápsula de raio 0.35 m |
   | Agent Height | 1.8 m | Pelo menos toda a altura da cápsula; confira o teto mais baixo |
   | `filter_walkable_low_height_spans` | `true` | Excluir partes do chão com menos espaço livre que Agent Height |
   | Agent Max Climb | 0.3 m | Corresponde a `Character.max_step_height` |
   | Agent Max Slope | 40° | Abaixo do limite de piso de 45° do corpo |
   | Cell Height / Cell Size | 0.025 m / 0.25 m | Resolução vertical fina; deve corresponder ao mapa de navegação |

   Mantenha chão e obstáculo **sob a região**, clique em **Bake NavigationMesh** e salve a cena. As malhas da demo
   usam Agent Height de 1.75 m e deixam desativado o filtro de pouca altura. Para um nível novo com tetos, use a
   altura total da colisão e ative o filtro. A navegação não substitui a colisão física. Sem caminho utilizável,
   esse movimentador pode recorrer ao deslocamento direto até o destino; assim, não contorna paredes. Veja
   [Mundo e navegação](systems/world-and-navigation.md#camadas-de-física-e-navegação).
5. **Instancie o herói ao lado da região**, com o nome `Hero`. Adicione um `Marker3D` chamado `Spawn` em
   `(0, 0, 4)`. Mantenha a raiz do herói na escala `(1, 1, 1)` e a câmera ativa. A cena pode ser tão pequena:

   ```text
   Game (Node3D)
   ├── NavigationRegion3D
   │   ├── Ground (StaticBody3D com colisão e malha)
   │   └── Obstacle (StaticBody3D com colisão e malha)
   ├── Hero (instância de playable_hero.tscn)
   ├── Spawn (Marker3D)
   └── DirectionalLight3D
   ```

   Anexe este script a `Game` e execute essa cena:

   ```gdscript
   extends Node3D

   @onready var hero: PlayableHero = $Hero


   func _ready() -> void:
       hero.place_at($Spawn, false)
   ```

   `false` preserva a órbita inicial de 45° da câmera; omita-o para colocá-la atrás da direção −Z do marcador.
   Depois da inicialização, posicione ou teleporte o **personagem pela API do herói**. A raiz `Hero` é um contêiner
   parado; ela não acompanha o corpo. Use `hero.character.global_position` para obter a posição atual do jogador.
6. **Confira o resultado antes de personalizar.** Clique no chão perto de `(0, 0, -8)`, além do obstáculo: o herói
   deve contorná-lo e parar. Afaste o zoom se necessário para ver o destino. Segure o botão esquerdo: ele deve se
   mover diretamente e parar ao soltar. Teste a órbita com o botão direito, zoom pela roda, botão direito + WASD,
   Shift e Espaço. Com o recurso de movimento fornecido, a velocidade normal é 5.5 m/s, a corrida rápida chega a
   8.25 m/s, o pulo tem 1 m de altura e um degrau de 0.2 m dispensa pulo. Confira no depurador se faltam ações,
   recursos ou se há avisos de configuração.

A cena copiada tem o comportamento padrão da demo sem o sistema de configurações: os dois modos de teclas são
`TURN`; acompanhamento da câmera, alinhamento de inclinação/altura e flutuação estão desligados; os sons da corrida
rápida estão desligados. O Necromante é o modelo inicial. Consulte [Configurações](configurations.md) para caminhos
exatos dos nós, os diferentes tipos de padrão e duas variantes úteis.

### Solução de problemas na transferência

| Sintoma | Confira primeiro |
|---|---|
| Falta uma classe global ou um recurso | Copie as quatro pastas de addons e os recursos listados nos caminhos originais; espere a importação terminar. Inclua os dois materiais de madeira |
| O herói atravessa o chão | O chão precisa de forma de colisão na camada 1; um MeshInstance3D só é visual |
| Os cliques não fazem nada | Ação no Input Map, câmera ativa, `PlayerInput.camera` e `ground_mask` do raio; um Control sobreposto pode consumir a entrada do mouse |
| O herói anda contra uma parede em vez de contorná-la | Gere a malha com os colliders sob a região, confira as camadas de navegação da região/do movimentador e examine a malha resultante |
| O caminho atravessa um degrau que o herói não consegue subir | Iguale a escalada a `max_step_height`, use células verticais finas, gere novamente e teste a geometria real |
| Alterações da cena somem na inicialização | Uma cópia de `SettingsApplier` pode substituí-las por ajustes salvos; o herói independente não precisa dele |
| A câmera gira de modo inesperado após mudar o movimento | Compare `turn_speed` do personagem e `sharp_turn_speed` da câmera; veja [Configurações](configurations.md#ajustes-sem-perder-a-configuração) |

Outros detalhes:

- Os addons e `playable_hero.gd` declaram nomes de classes globais (`GroundCharacter`, `NavigationMover`,
  `OrbitCameraRig`, `PlayableHero` e as demais [da tabela acima](#os-addons)). Se o seu projeto já tiver uma classe
  com o mesmo nome, renomeie uma delas.
- Ao mudar a velocidade de giro do personagem (`turn_speed` em `LocomotionSettings`), mantenha
  `CameraRig.sharp_turn_speed` na metade dela ou menos. Do contrário, a câmera pode interpretar uma mudança de
  direção rumo a ela como uma corrida lateral e girar. Se o limite não ficar abaixo da velocidade de giro, o
  herói avisa na inicialização.
- Nem o autoload `Settings` nem a janela de configurações são necessários. O HUD não integra o herói: a barra de
  fôlego e o aviso de lugar ficam na cena `main.tscn` da demo; veja a nota sobre o tema em [Os addons](#os-addons).
- Modelos e sons estão sob a licença MIT do projeto, como o código.

## Níveis

Copie `addons/iso_orbit/levels/`. A cena principal mantém um `LevelHost` cujo único filho é o nível inicial, o herói
ao lado dele e `loading_screen.tscn`. Seu script principal conecta os sinais do host: em `level_change_started`,
retira o controle; em `level_loaded(level, spawn)`, posiciona o herói em `spawn`; em `level_change_finished`, devolve
o controle; em `level_change_failed`, também o devolve (o nível permanece e `level_change_finished` não ocorre);
em `portal_entered` e `portal_exited`, mostra e oculta a oferta de viagem. `gdscript/main.gd` faz exatamente isso.
Cada nível precisa de um `SpawnPoint` chamado `default`; os portais são áreas `LevelPortal` com o caminho da cena
de destino.

Se você já tiver um sistema de níveis, leve apenas o herói jogável e chame `place_at()` quando o nível estiver
pronto; com outro personagem, chame `GroundCharacter.teleport()` para o mesmo efeito. Detalhes, padrões e
combinações de ajustes: [Níveis](systems/levels.md).

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


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
```

Esse corpo mínimo ainda precisa de uma forma de colisão, um piso e uma câmera para vê-lo; adicione um modelo sob
um nó `Visual`. Para orientar o modelo na direção do movimento, aponte seu eixo −Z para `mover.get_facing()` no
espaço global. `GroundCharacter` já cuida dessa orientação, inclusive com pai girado, se você não precisar manter
sua própria implementação do corpo.

`LedgeGuard` é opcional e exige `addons/iso_orbit/ground_character/`: adicione-o como filho do corpo e aplique
`velocity = ledge_guard.constrain(velocity, delta)` antes de `move_and_slide()`. Para correr mais rápido, defina
`mover.sprinting = true`: o limite de velocidade aumenta por `LocomotionSettings.sprint_speed_multiplier`. O resto
do `GroundCharacter` (pulo, fôlego, degraus, estado e sinais, giro suave do modelo) fica por sua conta.

## Comandando o movimentador

Qualquer coisa pode controlar um personagem: a entrada do jogador, IA, uma cutscene ou código de rede.

| Chamada | Efeito |
|---|---|
| `move_to(point)` | Seguir um caminho de navegação até um ponto global. Se inacessível, pode terminar no ponto alcançável mais próximo; um caminho vazio recorre ao movimento direto. Um destino a menos de `retarget_tolerance` (0.1 m) do atual não reconstrói o caminho |
| `steer(direction, facing = Vector3.ZERO)` | Correr numa direção sem caminho até nova ordem; com `facing`, olhar nessa direção enquanto se move (passo lateral) |
| `stop()` | Frear suavemente onde o personagem está |
| `halt()` | Parar instantaneamente, por exemplo depois de um teleporte |
| `face(direction)` | Virar imediatamente um personagem parado, por exemplo num ponto de entrada |

Para posicionar o personagem inteiro em outro lugar, chame `GroundCharacter.teleport(position, facing)`: ele para o
movimentador, gira o personagem e o modelo e move o corpo sem tranco para quem o acompanha.

Sinais: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (o ponto foi abandonado por
causa de `steer()` ou `stop()`). Consultas: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Detalhes: [Locomoção](systems/locomotion.md).

## Um NPC

Instancie `player.tscn` (ou a cena do seu próprio corpo com um movimentador) e remova os nós `Silhouette` e
`Appearance`, que são só do jogador. Não adicione os nós de entrada: chame `NavigationMover.move_to()` da sua IA e
escute `arrived`. Para usar um dos modelos de personagem da demo, coloque-o sob `Visual/Hover` como `Model`. Girar o
NPC no editor define a direção inicial; mais tarde, `GroundCharacter.teleport(position, facing)` ou
`NavigationMover.face()` podem mudá-la. Os NPCs parados
no nível da demo são corpos estáticos, não personagens; veja [Mundo e navegação](systems/world-and-navigation.md).

## Configurações

Os componentes nunca leem configurações: cada um lê as próprias propriedades exportadas. Para expô-las no seu menu de
configurações, defina as propriedades a partir do seu próprio código quando uma configuração mudar.
`gdscript/demo/settings_applier.gd` é um exemplo: um único `match` associa cada chave de configuração a uma propriedade
de nó. Para reutilizar também o sistema de configurações da demo, copie `gdscript/settings/game_settings.gd`,
registre-o como o autoload `Settings`, substitua as chaves e o `DEFAULTS` pelos seus, e pegue os controles de
`gdscript/ui/settings/`; veja [UI](systems/ui.md#configurações).

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
