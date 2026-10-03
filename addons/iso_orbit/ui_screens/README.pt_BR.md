<!-- translation of addons/iso_orbit/ui_screens/README.md @ b7618a65d4df -->
# Telas de UI

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Janelas sobre o jogo em forma de pilha: abra uma sobre a outra, feche a do topo com Esc, pause o jogo e mostre o cursor
do mouse enquanto qualquer janela estiver aberta, dê o foco do teclado à janela e devolva-o quando ela fechar. Além
disso, um contador de FPS que continua funcionando com o jogo pausado.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `ui_root.gd` | `UiRoot` (CanvasLayer) | A pilha de janelas: `open()`, `close_top()`, `toggle()`; pausa, cursor, foco |
| `ui_screen.gd` | `UiScreen` (Control) | Base de uma janela: `initial_focus`, o sinal `close_requested` |
| `fps_counter.gd`, `fps_counter.tscn` | `FpsCounter` (Label) | Quadros por segundo, também com o jogo pausado |

Nenhum outro addon é necessário.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/ui_screens/`.
2. Adicione um `CanvasLayer` com `ui_root.gd` à cena principal. Ele roda com o jogo pausado.
3. Faça de cada janela uma cena cuja raiz estende `UiScreen`. Uma janela nunca fecha a si mesma: ela chama
   `request_close()` e o `UiRoot` a fecha.
4. Abra janelas com `UiRoot.open(scene)`. Para abrir uma por uma tecla, defina `settings_screen` como a cena dela e
   adicione a ação de entrada `toggle_settings` (ou defina `settings_action`). Esc é o `ui_cancel` embutido.
5. Opcional: adicione `fps_counter.tscn` ao seu HUD.

A aparência vem do tema do projeto; `FpsCounter` usa a variação de tipo de tema `FpsCounter`.

## Documentação

No repositório do template: `docs/pt_BR/systems/ui.md`.

---

*Esta página corresponde ao Iso & Orbit 1.0.0.*
