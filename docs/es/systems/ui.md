<!-- translation of docs/en/systems/ui.md @ 8fc9a768e40b -->
# Interfaz de usuario

[← Índice de documentación](../index.md)

> Esta es una traducción del [original en inglés](../../en/systems/ui.md).
> Si hay diferencias, la versión en inglés es la correcta.

Ventanas sobre el juego, el sistema de configuración, el HUD y las traducciones de la interfaz.

## Ventanas: UiRoot y UiScreen

`UiRoot` (un `CanvasLayer`, `addons/iso_orbit/ui_screens/ui_root.gd`; la instancia de la demo es
`gdscript/ui/ui_root.tscn`) muestra las ventanas como una pila:

- `open(scene)` pone una ventana encima, `close_top()` cierra la de arriba, `toggle(scene)` cierra una ventana que
  está abierta (y todo lo que tenga encima) o la abre. Esc (`ui_cancel`) cierra la ventana de arriba; F10
  (`toggle_settings`) abre o cierra la ventana de configuración (`settings_screen`).
- Mientras hay alguna ventana abierta, el juego está en pausa (`pause_game`) y el cursor del mouse es visible.
  `UiRoot` solo pausa un juego en marcha y termina su propia pausa: si el juego estaba pausado al abrir la
  ventana, la pausa sigue a cargo de quien la inició. Si este la termina, el juego continúa detrás de la ventana
  (consulta [Niveles](levels.md#un-cambio-de-nivel)). `UiRoot` se ejecuta en `PROCESS_MODE_ALWAYS` y sus ventanas
  lo heredan.
- El foco del teclado pasa al `initial_focus` de la ventana cuando se abre y vuelve a donde estaba cuando se cierra.
- Señales: `screen_opened(screen)`, `screen_closed(screen)`. Consultas: `has_open_screens()`, `get_top_screen()`.

Una ventana es una escena cuya raíz extiende `UiScreen`, un `Control` de pantalla completa. Una ventana nunca se
cierra a sí misma: lo pide con la señal `close_requested` (`request_close()`), y `UiRoot` la cierra. Las llamadas
bajan por el árbol y las señales suben, así que `UiRoot` siempre sabe qué ventanas están abiertas y restaura
correctamente el foco y la pausa. Sobrescribe `_screen_opened()` y `_screen_closed()` para reaccionar.

**Una ventana nueva:** una escena con una raíz `UiScreen`, organizada con contenedores y con el estilo del tema;
ábrela con `UiRoot.open(scene)`.

## Configuración

### GameSettings

El autoload `Settings` (`gdscript/settings/game_settings.gd`, clase `GameSettings`) guarda los valores:

- Las claves son constantes de la clase (`GameSettings.LEDGE_GUARD` es `&"gameplay/ledge_guard"`), así que funcionan
  en `match`. La parte antes de la barra es la sección en el archivo.
- `DEFAULTS` contiene cada clave con su valor por defecto; el tipo del valor por defecto es el tipo de la opción. Un
  valor del tipo incorrecto en el archivo (editado a mano) vuelve al valor por defecto.
- `get_value(key)`, `set_value(key, value)`, `reset_to_defaults()` y la señal `changed(key, value)`.
- Los valores se cargan en `_init()`, antes del `_ready()` de cualquier nodo de la escena, y se guardan en
  `user://settings.cfg` cuando se cierra la ventana de configuración y cuando se sale del juego. `persistent = false`
  detiene el guardado; las pruebas lo establecen y restablecen todo a los valores por defecto, así que ignoran la
  configuración del jugador y nunca la sobrescriben.
- Las claves listadas en `_OBSOLETE_KEYS` se eliminan del archivo al cargarlo.
- Los ajustes a nivel de motor los aplica la propia clase (`_apply_to_engine()`): pantalla completa, límite de
  fotogramas y V-Sync, interpolación de física, escala de la interfaz, idioma, volumen. Los ajustes de los nodos de la
  escena los aplica la escena: en la demo, `gdscript/demo/settings_applier.gd` lee `get_value()` al iniciar y escucha
  `changed`.

**Una opción nueva:**

1. Una constante de clave y un valor por defecto en `DEFAULTS` en `GameSettings`.
2. Un control con esa clave en `settings_screen.tscn` (ver abajo). El código de la ventana no cambia.
3. Una rama en `settings_applier.gd` que establezca la propiedad, o en `GameSettings._apply_to_engine()` si la
   aplica el motor.
4. Sus textos en las traducciones, ver [Traducciones](#traducciones).

### La ventana de configuración

`gdscript/ui/settings/settings_screen.tscn` tiene seis pestañas: Controles, Personaje, Cámara, Pantalla, Interfaz,
Sonido. Todas las opciones y sus valores por defecto están en [Configuración](../settings.md).

- Cada control se vincula por sí mismo a una clave y se actualiza cuando la opción cambia desde cualquier lugar:
  - `SettingCheckButton`: una opción booleana.
  - `SettingOptionButton`: una opción entera; el valor de un elemento es su ID, que se fija en el Inspector junto con
    su texto, así que los elementos se pueden reordenar libremente.
  - `SettingSlider`: un número. `value_label` muestra el valor con `value_format`; `zero_text` reemplaza el cero
    (por ejemplo "al instante"); `apply_on_release` aplica un arrastre del mouse solo al soltar, para opciones que
    cambian el tamaño de la propia interfaz. Los límites y el paso son las propiedades de `Range`.
  - `SettingLanguageButton`: el idioma de la interfaz, ver abajo.
- Los controles que no tienen sentido sin otra opción se atenúan y se bloquean: la ralentización hacia atrás sin el
  modo lateral, la altura del salto sin el salto, todo lo del sprint sin el sprint, la duración de la resistencia sin
  la fatiga, el tiempo de giro sin girar, el ángulo y tiempo de inclinación sin alinearla, la altura y tiempo sin
  alineación de altura y los pasos mientras el héroe flota (`_update_dependent_rows()`).
- Cada página de pestaña es un `ScrollContainer`: una pestaña larga se desplaza (también siguiendo el foco del
  teclado) y la ventana no crece. La altura de la ventana es el `custom_minimum_size` del `TabContainer` (440). La
  pestaña Cámara, la más larga, y Personaje se desplazan; toda la ventana permanece visible al 100% de escala.
- **Restablecer todo** llama a `reset_to_defaults()`. La ventana guarda la configuración cuando se cierra.
- El texto de ayuda de V-Sync lo compone el código a partir de una frase traducida y la frecuencia de actualización
  del monitor.

### Escala de la interfaz

La escala de la interfaz es el `content_scale_factor` de la ventana raíz. Con el modo de estiramiento `canvas_items`
escala todo el 2D (la ayuda, el contador de FPS, la barra de resistencia, las ventanas) y deja intacta la vista 3D.
100% es el tamaño tal como está diseñado en las escenas, 50% la mitad. El control deslizante arrastrado con el mouse
aplica la escala solo al soltar (`apply_on_release`); de lo contrario la ventana cambiaría de tamaño bajo el mouse y
el control deslizante se alejaría de él. El teclado y la rueda cambian la escala de inmediato.

## HUD

| Nodo en `main.tscn` | Script | Qué muestra |
|---|---|---|
| `Hud`, `Hud/Panel` | `gdscript/demo/hud.gd` en `Hud` | Ayuda de controles con las teclas actuales (`Hud/ActionTexts`, consulta [Nombres de teclas en los textos](#nombres-de-teclas-en-los-textos)) y velocidad real del héroe (`GroundCharacter.get_move_speed()`; contra una pared es 0). El script solo actualiza la velocidad; `settings_applier.gd` muestra u oculta el panel y las líneas de funciones desactivadas (mirar alrededor, teclas con derecho, ambos botones + A/D, sprint y salto) |
| `Hud/FpsCounter` | `FpsCounter` (Label) | Fotogramas por segundo en la esquina superior derecha; funciona en pausa |
| `Hud/CharacterState/Monitor` | `CharacterMonitor` (Label) | Debajo del contador de FPS: lo que está haciendo el héroe (estado, velocidad y mezcla, movimiento, giro, suelo o aire, pasos y pies, resistencia) y los últimos eventos. Oculto por defecto. Ver [Locomoción](locomotion.md#charactermonitor-el-estado-como-texto) |
| `Hud/DiscoveryToast` | `DiscoveryToast` (Label) | «Lugar descubierto: …» durante `show_time` (3.5 s) al entrar por primera vez en un `PointOfInterest`. Encuentra todos mediante `points_of_interest`, incluso los añadidos después al cargar otro nivel (`watch_added_places` activado; desactivado: solo lugares iniciales); `show_discovery(title)` permite mostrar uno manualmente |
| `Hud/StaminaBar` | `StaminaBar` (ProgressBar) | Aparece cuando empieza a gastarse la resistencia, se pone roja mientras el personaje está agotado (variación `StaminaBarExhausted`) y se desvanece en 0,6 s cuando vuelve a estar llena |
| `Hud/TravelPrompt` | `TravelPrompt` (Control), `gdscript/ui/travel_prompt.gd` | Invitación a viajar en una plataforma, sobre la barra de resistencia: tecla de `interact` en un distintivo (`InputNames.of_action()`) y «Teletransporte: <lugar>». La tecla o un clic confirma (`confirmed(portal)`), también con Mayús u otro modificador. El botón no toma el foco: Espacio salta y no lo pulsa. No es una ventana: el juego sigue |

La pantalla de carga (`LoadingScreen` en `main.tscn`, del addon `levels`) no pertenece al HUD: cubre el juego
durante el cambio de nivel; consulta [Niveles](levels.md#la-pantalla-de-carga). El HUD se oculta mientras captura
la imagen y reaparece debajo de ella.

El panel de ayuda, el contador de FPS, la línea de ruta y el panel del estado del personaje se activan y desactivan en
Configuración → Interfaz.

## Tema

`shared/ui/ui_theme.tres` es el tema del proyecto (`gui/theme/custom`): paneles, la ventana, botones y estas
variaciones de tipo: `WindowPanel`, `WindowLayout`, `TabPage`, `SettingsList`, `HintLabel`, `FpsCounter`,
`DiscoveryToast`, `StaminaBar`, `StaminaBarExhausted`, `KeyBadge`, `TravelButton`. Los nodos eligen una variación
con `theme_type_variation` en vez de sobrescribir estilos. La pantalla de carga lleva su propio tema,
`loading_screen_theme.tres`, para mantener el mismo aspecto en cualquier proyecto.

## Traducciones

El inglés es el idioma de las propias escenas y scripts. Los demás idiomas son traducciones gettext en
`l10n/ui/<locale>.po`, registradas en `project.godot` (`internationalization/locale/translations`). El idioma es la
opción `interface/language` (Configuración → Interfaz → **Idioma**, inglés por defecto); `GameSettings` lo pasa a
`TranslationServer.set_locale()`, y la interfaz cambia de inmediato, sin reiniciar.

Cómo se traducen los textos:

- **Los textos de las escenas** los traduce el motor: los textos de `Label`, `Button` y `CheckButton`, los elementos
  de `OptionButton`, los tooltips, los títulos de pestañas y los textos de `Label3D` sobre PNJ y letreros de
  teletransporte (`auto_translate_mode`). El título que el script escribe en la pantalla de carga se traduce
  igual; sus consejos los traduce el script antes de insertar los nombres de teclas (`tip_format`).
- **Los textos compuestos por código** usan `tr()`: «Lugar descubierto: …» con el nombre del lugar, la invitación
  «Teletransporte: %s», los valores de
  los controles deslizantes con unidades y el texto de ayuda de V-Sync se reconstruyen con
  `NOTIFICATION_TRANSLATION_CHANGED`; el indicador de velocidad se reconstruye en cada fotograma de todos modos. Esos
  nodos desactivan la traducción automática para sí mismos, para que el motor no intente traducir el resultado
  compuesto.
- **Los nombres de los idiomas** en la lista de idiomas están escritos en su propio idioma ("English", "Русский") y
  nunca se traducen (`SettingLanguageButton.NATIVE_NAMES`).

**Un idioma nuevo:**

1. Copia `l10n/ui/ru.po` en `l10n/ui/<locale>.po`, fija `Language` y `Plural-Forms` en el encabezado y traduce cada
   `msgstr`. Un editor de PO como Poedit ayuda.
2. Agrega el archivo a `internationalization/locale/translations` (Configuración del Proyecto → Localización →
   Traducciones; en inglés, Project Settings → Localization → Translations).
3. Agrega el nombre propio del idioma a `NATIVE_NAMES` en `gdscript/ui/settings/setting_language_button.gd`. La lista
   de la ventana de configuración se construye a partir de las traducciones cargadas, así que no cambia nada más.
4. Ejecuta las pruebas: `tests/localization_checks.gd` informa de cada texto ausente, entrada que ya no se muestra
   o traducción que pierde una marca de tecla.

**Un texto nuevo:** escríbelo en inglés en la escena o en `tr("...")`, nombra las teclas mediante marcas (consulta
la sección siguiente) y agrega un `msgid` traducido a cada archivo `.po`. La prueba recoge las escenas, incluidas
las plantillas de `ActionTexts`; los textos que solo los scripts pasan a `tr()` están
listados en `SCRIPT_STRINGS` en `tests/localization_checks.gd`, así que agrega allí los nuevos.

### Nombres de teclas en los textos

Un texto no escribe una tecla fija: escribe la acción entre llaves y, al mostrarlo, se inserta su tecla actual.
`{sprint} — run faster` muestra «Shift — correr más rápido» y, al asignar sprint a Ctrl, «Ctrl — correr más
rápido». Las indicaciones siguen siendo correctas si se cambia el mapa de entrada o el juego deja reasignar teclas.
`InputNames` (del addon `ui_screens`) obtiene los nombres:

- `{action}`: primera tecla o botón de ratón de la acción. Una tecla se nombra según la letra que muestra la
  distribución del jugador (W en QWERTY y en una distribución rusa, Z en AZERTY), incluidos modificadores
  (`Ctrl+S`). Los botones usan nombres breves: izquierdo, derecho, central, rueda arriba, etc. Una asignación
  física limitada a un modificador de un lado indica ese lado, como `Ctrl+Right Shift`; una lógica admite ambos.
- `{a/b}`: varias acciones separadas por barras. `{move_left/move_right}` muestra «A/D». Dos acciones de rueda,
  arriba y abajo, se muestran como «Rueda».
- `{a+b+c+d}`: junta los nombres si todos son una sola letra. Por ejemplo,
  `{move_forward+move_left+move_back+move_right}` muestra «WASD»; de otro modo los separa con barras.
- Una acción sin eventos se muestra como «Sin asignar». Una marca de acción que no está en el mapa permanece
  literal para hacer visible la ausencia.

Los nombres también se traducen: los botones (`InputNames.get_mouse_names()`), «Space», «Unbound», «Left %s» y
«Right %s» tienen entradas en los archivos `.po`; los otros nombres de teclas son iguales en todos los idiomas.
Una traducción conserva las marcas de su cadena; `localization_checks.gd` falla si se pierde o modifica una.

Quién inserta los nombres:

- **`ActionTexts`** es un `Node` de la escena. Atiende todos los controles bajo su padre (o bajo `root`) cuyos
  textos, descripciones o elementos `OptionButton` contienen marcas: conserva las plantillas, desactiva su
  traducción propia y establece los textos traducidos con las teclas. Repite al cambiar de idioma. Tanto el HUD
  (`Hud/ActionTexts`) como la ventana de ajustes tienen uno. `ActionTexts` conserva esas plantillas. Los controles
  sin marcas siguen como estaban,
  incluidos los hijos que heredan traducción. Si se desactivó explícitamente la traducción en un control, su
  plantilla permanece literal pero los nombres de teclas sí se localizan. Excluye controles cuyo texto establece
  otro script, pues una actualización devolvería la plantilla. Tras cambiar teclas, llama a
  `get_tree().call_group(ActionTexts.GROUP, &"refresh")`.
- **Código:** `InputNames.format(tr(text))` para un texto completo o `InputNames.of_action(&"interact")` para una
  sola tecla, como el distintivo de la invitación. `TravelPrompt` pertenece a `ActionTexts.GROUP`, por lo que
  actualizar el grupo también renueva su tecla visible.
- **Consejos de pantalla de carga:** `LoadingScreen.tip_format` es un `Callable` que convierte un consejo
  traducido en el texto visible. `gdscript/main.gd` lo establece en `InputNames.format` y agrega la pantalla a
  `ActionTexts.GROUP`. `LoadingScreen.refresh()` vuelve a formatear el consejo actual sin reiniciar su tiempo.
  El addon `levels` no necesita `ui_screens`: sin `tip_format`, muestra el consejo traducido.

Si cambias el mapa de entrada en Ajustes del proyecto antes de iniciar, los textos ya muestran las asignaciones
nuevas. Si lo cambias con `InputMap` durante la partida, actualiza el grupo después de editarlo; también funciona
con el juego pausado. La demo no incluye una pestaña para reasignar teclas durante la partida.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
