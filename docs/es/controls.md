<!-- translation of docs/en/controls.md @ 18ede9271cf7 -->
# Controles

[← Índice de documentación](index.md)

> Esta es una traducción del [original en inglés](../en/controls.md).
> Si hay diferencias, la versión en inglés es la correcta.

Mouse y teclado; no hay soporte para gamepad. Casi todo el comportamiento descrito abajo se puede cambiar en la
ventana de configuración (F10), ver [Configuración](settings.md). Cómo funciona la entrada por dentro:
[Entrada](systems/input.md).

Las teclas y botones de esta página, como en el resto de la documentación, son los valores iniciales de la demo,
establecidos en Ajustes del proyecto → Mapa de entrada. Las indicaciones del juego, la ventana de ajustes y la
pantalla de carga muestran las teclas asignadas actualmente: si las cambias, muestran los nombres nuevos. Consulta
[Nombres de teclas en los textos](systems/ui.md#nombres-de-teclas-en-los-textos).

| Entrada | Acción |
|---|---|
| Clic izquierdo en el suelo | Correr hasta ese punto rodeando los obstáculos; aparece un marcador en el suelo |
| Mantener el botón izquierdo | Correr tras el cursor; el cursor se oculta mientras corres |
| Mantener el izquierdo y luego pulsar el derecho | Mirar alrededor mientras corres: el ratón gira la cámara y el héroe conserva el rumbo. Al soltar el derecho, el ratón vuelve a dirigir la carrera |
| Mantener el derecho y luego pulsar el izquierdo, o ambos a la vez | Correr hacia donde mira la cámara. Al girarla con el ratón, el héroe gira con ella. A / D desvían en diagonal hacia adelante. Suelta el izquierdo para parar, o ambos en cualquier orden |
| Botón derecho + mouse | Orbitar la cámara alrededor del héroe; después el cursor vuelve a su lugar |
| Botón derecho + WASD | Moverse según la cámara, de costado o girando (ver abajo). Suelta las teclas o el botón para detenerte |
| Rueda del mouse | Bajar la cámara más cerca del héroe o subirla más arriba y más lejos |
| Shift | Sprint mientras se mantiene, o alternar con una pulsación (una opción). Con la fatiga activada, mientras dure la resistencia; la barra de resistencia está en la parte inferior de la pantalla |
| Espacio | Saltar |
| E | En una plataforma de teletransporte, viajar al lugar indicado. Hacer clic en la invitación logra lo mismo |
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
lugar al que apuntaste, así el héroe mantiene el rumbo. Ocurre también al girar con el botón derecho para mirar
alrededor durante una carrera. Configuración → Cámara → **El cursor mantiene la mira al girar la cámara**.

## Ambos botones: qué ocurre y cuándo

El botón derecho siempre gira la cámara. Que también dirija la carrera depende del orden de las pulsaciones. Con
los ajustes predeterminados:

| Pulsas | Héroe | Cámara |
|---|---|---|
| Izquierdo mantenido | Corre directamente hacia el cursor | Permanece como está; seguimiento desactivado por defecto |
| ...luego también el derecho y mueves el ratón | Conserva el rumbo; mirar alrededor no dirige. Las teclas no actúan entretanto | Orbita alrededor del héroe |
| ...luego sueltas el derecho, manteniendo el izquierdo | Continúa con el mismo rumbo. El cursor oculto queda sobre el punto buscado y el ratón vuelve a dirigir desde allí | Queda como la dejaste |
| ...o sueltas primero el izquierdo | Frena suavemente; el cursor aparece en el punto buscado al soltar después el derecho | Orbita hasta soltar el derecho |
| Derecho y luego izquierdo, o ambos en menos de 0.2 s | Corre hacia donde mira la cámara y gira con ella; A / D desvían en diagonal hacia adelante | Gira con el ratón |
| ...luego sueltas el derecho, manteniendo el izquierdo | Conserva el rumbo de la cámara hasta mover el ratón; entonces el cursor, colocado 4 m delante del héroe, dirige | Queda como la dejaste |
| ...y pulsas otra vez el derecho antes de mover el ratón | Corre otra vez en la dirección de la cámara. Cuando el cursor ya dirige tras mover el ratón, el derecho permite mirar alrededor | Gira con el ratón |
| Sueltas el izquierdo | Frena suavemente en cerca de un cuarto de segundo. Con el derecho y W pulsados, sigue caminando con las teclas | — |
| Sueltas ambos, en cualquier orden y con cualquier intervalo, aunque se mueva el ratón | Se detiene en su rumbo sin girar hacia el cursor | — |
| Un clic y luego el derecho | Sigue hasta el punto marcado | Orbita alrededor del héroe |
| Derecho y WASD | Camina según la cámara y mira hacia donde va | Gira con el ratón |

Para pasar de mirar alrededor a correr según la cámara sin detenerte, pulsa otra vez el izquierdo mientras
mantienes el derecho.

### Efectos de los ajustes

- **Clic der. al correr con Clic izq. solo gira la cámara** (Controles), desactivado: el derecho dirige la
  carrera con cualquier orden. Si lo pulsas durante una carrera tras el cursor, el héroe gira de inmediato hacia
  donde mira la cámara.
- **El cursor mantiene la mira al girar la cámara** (Cámara), desactivado: mientras miras alrededor, el cursor
  permanece en la misma posición de pantalla y la carrera gira con la cámara en un arco. Ocurre lo mismo con una
  cámara que sigue la carrera.
- **Clic izq. mantenido → Al punto por una ruta** (Controles): sigue una ruta hacia el punto bajo el cursor.
  Mientras miras alrededor y después hasta mover el ratón, el destino permanece en el mismo lugar respecto al
  héroe, no bajo el cursor: desde otro ángulo, el cursor podría estar sobre la rampa o plataforma. Al soltar el
  izquierdo, el héroe continúa hacia el último punto.
- **Ocultar el cursor al correr con el botón izq. mantenido** (Controles), desactivado: después de mirar alrededor,
  el cursor salta desde donde estaba al punto que seguía, desplazado en pantalla por el giro de cámara.
- **Girar la cámara siguiendo la carrera**, **Alinear inclinación de cámara al correr** y
  **Alinear altura de cámara al correr** (Cámara): se alinea detrás de una carrera tras el cursor o a un punto,
  salvo mientras se mantiene el derecho. Tras girarla con ese botón, también al mirar alrededor durante la
  carrera, conserva la vista hasta que el héroe se detenga o comience otra carrera con el izquierdo. Nunca sigue
  el movimiento con teclas, pues estas requieren el botón derecho.
- **Clic der. + WASD** y **Clic izq. + der. + A/D** (Controles): determinan cómo mueven las teclas al héroe.

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

Un modo en **Desactivado** también quita su línea de la ayuda de controles. Para las combinaciones con teclas,
consulta [Ambos botones: qué ocurre y cuándo](#ambos-botones-qué-ocurre-y-cuándo).

Las teclas de movimiento usan las posiciones físicas de WASD en un teclado US QWERTY. Las letras mostradas siguen
la distribución del teclado: esas posiciones son ZQSD en AZERTY. Cambia las asignaciones en Ajustes del proyecto
→ Mapa de entrada; la demo todavía no incluye un menú de reasignación durante la partida.

## Cámara

- **Órbita:** botón derecho y mouse. El movimiento vertical también inclina la cámara si Configuración → Cámara →
  **Clic der. inclina la cámara arriba/abajo** está activado (desactivado por defecto).
- **Zoom:** la rueda cambia la distancia y la inclinación juntas. Por debajo de la mitad la cámara se nivela rápido,
  así ves lo que hay delante.
- **Seguimiento** (desactivado por defecto): Configuración → Cámara → **Girar la cámara siguiendo la carrera** y
  **Alinear inclinación de cámara al correr** y **Alinear altura de cámara al correr**. No sigue mientras se
  mantiene el derecho ni durante los primeros 0.2 s de una pulsación izquierda. Tras girarla con el derecho,
  también para mirar alrededor durante la carrera, conserva la vista elegida hasta que el héroe se detiene o
  inicia otra carrera con el izquierdo (clic o pulsación sostenida). No gira mientras frena o continúa hacia un
  punto marcado. Las teclas requieren el derecho, así que nunca se siguen automáticamente.
- **Obstáculos:** la cámara se detiene ante una montaña, una pared o un techo que tenga detrás. Opcionalmente se
  acerca cuando un obstáculo oculta al héroe. Detrás de los obstáculos el héroe se ve como una silueta.

Detalles: [Cámara](systems/camera.md).

## Teletransporte

Una plataforma luminosa junto al Círculo Antiguo lleva a Isla Solitaria y otra permite regresar. Súbete y
aparecerá abajo la invitación «E · Teletransporte: …»; al alejarte desaparece. Pulsa E (también con Mayús
mantenida, tras llegar esprintando) o haz clic en la invitación: la pantalla de carga cubre el cambio y el héroe
aparece junto a la otra plataforma, con la cámara detrás y los controles restablecidos. Una pulsación izquierda
que empezó antes del cambio solo cuenta desde la siguiente pulsación; las teclas que siguen mantenidas (derecho
con W, A, S o D, o Mayús) vuelven a actuar al instante. Consulta [Niveles](systems/levels.md).

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

*Esta página corresponde a Iso & Orbit 1.2.0.*
