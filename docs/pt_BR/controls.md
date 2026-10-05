<!-- translation of docs/en/controls.md @ 18ede9271cf7 -->
<!-- translation of docs/en/controls.md @ pending -->
# Controles

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/controls.md).
> Em caso de divergência, consulte a versão em inglês.

Mouse e teclado; não há suporte a gamepad. A maior parte dos comportamentos abaixo pode ser alterada na janela de
configurações (F10); veja [Configurações](settings.md). Funcionamento interno: [Entrada](systems/input.md).

As teclas e botões nesta página e no restante da documentação são os padrões da demo, definidos em Project
Settings → Input Map. As dicas do jogo, da janela de configurações e da tela de carregamento mostram os vínculos
atuais: ao mudá-los, os nomes exibidos mudam também (veja
[Nomes das teclas nos textos](systems/ui.md#nomes-das-teclas-nos-textos)).

| Entrada | Ação |
|---|---|
| Clique esquerdo no chão | Correr até o ponto contornando obstáculos; aparece um marcador no chão |
| Segurar o botão esquerdo | Correr atrás do cursor; ele some durante a corrida |
| Segurar o esquerdo e depois o direito | Olhar em volta durante a corrida: o mouse gira a câmera e o herói mantém o rumo. Ao soltar o direito, volte a guiá-lo com o mouse |
| Segurar o direito e depois o esquerdo, ou ambos juntos | Correr para onde a câmera olha. Gire-a com o mouse e o herói acompanha. A / D desviam na diagonal para a frente. Solte o esquerdo para parar, ou os dois em qualquer ordem |
| Botão direito + mouse | Girar a câmera ao redor do herói; o cursor volta à posição anterior |
| Botão direito + WASD | Mover-se em relação à câmera, de lado ou virando (veja abaixo). Solte teclas ou botão para parar |
| Roda do mouse | Abaixar e aproximar a câmera, ou elevá-la e afastá-la |
| Shift | Corrida rápida enquanto pressionado ou alternada a cada toque (ajuste). Com cansaço ativo, enquanto houver fôlego; a barra fica na parte inferior da tela |
| Espaço | Pular |
| E | Sobre uma plataforma de teleporte: viajar ao destino. Clicar na oferta faz o mesmo |
| F10 | Configurações (pausa o jogo); Esc ou F10 fecha a janela |

## Clicar ou segurar

Após 0.2 s o sistema decide se o botão foi clicado ou mantido pressionado.

- **Clique** (solto antes): o herói segue um caminho até o ponto em que você pressionou, mesmo se o mouse mover
  depois, e um marcador aparece ali. A corrida começa ao soltar. O marcador desaparece ao chegar ou quando você
  assume o controle segurando o botão ou usando teclas.
- **Botão segurado** (por mais tempo): o herói corre imediatamente atrás do cursor, sem desviar até o ponto
  original do pressionamento.

Até a decisão, o herói continua o que já fazia.

Como ele segue o botão segurado (Configurações → Controles → **BEM segurado**):

- **Direto ao cursor** (padrão): sem busca de caminho. O herói desliza junto a obstáculos, sobe a rampa conforme
  o cursor e para suavemente ao soltar.
- **Ao ponto por um caminho**: segue uma rota de navegação até o ponto sob o cursor. Perto de diferenças de altura
  (rampa, plataforma), a rota pode saltar entre alternativas. Ao soltar, continua até o último ponto.

Se a câmera girar automaticamente durante o botão esquerdo segurado (acompanhamento), o cursor se move com o mundo
e permanece sobre o ponto visado, preservando o rumo do herói. O mesmo vale ao girar com o botão direito para
olhar em volta durante a corrida. Configurações → Câmera → **O cursor mantém a mira enquanto a câmera gira**.

## Os dois botões: o que acontece

O botão direito sempre gira a câmera. A ordem dos pressionamentos determina se ele também dirige a corrida. Com
os ajustes padrão:

| Você pressiona | O herói | A câmera |
|---|---|---|
| O botão esquerdo, segurado | Corre direto rumo ao cursor | Fica como está (acompanhamento desligado por padrão) |
| ...depois o direito também, movendo o mouse | Mantém a direção: olhar em volta não o dirige. As teclas ficam inativas nesse intervalo | Gira em torno do herói |
| ...depois solta o direito, mantendo o esquerdo | Continua no mesmo rumo. O cursor oculto fica sobre o ponto visado, e o mouse volta a guiá-lo dali | Fica na posição escolhida |
| ...ou solta o esquerdo primeiro | Para suavemente; o cursor aparece no ponto visado ao soltar o direito | Continua girando até soltar o direito |
| O direito, depois o esquerdo, ou ambos em até 0.2 s | Corre para onde a câmera olha e gira com ela; A / D desviam na diagonal para a frente | Gira com o mouse |
| ...depois solta o direito, mantendo o esquerdo | Mantém o rumo da câmera até mover o mouse; então o cursor, colocado 4 m à frente do herói, passa a guiá-lo | Fica na posição escolhida |
| ...e aperta o direito outra vez antes de mover o mouse | Volta a correr para onde a câmera olha. Depois que o mouse mover e o cursor assumir a direção, o direito serve para olhar em volta | Gira com o mouse |
| Solta o esquerdo | Para suavemente, em cerca de um quarto de segundo. Se segurar direito e W, continua andando pelas teclas | — |
| Solta ambos, em qualquer ordem e com qualquer intervalo, movendo o mouse entre eles | Para no rumo atual, sem virar para o cursor | — |
| Um clique e depois o direito | Continua rumo ao ponto clicado | Gira em torno do herói |
| O direito com WASD | Anda em relação à câmera, virando para olhar na direção do movimento | Gira com o mouse |

Para passar de olhar em volta para correr na direção da câmera sem parar, pressione outra vez o esquerdo mantendo
o direito.

### O que os ajustes mudam

- **BDM durante a corrida com BEM só gira a câmera** (Controles), desligado: o direito dirige a corrida
  independentemente da ordem. Pressionado durante a corrida atrás do cursor, vira o herói imediatamente para onde
  a câmera olha.
- **O cursor mantém a mira enquanto a câmera gira** (Câmera), desligado: ao olhar em volta, o cursor fica no
  mesmo ponto da tela e a corrida gira junto com a câmera, em curva. A câmera que acompanha a corrida também a
  faz curvar assim.
- **BEM segurado → Ao ponto por um caminho** (Controles): o herói segue um caminho até o ponto sob o cursor.
  Enquanto você olha em volta, e depois até mover o mouse, o destino fica no mesmo lugar em relação ao herói,
  não sob o cursor: vista de outro lado, a posição do cursor pode coincidir com rampa ou plataforma. Ao soltar o
  esquerdo, o herói continua até o último destino.
- **Ocultar o cursor ao correr segurando BEM** (Controles), desligado: depois de olhar em volta, o cursor salta
  da posição anterior para o ponto visado, que mudou de lugar na tela durante a rotação da câmera.
- **Virar a câmera para seguir a corrida**, **Alinhar a inclinação da câmera na corrida** e
  **Alinhar a altura da câmera na corrida** (Câmera): a visão gira suavemente atrás da corrida rumo ao cursor ou
  ao ponto clicado, exceto enquanto o direito está pressionado. Após girá-la com o direito, inclusive ao olhar
  em volta correndo, ela permanece como você deixou até o herói parar ou começar outra corrida com o esquerdo
  (novo clique ou novo botão segurado). Corridas pelas teclas nunca são acompanhadas: elas exigem o direito.
- **BDM + WASD** e **BEM + BDM + A/D** (Controles): como as teclas movem o herói; veja abaixo.

## Teclas com o botão direito

WASD só funcionam com o botão direito pressionado. Sem ele, não fazem nada. O modo é escolhido separadamente para
o direito sozinho (**BDM + WASD**) e para ambos (**BEM + BDM + A/D**), cada um com **Desligado** e duas variantes:

| | Lateral | Virar / diagonal (padrão) |
|---|---|---|
| BDM + W | para a frente, rumo à visão da câmera | igual |
| BDM + A / D | de lado, olhando para a frente | vira à esquerda / direita e segue |
| BDM + S | para trás, olhando para a frente, mais devagar | dá meia-volta e anda rumo à câmera |
| Duas teclas (W + A, S + D…) | na diagonal, olhando para a frente | na diagonal, olhando para onde vai |
| BEM + BDM + A / D | diagonal para a frente, olhando para a frente | diagonal para a frente, olhando para onde vai |

O movimento diagonal é tão rápido quanto o reto. O recuo é 30% mais lento por padrão (3.85 m/s em vez de 5.5;
Configurações → Controles → **Recuo (S) mais lento em**). Diagonal para trás sofre redução parcial (S + D no modo
lateral: 21%); movimento lateral não sofre, portanto a redução só existe nesse modo.

Após parar, o herói mantém a orientação; um clique ou botão segurado o faz voltar a olhar na direção da corrida.

Um modo em **Desligado** também retira sua linha da dica de controles. Comportamento dos botões e teclas juntos:
[Os dois botões: o que acontece](#os-dois-botões-o-que-acontece).

As teclas de movimento usam as posições físicas WASD num teclado US QWERTY. As letras exibidas seguem o layout:
as mesmas posições são ZQSD num AZERTY. Mude vínculos em Project Settings → Input Map; a demo ainda não oferece
menu para remapear teclas durante o jogo.

## Câmera

- **Órbita:** botão direito e mouse. Movimento vertical também inclina se Configurações → Câmera → **BDM inclina
  a câmera na vertical** estiver ligado (desligado por padrão).
- **Zoom:** a roda muda distância e inclinação juntas. Abaixo da metade, a câmera se nivela rapidamente para
  mostrar o caminho à frente.
- **Acompanhamento** (desligado por padrão): Configurações → Câmera → **Virar a câmera para seguir a corrida**,
  **Alinhar a inclinação da câmera na corrida** e **Alinhar a altura da câmera na corrida**. A câmera não
  acompanha com o direito pressionado nem durante os primeiros 0.2 s de um pressionamento do esquerdo. Depois
  de girá-la com o direito, inclusive ao olhar em volta correndo, ela permanece como você deixou até o herói
  parar ou começar outra corrida com o esquerdo (clique ou botão segurado). Assim não dá a volta durante a
  frenagem nem numa corrida já iniciada por clique. Teclas exigem o direito, por isso não são acompanhadas.
- **Obstáculos:** a câmera para antes de encosta, parede ou teto atrás dela. Opcionalmente, aproxima-se quando um
  obstáculo esconde o herói. Atrás de obstáculos, ele aparece como silhueta.

Detalhes: [Câmera](systems/camera.md).

## Teleporte

Uma plataforma luminosa junto ao Círculo Antigo leva à Ilha Solitária; outra na ilha traz de volta. Ao subir,
aparece “E Teletransporte: …” na base da tela; afastar-se oculta a oferta. Aperte E (mesmo segurando Shift após
correr até a plataforma) ou clique na oferta: a tela de carregamento cobre a troca, e o herói chega ao lado da
outra plataforma com a câmera atrás e o controle restabelecido. O botão esquerdo mantido durante a transição só
volta a contar a partir do próximo pressionamento; teclas ainda seguradas (direito com W, A, S ou D, ou Shift)
funcionam imediatamente. Detalhes: [Níveis](systems/levels.md).

## Corrida rápida e pulo

- **Corrida rápida:** 1.5 vez a velocidade com Shift pressionado e o herói em movimento. Com cansaço, o fôlego
  dura 5 s; esgotado, o herói corre normalmente até recuperar 30% e então acelera de novo se Shift continuar
  pressionado. Parado, não gasta fôlego. No modo alternado, um toque liga a corrida rápida e o seguinte a
  desliga; a exaustão também a desliga.
- **Pulo:** 1 m de altura. Um pedido pouco antes da aterrissagem acontece ao tocar o chão; logo após sair de uma
  borda, ainda funciona. A proteção de bordas não impede um pulo para fora dela.

Detalhes: [Locomoção](systems/locomotion.md).

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
