<!-- translation of docs/en/settings.md @ 60ac8a94fbe7 -->
# Configuración

> Esta es una traducción del [original en inglés](../en/settings.md).
> Si hay diferencias, la versión en inglés es la correcta.

F10 abre la ventana de configuración y pausa el juego; Esc o F10 la cierra. Los cambios se aplican al instante y se
guardan en `user://settings.cfg` al cerrar la ventana y al salir del juego. **Restablecer todo** devuelve cada opción
a su valor por defecto.

Los valores por defecto están en `DEFAULTS` en `gdscript/settings/game_settings.gd`. La demo los aplica a propiedades
de nodos en `gdscript/demo/settings_applier.gd`; los valores por defecto de las propiedades de los propios componentes
pueden ser distintos, como se indica abajo. Cómo funciona el sistema de configuración y cómo agregar una opción:
[Interfaz de usuario](systems/ui.md#configuración).

## Controles

| Opción | Clave | Por defecto | Se aplica a |
|---|---|---|---|
| **Clic izq. mantenido**: Directo al cursor / Al punto por una ruta | `gameplay/hold_mode` | Directo al cursor | `PointClickMoveInput.hold_mode` |
| **Clic der. + WASD**: Desactivado / Lateral / Giro | `gameplay/camera_keys_mode` | Giro | `PointClickMoveInput.keys_with_camera` (por defecto en el componente: lateral) |
| **Clic izq. + der. + A/D**: Desactivado / Lateral / Diagonal | `gameplay/camera_steer_keys_mode` | Diagonal | `PointClickMoveInput.keys_with_camera_steer` (por defecto en el componente: lateral) |
| **Retroceso (S) más lento en** 0…80%, solo con lateral | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − valor |
| **Ocultar cursor al correr con clic izq. mantenido** | `gameplay/hide_cursor_on_hold` | activado | `PointClickMoveInput.hide_cursor_while_held` |

## Personaje

| Opción | Clave | Por defecto | Se aplica a |
|---|---|---|---|
| **Aspecto del héroe**: uno de diez | `character/look` | 10 · Mago de batalla | `CharacterAppearance.set_look()` |
| **No caer por los bordes** | `gameplay/ledge_guard` | activado | `LedgeGuard.enabled` |
| **Salto (Espacio)** | `character/jump` | activado | `GroundCharacter.can_jump` |
| **Altura del salto** 0,5…1,5 m | `character/jump_height` | 1,0 m | `GroundCharacter.jump_height` |
| **Sprint (Shift)** | `character/sprint` | activado | `GroundCharacter.can_sprint` |
| **Shift**: Mantener / Presionar para alternar | `character/sprint_mode` | Mantener | `CharacterActionInput.sprint_mode` |
| **Velocidad extra** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + valor |
| **Fatiga del sprint** | `character/fatigue` | activado | `GroundCharacter.sprint_tires` |
| **La resistencia dura** 3…10 s | `character/sprint_duration` | 5,0 s | `GroundCharacter.sprint_duration` |

La clave de la protección de bordes siguió siendo `gameplay/ledge_guard` cuando el interruptor pasó a la pestaña
Personaje, así no se pierde una elección guardada.

## Cámara

| Opción | Clave | Por defecto | Se aplica a |
|---|---|---|---|
| **Clic der. inclina la cámara arriba/abajo** | `camera/mouse_pitch` | desactivado | `OrbitCameraRig.mouse_pitch` |
| **Girar la cámara siguiendo la carrera** | `camera/follow` | desactivado | `OrbitCameraRig.follow_movement` |
| **Alinear inclinación de cámara** | `camera/align_pitch` | desactivado | `OrbitCameraRig.follow_pitch` |
| **Inclinación hacia abajo** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −valor (por defecto en el componente: −40°) |
| **Alcanzar en** 0…10 s ("al instante" en 0), para el giro y la inclinación | `camera/follow_time` | 1,1 s | `OrbitCameraRig.follow_time` (por defecto en el componente: 1,5 s) |
| **El cursor mantiene la mira al girar la cámara** | `camera/keep_aim` | activado | `PointClickMoveInput.keep_aim_on_camera_turn` |
| **La cámara se detiene en obstáculos detrás** | `camera/keep_out_of_geometry` | activado | `CameraArm.keep_out_of_geometry` |
| **Acercarse si el personaje queda oculto** | `camera/pull_in_on_occlusion` | desactivado | `CameraArm.pull_in_on_occlusion` |

## Pantalla

| Opción | Clave | Por defecto | Se aplica a |
|---|---|---|---|
| **Pantalla completa** | `display/fullscreen` | desactivado | `DisplayServer.window_set_mode()` |
| **Límite de FPS**: 24, 30, 60, 120, 240, Sin límite | `display/max_fps` | Sin límite | `Engine.max_fps` |
| **Sincronización vertical (V-Sync)** | `display/vsync` | desactivado | `DisplayServer.window_set_vsync_mode()` |
| **Interpolación de física (personaje y cámara)** | `display/physics_interpolation` | activado | `SceneTree.physics_interpolation` |
| **Contorno de silueta tras obstáculos** | `display/silhouette_outline` | activado | `OccludedSilhouette.outline_enabled` |

La pantalla completa no funciona mientras el juego se ejecuta dentro del editor, en la pestaña Juego (Game) o en su
ventana flotante (**Make Game Workspace Floating on Next Play**): la ventana pertenece al editor, así que allí el
interruptor está desactivado. Para probarla desde el editor, desactiva **Embed Game on Next Play** en el menú de la
pestaña Juego: entonces el juego se abre en su propia ventana.

Con V-Sync nunca hay más fotogramas que la frecuencia de actualización del monitor, así que un límite de FPS igual o
superior a esa frecuencia no se aplica en absoluto: competiría con V-Sync y daría menos fotogramas de los que muestra
el monitor (un límite de 240 en un monitor de 240 Hz daba unos 220).

Sin interpolación de física, el personaje y la cámara se mueven a saltos, tick a tick (60 por segundo): la cámara sigue
`get_global_transform_interpolated()` del objetivo, que sin interpolación es simplemente su posición en el último tick.
En un monitor de más de 60 Hz se nota, y con la cámara siguiendo la carrera el personaje además se tambalea en los
giros: la cámara gira cada fotograma, el personaje solo cada tick.

## Interfaz

| Opción | Clave | Por defecto | Se aplica a |
|---|---|---|---|
| **Idioma**: English, Español, 日本語, Português (Brasil), Русский, Türkçe, 简体中文 | `interface/language` | English | `TranslationServer.set_locale()` |
| **Escala de la interfaz** 50…100% | `interface/ui_scale` | 75% | `content_scale_factor` de la ventana raíz |
| **Contador de FPS** | `interface/fps_counter` | activado | Visibilidad de `Hud/FpsCounter` |
| **Ayuda de controles y velocidad** | `interface/help` | activado | Visibilidad de `Hud/Panel` |
| **Línea de ruta del personaje** | `interface/path_line` | desactivado | Visibilidad de `PathView` |

La escala de la interfaz cambia la ayuda, el contador de FPS, la barra de resistencia y las ventanas, no la vista 3D.
100% es el tamaño tal como está diseñado en las escenas.

## Sonido

| Opción | Clave | Por defecto | Se aplica a |
|---|---|---|---|
| **Volumen** 0…100% ("apagado" en 0) | `sound/volume` | 100% | Volumen del bus `Master`; 0 lo silencia |
| **Pasos** | `sound/footsteps` | activado | `CharacterSounds.footsteps_enabled` |
| **Salto y aterrizaje** | `sound/jump` | activado | `CharacterSounds.jump_enabled` |
| **Arranque y sprint** | `sound/sprint` | desactivado | `CharacterSounds.sprint_enabled` |

## Opciones dependientes

Los controles que no tienen sentido sin otra opción se atenúan y no se pueden cambiar: la ralentización hacia atrás
sin el modo lateral para Clic der. + WASD, la altura del salto sin el salto, todo lo del sprint sin el sprint, la
duración de la resistencia sin la fatiga, el ángulo de inclinación sin la alineación de la inclinación, y el tiempo
de alcance sin el seguimiento ni la alineación de la inclinación.

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
