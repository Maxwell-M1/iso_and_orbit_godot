<!-- translation of docs/en/integration.md @ 502ddfce7182 -->
# Uso en tu proyecto

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/integration.md).
> Si hay diferencias, la versión en inglés es la correcta.

Si quieres usar el movimiento y la cámara de la demo en otro proyecto, empieza por el héroe ya preparado. Si ya
tienes un controlador de personaje o solo necesitas la cámara, usa los componentes por separado. Los scripts son
clases GDScript normales (`class_name`): no hay que activar un plugin del editor ni registrar el autoload `Settings`.

| Lo que necesitas | Por dónde empezar |
|---|---|
| El héroe, sus controles y la cámara | [Transferir el héroe de la demo](#transferir-el-héroe-de-la-demo-a-tu-proyecto) y luego [elegir una configuración](configurations.md) |
| Una cámara para un personaje existente | [La cámara sola](#la-cámara-sola) |
| El movimiento del proyecto con tu propio modelo | [El cuerpo preparado](#movimiento-por-clic-con-el-cuerpo-preparado) y luego [cambiar el modelo](systems/characters.md) |
| Movimiento por rutas para tu controlador o una IA | [Tu propio cuerpo](#tu-propio-cuerpo) y [dar órdenes al componente de movimiento](#dar-órdenes-al-componente-de-movimiento) |

Las rutas siguientes son relativas a la raíz del proyecto, donde está `project.godot`. Una ruta `res://` señala ese
mismo lugar dentro de Godot. Conserva la estructura de carpetas suministrada durante la primera integración.

## Los addons

| Addon | Clases | Necesita |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | Las acciones de entrada `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`; capas de física para el brazo |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | Un `NavigationRegion3D` horneado en el mundo (sin él, el personaje corre en línea recta hacia el punto). Para la entrada: cualquier `Camera3D` y las acciones `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` |
| `ground_character` | `GroundCharacter`, `FallSettings`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterHover`, `DampedSpring`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. Para las teclas: las acciones `sprint` y `jump`. Para los sonidos: los tuyos o `shared/audio/character/`. Para el balanceo de la mano y los modelos intercambiables: modelos orientados hacia −Z con un nodo de mano |
| `occluded_silhouette` | `OccludedSilhouette`, con sus shaders y materiales | Nada: funciona con cualquier modelo |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | El cuerpo del jugador en el grupo `player`, en una capa de física que vean las áreas |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter`, `InputNames`, `ActionTexts` | La acción integrada `ui_cancel`; la acción `toggle_settings` si `UiRoot` abre una ventana mediante una tecla. Los nombres de teclas se obtienen del mapa de entrada |
| `levels` | `LevelHost`, `LevelPortal`, `SpawnPoint`, `LoadingScreen` | Solo el motor. El cuerpo del viajero en el grupo `player`, en una capa de física que detecten los portales |

Cada carpeta de addon tiene un `README.md` con su configuración y una copia de la `LICENSE`. Toma un addon entero:
las clases que contiene se referencian entre sí por tipo, y un archivo que no uses no hace daño. Mantén las carpetas
en `res://addons/iso_orbit/<addon>/`: las escenas y los materiales que contienen se refieren a sus archivos por esas
rutas. Para poner un addon en otro lugar, muévelo en el panel Sistema de Archivos (FileSystem) del editor, que
actualiza las referencias.

Los widgets del HUD (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) toman su aspecto de variaciones de tipo del tema
con los mismos nombres en el tema de la demo, `shared/ui/ui_theme.tres`; sin ellas usan el tema por defecto.

No forman parte de los addons porque están hechos para esta demo: el sistema de ajustes
(`gdscript/settings/game_settings.gd` y la ventana de `gdscript/ui/settings/`; consulta
[Ajustes](#ajustes)), `gdscript/ui/ui_root.tscn` (un `UiRoot` preparado con esa ventana), el héroe jugable
(`gdscript/player/playable_hero.tscn`, construido alrededor del personaje de la demo; consulta
[El héroe jugable](#el-héroe-jugable)), la invitación a viajar (`gdscript/ui/travel_prompt.tscn`), la estructura
principal `gdscript/main.gd` y el código de unión `gdscript/demo/hud.gd` y `settings_applier.gd`.

## La cámara sola

La cámara funciona con cualquier objetivo `Node3D` y solo necesita `addons/iso_orbit/orbit_camera/`.

1. Agrega a la escena un `Node3D` con `orbit_camera_rig.gd` junto al objetivo, no dentro de él.
2. Dale un hijo `Node3D` con `camera_arm.gd`, y a este, un hijo `Camera3D`.
3. Asigna el cuerpo móvil a `target` del rig y el nodo del brazo a `arm`. Activa **Current** en la cámara. Asigna
   a `fade_target` del brazo la raíz del modelo que debe volverse translúcido de cerca, o déjalo vacío.
4. Agrega las acciones de entrada y, para el brazo, las capas de física de
   [Preparación del proyecto](project-setup.md).

Mantén la escala del rig, el brazo, la cámara y sus ancestros en `(1, 1, 1)`. Deja la transformación local de la
cámara en su valor predeterminado: el brazo la establece durante la ejecución. Ajusta el encuadre mediante las
propiedades, no mediante la escala de los nodos.

Sin brazo también funciona un `Camera3D` hijo del rig: entonces la cámara permanece a la distancia fijada por el
zoom y atraviesa las paredes. El rig se actualiza en `_process` a partir de la posición interpolada del objetivo;
si el objetivo se mueve en los ticks de física, activa la interpolación de física en el proyecto. Más información:
[Cámara](systems/camera.md).

## Movimiento por clic con el cuerpo preparado

Copia `addons/iso_orbit/click_to_move/` y `addons/iso_orbit/ground_character/`.

1. Hornea una malla de navegación para tu nivel (`NavigationRegion3D` → **Bakear NavigationMesh**, en inglés
   **Bake NavigationMesh**). Su radio de agente y su escalada máxima deben corresponder a tu personaje, ver
   [Mundo y navegación](systems/world-and-navigation.md).
2. Crea un `CharacterBody3D` con `ground_character.gd`: una forma de colisión, un nodo `Visual` con el modelo
   (orientado hacia −Z) y estos hijos: `NavigationMover` (un `Node` con `navigation_mover.gd`) y, opcionalmente,
   `LedgeGuard` y `Stamina`. Establece `mover`, `visual`, `ledge_guard` y `stamina` del cuerpo.
3. Dale al componente de movimiento un recurso `LocomotionSettings`, o déjalo vacío para usar los valores por defecto.
4. Agrega un `Node` con `point_click_move_input.gd` en cualquier lugar de la escena y establece su `mover` y su
   `camera`.
5. Opcionalmente, agrega `character_action_input.gd` con `character` apuntando al cuerpo, para el sprint y el salto.

`gdscript/player/player.tscn` contiene esta configuración, además de sonidos, balanceo de la mano, flotación
(`Visual/Hover`, desactivada, con una caída más lenta), modelo intercambiable y silueta. Puedes instanciarla y
eliminar lo que no necesites. Los errores de configuración de `GroundCharacter`, `LedgeGuard` y `CharacterHover`
aparecen como advertencias al iniciar el juego.

## El héroe jugable

`gdscript/player/playable_hero.tscn` es el héroe controlado por el jugador y ya está montado: `player.tscn` como
`Character` (en el grupo `player`), `PointClickMoveInput`, `CharacterActionInput`, el rig de cámara con su brazo y
cámara, el marcador de clic y la línea de ruta, con sus ajustes y conexiones. Colócalo una vez en tu escena de
juego, junto a los niveles y no dentro de uno de ellos. Su script, `playable_hero.gd`, solo utiliza clases de los
addons:

- `place_at(marker)` y `teleport(position, facing)` colocan al héroe de inmediato en otro lugar: se descarta la
  pulsación en curso, el personaje llega sin sacudidas (`GroundCharacter.teleport()`), la cámara mira hacia donde
  apunta el héroe y se coloca en su sitio. Con `turn_camera` en false, la cámara conserva su ángulo, como al
  iniciar la demo.
- `controls_enabled = false` desactiva la entrada de movimiento, el sprint y el salto. Se puede seguir controlando
  la cámara y continúa una carrera hacia un destino ya marcado por clic. Llama también a
  `character.mover.stop()` para frenar, o a `halt()` para detener al instante el movimiento horizontal. Pausar el
  árbol de escenas es una operación distinta.
- Las partes son propiedades tipadas: `character`, `input`, `actions`, `camera_rig`, `camera_arm`, `camera`,
  `click_marker`, `path_view` y, en el personaje, `sounds`, `appearance`, `hover`, `silhouette`.

Para usar tu propio modelo, haz una copia de la escena y sustituye `player.tscn` por tu personaje, o monta las partes
a mano. Dos conexiones son esenciales para la cámara: `PointClickMoveInput.hold_pending_changed` con
`OrbitCameraRig.set_follow_paused`, y `PointClickMoveInput.run_requested` con `OrbitCameraRig.end_follow_wait` (tras
orbitar, la cámara espera a que empiece una carrera nueva). Las otras cuatro muestran y ocultan el marcador de
clic; consulta [Arquitectura](architecture.md#conexiones-hechas-en-la-escena). Mantén `sharp_turn_speed` de la
cámara como máximo en la mitad de la velocidad de giro del personaje: solo `PlayableHero` lo comprueba y advierte.

## Transferir el héroe de la demo a tu proyecto

Usa Godot 4.7.2 con Jolt Physics y Forward+ para reproducir la configuración probada de la demo. Empieza por un
nivel de prueba pequeño; agrega tus modelos, niveles y ajustes cuando el héroe copiado ya funcione allí.

1. **Copia los archivos conservando sus rutas.** Lleva a tu proyecto estas carpetas tal como están:
   - `addons/iso_orbit/click_to_move/`, `ground_character/`, `orbit_camera/` y `occluded_silhouette/`;
   - `gdscript/player/`: el héroe, el personaje, el script del héroe y los recursos de ajustes del personaje;
   - `shared/characters/`: los diez modelos, sus bastones y libros, y sus materiales;
   - `shared/audio/character/`: pasos, salto, aterrizaje y sprint;
   - `shared/world/materials/wood.tres` y `dark_wood.tres`: las partes de madera del druida y el mago de batalla
     usan esos materiales. Están con los materiales del mundo; copiar solo `shared/characters/` no los incluye.

   Copia también los archivos `.uid` y `.import` contiguos: las escenas encuentran scripts y sonidos por sus
   identificadores y rutas. No copies `.godot/`: tu editor importará los archivos. Como las escenas se refieren a
   ellos por estas rutas, si quieres otra ubicación, cópialos primero y después muévelos desde el panel Sistema de
   archivos del editor para actualizar las referencias.
2. **Prepara el proyecto** en Ajustes del proyecto; consulta [Preparación del proyecto](project-setup.md):
   - las acciones `move_to_cursor`, `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`, `move_forward`,
     `move_back`, `move_left`, `move_right`, `sprint` y `jump`. Si falta alguna, el componente que la utiliza
     avisa una vez al inicio y esa tecla o botón no hace nada;
   - `navigation/3d/default_cell_height` = 0.025 para coincidir con la malla del paso siguiente. El mapa y todas
     las mallas asignadas deben tener tamaños de celda compatibles;
   - activa la interpolación de física (`physics/common/physics_interpolation`): la cámara sigue la posición
     interpolada del personaje. El héroe se probó con Jolt Physics (`physics/3d/physics_engine`);
   - las capas de física: el cuerpo del héroe está en la capa 2 y colisiona con las capas 1 y 4; un clic busca el
     suelo en la capa 1; el brazo de cámara se detiene ante las capas 1 y 3. Importan los números, no los nombres:
     coloca el suelo y las paredes en la capa 1, o cambia estas máscaras en tu copia de la escena.
3. **Construye un nivel de prueba** bajo un `NavigationRegion3D`. Crea un suelo `StaticBody3D` con `BoxShape3D` y
   un `BoxMesh` visible, ambos de 20 × 1 × 20 m, centrados en `(0, -0.5, 0)`, de modo que la cara superior quede
   en Y = 0. Añade un obstáculo cúbico de 2 × 2 × 2 m centrado en `(0, 1, -4)`, con malla y colisión en la capa 1.
   Debe bloquear la ruta directa desde Spawn `(0, 0, 4)` hasta `(0, 0, -8)`. Agrega una luz y, si quieres, un
   escalón de 3 × 0.2 × 3 m centrado en `(5, 0.1, 0)`. Una malla visible por sí sola no proporciona colisión.
4. **Crea y hornea la malla de navegación.** Selecciona la región, asígnale un `NavigationMesh` nuevo y establece:

   | Propiedad | Valor para la prueba | Motivo |
   |---|---|---|
   | Parsed Geometry Type | Static Colliders | Hornea la misma geometría que bloquea el cuerpo |
   | Geometry Collision Mask | capa 1 | Incluye suelo y obstáculo, no al héroe |
   | Agent Radius | 0.5 m | Deja espacio alrededor de la cápsula de radio 0.35 m |
   | Agent Height | 1.8 m | Al menos la altura total de la cápsula; comprueba el techo más bajo |
   | `filter_walkable_low_height_spans` | `true` | Excluye superficies con menos espacio libre que Agent Height |
   | Agent Max Climb | 0.3 m | Coincide con `Character.max_step_height` |
   | Agent Max Slope | 40° | Inferior al límite de suelo de 45° del cuerpo |
   | Cell Height / Cell Size | 0.025 m / 0.25 m | Escalones verticales finos; coincide con el mapa de navegación |

   Mantén el suelo y el obstáculo **bajo la región**, haz clic en **Bake NavigationMesh** y guarda la escena. Las
   mallas de la demo usan una altura de agente de 1.75 m y tienen desactivado el filtro de poca altura. En un nivel
   nuevo con techos, usa la altura completa de colisión y activa el filtro.
   La navegación no sustituye a la colisión física. Si no hay una ruta utilizable, el componente puede recurrir a
   avanzar directamente hacia el objetivo; así no puede rodear paredes. Consulta
   [Mundo y navegación](systems/world-and-navigation.md#capas-de-física-y-navegación).
5. **Instancia el héroe como hermano de la región** y llámalo `Hero`. Añade un `Marker3D` llamado `Spawn` en
   `(0, 0, 4)`. Conserva la escala de la raíz del héroe en `(1, 1, 1)` y la cámara como actual. Basta una escena así:

   ```text
   Game (Node3D)
   ├── NavigationRegion3D
   │   ├── Ground (StaticBody3D con colisión y malla)
   │   └── Obstacle (StaticBody3D con colisión y malla)
   ├── Hero (instancia de playable_hero.tscn)
   ├── Spawn (Marker3D)
   └── DirectionalLight3D
   ```

   Asigna este script a `Game` y ejecuta la escena:

   ```gdscript
   extends Node3D

   @onready var hero: PlayableHero = $Hero


   func _ready() -> void:
       hero.place_at($Spawn, false)
   ```

   `false` conserva el ángulo inicial de 45° de la cámara; si lo omites, la cámara queda detrás de la dirección
   −Z del marcador. Después del inicio, mueve o teletransporta **el personaje mediante la API del héroe**. La
   raíz `Hero` es un contenedor fijo: no sigue al cuerpo en movimiento. Para obtener la posición actual del
   jugador, usa `hero.character.global_position`.
6. **Comprueba el resultado antes de personalizarlo.** Haz clic en el suelo cerca de `(0, 0, -8)`, detrás del
   obstáculo: el héroe debe rodearlo y detenerse. Aleja el zoom si necesitas ver el destino. Mantén pulsado el
   botón izquierdo: debe dirigirse directamente y detenerse al soltarlo. Prueba la órbita con el botón derecho,
   el zoom con la rueda, botón derecho + WASD, Mayús y Espacio.
   Con el recurso de movimiento suministrado, la velocidad normal es 5.5 m/s, el sprint 8.25 m/s, la altura de
   salto 1 m y un escalón de 0.2 m no requiere salto. Revisa el depurador por si faltan acciones o recursos, o
   aparecen advertencias de configuración.

La escena copiada tiene el comportamiento predeterminado de la demo sin su sistema de ajustes: ambos modos de
teclas son `TURN`; el seguimiento de cámara, la alineación de inclinación y altura, y la flotación están
desactivados; los sonidos de sprint también. El nigromante es el modelo inicial. Consulta
[Configuraciones](configurations.md) para ver las rutas exactas de los nodos, los distintos tipos de valores
predeterminados y dos variantes útiles.

### Resolver problemas de la transferencia

| Síntoma | Primera comprobación |
|---|---|
| Falta una clase global o un recurso | Copia las cuatro carpetas de addons y los recursos indicados en sus rutas originales; espera a que el editor acabe de importar. Incluye los dos materiales de madera |
| El héroe atraviesa el suelo | El suelo necesita una forma de colisión en la capa 1; un MeshInstance3D solo aporta lo visual |
| Los clics no hacen nada | Revisa la acción del mapa de entrada, la cámara activa, `PlayerInput.camera` y `ground_mask` del rayo; un Control superpuesto puede consumir la entrada del ratón |
| El héroe choca con una pared en vez de rodearla | Hornea los colisionadores bajo la región, revisa las capas de navegación de la región y el componente de movimiento e inspecciona la malla resultante |
| La ruta cruza un escalón que el héroe no puede subir | Haz coincidir Agent Max Climb con `max_step_height`, usa celdas verticales finas, vuelve a hornear y prueba la geometría real |
| Los cambios de la escena desaparecen al iniciar | Un `SettingsApplier` copiado puede sobrescribirlos con ajustes guardados; el héroe independiente no lo necesita |
| La cámara gira de forma inesperada tras cambiar el movimiento | Compara `turn_speed` del personaje con `sharp_turn_speed` de la cámara; consulta [Configuraciones](configurations.md#ajustar-sin-romper-la-configuración) |

Ten en cuenta lo siguiente:

- Los addons y `playable_hero.gd` declaran nombres de clase globales (`GroundCharacter`, `NavigationMover`,
  `OrbitCameraRig`, `PlayableHero` y las demás clases de [la tabla anterior](#los-addons)). Si tu proyecto ya tiene
  una clase con el mismo nombre, habrá un conflicto: cambia el nombre de una de las dos.
- Si cambias `turn_speed` en `LocomotionSettings`, mantén `CameraRig.sharp_turn_speed` en la mitad o menos. De otro
  modo, la cámara puede interpretar el giro completo como una carrera lateral y girar. El héroe advierte al inicio
  cuando este umbral no está por debajo de la velocidad de giro.
- No necesitas el autoload `Settings` ni su ventana. El HUD no forma parte del héroe: la barra de resistencia y
  el aviso de lugar están en `main.tscn` de la demo; consulta la nota sobre el tema en [Los addons](#los-addons).
- Los modelos y sonidos tienen licencia MIT, igual que el código del proyecto.

## Niveles

Copia `addons/iso_orbit/levels/`. La escena principal contiene un `LevelHost` cuyo único hijo es el nivel inicial,
el héroe a su lado y `loading_screen.tscn`. Tu script principal conecta las señales del host: al recibir
`level_change_started`, quita el control; en `level_loaded(level, spawn)`, coloca al héroe en `spawn`; en
`level_change_finished`, devuelve el control; en `level_change_failed`, devuélvelo también (el nivel anterior
permanece y no llega `level_change_finished`); con `portal_entered` y `portal_exited`, muestra y oculta la
invitación a viajar. `gdscript/main.gd` hace exactamente esto. Cada nivel necesita un `SpawnPoint` llamado
`default`; los portales son áreas `LevelPortal` con la ruta de la escena de destino.

Si tienes tu propio sistema de niveles, usa solo el héroe jugable y llama a `place_at()` cuando el nivel esté
listo; si tienes tu propio personaje, llama a `GroundCharacter.teleport()` para lograr lo mismo. Consulta
[Niveles](systems/levels.md) para conocer los valores predeterminados y las combinaciones de ajustes.

## Tu propio cuerpo

Para conservar tu propio controlador de personaje, toma solo `addons/iso_orbit/click_to_move/`. El contrato es corto:

- `NavigationMover` debe ser hijo directo del cuerpo (cualquier `Node3D`). Lee la posición del cuerpo y el mapa de
  navegación del mundo del cuerpo.
- El cuerpo llama a `mover.compute_velocity(delta)` una vez por tick de física, antes de `move_and_slide()`, y aplica
  la X y la Z del resultado. El componente de movimiento nunca mueve el cuerpo.
- La velocidad vertical queda a cargo del cuerpo: gravedad, saltos, empujes.

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover
func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
```

Este cuerpo mínimo necesita una forma de colisión propia, un suelo y una cámara para verlo; añade un modelo bajo
un nodo `Visual`. Para orientarlo hacia el movimiento, alinea su eje −Z con `mover.get_facing()` en el espacio
global. `GroundCharacter` ya se encarga de orientar el modelo, incluso si su padre está girado, cuando no
necesitas conservar tu implementación del cuerpo.

`LedgeGuard` es opcional y requiere `addons/iso_orbit/ground_character/`: añádelo como hijo del cuerpo y aplica
`velocity = ledge_guard.constrain(velocity, delta)` antes de `move_and_slide()`. Para esprintar, establece
`mover.sprinting = true`: el límite de velocidad aumenta según
`LocomotionSettings.sprint_speed_multiplier`. Todo lo demás de `GroundCharacter` (salto, resistencia, escalones,
estado y señales, giro suave del modelo) queda a tu cargo.

## Dar órdenes al componente de movimiento

Cualquier cosa puede controlar a un personaje: la entrada del jugador, una IA, una cinemática o código de red.

| Llamada | Efecto |
|---|---|
| `move_to(point)` | Sigue una ruta de navegación hacia un punto global. Un destino inaccesible puede terminar en el punto alcanzable más próximo; una ruta vacía hace que se avance directamente. Un destino a menos de `retarget_tolerance` (0.1 m) del actual no reconstruye la ruta |
| `steer(direction, facing = Vector3.ZERO)` | Correr en una dirección sin ruta hasta nueva orden; con `facing`, mirar hacia ese lado mientras se mueve (desplazamiento lateral) |
| `stop()` | Frenar suavemente donde está el personaje |
| `halt()` | Detenerse al instante, por ejemplo tras un teletransporte |
| `face(direction)` | Gira al instante a un personaje parado, por ejemplo en un punto de aparición |

Para colocar al personaje entero en otro lugar, llama a `GroundCharacter.teleport(position, facing)`: detiene el
componente de movimiento, gira el personaje y su modelo, y desplaza el cuerpo sin sacudidas para sus seguidores.

Señales: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (se abandonó el punto por
`steer()` o `stop()`). Consultas: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Detalles:
[Locomoción](systems/locomotion.md).

## Un NPC

Instancia `player.tscn` (o tu propia escena de cuerpo con componente de movimiento) y elimina los nodos `Silhouette` y
`Appearance`, exclusivos del jugador. No añadas nodos de entrada: llama a `NavigationMover.move_to()` desde la
IA y escucha `arrived`. Para usar un modelo de la demo, colócalo bajo `Visual/Hover` como `Model`. Si giras al PNJ
en el editor, cambias su orientación inicial; después puedes girarlo con
`GroundCharacter.teleport(position, facing)` o `NavigationMover.face()`. Los PNJ inmóviles del nivel de la demo
son cuerpos estáticos, no personajes; consulta [Mundo y navegación](systems/world-and-navigation.md).

## Ajustes

Los componentes nunca leen la configuración: cada uno lee sus propias propiedades exportadas. Para exponerlas en tu
menú de configuración, establece las propiedades desde tu propio código cuando cambie una opción.
`gdscript/demo/settings_applier.gd` es un ejemplo: un solo `match` asigna cada clave de configuración a una propiedad
de nodo. Para reutilizar también el sistema de configuración de la demo, copia `gdscript/settings/game_settings.gd`,
regístralo como el autoload `Settings`, reemplaza sus claves y `DEFAULTS` por las tuyas, y toma los controles de
`gdscript/ui/settings/`; ver [Interfaz de usuario](systems/ui.md#configuración).

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
