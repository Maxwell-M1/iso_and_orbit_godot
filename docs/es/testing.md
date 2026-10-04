<!-- translation of docs/en/testing.md @ e6e4e2d86c01 -->
# Pruebas

> Esta es una traducción del [original en inglés](../en/testing.md).
> Si hay diferencias, la versión en inglés es la correcta.

Las pruebas ejecutan la escena principal en modo headless, con eventos de entrada reales y física real, y comparan
las mediciones con lo esperado.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Aquí `godot` es tu ejecutable de Godot 4.7.2. En Windows usa la compilación `_console.exe`: la normal se separa de la
terminal, así que no ves ninguna salida ni obtienes código de salida. En un clon nuevo, importa primero el proyecto
una vez, en el editor o con `godot --headless --path . --import`.

Solo algunas suites, por ejemplo mientras trabajas en la cámara: partes de sus nombres después de `--`.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

El código de salida es 1 si falla alguna comprobación. Al final, el ejecutor imprime cuántas comprobaciones pasaron y
cuántas fallaron en cada suite.

## Suites

Las suites se ejecutan en el orden de `SUITES` en `tests/run_checks.gd`, sobre una sola instancia de la escena
principal.

| Suite | Qué cubre |
|---|---|
| `movement_checks.gd` | Aceleración y parada exacta, un clic nuevo durante el frenado, un giro durante el frenado, una inversión a toda velocidad. Recorridos: alrededor de la trampa, por el hueco del muro, el laberinto, subir y bajar la rampa, a la plataforma desde los lados de la rampa, un punto inalcanzable sobre una caja. La protección de bordes, y la caída sin ella |
| `world_checks.gd` | La montaña: una ruta del suelo a la cima por el sendero, el lugar se descubre una vez con su mensaje, la ladera no se puede subir fuera del sendero, la protección aguanta en el sendero. El campamento, la granja y las ruinas se descubren con sus mensajes. Los NPC: cinco con equipo y etiquetas, alguien en cada lugar, todos de pie sobre el suelo, las rutas los rodean, nadie los atraviesa. Los aspectos del héroe: diez por número, cada uno con cuerpo, ojos y un bastón en la mano derecha; el pasillo a lo largo de la fila se puede recorrer a toda velocidad |
| `hero_look_checks.gd` | El modelo del jugador: el bastón en la mano derecha al girar; cadenas de silueta separadas para el cuerpo y el equipo, también en mallas agregadas después; la opción del contorno. El balanceo de la mano: quieta al estar parado; balanceándose y bajando al correr, con los extremos en los pasos, alternando; retrasándose al acelerar; volviendo tras una parada; bajando al aterrizar. El aspecto del héroe: el predeterminado al iniciar; cada uno de los diez aplicado en tiempo de ejecución con un solo modelo, el bastón balanceándose en la nueva mano y la silueta en las nuevas mallas |
| `character_actions_checks.gd` | Sprint y fatiga a través de la acción de entrada, la barra de resistencia. Soltar Shift en modo mantener con eventos reales (al correr, con el botón izquierdo, en la ventana de configuración, después del modo alternar, una liberación perdida). El modo alternar. Sprint y salto desactivados, sprint sin fatiga. El salto: altura, el búfer, el tiempo de coyote, un salto desde un borde con la protección activada, un salto de 1,5 m. Señales del personaje: pasos por distancia y más rápidos al esprintar, ninguno parado o en el aire, salto y aterrizaje con la velocidad de caída, bajar la rampa caminando sin aterrizaje, inicio y fin del sprint. Un sonido para cada señal y sus interruptores; el bucle del sprint se repite |
| `input_checks.gd` | Un clic del mouse: sin carrera ni marcador mientras está presionado, carrera hasta el punto presionado tras soltar. Mantener en modo `STEER`: correr hacia el cursor, nunca hacia el punto presionado, sin marcador, parada rápida al soltar. Mantener en modo `FOLLOW_POINT`: correr mientras se mantiene; al soltar, parada rápida con `stop_on_release` o, si no, carrera hasta el último punto del cursor con su marcador. Ambos botones: subir la rampa, girar con la cámara. Clic der. + WASD en modo lateral y giro: dirección, orientación y velocidad para W, A, D, S y pares de teclas; nada sin el botón derecho o en el modo desactivado; detenerse con las teclas y con el botón; el botón derecho solo no interrumpe un clic. Clic izq. + der. + A/D en los tres modos. El botón izquierdo presionado y soltado mientras se camina con clic der. + W: la caminata sigue sin detenerse. Las teclas abandonan una carrera hacia un punto de clic y su marcador se desvanece. El cursor oculto al correr con el botón izquierdo mantenido |
| `camera_checks.gd` | El modo de seguimiento (desactivado, al instante, por defecto, muy lento) y sus pausas (el botón derecho, una pulsación sin decidir). Mantener el botón izquierdo con y sin que el cursor mantenga la mira. Órbita y zoom con el mouse: por debajo de la mitad la rueda nivela la cámara rápido; por defecto el botón derecho no inclina, con la opción sí, y al desactivarla se restaura la inclinación de la rueda. Alineación de la inclinación al correr |
| `camera_arm_checks.gd` | Longitud completa en campo abierto. Un acantilado detrás: parada inmediata; al caminar hacia él, la cámara se acerca y queda fuera; sin el acantilado, regreso tras una pausa, con suavidad; sin la parada, la cámara está dentro del acantilado. Una cerca con un acantilado justo detrás. Una cerca pegada a la cámara: la cámara se coloca delante; una cerca donde espera la cámara: detrás de ella de inmediato. Los cuerpos en la capa de la cámara la detienen, los de la capa de personajes no. Una cerca a mitad de camino: detrás de ella por defecto, delante de ella con suavidad con el acercamiento, una oclusión breve no cuenta. Una cerca junto al personaje: sin salto a la espalda del personaje. Un poste delgado no cuenta. Una columna que roza el brazo no mueve la cámara. Cuerpos en `camera_ignore` y bajo un nodo que esté en él. Desvanecimiento de cerca. Paredes del nivel (laberinto, montaña, tienda, piedras de la cima): la cámara no se mete en ellas. La configuración llega al brazo |
| `settings_window_checks.gd` | F10, la pausa, el foco, la liberación del cursor capturado; los interruptores llegan a sus nodos; la pestaña Controles (modos de las teclas, el control deslizante de ralentización hacia atrás); la pestaña Sonido (el volumen llega al bus `Master`, los interruptores llegan a los sonidos del personaje); la pestaña Personaje (aspecto del héroe, altura del salto, modo de Shift, velocidad extra, fatiga y resistencia); los controles dependientes se atenúan; el control deslizante de inclinación se mantiene dentro de los límites de la cámara; escala de la interfaz; restablecer; Esc |
| `localization_checks.gd` | Inglés por defecto. Cada texto de la interfaz, en las escenas, en la ventana de configuración abierta y en los scripts, tiene traducción en cada idioma, y no hay entradas de traducción sin usar. Cambiar el idioma cambia los textos compuestos por código; los nombres de los idiomas no se traducen; restablecer vuelve al inglés |

## Cómo se comportan las pruebas

- Se ejecutan con la configuración por defecto y no guardan nada: la configuración del jugador se restablece a los
  valores por defecto durante la ejecución y nunca se sobrescribe.
- Cada comprobación restaura lo que cambió. Las suites se ejecutan una tras otra sobre una sola escena principal,
  mientras que una suite ejecutada sola recibe una nueva, y una comprobación debe pasar en ambos casos.
- Cualquier error del motor o de un script también hace fallar la ejecución: un `Logger` agregado con
  `OS.add_logger()` los cuenta, y el ejecutor imprime el total como "engine and script errors" y lo suma a los
  fallos. Una comprobación interrumpida por un error queda incompleta, pero las demás continúan, y sin el contador
  ese error pasaría inadvertido. Con mucha carga de CPU, Jolt puede agregar una advertencia propia, ver
  [Problemas conocidos](known-issues.md#pruebas).
- Una ejecución que se cuelga falla tras 600 s de tiempo de juego.
- Antes de salir, el ejecutor quita la escena principal y espera 0,1 s. Con `--fixed-fps` el tiempo de juego corre
  más rápido que el tiempo real mientras el audio suena en tiempo real, así que los pasos reproducidos justo antes del
  final todavía están sonando. Salir de inmediato a veces hace que el motor informe fugas de objetos
  `AudioStreamPlayback` y de recursos de pasos.
- Una ventana headless no puede mover el cursor del sistema, así que las pruebas solo ven la dirección de carrera; el
  cursor en sí se comprueba en el juego. Una ventana headless tampoco cambia nunca el modo del mouse
  (`Input.mouse_mode` es siempre `VISIBLE`), así que para el cursor oculto las pruebas leen
  `PointClickMoveInput.is_cursor_hidden()`.
- Los límites se calculan a partir de la configuración de los componentes cuando es posible, así que ajustar
  `LocomotionSettings` no rompe las pruebas por sí solo.

## Escribir una comprobación

Una comprobación nueva es una función `_check_…` en la suite adecuada más una línea en `_checks()` de esa suite. Una
suite nueva es un archivo `tests/<topic>_checks.gd` que extiende `check_suite.gd`, más una línea en `SUITES`.
`check_suite.gd` tiene las funciones auxiliares compartidas:

| Función auxiliar | Qué hace |
|---|---|
| `_teleport(position)` | Coloca al jugador en un punto, detenido, y espera unos ticks |
| `_run_until_arrived(target, max_time)` | Ordena una carrera y registra el tiempo, las velocidades, la distancia recorrida y los ticks atascado hasta la llegada |
| `_check_route(title, from, to, max_time)` | Un recorrido: llegó a tiempo sin atascarse y, para un punto alcanzable, exactamente en él, en el piso correcto |
| `_ticks(count)`, `_frames(count)`, `_wait_until(condition, max_ticks)` | Esperar |
| `_send_key()`, `_send_button()`, `_send_motion()` | Eventos de entrada reales |
| `_expect(condition, what)` | Cuenta una comprobación como pasada o fallida y la imprime |
| `_median()`, `_min()`, `_max()`, `_first_time_at_most()` | Estadísticas sobre los valores registrados |

En los scripts de prueba, no uses como tipos las clases que acceden al autoload `Settings` (los controles de la
ventana de configuración). Los scripts de prueba se compilan antes de que existan los nombres de los autoloads, así
que una clase así no compila y rompe todo el juego en esa ejecución. Obtén el nodo de configuración con
`_tree.root.get_node(^"Settings")` y usa duck typing.

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
