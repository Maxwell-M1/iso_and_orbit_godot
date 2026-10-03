<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 77aade651b48 -->
# Cámara orbital

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Una cámara orbital para juegos isométricos y cenitales: sigue a un objetivo, orbita con el botón derecho del mouse,
hace zoom con la rueda (la distancia y la inclinación cambian juntas) y puede girar por sí sola tras el objetivo que
corre. La cámara está en el extremo de un brazo que se detiene ante las paredes que tiene detrás y puede acercarse
cuando un obstáculo oculta al objetivo.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig` (Node3D) | Sigue al objetivo, órbita, zoom, modo de seguimiento |
| `camera_arm.gd` | `CameraArm` (Node3D) | Sostiene la cámara y se acorta ante los obstáculos; desvanece al objetivo de cerca |

No se necesita ningún otro addon.

## Configuración

1. Copia esta carpeta en `res://addons/iso_orbit/orbit_camera/`.
2. Agrega las acciones de entrada (los nombres son propiedades exportadas, así que puedes usar los tuyos):
   `camera_rotate` (botón derecho del mouse), `camera_zoom_in` (rueda hacia arriba), `camera_zoom_out` (rueda hacia
   abajo).
3. Arma la cámara junto al objetivo, no dentro de él:

   ```
   CameraRig    Node3D con orbit_camera_rig.gd, target = tu personaje
   └── CameraArm    Node3D con camera_arm.gd
       └── Camera3D
   ```

4. Capas de física: el brazo se detiene ante los cuerpos de las capas 1 y 3 (`collision_mask`). Pon la geometría del
   nivel en una de ellas y mantén a los personajes fuera de ellas. Los cuerpos del grupo `camera_ignore` (o bajo un
   nodo que esté en él) nunca detienen el brazo.
5. Si el objetivo se mueve en ticks de física, activa la interpolación de física en el proyecto: el rig sigue la
   posición interpolada del objetivo.

Sin brazo también funciona un `Camera3D` hijo del rig: se queda a la distancia que fija el zoom y atraviesa las
paredes.

## Documentación

En el repositorio de la plantilla: `docs/es/systems/camera.md` (cada propiedad, la curva de zoom, el modo de
seguimiento, cómo funciona el brazo) y `docs/es/project-setup.md`.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
