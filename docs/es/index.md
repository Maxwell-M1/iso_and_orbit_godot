<!-- translation of docs/en/index.md @ ac381bae4d1d -->
# Documentación

[English](../en/index.md) · **Español** · [日本語](../ja/index.md) · [Português (Brasil)](../pt_BR/index.md) · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · [简体中文](../zh_CN/index.md)

> Esta es una traducción del [original en inglés](../en/index.md).
> Si hay diferencias, la versión en inglés es la correcta.

Un controlador de personaje con movimiento por clic y una cámara orbital para RPG isométricos y cenitales en
Godot 4.7, con un nivel de demo. Empieza por el [README](../../README.es.md) para una visión general.

La documentación en inglés es la original. Las traducciones la siguen y pueden quedar desactualizadas; donde
difieran, la página en inglés es la correcta.

## Inicio

- [Primeros pasos](getting-started.md): requisitos, cómo abrir el proyecto, qué hay en la demo.
- [Controles](controls.md): cada entrada, clic frente a pulsación mantenida, las teclas con el botón derecho,
  la cámara.
- [Configuración](settings.md): cada opción de la ventana de configuración, su clave, su valor por defecto
  y qué cambia.

## Código

- [Arquitectura](architecture.md): la escena principal, cómo fluyen los datos en un tick de física, los
  componentes y por qué están divididos así.
- [Uso en tu proyecto](integration.md): los addons y lo que necesita cada uno, la cámara sola, el movimiento
  por clic, tu propio cuerpo, los NPC.
- [Preparación del proyecto](project-setup.md): capas de física, acciones de entrada, grupos y ajustes del
  proyecto que esperan los componentes.

## Sistemas

- [Locomoción](systems/locomotion.md): `LocomotionSettings`, `GroundMotion`, `NavigationMover`,
  `GroundCharacter`, sprint y resistencia, el salto, la protección de bordes.
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

## Mantenimiento

- [Pruebas](testing.md): cómo ejecutarlas, qué cubre cada suite, cómo escribir una comprobación.
- [Problemas conocidos](known-issues.md): limitaciones y peculiaridades del motor, con qué hacer al respecto.
- [Glosario](glossary.md): términos usados en el código y en la documentación.
- [Hoja de ruta](roadmap.md): trabajo planificado.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
