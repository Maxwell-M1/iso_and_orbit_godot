<!-- translation of addons/iso_orbit/occluded_silhouette/README.md @ 9da2f485c778 -->
# Silueta ocluida

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Muestra un personaje a través de lo que lo oculte: el cuerpo como una sola forma plana, los objetos de sus manos
contorneados encima y un borde alrededor de todo. Donde el personaje es visible, no se dibuja nada. Los materiales
propios del modelo no se tocan, así que el mismo modelo en otro lugar no tiene silueta.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Tarea |
|---|---|
| `occluded_silhouette.gd` | `OccludedSilhouette` (Node): pone las pasadas en cada malla del modelo como `material_overlay`, incluidas las mallas agregadas después |
| `silhouette_mask.gdshader`, `.tres` | Marca dónde el personaje es visible por sí mismo |
| `silhouette_body.gdshader`, `.tres` | El relleno plano del cuerpo |
| `silhouette_gear.gdshader`, `.tres` | El relleno más claro de los objetos en la mano |
| `silhouette_outline.gdshader`, `.tres` | El borde alrededor de toda la forma |
| `silhouette_common.gdshaderinc` | Código compartido: profundidad en metros, la distribución del stencil |

No se necesita ningún otro addon.

## Configuración

1. Copia esta carpeta en `res://addons/iso_orbit/occluded_silhouette/`; los materiales se refieren a los shaders por
   esa ruta.
2. Agrega al personaje un `Node` con `occluded_silhouette.gd`. Establece `target` en el nodo que contiene el modelo y
   asigna `silhouette_mask.tres`, `silhouette_body.tres`, `silhouette_gear.tres` y `silhouette_outline.tres` a
   `mask`, `body_fill`, `gear_fill` y `outline`.
3. Las mallas bajo los nodos nombrados en `gear_nodes` (`RightHand`, `LeftHand`) cuentan como objetos en la mano.

Los colores son los parámetros `color` de los materiales, el ancho del borde es `width` en `silhouette_outline.tres`,
y `outline_enabled` desactiva el borde. La silueta necesita un obstáculo al menos 30 cm por delante del personaje
(`min_gap`).

Usa el búfer de stencil, que es experimental en Godot 4.5+. Probado con el renderizador Forward+.

## Documentación

En el repositorio de la plantilla: `docs/es/systems/characters.md`.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
