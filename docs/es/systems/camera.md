<!-- translation of docs/en/systems/camera.md @ d5569844bc1c -->
# Cámara

[← Índice de documentación](../index.md)

> Esta es una traducción del [original en inglés](../../en/systems/camera.md).
> Si hay diferencias, la versión en inglés es la referencia.

`OrbitCameraRig` sigue a un objetivo `Node3D`, gira a su alrededor con el ratón y cambia distancia e inclinación
con la rueda. Su hijo `CameraArm` coloca una `Camera3D` sobre el eje +Z local y la mantiene fuera de la geometría
cercana. El giro automático, la alineación de inclinación y la de zoom durante la carrera son opciones independientes.

```text
PlayableHero (raíz fija de la plantilla)
├── Character (objetivo en movimiento)
└── CameraRig (OrbitCameraRig; target = ../Character)
    └── CameraArm (CameraArm)
        └── Camera3D (current = true)
```

Pon el rig junto al objetivo móvil, no dentro de él: establece por sí mismo su posición y rotación globales. Mantén
la escala del rig, brazo, cámara y sus ancestros en `(1, 1, 1)` para que longitudes y radios de colisión conserven
su significado. Cada fotograma dibujado, el rig sitúa la cámara a partir de
`target.get_global_transform_interpolated()` y desactiva su propia interpolación de física en `_ready()`; sus hijos
heredan ese modo por defecto. Activa la interpolación de física del proyecto si el objetivo se mueve en los ticks
de física; de otro modo avanzará visiblemente a saltos de un tick. La plantilla ya la activa.
`height_follow_time` puede suavizar después los cambios de altura del objetivo.

La `Camera3D` debe conservar su transformación local predeterminada: el brazo establece su posición y rotación
locales. La plantilla la marca como **Current**, con campo visual de 45° y plano lejano a 300 unidades del mundo.
Si después entra otra cámara actual en la escena, vuelve a hacer actual esta cámara cuando el héroe deba controlar
la vista. Consulta [Integración](../integration.md#la-cámara-sola) para copiarla sola o con todo el héroe, y
[Preparación del proyecto](../project-setup.md) para las acciones de entrada y capas de física.

## ¿Qué valores están activos?

Los valores de script indicados abajo son los predeterminados de los componentes reutilizables.
`gdscript/player/playable_hero.tscn` sustituye algunos; `SettingsApplier` de la demo aplica los valores guardados
de `Settings` cuando se inicia la escena principal. Una copia de la escena del héroe funciona sin la ventana ni el
autoload de ajustes de la demo, con los valores de la escena.

| Ajuste | Valor del script | Escena del héroe / demo recién iniciada |
|---|---:|---:|
| Giro, inclinación y zoom alineados durante la carrera | todos desactivados | todos desactivados |
| `follow_time` | 1.5 s | 1.1 s |
| `follow_pitch_angle`, `follow_pitch_time` | −40°, 1.5 s | −22°, 1.1 s |
| `follow_zoom_level`, `follow_zoom_time` | 0.55, 1.5 s | 0.55, 1.5 s |
| `follow_wait_after_rotate` | desactivado | activado |
| `height_follow_time` | 0 s | 0.15 s |

Los tiempos y destinos de giro, inclinación y zoom solo se aplican cuando se activa su interruptor de seguimiento.
`height_follow_time` siempre suaviza el desplazamiento vertical del objetivo, incluso en órbita manual. En la demo,
un valor anterior de `user://settings.cfg` puede sustituir los de inicio. `SettingsApplier` convierte los grados
positivos de «Inclinación hacia abajo» de la ventana en un ángulo negativo, y el 0–100% de «Altura» en el zoom 0–1
del rig.

Longitudes y velocidades se miden en unidades del mundo de Godot (metros si la escena usa la escala de la plantilla,
1 unidad = 1 m). Los ángulos y velocidades angulares marcados como `radians_as_degrees` se muestran en grados en el
Inspector, pero GDScript les asigna radianes: usa `deg_to_rad(-22.0)` para `follow_pitch_angle` y
`deg_to_rad(360.0)` para `sharp_turn_speed`. El valor serializado `-0.383972...` de `playable_hero.tscn` es −22°.

## Órbita, inclinación y zoom

Mantén `camera_rotate` (botón derecho en la plantilla) y mueve el ratón para orbitar. El cursor queda capturado y
vuelve a su lugar al soltarlo; perder el foco o pausar el juego también lo libera. Con `mouse_pitch` desactivado,
el movimiento vertical no hace nada y la rueda elige la inclinación. Actívalo para inclinar con el ratón;
`invert_pitch` invierte ese eje. Girar la rueda hacia arriba baja la cámara; hacia abajo la sube. El desplazamiento
suave puede avanzar una fracción de `zoom_step`.

El zoom va de 0 (cerca) a 1 (lejos). El paso predeterminado de la rueda es 0.1. La longitud del brazo interpola
entre `near_distance` 5 y `far_distance` 20 unidades del mundo. De cerca la inclinación es menor, según esta curva:

| Zoom | Distancia | Inclinación base |
|---:|---:|---:|
| 0 | 5 | −22° |
| 0.2 (`flatten_end_zoom`) | 8 | −22° |
| 0.5 (`flatten_start_zoom`) | 12.5 | −38.5° |
| 0.55 (`start_zoom`) | 13.25 | −40.15° |
| 1 | 20 | −55° |

Entre 0.2 y 0.5 de zoom, la inclinación se nivela deprisa al bajar la cámara para ver mejor el terreno de delante.
Por debajo de 0.2, solo cambia la distancia. La inclinación del ratón y la del seguimiento añaden un desplazamiento
a la curva, limitado por `min_pitch` y `max_pitch` (−80° y −8°). Desactivar `mouse_pitch` borra su desplazamiento,
salvo si `follow_pitch` mantiene una inclinación. `rotation_sharpness` y `zoom_sharpness` suavizan los cambios del
ratón y la rueda; 0 hace inmediata la entrada correspondiente.

## Modo de seguimiento

Activa cualquier combinación de `follow_movement`, `follow_pitch` y `follow_zoom` para girar la cámara detrás de
la carrera, acercarse a una inclinación elegida y volver a un nivel de zoom. El rig mide el movimiento horizontal
por tick de física de cualquier objetivo `Node3D`: no necesita una propiedad de velocidad del personaje. Por debajo
de `follow_min_speed` no sigue; entre esa velocidad y el doble, la fuerza del seguimiento crece suavemente. Tras
detenerse, el objetivo inicia la siguiente carrera con una dirección nueva.

Cada movimiento activado empieza y se asienta suavemente con su propio resorte. Su tiempo indica aproximadamente
lo que tarda en completar el 95% de un cambio desde el reposo durante una carrera a velocidad plena, si no interviene
el límite de giro; 0 solicita un cambio inmediato. Si se detiene el movimiento o se pausa el seguimiento, una
acción ya iniciada frena en vez de cortarse bruscamente. `rotation_sharpness` y `zoom_sharpness` determinan ese
frenado. El seguimiento mueve la cámara directamente: el suavizado de entrada no añade otro retraso.

| Propiedad | Valor del script | Efecto |
|---|---:|---|
| `follow_movement`, `follow_time` | desactivado, 1.5 s | Gira detrás de la carrera horizontal; tiempo hasta casi completar el giro |
| `follow_max_turn_speed` | 0 | Velocidad máxima del giro automático en °/s; 0 quita el límite, incluso para un giro inmediato |
| `follow_toward_camera_angle` | 30° | Ignora carreras a menos de este ángulo de la dirección hacia la cámara; fuerza completa al doble del ángulo. 0 quita esta excepción |
| `sharp_turn_speed` | 360°/s | Ignora direcciones intermedias durante un giro brusco o cambio de sentido y luego adopta la nueva; 0 desactiva esta protección |
| `teleport_speed` | 50 unidades del mundo/s | Un movimiento horizontal entre ticks más rápido se trata como teletransporte, no como carrera |
| `follow_pitch`, `follow_pitch_angle`, `follow_pitch_time` | desactivado, −40°, 1.5 s | Lleva la inclinación a este ángulo descendente, independientemente del giro |
| `follow_zoom`, `follow_zoom_level`, `follow_zoom_time` | desactivado, 0.55, 1.5 s | Lleva el zoom a este nivel 0–1, independientemente del giro y la inclinación |
| `follow_min_speed` | 1 unidad del mundo/s | Velocidad horizontal mínima de seguimiento; fuerza completa al doble |
| `follow_wait_after_rotate` | desactivado | Conserva la vista tras una órbita manual hasta que el objetivo baje de `follow_min_speed` o se informe de una carrera nueva |

La protección para carreras hacia la cámara solo afecta **al giro**. Una carrera directamente hacia la cámara aún
puede cambiar inclinación y zoom si esas opciones están activadas. La protección ante giros bruscos tampoco detiene
la inclinación ni el zoom durante un cambio de sentido; un giro ya iniciado puede frenar gradualmente. Con
`LocomotionSettings.turn_speed` de 720°/s del héroe, el umbral de 360°/s detecta los cambios de sentido y permite
curvas más lentas. Si cambias la velocidad de giro del personaje, conserva `sharp_turn_speed` en la mitad o menos;
`PlayableHero` advierte cuando un umbral positivo alcanza la velocidad de giro del personaje. Poner
`follow_toward_camera_angle` en 0 permite deliberadamente que la cámara gire detrás de una carrera hacia ella.

Si activas la alineación de inclinación y zoom, el zoom cambia la distancia y la inclinación compensa su curva.
La vista se asienta en `follow_pitch_angle` y `follow_zoom_level` de forma independiente. La rueda y el ratón siguen
funcionando mientras corres; las opciones activas devuelven la vista a sus destinos. `height_follow_time` es otra
cosa: suaviza cómo el rig sigue la **posición Y global** del objetivo, sobre todo en escaleras. No cambia el zoom.
Con 0 sigue la altura exactamente; los 0.15 s de la escena del héroe permiten cubrir aproximadamente el 95% de
un cambio vertical en ese tiempo.

### Cuándo se pausa el seguimiento

Los tres movimientos de seguimiento dejan de atraer la cámara mientras se mantiene el botón derecho. Con
`follow_wait_after_rotate` activado, terminar una órbita tras al menos 0.2 s o 2 px de movimiento conserva la vista
elegida durante la carrera actual. También ocurre si se pierde el foco o se pausa antes de soltar el botón; un toque
más breve no inicia la espera. Con la opción desactivada, el seguimiento se reanuda al acabar la órbita. La espera
termina cuando la velocidad cae por debajo de `follow_min_speed`, `end_follow_wait()` informa de una carrera nueva,
se llama a `snap()`, cambia el objetivo o el desplazamiento supera `teleport_speed`. Una carrera nueva puede empezar
antes de terminar la anterior: conecta `run_requested` de la entrada a `end_follow_wait()` si usas esta opción.
Sin esa señal, un objetivo que nunca deja de moverse puede mantener la cámara esperando indefinidamente; desactiva
la opción si tu juego no puede informar de carreras nuevas.

`playable_hero.tscn` también conecta `PointClickMoveInput.hold_pending_changed` con `set_follow_paused()`. Esto
pausa el seguimiento durante los primeros 0.2 s de una pulsación izquierda mientras la entrada decide si será
un clic o una pulsación sostenida. `run_requested` termina la espera tras una órbita cuando comienza un clic, una
pulsación sostenida o botón derecho + tecla. Pulsar el derecho durante una carrera iniciada con el izquierdo permite
mirar alrededor; al soltarlo, esa carrera no cuenta como nueva y la vista queda donde la dejó el jugador hasta la
siguiente parada o carrera. `keep_aim_on_camera_turn` de la entrada mantiene el cursor apuntando al mismo punto
del mundo cuando se mueve la cámara y evita que la dirección de carrera persiga a la cámara.

Con `Engine.time_scale` en 0, los movimientos de seguimiento conservan su estado y se reanudan cuando avanza el
tiempo. Si mueves manualmente el objetivo o lo teletransportas una distancia corta que no activa la comprobación
de `teleport_speed`,
llama a `snap()` para recolocar cámara y brazo y reiniciar el historial de movimiento.

## Propiedades

| Grupo | Propiedad | Valor del script | Significado |
|---|---|---:|---|
| Objetivo | `target` | ninguno | `Node3D` al que sigue |
| Objetivo | `arm`, `camera` | ninguno | Primer hijo directo coincidente si no se asignan; usa `camera` solo sin brazo |
| Entrada | `rotate_action`, `zoom_in_action`, `zoom_out_action` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` | Acciones del mapa de entrada; si falta alguna, informa del error al inicio |
| Entrada | `mouse_sensitivity`, `mouse_pitch`, `invert_pitch`, `zoom_step` | 0.25 °/px, desactivado, desactivado, 0.1 | Velocidad de órbita, controles de inclinación y paso de rueda |
| Encuadre | `focus_height` | 1.2 unidades del mundo | Altura del punto al que mira sobre el origen del objetivo |
| Encuadre | `near_distance`, `far_distance` | 5, 20 | Longitud del brazo con zoom 0 y 1 |
| Encuadre | `near_pitch`, `far_pitch` | −22°, −55° | Inclinación base con zoom 0 y 1 |
| Encuadre | `flatten_start_zoom`, `flatten_end_zoom` | 0.5, 0.2 | Intervalo de zoom que nivela la inclinación más deprisa |
| Encuadre | `min_pitch`, `max_pitch` | −80°, −8° | Límites finales, incluidos los desplazamientos del ratón y seguimiento |
| Encuadre | `start_zoom`, `start_yaw` | 0.55, 45° | Zoom y giro inicial respecto a los ejes globales; `look_along()` puede cambiar luego el giro |
| Suavizado | `rotation_sharpness`, `zoom_sharpness` | 30, 10 | Valores mayores alcanzan antes el destino del ratón/rueda; 0 es inmediato |
| Suavizado | `height_follow_time` | 0 s | Tiempo para recorrer cerca del 95% del cambio vertical del objetivo; 0 lo sigue exactamente |

`look_along(direction)` orienta de inmediato la vista según la parte horizontal de una dirección en **espacio
global** y detiene cualquier giro automático en curso. `snap()` aplica al instante giro, inclinación, zoom,
posición del objetivo y respuesta del brazo a las colisiones; úsalo tras teletransportar. `get_zoom()` devuelve
el zoom actual de 0–1. `is_rotating()`, `is_follow_paused()`, `is_follow_waiting()` y
`is_target_turning_sharply()` informan de esos estados. `set_follow_paused(paused)` y `end_follow_wait()` controlan
las pausas anteriores.

El rig requiere un hijo brazo o cámara (o una propiedad `arm`/`camera` explícita); si falta, produce una aserción
en compilaciones de depuración. Establece su rotación global, por lo que `start_yaw`, `look_along()` y el giro
automático usan ejes globales incluso si la raíz fija del héroe está girada.

## Obstáculos, oclusión y transparencia

Normalmente `CameraArm` usa `keep_out_of_geometry`: una esfera en la posición deseada de la cámara debe caber
fuera de los cuerpos físicos. Si una pared, pendiente o techo ocuparía ese lugar, el brazo se acorta de inmediato.
Una valla entre el objetivo y una cámara que aún tiene espacio detrás no lo acorta. Para mover deliberadamente la
cámara delante de una valla que oculta al objetivo, activa `pull_in_on_occlusion`: el brazo espera a que la
oclusión persista y solo se acerca si conserva al menos `min_pull_in_length`. Cuando se despeja, espera un momento
y vuelve suavemente. Si hay un obstáculo en el recorrido de regreso, salta sobre él en lugar de atravesarlo.

### Cómo distingue el brazo entre espacio libre detrás de un obstáculo y el interior de un cuerpo

Primero comprueba si la esfera de cámara cabe en el extremo deseado. Puede quedarse detrás de una valla situada
entre objetivo y cámara si ese extremo está libre. Si el extremo toca o queda dentro de un cuerpo, el brazo busca
un lugar libre más cercano al objetivo. Los barridos de forma de Jolt no informan de cuerpos tocados o penetrados
al comenzar el barrido, así que el brazo comprueba por separado el espacio inicial. Cuando dos cuerpos están muy
próximos, busca desde un punto más cercano al objetivo. Así evita también introducir la cámara en una valla que
tiene un precipicio justo detrás.

Tanto la esfera como los rayos de visibilidad usan `collision_mask` (binario `0b101`, capas 1 y 3). En la plantilla,
la capa 1 es geometría sólida del mundo y la 3 contiene geometría solo para la cámara, como
`RoofCameraBlocker`; los personajes en la capa 2 y los límites invisibles del personaje en la 4 no mueven el brazo.
Un cuerpo en `camera_ignore`, o bajo un nodo de ese grupo, se ignora. Pon el grupo en la raíz de un objeto para
afectar a todas sus instancias. Al copiar a otro proyecto importan estos números de máscara; los nombres de las
capas son solo etiquetas. Con `keep_out_of_geometry` desactivado, el brazo deja de proteger la cámara de la
geometría situada detrás, con independencia de la opción de acercamiento.

Los cinco `occlusion_points` predeterminados muestrean pecho, cabeza, rodillas y lados del objetivo. Son relativos
al **inicio del brazo**, que el rig coloca `focus_height` por encima del origen del objetivo: x apunta a la derecha
de la cámara, y hacia arriba y z horizontalmente hacia la cámara. `occlusion_share = 0.75` exige que se bloqueen
al menos cuatro de los cinco puntos. Ajusta puntos y `focus_height` para un modelo más alto o flotante.
`CharacterHover` de la plantilla puede elevar el modelo visible 0.35 unidades del mundo sobre su cuerpo.

`fade_target` es opcional. Si se asigna, el brazo cambia `transparency` de sus descendientes
`GeometryInstance3D` cuando se acorta por debajo de `fade_start_length`; llega a `fade_transparency` en
`fade_end_length`. El héroe asigna `Character/Visual`. Esta transparencia de proximidad es distinta del addon
opcional `OccludedSilhouette`, que dibuja al personaje a través de obstáculos.

| Propiedad | Valor del script | Significado |
|---|---:|---|
| `length`, `camera` | 10, ninguno | Longitud deseada (normalmente la establece el rig) y primer hijo directo `Camera3D` si no se asigna otro |
| `keep_out_of_geometry`, `probe_radius` | activado, 0.3 | Mantiene la esfera de cámara fuera de los cuerpos de la máscara |
| `collision_mask`, `ignored_groups` | capas 1 + 3, `camera_ignore` | Cuerpos usados para colisiones y oclusión, y grupos excluidos |
| `pull_in_on_occlusion`, `min_pull_in_length`, `pull_in_sharpness` | desactivado, 2.5, 10 | Acercamiento, longitud mínima y rapidez de aproximación (0 es inmediato) |
| `occlusion_points`, `occlusion_share`, `occlusion_delay` | cinco puntos, 0.75, 0.25 s | Muestras de visibilidad, proporción bloqueada y espera previa a acercarse o volver |
| `return_delay`, `return_sharpness` | 0.3 s, 4 | Espera y rapidez de extensión (0 de rapidez es inmediata tras la espera) |
| `fade_target`, `fade_start_length`, `fade_end_length`, `fade_transparency` | ninguno, 1.5, 0.7, 0.75 | Transparencia opcional del modelo, completa a 0.7 unidades o menos |
| `debug_draw` | desactivado | Dibuja longitudes deseada/real, esfera de cámara y rayos de visibilidad; útil desde otra cámara |

`CameraArm.snap()` recalcula la colisión y coloca la cámara sin esperar al regreso. `get_current_length()` devuelve
su longitud real tras los obstáculos; `is_pulled_in_by_occlusion()` indica si la oclusión está acercándola.

Este comportamiento se comprueba en [`tests/camera_checks.gd`](../../../tests/camera_checks.gd) y
[`tests/camera_arm_checks.gd`](../../../tests/camera_arm_checks.gd): tiempos de seguimiento, protecciones al correr
hacia la cámara y ante giros bruscos, espera tras la órbita, alineación de inclinación y zoom, suavizado en
escaleras, obstáculos, acercamiento opcional, grupos ignorados y transparencia.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
