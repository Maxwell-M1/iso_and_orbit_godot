<!-- translation of docs/en/architecture.md @ adf142a1b736 -->
# Arquitectura

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/architecture.md).
> Si hay diferencias, la versión en inglés es la correcta.

La demo comienza en `gdscript/main.tscn`, la escena principal que aloja nivel actual, héroe e interfaz. Cada
comportamiento es un nodo con una sola tarea: un
componente lee sus propias propiedades exportadas, expone métodos y señales, y se conecta con sus vecinos en la
escena mediante referencias a nodos y conexiones de señales. Las pocas búsquedas que quedan son configurables:
`DiscoveryToast` y la escena principal encuentran lugares por grupo; `LevelHost` encuentra los portales y puntos
de aparición de su nivel mediante grupos; `PointOfInterest` y `LevelPortal` reconocen al cuerpo del jugador por
el grupo `player` (`player_group`, `traveller_group`); `CharacterAppearance` encuentra modelo y mano por nombres
exportados; y `CharacterSounds`, con `character` vacío, toma a su padre.

## La escena principal

```
Main (Node3D, main.gd)   escena principal: conecta niveles, héroe e interfaz
├── Levels             LevelHost: nivel actual, cambiado tras la pantalla de carga
│   └── World          shared/world/world.tscn: nivel inicial, malla, lugares, PNJ y plataforma
├── Hero               gdscript/player/playable_hero.tscn: PlayableHero, héroe controlado por el jugador
│   ├── Character          gdscript/player/player.tscn: GroundCharacter, grupo "player"
│   │   ├── CollisionShape3D   cápsula de radio 0.35 m y altura 1.8 m
│   │   ├── Visual             orientado hacia el movimiento
│   │   │   └── Hover          CharacterHover: eleva el modelo; desactivado al inicio
│   │   │       └── Model      aspecto actual; RightHand sostiene el bastón
│   │   ├── Silhouette         OccludedSilhouette: visible a través de obstáculos
│   │   ├── Appearance         CharacterAppearance: cambia Visual/Hover/Model
│   │   ├── RightHandSway      HandSway: balancea la mano con los pasos
│   │   ├── NavigationMover    rutas y velocidad
│   │   ├── LedgeGuard         evita desniveles
│   │   ├── Stamina            reserva del sprint
│   │   └── Sounds             CharacterSounds y cinco AudioStreamPlayer3D
│   ├── PlayerInput        PointClickMoveInput: ratón y WASD → Character/NavigationMover
│   ├── PlayerActionInput  CharacterActionInput: Mayús y Espacio → Character
│   ├── CameraRig          OrbitCameraRig: sigue a Character, órbita y zoom
│   │   └── CameraArm      CameraArm: se acorta ante obstáculos
│   │       └── Camera3D
│   ├── ClickMarker        anillo en el suelo en un punto marcado por clic
│   └── PathView           NavigationPathView: línea de ruta, oculta por defecto
├── Hud                ayuda y velocidad, FpsCounter, CharacterState, DiscoveryToast, StaminaBar,
│                      TravelPrompt (invitación a viajar en una plataforma)
├── SettingsApplier    ajustes → propiedades de nodos (solo demo)
├── UiRoot             ventanas sobre el juego: ajustes
└── LoadingScreen      LoadingScreen: pantalla durante la carga de nivel
```

`player.tscn` contiene solo el personaje. La entrada está en `playable_hero.tscn`, de modo que una IA, una
secuencia cinemática u otro jugador en red también pueden dirigir el mismo personaje. El héroe es hermano del
host, no parte de un nivel: los niveles cambian a su alrededor. Consulta [Niveles](systems/levels.md).

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
     señales: state_changed, stepped, jumped, left_floor, touched_floor, landed, sprint_changed, stair_taken,
              teleported
                                                                   ▼
                    CharacterSounds, HandSway, CharacterHover, CharacterMonitor, animaciones y otros

mouse ──► OrbitCameraRig ──► CameraArm ──► Camera3D
          (sigue la posición interpolada del objetivo, órbita, zoom, seguimiento opcional)

LevelPortal ──traveller_entered──► LevelHost ──portal_entered──► main.gd ──► TravelPrompt
     ▲                                  │                                       │ E o clic
     └───────────── travel() ───────────┼─────────── main.gd ◄── confirmed ─────┘
                                        ▼
    change_level(): pausa, LoadingScreen, carga, intercambio ──level_loaded──► main.gd ──► PlayableHero.place_at()
```

La entrada nunca toca el cuerpo. Envía órdenes al `NavigationMover`. El componente de movimiento tampoco lo
toca: devuelve una
velocidad cuando el cuerpo se la pide. La cámara y la entrada no saben nada la una de la otra.

## Un tick de física

1. `CharacterActionInput` se ejecuta antes que el personaje (`process_physics_priority = -1`): establece
   `GroundCharacter.sprint_requested` y llama a `jump()`, así una pulsación de tecla llega al cuerpo en el mismo tick.
2. `GroundCharacter._physics_process`, el único lugar donde se mueve el cuerpo:
   1. decide si el personaje esprinta (pedido, permitido, en movimiento, no agotado) y gasta resistencia;
   2. llama a `mover.compute_velocity(delta)` y toma su X y su Z como velocidad horizontal;
   3. inicia un salto si hay uno en el búfer y el cuerpo está en el suelo o acaba de dejarlo (tiempo de coyote);
   4. aplica gravedad en el aire: el ascenso del salto frena según `gravity_scale`, y el descenso sigue la
      configuración activa (`get_fall_settings()`);
   5. deja que `LedgeGuard.constrain()` gire la velocidad en un borde, salvo al saltar, y mide la aceleración
      de la velocidad ordenada (`get_local_acceleration()`);
   6. llama a `move_and_slide()`, subiendo a un escalón antes y bajando un escalón después (`max_step_height`);
   7. emite `left_floor`, `touched_floor`, `landed`, `stair_taken` y `stepped`, gira `Visual` hacia
      `mover.get_facing()` y, si el
      estado cambió, emite `state_changed`.
3. `HandSway` y `CharacterHover` se ejecutan después del cuerpo (`process_physics_priority = 1`) y mueven
   mano y modelo según su nuevo estado.

`PointClickMoveInput._physics_process` decide en un solo lugar quién controla al personaje: un botón del mouse
mantenido o, si no, las teclas con el botón derecho. Llama a `move_to()`, `steer()` o `stop()`.
El componente de movimiento guarda la
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
| `orbit_camera` | `OrbitCameraRig` (Node3D) | Sigue un objetivo, orbita con derecho y cambia zoom con rueda; opcionalmente gira tras la carrera y alinea inclinación y altura con suavidad |
| | `CameraArm` (Node3D) | Sostiene la cámara en su extremo y se acorta ante los obstáculos; desvanece al objetivo de cerca |
| `click_to_move` | `LocomotionSettings` (Resource) | Velocidad, aceleración, frenado y giro. Varios personajes pueden compartir un mismo recurso |
| | `GroundMotion` (RefCounted) | Cinemática sin nodos: dirección deseada y distancia restante → velocidad horizontal |
| | `NavigationMover` (Node) | `move_to()` por una ruta de navegación con parada exacta, `steer()` en una dirección, `stop()`; devuelve una velocidad, nunca mueve el cuerpo |
| | `PointClickMoveInput` (Node) | Mouse y clic derecho + WASD → órdenes al componente de movimiento; oculta el cursor y le reajusta la mira |
| | `ClickMarker` (Node3D) | El marcador en el punto del clic (`click_marker.tscn`) |
| | `NavigationPathView` (MeshInstance3D) | Dibuja la ruta restante del componente de movimiento |
| `ground_character` | `GroundCharacter` (CharacterBody3D) | Gravedad, salto, sprint con resistencia, escalones, `move_and_slide()`, giro del modelo; informa de su estado, pasos, despegues y aterrizajes para animaciones, sonidos y la interfaz |
| | `FallSettings` (Resource) | Gravedad de caída, velocidad máxima y frenado hasta ella. Puede compartirse entre personajes |
| | `LedgeGuard` (Node) | Detiene el cuerpo ante un desnivel o lo desliza a lo largo del borde |
| | `Stamina` (Node) | Una reserva que se gasta y se recupera; no sabe nada de qué la gasta |
| | `CharacterActionInput` (Node) | Teclas de sprint y salto → el personaje |
| | `CharacterSounds` (Node3D) | Reproduce sonidos a partir de las señales del personaje |
| | `HandSway` (Node) | Balancea un nodo de mano con los pasos, con inercia en arranques, paradas, giros y aterrizajes |
| | `CharacterHover` (Node3D) | Hace flotar el modelo: lo desliza por escalones, oscila e inclina; suspende pasos y puede frenar la caída |
| | `DampedSpring` (RefCounted) | Resorte amortiguado para un valor; aporta inercia a `HandSway` y `CharacterHover` |
| | `CharacterMonitor` (Label) | Muestra el estado del personaje y sus últimos eventos como texto; puede escribir los eventos en la salida |
| | `CharacterAppearance` (Node) | Cambia el modelo del personaje en tiempo de ejecución |
| | `StaminaBar` (ProgressBar) | La barra de resistencia del HUD (`stamina_bar.tscn`) |
| `occluded_silhouette` | `OccludedSilhouette` (Node) | Dibuja el personaje como silueta donde algo lo oculta; sus shaders y materiales están en la misma carpeta |
| `points_of_interest` | `PointOfInterest` (Area3D) | Un lugar por descubrir: emite `discovered(title)` la primera vez que entra el jugador |
| | `DiscoveryToast` (Label) | "Lugar descubierto: …" en pantalla durante unos segundos (`discovery_toast.tscn`) |
| `ui_screens` | `UiRoot` (CanvasLayer) | Una pila de ventanas: abrir, cerrar la de arriba con Esc, pausa, cursor, foco del teclado |
| | `UiScreen` (Control) | Base de una ventana: `initial_focus`, `close_requested` |
| | `FpsCounter` (Label) | Fotogramas por segundo, también en pausa (`fps_counter.tscn`) |
| | `InputNames` (RefCounted) | Nombres de teclas asignadas a acciones para los textos: `{sprint}` → «Mayús» |
| | `ActionTexts` (Node) | Inserta esos nombres en los textos de controles, también al cambiar de idioma |
| `levels` | `LevelHost` (Node3D) | Aloja el nivel actual y lo cambia tras la pantalla de carga: carga en segundo plano, intercambio, mapa de navegación y calentamiento; informa cada paso |
| | `LevelPortal` (Area3D) | Paso a otro nivel: detecta un viajero y viaja con `travel()` o automáticamente |
| | `SpawnPoint` (Marker3D) | Punto de aparición con nombre |
| | `LoadingScreen` (CanvasLayer) | Último fotograma desenfocado, nombre del lugar, progreso y consejos (`loading_screen.tscn`) |

`ground_character` necesita `click_to_move` (el cuerpo controla un `NavigationMover`); los demás addons solo
necesitan el motor. Qué espera cada uno del proyecto: [Uso en tu proyecto](integration.md).

La demo en `gdscript/` los ensambla:

| Archivo | Tarea |
|---|---|
| `main.tscn`, `main.gd` | Escena principal: host con nivel inicial, héroe, interfaz y pantalla de carga; `main.gd` los conecta |
| `player/player.tscn`, `player_locomotion.tres` | Personaje del héroe: `GroundCharacter` con sus partes y recurso de movimiento |
| `player/playable_hero.tscn`, `.gd` | `PlayableHero`: personaje, entrada, cámara, marcador y línea de ruta listos para una escena de juego |
| `ui/travel_prompt.tscn`, `.gd` | `TravelPrompt`: invitación a viajar en una plataforma, con tecla y nombre del lugar |
| `demo/hud.gd` | La ayuda de controles y el indicador de velocidad |
| `demo/settings_applier.gd` | Aplica la configuración a los nodos de la demo, un único lugar para "opción → propiedad" |
| `settings/game_settings.gd` | `GameSettings`, el autoload `Settings`: valores por defecto, `user://settings.cfg`, la señal `changed`; aplica él mismo los ajustes del motor |
| `ui/ui_root.tscn` | `UiRoot` con la ventana de configuración y F10 |
| `ui/settings/settings_screen.tscn`, `.gd` | La ventana de configuración |
| `ui/settings/setting_*.gd` | `SettingCheckButton`, `SettingOptionButton`, `SettingSlider`, `SettingLanguageButton`: controles vinculados a una clave de configuración |

Cada sistema tiene su propia página: [Locomoción](systems/locomotion.md), [Cámara](systems/camera.md),
[Entrada](systems/input.md), [Personajes](systems/characters.md), [Audio](systems/audio.md),
[Interfaz de usuario](systems/ui.md), [Mundo y navegación](systems/world-and-navigation.md) y
[Niveles](systems/levels.md).

## Conexiones hechas en la escena

Las referencias de nodos son propiedades exportadas establecidas en `main.tscn`, `playable_hero.tscn` y
`player.tscn`. Las conexiones de señales de `playable_hero.tscn` son:

| Señal | Conectada a | Efecto |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | El marcador aparece en el punto del clic |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | Una pulsación mantenida reemplaza al clic, el marcador se desvanece |
| `Character/NavigationMover.arrived` | `ClickMarker.fade_out` | El personaje llegó al punto |
| `Character/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | Se abandonó el punto |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | La cámara no gira por sí sola hasta que se sabe si una pulsación es un clic o una pulsación mantenida |
| `PlayerInput.run_requested` | `CameraRig.end_follow_wait` | Una carrera nueva: la cámara deja de esperar tras una órbita y vuelve a seguir |

`main.gd` conecta el host y la invitación a viajar mediante código; consulta
[Niveles](systems/levels.md#la-escena-principal).

## Configuración

El autoload `Settings` (`GameSettings`) guarda los valores y emite `changed(key, value)`. Aplica él mismo los ajustes a
nivel de motor: pantalla completa, límite de fotogramas, V-Sync, interpolación de física, escala de la interfaz, idioma
y volumen. Todo lo demás lo aplica `gdscript/demo/settings_applier.gd`, que asigna cada clave a una propiedad de nodo.
Los propios componentes nunca leen la configuración, ver [Configuración](settings.md).

## Por qué está construido así

- **Solo `GroundCharacter` mueve el cuerpo.** Los componentes de movimiento devuelven una velocidad y nunca llaman a
  `move_and_slide()`. La gravedad, los saltos y cualquier empuje futuro se combinan en un solo lugar y no pueden
  entrar en conflicto.
- **`GroundMotion` es matemática sin nodos.** La aceleración y el frenado son una función pura del estado: fácil de
  probar por separado y de portar a otro lenguaje línea por línea.
- **El personaje no sabe nada del ratón.** Se convierte en jugador porque `PlayerInput`, en la escena del héroe
  jugable (`playable_hero.tscn`), controla su movimiento. Para un PNJ, instancia `player.tscn` sin `Silhouette` y
  `Appearance`, que
  son solo del jugador, y llama a `NavigationMover.move_to()` desde tu IA.
- **El héroe es hermano del host de niveles, no parte de un nivel.** Un nivel contiene mundo, suelo, objetos,
  navegación, luz y portales. Héroe, cámara e interfaz permanecen durante los cambios: el nivel nuevo no necesita
  copiarlos y el héroe conserva resistencia y altura de cámara.
- **El host no conoce al héroe.** Comunica cada paso con señales y la escena principal coloca al héroe donde
  indica el nuevo nivel. El héroe también funciona sin el host.
- **La cámara es hermana del personaje, no su hija.** Se mueve en `_process` a la posición interpolada del objetivo y no
  se interpola ella misma, así que con la interpolación de física (activada por defecto, Configuración → Pantalla) la
  carrera se ve fluida a cualquier tasa de fotogramas. Para el modo de seguimiento, la cámara calcula la velocidad del
  objetivo a partir de su movimiento por tick de física, así que cualquier `Node3D` sirve como objetivo. Del
  mismo movimiento distingue un giro brusco de una curva para que un cambio de sentido no la arrastre. Sus
  resortes se calculan en pasos breves y se comportan igual a cualquier frecuencia de fotogramas.
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
| `shared/` | Contenido independiente del lenguaje: niveles, personajes y equipo, shaders y texturas, sonidos y tema de interfaz |
| `l10n/` | Traducciones de la interfaz |
| `tests/` | Pruebas headless, ver [Pruebas](testing.md) |
| `docs/` | Esta documentación |

`shared/` está pensado para que lo reutilice una futura versión en C# de la demo, que tendría su propia carpeta junto
a `gdscript/`. Quedan dos excepciones: niveles y plataforma usan scripts de los componentes (`world.tscn`,
`island.tscn` y `mountain.tscn` usan `point_of_interest.gd`; niveles, `spawn_point.gd`; y `teleport_pad.tscn`,
`level_portal.gd`). Dos scripts pequeños de objetos (`flicker.gd`, `hover_spin.gd`) están en
`shared/world/props/`. Consulta [Problemas conocidos](known-issues.md).

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
