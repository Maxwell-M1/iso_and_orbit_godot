<!-- translation of addons/iso_orbit/click_to_move/README.md @ 29860f203673 -->
# Перемещение по щелчку

[← Оглавление документации (репозиторий шаблона)](../../../docs/ru/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · **Русский** · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Это перевод [английского оригинала](README.md). При расхождениях верен оригинал.

Перемещение по щелчку для изометрических игр и игр с видом сверху: щёлкните по земле — и персонаж побежит туда по
навигационному пути и остановится в его достижимом конце; зажмите кнопку — и он побежит за курсором.
Равномерный разгон и
торможение, ограниченная скорость поворота, мгновенный разворот с места. При зажатой правой кнопке WASD двигают
персонажа относительно камеры. Если нажать правую кнопку во время бега за курсором, герой сохранит курс,
а игрок сможет осмотреться.

Часть Iso & Orbit — шаблона камеры и контроллера персонажа для Godot 4.7. Лицензия MIT (см. `LICENSE`).

## Состав

| Файл | Класс | Назначение |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Скорость, разгон, торможение, поворот |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | Математика: направление и оставшееся расстояние → скорость |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`, `halt()`, `face()`; возвращает скорость, никогда не двигает тело |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Мышь и ПКМ + WASD → команды контроллеру; `cancel()` сбрасывает текущее нажатие |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | Метка в точке щелчка |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | Отладочная линия вдоль оставшегося пути |

Другие аддоны не нужны. Для готового тела с гравитацией, прыжком и ускорением добавьте
`addons/iso_orbit/ground_character`.

## Настройка

1. Скопируйте эту папку в `res://addons/iso_orbit/click_to_move/`.
2. Запеките навигационную сетку уровня (`NavigationRegion3D`). Размер агента и подъём согласуйте с капсулой
   и ступенями тела. Если сетки нет или результат пути пуст, контроллер бежит прямо к заданной точке; неполный
   путь может завершиться на ближайшей достижимой точке. Телу по-прежнему нужны коллизии и форма столкновения.
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

   Назначьте `NavigationMover.settings` ресурс `LocomotionSettings` до входа контроллера в дерево или оставьте
   пустым для создания ресурса со значениями скрипта. Если персонажам нужны разные настройки, используйте
   **Make Unique**. Изменение полей ресурса во время игры действует; замена `mover.settings` после `_ready()`
   не обновляет созданный ранее объект `GroundMotion`. `GroundCharacter` из соседнего аддона обрабатывает ступени,
   прыжок и защиту от обрывов, если они вам нужны.

4. Для управления мышью добавьте в любое место `Node` с `point_click_move_input.gd` и задайте его `mover` и
   `camera`. Ему нужны действия ввода `move_to_cursor` (левая кнопка), `camera_rotate` (правая кнопка) и
   `move_forward`, `move_back`, `move_left`, `move_right` (WASD). Об отсутствии действия сообщается один раз при
   запуске; далее оно не читается. Щелчки попадают в физический слой 1 (`ground_mask`): не включайте в него
   персонажей и невидимые стены, иначе щелчок попадёт в них. Если камера из `addons/iso_orbit/orbit_camera`,
   соедините `hold_pending_changed` с её `set_follow_paused`, а `run_requested` — с `end_follow_wait`.
   Осмотр во время бега (`look_around_while_held`) требует, чтобы `camera_steer_action` совпадало с действием
   вращения камеры (её `rotate_action`; оба по умолчанию `camera_rotate`).
5. Можно управлять контроллером из ИИ: `move_to(point)`, `steer(direction)`, `stop()`, слушая `arrived`. Сигнал
   означает конец пути, который может не дойти до запрошенной точки, если она недостижима.

Чтобы взять собранного героя с готовой сценой и настройками, следуйте `docs/ru/integration.md`, а не собирайте
это тело вручную. Два режима ввода и настройки героя описаны в `docs/ru/systems/input.md`.

## Документация

В репозитории шаблона: `docs/ru/integration.md`, `docs/ru/systems/locomotion.md` и
`docs/ru/systems/input.md`.

---

*Страница соответствует Iso & Orbit 1.2.0.*
