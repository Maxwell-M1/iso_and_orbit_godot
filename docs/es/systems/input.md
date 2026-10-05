<!-- translation of docs/en/systems/input.md @ 286e042594f2 -->
# Entrada

[← Índice de documentación](../index.md)

> Esta es una traducción del [original en inglés](../../en/systems/input.md).
> Si hay diferencias, la versión en inglés es la correcta.

Dos nodos convierten la entrada del jugador en órdenes. Ninguno mueve nada por sí mismo.

- `PointClickMoveInput`: el mouse, y WASD con el botón derecho mantenido → `NavigationMover.move_to()`, `steer()`
  y `stop()`.
- `CharacterActionInput`: teclas de sprint y salto → `GroundCharacter.sprint_requested` y `jump()`.

Ambos están en la escena del héroe jugable (`playable_hero.tscn`), no en la escena del personaje, de modo que una IA
puede controlar ese mismo cuerpo. Para los controles vistos por el jugador, consulta [Controles](../controls.md).
Para copiar el héroe montado, sigue [Integración](../integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto);
para combinaciones recomendadas, [Configuraciones](../configurations.md).

## PointClickMoveInput

| Entrada | Orden |
|---|---|
| Clic en el suelo | `move_to(point)`: un rayo desde la cámara sobre `ground_mask` encuentra el punto |
| Botón izquierdo mantenido | `steer()` hacia el cursor, o `move_to()` hasta el punto bajo él, según `hold_mode` |
| Derecho y luego izquierdo, o ambos dentro de `hold_delay` | `steer()` hacia donde mira la cámara; A y D desvían en diagonal hacia adelante (`keys_with_camera_steer`) |
| Izquierdo mantenido y luego derecho | No se envía otra orden: la pulsación conserva la dirección mientras el derecho gira la cámara (`look_around_while_held`) |
| Botón derecho y WASD | `steer()` según la cámara, de costado o girando (`keys_with_camera`); `stop()` al soltar |

Quién controla al personaje en un tick se decide en un solo lugar, `_physics_process`: primero un botón izquierdo
mantenido y, si no, las teclas con el botón derecho. Así, soltar el botón izquierdo mientras se mantienen el botón
derecho y W no detiene al personaje: las teclas toman el control de inmediato.

A la inversa, al soltar el derecho durante una carrera con ambos botones se conserva el rumbo de la cámara
(`keep_camera_course`). El cursor vuelve a dirigir cuando se mueve más de 8 px y ha transcurrido
`cursor_takeover_delay` (0.2 s, para evitar el movimiento residual de la mano); parte de un punto 4 m delante del
personaje, en la dirección de carrera. Hasta entonces, soltar el izquierdo detiene al personaje en su rumbo,
como si ambos botones se soltaran juntos, sin importar el intervalo. Casi nadie suelta dos botones exactamente
al mismo tiempo. Con `keep_camera_course` desactivado, el cursor retoma el control en cuanto se suelta el derecho
desde su posición anterior a la órbita; esto puede girar bruscamente al personaje.

### Mirar alrededor durante la carrera

Pulsar el derecho mientras ya se corre tras el cursor con el izquierdo solo hace orbitar la cámara
(`look_around_while_held`, activado): quien corre a su destino quiere mirar alrededor sin entregar el rumbo a la
cámara. Sin este ajuste, el héroe giraría al instante hacia la vista, que con seguimiento desactivado rara vez
coincide con su dirección. El orden se captura al pulsar el derecho:

- Durante una pulsación sostenida dirigida por el cursor, sirve para mirar alrededor.
- Antes de que el izquierdo se convierta en pulsación sostenida (`hold_delay`, 0.2 s), con ambos botones casi a la
  vez o el derecho primero, corre hacia donde mira la cámara.
- Durante una pulsación que aún conserva el rumbo de cámara tras soltar el derecho (`keep_camera_course`), vuelve
  a correr según la cámara. Tras mover el ratón y devolver el control al cursor, la siguiente pulsación del
  derecho vuelve a permitir mirar alrededor.

Requiere que `camera_steer_action` gire la cámara, como hace `OrbitCameraRig.rotate_action` (ambas son
`camera_rotate`): mientras se mantiene el botón, el ratón no mueve la mira. Si usas otra acción o una cámara que
no gira con ella, desactiva `look_around_while_held`. Al mirar alrededor las teclas no actúan: la pulsación
izquierda controla la carrera como si no estuviera pulsado el derecho.

La mira no sigue al ratón mientras se mira alrededor: es un punto del suelo respecto a los pies del personaje que
también mantiene el rumbo durante el giro automático (`keep_aim_on_camera_turn`). El ratón gira la cámara y, en
modo `STEER`, el personaje corre hacia esa mira. Al soltar el derecho, el cursor vuelve allí y el ratón puede
dirigir de nuevo. Si una órbita grande saca la mira de pantalla, se acerca a lo largo de la misma dirección para
evitar un giro brusco en el borde.

En modo `FOLLOW_POINT`, el destino permanece donde estaba respecto a los pies mientras miras alrededor y hasta
que muevas el ratón más de 8 px tras `cursor_takeover_delay`, como con `keep_camera_course`. El personaje mantiene
la carrera y no llega a ese punto. Desde otro ángulo, el rayo bajo el cursor puede tocar una rampa o plataforma a
otra altura. Si la pulsación ya alcanzó su destino (cursor en los pies), mirar alrededor lo deja allí. Tras soltar,
el cursor apunta al mismo lugar visto desde la cámara nueva, salvo si algo lo oculta.

Si sueltas el izquierdo mientras el derecho gira la cámara, el cursor oculto reaparece en el punto al que apuntaba
cuando la cámara lo libera, no donde esta lo devuelve (su posición al comenzar la órbita).

Con `keep_aim_on_camera_turn` desactivado, el cursor permanece en pantalla y la órbita gira la carrera con él
(90° de órbita producen 90° de giro), igual que un giro automático de cámara. Para pasar de mirar alrededor a
correr según la cámara sin detenerte, pulsa otra vez el izquierdo manteniendo el derecho. Con
`look_around_while_held` desactivado, el derecho dirige la carrera con cualquier orden de pulsaciones.

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
pulsación es un clic o una pulsación mantenida, `hold_pending_changed(true)` pausa el seguimiento de cámara
(conectado con `OrbitCameraRig.set_follow_paused()` en `playable_hero.tscn`), así que un clic corto no la mueve.

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
  `stop_on_release` frena donde está. Solo afecta a las pulsaciones sostenidas: un clic breve siempre corre hasta
  el punto elegido. Una ruta vacía hace correr directamente y una parcial puede terminar antes del destino;
  consulta [Locomoción](locomotion.md#navigationmover).

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

El valor del script es `SIDESTEP` para ambos; la demo y `playable_hero.tscn` establecen `TURN` para ambos.
`keys_with_camera_steer = OFF` desactiva A/D mientras se mantienen ambos botones, pero estos todavía hacen
correr hacia donde mira la cámara. Desactivar también esa orden exige cambiar `camera_steer_action`, lo que afecta
a mirar alrededor y a las teclas con el botón derecho.

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

**Oculto** (`hide_cursor_while_held`, activado por defecto). Durante una carrera el cursor parpadearía, sobre todo
cuando gira la cámara y se mueve la mira con el mundo. Se oculta al convertirse la pulsación en sostenida (un clic
breve no lo cambia) y reaparece en el punto apuntado al soltar. El componente mantiene el cursor oculto dentro de
la ventana: en macOS usa `MOUSE_MODE_HIDDEN`; en otros sistemas, `MOUSE_MODE_CONFINED_HIDDEN`, para evitar que el
movimiento impuesto por la plataforma desvíe la mira. Mientras el derecho orbita, la cámara captura el cursor;
si lo sueltas y mantienes el izquierdo, vuelve a ocultarse. Pausar o cambiar de ventana lo muestra al instante.
`is_cursor_hidden()` indica si lo ocultó este componente.

**Mantiene la mira** (`keep_aim_on_camera_turn`, activado por defecto). Mientras se mantiene el botón izquierdo, la
dirección de carrera viene del cursor, un punto en la pantalla. Si la cámara gira mientras el cursor se queda quieto en
la pantalla, bajo él queda otro punto del suelo, el personaje gira tras ese punto, la cámara gira tras el personaje
y termina corriendo en círculos. Por eso, mientras se mantiene el botón, el componente mueve la mira con el mundo:
el personaje conserva la dirección mientras la cámara se coloca detrás. Mover el ratón sigue dirigiendo. La misma
mira conserva el rumbo al orbitar con el derecho para mirar alrededor durante la carrera.

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
| `camera_steer_action` | `camera_rotate` | Si se mantiene, la carrera sigue la cámara cuando se pulsó antes o durante la espera; consulta `look_around_while_held`. Vacía desactiva esa carrera, mirar alrededor y las teclas que requieren ese botón |
| `look_around_while_held` | activado | El botón de cámara pulsado durante una carrera tras el cursor solo gira la cámara y conserva el rumbo. Desactivado: ambos botones corren según la cámara con cualquier orden |
| `keep_camera_course` | activado | Tras soltar el botón de cámara, conserva su rumbo hasta mover el ratón; el cursor se coloca delante del personaje. Desactivado: retoma de inmediato desde su posición anterior |
| `cursor_takeover_delay` | 0.2 s | Con `keep_camera_course`, ignora para este cambio el movimiento del ratón inmediatamente posterior a soltar el botón |
| `ground_mask` | capa 1 | Superficies físicas donde puede apuntar un clic. Excluye la capa del personaje y las paredes invisibles (capa 4, `bounds`) |
| `hold_delay` | 0,2 s | Cuándo una pulsación se convierte en pulsación mantenida |
| `steer_dead_zone` | 0,5 m | `STEER`: sin cambio de dirección con el cursor así de cerca del personaje |
| `stop_on_release` | desactivado | `FOLLOW_POINT`: frenar hasta detenerse al soltar en lugar de seguir corriendo hasta el último punto |
| `ray_length` | 1000 m | Longitud del rayo desde la cámara |
| `keys_with_camera` | `SIDESTEP` (`TURN` en la demo) | Modo derecho + WASD |
| `keys_with_camera_steer` | `SIDESTEP` (`TURN` en la demo) | Modo izquierdo + derecho + A/D |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | Las teclas |

`ground_mask` selecciona superficies físicas para el rayo del clic; `NavigationMover.navigation_layers` selecciona
regiones transitables para la ruta. Son máscaras independientes. Excluye personajes y paredes invisibles de la
primera para que el rayo no los seleccione en lugar del suelo.

La tabla muestra valores de los componentes y señala las sustituciones `TURN` de la escena del héroe. En la demo,
`SettingsApplier` aplica al iniciar valores guardados para `hold_mode`, ocultar cursor, ambos modos de teclas,
mirar alrededor y mantener la mira. Una copia de `playable_hero.tscn` sin ajustes usa los valores de su escena.

Señales: `destination_picked(point)`, `hold_started`, `hold_pending_changed(pending)` y `run_requested`: el jugador
inició una carrera por clic nuevo, pulsación sostenida o teclas con el derecho. No se emite por un clic al destino
actual ni si las teclas continúan una pulsación recién terminada. En `playable_hero.tscn` termina la espera de
cámara tras orbitar (`CameraRig.end_follow_wait()`; consulta [Cámara](camera.md#modo-de-seguimiento)).

`cancel()` olvida la pulsación en curso: un clic todavía no soltado no inicia la ruta; una carrera controlada por
botón sostenido o teclas con derecho frena suavemente, también en modo `FOLLOW_POINT`, sin continuar al último
destino; y el cursor oculto reaparece en la mira. Un botón que siga pulsado solo cuenta desde la próxima pulsación;
las teclas con derecho se leen cada tick y vuelven a caminar enseguida. Una ruta de clic pertenece al componente
de movimiento y continúa (`NavigationMover.halt()` la detiene). El héroe cancela la entrada antes de
teletransportarse y al quitar los controles.

Al iniciar, el componente comprueba que existan las acciones y comunica las ausentes como errores. Después no las
lee: sus botones no hacen nada y el motor no repite el error. Si faltan algunas teclas de movimiento, las demás
siguen funcionando. `CharacterActionInput` y el rig de cámara hacen lo mismo.

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

En modo `HOLD`, la solicitud de sprint se lee en cada tick: soltar Mayús suele terminarla enseguida. A veces
esa liberación no llega a una pestaña Juego incrustada o la intercepta el sistema. Cuando todas las teclas de
`sprint_action` son modificadores (Mayús, Ctrl, Alt o Meta), `CharacterActionInput` también inspecciona los
modificadores de los eventos posteriores de ratón y teclado y libera una pulsación de sprint atascada. Lee las
asignaciones actuales, por lo que también funciona tras reasignarlas durante la partida. Para una tecla de sprint
que no sea modificadora, solo está disponible el estado normal de la acción.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
