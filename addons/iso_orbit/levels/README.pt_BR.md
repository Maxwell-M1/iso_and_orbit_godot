<!-- translation of addons/iso_orbit/levels/README.md @ 8dd533b32064 -->
<!-- translation of addons/iso_orbit/levels/README.md @ pending -->
# Níveis

[← Índice da documentação (repositório do modelo)](../../../docs/pt_BR/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md).
> Em caso de divergência, consulte a versão em inglês.

Níveis mudam atrás de uma tela de carregamento, enquanto o personagem do jogador e a interface permanecem: um host
carrega o próximo nível em segundo plano, libera o anterior e avisa ao jogo onde colocar o personagem; portais
levam a outros níveis após confirmação ou imediatamente; há pontos de entrada e uma tela de carregamento com o
último quadro do jogo desfocado atrás do nome do lugar, uma barra de progresso e dicas.

Parte do Iso & Orbit, modelo de câmera e controlador de personagem para Godot 4.7. Licença MIT (veja `LICENSE`).

## Conteúdo

| Arquivo | Classe | Função |
|---|---|---|
| `level_host.gd` | `LevelHost` (Node3D) | Mantém o nível atual; `change_level(path, spawn_name, title)` carrega o próximo em segundo plano, faz a troca e informa cada etapa por sinal; retransmite entradas e saídas dos portais, inclusive os adicionados depois, como `portal_entered` e `portal_exited` |
| `level_portal.gd` | `LevelPortal` (Area3D) | Passagem para outro nível: informa a entrada e saída de viajantes, viaja com `travel()` ou sozinho (`auto_travel`) e escreve `title` numa placa opcional |
| `spawn_point.gd` | `SpawnPoint` (Marker3D) | Onde o personagem aparece, identificado por nome; olha ao longo do eixo −Z do marcador |
| `loading_screen.gd`, `loading_screen.tscn`, `loading_background.gdshader`, `loading_screen_theme.tres` | `LoadingScreen` (CanvasLayer) | Tela durante a carga: último quadro desfocado e escurecido, aproximando-se lentamente, nome do lugar, barra que não retrocede e dicas; nenhum evento de entrada chega ao jogo enquanto aparece |

Nenhum outro addon é necessário: o host não conhece o personagem, a câmera ou a interface. Seu jogo os conecta aos
sinais dele.

## Configuração

1. Copie esta pasta para `res://addons/iso_orbit/levels/`.
2. Na cena principal (que permanece), adicione um `Node3D` com `level_host.gd` e coloque o nível inicial como seu
   único filho. O personagem, a câmera e a interface ficam ao lado do host, não dentro de um nível.
3. Adicione `loading_screen.tscn` à cena principal e atribua-a a `loading_screen` do host; deixe vazio se quiser
   trocar de nível sem uma tela.
4. Em cada nível, adicione um `Marker3D` com `spawn_point.gd`, cujo `spawn_name` seja `default`, no chão. Adicione
   outros pontos com nomes diferentes para as chegadas dos portais.
5. Para um portal, adicione um `Area3D` com `level_portal.gd` e uma forma de colisão. Seu `collision_mask` precisa
   incluir a camada do personagem. Defina `target_level` (arquivo de cena), `target_spawn` e `title`. Ponha o corpo
   do personagem no grupo `player` ou defina `traveller_group`.
6. Conecte os sinais do host no script principal:
   - `level_change_started`: oculte o que não deve aparecer na imagem da tela de carregamento e retire o controle;
   - `level_loaded(level, spawn)`: coloque o personagem em `spawn` (com `GroundCharacter.teleport()` ele chega sem
     tranco) e gire a câmera;
   - `level_change_finished`: devolva o controle;
   - `level_change_failed(path, error)`: devolva o controle e mostre o que foi ocultado; o nível atual permanece.
     Após falha de carregamento, só ocorre esse sinal, nunca `level_change_finished`;
   - `portal_entered(portal)` e `portal_exited(portal)`: mostre e oculte a oferta de viagem; ao confirmar, chame
     `portal.travel()`.

O host não anuncia o nível inicial: configure-o no `_ready()` do script principal com `get_current_level()` e
`find_spawn_point()`.

Por padrão, o portal pede confirmação: o jogo mostra uma oferta e chama `travel()`. Com `auto_travel` ativo, ele
viaja assim que o personagem entra, como uma porta ou a borda de um mapa. A mudança começa logo após o pedido,
fora dele, portanto um portal pode pedi-la num callback de física. O jogo fica pausado durante carga e troca. O
host espera, ainda em pausa, o mapa de navegação receber o novo nível; então encerra a pausa e desenha alguns
quadros atrás da tela antes de ocultá-la, compilando shaders fora de vista. Ajustes do host: `min_loading_time`
(0.6 s, tempo mínimo da tela), `warmup_frames` (3 quadros atrás dela) e `navigation_timeout` (2 s de espera máxima
pelo mapa); `is_changing()` informa se há mudança em curso. `change_level()` retorna `ERR_BUSY` durante uma mudança,
`ERR_FILE_NOT_FOUND` e `ERR_INVALID_PARAMETER` para um arquivo incorreto. Falha posterior de carregamento mantém o
nível atual e emite `level_change_failed`; a próxima tentativa carrega o arquivo novamente. O host encerra apenas
a pausa que iniciou: abra uma janela que pausa o jogo após `level_change_finished`. Tela e esperas usam tempo real,
qualquer que seja `Engine.time_scale`.

A aparência da tela está em `loading_screen_theme.tres` (variações de tipo `LoadingTitle`, `LoadingBar` e
`LoadingTip`). Atribua outro tema à raiz para mudar a aparência ou copie `loading_screen.tscn` para criar sua tela:
o script precisa dos nós `Root` e, por nome único, `Background`, `Title`, `Bar` e `Tip`. Não há dicas até você
adicioná-las em `tips`; cada dica é traduzida e depois passada por `tip_format`, se configurado no código
(`InputNames.format` do addon `ui_screens` insere as teclas vinculadas: `{sprint}` mostra “Shift”).

## Documentação

No repositório do modelo: `docs/pt_BR/systems/levels.md` e `docs/pt_BR/integration.md`.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
