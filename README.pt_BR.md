<!-- translation of README.md @ 84a666a02ac2 -->
# Iso & Orbit - Template de câmera e controlador de personagem

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · **Português (Brasil)** · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta é uma tradução do [original em inglês](README.md). Onde houver diferenças, a versão em inglês é a correta.

Versão 1.2.0 · Godot 4.7 (testado na 4.7.2) · GDScript · MIT

Um controlador de personagem de clicar para mover e uma câmera orbital para RPGs isométricos e de visão de cima.
Clique no chão e o herói corre até lá, contornando obstáculos; segure o botão e o herói segue o cursor. A câmera
orbita, dá zoom e não entra nas paredes.

**Chegando agora?** [Execute a demo](docs/pt_BR/getting-started.md),
[transfira o herói pronto](docs/pt_BR/integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto) e então
[escolha uma configuração de movimento e câmera](docs/pt_BR/configurations.md).

![Clicar para mover, segurar para guiar, orbitar e dar zoom com a câmera, descobrir um local](docs/images/demo.gif)

Sem assets de terceiros: os personagens são montados a partir de primitivas por um script, os padrões das superfícies
são gerados por shaders e pré-calculados em texturas sem emendas, e os sons são sintetizados.
A visão fornecida usa câmera em perspectiva com campo de visão de 45°. As partes reutilizáveis são componentes
GDScript comuns; não há plugin de editor para ativar.

## Primeiros passos

1. Instale o Godot 4.7.2, a versão padrão ou a .NET. O Jolt Physics já vem embutido na engine, não há nada a
   instalar. O renderizador é o Forward+.
2. Clone o repositório, importe o `project.godot` no Gerenciador de Projetos (Project Manager) e abra-o. A primeira
   importação demora um pouco, pois `.godot/` não está no repositório.
3. Pressione F5 para rodar a demo (`res://gdscript/main.tscn`).

Os controles estão listados no canto superior esquerdo. Para ocultá-los, abra Configurações (F10) → Interface e
desligue **Dica de controles e velocidade**. O idioma da interface é escolhido na mesma aba.

## Controles

| Entrada | Ação |
|---|---|
| Clique esquerdo no chão | Correr até esse ponto |
| Segurar o botão esquerdo | Correr atrás do cursor |
| Segurar o esquerdo e depois o direito | Olhar em volta durante a corrida; o herói mantém o rumo |
| Segurar o direito e depois o esquerdo | Correr para onde a câmera olha; A / D desviam na diagonal |
| Botão direito + mouse | Orbitar a câmera |
| Botão direito + WASD | Mover-se em relação à câmera |
| Roda do mouse | Zoom: mais baixo e mais perto, ou mais alto e mais longe |
| Shift | Corrida rápida enquanto segurado (ou alternar, nas configurações) |
| Espaço | Pular |
| E | Sobre uma plataforma de teleporte: viajar ao lugar de destino |
| F10 | Abrir as configurações (pausa o jogo); Esc ou F10 as fecha |

Todos os modos e suas configurações: [Controles](docs/pt_BR/controls.md).

## Recursos

**Movimento**

- Clique para correr até um ponto pela malha de navegação; um marcador mostra onde.
- Segure o botão esquerdo para correr atrás do cursor: por padrão direto até ele, deslizando ao longo dos obstáculos;
  opcionalmente por um caminho de navegação até o ponto sob ele.
- Clicar e segurar são diferenciados após 0,2 s, então segurar o botão nunca manda o herói fazer um desvio até o
  ponto onde você pressionou.
- O direito e depois o esquerdo (ou ambos juntos): correr para onde a câmera olha. O esquerdo e depois o direito:
  olhar em volta mantendo o rumo. Direito e WASD: mover-se em relação à câmera, olhando para a frente ou virando
  na direção do movimento.
- Aceleração e frenagem constantes, parada exata no alvo sem passar do ponto, velocidade de giro limitada e giro
  instantâneo a partir da parada.
- Corrida rápida com fôlego. Pulo com coyote time e buffer de entrada; a altura do pulo é a mesma em qualquer taxa de
  ticks de física. A queda pode ter gravidade e limite de velocidade próprios (`FallSettings`).
- Proteção de bordas: na beira de um desnível o herói para ou desliza ao longo dela, como numa parede.
- Degraus de até 0,3 m são subidos e descidos sem sair do chão; encostas de até 45° são subidas andando.
- Flutuação opcional: o herói permanece acima do chão, desliza por degraus, oscila e se inclina na corrida, sem
  passos, e desce lentamente após um pulo.

**Câmera**

- Órbita com o botão direito, zoom com a roda. Distância e inclinação mudam juntas: quanto mais perto a câmera, mais
  baixo o seu ângulo, para você ver o que está à frente.
- Opcionalmente, gira para trás do herói em corrida e leva inclinação e altura a valores definidos, começando e
  parando suavemente em qualquer taxa de quadros. Uma corrida rumo à câmera, mesmo após inversão de direção, não
  a faz dar uma volta brusca.
- Enquanto a câmera gira, o cursor fica sobre o mesmo ponto do chão, então o botão segurado mantém o herói no rumo em
  vez de fazê-lo correr em círculos.
- Um braço de câmera: a câmera para numa parede, montanha ou telhado atrás dela e, opcionalmente, se aproxima quando
  um obstáculo esconde o herói. De perto, o herói fica translúcido.
- Atrás de obstáculos, o herói aparece como uma única silhueta com contorno, com o equipamento na mão desenhado por
  cima.

**Níveis**

- Os níveis mudam atrás de uma tela de carregamento enquanto herói e interface permanecem: o próximo carrega em
  segundo plano, o antigo é liberado, e o herói chega a um ponto de entrada com a câmera atrás dele.
- A tela mostra o último quadro do jogo desfocado e se aproximando lentamente, nome do lugar, barra de progresso
  e dicas de controle.
- Portais pedem confirmação (as plataformas da demo oferecem “E Teletransporte: …”) ou viajam imediatamente,
  como uma porta.
- O herói controlado pelo jogador vem numa cena pronta (`PlayableHero`): personagem, entrada, câmera e marcador
  de clique, com métodos para colocá-lo em qualquer lugar.

**Também incluído**

- Uma janela de configurações (F10) com abas de controles, personagem, câmera, exibição, interface e som, salvas em
  `user://settings.cfg`. A interface está em inglês, espanhol, japonês, português do Brasil, russo, turco e chinês
  simplificado, com troca em tempo real.
- O personagem informa o que está fazendo, para animações, efeitos e a interface: o estado (parado, correndo, em
  corrida rápida, pulando, caindo) com um sinal a cada mudança, os passos com o pé, as saídas do chão e as
  aterrissagens, os degraus e suas alturas, a velocidade como valor de mistura, o movimento e a aceleração nos eixos
  do modelo, o giro e o ciclo da passada. Os
  sons estão conectados aos sinais, e um painel (Configurações → Interface) mostra tudo ao vivo com os últimos eventos.
- Dois níveis de demonstração: uma clareira cercada de 80 × 80 m com ruínas, acampamento, sítio, labirinto de
  sebes, plataforma com rampa e escada e montanha com trilha espiral; e uma ilha pequena num lago, acessível por
  teleporte. Cinco lugares para descobrir: quatro na clareira, com cinco NPCs, e um na ilha; dez aparências do herói.
- Testes headless de movimento, entrada, pulo, corrida rápida e sons, do estado do personagem, de degraus e encostas,
  da câmera e seu braço, das aparências do herói, da janela de configurações, traduções, níveis e teleporte.

**Não incluído:** suporte a gamepad, menu para remapear teclas no jogo nem animações esqueléticas. As ações de
entrada são configuráveis em Project Settings; a interface lê os vínculos atuais. Os modelos são primitivas
estáticas.

## Como as partes se encaixam

```
mouse, WASD ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (caminho ou         (aceleração, frenagem,
                                                           direção)            giro: matemática pura)
                                                               │ velocidade
                                                               ▼
Shift, Space ──► CharacterActionInput ──────────────────► GroundCharacter
                                                          (CharacterBody3D: gravidade, pulo, corrida rápida,
                                                           move_and_slide, giro do modelo)

mouse ──► OrbitCameraRig ──► CameraArm ──► Camera3D
```

- **Só o `GroundCharacter` move o corpo.** Os componentes de movimento retornam uma velocidade e nunca chamam
  `move_and_slide()`, então gravidade, pulos e qualquer futuro knockback são combinados num só lugar.
- **`GroundMotion` é matemática sem nós**, fácil de testar isoladamente.
- **O personagem não sabe nada do mouse.** Os nós de entrada ficam na cena do herói jogável
  (`playable_hero.tscn`), não em `player.tscn`. Para um NPC,
  instancie `player.tscn` sem os nós `Silhouette` e `Appearance`, que são só do jogador, e chame
  `NavigationMover.move_to()` da sua IA.
- **O herói não integra um nível.** Fica ao lado do host em `main.tscn`; os níveis mudam ao seu redor.
- **Os componentes não sabem nada das configurações.** Eles leem as próprias propriedades exportadas. Só o
  `settings_applier.gd` da demo e a janela de configurações falam com o autoload `Settings`, então um componente vai
  para outro projeto sem eles.

Detalhes: [Arquitetura](docs/pt_BR/architecture.md).

## Usando no seu projeto

Os componentes estão em `addons/iso_orbit/`, uma pasta por parte; copie os que precisar para a mesma pasta do seu
projeto:

| Addon | O que oferece |
|---|---|
| `orbit_camera` | A câmera orbital e seu braço; funciona com qualquer alvo `Node3D` |
| `click_to_move` | Clicar e segurar para mover pela malha de navegação, direcionamento, o marcador de clique |
| `ground_character` | Corpo pronto: gravidade, pulo, ajustes de queda, corrida rápida com fôlego, proteção de bordas, sinais de passos, sons, balanço da mão, flutuação e modelos trocáveis (precisa de `click_to_move`) |
| `occluded_silhouette` | A silhueta do personagem atrás de obstáculos |
| `points_of_interest` | Locais para descobrir e a mensagem sobre eles |
| `ui_screens` | Uma pilha de janelas que pausa o jogo e um contador de FPS |
| `levels` | Níveis trocados atrás de tela de carregamento, portais e pontos de entrada |

Para o caminho mais curto até funcionar, copie `playable_hero.tscn` montado e suas dependências pelo
[guia de transferência](docs/pt_BR/integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto). Ele traz um
nível pequeno de teste, ajustes exatos de colisão/navegação e verificações antes de personalizar. O herói funciona
sem a janela de configurações ou o sistema de níveis da demo.

Para seu controlador ou IA, `NavigationMover.move_to(point)` segue um caminho de navegação e
`steer(direction)` move diretamente. O corpo aplica a velocidade retornada uma vez por tick de física; o
movimentador nunca o move. Uma integração mínima está em
[Seu próprio corpo](docs/pt_BR/integration.md#seu-próprio-corpo).

[Configurações](docs/pt_BR/configurations.md) compara o padrão fornecido com movimento pelo mouse guiado por
caminhos e exploração com câmera que acompanha, explicando cada mudança. [Configuração do
projeto](docs/pt_BR/project-setup.md) lista as ações, camadas e dependências opcionais da demo.

## Documentação

- **Início:** [Primeiros passos](docs/pt_BR/getting-started.md) · [Controles](docs/pt_BR/controls.md) ·
  [Configurações do herói](docs/pt_BR/configurations.md) · [Configurações](docs/pt_BR/settings.md)
- **Código:** [Arquitetura](docs/pt_BR/architecture.md) · [Usando no seu projeto](docs/pt_BR/integration.md) ·
  [Configuração do projeto](docs/pt_BR/project-setup.md)
- **Sistemas:** [Locomoção](docs/pt_BR/systems/locomotion.md) · [Câmera](docs/pt_BR/systems/camera.md) ·
  [Entrada](docs/pt_BR/systems/input.md) · [Personagens](docs/pt_BR/systems/characters.md) ·
  [Áudio](docs/pt_BR/systems/audio.md) · [UI](docs/pt_BR/systems/ui.md) ·
  [Mundo e navegação](docs/pt_BR/systems/world-and-navigation.md) · [Níveis](docs/pt_BR/systems/levels.md)
- **Manutenção:** [Testes](docs/pt_BR/testing.md) · [Problemas conhecidos](docs/pt_BR/known-issues.md) ·
  [Glossário](docs/pt_BR/glossary.md) · [Roteiro](docs/pt_BR/roadmap.md)

## Estrutura do repositório

| Pasta | Conteúdo |
|---|---|
| `addons/iso_orbit/` | Os componentes, uma pasta por parte que pode ser usada sozinha |
| `gdscript/` | A demo que os monta: cena principal `main.tscn`, herói jogável, sistema e janela de configurações |
| `shared/` | Conteúdo da demo compartilhável com uma futura versão C#: níveis, personagens e equipamentos, shaders e texturas do mundo, sons e tema da UI. Dois scripts GDScript dos níveis também ficam aqui |
| `l10n/` | Traduções da interface (gettext `.po`) |
| `tests/` | Testes headless |
| `docs/` | Documentação |

## Testes

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Aqui `godot` é o seu executável do Godot 4.7.2; no Windows, use a versão `_console.exe` para ver a saída e obter o
código de saída. Para rodar só algumas suítes, adicione partes dos nomes delas depois de `--`, por exemplo
`-- camera input`. O código de saída é 1 se alguma verificação falhar. Detalhes: [Testes](docs/pt_BR/testing.md).

## Roteiro

- Um exemplo em C# em `csharp/`, com os mesmos componentes e uma cena principal sobre os níveis de `shared/world/`.
- Animações: controlar uma mistura de parado, corrida e corrida rápida em `AnimationTree` usando
  `GroundCharacter.get_locomotion_blend()`.

## Licença

MIT, veja [LICENSE](LICENSE). Exceção: `icon.svg`, o logotipo do Godot por Andrea Calabró, CC BY 4.0.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
