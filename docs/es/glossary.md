<!-- translation of docs/en/glossary.md @ 2c04d3857e30 -->
# Glosario

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/glossary.md).
> Si hay diferencias, la versión en inglés es la correcta.

Términos tal como los usan esta documentación y el código.

| Término | Significado |
|---|---|
| **Radio del agente** (agent radius) | Cuánto se aleja la malla de navegación de los obstáculos: 0,5 m, más que la cápsula de 0,35 m del personaje, así que las rutas dejan un margen respecto a las esquinas |
| **Brazo** (arm) | `CameraArm`: el nodo que sostiene la cámara en el extremo de una línea que sale del objetivo. La rueda fija su longitud; los obstáculos la acortan |
| **Mezcla** (blend) | `GroundCharacter.get_locomotion_blend()`: la velocidad como un número para las animaciones, 0 quieto, 1 corriendo, 2 en sprint |
| **Límites** (bounds) | Capa de física 4: paredes invisibles en el borde del nivel. Los personajes colisionan con ellas; los clics y el brazo de cámara las atraviesan |
| **Cuerpo solo para la cámara** (camera-only body) | Un cuerpo en la capa de física 3 (`camera`): detiene el brazo de la cámara, pero los clics, la navegación y los personajes lo ignoran |
| **Estado del personaje** (character state) | Lo que está haciendo el personaje: estar quieto, correr, esprintar, saltar o caer (`GroundCharacter.get_state()`, la señal `state_changed`) |
| **Clic** (click) | Una pulsación del botón izquierdo que se suelta dentro del retardo de pulsación. El personaje corre por una ruta hasta el punto donde se presionó el botón |
| **Tiempo de coyote** (coyote time) | Un breve lapso después de salir caminando de un borde en el que el salto todavía funciona (0,1 s) |
| **Agotado** (exhausted) | El estado después de que se acaba la resistencia: no hay sprint hasta que la resistencia se recupere hasta `recover_ratio` (30%) |
| **Orientación** (facing) | Hacia dónde mira el personaje, a diferencia de hacia dónde se mueve. Difieren al desplazarse de costado o retroceder. `NavigationMover.get_facing()` |
| **Ajustes de caída** (fall settings) | Cómo desciende el personaje tras un salto o un borde: gravedad, velocidad máxima y frenado de un exceso (`FallSettings`). No modifican el ascenso |
| **Flotación** (floating) | El modelo del héroe suspendido sobre el suelo y deslizándose por escaleras mientras el cuerpo camina normalmente (`CharacterHover`). Suspende los pasos y en la demo desciende más lentamente |
| **Seguimiento** (follow) | La cámara gira sola tras la carrera y devuelve inclinación y altura a valores elegidos (`follow_movement`, `follow_pitch`, `follow_zoom`). Después de orbitar puede esperar una parada o carrera nueva (`follow_wait_after_rotate`, activado en la demo) |
| **Ciclo de la marcha** (gait cycle) | Dos pasos, el izquierdo y el derecho, como un número de 0 a 1 (`GroundCharacter.get_gait_cycle()`). Sigue la distancia recorrida, no el tiempo |
| **Rumbo** (heading) | La dirección en la que se mueve el personaje. `NavigationMover.get_heading()` |
| **Aspecto del héroe** (hero look) | Uno de los diez modelos que puede llevar el personaje del jugador, elegido por número en la configuración (`CharacterAppearance`) |
| **Pulsación mantenida** (hold) | El botón izquierdo mantenido más tiempo que el retardo de pulsación. El personaje corre tras el cursor |
| **Retardo de pulsación** (hold delay) | El tiempo que distingue un clic de una pulsación mantenida: 0,2 s (`PointClickMoveInput.hold_delay`) |
| **Búfer de salto** (jump buffer) | Un salto presionado poco antes de aterrizar se recuerda y se ejecuta al aterrizar (0,12 s) |
| **Mantener la mira** (keeping the aim) | Mover el cursor del sistema junto con el mundo mientras se mantiene el botón y la cámara gira, para que el cursor se quede sobre el mismo punto del suelo (`keep_aim_on_camera_turn`) |
| **Protección de bordes** (ledge guard) | `LedgeGuard`: detiene al personaje ante un desnivel de más de 0,5 m o lo desliza a lo largo del borde |
| **Host de niveles** (level host) | `LevelHost`: contiene el nivel actual y lo cambia tras una pantalla de carga. Héroe e interfaz son hermanos, no partes del nivel |
| **Pantalla de carga** (loading screen) | `LoadingScreen`: cubre el juego durante un cambio de nivel con el último fotograma desenfocado, nombre del lugar, barra de progreso y consejos |
| **Aspecto** (look) | Ver aspecto del héroe |
| **Mirar alrededor** (looking around) | Pulsar el derecho durante una carrera tras el cursor: el ratón solo gira la cámara y la carrera conserva el rumbo (`look_around_while_held`). Si se pulsa primero el derecho, dirige la carrera según la cámara |
| **Marcador** (marker) | `ClickMarker`: el anillo en el suelo en el punto del clic |
| **Componente de movimiento** (mover) | `NavigationMover`: convierte las órdenes (`move_to`, `steer`, `stop`) en velocidad horizontal por tick; el cuerpo realiza el desplazamiento |
| **Malla de navegación** (navigation mesh) | Zona transitable horneada desde las colisiones de la capa 1 (en la isla también las paredes invisibles de la capa 4), guardada en la escena de cada nivel. Las rutas se buscan allí |
| **Invitación a viajar** (offer to travel) | `TravelPrompt`: tecla y «Teletransporte: …» mientras el héroe está en un portal que pide confirmación. E (`interact`) o un clic viajan; alejarse la oculta |
| **Interpolación de física** (physics interpolation) | Dibujar los cuerpos entre ticks de física a la tasa de fotogramas de la pantalla. Activada por defecto; una opción la desactiva |
| **Inclinación** (pitch, tilt) | Cuán empinada mira la cámara hacia abajo. Ángulos negativos en el código, grados hacia abajo en la configuración |
| **Pivote** (pivot) | Girar al instante desde parado, por debajo de `pivot_speed` (1 m/s) |
| **Lugar** (place) | Un `PointOfInterest`: un área que muestra "Lugar descubierto: …" la primera vez que el jugador entra en ella |
| **Héroe jugable** (playable hero) | `PlayableHero` (`playable_hero.tscn`): héroe controlado por el jugador, con entrada, cámara, marcador de clic y línea de ruta, junto a los niveles |
| **Portal** (portal) | `LevelPortal`: área que conduce a otro nivel; las plataformas de teletransporte de la demo son portales |
| **Acercamiento** (pull-in) | La cámara que se coloca delante de un obstáculo que oculta al personaje (`pull_in_on_occlusion`) |
| **Giro brusco** (sharp turn) | Giro de carrera más rápido que `OrbitCameraRig.sharp_turn_speed` (360°/s), como un cambio de sentido: la cámara omite las direcciones intermedias y adopta la nueva al terminar |
| **Escena principal** (shell) | Escena que permanece durante la partida (`main.tscn` con `main.gd`): host de niveles, héroe, interfaz y pantalla de carga |
| **Lateral** (sidestep) | Un modo de las teclas con el botón derecho: el personaje sigue mirando hacia donde mira la cámara mientras se mueve de costado o hacia atrás |
| **Silueta** (silhouette) | El personaje dibujado como una forma plana con contorno donde algo lo oculta (`OccludedSilhouette`) |
| **Punto de aparición** (spawn point) | `SpawnPoint`: lugar con nombre donde aparece el personaje. Cada nivel tiene uno `default` |
| **Sprint** (sprint) | Correr más rápido (×1,5) mientras Shift está mantenido o activado, gastando resistencia |
| **Altura de escalón** (stair height) | El escalón más alto al que el personaje sube sin saltar: 0,3 m (`GroundCharacter.max_step_height`) |
| **Resistencia** (stamina) | La reserva para el sprint (`Stamina`): se gasta al esprintar y se recupera tras una pausa |
| **Nivel inicial** (start level) | Nivel colocado en el host desde el editor: `shared/world/world.tscn`, claro cercado o prado. Dentro del juego se llama Valle Verde, título de la plataforma de la isla |
| **Dirigir** (steer) | Correr en una dirección sin ruta: `NavigationMover.steer()`. Mantener el botón dirige hacia el cursor por defecto |
| **Teletransporte** (teleport) | Colocar al personaje de inmediato en otro lugar, sin carrera ni sacudida: `GroundCharacter.teleport()`, `PlayableHero.teleport()` |
| **Tick** (tick) | Un paso de física; 60 por segundo |
| **Viajero** (traveller) | Cuerpo que puede usar un portal: pertenece al grupo `traveller_group` del portal (`player` por defecto) |
| **Modo giro** (turn mode) | Un modo de las teclas con el botón derecho: el personaje gira para mirar hacia donde va |
| **Calentamiento** (warm-up) | Fotogramas que dibuja el host tras la pantalla de carga antes de retirarla, para compilar shaders y asentar al personaje (`LevelHost.warmup_frames`, 3) |
| **Guiñada** (yaw) | La dirección de la cámara alrededor del eje vertical |
| **Zoom** (zoom) | Un valor de 0 (lo más cerca) a 1 (lo más lejos) que fija a la vez la distancia y la inclinación de la cámara |

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
