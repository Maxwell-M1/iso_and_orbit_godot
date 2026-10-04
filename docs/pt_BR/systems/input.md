<!-- translation of docs/en/systems/input.md @ 6012ceb531ff -->
# Entrada

> Esta é uma tradução do [original em inglês](../../en/systems/input.md).
> Onde houver diferenças, a versão em inglês é a correta.

Dois nós transformam a entrada do jogador em comandos. Nenhum deles move nada por conta própria.

- `PointClickMoveInput`: o mouse, e WASD com o botão direito segurado → `NavigationMover.move_to()`, `steer()` e
  `stop()`.
- `CharacterActionInput`: teclas de corrida rápida e pulo → `GroundCharacter.sprint_requested` e `jump()`.

Os dois ficam em `main.tscn`, não na cena do personagem, então o mesmo personagem pode ser controlado por uma IA em vez
disso. Para os controles do ponto de vista do jogador, veja [Controles](../controls.md).

## PointClickMoveInput

| Entrada | Comando |
|---|---|
| Clique no chão | `move_to(point)`: um raio da câmera em `ground_mask` encontra o ponto |
| Botão esquerdo segurado | `steer()` em direção ao cursor, ou `move_to()` até o ponto sob ele, dependendo de `hold_mode` |
| Botões esquerdo e direito segurados | `steer()` para onde a câmera olha; A e D desviam na diagonal para a frente (`keys_with_camera_steer`) |
| Botão direito e WASD | `steer()` em relação à câmera, de lado ou virando (`keys_with_camera`); `stop()` ao soltar |

Quem controla o personagem num tick é decidido num só lugar, `_physics_process`: primeiro um botão esquerdo segurado,
senão as teclas com o botão direito. Então soltar o botão esquerdo enquanto o botão direito e W estão segurados não
para o personagem: as teclas assumem na hora.

### Clicar ou segurar

Um pressionamento passa a contar como segurar depois de `hold_delay` (0,2 s). Até lá, o personagem continua fazendo o
que estava fazendo (parado, ou correndo para onde corria), e não há marcador nem caminho até o ponto pressionado.

- **Soltou antes: um clique.** O personagem corre por um caminho até o ponto onde o botão foi pressionado. O ponto é
  tomado no momento do pressionamento, mesmo que o mouse tenha se movido depois. O marcador aparece
  (`destination_picked`). Ele some quando o personagem chega ou quando a corrida é abandonada em favor das teclas ou de
  segurar o botão.
- **Segurou por mais tempo: segurar.** O personagem corre atrás do cursor na hora (`hold_started`) e não se vira antes
  para o ponto pressionado. Caso contrário, ele começaria pelo caminho até esse ponto, e um caminho contornando
  obstáculos pode levar a um lugar totalmente diferente do cursor.

O custo é que um clique age ao soltar, cerca de 0,1 s mais tarde do que ao pressionar. Enquanto não está claro se o
botão foi clicado ou está sendo segurado, `hold_pending_changed(true)` pausa o modo de seguir da câmera, então um
clique curto nunca move a câmera.

Se o botão direito já está segurado quando o esquerdo é pressionado, não há clique: o personagem corre seguindo a
câmera na hora.

### Modos de segurar

`hold_mode` (Configurações → Controles → **BEM segurado**):

- `STEER` (padrão): direto em direção ao cursor, sem caminho. O personagem desliza ao longo dos obstáculos e sobe a
  rampa por onde você apontar. Dentro de `steer_dead_zone` (0,5 m) do personagem, a direção não muda: tão perto, ela
  fica sensível demais ao cursor. Ao soltar, o personagem para suavemente.
- `FOLLOW_POINT`: até o ponto sob o cursor por um caminho de navegação. O caminho é reconstruído enquanto o ponto se
  move, então, perto de mudanças de altura (a rampa, a plataforma), ele pode saltar de uma rota para outra. Ao soltar,
  o personagem continua correndo até o último ponto e o marcador o mostra (`destination_picked`); com
  `stop_on_release`, ele freia até parar onde está.

### Teclas com o botão direito

As teclas só funcionam enquanto o botão direito está segurado: a câmera gira com o mouse e o cursor fica capturado.
Sem ele, WASD não fazem nada. Cada modo é `OFF` ou uma de duas variantes, definido separadamente para o botão direito
sozinho (`keys_with_camera`) e para os dois botões (`keys_with_camera_steer`).

| | `SIDESTEP` | `TURN` |
|---|---|---|
| BDM + W | para a frente, para onde a câmera olha | o mesmo |
| BDM + A / D | de lado, olhando para a frente | vira à esquerda / direita e vai para lá |
| BDM + S | para trás, olhando para a frente, mais devagar | dá meia-volta e anda em direção à câmera |
| Duas teclas (W + A, S + D…) | na diagonal, olhando para a frente | na diagonal, olhando para onde vai |
| BEM + BDM + A / D | na diagonal para a frente, olhando para a frente | na diagonal para a frente, olhando para onde vai |

O padrão do script é `SIDESTEP` para ambos; as configurações da demo usam `TURN` para ambos por padrão.

O movimento na diagonal é tão rápido quanto em linha reta. O movimento para trás é mais lento: `NavigationMover` escala
a velocidade conforme o quanto o movimento se opõe à orientação, veja [Locomoção](locomotion.md#navigationmover). A
orientação é passada como segundo argumento de `steer(direction, facing)`: no modo lateral, é a direção para a frente
da câmera. Depois de parar, o personagem continua olhando para onde olhava; um clique ou segurar o botão o faz olhar de
novo para onde corre.

Solte as teclas ou o botão direito e o personagem para suavemente. O botão direito sozinho, sem teclas, não interrompe
uma corrida até um ponto clicado, então você pode girar a câmera durante a corrida. As teclas a interrompem, e o
marcador some. As teclas são as ações `move_forward`, `move_back`, `move_left`, `move_right`, mapeadas pela posição
física.

### O cursor com o botão segurado

**Oculto** (`hide_cursor_while_held`, ligado por padrão). Na corrida, o cursor só ficaria piscando, especialmente
enquanto a câmera gira e o cursor se move com o mundo. Ele some assim que o pressionamento passa a contar como segurar
(um clique curto não mexe nele) e reaparece ao soltar, onde você mirou. Enquanto isso, o modo do mouse é
`MOUSE_MODE_CONFINED_HIDDEN`: um cursor simplesmente oculto poderia sair da janela e aparecer na borda dela. No macOS o
motor confina o cursor movendo-o por conta própria e conta duas vezes cada movimento que mantém a mira (abaixo), então a
mira se desvia; lá o modo é `MOUSE_MODE_HIDDEN`, e o próprio componente mantém o cursor dentro da janela. Enquanto o
botão direito orbita a câmera, a câmera captura o cursor; solte o botão direito com o esquerdo ainda segurado e o cursor
fica oculto de novo. Pausar (a janela de configurações) ou trocar para outra janela o mostra na hora.
`is_cursor_hidden()` informa se o componente o ocultou.

**Mantém a mira** (`keep_aim_on_camera_turn`, ligado por padrão). Enquanto o botão esquerdo está segurado, a direção da
corrida vem do cursor, um ponto na tela. Se a câmera gira enquanto o cursor fica parado na tela, outro ponto do chão
fica sob o cursor, o personagem vira atrás dele, a câmera vira atrás do personagem, e o personagem corre em círculos
(77,6° em 1,25 s com o tempo para alcançar de 1,1 s da demo; com "imediato", ele simplesmente gira). Por isso, enquanto
o botão está segurado, o componente move o cursor do sistema junto com o mundo (`Viewport.warp_mouse()`): o cursor fica
sobre o mesmo ponto do chão, o personagem corre para onde você mirou e a câmera vai suavemente para trás dele. Mover o
mouse vira o personagem como sempre. Depois de soltar, o cursor é deixado em paz.

Desligado, o cursor guia como ao dirigir um carro: segure-o à direita do personagem e o personagem vira para a direita
até o cursor ficar bem à frente. Onde o sistema não consegue mover o cursor (Wayland, por exemplo), a direção da
corrida se mantém, mas o cursor fica parado.

O cursor é corrigido em `_process` depois que a câmera se acomodou no quadro: o `process_priority` do componente é 1,
o da câmera é 0. A entrada lê o `Camera3D` diretamente e não sabe nada sobre o rig da câmera.

### Propriedades

| Propriedade | Padrão | Significado |
|---|---|---|
| `mover` | — | O `NavigationMover` a comandar; obrigatório |
| `camera` | — | Câmera para raios e direções; se vazia, a câmera atual da viewport |
| `move_action` | `move_to_cursor` | Clicar e segurar |
| `hold_mode` | `STEER` | Veja acima |
| `keep_aim_on_camera_turn` | ligado | Veja acima |
| `hide_cursor_while_held` | ligado | Veja acima |
| `camera_steer_action` | `camera_rotate` | Com ela segurada, segurar o botão corre para onde a câmera olha; vazia desativa |
| `ground_mask` | camada 1 | Camadas de física em que se pode clicar. Não deve incluir a camada dos personagens |
| `hold_delay` | 0,2 s | Quando um pressionamento passa a contar como segurar |
| `steer_dead_zone` | 0,5 m | `STEER`: sem mudança de direção com o cursor tão perto do personagem |
| `stop_on_release` | desligado | `FOLLOW_POINT`: frear até parar ao soltar, em vez de continuar até o último ponto |
| `ray_length` | 1000 m | Comprimento do raio a partir da câmera |
| `keys_with_camera` | `SIDESTEP` | Modo de BDM + WASD |
| `keys_with_camera_steer` | `SIDESTEP` | Modo de BEM + BDM + A/D |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | As teclas |

Sinais: `destination_picked(point)`, `hold_started`, `hold_pending_changed(pending)`.

O componente verifica na inicialização se suas ações de entrada existem e reporta uma ausente como erro.

## CharacterActionInput

| Propriedade | Padrão | Significado |
|---|---|---|
| `character` | — | O `GroundCharacter` a comandar |
| `sprint_action` | `sprint` | Shift |
| `jump_action` | `jump` | Espaço |
| `sprint_mode` | `HOLD` | `HOLD`: corrida rápida enquanto a tecla está segurada. `TOGGLE`: um toque liga a corrida rápida, o próximo a desliga; ela também desliga sozinha quando o personagem fica exausto e não volta depois do descanso |

O componente só repassa a entrada; o personagem decide se há fôlego para a corrida rápida e se pode pular agora. Ele
roda no tick de física antes do personagem (`process_physics_priority = -1`), então um toque e uma soltura chegam ao
personagem sem um tick extra de atraso. `is_sprint_toggled()` informa o estado de `TOGGLE`.

### O Shift não fica preso

No modo `HOLD`, a corrida rápida é lida a cada tick de `Input.is_action_pressed()`, então soltar o Shift a encerra.
Isso é verificado com eventos reais: na corrida, ao correr com o botão esquerdo segurado, ao soltá-lo na janela de
configurações, depois de trocar de modo.

Mas às vezes a própria soltura nunca chega ao jogo, e a engine considera o Shift segurado até ele ser pressionado de
novo. Isso acontece quando o jogo está embutido na aba Jogo (Game) do editor e o foco passa para o editor
(`Input.release_pressed_events()` pula a redefinição enquanto a janela do editor tem o foco), ou quando um atalho do
sistema engole a soltura. Para esse caso, o componente confere a corrida rápida com o estado real do Shift que todo
evento de mouse e teclado carrega (`shift_pressed`; no Windows, ele vem de `GetKeyboardState`). Se qualquer evento de
mouse ou teclado que não seja a própria tecla de corrida rápida disser que o Shift está solto, o pressionamento preso é
liberado. Isso funciona quando toda tecla mapeada para a ação de corrida rápida é uma modificadora (Shift, Ctrl, Alt,
Meta).

Se o Windows ativar as Teclas de Aderência (Sticky Keys), com cinco toques no Shift seguidos, o Shift fica preso no
próprio sistema; desative isso nas configurações do Windows.

---

*Esta página corresponde ao Iso & Orbit 1.0.0.*
