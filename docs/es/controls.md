<!-- translation of docs/en/controls.md @ 4a1d22271190 -->
# Controles

> Esta es una traducción del [original en inglés](../en/controls.md).
> Si hay diferencias, la versión en inglés es la correcta.

Mouse y teclado; no hay soporte para gamepad. Casi todo el comportamiento descrito abajo se puede cambiar en la
ventana de configuración (F10), ver [Configuración](settings.md). Cómo funciona la entrada por dentro:
[Entrada](systems/input.md).

| Entrada | Acción |
|---|---|
| Clic izquierdo en el suelo | Correr hasta ese punto rodeando los obstáculos; aparece un marcador en el suelo |
| Mantener el botón izquierdo | Correr tras el cursor; el cursor se oculta mientras corres |
| Botón izquierdo + derecho, en cualquier orden | Correr hacia donde mira la cámara. Gira la cámara con el mouse y el héroe gira con ella. A / D desvían en diagonal hacia adelante. Suelta el botón izquierdo para detenerte |
| Botón derecho + mouse | Orbitar la cámara alrededor del héroe; después el cursor vuelve a su lugar |
| Botón derecho + WASD | Moverse según la cámara, de costado o girando (ver abajo). Suelta las teclas o el botón para detenerte |
| Rueda del mouse | Bajar la cámara más cerca del héroe o subirla más arriba y más lejos |
| Shift | Sprint mientras se mantiene, o alternar con una pulsación (una opción). Con la fatiga activada, mientras dure la resistencia; la barra de resistencia está en la parte inferior de la pantalla |
| Espacio | Saltar |
| F10 | Configuración (pausa el juego); Esc o F10 la cierra |

## Clic o mantener

Si una pulsación es un clic o una pulsación mantenida se decide a los 0,2 s.

- **Clic** (se suelta antes): el héroe corre por una ruta hasta el punto donde presionaste, aunque el mouse se haya
  movido después, y allí aparece un marcador. La carrera empieza al soltar. El marcador se desvanece cuando el héroe
  llega o cuando tomas el control con una pulsación mantenida o con las teclas.
- **Mantener** (se mantiene más tiempo): el héroe corre tras el cursor de inmediato y nunca gira hacia el punto
  donde presionaste.

Hasta que se decide, el héroe sigue haciendo lo que estaba haciendo.

Cómo sigue el héroe a un botón mantenido (Configuración → Controles → **Clic izq. mantenido**):

- **Directo al cursor** (por defecto): sin búsqueda de ruta. El héroe se desliza junto a los obstáculos y sube la
  rampa hacia donde lo apuntes, y se detiene suavemente al soltar.
- **Al punto por una ruta**: el héroe sigue una ruta de navegación hasta el punto bajo el cursor. Cerca de los
  cambios de altura (la rampa, la plataforma) la ruta puede saltar de un recorrido a otro. Al soltar, el héroe sigue
  corriendo hasta el último punto.

Mientras un botón mantenido gira la cámara (modo de seguimiento), el cursor se mueve con el mundo y se queda sobre el
lugar al que apuntaste, así el héroe mantiene el rumbo. Configuración → Cámara → **El cursor mantiene la mira al
girar la cámara**.

## Teclas con el botón derecho

WASD funcionan solo mientras se mantiene el botón derecho. Sin él no hacen nada. El modo se elige por separado para
el botón derecho solo (**Clic der. + WASD**) y para ambos botones (**Clic izq. + der. + A/D**), cada uno con
**Desactivado** y dos variantes:

| | Lateral | Giro / diagonal (por defecto) |
|---|---|---|
| Clic der. + W | hacia adelante, adonde mira la cámara | igual |
| Clic der. + A / D | de costado, mirando al frente | gira a la izquierda / derecha y va hacia allí |
| Clic der. + S | hacia atrás, mirando al frente, más lento | se da la vuelta y camina hacia la cámara |
| Dos teclas (W + A, S + D…) | en diagonal, mirando al frente | en diagonal, mirando hacia donde va |
| Clic izq. + der. + A / D | en diagonal hacia adelante, mirando al frente | en diagonal hacia adelante, mirando hacia donde va |

El movimiento en diagonal es tan rápido como el recto. Retroceder es un 30% más lento por defecto (3,85 m/s en vez de
5,5; Configuración → Controles → **Retroceso (S) más lento en**). Moverse en diagonal hacia atrás se ralentiza en
parte (S + D en modo lateral: 21%) y de costado nada, así que la ralentización solo existe en el modo lateral.

Tras detenerse, el héroe sigue mirando hacia donde miraba; un clic o una pulsación mantenida lo vuelve a orientar
hacia donde corre.

Mantener solo el botón derecho, sin teclas, no interrumpe una carrera hacia un punto donde hiciste clic, así que
puedes girar la cámara mientras corres. Suelta el botón izquierdo mientras mantienes el botón derecho y W, y el héroe
sigue caminando con las teclas sin detenerse. Un modo en **Desactivado** también quita su línea de la ayuda de
controles.

Las teclas están asignadas por posición física, así que son WASD con cualquier distribución de teclado.

## Cámara

- **Órbita:** botón derecho y mouse. El movimiento vertical también inclina la cámara si Configuración → Cámara →
  **Clic der. inclina la cámara arriba/abajo** está activado (desactivado por defecto).
- **Zoom:** la rueda cambia la distancia y la inclinación juntas. Por debajo de la mitad la cámara se nivela rápido,
  así ves lo que hay delante.
- **Seguimiento** (desactivado por defecto): Configuración → Cámara → **Girar la cámara siguiendo la carrera** y
  **Alinear inclinación de cámara**. La cámara no sigue mientras se mantiene el botón derecho ni durante los primeros
  0,2 s de una pulsación del botón izquierdo.
- **Obstáculos:** la cámara se detiene ante una montaña, una pared o un techo que tenga detrás. Opcionalmente se
  acerca cuando un obstáculo oculta al héroe. Detrás de los obstáculos el héroe se ve como una silueta.

Detalles: [Cámara](systems/camera.md).

## Sprint y salto

- **Sprint:** 1,5 veces más rápido mientras se mantiene Shift y el héroe se mueve. Con fatiga, la resistencia dura
  5 s; cuando se agota, el héroe corre a velocidad normal hasta recuperar el 30%, y luego vuelve a esprintar solo si
  Shift sigue presionado. Quedarse quieto con Shift presionado no gasta nada. En el modo alternar, una pulsación
  activa el sprint y la siguiente lo desactiva; también se desactiva cuando el héroe se agota.
- **Salto:** 1 m de altura. Un salto presionado poco antes de aterrizar se ejecuta al aterrizar; un salto presionado
  poco después de salir caminando de un borde todavía funciona. La protección de bordes no impide saltar desde un
  borde.

Detalles: [Locomoción](systems/locomotion.md).

---

*Esta página corresponde a Iso & Orbit 1.1.0.*
