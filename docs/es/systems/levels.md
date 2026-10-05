<!-- translation of docs/en/systems/levels.md @ dc39dc2f669b -->
# Niveles

[← Índice de documentación](../index.md)

> Esta es una traducción del [original en inglés](../../en/systems/levels.md).
> Si hay diferencias, la versión en inglés es la referencia.

Aquí se explica cómo cambia el juego de nivel: el host y su pantalla de carga, los portales y puntos de aparición,
el héroe jugable que pasa entre niveles y los dos niveles de la demo. El componente está en
`addons/iso_orbit/levels/`; el héroe, la invitación a viajar y la escena principal son archivos de la demo
construidos a partir de los componentes.

## La escena principal

`gdscript/main.tscn` permanece durante toda la partida. El nivel actual es hijo del host; el héroe y la interfaz
son sus hermanos, de modo que los niveles cambian a su alrededor.

| Nodo | Clase | Función |
|---|---|---|
| `Levels` | `LevelHost` | Aloja el nivel actual como único hijo y lo cambia |
| `Levels/World` | | Nivel inicial, `shared/world/world.tscn`, colocado en el editor |
| `Hero` | `PlayableHero` | Personaje del jugador, con entrada, cámara, marcador de clic y línea de ruta |
| `Hud/TravelPrompt` | `TravelPrompt` | Invitación a viajar sobre una plataforma |
| `LoadingScreen` | `LoadingScreen` | Pantalla visible mientras se carga otro nivel |

`gdscript/main.gd` los conecta así:

| Señal | Lo que hace la escena principal |
|---|---|
| `LevelHost.portal_entered(portal)` | Muestra la invitación de ese portal, salvo si viaja automáticamente. Si se entra en dos portales a la vez, muestra el último |
| `LevelHost.portal_exited(portal)` | Oculta esa invitación; si el héroe sigue en otro portal, ofrece ese |
| `TravelPrompt.confirmed(portal)` | `portal.travel()` |
| `LevelHost.level_change_started` | Oculta la invitación y el HUD, y quita el control al héroe |
| `LevelHost.level_loaded(level, spawn)` | Marca los lugares descubiertos anteriormente, coloca al héroe en `spawn` con la cámara detrás y muestra el HUD bajo la pantalla |
| `LevelHost.level_change_finished` | Devuelve el control |
| `LevelHost.level_change_failed` | Muestra el HUD, devuelve el control y ofrece otra vez el portal si el héroe sigue en él |

Al comenzar, la escena principal coloca al héroe en el punto `default` del nivel inicial con el ángulo de cámara
propio de la escena (`OrbitCameraRig.start_yaw`). Al llegar por un portal, la cámara mira hacia donde apunta el punto
de aparición. Los lugares descubiertos se recuerdan durante la sesión por el archivo del nivel y la ruta del lugar
dentro de él: al cargar de nuevo un nivel se marcan mediante `PointOfInterest.mark_discovered()` y no se anuncian
otra vez. Una partida guardada conservaría esa misma lista.

La instancia del héroe sobrevive al cambio y conserva resistencia, aspecto y estado de flotación. El teletransporte
borra su movimiento y reinicia el seguimiento de cámara; los ajustes del jugador permanecen en el autoload `Settings`.

## Un cambio de nivel

El jugador se sitúa en la plataforma y pulsa E o hace clic en la invitación:

1. El portal solicita viajar; el host comprueba el archivo, pide al cargador que lo prepare y responde enseguida.
   El cambio empieza justo después, no dentro de la solicitud: el portal puede solicitarlo desde una llamada de
   física, donde un nivel no debe salir del árbol. El proceso empieza con `level_change_started`.
2. El juego se pausa, salvo si ya lo estaba. En pausa, la cámara suelta el cursor y la entrada lo muestra.
3. La pantalla de carga captura el siguiente fotograma dibujado (el HUD ya está oculto), lo desenfoca y oscurece,
   y aparece durante 0.35 s. La imagen se acerca lentamente un 6%; aparecen el nombre del lugar y un consejo,
   y comienza la barra.
4. La escena del nivel se carga en segundo plano (`ResourceLoader.load_threaded_request`). Sus archivos llenan
   la barra hasta el 85%; el nivel ya construido, hasta el 90%.
5. El nivel antiguo sale del árbol y se libera; el nuevo ocupa su lugar. `level_loaded` indica a la escena principal
   dónde colocar al héroe. Se conectan sus portales; los del nivel antiguo se desconectaron antes de salir. Si
   entretanto algo ha terminado la pausa, como cerrar una ventana, el host vuelve a pausarla para el intercambio.
6. Todavía en pausa, el host espera a que el mapa de navegación incorpore el nivel nuevo (95%): todas sus regiones
   deben estar en el mapa, sin superar `navigation_timeout` según el reloj. El servidor de navegación trabaja
   durante la pausa, así que desde el primer fotograma del juego se encuentran rutas en el nivel nuevo.
7. Termina la pausa y el host dibuja `warmup_frames` fotogramas tras la pantalla: se compilan los shaders del nivel
   nuevo y el héroe se asienta en el suelo.
8. Cuando transcurre `min_loading_time` desde el inicio, la barra se llena y la pantalla se desvanece; después
   llega `level_change_finished`.

Ajustes del host:

| Propiedad | Valor predeterminado | Significado |
|---|---|---|
| `loading_screen` | vacío; la demo asigna su `LoadingScreen` | Pantalla que cubre el juego durante la carga. Vacío: el nivel cambia a la vista del jugador |
| `min_loading_time` | 0.6 s | Tiempo mínimo de la pantalla para que una carga rápida no produzca un destello |
| `warmup_frames` | 3 | Fotogramas dibujados detrás antes de retirarla; los shaders nuevos se compilan fuera de la vista |
| `navigation_timeout` | 2 s | Espera máxima del mapa según el reloj; acaba antes si incorpora todas las regiones nuevas. 0: no esperar; hasta que incorpore el nivel, una ruta se buscaría en el anterior o en ninguno |

Señales y métodos del host:

| Señal o método | Significado |
|---|---|
| `level_change_started(path)` | Empezó el cambio; el nivel anterior todavía está presente |
| `level_loaded(level, spawn)` | Ya está el nivel nuevo y se retiró el anterior; coloca al personaje en `spawn`. La pantalla aún cubre el juego |
| `level_change_finished(level)` | Terminó el cambio y desapareció la pantalla |
| `level_change_failed(path, error)` | No se pudo cambiar y permanece el nivel actual: `ERR_CANT_OPEN` si falla la carga, `ERR_INVALID_DATA` si la raíz de la escena no es un `Node3D`. Llega en lugar de `level_change_finished` |
| `portal_entered(portal)`, `portal_exited(portal)` | Un viajero entró o salió de un portal del nivel actual |
| `change_level(path, spawn_name = &"default", title = "")` | Inicia el cambio y responde enseguida; consulta lo siguiente |
| `get_current_level()` | Nivel actual del juego; `null` antes del primero |
| `is_changing()` | Hay un cambio en curso desde que se acepta `change_level()` hasta `level_change_finished` o `level_change_failed` |
| `find_spawn_point(spawn_name = &"default", level = null)` | Busca un punto de aparición; consulta [Puntos de aparición](#puntos-de-aparición) |

El nivel inicial colocado en el editor no se anuncia: no emite `level_loaded`. Su punto `default` está listo.
El juego lo prepara en `_ready()`
mediante `get_current_level()` y `find_spawn_point()`, como hace `gdscript/main.gd`.

Una solicitud durante otro cambio se rechaza (`ERR_BUSY`), así que pulsar E de nuevo o entrar en otro portal no
tiene efecto. `change_level()` comprueba el archivo de inmediato: si falta devuelve `ERR_FILE_NOT_FOUND`; si no es
una escena, `ERR_INVALID_PARAMETER`. No inicia ningún cambio. Si falla la carga de una escena o su raíz no es un
`Node3D`, permanece el nivel actual: aparece un error en la salida, termina la pausa, la pantalla se desvanece sin
esperar `min_loading_time` y llega `level_change_failed`. Se descarta la carga fallida, de modo que una solicitud
posterior vuelve a cargar el archivo, por ejemplo tras corregirlo.

El host termina únicamente la pausa que inició. Abre una ventana que pause el juego, como un menú, después de
`level_change_finished`: si la abres durante el cambio, encontrará el juego pausado y dejará la pausa en manos del
host; al terminar, el juego seguirá detrás de la ventana. En la demo ocurre naturalmente porque la pantalla no
deja pasar ninguna entrada, incluida F10, hasta cerrarse. Cerrar una ventana durante el cambio no causa problemas:
el host vuelve a pausar para el intercambio. Si el host sale del árbol durante el cambio (por ejemplo al cambiar
la escena de juego), terminan tanto el cambio como su pausa.

La pantalla, la barra y `min_loading_time` utilizan tiempo real con independencia de `Engine.time_scale`: en
cámara lenta un cambio tarda lo mismo que a velocidad normal.

El calentamiento oculta parte del trabajo del primer uso tras la pantalla; no garantiza que nunca haya pausas
posteriores por shaders o recursos. Mide las transiciones con el contenido real y el renderizador de destino.

## Portales

`LevelPortal` es un `Area3D`: plataforma, puerta o borde de mapa. Necesita una forma de colisión y un
`collision_mask` que detecte la capa del viajero (2, personajes); no necesita capa propia. El host conecta los
portales del nivel actual, incluidos los que se agreguen más tarde, por ejemplo al completar una misión.

| Propiedad | Valor predeterminado | Significado |
|---|---|---|
| `target_level` | | Archivo de escena del nivel de destino. Es una ruta, no una escena cargada: dos niveles pueden enlazarse mutuamente. También funciona una ruta `uid://` elegida en el Inspector |
| `target_spawn` | `default` | Punto de aparición al que se llega |
| `title` | | Nombre del lugar de destino para la invitación, la pantalla y el letrero. Se traduce al mostrarlo |
| `title_label` | | `Label3D` sobre el portal que muestra `title`; el portal escribe allí el título |
| `traveller_group` | `player` | Puede viajar un cuerpo que pertenezca a este grupo |
| `auto_travel` | desactivado | Viaja al entrar un viajero sin pedir confirmación |

Combinaciones posibles:

- **Predeterminada, como las plataformas de la demo:** el portal informa de entradas y salidas
  (`traveller_entered`, `traveller_exited`); el host las retransmite como `portal_entered` y `portal_exited`, y el
  juego decide qué ofrecer. La escena principal muestra la tecla E y «Teletransporte: <lugar>»; alejarse lo oculta.
  E también funciona con Mayús u otro modificador pulsado, ya que el héroe suele llegar esprintando.
  `travel()` inicia el cambio.
- **`auto_travel` activado:** una puerta o un borde del mapa. El portal viaja en cuanto entra un viajero y la
  escena principal no muestra ninguna invitación.
- **Sin pantalla de carga:** deja vacío `LevelHost.loading_screen`. El nivel se sigue cargando en segundo plano
  y el juego se pausa para el intercambio y la navegación, pero el jugador ve el cambio.
- **Portal controlado por código:** `LevelHost.change_level(path, spawn_name, title)` hace lo mismo que un portal;
  puede llamarse desde una secuencia cinemática o un menú.

`travel()` y la entrada con `auto_travel` emiten `travel_requested(portal)`; el host conecta esa señal. Si tu juego
no usa host, conéctala tú. `has_traveller()` indica si hay un viajero en el portal. Todos los portales pertenecen
al grupo `level_portals`.

Si el personaje aparece dentro de un portal, enseguida se le ofrecería regresar. Dentro de uno con
`auto_travel`, se detecta al reanudarse la física durante el calentamiento, cuando todavía sigue el cambio: la
solicitud recibe `ERR_BUSY`, que el host ignora, y el personaje permanece allí hasta salir y volver a entrar. Si
el cambio ya terminó, regresa de inmediato. Coloca por tanto los puntos de aparición al lado de las plataformas,
fuera de las áreas de sus portales.

## Puntos de aparición

`SpawnPoint` es un `Marker3D` con `spawn_name`, inicialmente `default`. El personaje aparece en su posición y mira
hacia su eje −Z, la dirección de avance de un nodo (el eje azul del gizmo apunta hacia el lado contrario);
`get_facing()` devuelve esa dirección horizontal. Pon el marcador en el suelo: allí van los pies del personaje;
si está por encima, el personaje caerá. Todos los puntos pertenecen al grupo `spawn_points`.

`LevelHost.find_spawn_point(name, level)` devuelve el punto de `level` (nivel actual si se omite; debe estar en el
árbol) con ese nombre, el punto `default` si no existe uno con ese nombre, o `null` si falta también. Durante un
cambio, un punto ausente produce además una advertencia; si no hay ningún punto, el host entrega el nivel mismo
como `spawn`, de modo que el personaje llega al origen del nivel. Cada nivel necesita un punto `default`: ahí
empieza el juego y llega cualquier portal sin `target_spawn`. Se usa `spawn_name`, no el nombre del nodo: los
puntos `default` de la demo se llaman `Start` y `Arrival`. Da nombres propios a los demás: si dejas un segundo
punto como `default`, hay dos y la búsqueda por ese nombre obtiene el primero en el orden del árbol.

## La pantalla de carga

`LoadingScreen` es un `CanvasLayer` en la capa 20, por encima de las ventanas, que funciona mientras el juego está
pausado. Cuando aparece, ningún evento de entrada llega al juego: ni los clics ni F10 actúan (`Input` aún informa
de las teclas mantenidas).

| Propiedad | Valor predeterminado | Significado |
|---|---|---|
| `tips` | vacío; la demo establece seis consejos de control en su instancia de `gdscript/main.tscn` | Se muestran de uno en uno en orden aleatorio; cada uno se traduce y pasa por `tip_format` |
| `tip_format` | vacío (`Callable` asignado por código); la demo usa `InputNames.format` en `gdscript/main.gd` | Convierte un consejo traducido en texto visible. La demo nombra teclas mediante marcas como `{sprint}`, e `InputNames.format` inserta las asignadas; consulta [Nombres de teclas en los textos](ui.md#nombres-de-teclas-en-los-textos). Vacío: muestra el consejo traducido |
| `tip_time` | 6 s | Duración de cada consejo; luego se desvanece durante 0.25 s, cambia el texto y el siguiente aparece en 0.25 s |
| `fade_time` | 0.35 s | Duración de la aparición y desaparición de la pantalla |
| `zoom` | 0.06 | Acercamiento del fondo como proporción de su tamaño |
| `zoom_time` | 12 s | Tiempo que tarda en acercarse esa cantidad |

El fondo es el último fotograma del juego reducido ocho veces y algo más desenfocado por un shader
(`loading_background.gdshader`: desenfoque, oscurecimiento, esquinas más oscuras y parte inferior oscurecida
bajo el texto). Si no se dibuja ninguna ventana, porque se ejecuta sin ella o está minimizada, no hay fotograma
y se muestra un color oscuro uniforme. La barra se acerca rápidamente al progreso cuando va muy por detrás y
nunca retrocede, aunque el cargador comunique después un valor menor.

El aspecto está en `loading_screen_theme.tres`, el tema de la raíz: las variaciones de tipo `LoadingTitle` (44 px,
blanco cálido con sombra), `LoadingBar` (barra dorada y fina) y `LoadingTip` (18 px). Asigna otro tema a la raíz o
crea una pantalla propia a partir de `loading_screen.tscn`: los nodos pueden moverse y cambiar, pero el script
necesita el `Control` `Root` y, por nombre único, el `TextureRect` `Background`, los `Label` `Title` y `Tip`, y
el `ProgressBar` `Bar`. Un script que extienda `LoadingScreen` puede redefinir `open()`, `set_progress()` y
`close()`; la escena sigue necesitando esos nodos. Consultas: `is_open()` (la pantalla está visible, aparece o
desaparece), `get_shown_progress()` (fracción llena de la barra, de 0 a 1) y `get_tip()` (plantilla original del
consejo visible, vacía si no hay consejos). `refresh()` vuelve a traducir y formatear ese consejo sin reiniciar
su temporizador. La demo agrega la pantalla al grupo `ActionTexts.GROUP`; actualizar los nombres de teclas
también actualiza un consejo ya visible.

## El héroe jugable

`gdscript/player/playable_hero.tscn` está listo para colocarse en una escena de juego: contiene el personaje
(`player.tscn`, en el grupo `player`), `PointClickMoveInput`, `CharacterActionInput`, el rig de cámara con brazo y
cámara, marcador de clic y línea de ruta, con ajustes y seis conexiones dentro de la escena. La escena del
personaje por sí sola no incluye esas partes, por lo que una IA puede controlar el mismo `player.tscn`.

`PlayableHero` (`playable_hero.gd`) expone las partes como propiedades tipadas (`character`, `input`, `actions`,
`camera_rig`, `camera_arm`, `camera`, `click_marker`, `path_view`, y del personaje `sounds`, `appearance`,
`hover`, `silhouette`) y tres operaciones:

| Llamada | Efecto |
|---|---|
| `teleport(position, facing = Vector3.ZERO, turn_camera = true)` | Descarta la pulsación en curso (`PointClickMoveInput.cancel()`), coloca al personaje de inmediato (`GroundCharacter.teleport()`), orienta la cámara según `facing` si se pide, la lleva a su posición al instante y reinicia el seguimiento. Si `facing` se deja como `Vector3.ZERO`, el personaje mantiene su orientación y la cámara su dirección |
| `place_at(marker, turn_camera = true)` | Llama a `teleport()` hasta el marcador, orientado hacia su eje −Z |
| `controls_enabled` | Desactivado: descarta la pulsación, suelta la tecla de sprint y detiene los nodos de entrada; la cámara sigue bajo control del jugador. Una carrera hacia un punto marcado continúa: deténla con `character.mover.stop()` o `teleport()`. Activado: vuelven los controles y los nodos de entrada procesan igual que antes |

La raíz del héroe nunca se mueve: el personaje se desplaza en su interior y la cámara lo sigue. También funciona
sin el componente de niveles: un juego con sistema propio llama a `place_at()` cuando sus niveles estén listos.

## Los niveles de la demo

**El prado** (`shared/world/world.tscn`, consulta [Mundo y navegación](world-and-navigation.md)) contiene bajo
`Travel`: el punto `Start` (`default`) en el origen, mirando al norte; la plataforma `IslandPad` junto al Círculo
Antiguo, 12 m al norte del inicio y visible desde allí, que lleva a la isla; y el punto `FromIsland`
(`from_island`) al lado de la plataforma, mirando al este, con esta a la izquierda y un poco detrás del héroe.

**Isla Solitaria** (`shared/world/island/island.tscn`) es una isla redonda de 30 m de diámetro en un lago,
construida con los objetos, materiales y shaders del prado; aparte de dos materiales no tiene archivos propios:

- la hierba usa `island_ground.tres`: el suelo del prado con los caminos de tierra desactivados (`roads`), pues
  se dibujan en coordenadas del mundo y pertenecen al prado;
- el lago usa `lake_water.tres`: el agua quieta del pozo en azul más claro y con ondulaciones más marcadas, en
  un plano de 600 m que llega al horizonte;
- una costa rocosa bajo el borde de la hierba y rocas grandes en las aguas poco profundas;
- unas paredes invisibles en un anillo a 14.5 m (`Edge`, 24 cajas) retienen al héroe en la isla. Están en la
  capa de física `bounds` (4): el personaje colisiona con ellas, pero los clics y la cámara no las detectan. Un
  clic en el agua no apunta a ninguna pared y la cámara las atraviesa. La malla de navegación de la isla se
  hornea desde las capas 1 y 4 para que las rutas eviten las paredes;
- el Campamento del Ermitaño al norte, con tienda, hoguera y barriles, es un lugar descubrible (su
  `PointOfInterest` está bajo `Places`);
- el punto `Arrival` (`default`) al sur, orientado hacia el campamento al norte, y la plataforma `HomePad` de
  regreso al prado (punto `from_island`), a la izquierda y detrás del héroe;
- su propia malla de navegación, horneada como la del prado (consulta
  [Volver a hornear la malla de navegación](world-and-navigation.md#volver-a-hornear-la-malla-de-navegación)).

Ambos niveles comparten el entorno `shared/world/world_environment.tres`: cielo, niebla y luz ambiental. Cada uno
tiene su propia copia del sol (`Sun`).

Las plataformas (`shared/world/props/teleport_pad.tscn`) son instancias de una misma escena: un `LevelPortal` con
disco de piedra, incrustación luminosa, cristal giratorio por encima de la cabeza, luz y letrero con el nombre del
lugar. No tienen colisión, así que las mallas de navegación bajo ellas no cambiaron.

## Agregar un nivel

1. Crea una escena con raíz `Node3D`: luz y entorno del nivel, un `NavigationRegion3D` con suelo y objetos y un
   `SpawnPoint` en el suelo cuyo `spawn_name` sea `default`. Las paredes invisibles del borde van en la capa 4
   (`bounds`).
2. Crea un `NavigationMesh` único y hornéalo para este nivel: usa colisionadores estáticos, capa de física 1 y
   también la 4 si tiene paredes invisibles. Usa la altura de celda de 0.025 m y el tamaño de 0.25 m del mapa;
   empieza con radio de 0.5 m, subida máxima de 0.3 m y pendiente máxima de 40°. Para la cápsula suministrada de
   1.8 m, usa una altura de agente de 1.8 m y activa `filter_walkable_low_height_spans` para excluir techos bajos.
   Si copias una malla de la demo, hazla única antes de volver a hornearla y revisa su altura y el filtro. Consulta
   [Mundo y navegación](world-and-navigation.md#capas-de-física-y-navegación).
3. Agrega un portal desde otro nivel: una instancia de `teleport_pad.tscn` o tu propio `LevelPortal` con
   `target_level` apuntando a la escena nueva, y otro portal de regreso. Pon un punto de aparición junto a cada
   plataforma y escribe su nombre en `target_spawn` de la plataforma del otro extremo.
4. Agrega los títulos de sus portales y lugares a las traducciones: `localization_checks.gd` recorre desde el
   nivel inicial todos los niveles alcanzables por portales e informa de cadenas ausentes. No comprueba un nivel
   alcanzable únicamente desde código con `change_level()`.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
