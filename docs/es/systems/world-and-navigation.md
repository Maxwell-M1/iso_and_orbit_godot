<!-- translation of docs/en/systems/world-and-navigation.md @ c9c7a768629e -->
# Mundo y navegación

[← Índice de documentación](../index.md)

> Esta es una traducción del [original en inglés](../../en/systems/world-and-navigation.md).
> Si hay diferencias, la versión en inglés es la correcta.

El nivel inicial de la demo es `shared/world/world.tscn`, el prado: un claro de 80 × 80 m detrás de una cerca de
madera. Todo está construido con primitivas y shaders; los patrones finos proceden de texturas horneadas. Una
plataforma junto al Círculo Antiguo lleva al segundo nivel, Isla Solitaria; ambos se describen en
[Niveles](levels.md#los-niveles-de-la-demo).

## Capas de física y navegación

Los obstáculos son `StaticBody3D` en la capa 1 (`world`), los personajes en la capa 2 (`characters`), los cuerpos
solo para la cámara en la capa 3 (`camera`) y paredes invisibles de borde en la capa 4 (`bounds`); consulta
[Preparación del proyecto](../project-setup.md#capas-de-física). La malla se hornea desde colisiones de capa 1
(también la 4 en la isla) con radio de agente de 0.5 m; la cápsula del personaje tiene radio 0.35 m, dejando
margen en las esquinas.

| Parámetro de `NavigationMesh` | Valor | Por qué |
|---|---|---|
| `agent_radius` | 0,5 m | Las rutas se mantienen alejadas de las esquinas |
| `agent_height` | 1.75 m | Valor de las mallas existentes; para niveles nuevos con techos usa al menos la altura completa de colisión (cápsula del héroe: 1.8 m) |
| `agent_max_slope` | 40° | Las laderas de la montaña quedan fuera de la malla |
| `cell_height` | 0,025 m | Lo bastante fina para medir la escalada de abajo |
| `cell_size` | 0.25 m | Resolución horizontal; debe coincidir con el mapa de navegación |
| `agent_max_climb` | 0,3 m (12 celdas) | Los escalones a los que sube el personaje (`GroundCharacter.max_step_height`) |
| `geometry_parsed_geometry_type` | Static Colliders | La malla sigue formas de colisión, no mallas visuales. La máscara siguiente se aplica a colisionadores; las paredes invisibles solo cuentan así |
| `geometry_collision_mask` | capa 1; isla: 1 y 4 | Obstáculos y, en la isla, paredes invisibles |
| `filter_walkable_low_height_spans` | desactivado en la demo | Actívalo en un nivel nuevo con techos para excluir zonas con menos espacio libre que `agent_height` |

**Haz coincidir navegación y cuerpo.** `agent_max_climb` no debe superar `GroundCharacter.max_step_height`
(0.3 m aquí), y el límite de pendiente de navegación no debe superar el del suelo del cuerpo (40° frente a 45°).
Vuelve a hornear al cambiar uno de ellos. La navegación se rasteriza en celdas: igualar números no garantiza todos
los bordes. Prueba el escalón más alto permitido y la cornisa más baja prohibida. La demo prueba escalones de
0.2 m y rechaza un bloque de 0.4 m. Las celdas verticales finas de 0.025 m permiten distinguir esas alturas.

Para niveles nuevos, usa una altura de agente al menos igual a la cápsula completa y activa
`filter_walkable_low_height_spans`: la altura por sí sola no activa el filtro. Incluye los colisionadores de techo
en el horneado. Un modelo flotante sobrepasa el cuerpo: comprueba también su espacio visual. El radio controla
el margen junto a paredes; si cambias el de la cápsula, revisa los pasillos estrechos y vuelve a hornear.

Mantén iguales `cell_height` y `cell_size` del mapa y la malla. La demo usa 0.025 m verticalmente y 0.25 m
horizontalmente; los ajustes del proyecto son `navigation/3d/default_cell_height` y
`navigation/3d/default_cell_size`.
La [referencia de NavigationMesh](https://docs.godotengine.org/en/stable/classes/class_navigationmesh.html)
explica la resolución, el redondeo y el filtro de espacio libre.

La superficie horneada puede quedar algo elevada sobre el suelo de colisión. `NavigationMover` compara el avance
de la ruta en el plano XZ; la física determina la altura real del cuerpo. Las capas físicas seleccionan la
geometría del horneado, mientras las capas de la región y `NavigationMover.navigation_layers` seleccionan rutas.

Una ruta vacía hace avanzar directamente; una parcial puede terminar antes de un destino inaccesible. Usa
**Depuración → Navegación visible** y **Línea de ruta del personaje** de la demo antes de modificar el movimiento
para compensar una ruta defectuosa. Consulta [Locomoción](locomotion.md#navigationmover).

## Volver a hornear la malla de navegación

La malla se hornea de antemano y se guarda en cada escena de nivel: `shared/world/world.tscn` y
`shared/world/island/island.tscn` (recurso `NavigationMesh` de `NavigationRegion3D`). El juego no la recalcula.
Tras editar un nivel, vuelve a hornear su malla. Ambas usan los mismos parámetros salvo la máscara de colisión:
la isla hornea las capas 1 y 4.

**Cuándo:** moviste, agregaste, quitaste o cambiaste el tamaño de algo con una forma de colisión en la capa 1
(`world`): una roca, una caja, un muro, un árbol, un objeto, un PNJ o la montaña; en la isla, también una pared
invisible de la capa 4 (`bounds`). No hace falta cuando solo cambió el
aspecto (una malla, un material), ni para los cuerpos en la capa 3 (`camera`), el personaje del jugador (capa 2) y
las áreas (`Area3D`). Si lo olvidas, las rutas atraviesan un objeto movido (el personaje choca contra él y se desliza
a lo largo) o rodean el lugar vacío donde estaba.

**En el editor:**

1. Abre la escena del nivel.
2. Selecciona `NavigationRegion3D` en el árbol de escenas.
3. Presiona **Bakear NavigationMesh** (Bake NavigationMesh) en la barra de herramientas sobre la vista 3D. Tras un
   par de segundos la malla azul de la vista se actualiza: un hueco del radio del agente (0,5 m) alrededor del
   objeto, malla continua donde estaba antes.
4. Guarda la escena (Ctrl+S): la malla queda incrustada en la escena.

Los parámetros del horneado están en el propio recurso: selecciona `NavigationRegion3D` y despliega
`Navigation Mesh` en el Inspector.

Después de volver a hornear, ejecuta las pruebas ([Pruebas](../testing.md)): sus recorridos siguen la malla. Con el
juego en marcha, Depuración → Navegación Visible (Debug → Visible Navigation) en el editor muestra la malla, y
Configuración (F10) → Interfaz → **Línea de ruta del personaje** muestra la ruta del personaje.

## El nivel

- **El centro** es el punto de aparición. A su alrededor: un anillo de columnas en ruinas, una trampa en forma de U
  abierta hacia el punto de aparición, un muro largo con un hueco, cajas, una arboleda, un laberinto de setos y una
  plataforma de 1,6 m con una rampa en su lado oeste y una escalera en su lado este (siete escalones de 0,2 m con
  huellas de 0,4 m, en un cuerpo estático formado por siete cajas). Las pruebas usan todo esto, así que permanece.
- **Los caminos** son franjas de tierra desde la cerca sur, a través del hueco del muro, hasta el punto de aparición
  y de ahí hacia la montaña, las ruinas, el campamento y la rampa; el camino de la granja se desvía al sur del muro.
  Son solo un patrón (los segmentos `ROADS` en `shared/world/terrain.gdshaderinc`) y no afectan al movimiento. Tanto
  el suelo como la hierba suave al pie de la montaña los dibujan, así que el camino continúa en el sendero de la
  montaña sin interrupción. Llega al inicio del sendero desde el oeste: al este del inicio del sendero la montaña es
  un acantilado macizo de hasta 4 m.
- **Los props** de `shared/world/props/`: un bosque al noroeste y a lo largo de los bordes, arbustos, rocas, un
  campamento al este (una tienda, una fogata con luz parpadeante, barriles), una granja al suroeste (una casa, un
  pozo).
- **La montaña** al noreste, de 10 m de altura, con un único sendero en espiral hasta la cima.
- **Los diez aspectos del héroe** en fila de espaldas al muro sur, al este del hueco (ver
  [Personajes](characters.md#aspectos-del-héroe)).

Edita las instancias de objetos en la escena del nivel para cambiar su disposición y vuelve a hornear la malla.
Las pruebas de regresión usan rutas y posiciones concretas de obstáculos de esta demo: usa otro nivel para tu
distribución o actualiza las pruebas junto con su geometría.

### Lugares y NPC

Cuatro lugares son áreas `PointOfInterest`. La primera vez que el jugador entra en uno, aparece "Lugar descubierto: …"
en la parte superior de la pantalla durante unos segundos. En cada lugar hay NPC con etiquetas de nombre (`Label3D`)
sobre la cabeza, mirando hacia su centro; el Caballero mira hacia el camino.

| Lugar | Dónde | Quién está ahí |
|---|---|---|
| Cumbre de los Vientos | La cima de la montaña al noreste | El Mago, junto a un altar con un cristal |
| Campamento de Viajeros | Este: tienda, fogata, barriles | El Explorador y el Enano junto al fuego |
| Granja del Pozo | Suroeste: casa, pozo | El Caballero, de guardia junto al camino |
| Círculo Antiguo | El anillo de columnas al noroeste del punto de aparición | El Pícaro, junto al altar |

Cada NPC es un `StaticBody3D` con una cápsula en la capa 1 (`World/NavigationRegion3D/Characters`): la malla de
navegación los rodea y nadie los atraviesa. El campamento, la granja y las ruinas están bajo `World/Places`; la cumbre
está en `mountain.tscn`.

**Un lugar nuevo:** agrega un `PointOfInterest` (un `Area3D` cuya `collision_mask` incluya la capa 2 de los
personajes) con una forma de colisión y un `title` a cualquier escena del mundo. El aviso encuentra cada lugar a
través de su grupo, incluso en un nivel cargado después; no hacen falta conexiones. Agrega el título a las
traducciones ([Interfaz de usuario](ui.md#traducciones)). Isla Solitaria tiene un quinto lugar: Campamento del Ermitaño.

## Superficies

Casi todas las superficies son un shader en `shared/world/` con un material en `shared/world/materials/`; las
excepciones son materiales `StandardMaterial3D` simples, listados al final de esta sección. Lo que depende del tamaño
y la forma de un objeto lo calcula el shader, lo cual es barato: hiladas de mampostería ajustadas a la altura de una
caja, tablones, marcos y postes, entramado de madera, duelas y aros de barril, estrías y tambores de columna, caminos
a lo largo de `ROADS`, capas de roca según la altura. Así, una caja de cualquier tamaño no estira su patrón. El
detalle fino (briznas de hierba, guijarros, hojas, corteza, grano de la piedra) viene de texturas horneadas, ver
abajo.

| Superficie | Shader | Cómo se ve |
|---|---|---|
| Muros, plataforma, rampa, escalera | `stone_masonry` | Bloques en hiladas desplazadas con juntas, cada bloque con su propio tono, grano y desconchones, relieve mediante la normal, suciedad y musgo cerca del suelo. La parte superior es una hilada de piedras a lo ancho del lado corto |
| Laberinto de setos | `hedge_foliage` | Dos capas de hojas, cada una con su propia rotación, tamaño, tono e inclinación; la sombra de la profundidad del arbusto en los huecos; lados irregulares como los de un arbusto podado |
| Cajas, cerca | `wood_planks` | Tablones con anillos de crecimiento, fibras, nudos y rendijas. Las cajas tienen un marco de tablones en cada cara, un refuerzo diagonal y clavos; la cerca tiene tablas largas desgastadas sobre postes cada 2,5 m |
| Columnas, pozo | `stone_column` | Estrías alrededor de la circunferencia mediante la normal, tambores de 0,8 m con juntas desde el suelo, una base lisa, vetas, grietas escasas, líquenes, musgo cerca del suelo. El pozo usa mampostería de bloques en círculo (`blocks_around`) |
| Rocas, piedras erguidas | `rock` | Piedra granulada con vetas y grietas, líquenes arriba, musgo cerca del suelo; el patrón es triplanar (`triplanar.gdshaderinc`), distinto en cada roca |
| Paredes de la casa | `timber_plaster` | Entramado de madera: revoque con manchas y grietas finas en un marco de postes y vigas, un zócalo de piedra |
| Techos de la casa y del pozo | `thatch` | Paja en hileras de gavillas con una sombra bajo cada hilera, pajas a lo largo de la pendiente, una cumbrera atada, musgo |
| Tienda, faldón, estandarte | `canvas` | Lona tejida: paneles con costuras, pliegues, parches; el estandarte tiene un ribete y un emblema |
| Barriles | `barrel` | Duelas con rendijas, aros de hierro oxidados, una tapa de tablones |
| Leños, troncos, asta del estandarte | `bark` | Corteza surcada con musgo cerca del suelo y en el lado norte; leños carbonizados y humeantes en la fogata |
| Copas de árboles, arbustos | `foliage` | Hojas en dos capas sobre tres planos de ejes, bultos, una parte superior más clara; agujas en los pinos, naranja y rojo en el roble otoñal |
| Suelo | `ground_grid` | Ver abajo. La hierba de la isla usa `island_ground.tres`, el mismo suelo sin caminos (`roads`) |
| Montaña | `mountain` | Hierba, el sendero y capas de roca elegidos según el color de la cara |
| Agua del pozo y lago de la isla | `water` | Ondas lentas. El lago (`lake_water.tres`) es azul más claro y tiene ondulaciones más fuertes (`ripple` 0.55 frente a 0.35) |

El patrón de la mampostería sigue las caras de la malla y conoce el tamaño de la caja: un `BoxMesh` sin subdivisiones
de caras tiene un vértice solo en cada esquina, así que `abs(VERTEX)` da los semitamaños. Llegan sin cambios a los
píxeles mediante un valor `flat`: si se interpolaran, sus últimos dígitos variarían entre píxeles y una cantidad
de hiladas en el punto medio (escalón de 1.4 m con hiladas de 0.4 m) se redondearía en sentidos distintos,
produciendo parpadeo. Los shaders de yeso, tablones y tela transmiten así el tamaño de caja. Las hiladas de los lados se
ajustan a la altura, y la hilada superior de un lado es el borde de las piedras de arriba, así que sus juntas
continúan las juntas de la parte superior en el borde. La rampa (una losa delgada) es una de esas hiladas, y las
juntas de sus extremos coinciden con la parte superior. Las cajas del laberinto, en cambio, tienen subdivisiones de
caras cada 25 cm (`subdivide_*`), porque sus lados se desplazan con ruido según la posición en el mundo: las copias de
un vértice en una arista se mueven juntas y las caras no se separan. Las formas de colisión siguen siendo las cajas
simples; las hojas sobresalen unos centímetros.

**El suelo** (`ground_grid.gdshader`, parte compartida `terrain.gdshaderinc`): hierba a varias escalas (grandes
manchas de hierba oscura, normal y seca, matas, briznas en dos capas con normales inclinadas y sombra en las raíces,
flores dispersas en los claros) y caminos (un borde irregular con matas de hierba, un centro pisado más claro, roderas
poco profundas, grano, grietas finas en los puntos secos, guijarros con sombras, más abundantes en el borde). El
detalle fino se repite cada 3,84 m a partir de texturas horneadas; las grandes manchas vienen de una máscara sobre
todo el suelo. A lo lejos, el detalle se desvanece hacia un color medio a través de los niveles de mip de las
texturas. La hierba y el sendero de la montaña usan el mismo código. Una cuadrícula de 1 m con líneas gruesas cada
5 m está desactivada por defecto; actívala con `grid_strength` en `shared/world/materials/ground.tres` para medir
velocidades y distancias.

El ruido barato de los shaders (números aleatorios para piedras y tablones, bultos del follaje) está en
`noise.gdshaderinc`, las hojas en `leaves.gdshaderinc`. Algunos materiales siguen siendo `StandardMaterial3D`
simples: `dark_wood.tres` y `wood.tres`, que usa el equipo de los personajes (bastones, arco, hacha), y los luminosos
`crystal.tres` y `fire.tres`.

## Texturas horneadas

Los patrones de las superficies (hierba con briznas y flores, tierra con guijarros, hojas, corteza, grano de la
piedra, revoque, fibras de madera, paja, tela tejida) se diseñaron como shaders de ruido, pero el juego no los
calcula para cada píxel: se hornearon una vez en texturas sin costuras en `shared/world/textures/`, y los shaders del
mundo las repiten en mosaico.

El horneado sustituye cálculos de ruido repetidos en cada píxel por muestras de textura. Al reemplazar estas
texturas, conserva los ajustes de importación siguientes: varios canales contienen datos para shaders, no colores
ordinarios.

- **Sin costuras.** El ruido de los patrones se repite con el mosaico, con un número entero de rasgos por mosaico,
  así que la costura es invisible. La excepción es `ground_mask`: las grandes manchas y los caminos sobre todo el
  suelo de 96 m, sin mosaico.
- **El color se queda en el shader del mundo.** Las hojas, la piedra de las columnas, la corteza y las fibras de
  madera se hornean sin color (tono de la hoja, sombra, hoja o hueco, manchas, inclinación de la normal), y el shader
  del mundo construye el color a partir de los parámetros del material: una sola textura de hojas sirve para el
  roble, el roble otoñal y el seto. Solo la hierba (un multiplicador para el tono de la mancha), las flores y los
  guijarros tienen el color horneado.
- **El relieve** es la inclinación de la normal en dos canales, calculada durante el horneado a partir de diferencias
  de altura.
- **Archivos:** WebP sin pérdida (los datos bajo alfa cero se conservan intactos), importados con compresión de GPU
  (BPTC), mipmaps y sin corrección de color para píxeles transparentes, ya que el alfa contiene datos. Conserva esta
  configuración de importación al reemplazar una textura.

## La montaña y la Cumbre de los Vientos

La montaña está en una esquina, en el borde del mundo (sus laderas pasan más allá de la cerca), y se ve desde todas
partes. El sendero hasta la cima tiene 3 m de ancho: empieza al final del camino (23, 0, −19) y da casi toda la
vuelta a la montaña (340°) con una pendiente de 12°. Las laderas a ambos lados son empinadas (76° por encima del
sendero, 60° por debajo): no se pueden subir a pie (el cuerpo solo se sostiene en 45° o menos) ni por una ruta (la
malla de navegación admite pendientes de hasta 40°), y la protección de bordes evita que el personaje se caiga del
sendero. Un clic en la cima desde el suelo lleva por el sendero: 51 m en 9,8 s.

En la cima hay un santuario: un altar con un cristal luminoso que flota y gira lentamente sobre él, cinco piedras
erguidas y un estandarte. La cima es el lugar Cumbre de los Vientos.

La montaña es un mapa de alturas generado por un script: una malla con colores por cara y sombreado plano, con el
material `materials/mountain.tres` encima (hierba con briznas, tierra del sendero con guijarros, capas de roca con
grietas y líquenes, según el color de la cara), y una forma de colisión a partir de los mismos triángulos
(`shared/world/mountain/*.res`). Lo que hizo falta para que se construyera una ruta por el sendero:

- El sendero tiene una sola altura a lo ancho, así que su borde interior es más empinado que su eje (en la proporción
  entre el radio del eje y el radio del borde). Las curvas no son cerradas (radio de 9,5 → 7 m), para que incluso
  cerca de la cima el borde interior sea más plano que 16°: más empinado, y una malla de navegación con una escalada
  de 0,075 m por celda de 0,25 m rompe el sendero.
- La entrada desde el camino: al pie, mientras el sendero está por debajo de 1 m, la ladera exterior es suave. De lo
  contrario, el sendero caería hacia afuera desde el inicio, y su entrada se estrecharía hasta una franja más delgada
  que el margen del agente.
- Los últimos 3 m del sendero están a nivel con la cima, así que el sendero se une a la cima a lo largo de una
  franja, no en un punto.

La cámara mira desde el sureste por defecto, así que en el lado lejano del sendero la montaña oculta al héroe, que
entonces se ve como una silueta (ver
[Personajes](characters.md#occludedsilhouette-una-sola-forma-el-arma-contorneada-un-borde)).

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
