<!-- translation of docs/en/systems/characters.md @ 48c5e73646e2 -->
# Personajes

[← Índice de documentación](../index.md)

> Esta es una traducción del [original en inglés](../../en/systems/characters.md).
> Si hay diferencias, la versión en inglés es la correcta.

Un script construye los modelos de personaje con primitivas (cápsulas, cilindros, esferas, prismas), y estos viven
separados de la lógica, en `shared/characters/`. El mismo modelo puede ser el del héroe o estar de pie en el nivel.
Para copiar el héroe montado y sus archivos a otro proyecto, sigue
[Integración](../integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto).
[Configuraciones](../configurations.md) explica las opciones de control y cámara.

## Modelos y equipo

| Modelo (`shared/characters/models/`) | Quién | Equipo |
|---|---|---|
| `knight.tscn` | Caballero: armadura de placas, un yelmo cerrado con visera en forma de T y una cresta roja, una sobreveste roja con una cruz, hombreras | Espada, escudo redondo con una cruz |
| `ranger.tscn` | Explorador: una capucha verde con cola, ojos claros en su sombra, un carcaj con flechas a la espalda | Arco |
| `mage.tscn` | Mago: una túnica morada acampanada con ribetes dorados, un sombrero puntiagudo doblado, una barba blanca | Un orbe luminoso flotante con anillos, un libro de hechizos |
| `dwarf.tscn` | Enano: bajo y ancho, una barba roja con una cuenta, una nariz, un casco con cuernos | Hacha a dos manos |
| `rogue.tscn` | Pícaro: una capucha oscura, ojos amarillos, una máscara roja, una capa de tres paneles, una bolsa en el cinturón | Dos dagas, la izquierda con agarre invertido |

Convenciones de los cinco modelos independientes anteriores:

- Mira hacia −Z con los pies en el origen.
- Sus manos son nodos vacíos `RightHand` y `LeftHand`, "manos invisibles". Una escena de `equipment/` (bastón,
  espada, escudo, arco, hacha, daga, libro, orbe) va en una mano; el origen del equipo es el punto por donde se
  sujeta. Para cambiar un arma, reemplaza el hijo del nodo de la mano: en tiempo de ejecución en el juego, o de forma
  permanente en la escena del modelo. La inclinación del objeto es su rotación en la mano.
- Los materiales compartidos del equipo (acero, latón, cuero, hueso, gemas y ojos luminosos) están en `materials/`;
  los colores del cuerpo y de la ropa están dentro de las escenas de los modelos.

## Aspectos del héroe

El héroe usa uno de diez aspectos de mago (el Nigromante, aspecto 8, por defecto), colocado en
`Hero/Character/Visual/Hover/Model`. Gira con `Visual` y flota con el nodo de flotación cuando se activa. Lleva el
bastón en la mano derecha. Todos los aspectos están dimensionados para la cápsula de colisión separada del jugador,
tienen ojos propios (`EyeRight`, `EyeLeft`) y bastón en `RightHand`, así que cualquiera sirve como héroe.

| # | Aspecto | Qué lo distingue |
|---|---|---|
| 1 | Mago de tormenta | Una túnica color pizarra con relámpagos y un dobladillo luminoso, nubes de tormenta sobre los hombros, una capucha con una cresta chispeante y ojos de chispa entrecerrados en su sombra, un bastón con un rayo globular |
| 2 | Cronomante | Una túnica turquesa con bronce, una esfera de reloj en el pecho, un halo de reloj, engranajes flotantes, gafas de latón con lentes ámbar, un bastón con reloj de arena |
| 3 | Místico encapuchado | Una capucha y una capa amplias; sin rostro, solo dos ojos ámbar luminosos en la sombra |
| 4 | Astrólogo | Una túnica azul noche con estrellas, un sombrero con una luna, ojos grandes que miran hacia las estrellas, un bastón con una estrella entre anillos |
| 5 | Piromante | Una túnica escarlata con llamas en el dobladillo, en los hombros y a modo de corona, ojos de fuego enojados, un bastón de fuego |
| 6 | Criomante | Una túnica blanca con piel, una corona de hielo y cristales en los hombros, ojos serenos de un azul brillante, un bastón de cristal |
| 7 | Druida | Una túnica marrón, una capa de hojas, astas ramificadas, ojos animales ámbar con pupilas rasgadas, un bastón nudoso con una semilla |
| 8 | Nigromante | Una túnica negra y violeta con el dobladillo raído, un cuello en abanico, luces verdes en las cuencas de los ojos, una calavera en el hombro y en el bastón |
| 9 | Archimago | Túnicas blancas y doradas, una barba, un sombrero alto con un zafiro, bondadosos ojos de zafiro y un monóculo, un anillo de runas alrededor de la cintura |
| 10 | Mago de batalla | Una túnica corta, hombreras de placas, una capa, pociones en el cinturón, un libro en la cadera, ojos dorados bajo cejas severas, un bastón lanza |

Los modelos están en `shared/characters/models/mage_options/`, sus bastones en `equipment/staff*.tscn`. La mano está
a 0,52 m del eje del cuerpo, para que la parte inferior del bastón no se hunda en la túnica; el Archimago lo sostiene
a 0,55 m y el Mago de batalla a 0,49 m. Los aspectos del héroe solo tienen `RightHand`; el libro del Mago de batalla
cuelga en `LeftHip`.

En el nivel inicial (`shared/world/world.tscn`), los diez están en fila en el lado sur del muro sur, de espaldas
a él (al este del hueco del muro),
mirando al sur, cada uno con su número encima. Hay un pasillo despejado delante de toda la fila.

## CharacterAppearance

Cambia el modelo en tiempo de ejecución (Configuración → Personaje → **Aspecto del héroe**). `set_look(number)` quita
el modelo anterior y pone el nuevo en su lugar con el mismo nombre. También restablece la interpolación de física del
nuevo modelo (de lo contrario el modelo llegaría deslizándose desde el origen) y entrega la `RightHand` del nuevo
modelo a `HandSway`, para que el bastón vuelva a balancearse con los pasos. La silueta toma las nuevas mallas por sí
sola.

| Propiedad | Por defecto | Significado |
|---|---|---|
| `slot` | — | Nodo que contiene el modelo (`Visual/Hover` en el jugador: el flotador bajo el `Visual` que gira `GroundCharacter`) |
| `model_name` | `Model` | Nombre del nodo del modelo dentro de `slot` |
| `models` | — | Escenas de modelos para elegir; el número de aspecto es la posición en esta lista, desde 1 |
| `hand_sway` | — | Quién recibe la mano del nuevo modelo; si está vacío, la mano no se balancea |
| `hand_path` | `RightHand` | Dónde está en el modelo la mano que sostiene un objeto |

`get_look()` devuelve el número actual (0 para un modelo que no está en la lista), `get_model()` el nodo del modelo.
Señal: `look_changed(model)`.

### Usar tu modelo con el héroe jugable

1. Edita `gdscript/player/player.tscn` que usa tu copia de `playable_hero.tscn`, o sustituye su instancia
   `Character` por una copia de la escena. Conserva las rutas de nodos o reasigna las referencias exportadas del
   héroe. Sustituye `Visual/Hover/Model` por tu escena de modelo y llama `Model` a su raíz. Coloca los pies en el
   origen local y oriéntalo hacia −Z. Corrige dentro de la escena una malla orientada de otro modo para dejar
   `Visual` libre para que lo gire `GroundCharacter`. La cápsula de colisión está en el cuerpo, separada del
   modelo: cambia `CollisionShape3D` y vuelve a hornear la malla de navegación si necesita otro espacio libre
   (consulta [Mundo y navegación](world-and-navigation.md#capas-de-física-y-navegación)).
2. Si quieres alternar aspectos, agrega tus escenas a `Appearance.models`; los números empiezan en 1. Cada
   modelo debe tener una mano en `Appearance.hand_path` (`RightHand` por defecto). Si no hay mano, elimina
   `RightHandSway` y vacía `Appearance.hand_sway`. `CharacterAppearance.set_look()` asignará al balanceo la mano
   nueva, mientras la silueta detectará automáticamente las mallas nuevas.
3. Si usas un solo modelo, elimina `Appearance` y vacía la referencia `appearance` del héroe. Elimina también
   `RightHandSway` si no hay objeto en la mano. Si conservas `Appearance` en la demo completa, sustituye también
   su lista `models`: `SettingsApplier` llama a `set_look()` con el número guardado al iniciar y una lista sin
   cambiar devolvería un modelo de mago.

El modelo debe caber en la cápsula y bajo los techos cercanos. El modelo flotante sube sin mover su forma de
colisión: deja espacio sobre él o mantén `Hover.enabled` desactivado. `Silhouette.target` y
`CameraArm.fade_target` ya apuntan a `Visual` y seguirán incluyendo un modelo nuevo colocado debajo.

## HandSway: un bastón en la mano, no pegado al costado

`HandSway` (`RightHandSway` en el jugador) mueve el nodo de la mano del modelo respecto a su posición de reposo:

- **Con los pasos**, según `GroundCharacter.get_step_phase()`, el mismo ritmo que siguen los sonidos de los pasos. En
  cada paso la mano está en un extremo (delante y detrás alternadamente, ±7 cm) y en su punto más bajo (2,5 cm); a
  mitad de camino entre pasos está en el medio. El objeto se retrasa un poco en la inclinación (±7°). El balanceo
  crece con la velocidad, es una vez y media más amplio en sprint y se desvanece cuando el personaje se detiene o
  está en el aire. Sin pasos (`is_counting_steps()` es false porque `steps_enabled` está desactivado o el héroe
  flota), el balanceo se desvanece y vuelve cuando se reanudan los pasos.
- **Al correr**, el objeto se inclina hacia adelante (6°).
- **Inercia** con un resorte (1.8 Hz, amortiguación 0.45) a partir de
  `GroundCharacter.get_local_acceleration()`: al acelerar la punta va hacia atrás, al frenar hacia adelante y al
  girar hacia afuera; luego oscila hasta asentarse. Los escalones no la sacuden. Al tocar el suelo, la mano baja
  más cuanto más rápida fue la caída (`touched_floor`, incluso en un aterrizaje suave); al despegar baja un poco.
  `tilt_per_acceleration` (0.45°) positivo hace que el objeto quede atrás; negativo lo inclina hacia la
  aceleración. El resorte es `DampedSpring`, que también usa `CharacterHover`.

Se ejecuta en el tick de física después del cuerpo, así que la interpolación de física lo suaviza igual que al
cuerpo. El ritmo de los pasos es continuo: detente a mitad de un paso y el siguiente llegará `first_step_distance`
después de volver a arrancar, pero la fase no salta; alcanza el número entero en ese paso. Para otra mano o un NPC,
agrega otro `HandSway` con su propia mano. Las amplitudes, la inclinación y el resorte son propiedades exportadas en
los grupos Swing e Inertia.

## CharacterHover: flotar sobre el suelo

`CharacterHover` hace que un `GroundCharacter` parezca flotar: el modelo queda a una altura `height` sobre el suelo,
se desliza por escaleras en vez de subir a sacudidas, oscila suavemente arriba y abajo, se inclina según movimiento
y aceleración y desciende un poco al aterrizar. Solo se mueve el modelo. El cuerpo sigue caminando normalmente:
pendientes, escalones, saltos y protección de bordes funcionan igual; también rutas y cámara. Su recurso opcional
`FallSettings` puede cambiar la aceleración descendente y limitar la velocidad de caída; el héroe lo usa para
bajar más despacio. En la demo se activa con Configuración → Personaje → **Flotar sobre el suelo**.

El nodo se sitúa entre el nodo que gira el personaje y el modelo:

```
Player (GroundCharacter)   Hero/Character in the demo
└── Visual            turned by GroundCharacter toward the way it goes
    └── Hover         CharacterHover: raises and tilts itself
        └── Model     the look; CharacterAppearance.slot is Visual/Hover
```

El personaje solo escribe el giro de `Visual`, y `Hover` solo su propia transformación: no compiten por el mismo
nodo. Un aspecto nuevo de `CharacterAppearance` se coloca bajo el flotador (`slot`), y la silueta y la transparencia
de cámara encuentran allí el modelo sin trabajo adicional. La inclinación se aplica según los ejes de `Visual`,
por lo que un flotador girado en la escena para un modelo orientado de otra manera aún se inclina hacia el movimiento.

### Pasos

Por defecto, flotar suspende los eventos de pasos. El flotador usa
`GroundCharacter.set_steps_suppressed(self, true)`: no hay `stepped`, sonido de pasos ni balanceo del bastón debido
a ellos. Cuando el modelo vuelve a asentarse en el suelo, los libera y se cuentan otra vez si `steps_enabled`
sigue activo. Nunca cambia `steps_enabled`: el interruptor del juego conserva su valor y varios componentes pueden
suspender los pasos sin anularse. Al salir del árbol, los libera; al volver, los suspende. Con
`steps_while_floating` se mantienen, por ejemplo para una criatura que se impulsa desde el suelo al ritmo de sus
pasos. `GroundCharacter.is_counting_steps()` indica si se cuentan ahora.

### La caída

Si se asigna `fall` (un `FallSettings`, consulta [Locomoción](locomotion.md#la-caída)), el flotador lo pone en
lugar de la caída propia del personaje mientras flota, desde el comienzo de la subida hasta asentarse
(`GroundCharacter.set_fall_override(self, fall)`, prioridad 0). Tras el punto más alto de un salto o al salir de
un borde, gana velocidad más lentamente y solo hasta un límite. El ascenso del salto no cambia. Si activas la
flotación a mitad de una caída, la velocidad disminuye hasta el límite durante `braking_time`; si la desactivas,
continúa lenta hasta que el modelo se asiente y después vuelve a acelerar normalmente. Al salir del árbol, el
flotador devuelve la caída. Si `fall` está vacío, se conserva exactamente la caída propia, como a pie.
Cada vez que el modelo empieza a subir, el flotador vuelve a asignar su caída y pasa a ser la más reciente entre
las de prioridad 0. Una caída del juego con prioridad mayor prevalece; si se asigna un `fall` nuevo al flotador
mientras está activo, conserva la posición de la sustitución anterior.

El flotador de la demo usa `gdscript/player/player_floating_fall.tres`: escala de gravedad 0.5, frente al 3 del
cuerpo, y velocidad máxima descendente de 2 m/s. Desde lo alto de un salto de 1 m, un héroe flotante tarda 0.68 s
en bajar, frente a 0.25 s, y toca el suelo a 2 m/s, por debajo de `landing_min_speed` (2.5 m/s): aterrizaje suave
sin `landed` ni sonido de aterrizaje.

### Cómo sigue el suelo

El modelo flota sobre una altura del suelo suavizada. Mientras el cuerpo está en el suelo, mira hacia delante por
su trayectoria y se acerca a la altura encontrada durante `glide_time`. Mira exactamente tan lejos como lo que
retrasa el suavizado: en una rampa no hay retraso, y ante una escalera el modelo comienza a subir antes del escalón
y recorre la sucesión con una línea suave, sin bajar mientras asciende. Sobre el borde de un escalón queda cerca
de medio escalón por debajo de su altura relativa al peldaño bajo él: sigue la línea de la escalera, no cada
peldaño por separado.

La trayectoria se examina con rayos en tramos de hasta 0.15 m, hasta 0.9 m por delante. En cada tramo, el suelo
no puede subir o bajar más que un escalón (`max_step_height`) o una pendiente máxima. Un rayo que comienza dentro
de un cuerpo no encuentra suelo, por lo que una pared también detiene la búsqueda. Así el modelo permanece
nivelado antes de un borde, hueco o pared que el cuerpo no cruzará, y no se eleva hacia una terraza tras una
valla. En los cambios de pendiente al principio y final de una rampa, redondea la transición: empieza a subir
un poco antes y se nivela algo antes de llegar arriba, hasta unos 0.05 m bajo la altura ideal en la rampa de
15° de la demo.

En el aire y durante el tick de aterrizaje, el modelo acompaña exactamente al cuerpo: el salto conserva su arco
y al salir de un borde ambos caen juntos. Lo que quedaba del deslizamiento al despegar se desvanece en
`glide_time`.

Los rayos tienen un coste: hasta siete por tick si flota y corre, uno si permanece quieto y ninguno si está en
el aire o no flota. Al teletransportar al personaje (`GroundCharacter.teleport()`), el modelo se coloca al instante,
con o sin interpolación de física; lo mismo sucede al reiniciarla manualmente con
`reset_physics_interpolation()` (sin efecto si está desactivada) y tras un movimiento horizontal de más de un
metro en un tick. `snap()` permite hacerlo manualmente.

### La oscilación

La oscilación depende del tiempo y continúa incluso parado: un ciclo vertical dura `bob_period` (2.4 s) y tiene
altura `bob_height` (4 cm). El movimiento la modifica según la velocidad, desde reposo hasta carrera (mezcla
de 0 a 1): al correr, la frecuencia es `run_bob_rate` (1.5) veces mayor y la amplitud `run_bob_scale` (0.5)
veces menor, de modo que oscila más rápido pero con calma. La fase del ciclo avanza con el tiempo y un cambio de
velocidad nunca hace saltar el modelo. Con `random_bob_phase`, cada flotador comienza en un punto aleatorio y
varios personajes no oscilan al unísono. Nunca baja más que `height`, evitando penetrar en el suelo.

### Inclinación e inercia

- **Inclinación al correr.** `run_lean` (8°) inclina hacia el movimiento a velocidad de carrera: adelante al
  avanzar, al lado en un desplazamiento lateral y atrás al retroceder; al esprintar aumenta hasta
  `max_lean_scale` (1.5) veces.
- **Inercia.** `tilt_per_acceleration` por cada 1 m/s² de `GroundCharacter.get_local_acceleration()`, con límite
  `max_inertia_tilt` (15°) en cada dirección. El signo coincide con `HandSway`: positivo retrasa el modelo como
  un peso colgado; negativo lo inclina hacia la aceleración, como una nave flotante: adelante al acelerar,
  atrás al frenar y hacia el interior al girar. El valor predeterminado del flotador es −0.25°.
- Ambas pasan por resortes (`spring_frequency` 1.5 Hz, `spring_damping` 0.5). El modelo gira alrededor de un
  punto `tilt_pivot_height` (0.9 m) sobre los pies, cerca de la cintura, para que estos no oscilen demasiado.
- **Hundimiento.** Al tocar el suelo (`touched_floor`, incluso con suavidad), el modelo recibe un empuje hacia
  abajo de `landing_kick` por cada 1 m/s de velocidad de caída; al saltar, de `jump_kick`. El resorte lo devuelve.
  Nunca baja más de `max_drop` (0.15 m) ni más que su altura sobre el suelo. El flotador de la demo usa
  `landing_kick` 0.2: al aterrizar suavemente a 2 m/s se hunde unos 2 cm.

### Activar y desactivar

Al activarlo, el modelo sube a `height` durante `rise_time` (0.5 s), suavemente al principio y al final. Al
desactivarlo, baja en el mismo tiempo y los pasos vuelven cuando toca el suelo. Oscilación, inclinación y
hundimiento crecen y desaparecen con la subida. Si `enabled` se establece antes del primer tick de física (en
la escena o mediante ajustes guardados al inicio), se aplica de inmediato y no hay animación de subida.

`floating_changed(floating)` llega al comienzo de la subida y cuando el modelo se ha asentado.
`is_floating()` indica si flota ahora y `get_hover_height()` cuánto sube el modelo sobre los pies del cuerpo.

### Propiedades

| Grupo | Propiedad | Valor predeterminado | Significado |
|---|---|---|---|
| | `character` | — | `GroundCharacter`; si está vacío, el más cercano por encima del nodo |
| | `enabled` | activado (desactivado en la escena de la demo) | Activa la flotación |
| | `height` | 0.35 m | Altura de los pies del modelo sobre el suelo |
| | `rise_time` | 0.5 s | Duración de subida o descenso; 0 es inmediato |
| | `steps_while_floating` | desactivado | Conserva los pasos al flotar |
| | `fall` | — (`player_floating_fall.tres` en la demo) | Caída durante flotación; vacío: igual que sin flotación |
| Deslizamiento | `glide_time` | 0.3 s | Tiempo hasta cubrir el 95% de una nueva altura del suelo; 0 sigue cada escalón bajo el cuerpo |
| Oscilación | `bob_height` | 0.04 m | Amplitud vertical en reposo |
| | `bob_period` | 2.4 s | Duración de una oscilación en reposo, desde 0.5 s |
| | `run_bob_scale` | 0.5 | Amplitud al correr como fracción de `bob_height` |
| | `run_bob_rate` | 1.5 | Cuántas veces más rápida es la oscilación al correr |
| | `random_bob_phase` | activado | Inicia en un punto aleatorio del ciclo |
| Inclinación | `run_lean` | 8° | Inclinación hacia el movimiento a velocidad de carrera |
| | `max_lean_scale` | 1.5 | Multiplicador máximo de inclinación durante sprint |
| | `tilt_pivot_height` | 0.9 m | Altura del punto de giro sobre los pies |
| Inercia | `tilt_per_acceleration` | −0.25° por m/s² | Positivo retrasa, negativo inclina hacia la aceleración |
| | `max_inertia_tilt` | 15° | Límite de inclinación por aceleración |
| | `landing_kick` | 0.05 (0.2 en la demo) | Empuje hacia abajo al tocar el suelo por cada 1 m/s de caída |
| | `jump_kick` | 0.3 m/s | Empuje hacia abajo al despegar |
| | `max_drop` | 0.15 m | Hundimiento máximo, nunca mayor que la altura sobre el suelo |
| | `spring_frequency`, `spring_damping` | 1.5 Hz, 0.5 | Resortes de inclinación y hundimiento |

### Aspectos a tener en cuenta

- El modelo flota `height` más alto que el cuerpo; `focus_height` de la cámara y `occlusion_points` del brazo
  se miden desde el cuerpo: súbelos si el modelo flota mucho.
- Bajo un techo bajo, el modelo puede penetrarlo: el cuerpo no conoce la altura adicional.
- Solo el modelo suaviza los escalones. La cámara sigue el cuerpo; `height_follow_time` suaviza la subida en la
  vista (0.15 s en la demo).
- Una caída limitada por debajo de `landing_min_speed` nunca emite `landed`: no suena el aterrizaje ni ocurre
  nada que espere esa señal. Si debe sonar también al flotar, establece en su `fall` un `max_speed` al menos
  igual a `landing_min_speed` o reduce este último. Si está por debajo de `landing_min_speed`, el contacto es suave.
- Arriba debe ser +Y, como para todo el personaje.
- Con el tiempo detenido (`Engine.time_scale` 0), el modelo flotante permanece inmóvil, igual que la mano de
  `HandSway`; consulta [Locomoción](locomotion.md#groundcharacter).
- Un fallo de configuración se imprime como advertencia al iniciar: flotador fuera del `Visual` del personaje,
  modelo ausente bajo él, segundo flotador en el mismo personaje o `CharacterAppearance.slot` que no apunta al
  flotador.
- `DampedSpring` es el resorte compartido por flotador y `HandSway`:
  `update(target, frequency, damping, delta)`, `value`, `speed`, `keep_within(limit)`, `reset()`. Un resorte rígido
  se calcula en varios pasos pequeños por tick para mantenerse estable con cualquier ajuste.

### Comportamiento medido

Según `tests/character_state_checks.gd`, con los ajustes de la demo a 60 ticks de física y, para medir la
trayectoria, sin oscilación:

- Parado: entre 0.31 y 0.39 m sobre los pies (0.35 m más la oscilación de 4 cm).
- En las escaleras al este de la plataforma, la subida del modelo varía como máximo 0.031 m por tick, frente a
  0.100 m al subir y 0.138 m al bajar del cuerpo. El modelo no se mueve en sentido contrario y permanece al
  menos 0.17 m sobre el escalón bajo él.
- En la rampa: entre 0.347 y 0.350 m sobre el suelo en la zona central, sin retraso; en los extremos baja a
  0.30 m.
- Durante un salto sin empujes, mantiene su altura respecto al cuerpo dentro de 0.6 mm incluso al aterrizar;
  con ellos se hunde 0.021 m al tocar el suelo a 2 m/s.
- Caída lenta: un salto de 1 m llega a 1.000 m y toca el suelo a 2.00 m/s, sin aterrizaje fuerte. Si se activa
  flotación durante una caída a 6.4 m/s, disminuye hasta 2.2 m/s en 0.3 s, a no más de 0.67 m/s por tick.
  Si se desactiva a mitad de caída, mantiene 2 m/s durante los 30 ticks del descenso del modelo y luego acelera
  a 29.4 m/s², como a pie.
- En el borde protegido de la plataforma, frente a un bloque de 0.4 m y ante una pared con terraza detrás:
  no se hunde ni sube.
- Desactivado y activado durante una carrera: como máximo 0.018 m por tick; se asienta en 31 ticks
  (`rise_time` 0.5 s) y entonces vuelven los pasos. Si el ajuste se guardó como activado, flota desde el primer
  fotograma.

## OccludedSilhouette: una sola forma, el arma contorneada, un borde

Donde algo oculta al héroe (la montaña, una casa, un árbol), el héroe se ve como una silueta azul claro: una forma
plana para el cuerpo, el equipo en la mano contorneado encima y un borde alrededor de todo.

`OccludedSilhouette` (`Silhouette` en el jugador) establece `material_overlay` en cada malla del modelo, incluidas las
mallas agregadas después (un nuevo aspecto o arma, mediante `SceneTree.node_added`). Los materiales propios del
modelo no cambian, así que el mismo modelo en el nivel no tiene silueta. Las mallas del cuerpo y las mallas bajo los
nodos de las manos (`gear_nodes`: `RightHand`, `LeftHand`) reciben cadenas de pasadas distintas.
Si el equipo usa otros nombres, configura `gear_nodes`. Si no encuentra ninguno, todas las mallas usan el relleno
del cuerpo. Un valor anterior de `material_overlay` en esas mallas se sustituye.

Cada píxel de la pantalla se pinta una sola vez, gracias al búfer de stencil: una pasada dibuja solo donde el valor de
stencil es menor que el suyo y escribe el suyo de inmediato (`stencil_mode read, write, compare_greater, N`). Los
shaders y materiales están en `addons/iso_orbit/occluded_silhouette/`:

| Pasada | `render_priority` | Stencil | Qué hace |
|---|---|---|---|
| `silhouette_mask` | 1 | escribe 4 | Invisible, con prueba de profundidad: marca dónde el personaje es visible por sí mismo, para que nada más se dibuje ahí |
| `silhouette_body` | 2 | < 2 → 2 | Relleno plano del cuerpo: las partes no se superponen y se funden en una sola forma |
| `silhouette_gear` | 3 | < 3 → 3 | Relleno más claro para el equipo, encima del cuerpo y con su propio contorno |
| `silhouette_outline` | 4 | < 1 → 1 | El borde: mallas infladas a lo largo de sus normales un 0,4% de la altura de la pantalla; solo queda la parte que está fuera de la forma completa |

Los rellenos y el borde solo se dibujan donde un obstáculo está al menos 30 cm más cerca que el fragmento (el búfer
de profundidad se convierte a metros en `silhouette_common.gdshaderinc`). Los objetos transparentes se ordenan
primero por `render_priority`, así que las pasadas se ejecutan en orden para todas las mallas a la vez.
Modifica `min_gap` en los materiales de cuerpo, equipo y borde a la vez para cambiar la separación. El componente
construye sus cadenas de pasadas en `_ready()`, así que cambia esos materiales antes de iniciar la escena.

`outline_enabled` (Configuración → Pantalla → **Contorno de silueta tras obstáculos**) quita la última pasada de las
cadenas. El ancho del borde es el parámetro `width` de `silhouette_outline.tres`; los colores son `color` en los
rellenos y en el borde.

Dos detalles del motor: el búfer de stencil es experimental en Godot 4.5+ y solo se puede leer en una pasada
transparente. Y en Godot 4.7 (D3D12 y Vulkan) la proyección en los shaders está invertida en Y:
`PROJECTION_MATRIX[1][1]` es negativo. Sin `abs()`, la conversión "fracción de la pantalla → metros" da un valor
negativo, la malla del borde se encoge y el borde desaparece.

## Editar los modelos

Los modelos se construyeron con primitivas mediante un script y ahora son escenas comunes: edítalos en el editor como
cualquier otra escena.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
