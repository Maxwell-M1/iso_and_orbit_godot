<!-- translation of addons/iso_orbit/click_to_move/README.md @ 784d979b2a2a -->
# Movimiento por clic

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Movimiento por clic para juegos isométricos y cenitales: haz clic en el suelo y el personaje corre hasta allí por la
malla de navegación, deteniéndose exactamente en el punto; mantén el botón y corre tras el cursor. Aceleración y
frenado constantes, velocidad de giro limitada, giro instantáneo desde parado. Con el botón derecho mantenido, WASD
mueven al personaje según la cámara.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Velocidad, aceleración, frenado, giro |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | La matemática: dirección y distancia restante → velocidad |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`; devuelve una velocidad, nunca mueve el cuerpo |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Mouse y clic der. + WASD → órdenes al movedor |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | El marcador en el punto del clic |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | Una línea de depuración a lo largo de la ruta restante |

No se necesita ningún otro addon. Para un cuerpo listo para usar con gravedad, salto y sprint, agrega
`addons/iso_orbit/ground_character`.

## Configuración

1. Copia esta carpeta en `res://addons/iso_orbit/click_to_move/`.
2. Hornea una malla de navegación para tu nivel (`NavigationRegion3D`). Sin ella, el personaje corre en línea recta
   hacia el punto.
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

4. Para controlar con el mouse, agrega un `Node` con `point_click_move_input.gd` en cualquier lugar y establece su
   `mover` y su `camera`. Necesita las acciones de entrada `move_to_cursor` (botón izquierdo), `camera_rotate` (botón
   derecho) y `move_forward`, `move_back`, `move_left`, `move_right` (WASD), y los clics impactan en la capa de
   física 1 (`ground_mask`).
5. O da órdenes al movedor desde una IA: `move_to(point)`, `steer(direction)`, `stop()`, y escucha `arrived`.

## Documentación

En el repositorio de la plantilla: `docs/es/integration.md`, `docs/es/systems/locomotion.md` y
`docs/es/systems/input.md`.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
