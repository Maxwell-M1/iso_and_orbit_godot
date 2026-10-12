<!-- translation of docs/en/testing.md @ cce377f8600d -->
# Pruebas

[← Índice de documentación](index.md)

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

Puedes usar la ruta completa al ejecutable sin añadirlo a PATH. En PowerShell, una ruta entre comillas necesita `&`:

```powershell
& 'C:\path\to\Godot_console.exe' --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Sustituye la ruta de ejemplo por la de tu Godot 4.7.2 de consola y ejecuta desde la raíz de este proyecto.

Solo algunas suites, por ejemplo mientras trabajas en la cámara: partes de sus nombres después de `--`.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

El código de salida es 1 si falla alguna comprobación. Al final, el ejecutor imprime cuántas comprobaciones pasaron y
cuántas fallaron en cada suite.

## Suites

Las suites se ejecutan en el orden indicado en `tests/run_checks.gd` y comparten una escena principal. Elige las
relacionadas con tu cambio; ejecuta todas antes de integrar cambios que afecten a varios sistemas.

| Suite | Qué cubre |
|---|---|
| `movement_checks.gd` | Aceleración y parada exacta, un clic nuevo durante el frenado, un giro durante el frenado, una inversión a toda velocidad. Recorridos: alrededor de la trampa, por el hueco del muro, el laberinto, subir y bajar la rampa, a la plataforma desde los lados de la rampa, un punto inalcanzable sobre una caja. La protección de bordes, y la caída sin ella |
| `world_checks.gd` | Navegación por el terreno de la demo, áreas de descubrimiento, colisiones con los personajes de los lugares y los modelos expuestos de los aspectos del héroe |
| `hero_look_checks.gd` | El modelo del jugador: el bastón en la mano derecha al girar; cadenas de silueta separadas para el cuerpo y el equipo, también en mallas agregadas después; la opción del contorno. El balanceo de la mano: quieta al estar parado; balanceándose y bajando al correr, con los extremos en los pasos, alternando; retrasándose al acelerar; volviendo tras una parada; bajando al aterrizar. El aspecto del héroe: el predeterminado al iniciar; cada uno de los diez aplicado en tiempo de ejecución con un solo modelo, el bastón balanceándose en la nueva mano y la silueta en las nuevas mallas |
| `character_actions_checks.gd` | Sprint y fatiga, modos mantener y alternar, reasignación y liberación de modificadores, búfer y tiempo de gracia del salto, sustituciones de caída, señales y sonidos |
| `character_state_checks.gd` | Advertencias de configuración, estado y datos para animación, escaleras y pendientes, teletransporte, flotación, interpolación, tiempo detenido y panel de estado |
| `input_checks.gd` | Clic frente a pulsación sostenida, orden de los dos botones, ambos modos de pulsación, modos de teclas, captura del cursor, cancelación y acciones ausentes |
| `camera_checks.gd` | Órbita, zoom y seguimiento a distintas frecuencias de fotogramas y ticks, giros bruscos, carreras hacia la cámara, espera tras una órbita manual, clics que no interrumpen el seguimiento, alineación de inclinación, zoom y altura, y teletransporte |
| `camera_arm_checks.gd` | Espacio libre ante obstáculos, capas de colisión, grupos ignorados, acercamiento opcional al ocultarse el objetivo y transparencia de proximidad |
| `settings_window_checks.gd` | Pausa y foco, pestañas de ajustes, aplicación a propiedades, controles dependientes, escala de interfaz, restablecimiento y cierre |
| `localization_checks.gd` | Cobertura de traducciones, marcas de acción conservadas, cambio de idioma, nombres para las 12 acciones reasignadas, descripciones, ventanas y consejos de carga visibles, y herencia de traducción |
| `level_checks.gd` | Puntos de aparición, invitaciones a viajar, progreso y pausa de la carga, cambio de escena, estado conservado del héroe y recuperación tras fallos |
| `patrol_checks.gd` | La ronda del caballero por la línea dibujada para su recorrido, pasando por cada uno de sus puntos, girando con suavidad, la espera en el punto de partida y la ronda siguiente; la parada ante el héroe y la frase tras 2.5 s; una patrulla que solo detiene un personaje delante, a un metro y un poco a los lados; el explorador de la isla y sus paradas; recorridos a partir de curvas giradas y cerradas y desde un script; los puntos de un recorrido sobre la línea dibujada con un Bake Interval largo y uno corto, las paradas en sus puntos de control; referencias que faltan |
| `editor_authoring_checks.gd` | Un recurso de ajustes de movimiento compartido por varios componentes de movimiento y sustituido durante la partida; la ruta del archivo de configuración y los ajustes guardados por encima de los valores de la escena, y los valores de la escena conservados con `use_saved_settings` desactivado; el nivel inicial; las advertencias de configuración; objetos enteros (mover, `dimensions` y su 0, una raíz escalada, Surface Material, partes agregadas, un modelo, una parte animada); el interruptor de la excepción de la cámara con su ángulo |

Las suites nuevas también cubren sustituciones de caída y señales de escalones, flotación, teletransporte,
interpolación y tiempo detenido del personaje; orden de los dos botones y cancelación de entrada; alineación de
inclinación, zoom y altura de cámara, y espera tras una órbita; y traducciones de las 12 acciones reasignadas,
descripciones y consejos visibles. Las pruebas de niveles abarcan tanto éxito como fallos de carga.

Para las configuraciones documentadas de entrada y cámara, empieza por `movement`, `character_actions`, `input`,
`camera` y `settings_window`. El filtro `camera` selecciona las dos suites de cámara. Al copiar el héroe a otro
proyecto, sigue también la [lista de transferencia](integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto):
que pasen las pruebas de este repositorio no demuestra que hayas copiado todos los archivos y ajustes necesarios.

## Cómo se comportan las pruebas

- Se ejecutan con la configuración por defecto y nunca tocan la del jugador: la configuración se restablece a los
  valores por defecto durante la ejecución y nunca se guarda, y la única comprobación que lee un archivo de
  configuración escribe el suyo propio en `.godot/` y lo elimina.
- Los personajes que patrullan se quedan quietos en todas las suites salvo `patrol_checks.gd`, que los pone en marcha
  por sí misma: un caballero caminando estorbaría a otras comprobaciones.
- Cada comprobación restaura sus cambios. Las suites comparten una escena principal, mientras una ejecutada sola
  recibe una nueva; una prueba debe pasar de ambas formas. Tras cada comprobación, `Engine.time_scale` vuelve a 1
  para que un fallo con el tiempo ralentizado o detenido no afecte a las demás.
- Cualquier error o advertencia del motor o de un script hace fallar la ejecución: un `Logger` agregado con
  `OS.add_logger()` los cuenta, y el ejecutor imprime el total como "engine and script errors" y lo suma a los
  fallos. Una comprobación interrumpida por un error queda incompleta, pero las demás continúan, y sin el contador
  ese error pasaría inadvertido. Solo se exceptúa un error provocado y anunciado por la propia prueba:
  `expect_error()` antes y `take_expected_errors()` para comprobar que llegó, como en una escena que no puede ser
  nivel. Con mucha carga de CPU, Jolt puede agregar una advertencia propia; consulta
  [Problemas conocidos](known-issues.md#pruebas).
- Una ejecución colgada falla tras 1200 s de tiempo de juego. Durante la carga de niveles en segundo plano,
  los fotogramas sin ventana pasan mucho más rápido que en pantalla; las pruebas de nivel esperan con tiempo real.
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

## Comprobaciones en el editor

`tests/run_checks.gd` ejecuta el juego; la parte de los componentes para el editor solo se ejecuta en el editor, y
tiene sus propias comprobaciones: abre `tests/editor_tool_checks.tscn` en el editor y pulsa **Run Checks** en el
Inspector. Cubren lo que el juego no puede mostrar: que una advertencia se actualiza mientras se edita una escena (un
nodo dependiente, un recurso, un componente de movimiento agregado al cuerpo de una patrulla o quitado de él), que la
cámara, los objetos, los personajes que patrullan y el letrero de un portal muestran sus vistas previas en el editor
mientras una escena guardada conserva lo establecido, que un objeto heredado sigue a su base, que las acciones de
entrada del proyecto cuentan en el editor, donde el mapa de entrada solo contiene las del propio editor, que los
interruptores del juego (flotación, una patrulla) no cambian nada en el editor, que un personaje que patrulla copiado
muestra un solo modelo, y que un brazo de cámara cuyo script extiende `CameraArm` sin `@tool` sigue mostrando la
vista inicial. **Status** y **Results** en el Inspector muestran el resultado y no se guardan con la escena;
`.godot/editor_tool_checks/results.json` también lo contiene, y la salida recibe la línea de estado. Las
comprobaciones escriben sus escenas solo en `.godot/editor_tool_checks/`, que se vacía en cada ejecución.

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
| `_error_count()` | Número de errores de motor y script recibidos, salvo los esperados; una prueba compara el valor antes y después |
| `_tree.call(&"expect_error", "part of the message")`, `_tree.call(&"take_expected_errors")` | Métodos del ejecutor, no de `check_suite.gd`: anuncian un error esperado y devuelven los anunciados que no llegaron |
| `_find_non_finite(found)` | Recoge nodos 3D de la escena principal cuya transformación no es finita (INF o NaN) |
| `_same_values(a, b)` | Compara dos matrices de valores; a diferencia de `==`, no considera iguales dos NaN |
| `_median()`, `_min()`, `_max()`, `_first_time_at_most()` | Estadísticas sobre los valores registrados |

En los scripts de prueba, no uses como tipos las clases que acceden al autoload `Settings` (los controles de la
ventana de configuración). Los scripts de prueba se compilan antes de que existan los nombres de los autoloads, así
que una clase así no compila y rompe todo el juego en esa ejecución. Obtén el nodo de configuración con
`_tree.root.get_node(^"Settings")` y usa duck typing.

---

*Esta página corresponde a Iso & Orbit 1.3.0.*
