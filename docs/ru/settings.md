<!-- translation of docs/en/settings.md @ 262d20fd6cef -->
# Настройки

[← Оглавление документации](index.md)

> Это перевод [английского оригинала](../en/settings.md). При расхождениях верен оригинал.

F10 открывает окно настроек и ставит игру на паузу; Esc или F10 закрывает его. Изменения применяются сразу
(только масштаб интерфейса при перетаскивании мышью ждёт отпускания) и
сохраняются в `user://settings.cfg`, когда окно закрывается и когда игра завершается. **Сбросить всё** возвращает
каждой настройке значение по умолчанию.

Значения по умолчанию заданы в `DEFAULTS` в `gdscript/settings/game_settings.gd`. Демо применяет их к свойствам
узлов в `gdscript/demo/settings_applier.gd`; собственные значения свойств по умолчанию у компонентов могут
отличаться, это отмечено ниже. Как устроена система настроек и как добавить настройку:
[Интерфейс](systems/ui.md#настройки).

Для отдельного скопированного героя используйте [Конфигурации](configurations.md), чтобы найти свойства в
Инспекторе и выбрать согласованный вариант. Здесь описано **меню демо**. Названия ниже используют исходные
клавиши; во время игры меню подставляет текущие назначения из `InputMap`.

## Управление

| Настройка | Ключ | По умолчанию | Куда применяется |
|---|---|---|---|
| **Зажатая ЛКМ**: Напрямую к курсору / К точке по пути | `gameplay/hold_mode` | Напрямую к курсору | `PointClickMoveInput.hold_mode` |
| **ПКМ + WASD**: Выключено / Боком / С поворотом | `gameplay/camera_keys_mode` | С поворотом | `PointClickMoveInput.keys_with_camera` (в компоненте по умолчанию боком); выключение скрывает подсказку о ПКМ + WASD |
| **ЛКМ + ПКМ + A/D**: Выключено / Боком / Наискосок | `gameplay/camera_steer_keys_mode` | Наискосок | `PointClickMoveInput.keys_with_camera_steer` (в компоненте по умолчанию боком); выключение скрывает соответствующую подсказку |
| **Задом (S) медленнее на** 0…80%, только в режиме «Боком» | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − значение / 100 |
| **Прятать курсор, пока бежишь с зажатой ЛКМ** | `gameplay/hide_cursor_on_hold` | вкл | `PointClickMoveInput.hide_cursor_while_held` |
| **ПКМ на бегу с ЛКМ только поворачивает камеру** | `gameplay/look_around` | вкл | `PointClickMoveInput.look_around_while_held`; выключение также скрывает подсказку об осмотре |

## Персонаж

| Настройка | Ключ | По умолчанию | Куда применяется |
|---|---|---|---|
| **Облик героя**: один из десяти | `character/look` | 8 · Некромант | `CharacterAppearance.set_look()` |
| **Парить над землёй** | `character/hover` | выкл | `CharacterHover.enabled` на `Hero/Character/Visual/Hover` (по умолчанию в компоненте вкл.; `player.tscn` выключает); при парении узел отключает шаги и замедляет падение (`player_floating_fall.tres`) |
| **Не падать с обрывов** | `gameplay/ledge_guard` | вкл | `LedgeGuard.enabled` |
| **Прыжок (пробел)** | `character/jump` | вкл | `GroundCharacter.can_jump`; также скрывает подсказку о прыжке |
| **Высота прыжка** 0,5…1,5 м | `character/jump_height` | 1,0 м | `GroundCharacter.jump_height` |
| **Бег с ускорением (Shift)** | `character/sprint` | вкл | `GroundCharacter.can_sprint`; также скрывает подсказку об ускорении |
| **Shift**: Держать / Нажать: вкл, ещё раз: выкл | `character/sprint_mode` | Держать | `CharacterActionInput.sprint_mode` |
| **Прибавка к скорости** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + значение / 100 |
| **Усталость от ускорения** | `character/fatigue` | вкл | `GroundCharacter.sprint_tires` |
| **Сил хватает на** 3…10 с | `character/sprint_duration` | 5,0 с | `GroundCharacter.sprint_duration` |

Ключ защиты от обрывов — `gameplay/ledge_guard`, хотя переключатель находится на вкладке «Персонаж».

## Камера

| Настройка | Ключ | По умолчанию | Куда применяется |
|---|---|---|---|
| **ПКМ наклоняет камеру вверх-вниз** | `camera/mouse_pitch` | выкл | `OrbitCameraRig.mouse_pitch` |
| **Поворачивать камеру за бегом** | `camera/follow` | выкл | `OrbitCameraRig.follow_movement` |
| **Доворачивать за** 0…10 с («сразу» при 0) | `camera/follow_time` | 1,1 с | `OrbitCameraRig.follow_time` (в компоненте по умолчанию 1,5 с) |
| **Кроме бега на камеру** | `camera/follow_except_toward` | вкл | `OrbitCameraRig.follow_toward_camera_angle`: выключение задаёт 0, и камера поворачивается за любым бегом, даже прямо на неё |
| **Угол** 5…60° | `camera/follow_except_toward_angle` | 30° | `OrbitCameraRig.follow_toward_camera_angle` = значение при включённом исключении (в компоненте тоже 30°) |
| **Выравнивать наклон камеры на бегу** | `camera/align_pitch` | выкл | `OrbitCameraRig.follow_pitch` |
| **Наклон вниз** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −значение (по умолчанию в компоненте: −40°) |
| **Выравнивать наклон за** 0…10 с («сразу» при 0) | `camera/align_pitch_time` | 1,1 с | `OrbitCameraRig.follow_pitch_time` (в компоненте по умолчанию 1,5 с) |
| **Выравнивать высоту камеры на бегу** | `camera/align_height` | выкл | `OrbitCameraRig.follow_zoom` |
| **Высота** 0…100% | `camera/align_height_level` | 55% | `OrbitCameraRig.follow_zoom_level` = значение / 100: 0% — камера опущена до конца, 100% — поднята до конца |
| **Выравнивать высоту за** 0…10 с («сразу» при 0) | `camera/align_height_time` | 1,5 с | `OrbitCameraRig.follow_zoom_time` |
| **Курсор держит цель, пока камера поворачивается** | `camera/keep_aim` | вкл | `PointClickMoveInput.keep_aim_on_camera_turn` |
| **Камера упирается в препятствия за спиной** | `camera/keep_out_of_geometry` | вкл | `CameraArm.keep_out_of_geometry` |
| **Приближаться, если персонажа закрыло** | `camera/pull_in_on_occlusion` | выкл | `CameraArm.pull_in_on_occlusion` |

## Изображение

| Настройка | Ключ | По умолчанию | Куда применяется |
|---|---|---|---|
| **Полноэкранный режим** | `display/fullscreen` | выкл | `DisplayServer.window_set_mode()` |
| **Ограничение FPS**: 24, 30, 60, 120, 240, Без ограничения | `display/max_fps` | Без ограничения | `Engine.max_fps` |
| **Вертикальная синхронизация (V-Sync)** | `display/vsync` | выкл | `DisplayServer.window_set_vsync_mode()` |
| **Интерполяция физики (персонаж и камера)** | `display/physics_interpolation` | вкл | `SceneTree.physics_interpolation` |
| **Обводка силуэта за препятствиями** | `display/silhouette_outline` | вкл | `OccludedSilhouette.outline_enabled` |

Полноэкранный режим не работает, пока игра запущена внутри редактора — во вкладке «Игра» (Game) или в её плавающем окне
(**Make Game Workspace Floating on Next Play**): окном там владеет редактор, поэтому переключатель недоступен. Чтобы
проверить его из редактора, выключите **Embed Game on Next Play** в меню вкладки «Игра»: тогда игра откроется в
собственном окне.

С V-Sync кадров никогда не бывает больше частоты обновления монитора, поэтому ограничение FPS на уровне этой частоты
или выше вообще не выставляется: оно боролось бы с V-Sync и давало бы меньше кадров, чем показывает монитор
(ограничение 240 на мониторе 240 Гц давало около 220).

Без интерполяции физики персонаж и камера двигаются рывками, по тикам (60 в секунду): камера следует за
`get_global_transform_interpolated()` цели, а без интерполяции это просто её позиция на последнем тике. На мониторе чаще
60 Гц это заметно, а когда камера поворачивается за бегом, персонаж ещё и покачивается на поворотах: камера
поворачивается каждый кадр, а персонаж — только каждый тик.

## Интерфейс

| Настройка | Ключ | По умолчанию | Куда применяется |
|---|---|---|---|
| **Язык**: English, Español, 日本語, Português (Brasil), Русский, Türkçe, 简体中文 | `interface/language` | English | `TranslationServer.set_locale()` |
| **Масштаб интерфейса** 50…100% | `interface/ui_scale` | 75% | `content_scale_factor` корневого окна |
| **Счётчик FPS** | `interface/fps_counter` | вкл | Видимость `Hud/FpsCounter` |
| **Подсказка по управлению и скорость** | `interface/help` | вкл | Видимость `Hud/Panel` |
| **Линия пути персонажа** | `interface/path_line` | выкл | Видимость `Hero/PathView` |
| **Состояние персонажа и события** | `interface/character_state` | выкл | Видимость `Hud/CharacterState` (`CharacterMonitor`) |

Масштаб интерфейса меняет подсказку, счётчик FPS, полосу сил, панель состояния, сообщение «Открыто место: …»,
приглашение к переходу, экран загрузки и окна, но не 3D-вид. 100% — размер, заданный в сценах. При перетаскивании
ползунка мышью масштаб применяется после отпускания, чтобы ползунок не уходил из-под курсора; клавиатура и колесо
применяют его сразу.

## Звук

| Настройка | Ключ | По умолчанию | Куда применяется |
|---|---|---|---|
| **Громкость** 0…100% («выкл» при 0) | `sound/volume` | 100% | Громкость шины `Master`; 0 заглушает её |
| **Шаги** | `sound/footsteps` | вкл | `CharacterSounds.footsteps_enabled` |
| **Прыжок и приземление** | `sound/jump` | вкл | `CharacterSounds.jump_enabled` |
| **Рывок и бег с ускорением** | `sound/sprint` | выкл | `CharacterSounds.sprint_enabled` (в компоненте по умолчанию вкл.) |

## Зависимые настройки

Элементы, которые не имеют смысла без другой настройки, затемняются и не меняются: замедление назад без режима
«Боком» для ПКМ + WASD, высота прыжка без прыжка, всё об ускорении без ускорения, длительность запаса сил без
усталости, время поворота без поворота, угол и время наклона без выравнивания наклона, высота и время высоты без
выравнивания высоты, а звук шагов — пока герой парит (шагов тогда нет).

---

*Страница соответствует Iso & Orbit 1.2.0.*
