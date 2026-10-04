<!-- translation of docs/en/known-issues.md @ 958e422b4a78 -->
# Problemas conocidos

> Esta es una traducción del [original en inglés](../en/known-issues.md).
> Si hay diferencias, la versión en inglés es la correcta.

Limitaciones del proyecto y peculiaridades del motor que sortea. Cada entrada dice qué ves y qué hacer.

## Limitaciones

- **Solo mouse y teclado.** No hay soporte para gamepad.
- **Sin animaciones.** Los modelos son primitivas estáticas; solo el objeto en la mano se balancea con los pasos
  (`HandSway`). `NavigationMover.get_speed()` y `GroundCharacter.get_step_phase()` están ahí para controlar un
  `AnimationTree`.
- **Sin evasión entre personajes.** `NavigationMover` sigue una ruta y no usa la evasión de navegación, así que los
  personajes en movimiento no se esquivan entre sí. El cuerpo del jugador está en la capa 2 y solo colisiona con la
  capa 1, así que dos personajes creados a partir de `player.tscn` se atraviesan; agrega la capa 2 a su
  `collision_mask` si deben bloquearse entre sí. Los NPC de la demo están quietos y están horneados en la malla de
  navegación como obstáculos.
- **La malla de navegación se hornea de antemano.** Mover un obstáculo en tiempo de ejecución no cambia las rutas.
  Después de editar el nivel, vuelve a hornear la malla
  ([Mundo y navegación](systems/world-and-navigation.md#volver-a-hornear-la-malla-de-navegación)).
- **Solo Godot 4.7.** El proyecto está probado en 4.7.2. La silueta necesita el búfer de stencil (4.5+), y la
  comprobación de advertencias de escena repite las condiciones de 4.7.2.

## Entrada

- **Un clic actúa al soltar.** Una pulsación se convierte en clic o en pulsación mantenida solo después de 0,2 s
  (`hold_delay`) o al soltar, así que un clic llega unos 0,1 s más tarde que si actuara al presionar. Es
  intencional: de lo contrario, una pulsación mantenida mandaría primero al héroe por una ruta hasta el punto
  presionado. Ver [Entrada](systems/input.md#clic-o-mantener).
- **El cursor puede no mantener la mira en algunos sistemas.** Mantener la mira mientras la cámara gira mueve el
  cursor del sistema (`Viewport.warp_mouse()`). Donde el sistema no lo permite (Wayland, por ejemplo), la dirección
  de carrera se mantiene, pero el cursor se queda donde estaba en la pantalla.
- **"Al punto por una ruta" puede cambiar de recorrido.** En este modo de pulsación mantenida la ruta se reconstruye
  a medida que se mueve el punto bajo el cursor, y cerca de los cambios de altura (la rampa, la plataforma) puede
  saltar de un recorrido a otro. El modo por defecto, directo al cursor, no tiene ese problema.
- **Shift puede quedarse pegado cuando el juego se ejecuta dentro del editor.** Cuando el juego está incrustado en la
  pestaña Juego (Game) del editor y el foco pasa al editor, el motor no restablece las teclas presionadas.
  `CharacterActionInput` libera un sprint atascado en el siguiente evento de mouse o teclado, siempre que la acción
  de sprint esté asignada a teclas modificadoras. Si se activan las teclas especiales (Sticky Keys) de Windows (cinco
  pulsaciones de Shift seguidas), Shift se queda pegado en el propio sistema; desactiva las teclas especiales en la
  configuración de Windows. Ver [Entrada](systems/input.md#shift-no-se-queda-pegado).

## Cámara

- **Un cuerpo justo detrás de un obstáculo.** Jolt no informa los cuerpos que un shape cast toca en su inicio.
  Cuando otro cuerpo está justo detrás del obstáculo en el que está la cámara (una cerca con un acantilado detrás),
  el brazo busca en su lugar espacio libre más cerca del objetivo. Ver
  [Cámara](systems/camera.md#cómo-distingue-el-brazo-el-espacio-detrás-de-un-obstáculo-de-estar-dentro-de-un-cuerpo).
- **Saltos en el movimiento sin interpolación de física.** La interpolación de física está activada por defecto. Si la
  desactivas (Configuración → Pantalla), el personaje y la cámara se mueven tick a tick, 60 veces por segundo: en un
  monitor rápido se ve irregular, y con la cámara siguiendo la carrera el personaje se tambalea en los giros.

## Pruebas

- **Una rara advertencia de Jolt hace fallar una ejecución.** Con mucha carga de CPU, por ejemplo en la primera
  ejecución justo después de una importación nueva, Jolt Physics puede imprimir "Jolt Physics job system exceeded
  the maximum number of jobs. This should not happen." El ejecutor de pruebas cuenta cada advertencia y cada error
  del motor como un fallo, así que la ejecución termina con el código de salida 1 y "engine and script errors: 1"
  aunque todas las comprobaciones hayan pasado. La advertencia viene del sistema de trabajos de física del motor, no
  del proyecto: vuelve a ejecutar las pruebas en una máquina que no esté ocupada.

## Renderizado

- **La silueta usa una función experimental del motor.** El búfer de stencil es experimental en Godot 4.5+ y solo
  se puede leer en una pasada transparente. Si una versión futura del motor lo cambia, la silueta es el lugar donde
  mirar.
- **La proyección está invertida en Y en Godot 4.7** (D3D12 y Vulkan): `PROJECTION_MATRIX[1][1]` es negativo en los
  shaders. El borde de la silueta toma su `abs()`; sin eso, la malla del borde se encoge y el borde desaparece.

## Archivos del proyecto

- **Las rotaciones redondeadas generan advertencias de "escala no uniforme".** Una rotación escrita en un `.tscn`
  con 4 dígitos hace que las longitudes de los ejes de la base difieran en más de 1e-5, y el motor informa una escala
  no uniforme en cuerpos y formas. Escribe los números de `Transform3D` con precisión completa (9 dígitos
  significativos).
- **`shared/` todavía no es del todo neutral respecto al lenguaje.** `world.tscn` y `mountain.tscn` usan
  `addons/iso_orbit/points_of_interest/point_of_interest.gd`, y dos pequeños scripts de props viven en
  `shared/world/props/`. Una versión en C# necesitaría su propio script de lugares o una forma de marcar lugares
  solo con la escena.
- **Fugas de recursos informadas al salir.** Si un script sale justo después de que suenen pasos, el motor puede
  informar fugas de objetos `AudioStreamPlayback`: con `--fixed-fps` el tiempo de juego va por delante del tiempo
  real mientras los sonidos todavía suenan. Libera la escena y espera un momento antes de salir;
  `tests/run_checks.gd` espera 0,1 s.

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
