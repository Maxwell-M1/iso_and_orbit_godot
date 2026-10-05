<!-- translation of docs/en/systems/levels.md @ dc39dc2f669b -->
<!-- translation of docs/en/systems/levels.md @ pending -->
# Níveis

[← Índice da documentação](../index.md)

> Esta é uma tradução do [original em inglês](../../en/systems/levels.md).
> Em caso de divergência, consulte a versão em inglês.

Como o jogo troca de nível: o host e sua tela de carregamento, portais e pontos de entrada, o herói jogável que
passa de um nível a outro e os dois níveis da demo. O componente está em `addons/iso_orbit/levels/`; o herói, a
oferta de viagem e a cena principal são arquivos da demo montados com os componentes.

## A cena principal

`gdscript/main.tscn` permanece enquanto o jogo roda. O nível atual é filho do host; herói e interface são seus
irmãos na árvore, por isso os níveis mudam em volta deles.

| Nó | Classe | Função |
|---|---|---|
| `Levels` | `LevelHost` | Mantém o nível atual como único filho e o troca |
| `Levels/World` | | Nível inicial, `shared/world/world.tscn`, colocado no editor |
| `Hero` | `PlayableHero` | Personagem do jogador com entrada, câmera, marcador de clique e linha do caminho |
| `Hud/TravelPrompt` | `TravelPrompt` | Oferta de viagem sobre um portal |
| `LoadingScreen` | `LoadingScreen` | Tela enquanto o nível carrega |

`gdscript/main.gd` conecta essas partes:

| Sinal | O que a cena principal faz |
|---|---|
| `LevelHost.portal_entered(portal)` | Mostra a oferta do portal, a menos que ele viaje sozinho. Se entrar em dois portais, vale o último |
| `LevelHost.portal_exited(portal)` | Oculta a oferta; se o herói ainda estiver em outro portal, oferece o outro |
| `TravelPrompt.confirmed(portal)` | Chama `portal.travel()` |
| `LevelHost.level_change_started` | Oculta oferta e HUD e retira o controle do herói |
| `LevelHost.level_loaded(level, spawn)` | Marca os lugares já descobertos, coloca o herói em `spawn` com a câmera atrás dele e mostra o HUD sob a tela |
| `LevelHost.level_change_finished` | Devolve o controle |
| `LevelHost.level_change_failed` | Mostra o HUD, devolve o controle e oferece novamente o portal se o herói ainda estiver nele |

Na inicialização, a cena principal põe o herói no ponto `default` do nível inicial, com a câmera em seu ângulo
inicial (`OrbitCameraRig.start_yaw`). Ao chegar por um portal, a câmera olha na direção do ponto de entrada. Os
lugares descobertos ficam na memória durante a sessão, identificados pelo arquivo do nível e pelo caminho do lugar
nele: ao carregar de novo, `PointOfInterest.mark_discovered()` os marca, sem anunciá-los uma segunda vez. Um jogo
salvo guardaria essa mesma lista.

A instância do herói sobrevive à mudança, preservando fôlego, aparência e estado de flutuação. O teleporte limpa o
movimento e reinicia o acompanhamento da câmera; as configurações do jogador continuam no autoload `Settings`.

## Uma mudança de nível

O jogador fica sobre a plataforma e aperta E ou clica na oferta:

1. O portal pede a viagem; o host verifica o arquivo, solicita seu carregamento e responde imediatamente. A
   mudança começa logo depois, fora do pedido: o portal pode pedir a partir de um callback de física, no qual um
   nível não deve sair da árvore. O primeiro sinal é `level_change_started`.
2. O jogo é pausado, salvo se já estava. Durante a pausa, a câmera libera o cursor e a entrada o mostra.
3. A tela de carregamento captura o próximo quadro desenhado (o HUD já está oculto), desfoca e escurece a imagem e
   aparece em 0.35 s. O quadro se aproxima lentamente em 6%, surgem nome do lugar e dica, e a barra começa.
4. A cena do nível carrega em segundo plano (`ResourceLoader.load_threaded_request`). Seus arquivos preenchem a
   barra até 85%; o nível montado, até 90%.
5. O nível antigo sai da árvore e é liberado; o novo entra em seu lugar; `level_loaded` indica à cena principal
   onde colocar o herói. Os portais novos são conectados; os antigos foram desconectados antes de sair. Se algo
   encerrou a pausa nesse meio-tempo (por exemplo, uma janela fechada), o host pausa o jogo novamente para a troca.
6. Ainda pausado, o host espera o mapa de navegação incorporar o novo nível (95%): todas as regiões de navegação
   precisam aparecer no mapa, mas a espera pelo relógio não passa de `navigation_timeout`. O servidor de navegação
   trabalha durante a pausa, portanto os caminhos do novo nível estão disponíveis desde seu primeiro quadro.
7. A pausa termina e o host desenha `warmup_frames` quadros atrás da tela: os shaders do novo nível compilam e o
   herói se acomoda no chão.
8. Após `min_loading_time` desde o começo, a barra chega ao fim e a tela desaparece; então ocorre
   `level_change_finished`.

Ajustes do host:

| Propriedade | Padrão | Significado |
|---|---|---|
| `loading_screen` | vazio; a demo atribui sua `LoadingScreen` | Tela sobre o jogo durante a carga. Vazio: a troca fica visível ao jogador |
| `min_loading_time` | 0.6 s | Tempo mínimo da tela, para cargas rápidas não causarem um lampejo |
| `warmup_frames` | 3 | Quadros desenhados sob a tela antes de ela desaparecer, para os shaders do novo nível compilarem fora de vista |
| `navigation_timeout` | 2 s | Espera máxima, pelo relógio, pelo mapa de navegação; termina quando todas as regiões novas entram no mapa. 0: não esperar; antes disso, um caminho seria buscado no nível antigo ou em nenhum |

Sinais e métodos do host:

| Sinal ou método | Significado |
|---|---|
| `level_change_started(path)` | Mudança iniciada; o nível antigo ainda está presente |
| `level_loaded(level, spawn)` | O nível novo está presente e o antigo saiu; posicione o personagem em `spawn`. A tela ainda cobre o jogo |
| `level_change_finished(level)` | Mudança encerrada; a tela desapareceu |
| `level_change_failed(path, error)` | Falha; o nível atual permanece: `ERR_CANT_OPEN` se a carga falhou, `ERR_INVALID_DATA` se a raiz da cena não for `Node3D`. Vem no lugar de `level_change_finished` |
| `portal_entered(portal)`, `portal_exited(portal)` | Um viajante entrou ou saiu de um portal do nível atual |
| `change_level(path, spawn_name = &"default", title = "")` | Inicia a mudança e retorna imediatamente; veja abaixo |
| `get_current_level()` | Nível atual do jogo; `null` antes do primeiro |
| `is_changing()` | Há uma mudança em andamento desde um `change_level()` aceito até `level_change_finished` ou `level_change_failed` |
| `find_spawn_point(spawn_name = &"default", level = null)` | Ponto de entrada de um nível; veja [Pontos de entrada](#pontos-de-entrada) |

O nível inicial colocado no editor não é anunciado: não ocorre `level_loaded`. A cena principal o prepara em
`_ready()` com `get_current_level()` e `find_spawn_point()`, como em `gdscript/main.gd`.

Um pedido durante outra mudança é recusado (`ERR_BUSY`), por isso apertar E outra vez ou entrar em um portal durante
a troca não tem efeito. `change_level()` verifica o arquivo imediatamente: arquivo ausente retorna
`ERR_FILE_NOT_FOUND`, arquivo que não é cena retorna `ERR_INVALID_PARAMETER`, sem nenhuma mudança. Se uma cena não
carregar ou sua raiz não for `Node3D`, o nível atual permanece: aparece uma mensagem de erro na saída, a pausa
termina, a tela desaparece sem esperar `min_loading_time` e ocorre `level_change_failed`. A carga fracassada é
descartada, permitindo outra tentativa de carregar o arquivo após uma correção.

O host encerra somente a pausa que iniciou. Abra janelas que pausam o jogo (como um menu) só depois de
`level_change_finished`: se abertas durante a troca, encontram o jogo já pausado e deixam a pausa por conta do
host, que a encerra, fazendo o jogo continuar atrás da janela. Na demo isso acontece automaticamente: a tela de
carregamento bloqueia toda entrada, inclusive F10, até fechar. Fechar uma janela durante a mudança não atrapalha:
o host pausa o jogo de novo para a troca. Se ele sair da árvore durante a mudança (ao trocar a cena do jogo), a
mudança e sua pausa terminam com ele.

A tela, a barra e `min_loading_time` usam tempo real, qualquer que seja `Engine.time_scale`: em câmera lenta a
troca demora tanto quanto na velocidade normal.

Os quadros de preparação escondem parte do trabalho inicial atrás da tela, sem garantir ausência de travamentos
posteriores por shaders ou recursos. Meça as transições com o conteúdo real dos níveis e o renderizador escolhido.

## Portais

`LevelPortal` é um `Area3D`: plataforma, porta ou borda de mapa. Precisa de forma de colisão e de um
`collision_mask` que enxergue a camada do viajante (2, dos personagens); não precisa de camada própria. O host
conecta os portais do nível atual, inclusive os adicionados depois, como uma porta que abre após uma missão.

| Propriedade | Padrão | Significado |
|---|---|---|
| `target_level` | | Arquivo de cena do nível de destino. É caminho, não cena carregada, permitindo viagens nos dois sentidos; um caminho `uid://` escolhido no Inspector também funciona |
| `target_spawn` | `default` | Ponto de entrada na chegada |
| `title` | | Nome do lugar de destino, mostrado na oferta, tela e placa. Traduzido ao ser exibido |
| `title_label` | | `Label3D` sobre o portal que mostra `title`; o portal escreve o nome nele |
| `traveller_group` | `player` | Quem pode viajar: um corpo nesse grupo |
| `auto_travel` | desligado | Viajar assim que o viajante entra, sem oferta |

Combinações possíveis:

- **Padrão, plataformas da demo:** o portal informa entradas e saídas (`traveller_entered`, `traveller_exited`),
  o host retransmite como `portal_entered` e `portal_exited`, e o jogo decide o que oferecer. A cena principal
  mostra “E Teletransporte: <lugar>”; sair da plataforma oculta a oferta. E funciona mesmo com Shift ou outro
  modificador pressionado, pois o herói costuma chegar correndo. `travel()` inicia a troca.
- **`auto_travel` ativo:** porta ou borda do mapa. O portal viaja assim que alguém entra, sem oferta.
- **Sem tela de carregamento:** deixe `LevelHost.loading_screen` vazio. O nível continua carregando em segundo
  plano e o jogo pausa para troca e navegação, mas o jogador vê a troca.
- **Portal chamado pelo código:** `LevelHost.change_level(path, spawn_name, title)` equivale a um portal e pode ser
  chamado por uma cena cinemática ou por um menu.

`travel()` e a entrada com `auto_travel` emitem `travel_requested(portal)`. O host conecta esse sinal; jogos sem o
host precisam conectá-lo por conta própria. `has_traveller()` informa se há alguém sobre o portal. Cada portal
pertence ao grupo `level_portals`.

Um personagem que chega dentro da área de um portal receberia imediatamente a oferta de voltar. Com
`auto_travel`, ele é detectado quando a física recomeça, durante os quadros de preparação, enquanto a troca ainda
ocorre: o pedido recebe `ERR_BUSY`, ignorado pelo host, e o personagem só viaja ao sair e entrar de novo. Se a
troca já terminou, ele volta imediatamente. Portanto, ponha os pontos de entrada ao lado das plataformas, fora
das áreas dos portais.

## Pontos de entrada

`SpawnPoint` é um `Marker3D` com `spawn_name`, por padrão `default`. O personagem aparece no marcador e olha ao
longo de seu −Z, a direção à frente do nó (o eixo azul do gizmo aponta para o lado oposto); `get_facing()` retorna
essa direção no plano horizontal. Coloque o marcador no chão: os pés do personagem aparecem ali; acima dele, o
personagem cairia. Todos os pontos pertencem ao grupo `spawn_points`.

`LevelHost.find_spawn_point(name, level)` retorna o ponto com esse nome no `level` (ou nível atual, que precisa
estar na árvore); se não houver, retorna o `default`; se faltar também, retorna `null`. Durante uma troca, um
ponto ausente também gera aviso na saída. Sem nenhum ponto, o host envia o próprio nível como `spawn`, e o
personagem chega à origem. Todo nível precisa de um ponto `default`: o jogo começa nele e um portal sem
`target_spawn` chega nele. O nome é `spawn_name`, não o nome do nó: os pontos `default` da demo são os nós `Start`
e `Arrival`. Dê nomes próprios aos demais: outro ponto deixado como `default` também será `default` e, ao pedir
esse nome, vence o primeiro na ordem da árvore.

## A tela de carregamento

`LoadingScreen` é um `CanvasLayer` na camada 20, acima das janelas, e funciona enquanto o jogo está pausado. Com
a tela aberta, nenhum evento de entrada chega ao jogo: nem clique nem F10 fazem algo (`Input` ainda informa quais
teclas estão pressionadas).

| Propriedade | Padrão | Significado |
|---|---|---|
| `tips` | vazio; a demo define seis dicas de controle na instância em `gdscript/main.tscn` | Exibidas uma por vez em ordem aleatória; cada uma é traduzida e depois passada por `tip_format` |
| `tip_format` | vazio (um `Callable`, definido pelo código); a demo usa `InputNames.format` em `gdscript/main.gd` | Transforma a dica traduzida no texto exibido. As dicas da demo usam tokens como `{sprint}`; `InputNames.format` insere as teclas atualmente vinculadas, veja [Nomes das teclas nos textos](ui.md#nomes-das-teclas-nos-textos). Vazio: mostra só a tradução |
| `tip_time` | 6 s | Duração de cada dica; ela desaparece em 0.25 s, o texto muda e a próxima surge em 0.25 s |
| `fade_time` | 0.35 s | Tempo para a tela aparecer e desaparecer |
| `zoom` | 0.06 | Aproximação proporcional ao tamanho do fundo |
| `zoom_time` | 12 s | Tempo até completar a aproximação |

O fundo usa o último quadro do jogo, reduzido oito vezes e com mais desfoque por um shader
(`loading_background.gdshader`: desfoque, escurecimento, cantos mais escuros e base mais escura sob o texto). Sem
janela desenhando (execução sem janela ou janela minimizada), não há quadro e a tela mostra apenas cor escura. A
barra alcança rapidamente o progresso quando ainda está longe dele e nunca retrocede, mesmo quando o carregador
informa um valor menor que antes.

A aparência vem de `loading_screen_theme.tres`, tema da raiz da tela: variações `LoadingTitle` (44 px, branco
quente com sombra), `LoadingBar` (barra fina dourada) e `LoadingTip` (18 px). Atribua outro tema à raiz ou copie
`loading_screen.tscn` para criar outra tela: os nós podem mudar de posição e aparência, mas o script precisa do
`Control` `Root` e, por nomes únicos, do `TextureRect` `Background`, dos `Label`s `Title` e `Tip` e do
`ProgressBar` `Bar`. Um script derivado de `LoadingScreen` pode substituir `open()`, `set_progress()` e `close()`;
a cena ainda precisa desses nós. Consultas: `is_open()` (a tela está aberta ou entrando/saindo),
`get_shown_progress()` (fração preenchida da barra, de 0 a 1) e `get_tip()` (modelo original da dica exibida, vazio
se não houver dicas). `refresh()` traduz e formata a dica de novo sem reiniciar seu tempo. A demo põe a tela no
grupo `ActionTexts.GROUP`, então atualizar nomes das teclas também atualiza uma dica de carregamento já visível.

## O herói jogável

`gdscript/player/playable_hero.tscn` traz o herói controlado pelo jogador pronto para adicionar à cena do jogo:
personagem (`player.tscn`, no grupo `player`), `PointClickMoveInput`, `CharacterActionInput`, rig da câmera com
braço e câmera, marcador de clique e linha do caminho, com seus ajustes e seis conexões internas. A cena do
personagem não contém essas partes, por isso uma IA também pode comandar `player.tscn`.

`PlayableHero` (`playable_hero.gd`) expõe as partes como propriedades tipadas (`character`, `input`, `actions`,
`camera_rig`, `camera_arm`, `camera`, `click_marker`, `path_view` e, no personagem, `sounds`, `appearance`, `hover`,
`silhouette`) e três operações:

| Chamada | Efeito |
|---|---|
| `teleport(position, facing = Vector3.ZERO, turn_camera = true)` | Esquece o botão pressionado (`PointClickMoveInput.cancel()`), coloca o personagem imediatamente (`GroundCharacter.teleport()`), aponta a câmera ao longo de `facing` se solicitado, ajusta sua posição e reinicia o acompanhamento. Com `facing` igual a `Vector3.ZERO`, personagem e câmera mantêm suas direções |
| `place_at(marker, turn_camera = true)` | Usa `teleport()` para colocar o herói no marcador, olhando ao longo do −Z dele |
| `controls_enabled` | Desligado: esquece o botão pressionado, libera a tecla da corrida rápida e para os nós de entrada; a câmera continua sob controle do jogador. Uma corrida até um ponto clicado prossegue: interrompa-a com `character.mover.stop()` ou `teleport()`. Ligado: devolve o controle e os nós processam como antes |

A raiz do herói nunca se move: o personagem se move dentro dela e a câmera o acompanha. O herói funciona sem o
componente de níveis: outro sistema pode chamar `place_at()` quando seus níveis estiverem prontos.

## Os níveis da demo

**A clareira** (`shared/world/world.tscn`, veja [Mundo e navegação](world-and-navigation.md)) contém, sob `Travel`,
o ponto `Start` (`default`) na origem olhando para o norte; a plataforma `IslandPad` perto do Círculo Antigo, a
12 m ao norte do início e visível dali, que leva à ilha; e o ponto `FromIsland` (`from_island`) ao lado dela,
olhando para o leste, com a plataforma à esquerda e um pouco atrás do herói.

**Ilha Solitária** (`shared/world/island/island.tscn`) é uma ilha circular de 30 m num lago. Usa objetos, materiais
e shaders da clareira; seus únicos arquivos próprios são dois materiais:

- a grama usa `island_ground.tres`: o chão da clareira com as estradas de terra desativadas (`roads`), pois elas
  são desenhadas em coordenadas globais e pertencem à clareira;
- o lago usa `lake_water.tres`: água parada do poço num azul mais claro e com ondulação mais forte; é um plano de
  600 m que chega ao horizonte;
- há costa rochosa sob a borda da grama e pedras grandes na água rasa;
- muros invisíveis em anel a 14.5 m (`Edge`, 24 caixas) mantêm o herói na ilha. Estão na camada de física `bounds`
  (4), com a qual o personagem colide, mas cliques e câmera não enxergam; assim, um clique na água não acerta o
  muro e a câmera o atravessa. A malha de navegação da ilha é gerada das camadas 1 e 4, mantendo os caminhos
  longe desses muros;
- o Acampamento do Eremita fica ao norte: barraca, fogueira e barris, um lugar descobrível (seu `PointOfInterest`
  está sob `Places`);
- o ponto `Arrival` (`default`) fica ao sul, voltado para o norte, na direção do acampamento; `HomePad` leva de
  volta à clareira (ponto `from_island`) e fica à esquerda, atrás do herói;
- possui sua própria malha de navegação, gerada como a da clareira (veja [Gerar novamente a malha de
  navegação](world-and-navigation.md#gerando-novamente-a-malha-de-navegação)).

Os dois níveis compartilham o ambiente `shared/world/world_environment.tres`: céu, névoa e luz ambiente. Cada um
tem sua própria cópia do sol (`Sun`).

As plataformas (`shared/world/props/teleport_pad.tscn`) são instâncias de uma cena: um `LevelPortal` com disco de
pedra, incrustação luminosa, cristal giratório acima da cabeça, luz e placa com o nome do lugar. Não têm colisão;
portanto, as malhas de navegação sob elas não precisaram mudar.

## Adicionando um nível

1. Crie uma cena com raiz `Node3D`: luz e ambiente do nível, `NavigationRegion3D` com chão e objetos, e um
   `SpawnPoint` no chão com `spawn_name` `default`. Muros invisíveis nas bordas vão na camada 4 (`bounds`).
2. Crie um `NavigationMesh` exclusivo e gere a malha do nível: use colisores estáticos, camada de física 1 e também
   4 se houver muros invisíveis nas bordas. Combine a altura da célula de 0.025 m e o tamanho de 0.25 m do mapa;
   comece com raio 0.5 m, escalada máxima 0.3 m e inclinação máxima 40°. Para a cápsula fornecida de 1.8 m, use
   Agent Height de 1.8 m e ative `filter_walkable_low_height_spans` para excluir tetos baixos. Se copiar o recurso
   de malha da demo, torne-o único antes de gerar novamente e reveja altura e filtro. Veja
   [Mundo e navegação](world-and-navigation.md#camadas-de-física-e-navegação).
3. Adicione um portal para o novo nível a partir de outro: uma instância de `teleport_pad.tscn` ou seu próprio
   `LevelPortal`, com `target_level` apontando para a cena nova, e um portal de volta. Ponha um ponto de entrada
   junto de cada plataforma e indique seu nome em `target_spawn` da plataforma do outro nível.
4. Acrescente os nomes dos portais e lugares às traduções: `localization_checks.gd` percorre todos os níveis
   alcançáveis pelos portais a partir do inicial e informa strings ausentes. Um nível acessível somente por
   `change_level()` no código não é verificado.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
