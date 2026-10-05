<!-- translation of docs/en/project-setup.md @ e52ff77b332d -->
# Preparación del proyecto

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/project-setup.md).
> Si hay diferencias, la versión en inglés es la correcta.

Qué esperan los componentes de `project.godot` y de la escena. Cuando pases componentes a otro proyecto, copia las
partes de esta preparación que usan.

Para el héroe montado, sigue primero los
[pasos de transferencia](integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto).
Necesita las acciones de movimiento, cámara, sprint y salto, ajustes de navegación compatibles y capas de colisión.
Autoload, tema, traducciones, pantalla y sistema de niveles de la demo son opcionales.

## Capas de física

| Capa | Nombre | Qué hay en ella | Quién la lee |
|---|---|---|---|
| 1 | `world` | Suelo, paredes, objetos, montaña y PNJ del nivel | Rayo del clic (`PointClickMoveInput.ground_mask`), cuerpo del jugador y su `LedgeGuard` (`floor_mask` 0 toma la máscara del cuerpo), `CameraArm.collision_mask` y horneado de navegación |
| 2 | `characters` | Cuerpo del jugador (`collision_layer = 2`) | Áreas `PointOfInterest` y `LevelPortal` (`collision_mask = 2`); el brazo la ignora |
| 3 | `camera` | Cuerpos que solo detienen la cámara, como `RoofCameraBlocker` en `shared/world/props/house.tscn` | Solo `CameraArm.collision_mask` |
| 4 | `bounds` | Paredes invisibles en el borde de un nivel, como `Edge` en la isla | Cuerpo del jugador (`collision_mask` = capas 1 y 4) y su `LedgeGuard`; horneado de malla donde se solicite, como la isla |

`CameraArm.collision_mask` incluye por defecto las capas 1 y 3 (`0b101`). Los personajes en la capa 2 nunca empujan
la cámara. Un cuerpo en la capa 3 detiene la cámara pero es invisible para los clics, la navegación y los
personajes, así que puedes mantener la cámara fuera de un techo sin que nadie pueda trazar una ruta hasta él. Un
cuerpo en la capa 4 hace lo contrario: detiene al personaje, pero clics y cámara lo atraviesan. Un clic en suelo o
agua tras una pared invisible no apunta a la propia pared.

La capa de navegación 1 se llama `ground`; `NavigationMover.navigation_layers` la usa por defecto.
Las capas de física y de navegación son independientes: la capa física de un colisionador determina qué rayos y
cuerpos chocan, y las capas de una región determinan qué rutas puede consultar el componente de movimiento. En
código son campos de bits: capas 1 y 4 son `1 | 8 = 9`; capas 1 y 3 son `1 | 4 = 5`. En el Inspector marca las
casillas numeradas.

## Acciones de entrada

| Acción | Por defecto | La usa |
|---|---|---|
| `move_to_cursor` | Botón izquierdo del mouse | `PointClickMoveInput.move_action` |
| `camera_rotate` | Botón derecho del mouse | `OrbitCameraRig.rotate_action`, `PointClickMoveInput.camera_steer_action` |
| `camera_zoom_in` | Rueda hacia arriba | `OrbitCameraRig.zoom_in_action` |
| `camera_zoom_out` | Rueda hacia abajo | `OrbitCameraRig.zoom_out_action` |
| `move_forward`, `move_back`, `move_left`, `move_right` | W, S, A, D | `PointClickMoveInput`, con el botón derecho mantenido |
| `sprint` | Shift | `CharacterActionInput.sprint_action` |
| `jump` | Espacio | `CharacterActionInput.jump_action` |
| `toggle_settings` | F10 | `UiRoot.settings_action` |
| `interact` | E | `TravelPrompt.action`: confirma la invitación a viajar en una plataforma (demo) |
| `ui_cancel` | Esc (integrada) | `UiRoot`: cierra la ventana de arriba |

Agrega estas acciones en **Proyecto → Ajustes del proyecto → Mapa de entrada**, usando eventos de tecla física
para las letras. El héroe independiente necesita las siete primeras filas (diez acciones); `toggle_settings`,
`interact` y `ui_cancel` pertenecen a la interfaz y el viaje opcionales. También puedes incorporar a tu proyecto
las entradas necesarias de la sección `[input]` de este `project.godot`; no reemplaces todo tu archivo.

Las teclas están asignadas por posición física, así que WASD queda en su lugar con cualquier distribución de
teclado. Cada componente recibe el nombre de la acción como propiedad exportada, así que puedes usar tus propias
acciones. Si falta alguna, el componente que la necesita (también la raíz de ventanas y la invitación a viajar)
informa una vez al inicio y luego no la lee: sus botones no actúan, no repite errores y las demás teclas funcionan.

Las indicaciones del HUD, ajustes y consejos de carga obtienen los nombres de estas acciones. Tras cambiar
`InputMap` durante una partida, llama a `get_tree().call_group(ActionTexts.GROUP, &"refresh")` si usas esos textos.
La demo no tiene menú de reasignación ni guarda las teclas; consulta
[nombres de teclas en los textos](systems/ui.md#nombres-de-teclas-en-los-textos).

## Grupos

| Grupo | Significado |
|---|---|
| `player` | Cuerpo del jugador. `PointOfInterest` (`player_group`) y `LevelPortal` (`traveller_group`) solo reaccionan a ese grupo. Se asigna a `Character` en `playable_hero.tscn` |
| `camera_ignore` | Cuerpos que el brazo de la cámara atraviesa (`CameraArm.ignored_groups`). Se aplica a todo lo que está bajo un nodo del grupo, así que asígnalo una vez en la raíz de una escena de prop o en un nodo carpeta del nivel. La demo no lo usa |
| `points_of_interest` | Cada `PointOfInterest` se agrega a sí mismo; `DiscoveryToast` y la escena principal encuentran los lugares por este grupo |
| `level_portals`, `spawn_points` | Se agregan automáticamente por cada `LevelPortal` y `SpawnPoint`; `LevelHost` encuentra los de su nivel |

## Autoload

`Settings` → `res://gdscript/settings/game_settings.gd`. Solo lo necesitan la ventana de configuración, sus controles
y `gdscript/demo/settings_applier.gd`. Los componentes funcionan sin él. Ver [Configuración](settings.md).

## Otros ajustes del proyecto

| Ajuste | Valor | Notas |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | La demo |
| `physics/3d/physics_engine` | Jolt Physics | Integrado en el motor; el brazo de la cámara y las pruebas se verifican con él |
| `navigation/3d/default_cell_height` | 0.025 | Debe coincidir con `cell_height` de la malla. La demo usa celdas verticales finas para escalones; un mapa y malla nuevos también deben coincidir. Consulta [Mundo y navegación](systems/world-and-navigation.md) |
| `display/window/stretch/mode` | `canvas_items` | La opción de escala de la interfaz escala todo el 2D mediante `content_scale_factor` y deja intacta la vista 3D |
| `display/window/stretch/aspect` | `expand` | Cualquier forma de ventana |
| `gui/theme/custom` | `res://shared/ui/ui_theme.tres` | Aspecto de todas las ventanas y los elementos del HUD |
| `internationalization/locale/translations` | `res://l10n/ui/*.po` | Traducciones de la interfaz; ver [Interfaz de usuario](systems/ui.md) |
| `rendering/rendering_device/driver.windows` | `d3d12` | Direct3D 12 en Windows |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 5 (Ultra) | Sombras suaves; el sol en `world.tscn` también tiene `shadow_blur = 1.25` y una distancia de sombra de 70 m |
| `rendering/anti_aliasing/quality/msaa_3d` | 2 (4×) | Antialiasing multimuestra |

La física funciona a los 60 ticks por segundo por defecto. La interpolación de física está activada en `project.godot`
(`physics/common/physics_interpolation`) y se cambia en tiempo de ejecución con una opción (Configuración → Pantalla).

## Datos guardados

La configuración se guarda en `user://settings.cfg`, en la carpeta de datos de usuario del proyecto (en el editor:
Proyecto → Abrir Carpeta de Datos del Usuario, en inglés Project → Open User Data Folder). Borra el archivo para
volver a los valores por defecto, o usa **Restablecer todo** en la ventana de configuración.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
