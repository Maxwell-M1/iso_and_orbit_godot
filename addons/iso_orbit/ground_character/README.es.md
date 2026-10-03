<!-- translation of addons/iso_orbit/ground_character/README.md @ 22bbe02ebe51 -->
# Personaje terrestre

[English](README.md) · **Español** · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Esta es una traducción del [original en inglés](README.md). Si hay diferencias, la versión en inglés es la correcta.

Un cuerpo de personaje listo para usar con movimiento por clic: gravedad, un salto con tiempo de coyote y búfer de
entrada (la misma altura con cualquier frecuencia de ticks de física), sprint con resistencia, una protección de
bordes que detiene el cuerpo ante los desniveles, señales de pasos, saltos, aterrizajes y sprint, sonidos en esas
señales, un objeto en la mano que se balancea con los pasos y modelos intercambiables.

Parte de Iso & Orbit, una plantilla de cámara y controlador de personaje para Godot 4.7. Licencia MIT (ver
`LICENSE`).

## Contenido

| Archivo | Clase | Tarea |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Gravedad, salto, sprint, `move_and_slide()`, giro del modelo; señales |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Detiene el cuerpo ante un desnivel o lo desliza a lo largo del borde |
| `stamina.gd` | `Stamina` (Node) | La reserva para el sprint |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Teclas de sprint y salto → el personaje |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Reproduce sonidos con las señales del personaje |
| `hand_sway.gd` | `HandSway` (Node) | Balancea un nodo de mano con los pasos |
| `character_appearance.gd` | `CharacterAppearance` (Node) | Cambia el modelo en tiempo de ejecución |
| `stamina_bar.gd`, `stamina_bar.tscn` | `StaminaBar` (ProgressBar) | Una barra del HUD para `Stamina` |

Necesita `addons/iso_orbit/click_to_move`: el cuerpo lo controla un `NavigationMover`.

## Configuración

1. Copia esta carpeta y `click_to_move` en `res://addons/iso_orbit/`.
2. Arma el personaje:

   ```
   Player           CharacterBody3D con ground_character.gd
   ├── CollisionShape3D
   ├── Visual       Node3D; el modelo dentro mira hacia −Z
   ├── NavigationMover   de click_to_move
   ├── LedgeGuard   opcional
   └── Stamina      opcional
   ```

   Establece `mover`, `visual`, `ledge_guard` y `stamina` del cuerpo. La demo también activa `floor_constant_speed`
   en el cuerpo, para que el personaje conserve su velocidad en las rampas, y lo pone en la capa de física 2, aparte
   del nivel.
3. Para las teclas, agrega un `Node` con `character_action_input.gd` y establece su `character`. Necesita las
   acciones de entrada `sprint` y `jump`.
4. Opcional: `CharacterSounds` con hijos `AudioStreamPlayer3D`, `HandSway` con el nodo de la mano del modelo,
   `CharacterAppearance` con una lista de escenas de modelos. `LedgeGuard.floor_mask` es la capa de física 1 por
   defecto.

Una IA puede controlar el mismo cuerpo: llama a `NavigationMover.move_to()` y `GroundCharacter.jump()`, y establece
`sprint_requested`.

## Documentación

En el repositorio de la plantilla: `docs/es/integration.md`, `docs/es/systems/locomotion.md`,
`docs/es/systems/audio.md` y `docs/es/systems/characters.md`.

---

*Esta página corresponde a Iso & Orbit 1.0.0.*
