<!-- translation of docs/en/testing.md @ fd518f56694a -->
# Testes

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/testing.md). Onde houver diferenças, a versão em inglês é a correta.

Os testes rodam a cena principal em modo headless, com eventos de entrada reais e física real, e comparam medições com
o esperado.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Aqui `godot` é o seu executável do Godot 4.7.2. No Windows, use a versão `_console.exe`: a comum se desprende do
terminal, então você não vê a saída nem recebe o código de saída. Num clone novo, importe o projeto uma vez antes, no
editor ou com `godot --headless --path . --import`.

Você pode usar o caminho completo do executável em vez de acrescentá-lo ao PATH. No PowerShell, um caminho entre
aspas precisa de `&`:

```powershell
& 'C:\path\to\Godot_console.exe' --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Substitua o caminho de exemplo pelo executável de console Godot 4.7.2 instalado e execute a partir da raiz deste
projeto.

Só algumas suítes, por exemplo enquanto trabalha na câmera: partes dos nomes delas depois de `--`.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

O código de saída é 1 se alguma verificação falhar. No fim, o executor imprime quantas verificações passaram e
falharam em cada suíte.

## Suítes

As suítes rodam na ordem listada em `tests/run_checks.gd`, compartilhando uma cena principal. Escolha as
relacionadas à sua alteração; use a execução completa antes de integrar mudanças entre sistemas.

| Suíte | Verificações principais |
|---|---|
| `movement_checks.gd` | Aceleração, frenagem, mudança de destino, giro, destinos alcançáveis e inacessíveis, caminhos entre obstáculos, rampas e bordas |
| `world_checks.gd` | Navegação pelo terreno da demo, áreas de descoberta, colisão de NPCs estáticos e modelos do herói em exposição |
| `hero_look_checks.gd` | Troca dos dez modelos, posição dos equipamentos, silhuetas e movimento das mãos |
| `character_actions_checks.gd` | Corrida rápida e cansaço, modo segurado/alternado, remapeamento e liberação de modificadoras, pulo antecipado/tolerância de borda, ajustes temporários de queda, sinais e sons |
| `character_state_checks.gd` | Avisos de configuração, estado e dados de animação, degraus/encostas, teleporte, flutuação, interpolação, tempo de jogo parado e painel monitor |
| `input_checks.gd` | Clique versus botão segurado, ordem dos dois botões, modos de hold, modos das teclas, captura do cursor, cancelamento e ações ausentes |
| `camera_checks.gd` | Órbita/zoom e acompanhamento em diferentes taxas de quadros/ticks, giros bruscos, corrida rumo à câmera, espera após órbita manual, alinhamentos de inclinação/zoom/altura e teleporte |
| `camera_arm_checks.gd` | Folga diante de obstáculos, camadas de colisão, grupos ignorados, aproximação opcional ao ocultar o alvo e transparência perto dele |
| `settings_window_checks.gd` | Pausa e foco, todas as abas, mapeamento das propriedades, controles dependentes, escala da interface, redefinição e fechamento |
| `localization_checks.gd` | Cobertura das traduções, tokens de ações preservados, mudança de idioma, nomes das 12 ações remapeáveis, dicas/janelas abertas/dicas de carregamento e herança das traduções |
| `level_checks.gd` | Pontos de entrada, ofertas de viagem, progresso e pausa no carregamento, troca de cenas, estado do herói preservado e recuperação de falhas |

Para as configurações de entrada e câmera documentadas, comece com `movement`, `character_actions`, `input`,
`camera` e `settings_window`. O filtro `camera` seleciona ambas as suítes da câmera. Ao copiar o herói para outro
projeto, siga também a [lista de transferência](integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto):
a suíte deste repositório não comprova que todos os arquivos e ajustes necessários foram copiados.

## Como os testes se comportam

- Eles rodam com as configurações padrão e não salvam nada: as configurações do jogador são redefinidas para o padrão
  durante a execução e nunca são sobrescritas.
- Cada verificação restaura o que mudou. As suítes rodam uma após a outra numa única cena principal, enquanto uma suíte
  rodada sozinha recebe uma nova, e uma verificação precisa passar nos dois casos. Após cada uma,
  `Engine.time_scale` volta a 1, para uma falha com tempo lento ou parado não afetar a próxima.
- Qualquer erro ou aviso do motor ou script também faz a execução falhar: um `Logger` adicionado com
  `OS.add_logger()` os
  conta, e o executor imprime a contagem como "engine and script errors" e a soma às falhas. Uma verificação que
  travou é interrompida, mas as outras continuam. Só erros provocados de propósito e anunciados antes
  (`expect_error()` do executor, depois `take_expected_errors()` para conferir que ocorreram) não contam, como
  o teste de uma cena inválida como nível. Sob carga pesada de CPU, o Jolt pode avisar; veja
  [Problemas conhecidos](known-issues.md#testes).
- Uma execução travada falha após 1200 s de tempo de jogo. No carregamento em segundo plano, quadros sem janela
  passam muito mais rápido que na tela; por isso os testes de níveis esperam mudanças em tempo real.
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
| `_error_count()` | Número de erros do motor e scripts até agora, exceto esperados; uma verificação compara antes e depois |
| `_tree.call(&"expect_error", "part of the message")`, `_tree.call(&"take_expected_errors")` | Métodos do executor, não de `check_suite.gd`: o primeiro anuncia erro intencional, o segundo devolve os anunciados que não ocorreram e encerra a expectativa |
| `_find_non_finite(found)` | Reúne nós 3D da cena principal cuja transformação não é finita (INF ou NaN) |
| `_same_values(a, b)` | Compara os valores de dois arrays; diferente de `==`, não considera um NaN igual a outro |
| `_median()`, `_min()`, `_max()`, `_first_time_at_most()` | Estatísticas sobre valores registrados |

Não use como tipos, em scripts de teste, as classes que acessam o autoload `Settings` (os controles da janela de
configurações). Os scripts de teste são compilados antes de os nomes dos autoloads existirem, então uma classe assim
falha ao compilar e quebra o jogo inteiro naquela execução. Obtenha o nó de configurações com
`_tree.root.get_node(^"Settings")` e use duck typing.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
