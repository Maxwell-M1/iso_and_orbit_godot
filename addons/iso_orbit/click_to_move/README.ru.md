<!-- translation of addons/iso_orbit/click_to_move/README.md @ 784d979b2a2a -->
# Перемещение по щелчку

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · **Русский** · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Это перевод [английского оригинала](README.md). При расхождениях верен оригинал.

Перемещение по щелчку для изометрических игр и игр с видом сверху: щёлкните по земле — и персонаж побежит туда по
навигационной сетке и остановится точно в точке; зажмите кнопку — и он побежит за курсором. Равномерный разгон и
торможение, ограниченная скорость поворота, мгновенный разворот с места. При зажатой правой кнопке WASD двигают
персонажа относительно камеры.

Часть Iso & Orbit — шаблона камеры и контроллера персонажа для Godot 4.7. Лицензия MIT (см. `LICENSE`).

## Состав

| Файл | Класс | Назначение |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Скорость, разгон, торможение, поворот |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | Математика: направление и оставшееся расстояние → скорость |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`; возвращает скорость, никогда не двигает тело |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Мышь и ПКМ + WASD → команды контроллеру перемещения |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | Метка в точке щелчка |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | Отладочная линия вдоль оставшегося пути |

Другие аддоны не нужны. Для готового тела с гравитацией, прыжком и ускорением добавьте
`addons/iso_orbit/ground_character`.

## Настройка

1. Скопируйте эту папку в `res://addons/iso_orbit/click_to_move/`.
2. Запеките навигационную сетку для своего уровня (`NavigationRegion3D`). Без неё персонаж бежит прямо к
   точке.
3. Добавьте `NavigationMover` прямым потомком тела персонажа. Тело вызывает `compute_velocity(delta)` раз в
   физический тик, до `move_and_slide()`:

   ```gdscript
   extends CharacterBody3D

   @onready var mover: NavigationMover = $NavigationMover


   func _physics_process(delta: float) -> void:
   	var planar := mover.compute_velocity(delta)
   	velocity.x = planar.x
   	velocity.z = planar.z
   	if not is_on_floor():
   		velocity += get_gravity() * delta
   	move_and_slide()
   ```

4. Для управления мышью добавьте в любое место `Node` с `point_click_move_input.gd` и задайте его `mover` и
   `camera`. Ему нужны действия ввода `move_to_cursor` (левая кнопка), `camera_rotate` (правая кнопка) и
   `move_forward`, `move_back`, `move_left`, `move_right` (WASD), а щелчки попадают в физический слой 1
   (`ground_mask`).
5. Или командуйте контроллером перемещения из ИИ: `move_to(point)`, `steer(direction)`, `stop()` — и слушайте `arrived`.

## Документация

В репозитории шаблона: `docs/ru/integration.md`, `docs/ru/systems/locomotion.md` и
`docs/ru/systems/input.md`.

---

*Страница соответствует Iso & Orbit 1.0.0.*
