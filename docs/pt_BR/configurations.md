<!-- translation of docs/en/configurations.md @ 2173d5158953 -->
<!-- translation of docs/en/configurations.md @ pending -->
# Configurando o herói jogável

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/configurations.md).
> Em caso de divergência, consulte a versão em inglês.

Comece por `gdscript/player/playable_hero.tscn` depois de seguir o [guia de transferência](integration.md). As três
configurações abaixo mantêm o tamanho do personagem, o recurso de movimento e os ajustes de colisão da câmera
fornecidos. Elas mudam como você controla e vê o herói, sem introduzir valores arbitrários de velocidade ou suavização.

| Configuração | Quando usar | Principal contrapartida |
|---|---|---|
| [Padrão: órbita manual](#padrão-órbita-manual) | Visão estável da área, com movimento por clique e controle direto | O jogador escolhe a direção da câmera |
| [Movimento pelo mouse com caminhos](#movimento-pelo-mouse-com-caminhos) | Contornar obstáculos da malha de navegação enquanto segura o mouse | Perto de rampas e alturas sobrepostas, o caminho pode mudar |
| [Exploração com câmera que acompanha](#exploração-com-câmera-que-acompanha) | Trajetos longos em que a câmera deve voltar para trás do personagem | A visão gira conforme o percurso muda |

## Onde alterar cada ajuste

Os valores vêm de três fontes. Confira qual delas você está alterando:

| Fonte | Quando se aplica | Exemplo |
|---|---|---|
| Padrões do script | Componente recém-adicionado, sem substituição na cena | `PointClickMoveInput.keys_with_camera` começa como `SIDESTEP` |
| Cena ou recurso salvo | Instância da cena fornecida | `playable_hero.tscn` seleciona `TURN`; sua câmera usa 1.1 s para acompanhar |
| Configurações da demo | `SettingsApplier` roda na inicialização e quando um ajuste do menu muda | `user://settings.cfg` pode ativar o acompanhamento da câmera mesmo que ele esteja desativado na cena |

Na demo, use **Configurações → Redefinir tudo** antes de comparar configurações. As alterações feitas no menu são
salvas; alterações na cena em execução pelo inspetor **Remote** são temporárias. Para um herói independente, edite as
cenas copiadas ou crie uma cena herdada de `playable_hero.tscn` e salve cada variante separadamente. Ative **Editable
Children** nas instâncias de cena para acessar os nós internos. Só copie `SettingsApplier` se quiser que ele controle
esses valores.

Os caminhos abaixo são relativos à instância do herói:

| O que ajustar | Nó ou recurso |
|---|---|
| Clique, botão segurado, teclas e cursor | `PlayerInput` (`PointClickMoveInput`) |
| Modo da tecla de corrida rápida e entrada do pulo | `PlayerActionInput` (`CharacterActionInput`) |
| Velocidade, aceleração, frenagem e velocidade de giro | `Character/NavigationMover` → `settings`, normalmente `player_locomotion.tres` |
| Pulo, gravidade, degraus e gasto de fôlego | `Character` (`GroundCharacter`) |
| Proteção contra quedas / recuperação do fôlego | `Character/LedgeGuard` / `Character/Stamina` |
| Órbita, acompanhamento, inclinação e zoom | `CameraRig` (`OrbitCameraRig`) |
| Obstáculos da câmera e transparência | `CameraRig/CameraArm` (`CameraArm`) |
| Modelo flutuante | `Character/Visual/Hover` (`CharacterHover`) |

Os ângulos do rig e a velocidade de giro do recurso de movimento aparecem em **graus no Inspector**, mas atribuições
em GDScript usam **radianos** (`deg_to_rad(30.0)`). `Camera3D.fov` é diferente: usa graus também no código. A
inclinação da câmera para baixo é negativa. O controle **Inclinação para baixo** da demo usa graus positivos, e
**Altura** usa porcentagem: 55% no menu significa `follow_zoom_level = 0.55`, não altura em metros.

## Padrão: órbita manual

É a configuração da cena fornecida e da demo após **Redefinir tudo**. Você pode clicar para contornar obstáculos,
segurar o botão esquerdo para controlar a direção diretamente ou usar o botão direito com WASD para se mover em
relação à câmera. A câmera acompanha a posição do corpo, mas não gira automaticamente para trás da corrida.

| Parte | Valores a manter |
|---|---|
| Recurso de movimento | `max_speed = 5.5`, `sprint_speed_multiplier = 1.5`, `acceleration_time = 0.18`, `stop_time = 0.22`, `turn_speed = 720°/s` |
| Personagem | `jump_height = 1.0`, `gravity_scale = 3.0`, `max_step_height = 0.3`, `sprint_tires = true`, `sprint_duration = 5.0` |
| Entrada | `hold_mode = STEER`, `hold_delay = 0.2`, ambos os modos de teclas em `TURN`, `look_around_while_held = true`, `keep_aim_on_camera_turn = true` |
| Câmera | `follow_movement = false`, `follow_pitch = false`, `follow_zoom = false`, `mouse_pitch = false`; a suavização da altura do alvo continua ativa com `height_follow_time = 0.15 s` |
| Visão inicial | `start_yaw = 45°`, `start_zoom = 0.55`, campo de visão da câmera de 45° |
| Braço da câmera | `keep_out_of_geometry = true`, `pull_in_on_occlusion = false`, camadas de colisão 1 e 3 |

Mantenha a proteção contra bordas ativada e o `Visual` fornecido como alvo de transparência do braço da câmera.
Atrás de uma parede, a silhueta mantém o herói visível; o braço impede que a câmera atravesse a geometria. São
funções diferentes.

**Confira:** clique além de uma parede que tenha um caminho ao redor, segure o mouse apontando para a parede e
depois gire a câmera enquanto se move. O clique deve seguir o caminho; com o botão segurado, o herói deve deslizar
ou parar na colisão. Olhar em volta deve preservar a direção da corrida. Teste separadamente um degrau de 0.2 m e
um pulo antes de alterar os valores de movimento.

## Movimento pelo mouse com caminhos

Parta da configuração padrão. Altere estas propriedades em `PlayerInput`:

| Propriedade | Valor | Efeito |
|---|---|---|
| `hold_mode` | `FOLLOW_POINT` | O botão do mouse segurado atualiza um destino de navegação em vez de controlar a direção em linha reta |
| `stop_on_release` | `true` | Soltar o botão durante a corrida freia o personagem onde ele está |
| `keys_with_camera` | `OFF` | Desativa botão direito + WASD |
| `keys_with_camera_steer` | `OFF` | Desativa o controle de direção por A/D com os dois botões do mouse segurados |

Mantenha desligadas as três opções de acompanhamento da câmera: assim, a direção da câmera continua sob controle
manual. O recurso de movimento padrão já acelera e para rapidamente; este estilo de entrada não exige mudar a
velocidade.

Cliques curtos ainda levam a corrida até o fim. `stop_on_release` afeta **apenas o botão segurado** e não aparece no
menu da demo; defina-o na cena ou no código. Desativar os dois modos de teclas **não** desativa o movimento com os
dois botões: apertar o direito e depois o esquerdo ainda faz o herói correr em linha reta na direção da câmera, sem
um caminho de navegação.

Use esta configuração em níveis com malha de navegação bem gerada e chão geralmente inequívoco sob o cursor. Perto
de uma rampa ou plataforma, o raio pode selecionar outra altura e reconstruir o caminho. Para controle direto e
preciso nesse terreno, use o modo padrão `STEER`. Um caminho vazio não significa, com segurança, «não se mover»
neste controlador; examine a malha de navegação se o herói seguir direto para um obstáculo.

**Confira:** mantenha o botão pressionado do outro lado de uma parede, mova o cursor para outro ponto alcançável e
solte o botão no meio do trajeto. O herói deve contornar a parede, mudar de destino e frear ao soltar. Depois, faça
um clique curto e confira que ele continua até o destino.

## Exploração com câmera que acompanha

Parta dos modos padrão `STEER` e `TURN`. Ative estas propriedades em `CameraRig`:

| Propriedade | Valor | Motivo |
|---|---|---|
| `follow_movement` | `true` | Gira para trás do herói ao correr após um clique ou o cursor |
| `follow_time` | 1.1 s | Tempo de giro ajustado na cena fornecida; aproxima-se suavemente da nova direção |
| `follow_toward_camera_angle` | 30° | Correr quase diretamente em direção à câmera não faz a visão dar a volta |
| `sharp_turn_speed` | 360°/s | Metade da velocidade de giro de 720°/s do personagem fornecido; evita seguir direções intermediárias numa meia-volta |
| `follow_wait_after_rotate` | `true` | Mantém a visão escolhida manualmente até parar ou começar uma nova corrida |
| `follow_pitch` / `follow_pitch_angle` / `follow_pitch_time` | `true` / −22° / 1.1 s | Volta a uma visão pouco inclinada do caminho à frente |
| `follow_zoom` / `follow_zoom_level` / `follow_zoom_time` | `true` / 0.55 / 1.5 s | Volta ao zoom inicial fornecido durante o movimento |

Os ângulos, o zoom e os tempos vêm da cena fornecida e das configurações da demo. O giro, o alinhamento da
inclinação e o do zoom são independentes. Se o jogador deve manter o zoom escolhido com a roda do mouse, deixe
`follow_zoom` desligado; desligue também `follow_pitch` se a roda deve continuar controlando a inclinação da forma
habitual.

Na demo, são os controles **Virar a câmera para seguir a corrida**, **Alinhar a inclinação da câmera na corrida** e
**Alinhar a altura da câmera na corrida** da aba **Câmera**. Seus valores de destino padrão já correspondem à tabela.

Girar com o botão direito tem prioridade sobre o acompanhamento automático. Como WASD exige esse botão, a câmera
não gira automaticamente para trás do movimento com botão direito + WASD. Depois de girá-la, apenas soltar o botão
direito não encerra a espera: pare, clique em outro destino ou comece a segurar o botão de novo. Mantenha a conexão
`run_requested → end_follow_wait` da cena e `keep_aim_on_camera_turn = true`; do contrário, o acompanhamento pode
continuar esperando ou o movimento da câmera pode desviar o cursor enquanto o botão fica pressionado.

**Confira:** corra atravessando a visão, vire 90° e depois inverta o sentido em direção à câmera. No primeiro giro,
a câmera deve acompanhar o trajeto por trás; na inversão, não deve dar uma volta brusca. Gire-a manualmente durante
a corrida e solte o botão direito: a visão escolhida deve ficar até a parada ou uma nova corrida. Repita perto de
uma parede para conferir o braço da câmera.

Para um herói independente, este código ativa a configuração. Execute-o no `_ready()` da cena do seu jogo, depois
que os filhos do herói estiverem prontos:

```gdscript
extends Node3D

@onready var hero: PlayableHero = $Hero


func _ready() -> void:
    hero.place_at($Spawn, false)
    var rig := hero.camera_rig
    rig.follow_movement = true
    rig.follow_time = 1.1
    rig.follow_toward_camera_angle = deg_to_rad(30.0)
    rig.sharp_turn_speed = deg_to_rad(360.0)
    rig.follow_wait_after_rotate = true
    rig.follow_pitch = true
    rig.follow_pitch_angle = deg_to_rad(-22.0)
    rig.follow_pitch_time = 1.1
    rig.follow_zoom = true
    rig.follow_zoom_level = 0.55
    rig.follow_zoom_time = 1.5
```

O exemplo pressupõe o movimento e a entrada do herói sem alterações. Na demo completa, use o menu de configurações
ou `Settings.set_value()` para manter os ajustes salvos e os controles coerentes.

## Opcional: herói flutuante

Qualquer uma dessas configurações pode usar o sistema de flutuação existente: defina
`Character/Visual/Hover.enabled = true` ou ative **Personagem → Flutuar acima do chão** na demo. Mantenha
`height = 0.35 m`, `glide_time = 0.3 s` e o recurso `player_floating_fall.tres` atribuído (escala da gravidade da
queda de 0.5 e velocidade máxima de queda de 2 m/s).

O modelo flutua; o corpo de colisão ainda sobe degraus e cai. Isso não permite atravessar vãos nem voar. O pulo
chega à mesma altura e a descida é mais lenta. Os eventos de passos param durante a flutuação, e uma aterrissagem
suave a 2 m/s fica abaixo do limite padrão de 2.5 m/s para o evento de aterrissagem. O collider do corpo não cresce
com o modelo elevado: teste tetos baixos. Detalhes sobre modelo e queda: [Personagens](systems/characters.md) e
[Locomoção](systems/locomotion.md).

## Ajustes sem perder a configuração

- **Mantenha recursos separados quando os valores precisarem diferir.** No Inspector, torne único o recurso de
  ajustes do movimentador e salve-o com outro nome antes de editar um personagem. Atribua outro recurso antes de o
  movimentador entrar na árvore de cenas. Durante a execução, edite os campos do recurso existente: substituir
  `mover.settings` após `_ready()` não troca o recurso já retido por `GroundMotion`.
- **Ajuste velocidade e frenagem em conjunto.** `acceleration_time` e `stop_time` são tempos na velocidade básica.
  A corrida rápida a 1.5× usa a mesma aceleração e frenagem; por isso, leva 1.5× mais tempo para parar: cerca de
  0.33 s, em
  vez de 0.22 s. A distância ideal de parada em linha reta é de cerca de 0.61 m a 5.5 m/s e de 1.36 m a 8.25 m/s.
  Reserve espaço nas bordas.
- **Combine a detecção de giros da câmera com o movimento.** Mantenha `sharp_turn_speed` na metade de
  `LocomotionSettings.turn_speed` ou menos. Ao reduzir a velocidade de giro do personagem, reveja esse limite da
  câmera.
- **Combine corpo, proteção e navegação.** Alterar o tamanho da cápsula, a altura máxima de degraus ou o limite de
  inclinação exige rever raio, altura, escalada e inclinação da navegação e gerar a malha novamente. O limite de
  queda da proteção ainda deve permitir os degraus pretendidos. Camadas de física e de navegação são ajustes
  diferentes.
- **Mude um comportamento e refaça sua verificação.** Use os painéis **Linha do caminho do personagem** e
  **Estado do personagem e eventos** da demo para descobrir se o problema está no caminho, na colisão, na entrada
  ou na câmera. Guarde uma cena de referência, em vez de tentar reconstruí-la de memória.

Referência completa das propriedades: [Entrada](systems/input.md), [Locomoção](systems/locomotion.md) e
[Câmera](systems/camera.md).

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
