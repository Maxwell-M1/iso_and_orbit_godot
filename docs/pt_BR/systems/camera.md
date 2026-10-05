<!-- translation of docs/en/systems/camera.md @ d5569844bc1c -->
<!-- translation of docs/en/systems/camera.md @ pending -->
# Câmera

[← Índice da documentação](../index.md)

> Esta é uma tradução do [original em inglês](../../en/systems/camera.md).
> Em caso de divergência, consulte a versão em inglês.

`OrbitCameraRig` acompanha um alvo `Node3D`, gira em torno dele com o mouse e muda distância e inclinação com a
roda. Seu filho `CameraArm` posiciona um `Camera3D` ao longo de +Z local e o mantém fora da geometria próxima. O
giro automático, o alinhamento da inclinação e o alinhamento do zoom durante a corrida são três opções
independentes.

```text
PlayableHero (raiz estacionária no modelo)
├── Character (alvo em movimento)
└── CameraRig (OrbitCameraRig; target = ../Character)
    └── CameraArm (CameraArm)
        └── Camera3D (current = true)
```

Mantenha o rig ao lado do alvo móvel, não sob ele: o rig define sua posição e rotação globais. Deixe rig, braço,
câmera e seus ancestrais na escala `(1, 1, 1)` para que comprimento e raio de colisão conservem seu significado.
O rig posiciona a câmera a cada quadro renderizado usando `target.get_global_transform_interpolated()` e desativa
sua interpolação de física em `_ready()`; os filhos herdam esse modo por padrão. Ative a interpolação no projeto
quando o alvo se mover em ticks de física, senão ele avançará visivelmente um tick de cada vez. O modelo já a
ativa. `height_follow_time` pode suavizar a subida e descida vertical do alvo depois da interpolação.

`Camera3D` deve começar com sua transformação local padrão: o braço define sua posição e rotação locais. O modelo
a marca como **Current**, usa campo de visão de 45° e plano distante de 300 unidades do mundo. Se outra câmera
ativa entrar na cena, volte a ativar esta quando o herói precisar controlar a visão. Veja
[Integração](../integration.md#só-a-câmera) para copiar a câmera ou o herói inteiro e
[Configuração do projeto](../project-setup.md) para ações e camadas de física.

## Quais valores estão ativos?

Os valores dos scripts abaixo são padrões dos componentes reutilizáveis. `gdscript/player/playable_hero.tscn`
substitui alguns; `SettingsApplier` da demo aplica depois os valores salvos em `Settings` quando a cena principal
inicia. Uma cena do herói copiada funciona sem o autoload ou a janela da demo, usando os valores da cena.

| Ajuste | Padrão do script | Cena do herói / demo recém-iniciada |
|---|---:|---:|
| Alinhamento de giro, inclinação e zoom na corrida | todos desligados | todos desligados |
| `follow_time` | 1.5 s | 1.1 s |
| `follow_pitch_angle`, `follow_pitch_time` | −40°, 1.5 s | −22°, 1.1 s |
| `follow_zoom_level`, `follow_zoom_time` | 0.55, 1.5 s | 0.55, 1.5 s |
| `follow_wait_after_rotate` | desligado | ligado |
| `height_follow_time` | 0 s | 0.15 s |

Tempos e destinos de giro, inclinação e zoom só atuam quando os respectivos controles de acompanhamento estão
ligados. `height_follow_time` sempre suaviza o movimento vertical do alvo, mesmo com órbita manual. Na demo, uma
escolha anterior em `user://settings.cfg` pode substituir os padrões iniciais. `SettingsApplier` converte os graus
positivos de “Inclinação para baixo” da janela em inclinação negativa e os 0–100% de “Altura” em zoom 0–1 do rig.

Comprimentos e velocidades usam unidades do mundo Godot (metros quando a cena usa a escala 1 unidade = 1 m do
modelo). Ângulos e velocidades angulares marcados `radians_as_degrees` aparecem em graus no Inspector; GDScript
atribui radianos: use `deg_to_rad(-22.0)` para `follow_pitch_angle` e `deg_to_rad(360.0)` para
`sharp_turn_speed`. O valor serializado `-0.383972...` em `playable_hero.tscn` equivale a −22°.

## Órbita, inclinação e zoom

Segure `camera_rotate` (botão direito no modelo) e mova o mouse para girar. O cursor é capturado e volta à posição
anterior ao soltar; perda de foco ou pausa também o liberam. Com `mouse_pitch` desligado, o movimento vertical do
mouse não afeta a visão e a roda escolhe a inclinação. Ligue-o para inclinar com o mouse; `invert_pitch` inverte o
eixo. Roda para cima abaixa a câmera; para baixo a eleva. Rolagem suave pode mover uma fração de `zoom_step`.

Zoom vai de 0 (perto) a 1 (longe). O passo padrão da roda é 0.1. O braço varia de `near_distance` 5 a
`far_distance` 20 unidades do mundo. Perto, a inclinação fica mais rasa, conforme esta curva:

| Zoom | Distância | Inclinação básica |
|---:|---:|---:|
| 0 | 5 | −22° |
| 0.2 (`flatten_end_zoom`) | 8 | −22° |
| 0.5 (`flatten_start_zoom`) | 12.5 | −38.5° |
| 0.55 (`start_zoom`) | 13.25 | −40.15° |
| 1 | 20 | −55° |

Entre zoom 0.2 e 0.5, a câmera se nivela rapidamente ao descer, mostrando melhor o chão à frente. Abaixo de
0.2, só a distância muda. A inclinação pelo mouse ou pelo acompanhamento soma um deslocamento à curva, limitado
por `min_pitch` e `max_pitch` (−80° e −8°). Desligar `mouse_pitch` limpa seu deslocamento, salvo se
`follow_pitch` ainda mantiver uma inclinação. `rotation_sharpness` e `zoom_sharpness` suavizam mouse e roda; 0
torna a respectiva entrada imediata.

## Modo de acompanhamento

Ative qualquer combinação de `follow_movement`, `follow_pitch` e `follow_zoom` para girar atrás da direção da
corrida, aproximar-se de uma inclinação escolhida e voltar a um zoom escolhido. O rig mede o movimento horizontal
por tick de física em qualquer alvo `Node3D`, sem exigir uma propriedade de velocidade. Abaixo de
`follow_min_speed`, não acompanha; entre essa velocidade e o dobro, a força do acompanhamento cresce
suavemente. Um alvo que para começa a próxima corrida com uma direção nova.

Cada movimento ativo começa e se estabiliza suavemente com sua própria mola. Seu tempo aproxima o necessário para
completar 95% de uma mudança a partir do repouso numa corrida a toda velocidade, se não houver limite de giro; 0
pede mudança imediata. Ao parar ou pausar o acompanhamento, um movimento em curso freia, sem corte brusco.
`rotation_sharpness` e `zoom_sharpness` definem a taxa dessa frenagem. O acompanhamento move a câmera diretamente,
portanto a suavização da entrada não acrescenta outro atraso.

| Propriedade | Padrão do script | Efeito |
|---|---:|---|
| `follow_movement`, `follow_time` | desligado, 1.5 s | Girar atrás da corrida horizontal; tempo para quase completar o giro |
| `follow_max_turn_speed` | 0 | Velocidade angular máxima automática em °/s; 0 elimina o limite, inclusive em giro instantâneo |
| `follow_toward_camera_angle` | 30° | Ignora corrida dentro deste ângulo em direção à câmera; força total do giro ao dobro do ângulo. 0 elimina a exceção |
| `sharp_turn_speed` | 360°/s | Ignora direções intermediárias em mudança brusca ou inversão, depois assume a nova direção; 0 desativa a proteção |
| `teleport_speed` | 50 unidades do mundo/s | Movimento horizontal mais rápido entre ticks é tratado como teleporte, não corrida |
| `follow_pitch`, `follow_pitch_angle`, `follow_pitch_time` | desligado, −40°, 1.5 s | Aproxima a inclinação desse ângulo para baixo, independentemente do giro horizontal |
| `follow_zoom`, `follow_zoom_level`, `follow_zoom_time` | desligado, 0.55, 1.5 s | Aproxima o zoom desse valor de 0–1, independente de giro e inclinação |
| `follow_min_speed` | 1 unidade do mundo/s | Velocidade horizontal mínima para acompanhar; força total ao dobro dela |
| `follow_wait_after_rotate` | desligado | Mantém a visão após órbita manual até o alvo reduzir a velocidade abaixo de `follow_min_speed` ou informar nova corrida |

A proteção contra movimento em direção à câmera afeta **apenas o giro**. Uma corrida diretamente para a câmera
ainda pode mudar inclinação e zoom se ativados. A proteção contra giros bruscos também afeta só o giro: inclinação
e zoom continuam numa inversão, enquanto um giro já em curso pode frear aos poucos. Com
`LocomotionSettings.turn_speed` de 720°/s do herói, o limite de 360°/s reconhece inversões e permite curvas mais
lentas. Se mudar a velocidade de giro do personagem, deixe `sharp_turn_speed` na metade dela ou menos;
`PlayableHero` avisa quando um limite positivo chega à velocidade de giro do personagem. Definir
`follow_toward_camera_angle` como 0 permite, deliberadamente, que a câmera dê a volta numa corrida rumo a ela.

Com alinhamentos de inclinação e zoom ativos, o zoom altera a distância e o alinhamento de inclinação compensa a
curva do zoom. A visão chega a `follow_pitch_angle` e `follow_zoom_level` independentemente. Roda e mouse ainda
funcionam durante a corrida; os acompanhamentos ativos trazem a visão de volta aos destinos. `height_follow_time`
é separado: suaviza como o rig segue a **posição Y global** do alvo, especialmente em degraus. Não altera o nível
de zoom. Em 0 acompanha a altura exatamente; os 0.15 s da cena do herói completam cerca de 95% da mudança vertical
nesse tempo.

### Quando o acompanhamento pausa

Os três movimentos param de puxar enquanto o botão direito está pressionado. Com `follow_wait_after_rotate` ativo,
terminar uma órbita após pelo menos 0.2 s ou 2 px de movimento mantém a visão escolhida enquanto a corrida atual
continua. Isso também vale se o foco se perder ou o jogo pausar antes de soltar o botão; um toque mais curto não
inicia a espera. Com a opção desligada, o acompanhamento volta ao fim da órbita. A espera termina quando a
velocidade cai abaixo de `follow_min_speed`, `end_follow_wait()` informa nova corrida, `snap()` é chamado, o alvo
muda ou o movimento passa de `teleport_speed`. Uma nova corrida pode começar antes da anterior parar, por isso
conecte o sinal `run_requested` da entrada a `end_follow_wait()` ao usar essa opção. Sem tal sinal, um alvo que se
move continuamente pode deixar a câmera esperando indefinidamente; desligue a opção se o jogo não puder informar
novas corridas.

`playable_hero.tscn` conecta também `PointClickMoveInput.hold_pending_changed` a `set_follow_paused()`. Isso pausa
o acompanhamento nos primeiros 0.2 s do botão esquerdo, enquanto a entrada distingue clique de botão segurado.
Seu `run_requested` encerra a espera após órbita em novo clique, botão segurado ou corrida com botão direito +
tecla. Pressionar o direito durante uma corrida com o esquerdo permite olhar em volta; ao soltar o direito, essa
mesma corrida não conta como nova, então a visão fica onde o jogador a deixou até parada ou nova corrida.
`keep_aim_on_camera_turn` mantém o cursor apontado para o mesmo ponto global enquanto a câmera se move, evitando
que a direção da corrida persiga a câmera.

Quando `Engine.time_scale` é 0, os movimentos de acompanhamento mantêm seu estado e retomam quando o tempo
avança. Se mover manualmente um alvo ou teleportá-lo por distância curta demais para acionar `teleport_speed`,
chame `snap()` para reposicionar câmera e braço e reiniciar o histórico de movimento.

## Propriedades

| Grupo | Propriedade | Padrão do script | Significado |
|---|---|---:|---|
| Alvo | `target` | nenhum | `Node3D` a acompanhar |
| Alvo | `arm`, `camera` | nenhum | Primeiro filho direto correspondente, se vazio; use `camera` somente sem braço |
| Entrada | `rotate_action`, `zoom_in_action`, `zoom_out_action` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` | Ações do Mapa de Entrada; ausentes geram erro na inicialização |
| Entrada | `mouse_sensitivity`, `mouse_pitch`, `invert_pitch`, `zoom_step` | 0.25 °/px, desligado, desligado, 0.1 | Velocidade da órbita, controle da inclinação com mouse e passo da roda |
| Enquadramento | `focus_height` | 1.2 unidades do mundo | Ponto visado acima da origem do alvo |
| Enquadramento | `near_distance`, `far_distance` | 5, 20 | Comprimentos do braço no zoom 0 e 1 |
| Enquadramento | `near_pitch`, `far_pitch` | −22°, −55° | Inclinações básicas no zoom 0 e 1 |
| Enquadramento | `flatten_start_zoom`, `flatten_end_zoom` | 0.5, 0.2 | Faixa do zoom que nivela mais depressa a inclinação |
| Enquadramento | `min_pitch`, `max_pitch` | −80°, −8° | Limites finais, inclusive deslocamentos por mouse e acompanhamento |
| Enquadramento | `start_zoom`, `start_yaw` | 0.55, 45° | Zoom e giro inicial no eixo global; `look_along()` pode mudar o giro depois |
| Suavização | `rotation_sharpness`, `zoom_sharpness` | 30, 10 | Valores maiores alcançam mais rápido os destinos do mouse/roda; 0 é imediato |
| Suavização | `height_follow_time` | 0 s | Tempo para cobrir cerca de 95% da mudança vertical do alvo; 0 segue exatamente |

`look_along(direction)` aponta imediatamente a visão ao longo da parte horizontal de uma direção em **coordenadas
globais** e interrompe um giro automático em curso. `snap()` aplica imediatamente giro, inclinação, zoom, posição
do alvo e resposta do braço às colisões; use depois de teleportar. `get_zoom()` retorna zoom atual de 0–1.
`is_rotating()`, `is_follow_paused()`, `is_follow_waiting()` e `is_target_turning_sharply()` informam esses estados.
`set_follow_paused(paused)` e `end_follow_wait()` controlam as pausas descritas acima.

O rig exige um filho braço ou câmera (ou propriedade explícita `arm`/`camera`); a falta gera assert em versão de
depuração. Ele define a rotação global; assim, `start_yaw`, `look_along()` e o giro automático usam eixos globais
mesmo com a raiz estacionária do herói girada.

## Obstáculos, ocultação e transparência

`CameraArm` normalmente usa `keep_out_of_geometry`: uma esfera na posição desejada da câmera deve caber fora dos
corpos físicos. Se uma parede, encosta ou teto ocupar essa posição, o braço encurta imediatamente. Uma cerca entre
alvo e câmera não o encurta se ainda houver espaço atrás dela. Para aproximar deliberadamente a câmera pela frente
de uma cerca que esconde o alvo, ative `pull_in_on_occlusion`; o braço espera ocultação contínua e só avança se
restar pelo menos `min_pull_in_length`. Ao liberar a visão, aguarda um pouco e volta suavemente. Se houver obstáculo
no caminho de volta, salta sobre ele em vez de atravessá-lo.

### Como o braço distingue espaço livre atrás de um obstáculo de um corpo ocupado

Primeiro, o braço verifica se a esfera cabe na ponta desejada. Ela pode ficar atrás de uma cerca entre o alvo e a
câmera se esse lugar estiver livre. Se a ponta tocar ou ficar dentro de um corpo, ele procura um lugar livre mais
perto do alvo. Os lançamentos de formas do Jolt não informam corpos tocados ou penetrados no começo do lançamento;
por isso o braço verifica separadamente o espaço inicial. Com dois corpos próximos, procura a partir de um ponto
mais perto do alvo. Isso também impede que a câmera entre numa cerca com penhasco logo atrás.

A esfera e os raios de visibilidade usam `collision_mask` (binário `0b101`, camadas 1 e 3). No modelo, a camada 1
contém geometria sólida do mundo e a 3 contém bloqueios exclusivos da câmera, como `RoofCameraBlocker`;
personagens na 2 e limites invisíveis na 4 não movem o braço. Um corpo em `camera_ignore`, ou sob um nó desse
grupo, é ignorado. Defina esse grupo na raiz de um objeto para afetar todas as instâncias. Os números das máscaras
importam ao copiar para outro projeto; os nomes das camadas são apenas rótulos. Com `keep_out_of_geometry`
desligado, o braço deixa de proteger a câmera da geometria atrás dela, independentemente da aproximação por
ocultação.

Os cinco `occlusion_points` padrão amostram peito, cabeça, joelhos e lados do alvo. São relativos ao **início do
braço**, que o rig põe `focus_height` acima da origem do alvo: x para a direita da câmera, y para cima e z
horizontalmente rumo à câmera. `occlusion_share = 0.75` exige pelo menos quatro dos cinco pontos bloqueados.
Ajuste pontos e `focus_height` para modelos mais altos ou flutuantes. `CharacterHover` do modelo pode elevar o
personagem visível 0.35 unidade do mundo acima do corpo.

`fade_target` é opcional. Quando definido, o braço altera a `transparency` dos descendentes `GeometryInstance3D`
desse alvo se o braço ficar mais curto que `fade_start_length`, atingindo `fade_transparency` em
`fade_end_length`. O herói atribui `Character/Visual`. Essa transparência de perto é distinta do addon opcional
`OccludedSilhouette`, que desenha o personagem através de obstáculos.

| Propriedade | Padrão do script | Significado |
|---|---:|---|
| `length`, `camera` | 10, nenhum | Comprimento desejado do braço (normalmente definido pelo rig) e primeiro filho direto `Camera3D`, salvo atribuição explícita |
| `keep_out_of_geometry`, `probe_radius` | ligado, 0.3 | Manter uma esfera de câmera fora dos corpos incluídos na máscara |
| `collision_mask`, `ignored_groups` | camadas 1 + 3, `camera_ignore` | Corpos considerados para colisão/ocultação e grupos excluídos |
| `pull_in_on_occlusion`, `min_pull_in_length`, `pull_in_sharpness` | desligado, 2.5, 10 | Aproximação, comprimento mínimo e taxa de avanço (0 é imediato) |
| `occlusion_points`, `occlusion_share`, `occlusion_delay` | cinco pontos, 0.75, 0.25 s | Amostras de visibilidade, fração bloqueada e espera antes de aproximar ou voltar |
| `return_delay`, `return_sharpness` | 0.3 s, 4 | Espera e velocidade de extensão do braço (taxa 0 é imediata após a espera) |
| `fade_target`, `fade_start_length`, `fade_end_length`, `fade_transparency` | nenhum, 1.5, 0.7, 0.75 | Transparência opcional do modelo, máxima a 0.7 unidade ou menos |
| `debug_draw` | desligado | Desenha comprimentos desejado/atual, esfera da câmera e raios de visibilidade; útil de outra câmera |

`CameraArm.snap()` recalcula colisões e posiciona a câmera sem esperar o retorno. `get_current_length()` dá o
comprimento real após obstáculos; `is_pulled_in_by_occlusion()` informa se a ocultação do alvo a está aproximando.

O comportamento acima é exercitado por [`tests/camera_checks.gd`](../../../tests/camera_checks.gd) e
[`tests/camera_arm_checks.gd`](../../../tests/camera_arm_checks.gd): cobrem tempos de acompanhamento, proteções
contra corridas rumo à câmera e giros bruscos, espera após órbita manual, alinhamentos de inclinação/zoom,
suavização vertical nos degraus, desvio de obstáculos, aproximação opcional, grupos ignorados e transparência.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
