<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 6dce2786aac6 -->
# Pontos de interesse

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Locais para descobrir: uma área que avisa na primeira vez que o jogador entra nela, e uma mensagem na tela
"Descoberto: …" que encontra todos os locais sozinha.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest` (Area3D) | Emite `discovered(title)` na primeira vez que um corpo do grupo `player` entra; entra no grupo `points_of_interest` |
| `discovery_toast.gd`, `discovery_toast.tscn` | `DiscoveryToast` (Label) | Mostra "Descoberto: …" por alguns segundos quando qualquer local é descoberto |

Nenhum outro addon é necessário.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/points_of_interest/`.
2. Coloque o corpo do jogador no grupo `player` (ou defina `player_group`).
3. Para cada local, adicione um `Area3D` com `point_of_interest.gd` e uma forma de colisão, defina o `title` dele e faça
   a `collision_mask` dele incluir a camada de física do jogador.
4. Adicione `discovery_toast.tscn` ao seu HUD. Ele se conecta a todos os locais da cena na inicialização; não é preciso
   ligar nada.

O texto da mensagem e os títulos passam pelo servidor de tradução, então podem ser localizados. A aparência vem da
variação de tipo de tema `DiscoveryToast`.

## Documentação

No repositório do template: `docs/pt_BR/systems/world-and-navigation.md` e `docs/pt_BR/systems/ui.md`.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
