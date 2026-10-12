<!-- translation of docs/en/editor_authoring.md @ a4a7c741507e -->
# Editando cenas no editor

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/editor_authoring.md).
> Onde houver diferenças, a versão em inglês é a correta.

As cenas da demo foram feitas para serem editadas no editor. Os nós são ligados no Inspector; os componentes verificam
a própria configuração e mostram um aviso no painel Cena (Scene) enquanto algo falta ou está errado; e o que o jogo
configura no início (a vista da câmera, o modelo de um personagem e o nome sobre a cabeça dele, o título na placa de um
portal, o tamanho de um objeto) também aparece no editor. Essas pré-visualizações nunca são salvas: uma cena salva
guarda o que você definiu, então o diff dela mostra só as suas alterações.

## Referências e avisos

Um componente que trabalha com outros nós tem referências a eles como propriedades: `PlayableHero.character`,
`GroundCharacter.mover`, `OccludedSilhouette.target` e assim por diante. Defina-as no Inspector arrastando um nó para o
campo. Enquanto uma referência de que o componente precisa estiver vazia, ou um nó estiver onde não pode funcionar (um
`NavigationMover` que não está sob o corpo que move, um `LevelPortal` sem cena de destino, uma ação de entrada ausente
do Input Map), o painel Cena mostra um sinal de aviso ao lado do nó; passe o mouse sobre ele para ver o motivo. Os
avisos acompanham suas edições: aparecem e somem conforme você muda uma propriedade, adiciona ou remove um filho, edita
a curva de uma rota, o `max_drop` de uma proteção contra bordas ou os ajustes de queda de um personagem. Não é preciso
reabrir a cena.

Os componentes se verificam no editor porque seus scripts são scripts de ferramenta (tool scripts). No editor, eles só
verificam e pré-visualizam: ali não rodam entrada, física nem temporizadores, e nada do que calculam é gravado na cena.
No jogo, funcionam como sempre.

## O nível inicial

`gdscript/main.tscn` contém o host de níveis, `Levels`, com o nível inicial, `World`, como filho, e
`Levels.initial_level` o indica. Sem ele, o host começa no seu primeiro filho `Node3D`; com vários filhos 3D e nenhum
indicado, ele mostra um aviso. Veja [Níveis](systems/levels.md).

## A câmera no editor

`Hero/CameraRig` mostra a vista com que o jogo começa: o rig fica no alvo, `focus_height` acima dele, girado por
`start_yaw`, inclinado e afastado conforme `start_zoom`, e o braço mostra a câmera a essa distância. Mude essas
propriedades para enquadrar o início; a visão 3D acompanha na hora.

O jogo define a transformação do rig, a da câmera e, sob um rig, o `length` do braço a cada quadro, então no editor
eles também são pré-visualizações: um rig ou uma câmera movidos à mão voltam para onde o jogo os coloca, e sob um rig o
`length` do braço fica somente leitura. Ao salvar, ficam os valores com que a cena foi carregada, então a
pré-visualização nunca aparece num diff, e a cena que posiciona o herói nunca recebe uma cópia da posição da câmera
dele. Um rig sem alvo é diferente: o jogo não o move, então a posição dele é sua e é salva como você a definir; só o
giro dele é pré-visualizado.

## Configurações da janela de configurações

`SettingsApplier` aplica as configurações salvas do jogador (F10) sobre os valores definidos na cena. Os valores da
cena também são os padrões: uma configuração que o jogador não mudou mantém o valor da cena, e **Redefinir tudo** volta
a eles. Desligue `SettingsApplier.use_saved_settings` para rodar os nós da cena exatamente como definidos enquanto os
ajusta no Inspector; a janela de configurações então os deixa em paz e muda só as configurações da engine (tela cheia,
taxa de quadros, V-Sync, interpolação de física, escala da interface, idioma, volume). Veja
[Configurações](settings.md).

## Objetos sólidos

Um objeto sólido é uma cena com uma raiz `StaticProp`, um `StaticBody3D` com `shared/world/props/static_prop.gd`. Suas
partes visíveis e formas de colisão são filhas da raiz, agrupadas, então um clique na visão 3D seleciona o objeto
inteiro.

- **Mova-o** pela raiz.
- **Redimensione-o** com `dimensions`, em metros ao longo dos eixos do próprio objeto: as partes visíveis e a colisão
  mudam juntas. 0 num eixo mantém o tamanho das partes ao longo dele, então um objeto novo, em `(0, 0, 0)`, tem o
  tamanho com que foi feito, e um pilar mais alto só precisa da altura. Não aplique escala à raiz, que então mostra um
  aviso; também não aplique escala aos filhos dela, e uma malha aumentada ou diminuída precisa que sua forma de colisão
  mude junto.
- **Recolora-o** com `surface_material`: ele substitui o material de todas as partes visíveis; vazio mantém os
  materiais próprios delas.

Os objetos que os níveis compartilham são cenas em `shared/world/props/`: `stone_pillar.tscn`, `solid_box.tscn` (os
muros, caixotes, a plataforma e sua rampa), `grove_tree.tscn`, `rock.tscn` e os objetos sólidos da floresta, do
acampamento e do sítio (um arbusto não tem colisão e não é um `StaticProp`). Uma instância define seu próprio
`dimensions` e `surface_material`; edite a cena do objeto para mudar todas as suas instâncias. Uma parte usada uma só
vez fica direto no seu nível, com uma raiz `StaticProp` própria: o chão da clareira, a escada do platô, as sebes do
labirinto, as figuras nos locais, as dez aparências do herói, o chão e os muros da borda da ilha. As sebes mantêm o
tamanho das suas malhas: as folhas delas precisam de uma malha subdividida em células de cerca de 25 cm, então uma sebe
de outro tamanho recebe uma malha desse tamanho, não `dimensions`.

Edite as partes como de costume: mova um filho, troque uma malha ou uma forma, adicione uma parte. O objeto toma a
mudança como sua nova forma: nos eixos em que `dimensions` é 0, ele assume o novo tamanho das partes; nos outros,
mantém seu estiramento. Um objeto novo não é agrupado sozinho: selecione sua raiz e pressione o botão Group da barra de
ferramentas da visão 3D. Ao salvar, as partes ficam como você as fez; o redimensionamento é uma pré-visualização,
aplicada de novo quando a cena abre e quando o jogo começa. Uma forma redimensionada é uma cópia própria, então
redimensionar uma instância nunca muda outra. Uma forma redonda ou girada esticada de modo desigual vira uma forma
convexa esticada do mesmo jeito.

Mantenha partes que se movem sob um `Node3D` simples: um nó que se anima sozinho não pode ser o nó que o objeto
redimensiona. Na montanha, o objeto redimensiona e posiciona `CrystalAnchor`, e o filho dele, `Crystal`, gira e sobe e
desce.

Depois de mudar a colisão de um objeto (movendo, redimensionando ou editando-o), gere a malha de navegação novamente,
veja [Mundo e navegação](systems/world-and-navigation.md#gerando-novamente-a-malha-de-navegação).

## Patrulhas

O cavaleiro da clareira percorre uma rota. Abra `shared/world/world.tscn` e selecione `Routes/KnightPatrol`, um
`Path3D`: edite a curva na visão 3D com as ferramentas de curva, e o cavaleiro percorre a linha desenhada ali, virando
suavemente nas curvas dela. Para arredondar um canto, ative **Select Control Points** na barra de ferramentas e arraste
a partir do ponto com Shift para puxar as alças dele. Mantenha a linha afastada das sebes por cerca da largura do
cavaleiro: ao longo dela ele não procura um caminho em volta delas. O cavaleiro (`NavigationRegion3D/Characters/Knight`,
uma instância de `gdscript/npc/knight_patrol.tscn`) se refere a ela em **Route**. Do seu lugar junto à casa ele anda até
o primeiro ponto da rota e, depois do último, volta pelo caminho mais curto: esses dois caminhos não fazem parte da
linha desenhada. A rota pertence ao nível, então o mesmo personagem pode percorrer outra rota em outro nível. O
patrulheiro da ilha (`island_patrol.tscn`) percorre `Routes/IslandPatrol` na ilha. Uma rota sem pontos, ou uma dentro do
personagem, mostra um aviso na raiz do personagem, `Knight`.

No editor, um personagem em patrulha mostra seu modelo e o nome sobre a cabeça; nenhum dos dois é salvo na cena. Sua
raiz define **Model Scene**, **Speaker Name** (sobre a cabeça e nas legendas) e **Blocked Line** (o que ele diz quando
alguém fica no seu caminho por tempo suficiente). Sua caminhada é definida em `Character/PatrolController` (ative
**Editable Children**): **Cycle Wait**, a espera em casa após uma ronda (10 s); **Waypoint Wait**, a parada em cada
ponto da curva; **Blocked Delay**, quanto tempo alguém precisa ficar no caminho antes da fala (2.5 s para o cavaleiro);
**Blocking Distance** e **Blocking Angle**, a área à frente dele onde alguém o detém: 1 m adiante, abrindo-se 25° para
cada lado, como o facho de uma lanterna. Dos lados e atrás dele, ninguém o detém. Veja
[Locomoção](systems/locomotion.md#patrolcontroller-percorrendo-uma-rota).

## Verificando a parte do editor

`tests/run_checks.gd` verifica o jogo, mas não consegue rodar o editor. A parte do editor, isto é, os avisos que
acompanham as edições, as pré-visualizações e o que é salvo nas cenas, tem verificações próprias: abra
`tests/editor_tool_checks.tscn` e pressione **Run Checks** no Inspector. O resultado aparece ali em **Status** e
**Results** e em `.godot/editor_tool_checks/results.json`; a saída recebe a linha de status. As verificações salvam
suas cenas só nessa pasta, que cada execução limpa: nenhuma cena do projeto nem nenhuma configuração do jogador é
gravada. Veja [Testes](testing.md#verificações-no-editor).

---

*Esta página corresponde ao Iso & Orbit 1.3.0.*
