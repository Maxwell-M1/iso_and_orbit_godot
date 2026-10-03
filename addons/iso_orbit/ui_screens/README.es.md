<!-- translation of addons/iso_orbit/ui_screens/README.md @ b7618a65d4df -->
# Pantallas de UI

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Ventanas sobre el juego como una pila: abre una encima de otra, cierra la de arriba con Esc, pausa el juego y muestra
el cursor del mouse mientras haya alguna ventana abierta, da el foco del teclado a la ventana y lo devuelve cuando la
ventana se cierra. Además, un contador de FPS que sigue funcionando mientras el juego está en pausa.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `ui_root.gd` | `UiRoot` (CanvasLayer) | La pila de ventanas: `open()`, `close_top()`, `toggle()`; pausa, cursor, foco |
| `ui_screen.gd` | `UiScreen` (Control) | Base de una ventana: `initial_focus`, la señal `close_requested` |
| `fps_counter.gd`, `fps_counter.tscn` | `FpsCounter` (Label) | Fotogramas por segundo, también en pausa |

No se necesita ningún otro addon.

## Configuración

1. Copia esta carpeta en `res://addons/iso_orbit/ui_screens/`.
2. Agrega a la escena principal un `CanvasLayer` con `ui_root.gd`. Se ejecuta mientras el juego está en pausa.
3. Haz que cada ventana sea una escena cuya raíz extienda `UiScreen`. Una ventana nunca se cierra a sí misma: llama a
   `request_close()` y `UiRoot` la cierra.
4. Abre las ventanas con `UiRoot.open(scene)`. Para abrir una con una tecla, establece `settings_screen` en su escena
   y agrega la acción de entrada `toggle_settings` (o establece `settings_action`). Esc es la acción integrada
   `ui_cancel`.
5. Opcional: agrega `fps_counter.tscn` a tu HUD.

El aspecto viene del tema del proyecto; `FpsCounter` usa la variación de tipo del tema `FpsCounter`.

## Documentación

En el repositorio de la plantilla: `docs/es/systems/ui.md`.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
