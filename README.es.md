<!-- translation of README.md @ ed3c07c99517 -->
# Iso & Orbit - Plantilla de cámara y controlador de personaje

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Versión 1.0.0 · Godot 4.7 (probado en 4.7.2) · GDScript · MIT

Un controlador de personaje con movimiento por clic y una cámara orbital para RPG isométricos y cenitales. Haz clic
en el suelo y el héroe corre hasta allí, rodeando los obstáculos; mantén el botón y el héroe sigue al cursor. La
cámara orbita, hace zoom y no se mete en las paredes.

![Clic para moverse, mantener para dirigir, orbitar la cámara y hacer zoom, descubrir un lugar](docs/images/demo.gif)

Sin assets de terceros: un script construye los personajes con primitivas, los patrones de las superficies se generan
con shaders y se hornean en texturas sin costuras, y los sonidos son sintetizados.

## Primeros pasos

1. Instala Godot 4.7.2, la versión estándar o la .NET. Jolt Physics viene integrado en el motor, no hay nada que
   instalar. El renderizador es Forward+.
2. Clona el repositorio, importa `project.godot` en el Administrador de Proyectos (Project Manager) y ábrelo. La
   primera importación tarda un poco, ya que `.godot/` no está en el repositorio.
3. Presiona F5 para ejecutar la demo (`res://gdscript/main.tscn`).

Los controles aparecen en la esquina superior izquierda. Para ocultarlos, abre Configuración (F10) → Interfaz y
desactiva **Ayuda de controles y velocidad**. El idioma de la interfaz se elige en la misma pestaña.

## Controles

| Entrada | Acción |
|---|---|
| Clic izquierdo en el suelo | Correr hasta ese punto |
| Mantener el botón izquierdo | Correr tras el cursor |
| Botón izquierdo + derecho | Correr hacia donde mira la cámara; A / D desvían en diagonal |
| Botón derecho + mouse | Orbitar la cámara |
| Botón derecho + WASD | Moverse según la cámara |
| Rueda del mouse | Zoom: más abajo y más cerca, o más arriba y más lejos |
| Shift | Sprint mientras se mantiene (o alternar, en la configuración) |
| Espacio | Saltar |
| F10 | Abrir la configuración (pausa el juego); Esc o F10 la cierra |

Todos los modos y sus opciones: [Controles](docs/es/controls.md).

## Características

**Movimiento**

- Clic para correr hasta un punto por la malla de navegación; un marcador indica dónde.
- Mantén el botón izquierdo para correr tras el cursor: por defecto directo hacia él, deslizándose junto a los
  obstáculos; opcionalmente por una ruta de navegación hasta el punto bajo el cursor.
- Un clic y una pulsación mantenida se distinguen a los 0,2 s, así que mantener el botón nunca manda al héroe a dar
  un rodeo hasta el punto donde presionaste.
- Ambos botones a la vez: correr hacia donde mira la cámara. Botón derecho y WASD: moverse según la cámara, mirando
  al frente o girando hacia donde vas.
- Aceleración y frenado constantes, parada exacta en el objetivo sin pasarse, velocidad de giro limitada y giro
  instantáneo desde parado.
- Sprint con resistencia. Salto con tiempo de coyote y búfer de entrada; la altura del salto es la misma con
  cualquier frecuencia de ticks de física.
- Protección de bordes: al borde de un desnivel el héroe se detiene o se desliza a lo largo de él, como junto a una
  pared.

**Cámara**

- Se orbita con el botón derecho y se hace zoom con la rueda. La distancia y la inclinación cambian juntas: cuanto más
  cerca está la cámara, más bajo es su ángulo, así ves lo que hay delante.
- Opcionalmente gira tras el héroe que corre y lleva suavemente su inclinación a un ángulo fijado.
- Mientras la cámara gira, el cursor se queda sobre el mismo punto del suelo, así un botón mantenido conserva el
  rumbo del héroe en vez de hacerlo correr en círculos.
- Un brazo de cámara: la cámara se detiene ante una pared, una montaña o un techo que tenga detrás y, opcionalmente,
  se acerca cuando un obstáculo oculta al héroe. De cerca, el héroe se vuelve translúcido.
- Detrás de los obstáculos el héroe se ve como una sola silueta con contorno, con el equipo que lleva en la mano
  dibujado encima.

**También incluye**

- Una ventana de configuración (F10) con pestañas de controles, personaje, cámara, pantalla, interfaz y sonido, que
  se guarda en `user://settings.cfg`. La interfaz está en inglés, español, japonés, portugués de Brasil, ruso, turco
  y chino simplificado, y el idioma se cambia al vuelo.
- Señales del personaje para pasos, saltos, aterrizajes y sprint, con sonidos conectados a ellas.
- Un nivel de demo: un claro cercado de 80 × 80 m con ruinas, un campamento, una granja, un laberinto de setos, una
  rampa y una montaña con un sendero en espiral. Cuatro lugares por descubrir con cinco NPC apostados en ellos, y diez
  aspectos de héroe para elegir.
- Pruebas headless de movimiento, entrada, salto, sprint y sonidos, de la cámara y su brazo, de los aspectos del
  héroe, de la ventana de configuración y de las traducciones, y un script que encuentra las advertencias de nodos
  del editor en todas las escenas sin abrir el editor.

**No incluye:** soporte para gamepad (solo mouse y teclado) ni animaciones: los modelos son primitivas estáticas.

## Cómo encaja todo

```
mouse, WASD ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (ruta o             (aceleración, frenado,
                                                           dirección)          giro: matemática simple)
                                                               │ velocidad
                                                               ▼
Shift, Space ──► CharacterActionInput ──────────────────► GroundCharacter
                                                          (CharacterBody3D: gravedad, salto, sprint,
                                                           move_and_slide, giro del modelo)

mouse ──► OrbitCameraRig ──► CameraArm ──► Camera3D
```

- **Solo `GroundCharacter` mueve el cuerpo.** Los componentes de movimiento devuelven una velocidad y nunca llaman a
  `move_and_slide()`, así que la gravedad, los saltos y cualquier empuje futuro se combinan en un solo lugar.
- **`GroundMotion` es matemática sin nodos**, fácil de probar por separado.
- **El personaje no sabe nada del mouse.** Los nodos de entrada viven en `main.tscn`, no en `player.tscn`. Para un
  NPC, instancia `player.tscn` sin los nodos `Silhouette` y `Appearance`, que son solo del jugador, y llama a
  `NavigationMover.move_to()` desde tu IA.
- **Los componentes no saben nada de la configuración.** Leen sus propias propiedades exportadas. Solo
  `settings_applier.gd` de la demo y la ventana de configuración hablan con el autoload `Settings`, así que un
  componente pasa a otro proyecto sin ellos.

Detalles: [Arquitectura](docs/es/architecture.md).

## Uso en tu proyecto

Los componentes están en `addons/iso_orbit/`, una carpeta por parte; copia las que necesites en la misma carpeta de
tu proyecto:

| Addon | Qué ofrece |
|---|---|
| `orbit_camera` | La cámara orbital y su brazo; funciona con cualquier objetivo `Node3D` |
| `click_to_move` | Clic y pulsación mantenida para moverse por la malla de navegación, movimiento dirigido, el marcador de clic |
| `ground_character` | El cuerpo listo para usar: gravedad, salto, sprint con resistencia, protección de bordes, señales de pasos, sonidos, el balanceo de la mano, modelos intercambiables (requiere `click_to_move`) |
| `occluded_silhouette` | La silueta del personaje detrás de los obstáculos |
| `points_of_interest` | Lugares por descubrir y el mensaje sobre ellos |
| `ui_screens` | Una pila de ventanas que pausa el juego, y un contador de FPS |

El movimiento funciona como una cadena: la entrada da órdenes a un `NavigationMover`, y el movedor solo calcula una
velocidad, que el cuerpo al que pertenece aplica en cada tick de física. `GroundCharacter` es el cuerpo listo para
usar; uno mínimo se ve así:

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
```

Llama a `mover.move_to(point)` o `mover.steer(direction)` desde donde quieras: tu propia entrada, IA o código de red.
[Uso en tu proyecto](docs/es/integration.md) indica qué necesita cada addon, y
[Preparación del proyecto](docs/es/project-setup.md) enumera las capas de física, las acciones de entrada y los
grupos que los componentes esperan de `project.godot`.

## Documentación

- **Inicio:** [Primeros pasos](docs/es/getting-started.md) · [Controles](docs/es/controls.md) ·
  [Configuración](docs/es/settings.md)
- **Código:** [Arquitectura](docs/es/architecture.md) · [Uso en tu proyecto](docs/es/integration.md) ·
  [Preparación del proyecto](docs/es/project-setup.md)
- **Sistemas:** [Locomoción](docs/es/systems/locomotion.md) · [Cámara](docs/es/systems/camera.md) ·
  [Entrada](docs/es/systems/input.md) · [Personajes](docs/es/systems/characters.md) ·
  [Audio](docs/es/systems/audio.md) · [Interfaz de usuario](docs/es/systems/ui.md) ·
  [Mundo y navegación](docs/es/systems/world-and-navigation.md)
- **Mantenimiento:** [Pruebas](docs/es/testing.md) · [Problemas conocidos](docs/es/known-issues.md) ·
  [Glosario](docs/es/glossary.md) · [Hoja de ruta](docs/es/roadmap.md)

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `addons/iso_orbit/` | Los componentes, una carpeta por cada parte que puedes tomar por separado |
| `gdscript/` | La demo que los ensambla: `main.tscn`, el héroe, el sistema y la ventana de configuración |
| `shared/` | Contenido de la demo pensado para compartirse entre la demo en GDScript y una futura en C#: el nivel, los personajes y el equipo, los shaders y las texturas del mundo, los sonidos, el tema de la UI. Aquí también viven dos pequeños scripts GDScript que usa el nivel |
| `l10n/` | Traducciones de la interfaz (gettext `.po`) |
| `tests/` | Pruebas headless |
| `docs/` | Documentación |

## Pruebas

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Aquí `godot` es tu ejecutable de Godot 4.7.2; en Windows usa la compilación `_console.exe` para ver la salida y
obtener el código de salida. Para ejecutar solo algunas suites, agrega partes de sus nombres después de `--`, por
ejemplo `-- camera input`. El código de salida es 1 si falla alguna comprobación. Detalles:
[Pruebas](docs/es/testing.md).

## Hoja de ruta

- Un ejemplo en C# en `csharp/`, con los mismos componentes y una escena principal sobre `shared/world/world.tscn`.
- Animaciones: controlar una mezcla de reposo y carrera en un `AnimationTree` con `NavigationMover.get_speed()`.

## Licencia

MIT, ver [LICENSE](LICENSE). Excepción: `icon.svg`, el logo de Godot de Andrea Calabró, CC BY 4.0.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
