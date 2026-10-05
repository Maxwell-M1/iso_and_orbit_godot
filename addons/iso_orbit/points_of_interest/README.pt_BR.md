<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 70ad45747177 -->
# Pontos de interesse

[← Índice da documentação (repositório do template)](../../../docs/pt_BR/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Locais para descobrir: uma área que avisa na primeira vez que o jogador entra nela, e uma mensagem na tela
"Descoberto: …" que encontra todos os locais sozinha.

Parte do Iso & Orbit, um template de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest` (Area3D) | Emite `discovered(title)` na primeira entrada de um corpo do grupo `player`; entra no grupo `points_of_interest`; `is_discovered()` informa se já foi encontrado; `mark_discovered()` marca sem emitir sinal (ao recarregar nível ou jogo salvo) |
| `discovery_toast.gd`, `discovery_toast.tscn` | `DiscoveryToast` (Label) | Mostra “Descoberto: …” por alguns segundos, inclusive para lugar num nível carregado depois (`watch_added_places`; desligado: só os presentes na inicialização) |

Nenhum outro addon é necessário.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/points_of_interest/`.
2. Coloque o corpo do jogador no grupo `player` (ou defina `player_group`).
3. Para cada local, adicione um `Area3D` com `point_of_interest.gd` e uma forma de colisão, defina o `title` dele e faça
   a `collision_mask` dele incluir a camada de física do jogador.
4. Adicione `discovery_toast.tscn` ao HUD. Ele se conecta aos lugares presentes ao iniciar e aos adicionados
   depois, salvo se `watch_added_places` estiver desligado; nenhuma ligação manual é necessária.

Um lugar se lembra da descoberta apenas enquanto existe: quando seu nível é liberado, ele desaparece, e outra
instância do mesmo nível começa sem descobertas. Cabe ao jogo guardar isso: `gdscript/main.gd` do modelo registra
os lugares por nível e chama `mark_discovered()` ao carregá-lo outra vez.

O texto da mensagem e os títulos passam pelo servidor de tradução, então podem ser localizados. A aparência vem da
variação de tipo de tema `DiscoveryToast`.

## Documentação

No repositório do modelo: `docs/pt_BR/systems/world-and-navigation.md`, `docs/pt_BR/systems/ui.md` e
`docs/pt_BR/systems/levels.md`.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
