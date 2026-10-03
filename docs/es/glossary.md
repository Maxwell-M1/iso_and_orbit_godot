<!-- translation of docs/en/glossary.md @ c34a86f53e66 -->
# Glosario

> Esta es una traducción del [original en inglés](../en/glossary.md).
> Si hay diferencias, la versión en inglés es la correcta.

Términos tal como los usan esta documentación y el código.

| Término | Significado |
|---|---|
| **Radio del agente** (agent radius) | Cuánto se aleja la malla de navegación de los obstáculos: 0,5 m, más que la cápsula de 0,35 m del personaje, así que las rutas dejan un margen respecto a las esquinas |
| **Brazo** (arm) | `CameraArm`: el nodo que sostiene la cámara en el extremo de una línea que sale del objetivo. La rueda fija su longitud; los obstáculos la acortan |
| **Cuerpo solo para la cámara** (camera-only body) | Un cuerpo en la capa de física 3 (`camera`): detiene el brazo de la cámara, pero los clics, la navegación y los personajes lo ignoran |
| **Clic** (click) | Una pulsación del botón izquierdo que se suelta dentro del retardo de pulsación. El personaje corre por una ruta hasta el punto donde se presionó el botón |
| **Tiempo de coyote** (coyote time) | Un breve lapso después de salir caminando de un borde en el que el salto todavía funciona (0,1 s) |
| **Agotado** (exhausted) | El estado después de que se acaba la resistencia: no hay sprint hasta que la resistencia se recupere hasta `recover_ratio` (30%) |
| **Orientación** (facing) | Hacia dónde mira el personaje, a diferencia de hacia dónde se mueve. Difieren al desplazarse de costado o retroceder. `NavigationMover.get_facing()` |
| **Seguimiento** (follow) | La cámara que gira sola tras el personaje que corre y, opcionalmente, ajusta suavemente su inclinación (`follow_movement`, `follow_pitch`) |
| **Rumbo** (heading) | La dirección en la que se mueve el personaje. `NavigationMover.get_heading()` |
| **Aspecto del héroe** (hero look) | Uno de los diez modelos que puede llevar el personaje del jugador, elegido por número en la configuración (`CharacterAppearance`) |
| **Pulsación mantenida** (hold) | El botón izquierdo mantenido más tiempo que el retardo de pulsación. El personaje corre tras el cursor |
| **Retardo de pulsación** (hold delay) | El tiempo que distingue un clic de una pulsación mantenida: 0,2 s (`PointClickMoveInput.hold_delay`) |
| **Búfer de salto** (jump buffer) | Un salto presionado poco antes de aterrizar se recuerda y se ejecuta al aterrizar (0,12 s) |
| **Mantener la mira** (keeping the aim) | Mover el cursor del sistema junto con el mundo mientras se mantiene el botón y la cámara gira, para que el cursor se quede sobre el mismo punto del suelo (`keep_aim_on_camera_turn`) |
| **Protección de bordes** (ledge guard) | `LedgeGuard`: detiene al personaje ante un desnivel de más de 0,5 m o lo desliza a lo largo del borde |
| **Aspecto** (look) | Ver aspecto del héroe |
| **Marcador** (marker) | `ClickMarker`: el anillo en el suelo en el punto del clic |
| **Movedor** (mover) | `NavigationMover`: convierte las órdenes (`move_to`, `steer`, `stop`) en una velocidad horizontal en cada tick. Nunca mueve el cuerpo |
| **Malla de navegación** (navigation mesh) | La zona transitable horneada a partir de las colisiones del nivel en la capa 1, guardada en `world.tscn`. Las rutas se buscan sobre ella |
| **Interpolación de física** (physics interpolation) | Dibujar los cuerpos entre ticks de física a la tasa de fotogramas de la pantalla. Desactivada por defecto; una opción la activa |
| **Inclinación** (pitch, tilt) | Cuán empinada mira la cámara hacia abajo. Ángulos negativos en el código, grados hacia abajo en la configuración |
| **Pivote** (pivot) | Girar al instante desde parado, por debajo de `pivot_speed` (1 m/s) |
| **Lugar** (place) | Un `PointOfInterest`: un área que muestra "Lugar descubierto: …" la primera vez que el jugador entra en ella |
| **Acercamiento** (pull-in) | La cámara que se coloca delante de un obstáculo que oculta al personaje (`pull_in_on_occlusion`) |
| **Lateral** (sidestep) | Un modo de las teclas con el botón derecho: el personaje sigue mirando hacia donde mira la cámara mientras se mueve de costado o hacia atrás |
| **Silueta** (silhouette) | El personaje dibujado como una forma plana con contorno donde algo lo oculta (`OccludedSilhouette`) |
| **Sprint** (sprint) | Correr más rápido (×1,5) mientras Shift está mantenido o activado, gastando resistencia |
| **Resistencia** (stamina) | La reserva para el sprint (`Stamina`): se gasta al esprintar y se recupera tras una pausa |
| **Dirigir** (steer) | Correr en una dirección sin ruta: `NavigationMover.steer()`. Mantener el botón dirige hacia el cursor por defecto |
| **Tick** (tick) | Un paso de física; 60 por segundo |
| **Modo giro** (turn mode) | Un modo de las teclas con el botón derecho: el personaje gira para mirar hacia donde va |
| **Guiñada** (yaw) | La dirección de la cámara alrededor del eje vertical |
| **Zoom** (zoom) | Un valor de 0 (lo más cerca) a 1 (lo más lejos) que fija a la vez la distancia y la inclinación de la cámara |

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
