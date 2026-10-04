<!-- translation of docs/en/glossary.md @ c34a86f53e66 -->
# Glossário

> Esta é uma tradução do [original em inglês](../en/glossary.md).
> Onde houver diferenças, a versão em inglês é a correta.

Os termos como esta documentação e o código os usam.

| Termo | Significado |
|---|---|
| **Raio do agente** (Agent radius) | A distância que a malha de navegação mantém dos obstáculos: 0,5 m, mais que a cápsula de 0,35 m do personagem, para que os caminhos mantenham uma margem dos cantos |
| **Braço** (Arm) | `CameraArm`: o nó que segura a câmera na ponta de uma linha a partir do alvo. A roda define o comprimento dele; obstáculos o encurtam |
| **Corpo só para a câmera** (Camera-only body) | Um corpo na camada de física 3 (`camera`): ele para o braço da câmera, mas cliques, navegação e personagens o ignoram |
| **Clique** (Click) | Um pressionamento do botão esquerdo solto dentro do tempo para segurar. O personagem corre por um caminho até o ponto onde o botão foi pressionado |
| **Tempo coiote** (Coyote time) | Um curto tempo depois de sair de uma borda em que um pulo ainda funciona (0,1 s) |
| **Exausto** (Exhausted) | O estado depois que o fôlego acaba: sem corrida rápida até o fôlego se recuperar a `recover_ratio` (30%) |
| **Orientação** (Facing) | Para onde o personagem olha, em oposição a para onde ele se move. Os dois diferem no passo lateral ou no recuo. `NavigationMover.get_facing()` |
| **Seguir** (Follow) | A câmera virando sozinha para trás do personagem em corrida e, opcionalmente, ajustando suavemente a inclinação (`follow_movement`, `follow_pitch`) |
| **Rumo** (Heading) | A direção em que o personagem se move. `NavigationMover.get_heading()` |
| **Aparência do herói** (Hero look) | Um dos dez modelos que o personagem do jogador pode usar, escolhido por número nas configurações (`CharacterAppearance`) |
| **Segurar** (Hold) | O botão esquerdo mantido pressionado por mais tempo que o tempo para segurar. O personagem corre atrás do cursor |
| **Tempo para segurar** (Hold delay) | O tempo que distingue um clique de segurar o botão: 0,2 s (`PointClickMoveInput.hold_delay`) |
| **Buffer de pulo** (Jump buffer) | Um pulo pressionado pouco antes de aterrissar é lembrado e acontece na aterrissagem (0,12 s) |
| **Manter a mira** (Keeping the aim) | Mover o cursor do sistema junto com o mundo enquanto o botão está segurado e a câmera gira, para que o cursor fique sobre o mesmo ponto do chão (`keep_aim_on_camera_turn`) |
| **Proteção de bordas** (Ledge guard) | `LedgeGuard`: para o personagem num desnível maior que 0,5 m, ou o faz deslizar ao longo da borda |
| **Aparência** (Look) | Veja aparência do herói |
| **Marcador** (Marker) | `ClickMarker`: o anel no chão no ponto clicado |
| **Movimentador** (Mover) | `NavigationMover`: transforma comandos (`move_to`, `steer`, `stop`) numa velocidade horizontal a cada tick. Nunca move o corpo |
| **Malha de navegação** (Navigation mesh) | A área transitável gerada a partir das colisões do nível na camada 1, guardada em `world.tscn`. Os caminhos são buscados nela |
| **Interpolação de física** (Physics interpolation) | Desenhar os corpos entre os ticks de física na taxa de quadros da tela. Ligada por padrão; uma configuração a desliga |
| **Inclinação** (Pitch, tilt) | O quanto a câmera olha para baixo. Ângulos negativos no código, graus para baixo nas configurações |
| **Giro no lugar** (Pivot) | Girar instantaneamente a partir da parada, abaixo de `pivot_speed` (1 m/s) |
| **Local** (Place) | Um `PointOfInterest`: uma área que mostra "Descoberto: …" na primeira vez que o jogador entra nela |
| **Aproximação** (Pull-in) | A câmera indo para a frente de um obstáculo que esconde o personagem (`pull_in_on_occlusion`) |
| **Modo lateral** (Sidestep) | Um modo das teclas com o botão direito: o personagem continua olhando para onde a câmera olha enquanto se move de lado ou para trás |
| **Silhueta** (Silhouette) | O personagem desenhado como uma forma plana com contorno onde algo o esconde (`OccludedSilhouette`) |
| **Corrida rápida** (Sprint) | Correr mais rápido (×1,5) enquanto o Shift está segurado ou alternado, gastando fôlego |
| **Fôlego** (Stamina) | A reserva para a corrida rápida (`Stamina`): é gasto durante a corrida rápida e se recupera depois de uma pausa |
| **Direcionar** (Steer) | Correr numa direção sem caminho: `NavigationMover.steer()`. Segurar o botão direciona para o cursor por padrão |
| **Tick** (Tick) | Um passo de física; 60 por segundo |
| **Modo virar** (Turn mode) | Um modo das teclas com o botão direito: o personagem vira para olhar para onde vai |
| **Guinada** (Yaw) | A direção da câmera em torno do eixo vertical |
| **Zoom** (Zoom) | Um valor de 0 (mais perto) a 1 (mais longe) que define a distância e a inclinação da câmera juntas |

---

*Esta página corresponde ao Iso & Orbit 1.0.0.*
