<!-- translation of docs/en/systems/locomotion.md @ 78c912e8971a -->
# Locomoção

[← Índice da documentação](../index.md)

> Esta é uma tradução do [original em inglês](../../en/systems/locomotion.md).
> Onde houver diferenças, a versão em inglês é a correta.

Como o personagem corre, para, vira, faz corrida rápida, pula, sobe degraus e evita desníveis. Para levar o herói
montado e os arquivos necessários a outro projeto, comece em
[Usando no seu projeto](../integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto). Para escolhas de
controle prontas, veja [Configurações](../configurations.md). Quatro classes dividem o trabalho:

| Classe | Tipo | Função |
|---|---|---|
| `LocomotionSettings` | Resource | Velocidade, aceleração, frenagem, giro |
| `GroundMotion` | RefCounted | A matemática: direção desejada e distância restante → velocidade horizontal |
| `NavigationMover` | Node, filho do corpo | Caminhos e comandos; retorna uma velocidade, nunca move o corpo |
| `GroundCharacter` | CharacterBody3D | Gravidade, pulo, corrida rápida, `move_and_slide()`, giro do modelo |

Dois auxiliares se conectam ao corpo: `Stamina` (a reserva para a corrida rápida) e `LedgeGuard` (nada de sair andando
de desníveis). Um recurso `FallSettings` define a queda. `CharacterMonitor` mostra como texto o que o corpo informa.
`CharacterHover` faz o modelo flutuar sobre o chão; veja
[Personagens](characters.md#characterhover-flutuando-acima-do-chão).

## A sensação da corrida

- **Aceleração e frenagem constantes.** A velocidade muda numa taxa fixa, definida por `acceleration_time` e
  `stop_time`.
- **Parada exata.** Perto do alvo, a velocidade é limitada a `√(2 · braking · distance left)`: o personagem começa a
  frear exatamente onde ainda consegue parar no ponto, e nunca passa dele.
- **Sem reinício com um novo alvo.** Um novo clique durante a frenagem mantém a velocidade atual; o personagem acelera
  de novo a partir dela.
- **Velocidade de giro limitada.** Na corrida, a direção gira a `turn_speed`. Enquanto a direção não alcança a
  desejada, `turn_slowdown` tira um pouco da velocidade, então uma curva fechada vira um arco apertado, não uma
  derrapagem larga.
- **Giro instantâneo a partir da parada.** Abaixo de `pivot_speed`, o personagem vira na hora, então uma partida em
  qualquer direção não tem arco nem atraso.
- **Frenagem forte quando necessário.** Se o ponto de parada é definido logo à frente de um personagem correndo, ele
  pode frear até `max_braking_multiplier` vezes mais forte que o normal.

## LocomotionSettings

Estes são os padrões do script `LocomotionSettings` e os valores do recurso fornecido
`gdscript/player/player_locomotion.tres`. O recurso separado permite às configurações da demo alterar a velocidade
de corrida rápida e de recuo deste herói sem mudar outros personagens.

| Propriedade | Padrão | Significado |
|---|---|---|
| `max_speed` | 5.5 m/s | Velocidade de corrida |
| `acceleration_time` | 0.18 s | Da parada até `max_speed` |
| `stop_time` | 0.22 s | De `max_speed` até parar; distância de frenagem `max_speed × stop_time / 2` (cerca de 0.61 m) |
| `turn_speed` | 720 °/s | Velocidade de giro na corrida. Mantenha `sharp_turn_speed` da câmera na metade ou menos (veja [Câmera](camera.md#modo-de-acompanhamento)) |
| `turn_slowdown` | 0.75 | Velocidade perdida enquanto a direção alcança a desejada: 0 a mantém (arco largo), 1 freia até zero em giro de 90° ou mais |
| `pivot_speed` | 1 m/s | Abaixo disso, o personagem vira instantaneamente |
| `max_braking_multiplier` | 3 | Multiplicador máximo da frenagem para um ponto logo à frente |
| `sprint_speed_multiplier` | 1.5 | Multiplicador da velocidade básica na corrida rápida (8.25 m/s); aceleração e frenagem permanecem iguais |
| `backward_speed_multiplier` | 0.7 | Fração da velocidade mantida ao recuar (olhando contra o movimento) |

Como a corrida rápida eleva apenas o limite de velocidade, parar após atingir a velocidade máxima demora mais e
exige mais distância: cerca de 1.36 m a 8.25 m/s com a frenagem padrão, contra 0.61 m a 5.5 m/s. Um destino
clicado logo à frente pode usar `max_braking_multiplier` para parar mais cedo.

`SettingsApplier` da demo altera `sprint_speed_multiplier` e `backward_speed_multiplier` ao iniciar e ao mudar
um ajuste; valores salvos podem substituir os acima. O addon em si não tem sistema de configurações. Para ajustar
a demo em execução, use Cena → Remote → `Hero/Character/NavigationMover` → `settings`. O código lê os campos do
recurso a cada tick, mas alterações no inspetor Remote não são salvas: copie o resultado para o `.tres`. Use um
recurso separado por personagem se mudanças em execução não devem afetar os demais. Atribua-o antes de o
movimentador entrar na árvore ou use **Make Unique** no editor: após `_ready()`, `GroundMotion` retém o recurso
original, então substituir `mover.settings` não altera seus ajustes. Durante o jogo, edite os campos do recurso
existente.

Um recurso pode ser compartilhado por vários personagens, por exemplo todos os NPCs de um mesmo tipo.

## NavigationMover

Um filho do corpo (qualquer `Node3D`, geralmente um `CharacterBody3D`). Dois modos:

- `move_to(point)`: até um ponto por um caminho de navegação, contornando obstáculos, com parada exata no fim do
  caminho. Ele vem de `NavigationServer3D` para o mundo do corpo. Se o resultado for vazio, inclusive num mundo
  sem malha de navegação, o movimentador corre diretamente até o ponto solicitado.
- `steer(direction, facing = Vector3.ZERO)`: numa direção, sem caminho, até `stop()`, `halt()` ou `move_to()`. Os
  obstáculos são resolvidos pelo corpo deslizando ao longo deles. Com `facing`, o personagem olha nessa direção
  enquanto se move: passo lateral e recuo. A orientação se mantém depois de `stop()`; `move_to()`, `steer()` sem
  direção de olhar, `halt()` e `face()` a limpam.

O corpo chama `compute_velocity(delta)` uma vez por tick de física, antes de `move_and_slide()`. `stop()` freia
suavemente, `halt()` para imediatamente (num teleporte), e `face(direction)` vira um personagem parado sem corrida,
por exemplo num ponto de entrada: direção de deslocamento e de olhar mudam na hora, e `GroundCharacter` gira seu
modelo depois, na velocidade `visual_turn_speed` (só `GroundCharacter.teleport(position, facing)` gira também o
modelo imediatamente). Uma corrida em curso volta a orientar o personagem no rumo do movimento.

| Propriedade | Padrão | Significado |
|---|---|---|
| `settings` | — | `LocomotionSettings`; se vazio, o movimentador cria um com padrões do script em `_ready()` |
| `use_navigation` | ligado | Buscar um caminho; desligado, ou sem navegação no mundo: correr direto até o ponto |
| `navigation_layers` | 1 | Camadas de navegação que o caminho pode usar |
| `waypoint_radius` | 0,4 m | Um ponto do caminho conta como ultrapassado a menos que isso; maior corta cantos mais cedo |
| `arrive_distance` | 0,005 m | A menos que isso do fim, o personagem para na hora. A própria frenagem o leva até o ponto, então o limiar é minúsculo |
| `retarget_tolerance` | 0,1 m | Um novo ponto a menos que isso do atual não reconstrói o caminho. Um botão segurado envia um ponto a cada tick |
| `max_path_deviation` | 2 m | Empurrado para mais longe que isso do caminho, o personagem recebe um novo caminho |
| `sprinting` | desligado | Eleva o limite por `sprint_speed_multiplier`. O dono decide quando; `GroundCharacter` o define a cada tick, então nesse corpo use `sprint_requested` |

Sinais: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled`.

`arrived` indica o fim do caminho. Um caminho pode terminar no ponto alcançável mais próximo, antes do destino
solicitado; compare as posições se o jogo exigir aquele ponto exato. O movimento direto usado como alternativa
não evita obstáculos além do deslizamento da colisão do corpo.

| Consulta | Retorna |
|---|---|
| `is_moving()` | Há comando para chegar a um ponto ou seguir direção; informa o comando, não a velocidade: verdadeiro ainda parado no início, falso enquanto freia após `stop()` |
| `is_steering()` | Corre na direção de `steer()`, não rumo a um ponto |
| `has_destination()`, `get_destination()` | Há ponto de `move_to()` em andamento (até chegar ou cancelar); esse ponto |
| `get_speed()` | Velocidade de corrida, m/s |
| `get_heading()` | Direção do movimento, vetor horizontal unitário; parado, direção da última corrida |
| `get_facing()` | Direção em que deve olhar: a do movimento (`get_heading()`) ou a indicada por `steer()` |
| `get_body()` | Corpo que comanda, seu pai |
| `get_remaining_path()` | Pontos restantes desde o próximo, na altura da malha; vazio no movimento direto |

**Os pontos do caminho são comparados no plano horizontal.** Uma malha de navegação do Recast fica suspensa acima do
chão cerca de duas alturas de célula (0,05 m aqui). Comparar distâncias 3D com os pés do personagem erraria por esse
tanto, e é por isso que o movimentador segue o caminho ele mesmo em vez de usar `NavigationAgent3D`.

**O recuo é mais lento.** Quando `steer()` recebe um `facing`, a velocidade é escalada conforme o quanto o movimento se
opõe à orientação: direto para trás recebe o `backward_speed_multiplier` inteiro, na diagonal para trás uma parte dele
(S + D no modo lateral: 21% mais lento), de lado nada. Então a redução só existe no modo lateral das teclas, veja
[Entrada](input.md).

## GroundCharacter

O único lugar onde o corpo se move. Em cada tick de física, ele atualiza o estado da corrida rápida, pega a velocidade
horizontal do movimentador, trata o pulo e a gravidade, deixa `LedgeGuard` corrigir a velocidade, chama
`move_and_slide()` com a subida de um degrau antes e a descida de um degrau depois, e então informa o que o tick mudou:
o contato com o chão, o degrau percorrido, os passos, o giro do modelo para `mover.get_facing()` e o estado.

O inspetor agrupa as propriedades: primeiro as partes e o giro, depois Ground, Jump and fall, Sprint e Steps.

| Propriedade | Padrão | Significado |
|---|---|---|
| `mover` | — | O `NavigationMover`; obrigatório |
| `visual` | — | Nó girado em relação ao corpo para olhar na direção do movimento; sua frente é −Z |
| `visual_turn_speed` | 1080 °/s | A rapidez com que o modelo vira |
| `max_step_height` | 0,3 m | O degrau mais alto em que o personagem sobe sem pular, e o mais fundo que ele desce sem sair do chão. 0 desliga a subida e a descida de degraus |
| `ledge_guard` | — | `LedgeGuard` opcional; sem ele, o personagem cai de qualquer altura |
| `can_jump` | ligado | Pulo permitido; desligado, `jump()` não faz nada |
| `jump_height` | 1 m | Altura dos pés no topo do pulo |
| `coyote_time` | 0,1 s | Um pulo ainda funciona por esse tempo depois de sair de uma borda |
| `jump_buffer_time` | 0,12 s | Um pulo pressionado esse tempo antes de aterrissar acontece na aterrissagem |
| `gravity_scale` | 3 | Multiplicador da gravidade na subida do pulo e na descida, salvo se `fall` definir outro. O personagem corre mais rápido que uma pessoa e cairia devagar com gravidade normal: uma queda de 1.6 m leva 0.33 s, não 0.57 s |
| `fall` | — | Um `FallSettings`: aceleração e limite de velocidade da queda, veja [A queda](#a-queda). Vazio: usa `gravity_scale`, sem limite |
| `landing_min_speed` | 2,5 m/s | Uma queda mais lenta (um solavanco, uma rampa) é só `touched_floor`, não `landed` |
| `can_sprint` | ligado | Corrida rápida permitida. Se desligada durante a corrida, a velocidade extra é freada |
| `stamina` | — | `Stamina` opcional; sem ele, a corrida rápida nunca cansa |
| `sprint_tires` | ligado | A corrida rápida gasta fôlego |
| `sprint_duration` | 5 s | Quanto dura uma reserva cheia: gasta `max_value / sprint_duration` por segundo |
| `steps_enabled` | ligado | Conta os passos: `stepped` e ritmo. Desligue num personagem sem pernas; ao religar, o primeiro passo vem após `first_step_distance` |
| `stride_length` | 1,5 m | Distância no chão entre os passos |
| `first_step_distance` | 0,3 m | Distância da parada até o primeiro passo |

O limite de inclinação é o próprio `floor_max_angle` do corpo (Floor → Max Angle no inspetor, 45° por padrão). Uma
superfície mais íngreme é parede para corpo, degraus e proteção de bordas. Para cima é +Y: mantenha `up_direction`
em `Vector3.UP`.

Ao mudar o tamanho do corpo ou os degraus, ajuste em conjunto: `max_step_height` não pode ser menor que o degrau,
`LedgeGuard.max_drop` deve ser pelo menos igual a `max_step_height`, e `agent_max_climb` da malha deve corresponder
ao degrau que se pretende atravessar. Gere novamente a malha após alterar seus ajustes. A malha planeja rotas; a
cápsula, inclinação do piso, espaço sob o teto e colisões ainda determinam se o corpo pode segui-las. Mantenha
`floor_snap_length` abaixo de `max_step_height` se quiser `stair_taken` na descida. A demo usa cápsula de 1.8 m de
altura e 0.35 m de raio, degraus de 0.3 m, proteção contra quedas de 0.5 m e malha com escalada máxima de 0.3 m
e célula de altura 0.025 m; veja [Mundo e navegação](world-and-navigation.md#camadas-de-física-e-navegação).

O corpo pode começar girado no nível, como um NPC ajustado no editor ou a raiz `PlayableHero`: o personagem gira
apenas `visual` em relação ao corpo, começa olhando ao longo do −Z do corpo, e daí o movimentador toma sua
direção inicial. Depois, `teleport(position, facing)` ou `NavigationMover.face()` definem para onde olha.

Um componente pode interromper os passos sem mexer em `steps_enabled`: `set_steps_suppressed(self, true)`, e
`false` para liberá-los (`CharacterHover` faz isso durante a flutuação). Só se contam passos com `steps_enabled`
ligado e sem supressão por componente (`is_counting_steps()`); assim, o controle do jogo e os componentes não se
anulam. O personagem não mantém o componente vivo: ao ser liberado, os passos voltam até o tick seguinte. A queda
segue o mesmo princípio; veja [A queda](#a-queda).

Erros de configuração geram avisos quando o personagem entra na árvore, e `get_setup_warnings()` retorna a mesma
lista: movimentador ou proteção não é filho do corpo; `LedgeGuard.max_drop` fica abaixo de `max_step_height`,
barrando degraus que o personagem poderia descer; a aderência ao piso é tão longa quanto um degrau e absorve a
descida sem `stair_taken`; `can_jump` está ligado com `jump_height` ou `gravity_scale` em 0 e o pulo não sai do
chão (sem `jumped`); `fall.max_speed` fica abaixo de `landing_min_speed`, então não há aterrissagem; ou
`up_direction` não é +Y. `LedgeGuard` e `CharacterHover` verificam a própria configuração da mesma forma.

Defina `sprint_requested` para pedir a corrida rápida e chame `jump()` para pular. `CharacterActionInput` faz as duas
coisas para o jogador; uma IA pode fazer o mesmo.

`teleport(position, facing)` coloca o personagem imediatamente em outro lugar, como um ponto de entrada de outro
nível. Ele para por completo (`NavigationMover.halt()`), e quem acompanha o movimento não recebe tranco: velocidade,
aceleração e taxa de giro são zeradas, a suavização entre ticks recomeça no local novo (o modelo flutuante também
se ajusta) e um pulo pressionado antes é esquecido. Com `facing`, personagem e modelo giram imediatamente. O fôlego
é mantido e o estado de contato com o chão continua como estava; portanto, ponha os pés no chão. Em seguida vem o
sinal `teleported`, para câmera ou rastro que devam saltar junto. Nos testes, teleportar durante uma corrida de
5.5 m/s deixa o personagem parado no novo lugar no mesmo quadro, sem aceleração nem giro depois.

O teleporte do personagem não mexe na entrada do jogador nem na câmera. Para o herói do jogador, use
`PlayableHero.teleport()` ou `place_at()` (veja [Níveis](levels.md#o-herói-jogável)): eles também esquecem o botão
pressionado, giram a câmera se solicitado e a posicionam. Se usar só `GroundCharacter.teleport()`, chame antes
`PointClickMoveInput.cancel()` (um botão do mouse ainda segurado enviaria novo comando no tick seguinte) e conecte
`teleported` a `OrbitCameraRig.snap()`.

Com o tempo parado (`Engine.time_scale` 0), ticks de física continuam com passo zero. O personagem conserva
posição, velocidade (`get_move_velocity()`), estado e ritmo dos passos; aceleração e taxa de giro são 0, e modelo
flutuante e mão oscilante ficam onde estão. Ao retomar o tempo, a corrida continua no mesmo ritmo. Nos testes,
um herói correndo a 5.5 m/s, no chão ou flutuando, fica exatamente como estava, sem erro, e depois continua.
Entradas dadas nesse intervalo ainda chegam: a tecla da corrida rápida muda o estado (`sprint_changed`) e um
pulo pressionado no chão acontece imediatamente (`jumped`). Para impedir qualquer mudança, retire o controle
nesse período (`PlayableHero.controls_enabled`).

### O que o personagem informa

Animações, efeitos, sons e a interface não precisam deduzir pela velocidade o que o personagem está fazendo. Os momentos
chegam como sinais; o que muda o tempo todo é lido com consultas, a cada quadro ou tick.

| Sinal | Quando |
|---|---|
| `state_changed(state, previous)` | O estado mudou. No fim do tick, depois dos outros sinais do tick |
| `stepped(sprinting)` | Um pé tocou o chão (`get_step_foot()` diz qual): a cada `stride_length` percorrido no chão, o primeiro a `first_step_distance` da parada. Os passos seguem a distância, não o tempo: cerca de 3,7 por segundo correndo, 5,5 na corrida rápida, nenhum parado contra uma parede ou no ar |
| `jumped` | O personagem tomou impulso do chão; `left_floor` vem em seguida no mesmo tick |
| `left_floor` | O personagem saiu do chão: por um pulo ou de uma borda. Descer um degrau não conta |
| `touched_floor(fall_speed)` | De volta ao chão após qualquer tempo no ar; um para cada `left_floor`. `fall_speed` é a velocidade no contato |
| `landed(impact_speed)` | Um `touched_floor` a `landing_min_speed` ou mais rápido: uma aterrissagem de verdade, não um solavanco |
| `sprint_changed(sprinting)` | A corrida rápida começou ou parou |
| `stair_taken(height)` | Subiu ou desceu um degrau: altura de chão a chão, positiva ao subir, negativa ao descer (±0.2 m na demo). No fim do tick, antes de `state_changed`. Degraus baixos o bastante para a cápsula subir sozinha (até `radius × (1 − cos floor_max_angle)`, 0.1 m na demo) ou para a aderência ao piso descer (`floor_snap_length`) passam sem esse sinal |
| `teleported` | `teleport()` colocou o personagem em outro lugar; ao fim da operação, câmera ou rastro devem saltar para lá, não atravessar o espaço |

| Estado (`GroundCharacter.State`) | Quando |
|---|---|
| `IDLE` | No chão, mais lento que `IDLE_SPEED` (0,1 m/s), também ao correr contra uma parede |
| `RUNNING` | No chão, em movimento a qualquer velocidade, sem corrida rápida |
| `SPRINTING` | No chão, em corrida rápida |
| `JUMPING` | No ar depois de um pulo, até o topo |
| `FALLING` | No ar, descendo: depois do topo de um pulo ou ao sair de uma borda |

| Consulta | Retorna |
|---|---|
| `get_state()` | O estado |
| `get_move_velocity()`, `get_move_speed()` | Velocidade horizontal real e módulo, m/s: o que o corpo percorre. Diferente de `get_real_velocity()`, conta a subida de degraus e mantém o valor com tempo parado (`Engine.time_scale` 0) |
| `get_locomotion_blend()` | Para mistura 1D: 0 parado (abaixo de `IDLE_SPEED`), 1 em `max_speed`, 2 na velocidade máxima da corrida rápida, quaisquer que sejam as velocidades ajustadas |
| `get_local_movement()` | Para mistura 2D: x à direita do modelo (negativo à esquerda), y à frente (negativo atrás); o módulo é a mistura. Corrida (0, 1), corrida rápida (0, 2), passo à direita (1, 0), à esquerda (−1, 0), frente-esquerda (−0.71, 0.71), recuo (0, −0.7) |
| `get_local_acceleration()` | Taxa de aceleração, frenagem e mudança de direção, m/s², nos mesmos eixos: acelerar dá y > 0, frear y < 0, virar à esquerda x < 0. Calculada da velocidade que comanda o corpo, sem tranco de degraus nem indicação de choque com parede |
| `get_turn_rate()` | A rapidez com que o modelo vira, rad/s: positivo para a esquerda, negativo para a direita |
| `get_air_time()` | Segundos no ar; 0 no chão |
| `get_step_phase()` | Os passos dados como um número: inteiro a cada passo, a parte fracionária cresce com a distância entre os passos |
| `get_gait_cycle()` | O ciclo de dois passos, de 0 a 1: 0 quando o pé esquerdo toca o chão, 0,5 o direito |
| `get_step_foot()` | O pé do último passo, `Foot.LEFT` ou `Foot.RIGHT`. Os pés se alternam, também depois de paradas |
| `is_sprinting()`, `is_exhausted()`, `get_jump_speed()` | Em corrida rápida agora; exausto; a velocidade de impulso do pulo |
| `is_on_floor()`, `get_floor_angle()`, `velocity.y` | Do próprio `CharacterBody3D`: no chão, a inclinação sob os pés, a velocidade vertical |
| `get_ground_height(point, above, below)` | Altura do chão onde o corpo pode ficar sob um ponto: um raio de `above` metros acima até `below` abaixo, com a máscara do corpo; NAN se não houver chão ou se o raio começar dentro de algo (parede acima de `above`) |
| `is_counting_steps()` | Passos estão sendo contados: `steps_enabled` ativo, sem componente suprimindo-os |
| `get_fall_settings()` | Queda em vigor: override de maior prioridade, depois o mais recente se empatar; senão, `fall`. Null significa `gravity_scale` sem limite de velocidade |

Qual consulta usar:

- **Mistura de animações:** `get_locomotion_blend()` para `BlendSpace1D` com pontos 0, 1 e 2;
  `get_local_movement()` para `BlendSpace2D` com passos laterais e recuo. São as entradas exatas.
- **Efeitos que acompanham a velocidade:** `get_move_velocity()`, não `get_real_velocity()`. A velocidade real cai
  ao subir degraus, quando o corpo é colocado sobre o degrau após `move_and_slide()`; com o tempo parado, dividir
  o deslocamento do tick pela duração zero gera 0 / 0, NaN.
- **Inércia** (item que fica para trás, modelo que inclina ao partir ou virar, capa): `get_local_acceleration()`.
- **Inclinar em curvas ou girar parado:** `get_turn_rate()`. É velocidade, não ângulo: aparece enquanto o modelo
  gira, oscila entre ticks e volta a 0 ao terminar. Suavize antes de usar.
- **Queda curta ou longa:** `get_air_time()`. Ignore a animação de queda se passou só um instante no ar ou
  intensifique a aterrissagem após uma queda longa.
- **`touched_floor` ou `landed`:** `touched_floor` encerra qualquer tempo no ar, para voltar à animação de chão;
  `landed` indica aterrissagem real para tremer a câmera, tocar som ou agachar.
- **Pegadas, poeira, som do pé direito:** `get_step_foot()` no manipulador de `stepped`.
- **Som de escada ou animação de subida:** `stair_taken(height)`. Não é para suavização: o corpo já está no degrau.
- **Pés sobre escadas, modelo sobre o chão:** `get_ground_height()`.

**Sem contagem de passos** (`is_counting_steps()` falso), não há `stepped`; `get_step_phase()`, `get_gait_cycle()`
e `get_step_foot()` mantêm os últimos valores, então animações das pernas não devem segui-los nesse período. O
personagem continua correndo, pulando e subindo degraus normalmente.

`HandSway` segue a fase dos passos; uma animação pode fazer o mesmo. O jeito usual de controlar um `AnimationTree` é
definir as misturas dele a partir das consultas a cada quadro e trocar a máquina de estados pelos sinais:

```gdscript
@export var character: GroundCharacter
@export var tree: AnimationTree


func _ready() -> void:
	character.state_changed.connect(_on_state_changed)
	character.landed.connect(func(_speed: float) -> void:
		tree.set("parameters/land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE))


func _process(_delta: float) -> void:
	# A BlendSpace1D with idle at 0, run at 1 and sprint at 2; for sidesteps, a BlendSpace2D and get_local_movement().
	tree.set("parameters/ground/blend_position", character.get_locomotion_blend())


func _on_state_changed(state: GroundCharacter.State, _previous: GroundCharacter.State) -> void:
	var in_air := state == GroundCharacter.State.JUMPING or state == GroundCharacter.State.FALLING
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	playback.travel("air" if in_air else "ground")
```

Para manter os pés em sincronia com o chão, toque o ciclo da corrida pela distância, e não pelo tempo: defina a posição
dele como `get_gait_cycle()` vezes a sua duração (um nó `TimeSeek`, ou um `AnimationPlayer` pausado com `seek()`). O
ciclo deve começar com o pé esquerdo tocando o chão.

### CharacterMonitor: o estado como texto

Um `Label` que mostra o que um `GroundCharacter` está fazendo e os últimos eventos dele, para ajustar animações ou como
sobreposição de depuração. Na demo ele é `Hud/CharacterState/Monitor`, mostrado por Configurações (F10) → Interface →
**Estado do personagem e eventos**. O texto vem só dos sinais e das consultas acima, então o script também é um exemplo
de como usá-los.

```
Running
Speed 5.5 m/s · blend 1.00
Forward +1.00 · right +0.00
Turning +0°/s
On the ground · slope 0°
Step 38 · left foot · cycle 0.03
Stamina 100%

11.83 s  Jumping → Falling
12.08 s  touched the ground at 7.8 m/s
12.08 s  landing at 7.8 m/s
12.08 s  Falling → Running
12.35 s  step, right foot
12.62 s  step, left foot
```

Linha por linha:

1. Estado retornado por `get_state()`.
2. Velocidade real (`get_move_speed()`) e valor de mistura.
3. Movimento nos eixos do modelo, com sinal: à frente +1.00 é corrida plena, −0.70 é recuo; direita −1.00 é
   passo lateral à esquerda.
4. Velocidade de giro do modelo em graus por segundo, positiva à esquerda. Não é ângulo: aparece durante o giro
   e volta a 0 ao terminá-lo.
5. No chão, com inclinação sob os pés; no ar, com tempo e velocidade vertical.
6. Número de passos, último pé e ciclo da passada; “Sem passos” enquanto não são contados.
7. Fôlego e “exausto” quando não pode correr rapidamente.

Abaixo vêm os eventos recentes, dos mais antigos para os novos, com o tempo desde o início: passos e pé,
degraus e altura, pulos, saída do chão, aterrissagens e velocidade da queda, corrida rápida e mudanças de estado.
Visível, o painel reconstrói o texto a cada quadro; oculto, deixa de fazê-lo, mas ainda registra os eventos
(e os imprime se `log_events` estiver ligado).

| Propriedade | Padrão | Significado |
|---|---|---|
| `character` | — | O `GroundCharacter`; se vazio, o pai |
| `history_size` | 6 | Quantos dos últimos eventos mostrar sob o estado; 0 mostra só o estado |
| `log_events` | desligado | Também imprimir cada evento na saída, com o seu tempo e o nome do personagem |
| `include_steps` | ligado | Mostrar e registrar passos e degraus: são vários por segundo |

Métodos: `get_text_now()`, `get_state_lines()`, `get_event_lines()`, `get_state_name(state, translated)`. As frases
passam por `tr()`, então o painel fala o idioma da interface; o log na saída fica em inglês.

### Degraus e encostas

**As encostas** são trabalho do próprio `move_and_slide()`: o corpo sobe andando uma superfície não mais íngreme que
`floor_max_angle` e para numa mais íngreme. Com `floor_constant_speed`, que o corpo da demo tem ligado, ele mantém a
velocidade numa rampa.

**Os degraus.** Sozinha, uma cápsula sobe numa borda só até `radius × (1 − cos floor_max_angle)`, 0,1 m para a cápsula
de 0,35 m. Degraus mais altos, até `max_step_height`, o corpo sobe por conta própria:

- **Subida.** Se o movimento do tick, visto 5 cm mais longe, bate em algo íngreme demais para ficar de pé, o corpo tenta
  um degrau: sobe `max_step_height` (ou o quanto um teto deixar), avança o movimento do tick, desce até o chão. Um raio
  verifica o topo: ele deve ser chão a no máximo `max_step_height` acima dos pés, então um bloco de 0,4 m ou uma encosta
  íngreme não é um degrau. O corpo é colocado no degrau, e `move_and_slide()` só o acomoda ali.
- **Descida.** Se o corpo estava no chão antes do tick e está no ar depois dele sem um pulo, e há chão a no máximo
  `max_step_height` abaixo dele, o corpo é colocado nesse chão: sem `left_floor`, sem queda.
- Cada degrau vencido pelo corpo é informado por `stair_taken(height)`: altura real entre o chão anterior e o
  novo, +0.2 m em cada degrau de subida da demo, −0.2 m na descida.
- A base redonda da cápsula se apoia na quina de um degrau num ângulo íngreme demais para ficar de pé enquanto o corpo
  está longe da quina. Por isso o lugar no degrau é procurado um pouco mais longe, em incrementos de 2 cm: o corpo
  termina até alguns centímetros além de onde o tick o levaria.

Cada degrau custa cerca de um tick rolando sobre a quina, em que a velocidade horizontal cai para cerca de 70%
(`get_move_speed()` mostra isso; o cajado não percebe, pois `HandSway` usa `get_local_acceleration()`). Para uma
escada longa, um colisor de rampa
invisível é o mais suave.

O corpo sobe um degrau imediatamente: num degrau de 0.2 m, sobe cerca de 0.1 m em um tick e o restante nos dois
ou três seguintes enquanto a cápsula passa pela borda. A interpolação física distribui a mudança pelos quadros,
mas ainda há um pequeno tranco na tela. O modelo flutuante desliza sobre degraus (`CharacterHover`), e
`height_follow_time` da câmera suaviza a subida da visão (0.15 s na demo; veja [Câmera](camera.md#propriedades)).

A malha de navegação precisa ligar o que o corpo consegue subir: na demo, `agent_max_climb` é 0,3 m, o mesmo que
`max_step_height` (veja [Mundo e navegação](world-and-navigation.md#camadas-de-física-e-navegação)).

### O pulo

A velocidade de impulso é `v = √(2·g·h)`. No tick do impulso, o corpo recebe `v − g·dt/2` e nenhuma outra gravidade,
inclusive no tempo de tolerância após sair da borda: assim suas posições em cada
tick ficam exatamente sobre a parábola, e a altura do pulo não depende da taxa de ticks. Com `v` puro, o pulo seria
`v·dt/2` mais alto, 1,064 m em vez de 1 m a 60 ticks. Na demo, um pulo de 1 m leva 0,52 s com `gravity_scale` 3.

No ar, o personagem continua correndo como estava, e os controles continuam os mesmos. A proteção de bordas não segura
um pulo: pular da borda de uma plataforma é um passo deliberado, não um acidente.

### A queda

A descida após o topo de um pulo ou depois de sair de uma borda segue um recurso `FallSettings`: o `fall` do
personagem ou outro atribuído temporariamente por um componente. A subida do pulo não muda: perde velocidade com
`gravity_scale`, mantendo a altura `jump_height` independentemente da queda. Sem ajustes de queda, a gravidade do
lugar multiplicada por `gravity_scale` age como antes em qualquer direção, sem limite. Com eles, a componente da
gravidade paralela ao chão (de uma área) continua agindo; se não houver componente para baixo (corrente
ascendente), os ajustes não têm queda para moldar.

| Propriedade | Padrão | Significado |
|---|---|---|
| `gravity_scale` | 0 | Multiplicador da gravidade na descida: controla o ganho de velocidade. Menor que o do personagem, a descida é mais lenta que a subida. 0 usa `gravity_scale` do personagem: recurso novo não muda nada, e um limite isolado mantém a gravidade anterior |
| `max_speed` | 0 m/s | Velocidade máxima da queda: acelera até ela e continua. 0 remove o limite |
| `braking_time` | 0.3 s | Tempo para reduzir a 95% o excesso acima de `max_speed`: após ser lançado para baixo ou quando os ajustes mudam no meio da queda. 0 é imediato |

Um componente pode substituir `fall` temporariamente com `set_fall_override(self, settings, priority)` e usar
`null` para devolver o controle. Entre vários componentes, vence a prioridade maior (0 por padrão) e, em empate,
o que substituiu a queda mais recentemente; apenas mudar os ajustes ou a prioridade não altera sua ordem.
`fall` não é modificado, então os ajustes do jogo voltam quando os componentes liberam o controle. O personagem
não mantém o componente vivo: ao liberá-lo, a substituição termina. `get_fall_settings()` retorna a queda em
vigor. `CharacterHover` atribui seu próprio `fall` com prioridade 0 a cada início da flutuação (veja
[Personagens](characters.md#a-queda)); uma queda do jogo com prioridade 1, por exemplo um feitiço de queda lenta,
prevalece mesmo com a flutuação ligada.

`touched_floor` e `landed` informam a velocidade no contato com o chão. Uma queda limitada abaixo de
`landing_min_speed` produz só `touched_floor`; `landed` só ocorre se o personagem foi lançado mais rápido e tocou
o chão antes de frear. No `fall` próprio do personagem, isso gera aviso de configuração: som e efeitos de
aterrissagem nunca ocorreriam após um pulo. Para um personagem flutuante, esse toque suave é intencional. Um
limite exatamente igual a `landing_min_speed` gera aterrissagem.

O herói da demo não tem `fall` próprio. Seu nó de flutuação usa
`gdscript/player/player_floating_fall.tres`: escala da gravidade 0.5 em vez dos 3 do corpo e limite de 2 m/s na
descida. Assim, após um pulo de 1 m, fica 0.95 s no ar, não 0.52 s, e toca o chão a 2 m/s, não a 7.8 m/s.
`FallSettings.get_next_speed(speed, acceleration, delta)` e `get_gravity_scale(own)` implementam esse passo
para um corpo criado por você.

## Corrida rápida e fôlego

Enquanto a corrida rápida é pedida e o personagem está sendo conduzido (um clique, um botão segurado, os dois botões,
teclas), ele corre `sprint_speed_multiplier` vezes mais rápido e gasta fôlego. Ficar parado com o Shift segurado não
gasta nada. Quando a reserva acaba, o personagem fica exausto: corre na velocidade normal até o fôlego se recuperar a
`recover_ratio`, e então volta à corrida rápida sozinho se o Shift ainda estiver segurado.

`Stamina` não sabe nada sobre o que a gasta:

| Propriedade | Padrão | Significado |
|---|---|---|
| `max_value` | 100 | Reserva cheia |
| `recovery_rate` | 12,5 por segundo | De vazia a cheia em 8 s |
| `recovery_delay` | 1 s | A recuperação começa esse tempo depois do último gasto |
| `recover_ratio` | 0,3 | Um personagem exausto volta à corrida rápida depois de recuperar essa fração (1 + 2,4 s) |

Métodos: `spend(amount)`, `can_spend()`, `get_ratio()`, `is_exhausted()`, `refill()`. Sinais: `changed(ratio)`,
`exhausted_changed(exhausted)`. O `StaminaBar` do HUD os escuta.

## LedgeGuard

Impede o personagem de sair andando de um desnível. O corpo chama `constrain(velocity, delta)` antes de
`move_and_slide()`. Se o corpo fosse terminar o tick sobre um desnível, o movimento é virado ao longo da borda para a
direção mais próxima com chão embaixo e encurtado pelo cosseno do giro, exatamente como deslizar ao longo de uma
parede. Correr direto para a borda para o personagem.

| Propriedade | Padrão | Significado |
|---|---|---|
| `enabled` | ligado | Proteger as bordas |
| `max_drop` | 0.5 m | Protege contra quedas maiores; as menores podem ser atravessadas. Só as que não excedem `GroundCharacter.max_step_height` são descidas como degraus sem cair |
| `edge_margin` | 0,15 m | O quanto o centro do personagem pode chegar perto da borda |
| `margin_probes` | 6 | Raios em volta do círculo de `edge_margin` |
| `probe_height` | 0,5 m | Os raios começam a essa altura acima dos pés, para achar chão um pouco acima deles (uma rampa) |
| `floor_mask` | 0 | O que conta como chão; 0 usa a máscara de colisão do corpo, contando apenas superfícies em que ele poderia pisar |
| `slide_iterations` | 6 | Divisões pela metade do ângulo de deslize; 6 dá cerca de 1,4° |

Em terreno aberto, são 7 raios por tick, até 98 numa borda. No ar, a proteção não faz nada. Um caminho descendo
da plataforma segue a rampa sem interferência. Chão significa superfície em que o corpo pode ficar de pé: não
mais inclinada que `floor_max_angle`, com a pequena margem da verificação do motor
(`GroundCharacter.FLOOR_ANGLE_MARGIN`). Um `floor_mask` com camadas com que o corpo não colide gera aviso de
configuração: a proteção trataria como chão algo que o corpo atravessa.

## Comportamento medido

Os testes de cena em `tests/movement_checks.gd`, `tests/character_actions_checks.gd` e
`tests/character_state_checks.gd` exercitam o herói fornecido a 60 ticks de física:

- Com corrida padrão de 5.5 m/s e aceleração de 0.18 s, chega a 95% da velocidade em 0.18 s; a parada normal
  desde 95% leva cerca de 0.20 s. Um novo destino durante a frenagem preserva velocidade, e clicar para trás
  produz uma curva.
- A corrida rápida chega a 8.25 m/s. Nos testes, uma reserva que dura 2 s se esgota, recupera-se até o limite
  e retoma a corrida rápida se o pedido continuar ativo.
- O pulo de 1 m alcança 1.000 m e dura cerca de 0.52 s no ar. Um botão pressionado pouco antes da aterrissagem
  dispara o pulo; pressionado logo após sair da borda funciona dentro do tempo de tolerância.
- Os degraus de 0.2 m da demo são atravessados nos dois sentidos sem sair do chão; `stair_taken` informa cada um.
  Um bloco de 0.4 m e uma encosta de 50° param o corpo. A proteção detém corrida sobre a borda da plataforma e
  faz uma corrida em ângulo deslizar ao longo dela.
- Com gravidade de queda 0.5 e limite 2 m/s da flutuação, o pulo mantém altura 1 m, mas o contato com o chão é
  a 2 m/s, abaixo do limite padrão de 2.5 m/s para o sinal de aterrissagem. Os resultados dependem da cápsula,
  colisores, malha
  e ajustes fornecidos; teste geometria e valores alterados no seu nível.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
