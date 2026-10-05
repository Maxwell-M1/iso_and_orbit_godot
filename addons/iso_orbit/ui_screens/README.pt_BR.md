<!-- translation of addons/iso_orbit/ui_screens/README.md @ f510902e02d8 -->
# Telas de UI

[← Índice da documentação (repositório do template)](../../../docs/pt_BR/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Janelas sobre o jogo em forma de pilha: abra uma sobre a outra, feche a do topo com Esc, pause o jogo e mostre o cursor
do mouse enquanto qualquer janela estiver aberta, dê o foco do teclado à janela e devolva-o quando ela fechar. Além
disso, há um contador de FPS que continua funcionando com o jogo pausado e nomes das teclas vinculadas às ações de
entrada para os textos da tela.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `ui_root.gd` | `UiRoot` (CanvasLayer) | A pilha de janelas: `open()`, `close_top()`, `toggle()`; pausa, cursor, foco |
| `ui_screen.gd` | `UiScreen` (Control) | Base de uma janela: `initial_focus`, o sinal `close_requested` |
| `fps_counter.gd`, `fps_counter.tscn` | `FpsCounter` (Label) | Quadros por segundo, também com o jogo pausado |
| `input_names.gd` | `InputNames` (RefCounted, estático) | Nome traduzido da tecla ou botão do mouse de uma ação, conforme o layout do jogador: `of_action()`, `of_event()`; `format()` insere nomes em textos por tokens como `{sprint}` |
| `action_texts.gd` | `ActionTexts` (Node) | Preenche os tokens nos textos dos controles sob seu pai, novamente ao mudar o idioma ou chamar `refresh()` |

Nenhum outro addon é necessário.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/ui_screens/`.
2. Adicione um `CanvasLayer` com `ui_root.gd` à cena principal. Ele roda com o jogo pausado.
3. Faça de cada janela uma cena cuja raiz estende `UiScreen`. Uma janela nunca fecha a si mesma: ela chama
   `request_close()` e o `UiRoot` a fecha.
4. Abra janelas com `UiRoot.open(scene)`. Para abrir uma por uma tecla, defina `settings_screen` como a cena dela e
   adicione a ação de entrada `toggle_settings` (ou defina `settings_action`). Sem ela, `UiRoot` informa a falta
   uma vez na inicialização e a tecla não funciona. Esc usa o `ui_cancel` embutido.
5. Opcional: adicione `fps_counter.tscn` ao seu HUD.
6. Opcional: use tokens de ação nos textos, como `{jump} — jump`, e adicione um nó `ActionTexts` à cena (ele atende
   aos controles sob seu pai). Após mudar os vínculos das teclas, chame
   `get_tree().call_group(ActionTexts.GROUP, &"refresh")`. Controles que compõem seu próprio texto podem implementar
   `refresh()` e entrar no mesmo grupo. Para nomear botões do mouse, “Space” e ações sem vínculo em outros idiomas,
   inclua nas traduções as entradas de `InputNames.get_mouse_names()`, “Space”, `InputNames.UNBOUND`,
   `InputNames.LEFT_KEY` e `InputNames.RIGHT_KEY`. As duas últimas preservam `%s` para o nome da tecla.

`UiRoot` pausa apenas um jogo em execução e encerra somente a própria pausa: se o jogo já estava pausado ao abrir
uma janela (por exemplo, durante troca de nível), continua sob controle de quem o pausou. Se essa pausa acabar,
o jogo volta a rodar por trás da janela.

A aparência vem do tema do projeto; `FpsCounter` usa a variação de tipo de tema `FpsCounter`.

## Documentação

No repositório do modelo: `docs/pt_BR/systems/ui.md` e, para janelas durante troca de nível,
`docs/pt_BR/systems/levels.md`.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
