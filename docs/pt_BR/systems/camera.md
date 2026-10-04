<!-- translation of docs/en/systems/camera.md @ 1850159bc3c5 -->
# Câmera

> Esta é uma tradução do [original em inglês](../../en/systems/camera.md).
> Onde houver diferenças, a versão em inglês é a correta.

Dois nós: `OrbitCameraRig` segue um alvo, orbita e dá zoom; seu filho `CameraArm` segura o `Camera3D` na ponta de um
braço e encurta o braço em obstáculos.

```
CameraRig (OrbitCameraRig)     colocado no alvo, girado pela guinada e pela inclinação
└── CameraArm (CameraArm)      braço ao longo do +Z local; o rig define o comprimento dele pelo zoom
    └── Camera3D               na ponta do braço, olhando de volta ao longo dele
```

O rig é irmão do alvo, não filho dele. Ele se move em `_process` para a posição interpolada do alvo, e a sua própria
interpolação de física fica desligada: senão ele suavizaria uma posição já suavizada e ficaria um tick atrasado. Com a
interpolação de física ligada no projeto, a câmera e o personagem se movem suavemente em qualquer taxa de quadros.

## OrbitCameraRig

- **Órbita.** Segure o botão direito (`camera_rotate`) e mova o mouse. O cursor fica capturado enquanto você orbita e
  volta para onde estava quando você solta o botão. Se a janela perde o foco ou o jogo pausa no meio da órbita, o
  próprio rig libera o cursor.
- **Inclinação com o mouse** (`mouse_pitch`, desligado por padrão). O movimento vertical do mouse com o botão direito
  também inclina a câmera. Desligado, a inclinação vem só do zoom.
- **Zoom.** A roda move a câmera para baixo e para mais perto, ou para cima e para mais longe. Distância e inclinação
  mudam juntas.
- **Seguir** (`follow_movement`, `follow_pitch`, ambos desligados por padrão). A câmera vira aos poucos para trás do
  alvo em corrida e leva suavemente a inclinação a `follow_pitch_angle`.

### A curva de zoom

O zoom é um valor de 0 (mais perto) a 1 (mais longe); cada passo da roda o muda em `zoom_step` (0,1). A distância vai
de `near_distance` (5 m) a `far_distance` (20 m). A inclinação vai de `near_pitch` (−22°) a `far_pitch` (−55°), mas não
de forma uniforme: do topo até `flatten_start_zoom` (0,5; 12,5 m; −38,5°) ela muda uniformemente, e abaixo disso a
câmera se nivela rapidamente, para que o que está à frente do personagem já fique visível numa altura média. A partir
de `flatten_end_zoom` (0,2; 8 m), a câmera olha a −22° e só se aproxima.

A demo começa em `start_zoom` 0,55. Um passo da roda para baixo a partir daí: −33,5°; dois: −26°; três (8,75 m):
−22,5°.

A inclinação é a inclinação do zoom mais um deslocamento. O mouse (com `mouse_pitch`) e o modo de seguir mudam o
deslocamento, então a roda e o mouse funcionam como sempre e, na corrida, a inclinação volta suavemente ao ângulo
escolhido. Desligar `mouse_pitch` zera o deslocamento. A inclinação nunca passa de `min_pitch` (−80°) e `max_pitch`
(−8°).

### Modo de seguir

| Propriedade | Padrão | Significado |
|---|---|---|
| `follow_movement` | desligado | Virar a câmera para trás do alvo em corrida |
| `follow_pitch` | desligado | Levar suavemente a inclinação a `follow_pitch_angle` na corrida, na mesma taxa e nos mesmos casos que o giro; funciona sem `follow_movement` |
| `follow_pitch_angle` | −40° | Inclinação alvo (para baixo é negativo), limitada por `min_pitch` e `max_pitch` |
| `follow_time` | 1,5 s | Tempo para virar quase todo o caminho (resta 5% do ângulo); 0 é imediato |
| `follow_min_speed` | 1 m/s | Abaixo dessa velocidade a câmera não vira: parado ou girando no lugar, a direção não é confiável. Entre essa velocidade e o dobro dela, o giro ganha força suavemente |

As configurações da demo usam padrões diferentes: tempo para alcançar de 1,1 s e inclinação de 22° para baixo.

A câmera não segue:

- enquanto o botão direito está segurado: o mouse controla a câmera, inclusive ao correr com os dois botões;
- nos primeiros 0,2 s depois de pressionar o botão esquerdo, até ficar claro se é um clique ou se o botão está sendo
  segurado. A pausa vem de `PointClickMoveInput.hold_pending_changed`, conectado em `main.tscn` a
  `CameraRig.set_follow_paused()`.

A velocidade do alvo é medida pelo rig a partir do movimento do alvo por tick de física, então qualquer `Node3D` pode
ser o alvo.

Quando a câmera gira com o botão esquerdo segurado, o cursor apontaria para outro ponto do chão e o personagem viraria
atrás dele, e a câmera atrás do personagem: o personagem correria em círculos. Por isso, enquanto o botão está
segurado, a entrada move o cursor do sistema junto com o mundo. Veja
[Entrada](input.md#o-cursor-com-o-botão-segurado).

### Propriedades

| Grupo | Propriedade | Padrão | Significado |
|---|---|---|---|
| | `target` | — | O que seguir |
| | `arm` | — | O `CameraArm`; se vazio, o primeiro filho `CameraArm` |
| | `camera` | — | Usada sem braço; se vazia, o primeiro filho `Camera3D` |
| Input | `rotate_action`, `zoom_in_action`, `zoom_out_action` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` | Ações de entrada |
| | `mouse_sensitivity` | 0,25 °/px | Velocidade da órbita |
| | `mouse_pitch` | desligado | O movimento vertical do mouse inclina a câmera |
| | `invert_pitch` | desligado | Inverter essa inclinação |
| | `zoom_step` | 0,1 | Mudança do zoom por passo da roda |
| Framing | `focus_height` | 1,2 m | Altura acima da origem do alvo para onde a câmera olha |
| | `near_distance`, `far_distance` | 5 m, 20 m | Comprimento do braço no zoom mais perto e no mais longe |
| | `near_pitch`, `far_pitch` | −22°, −55° | Inclinação no zoom mais perto e no mais longe |
| | `flatten_start_zoom`, `flatten_end_zoom` | 0,5; 0,2 | Onde a inclinação começa a se nivelar mais rápido, e onde ela fica nivelada |
| | `min_pitch`, `max_pitch` | −80°, −8° | Limites da inclinação |
| | `start_zoom`, `start_yaw` | 0,55; 45° | Zoom e direção iniciais |
| Follow | veja acima | | |
| Smoothing | `rotation_sharpness`, `zoom_sharpness` | 30, 10 | A rapidez com que a câmera chega à guinada, à inclinação e ao zoom desejados |

Métodos: `look_along(direction)` vira a câmera para olhar ao longo de uma direção na hora; `snap()` salta para a
posição desejada, por exemplo depois de teleportar o alvo; `is_rotating()`; `set_follow_paused(paused)`.

## CameraArm

A roda define o comprimento do braço; o braço encurta em obstáculos e volta a esse comprimento quando há espaço.

- **Parar no que está atrás** (`keep_out_of_geometry`, ligado por padrão). Uma montanha, uma parede ou um telhado atrás
  da câmera: a câmera não entra, mas se move em direção ao alvo. Ande em direção à montanha e a câmera se aproxima do
  alvo sem entrar na encosta; afaste-se, e ela volta assim que houver espaço atrás dela. O braço só encurta se a câmera
  não puder ficar na ponta dele. Uma coluna ou uma cerca entre a câmera e o alvo, com espaço atrás, não move a câmera: o
  personagem aparece através dela como silhueta. Se a câmera fosse ficar colada atrás desse obstáculo, mais perto que
  `probe_radius`, não há espaço para ela ali, e ela vai para a frente do obstáculo.
- **Aproximar quando o alvo está encoberto** (`pull_in_on_occlusion`, desligado por padrão). Uma cerca ou uma parede
  esconde o alvo quase por inteiro: a câmera vai suavemente para a frente do obstáculo, mas nunca mais perto que
  `min_pull_in_length` (2,5 m) do alvo. Se o personagem está colado na parede, a câmera fica onde está em vez de saltar
  para as costas do personagem.
- **Esmaecer de perto.** Quando o braço está muito curto, `fade_target` fica translúcido.

| Propriedade | Padrão | Significado |
|---|---|---|
| `length` | 10 m | Comprimento do braço; definido pelo rig a partir do zoom |
| `camera` | — | A câmera; se vazia, o primeiro filho `Camera3D` |
| `keep_out_of_geometry` | ligado | Parar em corpos atrás da câmera |
| `probe_radius` | 0,3 m | A câmera é uma esfera com esse raio e se mantém a essa distância das paredes |
| `collision_mask` | camadas 1 e 3 | Corpos que param o braço: `world` e `camera`. Personagens (camada 2) não |
| `ignored_groups` | `camera_ignore` | Corpos nesses grupos, ou sob um nó deles, não param o braço |
| `pull_in_on_occlusion` | desligado | Aproximar quando o alvo está encoberto |
| `min_pull_in_length` | 2,5 m | A câmera não se aproxima mais que isso por causa de um alvo encoberto; com menos espaço na frente do obstáculo, ela fica onde está |
| `pull_in_sharpness` | 10 | A rapidez com que a câmera vai para a frente de um obstáculo que esconde o alvo (0 é imediato). Ela sempre para na hora num corpo atrás |
| `occlusion_points` | peito, cabeça, joelhos, lados | Pontos do alvo verificados quanto à visibilidade, relativos ao início do braço: direita, cima, em direção à câmera |
| `occlusion_share` | 0,75 | O alvo está encoberto quando essa fração dos pontos está encoberta. Um poste fino ou um tronco esconde três de cinco e não conta |
| `occlusion_delay` | 0,25 s | Quanto tempo o alvo precisa ficar encoberto para a câmera se aproximar, e visível para ela voltar |
| `return_delay`, `return_sharpness` | 0,3 s; 4 | O braço encurta na hora, mas volta a crescer depois de uma pausa e suavemente, para que a câmera não trema entre colunas. Um corpo no caminho de volta é pulado, não atravessado |
| `fade_target` | — | O que fica translúcido de perto (`Player/Visual` na demo) |
| `fade_start_length`, `fade_end_length`, `fade_transparency` | 1,5 m; 0,7 m; 0,75 | O alvo começa a esmaecer no primeiro comprimento e fica 75% transparente no segundo |
| `debug_draw` | desligado | Desenhar o braço (cinza: o comprimento da roda; verde: o atual), a esfera da câmera e os raios até os pontos do alvo (vermelho: encoberto). Visível de outra câmera |

Métodos: `snap()`, `get_current_length()`, `is_pulled_in_by_occlusion()`.

### Corpos só para a câmera

Coloque-os na camada de física 3 (`camera`). Personagens não colidem com eles, e cliques e navegação não os enxergam. O
telhado da casa (`RoofCameraBlocker` em `shared/world/props/house.tscn`) tem um corpo assim: a câmera para no telhado,
mas ninguém consegue subir nele ou traçar caminho por ele.

### O grupo `camera_ignore`

O grupo também vale para tudo sob um nó que está nele. Defina-o uma vez na raiz da cena de um prop, para que toda
instância no nível o tenha, ou num nó de pasta do nível. A demo não precisa dele: os troncos das árvores (até 2,4 m)
ficam abaixo da câmera mesmo no zoom mais perto (3 m acima do chão).

### Como o braço distingue espaço atrás de um obstáculo de estar dentro de um corpo

Primeiro, o braço verifica se a câmera pode ficar na ponta dele: a esfera não toca nada ali, nem o obstáculo à frente da
câmera, e a ponta não está dentro de um corpo. Um raio da câmera até o alvo não enxerga as faces de um corpo dentro do
qual ele começa, então ele encontra a face mais distante do obstáculo à frente da câmera. Um raio dessa face até a ponta
do braço entra no corpo em que a câmera está e nunca sai dele. Se algo está no caminho, a esfera é lançada dessa face em
direção à câmera e para na frente do corpo que está no caminho, passando pelos outros. Uma coluna que o braço apenas
roça não move a câmera.

O Jolt não reporta corpos que a esfera toca no início de um lançamento (cast), nem um corpo de malha (como a montanha)
dentro do qual o lançamento começa. Então, se outro corpo está logo atrás da face (uma cerca com um penhasco atrás), ou
o lançamento começaria dentro de outro corpo (duas lâminas de rocha bem próximas, com o braço quase ao longo delas), o
espaço livre é procurado mais perto do alvo.

O caminho de volta também é verificado. Enquanto o braço espera para voltar a crescer, ele pode girar, e no comprimento
que ele mantém a câmera pode acabar dentro de uma parede: então a câmera vai na hora para o comprimento livre. Se há um
corpo entre a câmera e o lugar para onde ela volta (a câmera estava na frente de uma cerca, e agora há espaço atrás
dela), depois da pausa a câmera pula por cima do corpo em vez de atravessá-lo.

## Comportamento medido

De `tests/camera_checks.gd` e `tests/camera_arm_checks.gd`:

- Seguir com a corrida a 90° da câmera: `follow_time` 0 vira 95% em 0,17 s, o 1,1 da demo em 1,23 s; com 10, virou só
  39° de 90° depois de 2 s. Parado, não vira. Com o botão direito segurado, não vira e continua depois de soltar.
- Segurando o botão esquerdo com o seguir ligado (1,1 s): nos primeiros 0,2 s a câmera fica parada (um clique curto
  não a move), depois em 1,25 s ela vira 27,1° dos 28,3° para trás da corrida, enquanto a direção da corrida muda
  0,01°; com "imediato", também. Mover o mouse 150 px vira a corrida em 25°, e a nova direção se mantém. Com
  `keep_aim_on_camera_turn` desligado, o personagem se curva 77,6° em 1,25 s.
- Alinhamento da inclinação: uma câmera abaixada pela roda (22,5° para baixo) vai suavemente a 55° com `follow_time`
  0,5, 95% do caminho em cerca de 0,65 s, sem virar atrás da corrida se o giro estiver desligado. 89° é limitado ao
  limite de 80° da câmera. Segurando o botão esquerdo com o seguir e uma inclinação de 20°: a inclinação vai de 80° a
  22,5° em 1,25 s, a caminho de 20°, e a direção da corrida muda 0,01°.
- O braço: comprimento total em área aberta; um penhasco atrás o para na hora; andando em direção ao penhasco, a câmera
  se aproxima e fica fora dele; sem o penhasco, o braço volta depois de uma pausa, suavemente. Uma cerca com um penhasco
  logo atrás: a câmera para na frente da cerca. Uma cerca colada às costas da câmera: a câmera vai para a frente dela.
  Uma cerca que aparece onde a câmera espera para voltar: a câmera vai para trás dela na hora. Uma cerca no meio do
  caminho entre a câmera e o personagem: por padrão a câmera fica atrás dela; com a aproximação, vai suavemente para a
  frente dela, e uma oclusão curta não conta. Uma cerca colada ao personagem: a câmera não salta para as costas do
  personagem. Um poste fino não conta, uma coluna que roça o braço não move a câmera, corpos em `camera_ignore` não a
  param, e de perto o personagem fica translúcido. No nível, junto às sebes do labirinto, à encosta da montanha e suas
  lâminas de rocha, a uma barraca e às pedras do cume, a câmera não entra neles.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
