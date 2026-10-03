<!-- translation of docs/en/architecture.md @ 8409307c5782 -->
# Arquitectura

> Esta es una traducción del [original en inglés](../en/architecture.md).
> Si hay diferencias, la versión en inglés es la correcta.

La demo es una sola escena, `gdscript/main.tscn`. Cada comportamiento es un nodo separado con una sola tarea: un
componente lee sus propias propiedades exportadas, expone métodos y señales, y se conecta con sus vecinos en la
escena mediante referencias a nodos y conexiones de señales. Las pocas búsquedas que quedan son configurables:
`DiscoveryToast` encuentra los lugares por grupo, `CharacterAppearance` encuentra el modelo y su mano por nombres
exportados, y `CharacterSounds` con la propiedad `character` vacía toma a su padre.

## La escena principal

```
Main (Node3D)
├── World              shared/world/world.tscn: el nivel, su malla de navegación, lugares y NPC
├── Player             gdscript/player/player.tscn: GroundCharacter, grupo "player"
│   ├── CollisionShape3D   cápsula, radio 0.35 m, altura 1.8 m
│   ├── Visual             girado hacia donde va el personaje
│   │   └── Model          el aspecto actual del héroe; su RightHand sostiene el bastón
│   ├── Silhouette         OccludedSilhouette: el héroe visto a través de los obstáculos
│   ├── Appearance         CharacterAppearance: cambia Visual/Model en tiempo de ejecución
│   ├── RightHandSway      HandSway: balancea la mano derecha con los pasos
│   ├── NavigationMover    rutas y velocidad
│   ├── LedgeGuard         evita que el cuerpo salga caminando por un desnivel
│   ├── Stamina            reserva para el sprint
│   └── Sounds             CharacterSounds y cinco AudioStreamPlayer3D
├── PlayerInput        PointClickMoveInput: mouse y WASD → Player/NavigationMover
├── PlayerActionInput  CharacterActionInput: Shift y Space → Player
├── CameraRig          OrbitCameraRig: sigue a Player, órbita y zoom
│   └── CameraArm      CameraArm: se acorta ante los obstáculos
│       └── Camera3D
├── ClickMarker        el anillo en el suelo en el punto del clic
├── PathView           NavigationPathView: la línea de ruta de depuración, oculta por defecto
├── Hud                ayuda de controles y velocidad, FpsCounter, DiscoveryToast, StaminaBar
├── SettingsApplier    configuración → propiedades de nodos (solo en la demo)
└── UiRoot             ventanas sobre el juego: la ventana de configuración
```

`player.tscn` contiene solo el personaje. Los nodos de entrada viven en `main.tscn`, así que la misma escena de
personaje puede ser controlada por otra cosa: una IA, una cinemática o un par de red.

## Flujo de datos

```
mouse, WASD ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (ruta o             (aceleración, frenado,
                                    ──stop()────────────►  dirección)          giro: matemática simple)
                                                               ▲
                                                               │ compute_velocity(delta)
                                                               │ devuelve una velocidad horizontal
Shift, Space ──► CharacterActionInput ──sprint_requested──► GroundCharacter ──► LedgeGuard.constrain()
                                      ──jump()────────────►  (CharacterBody3D)  ──► move_and_slide()
                                                                   │
                                     señales: stepped, jumped, landed, sprint_changed
                                                                   ▼
                                                   CharacterSounds, HandSway, cualquier otra cosa

mouse ──► OrbitCameraRig ──► CameraArm ──► Camera3D
          (sigue la posición interpolada del objetivo, órbita, zoom, seguimiento opcional)
```

La entrada nunca toca el cuerpo. Envía órdenes al `NavigationMover`. El movedor tampoco toca el cuerpo: devuelve una
velocidad cuando el cuerpo se la pide. La cámara y la entrada no saben nada la una de la otra.

## Un tick de física

1. `CharacterActionInput` se ejecuta antes que el personaje (`process_physics_priority = -1`): establece
   `GroundCharacter.sprint_requested` y llama a `jump()`, así una pulsación de tecla llega al cuerpo en el mismo tick.
2. `GroundCharacter._physics_process`, el único lugar donde se mueve el cuerpo:
   1. decide si el personaje esprinta (pedido, permitido, en movimiento, no agotado) y gasta resistencia;
   2. llama a `mover.compute_velocity(delta)` y toma su X y su Z como velocidad horizontal;
   3. inicia un salto si hay uno en el búfer y el cuerpo está en el suelo o acaba de dejarlo (tiempo de coyote);
   4. suma la gravedad multiplicada por `gravity_scale` en el aire;
   5. deja que `LedgeGuard.constrain()` gire la velocidad a lo largo de un borde, salvo que el personaje esté
      saltando;
   6. llama a `move_and_slide()`;
   7. emite `landed` y `stepped`, y gira `Visual` hacia `mover.get_facing()`.
3. `HandSway` se ejecuta después del cuerpo (`process_physics_priority = 1`) y mueve la mano según el nuevo estado
   del cuerpo.

`PointClickMoveInput._physics_process` decide en un solo lugar quién controla al personaje: un botón del mouse
mantenido o, si no, las teclas con el botón derecho. Llama a `move_to()`, `steer()` o `stop()`. El movedor guarda la
última orden, y el cuerpo la recoge la próxima vez que llama a `compute_velocity()`.

En cada fotograma renderizado, `OrbitCameraRig._process` coloca el rig en la transformación interpolada del objetivo
y su hijo `CameraArm` se actualiza justo después. `PointClickMoveInput` tiene `process_priority = 1`, así que corrige
la posición del cursor después de que la cámara se haya asentado en ese fotograma.

## Componentes

Los componentes reutilizables están en `addons/iso_orbit/`, una carpeta por cada parte que se puede tomar por
separado. Cada script lleva el nombre de su clase en snake case: `OrbitCameraRig` es
`addons/iso_orbit/orbit_camera/orbit_camera_rig.gd`.

| Addon | Clase | Tarea |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig` (Node3D) | Sigue a un objetivo, orbita con el clic derecho, hace zoom con la rueda y, opcionalmente, gira tras la carrera |
| | `CameraArm` (Node3D) | Sostiene la cámara en su extremo y se acorta ante los obstáculos; desvanece al objetivo de cerca |
| `click_to_move` | `LocomotionSettings` (Resource) | Velocidad, aceleración, frenado y giro. Varios personajes pueden compartir un mismo recurso |
| | `GroundMotion` (RefCounted) | Cinemática sin nodos: dirección deseada y distancia restante → velocidad horizontal |
| | `NavigationMover` (Node) | `move_to()` por una ruta de navegación con parada exacta, `steer()` en una dirección, `stop()`; devuelve una velocidad, nunca mueve el cuerpo |
| | `PointClickMoveInput` (Node) | Mouse y clic derecho + WASD → órdenes al movedor; oculta el cursor y le reajusta la mira |
| | `ClickMarker` (Node3D) | El marcador en el punto del clic (`click_marker.tscn`) |
| | `NavigationPathView` (MeshInstance3D) | Dibuja la ruta restante del movedor |
| `ground_character` | `GroundCharacter` (CharacterBody3D) | Gravedad, salto, sprint con resistencia, `move_and_slide()`, giro del modelo; señales de pasos, saltos, aterrizajes y sprint |
| | `LedgeGuard` (Node) | Detiene el cuerpo ante un desnivel o lo desliza a lo largo del borde |
| | `Stamina` (Node) | Una reserva que se gasta y se recupera; no sabe nada de qué la gasta |
| | `CharacterActionInput` (Node) | Teclas de sprint y salto → el personaje |
| | `CharacterSounds` (Node3D) | Reproduce sonidos a partir de las señales del personaje |
| | `HandSway` (Node) | Balancea un nodo de mano con los pasos, con inercia en arranques, paradas, giros y aterrizajes |
| | `CharacterAppearance` (Node) | Cambia el modelo del personaje en tiempo de ejecución |
| | `StaminaBar` (ProgressBar) | La barra de resistencia del HUD (`stamina_bar.tscn`) |
| `occluded_silhouette` | `OccludedSilhouette` (Node) | Dibuja el personaje como silueta donde algo lo oculta; sus shaders y materiales están en la misma carpeta |
| `points_of_interest` | `PointOfInterest` (Area3D) | Un lugar por descubrir: emite `discovered(title)` la primera vez que entra el jugador |
| | `DiscoveryToast` (Label) | "Lugar descubierto: …" en pantalla durante unos segundos (`discovery_toast.tscn`) |
| `ui_screens` | `UiRoot` (CanvasLayer) | Una pila de ventanas: abrir, cerrar la de arriba con Esc, pausa, cursor, foco del teclado |
| | `UiScreen` (Control) | Base de una ventana: `initial_focus`, `close_requested` |
| | `FpsCounter` (Label) | Fotogramas por segundo, también en pausa (`fps_counter.tscn`) |

`ground_character` necesita `click_to_move` (el cuerpo controla un `NavigationMover`); los demás addons solo
necesitan el motor. Qué espera cada uno del proyecto: [Uso en tu proyecto](integration.md).

La demo en `gdscript/` los ensambla:

| Archivo | Tarea |
|---|---|
| `main.tscn` | La escena de la demo |
| `player/player.tscn`, `player_locomotion.tres` | El héroe: un `GroundCharacter` con todas sus partes, y su configuración de carrera |
| `demo/hud.gd` | La ayuda de controles y el indicador de velocidad |
| `demo/settings_applier.gd` | Aplica la configuración a los nodos de la demo, un único lugar para "opción → propiedad" |
| `settings/game_settings.gd` | `GameSettings`, el autoload `Settings`: valores por defecto, `user://settings.cfg`, la señal `changed`; aplica él mismo los ajustes del motor |
| `ui/ui_root.tscn` | `UiRoot` con la ventana de configuración y F10 |
| `ui/settings/settings_screen.tscn`, `.gd` | La ventana de configuración |
| `ui/settings/setting_*.gd` | `SettingCheckButton`, `SettingOptionButton`, `SettingSlider`, `SettingLanguageButton`: controles vinculados a una clave de configuración |

Cada sistema tiene su propia página: [Locomoción](systems/locomotion.md), [Cámara](systems/camera.md),
[Entrada](systems/input.md), [Personajes](systems/characters.md), [Audio](systems/audio.md),
[Interfaz de usuario](systems/ui.md), [Mundo y navegación](systems/world-and-navigation.md).

## Conexiones hechas en la escena

Las referencias a nodos son propiedades exportadas establecidas en `main.tscn` y `player.tscn`. Las conexiones de
señales en `main.tscn`:

| Señal | Conectada a | Efecto |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | El marcador aparece en el punto del clic |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | Una pulsación mantenida reemplaza al clic, el marcador se desvanece |
| `Player/NavigationMover.arrived` | `ClickMarker.fade_out` | El personaje llegó al punto |
| `Player/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | Se abandonó el punto |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | La cámara no gira por sí sola hasta que se sabe si una pulsación es un clic o una pulsación mantenida |

## Configuración

El autoload `Settings` (`GameSettings`) guarda los valores y emite `changed(key, value)`. Aplica él mismo los ajustes
a nivel de motor: límite de fotogramas, V-Sync, interpolación de física, escala de la interfaz, idioma y volumen. Todo
lo demás lo aplica `gdscript/demo/settings_applier.gd`, que asigna cada clave a una propiedad de nodo. Los propios
componentes nunca leen la configuración, ver [Configuración](settings.md).

## Por qué está construido así

- **Solo `GroundCharacter` mueve el cuerpo.** Los componentes de movimiento devuelven una velocidad y nunca llaman a
  `move_and_slide()`. La gravedad, los saltos y cualquier empuje futuro se combinan en un solo lugar y no pueden
  entrar en conflicto.
- **`GroundMotion` es matemática sin nodos.** La aceleración y el frenado son una función pura del estado: fácil de
  probar por separado y de portar a otro lenguaje línea por línea.
- **El personaje no sabe nada del mouse.** Se convierte en el personaje del jugador porque `PlayerInput`, en la escena
  principal, controla su movedor. Para un NPC, instancia `player.tscn` sin los nodos `Silhouette` y `Appearance`, que
  son solo del jugador, y llama a `NavigationMover.move_to()` desde tu IA.
- **La cámara es hermana del personaje, no su hija.** Se mueve en `_process` a la posición interpolada del objetivo y
  no se interpola ella misma, así que con la interpolación de física activada (Configuración → Pantalla) la carrera se
  ve fluida a cualquier tasa de fotogramas. Para el modo de seguimiento, la cámara calcula la velocidad del objetivo a
  partir de su movimiento por tick de física, así que cualquier `Node3D` sirve como objetivo.
- **Los componentes no saben nada de la configuración.** `LedgeGuard`, `PointClickMoveInput`, `OrbitCameraRig` y los
  demás leen sus propias propiedades; solo `settings_applier.gd` y la ventana de configuración hablan con el autoload
  `Settings`. Un componente pasa a otro proyecto sin el sistema de configuración.
- **Las ventanas siguen las convenciones de Godot.** El diseño usa solo contenedores; el aspecto viene del tema del
  proyecto y sus variaciones de tipo, no de overrides en cada nodo. Una ventana pide que la cierren con una señal y
  `UiRoot` la cierra (las llamadas bajan por el árbol, las señales suben). Las teclas son acciones de entrada. El foco
  del teclado se establece al abrir una ventana y se restaura al cerrarla. Mientras hay una ventana abierta el juego
  está en pausa (`UiRoot` se ejecuta en `PROCESS_MODE_ALWAYS`) y la cámara libera el cursor capturado.

## Carpetas

| Carpeta | Contenido |
|---|---|
| `addons/iso_orbit/` | Los componentes reutilizables, una carpeta por parte |
| `gdscript/` | La demo en GDScript: la escena principal, el héroe, el sistema y la ventana de configuración, la ayuda del HUD |
| `shared/` | Contenido de la demo que no depende del lenguaje de scripting: el nivel, los personajes y el equipo, los shaders y las texturas del mundo, los sonidos, el tema de la UI |
| `l10n/` | Traducciones de la interfaz |
| `tests/` | Pruebas headless, ver [Pruebas](testing.md) |
| `docs/` | Esta documentación |

`shared/` está pensado para que lo reutilice una futura versión en C# de la demo, que tendría su propia carpeta junto
a `gdscript/`. Por ahora quedan dos excepciones: `world.tscn` y `mountain.tscn` usan
`addons/iso_orbit/points_of_interest/point_of_interest.gd`, y dos pequeños scripts de props (`flicker.gd`,
`hover_spin.gd`) viven en `shared/world/props/`. Ver [Problemas conocidos](known-issues.md).

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
