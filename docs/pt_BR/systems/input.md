<!-- translation of docs/en/systems/input.md @ 286e042594f2 -->
# Entrada

[← Índice da documentação](../index.md)

> Esta é uma tradução do [original em inglês](../../en/systems/input.md).
> Onde houver diferenças, a versão em inglês é a correta.

Dois nós transformam a entrada do jogador em comandos. Nenhum deles move nada por conta própria.

- `PointClickMoveInput`: o mouse, e WASD com o botão direito segurado → `NavigationMover.move_to()`, `steer()` e
  `stop()`.
- `CharacterActionInput`: teclas de corrida rápida e pulo → `GroundCharacter.sprint_requested` e `jump()`.

Os dois ficam na cena do herói jogável (`playable_hero.tscn`), não na cena do personagem; assim, uma IA pode
controlar o mesmo corpo. Para a visão do jogador, veja [Controles](../controls.md). Para copiar o herói montado,
siga [Usando no seu projeto](../integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto); para combinações
sugeridas, veja [Configurações](../configurations.md).

## PointClickMoveInput

| Entrada | Comando |
|---|---|
| Clique no chão | `move_to(point)`: um raio da câmera em `ground_mask` encontra o ponto |
| Botão esquerdo segurado | `steer()` em direção ao cursor, ou `move_to()` até o ponto sob ele, dependendo de `hold_mode` |
| Direito e depois esquerdo, ou ambos durante `hold_delay` | `steer()` para onde a câmera olha; A e D desviam na diagonal para a frente (`keys_with_camera_steer`) |
| Esquerdo segurado e depois direito | Nenhum novo comando: o botão segurado mantém a direção pela mira enquanto o direito gira a câmera (`look_around_while_held`) |
| Botão direito e WASD | `steer()` em relação à câmera, de lado ou virando (`keys_with_camera`); `stop()` ao soltar |

Quem controla o personagem num tick é decidido num só lugar, `_physics_process`: primeiro um botão esquerdo segurado,
senão as teclas com o botão direito. Então soltar o botão esquerdo enquanto o botão direito e W estão segurados não
para o personagem: as teclas assumem na hora.

Ao soltar o direito durante uma corrida com ambos os botões, o herói mantém a direção anterior da câmera
(`keep_camera_course`). O cursor assume quando o mouse se move mais de 8 px, mas não nos primeiros
`cursor_takeover_delay` 0.2 s, quando a mão ainda pode estar girando a câmera. Ele começa 4 m adiante do
personagem na direção da corrida. Até então, soltar o esquerdo para o herói nesse rumo, como se os dois botões
tivessem sido soltos juntos, qualquer que seja o intervalo: raramente soltamos dois botões ao mesmo tempo. Com
`keep_camera_course` desligado, o cursor assume assim que o direito é solto, a partir de sua posição anterior à
órbita, o que pode virar bruscamente o personagem.

### Olhando em volta durante a corrida

Se pressionado durante uma corrida já guiada pelo cursor com o esquerdo segurado, o direito só gira a câmera
(`look_around_while_held`, ligado): o jogador quer olhar em volta sem passar o controle da corrida para a câmera.
Sem essa opção, o personagem vira imediatamente para onde a câmera olha, muitas vezes fora da rota. A ordem é
registrada ao pressionar o direito:

- durante uma corrida guiada pelo cursor: olhar em volta;
- antes de o esquerdo tornar-se um botão segurado (`hold_delay`, 0.2 s), portanto com os dois juntos, ou com o
  direito primeiro: correr na direção da câmera;
- durante uma corrida que ainda mantém a direção da câmera após soltar o direito (`keep_camera_course`): voltar a
  correr para onde a câmera olha. Depois que o mouse se mover e o cursor assumir, o próximo pressionamento do
  direito serve para olhar em volta.

Isso depende de `camera_steer_action` girar a câmera, como faz `OrbitCameraRig.rotate_action` (ambas são
`camera_rotate`): com o botão pressionado, o mouse não deve mover a mira. Se usar outra ação ou uma câmera que não
gira com ela, desligue `look_around_while_held`. Enquanto olha em volta, as teclas não interferem: o esquerdo
segurado continua comandando, como faria sem o direito.

Durante a órbita, a mira não segue o mouse: ela é o ponto do chão relativo aos pés do personagem que também
preserva o rumo quando a câmera gira sozinha (`keep_aim_on_camera_turn`). O mouse gira a câmera; no modo `STEER`,
o personagem corre para a mira. Ao soltar o direito, o cursor volta a esse ponto e o movimento do mouse volta a
guiar. Se uma órbita ampla levar a mira para fora da tela, o componente a aproxima ao longo da mesma direção para
evitar curva súbita na borda da janela.

Em `FOLLOW_POINT`, o destino permanece no mesmo lugar relativo aos pés enquanto se olha em volta e depois, até o
mouse mover mais de 8 px após `cursor_takeover_delay`, como ocorre com `keep_camera_course`. Assim a corrida
prossegue no mesmo rumo e não chega ao destino. Visto de outro lado, o ponto sob o cursor pode diferir mesmo com
o cursor sobre o mesmo chão: o raio da câmera pode acertar uma encosta ou plataforma antes. Se o personagem já
chegou ao ponto (cursor sobre os pés), não há destino a preservar, e olhar em volta o deixa ali. Ao soltar, o
cursor mira o mesmo ponto visto pelo novo ângulo, salvo se algo agora o esconder.

Se o esquerdo for solto enquanto o direito ainda gira a câmera, o cursor oculto aparece no ponto visado assim
que a câmera o liberar, não onde ela o devolveria (a posição em que estava ao pressionar o direito).

Com `keep_aim_on_camera_turn` desligado, o cursor permanece no mesmo lugar da tela e a órbita gira a corrida
junto (90° para uma órbita de 90°), assim como o giro automático da câmera. Para passar de olhar em volta a correr
na direção da câmera sem parar, pressione o esquerdo novamente enquanto segura o direito. Uma pressão do esquerdo
com o direito já ativo segue imediatamente a câmera. Desligar `look_around_while_held` faz o direito dirigir a
corrida independentemente da ordem.

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
botão foi clicado ou está sendo segurado, `hold_pending_changed(true)` pausa o acompanhamento da câmera (conectado
a `OrbitCameraRig.set_follow_paused()` em `playable_hero.tscn`), então um clique curto não a move.

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
  `stop_on_release`, ele freia onde está. Essa opção afeta só o botão segurado: um clique curto ainda corre até
  seu ponto. Caminho vazio produz corrida direta; caminho parcial pode terminar antes do destino, como explica
  [Locomoção](locomotion.md#navigationmover).

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

O padrão do script é `SIDESTEP` para ambos; a demo seleciona `TURN` para ambos, em suas configurações e em
`playable_hero.tscn`. `keys_with_camera_steer = OFF` desativa A/D com os dois botões pressionados, mas ainda se
corre na direção da câmera. Para desativar também esse comando seria preciso mudar `camera_steer_action`, o que
afeta olhar em volta e as teclas com o direito.

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

**Oculto** (`hide_cursor_while_held`, ligado por padrão). Durante a corrida, o cursor só piscaria, sobretudo quando
a câmera gira e a mira se move com o mundo. Ele some assim que o pressionamento vira botão segurado (um clique
curto não o afeta) e reaparece ao soltar, no ponto visado. O componente mantém o cursor oculto dentro da janela;
no macOS usa `MOUSE_MODE_HIDDEN`, e nos demais sistemas `MOUSE_MODE_CONFINED_HIDDEN`, evitando desvio da mira
causado pelo movimento de cursor da plataforma. Enquanto o direito gira a câmera, ela captura o cursor; soltar
o direito mantendo o esquerdo torna a ocultá-lo. Pausar ou trocar de janela o mostra imediatamente.
`is_cursor_hidden()` informa se este componente o ocultou.

**Mantém a mira** (`keep_aim_on_camera_turn`, ligado por padrão). Enquanto o botão esquerdo está segurado, a direção da
corrida vem do cursor, um ponto na tela. Se a câmera gira enquanto o cursor fica parado na tela, outro ponto do chão
fica sob o cursor, o personagem vira atrás dele, a câmera vira atrás do personagem e ele corre em círculos. Por
isso, com o botão pressionado, o componente move a mira junto com o mundo: o personagem mantém a direção enquanto
a câmera se posiciona atrás. Mover o mouse ainda guia. A mesma mira preserva o rumo durante a órbita do botão
direito usada para olhar em volta.

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
| `camera_steer_action` | `camera_rotate` | Com ela ativa, o botão segurado corre para onde a câmera olha (se pressionada primeiro ou antes de virar hold, veja `look_around_while_held`). Vazia desativa esse comando, olhar em volta e as teclas que exigem o botão |
| `look_around_while_held` | ligado | Com a corrida já guiada pelo cursor, o botão da câmera só gira a visão e preserva o rumo. Desligado: ambos dirigem na direção da câmera em qualquer ordem |
| `keep_camera_course` | ligado | Após soltar o botão da câmera durante um hold, mantém seu rumo até mover o mouse; então o cursor à frente do personagem assume. Desligado: o cursor anterior assume imediatamente |
| `cursor_takeover_delay` | 0.2 s | Com `keep_camera_course`, movimento do mouse logo após soltar o botão da câmera ainda não assume o controle |
| `ground_mask` | camada 1 | Camadas de física clicáveis. Exclua personagens e muros invisíveis (camada 4, `bounds`) |
| `hold_delay` | 0,2 s | Quando um pressionamento passa a contar como segurar |
| `steer_dead_zone` | 0,5 m | `STEER`: sem mudança de direção com o cursor tão perto do personagem |
| `stop_on_release` | desligado | `FOLLOW_POINT`: frear até parar ao soltar, em vez de continuar até o último ponto |
| `ray_length` | 1000 m | Comprimento do raio a partir da câmera |
| `keys_with_camera` | `SIDESTEP` (`TURN` na demo) | Modo de BDM + WASD |
| `keys_with_camera_steer` | `SIDESTEP` (`TURN` na demo) | Modo de BEM + BDM + A/D |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | As teclas |

`ground_mask` escolhe superfícies físicas para o raio do clique. `NavigationMover.navigation_layers` escolhe
regiões transitáveis da rota; são máscaras separadas. Exclua personagem e muros invisíveis da máscara de clique,
senão o raio pode atingi-los em vez do chão.

A tabela mostra padrões do componente, com as substituições `TURN` da cena. Na demo, `SettingsApplier` aplica os
valores salvos ao iniciar para `hold_mode`, ocultação do cursor, ambos os modos de teclas, olhar em volta e manter
a mira. Uma cópia de `playable_hero.tscn` sem esse sistema mantém os valores da cena.

Sinais: `destination_picked(point)`, `hold_started`, `hold_pending_changed(pending)` e `run_requested`: o jogador
iniciou nova corrida por clique, por botão que passou a ser segurado ou por teclas com o direito. Não ocorre se
clicar no destino atual nem se as teclas apenas continuarem após soltar o esquerdo. Em `playable_hero.tscn`,
encerra a espera da câmera após uma órbita (`CameraRig.end_follow_wait()`, veja
[Câmera](camera.md#modo-de-acompanhamento)).

`cancel()` esquece um botão pressionado: clique ainda não solto deixa de iniciar corrida; corrida pelo botão
segurado ou pelas teclas com direito freia suavemente (inclusive em `FOLLOW_POINT`, sem continuar até o último
ponto); cursor oculto reaparece no ponto visado. Um botão mantido só conta a partir do próximo pressionamento;
teclas com o direito são lidas a cada tick e voltam a andar imediatamente. Uma corrida até ponto clicado pertence
ao movimentador e continua (`NavigationMover.halt()` também a interrompe). O herói jogável chama o método antes
de teleportar e ao retirar o controle.

O componente verifica na inicialização se as ações de entrada existem e informa as ausentes como erro. Depois
não as lê: suas teclas e botões nada fazem e o motor não repete o erro. Se algumas teclas de movimento faltarem,
as outras ainda funcionam. `CharacterActionInput` e o rig da câmera seguem a mesma regra.

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

No modo `HOLD`, o pedido de corrida rápida é lido a cada tick de física, portanto soltar Shift normalmente o
encerra imediatamente. Às vezes a soltura não chega à aba Game embutida ou é interceptada pelo sistema. Se todas
as teclas vinculadas a `sprint_action` forem modificadoras (Shift, Ctrl, Alt ou Meta), `CharacterActionInput`
também verifica os modificadores carregados por eventos posteriores de mouse e teclado e libera uma pressão
obsoleta. Lê os vínculos atuais, inclusive remapeamentos durante o jogo. Para teclas de corrida que não são
modificadoras, apenas o estado normal da ação está disponível.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
