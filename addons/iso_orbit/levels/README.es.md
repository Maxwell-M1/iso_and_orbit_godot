<!-- translation of addons/iso_orbit/levels/README.md @ 8dd533b32064 -->
# Niveles

[← Índice de documentación (repositorio de la plantilla)](../../../docs/es/index.md)

> Esta es una traducción del [original en inglés](README.md).
> Si hay diferencias, la versión en inglés es la referencia.

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

Permite cambiar de nivel tras una pantalla de carga mientras el personaje del jugador y la interfaz permanecen:
un host carga el nivel siguiente en segundo plano, libera el anterior e indica al juego dónde colocar al personaje;
los portales conducen a otros niveles, tras una confirmación o de inmediato; hay puntos de aparición y una pantalla
de carga que muestra, detrás del nombre del lugar, una imagen desenfocada del último fotograma, una barra de
progreso y consejos.

Forma parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT
(consulta `LICENSE`).

## Contenido

| Archivo | Clase | Función |
|---|---|---|
| `level_host.gd` | `LevelHost` (Node3D) | Aloja el nivel actual; `change_level(path, spawn_name, title)` carga el siguiente en segundo plano, los intercambia y comunica cada paso mediante señales. Vuelve a emitir las entradas y salidas de viajeros de los portales, incluidos los agregados más tarde, como `portal_entered` y `portal_exited` |
| `level_portal.gd` | `LevelPortal` (Area3D) | Paso a otro nivel: informa cuando un viajero entra o sale, viaja al llamar a `travel()` o por sí solo (`auto_travel`), y escribe su `title` en un letrero opcional |
| `spawn_point.gd` | `SpawnPoint` (Marker3D) | Punto de aparición identificado por nombre; el personaje mira hacia el eje −Z del marcador |
| `loading_screen.gd`, `loading_screen.tscn`, `loading_background.gdshader`, `loading_screen_theme.tres` | `LoadingScreen` (CanvasLayer) | Pantalla durante la carga: último fotograma desenfocado y oscurecido, que se acerca lentamente; nombre del lugar, barra que nunca retrocede y consejos. Mientras está visible, no llega ningún evento de entrada al juego |

No se necesita ningún otro addon: el host no conoce al personaje, la cámara ni la interfaz. Tu juego los conecta
a sus señales.

## Preparación

1. Copia esta carpeta en `res://addons/iso_orbit/levels/`.
2. En la escena principal que permanece entre niveles, agrega un `Node3D` con `level_host.gd` y pon el nivel inicial
   como único hijo. El personaje del jugador, la cámara y la interfaz van junto al host, no dentro de un nivel.
3. Agrega `loading_screen.tscn` a la escena principal y asígnalo a `loading_screen` del host; déjalo vacío si quieres
   cambiar de nivel sin pantalla.
4. En cada nivel, agrega en el suelo un `Marker3D` con `spawn_point.gd` llamado `default` (`spawn_name`), y otros
   puntos con nombres distintos para las llegadas desde portales.
5. Para un portal, crea un `Area3D` con `level_portal.gd` y una forma de colisión. Su `collision_mask` debe incluir
   la capa del personaje. Asigna `target_level` (archivo de escena), `target_spawn` y `title`. Añade el cuerpo del
   personaje al grupo `player` o cambia `traveller_group`.
6. Conecta las señales del host en tu script principal:
   - `level_change_started`: oculta lo que no deba aparecer en la imagen de la pantalla de carga y quita el control;
   - `level_loaded(level, spawn)`: coloca al personaje en `spawn` (con `GroundCharacter.teleport()` llega sin
     sacudidas) y gira la cámara;
   - `level_change_finished`: devuelve el control;
   - `level_change_failed(path, error)`: devuelve el control y muestra lo que ocultaste; el nivel actual permanece.
     Tras un fallo solo llega esta señal, nunca `level_change_finished`;
   - `portal_entered(portal)` y `portal_exited(portal)`: muestran y ocultan tu invitación a viajar; al confirmar,
     llama a `portal.travel()`.

El host no anuncia el nivel inicial: prepáralo en `_ready()` del script principal mediante `get_current_level()` y
`find_spawn_point()`.

Un portal normalmente solicita confirmación: el juego muestra una invitación y llama a `travel()`. Con
`auto_travel`, viaja al entrar el personaje, como una puerta o un límite del mapa. El cambio comienza justo después
de la solicitud, no dentro de ella, por lo que un portal puede solicitarlo desde una llamada de física. El juego se
pausa durante la carga y el intercambio; el host espera, todavía pausado, a que el mapa de navegación incluya el
nivel nuevo. Después reanuda el juego y dibuja unos fotogramas tras la pantalla antes de desvanecerla, para que los
shaders se compilen fuera de la vista. Ajustes del host: `min_loading_time` (0.6 s, duración mínima de pantalla),
`warmup_frames` (3, fotogramas dibujados detrás) y `navigation_timeout` (2 s, espera máxima del mapa).
`is_changing()` indica si hay un cambio en curso. `change_level()` devuelve `ERR_BUSY` durante un cambio,
`ERR_FILE_NOT_FOUND` y `ERR_INVALID_PARAMETER` si el archivo es incorrecto; una carga que falle más tarde conserva
el nivel actual y emite `level_change_failed`. La siguiente solicitud vuelve a cargar el archivo. El host solo
termina la pausa que él inició: abre las ventanas que pausen el juego después de `level_change_finished`. La
pantalla y las esperas usan tiempo real, con independencia de `Engine.time_scale`.

El aspecto de la pantalla de carga está en `loading_screen_theme.tres` (variaciones de tipo `LoadingTitle`,
`LoadingBar` y `LoadingTip`). Asigna otro tema a la raíz para cambiarlo o crea tu propia pantalla a partir de una
copia de `loading_screen.tscn`: el script necesita los nodos `Root` y, por nombre único, `Background`, `Title`,
`Bar` y `Tip`. No hay consejos hasta que los agregues a `tips`; cada uno se traduce y después pasa por
`tip_format` si el código lo establece (`InputNames.format` del addon `ui_screens` inserta las teclas asignadas:
`{sprint}` muestra «Shift»).

## Documentación

En el repositorio de la plantilla: `docs/es/systems/levels.md` y `docs/es/integration.md`.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
