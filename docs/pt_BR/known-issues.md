<!-- translation of docs/en/known-issues.md @ 2fc99af68b14 -->
# Problemas conhecidos

[← Índice da documentação](index.md)

> Esta é uma tradução do [original em inglês](../en/known-issues.md).
> Onde houver diferenças, a versão em inglês é a correta.

Limitações do projeto e peculiaridades da engine que ele contorna. Cada item diz o que você vê e o que fazer.

## Limitações

- **Só mouse e teclado.** Não há suporte a gamepad.
- **Sem remapeamento de teclas no jogo.** Altere os vínculos em Project Settings → Input Map ou por `InputMap`
  no código. A interface atualiza os nomes, mas não há tela de remapeamento, detecção de conflitos nem persistência
  dos vínculos. Veja [nomes das teclas nos textos](systems/ui.md#nomes-das-teclas-nos-textos).
- **Sem animações.** Os modelos são primitivas estáticas; só o item na mão balança com os passos (`HandSway`).
  `GroundCharacter` informa o que um `AnimationTree` precisa: o estado, a velocidade como valor de mistura, o
  movimento nos eixos do modelo e o ciclo da passada, veja
  [Locomoção](systems/locomotion.md#o-que-o-personagem-informa).
- **Uma cápsula em degraus.** A base redonda da cápsula rola sobre a quina de cada degrau: em degraus, a velocidade
  horizontal cai para cerca de 70% durante um tick por degrau, e o corpo é colocado sobre o degrau até alguns
  centímetros à frente. Para uma escada longa, um colisor de rampa invisível é mais suave, veja
  [Locomoção](systems/locomotion.md#degraus-e-encostas).
- **Modelo flutuante é apenas visual.** `CharacterHover` eleva o modelo, não o corpo: sob teto baixo ele pode
  atravessá-lo, e o foco da câmera e as verificações do braço continuam na altura do corpo. Sobre um vão, o
  modelo cai com ele.
- **Para cima é +Y.** O personagem e os componentes suportam apenas `Vector3.UP` como direção superior.
- **Sem desvio entre personagens.** `NavigationMover` segue um caminho e não usa o desvio da navegação (avoidance),
  então personagens em movimento não desviam uns dos outros. O corpo do jogador está na camada 2 e só colide com a
  camadas 1 e 4, então dois personagens feitos a partir de `player.tscn` se atravessam; adicione a camada 2 à
  `collision_mask` deles se eles devem bloquear um ao outro. Os NPCs da demo ficam parados e entram na geração da
  malha de navegação como obstáculos.
- **A malha de navegação é gerada com antecedência.** Mover um obstáculo em tempo de execução não muda os caminhos.
  Depois de editar o nível, gere a malha de novo
  ([Mundo e navegação](systems/world-and-navigation.md#gerando-novamente-a-malha-de-navegação)).
- **Motor e renderizador testados.** Use Godot 4.7.2, Jolt Physics e Forward+ para reproduzir o ambiente
  verificado. A suíte não estabelece compatibilidade com outras versões e renderizadores. A silhueta exige stencil.

## Entrada

- **Um clique age ao soltar.** Só se sabe se um pressionamento é um clique ou se o botão está sendo segurado depois de
  0,2 s (`hold_delay`) ou ao soltar, então um clique acontece cerca de 0,1 s mais tarde do que aconteceria ao
  pressionar. Isso é intencional: caso contrário, segurar o botão primeiro mandaria o herói por um caminho até o ponto
  pressionado. Veja [Entrada](systems/input.md#clicar-ou-segurar).
- **O cursor pode não manter a mira em alguns sistemas.** Manter a mira enquanto a câmera gira move o cursor do
  sistema (`Viewport.warp_mouse()`). Onde o sistema não permite isso (Wayland, por exemplo), a direção da corrida se
  mantém, mas o cursor fica onde estava na tela.
- **"Ao ponto por um caminho" pode trocar de rota.** Neste modo de segurar, o caminho é reconstruído conforme o ponto
  sob o cursor se move, e perto de mudanças de altura (a rampa, a plataforma) ele pode saltar de uma rota para outra.
  O modo padrão, direto ao cursor, não tem esse problema.
- **O Shift pode ficar preso quando o jogo roda dentro do editor.** Quando o jogo está embutido na aba Jogo (Game) do
  editor e o foco passa para o editor, a engine não redefine as teclas pressionadas. `CharacterActionInput` libera uma
  corrida rápida presa no próximo evento de mouse ou teclado, desde que a ação de corrida rápida esteja em teclas
  modificadoras. Se as Teclas de Aderência (Sticky Keys) do Windows forem ativadas (cinco toques no Shift seguidos), o
  Shift fica preso no próprio sistema; desative as Teclas de Aderência nas configurações do Windows. Veja
  [Entrada](systems/input.md#o-shift-não-fica-preso).

## Câmera

- **Um corpo logo atrás de um obstáculo.** O Jolt não reporta corpos que um shape cast toca no seu início. Quando
  outro corpo está logo atrás do obstáculo em que a câmera está (uma cerca com um penhasco atrás), o braço procura
  espaço livre mais perto do alvo. Veja
  [Câmera](systems/camera.md#como-o-braço-distingue-espaço-livre-atrás-de-um-obstáculo-de-um-corpo-ocupado).
- **Saltos no movimento sem interpolação de física.** A interpolação de física está ligada por padrão. Desligada
  (Configurações → Exibição), o personagem e a câmera se movem tick a tick, 60 vezes por segundo: num monitor rápido
  isso parece irregular, e com a câmera seguindo a corrida o personagem balança nas curvas.

## Testes

- **Um aviso raro do Jolt faz a execução falhar.** Sob carga pesada de CPU, por exemplo na primeira execução logo após
  uma importação nova, o Jolt Physics pode imprimir "Jolt Physics job system exceeded the maximum number of jobs. This
  should not happen." O executor de testes conta cada aviso e erro da engine como falha, então a execução termina com
  código de saída 1 e "engine and script errors: 1", embora todas as verificações tenham passado. O aviso vem do
  sistema de jobs de física da engine, não do projeto: rode os testes de novo, numa máquina que não esteja ocupada.

## Renderização

- **A silhueta usa um recurso experimental da engine.** O stencil buffer é experimental no Godot 4.5+ e só pode ser
  lido num passe transparente. Se uma versão futura da engine o mudar, a silhueta é o lugar para olhar.
- **A projeção é invertida em Y no Godot 4.7** (D3D12 e Vulkan): `PROJECTION_MATRIX[1][1]` é negativo nos shaders. A
  borda da silhueta usa o `abs()` dele; sem isso, a malha da borda encolhe e a borda desaparece.

## Arquivos do projeto

- **Rotações arredondadas geram avisos de "non-uniform scale".** Uma rotação gravada num `.tscn` com 4 dígitos faz os
  comprimentos dos eixos da base diferirem em mais de 1e-5, e a engine reporta uma escala não uniforme em corpos e
  formas. Grave os números de `Transform3D` com precisão total (9 dígitos significativos).
- **`shared/` ainda não é totalmente neutro quanto à linguagem.** Níveis e plataforma usam scripts dos
  componentes: `world.tscn`, `island.tscn` e `mountain.tscn` usam
  `addons/iso_orbit/points_of_interest/point_of_interest.gd`; ambos os níveis usam
  `addons/iso_orbit/levels/spawn_point.gd`, e `shared/world/props/teleport_pad.tscn` usa
  `addons/iso_orbit/levels/level_portal.gd`. Dois scripts pequenos de objetos também ficam em
  `shared/world/props/`. Uma versão em C# precisaria de scripts próprios para lugares, pontos de entrada e
  portais ou de uma forma de marcá-los só na cena.
- **Recursos vazados reportados na saída.** Se um script sai logo depois de tocar passos, a engine pode reportar
  objetos `AudioStreamPlayback` vazados: com `--fixed-fps`, o tempo de jogo corre à frente do tempo real enquanto os
  sons ainda tocam. Libere a cena e espere um momento antes de sair; `tests/run_checks.gd` espera 0,1 s.

---

*Esta página corresponde ao Iso & Orbit 1.2.0.*
