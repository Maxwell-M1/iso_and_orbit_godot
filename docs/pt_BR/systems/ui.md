<!-- translation of docs/en/systems/ui.md @ 8fc9a768e40b -->
# UI

[← Índice da documentação](../index.md)

> Esta é uma tradução do [original em inglês](../../en/systems/ui.md).
> Onde houver diferenças, a versão em inglês é a correta.

Janelas sobre o jogo, o sistema de configurações, o HUD e as traduções da interface.

## Janelas: UiRoot e UiScreen

`UiRoot` (um `CanvasLayer`, `addons/iso_orbit/ui_screens/ui_root.gd`; a instância da demo é
`gdscript/ui/ui_root.tscn`) mostra as janelas como uma pilha:

- `open(scene)` coloca uma janela no topo, `close_top()` fecha a do topo, `toggle(scene)` fecha uma janela que está
  aberta (e tudo acima dela) ou a abre. Esc (`ui_cancel`) fecha a janela do topo; F10 (`toggle_settings`) abre e fecha
  a janela de configurações (`settings_screen`).
- Enquanto qualquer janela está aberta, o jogo fica pausado (`pause_game`) e o cursor fica visível. `UiRoot` pausa
  apenas um jogo em execução e encerra só a pausa que iniciou: se o jogo já estava pausado ao abrir a janela,
  continua sob responsabilidade de quem o pausou. Se essa outra pausa acabar, o jogo corre atrás da janela (veja
  [Níveis](levels.md#uma-mudança-de-nível)). `UiRoot` roda em `PROCESS_MODE_ALWAYS`, herdado pelas janelas.
- O foco do teclado vai para o `initial_focus` da janela quando ela abre e volta para onde estava quando ela fecha.
- Sinais: `screen_opened(screen)`, `screen_closed(screen)`. Consultas: `has_open_screens()`, `get_top_screen()`.

Uma janela é uma cena cuja raiz estende `UiScreen`, um `Control` de tela cheia. Uma janela nunca fecha a si mesma: ela
pede com o sinal `close_requested` (`request_close()`), e o `UiRoot` a fecha. Chamadas descem a árvore e sinais sobem,
então o `UiRoot` sempre sabe quais janelas estão abertas e restaura o foco e a pausa corretamente. Sobrescreva
`_screen_opened()` e `_screen_closed()` para reagir.

**Uma nova janela:** uma cena com raiz `UiScreen`, organizada com contêineres e estilizada pelo tema; abra-a com
`UiRoot.open(scene)`.

## Configurações

### GameSettings

O autoload `Settings` (`gdscript/settings/game_settings.gd`, classe `GameSettings`) guarda os valores:

- As chaves são constantes da classe (`GameSettings.LEDGE_GUARD` é `&"gameplay/ledge_guard"`), então funcionam em
  `match`. A parte antes da barra é a seção no arquivo.
- `DEFAULTS` guarda cada chave com seu padrão; o tipo do padrão é o tipo da configuração. Um valor do tipo errado no
  arquivo (editado à mão) volta para o padrão.
- `get_value(key)`, `set_value(key, value)`, `reset_to_defaults()` e o sinal `changed(key, value)`.
- Os valores são carregados em `_init()`, antes do `_ready()` de qualquer nó da cena, e salvos em
  `user://settings.cfg` quando a janela de configurações fecha e quando o jogo é encerrado. `persistent = false` impede
  o salvamento; os testes o definem e redefinem tudo para o padrão, então ignoram as configurações do jogador e nunca
  as sobrescrevem.
- As chaves listadas em `_OBSOLETE_KEYS` são removidas do arquivo ao carregar.
- As configurações no nível da engine são aplicadas pela própria classe (`_apply_to_engine()`): tela cheia, limite de
  taxa de quadros e V-Sync, interpolação de física, escala da interface, idioma, volume. As configurações dos nós da
  cena são aplicadas pela cena: na demo, `gdscript/demo/settings_applier.gd` lê `get_value()` na inicialização e escuta
  `changed`.

**Uma nova configuração:**

1. Uma constante de chave e um padrão em `DEFAULTS` em `GameSettings`.
2. Um controle com essa chave em `settings_screen.tscn` (veja abaixo). O código da janela não muda.
3. Um ramo em `settings_applier.gd` que define a propriedade, ou em `GameSettings._apply_to_engine()` se a engine a
   aplicar.
4. Os textos dela nas traduções, veja [Traduções](#traduções).

### A janela de configurações

`gdscript/ui/settings/settings_screen.tscn` tem seis abas: Controles, Personagem, Câmera, Exibição, Interface, Som.
Todas as configurações e seus padrões estão listados em [Configurações](../settings.md).

- Cada controle se liga a uma chave e se atualiza quando a configuração muda em qualquer lugar:
  - `SettingCheckButton`: uma configuração booleana.
  - `SettingOptionButton`: uma configuração inteira; o valor de um item é o seu ID, definido no Inspetor (Inspector)
    junto com o texto, então os itens podem ser reordenados livremente.
  - `SettingSlider`: um número. `value_label` mostra o valor com `value_format`; `zero_text` substitui o zero (por
    exemplo "instant"); `apply_on_release` aplica um arraste do mouse só ao soltar, para configurações que
    redimensionam a própria interface. Os limites e o passo são as propriedades de `Range`.
  - `SettingLanguageButton`: o idioma da interface, veja abaixo.
- Controles que não fazem sentido sem outra configuração ficam esmaecidos e bloqueados: a redução do recuo sem o modo
  lateral, a altura do pulo sem o pulo, tudo sobre a corrida rápida sem a corrida rápida, a duração do fôlego sem o
  cansaço, o tempo do giro sem giro, ângulo e tempo da inclinação sem alinhamento, altura e tempo da altura sem
  alinhamento e som de passos com o herói flutuando (`_update_dependent_rows()`).
- Cada página de aba é um `ScrollContainer`: uma aba longa rola (também acompanhando o foco do teclado) e a janela não
  cresce. A altura da janela é o `custom_minimum_size` do `TabContainer` (440). As abas longas (Câmera, a maior, e
  Personagem) rolam, e a janela inteira fica na tela com escala de 100%.
- **Redefinir tudo** chama `reset_to_defaults()`. A janela salva as configurações quando fecha.
- A dica do V-Sync é montada pelo código a partir de uma frase traduzida e da taxa de atualização do monitor.

### Escala da interface

A escala da interface é o `content_scale_factor` da janela raiz. Com o modo de stretch `canvas_items`, ela escala todo
o 2D (a dica, o contador de FPS, a barra de fôlego, as janelas) e deixa a visão 3D intacta. 100% é o tamanho como foi
criado nas cenas, 50% a metade disso. O slider arrastado com o mouse só aplica a escala ao soltar (`apply_on_release`);
senão a janela se redimensionaria sob o mouse e o slider fugiria dele. O teclado e a roda mudam a escala na hora.

## HUD

| Nó em `main.tscn` | Script | O que mostra |
|---|---|---|
| `Hud`, `Hud/Panel` | `gdscript/demo/hud.gd` em `Hud` | Dica com os vínculos atuais (`Hud/ActionTexts`, veja [Nomes das teclas nos textos](#nomes-das-teclas-nos-textos)) e velocidade real do herói (`GroundCharacter.get_move_speed()`; contra parede, 0). O script só atualiza a velocidade; `settings_applier.gd` mostra/oculta o painel e as linhas de recursos desligados (olhar em volta, teclas com BDM, dois botões + A/D, corrida rápida, pulo) |
| `Hud/FpsCounter` | `FpsCounter` (Label) | Quadros por segundo no canto superior direito; funciona com o jogo pausado |
| `Hud/CharacterState/Monitor` | `CharacterMonitor` (Label) | Sob o contador de FPS: o que o herói está fazendo (estado, velocidade e mistura, movimento, giro, chão ou ar, passos e pés, fôlego) e os últimos eventos. Oculto por padrão. Veja [Locomoção](locomotion.md#charactermonitor-o-estado-como-texto) |
| `Hud/DiscoveryToast` | `DiscoveryToast` (Label) | “Descoberto: …” por `show_time` (3.5 s) na primeira entrada num `PointOfInterest`. Encontra lugares pelo grupo `points_of_interest`, inclusive os adicionados depois durante o jogo (`watch_added_places` ligado; desligado: só os iniciais); `show_discovery(title)` mostra manualmente |
| `Hud/StaminaBar` | `StaminaBar` (ProgressBar) | Aparece quando o fôlego começa a ser gasto, fica vermelha enquanto o personagem está exausto (variação `StaminaBarExhausted`) e some em 0,6 s quando fica cheia de novo |
| `Hud/TravelPrompt` | `TravelPrompt` (Control), `gdscript/ui/travel_prompt.gd` | Oferta acima da barra de fôlego: tecla de `interact` num indicador (`InputNames.of_action()`, como nas dicas) e “Teletransporte: <lugar>”. Tecla ou clique confirma (`confirmed(portal)`), inclusive com Shift ou outro modificador segurado; o botão não assume foco do teclado, então Espaço pula sem pressioná-lo. Não é janela: o jogo continua |

A tela de carregamento (`LoadingScreen` em `main.tscn`, do addon `levels`) não integra o HUD: cobre o jogo na troca
de nível; veja [Níveis](levels.md#a-tela-de-carregamento). O HUD se oculta para a captura da imagem e volta sob
a tela.

O painel de dica, o contador de FPS, a linha do caminho e o painel do estado do personagem são ligados e desligados em
Configurações → Interface.

## Tema

`shared/ui/ui_theme.tres` é o tema do projeto (`gui/theme/custom`): painéis, a janela, botões e estas variações de
tipo: `WindowPanel`, `WindowLayout`, `TabPage`, `SettingsList`, `HintLabel`, `FpsCounter`, `DiscoveryToast`,
`StaminaBar`, `StaminaBarExhausted`, `KeyBadge`, `TravelButton`. Os nós escolhem uma variação por
`theme_type_variation` em vez de sobrescrever estilos individualmente. A tela de carregamento tem tema próprio,
`loading_screen_theme.tres`, portanto conserva a aparência em qualquer projeto.

## Traduções

O inglês é o idioma das próprias cenas e scripts. Os outros idiomas são traduções gettext em `l10n/ui/<locale>.po`,
registradas no `project.godot` (`internationalization/locale/translations`). O idioma é a configuração
`interface/language` (Configurações → Interface → **Idioma**, inglês por padrão); `GameSettings` o passa para
`TranslationServer.set_locale()`, e a interface muda na hora, sem reiniciar.

Como os textos são traduzidos:

- **Textos nas cenas** são traduzidos pela engine: textos de `Label`, `Button` e `CheckButton`, itens de
  `OptionButton`, tooltips, títulos de abas e `Label3D` acima de NPCs e nas placas dos portais
  (`auto_translate_mode`). O título escrito pelo script na tela de carregamento é traduzido da mesma forma;
  as dicas são traduzidas pelo script antes de inserir as teclas (`tip_format`).
- **Textos montados pelo código** usam `tr()`: “Descoberto: …” com o nome do local, a oferta “Teletransporte: %s”,
  os valores dos sliders com
  unidades e a dica do V-Sync são reconstruídos em `NOTIFICATION_TRANSLATION_CHANGED`; a leitura da velocidade é
  reconstruída a cada quadro de qualquer forma. Esses nós desligam a tradução automática para si mesmos, para que a
  engine não tente traduzir o resultado montado.
- **Os nomes dos idiomas** na lista de idiomas são escritos no próprio idioma ("English", "Русский") e nunca são
  traduzidos (`SettingLanguageButton.NATIVE_NAMES`).

**Um novo idioma:**

1. Copie `l10n/ui/ru.po` para `l10n/ui/<locale>.po`, defina `Language` e `Plural-Forms` no cabeçalho e traduza cada
   `msgstr`. Um editor de PO como o Poedit ajuda.
2. Adicione o arquivo a `internationalization/locale/translations` (Configurações do Projeto → Localização →
   Traduções; em inglês, Project Settings → Localization → Translations).
3. Adicione o nome do idioma no próprio idioma a `NATIVE_NAMES` em `gdscript/ui/settings/setting_language_button.gd`.
   A lista na janela de configurações é montada a partir das traduções carregadas, então nada mais muda.
4. Rode os testes: `tests/localization_checks.gd` informa strings ausentes, entradas não usadas e traduções que
   perdem um token de tecla.

**Uma nova string:** escreva-a em inglês na cena ou em `tr("...")`, usando tokens para teclas (veja abaixo), e
adicione um `msgid` com a tradução a cada `.po`. O teste coleta strings de cenas, inclusive modelos de
`ActionTexts`; as que só os scripts passam para `tr()` estão listadas em
`SCRIPT_STRINGS` em `tests/localization_checks.gd`, então adicione as novas ali.

### Nomes das teclas nos textos

Um texto escreve a ação de entrada entre chaves, não a tecla; ao exibir, insere-se a tecla vinculada naquele
momento. `{sprint} — run faster` aparece como “Shift — correr mais rápido”, ou “Ctrl — correr mais rápido” se a
ação passar para Ctrl. Assim, as dicas seguem corretas quando o jogo muda o Input Map ou permite remapeamento.
`InputNames` (addon `ui_screens`) fornece os nomes:

- `{action}`: primeira tecla ou botão do mouse da ação. A tecla recebe a letra no layout do jogador (W em
  QWERTY e num teclado russo, Z em AZERTY), com modificadores (`Ctrl+S`); botão do mouse recebe nome curto: BEM,
  BDM, botão do meio, roda para cima etc. Vínculos físicos limitados ao modificador esquerdo ou direito indicam
  o lado, como `Ctrl+Right Shift`; teclas lógicas correspondem a ambos os lados.
- `{a/b}`: várias ações separadas por barras: `{move_left/move_right}` vira “A/D”. Duas ações da roda, uma para
  cima e outra para baixo, viram “Roda”.
- `{a+b+c+d}`: nomes unidos quando cada um é uma só letra:
  `{move_forward+move_left+move_back+move_right}` vira “WASD”; nos outros casos, são separados por barras.
- Ação sem evento aparece como “Não atribuído”. Token de ação ausente no Input Map permanece literal, deixando
  a lacuna visível.

Os nomes também são traduzidos: botões do mouse (`InputNames.get_mouse_names()`), “Space”, “Unbound”, “Left %s”
e “Right %s” têm entradas nos `.po`; os outros nomes de teclas são iguais em todos os idiomas. A tradução mantém
os tokens da string; `localization_checks.gd` reprova uma que perde ou muda algum.

Quem insere os nomes:

- **`ActionTexts`**, um `Node` da cena. Assume cada controle sob seu pai (ou sob `root`) cujo texto, tooltip ou
  itens `OptionButton` tenham token. Guarda modelos, desliga a tradução automática do próprio controle e define
  o texto traduzido com os nomes; refaz isso ao mudar o idioma. HUD (`Hud/ActionTexts`) e janela de
  configurações (`ActionTexts` em sua raiz) possuem uma instância cada. Controles sem tokens permanecem como
  estão, inclusive filhos que herdam tradução. Um controle explicitamente não traduzido conserva seu modelo
  literal, mas seus nomes de teclas são localizados. Exclua controles cujo texto é definido por script, pois
  atualizar recolocaria o modelo. Após mudar teclas, atualize todos:
  `get_tree().call_group(ActionTexts.GROUP, &"refresh")`.
- **Código:** `InputNames.format(tr(text))` para texto completo; `InputNames.of_action(&"interact")` para uma tecla
  (indicador da oferta de viagem). `TravelPrompt` integra `ActionTexts.GROUP`, então a mesma atualização muda
  seu indicador visível.
- **Dicas da tela de carregamento:** `LoadingScreen.tip_format` é um `Callable` que transforma dica traduzida no
  texto exibido; `gdscript/main.gd` o define como `InputNames.format` e inclui a tela em `ActionTexts.GROUP`.
  `LoadingScreen.refresh()` reformata a dica atual sem reiniciar o tempo dela. O addon `levels` dispensa
  `ui_screens`: sem `tip_format`, a dica aparece apenas traduzida.

Para mudanças em Project Settings → Input Map antes do jogo, os textos iniciais já usam os vínculos novos. Para
mudanças via `InputMap` durante o jogo, atualize o grupo após editar; isso funciona também com o jogo pausado.
A demo não tem aba de remapeamento de teclas na janela de configurações.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
