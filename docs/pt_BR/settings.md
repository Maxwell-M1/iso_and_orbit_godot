<!-- translation of docs/en/settings.md @ 262d20fd6cef -->
# Configurações

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/settings.md).
> Onde houver diferenças, a versão em inglês é a correta.

F10 abre a janela de configurações e pausa o jogo; Esc ou F10 a fecha. As alterações se aplicam na hora (a escala
da interface arrastada pelo mouse espera até soltar o botão) e são salvas em
`user://settings.cfg` quando a janela fecha e quando o jogo é encerrado. **Redefinir tudo** volta todas as
configurações ao padrão.

Os padrões estão em `DEFAULTS` em `gdscript/settings/game_settings.gd`. A demo os aplica às propriedades dos nós em
`gdscript/demo/settings_applier.gd`; os padrões das propriedades dos próprios componentes podem ser diferentes, como
indicado abaixo. Como o sistema de configurações funciona e como adicionar uma configuração:
[UI](systems/ui.md#configurações).

Para o herói copiado sem a demo, use [Configurações](configurations.md) para localizar as propriedades no Inspector
e escolher uma combinação coerente. Esta página descreve o **menu da demo**. Os rótulos usam vínculos originais;
o menu em execução substitui as teclas pelas vinculadas em `InputMap`.

## Controles

| Configuração | Chave | Padrão | Aplicada a |
|---|---|---|---|
| **BEM segurado**: Direto ao cursor / Ao ponto por um caminho | `gameplay/hold_mode` | Direto ao cursor | `PointClickMoveInput.hold_mode` |
| **BDM + WASD**: Desligado / Lateral / Virar | `gameplay/camera_keys_mode` | Virar | `PointClickMoveInput.keys_with_camera` (padrão do componente: lateral); desligar oculta também a linha da dica |
| **BEM + BDM + A/D**: Desligado / Lateral / Diagonal | `gameplay/camera_steer_keys_mode` | Diagonal | `PointClickMoveInput.keys_with_camera_steer` (padrão do componente: lateral); desligar oculta a linha da dica |
| **Recuo (S) mais lento em** 0…80%, só no modo lateral | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − valor / 100 |
| **Ocultar o cursor ao correr segurando o BEM** | `gameplay/hide_cursor_on_hold` | ligado | `PointClickMoveInput.hide_cursor_while_held` |
| **BDM durante a corrida com BEM só gira a câmera** | `gameplay/look_around` | ligado | `PointClickMoveInput.look_around_while_held`; também oculta a linha correspondente da dica |

## Personagem

| Configuração | Chave | Padrão | Aplicada a |
|---|---|---|---|
| **Aparência do herói**: uma de dez | `character/look` | 8 · Necromante | `CharacterAppearance.set_look()` |
| **Flutuar acima do chão** | `character/hover` | desligado | `CharacterHover.enabled` em `Hero/Character/Visual/Hover` (padrão do componente: ligado; `player.tscn` desliga); durante a flutuação, suprime passos e retarda a queda (`player_floating_fall.tres`) |
| **Não cair de bordas** | `gameplay/ledge_guard` | ligado | `LedgeGuard.enabled` |
| **Pulo (Espaço)** | `character/jump` | ligado | `GroundCharacter.can_jump`; também oculta a linha da dica |
| **Altura do pulo** 0,5…1,5 m | `character/jump_height` | 1,0 m | `GroundCharacter.jump_height` |
| **Corrida rápida (Shift)** | `character/sprint` | ligado | `GroundCharacter.can_sprint`; também oculta a linha da dica |
| **Shift**: Segurar / Apertar: liga, de novo: desliga | `character/sprint_mode` | Segurar | `CharacterActionInput.sprint_mode` |
| **Bônus de velocidade** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + valor / 100 |
| **Cansaço na corrida rápida** | `character/fatigue` | ligado | `GroundCharacter.sprint_tires` |
| **Fôlego dura** 3…10 s | `character/sprint_duration` | 5,0 s | `GroundCharacter.sprint_duration` |

A proteção de bordas usa a chave salva `gameplay/ledge_guard`, embora fique na aba Personagem.

## Câmera

| Configuração | Chave | Padrão | Aplicada a |
|---|---|---|---|
| **BDM inclina a câmera na vertical** | `camera/mouse_pitch` | desligado | `OrbitCameraRig.mouse_pitch` |
| **Virar a câmera para seguir a corrida** | `camera/follow` | desligado | `OrbitCameraRig.follow_movement` |
| **Virar em** 0…10 s (“imediato” em 0) | `camera/follow_time` | 1.1 s | `OrbitCameraRig.follow_time` (padrão do componente: 1.5 s) |
| **Exceto ao correr em direção à câmera** | `camera/follow_except_toward` | ligado | `OrbitCameraRig.follow_toward_camera_angle`: desligado define 0 e permite seguir qualquer corrida, até diretamente rumo à câmera |
| **Ângulo** 5…60° | `camera/follow_except_toward_angle` | 30° | `OrbitCameraRig.follow_toward_camera_angle` = valor quando a exceção está ativa (padrão do componente também 30°) |
| **Alinhar a inclinação da câmera na corrida** | `camera/align_pitch` | desligado | `OrbitCameraRig.follow_pitch` |
| **Inclinação para baixo** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −valor (padrão do componente: −40°) |
| **Alinhar a inclinação em** 0…10 s (“imediato” em 0) | `camera/align_pitch_time` | 1.1 s | `OrbitCameraRig.follow_pitch_time` (padrão do componente: 1.5 s) |
| **Alinhar a altura da câmera na corrida** | `camera/align_height` | desligado | `OrbitCameraRig.follow_zoom` |
| **Altura** 0…100% | `camera/align_height_level` | 55% | `OrbitCameraRig.follow_zoom_level` = valor / 100: 0% é câmera totalmente abaixada, 100% totalmente elevada |
| **Alinhar a altura em** 0…10 s (“imediato” em 0) | `camera/align_height_time` | 1.5 s | `OrbitCameraRig.follow_zoom_time` |
| **O cursor mantém a mira enquanto a câmera gira** | `camera/keep_aim` | ligado | `PointClickMoveInput.keep_aim_on_camera_turn` |
| **A câmera para em obstáculos atrás dela** | `camera/keep_out_of_geometry` | ligado | `CameraArm.keep_out_of_geometry` |
| **Aproximar se o personagem for encoberto** | `camera/pull_in_on_occlusion` | desligado | `CameraArm.pull_in_on_occlusion` |

## Exibição

| Configuração | Chave | Padrão | Aplicada a |
|---|---|---|---|
| **Tela cheia** | `display/fullscreen` | desligado | `DisplayServer.window_set_mode()` |
| **Limite de FPS**: 24, 30, 60, 120, 240, Sem limite | `display/max_fps` | Sem limite | `Engine.max_fps` |
| **Sincronização vertical (V-Sync)** | `display/vsync` | desligado | `DisplayServer.window_set_vsync_mode()` |
| **Interpolação de física (personagem e câmera)** | `display/physics_interpolation` | ligado | `SceneTree.physics_interpolation` |
| **Contorno da silhueta atrás de obstáculos** | `display/silhouette_outline` | ligado | `OccludedSilhouette.outline_enabled` |

A tela cheia não funciona enquanto o jogo roda dentro do editor, na aba Jogo (Game) ou na janela flutuante dela (**Make
Game Workspace Floating on Next Play**): a janela pertence ao editor, então lá a chave fica desativada. Para testá-la
pelo editor, desligue **Embed Game on Next Play** no menu da aba Jogo: o jogo então abre na própria janela.

Com V-Sync nunca há mais quadros que a taxa de atualização do monitor, então um limite de FPS igual ou acima dessa taxa
nem é aplicado: ele brigaria com o V-Sync e daria menos quadros do que o monitor mostra (um limite de 240 num monitor
de 240 Hz dava cerca de 220).

Sem interpolação de física, o personagem e a câmera se movem aos saltos, tick a tick (60 por segundo): a câmera segue o
`get_global_transform_interpolated()` do alvo, que sem interpolação é simplesmente a posição dele no último tick. Num
monitor acima de 60 Hz isso aparece, e com a câmera seguindo a corrida o personagem também balança nas curvas: a câmera
gira a cada quadro, o personagem só a cada tick.

## Interface

| Configuração | Chave | Padrão | Aplicada a |
|---|---|---|---|
| **Idioma**: English, Español, 日本語, Português (Brasil), Русский, Türkçe, 简体中文 | `interface/language` | English | `TranslationServer.set_locale()` |
| **Escala da interface** 50…100% | `interface/ui_scale` | 75% | `content_scale_factor` da janela raiz |
| **Contador de FPS** | `interface/fps_counter` | ligado | Visibilidade de `Hud/FpsCounter` |
| **Dica de controles e velocidade** | `interface/help` | ligado | Visibilidade de `Hud/Panel` |
| **Linha do caminho do personagem** | `interface/path_line` | desligado | Visibilidade de `Hero/PathView` |
| **Estado do personagem e eventos** | `interface/character_state` | desligado | Visibilidade de `Hud/CharacterState` (`CharacterMonitor`) |

A escala da interface muda dica, contador de FPS, barra de fôlego, painel do estado do personagem, mensagem
“Descoberto: …”, oferta de viagem, tela de carregamento e janelas, mas não a visão 3D. 100% é o tamanho definido
nas cenas. Ao arrastar o controle com o mouse, aplica-se a escala só ao soltar, para ele não se afastar do cursor;
teclado e roda a aplicam imediatamente.

## Som

| Configuração | Chave | Padrão | Aplicada a |
|---|---|---|---|
| **Volume** 0…100% ("mudo" em 0) | `sound/volume` | 100% | Volume do barramento `Master`; 0 o silencia |
| **Passos** | `sound/footsteps` | ligado | `CharacterSounds.footsteps_enabled` |
| **Pulo e aterrissagem** | `sound/jump` | ligado | `CharacterSounds.jump_enabled` |
| **Arranque e corrida rápida** | `sound/sprint` | desligado | `CharacterSounds.sprint_enabled` (padrão do componente: ligado) |

## Configurações dependentes

Controles que não fazem sentido sem outra configuração ficam esmaecidos e não podem ser alterados: a redução do recuo
sem o modo lateral para BDM + WASD, a altura do pulo sem o pulo, tudo sobre a corrida rápida sem a corrida rápida, a
duração do fôlego sem o cansaço, o tempo do giro sem o acompanhamento, ângulo e tempo da inclinação sem seu
alinhamento, altura e tempo sem alinhamento da altura e som dos passos enquanto o herói flutua (não há passos).

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
