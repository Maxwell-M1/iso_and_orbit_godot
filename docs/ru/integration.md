<!-- translation of docs/en/integration.md @ 69adeef2aab9 -->
# Использование в своём проекте

> Это перевод [английского оригинала](../en/integration.md). При расхождениях верен оригинал.

Переиспользуемые компоненты лежат в `addons/iso_orbit/`, по папке на каждую часть; общая папка отделяет их от ваших
остальных аддонов. Скопируйте нужные папки в `addons/iso_orbit/` своего проекта, свяжите узлы в своих сценах и
настройте проект, как описано на странице [Настройка проекта](project-setup.md). Скрипты — обычные классы GDScript
(`class_name`): никакой плагин редактора включать не нужно.

## Аддоны

| Аддон | Классы | Что нужно |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | Действия ввода `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`; физические слои для держателя камеры |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | Запечённый `NavigationRegion3D` в мире (без него персонаж бежит прямо к точке). Для ввода: любая `Camera3D` и действия `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` |
| `ground_character` | `GroundCharacter`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. Для клавиш: действия `sprint` и `jump`. Для звуков: свои или `shared/audio/character/`. Для покачивания руки и сменных моделей: модели, смотрящие в −Z, с узлом руки |
| `occluded_silhouette` | `OccludedSilhouette` с его шейдерами и материалами | Ничего: работает с любой моделью |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | Тело игрока в группе `player`, на физическом слое, который видят области |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter` | Встроенное действие `ui_cancel`; действие `toggle_settings`, если `UiRoot` открывает окно по клавише |

В папке каждого аддона есть `README.md` с инструкцией по настройке и копия `LICENSE`. Берите аддон целиком: классы
внутри ссылаются друг на друга по типу, а неиспользуемый файл ничему не мешает. Держите папки в
`res://addons/iso_orbit/<addon>/`: сцены и материалы в них ссылаются на свои файлы по этим путям. Чтобы положить
аддон в другое место, переместите его в панели «Файловая система» (FileSystem) редактора — она обновит ссылки.

Виджеты HUD (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) берут внешний вид из одноимённых вариаций типов в теме
демо, `shared/ui/ui_theme.tres`; без них используется тема по умолчанию.

Не вошли в аддоны, потому что построены вокруг этого демо: система настроек (`gdscript/settings/game_settings.gd` и
окно настроек в `gdscript/ui/settings/`, см. [Настройки](#настройки)), `gdscript/ui/ui_root.tscn` (`UiRoot`,
настроенный с этим окном) и связующий код демо `gdscript/demo/hud.gd` и `settings_applier.gd`.

## Только камера

Камера работает с любой целью типа `Node3D`, и ей нужна только папка `addons/iso_orbit/orbit_camera/`.

1. Добавьте в сцену `Node3D` с `orbit_camera_rig.gd` рядом с целью, а не внутрь неё.
2. Добавьте ему дочерний `Node3D` с `camera_arm.gd`, а тому — дочернюю `Camera3D`.
3. Задайте `target` у рига камеры. В `fade_target` держателя укажите узел, который должен становиться полупрозрачным,
   когда камера совсем близко, или оставьте поле пустым.
4. Добавьте действия ввода и, для держателя, физические слои со страницы [Настройка проекта](project-setup.md).

Без держателя тоже можно — с `Camera3D` прямо в качестве дочернего узла рига камеры: тогда камера стоит на расстоянии,
заданном зумом, и проходит сквозь стены. Риг обновляется в `_process` по интерполированной позиции цели, поэтому,
если цель движется в физических тиках, включите в проекте интерполяцию физики. Подробнее: [Камера](systems/camera.md).

## Перемещение по щелчку с готовым телом

Скопируйте `addons/iso_orbit/click_to_move/` и `addons/iso_orbit/ground_character/`.

1. Запеките навигационную сетку для своего уровня (`NavigationRegion3D` →
   **Запечь NavigationMesh** (Bake NavigationMesh)). Её радиус агента и максимальная высота подъёма должны
   подходить вашему персонажу, см. [Мир и навигация](systems/world-and-navigation.md).
2. Создайте `CharacterBody3D` с `ground_character.gd`: форма столкновения, узел `Visual` с моделью (смотрит в −Z) и
   такие дочерние узлы: `NavigationMover` (`Node` с `navigation_mover.gd`), по желанию `LedgeGuard` и `Stamina`.
   Задайте у тела `mover`, `visual`, `ledge_guard` и `stamina`.
3. Дайте контроллеру перемещения ресурс `LocomotionSettings` или оставьте поле пустым, чтобы взять значения по
   умолчанию.
4. Добавьте в любое место сцены `Node` с `point_click_move_input.gd` и задайте его `mover` и `camera`.
5. По желанию добавьте `character_action_input.gd` с `character`, указывающим на тело, — для ускорения и прыжка.

`gdscript/player/player.tscn` — это именно такая сборка плюс звуки, покачивание руки, сменная модель и силуэт. Можно
создать её экземпляр и убрать то, что не нужно.

## Своё тело

Чтобы оставить свой контроллер персонажа, возьмите только `addons/iso_orbit/click_to_move/`. Контракт короткий:

- `NavigationMover` должен быть прямым потомком тела (любого `Node3D`). Он читает позицию тела и навигационную карту
  мира, в котором находится тело.
- Тело вызывает `mover.compute_velocity(delta)` раз в физический тик, до `move_and_slide()`, и применяет X и Z
  результата. Контроллер перемещения никогда не двигает тело.
- Вертикальная скорость остаётся за телом: гравитация, прыжки, отбрасывание.

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover
@onready var ledge_guard: LedgeGuard = $LedgeGuard


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity = ledge_guard.constrain(velocity, delta)
	move_and_slide()
	var facing := mover.get_facing()
	$Visual.rotation.y = atan2(-facing.x, -facing.z)
```

`LedgeGuard` необязателен: это дочерний узел тела из `addons/iso_orbit/ground_character/`. Для ускорения выставьте
`mover.sprinting = true`: предел скорости вырастет в `LocomotionSettings.sprint_speed_multiplier` раз. Всё остальное,
что есть в `GroundCharacter` (прыжок, запас сил, сигналы шагов, плавный поворот модели), тогда остаётся на вас.

## Управление контроллером перемещения

Персонажем может управлять что угодно: ввод игрока, ИИ, катсцена или сетевой код.

| Вызов | Эффект |
|---|---|
| `move_to(point)` | Бежать к точке по навигационному пути и остановиться точно в ней. Можно вызывать каждый тик; точка, которая ближе `retarget_tolerance` (0,1 м) к текущей, не перестраивает путь |
| `steer(direction, facing = Vector3.ZERO)` | Бежать в направлении без пути, пока не будет другой команды; с `facing` — смотреть в ту сторону во время движения (боком) |
| `stop()` | Плавно затормозить там, где персонаж находится |
| `halt()` | Остановиться мгновенно, например после телепорта |

Сигналы: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (от точки отказались ради
`steer()` или `stop()`). Запросы: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Подробнее:
[Передвижение](systems/locomotion.md).

## NPC

Создайте экземпляр `player.tscn` (или своей сцены тела с контроллером перемещения) и удалите узлы `Silhouette` и
`Appearance`, нужные только игроку. Узлы ввода не добавляйте: вызывайте `NavigationMover.move_to()` из своего ИИ и
слушайте `arrived`. Чтобы взять одну из моделей персонажей демо, поместите её под `Visual` с именем `Model`. NPC,
стоящие на демо-уровне, — статичные тела, а не персонажи; см. [Мир и навигация](systems/world-and-navigation.md).

## Настройки

Компоненты никогда не читают настройки: каждый читает собственные экспортируемые свойства. Чтобы вынести их в своё
меню настроек, задавайте свойства из своего кода при изменении настройки. Пример — `gdscript/demo/settings_applier.gd`:
один `match` сопоставляет каждый ключ настроек свойству узла. Чтобы заодно взять систему настроек демо, скопируйте
`gdscript/settings/game_settings.gd`, зарегистрируйте его как автозагрузку `Settings`, замените его ключи и `DEFAULTS`
своими и возьмите элементы управления из `gdscript/ui/settings/`; см. [Интерфейс](systems/ui.md#настройки).

---

*Страница соответствует Iso & Orbit 1.1.0.*
