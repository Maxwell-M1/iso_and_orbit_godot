<!-- translation of docs/en/systems/locomotion.md @ f90a0207f4e9 -->
# Locomoção

> Esta é uma tradução do [original em inglês](../../en/systems/locomotion.md).
> Onde houver diferenças, a versão em inglês é a correta.

Como um personagem corre, para, vira, faz corrida rápida, pula e se mantém longe de desníveis. Quatro classes, de baixo
para cima:

| Classe | Tipo | Função |
|---|---|---|
| `LocomotionSettings` | Resource | Velocidade, aceleração, frenagem, giro |
| `GroundMotion` | RefCounted | A matemática: direção desejada e distância restante → velocidade horizontal |
| `NavigationMover` | Node, filho do corpo | Caminhos e comandos; retorna uma velocidade, nunca move o corpo |
| `GroundCharacter` | CharacterBody3D | Gravidade, pulo, corrida rápida, `move_and_slide()`, giro do modelo |

Dois auxiliares se conectam ao corpo: `Stamina` (a reserva para a corrida rápida) e `LedgeGuard` (nada de sair andando
de desníveis).

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

A demo usa `gdscript/player/player_locomotion.tres`. Ele muda dois dos padrões do script.

| Propriedade | Demo | Padrão do script | Significado |
|---|---|---|---|
| `max_speed` | 5,5 m/s | 5,5 m/s | Velocidade de corrida |
| `acceleration_time` | 0,35 s | 0,18 s | Da parada até `max_speed` |
| `stop_time` | 0,4 s | 0,22 s | De `max_speed` até parar; a distância de frenagem é `max_speed × stop_time / 2` (1,1 m na demo) |
| `turn_speed` | 720 °/s | 720 °/s | A rapidez com que a direção da corrida gira |
| `turn_slowdown` | 0,75 | 0,75 | Velocidade perdida enquanto a direção alcança a desejada: 0 mantém a velocidade (arco largo), 1 freia até zero numa curva de 90° ou mais |
| `pivot_speed` | 1 m/s | 1 m/s | Abaixo disso, o personagem vira instantaneamente |
| `max_braking_multiplier` | 3 | 3 | Quanto mais forte que o normal o personagem pode frear para um ponto logo à frente |
| `sprint_speed_multiplier` | 1,5 | 1,5 | Limite de velocidade na corrida rápida (8,25 m/s); aceleração e frenagem continuam as mesmas |
| `backward_speed_multiplier` | 0,7 | 0,7 | Fração da velocidade que resta ao se mover para trás (olhando contra o movimento) |

A janela de configurações muda `sprint_speed_multiplier` e `backward_speed_multiplier` em tempo de execução. O resto é
ajustado no recurso. Para ajustar com o jogo rodando: painel Cena (Scene) → Remoto (Remote) → `Player/NavigationMover`
→ `settings`. O código os lê a cada tick, mas as mudanças feitas ali não são salvas, então copie o resultado para o
arquivo `.tres`.

Um recurso pode ser compartilhado por vários personagens, por exemplo todos os NPCs de um mesmo tipo.

## NavigationMover

Um filho do corpo (qualquer `Node3D`, geralmente um `CharacterBody3D`). Dois modos:

- `move_to(point)`: até um ponto por um caminho de navegação, contornando obstáculos, com parada exata. O caminho vem
  do `NavigationServer3D` para o mundo do corpo. Sem um mapa de navegação, o personagem corre direto até o ponto.
- `steer(direction, facing = Vector3.ZERO)`: numa direção, sem caminho, até `stop()`, `halt()` ou `move_to()`. Os
  obstáculos são resolvidos pelo corpo deslizando ao longo deles. Com `facing`, o personagem olha nessa direção
  enquanto se move: passo lateral e recuo. A orientação se mantém depois de uma parada, até um comando sem ela.

O corpo chama `compute_velocity(delta)` uma vez por tick de física, antes de `move_and_slide()`.

| Propriedade | Padrão | Significado |
|---|---|---|
| `settings` | — | `LocomotionSettings`; padrões se vazio |
| `use_navigation` | ligado | Buscar um caminho; desligado, ou sem navegação no mundo: correr direto até o ponto |
| `navigation_layers` | 1 | Camadas de navegação que o caminho pode usar |
| `waypoint_radius` | 0,4 m | Um ponto do caminho conta como ultrapassado a menos que isso; maior corta cantos mais cedo |
| `arrive_distance` | 0,005 m | A menos que isso do fim, o personagem para na hora. A própria frenagem o leva até o ponto, então o limiar é minúsculo |
| `retarget_tolerance` | 0,1 m | Um novo ponto a menos que isso do atual não reconstrói o caminho. Um botão segurado envia um ponto a cada tick |
| `max_path_deviation` | 2 m | Empurrado para mais longe que isso do caminho, o personagem recebe um novo caminho |
| `sprinting` | desligado | Multiplicar o limite de velocidade por `sprint_speed_multiplier`. O dono decide quando |

Sinais: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled`.

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
`move_and_slide()`, reporta passos e aterrissagens e vira `visual` para `mover.get_facing()`.

| Propriedade | Padrão | Significado |
|---|---|---|
| `mover` | — | O `NavigationMover`; obrigatório |
| `visual` | — | O nó virado para onde o personagem vai; a frente dele é −Z |
| `visual_turn_speed` | 1080 °/s | A rapidez com que o modelo vira |
| `gravity_scale` | 3 | Multiplicador da gravidade. O personagem corre mais rápido que uma pessoa e flutuaria para baixo com a gravidade normal: uma queda de 1,6 m leva 0,33 s em vez de 0,57 s |
| `ledge_guard` | — | `LedgeGuard` opcional; sem ele, o personagem cai de qualquer altura |
| `can_sprint` | ligado | Corrida rápida permitida. Se desligada durante a corrida, a velocidade extra é freada |
| `stamina` | — | `Stamina` opcional; sem ele, a corrida rápida nunca cansa |
| `sprint_tires` | ligado | A corrida rápida gasta fôlego |
| `sprint_duration` | 5 s | Quanto dura uma reserva cheia: gasta `max_value / sprint_duration` por segundo |
| `can_jump` | ligado | Pulo permitido; desligado, `jump()` não faz nada |
| `jump_height` | 1 m | Altura dos pés no topo do pulo |
| `coyote_time` | 0,1 s | Um pulo ainda funciona por esse tempo depois de sair de uma borda |
| `jump_buffer_time` | 0,12 s | Um pulo pressionado esse tempo antes de aterrissar acontece na aterrissagem |
| `landing_min_speed` | 2,5 m/s | Quedas mais lentas (um degrau para baixo, uma rampa) não contam como aterrissagens |
| `stride_length` | 1,5 m | Distância no chão entre os passos |
| `first_step_distance` | 0,3 m | Distância da parada até o primeiro passo |

Defina `sprint_requested` para pedir a corrida rápida e chame `jump()` para pular. `CharacterActionInput` faz as duas
coisas para o jogador; uma IA pode fazer o mesmo.

### Sinais

| Sinal | Quando |
|---|---|
| `stepped(sprinting)` | Um pé tocou o chão: a cada `stride_length` percorrido no chão, o primeiro a `first_step_distance` da parada. Os passos seguem a distância, não o tempo: cerca de 3,7 por segundo correndo, 5,5 na corrida rápida, nenhum parado contra uma parede ou no ar |
| `jumped` | O personagem tomou impulso do chão |
| `landed(impact_speed)` | O personagem aterrissou; `impact_speed` é a velocidade da queda em m/s |
| `sprint_changed(sprinting)` | A corrida rápida começou ou parou |

`get_step_phase()` retorna o ritmo dos passos como um número de passos dados: um inteiro a cada passo, com a parte
fracionária crescendo de 0 a 1 com a distância entre os passos. `HandSway` o usa; uma animação também pode. Outras
consultas: `is_sprinting()`, `is_exhausted()`, `get_jump_speed()`.

### O pulo

A velocidade de impulso é `v = √(2·g·h)`. No tick do impulso, o corpo recebe `v − g·dt/2`: assim suas posições em cada
tick ficam exatamente sobre a parábola, e a altura do pulo não depende da taxa de ticks. Com `v` puro, o pulo seria
`v·dt/2` mais alto, 1,064 m em vez de 1 m a 60 ticks. Na demo, um pulo de 1 m leva 0,52 s com `gravity_scale` 3.

No ar, o personagem continua correndo como estava, e os controles continuam os mesmos. A proteção de bordas não segura
um pulo: pular da borda de uma plataforma é um passo deliberado, não um acidente.

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
| `max_drop` | 0,5 m | Um desnível menor é um degrau e pode ser descido; um maior é uma borda |
| `edge_margin` | 0,15 m | O quanto o centro do personagem pode chegar perto da borda |
| `margin_probes` | 6 | Raios em volta do círculo de `edge_margin` |
| `probe_height` | 0,5 m | Os raios começam a essa altura acima dos pés, para achar chão um pouco acima deles (uma rampa) |
| `floor_mask` | camada 1 | O que conta como chão |
| `slide_iterations` | 6 | Divisões pela metade do ângulo de deslize; 6 dá cerca de 1,4° |

Em terreno aberto, são 7 raios por tick, até 98 numa borda. No ar, a proteção não faz nada. Um caminho descendo da
plataforma segue a rampa, e a proteção não atrapalha.

## Comportamento medido

Os testes (`tests/movement_checks.gd`, `tests/character_actions_checks.gd`, `tests/camera_checks.gd`) medem as
configurações da demo a 60 ticks de física. Os limites deles são calculados a partir das configurações, então você pode
mudá-las.

- 95% da velocidade máxima em 0,33 s; de 95% até parar em 0,35 s; a parada é exatamente no ponto clicado.
- Um novo clique mais longe durante a frenagem: a partir de 2,66 m/s a velocidade volta a crescer na hora, sem nunca
  cair a zero.
- Um clique atrás do personagem em velocidade máxima: ele segue mais 0,34 m, o arco vai 0,63 m para o lado e, depois
  de 0,28 s, ele corre de volta.
- Direto para a borda da plataforma: parada a 0,15 m da borda com velocidade zero. A 45°: deslize ao longo da borda a
  3,89 m/s (5,5 × cos 45°, como ao longo de uma parede) até o canto da plataforma, na mesma altura. Sem a proteção:
  uma queda de 1,6 m em 0,35 s.
- Corrida rápida: 8,25 m/s. Com `sprint_duration` de 2 s (50 por segundo), o fôlego acaba depois de 2,02 s, então
  5,5 m/s; 3,38 s depois o personagem se recuperou (1 + 2,4 s) e volta à corrida rápida a 8,25 m/s com o Shift ainda
  segurado.
- Pulo: topo a 1,000 m, 0,517 s no ar (0,522 pela fórmula). Pressionado a 0,4 m do chão, o pulo acontece no tick
  depois da aterrissagem; pressionado no topo, é esquecido. Espaço 3 ticks depois de sair de uma borda pula, 9 ticks
  depois não.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
