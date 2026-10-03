<!-- translation of docs/en/systems/audio.md @ 551102f71d1a -->
# Audio

> Esta es una traducción del [original en inglés](../../en/systems/audio.md).
> Si hay diferencias, la versión en inglés es la correcta.

`GroundCharacter` informa con señales lo que le pasa: `stepped(sprinting)`, `jumped`, `landed(impact_speed)`,
`sprint_changed(sprinting)` (ver [Locomoción](locomotion.md#señales)). Los sonidos, el polvo bajo los pies o las
animaciones se conectan a ellas; el personaje en sí no sabe nada de ellos. La demo conecta sonidos.

## CharacterSounds

`CharacterSounds` (`Player/Sounds`) es un `Node3D` hijo del personaje. Sus hijos son nodos `AudioStreamPlayer3D`, así
que el sonido sale del personaje y funciona igual para un NPC. Sin este nodo el personaje funciona exactamente igual,
solo que en silencio.

| Sonido | Reproductor | Qué suena |
|---|---|---|
| Pasos | `Footsteps` | Un `AudioStreamRandomizer` de cuatro variantes con tono (±8%) y volumen aleatorios, hasta tres a la vez. En sprint, un poco más agudos (`sprint_step_pitch` 1,08) y más fuertes (+2 dB); más rápidos por sí solos, ya que los pasos siguen la distancia |
| Salto | `Jump` | Un impulso del pie y el roce de la ropa |
| Aterrizaje | `Land` | Un golpe sordo y pesado, más fuerte cuanto más rápida es la caída: volumen completo desde `land_full_speed` (10 m/s), nunca más bajo que `min_land_volume` (30%) |
| Inicio del sprint | `SprintStart` | Un impulso y una ráfaga de aire creciente al inicio de un sprint |
| Sprint | `SprintLoop` | Un bucle de 2 s de respiración rápida y aire, con fundido de entrada y de salida durante `sprint_loop_fade` (0,25 s) |

| Propiedad | Por defecto | Significado |
|---|---|---|
| `character` | el padre | De quién reproducir las señales |
| `footsteps`, `jump`, `land`, `sprint_start`, `sprint_loop` | — | Los reproductores |
| `footsteps_enabled`, `jump_enabled`, `sprint_enabled` | activado | Grupos de sonidos; el salto abarca el salto y el aterrizaje, el sprint abarca el inicio y el bucle |
| `sprint_step_pitch`, `sprint_step_volume_db` | 1,08; +2 dB | Los pasos durante el sprint |
| `land_full_speed`, `min_land_volume` | 10 m/s; 0,3 | Curva de volumen del aterrizaje |
| `sprint_loop_fade` | 0,25 s | Fundido del bucle del sprint |

Los volúmenes se fijan en los reproductores en `gdscript/player/player.tscn`; ajústalos con el juego en marcha a
través del árbol Remoto (Remote). La excepción es `Land`: su volumen se fija antes de cada aterrizaje a partir de la
velocidad de caída (`land_full_speed`, `min_land_volume`). Los grupos se activan y desactivan en Configuración →
Sonido; la demo desactiva por defecto los sonidos del sprint. El volumen general allí es el del bus `Master`: el
porcentaje es una fracción de la amplitud (50% es 6 dB más bajo), y 0 silencia el bus.

## Los sonidos en sí

Un script sintetizó los archivos de `shared/audio/character/`: los golpes sordos son senoides con un tono que
desciende, los crujidos y el aire son ruido pasado por filtros pasabanda. El bucle del sprint lleva un bloque `smpl`
en el WAV, y el modo de bucle de importación por defecto, "Detectar desde WAV" ("Detect From WAV"), hace que se
repita sin tocar la configuración de importación. La unión del bucle tiene un fundido cruzado del final con el
inicio, así que no hace clic.

Se pueden reemplazar por sonidos grabados reales: pon en la carpeta archivos con los mismos nombres.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
