<!-- translation of docs/en/systems/world-and-navigation.md @ a8fe33886a8e -->
# Mundo e navegação

> Esta é uma tradução do [original em inglês](../../en/systems/world-and-navigation.md).
> Onde houver diferenças, a versão em inglês é a correta.

O nível da demo é `shared/world/world.tscn`: uma clareira de 80 × 80 m atrás de uma cerca de madeira. Tudo nele é feito
de primitivas e shaders; os padrões finos das superfícies vêm de texturas pré-calculadas.

## O nível

- **O centro** é o ponto de spawn. Em volta dele: um anel de colunas em ruínas, uma armadilha em forma de U aberta
  para o spawn, um muro longo com uma abertura, caixotes, um bosque, um labirinto de sebes e uma plataforma de 1,6 m
  que só pode ser alcançada pela rampa. Os testes usam tudo isso, então essas coisas ficam onde estão.
- **As estradas** são faixas de terra da cerca sul, pela abertura no muro, até o spawn e daí até a montanha, as ruínas,
  o acampamento e a rampa; a estrada do sítio se ramifica ao sul do muro. Elas são só um padrão (os segmentos `ROADS`
  em `shared/world/terrain.gdshaderinc`) e não afetam o movimento. O chão e a grama suave no pé da montanha as
  desenham, então a estrada entra na trilha da montanha sem interrupção. Ela chega ao início da trilha pelo oeste: a
  leste do início da trilha, a montanha é um paredão contínuo de até 4 m.
- **Props** de `shared/world/props/`: uma floresta no noroeste e ao longo das bordas, arbustos, pedregulhos, um
  acampamento no leste (uma barraca, uma fogueira com luz tremeluzente, barris), um sítio no sudoeste (uma casa, um
  poço).
- **A montanha** no nordeste, com 10 m de altura e uma única trilha em espiral até o topo.
- **As dez aparências do herói** em fila de costas para o muro sul, a leste da abertura (veja
  [Personagens](characters.md#aparências-do-herói)).

A floresta, os arbustos e os pedregulhos foram posicionados uma vez por um script descartável com uma semente fixa,
deixando livres os lugares que os testes usam (rotas, a corrida pela faixa sul, o pulo da plataforma, tudo em volta do
spawn). O script não está no projeto; a disposição agora é editada no editor. Ao mover árvores, mantenha esses lugares
livres.

### Locais e NPCs

Quatro locais são áreas `PointOfInterest`. Na primeira vez que o jogador entra num deles, "Descoberto: …" aparece no
alto da tela por alguns segundos. Em cada local há NPCs com rótulos de nome (`Label3D`) sobre a cabeça, virados para o
centro do local; o Cavaleiro olha ao longo da estrada.

| Local | Onde | Quem está lá |
|---|---|---|
| Pico dos Ventos | O topo da montanha no nordeste | O Mago, junto a um altar com um cristal |
| Acampamento dos Viajantes | Leste: barraca, fogueira, barris | O Patrulheiro e o Anão junto ao fogo |
| Sítio do Poço | Sudoeste: casa, poço | O Cavaleiro de guarda junto à estrada |
| Círculo Antigo | O anel de colunas a noroeste do spawn | O Ladino junto ao altar |

Cada NPC é um `StaticBody3D` com uma cápsula na camada 1 (`World/NavigationRegion3D/Characters`): a malha de
navegação os contorna e ninguém os atravessa. O acampamento, o sítio e as ruínas estão sob `World/Places`; o pico está
em `mountain.tscn`.

**Um novo local:** adicione um `PointOfInterest` (um `Area3D` cuja `collision_mask` inclui a camada 2 dos personagens)
com uma forma de colisão e um `title` a qualquer cena do mundo. O aviso (toast) encontra todos os locais pelo grupo;
nenhuma conexão é necessária. Adicione o título às traduções ([UI](ui.md#traduções)).

## Superfícies

Quase toda superfície é um shader em `shared/world/` com um material em `shared/world/materials/`; as exceções são
materiais `StandardMaterial3D` simples, listados no fim desta seção. O que depende do tamanho e da forma de um objeto é
calculado pelo shader, o que é barato: fiadas de alvenaria ajustadas à altura de uma caixa, tábuas, molduras e postes,
enxaimel, aduelas e aros de barril, caneluras e tambores de coluna, estradas ao longo de `ROADS`, camadas de rocha por
altura. Assim, uma caixa de qualquer tamanho não estica o seu padrão. O detalhe fino (lâminas de grama, pedrinhas,
folhas, casca, grão da pedra) vem de texturas pré-calculadas, veja abaixo.

| Superfície | Shader | Aparência |
|---|---|---|
| Muros, plataforma, rampa | `stone_masonry` | Blocos em fiadas desencontradas com juntas, cada bloco com tom, grão e lascas próprios, relevo pela normal, sujeira e musgo perto do chão. O topo é uma fiada de pedras atravessadas no lado curto |
| Labirinto de sebes | `hedge_foliage` | Duas camadas de folhas, cada uma com rotação, tamanho, tom e inclinação próprios; a sombra da profundidade do arbusto nas falhas; laterais irregulares como um arbusto podado |
| Caixotes, cerca | `wood_planks` | Tábuas com anéis de crescimento, fibras, nós e frestas. Os caixotes têm uma moldura de tábuas em cada face, uma travessa diagonal e pregos; a cerca tem tábuas longas desgastadas sobre postes a cada 2,5 m |
| Colunas, poço | `stone_column` | Caneluras em volta da circunferência pela normal, tambores de 0,8 m com juntas a partir do chão, uma base lisa, manchas escorridas, rachaduras raras, líquen, musgo perto do chão. O poço usa alvenaria de blocos em círculo (`blocks_around`) |
| Pedregulhos, pedras em pé | `rock` | Pedra granulada com veios e rachaduras, líquen em cima, musgo perto do chão; o padrão é triplanar (`triplanar.gdshaderinc`), diferente em cada pedregulho |
| Paredes da casa | `timber_plaster` | Enxaimel: reboco com manchas e rachaduras finas numa moldura de postes e vigas, um embasamento de pedra |
| Telhados da casa e do poço | `thatch` | Sapê em fileiras de feixes com uma sombra sob cada fileira, palhas descendo a inclinação, uma cumeeira amarrada, musgo |
| Barraca, aba, estandarte | `canvas` | Lona tecida: painéis com costuras, dobras, remendos; o estandarte tem uma borda e um emblema |
| Barris | `barrel` | Aduelas com frestas, aros de ferro enferrujados, uma tampa de tábuas |
| Toras, troncos, mastro do estandarte | `bark` | Casca sulcada com musgo perto do chão e no lado norte; toras carbonizadas e em brasa na fogueira |
| Copas das árvores, arbustos | `foliage` | Folhas em duas camadas em três planos de eixo, tufos, um topo mais claro; agulhas nos pinheiros, laranja e vermelho no carvalho de outono |
| Chão | `ground_grid` | Veja abaixo |
| Montanha | `mountain` | Grama, a trilha e camadas de rocha escolhidas pela cor da face |
| Água do poço | `water` | Ondulações lentas |

O padrão da alvenaria segue as faces da malha e conhece o tamanho da caixa: um `BoxMesh` sem subdivisões de face só tem
um vértice em cada canto, então `abs(VERTEX)` dá as metades das dimensões. As fiadas nas laterais se ajustam à altura,
e a fiada de cima de uma lateral é a borda das pedras do topo, então suas juntas continuam as juntas do topo na borda.
A rampa (uma laje fina) é uma dessas fiadas, e as juntas das suas pontas coincidem com o topo. Já as caixas do
labirinto têm subdivisões de face a cada 25 cm (`subdivide_*`), porque suas laterais são deslocadas por ruído a partir
da posição no mundo: as cópias de um vértice numa aresta se movem juntas e as faces não se separam. As formas de
colisão continuam sendo as caixas simples; as folhas se projetam alguns centímetros.

**O chão** (`ground_grid.gdshader`, parte compartilhada `terrain.gdshaderinc`): grama em várias escalas (grandes
manchas de grama escura, normal e seca, touceiras, lâminas em duas camadas com normais inclinadas e sombra nas raízes,
flores espalhadas nas clareiras) e estradas (uma borda irregular com tufos de grama, um meio pisado mais claro, sulcos
rasos, grão, rachaduras finas nos pontos secos, pedrinhas com sombras, mais delas na borda). O detalhe fino se repete a
cada 3,84 m a partir de texturas pré-calculadas; as grandes manchas vêm de uma máscara sobre o chão inteiro. À
distância, o detalhe se dissolve numa cor média pelos níveis de mip das texturas. A grama e a trilha da montanha usam o
mesmo código. Uma grade de 1 m com linhas grossas a cada 5 m fica desligada por padrão; ligue-a com `grid_strength` em
`shared/world/materials/ground.tres` para medir velocidades e distâncias.

O ruído barato dos shaders (números aleatórios para pedras e tábuas, tufos da folhagem) está em `noise.gdshaderinc`, as
folhas em `leaves.gdshaderinc`. Alguns materiais continuam `StandardMaterial3D` simples: `dark_wood.tres` e
`wood.tres`, usados pelos equipamentos dos personagens (cajados, arco, machado), e os brilhantes `crystal.tres` e
`fire.tres`.

## Texturas pré-calculadas

Os padrões das superfícies (grama com lâminas e flores, terra com pedrinhas, folhas, casca, grão da pedra, reboco,
fibras da madeira, sapê, tecido) foram criados como shaders de ruído, mas o jogo não os calcula para cada pixel: eles
foram pré-calculados (baked) uma vez em texturas sem emendas em `shared/world/textures/`, e os shaders do mundo as
repetem lado a lado.

O motivo é o tempo de quadro. Só o chão custava à GPU cerca de 2,5 ms por quadro numa janela de 2560 × 1511: cada pixel
percorria 18 células de lâminas de grama com senos e hashes. Com texturas, a GPU precisa de cerca de 2 ms para o quadro
inteiro em vez de 4,5, e a taxa de quadros foi de 160–230 para 300–470 (12 vistas do nível, sem V-Sync, uma RTX 4090
Laptop GPU; além disso, o limite é a CPU).

- **Sem emendas.** O ruído dos padrões se repete junto com o ladrilho, com um número inteiro de elementos por ladrilho,
  então a emenda é invisível. A exceção é `ground_mask`: as grandes manchas e as estradas sobre o chão inteiro de 96 m,
  sem repetição.
- **A cor fica no shader do mundo.** Folhas, pedra das colunas, casca e fibras da madeira são pré-calculadas sem cor
  (tom da folha, sombra, folha ou falha, manchas, inclinação da normal), e o shader do mundo monta a cor a partir de
  parâmetros do material: uma única textura de folhas serve para o carvalho, o carvalho de outono e a sebe. Só a grama
  (um multiplicador para o tom da mancha), as flores e as pedrinhas têm cor pré-calculada.
- **O relevo** é a inclinação da normal em dois canais, calculada durante o pré-cálculo a partir de diferenças de
  altura.
- **Arquivos:** WebP sem perdas (os dados sob alfa zero ficam intactos), importados com compressão de GPU (BPTC),
  mipmaps e sem correção de cor para pixels transparentes, já que o alfa guarda dados. Mantenha essas configurações de
  importação ao substituir uma textura.

## A montanha e o Pico dos Ventos

A montanha fica num canto na borda do mundo (suas encostas passam da cerca) e é visível de todo lugar. A trilha até o
topo tem 3 m de largura: começa no fim da estrada (23, 0, −19) e dá quase uma volta inteira em torno da montanha (340°)
com inclinação de 12°. As encostas dos dois lados são íngremes (76° acima da trilha, 60° abaixo): não podem ser
escaladas a pé (o corpo só fica de pé em 45° ou menos) nem por um caminho (a malha de navegação aceita inclinações de
até 40°), e a proteção de bordas impede o personagem de cair da trilha. Um clique no topo a partir do chão leva pela
trilha: 51 m em 9,8 s.

No topo há um santuário: um altar com um cristal brilhante flutuando e girando devagar acima dele, cinco pedras em pé e
um estandarte. O topo é o local Pico dos Ventos.

A montanha é um mapa de altura gerado por um script: uma malha com cores de face e sombreamento plano, com o material
`materials/mountain.tres` por cima (grama com lâminas, terra da trilha com pedrinhas, camadas de rocha com rachaduras e
líquen, pela cor da face), e uma forma de colisão dos mesmos triângulos (`shared/world/mountain/*.res`). O que foi
preciso para que um caminho fosse traçado ao longo da trilha:

- A trilha tem uma única altura na largura, então sua borda interna é mais íngreme que o eixo (na razão entre o raio
  do eixo e o raio da borda). As curvas não são fechadas (raio de 9,5 → 7 m), para que mesmo perto do topo a borda
  interna fique abaixo de 16°: mais íngreme que isso, uma malha de navegação com escalada de 0,075 m por célula de
  0,25 m quebra a trilha.
- A entrada pela estrada: no pé, enquanto a trilha está abaixo de 1 m, a encosta externa é suave. Caso contrário, a
  trilha cai para fora desde o início, e sua entrada se estreita numa faixa mais fina que a margem do agente.
- Os últimos 3 m da trilha ficam no nível do topo, então a trilha encontra o topo ao longo de uma faixa, não num
  ponto.

Por padrão, a câmera olha do sudeste, então no lado oposto da trilha a montanha esconde o herói, que então aparece como
silhueta (veja [Personagens](characters.md#occludedsilhouette-uma-forma-a-arma-contornada-uma-borda)).

## Camadas de física e navegação

Os obstáculos são `StaticBody3D` na camada 1 (`world`), os personagens na camada 2 (`characters`), os corpos só para a
câmera na camada 3 (`camera`), veja [Configuração do projeto](../project-setup.md#camadas-de-física). A malha de
navegação é gerada a partir das colisões da camada 1 com um raio do agente de 0,5 m; a cápsula do personagem tem
0,35 m, então os caminhos mantêm uma margem dos cantos.

| Parâmetro do `NavigationMesh` | Valor | Por quê |
|---|---|---|
| `agent_radius` | 0,5 m | Os caminhos ficam longe dos cantos |
| `agent_height` | 1,75 m | |
| `agent_max_slope` | 40° | As encostas da montanha ficam fora da malha |
| `cell_height` | 0,025 m | Fina o bastante para medir a escalada abaixo |
| `agent_max_climb` | 0,075 m (3 células) | Abaixo da borda de 0,1 m em que o corpo consegue subir |
| `geometry_collision_mask` | camada 1 | Só os obstáculos contam |

**Um caminho nunca leva a uma borda mais alta do que o corpo consegue subir.** A cápsula do `CharacterBody3D` sobe numa
borda de no máximo `r·(1 − cos floor_max_angle)` = 0,35 × (1 − cos 45°) ≈ 0,1 m. A malha era gerada com
`agent_max_climb` = 0,25 m e `cell_height` = 0,25 m, e o Recast mede alturas em células inteiras, então tratava uma
borda de quase 0,5 m como transitável: o caminho até a plataforma entrava na rampa pela lateral, onde a borda dela fica
0,4 m acima do chão, e o personagem batia nela. Agora uma borda acima de 0,075 m não é ligada, e a rampa (uma subida de
0,067 m por célula de 0,25 m) fica inteira. A altura de célula do mapa de navegação não pode passar da altura de célula
da malha (senão a engine avisa), então o `project.godot` define `navigation/3d/default_cell_height` como 0,025.

Uma malha do Recast fica suspensa cerca de duas alturas de célula acima do chão (0,05 m aqui; era 0,5 m com as antigas
células de 0,25 m). É por isso que o `NavigationMover` compara os pontos do caminho no plano horizontal, veja
[Locomoção](locomotion.md#navigationmover).

## Gerar a malha de navegação de novo

A malha é gerada (baked) com antecedência e guardada dentro de `shared/world/world.tscn` (o recurso `NavigationMesh` do
`NavigationRegion3D`); o jogo não a recalcula. Depois de editar o nível, gere-a de novo.

**Quando:** você moveu, adicionou, removeu ou redimensionou qualquer coisa com uma forma de colisão na camada 1
(`world`): uma rocha, um caixote, um muro, uma árvore, um prop, um NPC, a montanha. Não é necessário quando só a
aparência mudou (uma malha, um material), nem para corpos na camada 3 (`camera`), o personagem do jogador (camada 2) e
áreas (`Area3D`). Se você esquecer, os caminhos atravessam um objeto movido (o personagem bate nele e desliza ao longo
dele) ou contornam o espaço vazio onde ele estava.

**No editor:**

1. Abra `shared/world/world.tscn`.
2. Selecione `NavigationRegion3D` na árvore de cena.
3. Pressione **Gerar NavigationMesh** (**Bake NavigationMesh**) na barra de ferramentas acima da viewport 3D. Depois
   de alguns segundos, a malha azul na viewport se atualiza: um buraco do tamanho do raio do agente (0,5 m) em volta do
   objeto, malha contínua onde ele estava antes.
4. Salve a cena (Ctrl+S): a malha fica embutida na cena.

Os parâmetros de geração ficam no próprio recurso: selecione `NavigationRegion3D` e expanda `Navigation Mesh` no
Inspetor (Inspector).

Depois de gerar de novo, rode os testes ([Testes](../testing.md)): as rotas deles seguem a malha. No jogo em execução,
Depurar → Navegação Visível (Debug → Visible Navigation) no editor mostra a malha, e Configurações (F10) → Interface →
**Linha do caminho do personagem** mostra o caminho do personagem.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
