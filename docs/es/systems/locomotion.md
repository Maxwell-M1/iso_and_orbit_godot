<!-- translation of docs/en/systems/locomotion.md @ 78c912e8971a -->
# Locomoción

[← Índice de documentación](../index.md)

> Esta es una traducción del [original en inglés](../../en/systems/locomotion.md).
> Si hay diferencias, la versión en inglés es la correcta.

Cómo corre, se detiene, gira, esprinta, salta y sube escalones un personaje, y cómo evita los desniveles. Para usar
el héroe completo y conocer los archivos que necesita, empieza por
[Integración](../integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto). Consulta
[Configuraciones](../configurations.md) para elegir controles ya preparados. Cuatro clases reparten el trabajo:

| Clase | Tipo | Tarea |
|---|---|---|
| `LocomotionSettings` | Resource | Velocidad, aceleración, frenado, giro |
| `GroundMotion` | RefCounted | La matemática: dirección deseada y distancia restante → velocidad horizontal |
| `NavigationMover` | Node, hijo del cuerpo | Rutas y órdenes; devuelve una velocidad, nunca mueve el cuerpo |
| `GroundCharacter` | CharacterBody3D | Gravedad, salto, sprint, `move_and_slide()`, giro del modelo |

Dos auxiliares se conectan al cuerpo: `Stamina` (reserva del sprint) y `LedgeGuard` (protección ante desniveles).
Un recurso `FallSettings` determina la caída. `CharacterMonitor` muestra en texto el estado del cuerpo.
`CharacterHover` hace flotar el modelo; consulta [Personajes](characters.md#characterhover-flotar-sobre-el-suelo).

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

Estos son los valores predeterminados de `LocomotionSettings` y del recurso suministrado
`gdscript/player/player_locomotion.tres`. El recurso separado permite que los ajustes de la demo cambien las
velocidades de sprint y retroceso de este héroe sin afectar a otros personajes.

| Propiedad | Valor predeterminado | Significado |
|---|---|---|
| `max_speed` | 5.5 m/s | Velocidad de carrera |
| `acceleration_time` | 0.18 s | Tiempo de parado hasta `max_speed` |
| `stop_time` | 0.22 s | Tiempo de `max_speed` hasta parar; distancia de frenado `max_speed × stop_time / 2` (unos 0.61 m) |
| `turn_speed` | 720 °/s | Velocidad de giro de la carrera. Mantén `sharp_turn_speed` de la cámara como máximo en la mitad; consulta [Cámara](camera.md#modo-de-seguimiento) |
| `turn_slowdown` | 0.75 | Velocidad perdida mientras la dirección alcanza el giro: 0 la conserva (arco amplio), 1 frena hasta cero en un giro de 90° o más |
| `pivot_speed` | 1 m/s | Por debajo, gira al instante |
| `max_braking_multiplier` | 3 | Multiplicador máximo del frenado ante un punto justo delante |
| `sprint_speed_multiplier` | 1.5 | Multiplica la velocidad base durante el sprint (8.25 m/s con los valores predeterminados); aceleración y frenado no cambian |
| `backward_speed_multiplier` | 0.7 | Fracción de velocidad al retroceder mirando en dirección contraria al movimiento |

El sprint solo eleva el límite de velocidad, así que desde el sprint máximo se tarda más tiempo y distancia en
parar: alrededor de 1.36 m a 8.25 m/s con el frenado predeterminado, frente a 0.61 m a 5.5 m/s. Un punto marcado
muy cerca delante puede activar `max_braking_multiplier` para detenerse antes.

`SettingsApplier` de la demo cambia `sprint_speed_multiplier` y `backward_speed_multiplier` al iniciar y cuando el
jugador modifica un ajuste; los valores guardados pueden sustituir los de arriba. El addon no tiene sistema de
ajustes. Para modificar una demo en ejecución, abre panel Escena → Remoto → `Hero/Character/NavigationMover` →
`settings`. El código lee los campos del recurso cada tick, pero los cambios del Inspector remoto no se guardan:
copia el resultado al `.tres`. Usa un recurso separado para cada personaje si los cambios de ejecución no deben
afectar a otros. Asígnalo antes de que el componente entre en el árbol o usa **Make Unique** en el editor:
después de
`_ready()`, `GroundMotion` conserva el recurso original. Sustituir entonces `mover.settings` no cambia los ajustes
del movimiento; edita los campos del recurso existente durante la ejecución.

Varios personajes pueden compartir un mismo recurso, por ejemplo todos los NPC de un mismo tipo.

## NavigationMover

Un hijo del cuerpo (cualquier `Node3D`, normalmente un `CharacterBody3D`). Dos modos:

- `move_to(point)`: hasta un punto siguiendo una ruta de navegación, rodeando obstáculos, con parada exacta al final
  de la ruta. Esta procede de `NavigationServer3D` para el mundo del cuerpo. Si la ruta resulta vacía, incluso en
  un mundo sin malla de navegación, el componente de movimiento corre en línea recta hacia el punto solicitado.
- `steer(direction, facing = Vector3.ZERO)`: en una dirección, sin ruta, hasta `stop()`, `halt()` o `move_to()`.
  Los obstáculos se resuelven con el cuerpo deslizándose junto a ellos. Con `facing`, el personaje mira hacia ese
  lado mientras se mueve: desplazamiento lateral y retroceso. La orientación se conserva tras `stop()`;
  `move_to()`, `steer()` sin `facing`, `halt()` y `face()` la borran.

El cuerpo llama a `compute_velocity(delta)` una vez por tick de física, antes de `move_and_slide()`. `stop()` frena
suavemente, `halt()` detiene al instante (por ejemplo al teletransportar) y `face(direction)` gira a un personaje
parado sin iniciar una carrera, por ejemplo en un punto de aparición. La dirección de carrera y la orientación del
componente de movimiento cambian de inmediato; `GroundCharacter` gira el modelo hacia ellas a `visual_turn_speed` (solo
`GroundCharacter.teleport(position, facing)` gira también el modelo de inmediato). Si había una carrera, vuelve a
orientarse en la dirección que sigue.

| Propiedad | Por defecto | Significado |
|---|---|---|
| `settings` | — | `LocomotionSettings`; si está vacío, el componente de movimiento crea uno con los valores del script en `_ready()` |
| `use_navigation` | activado | Buscar una ruta; desactivado, o sin navegación en el mundo: correr en línea recta hasta el punto |
| `navigation_layers` | 1 | Capas de navegación que puede usar la ruta |
| `waypoint_radius` | 0,4 m | Un punto de la ruta cuenta como pasado a menos de esta distancia; un valor mayor corta las esquinas antes |
| `arrive_distance` | 0,005 m | A menos de esta distancia del final, el personaje se detiene de inmediato. El propio frenado lo lleva al punto, así que el umbral es diminuto |
| `retarget_tolerance` | 0,1 m | Un punto nuevo a menos de esta distancia del actual no reconstruye la ruta. Un botón mantenido envía un punto en cada tick |
| `max_path_deviation` | 2 m | Si lo empujan más lejos que esto de la ruta, el personaje recibe una ruta nueva |
| `sprinting` | desactivado | Eleva el límite según `sprint_speed_multiplier`. El dueño decide cuándo; `GroundCharacter` lo establece cada tick, así que con ese cuerpo cambia `sprint_requested` |

Señales: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled`.

`arrived` indica que se llegó al final de la ruta. Una ruta puede terminar en el punto alcanzable más próximo en
vez de en el destino solicitado: compara posiciones si tu juego necesita llegar exactamente al punto pedido.
Avanzar en línea recta como alternativa no evita obstáculos más allá de deslizarse contra ellos con el cuerpo.

| Consulta | Devuelve |
|---|---|
| `is_moving()` | El personaje recibe una orden de ir a un punto o en una dirección. Describe la orden, no el movimiento: true mientras aún está parado al empezar y false mientras frena tras `stop()` |
| `is_steering()` | Corre en la dirección de `steer()`, no hacia un punto |
| `has_destination()`, `get_destination()` | Hay un punto de `move_to()` en curso (hasta llegar o cancelar); devuelve ese punto |
| `get_speed()` | Velocidad de carrera en m/s |
| `get_heading()` | Dirección de carrera como vector horizontal unitario; parado, dirección de su última carrera |
| `get_facing()` | Hacia dónde debe mirar: según `get_heading()` o lo indicado con `steer()` |
| `get_body()` | Cuerpo al que conduce, su padre |
| `get_remaining_path()` | Puntos restantes desde el siguiente, a altura de la malla de navegación; vacío si avanza directamente |

**Los puntos de la ruta se comparan en el plano horizontal.** Una malla de navegación de Recast queda suspendida
sobre el suelo unas dos alturas de celda (0,05 m aquí). Comparar distancias 3D con los pies del personaje daría un
error de esa magnitud. Por ello, el componente sigue la ruta por sí mismo en lugar de usar
`NavigationAgent3D`.

**Retroceder es más lento.** Cuando `steer()` recibe un `facing`, la velocidad se escala según cuánto se opone el
movimiento a la orientación: hacia atrás en línea recta recibe todo el `backward_speed_multiplier`, en diagonal
hacia atrás una parte (S + D en modo lateral: 21% más lento), de costado nada. Así que la ralentización solo existe
en el modo lateral de las teclas, ver [Entrada](input.md).

## GroundCharacter

El único lugar donde se mueve el cuerpo. En cada tick de física actualiza el estado del sprint, toma la velocidad
horizontal del componente de movimiento, gestiona salto y gravedad, deja que `LedgeGuard` corrija la velocidad,
llama a
`move_and_slide()` con una subida de escalón antes y una bajada después, y luego informa de lo que cambió en el
tick: contacto con el suelo, escalón subido o bajado, pasos, giro del modelo hacia `mover.get_facing()` y estado.

El Inspector agrupa las propiedades: primero las partes y el giro, luego Ground (suelo), Jump and fall (salto y caída),
Sprint y Steps (pasos).

| Propiedad | Por defecto | Significado |
|---|---|---|
| `mover` | — | El `NavigationMover`; obligatorio |
| `visual` | — | El nodo que gira hacia donde va el personaje; su frente es −Z |
| `visual_turn_speed` | 1080 °/s | Qué tan rápido gira el modelo |
| `max_step_height` | 0,3 m | El escalón más alto al que el personaje sube sin saltar, y el más profundo que baja sin despegar del suelo. Con 0 no sube ni baja escalones |
| `ledge_guard` | — | `LedgeGuard` opcional; sin él, el personaje cae desde cualquier altura |
| `can_jump` | activado | Salto permitido; desactivado, `jump()` no hace nada |
| `jump_height` | 1 m | Altura de los pies en la cima del salto |
| `coyote_time` | 0,1 s | Un salto todavía funciona durante este tiempo después de salir caminando de un borde |
| `jump_buffer_time` | 0,12 s | Un salto presionado este tiempo antes de aterrizar se ejecuta al aterrizar |
| `gravity_scale` | 3 | Multiplica la gravedad durante el ascenso del salto y también el descenso, salvo si `fall` establece otra. El personaje corre más rápido que una persona y con gravedad normal parecería flotar: una caída de 1.6 m dura 0.33 s en vez de 0.57 s |
| `fall` | — | `FallSettings` que determina la aceleración y velocidad máxima de caída; consulta [La caída](#la-caída). Vacío: usa `gravity_scale` sin límite |
| `landing_min_speed` | 2,5 m/s | Una caída más lenta (un pequeño desnivel, una rampa) es solo `touched_floor`, no `landed` |
| `can_sprint` | activado | Sprint permitido. Si se desactiva durante la carrera, la velocidad extra se frena |
| `stamina` | — | `Stamina` opcional; sin ella, el sprint nunca cansa |
| `sprint_tires` | activado | El sprint gasta resistencia |
| `sprint_duration` | 5 s | Cuánto dura una reserva llena: gasta `max_value / sprint_duration` por segundo |
| `steps_enabled` | activado | Cuenta los pasos: señal `stepped` y ritmo. Desactívalo para un personaje sin piernas. Al reactivarlo, el primero llega tras `first_step_distance` |
| `stride_length` | 1,5 m | Distancia sobre el suelo entre pasos |
| `first_step_distance` | 0,3 m | Distancia desde parado hasta el primer paso |

El límite de pendiente es `floor_max_angle` del cuerpo (Inspector → Floor → Max Angle, 45° de forma predeterminada).
Una superficie más empinada es pared para cuerpo, escalones y protección de bordes. Arriba es +Y: `up_direction`
debe permanecer como `Vector3.UP`.

Al cambiar tamaño del cuerpo o escalones, ajusta estos valores juntos: `max_step_height` no debe ser menor que el
escalón; `LedgeGuard.max_drop` debe ser al menos igual a `max_step_height`; y `agent_max_climb` de la malla de
navegación debe coincidir con la altura que quieres atravesar. Vuelve a hornear tras cambiar la malla. Esta solo
planea rutas; cápsula, pendiente, espacio bajo techos y colisiones reales determinan si el cuerpo puede seguirlas.
Mantén `floor_snap_length` menor que `max_step_height` si quieres la señal `stair_taken` al bajar. La demo usa una
cápsula de 1.8 m de altura y 0.35 m de radio, escalones de 0.3 m, protección desde caídas de 0.5 m y malla con
ascenso máximo de 0.3 m y celdas de 0.025 m de altura; consulta
[Mundo y navegación](world-and-navigation.md#capas-de-física-y-navegación).

El cuerpo puede comenzar girado en el nivel, como un PNJ orientado en el editor o la raíz de `PlayableHero`:
el personaje gira solo `visual` con respecto al cuerpo y empieza mirando según su eje −Z.
El componente de movimiento toma
de ahí su dirección inicial. Después, `teleport(position, facing)` o `NavigationMover.face()` cambian la orientación.

Un componente puede suspender los pasos temporalmente sin cambiar `steps_enabled`:
`set_steps_suppressed(self, true)` y `false` para reanudarlos (`CharacterHover` lo hace mientras flota). Se cuentan
si `steps_enabled` está activo y ningún componente los suspende (`is_counting_steps()`): el interruptor del juego
y los componentes no se anulan entre sí. El personaje no retiene al componente: al liberarlo se reanudan los
pasos automáticamente en el siguiente tick. La caída funciona igual; consulta [La caída](#la-caída).

Los fallos de configuración se imprimen como advertencias al entrar el personaje en el árbol;
`get_setup_warnings()` devuelve la misma lista: el componente de movimiento o la protección de bordes no es hijo
del cuerpo;
`LedgeGuard.max_drop` es menor que `max_step_height` y bloquearía escalones descendentes
transitables;
la distancia de ajuste al suelo es tan larga como un escalón y lo baja sin emitir `stair_taken`;
`can_jump` está activado,
pero `jump_height` o `gravity_scale` es 0 y el salto no despegaría (no ocurre ni emite `jumped`);
`fall.max_speed` es menor que `landing_min_speed` y una caída nunca emitiría `landed`; o `up_direction` no es +Y.
`LedgeGuard` y `CharacterHover` comprueban también su propia configuración.

Establece `sprint_requested` para pedir un sprint y llama a `jump()` para saltar. `CharacterActionInput` hace ambas
cosas para el jugador; una IA puede hacer lo mismo.

`teleport(position, facing)` coloca al personaje al instante en otro lugar, como un punto de aparición de otro
nivel. Lo detiene (`NavigationMover.halt()`) y quienes siguen su movimiento no perciben una sacudida: velocidad,
aceleración y velocidad de giro pasan a 0. El suavizado entre ticks de física se reinicia en el nuevo lugar (también
se recoloca el modelo flotante); y se olvida un salto solicitado anteriormente. Con una orientación nueva,
personaje y modelo
giran allí al instante. Conserva la resistencia y el estado de contacto con el suelo; coloca por ello los pies
sobre el suelo. Al terminar emite `teleported` para cámara, estela y otros seguidores. En las comprobaciones,
teletransportar a mitad de una carrera a 5.5 m/s deja al personaje parado en el lugar nuevo en el mismo fotograma,
sin aceleración ni giro posteriores.

El teletransporte no cambia la entrada del jugador ni la cámara. Para el héroe utiliza
`PlayableHero.teleport()` o `place_at()` (consulta [Niveles](levels.md#el-héroe-jugable)): también descartan la
pulsación en curso, giran la cámara si se solicita y la recolocan al instante. Si llamas directamente a
`GroundCharacter.teleport()`, llama primero a `PointClickMoveInput.cancel()` (un botón aún pulsado volvería a
enviar al personaje en el tick siguiente) y conecta `teleported` con `OrbitCameraRig.snap()`.

Cuando se detiene el tiempo (`Engine.time_scale` 0), los ticks de física continúan con un paso cero y el personaje
conserva lugar, velocidad (`get_move_velocity()`), estado y ritmo de pasos. Aceleración y velocidad de giro son 0;
modelo flotante y mano oscilante permanecen inmóviles. Al reanudarse el tiempo, continúa la carrera. En las
comprobaciones, un héroe que corre a 5.5 m/s, tanto a pie como flotando, permanece exactamente en su lugar sin
errores y sigue corriendo después. La entrada todavía le llega: la tecla de sprint cambia el sprint de un personaje
que corre (`sprint_changed`), y un salto solicitado en el suelo ocurre inmediatamente (`jumped`). Si nada debe
cambiar durante ese tiempo, quita los controles (`PlayableHero.controls_enabled`).

### Lo que informa el personaje

Las animaciones, los efectos, los sonidos y la interfaz no tienen que deducir de la velocidad lo que está haciendo el
personaje. Los momentos llegan como señales; lo que cambia todo el tiempo se lee con consultas, en cada fotograma o
tick.

| Señal | Cuándo |
|---|---|
| `state_changed(state, previous)` | El estado cambió. Al final del tick, después de las demás señales del tick |
| `stepped(sprinting)` | Un pie tocó el suelo (`get_step_foot()` dice cuál): cada `stride_length` recorrida sobre el suelo, el primero a `first_step_distance` desde parado. Los pasos siguen la distancia, no el tiempo: unos 3,7 por segundo corriendo, 5,5 en sprint, ninguno parado contra una pared o en el aire |
| `jumped` | El personaje se impulsó desde el suelo; `left_floor` llega en el mismo tick |
| `left_floor` | El personaje despegó del suelo: con un salto o al salir de un borde. Bajar un escalón no cuenta |
| `touched_floor(fall_speed)` | Vuelve al suelo tras cualquier tiempo en el aire; una por cada `left_floor`. `fall_speed` es la velocidad al tocarlo |
| `landed(impact_speed)` | Un `touched_floor` a `landing_min_speed` o más rápido: un aterrizaje real, no un pequeño desnivel |
| `sprint_changed(sprinting)` | El sprint empezó o terminó |
| `stair_taken(height)` | El personaje subió o bajó un escalón: altura real de suelo a suelo, positiva al subir y negativa al bajar (±0.2 m en la demo). Al final del tick, antes de `state_changed`. Un escalón lo bastante bajo para que la cápsula lo suba sola (hasta `radius × (1 − cos floor_max_angle)`, 0.1 m con su cápsula) o lo baje `floor_snap_length` no emite la señal |
| `teleported` | Terminó `teleport()` y quienes lo siguen, como cámara o estela, deben saltar con él al nuevo lugar |

| Estado (`GroundCharacter.State`) | Cuándo |
|---|---|
| `IDLE` | En el suelo, más lento que `IDLE_SPEED` (0,1 m/s), también al correr contra una pared |
| `RUNNING` | En el suelo, moviéndose a cualquier velocidad, sin esprintar |
| `SPRINTING` | En el suelo, esprintando |
| `JUMPING` | En el aire después de un salto, hasta la cima |
| `FALLING` | En el aire, bajando: después de la cima de un salto o al salir de un borde |

| Consulta | Devuelve |
|---|---|
| `get_state()` | El estado |
| `get_move_velocity()`, `get_move_speed()` | Velocidad horizontal real y módulo, m/s: lo que el cuerpo recorre. A diferencia de `get_real_velocity()`, incluye escalones y conserva el valor con `Engine.time_scale` en 0 |
| `get_locomotion_blend()` | Para mezcla 1D: 0 parado por debajo de `IDLE_SPEED`, 1 a `max_speed`, 2 a toda velocidad de sprint, con cualquier valor de velocidad |
| `get_local_movement()` | Para mezcla 2D: x a la derecha del modelo (negativa a la izquierda), y hacia delante (negativa atrás), longitud igual a la mezcla. Carrera (0, 1), sprint (0, 2), derecha (1, 0), izquierda (−1, 0), adelante e izquierda (−0.71, 0.71), retroceso (0, −0.7) |
| `get_local_acceleration()` | Aceleración, frenado y giros en m/s² según esos ejes: al acelerar y > 0, al frenar y < 0, al girar a la izquierda x < 0. Se obtiene de la velocidad ordenada al cuerpo: los escalones no producen sacudidas y chocar con una pared no aparece aquí |
| `get_turn_rate()` | Qué tan rápido gira el modelo, rad/s: positivo hacia la izquierda, negativo hacia la derecha |
| `get_air_time()` | Segundos en el aire; 0 en el suelo |
| `get_step_phase()` | Los pasos dados como número: entero en cada paso, la parte fraccionaria crece con la distancia entre pasos |
| `get_gait_cycle()` | El ciclo de dos pasos, de 0 a 1: 0 cuando el pie izquierdo toca el suelo, 0,5 el derecho |
| `get_step_foot()` | El pie del último paso, `Foot.LEFT` o `Foot.RIGHT`. Los pies se alternan, también después de una parada |
| `is_sprinting()`, `is_exhausted()`, `get_jump_speed()` | Si esprinta ahora; si está agotado; la velocidad de despegue del salto |
| `is_on_floor()`, `get_floor_angle()`, `velocity.y` | Del propio `CharacterBody3D`: en el suelo, la pendiente bajo los pies, la velocidad vertical |
| `get_ground_height(point, above, below)` | Altura del suelo transitable bajo un punto: un rayo desde `above` metros por encima hasta `below` por debajo, usando la máscara de colisión del cuerpo; NAN si no hay suelo o si el rayo empieza dentro de algo (una pared mayor que `above`) |
| `is_counting_steps()` | Se cuentan pasos si `steps_enabled` está activo y ningún componente los suspende |
| `get_fall_settings()` | Caída activa: prioridad mayor entre sustituciones y la más reciente en caso de empate; si no, `fall`. Null significa `gravity_scale` sin límite de velocidad |

Qué consulta usar en cada caso:

- **Mezcla de animaciones:** `get_locomotion_blend()` para `BlendSpace1D` con puntos 0, 1 y 2;
  `get_local_movement()` para `BlendSpace2D` con desplazamientos laterales y retroceso. Son sus entradas exactas.
- **Efectos que siguen la velocidad:** `get_move_velocity()`, no `get_real_velocity()`. Esta última baja en cada
  escalón ascendente, cuando el cuerpo se coloca después de `move_and_slide()`, y con tiempo detenido resulta
  0 / 0, NaN: movimiento de un tick dividido por duración cero.
- **Inercia** de un objeto que se retrasa, modelo que se inclina al arrancar o girar, o capa:
  `get_local_acceleration()`.
- **Inclinación en giros o giro sobre el sitio:** `get_turn_rate()`. Es una velocidad, no un ángulo: aparece
  mientras gira el modelo, fluctúa entre ticks y vuelve a 0 cuando queda orientado. Suavízala antes de usarla.
- **Caída breve o dura:** `get_air_time()`. Omite la animación de caída si estuvo poco tiempo en el aire o
  intensifica el aterrizaje después de una caída larga.
- **`touched_floor` o `landed`:** la primera termina cualquier tiempo en el aire y sirve para volver a la
  animación terrestre; la segunda indica un aterrizaje real para sacudir la cámara, reproducir sonido o agacharse.
- **Huellas, polvo o sonido de un pie:** `get_step_foot()` al recibir `stepped`.
- **Sonido o animación de subir un escalón:** `stair_taken(height)`. No sirve para suavizar: el cuerpo ya está
  encima del escalón.
- **Pies apoyados en escaleras, modelo elevado del suelo:** `get_ground_height()`.

**Sin pasos** (`is_counting_steps()` es false) no se emite `stepped`; `get_step_phase()`, `get_gait_cycle()` y
`get_step_foot()` se quedan en su último valor. En tal caso, las animaciones de piernas no deben seguirlos.
El personaje sigue corriendo, saltando y subiendo escaleras.

`HandSway` sigue la fase de los pasos; una animación puede hacer lo mismo. La forma habitual de controlar un
`AnimationTree` es fijar sus mezclas a partir de las consultas en cada fotograma y cambiar la máquina de estados con las
señales:

```gdscript
@export var character: GroundCharacter
@export var tree: AnimationTree


func _ready() -> void:
	character.state_changed.connect(_on_state_changed)
	character.landed.connect(func(_speed: float) -> void:
		tree.set("parameters/land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE))


func _process(_delta: float) -> void:
	# A BlendSpace1D with idle at 0, run at 1 and sprint at 2; for sidesteps, a BlendSpace2D and get_local_movement().
	tree.set("parameters/ground/blend_position", character.get_locomotion_blend())


func _on_state_changed(state: GroundCharacter.State, _previous: GroundCharacter.State) -> void:
	var in_air := state == GroundCharacter.State.JUMPING or state == GroundCharacter.State.FALLING
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	playback.travel("air" if in_air else "ground")
```

Para que los pies vayan acompasados con el suelo, reproduce el ciclo de carrera según la distancia y no según el tiempo:
fija su posición en `get_gait_cycle()` multiplicado por su duración (un nodo `TimeSeek`, o un `AnimationPlayer` en pausa
con `seek()`). El ciclo debe empezar con el pie izquierdo tocando el suelo.

### CharacterMonitor: el estado como texto

Un `Label` que muestra lo que está haciendo un `GroundCharacter` y sus últimos eventos, para ajustar animaciones o como
superposición de depuración. En la demo es `Hud/CharacterState/Monitor`, y lo muestra Configuración (F10) → Interfaz →
**Estado del personaje y eventos**. El texto sale solo de las señales y consultas de arriba, así que el script también
es un ejemplo de cómo usarlas.

```
Running
Speed 5.5 m/s · blend 1.00
Forward +1.00 · right +0.00
Turning +0°/s
On the ground · slope 0°
Step 38 · left foot · cycle 0.03
Stamina 100%

11.83 s  Jumping → Falling
12.08 s  touched the ground at 7.8 m/s
12.08 s  landing at 7.8 m/s
12.08 s  Falling → Running
12.35 s  step, right foot
12.62 s  step, left foot
```

Línea por línea:

1. Estado devuelto por `get_state()`.
2. Velocidad real (`get_move_speed()`) y valor de mezcla.
3. Movimiento firmado en los ejes del modelo: adelante +1.00 indica carrera plena; −0.70, retroceso; derecha
   −1.00 indica desplazamiento lateral a la izquierda.
4. Rapidez del giro en grados por segundo, positiva hacia la izquierda. Es velocidad, no ángulo: se muestra
   mientras gira y vuelve a 0 cuando el modelo termina de orientarse.
5. En el suelo, pendiente bajo los pies; en el aire, tiempo transcurrido y velocidad vertical.
6. Número de pasos, pie del último y ciclo de marcha; «Sin pasos» cuando no se cuentan.
7. Resistencia y «agotado» cuando no puede esprintar.

Debajo aparecen los últimos eventos del más antiguo al más reciente, con el tiempo desde el inicio: pasos con
pie, escalones con altura, saltos, despegues, aterrizajes con velocidad de caída, sprint y cambios de estado. Cuando
está visible, el panel reconstruye el texto en cada fotograma. Oculto, omite ese trabajo, pero sigue registrando
los eventos (y los imprime si se activa `log_events`).

| Propiedad | Por defecto | Significado |
|---|---|---|
| `character` | — | El `GroundCharacter`; si está vacío, el padre |
| `history_size` | 6 | Cuántos eventos recientes mostrar bajo el estado; 0 muestra solo el estado |
| `log_events` | desactivado | Además, imprimir cada evento en la salida con su tiempo y el nombre del personaje |
| `include_steps` | activado | Mostrar y registrar pasos y escalones: hay varios por segundo |

Métodos: `get_text_now()`, `get_state_lines()`, `get_event_lines()`, `get_state_name(state, translated)`. Las frases
pasan por `tr()`, así que el panel habla el idioma de la interfaz; el registro en la salida se queda en inglés.

### Escalones y pendientes

**Las pendientes** son tarea del propio `move_and_slide()`: el cuerpo sube caminando por una superficie no más empinada
que `floor_max_angle` y se detiene ante una más empinada. Con `floor_constant_speed`, que el cuerpo de la demo tiene
activado, conserva su velocidad en una rampa.

**Los escalones.** Una cápsula sube por sí sola a una cornisa solo hasta `radius × (1 − cos floor_max_angle)`, 0,1 m
para la cápsula de 0,35 m. Los escalones más altos, hasta `max_step_height`, los sube el propio cuerpo:

- **Subida.** Si el movimiento del tick, mirado 5 cm más allá, choca con algo demasiado empinado para pararse encima, el
  cuerpo prueba un escalón: sube `max_step_height` (o lo que permita un techo), avanza el movimiento del tick y baja
  hasta el suelo. Un rayo comprueba la parte de arriba: debe ser suelo a no más de `max_step_height` sobre los pies, así
  que un bloque de 0,4 m o una pendiente empinada no son un escalón. El cuerpo se coloca sobre el escalón, y
  `move_and_slide()` solo lo asienta ahí.
- **Bajada.** Si el cuerpo estaba en el suelo antes del tick y está en el aire después sin haber saltado, y hay suelo a
  no más de `max_step_height` por debajo, el cuerpo se coloca sobre ese suelo: sin `left_floor` y sin caída.
- Cada escalón que sube o baja el cuerpo se comunica mediante `stair_taken(height)`: altura real entre el suelo
  anterior y el del escalón, +0.2 m al subir los de la demo y −0.2 m al bajarlos.
- La parte inferior redonda de la cápsula se apoya en ángulo sobre el borde de un escalón, demasiado empinado para
  pararse mientras el cuerpo está lejos del borde. Por eso el lugar sobre el escalón se busca un poco más allá, en pasos
  de 2 cm: el cuerpo termina hasta unos centímetros más adelante de donde lo llevaría el tick.

Cada escalón cuesta cerca de un tick rodando sobre su borde, en el que la velocidad horizontal baja a cerca del 70%
(`get_move_speed()` lo muestra; el bastón en la mano no lo acusa porque `HandSway` sigue
`get_local_acceleration()`). Para una escalera larga, lo más suave es un colisionador de rampa invisible.

El cuerpo sube un escalón de inmediato: en uno de 0.2 m avanza unos 0.1 m en un tick y el resto durante los dos o
tres ticks siguientes, mientras la cápsula rueda sobre el borde. La interpolación de física lo distribuye entre
fotogramas, aunque en pantalla todavía se percibe una breve sacudida. Un modelo flotante se desliza suavemente
sobre los escalones (`CharacterHover`) y `height_follow_time` de la cámara suaviza la subida de la vista (0.15 s
en la demo; consulta [Cámara](camera.md#propiedades)).

La malla de navegación debe unir lo que el cuerpo puede subir: en la demo `agent_max_climb` es 0,3 m, igual que
`max_step_height` (ver [Mundo y navegación](world-and-navigation.md#capas-de-física-y-navegación)).

### El salto

La velocidad de despegue es `v = √(2·g·h)`. En el tick del despegue el cuerpo recibe `v − g·dt/2` y ninguna otra
gravedad, incluso durante el tiempo de gracia: así sus
posiciones en cada tick caen exactamente sobre la parábola, y la altura del salto no depende de la frecuencia de
ticks. Con `v` a secas el salto sería `v·dt/2` más alto, 1,064 m en lugar de 1 m a 60 ticks. En la demo, un salto de
1 m dura 0,52 s con `gravity_scale` 3.

En el aire el personaje sigue corriendo como lo hacía, y los controles siguen siendo los mismos. La protección de
bordes no retiene un salto: saltar desde el borde de una plataforma es un paso deliberado, no un accidente.

### La caída

El descenso desde el punto más alto de un salto o desde un borde sigue un recurso `FallSettings`: el `fall` propio
del personaje o el que un componente haya colocado en su lugar. El ascenso del salto no cambia: frena con
`gravity_scale`, por lo que alcanza `jump_height` con cualquier configuración de caída. Sin ese recurso, el
personaje cae como antes, sin límite, con la gravedad del lugar multiplicada por `gravity_scale`, sea cual sea su
dirección. Con él, la gravedad horizontal de un área sigue atrayendo del mismo modo; si no hay gravedad hacia
abajo, como en una corriente ascendente, el recurso no tiene una caída que modificar.

| Propiedad | Valor predeterminado | Significado |
|---|---|---|
| `gravity_scale` | 0 | Veces que se multiplica la gravedad durante el descenso: determina cómo gana velocidad. Si es menor que la del personaje, baja más lentamente de lo que sube. 0 toma su `gravity_scale`, así que un recurso nuevo no cambia nada y un límite de velocidad por sí solo conserva la gravedad anterior |
| `max_speed` | 0 m/s | Velocidad máxima de caída: acelera hasta ella y después la mantiene. 0 quita el límite |
| `braking_time` | 0.3 s | Tiempo para reducir hasta `max_speed` una caída más rápida (95% del exceso) tras un empujón hacia abajo o al activar el recurso a mitad de una caída. 0 es inmediato |

Un componente puede sustituir `fall` temporalmente con `set_fall_override(self, settings, priority)` y retirarlo
con `null`. Si hay varios, gana la prioridad mayor (0 de forma predeterminada) y, entre iguales, el que asignó
el suyo más recientemente. Cambiar solo los ajustes o la prioridad de un componente no altera su orden. `fall`
permanece intacto, así que vuelve a aplicarse cuando se retiren los componentes. El personaje no mantiene vivo
al componente: si se libera, su sustitución desaparece sola. `get_fall_settings()` devuelve la caída activa.
`CharacterHover` asigna su propio `fall` con prioridad 0 cada vez que el modelo empieza a subir; consulta
[Personajes](characters.md#la-caída). Una prioridad 1 puesta por el juego, como un hechizo de caída lenta, prevalece
incluso con la flotación activada.

`touched_floor` y `landed` comunican la velocidad al tocar el suelo. `touched_floor` se emite también tras un
contacto suave. Una caída limitada por debajo de
`landing_min_speed` solo emite `touched_floor`; `landed` aparece si un empujón hace que el personaje toque el suelo
antes de reducir su velocidad. En el `fall` propio del personaje eso produce una advertencia de configuración:
tras un salto nunca se activarían sonido y efectos de aterrizaje. En el personaje flotante es intencional: aterriza
suavemente. Un límite exactamente igual a `landing_min_speed` sí cuenta como aterrizaje.

El héroe de la demo no tiene `fall` propio. Su flotación usa `gdscript/player/player_floating_fall.tres`: escala
de gravedad 0.5 en lugar del 3 del cuerpo y velocidad máxima descendente de 2 m/s. Así, después de un salto de
1 m permanece 0.95 s en el aire en vez de 0.52 s y toca el suelo a 2 m/s en vez de 7.8 m/s.
`FallSettings.get_next_speed(speed, acceleration, delta)` y `get_gravity_scale(own)` permiten aplicar esa caída
paso a paso en tu propio cuerpo.

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
| `max_drop` | 0.5 m | Protege ante caídas más profundas; las menores pueden cruzarse. Solo las de altura hasta `GroundCharacter.max_step_height` se bajan como escalón sin caer |
| `edge_margin` | 0,15 m | Qué tan cerca del borde puede llegar el centro del personaje |
| `margin_probes` | 6 | Rayos alrededor del círculo de `edge_margin` |
| `probe_height` | 0,5 m | Los rayos parten a esta altura sobre los pies, para encontrar suelo algo por encima de ellos (una rampa) |
| `floor_mask` | 0 | Qué cuenta como suelo; 0 toma la máscara de colisión del cuerpo y protege exactamente ante lo que este puede pisar |
| `slide_iterations` | 6 | Divisiones a la mitad del ángulo de deslizamiento; 6 da unos 1,4° |

En terreno abierto son 7 rayos por tick, hasta 98 en un borde. En el aire la protección no hace nada. Una ruta que
baja de la plataforma sigue la rampa, y la protección no le estorba. Solo cuenta como suelo lo que el cuerpo
puede pisar, con pendiente no mayor que `floor_max_angle` y el mismo margen pequeño de la comprobación del motor
(`GroundCharacter.FLOOR_ANGLE_MARGIN`). Si `floor_mask` incluye capas con las que el cuerpo no colisiona,
aparece una advertencia: la protección trataría como suelo algo que el cuerpo atraviesa.

## Comportamiento medido

Las comprobaciones de escena en `tests/movement_checks.gd`, `tests/character_actions_checks.gd` y
`tests/character_state_checks.gd` prueban al héroe suministrado a 60 ticks de física:

- Con carrera de 5.5 m/s y aceleración de 0.18 s, llega al 95% de velocidad en 0.18 s; detenerse normalmente
  desde el 95% lleva unos 0.20 s. Un destino nuevo durante el frenado conserva la velocidad, y un clic en dirección
  contraria produce un giro en arco.
- El sprint alcanza 8.25 m/s. Con duración de resistencia de 2 s en la prueba, se agota, se recupera sobre el
  umbral y reanuda el sprint si la tecla sigue pulsada.
- Un salto de 1 m alcanza 1.000 m y dura unos 0.52 s en el aire. Una pulsación guardada justo antes de aterrizar
  se ejecuta entonces; otra poco después de dejar un borde funciona durante el tiempo de gracia.
- Los escalones de 0.2 m de la demo se suben y bajan sin despegar del suelo; `stair_taken` informa de cada uno.
  Un bloque de 0.4 m y una pendiente de 50° detienen el cuerpo. La protección detiene una carrera hacia el borde
  de la plataforma y desliza junto a él una carrera oblicua.
- Con gravedad de caída 0.5 y límite de 2 m/s del modelo flotante, el salto sigue midiendo 1 m pero el contacto
  con el suelo ocurre a 2 m/s, bajo el umbral predeterminado de aterrizaje de 2.5 m/s. Estos resultados dependen
  de cápsula, colisionadores, malla y ajustes suministrados: prueba los cambios en tu propio nivel.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
