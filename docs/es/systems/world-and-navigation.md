<!-- translation of docs/en/systems/world-and-navigation.md @ 139c7571619f -->
# Mundo y navegación

> Esta es una traducción del [original en inglés](../../en/systems/world-and-navigation.md).
> Si hay diferencias, la versión en inglés es la correcta.

El nivel de la demo es `shared/world/world.tscn`: un claro de 80 × 80 m detrás de una cerca de madera. Todo en él
está construido con primitivas y shaders; los patrones finos de las superficies vienen de texturas horneadas.

## El nivel

- **El centro** es el punto de aparición. A su alrededor: un anillo de columnas en ruinas, una trampa en forma de U
  abierta hacia el punto de aparición, un muro largo con un hueco, cajas, una arboleda, un laberinto de setos y una
  plataforma de 1,6 m con una rampa en su lado oeste y una escalera en su lado este (siete escalones de 0,2 m con
  huellas de 0,4 m). Las pruebas usan todo esto, así que se queda donde está.
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

El bosque, los arbustos y las rocas se colocaron una vez con un script desechable con una semilla fija, dejando
libres los lugares que usan las pruebas (los recorridos, la carrera por la franja sur, el salto desde la plataforma,
todo lo que rodea el punto de aparición). El script no está en el proyecto; la distribución ahora se edita en el
editor. Al mover árboles, mantén despejados esos lugares.

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
través de su grupo; no hacen falta conexiones. Agrega el título a las traducciones
([Interfaz de usuario](ui.md#traducciones)).

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
| Suelo | `ground_grid` | Ver abajo |
| Montaña | `mountain` | Hierba, el sendero y capas de roca elegidos según el color de la cara |
| Agua del pozo | `water` | Ondas lentas |

El patrón de la mampostería sigue las caras de la malla y conoce el tamaño de la caja: un `BoxMesh` sin subdivisiones
de caras tiene un vértice solo en cada esquina, así que `abs(VERTEX)` da los semitamaños. Las hiladas de los lados se
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

La razón es el tiempo de fotograma. Solo el suelo le costaba a la GPU unos 2,5 ms por fotograma en una ventana de
2560 × 1511: cada píxel recorría 18 celdas de briznas de hierba con senos y hashes. Con texturas, la GPU necesita
unos 2 ms para todo el fotograma en lugar de 4,5, y la tasa de fotogramas pasó de 160–230 a 300–470 (12 vistas del
nivel, sin V-Sync, una RTX 4090 Laptop GPU; más allá de eso, el límite es la CPU).

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

## Capas de física y navegación

Los obstáculos son `StaticBody3D` en la capa 1 (`world`), los personajes en la capa 2 (`characters`), los cuerpos
solo para la cámara en la capa 3 (`camera`), ver [Preparación del proyecto](../project-setup.md#capas-de-física). La
malla de navegación se hornea a partir de las colisiones de la capa 1 con un radio de agente de 0,5 m; la cápsula del
personaje es de 0,35 m, así que las rutas dejan un margen respecto a las esquinas.

| Parámetro de `NavigationMesh` | Valor | Por qué |
|---|---|---|
| `agent_radius` | 0,5 m | Las rutas se mantienen alejadas de las esquinas |
| `agent_height` | 1,75 m | |
| `agent_max_slope` | 40° | Las laderas de la montaña quedan fuera de la malla |
| `cell_height` | 0,025 m | Lo bastante fina para medir la escalada de abajo |
| `agent_max_climb` | 0,3 m (12 celdas) | Los escalones a los que sube el personaje (`GroundCharacter.max_step_height`) |
| `geometry_collision_mask` | capa 1 | Solo cuentan los obstáculos |

**Una ruta nunca lleva a una cornisa más alta de lo que el cuerpo puede subir.** `GroundCharacter` sube escalones de
hasta `max_step_height` (0,3 m), así que la malla une cornisas de hasta 0,3 m (`agent_max_climb`) y no más altas: la
escalera al este de la plataforma queda unida; el borde de 1,6 m de la plataforma y los costados de la rampa de más de
0,3 m, no. Recast mide las alturas en celdas enteras, así que las celdas deben ser finas. La malla se horneaba antes con
`agent_max_climb` = 0,25 m y `cell_height` = 0,25 m, y trataba como transitable una cornisa de casi 0,5 m: la ruta a la
plataforma entraba en la rampa por el costado, donde su borde está a 0,4 m sobre el suelo, y el personaje chocaba contra
ella. Con celdas de 0,025 m la escalada se mide con una precisión de 2,5 cm. La altura de celda del mapa de navegación
no debe superar la de la malla (o el motor emite una advertencia), así que `project.godot` fija
`navigation/3d/default_cell_height` en 0,025. Si cambias `max_step_height`, pon `agent_max_climb` al mismo valor y
vuelve a hornear la malla.

Una malla de Recast queda suspendida unas dos alturas de celda sobre el suelo (0,05 m aquí; era 0,5 m con las
antiguas celdas de 0,25 m). Por eso `NavigationMover` compara los puntos de la ruta en el plano horizontal, ver
[Locomoción](locomotion.md#navigationmover).

## Volver a hornear la malla de navegación

La malla se hornea de antemano y se guarda directamente en `shared/world/world.tscn` (el recurso `NavigationMesh` de
`NavigationRegion3D`); el juego no la recalcula. Después de editar el nivel, vuelve a hornearla.

**Cuándo:** moviste, agregaste, quitaste o cambiaste el tamaño de algo con una forma de colisión en la capa 1
(`world`): una roca, una caja, un muro, un árbol, un prop, un NPC, la montaña. No hace falta cuando solo cambió el
aspecto (una malla, un material), ni para los cuerpos en la capa 3 (`camera`), el personaje del jugador (capa 2) y
las áreas (`Area3D`). Si lo olvidas, las rutas atraviesan un objeto movido (el personaje choca contra él y se desliza
a lo largo) o rodean el lugar vacío donde estaba.

**En el editor:**

1. Abre `shared/world/world.tscn`.
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

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
