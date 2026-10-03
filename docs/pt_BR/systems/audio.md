<!-- translation of docs/en/systems/audio.md @ 551102f71d1a -->
# Áudio

> Esta é uma tradução do [original em inglês](../../en/systems/audio.md).
> Onde houver diferenças, a versão em inglês é a correta.

`GroundCharacter` informa o que acontece com ele por sinais: `stepped(sprinting)`, `jumped`, `landed(impact_speed)`,
`sprint_changed(sprinting)` (veja [Locomoção](locomotion.md#sinais)). Sons, poeira sob os pés ou animações se conectam
a eles; o próprio personagem não sabe nada sobre isso. A demo conecta sons.

## CharacterSounds

`CharacterSounds` (`Player/Sounds`) é um `Node3D` filho do personagem. Os filhos dele são nós `AudioStreamPlayer3D`,
então o som sai do personagem e funciona igual para um NPC. Sem esse nó, o personagem funciona exatamente igual, só que
em silêncio.

| Som | Reprodutor | O que toca |
|---|---|---|
| Passos | `Footsteps` | Um `AudioStreamRandomizer` de quatro variantes com tom (±8%) e volume aleatórios, até três ao mesmo tempo. Na corrida rápida, um pouco mais agudos (`sprint_step_pitch` 1,08) e mais altos (+2 dB); mais rápidos por si sós, já que os passos seguem a distância |
| Pulo | `Jump` | Um impulso do pé e o farfalhar das roupas |
| Aterrissagem | `Land` | Um baque pesado, mais alto quanto mais rápida a queda: volume total a partir de `land_full_speed` (10 m/s), nunca mais baixo que `min_land_volume` (30%) |
| Início da corrida rápida | `SprintStart` | Um impulso e uma rajada de ar crescente no início da corrida rápida |
| Corrida rápida | `SprintLoop` | Um loop de 2 s de respiração rápida e ar, com fade de entrada e saída em `sprint_loop_fade` (0,25 s) |

| Propriedade | Padrão | Significado |
|---|---|---|
| `character` | pai | De quem tocar os sinais |
| `footsteps`, `jump`, `land`, `sprint_start`, `sprint_loop` | — | Os reprodutores |
| `footsteps_enabled`, `jump_enabled`, `sprint_enabled` | ligado | Grupos de sons; o pulo cobre o pulo e a aterrissagem, a corrida rápida cobre o início e o loop |
| `sprint_step_pitch`, `sprint_step_volume_db` | 1,08; +2 dB | Passos durante a corrida rápida |
| `land_full_speed`, `min_land_volume` | 10 m/s; 0,3 | Curva de volume da aterrissagem |
| `sprint_loop_fade` | 0,25 s | Fade do loop da corrida rápida |

Os volumes são definidos nos reprodutores em `gdscript/player/player.tscn`; ajuste-os com o jogo rodando pela árvore
Remota (Remote). A exceção é `Land`: o volume dele é definido antes de cada aterrissagem a partir da velocidade da
queda (`land_full_speed`, `min_land_volume`). Os grupos são ligados e desligados em Configurações → Som; a demo deixa
os sons da corrida rápida desligados por padrão. O volume geral ali é o barramento `Master`: a porcentagem é uma fração
da amplitude (50% é 6 dB mais baixo), e 0 silencia o barramento.

## Os sons em si

Os arquivos em `shared/audio/character/` foram sintetizados por um script: os baques são senoides com tom
descendente, os estalos e o ar são ruído passado por filtros passa-banda. O loop da corrida rápida carrega um chunk
`smpl` no WAV, e o modo de loop padrão da importação, "Detect From WAV", faz com que ele se repita sem mexer nas
configurações de importação. A emenda do loop tem crossfade do fim para o início, então não estala.

Sons reais gravados podem substituir estes: coloque arquivos com os mesmos nomes na pasta.

---

*Esta página corresponde ao Iso & Orbit 1.0.0.*
