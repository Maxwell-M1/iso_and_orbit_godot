<!-- translation of addons/iso_orbit/click_to_move/README.md @ 29860f203673 -->
# Movimiento por clic

[← Índice de documentación (repositorio de la plantilla)](../../../docs/es/index.md)

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Movimiento por clic para juegos isométricos y cenitales: haz clic en el suelo y el personaje corre hasta allí por la
malla de navegación, deteniéndose al final alcanzable de la ruta; mantén el botón y corre tras el cursor. Aceleración y
frenado constantes, velocidad de giro limitada, giro instantáneo desde parado. Con el botón derecho mantenido, WASD
mueven al personaje según la cámara. Si pulsas el botón derecho durante una carrera tras el cursor, el personaje
mantiene su dirección y puedes mirar alrededor.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Velocidad, aceleración, frenado, giro |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | La matemática: dirección y distancia restante → velocidad |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`, `halt()`, `face()`; devuelve velocidad, nunca mueve el cuerpo |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Ratón y botón derecho + WASD → órdenes de movimiento; `cancel()` descarta una pulsación en curso |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | El marcador en el punto del clic |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | Una línea de depuración a lo largo de la ruta restante |

No se necesita ningún otro addon. Para un cuerpo listo para usar con gravedad, salto y sprint, agrega
`addons/iso_orbit/ground_character`.

## Configuración

1. Copia esta carpeta en `res://addons/iso_orbit/click_to_move/`.
2. Hornea una malla de navegación para tu nivel (`NavigationRegion3D`). Ajusta tamaño del agente y altura máxima
   de escalón a la cápsula y escaleras del cuerpo. Sin malla o con una ruta vacía, el componente corre en línea
   recta hacia el punto solicitado; una ruta parcial puede terminar en el punto alcanzable más cercano. El cuerpo
   también necesita geometría y forma de colisión.
3. Agrega `NavigationMover` como hijo directo del cuerpo del personaje. El cuerpo llama a `compute_velocity(delta)`
   una vez por tick de física, antes de `move_and_slide()`:

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

   Asigna a `NavigationMover.settings` un recurso `LocomotionSettings` antes de que el componente entre en el
   árbol o déjalo vacío para crear uno con los valores del script. Usa **Make Unique** si cada personaje necesita
   ajustes independientes. Cambiar campos del recurso durante la partida funciona, pero sustituir
   `mover.settings` después de `_ready()` no cambia el recurso que ya usa `GroundMotion`. `GroundCharacter` del
   addon complementario se ocupa de escaleras, saltos y protección de bordes.

4. Para controlar con el ratón, agrega un `Node` con `point_click_move_input.gd` en cualquier lugar y asigna
   `mover` y `camera`. Necesita las acciones `move_to_cursor` (botón izquierdo), `camera_rotate` (derecho) y
   `move_forward`, `move_back`, `move_left`, `move_right` (WASD). Si falta una, informa una vez al inicio y luego
   no intenta leerla. Los clics detectan la capa de física 1 (`ground_mask`): deja fuera la capa de personajes y
   las paredes invisibles para que el clic no apunte a ellos. Si usas la cámara de
   `addons/iso_orbit/orbit_camera`, conecta `hold_pending_changed` a `set_follow_paused` y `run_requested` a
   `end_follow_wait`. Mirar alrededor durante una carrera (`look_around_while_held`) requiere que
   `camera_steer_action` sea la acción que gira la cámara (`rotate_action` en el rig, ambas `camera_rotate`).
5. También puedes mandar la IA con `move_to(point)`, `steer(direction)`, `stop()` y escuchar `arrived`. Indica que
   se llegó al final de la ruta, que puede estar antes del destino solicitado si este es inaccesible.

Para copiar el héroe ya montado, con sus archivos y ajustes de escena, consulta `docs/es/integration.md` en vez
de crear el cuerpo a mano. `docs/es/systems/input.md` explica los dos modos de entrada y los ajustes del héroe.

## Documentación

En el repositorio de la plantilla: `docs/es/integration.md`, `docs/es/systems/locomotion.md` y
`docs/es/systems/input.md`.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
