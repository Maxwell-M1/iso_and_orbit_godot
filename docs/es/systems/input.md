<!-- translation of docs/en/systems/input.md @ 4f1e5987b000 -->
# Entrada

> Esta es una traducción del [original en inglés](../../en/systems/input.md).
> Si hay diferencias, la versión en inglés es la correcta.

Dos nodos convierten la entrada del jugador en órdenes. Ninguno mueve nada por sí mismo.

- `PointClickMoveInput`: el mouse, y WASD con el botón derecho mantenido → `NavigationMover.move_to()`, `steer()`
  y `stop()`.
- `CharacterActionInput`: teclas de sprint y salto → `GroundCharacter.sprint_requested` y `jump()`.

Ambos viven en `main.tscn`, no en la escena del personaje, así que el mismo personaje puede ser controlado por una IA
en su lugar. Para ver los controles desde el punto de vista del jugador, consulta [Controles](../controls.md).

## PointClickMoveInput

| Entrada | Orden |
|---|---|
| Clic en el suelo | `move_to(point)`: un rayo desde la cámara sobre `ground_mask` encuentra el punto |
| Botón izquierdo mantenido | `steer()` hacia el cursor, o `move_to()` hasta el punto bajo él, según `hold_mode` |
| Botones izquierdo y derecho mantenidos | `steer()` hacia donde mira la cámara; A y D desvían en diagonal hacia adelante (`keys_with_camera_steer`) |
| Botón derecho y WASD | `steer()` según la cámara, de costado o girando (`keys_with_camera`); `stop()` al soltar |

Quién controla al personaje en un tick se decide en un solo lugar, `_physics_process`: primero un botón izquierdo
mantenido y, si no, las teclas con el botón derecho. Así, soltar el botón izquierdo mientras se mantienen el botón
derecho y W no detiene al personaje: las teclas toman el control de inmediato.

### Clic o mantener

Una pulsación se convierte en pulsación mantenida después de `hold_delay` (0,2 s). Hasta entonces el personaje sigue
haciendo lo que hacía (quieto, o corriendo hacia donde corría), y no hay marcador ni ruta hacia el punto presionado.

- **Se suelta antes: un clic.** El personaje corre por una ruta hasta el punto donde se presionó el botón. El punto
  se toma en el momento de presionar, aunque el mouse se haya movido después. Aparece el marcador
  (`destination_picked`). Se desvanece cuando el personaje llega o cuando la carrera se abandona por las teclas o por
  una pulsación mantenida.
- **Se mantiene más tiempo: una pulsación mantenida.** El personaje corre tras el cursor de inmediato
  (`hold_started`) y no gira primero hacia el punto presionado. De lo contrario empezaría a seguir la ruta hacia ese
  punto, y una ruta que rodea obstáculos puede llevar a un lugar completamente distinto del cursor.

El precio es que un clic actúa al soltar, unos 0,1 s más tarde que al presionar. Mientras no está claro si una
pulsación es un clic o una pulsación mantenida, `hold_pending_changed(true)` pausa el modo de seguimiento de la
cámara, así que un clic corto nunca mueve la cámara.

Si el botón derecho ya está mantenido cuando se presiona el izquierdo, no hay clic: el personaje corre tras la cámara
de inmediato.

### Modos de pulsación mantenida

`hold_mode` (Configuración → Controles → **Clic izq. mantenido**):

- `STEER` (por defecto): directo hacia el cursor, sin ruta. El personaje se desliza junto a los obstáculos y sube la
  rampa hacia donde lo apuntes. Dentro de `steer_dead_zone` (0,5 m) alrededor del personaje la dirección no cambia:
  tan cerca, sería demasiado sensible al cursor. Al soltar, el personaje se detiene suavemente.
- `FOLLOW_POINT`: hasta el punto bajo el cursor por una ruta de navegación. La ruta se reconstruye mientras el punto
  se mueve, así que cerca de los cambios de altura (la rampa, la plataforma) puede saltar de un recorrido a otro. Al
  soltar, el personaje sigue corriendo hasta el último punto y el marcador lo indica (`destination_picked`); con
  `stop_on_release` frena hasta detenerse donde está.

### Teclas con el botón derecho

Las teclas funcionan solo mientras se mantiene el botón derecho: la cámara gira con el mouse y el cursor queda
capturado. Sin él, WASD no hacen nada. Cada modo es `OFF` o una de dos variantes, que se fijan por separado para el
botón derecho solo (`keys_with_camera`) y para ambos botones (`keys_with_camera_steer`).

| | `SIDESTEP` | `TURN` |
|---|---|---|
| Clic der. + W | hacia adelante, adonde mira la cámara | igual |
| Clic der. + A / D | de costado, mirando al frente | gira a la izquierda / derecha y va hacia allí |
| Clic der. + S | hacia atrás, mirando al frente, más lento | se da la vuelta y camina hacia la cámara |
| Dos teclas (W + A, S + D…) | en diagonal, mirando al frente | en diagonal, mirando hacia donde va |
| Clic izq. + der. + A / D | en diagonal hacia adelante, mirando al frente | en diagonal hacia adelante, mirando hacia donde va |

El valor por defecto del script es `SIDESTEP` para ambos; la configuración de la demo usa `TURN` por defecto para
ambos.

El movimiento en diagonal es tan rápido como el recto. El movimiento hacia atrás es más lento: `NavigationMover`
escala la velocidad según cuánto se opone el movimiento a la orientación, ver
[Locomoción](locomotion.md#navigationmover). La orientación se pasa como segundo argumento de
`steer(direction, facing)`: en modo lateral es la dirección hacia adelante de la cámara. Tras detenerse, el personaje
sigue mirando hacia donde miraba; un clic o una pulsación mantenida lo vuelve a orientar hacia donde corre.

Suelta las teclas o el botón derecho y el personaje se detiene suavemente. El botón derecho solo, sin teclas, no
interrumpe una carrera hacia un punto de clic, así que puedes girar la cámara mientras corres. Las teclas sí la
interrumpen, y el marcador se desvanece. Las teclas son las acciones `move_forward`, `move_back`, `move_left`,
`move_right`, asignadas por posición física.

### El cursor con el botón mantenido

**Oculto** (`hide_cursor_while_held`, activado por defecto). Al correr, el cursor solo parpadearía, sobre todo mientras
la cámara gira y el cursor se mueve con el mundo. Se oculta en cuanto una pulsación se convierte en pulsación mantenida
(un clic corto no lo toca) y reaparece al soltar, donde apuntaste. Mientras tanto, el modo del mouse es
`MOUSE_MODE_CONFINED_HIDDEN`: un cursor simplemente oculto podría salir de la ventana y aparecer en su borde. En macOS
el motor confina el cursor moviéndolo por su cuenta y cuenta dos veces cada movimiento que mantiene la mira (abajo), así
que la mira se desvía. Allí el modo es `MOUSE_MODE_HIDDEN`. El cursor del sistema oculto no sigue la mira en ningún
sistema: nadie lo ve, y en la pestaña Juego (Game) del editor en macOS cada uno de esos movimientos le llega uno o dos
fotogramas tarde, así que el personaje daría tirones en los giros. El componente mueve su propio cursor según el
movimiento del mouse, devuelve el cursor del sistema al centro de la ventana cuando llega al borde y, al soltar, lo
coloca donde apuntaste. Mientras el botón derecho orbita la cámara, la cámara captura el cursor; suelta el botón derecho
con el izquierdo todavía mantenido y el cursor vuelve a quedar oculto. Al pausar (la ventana de configuración) o al
cambiar a otra ventana, se muestra de inmediato. `is_cursor_hidden()` indica si el componente lo ha ocultado.

**Mantiene la mira** (`keep_aim_on_camera_turn`, activado por defecto). Mientras se mantiene el botón izquierdo, la
dirección de carrera viene del cursor, un punto en la pantalla. Si la cámara gira mientras el cursor se queda quieto en
la pantalla, bajo el cursor queda otro punto del suelo, el personaje gira tras él, la cámara gira tras el personaje y el
personaje corre en círculos (77,6° en 1,25 s con el tiempo de alcance de 1,1 s de la demo; con "al instante" simplemente
da vueltas sobre sí mismo). Por eso, mientras se mantiene el botón, el componente mueve el cursor junto con el mundo (el
cursor del sistema visible con `Viewport.warp_mouse()`, uno oculto solo al soltar): el cursor se queda sobre el mismo
punto del suelo, el personaje corre adonde apuntaste y la cámara se coloca suavemente detrás. Mover el mouse gira al
personaje como siempre. Después de soltar, el cursor queda libre.

Desactivado, el cursor conduce como un auto: mantenlo a la derecha del personaje y el personaje se desvía a la derecha
hasta que el cursor queda justo delante. Donde el sistema no puede mover el cursor (Wayland, por ejemplo), la
dirección de carrera se mantiene, pero el cursor se queda quieto.

El cursor se corrige en `_process` después de que la cámara se haya asentado en ese fotograma: el `process_priority`
del componente es 1 y el de la cámara, 0. La entrada lee el `Camera3D` directamente y no sabe nada del rig de la
cámara.

### Propiedades

| Propiedad | Por defecto | Significado |
|---|---|---|
| `mover` | — | El `NavigationMover` al que dar órdenes; obligatorio |
| `camera` | — | Cámara para los rayos y las direcciones; si está vacía, la cámara actual del viewport |
| `move_action` | `move_to_cursor` | Clic y pulsación mantenida |
| `hold_mode` | `STEER` | Ver arriba |
| `keep_aim_on_camera_turn` | activado | Ver arriba |
| `hide_cursor_while_held` | activado | Ver arriba |
| `camera_steer_action` | `camera_rotate` | Con ella mantenida, una pulsación mantenida corre hacia donde mira la cámara; vacía, lo desactiva |
| `ground_mask` | capa 1 | Capas de física en las que se puede hacer clic. No debe incluir la capa de los personajes |
| `hold_delay` | 0,2 s | Cuándo una pulsación se convierte en pulsación mantenida |
| `steer_dead_zone` | 0,5 m | `STEER`: sin cambio de dirección con el cursor así de cerca del personaje |
| `stop_on_release` | desactivado | `FOLLOW_POINT`: frenar hasta detenerse al soltar en lugar de seguir corriendo hasta el último punto |
| `ray_length` | 1000 m | Longitud del rayo desde la cámara |
| `keys_with_camera` | `SIDESTEP` | Modo de clic der. + WASD |
| `keys_with_camera_steer` | `SIDESTEP` | Modo de clic izq. + der. + A/D |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | Las teclas |

Señales: `destination_picked(point)`, `hold_started`, `hold_pending_changed(pending)`.

Al iniciar, el componente comprueba que existan sus acciones de entrada e informa de la falta de alguna como error.

## CharacterActionInput

| Propiedad | Por defecto | Significado |
|---|---|---|
| `character` | — | El `GroundCharacter` al que dar órdenes |
| `sprint_action` | `sprint` | Shift |
| `jump_action` | `jump` | Espacio |
| `sprint_mode` | `HOLD` | `HOLD`: sprint mientras se mantiene la tecla. `TOGGLE`: una pulsación activa el sprint y la siguiente lo desactiva; también se desactiva solo cuando el personaje se agota y no vuelve tras el descanso |

El componente solo transmite la entrada; el personaje decide si hay resistencia para un sprint y si puede saltar en
ese momento. Se ejecuta en el tick de física antes que el personaje (`process_physics_priority = -1`), así que una
pulsación y una liberación llegan al personaje sin un tick extra de retraso. `is_sprint_toggled()` indica el estado
de `TOGGLE`.

### Shift no se queda pegado

En modo `HOLD` el sprint se lee en cada tick de `Input.is_action_pressed()`, así que soltar Shift lo termina. Esto se
comprueba con eventos reales: al correr, al correr con el botón izquierdo mantenido, al soltarlo en la ventana de
configuración, después de cambiar de modo.

Pero a veces la liberación en sí nunca llega al juego, y el motor considera que Shift sigue presionado hasta que se
vuelve a presionar. Esto pasa cuando el juego está incrustado en la pestaña Juego (Game) del editor y el foco pasa al
editor (`Input.release_pressed_events()` omite el restablecimiento mientras la ventana del editor tiene el foco), o
cuando un atajo del sistema se traga la liberación. Para este caso, el componente compara el sprint con el estado
real de Shift que lleva cada evento de mouse y de teclado (`shift_pressed`; en Windows viene de
`GetKeyboardState`). Si cualquier evento de mouse o de teclado distinto de la propia tecla de sprint dice que Shift
está suelto, la pulsación atascada se libera. Esto funciona cuando todas las teclas asignadas a la acción de sprint
son modificadoras (Shift, Ctrl, Alt, Meta).

Si Windows activa las teclas especiales (Sticky Keys; cinco pulsaciones de Shift seguidas), Shift se queda pegado en
el propio sistema; desactívalas en la configuración de Windows.

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
