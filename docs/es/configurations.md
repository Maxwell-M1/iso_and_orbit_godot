<!-- translation of docs/en/configurations.md @ 2173d5158953 -->
# Configurar el héroe jugable

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/configurations.md).
> Si hay diferencias, la versión en inglés es la referencia.

Empieza por `gdscript/player/playable_hero.tscn` después de seguir la [guía de transferencia](integration.md). Las
tres configuraciones conservan el tamaño del personaje, el recurso de movimiento y las colisiones de cámara de la
escena suministrada. Cambian cómo controlas y ves al héroe sin introducir valores arbitrarios de velocidad o suavizado.

| Configuración | Úsala para | Principal contrapartida |
|---|---|---|
| [Predeterminada: órbita manual](#predeterminada-órbita-manual) | Ver una zona con estabilidad y combinar movimiento por clic y dirección directa | El jugador elige la dirección de la cámara |
| [Ratón guiado por rutas](#ratón-guiado-por-rutas) | Rodear obstáculos horneados mientras mantienes pulsado el ratón | La ruta puede cambiar cerca de rampas y alturas superpuestas |
| [Exploración con cámara de seguimiento](#exploración-con-cámara-de-seguimiento) | Trayectos largos en los que la cámara debe volver detrás del movimiento | La vista gira cuando cambia la ruta |

## Dónde cambiar cada ajuste

Hay tres orígenes posibles para cada valor. Comprueba cuál estás editando:

| Origen | Cuándo se aplica | Ejemplo |
|---|---|---|
| Valor predeterminado del script | Componente recién agregado sin valor propio en la escena | `PointClickMoveInput.keys_with_camera` empieza en `SIDESTEP` |
| Escena o recurso guardado | Instancia de la escena suministrada | `playable_hero.tscn` selecciona `TURN`; su cámara tarda 1.1 s en seguir un giro |
| Ajustes de la demo | `SettingsApplier` se ejecuta al iniciar y al cambiar una opción del menú | `user://settings.cfg` puede activar el seguimiento de cámara aunque la escena lo tenga desactivado |

En la demo, usa **Configuración → Restablecer todo** antes de comparar configuraciones. Los cambios del menú se guardan;
los cambios en el inspector **Remoto** de la escena en ejecución son temporales. Para un héroe independiente, edita
las escenas copiadas o crea una escena heredada de `playable_hero.tscn` y guarda cada variante por separado. Activa
**Editable Children** en una instancia si necesitas acceder a nodos internos. Copia `SettingsApplier` solo si
quieres que controle estos valores.

Las rutas siguientes son relativas a la instancia del héroe:

| Qué ajustar | Nodo o recurso |
|---|---|
| Clic, pulsación sostenida, teclas y cursor | `PlayerInput` (`PointClickMoveInput`) |
| Modo de la tecla de sprint y entrada de salto | `PlayerActionInput` (`CharacterActionInput`) |
| Velocidad, aceleración, frenado y velocidad de giro | `Character/NavigationMover` → `settings`, normalmente `player_locomotion.tres` |
| Salto, gravedad, escalones y uso de resistencia | `Character` (`GroundCharacter`) |
| Protección de bordes y recuperación de resistencia | `Character/LedgeGuard` / `Character/Stamina` |
| Órbita, seguimiento, inclinación y zoom | `CameraRig` (`OrbitCameraRig`) |
| Obstáculos de cámara y transparencia | `CameraRig/CameraArm` (`CameraArm`) |
| Modelo flotante | `Character/Visual/Hover` (`CharacterHover`) |

El Inspector muestra los ángulos del rig y la velocidad de giro del recurso de movimiento en **grados**, pero las
asignaciones en GDScript usan **radianes** (`deg_to_rad(30.0)`). `Camera3D.fov` es una excepción: también usa grados
en el código. La inclinación hacia abajo es negativa. El control **Inclinación hacia abajo** de la demo usa grados
positivos, y **Altura** usa porcentajes: 55% en el menú corresponde a `follow_zoom_level = 0.55`, no a metros.

## Predeterminada: órbita manual

Es la configuración de la escena del héroe suministrada y de la demo después de Restablecer todo. Puedes hacer
clic para rodear obstáculos mediante una ruta, mantener pulsado el botón izquierdo para dirigir al héroe directamente
o mantener el derecho junto con WASD para moverte según la cámara. La cámara sigue la posición del cuerpo, pero no
gira automáticamente detrás de la carrera.

| Parte | Valores que conservar |
|---|---|
| Recurso de movimiento | `max_speed = 5.5`, `sprint_speed_multiplier = 1.5`, `acceleration_time = 0.18`, `stop_time = 0.22`, `turn_speed = 720°/s` |
| Personaje | `jump_height = 1.0`, `gravity_scale = 3.0`, `max_step_height = 0.3`, `sprint_tires = true`, `sprint_duration = 5.0` |
| Entrada | `hold_mode = STEER`, `hold_delay = 0.2`, ambos modos de teclas `TURN`, `look_around_while_held = true`, `keep_aim_on_camera_turn = true` |
| Cámara | `follow_movement = false`, `follow_pitch = false`, `follow_zoom = false`, `mouse_pitch = false`; sigue activo el suavizado vertical del objetivo con `height_follow_time = 0.15 s` |
| Vista inicial | `start_yaw = 45°`, `start_zoom = 0.55`, campo visual de cámara de 45° |
| Brazo de cámara | `keep_out_of_geometry = true`, `pull_in_on_occlusion = false`, capas de colisión 1 y 3 |

Deja activada la protección de bordes y conserva el `Visual` suministrado como objetivo de transparencia del brazo.
Tras una pared, la silueta mantiene visible al héroe; el brazo evita que la cámara entre en la geometría. Cumplen
funciones distintas.

**Compruébalo:** haz clic detrás de una pared que se pueda rodear, mantén pulsado el ratón apuntando a la pared y
después orbita mientras te mueves. El clic debe seguir una ruta; con la pulsación sostenida, el héroe debe deslizarse
o detenerse al chocar. Mirar alrededor debe conservar la dirección de la carrera. Prueba por separado un escalón
de 0.2 m y un salto antes de cambiar los valores de movimiento.

## Ratón guiado por rutas

Parte de la configuración predeterminada y cambia estas propiedades en `PlayerInput`:

| Propiedad | Valor | Efecto |
|---|---|---|
| `hold_mode` | `FOLLOW_POINT` | La pulsación sostenida actualiza un destino de navegación en vez de dirigir directamente |
| `stop_on_release` | `true` | Al soltar el botón, se frena en la posición actual |
| `keys_with_camera` | `OFF` | Desactiva botón derecho + WASD |
| `keys_with_camera_steer` | `OFF` | Desactiva la dirección con A/D cuando se mantienen ambos botones |

Deja desactivados los tres interruptores de seguimiento de cámara para seguir eligiendo su dirección manualmente.
El recurso de movimiento predeterminado ya acelera y frena con rapidez; este tipo de entrada no exige cambiar
su velocidad.

Los clics breves siguen su ruta hasta el final. `stop_on_release` afecta **solo a las pulsaciones sostenidas** y
no aparece en el menú de la demo: asígnalo en la escena o en el código. Poner ambos modos de teclas en Off **no**
desactiva el movimiento con los dos botones: botón derecho y luego izquierdo sigue avanzando directamente en la
dirección de la cámara, sin ruta de navegación.

Usa esta variante en niveles con una malla horneada fiable y un suelo cuya altura bajo el cursor sea casi siempre
inequívoca. Cerca de una rampa o plataforma, el rayo puede seleccionar otra altura y reconstruir la ruta. Si
necesitas un control directo preciso allí, usa el modo predeterminado `STEER`. En este controlador, una ruta vacía
no significa de forma segura «no moverse»: revisa la malla de navegación si el héroe se dirige a un obstáculo.

**Compruébalo:** mantén pulsado el ratón al otro lado de una pared, mueve el cursor a otro punto alcanzable y
suelta el botón a mitad de camino. El héroe debe rodear la pared, cambiar de destino y frenar al soltar. Después
haz un clic breve y confirma que continúa hasta el destino.

## Exploración con cámara de seguimiento

Parte de los modos de entrada predeterminados `STEER` y `TURN`. Activa estas propiedades en `CameraRig`:

| Propiedad | Valor | Motivo |
|---|---|---|
| `follow_movement` | `true` | Gira detrás de una carrera iniciada por clic o cursor |
| `follow_time` | 1.1 s | Tiempo de giro ajustado en la escena; se acerca suavemente a la nueva dirección |
| `follow_toward_camera_angle` | 30° | Una carrera casi de frente a la cámara no hace girar toda la vista |
| `sharp_turn_speed` | 360°/s | La mitad de los 720°/s de giro del personaje; evita seguir las direcciones intermedias de un cambio de sentido |
| `follow_wait_after_rotate` | `true` | Conserva una vista elegida manualmente hasta una parada o una carrera nueva |
| `follow_pitch` / `follow_pitch_angle` / `follow_pitch_time` | `true` / −22° / 1.1 s | Recupera una vista de la ruta con poca inclinación |
| `follow_zoom` / `follow_zoom_level` / `follow_zoom_time` | `true` / 0.55 / 1.5 s | Vuelve al zoom inicial suministrado durante el movimiento |

Los ángulos, el zoom y los tiempos proceden de la escena y de los ajustes de la demo. El giro, la alineación de
inclinación y la de zoom son independientes. Si el jugador debe conservar el zoom elegido con la rueda, deja
`follow_zoom` desactivado; deja también `follow_pitch` desactivado si la rueda debe seguir controlando la
inclinación del modo habitual.

En la pestaña Cámara de la demo corresponden a **Girar la cámara siguiendo la carrera**,
**Alinear inclinación de cámara al correr** y **Alinear altura de cámara al correr**. Los valores de destino
predeterminados ya coinciden con la tabla.

La órbita con el botón derecho tiene prioridad sobre el seguimiento automático. Como WASD requiere ese botón,
la cámara no gira automáticamente detrás del movimiento con botón derecho + WASD. Tras orbitar, soltar solo el
botón derecho no termina la espera: detente, haz clic en un destino nuevo o inicia otra pulsación sostenida.
Conserva la conexión `run_requested → end_follow_wait` de la escena y
`keep_aim_on_camera_turn = true`; de otro modo el seguimiento puede seguir esperando o el movimiento de cámara
puede dirigir el cursor mientras mantienes pulsado el botón.

**Compruébalo:** corre a través de la vista, gira 90° y luego da media vuelta hacia la cámara. El primer giro
debe llevar la cámara detrás de la ruta; el cambio de sentido no debe hacerla girar alrededor del héroe.
Orbita manualmente durante
la carrera y suelta el botón derecho: la vista elegida debe durar hasta detenerte o iniciar otra carrera. Repite
la prueba junto a una pared para comprobar el brazo.

Si usas el héroe por separado, este código activa la misma configuración. Ejecútalo desde `_ready()` de la escena
de juego, cuando los hijos del héroe ya estén preparados:

```gdscript
extends Node3D

@onready var hero: PlayableHero = $Hero


func _ready() -> void:
    hero.place_at($Spawn, false)
    var rig := hero.camera_rig
    rig.follow_movement = true
    rig.follow_time = 1.1
    rig.follow_toward_camera_angle = deg_to_rad(30.0)
    rig.sharp_turn_speed = deg_to_rad(360.0)
    rig.follow_wait_after_rotate = true
    rig.follow_pitch = true
    rig.follow_pitch_angle = deg_to_rad(-22.0)
    rig.follow_pitch_time = 1.1
    rig.follow_zoom = true
    rig.follow_zoom_level = 0.55
    rig.follow_zoom_time = 1.5
```

El ejemplo supone que no has modificado los ajustes de entrada ni movimiento del héroe. En la demo completa,
utiliza el menú de ajustes o `Settings.set_value()` para mantener sincronizados los valores guardados y los
controles.

## Opcional: un héroe flotante

Cualquiera de las configuraciones puede usar la flotación existente: establece
`Character/Visual/Hover.enabled = true` o activa **Personaje → Flotar sobre el suelo** en la demo. Conserva
`height = 0.35 m`, `glide_time = 0.3 s` y el recurso asignado `player_floating_fall.tres` (escala de gravedad
de caída 0.5 y velocidad máxima de caída 2 m/s).

Flota el modelo; el cuerpo de colisión sigue subiendo escalones y cayendo. Esto no permite cruzar huecos ni volar.
El salto alcanza la misma altura y luego desciende más despacio. Los eventos de pasos se suspenden durante la
flotación y un aterrizaje suave a 2 m/s queda por debajo del umbral predeterminado de 2.5 m/s. El colisionador
del cuerpo no crece con el modelo elevado: prueba los techos bajos. Consulta [Personajes](systems/characters.md)
y [Locomoción](systems/locomotion.md) para los detalles del modelo y la caída.

## Ajustar sin romper la configuración

- **Usa recursos independientes cuando los valores deban variar.** En el Inspector, haz único el recurso de
  ajustes del componente de movimiento y guárdalo con otro nombre antes de editar un solo personaje.
  Asigna otro recurso antes de que el componente entre en el árbol de escenas. Durante la ejecución, edita
  los campos del recurso existente:
  sustituir `mover.settings` después de `_ready()` no cambia el recurso que ya usa `GroundMotion`.
- **Cambia a la vez velocidad y frenado.** `acceleration_time` y `stop_time` se miden a velocidad base. El sprint
  usa la misma aceleración y frenado: a 1.5× de velocidad tarda 1.5× en detenerse, unos 0.33 s en vez de 0.22 s.
  La distancia ideal de frenado recto es unos 0.61 m a 5.5 m/s y 1.36 m a 8.25 m/s. Deja espacio en los bordes.
- **Relaciona la detección de giro de cámara con el movimiento.** Mantén `sharp_turn_speed` como máximo en la mitad
  de `LocomotionSettings.turn_speed`. Si reduces la velocidad de giro del personaje, revisa este umbral.
- **Coordina cuerpo, protector y navegación.** Al cambiar tamaño de cápsula, altura máxima de escalón o límite
  de pendiente, revisa radio, altura, ascenso y pendiente de navegación y vuelve a hornear. El límite de caída
  del protector debe seguir permitiendo los escalones previstos. Las capas de física y navegación son distintas.
- **Cambia un comportamiento y repite su prueba.** Usa los paneles **Línea de ruta del personaje** y
  **Estado del personaje y eventos** de la demo para saber si falla la ruta, la colisión, la entrada o la cámara.
  Conserva una escena base guardada en lugar de intentar reconstruirla de memoria.

Referencias de propiedades: [Entrada](systems/input.md), [Locomoción](systems/locomotion.md) y
[Cámara](systems/camera.md).

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
