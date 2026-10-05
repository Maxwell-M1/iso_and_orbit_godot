<!-- translation of addons/iso_orbit/ground_character/README.md @ 87915285e965 -->
# Personaje terrestre

[← Índice de documentación (repositorio de la plantilla)](../../../docs/es/index.md)

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Un cuerpo de personaje listo para usar con movimiento por clic: gravedad, un salto con tiempo de coyote y búfer de
entrada (la misma altura con cualquier frecuencia de ticks de física), caída con gravedad y límite de velocidad
propios, sprint con resistencia, subida y bajada de escalones y protección opcional ante desniveles. El cuerpo informa
para animaciones, efectos y la interfaz: el estado y sus cambios, los pasos con el pie, los despegues y los aterrizajes,
la velocidad como valor de mezcla, el movimiento en los ejes del modelo, el giro y el ciclo de la marcha. También
incluye: sonidos en esas señales, un panel que muestra el estado como texto, un objeto en la mano que se balancea con
los pasos, un modo que hace flotar el modelo y modelos intercambiables.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Gravedad, salto, sprint, escalones, `move_and_slide()`, giro del modelo; estado, señales y consultas para animaciones; `teleport()` sin sacudidas |
| `fall_settings.gd` | `FallSettings` (Resource) | Gravedad de caída, límite de velocidad y frenado hasta él |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Detiene el cuerpo ante un desnivel o lo desliza a lo largo del borde |
| `stamina.gd` | `Stamina` (Node) | La reserva para el sprint |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Teclas de sprint y salto → el personaje |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Reproduce sonidos con las señales del personaje |
| `hand_sway.gd` | `HandSway` (Node) | Balancea un nodo de mano con los pasos |
| `character_hover.gd` | `CharacterHover` (Node3D) | Hace flotar el modelo, deslizarse por escaleras, oscilar e inclinarse; puede ralentizar la caída |
| `damped_spring.gd` | `DampedSpring` (RefCounted) | Resorte amortiguado de un valor para la inercia |
| `character_monitor.gd` | `CharacterMonitor` (Label) | Muestra el estado del personaje y sus últimos eventos como texto; puede registrar los eventos |
| `character_appearance.gd` | `CharacterAppearance` (Node) | Cambia el modelo en tiempo de ejecución |
| `stamina_bar.gd`, `stamina_bar.tscn` | `StaminaBar` (ProgressBar) | Una barra del HUD para `Stamina` |

Necesita `addons/iso_orbit/click_to_move`: el cuerpo lo controla un `NavigationMover`.

## Configuración

1. Copia esta carpeta y `click_to_move` en `res://addons/iso_orbit/`.
2. Arma el personaje:

   ```
   Player           CharacterBody3D con ground_character.gd
   ├── CollisionShape3D
   ├── Visual       Node3D; el modelo dentro mira hacia −Z
   ├── NavigationMover   de click_to_move
   ├── LedgeGuard   opcional
   └── Stamina      opcional
   ```

   Establece `mover`, `visual`, `ledge_guard` y `stamina` del cuerpo. La demo también activa `floor_constant_speed` en
   el cuerpo, para que el personaje conserve su velocidad en las rampas, y lo pone en la capa de física 2, aparte del
   nivel: colisiona con las capas 1 y 4 (nivel y paredes invisibles). `get_ground_height()` y, por defecto,
   `LedgeGuard` buscan suelo con la misma máscara. El cuerpo sube escalones de hasta `max_step_height` (0.3 m) y
   pendientes de hasta `floor_max_angle`. Para crear rutas por escaleras, hornea la malla con `agent_max_climb`
   igual a la altura deseada y prueba la ruta contra el colisionador real. Mantén `LedgeGuard.max_drop` al menos
   igual a `max_step_height` y `floor_snap_length` por debajo si necesitas `stair_taken` al bajar.
   El cuerpo puede empezar girado: solo gira `Visual` respecto al cuerpo y mira inicialmente hacia su eje −Z;
   después lo giras con `teleport(position, facing)` o `NavigationMover.face()`.
3. Para las teclas, agrega un `Node` con `character_action_input.gd` y establece su `character`. Necesita las
   acciones de entrada `sprint` y `jump`; si falta una, informa una vez al inicio y no vuelve a leerla.
4. Opcional: `CharacterSounds` con hijos `AudioStreamPlayer3D`, `HandSway` con `character` y el nodo de mano,
   `CharacterAppearance` con un `slot` y lista de modelos, `CharacterMonitor` en un `CanvasLayer` como panel de
   depuración. `LedgeGuard.floor_mask` vale 0 por defecto: toma la máscara del cuerpo y descarta superficies
   demasiado inclinadas para pisarlas.
5. Para flotar, inserta un `Node3D` con `character_hover.gd` entre `Visual` y el modelo (`Visual/Hover/Model`),
   y asígnalo como `slot` de `CharacterAppearance` si lo usas. Mientras flota, se suspenden los pasos y un `fall`
   asignado (recurso `FallSettings`) puede ralentizar la caída. Sube el modelo; cuerpo y colisionador no cambian.
6. Si lo necesitas, asigna un `FallSettings` al `fall` del cuerpo para definir su propia gravedad de descenso y
   velocidad máxima.

Los fallos de configuración se imprimen como advertencias al iniciar. `player.tscn` trae una cápsula de 1.8 m,
`floor_constant_speed` activado, protección de bordes, resistencia, recurso de caída flotante y flotación
**desactivada** al inicio. Su `NavigationMover` usa `player_locomotion.tres`; `SettingsApplier` puede aplicar
ajustes guardados al iniciar la demo. Para copiar el héroe jugable, consulta `docs/es/integration.md`; para
adaptar tu modelo y su colisión, `docs/es/systems/characters.md`.

Una IA puede controlar el mismo cuerpo: llama a `NavigationMover.move_to()` y `GroundCharacter.jump()`, y establece
`sprint_requested`.

## Documentación

En el repositorio de la plantilla: `docs/es/integration.md`, `docs/es/systems/locomotion.md`,
`docs/es/systems/input.md` (`CharacterActionInput`), `docs/es/systems/audio.md`,
`docs/es/systems/characters.md` y `docs/es/systems/levels.md` (teletransporte del héroe).

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
