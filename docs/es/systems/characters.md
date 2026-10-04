<!-- translation of docs/en/systems/characters.md @ 1eac13a73cbf -->
# Personajes

> Esta es una traducción del [original en inglés](../../en/systems/characters.md).
> Si hay diferencias, la versión en inglés es la correcta.

Un script construye los modelos de personaje con primitivas (cápsulas, cilindros, esferas, prismas), y estos viven
separados de la lógica, en `shared/characters/`. El mismo modelo puede ser el del héroe o estar de pie en el nivel.

## Modelos y equipo

| Modelo (`shared/characters/models/`) | Quién | Equipo |
|---|---|---|
| `knight.tscn` | Caballero: armadura de placas, un yelmo cerrado con visera en forma de T y una cresta roja, una sobreveste roja con una cruz, hombreras | Espada, escudo redondo con una cruz |
| `ranger.tscn` | Explorador: una capucha verde con cola, ojos claros en su sombra, un carcaj con flechas a la espalda | Arco |
| `mage.tscn` | Mago: una túnica morada acampanada con ribetes dorados, un sombrero puntiagudo doblado, una barba blanca | Un orbe luminoso flotante con anillos, un libro de hechizos |
| `dwarf.tscn` | Enano: bajo y ancho, una barba roja con una cuenta, una nariz, un casco con cuernos | Hacha a dos manos |
| `rogue.tscn` | Pícaro: una capucha oscura, ojos amarillos, una máscara roja, una capa de tres paneles, una bolsa en el cinturón | Dos dagas, la izquierda con agarre invertido |

Convenciones que sigue cada modelo:

- Mira hacia −Z con los pies en el origen.
- Sus manos son nodos vacíos `RightHand` y `LeftHand`, "manos invisibles". Una escena de `equipment/` (bastón,
  espada, escudo, arco, hacha, daga, libro, orbe) va en una mano; el origen del equipo es el punto por donde se
  sujeta. Para cambiar un arma, reemplaza el hijo del nodo de la mano: en tiempo de ejecución en el juego, o de forma
  permanente en la escena del modelo. La inclinación del objeto es su rotación en la mano.
- Los materiales compartidos del equipo (acero, latón, cuero, hueso, gemas y ojos luminosos) están en `materials/`;
  los colores del cuerpo y de la ropa están dentro de las escenas de los modelos.

## Aspectos del héroe

El héroe es uno de diez aspectos de mago (el Mago de batalla por defecto), colocado en `Player/Visual/Model`, que
gira con `Visual`. El bastón está en la mano derecha. Todos los aspectos comparten un cuerpo de cápsula del tamaño del
jugador, ojos propios (`EyeRight`, `EyeLeft`) y un bastón en `RightHand`, así que cualquiera de ellos sirve como
héroe.

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

En el nivel, los diez están en fila en el lado sur del muro sur, de espaldas a él (al este del hueco del muro),
mirando al sur, cada uno con su número encima. Hay un pasillo despejado delante de toda la fila.

## CharacterAppearance

Cambia el modelo en tiempo de ejecución (Configuración → Personaje → **Aspecto del héroe**). `set_look(number)` quita
el modelo anterior y pone el nuevo en su lugar con el mismo nombre. También restablece la interpolación de física del
nuevo modelo (de lo contrario el modelo llegaría deslizándose desde el origen) y entrega la `RightHand` del nuevo
modelo a `HandSway`, para que el bastón vuelva a balancearse con los pasos. La silueta toma las nuevas mallas por sí
sola.

| Propiedad | Por defecto | Significado |
|---|---|---|
| `slot` | — | El nodo que contiene el modelo (`Visual` en el jugador, girado por `GroundCharacter`) |
| `model_name` | `Model` | Nombre del nodo del modelo dentro de `slot` |
| `models` | — | Escenas de modelos para elegir; el número de aspecto es la posición en esta lista, desde 1 |
| `hand_sway` | — | Quién recibe la mano del nuevo modelo; si está vacío, la mano no se balancea |
| `hand_path` | `RightHand` | Dónde está en el modelo la mano que sostiene un objeto |

`get_look()` devuelve el número actual (0 para un modelo que no está en la lista), `get_model()` el nodo del modelo.
Señal: `look_changed(model)`.

## HandSway: un bastón en la mano, no pegado al costado

`HandSway` (`RightHandSway` en el jugador) mueve el nodo de la mano del modelo respecto a su posición de reposo:

- **Con los pasos**, según `GroundCharacter.get_step_phase()`, el mismo ritmo que siguen los sonidos de los pasos. En
  cada paso la mano está en un extremo (delante y detrás alternadamente, ±7 cm) y en su punto más bajo (2,5 cm); a
  mitad de camino entre pasos está en el medio. El objeto se retrasa un poco en la inclinación (±7°). El balanceo
  crece con la velocidad, es una vez y media más amplio en sprint y se desvanece cuando el personaje se detiene o
  está en el aire.
- **Al correr**, el objeto se inclina hacia adelante (6°).
- **Inercia** con un resorte (1,8 Hz, amortiguación 0,45): al acelerar la punta va hacia atrás, al frenar hacia
  adelante, en los giros hacia afuera, y se balancea hasta asentarse. Al aterrizar, la mano baja más cuanto más
  rápida es la caída; al despegar, un poco.

Se ejecuta en el tick de física después del cuerpo, así que la interpolación de física lo suaviza igual que al
cuerpo. El ritmo de los pasos es continuo: detente a mitad de un paso y el siguiente llegará `first_step_distance`
después de volver a arrancar, pero la fase no salta; alcanza el número entero en ese paso. Para otra mano o un NPC,
agrega otro `HandSway` con su propia mano. Las amplitudes, la inclinación y el resorte son propiedades exportadas en
los grupos Swing e Inertia.

## OccludedSilhouette: una sola forma, el arma contorneada, un borde

Donde algo oculta al héroe (la montaña, una casa, un árbol), el héroe se ve como una silueta azul claro: una forma
plana para el cuerpo, el equipo en la mano contorneado encima y un borde alrededor de todo.

`OccludedSilhouette` (`Silhouette` en el jugador) establece `material_overlay` en cada malla del modelo, incluidas las
mallas agregadas después (un nuevo aspecto o arma, mediante `SceneTree.node_added`). Los materiales propios del
modelo no cambian, así que el mismo modelo en el nivel no tiene silueta. Las mallas del cuerpo y las mallas bajo los
nodos de las manos (`gear_nodes`: `RightHand`, `LeftHand`) reciben cadenas de pasadas distintas.

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

*Esta página corresponde a Iso & Orbit 1.1.0.*
