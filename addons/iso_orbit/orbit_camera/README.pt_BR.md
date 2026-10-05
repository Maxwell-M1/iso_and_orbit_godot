<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 94f2d396a032 -->
<!-- translation of addons/iso_orbit/orbit_camera/README.md @ pending -->
# Câmera orbital

[← Índice da documentação (repositório do modelo)](../../../docs/pt_BR/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md).
> Em caso de divergência, consulte a versão em inglês.

Uma câmera orbital para jogos isométricos e vistos de cima. Ela acompanha qualquer `Node3D`, gira com o mouse e
usa a roda para zoom. Durante a corrida, pode girar para trás do alvo, alinhar a inclinação e voltar a um zoom
escolhido, independentemente. Seu braço impede que a câmera entre em paredes e pode aproximá-la quando um
obstáculo esconde o alvo.

Parte do Iso & Orbit para Godot 4.7. Licença MIT (veja `LICENSE`). Sozinha, esta pasta dispensa outros addons.

| Script | Classe | Função |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig` (`Node3D`) | Acompanhamento do alvo, entrada, zoom e alinhamento opcional durante a corrida |
| `camera_arm.gd` | `CameraArm` (`Node3D`) | Posicionamento da câmera, resposta a obstáculos e transparência opcional de perto |

## Adicionando à cena

1. Copie a pasta para `res://addons/iso_orbit/orbit_camera/`.
2. Em **Project Settings → Input Map**, crie `camera_rotate` (botão direito), `camera_zoom_in` (roda para cima) e
   `camera_zoom_out` (roda para baixo). Você pode mudar os nomes das ações nas propriedades exportadas do rig. Uma
   ação ausente gera erro ao iniciar e não dispara entrada.
3. Adicione estes nós ao lado do alvo em movimento. Atribua `CameraRig.target` ao personagem ou a outro `Node3D`.
   Não aplique escala à árvore da câmera nem a seus ancestrais.

   ```text
   Scene
   ├── Character (alvo em movimento)
   └── CameraRig (Node3D + orbit_camera_rig.gd; target = ../Character)
       └── CameraArm (Node3D + camera_arm.gd)
           └── Camera3D (Current = on)
   ```

   Rig e braço encontram, respectivamente, seus primeiros filhos diretos `CameraArm` e `Camera3D`; também é
   possível definir as referências exportadas `arm` e `camera`. Deixe a transformação local de `Camera3D` no
   padrão: o braço a posiciona. Ative a câmera se ela for a visão atual. Para o enquadramento do modelo, use campo
   de visão de 45° e plano distante de 300 unidades do mundo.
4. Ponha a colisão sólida do mundo na camada de física 1. O `collision_mask` padrão do braço inclui as camadas 1
   e 3 (`0b101`); a 3 pode conter bloqueios só da câmera, como tetos. Deixe personagens fora dessa máscara para
   não empurrarem a câmera. Ponha `camera_ignore` num corpo ou ancestral para excluí-lo. Opcionalmente, defina
   `CameraArm.fade_target` como a raiz de um modelo para torná-lo translúcido com o braço muito curto.
5. Se o alvo se mover em ticks de física, ative **Project Settings → Physics → Common → Physics Interpolation**.
   O rig segue a posição interpolada a cada quadro renderizado e desativa sua própria interpolação. Braço e câmera
   herdam esse modo por padrão.

Os padrões do script dão órbita manual: os três controles de alinhamento durante a corrida estão desligados, embora
seus tempos e destinos tenham valores. Para o acompanhamento opcional ajustado no herói do modelo, use
`follow_time = 1.1` s, `follow_pitch_angle = -22°`, `follow_pitch_time = 1.1` s,
`follow_zoom_level = 0.55`, `follow_zoom_time = 1.5` s, `follow_wait_after_rotate = true` e
`height_follow_time = 0.15` s. Ative `follow_movement` para girar atrás da corrida; ative `follow_pitch` e/ou
`follow_zoom` somente se quiser esses alinhamentos. O herói do modelo deixa os três desligados inicialmente. No
Inspector, informe os ângulos em graus; em GDScript, atribua radianos com `deg_to_rad()`.

Com `follow_wait_after_rotate` ativo, o acompanhamento fica em espera após girar a câmera de propósito com o mouse,
até o alvo diminuir a velocidade ou começar outra corrida. Se a entrada iniciar nova corrida antes de o alvo parar,
chame `end_follow_wait()`. O modelo conecta `PointClickMoveInput.run_requested` a esse método e
`hold_pending_changed` a `set_follow_paused()` em `gdscript/player/playable_hero.tscn`. Se o alvo se move sem parar
e não pode informar o início de outra corrida, desligue essa espera. Mantenha `sharp_turn_speed` na metade da
velocidade de giro do personagem ou menos, para uma inversão não puxar a câmera por direções intermediárias; o
modelo combina 360°/s com os 720°/s do herói.

Sem braço, um `Camera3D` filho direto do rig também funciona. Ele permanece à distância do zoom e pode atravessar
paredes; resposta a obstáculos e transparência exigem `CameraArm`.

Para curva de zoom, propriedades, ocultação e interações testadas, veja
[Câmera](../../../docs/pt_BR/systems/camera.md). Para transferir o herói pronto, veja
[Integração](../../../docs/pt_BR/integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto) e
[Configuração do projeto](../../../docs/pt_BR/project-setup.md).

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
