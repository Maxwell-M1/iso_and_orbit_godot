<!-- translation of docs/en/architecture.md @ 38b9342d8085 -->
# Arquitetura

> Esta é uma tradução do [original em inglês](../en/architecture.md).
> Onde houver diferenças, a versão em inglês é a correta.

A demo é uma única cena, `gdscript/main.tscn`. Cada comportamento é um nó separado com uma única função: um componente
lê as próprias propriedades exportadas, expõe métodos e sinais e é ligado aos vizinhos na cena por referências a nós e
conexões de sinais. As poucas buscas que restam são configuráveis: `DiscoveryToast` encontra os locais pelo grupo,
`CharacterAppearance` encontra o modelo e sua mão por nomes exportados, e `CharacterSounds` com a propriedade
`character` vazia usa o próprio pai.

## A cena principal

```
Main (Node3D)
├── World              shared/world/world.tscn: o nível, sua malha de navegação, locais e NPCs
├── Player             gdscript/player/player.tscn: GroundCharacter, grupo "player"
│   ├── CollisionShape3D   cápsula, raio 0.35 m, altura 1.8 m
│   ├── Visual             virado para onde o personagem vai
│   │   └── Model          a aparência atual do herói; sua RightHand segura o cajado
│   ├── Silhouette         OccludedSilhouette: o herói visto através de obstáculos
│   ├── Appearance         CharacterAppearance: troca Visual/Model em tempo de execução
│   ├── RightHandSway      HandSway: balança a mão direita com os passos
│   ├── NavigationMover    caminhos e velocidade
│   ├── LedgeGuard         impede o corpo de sair andando de um desnível
│   ├── Stamina            reserva para a corrida rápida
│   └── Sounds             CharacterSounds e cinco AudioStreamPlayer3D
├── PlayerInput        PointClickMoveInput: mouse e WASD → Player/NavigationMover
├── PlayerActionInput  CharacterActionInput: Shift e Space → Player
├── CameraRig          OrbitCameraRig: segue Player, órbita e zoom
│   └── CameraArm      CameraArm: encurta em obstáculos
│       └── Camera3D
├── ClickMarker        o anel no chão no ponto clicado
├── PathView           NavigationPathView: a linha de depuração do caminho, oculta por padrão
├── Hud                dica de controles e velocidade, FpsCounter, DiscoveryToast, StaminaBar
├── SettingsApplier    configurações → propriedades dos nós (só na demo)
└── UiRoot             janelas sobre o jogo: a janela de configurações
```

`player.tscn` contém só o personagem. Os nós de entrada ficam em `main.tscn`, então a mesma cena de personagem pode ser
controlada por outra coisa: IA, uma cutscene ou um peer de rede.

## Fluxo de dados

```
mouse, WASD ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (caminho ou         (aceleração, frenagem,
                                    ──stop()────────────►  direção)            giro: matemática pura)
                                                               ▲
                                                               │ compute_velocity(delta)
                                                               │ retorna uma velocidade horizontal
Shift, Space ──► CharacterActionInput ──sprint_requested──► GroundCharacter ──► LedgeGuard.constrain()
                                      ──jump()────────────►  (CharacterBody3D)  ──► move_and_slide()
                                                                   │
                                     sinais: stepped, jumped, landed, sprint_changed
                                                                   ▼
                                                   CharacterSounds, HandSway, qualquer outra coisa

mouse ──► OrbitCameraRig ──► CameraArm ──► Camera3D
          (segue a posição interpolada do alvo, órbita, zoom, seguir opcional)
```

A entrada nunca toca o corpo. Ela envia comandos ao `NavigationMover`. O movimentador também nunca toca o corpo: ele
retorna uma velocidade quando o corpo pede. A câmera e a entrada não sabem uma da outra.

## Um tick de física

1. `CharacterActionInput` roda antes do personagem (`process_physics_priority = -1`): define
   `GroundCharacter.sprint_requested` e chama `jump()`, então um toque de tecla chega ao corpo no mesmo tick.
2. `GroundCharacter._physics_process`, o único lugar onde o corpo se move:
   1. decide se o personagem está em corrida rápida (pedida, permitida, em movimento, não exausto) e gasta fôlego;
   2. chama `mover.compute_velocity(delta)` e usa o X e o Z do resultado como a velocidade horizontal;
   3. inicia um pulo se houver um no buffer e o corpo estiver no chão ou tiver acabado de sair dele (coyote time);
   4. no ar, soma a gravidade vezes `gravity_scale`;
   5. deixa `LedgeGuard.constrain()` virar a velocidade ao longo de uma borda, a não ser que o personagem esteja
      pulando;
   6. chama `move_and_slide()`;
   7. emite `landed` e `stepped` e vira `Visual` para `mover.get_facing()`.
3. `HandSway` roda depois do corpo (`process_physics_priority = 1`) e move a mão a partir do novo estado do corpo.

`PointClickMoveInput._physics_process` decide num só lugar quem controla o personagem: um botão do mouse segurado ou,
senão, as teclas com o botão direito. Ele chama `move_to()`, `steer()` ou `stop()`. O movimentador guarda o último
comando, e o corpo o recebe na próxima vez que chamar `compute_velocity()`.

A cada quadro renderizado, `OrbitCameraRig._process` coloca o rig na transformação interpolada do alvo, e seu filho
`CameraArm` se atualiza logo depois. `PointClickMoveInput` tem `process_priority = 1`, então corrige a posição do
cursor depois que a câmera se acomodou no quadro.

## Componentes

Os componentes reutilizáveis estão em `addons/iso_orbit/`, uma pasta por parte que pode ser usada sozinha. Cada script
tem o nome da sua classe em snake case: `OrbitCameraRig` é `addons/iso_orbit/orbit_camera/orbit_camera_rig.gd`.

| Addon | Classe | Função |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig` (Node3D) | Segue um alvo, orbita com o BDM, dá zoom com a roda, opcionalmente vira acompanhando a corrida |
| | `CameraArm` (Node3D) | Segura a câmera na sua ponta e encurta em obstáculos; esmaece o alvo de perto |
| `click_to_move` | `LocomotionSettings` (Resource) | Velocidade, aceleração, frenagem e giro. Um recurso pode ser compartilhado por vários personagens |
| | `GroundMotion` (RefCounted) | Cinemática sem nós: direção desejada e distância restante → velocidade horizontal |
| | `NavigationMover` (Node) | `move_to()` por um caminho de navegação com parada exata, `steer()` numa direção, `stop()`; retorna uma velocidade, nunca move o corpo |
| | `PointClickMoveInput` (Node) | Mouse e BDM + WASD → comandos ao movimentador; oculta o cursor e corrige a mira dele |
| | `ClickMarker` (Node3D) | O marcador no ponto clicado (`click_marker.tscn`) |
| | `NavigationPathView` (MeshInstance3D) | Desenha o caminho restante do movimentador |
| `ground_character` | `GroundCharacter` (CharacterBody3D) | Gravidade, pulo, corrida rápida com fôlego, `move_and_slide()`, giro do modelo; sinais para passos, pulos, aterrissagens e corrida rápida |
| | `LedgeGuard` (Node) | Para o corpo num desnível ou o faz deslizar ao longo da borda |
| | `Stamina` (Node) | Uma reserva que é gasta e se recupera; não sabe nada sobre o que a gasta |
| | `CharacterActionInput` (Node) | Teclas de corrida rápida e pulo → o personagem |
| | `CharacterSounds` (Node3D) | Toca sons a partir dos sinais do personagem |
| | `HandSway` (Node) | Balança um nó de mão com os passos, com inércia em arrancadas, paradas, curvas e aterrissagens |
| | `CharacterAppearance` (Node) | Troca o modelo do personagem em tempo de execução |
| | `StaminaBar` (ProgressBar) | A barra de fôlego do HUD (`stamina_bar.tscn`) |
| `occluded_silhouette` | `OccludedSilhouette` (Node) | Desenha o personagem como silhueta onde algo o esconde; seus shaders e materiais estão na mesma pasta |
| `points_of_interest` | `PointOfInterest` (Area3D) | Um local para descobrir: emite `discovered(title)` na primeira vez que o jogador entra |
| | `DiscoveryToast` (Label) | "Descoberto: …" na tela por alguns segundos (`discovery_toast.tscn`) |
| `ui_screens` | `UiRoot` (CanvasLayer) | Uma pilha de janelas: abrir, fechar a do topo com Esc, pausa, cursor, foco do teclado |
| | `UiScreen` (Control) | Base de uma janela: `initial_focus`, `close_requested` |
| | `FpsCounter` (Label) | Quadros por segundo, também com o jogo pausado (`fps_counter.tscn`) |

`ground_character` precisa de `click_to_move` (o corpo comanda um `NavigationMover`); os outros addons só precisam da
engine. O que cada um espera do projeto: [Usando no seu projeto](integration.md).

A demo em `gdscript/` os monta:

| Arquivo | Função |
|---|---|
| `main.tscn` | A cena da demo |
| `player/player.tscn`, `player_locomotion.tres` | O herói: um `GroundCharacter` com todas as suas partes, e suas configurações de corrida |
| `demo/hud.gd` | A dica de controles e a leitura da velocidade |
| `demo/settings_applier.gd` | Aplica as configurações aos nós da demo, um só lugar para "configuração → propriedade" |
| `settings/game_settings.gd` | `GameSettings`, o autoload `Settings`: padrões, `user://settings.cfg`, o sinal `changed`; aplica ele mesmo as configurações da engine |
| `ui/ui_root.tscn` | `UiRoot` com a janela de configurações e o F10 |
| `ui/settings/settings_screen.tscn`, `.gd` | A janela de configurações |
| `ui/settings/setting_*.gd` | `SettingCheckButton`, `SettingOptionButton`, `SettingSlider`, `SettingLanguageButton`: controles ligados a uma chave de configuração |

Cada sistema tem sua própria página: [Locomoção](systems/locomotion.md), [Câmera](systems/camera.md),
[Entrada](systems/input.md), [Personagens](systems/characters.md), [Áudio](systems/audio.md), [UI](systems/ui.md),
[Mundo e navegação](systems/world-and-navigation.md).

## Conexões feitas na cena

As referências a nós são propriedades exportadas definidas em `main.tscn` e `player.tscn`. As conexões de sinais em
`main.tscn`:

| Sinal | Conectado a | Efeito |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | O marcador aparece no ponto clicado |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | O botão segurado substitui o clique, o marcador some |
| `Player/NavigationMover.arrived` | `ClickMarker.fade_out` | O personagem chegou ao ponto |
| `Player/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | O ponto foi abandonado |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | A câmera não gira sozinha até se saber se o botão foi clicado ou está sendo segurado |

## Configurações

O autoload `Settings` (`GameSettings`) guarda os valores e emite `changed(key, value)`. Ele mesmo aplica as
configurações no nível da engine: tela cheia, limite de taxa de quadros, V-Sync, interpolação de física, escala da
interface, idioma e volume. Todo o resto é aplicado por `gdscript/demo/settings_applier.gd`, que associa cada chave a
uma propriedade de nó. Os próprios componentes nunca leem configurações, veja [Configurações](settings.md).

## Por que é feito assim

- **Só o `GroundCharacter` move o corpo.** Os componentes de movimento retornam uma velocidade e nunca chamam
  `move_and_slide()`. Gravidade, pulos e qualquer futuro knockback são combinados num só lugar e não podem brigar
  entre si.
- **`GroundMotion` é matemática sem nós.** Aceleração e frenagem são uma função pura do estado: fácil de testar
  isoladamente e de portar para outra linguagem linha por linha.
- **O personagem não sabe nada do mouse.** Ele vira o personagem do jogador porque o `PlayerInput` na cena principal
  comanda o movimentador dele. Para um NPC, instancie `player.tscn` sem os nós `Silhouette` e `Appearance`, que são só
  do jogador, e chame `NavigationMover.move_to()` da sua IA.
- **A câmera é irmã do personagem, não filha dele.** Ela se move em `_process` para a posição interpolada do alvo e não
  é interpolada ela mesma, então com a interpolação de física (ligada por padrão, Configurações → Exibição) a corrida
  fica suave em qualquer taxa de quadros. Para o modo de seguir, a câmera calcula a velocidade do alvo a partir do
  movimento dele por tick de física, então qualquer `Node3D` serve como alvo.
- **Os componentes não sabem nada das configurações.** `LedgeGuard`, `PointClickMoveInput`, `OrbitCameraRig` e os
  outros leem as próprias propriedades; só o `settings_applier.gd` e a janela de configurações falam com o autoload
  `Settings`. Um componente vai para outro projeto sem o sistema de configurações.
- **As janelas seguem as convenções do Godot.** O layout usa só contêineres; a aparência vem do tema do projeto e de
  suas variações de tipo, não de sobrescritas (overrides) em cada nó. Uma janela pede para ser fechada com um sinal, e
  o `UiRoot` a fecha (chamadas descem a árvore, sinais sobem). As teclas são ações de entrada. O foco do teclado é
  definido quando uma janela abre e restaurado quando ela fecha. Enquanto uma janela está aberta, o jogo fica pausado
  (`UiRoot` roda em `PROCESS_MODE_ALWAYS`) e a câmera libera um cursor capturado.

## Pastas

| Pasta | Conteúdo |
|---|---|
| `addons/iso_orbit/` | Os componentes reutilizáveis, uma pasta por parte |
| `gdscript/` | A demo em GDScript: a cena principal, o herói, o sistema e a janela de configurações, a dica do HUD |
| `shared/` | Conteúdo da demo que não depende da linguagem de script: o nível, personagens e equipamentos, shaders e texturas do mundo, sons, o tema da UI |
| `l10n/` | Traduções da interface |
| `tests/` | Testes headless, veja [Testes](testing.md) |
| `docs/` | Esta documentação |

`shared/` foi feito para ser reutilizado por uma futura versão em C# da demo, que teria a própria pasta ao lado de
`gdscript/`. Por enquanto restam duas exceções: `world.tscn` e `mountain.tscn` usam
`addons/iso_orbit/points_of_interest/point_of_interest.gd`, e dois pequenos scripts de props (`flicker.gd`,
`hover_spin.gd`) ficam em `shared/world/props/`. Veja [Problemas conhecidos](known-issues.md).

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
