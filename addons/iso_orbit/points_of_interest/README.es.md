<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 4bf86f099c43 -->
# Puntos de interés

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Lugares por descubrir: un área que avisa la primera vez que el jugador entra en ella, y un mensaje en pantalla
"Lugar descubierto: …" que encuentra cada lugar por sí solo.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest` (Area3D) | Emite `discovered(title)` la primera vez que entra un cuerpo del grupo `player`; se une al grupo `points_of_interest` |
| `discovery_toast.gd`, `discovery_toast.tscn` | `DiscoveryToast` (Label) | Muestra "Lugar descubierto: …" durante unos segundos cuando se descubre cualquier lugar |

No se necesita ningún otro addon.

## Configuración

1. Copia esta carpeta en `res://addons/iso_orbit/points_of_interest/`.
2. Pon el cuerpo del jugador en el grupo `player` (o establece `player_group`).
3. Para cada lugar, agrega un `Area3D` con `point_of_interest.gd` y una forma de colisión, establece su `title` y haz
   que su `collision_mask` incluya la capa de física del jugador.
4. Agrega `discovery_toast.tscn` a tu HUD. Se conecta a cada lugar de la escena al iniciar; no hace falta conectar
   nada.

El texto del mensaje y los títulos pasan por el servidor de traducción, así que se pueden localizar. El aspecto viene
de la variación de tipo del tema `DiscoveryToast`.

## Documentación

En el repositorio de la plantilla: `docs/es/systems/world-and-navigation.md` y `docs/es/systems/ui.md`.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
