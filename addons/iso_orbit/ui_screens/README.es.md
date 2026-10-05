<!-- translation of addons/iso_orbit/ui_screens/README.md @ f510902e02d8 -->
# Pantallas de UI

[← Índice de documentación (repositorio de la plantilla)](../../../docs/es/index.md)

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Ventanas sobre el juego como una pila: abre una encima de otra, cierra la de arriba con Esc, pausa el juego y muestra
el cursor del mouse mientras haya alguna ventana abierta, da el foco del teclado a la ventana y lo devuelve cuando la
ventana se cierra. Incluye un contador de FPS que funciona también en pausa y nombres de las teclas asignadas a
acciones de entrada para mostrar en los textos de la pantalla.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `ui_root.gd` | `UiRoot` (CanvasLayer) | La pila de ventanas: `open()`, `close_top()`, `toggle()`; pausa, cursor, foco |
| `ui_screen.gd` | `UiScreen` (Control) | Base de una ventana: `initial_focus`, la señal `close_requested` |
| `fps_counter.gd`, `fps_counter.tscn` | `FpsCounter` (Label) | Fotogramas por segundo, también en pausa |
| `input_names.gd` | `InputNames` (RefCounted, estático) | Tecla o botón de ratón de una acción según la distribución del jugador y el idioma: `of_action()`, `of_event()`; `format()` inserta los nombres en un texto mediante marcas como `{sprint}` |
| `action_texts.gd` | `ActionTexts` (Node) | Sustituye las marcas de los textos de controles bajo su padre, también al cambiar de idioma o llamar a `refresh()` |

No se necesita ningún otro addon.

## Configuración

1. Copia esta carpeta en `res://addons/iso_orbit/ui_screens/`.
2. Agrega a la escena principal un `CanvasLayer` con `ui_root.gd`. Se ejecuta mientras el juego está en pausa.
3. Haz que cada ventana sea una escena cuya raíz extienda `UiScreen`. Una ventana nunca se cierra a sí misma: llama a
   `request_close()` y `UiRoot` la cierra.
4. Abre las ventanas con `UiRoot.open(scene)`. Para abrir una con una tecla, establece `settings_screen` en su escena
   y agrega la acción de entrada `toggle_settings` (o establece `settings_action`). Si falta, `UiRoot` informa
   una vez al inicio y la tecla no hace nada. Esc usa la acción integrada `ui_cancel`.
5. Opcional: agrega `fps_counter.tscn` a tu HUD.
6. Opcional: escribe las teclas en tus textos como marcas de acción, por ejemplo `{jump} — jump`, y agrega un
   nodo `ActionTexts` a la escena para atender los controles bajo su padre. Si el jugador cambia las teclas, llama
   a `get_tree().call_group(ActionTexts.GROUP, &"refresh")`. Los controles que forman su propio texto pueden
   implementar `refresh()` y unirse al mismo grupo. Para traducir nombres de botones del ratón, «Space» y
   acciones sin tecla, agrega a tus traducciones `InputNames.get_mouse_names()`, «Space», `InputNames.UNBOUND`,
   `InputNames.LEFT_KEY` y `InputNames.RIGHT_KEY`. Las dos últimas conservan `%s` para el nombre de la tecla.

`UiRoot` solo pausa un juego que esté en marcha y termina solo su propia pausa. Si el juego ya estaba pausado al
abrirse una ventana, por ejemplo durante un cambio de nivel, conserva el responsable anterior; si este termina
la pausa, el juego continúa detrás de la ventana.

El aspecto viene del tema del proyecto; `FpsCounter` usa la variación de tipo del tema `FpsCounter`.

## Documentación

En el repositorio de la plantilla: `docs/es/systems/ui.md` y, para ventanas durante un cambio de nivel,
`docs/es/systems/levels.md`.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
