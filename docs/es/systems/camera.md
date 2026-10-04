<!-- translation of docs/en/systems/camera.md @ 2985993ef79c -->
# Cámara

> Esta es una traducción del [original en inglés](../../en/systems/camera.md).
> Si hay diferencias, la versión en inglés es la correcta.

Dos nodos: `OrbitCameraRig` sigue a un objetivo, orbita y hace zoom; su hijo `CameraArm` sostiene el `Camera3D` en el
extremo de un brazo y acorta el brazo ante los obstáculos.

```
CameraRig (OrbitCameraRig)     colocado en el objetivo, girado según la guiñada y la inclinación
└── CameraArm (CameraArm)      brazo a lo largo del +Z local; el rig fija su longitud según el zoom
    └── Camera3D               en el extremo del brazo, mirando hacia atrás a lo largo de él
```

El rig es hermano del objetivo, no su hijo. Se mueve en `_process` a la posición interpolada del objetivo, y su
propia interpolación de física está desactivada: de lo contrario suavizaría una posición ya suavizada y se retrasaría
un tick. Con la interpolación de física activada en el proyecto, la cámara y el personaje se mueven con fluidez a
cualquier tasa de fotogramas.

## OrbitCameraRig

- **Órbita.** Mantén el botón derecho (`camera_rotate`) y mueve el mouse. El cursor queda capturado mientras orbitas
  y vuelve a donde estaba al soltar el botón. Si la ventana pierde el foco o el juego se pausa en plena órbita, el
  rig libera el cursor por sí mismo.
- **Inclinación con el mouse** (`mouse_pitch`, desactivado por defecto). El movimiento vertical del mouse con el
  botón derecho también inclina la cámara. Desactivado, la inclinación viene solo del zoom.
- **Zoom.** La rueda mueve la cámara hacia abajo y más cerca o hacia arriba y más lejos. La distancia y la
  inclinación cambian juntas.
- **Seguimiento** (`follow_movement`, `follow_pitch`, ambos desactivados por defecto). La cámara gira gradualmente
  tras el objetivo que corre y lleva suavemente su inclinación a `follow_pitch_angle`.

### La curva de zoom

El zoom es un valor de 0 (lo más cerca) a 1 (lo más lejos); cada paso de la rueda lo cambia en `zoom_step` (0,1). La
distancia va de `near_distance` (5 m) a `far_distance` (20 m). La inclinación va de `near_pitch` (−22°) a
`far_pitch` (−55°), pero no de manera uniforme: desde arriba hasta `flatten_start_zoom` (0,5; 12,5 m; −38,5°)
cambia de manera uniforme, y por debajo la cámara se nivela rápido, para que lo que hay delante del personaje ya se
vea a una altura media. Desde `flatten_end_zoom` (0,2; 8 m) la cámara mira a −22° y solo se acerca.

La demo empieza en `start_zoom` 0,55. Un paso hacia abajo desde ahí: −33,5°; dos: −26°; tres (8,75 m): −22,5°.

La inclinación es la del zoom más un desplazamiento. El mouse (con `mouse_pitch`) y el modo de seguimiento cambian el
desplazamiento, así que la rueda y el mouse funcionan como siempre y al correr la inclinación vuelve suavemente al
ángulo elegido. Desactivar `mouse_pitch` borra el desplazamiento. La inclinación nunca pasa de `min_pitch` (−80°) ni
de `max_pitch` (−8°).

### Modo de seguimiento

| Propiedad | Por defecto | Significado |
|---|---|---|
| `follow_movement` | desactivado | Girar la cámara tras el objetivo que corre |
| `follow_pitch` | desactivado | Llevar suavemente la inclinación a `follow_pitch_angle` al correr, al mismo ritmo y en los mismos casos que el giro; funciona sin `follow_movement` |
| `follow_pitch_angle` | −40° | Inclinación objetivo (hacia abajo es negativa), limitada por `min_pitch` y `max_pitch` |
| `follow_time` | 1,5 s | Tiempo para girar casi del todo (queda el 5% del ángulo); 0 es instantáneo |
| `follow_min_speed` | 1 m/s | Por debajo de esta velocidad la cámara no gira: parado o pivotando, la dirección no es fiable. Entre esta velocidad y el doble, el giro gana fuerza con suavidad |

La configuración de la demo usa otros valores por defecto: tiempo de alcance de 1,1 s e inclinación de 22° hacia
abajo.

La cámara no sigue:

- mientras se mantiene el botón derecho: el mouse controla la cámara, también al correr con ambos botones;
- durante los primeros 0,2 s tras presionar el botón izquierdo, hasta que queda claro si es un clic o una pulsación
  mantenida. La pausa viene de `PointClickMoveInput.hold_pending_changed`, conectada en `main.tscn` a
  `CameraRig.set_follow_paused()`.

El rig mide la velocidad del objetivo a partir de su movimiento por tick de física, así que cualquier `Node3D` puede
ser el objetivo.

Cuando la cámara gira mientras se mantiene el botón izquierdo, el cursor apuntaría a otro punto del suelo y el
personaje giraría tras él, y la cámara tras el personaje: el personaje correría en círculos. Por eso, mientras se
mantiene el botón, la entrada mueve el cursor del sistema junto con el mundo. Ver
[Entrada](input.md#el-cursor-con-el-botón-mantenido).

### Propiedades

| Grupo | Propiedad | Por defecto | Significado |
|---|---|---|---|
| | `target` | — | Qué seguir |
| | `arm` | — | El `CameraArm`; si está vacío, el primer hijo `CameraArm` |
| | `camera` | — | Se usa sin brazo; si está vacío, el primer hijo `Camera3D` |
| Input | `rotate_action`, `zoom_in_action`, `zoom_out_action` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` | Acciones de entrada |
| | `mouse_sensitivity` | 0,25 °/px | Velocidad de órbita |
| | `mouse_pitch` | desactivado | El movimiento vertical del mouse inclina la cámara |
| | `invert_pitch` | desactivado | Invertir esa inclinación |
| | `zoom_step` | 0,1 | Cambio de zoom por paso de la rueda |
| Framing | `focus_height` | 1,2 m | Altura sobre el origen del objetivo a la que mira la cámara |
| | `near_distance`, `far_distance` | 5 m, 20 m | Longitud del brazo con el zoom más cercano y con el más lejano |
| | `near_pitch`, `far_pitch` | −22°, −55° | Inclinación con el zoom más cercano y con el más lejano |
| | `flatten_start_zoom`, `flatten_end_zoom` | 0,5; 0,2 | Dónde la inclinación empieza a nivelarse más rápido, y dónde queda nivelada |
| | `min_pitch`, `max_pitch` | −80°, −8° | Límites de la inclinación |
| | `start_zoom`, `start_yaw` | 0,55; 45° | Zoom y dirección iniciales |
| Follow | ver arriba | | |
| Smoothing | `rotation_sharpness`, `zoom_sharpness` | 30, 10 | Qué tan rápido alcanza la cámara la guiñada, la inclinación y el zoom deseados |

Métodos: `look_along(direction)` gira la cámara para que mire en una dirección de inmediato; `snap()` salta a la
posición deseada, por ejemplo tras teletransportar al objetivo; `is_rotating()`; `set_follow_paused(paused)`.

## CameraArm

La rueda fija la longitud del brazo; el brazo se acorta ante los obstáculos y vuelve a esa longitud cuando hay
espacio.

- **Detenerse ante lo que hay detrás** (`keep_out_of_geometry`, activado por defecto). Una montaña, una pared o un
  techo detrás de la cámara: la cámara no entra, sino que se acerca al objetivo. Camina hacia la montaña y la cámara
  se acerca al objetivo sin entrar en la ladera; aléjate y la cámara vuelve atrás en cuanto tiene espacio detrás. El
  brazo solo se acorta si la cámara no puede estar en su extremo. Una columna o una cerca entre la cámara y el
  objetivo, con espacio detrás, no mueve la cámara: el personaje se ve a través como silueta.
- **Acercarse cuando el objetivo queda oculto** (`pull_in_on_occlusion`, desactivado por defecto). Una cerca o una
  pared oculta casi por completo al objetivo: la cámara se coloca suavemente delante del obstáculo, pero nunca más
  cerca del objetivo que `min_pull_in_length` (2,5 m). Si el personaje está justo junto a la pared, la cámara se
  queda quieta en lugar de saltar a la espalda del personaje.
- **Desvanecimiento de cerca.** Cuando el brazo es muy corto, `fade_target` se vuelve translúcido.

| Propiedad | Por defecto | Significado |
|---|---|---|
| `length` | 10 m | Longitud del brazo; la fija el rig según el zoom |
| `camera` | — | La cámara; si está vacía, el primer hijo `Camera3D` |
| `keep_out_of_geometry` | activado | Detenerse ante los cuerpos detrás de la cámara |
| `probe_radius` | 0,3 m | La cámara es una esfera de este radio y se mantiene a esa distancia de las paredes |
| `collision_mask` | capas 1 y 3 | Cuerpos que detienen el brazo: `world` y `camera`. Los personajes (capa 2) no |
| `ignored_groups` | `camera_ignore` | Los cuerpos de estos grupos, o bajo un nodo que esté en ellos, no detienen el brazo |
| `pull_in_on_occlusion` | desactivado | Acercarse cuando el objetivo queda oculto |
| `min_pull_in_length` | 2,5 m | La cámara no se acerca más que esto por un objetivo oculto; con menos espacio delante del obstáculo, se queda quieta |
| `pull_in_sharpness` | 10 | Qué tan rápido se coloca la cámara delante de un obstáculo que oculta (0 es instantáneo). Ante un cuerpo detrás siempre se detiene de inmediato |
| `occlusion_points` | pecho, cabeza, rodillas, costados | Puntos del objetivo cuya visibilidad se comprueba, relativos al inicio del brazo: derecha, arriba, hacia la cámara |
| `occlusion_share` | 0,75 | El objetivo está oculto cuando esta fracción de los puntos está oculta. Un poste delgado o un tronco oculta tres de cinco y no cuenta |
| `occlusion_delay` | 0,25 s | Cuánto tiempo debe seguir oculto el objetivo para que la cámara se acerque, y visible para que vuelva |
| `return_delay`, `return_sharpness` | 0,3 s; 4 | El brazo se acorta de inmediato, pero vuelve a crecer tras una pausa y con suavidad, para que la cámara no tiemble entre columnas |
| `fade_target` | — | Lo que se vuelve translúcido de cerca (`Player/Visual` en la demo) |
| `fade_start_length`, `fade_end_length`, `fade_transparency` | 1,5 m; 0,7 m; 0,75 | El objetivo empieza a desvanecerse en la primera longitud y es 75% transparente en la segunda |
| `debug_draw` | desactivado | Dibujar el brazo (gris: la longitud de la rueda; verde: la actual), la esfera de la cámara y los rayos hacia los puntos del objetivo (rojo: oculto). Visible desde otra cámara |

Métodos: `snap()`, `get_current_length()`, `is_pulled_in_by_occlusion()`.

### Cuerpos solo para la cámara

Ponlos en la capa de física 3 (`camera`). Los personajes no colisionan con ellos, y los clics y la navegación no los
ven. El techo de la casa (`RoofCameraBlocker` en `shared/world/props/house.tscn`) tiene un cuerpo así: la cámara se
detiene en el techo, pero nadie puede subirse a él ni trazar una ruta por encima.

### El grupo `camera_ignore`

El grupo también se aplica a todo lo que está bajo un nodo que esté en él. Asígnalo una vez en la raíz de una escena
de prop, para que lo tenga cada instancia en el nivel, o en un nodo carpeta del nivel. La demo no lo necesita: los
troncos de los árboles (hasta 2,4 m) quedan por debajo de la cámara incluso con el zoom más cercano (3 m sobre el
suelo).

### Cómo distingue el brazo el espacio detrás de un obstáculo de estar dentro de un cuerpo

Primero el brazo comprueba si la cámara puede estar en el extremo del brazo: allí la esfera no toca nada y el extremo
no está dentro de un cuerpo. Un rayo desde la cámara hacia el objetivo no ve las caras de un cuerpo dentro del cual
empieza, así que encuentra la cara lejana del obstáculo que hay delante de la cámara. Un rayo desde esa cara hasta el
extremo del brazo entra en el cuerpo en el que está la cámara y nunca sale de él. Si algo estorba, la esfera se
lanza desde esa cara hacia la cámara y se detiene delante del cuerpo que estorba, pasando de largo los demás. Una
columna que el brazo solo roza no mueve la cámara.

Jolt no informa los cuerpos que la esfera toca al inicio de un lanzamiento. Así que, si otro cuerpo está justo detrás
de la cara (una cerca con un acantilado detrás), se busca espacio libre más cerca del objetivo.

## Comportamiento medido

De `tests/camera_checks.gd` y `tests/camera_arm_checks.gd`:

- Seguimiento con la carrera a 90° respecto a la cámara: `follow_time` 0 gira el 95% en 0,17 s, el 1,1 de la demo en
  1,23 s; con 10 solo ha girado 39° de 90° tras 2 s. Parado, no gira. Con el botón derecho mantenido no gira, y
  continúa después de soltarlo.
- Mantener el botón izquierdo con el seguimiento activado (1,1 s): durante los primeros 0,2 s la cámara se queda
  quieta (un clic corto no la mueve), luego en 1,25 s gira 27,1° de los 28,3° que la separan de la espalda del
  personaje mientras la dirección de carrera cambia 0,01°; con "al instante", también. Mover el mouse 150 px gira la
  carrera 25°, y la nueva dirección se mantiene. Con `keep_aim_on_camera_turn` desactivado, el personaje se curva
  77,6° en 1,25 s.
- Alineación de la inclinación: una cámara bajada con la rueda (22,5° hacia abajo) pasa suavemente a 55° con
  `follow_time` 0,5, el 95% del camino en unos 0,65 s, sin girar tras la carrera si el giro está desactivado. 89° se
  limita al tope de 80° de la cámara. Mantener el botón izquierdo con seguimiento y una inclinación de 20°: la
  inclinación va de 80° a 22,5° en 1,25 s, camino de los 20°, y la dirección de carrera cambia 0,01°.
- El brazo: longitud completa en campo abierto; un acantilado detrás lo detiene de inmediato; al caminar hacia el
  acantilado, la cámara se acerca y queda fuera de él; sin el acantilado, el brazo vuelve tras una pausa, con
  suavidad. Una cerca con un acantilado justo detrás: la cámara se detiene delante de la cerca. Una cerca a mitad de
  camino entre la cámara y el personaje: por defecto la cámara se queda detrás de ella; con el acercamiento se coloca
  delante con suavidad, y una oclusión breve no cuenta. Una cerca justo junto al personaje: la cámara no salta a la
  espalda del personaje. Un poste delgado no cuenta, una columna que roza el brazo no mueve la cámara, los cuerpos en
  `camera_ignore` no la detienen y, de cerca, el personaje es translúcido.

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
