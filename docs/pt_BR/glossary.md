<!-- translation of docs/en/glossary.md @ 2c04d3857e30 -->
<!-- translation of docs/en/glossary.md @ pending -->
# Glossário

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/glossary.md).
> Em caso de divergência, consulte a versão em inglês.

Termos usados nesta documentação e no código.

| Termo | Significado |
|---|---|
| **Raio do agente** | Distância da malha de navegação aos obstáculos: 0.5 m, maior que o raio de 0.35 m da cápsula, deixando folga nos cantos |
| **Braço** | `CameraArm`: nó que mantém a câmera na ponta de uma linha a partir do alvo. A roda define seu comprimento; obstáculos o encurtam |
| **Mistura** | `GroundCharacter.get_locomotion_blend()`: velocidade como número para animações, 0 parado, 1 correndo, 2 em corrida rápida |
| **Limites** | Camada de física 4: muros invisíveis nas bordas do nível. O personagem colide com eles; cliques e braço da câmera os atravessam |
| **Corpo exclusivo da câmera** | Corpo na camada de física 3 (`camera`): para o braço, mas cliques, navegação e personagens o ignoram |
| **Estado do personagem** | O que faz: parado, correndo, em corrida rápida, pulando ou caindo (`GroundCharacter.get_state()`, sinal `state_changed`) |
| **Clique** | Pressionar e soltar o botão esquerdo antes do tempo de espera. O personagem percorre um caminho até o ponto em que o botão foi pressionado |
| **Tolerância do pulo após a borda** | Curto período após sair do chão em que o pulo ainda funciona (0.1 s, coyote time) |
| **Exausto** | Estado após gastar todo o fôlego: sem corrida rápida até recuperá-lo a `recover_ratio` (30%) |
| **Direção do olhar** | Para onde o personagem olha, diferente do deslocamento em passo lateral ou recuo. `NavigationMover.get_facing()` |
| **Ajustes de queda** | Como o personagem desce após o topo do pulo ou uma borda: gravidade, velocidade máxima e frenagem do excesso (`FallSettings`). Não alteram a subida |
| **Flutuação** | Modelo elevado acima do chão, deslizando por degraus enquanto o corpo anda normalmente (`CharacterHover`). Sem passos; na demo desce mais devagar |
| **Acompanhamento** | Câmera girando sozinha atrás da corrida e trazendo inclinação e altura para valores definidos; cada movimento começa e termina suavemente (`follow_movement`, `follow_pitch`, `follow_zoom`). Após órbita, pode esperar parada ou nova corrida (`follow_wait_after_rotate`, ativo na demo) |
| **Ciclo da passada** | Dois passos, esquerdo e direito, como número de 0 a 1 (`GroundCharacter.get_gait_cycle()`). Segue a distância percorrida, não o tempo |
| **Direção do movimento** | Rumo em que o personagem se desloca. `NavigationMover.get_heading()` |
| **Aparência do herói** | Um dos dez modelos do personagem do jogador, escolhido pelo número nas configurações (`CharacterAppearance`) |
| **Botão segurado** | Botão esquerdo mantido além do tempo de espera. O personagem corre atrás do cursor |
| **Tempo para segurar** | Intervalo que distingue clique de botão segurado: 0.2 s (`PointClickMoveInput.hold_delay`) |
| **Entrada antecipada do pulo** | Um pulo pedido pouco antes de aterrissar fica guardado e acontece na aterrissagem (0.12 s) |
| **Manter a mira** | Mover o cursor do sistema com o mundo enquanto o botão está pressionado e a câmera gira, mantendo-o sobre o mesmo ponto do chão (`keep_aim_on_camera_turn`) |
| **Proteção contra bordas** | `LedgeGuard`: para diante de queda maior que 0.5 m ou desliza ao longo da borda |
| **Host de níveis** | `LevelHost`: mantém o nível atual e o troca atrás da tela de carregamento; herói e interface ficam ao lado, fora do nível |
| **Tela de carregamento** | `LoadingScreen`: cobre o jogo durante a troca, com último quadro desfocado, nome do lugar, barra de progresso e dicas |
| **Visual** | Veja aparência do herói |
| **Olhar em volta** | Botão direito pressionado durante corrida atrás do cursor: o mouse gira só a câmera e a corrida mantém o rumo (`look_around_while_held`). Pressionado primeiro, o direito dirige a corrida para onde a câmera olha |
| **Marcador** | `ClickMarker`: anel no chão no ponto clicado |
| **Movimentador** | `NavigationMover`: converte comandos (`move_to`, `steer`, `stop`) em velocidade horizontal a cada tick; nunca move o corpo |
| **Malha de navegação** | Área transitável gerada das colisões do nível na camada 1 (na ilha, também muros invisíveis da camada 4), guardada em cada cena. Os caminhos são buscados nela |
| **Oferta de viagem** | `TravelPrompt`: tecla e texto “Teletransporte: …” enquanto o herói está num portal que pede confirmação. E (ação `interact`) ou clique viaja; afastar-se oculta a oferta |
| **Interpolação de física** | Desenhar corpos entre ticks de física na taxa de quadros da tela. Ativa por padrão; há ajuste para desligá-la |
| **Inclinação** | Ângulo com que a câmera olha para baixo. Negativo no código, graus para baixo nas configurações |
| **Giro a partir da parada** | Virar instantaneamente abaixo de `pivot_speed` (1 m/s) |
| **Lugar** | Um `PointOfInterest`: área que mostra “Descoberto: …” na primeira entrada do jogador |
| **Herói jogável** | `PlayableHero` (`playable_hero.tscn`): personagem controlado pelo jogador, com entrada, câmera, marcador e linha do caminho, colocado ao lado dos níveis |
| **Portal** | `LevelPortal`: área que leva a outro nível; as plataformas de teleporte da demo são portais |
| **Aproximação por ocultação** | Câmera passando à frente de um obstáculo que esconde o personagem (`pull_in_on_occlusion`) |
| **Giro brusco** | Mudança de direção mais rápida que `OrbitCameraRig.sharp_turn_speed` (360°/s), como uma inversão: a câmera ignora direções intermediárias e assume a nova após o giro |
| **Cena principal** | Cena que permanece durante o jogo (`main.tscn` com `main.gd`): host, herói, interface e tela de carregamento |
| **Passo lateral** | Modo de teclas com botão direito: personagem continua olhando para onde a câmera aponta enquanto anda de lado ou recua |
| **Silhueta** | Personagem desenhado como forma plana com contorno ao ser escondido (`OccludedSilhouette`) |
| **Ponto de entrada** | `SpawnPoint`: onde o personagem aparece num nível, identificado por nome; cada nível possui um `default` |
| **Corrida rápida** | Correr mais depressa (×1.5) enquanto Shift fica pressionado ou por alternância, gastando fôlego |
| **Altura do degrau** | Maior degrau que o personagem sobe sem pular: 0.3 m (`GroundCharacter.max_step_height`) |
| **Fôlego** | Reserva da corrida rápida (`Stamina`): gasta durante a corrida e se recupera após uma pausa |
| **Nível inicial** | Nível colocado no host pelo editor: `shared/world/world.tscn`, a clareira cercada. No jogo chama-se Vale Verde (nome na plataforma da ilha) |
| **Controle direto da direção** | Correr sem caminho: `NavigationMover.steer()`. Segurar o botão guia rumo ao cursor por padrão |
| **Teleporte** | Colocar o personagem imediatamente noutro lugar, sem corrida ou tranco: `GroundCharacter.teleport()`, `PlayableHero.teleport()` |
| **Tick** | Uma etapa da física; 60 por segundo |
| **Viajante** | Corpo que pode usar um portal: membro do grupo `traveller_group` (`player` por padrão) |
| **Modo de giro** | Modo de teclas com botão direito: personagem vira para olhar na direção em que anda |
| **Quadros de preparação** | Quadros que o host desenha do novo nível atrás da tela antes de ocultá-la, para compilar shaders e acomodar o personagem (`LevelHost.warmup_frames`, 3) |
| **Guinada** | Direção da câmera em torno do eixo vertical |
| **Zoom** | Valor de 0 (mais perto) a 1 (mais longe) que define distância e inclinação da câmera juntas |

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
