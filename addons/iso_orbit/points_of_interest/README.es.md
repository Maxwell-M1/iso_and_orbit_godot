<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 70ad45747177 -->
# Puntos de interés

[← Índice de documentación (repositorio de la plantilla)](../../../docs/es/index.md)

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Lugares por descubrir: un área que avisa la primera vez que el jugador entra en ella, y un mensaje en pantalla
"Lugar descubierto: …" que encuentra cada lugar por sí solo.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest` (Area3D) | Emite `discovered(title)` la primera vez que entra un cuerpo del grupo `player`; pertenece a `points_of_interest`. `is_discovered()` consulta su estado y `mark_discovered()` lo marca sin emitir señal (al recargar un nivel o una partida) |
| `discovery_toast.gd`, `discovery_toast.tscn` | `DiscoveryToast` (Label) | Muestra «Lugar descubierto: …» durante unos segundos cuando se descubre cualquier lugar, incluso uno de un nivel cargado después (`watch_added_places`; si se desactiva, solo conecta los lugares iniciales) |

No se necesita ningún otro addon.

## Configuración

1. Copia esta carpeta en `res://addons/iso_orbit/points_of_interest/`.
2. Pon el cuerpo del jugador en el grupo `player` (o establece `player_group`).
3. Para cada lugar, agrega un `Area3D` con `point_of_interest.gd` y una forma de colisión, establece su `title` y haz
   que su `collision_mask` incluya la capa de física del jugador.
4. Agrega `discovery_toast.tscn` a tu HUD. Se conecta a los lugares iniciales y a los agregados después, salvo si
   desactivas `watch_added_places`; no hace falta conectar nada.

Un lugar recuerda que se descubrió mientras existe: al liberar su nivel también se libera ese estado, de modo que
si se carga otra vez vuelve a aparecer sin descubrir. El juego debe recordar los hallazgos: `gdscript/main.gd`
conserva una lista por nivel y llama a `mark_discovered()` al cargarlo de nuevo.

El texto del mensaje y los títulos pasan por el servidor de traducción, así que se pueden localizar. El aspecto viene
de la variación de tipo del tema `DiscoveryToast`.

## Documentación

En el repositorio de la plantilla: `docs/es/systems/world-and-navigation.md`, `docs/es/systems/ui.md` y
`docs/es/systems/levels.md`.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
