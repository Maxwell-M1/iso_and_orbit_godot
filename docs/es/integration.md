<!-- translation of docs/en/integration.md @ 69adeef2aab9 -->
# Uso en tu proyecto

> Esta es una traducción del [original en inglés](../en/integration.md).
> Si hay diferencias, la versión en inglés es la correcta.

Los componentes reutilizables están en `addons/iso_orbit/`, una carpeta por parte; la carpeta común los mantiene
separados de tus otros addons. Copia las carpetas que necesites en `addons/iso_orbit/` de tu proyecto, conecta los
nodos en tus escenas y prepara el proyecto como se describe en [Preparación del proyecto](project-setup.md). Los
scripts son clases GDScript comunes (`class_name`): no hay ningún plugin del editor que activar.

## Los addons

| Addon | Clases | Necesita |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | Las acciones de entrada `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`; capas de física para el brazo |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | Un `NavigationRegion3D` horneado en el mundo (sin él, el personaje corre en línea recta hacia el punto). Para la entrada: cualquier `Camera3D` y las acciones `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` |
| `ground_character` | `GroundCharacter`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. Para las teclas: las acciones `sprint` y `jump`. Para los sonidos: los tuyos, o `shared/audio/character/`. Para el balanceo de la mano y los modelos intercambiables: modelos orientados hacia −Z con un nodo de mano |
| `occluded_silhouette` | `OccludedSilhouette`, con sus shaders y materiales | Nada: funciona con cualquier modelo |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | El cuerpo del jugador en el grupo `player`, en una capa de física que vean las áreas |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter` | La acción integrada `ui_cancel`; la acción `toggle_settings` si `UiRoot` abre una ventana con una tecla |

Cada carpeta de addon tiene un `README.md` con su configuración y una copia de la `LICENSE`. Toma un addon entero:
las clases que contiene se referencian entre sí por tipo, y un archivo que no uses no hace daño. Mantén las carpetas
en `res://addons/iso_orbit/<addon>/`: las escenas y los materiales que contienen se refieren a sus archivos por esas
rutas. Para poner un addon en otro lugar, muévelo en el panel Sistema de Archivos (FileSystem) del editor, que
actualiza las referencias.

Los widgets del HUD (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) toman su aspecto de variaciones de tipo del tema
con los mismos nombres en el tema de la demo, `shared/ui/ui_theme.tres`; sin ellas usan el tema por defecto.

No están en los addons, porque están construidos en torno a esta demo: el sistema de configuración
(`gdscript/settings/game_settings.gd` y la ventana de configuración en `gdscript/ui/settings/`, ver
[Configuración](#configuración)), `gdscript/ui/ui_root.tscn` (un `UiRoot` preparado con esa ventana) y el código de
enlace de la demo, `gdscript/demo/hud.gd` y `settings_applier.gd`.

## La cámara sola

La cámara funciona con cualquier objetivo `Node3D` y solo necesita `addons/iso_orbit/orbit_camera/`.

1. Agrega a la escena un `Node3D` con `orbit_camera_rig.gd` junto al objetivo, no dentro de él.
2. Dale un hijo `Node3D` con `camera_arm.gd`, y a este, un hijo `Camera3D`.
3. Establece el `target` del rig. Establece el `fade_target` del brazo en el nodo que debe volverse translúcido cuando
   la cámara está muy cerca, o déjalo vacío.
4. Agrega las acciones de entrada y, para el brazo, las capas de física de
   [Preparación del proyecto](project-setup.md).

Sin brazo también funciona un `Camera3D` hijo del rig: la cámara se queda entonces a la distancia que fija el zoom y
atraviesa las paredes. El rig se actualiza en `_process` a partir de la posición interpolada del objetivo, así que
activa la interpolación de física en el proyecto si el objetivo se mueve en ticks de física. Detalles:
[Cámara](systems/camera.md).

## Movimiento por clic con el cuerpo listo para usar

Copia `addons/iso_orbit/click_to_move/` y `addons/iso_orbit/ground_character/`.

1. Hornea una malla de navegación para tu nivel (`NavigationRegion3D` → **Bakear NavigationMesh**, en inglés
   **Bake NavigationMesh**). Su radio de agente y su escalada máxima deben corresponder a tu personaje, ver
   [Mundo y navegación](systems/world-and-navigation.md).
2. Crea un `CharacterBody3D` con `ground_character.gd`: una forma de colisión, un nodo `Visual` con el modelo
   (orientado hacia −Z) y estos hijos: `NavigationMover` (un `Node` con `navigation_mover.gd`) y, opcionalmente,
   `LedgeGuard` y `Stamina`. Establece `mover`, `visual`, `ledge_guard` y `stamina` del cuerpo.
3. Dale al movedor un recurso `LocomotionSettings`, o déjalo vacío para usar los valores por defecto.
4. Agrega un `Node` con `point_click_move_input.gd` en cualquier lugar de la escena y establece su `mover` y su
   `camera`.
5. Opcionalmente, agrega `character_action_input.gd` con `character` apuntando al cuerpo, para el sprint y el salto.

`gdscript/player/player.tscn` es esta configuración, más los sonidos, el balanceo de la mano, el modelo
intercambiable y la silueta. Puedes instanciarla y quitar lo que no necesites.

## Tu propio cuerpo

Para conservar tu propio controlador de personaje, toma solo `addons/iso_orbit/click_to_move/`. El contrato es corto:

- `NavigationMover` debe ser hijo directo del cuerpo (cualquier `Node3D`). Lee la posición del cuerpo y el mapa de
  navegación del mundo del cuerpo.
- El cuerpo llama a `mover.compute_velocity(delta)` una vez por tick de física, antes de `move_and_slide()`, y aplica
  la X y la Z del resultado. El movedor nunca mueve el cuerpo.
- La velocidad vertical queda a cargo del cuerpo: gravedad, saltos, empujes.

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover
@onready var ledge_guard: LedgeGuard = $LedgeGuard


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity = ledge_guard.constrain(velocity, delta)
	move_and_slide()
	var facing := mover.get_facing()
	$Visual.rotation.y = atan2(-facing.x, -facing.z)
```

`LedgeGuard` es opcional: un hijo del cuerpo, de `addons/iso_orbit/ground_character/`. Para esprintar, establece
`mover.sprinting = true`: el límite de velocidad sube según `LocomotionSettings.sprint_speed_multiplier`. Todo lo
demás de `GroundCharacter` (salto, resistencia, señales de pasos, el giro suave del modelo) queda entonces en tus
manos.

## Dar órdenes al movedor

Cualquier cosa puede controlar a un personaje: la entrada del jugador, una IA, una cinemática o código de red.

| Llamada | Efecto |
|---|---|
| `move_to(point)` | Correr hasta un punto por una ruta de navegación y detenerse exactamente allí. Se puede llamar en cada tick; un punto a menos de `retarget_tolerance` (0,1 m) del actual no reconstruye la ruta |
| `steer(direction, facing = Vector3.ZERO)` | Correr en una dirección sin ruta hasta nueva orden; con `facing`, mirar hacia ese lado mientras se mueve (desplazamiento lateral) |
| `stop()` | Frenar suavemente donde está el personaje |
| `halt()` | Detenerse al instante, por ejemplo tras un teletransporte |

Señales: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (se abandonó el punto por
`steer()` o `stop()`). Consultas: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Detalles:
[Locomoción](systems/locomotion.md).

## Un NPC

Instancia `player.tscn` (o tu propia escena de cuerpo con un movedor) y quita los nodos `Silhouette` y `Appearance`,
que son solo del jugador. No agregues los nodos de entrada: llama a `NavigationMover.move_to()` desde tu IA y escucha
`arrived`. Para usar uno de los modelos de personaje de la demo, ponlo bajo `Visual` como `Model`. Los NPC que hay en
el nivel de la demo son cuerpos estáticos, no personajes; ver [Mundo y navegación](systems/world-and-navigation.md).

## Configuración

Los componentes nunca leen la configuración: cada uno lee sus propias propiedades exportadas. Para exponerlas en tu
menú de configuración, establece las propiedades desde tu propio código cuando cambie una opción.
`gdscript/demo/settings_applier.gd` es un ejemplo: un solo `match` asigna cada clave de configuración a una propiedad
de nodo. Para reutilizar también el sistema de configuración de la demo, copia `gdscript/settings/game_settings.gd`,
regístralo como el autoload `Settings`, reemplaza sus claves y `DEFAULTS` por las tuyas, y toma los controles de
`gdscript/ui/settings/`; ver [Interfaz de usuario](systems/ui.md#configuración).

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
