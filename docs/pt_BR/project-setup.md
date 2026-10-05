<!-- translation of docs/en/project-setup.md @ e52ff77b332d -->
# Configuração do projeto

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/project-setup.md).
> Onde houver diferenças, a versão em inglês é a correta.

O que os componentes esperam do `project.godot` e da cena. Ao levar componentes para outro projeto, copie as partes
desta configuração que eles usam.

Para o herói montado, siga primeiro
[os passos de transferência](integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto).
Ele precisa de ações de movimento/câmera/corrida rápida/pulo, ajustes de navegação correspondentes e camadas de
colisão. Autoload, tema da interface, traduções, ajustes de exibição e sistema de níveis da demo são opcionais.

## Camadas de física

| Camada | Nome | O que fica nela | Quem a lê |
|---|---|---|---|
| 1 | `world` | Chão, paredes, objetos, montanha, NPCs parados | Raio do clique (`PointClickMoveInput.ground_mask`), corpo do jogador e `LedgeGuard` (cujo `floor_mask` 0 usa a máscara do corpo), `CameraArm.collision_mask`, geração da malha de navegação |
| 2 | `characters` | Corpo do jogador (`collision_layer = 2`) | Áreas `PointOfInterest` e `LevelPortal` (`collision_mask = 2`); braço da câmera ignora |
| 3 | `camera` | Corpos que só param a câmera, como `RoofCameraBlocker` em `shared/world/props/house.tscn` | Só `CameraArm.collision_mask` |
| 4 | `bounds` | Muros invisíveis na borda do nível, como `Edge` na ilha | Corpo do jogador (`collision_mask` = camadas 1 e 4), `LedgeGuard` e geração da malha quando necessário (como na ilha) |

`CameraArm.collision_mask` tem como padrão as camadas 1 e 3 (`0b101`). Personagens na camada 2 nunca empurram a
câmera. Um corpo na camada 3 para a câmera, mas é invisível para cliques, navegação e personagens, então você pode
manter a câmera fora de um telhado sem deixar ninguém traçar caminho até ele. Um corpo na camada 4 faz o inverso:
para o personagem, mas cliques e câmera o atravessam; clicar no chão ou água atrás do muro não acerta o muro.

A camada de navegação 1 se chama `ground`; `NavigationMover.navigation_layers` a usa por padrão.
Camadas de física e navegação são separadas: a camada física do colisor define quais raios e corpos o atingem;
as camadas de navegação da região definem os caminhos consultáveis. No código, máscaras são campos de bits:
camadas 1 e 4 são `1 | 8 = 9`; camadas 1 e 3, `1 | 4 = 5`. No Inspector, marque os números.

## Ações de entrada

| Ação | Padrão | Usada por |
|---|---|---|
| `move_to_cursor` | Botão esquerdo do mouse | `PointClickMoveInput.move_action` |
| `camera_rotate` | Botão direito do mouse | `OrbitCameraRig.rotate_action`, `PointClickMoveInput.camera_steer_action` |
| `camera_zoom_in` | Roda para cima | `OrbitCameraRig.zoom_in_action` |
| `camera_zoom_out` | Roda para baixo | `OrbitCameraRig.zoom_out_action` |
| `move_forward`, `move_back`, `move_left`, `move_right` | W, S, A, D | `PointClickMoveInput`, com o botão direito segurado |
| `sprint` | Shift | `CharacterActionInput.sprint_action` |
| `jump` | Espaço | `CharacterActionInput.jump_action` |
| `toggle_settings` | F10 | `UiRoot.settings_action` |
| `interact` | E | `TravelPrompt.action`: confirma a oferta de viagem na plataforma (demo) |
| `ui_cancel` | Esc (embutida) | `UiRoot`: fecha a janela do topo |

Adicione as ações em **Project → Project Settings → Input Map**, usando eventos físicos para as letras. O herói
independente precisa das primeiras sete linhas (dez ações); `toggle_settings`, `interact` e `ui_cancel` pertencem
à interface e viagem opcionais. Você também pode juntar as entradas necessárias da seção `[input]` deste
`project.godot` ao seu; não substitua o arquivo inteiro do projeto.

As teclas são mapeadas pela posição física, então WASD fica no mesmo lugar em qualquer layout de teclado. Cada
componente recebe o nome da ação como propriedade exportada, então você pode usar suas próprias ações. Uma ação
ausente é informada uma vez no começo pelo componente que a usa (inclusive raiz da janela e oferta de viagem) e
não é lida depois: suas teclas nada fazem sem novos erros, e as outras teclas de movimento seguem funcionando.

HUD, configurações e dicas de carregamento obtêm os nomes dessas ações. Após alterar `InputMap` durante o jogo,
chame `get_tree().call_group(ActionTexts.GROUP, &"refresh")` se usar esses componentes de texto. A demo não tem
menu nem persistência para remapear teclas; veja
[nomes das teclas nos textos](systems/ui.md#nomes-das-teclas-nos-textos).

## Grupos

| Grupo | Significado |
|---|---|
| `player` | Corpo do jogador. `PointOfInterest` (`player_group`) e `LevelPortal` (`traveller_group`) reagem só a corpos deste grupo. Definido em `Character` de `playable_hero.tscn` |
| `camera_ignore` | Corpos que o braço da câmera atravessa (`CameraArm.ignored_groups`). Vale para tudo sob um nó do grupo, então defina-o uma vez na raiz da cena de um prop ou num nó de pasta do nível. A demo não o usa |
| `points_of_interest` | Adicionado pelo próprio `PointOfInterest`; `DiscoveryToast` e a cena principal encontram lugares por ele |
| `level_portals`, `spawn_points` | Adicionados por cada `LevelPortal` e `SpawnPoint`; `LevelHost` encontra os do nível por esses grupos |

## Autoload

`Settings` → `res://gdscript/settings/game_settings.gd`. Necessário só para a janela de configurações, seus controles e
`gdscript/demo/settings_applier.gd`. Os componentes funcionam sem ele. Veja [Configurações](settings.md).

## Outras configurações do projeto

| Configuração | Valor | Observações |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | A demo |
| `physics/3d/physics_engine` | Jolt Physics | Embutido na engine; o braço da câmera e os testes são verificados com ele |
| `navigation/3d/default_cell_height` | 0.025 | Igual à `cell_height` da malha. A demo usa células verticais finas para degraus; novos mapa e malha também devem coincidir. Veja [Mundo e navegação](systems/world-and-navigation.md) |
| `display/window/stretch/mode` | `canvas_items` | A configuração de escala da interface escala todo o 2D por `content_scale_factor` e deixa a visão 3D intacta |
| `display/window/stretch/aspect` | `expand` | Qualquer formato de janela |
| `gui/theme/custom` | `res://shared/ui/ui_theme.tres` | Aparência de todas as janelas e elementos do HUD |
| `internationalization/locale/translations` | `res://l10n/ui/*.po` | Traduções da interface; veja [UI](systems/ui.md) |
| `rendering/rendering_device/driver.windows` | `d3d12` | Direct3D 12 no Windows |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 5 (Ultra) | Sombras suaves; o sol em `world.tscn` também tem `shadow_blur = 1.25` e uma distância de sombra de 70 m |
| `rendering/anti_aliasing/quality/msaa_3d` | 2 (4×) | Antisserrilhamento por multiamostragem |

A física roda no padrão de 60 ticks por segundo. A interpolação de física está ligada no `project.godot`
(`physics/common/physics_interpolation`) e é alternada em tempo de execução por uma configuração (Configurações →
Exibição).

## Dados salvos

As configurações são salvas em `user://settings.cfg`, na pasta de dados do usuário do projeto (no editor: Projeto →
Abrir Pasta de Dados do Usuário, em inglês Project → Open User Data Folder). Apague o arquivo para voltar aos padrões,
ou use **Redefinir tudo** na janela de configurações.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
