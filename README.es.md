<!-- translation of README.md @ 84a666a02ac2 -->
# Iso & Orbit - Plantilla de cámara y controlador de personaje

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Versión 1.2.0 · Godot 4.7 (probado en 4.7.2) · GDScript · MIT

Un controlador de personaje con movimiento por clic y una cámara orbital para RPG isométricos y cenitales. Haz clic
en el suelo y el héroe corre hasta allí, rodeando los obstáculos; mantén el botón y el héroe sigue al cursor. La
cámara orbita, hace zoom y no se mete en las paredes.

**¿Acabas de llegar al proyecto?** [Ejecuta la demo](docs/es/getting-started.md),
[transfiere el héroe preparado](docs/es/integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto) y después
[elige una configuración de movimiento y cámara](docs/es/configurations.md).

![Clic para moverse, mantener para dirigir, orbitar la cámara y hacer zoom, descubrir un lugar](docs/images/demo.gif)

Sin assets de terceros: un script construye los personajes con primitivas, los patrones de las superficies se generan
con shaders y se hornean en texturas sin costuras, y los sonidos son sintetizados.
La vista suministrada usa una cámara en perspectiva con campo visual de 45°. Las partes reutilizables son
componentes GDScript normales; no hay ningún plugin del editor que activar.

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
| Mantener el izquierdo y luego pulsar el derecho | Mirar alrededor durante la carrera; el héroe conserva el rumbo |
| Mantener el derecho y luego pulsar el izquierdo | Correr hacia donde mira la cámara; A / D desvían en diagonal |
| Botón derecho + mouse | Orbitar la cámara |
| Botón derecho + WASD | Moverse según la cámara |
| Rueda del mouse | Zoom: más abajo y más cerca, o más arriba y más lejos |
| Shift | Sprint mientras se mantiene (o alternar, en la configuración) |
| Espacio | Saltar |
| E | En una plataforma de teletransporte: viajar a su destino |
| F10 | Abrir la configuración (pausa el juego); Esc o F10 la cierra |

Todos los modos y sus opciones: [Controles](docs/es/controls.md).

## Características

**Movimiento**

- Clic para correr hasta un punto por la malla de navegación; un marcador indica dónde.
- Mantén el botón izquierdo para correr tras el cursor: por defecto directo hacia él, deslizándose junto a los
  obstáculos; opcionalmente por una ruta de navegación hasta el punto bajo el cursor.
- Un clic y una pulsación mantenida se distinguen a los 0,2 s, así que mantener el botón nunca manda al héroe a dar
  un rodeo hasta el punto donde presionaste.
- Derecho y luego izquierdo (o ambos a la vez): correr según la cámara. Izquierdo y luego derecho: mirar alrededor
  manteniendo el rumbo. Derecho con WASD: moverse según la cámara, mirando al frente o girando hacia donde vas.
- Aceleración y frenado constantes, parada exacta en el objetivo sin pasarse, velocidad de giro limitada y giro
  instantáneo desde parado.
- Sprint con resistencia. Salto con tiempo de coyote y búfer de entrada; la altura del salto es la misma con
  cualquier frecuencia de ticks de física. La caída puede tener gravedad y velocidad máxima propias (`FallSettings`).
- Protección de bordes: al borde de un desnivel el héroe se detiene o se desliza a lo largo de él, como junto a una
  pared.
- Los escalones de hasta 0,3 m se suben y se bajan sin despegar del suelo; las pendientes de hasta 45° se suben
  caminando.
- Modo flotante opcional: el héroe se eleva sobre el suelo, se desliza por escaleras, oscila y se inclina al correr,
  sin pasos, y desciende lentamente tras saltar.

**Cámara**

- Se orbita con el botón derecho y se hace zoom con la rueda. La distancia y la inclinación cambian juntas: cuanto más
  cerca está la cámara, más bajo es su ángulo, así ves lo que hay delante.
- Opcionalmente gira detrás del héroe y alinea inclinación y altura a valores elegidos, con arranques y paradas
  suaves a cualquier frecuencia de fotogramas. Una carrera hacia la cámara no la hace girar bruscamente, tampoco
  tras un cambio de sentido.
- Mientras la cámara gira, el cursor se queda sobre el mismo punto del suelo, así un botón mantenido conserva el
  rumbo del héroe en vez de hacerlo correr en círculos.
- Un brazo de cámara: la cámara se detiene ante una pared, una montaña o un techo que tenga detrás y, opcionalmente,
  se acerca cuando un obstáculo oculta al héroe. De cerca, el héroe se vuelve translúcido.
- Detrás de los obstáculos el héroe se ve como una sola silueta con contorno, con el equipo que lleva en la mano
  dibujado encima.

**Niveles**

- Los niveles cambian tras una pantalla de carga mientras héroe e interfaz permanecen: el siguiente se carga en
  segundo plano, el anterior se libera y el héroe llega a un punto de aparición con la cámara detrás.
- La pantalla muestra el último fotograma desenfocado que se acerca lentamente, nombre del lugar, barra de
  progreso y consejos de control.
- Los portales pueden pedir confirmación (las plataformas ofrecen la tecla E y «Teletransporte: …»)
  o viajar de inmediato.
- El héroe controlado por el jugador es una escena lista (`PlayableHero`) con personaje, entrada, cámara y marcador,
  y métodos para colocarlo en cualquier lugar.

**También incluye**

- Una ventana de configuración (F10) con pestañas de controles, personaje, cámara, pantalla, interfaz y sonido, que
  se guarda en `user://settings.cfg`. La interfaz está en inglés, español, japonés, portugués de Brasil, ruso, turco
  y chino simplificado, y el idioma se cambia al vuelo.
- El personaje informa de lo que está haciendo, para animaciones, efectos y la interfaz: el estado (quieto, corriendo,
  en sprint, saltando, cayendo) con una señal para cada cambio, los pasos con el pie, escalones con su altura,
  despegues y aterrizajes, velocidad como mezcla, movimiento y aceleración en los ejes del modelo, giro y ciclo
  de marcha. Los sonidos
  están conectados a las señales, y un panel (Configuración → Interfaz) lo muestra todo en vivo con los últimos
  eventos.
- Dos niveles de demo: un claro cercado de 80 × 80 m con ruinas, campamento, granja, laberinto, plataforma con
  rampa y escaleras, y montaña de sendero espiral; y una isla en un lago a la que se llega por teletransporte.
  Cinco lugares por descubrir, cuatro en el claro con cinco PNJ y uno en la isla, y diez aspectos de héroe.
- Pruebas headless de movimiento, entrada, salto, sprint y sonidos, del estado del personaje, de escalones y
  pendientes, cámara y brazo, aspectos del héroe, ventana de ajustes, traducciones, niveles y teletransporte.

**No incluye:** gamepad, menú de reasignación de teclas durante la partida ni animaciones esqueléticas. Las acciones
se configuran en Ajustes del proyecto y la interfaz muestra sus asignaciones actuales. Los modelos son primitivas.

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
- **El personaje no sabe nada del ratón.** Los nodos de entrada viven en la escena del héroe
  (`playable_hero.tscn`), no en `player.tscn`. Para un
  NPC, instancia `player.tscn` sin los nodos `Silhouette` y `Appearance`, que son solo del jugador, y llama a
  `NavigationMover.move_to()` desde tu IA.
- **El héroe no forma parte de un nivel.** Es hermano del host de niveles en `main.tscn`; los niveles cambian
  alrededor de él.
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
| `ground_character` | Cuerpo preparado: gravedad, salto, caída configurable, sprint y resistencia, protección de bordes, señales de pasos, sonidos, mano oscilante, flotación y modelos intercambiables (requiere `click_to_move`) |
| `occluded_silhouette` | La silueta del personaje detrás de los obstáculos |
| `points_of_interest` | Lugares por descubrir y el mensaje sobre ellos |
| `ui_screens` | Una pila de ventanas que pausa el juego, y un contador de FPS |
| `levels` | Cambio de niveles tras pantalla de carga, portales y puntos de aparición |

Para la integración más breve, copia `playable_hero.tscn` y sus dependencias siguiendo
[la guía de transferencia](docs/es/integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto). Incluye un nivel
de prueba, ajustes exactos de colisión y navegación, y comprobaciones previas a personalizar. El héroe funciona
sin la ventana de ajustes ni el sistema de niveles de la demo.

Con tu propio controlador o IA, `NavigationMover.move_to(point)` sigue una ruta y `steer(direction)` avanza
directamente. El cuerpo aplica la velocidad devuelta una vez por tick de física; el componente de movimiento
nunca lo desplaza. Hay una integración mínima en [Tu propio cuerpo](docs/es/integration.md#tu-propio-cuerpo).

[Configuraciones](docs/es/configurations.md) compara el valor predeterminado con ratón guiado por rutas y cámara
de seguimiento, y explica cada parámetro. [Preparación del proyecto](docs/es/project-setup.md) enumera las
acciones, capas y dependencias opcionales de la demo.

## Documentación

- **Inicio:** [Primeros pasos](docs/es/getting-started.md) · [Controles](docs/es/controls.md) ·
  [Configuraciones](docs/es/configurations.md) · [Configuración](docs/es/settings.md)
- **Código:** [Arquitectura](docs/es/architecture.md) · [Uso en tu proyecto](docs/es/integration.md) ·
  [Preparación del proyecto](docs/es/project-setup.md)
- **Sistemas:** [Locomoción](docs/es/systems/locomotion.md) · [Cámara](docs/es/systems/camera.md) ·
  [Entrada](docs/es/systems/input.md) · [Personajes](docs/es/systems/characters.md) ·
  [Audio](docs/es/systems/audio.md) · [Interfaz de usuario](docs/es/systems/ui.md) ·
  [Mundo y navegación](docs/es/systems/world-and-navigation.md) · [Niveles](docs/es/systems/levels.md)
- **Mantenimiento:** [Pruebas](docs/es/testing.md) · [Problemas conocidos](docs/es/known-issues.md) ·
  [Glosario](docs/es/glossary.md) · [Hoja de ruta](docs/es/roadmap.md)

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `addons/iso_orbit/` | Los componentes, una carpeta por cada parte que puedes tomar por separado |
| `gdscript/` | La demo que los ensambla: escena principal `main.tscn`, héroe jugable y sistema y ventana de ajustes |
| `shared/` | Contenido para la demo GDScript y una futura versión C#: niveles, personajes y equipo, shaders y texturas del mundo, sonidos y tema de interfaz. También hay dos scripts GDScript pequeños usados por los niveles |
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

- Un ejemplo en C# en `csharp/`, con los mismos componentes y una escena principal sobre los niveles de
  `shared/world/`.
- Animaciones: controlar mezclas de reposo, carrera y sprint en `AnimationTree` con
  `GroundCharacter.get_locomotion_blend()`.

## Licencia

MIT, ver [LICENSE](LICENSE). Excepción: `icon.svg`, el logo de Godot de Andrea Calabró, CC BY 4.0.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
