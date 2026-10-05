<!-- translation of addons/iso_orbit/occluded_silhouette/README.md @ af038a43f7c2 -->
# Silueta ocluida

[← Índice de documentación (repositorio de la plantilla)](../../../docs/es/index.md)

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
2. Agrega al personaje un `Node` con `occluded_silhouette.gd`. Establece `target` en el nodo que contiene el modelo
   (el héroe suministrado usa `Character/Visual`) y
   asigna `silhouette_mask.tres`, `silhouette_body.tres`, `silhouette_gear.tres` y `silhouette_outline.tres` a
   `mask`, `body_fill`, `gear_fill` y `outline`.
3. Las mallas bajo los nodos nombrados en `gear_nodes` (`RightHand`, `LeftHand`) cuentan como objetos en la mano.
   Si el modelo no tiene esos nodos, todas usan el relleno del cuerpo; cambia los nombres si tu equipo usa otra
   jerarquía.

Los colores son los parámetros `color` de los materiales, el ancho del borde es `width` en `silhouette_outline.tres`,
y `outline_enabled` desactiva el borde. La silueta necesita un obstáculo al menos 30 cm por delante del personaje
(`min_gap`, parámetro de los materiales de cuerpo, equipo y borde definido en `silhouette_common.gdshaderinc`:
cámbialo en los tres).

El componente asigna `material_overlay` a cada malla, incluidas las añadidas al cambiar de aspecto. Si tu modelo
ya usa esa propiedad para otro efecto, decide qué efecto tendrá prioridad. Los materiales se copian a las cadenas
de pasadas cuando se prepara el componente: cambia colores y `min_gap` antes de iniciar la escena;
`outline_enabled` sí puede cambiar durante la partida.

Usa el búfer de stencil, que es experimental en Godot 4.5+. Probado con el renderizador Forward+.

## Documentación

En el repositorio de la plantilla: `docs/es/systems/characters.md` (incluida la sustitución del modelo) y
`docs/es/integration.md` (copia del héroe jugable).

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
