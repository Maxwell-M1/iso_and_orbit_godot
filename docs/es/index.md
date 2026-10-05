<!-- translation of docs/en/index.md @ 0499e77e2e07 -->
# Documentación

[English](../en/index.md) · **Español** · [日本語](../ja/index.md) · [Português (Brasil)](../pt_BR/index.md) · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · [简体中文](../zh_CN/index.md)

> Esta es una traducción del [original en inglés](../en/index.md).
> Si hay diferencias, la versión en inglés es la correcta.

Un controlador de personaje con movimiento por clic y una cámara orbital para RPG isométricos y cenitales en
Godot 4.7, con dos niveles de demo. Empieza por el [README](../../README.es.md) para una visión general.

La documentación en inglés es la original. Las traducciones la siguen y pueden quedar desactualizadas; donde
difieran, la página en inglés es la correcta.

## Primera integración funcional

1. [Ejecuta la demo](getting-started.md) para probar los controles predeterminados.
2. [Transfiere el héroe](integration.md#transferir-el-héroe-de-la-demo-a-tu-proyecto) a un nivel pequeño de tu
   proyecto. Sigue la lista de archivos, el mapa de entrada y los pasos de navegación antes de cambiar el personaje.
3. [Elige una configuración](configurations.md): órbita manual, ratón guiado por rutas o cámara de seguimiento.
4. Consulta las referencias de [movimiento](systems/locomotion.md), [entrada](systems/input.md) y
   [cámara](systems/camera.md) para ajustar propiedades concretas. [Personajes](systems/characters.md) explica
   cómo sustituir el modelo y agregar animación.

## Menú de documentación

Elige una página. Las guías de instalación de los addons figuran después de las referencias de sistemas.

### Inicio

- [Primeros pasos](getting-started.md): requisitos, cómo abrir el proyecto, qué hay en la demo.
- [Controles](controls.md): cada entrada, clic frente a pulsación mantenida, las teclas con el botón derecho,
  la cámara.
- [Configuración](settings.md): cada opción de la ventana de configuración, su clave, su valor por defecto
  y qué cambia.
- [Configuraciones del héroe](configurations.md): origen de los valores, rutas exactas de nodos, tres opciones
  coherentes y cómo comprobar el resultado.

### Código

- [Arquitectura](architecture.md): la escena principal, cómo fluyen los datos en un tick de física, los
  componentes y por qué están divididos así.
- [Uso en tu proyecto](integration.md): los addons y lo que necesita cada uno, la cámara sola, el movimiento
  por clic, tu propio cuerpo, los NPC.
- [Preparación del proyecto](project-setup.md): capas de física, acciones de entrada, grupos y ajustes del
  proyecto que esperan los componentes.

### Sistemas

- [Locomoción](systems/locomotion.md): `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `GroundCharacter`, lo
  que el personaje informa para las animaciones y la interfaz, `CharacterMonitor`, escalones y pendientes, sprint y
  resistencia, el salto, la caída (`FallSettings`) y la protección de bordes.
- [Cámara](systems/camera.md): `OrbitCameraRig` (órbita, curva de zoom, seguimiento) y `CameraArm`
  (obstáculos, acercamiento, desvanecimiento).
- [Entrada](systems/input.md): `PointClickMoveInput` (clic, pulsación mantenida, teclas, el cursor) y
  `CharacterActionInput`.
- [Personajes](systems/characters.md): modelos y equipo, aspectos del héroe, el balanceo de la mano, la
  silueta.
- [Audio](systems/audio.md): los sonidos del personaje y cómo se sintetizan.
- [Interfaz de usuario](systems/ui.md): ventanas, el sistema y la ventana de configuración, el HUD, el tema,
  las traducciones.
- [Mundo y navegación](systems/world-and-navigation.md): el nivel, los lugares, las superficies y las
  texturas horneadas, la montaña, la malla de navegación y cómo volver a hornearla.
- [Niveles](systems/levels.md): escena principal, host y pantalla de carga, portales, puntos de aparición,
  héroe jugable e isla.

### Guías de instalación de los addons

- [Movimiento por clic](../../addons/iso_orbit/click_to_move/README.es.md)
- [Personaje terrestre](../../addons/iso_orbit/ground_character/README.es.md)
- [Cámara orbital](../../addons/iso_orbit/orbit_camera/README.es.md)
- [Silueta tras obstáculos](../../addons/iso_orbit/occluded_silhouette/README.es.md)
- [Puntos de interés](../../addons/iso_orbit/points_of_interest/README.es.md)
- [Ventanas de interfaz](../../addons/iso_orbit/ui_screens/README.es.md)
- [Transiciones entre niveles](../../addons/iso_orbit/levels/README.es.md)

### Mantenimiento

- [Pruebas](testing.md): cómo ejecutarlas, qué cubre cada suite, cómo escribir una comprobación.
- [Problemas conocidos](known-issues.md): limitaciones y peculiaridades del motor, con qué hacer al respecto.
- [Glosario](glossary.md): términos usados en el código y en la documentación.
- [Hoja de ruta](roadmap.md): trabajo planificado.

---

*Esta página corresponde a Iso & Orbit 1.2.0.*
