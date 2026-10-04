<!-- translation of docs/en/systems/characters.md @ 1eac13a73cbf -->
# Personagens

> Esta é uma tradução do [original em inglês](../../en/systems/characters.md).
> Onde houver diferenças, a versão em inglês é a correta.

Os modelos de personagem são montados a partir de primitivas (cápsulas, cilindros, esferas, prismas) por um script e
ficam separados da lógica, em `shared/characters/`. O mesmo modelo pode ser o do herói ou ficar parado no nível.

## Modelos e equipamentos

| Modelo (`shared/characters/models/`) | Quem | Equipamento |
|---|---|---|
| `knight.tscn` | Cavaleiro: armadura de placas, um elmo em forma de balde com viseira em T e uma crista vermelha, uma sobreveste vermelha com uma cruz, ombreiras | Espada, escudo redondo com uma cruz |
| `ranger.tscn` | Patrulheiro: um capuz verde com cauda, olhos claros na sombra dele, uma aljava de flechas nas costas | Arco |
| `mage.tscn` | Mago: um manto roxo em forma de sino com debrum dourado, um chapéu pontudo torto, uma barba branca | Um orbe brilhante flutuante com anéis, um grimório |
| `dwarf.tscn` | Anão: baixo e largo, uma barba ruiva com uma conta, um nariz, um elmo com chifres | Machado de duas mãos |
| `rogue.tscn` | Ladino: um capuz escuro, olhos amarelos, uma máscara vermelha, uma capa de três painéis, uma bolsa no cinto | Duas adagas, a esquerda em empunhadura invertida |

Convenções que todo modelo segue:

- Fica virado para −Z, com os pés na origem.
- As mãos são nós vazios `RightHand` e `LeftHand`, "mãos invisíveis". Uma cena de `equipment/` (cajado, espada,
  escudo, arco, machado, adaga, livro, orbe) vai numa mão; a origem do equipamento é onde ele é empunhado. Para trocar
  uma arma, substitua o filho do nó da mão: em tempo de execução no jogo, ou de forma permanente na cena do modelo. A
  inclinação do item é a rotação dele na mão.
- Os materiais compartilhados dos equipamentos (aço, latão, couro, osso, gemas e olhos brilhantes) estão em
  `materials/`; as cores do corpo e das roupas ficam dentro das cenas dos modelos.

## Aparências do herói

O herói é uma de dez aparências de mago (o Mago de Batalha por padrão), colocada em `Player/Visual/Model`, que gira com
`Visual`. O cajado fica na mão direita. Todas as aparências têm em comum um corpo em cápsula do tamanho do jogador,
olhos próprios (`EyeRight`, `EyeLeft`) e um cajado em `RightHand`, então qualquer uma delas serve como herói.

| # | Aparência | O que a diferencia |
|---|---|---|
| 1 | Mago da Tempestade | Um manto cor de ardósia com relâmpagos e barra brilhante, nuvens de tempestade nos ombros, um capuz com uma crista que solta faíscas e olhos estreitos de faísca na sombra dele, um cajado com uma bola de raio |
| 2 | Cronomante | Um manto turquesa com bronze, um mostrador de relógio no peito, um halo de relógio, engrenagens flutuantes, óculos de latão com lentes âmbar, um cajado de ampulheta |
| 3 | Místico Encapuzado | Um capuz fundo e uma capa; sem rosto, só dois olhos âmbar brilhantes na sombra |
| 4 | Astrólogo | Um manto azul-noite com estrelas, um chapéu com uma lua, olhos grandes olhando para as estrelas, um cajado com uma estrela entre anéis |
| 5 | Piromante | Um manto escarlate com chamas ao longo da barra, nos ombros e como coroa, olhos de fogo zangados, um cajado de fogo |
| 6 | Criomante | Um manto branco com pele, uma coroa de gelo e cristais nos ombros, olhos azul-claros calmos, um cajado de cristal |
| 7 | Druida | Um manto marrom, uma capa de folhas, chifres ramificados, olhos âmbar de animal com pupilas em fenda, um cajado nodoso com uma semente |
| 8 | Necromante | Um manto preto e violeta com barra esfarrapada, um colarinho em leque, luzes verdes nas órbitas, uma caveira no ombro e no cajado |
| 9 | Arquimago | Mantos brancos e dourados, uma barba, um chapéu alto com uma safira, olhos de safira bondosos e um monóculo, um anel de runas em volta da cintura |
| 10 | Mago de Batalha | Um manto curto, ombreiras de placas, uma capa, poções no cinto, um livro no quadril, olhos dourados sob sobrancelhas severas, um cajado-lança |

Os modelos estão em `shared/characters/models/mage_options/`, e os cajados deles em `equipment/staff*.tscn`. A mão fica
a 0,52 m do eixo do corpo, para que a base do cajado não afunde no manto; o Arquimago o segura a 0,55 m, o Mago de
Batalha a 0,49 m. As aparências do herói só têm `RightHand`; o livro do Mago de Batalha fica pendurado em `LeftHip`.

No nível, as dez ficam em fila do lado sul do muro sul, de costas para ele (a leste da abertura no muro), viradas para o
sul, cada uma com seu número sobre a cabeça. Há uma passagem livre na frente de toda a fila.

## CharacterAppearance

Troca o modelo em tempo de execução (Configurações → Personagem → **Aparência do herói**). `set_look(number)` remove o
modelo antigo e coloca o novo no lugar dele com o mesmo nome. Também redefine a interpolação de física do novo modelo
(senão o modelo deslizaria a partir da origem) e passa a `RightHand` do novo modelo ao `HandSway`, para que o cajado
volte a balançar com os passos. A silhueta pega as novas malhas sozinha.

| Propriedade | Padrão | Significado |
|---|---|---|
| `slot` | — | O nó que contém o modelo (`Visual` no jogador, girado pelo `GroundCharacter`) |
| `model_name` | `Model` | Nome do nó do modelo dentro de `slot` |
| `models` | — | Cenas de modelos para escolher; o número da aparência é a posição nesta lista, a partir de 1 |
| `hand_sway` | — | Quem recebe a mão do novo modelo; se vazio, a mão não balança |
| `hand_path` | `RightHand` | Onde fica no modelo a mão que segura um item |

`get_look()` retorna o número atual (0 para um modelo fora da lista), `get_model()` o nó do modelo. Sinal:
`look_changed(model)`.

## HandSway: um cajado na mão, não colado ao lado do corpo

`HandSway` (`RightHandSway` no jogador) move o nó da mão do modelo em relação à sua posição de repouso:

- **Com os passos**, por `GroundCharacter.get_step_phase()`, o mesmo ritmo que os sons de passos seguem. A cada passo,
  a mão está num extremo (na frente e atrás, alternadamente, ±7 cm) e no ponto mais baixo (2,5 cm); no meio entre os
  passos, ela está no centro. O item atrasa um pouco na inclinação (±7°). O balanço cresce com a velocidade, uma vez e
  meia maior na corrida rápida, e some quando o personagem para ou está no ar.
- **Na corrida**, o item se inclina para a frente (6°).
- **Inércia** numa mola (1,8 Hz, amortecimento 0,45): na aceleração a ponta vai para trás, na frenagem para a frente,
  nas curvas para fora, e ela oscila até se acomodar. Na aterrissagem, a mão desce mais quanto mais rápida a queda; no
  impulso, um pouco.

Ele roda no tick de física depois do corpo, então a interpolação de física o suaviza assim como o corpo. O ritmo dos
passos é contínuo: pare no meio de um passo e o próximo passo vem `first_step_distance` depois que você voltar a andar,
mas a fase não salta; ela chega ao número inteiro nesse passo. Para outra mão ou um NPC, adicione outro `HandSway` com
a sua própria mão. As amplitudes, a inclinação e a mola são propriedades exportadas nos grupos Swing e Inertia.

## OccludedSilhouette: uma forma, a arma contornada, uma borda

Onde algo esconde o herói (a montanha, uma casa, uma árvore), o herói aparece como uma silhueta azul-clara: uma forma
plana para o corpo, o equipamento na mão contornado por cima dela e uma borda em volta de tudo.

`OccludedSilhouette` (`Silhouette` no jogador) define `material_overlay` em todas as malhas do modelo, inclusive malhas
adicionadas depois (uma nova aparência ou arma, por `SceneTree.node_added`). Os materiais do próprio modelo não mudam,
então o mesmo modelo no nível não tem silhueta. As malhas do corpo e as malhas sob os nós das mãos (`gear_nodes`:
`RightHand`, `LeftHand`) recebem cadeias de passes diferentes.

Cada pixel da tela é pintado uma vez, graças ao stencil buffer: um passe só desenha onde o valor do stencil é menor que
o seu e já grava o seu próprio (`stencil_mode read, write, compare_greater, N`). Os shaders e materiais estão em
`addons/iso_orbit/occluded_silhouette/`:

| Passe | `render_priority` | Stencil | O que faz |
|---|---|---|---|
| `silhouette_mask` | 1 | grava 4 | Invisível, com teste de profundidade: marca onde o personagem está visível por si mesmo, para que nada mais desenhe ali |
| `silhouette_body` | 2 | < 2 → 2 | Preenchimento plano do corpo: as partes não se sobrepõem e se fundem numa só forma |
| `silhouette_gear` | 3 | < 3 → 3 | Preenchimento mais claro para o equipamento, por cima do corpo e com contorno próprio |
| `silhouette_outline` | 4 | < 1 → 1 | A borda: malhas infladas ao longo das normais em 0,4% da altura da tela; só resta a parte fora da forma inteira |

Os preenchimentos e a borda só são desenhados onde um obstáculo está pelo menos 30 cm mais perto que o fragmento (o
buffer de profundidade é convertido em metros em `silhouette_common.gdshaderinc`). Objetos transparentes são ordenados
primeiro por `render_priority`, então os passes rodam em ordem para todas as malhas de uma vez.

`outline_enabled` (Configurações → Exibição → **Contorno da silhueta atrás de obstáculos**) remove o último passe das
cadeias. A largura da borda é o parâmetro `width` de `silhouette_outline.tres`; as cores são `color` nos preenchimentos
e na borda.

Dois detalhes da engine: o stencil buffer é experimental no Godot 4.5+ e só pode ser lido num passe transparente. E no
Godot 4.7 (D3D12 e Vulkan) a projeção nos shaders é invertida em Y: `PROJECTION_MATRIX[1][1]` é negativo. Sem `abs()`,
a conversão "fração da tela → metros" fica negativa, a malha da borda encolhe e a borda desaparece.

## Editando os modelos

Os modelos foram montados a partir de primitivas por um script e agora são cenas comuns: edite-as no editor como
qualquer outra cena.

---

*Esta página corresponde ao Iso & Orbit 1.1.0.*
