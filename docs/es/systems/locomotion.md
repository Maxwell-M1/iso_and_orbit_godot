<!-- translation of docs/en/systems/locomotion.md @ f90a0207f4e9 -->
# Locomoción

> Esta es una traducción del [original en inglés](../../en/systems/locomotion.md).
> Si hay diferencias, la versión en inglés es la correcta.

Cómo un personaje corre, se detiene, gira, esprinta, salta y se mantiene alejado de los desniveles. Cuatro clases, de
abajo hacia arriba:

| Clase | Tipo | Tarea |
|---|---|---|
| `LocomotionSettings` | Resource | Velocidad, aceleración, frenado, giro |
| `GroundMotion` | RefCounted | La matemática: dirección deseada y distancia restante → velocidad horizontal |
| `NavigationMover` | Node, hijo del cuerpo | Rutas y órdenes; devuelve una velocidad, nunca mueve el cuerpo |
| `GroundCharacter` | CharacterBody3D | Gravedad, salto, sprint, `move_and_slide()`, giro del modelo |

Dos auxiliares se conectan al cuerpo: `Stamina` (la reserva para el sprint) y `LedgeGuard` (nada de salir caminando
por un desnivel).

## Cómo se siente la carrera

- **Aceleración y frenado constantes.** La velocidad cambia a un ritmo fijo, según `acceleration_time` y
  `stop_time`.
- **Parada exacta.** Cerca del objetivo la velocidad se limita a `√(2 · braking · distance left)`: el personaje
  empieza a frenar exactamente donde todavía puede detenerse en el punto, y nunca se pasa.
- **Sin reinicio con un objetivo nuevo.** Un clic nuevo durante el frenado conserva la velocidad actual; el personaje
  vuelve a acelerar desde ahí.
- **Velocidad de giro limitada.** Al correr, la dirección gira a `turn_speed`. Mientras la dirección no se ha
  alineado, `turn_slowdown` resta algo de velocidad, así que un giro brusco es un arco cerrado y no una deriva amplia.
- **Giro instantáneo desde parado.** Por debajo de `pivot_speed` el personaje gira de inmediato, así que un arranque
  en cualquier dirección no tiene arco ni demora.
- **Frenado fuerte cuando hace falta.** Si el punto de parada se fija justo delante de un personaje que corre, este
  puede frenar hasta `max_braking_multiplier` veces más fuerte de lo normal.

## LocomotionSettings

La demo usa `gdscript/player/player_locomotion.tres`. Cambia dos de los valores por defecto del script.

| Propiedad | Demo | Por defecto en el script | Significado |
|---|---|---|---|
| `max_speed` | 5,5 m/s | 5,5 m/s | Velocidad de carrera |
| `acceleration_time` | 0,35 s | 0,18 s | De parado a `max_speed` |
| `stop_time` | 0,4 s | 0,22 s | De `max_speed` a detenerse; la distancia de frenado es `max_speed × stop_time / 2` (1,1 m en la demo) |
| `turn_speed` | 720 °/s | 720 °/s | Qué tan rápido gira la dirección de carrera |
| `turn_slowdown` | 0,75 | 0,75 | Velocidad que se pierde mientras la dirección se alinea: 0 conserva la velocidad (arco amplio), 1 frena hasta cero en un giro de 90° o más |
| `pivot_speed` | 1 m/s | 1 m/s | Por debajo de esto el personaje gira al instante |
| `max_braking_multiplier` | 3 | 3 | Cuánto más fuerte de lo normal puede frenar el personaje ante un punto justo delante de él |
| `sprint_speed_multiplier` | 1,5 | 1,5 | Límite de velocidad durante el sprint (8,25 m/s); la aceleración y el frenado no cambian |
| `backward_speed_multiplier` | 0,7 | 0,7 | Fracción de la velocidad que queda al moverse hacia atrás (mirando en contra del movimiento) |

La ventana de configuración cambia `sprint_speed_multiplier` y `backward_speed_multiplier` en tiempo de ejecución.
El resto se ajusta en el recurso. Para ajustarlos con el juego en marcha: panel Escena (Scene) → Remoto (Remote) →
`Player/NavigationMover` → `settings`. El código los lee en cada tick, pero los cambios hechos ahí no se guardan,
así que copia el resultado al archivo `.tres`.

Varios personajes pueden compartir un mismo recurso, por ejemplo todos los NPC de un mismo tipo.

## NavigationMover

Un hijo del cuerpo (cualquier `Node3D`, normalmente un `CharacterBody3D`). Dos modos:

- `move_to(point)`: hasta un punto por una ruta de navegación, rodeando los obstáculos, con parada exacta. La ruta
  viene de `NavigationServer3D` para el mundo del cuerpo. Sin un mapa de navegación, el personaje corre en línea
  recta hacia el punto.
- `steer(direction, facing = Vector3.ZERO)`: en una dirección, sin ruta, hasta `stop()`, `halt()` o `move_to()`.
  Los obstáculos se resuelven con el cuerpo deslizándose junto a ellos. Con `facing`, el personaje mira hacia ese
  lado mientras se mueve: desplazamiento lateral y retroceso. La orientación se mantiene tras una parada, hasta una
  orden sin ella.

El cuerpo llama a `compute_velocity(delta)` una vez por tick de física, antes de `move_and_slide()`.

| Propiedad | Por defecto | Significado |
|---|---|---|
| `settings` | — | `LocomotionSettings`; valores por defecto si está vacío |
| `use_navigation` | activado | Buscar una ruta; desactivado, o sin navegación en el mundo: correr en línea recta hasta el punto |
| `navigation_layers` | 1 | Capas de navegación que puede usar la ruta |
| `waypoint_radius` | 0,4 m | Un punto de la ruta cuenta como pasado a menos de esta distancia; un valor mayor corta las esquinas antes |
| `arrive_distance` | 0,005 m | A menos de esta distancia del final, el personaje se detiene de inmediato. El propio frenado lo lleva al punto, así que el umbral es diminuto |
| `retarget_tolerance` | 0,1 m | Un punto nuevo a menos de esta distancia del actual no reconstruye la ruta. Un botón mantenido envía un punto en cada tick |
| `max_path_deviation` | 2 m | Si lo empujan más lejos que esto de la ruta, el personaje recibe una ruta nueva |
| `sprinting` | desactivado | Subir el límite de velocidad según `sprint_speed_multiplier`. El dueño decide cuándo |

Señales: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled`.

**Los puntos de la ruta se comparan en el plano horizontal.** Una malla de navegación de Recast queda suspendida
sobre el suelo unas dos alturas de celda (0,05 m aquí). Comparar distancias 3D con los pies del personaje daría un
error de esa magnitud, y por eso el movedor sigue la ruta por sí mismo en lugar de usar `NavigationAgent3D`.

**Retroceder es más lento.** Cuando `steer()` recibe un `facing`, la velocidad se escala según cuánto se opone el
movimiento a la orientación: hacia atrás en línea recta recibe todo el `backward_speed_multiplier`, en diagonal
hacia atrás una parte (S + D en modo lateral: 21% más lento), de costado nada. Así que la ralentización solo existe
en el modo lateral de las teclas, ver [Entrada](input.md).

## GroundCharacter

El único lugar donde se mueve el cuerpo. En cada tick de física actualiza el estado del sprint, toma la velocidad
horizontal del movedor, gestiona el salto y la gravedad, deja que `LedgeGuard` corrija la velocidad, llama a
`move_and_slide()`, informa pasos y aterrizajes y gira `visual` hacia `mover.get_facing()`.

| Propiedad | Por defecto | Significado |
|---|---|---|
| `mover` | — | El `NavigationMover`; obligatorio |
| `visual` | — | El nodo que gira hacia donde va el personaje; su frente es −Z |
| `visual_turn_speed` | 1080 °/s | Qué tan rápido gira el modelo |
| `gravity_scale` | 3 | Multiplicador de la gravedad. El personaje corre más rápido que una persona y con la gravedad normal parecería flotar al caer: una caída de 1,6 m tarda 0,33 s en lugar de 0,57 s |
| `ledge_guard` | — | `LedgeGuard` opcional; sin él, el personaje cae desde cualquier altura |
| `can_sprint` | activado | Sprint permitido. Si se desactiva durante la carrera, la velocidad extra se frena |
| `stamina` | — | `Stamina` opcional; sin ella, el sprint nunca cansa |
| `sprint_tires` | activado | El sprint gasta resistencia |
| `sprint_duration` | 5 s | Cuánto dura una reserva llena: gasta `max_value / sprint_duration` por segundo |
| `can_jump` | activado | Salto permitido; desactivado, `jump()` no hace nada |
| `jump_height` | 1 m | Altura de los pies en la cima del salto |
| `coyote_time` | 0,1 s | Un salto todavía funciona durante este tiempo después de salir caminando de un borde |
| `jump_buffer_time` | 0,12 s | Un salto presionado este tiempo antes de aterrizar se ejecuta al aterrizar |
| `landing_min_speed` | 2,5 m/s | Las caídas más lentas (un escalón hacia abajo, una rampa) no cuentan como aterrizajes |
| `stride_length` | 1,5 m | Distancia sobre el suelo entre pasos |
| `first_step_distance` | 0,3 m | Distancia desde parado hasta el primer paso |

Establece `sprint_requested` para pedir un sprint y llama a `jump()` para saltar. `CharacterActionInput` hace ambas
cosas para el jugador; una IA puede hacer lo mismo.

### Señales

| Señal | Cuándo |
|---|---|
| `stepped(sprinting)` | Un pie tocó el suelo: cada `stride_length` recorrida sobre el suelo, el primero a `first_step_distance` desde parado. Los pasos siguen la distancia, no el tiempo: unos 3,7 por segundo corriendo, 5,5 en sprint, ninguno parado contra una pared o en el aire |
| `jumped` | El personaje se impulsó desde el suelo |
| `landed(impact_speed)` | El personaje aterrizó; `impact_speed` es la velocidad de caída en m/s |
| `sprint_changed(sprinting)` | El sprint empezó o terminó |

`get_step_phase()` devuelve el ritmo de los pasos como un número de pasos dados: un entero en cada paso, y la parte
fraccionaria crece de 0 a 1 con la distancia entre pasos. `HandSway` lo usa; una animación también puede usarlo.
Otras consultas: `is_sprinting()`, `is_exhausted()`, `get_jump_speed()`.

### El salto

La velocidad de despegue es `v = √(2·g·h)`. En el tick del despegue el cuerpo recibe `v − g·dt/2`: así sus
posiciones en cada tick caen exactamente sobre la parábola, y la altura del salto no depende de la frecuencia de
ticks. Con `v` a secas el salto sería `v·dt/2` más alto, 1,064 m en lugar de 1 m a 60 ticks. En la demo, un salto de
1 m dura 0,52 s con `gravity_scale` 3.

En el aire el personaje sigue corriendo como lo hacía, y los controles siguen siendo los mismos. La protección de
bordes no retiene un salto: saltar desde el borde de una plataforma es un paso deliberado, no un accidente.

## Sprint y resistencia

Mientras se pide el sprint y el personaje está siendo conducido (un clic, un botón mantenido, ambos botones, las
teclas), corre `sprint_speed_multiplier` veces más rápido y gasta resistencia. Quedarse quieto con Shift presionado
no gasta nada. Cuando la reserva se agota, el personaje queda agotado: corre a velocidad normal hasta que la
resistencia se recupera hasta `recover_ratio`, y luego vuelve a esprintar solo si Shift sigue presionado.

`Stamina` no sabe nada de qué la gasta:

| Propiedad | Por defecto | Significado |
|---|---|---|
| `max_value` | 100 | Reserva llena |
| `recovery_rate` | 12,5 por segundo | De vacía a llena en 8 s |
| `recovery_delay` | 1 s | La recuperación empieza este tiempo después del último gasto |
| `recover_ratio` | 0,3 | Un personaje agotado vuelve a esprintar después de recuperar esta fracción (1 + 2,4 s) |

Métodos: `spend(amount)`, `can_spend()`, `get_ratio()`, `is_exhausted()`, `refill()`. Señales: `changed(ratio)`,
`exhausted_changed(exhausted)`. El `StaminaBar` del HUD las escucha.

## LedgeGuard

Evita que el personaje salga caminando por un desnivel. El cuerpo llama a `constrain(velocity, delta)` antes de
`move_and_slide()`. Si el cuerpo fuera a terminar el tick sobre un desnivel, el movimiento se gira a lo largo del
borde hacia la dirección más cercana que tenga suelo debajo y se acorta según el coseno del giro, exactamente como al
deslizarse junto a una pared. Correr en línea recta hacia el borde detiene al personaje.

| Propiedad | Por defecto | Significado |
|---|---|---|
| `enabled` | activado | Proteger los bordes |
| `max_drop` | 0,5 m | Un desnivel menor es un escalón y se puede bajar caminando; uno mayor es una cornisa |
| `edge_margin` | 0,15 m | Qué tan cerca del borde puede llegar el centro del personaje |
| `margin_probes` | 6 | Rayos alrededor del círculo de `edge_margin` |
| `probe_height` | 0,5 m | Los rayos parten a esta altura sobre los pies, para encontrar suelo algo por encima de ellos (una rampa) |
| `floor_mask` | capa 1 | Qué cuenta como suelo |
| `slide_iterations` | 6 | Divisiones a la mitad del ángulo de deslizamiento; 6 da unos 1,4° |

En terreno abierto son 7 rayos por tick, hasta 98 en un borde. En el aire la protección no hace nada. Una ruta que
baja de la plataforma sigue la rampa, y la protección no le estorba.

## Comportamiento medido

Las pruebas (`tests/movement_checks.gd`, `tests/character_actions_checks.gd`, `tests/camera_checks.gd`) miden la
configuración de la demo a 60 ticks de física. Sus límites se calculan a partir de la configuración, así que puedes
cambiarla.

- 95% de la velocidad máxima en 0,33 s; del 95% a detenerse en 0,35 s; la parada es exactamente en el punto del
  clic.
- Un clic nuevo más lejos durante el frenado: desde 2,66 m/s la velocidad vuelve a crecer de inmediato, sin bajar
  nunca a cero.
- Un clic detrás del personaje a toda velocidad: sigue 0,34 m, el arco se desvía 0,63 m hacia un lado y, tras
  0,28 s, corre de vuelta.
- En línea recta hacia el borde de la plataforma: parada a 0,15 m del borde a velocidad cero. A 45°: deslizamiento a
  lo largo del borde a 3,89 m/s (5,5 × cos 45°, como junto a una pared) hasta la esquina de la plataforma, a la misma
  altura. Sin la protección: una caída de 1,6 m en 0,35 s.
- Sprint: 8,25 m/s. Con `sprint_duration` de 2 s (50 por segundo), la resistencia se agota tras 2,02 s, luego
  5,5 m/s; 3,38 s más tarde el personaje se ha recuperado (1 + 2,4 s) y vuelve a esprintar a 8,25 m/s con Shift
  todavía presionado.
- Salto: cima a 1,000 m, 0,517 s en el aire (0,522 según la fórmula). Presionado 0,4 m sobre el suelo, el salto se
  ejecuta en el tick posterior al aterrizaje; presionado en la cima, se olvida. Espacio 3 ticks después de salir
  caminando de un borde salta, 9 ticks después no.

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
