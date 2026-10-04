<!-- translation of docs/en/project-setup.md @ 7a7b1e97933c -->
# Настройка проекта

> Это перевод [английского оригинала](../en/project-setup.md). При расхождениях верен оригинал.

Что компоненты ждут от `project.godot` и сцены. Перенося компоненты в другой проект, скопируйте те части этой
настройки, которые они используют.

## Физические слои

| Слой | Имя | Что на нём | Кто его читает |
|---|---|---|---|
| 1 | `world` | Земля, стены, декорации, гора, NPC, стоящие на уровне | Луч щелчка (`PointClickMoveInput.ground_mask`), `LedgeGuard.floor_mask`, `CameraArm.collision_mask`, запекание навигационной сетки |
| 2 | `characters` | Тело игрока (`collision_layer = 2`) | Области `PointOfInterest` (`collision_mask = 2`); держатель камеры его игнорирует |
| 3 | `camera` | Тела, которые останавливают только камеру, например `RoofCameraBlocker` в `shared/world/props/house.tscn` | Только `CameraArm.collision_mask` |

По умолчанию `CameraArm.collision_mask` включает слои 1 и 3 (`0b101`). Персонажи на слое 2 никогда не толкают
камеру. Тело на слое 3 останавливает камеру, но невидимо для щелчков, навигации и персонажей, так что камеру можно не
пускать в крышу и при этом никому не дать проложить по ней путь.

Навигационный слой 1 называется `ground`; по умолчанию `NavigationMover.navigation_layers` указывает на него.

## Действия ввода

| Действие | По умолчанию | Кто использует |
|---|---|---|
| `move_to_cursor` | Левая кнопка мыши | `PointClickMoveInput.move_action` |
| `camera_rotate` | Правая кнопка мыши | `OrbitCameraRig.rotate_action`, `PointClickMoveInput.camera_steer_action` |
| `camera_zoom_in` | Колесо вверх | `OrbitCameraRig.zoom_in_action` |
| `camera_zoom_out` | Колесо вниз | `OrbitCameraRig.zoom_out_action` |
| `move_forward`, `move_back`, `move_left`, `move_right` | W, S, A, D | `PointClickMoveInput`, при зажатой правой кнопке |
| `sprint` | Shift | `CharacterActionInput.sprint_action` |
| `jump` | Пробел | `CharacterActionInput.jump_action` |
| `toggle_settings` | F10 | `UiRoot.settings_action` |
| `ui_cancel` | Esc (встроенное) | `UiRoot`: закрывает верхнее окно |

Клавиши привязаны к физическому положению, поэтому WASD остаются на месте при любой раскладке. Каждый компонент
получает имя действия через экспортируемое свойство, так что вместо этих действий можно использовать свои.

## Группы

| Группа | Значение |
|---|---|
| `player` | Тело игрока. `PointOfInterest` реагирует только на тела из этой группы (`player_group`). Задана у `Player` в `main.tscn` |
| `camera_ignore` | Тела, сквозь которые проходит держатель камеры (`CameraArm.ignored_groups`). Действует на всё, что находится под узлом из этой группы, так что задайте её один раз на корне сцены декорации или на узле-папке уровня. Демо её не использует |
| `points_of_interest` | Каждый `PointOfInterest` добавляет себя в неё сам; через неё `DiscoveryToast` находит места |

## Автозагрузка

`Settings` → `res://gdscript/settings/game_settings.gd`. Она нужна только окну настроек, его элементам и
`gdscript/demo/settings_applier.gd`. Компоненты работают без неё. См. [Настройки](settings.md).

## Другие настройки проекта

| Настройка | Значение | Примечания |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | Демо |
| `physics/3d/physics_engine` | Jolt Physics | Встроен в движок; держатель камеры и тесты проверены с ним |
| `navigation/3d/default_cell_height` | 0,025 | Не должна превышать высоту ячейки навигационной сетки, а та равна 0,025 м, чтобы сетка не соединяла уступы, на которые тело не может подняться; см. [Мир и навигация](systems/world-and-navigation.md) |
| `display/window/stretch/mode` | `canvas_items` | Настройка масштаба интерфейса масштабирует весь 2D через `content_scale_factor` и не трогает 3D-вид |
| `display/window/stretch/aspect` | `expand` | Любая форма окна |
| `gui/theme/custom` | `res://shared/ui/ui_theme.tres` | Внешний вид всех окон и элементов HUD |
| `internationalization/locale/translations` | `res://l10n/ui/*.po` | Переводы интерфейса; см. [Интерфейс](systems/ui.md) |
| `rendering/rendering_device/driver.windows` | `d3d12` | Direct3D 12 в Windows |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 5 (Ultra) | Мягкие тени; у солнца в `world.tscn` к тому же `shadow_blur = 1.25` и дальность теней 70 м |
| `rendering/anti_aliasing/quality/msaa_3d` | 2 (4×) | Мультисэмпловое сглаживание |

Физика работает со стандартной частотой 60 тиков в секунду. Интерполяция физики в `project.godot` включена
(`physics/common/physics_interpolation`) и переключается во время игры настройкой (Настройки → Изображение).

## Сохранённые данные

Настройки сохраняются в `user://settings.cfg`, в папке пользовательских данных проекта (в редакторе: Проект → Открыть
папку данных пользователя, Project → Open User Data Folder). Удалите файл, чтобы вернуться к значениям по умолчанию,
или нажмите **Сбросить всё** в окне настроек.

---

*Страница соответствует Iso & Orbit 1.1.0.*
