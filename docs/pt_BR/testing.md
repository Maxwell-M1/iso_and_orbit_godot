<!-- translation of docs/en/testing.md @ 70a550884801 -->
# Testes

> Esta é uma tradução do [original em inglês](../en/testing.md). Onde houver diferenças, a versão em inglês é a correta.

Os testes rodam a cena principal em modo headless, com eventos de entrada reais e física real, e comparam medições com
o esperado.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Aqui `godot` é o seu executável do Godot 4.7.2. No Windows, use a versão `_console.exe`: a comum se desprende do
terminal, então você não vê a saída nem recebe o código de saída. Num clone novo, importe o projeto uma vez antes, no
editor ou com `godot --headless --path . --import`.

Só algumas suítes, por exemplo enquanto trabalha na câmera: partes dos nomes delas depois de `--`.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

O código de saída é 1 se alguma verificação falhar. No fim, o executor imprime quantas verificações passaram e
falharam em cada suíte.

## Suítes

As suítes rodam na ordem de `SUITES` em `tests/run_checks.gd`, numa única instância da cena principal.

| Suíte | O que cobre |
|---|---|
| `movement_checks.gd` | Aceleração e parada exata, um novo clique durante a frenagem, uma curva durante a frenagem, uma inversão em velocidade máxima. Rotas: em volta da armadilha, pela abertura no muro, o labirinto, subindo e descendo a rampa, para a plataforma pelas laterais da rampa, um ponto inalcançável sobre um caixote. A proteção de bordas, e a queda sem ela |
| `world_checks.gd` | A montanha: um caminho do chão ao topo pela trilha, o local é descoberto uma vez com sua mensagem, a encosta não pode ser escalada fora da trilha, a proteção segura na trilha. O acampamento, o sítio e as ruínas são descobertos com suas mensagens. Os NPCs: cinco com equipamento e rótulos, alguém em cada local, todos de pé no chão, os caminhos os contornam, ninguém os atravessa. As aparências do herói: dez por número, cada uma com corpo, olhos e um cajado na mão direita; a passagem ao longo da fila é transitável em velocidade máxima |
| `hero_look_checks.gd` | O modelo do jogador: o cajado na mão direita durante as curvas; cadeias de silhueta separadas para o corpo e o equipamento, também em malhas adicionadas depois; a configuração do contorno. O balanço da mão: parada quando em pé; balançando e baixando na corrida, com os extremos nos passos, alternadamente; atrasando na aceleração; voltando depois de uma parada; baixando na aterrissagem. A aparência do herói: a padrão na inicialização; cada uma das dez definida em tempo de execução com um só modelo, o cajado balançando na nova mão e a silhueta nas novas malhas |
| `character_actions_checks.gd` | Corrida rápida e cansaço pela ação de entrada, a barra de fôlego. Soltar o Shift no modo segurar com eventos reais (na corrida, com o botão esquerdo, na janela de configurações, depois do modo alternar, uma soltura perdida). O modo alternar. Corrida rápida e pulo desligados, corrida rápida sem cansaço. O pulo: altura, o buffer, coyote time, um pulo de uma borda com a proteção ligada, um pulo de 1,5 m. Sinais do personagem: passos por distância e mais rápidos na corrida rápida, nenhum parado ou no ar, pulo e aterrissagem com a velocidade da queda, descer a rampa sem aterrissagem, início e fim da corrida rápida. Um som para cada sinal e seus interruptores; o loop da corrida rápida se repete |
| `input_checks.gd` | Um clique do mouse: sem corrida e sem marcador enquanto pressionado, corrida até o ponto pressionado depois de soltar. Segurar no modo `STEER`: corrida em direção ao cursor, nunca até o ponto pressionado, sem marcador, parada rápida ao soltar. Segurar no modo `FOLLOW_POINT`: corrida enquanto segurado; ao soltar, parada rápida com `stop_on_release`, senão corrida até o último ponto do cursor com seu marcador. Os dois botões: subida da rampa, giro com a câmera. BDM + WASD nos modos lateral e virar: direção, orientação e velocidade para W, A, D, S e pares de teclas; nada sem o botão direito ou no modo desligado; parada pelas teclas e pelo botão; o botão direito sozinho não interrompe um clique. BEM + BDM + A/D nos três modos. O botão esquerdo pressionado e solto enquanto anda com BDM + W: a caminhada continua sem parar. As teclas abandonam uma corrida até um ponto clicado e seu marcador some. O cursor oculto ao correr segurando o botão esquerdo |
| `camera_checks.gd` | O modo de seguir (desligado, imediato, padrão, muito lento) e suas pausas (o botão direito, um pressionamento indefinido). Segurar o botão esquerdo com e sem o cursor mantendo a mira. Órbita e zoom com o mouse: abaixo do meio a roda nivela a câmera rapidamente; por padrão o botão direito não inclina, com a configuração inclina, e desligá-la restaura a inclinação da roda. Alinhamento da inclinação na corrida |
| `camera_arm_checks.gd` | Comprimento total em área aberta. Um penhasco atrás: parada imediata; andando em direção a ele, a câmera se aproxima e fica fora dele; sem o penhasco, retorno depois de uma pausa, suavemente; sem a parada, a câmera fica dentro do penhasco. Uma cerca com um penhasco logo atrás. Corpos na camada da câmera a param, na camada dos personagens não. Uma cerca no meio do caminho: atrás dela por padrão, na frente dela suavemente com a aproximação, uma oclusão curta não conta. Uma cerca junto ao personagem: sem salto para as costas do personagem. Um poste fino não conta. Uma coluna que roça o braço não move a câmera. Corpos em `camera_ignore` e sob um nó dele. Esmaecimento de perto. As configurações chegam ao braço |
| `settings_window_checks.gd` | F10, a pausa, o foco, a captura do cursor liberada; os interruptores chegam aos seus nós; a aba Controles (modos das teclas, o slider da redução do recuo); a aba Som (o volume chega ao barramento `Master`, os interruptores chegam aos sons do personagem); a aba Personagem (aparência do herói, altura do pulo, modo do Shift, bônus de velocidade, cansaço e fôlego); controles dependentes ficam esmaecidos; o slider de inclinação fica dentro dos limites da câmera; escala da interface; redefinição; Esc |
| `localization_checks.gd` | Inglês por padrão. Cada string da interface, nas cenas, na janela de configurações aberta e nos scripts, tem tradução em todos os idiomas, e nenhuma entrada de tradução fica sem uso. Trocar o idioma muda os textos montados pelo código; os nomes dos idiomas não são traduzidos; a redefinição volta ao inglês |

## Como os testes se comportam

- Eles rodam com as configurações padrão e não salvam nada: as configurações do jogador são redefinidas para o padrão
  durante a execução e nunca são sobrescritas.
- Cada verificação restaura o que mudou. As suítes rodam uma após a outra numa única cena principal, enquanto uma suíte
  rodada sozinha recebe uma nova, e uma verificação precisa passar nos dois casos.
- Qualquer erro da engine ou de script também faz a execução falhar: um `Logger` adicionado com `OS.add_logger()` os
  conta, e o executor imprime a contagem como "engine and script errors" e a soma às falhas. Uma verificação que
  travou é interrompida, mas as outras continuam, e sem o contador a falha passaria despercebida. Sob carga pesada de
  CPU, o Jolt pode adicionar um aviso próprio, veja [Problemas conhecidos](known-issues.md#testes).
- Uma execução que trava falha depois de 600 s de tempo de jogo.
- Antes de sair, o executor remove a cena principal e espera 0,1 s. Com `--fixed-fps`, o tempo de jogo corre mais
  rápido que o tempo real enquanto o áudio toca em tempo real, então passos tocados logo antes do fim ainda estão
  soando. Sair na hora às vezes faz a engine reportar objetos `AudioStreamPlayback` e recursos de passos vazados.
- Uma janela headless não consegue mover o cursor do sistema, então os testes só veem a direção da corrida; o cursor
  em si é verificado no jogo. Uma janela headless também nunca muda o modo do mouse (`Input.mouse_mode` é sempre
  `VISIBLE`), então, para o cursor oculto, os testes leem `PointClickMoveInput.is_cursor_hidden()`.
- Os limites são calculados a partir das configurações dos componentes sempre que possível, então ajustar
  `LocomotionSettings` não quebra os testes por si só.

## Escrevendo uma verificação

Uma nova verificação é uma função `_check_…` na suíte adequada mais uma linha no `_checks()` dessa suíte. Uma nova
suíte é um arquivo `tests/<topic>_checks.gd` que estende `check_suite.gd`, mais uma linha em `SUITES`. `check_suite.gd`
tem os auxiliares compartilhados:

| Auxiliar | O que faz |
|---|---|
| `_teleport(position)` | Coloca o jogador num ponto, parado, e espera alguns ticks |
| `_run_until_arrived(target, max_time)` | Comanda uma corrida e registra o tempo, as velocidades, a distância percorrida e os ticks preso até a chegada |
| `_check_route(title, from, to, max_time)` | Uma rota: chegou a tempo sem ficar preso e, para um ponto alcançável, exatamente nele, no andar certo |
| `_ticks(count)`, `_frames(count)`, `_wait_until(condition, max_ticks)` | Espera |
| `_send_key()`, `_send_button()`, `_send_motion()` | Eventos de entrada reais |
| `_expect(condition, what)` | Conta uma verificação aprovada ou reprovada e a imprime |
| `_median()`, `_min()`, `_max()`, `_first_time_at_most()` | Estatísticas sobre valores registrados |

Não use como tipos, em scripts de teste, as classes que acessam o autoload `Settings` (os controles da janela de
configurações). Os scripts de teste são compilados antes de os nomes dos autoloads existirem, então uma classe assim
falha ao compilar e quebra o jogo inteiro naquela execução. Obtenha o nó de configurações com
`_tree.root.get_node(^"Settings")` e use duck typing.

---

*Esta página corresponde ao Iso & Orbit 1.0.0.*
