<!-- translation of docs/en/systems/characters.md @ 48c5e73646e2 -->
# Personagens

[← Índice da documentação](../index.md)

> Esta é uma tradução do [original em inglês](../../en/systems/characters.md).
> Onde houver diferenças, a versão em inglês é a correta.

Os modelos de personagem são montados a partir de primitivas (cápsulas, cilindros, esferas, prismas) por um script e
ficam separados da lógica, em `shared/characters/`. O mesmo modelo pode ser o do herói ou ficar parado no nível.
Para copiar o herói montado e seus arquivos, siga
[Usando no seu projeto](../integration.md#transferindo-o-herói-da-demo-para-o-seu-projeto).
[Configurações](../configurations.md) mostra escolhas de controle e câmera.

## Modelos e equipamentos

| Modelo (`shared/characters/models/`) | Quem | Equipamento |
|---|---|---|
| `knight.tscn` | Cavaleiro: armadura de placas, um elmo em forma de balde com viseira em T e uma crista vermelha, uma sobreveste vermelha com uma cruz, ombreiras | Espada, escudo redondo com uma cruz |
| `ranger.tscn` | Patrulheiro: um capuz verde com cauda, olhos claros na sombra dele, uma aljava de flechas nas costas | Arco |
| `mage.tscn` | Mago: um manto roxo em forma de sino com debrum dourado, um chapéu pontudo torto, uma barba branca | Um orbe brilhante flutuante com anéis, um grimório |
| `dwarf.tscn` | Anão: baixo e largo, uma barba ruiva com uma conta, um nariz, um elmo com chifres | Machado de duas mãos |
| `rogue.tscn` | Ladino: um capuz escuro, olhos amarelos, uma máscara vermelha, uma capa de três painéis, uma bolsa no cinto | Duas adagas, a esquerda em empunhadura invertida |

Convenções dos cinco modelos independentes acima:

- Fica virado para −Z, com os pés na origem.
- As mãos são nós vazios `RightHand` e `LeftHand`, "mãos invisíveis". Uma cena de `equipment/` (cajado, espada,
  escudo, arco, machado, adaga, livro, orbe) vai numa mão; a origem do equipamento é onde ele é empunhado. Para trocar
  uma arma, substitua o filho do nó da mão: em tempo de execução no jogo, ou de forma permanente na cena do modelo. A
  inclinação do item é a rotação dele na mão.
- Os materiais compartilhados dos equipamentos (aço, latão, couro, osso, gemas e olhos brilhantes) estão em
  `materials/`; as cores do corpo e das roupas ficam dentro das cenas dos modelos.

## Aparências do herói

O herói usa uma de dez aparências de mago (Necromante, aparência 8, por padrão), colocada em
`Hero/Character/Visual/Hover/Model`: gira com `Visual` e flutua com `Hover` quando ativado. O cajado fica na mão
direita. Todas as aparências cabem na cápsula de colisão separada do jogador, têm olhos próprios (`EyeRight`,
`EyeLeft`) e um cajado em `RightHand`, portanto qualquer uma funciona como herói.

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

No nível inicial (`shared/world/world.tscn`), as dez ficam em fila do lado sul do muro sul, de costas para ele
(a leste da abertura no muro), viradas para o
sul, cada uma com seu número sobre a cabeça. Há uma passagem livre na frente de toda a fila.

## CharacterAppearance

Troca o modelo em tempo de execução (Configurações → Personagem → **Aparência do herói**). `set_look(number)` remove o
modelo antigo e coloca o novo no lugar dele com o mesmo nome. Também redefine a interpolação de física do novo modelo
(senão o modelo deslizaria a partir da origem) e passa a `RightHand` do novo modelo ao `HandSway`, para que o cajado
volte a balançar com os passos. A silhueta pega as novas malhas sozinha.

| Propriedade | Padrão | Significado |
|---|---|---|
| `slot` | — | O nó que contém o modelo (`Visual/Hover` no jogador: o nó de flutuação sob `Visual`, girado por `GroundCharacter`) |
| `model_name` | `Model` | Nome do nó do modelo dentro de `slot` |
| `models` | — | Cenas de modelos para escolher; o número da aparência é a posição nesta lista, a partir de 1 |
| `hand_sway` | — | Quem recebe a mão do novo modelo; se vazio, a mão não balança |
| `hand_path` | `RightHand` | Onde fica no modelo a mão que segura um item |

`get_look()` retorna o número atual (0 para um modelo fora da lista), `get_model()` o nó do modelo. Sinal:
`look_changed(model)`.

### Usando seu modelo com o herói jogável

1. Edite `gdscript/player/player.tscn` usado pelo `playable_hero.tscn` copiado ou substitua a instância
   `Character` do herói por uma cópia da cena, preservando os caminhos dos nós ou reatribuindo as referências
   exportadas. Troque `Visual/Hover/Model` pela cena do seu modelo e chame a raiz de `Model`. Ponha seus pés na
   origem local e a frente voltada para −Z. Corrija dentro da cena a orientação de uma malha diferente, deixando
   `Visual` livre para `GroundCharacter` girar. A cápsula fica no corpo, separada do modelo: redimensione
   `CollisionShape3D` e gere novamente a malha de navegação se o personagem precisar de outra folga (veja
   [Mundo e navegação](world-and-navigation.md#camadas-de-física-e-navegação)).
2. Para alternar aparências, ponha as cenas dos seus modelos em `Appearance.models`; a numeração começa em 1.
   Dê a cada uma um nó de mão em `Appearance.hand_path` (`RightHand` por padrão). Se não houver mão, retire
   `RightHandSway` e limpe `Appearance.hand_sway`. `CharacterAppearance.set_look()` redireciona o balanço e a
   silhueta encontra as novas malhas automaticamente.
3. Com um só modelo, retire `Appearance` e limpe a referência `appearance` do herói jogável. Retire também
   `RightHandSway` se não houver item na mão. Se mantiver `Appearance` na demo completa, substitua a lista
   `models`: `SettingsApplier` chama `set_look()` com o número salvo na inicialização e uma lista antiga faria
   voltar um modelo de mago.

O modelo precisa caber na cápsula e sob os tetos próximos. Na flutuação, ele sobe sem mover a forma de colisão;
deixe espaço sobre a cabeça ou mantenha `Hover.enabled` desligado. `Silhouette.target` e
`CameraArm.fade_target` já apontam para `Visual`, portanto incluem também um modelo substituto sob ele.

## HandSway: um cajado na mão, não colado ao lado do corpo

`HandSway` (`RightHandSway` no jogador) move o nó da mão do modelo em relação à sua posição de repouso:

- **Com os passos**, por `GroundCharacter.get_step_phase()`, o mesmo ritmo que os sons de passos seguem. A cada passo,
  a mão está num extremo (na frente e atrás, alternadamente, ±7 cm) e no ponto mais baixo (2,5 cm); no meio entre os
  passos, ela está no centro. O item atrasa um pouco na inclinação (±7°). O balanço cresce com a velocidade, uma vez e
  meia maior na corrida rápida, e some quando o personagem para ou está no ar. Sem passos
  (`is_counting_steps()` falso: `steps_enabled` desligado ou herói flutuando), o balanço desaparece e volta com
  os passos.
- **Na corrida**, o item se inclina para a frente (6°).
- **Inércia** numa mola (1.8 Hz, amortecimento 0.45), a partir de `GroundCharacter.get_local_acceleration()`:
  na aceleração a ponta vai para trás, na frenagem para a frente, nas curvas para fora, e oscila até se acomodar.
  Degraus não a sacodem. Ao tocar o chão, a mão desce mais quanto mais rápida a queda (`touched_floor`, portanto
  até um toque suave a move); no impulso, desce um pouco. `tilt_per_acceleration` (0.45°) positivo faz o item
  ficar para trás; negativo o inclina para a aceleração. A mola é `DampedSpring`, também usada por
  `CharacterHover`.

Ele roda no tick de física depois do corpo, então a interpolação de física o suaviza assim como o corpo. O ritmo dos
passos é contínuo: pare no meio de um passo e o próximo passo vem `first_step_distance` depois que você voltar a andar,
mas a fase não salta; ela chega ao número inteiro nesse passo. Para outra mão ou um NPC, adicione outro `HandSway` com
a sua própria mão. As amplitudes, a inclinação e a mola são propriedades exportadas nos grupos Swing e Inertia.

## CharacterHover: flutuando acima do chão

`CharacterHover` faz um `GroundCharacter` parecer flutuar: o modelo permanece `height` acima do chão, desliza
pelos degraus em vez de saltar sobre eles, oscila suavemente para cima e para baixo, inclina-se com movimento e
aceleração e abaixa um pouco ao tocar o chão. Só o modelo se move. O corpo continua andando normalmente: encostas,
degraus, pulos, proteção de bordas, caminhos e câmera funcionam como antes. Seu `FallSettings` opcional pode mudar
a aceleração da descida e limitar a velocidade; o herói fornecido o usa para cair mais devagar. Na demo,
Configurações → Personagem → **Flutuar acima do chão** ativa o efeito.

O nó fica entre o que o personagem gira e o modelo:

```
Player (GroundCharacter)   Hero/Character na demo
└── Visual            girado por GroundCharacter para a direção do movimento
    └── Hover         CharacterHover: sobe e se inclina
        └── Model     aparência; CharacterAppearance.slot é Visual/Hover
```

O personagem só escreve o giro de `Visual`, e o nó de flutuação só sua própria transformação; eles não disputam
um nó. Nova aparência de `CharacterAppearance` entra sob o nó de flutuação (`slot`); silhueta e transparência
da câmera
acham o modelo por conta própria. A inclinação usa os eixos de `Visual`; mesmo que o nó de flutuação seja girado
na cena para um modelo voltado em outra direção, ele ainda se inclina rumo ao movimento.

### Passos

Por padrão, flutuar suprime eventos de passos. O nó chama `GroundCharacter.set_steps_suppressed(self, true)`:
sem `stepped`, som de passos ou balanço do cajado por passos. Assim que o modelo se acomoda no chão, libera os
passos, que voltam a ser contados se `steps_enabled` estiver ligado. O nó nunca altera `steps_enabled`: o controle
do jogo continua como estava, e vários componentes podem suprimir passos sem se anularem. Ao sair da árvore,
libera os passos; ao voltar, suprime novamente. `steps_while_floating` os preserva, útil para criatura que se
impulsiona do chão no ritmo deles. `GroundCharacter.is_counting_steps()` informa se há contagem agora.

### A queda

Com `fall` definido (um `FallSettings`, veja [Locomoção](locomotion.md#a-queda)), a flutuação o põe no lugar da
queda própria do personagem enquanto o modelo estiver elevado, desde o começo da subida até acomodar-se
(`GroundCharacter.set_fall_override(self, fall)`, prioridade 0). Após o topo do pulo ou uma borda, a queda ganha
velocidade mais lentamente, até um limite. A subida do pulo não muda. Se a flutuação for ligada durante uma queda,
a velocidade se reduz até o limite em `braking_time`; ao desligá-la, continua lenta até o modelo se acomodar e
depois volta a acelerar normalmente. Ao sair da árvore, o nó devolve a queda. Um `fall` vazio deixa a queda
original, exatamente como sem flutuação. No início de cada subida, o nó torna a atribuir sua queda, tornando-a a
mais recente entre as de prioridade 0; uma queda do jogo com prioridade maior prevalece. Trocar o `fall` do nó
enquanto ele flutua mantém sua posição na ordem.

O recurso da demo é `gdscript/player/player_floating_fall.tres`: escala da gravidade 0.5 em vez dos 3 do corpo,
e limite de 2 m/s para baixo. Após o topo de um pulo de 1 m, o herói flutuante leva 0.68 s para descer, em vez de
0.25 s, e toca o chão a 2 m/s, abaixo de `landing_min_speed` (2.5 m/s): é um contato suave sem `landed` nem som
de aterrissagem.

### Como acompanha o chão

O modelo flutua sobre uma altura do chão suavizada. No solo, o nó olha adiante na direção do movimento e se
aproxima da altura encontrada em `glide_time`. Olha exatamente tão adiante quanto o atraso da suavização, portanto
não há atraso numa rampa. Em escadas, o modelo começa a subir antes do degrau e percorre a sequência por uma linha
suave, sem descer no meio da subida. Sobre uma borda de degrau, fica cerca de meio degrau abaixo da altura que
teria sobre o degrau de baixo: segue a linha geral da escada, não cada piso.

A direção adiante é examinada com raios em trechos de no máximo 0.15 m, até 0.9 m à frente. Em cada trecho o chão
só pode subir ou descer até a altura de um degrau (`max_step_height`) ou de uma encosta máxima. Um raio que começa
dentro de algo não encontra chão, então uma parede também interrompe a busca. Assim o modelo permanece nivelado
diante de borda, vão ou parede que o corpo não atravessará e não sobe rumo a um terraço atrás de uma cerca. Nas
extremidades da rampa, arredonda a mudança: começa a subir pouco antes e se nivela antes do topo, até cerca de
0.05 m abaixo da altura na rampa de 15° da demo.

No ar e no tick da aterrissagem, o modelo acompanha exatamente o corpo: pulo e queda seguem o mesmo arco. O que
restou do deslizamento ao decolar desaparece em `glide_time`.

Os raios custam até sete verificações por tick com o personagem flutuando e correndo, uma parado, nenhuma no ar ou
sem flutuação. Em teleporte (`GroundCharacter.teleport()`), o modelo é colocado imediatamente, com interpolação
física ligada ou desligada; o mesmo ocorre após reiniciar manualmente a interpolação
(`reset_physics_interpolation()`, sem efeito quando desligada) e após deslocamento horizontal de mais de um metro
num tick. `snap()` também força o ajuste.

### Oscilação

A oscilação depende do tempo e acontece até parado: um ciclo vertical leva `bob_period` (2.4 s) e tem amplitude
`bob_height` (4 cm). O movimento muda isso proporcionalmente à velocidade, da parada à corrida (mistura de 0 a
1): na velocidade de corrida, fica `run_bob_rate` (1.5) vez mais rápido e `run_bob_scale` (0.5) vez tão amplo,
mais calmo e rápido. A fase avança com o tempo, então mudar a velocidade não causa saltos. Com
`random_bob_phase`, cada personagem começa num ponto aleatório, evitando oscilar em uníssono. O modelo nunca
desce mais que `height`, portanto não afunda no chão.

### Inclinação e inércia

- **Inclinação no movimento.** `run_lean` (8°) inclina na direção da corrida: para a frente, de lado ou para trás
  conforme o deslocamento; na corrida rápida, pode alcançar `max_lean_scale` (1.5) vez esse valor.
- **Inércia.** `tilt_per_acceleration` por 1 m/s² de `GroundCharacter.get_local_acceleration()`, até
  `max_inertia_tilt` (15°) em qualquer direção. O sinal é como em `HandSway`: positivo atrasa a inclinação, como
  peso preso a um fio; negativo inclina para a aceleração, como veículo flutuante: à frente ao acelerar, atrás ao
  frear, para dentro da curva. O padrão é −0.25°.
- Ambas passam por molas (`spring_frequency` 1.5 Hz, `spring_damping` 0.5). O modelo gira em torno de
  `tilt_pivot_height` (0.9 m) acima dos pés, aproximadamente na cintura, para que os pés não oscilem demais.
- **Abaixamento.** Ao tocar o chão (`touched_floor`, inclusive em toque suave), o modelo recebe impulso para baixo
  de `landing_kick` por 1 m/s de velocidade da queda; ao saltar, de `jump_kick`. A mola o traz de volta. Nunca
  abaixa mais que `max_drop` (0.15 m) nem mais que a altura sobre o chão. Na demo, `landing_kick` é 0.2, gerando
  cerca de 2 cm de abaixamento no contato suave a 2 m/s.

### Ligando e desligando

Ao ativar, o modelo sobe até `height` em `rise_time` (0.5 s), suavemente no começo e no fim; ao desativar,
acomoda-se no mesmo tempo, e os passos voltam quando toca o chão. Oscilação, inclinação e abaixamento crescem e
desaparecem com a subida. Se `enabled` for definido antes do primeiro tick (na cena ou por ajuste salvo na
inicialização), atua imediatamente, sem animação de subida.

`floating_changed(floating)` ocorre no começo da subida e ao acomodar-se. `is_floating()` informa se flutua
agora; `get_hover_height()` informa a altura do modelo sobre os pés do corpo.

### Propriedades

| Grupo | Propriedade | Padrão | Significado |
|---|---|---|---|
| | `character` | — | `GroundCharacter`; se vazio, o mais próximo acima do nó |
| | `enabled` | ligado (desligado na cena da demo) | Flutuar |
| | `height` | 0.35 m | Altura dos pés do modelo sobre o chão |
| | `rise_time` | 0.5 s | Duração de subida e acomodação; 0 é imediato |
| | `steps_while_floating` | desligado | Preservar passos durante a flutuação |
| | `fall` | — (`player_floating_fall.tres` na demo) | Queda durante a flutuação; vazio: igual à queda normal |
| Deslizamento | `glide_time` | 0.3 s | Tempo para atingir 95% da nova altura do chão; 0 segue cada degrau imediatamente |
| Oscilação | `bob_height` | 0.04 m | Amplitude vertical com o personagem parado |
| | `bob_period` | 2.4 s | Duração de um ciclo parado, a partir de 0.5 s |
| | `run_bob_scale` | 0.5 | Fração de `bob_height` na velocidade de corrida |
| | `run_bob_rate` | 1.5 | Multiplicador da frequência na velocidade de corrida |
| | `random_bob_phase` | ligado | Inicia numa fase aleatória |
| Inclinação | `run_lean` | 8° | Inclinação rumo ao movimento na velocidade de corrida |
| | `max_lean_scale` | 1.5 | Multiplicador máximo da inclinação na corrida rápida |
| | `tilt_pivot_height` | 0.9 m | Altura acima dos pés do ponto em torno do qual inclina |
| Inércia | `tilt_per_acceleration` | −0.25° por m/s² | Positivo fica para trás; negativo inclina na aceleração |
| | `max_inertia_tilt` | 15° | Limite da inclinação pela aceleração |
| | `landing_kick` | 0.05 (0.2 na demo) | Impulso para baixo no contato, por 1 m/s de queda |
| | `jump_kick` | 0.3 m/s | Impulso para baixo ao saltar |
| | `max_drop` | 0.15 m | Limite do abaixamento, sempre abaixo da altura sobre o chão |
| | `spring_frequency`, `spring_damping` | 1.5 Hz, 0.5 | Molas da inclinação e do abaixamento |

### Cuidados

- O modelo flutua `height` acima do corpo: `focus_height` da câmera e `occlusion_points` do braço são medidos
  a partir do corpo. Eleve-os se o modelo subir muito.
- Sob teto baixo, o modelo pode atravessá-lo: o corpo não considera a altura extra.
- Os degraus são suavizados só para o modelo. A câmera acompanha o corpo; `height_follow_time` suaviza a subida
  na tela (0.15 s na demo).
- Uma queda limitada abaixo de `landing_min_speed` nunca produz `landed`, som de aterrissagem ou qualquer efeito
  que espere aterrissagem real. Para ouvi-la, defina `max_speed` de `fall` como pelo menos `landing_min_speed` ou
  reduza `landing_min_speed`.
- Para cima deve ser +Y, como no restante do personagem.
- Com o tempo parado (`Engine.time_scale` 0), modelo flutuante e mão movida por `HandSway` ficam imóveis; veja
  [Locomoção](locomotion.md#groundcharacter).
- Uma configuração incorreta gera aviso ao iniciar: nó fora de `Visual`, nenhum modelo sob ele, segundo nó de
  flutuação no mesmo personagem ou `CharacterAppearance.slot` não apontando para ele.
- `DampedSpring` é compartilhada com `HandSway`: `update(target, frequency, damping, delta)`, `value`, `speed`,
  `keep_within(limit)`, `reset()`. A mola rígida é calculada em vários passos curtos por tick e permanece estável
  em qualquer configuração.

### Comportamento medido

Em `tests/character_state_checks.gd`, com ajustes da demo a 60 ticks de física e sem oscilação para medir o
trajeto:

- Parado: 0.31 a 0.39 m acima dos pés (0.35 m mais oscilação de 4 cm).
- Subindo e descendo os degraus a leste da plataforma: o modelo varia no máximo 0.031 m por tick, contra
  0.100 m de subida e 0.138 m de descida do corpo. Nunca se move contra o percurso e permanece pelo menos
  0.17 m acima do degrau sob ele.
- Na rampa: 0.347 a 0.350 m acima do chão no meio, sem atraso; nas extremidades, até 0.30 m.
- Num pulo sem impulsos adicionais, modelo e corpo mantêm a diferença de altura dentro de 0.6 mm no ar e na
  aterrissagem. Com impulsos, abaixa 0.021 m no contato a 2 m/s.
- A queda lenta: pulo de 1 m alcança 1.000 m e toca o chão a 2.00 m/s, sem evento de aterrissagem. Ligada
  durante queda a 6.4 m/s, a flutuação freia até 2.2 m/s em 0.3 s, no máximo 0.67 m/s por tick; desligada em
  queda, a velocidade fica em 2 m/s pelos 30 ticks da acomodação e então acelera a 29.4 m/s², como no chão.
- Diante da borda protegida da plataforma, de bloco de 0.4 m ou de muro com terraço atrás, não desce nem sobe.
- Desligada e ligada durante corrida: variação de no máximo 0.018 m por tick, acomodando-se em 31 ticks
  (`rise_time` 0.5 s); os passos retornam então. Com ajuste salvo como ligado, o herói flutua desde o primeiro
  quadro.

## OccludedSilhouette: uma forma, a arma contornada, uma borda

Onde algo esconde o herói (a montanha, uma casa, uma árvore), o herói aparece como uma silhueta azul-clara: uma forma
plana para o corpo, o equipamento na mão contornado por cima dela e uma borda em volta de tudo.

`OccludedSilhouette` (`Silhouette` no jogador) define `material_overlay` em todas as malhas do modelo, inclusive malhas
adicionadas depois (uma nova aparência ou arma, por `SceneTree.node_added`). Os materiais do próprio modelo não mudam,
então o mesmo modelo no nível não tem silhueta. As malhas do corpo e as malhas sob os nós das mãos (`gear_nodes`:
`RightHand`, `LeftHand`) recebem cadeias de passes diferentes. Com outros nomes de equipamentos, ajuste
`gear_nodes`; sem nós correspondentes, todas as malhas usam o preenchimento do corpo. Um `material_overlay`
anterior dessas malhas é substituído.

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
primeiro por `render_priority`, então os passes rodam em ordem para todas as malhas de uma vez. Para alterar a
separação, mude `min_gap` nos materiais de corpo, equipamento e contorno em conjunto. O componente monta as
cadeias em `_ready()`, então altere os materiais antes de iniciar a cena.

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

*Esta página corresponde ao Iso & Orbit 1.2.0.*
