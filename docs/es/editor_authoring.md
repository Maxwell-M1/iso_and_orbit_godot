<!-- translation of docs/en/editor_authoring.md @ a4a7c741507e -->
# Edición de escenas en el editor

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/editor_authoring.md).
> Si hay diferencias, la versión en inglés es la correcta.

Las escenas de la demo están pensadas para editarse en el editor. Los nodos se enlazan en el Inspector; los
componentes comprueban su configuración y muestran una advertencia en el panel Escena mientras falta algo o algo está
mal; y lo que el juego prepara al inicio (la vista de la cámara, el modelo de un personaje y el nombre sobre su
cabeza, el título del letrero de un portal, el tamaño de un objeto) también se ve en el editor. Estas vistas previas
nunca se guardan: una escena guardada contiene lo que tú estableciste, así que su diff solo muestra tus cambios.

## Referencias y advertencias

Un componente que trabaja con otros nodos tiene referencias a ellos como propiedades: `PlayableHero.character`,
`GroundCharacter.mover`, `OccludedSilhouette.target`, etc. Establécelas en el Inspector arrastrando un nodo al campo.
Mientras una referencia que el componente necesita está vacía, o un nodo está donde no puede funcionar (un
`NavigationMover` que no está bajo el cuerpo que mueve, un `LevelPortal` sin escena de destino, una acción de entrada
que falta en el mapa de entrada), el panel Escena muestra un signo de advertencia junto al nodo; pasa el puntero sobre
él para ver el motivo. Las advertencias siguen tus ediciones: aparecen y desaparecen a medida que cambias una
propiedad, agregas o quitas un hijo, editas la curva de un recorrido, el `max_drop` de una protección de bordes o los
ajustes de caída de un personaje. No hace falta volver a abrir la escena.

Los componentes se comprueban a sí mismos en el editor porque sus scripts son scripts de herramienta (tool). En el
editor solo comprueban y muestran vistas previas: allí no se ejecutan la entrada, la física ni los temporizadores, y
nada de lo que calculan se escribe en la escena. En el juego funcionan como siempre.

## El nivel inicial

`gdscript/main.tscn` contiene el host de niveles, `Levels`, con el nivel inicial, `World`, como hijo, y
`Levels.initial_level` lo indica. Sin él, el host empieza en su primer hijo `Node3D`; con varios hijos 3D y ninguno
indicado, muestra una advertencia. Consulta [Niveles](systems/levels.md).

## La cámara en el editor

`Hero/CameraRig` muestra la vista con la que empieza el juego: el rig se sitúa en el objetivo, `focus_height` por
encima de él, girado según `start_yaw`, con la inclinación y la distancia que fija `start_zoom`, y el brazo muestra la
cámara a esa distancia. Cambia estas propiedades para encuadrar el inicio; la vista 3D las sigue al instante.

El juego establece en cada fotograma la transformación del rig, la de la cámara y, bajo un rig, la `length` del brazo,
así que en el editor también son vistas previas: un rig o una cámara movidos a mano vuelven adonde los pone el juego,
y bajo un rig la `length` del brazo es de solo lectura. Al guardar se conservan los valores con los que se cargó la
escena, así que la vista previa nunca aparece en un diff, y la escena que coloca al héroe nunca recibe una copia de la
posición de su cámara. Un rig sin objetivo es distinto: el juego no lo mueve, así que su posición es tuya y se guarda
tal como la estableces; solo su giro es una vista previa.

## Ajustes de la ventana de configuración

`SettingsApplier` aplica la configuración guardada del jugador (F10) por encima de los valores establecidos en la
escena. Los valores de la escena también son los valores por defecto: una opción que el jugador no ha cambiado
conserva el valor de la escena, y **Restablecer todo** vuelve a ellos. Desactiva `SettingsApplier.use_saved_settings`
para ejecutar los nodos de la escena exactamente como están establecidos mientras los ajustas en el Inspector; la
ventana de configuración entonces no los toca y solo cambia los ajustes del motor (pantalla completa, frecuencia de
fotogramas, V-Sync, interpolación de física, escala de la interfaz, idioma, volumen). Consulta
[Configuración](settings.md).

## Objetos sólidos

Un objeto sólido es una escena con una raíz `StaticProp`, un `StaticBody3D` con `shared/world/props/static_prop.gd`.
Sus partes visibles y sus formas de colisión son hijos de la raíz, agrupados, así que un clic en la vista 3D
selecciona el objeto entero.

- **Muévelo** por la raíz.
- **Redimensiónalo** con `dimensions`, en metros a lo largo de los propios ejes del objeto: las partes visibles y la
  colisión cambian a la vez. 0 en un eje conserva el tamaño de las partes a lo largo de él, así que un objeto nuevo, en
  `(0, 0, 0)`, tiene el tamaño con el que se hizo, y para hacer más alto un pilar basta con cambiar su altura. No
  escales la raíz, pues entonces muestra una advertencia; tampoco escales sus hijos, y una malla agrandada o reducida
  necesita que su forma de colisión cambie con ella.
- **Cambia su color** con `surface_material`: sustituye el material de todas sus partes visibles; vacío, conservan el
  suyo.

Los objetos que comparten los niveles son escenas de `shared/world/props/`: `stone_pillar.tscn`, `solid_box.tscn` (los
muros, las cajas, la plataforma y su rampa), `grove_tree.tscn`, `rock.tscn` y los objetos sólidos del bosque, el
campamento y la granja (un arbusto no tiene colisión y no es un `StaticProp`). Una instancia establece sus propias
`dimensions` y `surface_material`; edita la escena del objeto para cambiar todas sus instancias. Una parte que se usa
una sola vez está directamente en su nivel con una raíz `StaticProp` propia: el suelo del prado, la escalera de la
plataforma, los setos del laberinto, las figuras de los lugares, los diez aspectos del héroe, el suelo de la isla y
las paredes de su borde. Los setos conservan el tamaño de sus mallas: sus hojas necesitan una malla subdividida en
celdas de unos 25 cm, así que un seto de otro tamaño recibe una malla de ese tamaño, no `dimensions`.

Edita las partes como de costumbre: mueve un hijo, cambia una malla o una forma, agrega una parte. El objeto toma el
cambio como su nueva forma: en los ejes donde `dimensions` es 0 toma el nuevo tamaño de las partes, y en los demás
conserva su estiramiento. Un objeto nuevo no se agrupa solo: selecciona su raíz y pulsa el botón Group de la barra de
herramientas de la vista 3D. Al guardar se conservan las partes tal como las hiciste; el redimensionado es una vista
previa que se aplica de nuevo al abrir la escena y al iniciar el juego. Una forma redimensionada es una copia propia,
así que redimensionar una instancia nunca cambia otra. Una forma redonda o girada que se estira de forma desigual se
convierte en una forma convexa estirada del mismo modo.

Pon las partes móviles bajo un `Node3D` simple: un nodo que se anima a sí mismo no debe ser el nodo que el objeto
redimensiona. En la montaña, el objeto redimensiona y coloca `CrystalAnchor`, y su hijo `Crystal` gira y sube y baja.

Después de cambiar la colisión de un objeto (al moverlo, redimensionarlo o editarlo), vuelve a hornear la malla de
navegación; consulta [Mundo y navegación](systems/world-and-navigation.md#volver-a-hornear-la-malla-de-navegación).

## Patrullas

El caballero del prado sigue un recorrido. Abre `shared/world/world.tscn` y selecciona `Routes/KnightPatrol`, un
`Path3D`: edita su curva en la vista 3D con las herramientas de curvas, y el caballero recorre la línea dibujada allí,
girando con suavidad en sus curvas. Para redondear una esquina, activa **Select Control Points** en la barra de
herramientas y arrastra desde el punto con Shift para sacar sus tiradores. Mantén la línea apartada de los setos
aproximadamente el ancho del caballero: a lo largo de ella no busca cómo rodearlos. El caballero
(`NavigationRegion3D/Characters/Knight`, una instancia de `gdscript/npc/knight_patrol.tscn`) se refiere a él en
**Route**. Desde su sitio junto a la casa camina hasta el primer punto del recorrido, y después del último vuelve por el
camino más corto: esos dos caminos no forman parte de la línea dibujada. El recorrido pertenece al nivel, así que el
mismo personaje puede seguir otro recorrido en otro nivel. El explorador de la isla (`island_patrol.tscn`) sigue
`Routes/IslandPatrol` en la isla. Un recorrido sin puntos, o uno dentro del personaje, muestra una advertencia en la
raíz del personaje, `Knight`.

En el editor, un personaje que patrulla muestra su modelo y el nombre sobre su cabeza; ninguno de los dos se guarda en
la escena. Su raíz establece **Model Scene**, **Speaker Name** (sobre la cabeza y en los subtítulos) y **Blocked Line**
(lo que dice cuando alguien le ha cerrado el paso el tiempo suficiente). Su marcha se ajusta en
`Character/PatrolController` (activa **Editable Children**): **Cycle Wait**, la espera en el punto de partida tras una
ronda (10 s); **Waypoint Wait**, la parada en cada punto de la curva; **Blocked Delay**, cuánto tiempo debe alguien
cerrarle el paso antes de la frase (2.5 s para el caballero); **Blocking Distance** y **Blocking Angle**, la zona
delante de él donde alguien lo detiene: 1 m por delante, abriéndose 25° hacia cada lado, como el haz de una linterna. A
sus lados y detrás de él nadie lo detiene. Consulta
[Locomoción](systems/locomotion.md#patrolcontroller-seguir-un-recorrido).

## Comprobar la parte del editor

`tests/run_checks.gd` comprueba el juego, pero no puede ejecutar el editor. La parte del editor, es decir, las
advertencias que siguen a las ediciones, las vistas previas y lo que se guarda en las escenas, tiene sus propias
comprobaciones: abre `tests/editor_tool_checks.tscn` y pulsa **Run Checks** en el Inspector. El resultado aparece
allí, en **Status** y **Results**, y en `.godot/editor_tool_checks/results.json`; la salida recibe la línea de estado.
Las comprobaciones guardan sus escenas solo en esa carpeta, que se vacía en cada ejecución: no se escribe ninguna
escena del proyecto ni la configuración del jugador. Consulta [Pruebas](testing.md#comprobaciones-en-el-editor).

---

*Esta página corresponde a Iso & Orbit 1.3.0.*
