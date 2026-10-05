<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 94f2d396a032 -->
# Cámara orbital

[← Índice de documentación (repositorio de la plantilla)](../../../docs/es/index.md)

> Esta es una traducción del [original en inglés](README.md).
> Si hay diferencias, la versión en inglés es la referencia.

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Una cámara orbital para juegos isométricos y cenitales. Sigue cualquier `Node3D`, gira con el ratón y cambia el
zoom con la rueda. Durante una carrera puede girar detrás del objetivo, alinear su inclinación y volver a un zoom
elegido, de forma independiente. El brazo evita que la cámara entre en las paredes y, opcionalmente, la acerca
cuando un obstáculo oculta al objetivo.

Parte de Iso & Orbit para Godot 4.7. Licencia MIT (consulta `LICENSE`). Esta carpeta no necesita otros addons.

| Script | Clase | Función |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig` (`Node3D`) | Sigue al objetivo, procesa entrada y zoom, y alinea la vista opcionalmente al correr |
| `camera_arm.gd` | `CameraArm` (`Node3D`) | Coloca la cámara, responde a obstáculos y puede hacer transparente el modelo de cerca |

## Colocarla en una escena

1. Copia esta carpeta en `res://addons/iso_orbit/orbit_camera/`.
2. En **Ajustes del proyecto → Mapa de entrada**, agrega `camera_rotate` (botón derecho), `camera_zoom_in`
   (rueda arriba) y `camera_zoom_out` (rueda abajo). Puedes cambiar los nombres de acciones exportados por el rig.
   Si falta una acción, se informa del error al iniciar y no puede activar su entrada.
3. Añade los nodos siguientes junto al objetivo móvil. Asigna tu personaje u otro `Node3D` a
   `CameraRig.target`. Mantén sin escalar el subárbol de cámara y sus ancestros.

   ```text
   Scene
   ├── Character (objetivo en movimiento)
   └── CameraRig (Node3D + orbit_camera_rig.gd; target = ../Character)
       └── CameraArm (Node3D + camera_arm.gd)
           └── Camera3D (Current = on)
   ```

   El rig y el brazo encuentran respectivamente sus primeros hijos directos `CameraArm` y `Camera3D`; también
   puedes asignar las referencias exportadas `arm` y `camera`. Deja la transformación local de `Camera3D` en su
   valor predeterminado porque el brazo la coloca. Hazla actual cuando deba ser la vista activa. Para el encuadre
   de la plantilla, usa campo visual de 45° y plano lejano a 300 unidades del mundo.
4. Coloca la colisión sólida del mundo en la capa de física 1. `collision_mask` del brazo incluye por defecto
   las capas 1 y 3 (`0b101`); la capa 3 puede contener obstáculos solo para la cámara, como techos. No incluyas
   personajes en esa máscara para que no empujen la cámara. Agrega `camera_ignore` a un cuerpo o ancestro para
   excluirlo. Puedes asignar la raíz de un modelo a `CameraArm.fade_target` para hacerlo translúcido de cerca.
5. Si el objetivo se mueve en ticks de física, activa **Ajustes del proyecto → Física → Común → Interpolación de
   física**. El rig sigue la posición interpolada del objetivo en cada fotograma y desactiva su propia
   interpolación. Brazo y cámara heredan ese modo de forma predeterminada.

Los valores del script producen órbita manual: los tres interruptores de alineación al correr están desactivados,
aunque tiempos y destinos tengan valores. Para el seguimiento opcional ajustado del héroe, usa
`follow_time = 1.1` s, `follow_pitch_angle = -22°`, `follow_pitch_time = 1.1` s,
`follow_zoom_level = 0.55`, `follow_zoom_time = 1.5` s, `follow_wait_after_rotate = true` y
`height_follow_time = 0.15` s. Activa `follow_movement` para girar detrás de la carrera; activa `follow_pitch`
y/o `follow_zoom` si quieres esas alineaciones. El héroe deja los tres desactivados inicialmente. Los ángulos
se escriben en grados en el Inspector y en radianes con `deg_to_rad()` en GDScript.

Con `follow_wait_after_rotate`, el seguimiento espera tras una órbita deliberada hasta que el objetivo reduzca
la velocidad o comience otra carrera. Si tu entrada inicia una carrera antes de que se detenga, llama entonces a
`end_follow_wait()`. La plantilla conecta `PointClickMoveInput.run_requested` con ese método y
`hold_pending_changed` con `set_follow_paused()` en `gdscript/player/playable_hero.tscn`. Si el objetivo se
mueve continuamente sin poder anunciar carreras nuevas, deja desactivada la espera. Mantén `sharp_turn_speed`
como máximo en la mitad de la velocidad de giro del personaje para que un cambio de sentido no arrastre la cámara
por direcciones intermedias; la plantilla combina 360°/s con 720°/s del héroe.

Sin brazo también funciona una `Camera3D` hija directa del rig. Permanece a la distancia del zoom y atraviesa
paredes; evitar obstáculos y hacer transparente el modelo requiere `CameraArm`.

Para la curva de zoom, todas las propiedades, la oclusión y las interacciones probadas, consulta
[Cámara](../../../docs/es/systems/camera.md). Para transferir el héroe preparado, consulta
[Integración](../../../docs/es/integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto) y
[Preparación del proyecto](../../../docs/es/project-setup.md).

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
