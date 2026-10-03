<!-- translation of docs/en/controls.md @ b096a8a367b0 -->
# Controles

> Esta é uma tradução do [original em inglês](../en/controls.md).
> Onde houver diferenças, a versão em inglês é a correta.

Mouse e teclado; não há suporte a gamepad. A maior parte do comportamento abaixo pode ser alterada na janela de
configurações (F10), veja [Configurações](settings.md). Como a entrada funciona por dentro: [Entrada](systems/input.md).

| Entrada | Ação |
|---|---|
| Clique esquerdo no chão | Correr até esse ponto contornando obstáculos; um marcador aparece no chão |
| Segurar o botão esquerdo | Correr atrás do cursor; o cursor some enquanto você corre |
| Botão esquerdo + direito, em qualquer ordem | Correr para onde a câmera olha. Gire a câmera com o mouse e o herói vira junto. A / D desviam na diagonal para a frente. Solte o botão esquerdo para parar |
| Botão direito + mouse | Orbitar a câmera ao redor do herói; o cursor volta ao seu lugar depois |
| Botão direito + WASD | Mover-se em relação à câmera, de lado ou virando (veja abaixo). Solte as teclas ou o botão para parar |
| Roda do mouse | Abaixar a câmera para mais perto do herói ou erguê-la mais alto e mais longe |
| Shift | Corrida rápida enquanto segurado, ou alternar com um toque (uma configuração). Com o cansaço ligado, enquanto durar o fôlego; a barra de fôlego fica na parte de baixo da tela |
| Espaço | Pular |
| F10 | Configurações (pausa o jogo); Esc ou F10 as fecha |

## Clicar ou segurar

Após 0,2 s fica decidido se o pressionamento é um clique ou se o botão está sendo segurado.

- **Clique** (soltou antes): o herói corre por um caminho até o ponto onde você pressionou, mesmo que o mouse tenha se
  movido depois, e um marcador aparece ali. A corrida começa ao soltar. O marcador some quando o herói chega ou quando
  você assume o controle segurando o botão ou com as teclas.
- **Segurar** (segurou por mais tempo): o herói corre atrás do cursor na hora e nunca se vira para o ponto onde você
  pressionou.

Até a decisão, o herói continua fazendo o que estava fazendo.

Como o herói segue o botão segurado (Configurações → Controles → **BEM segurado**):

- **Direto ao cursor** (padrão): sem busca de caminho. O herói desliza ao longo dos obstáculos e sobe a rampa por onde
  você apontar, e para suavemente ao soltar.
- **Ao ponto por um caminho**: o herói segue um caminho de navegação até o ponto sob o cursor. Perto de mudanças de
  altura (a rampa, a plataforma), o caminho pode saltar entre rotas. Ao soltar, o herói continua correndo até o último
  ponto.

Enquanto o botão segurado faz a câmera girar (modo de seguir), o cursor se move com o mundo e fica sobre o ponto em que
você mirou, então o herói mantém o rumo. Configurações → Câmera → **O cursor mantém a mira enquanto a câmera gira**.

## Teclas com o botão direito

WASD só funcionam enquanto o botão direito está segurado. Sem ele, não fazem nada. O modo é escolhido separadamente
para o botão direito sozinho (**BDM + WASD**) e para os dois botões (**BEM + BDM + A/D**), cada um com **Desligado** e
duas variantes:

| | Lateral | Virar / diagonal (padrão) |
|---|---|---|
| BDM + W | para a frente, para onde a câmera olha | o mesmo |
| BDM + A / D | de lado, olhando para a frente | vira à esquerda / direita e vai para lá |
| BDM + S | para trás, olhando para a frente, mais devagar | dá meia-volta e anda em direção à câmera |
| Duas teclas (W + A, S + D…) | na diagonal, olhando para a frente | na diagonal, olhando para onde vai |
| BEM + BDM + A / D | na diagonal para a frente, olhando para a frente | na diagonal para a frente, olhando para onde vai |

O movimento na diagonal é tão rápido quanto em linha reta. O recuo é 30% mais lento por padrão (3,85 m/s em vez de
5,5; Configurações → Controles → **Recuo (S) mais lento em**). Na diagonal para trás a redução é parcial (S + D no modo
lateral: 21%), de lado não há nenhuma, então a redução só existe no modo lateral.

Depois de parar, o herói continua olhando para onde olhava; um clique ou segurar o botão o faz olhar de novo para onde
corre.

Segurar só o botão direito, sem teclas, não interrompe uma corrida até um ponto clicado, então você pode girar a
câmera durante a corrida. Solte o botão esquerdo enquanto segura o botão direito e W, e o herói continua andando pelas
teclas sem parar. Um modo definido como **Desligado** também remove sua linha da dica de controles.

As teclas são mapeadas pela posição física, então são WASD em qualquer layout de teclado.

## Câmera

- **Órbita:** botão direito e mouse. O movimento vertical também inclina a câmera se Configurações → Câmera → **BDM
  inclina a câmera na vertical** estiver ligado (desligado por padrão).
- **Zoom:** a roda muda a distância e a inclinação juntas. Abaixo do meio, a câmera se nivela rapidamente, para você
  ver o que está à frente.
- **Seguir** (desligado por padrão): Configurações → Câmera → **Virar a câmera para seguir a corrida** e **Alinhar a
  inclinação da câmera**. A câmera não segue enquanto o botão direito está segurado, nem durante os primeiros 0,2 s de
  um pressionamento do botão esquerdo.
- **Obstáculos:** a câmera para numa montanha, parede ou telhado atrás dela. Opcionalmente, ela se aproxima quando um
  obstáculo esconde o herói. Atrás de obstáculos, o herói aparece como silhueta.

Detalhes: [Câmera](systems/camera.md).

## Corrida rápida e pulo

- **Corrida rápida:** 1,5 vez mais rápido enquanto o Shift está segurado e o herói está se movendo. Com cansaço, o
  fôlego dura 5 s; quando acaba, o herói corre na velocidade normal até o fôlego se recuperar a 30%, e então volta à
  corrida rápida sozinho se o Shift ainda estiver segurado. Ficar parado com o Shift segurado não gasta nada. No modo
  alternar, um toque liga a corrida rápida e o próximo a desliga; ela também desliga quando o herói fica exausto.
- **Pulo:** 1 m de altura. Um pulo pressionado pouco antes de aterrissar acontece na aterrissagem; um pulo pressionado
  logo depois de sair de uma borda ainda funciona. A proteção de bordas não impede um pulo de uma borda.

Detalhes: [Locomoção](systems/locomotion.md).

---

*Esta página corresponde ao Iso & Orbit 1.0.0.*
