<!-- translation of docs/en/systems/ui.md @ 3f969cf9dfdc -->
# UI

> Esta é uma tradução do [original em inglês](../../en/systems/ui.md).
> Onde houver diferenças, a versão em inglês é a correta.

Janelas sobre o jogo, o sistema de configurações, o HUD e as traduções da interface.

## Janelas: UiRoot e UiScreen

`UiRoot` (um `CanvasLayer`, `addons/iso_orbit/ui_screens/ui_root.gd`; a instância da demo é
`gdscript/ui/ui_root.tscn`) mostra as janelas como uma pilha:

- `open(scene)` coloca uma janela no topo, `close_top()` fecha a do topo, `toggle(scene)` fecha uma janela que está
  aberta (e tudo acima dela) ou a abre. Esc (`ui_cancel`) fecha a janela do topo; F10 (`toggle_settings`) abre e fecha
  a janela de configurações (`settings_screen`).
- Enquanto qualquer janela está aberta, o jogo fica pausado (`pause_game`) e o cursor do mouse fica visível. `UiRoot`
  roda em `PROCESS_MODE_ALWAYS`, e as janelas dele herdam isso.
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
- As configurações no nível da engine são aplicadas pela própria classe (`_apply_to_engine()`): limite de taxa de
  quadros e V-Sync, interpolação de física, escala da interface, idioma, volume. As configurações dos nós da cena são
  aplicadas pela cena: na demo, `gdscript/demo/settings_applier.gd` lê `get_value()` na inicialização e escuta
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
  cansaço, o ângulo de inclinação sem o alinhamento da inclinação, o tempo para alcançar sem o seguir nem o
  alinhamento (`_update_dependent_rows()`).
- Cada página de aba é um `ScrollContainer`: uma aba longa rola (também acompanhando o foco do teclado) e a janela não
  cresce. A altura da janela é o `custom_minimum_size` do `TabContainer` (440). A aba mais longa, Personagem, cabe, e a
  janela inteira fica na tela com a escala da interface em 100%.
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
| `Hud`, `Hud/Panel` | `gdscript/demo/hud.gd` em `Hud` | A dica de controles e a velocidade. O script só atualiza a velocidade; `settings_applier.gd` mostra ou oculta o painel e oculta as linhas dos recursos desativados (as teclas com o BDM, os dois botões + A/D, corrida rápida, pulo) |
| `Hud/FpsCounter` | `FpsCounter` (Label) | Quadros por segundo no canto superior direito; funciona com o jogo pausado |
| `Hud/DiscoveryToast` | `DiscoveryToast` (Label) | "Descoberto: …" por `show_time` (3,5 s) quando o jogador entra pela primeira vez num `PointOfInterest`. Encontra todos os locais pelo grupo `points_of_interest`; `show_discovery(title)` mostra um manualmente |
| `Hud/StaminaBar` | `StaminaBar` (ProgressBar) | Aparece quando o fôlego começa a ser gasto, fica vermelha enquanto o personagem está exausto (variação `StaminaBarExhausted`) e some em 0,6 s quando fica cheia de novo |

O painel de dica, o contador de FPS e a linha do caminho são ligados e desligados em Configurações → Interface.

## Tema

`shared/ui/ui_theme.tres` é o tema do projeto (`gui/theme/custom`): painéis, a janela, botões e estas variações de
tipo: `WindowPanel`, `WindowLayout`, `TabPage`, `SettingsList`, `HintLabel`, `FpsCounter`, `DiscoveryToast`,
`StaminaBar`, `StaminaBarExhausted`. Os nós escolhem uma variação por `theme_type_variation` em vez de sobrescrever
estilos um a um.

## Traduções

O inglês é o idioma das próprias cenas e scripts. Os outros idiomas são traduções gettext em `l10n/ui/<locale>.po`,
registradas no `project.godot` (`internationalization/locale/translations`). O idioma é a configuração
`interface/language` (Configurações → Interface → **Idioma**, inglês por padrão); `GameSettings` o passa para
`TranslationServer.set_locale()`, e a interface muda na hora, sem reiniciar.

Como os textos são traduzidos:

- **Textos nas cenas** são traduzidos pela engine: textos de `Label`, `Button` e `CheckButton`, itens de
  `OptionButton`, dicas de ferramenta (tooltips), títulos de abas e textos de `Label3D` acima dos NPCs
  (`auto_translate_mode`).
- **Textos montados pelo código** usam `tr()`: "Descoberto: …" com o nome do local, os valores dos sliders com
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
4. Rode os testes: `tests/localization_checks.gd` reporta cada string da interface que falta numa tradução e cada
   entrada de tradução que o jogo não mostra mais.

**Uma nova string:** escreva-a em inglês na cena ou em `tr("...")` e depois adicione um `msgid` com a tradução a cada
arquivo `.po`. O teste coleta as strings das cenas; as strings que só os scripts passam para `tr()` estão listadas em
`SCRIPT_STRINGS` em `tests/localization_checks.gd`, então adicione as novas ali.

---

*Esta página corresponde ao Iso & Orbit 1.0.0.*
