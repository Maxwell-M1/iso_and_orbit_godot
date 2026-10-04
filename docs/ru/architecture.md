<!-- translation of docs/en/architecture.md @ 8409307c5782 -->
# Архитектура

> Это перевод [английского оригинала](../en/architecture.md). При расхождениях верен оригинал.

Демо — это одна сцена, `gdscript/main.tscn`. Каждое поведение — отдельный узел с одной задачей: компонент читает
собственные экспортируемые свойства, предоставляет методы и сигналы и связан с соседями в сцене через ссылки на узлы и
подключения сигналов. Немногие оставшиеся поиски настраиваются: `DiscoveryToast` находит места по группе,
`CharacterAppearance` находит модель и её руку по экспортируемым именам, а `CharacterSounds` с пустым свойством
`character` берёт своего родителя.

## Главная сцена

```
Main (Node3D)
├── World              shared/world/world.tscn: уровень, его навигационная сетка, места и NPC
├── Player             gdscript/player/player.tscn: GroundCharacter, группа "player"
│   ├── CollisionShape3D   капсула, радиус 0,35 м, высота 1,8 м
│   ├── Visual             повёрнут лицом туда, куда идёт персонаж
│   │   └── Model          текущий облик героя; его RightHand держит посох
│   ├── Silhouette         OccludedSilhouette: герой, видимый сквозь препятствия
│   ├── Appearance         CharacterAppearance: меняет Visual/Model во время игры
│   ├── RightHandSway      HandSway: покачивает правую руку в такт шагам
│   ├── NavigationMover    пути и скорость
│   ├── LedgeGuard         не даёт телу сойти с обрыва
│   ├── Stamina            запас сил для ускорения
│   └── Sounds             CharacterSounds и пять AudioStreamPlayer3D
├── PlayerInput        PointClickMoveInput: мышь и WASD → Player/NavigationMover
├── PlayerActionInput  CharacterActionInput: Shift и Space → Player
├── CameraRig          OrbitCameraRig: следует за Player, вращение и зум
│   └── CameraArm      CameraArm: укорачивается у препятствий
│       └── Camera3D
├── ClickMarker        кольцо на земле в точке щелчка
├── PathView           NavigationPathView: отладочная линия пути, по умолчанию скрыта
├── Hud                подсказка по управлению и скорость, FpsCounter, DiscoveryToast, StaminaBar
├── SettingsApplier    настройки → свойства узлов (только в демо)
└── UiRoot             окна поверх игры: окно настроек
```

`player.tscn` содержит только персонажа. Узлы ввода находятся в `main.tscn`, поэтому той же сценой персонажа может
управлять что-то другое: ИИ, катсцена или сетевой узел.

## Поток данных

```
мышь, WASD ───► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (путь или           (разгон, торможение,
                                    ──stop()────────────►  направление)        поворот: чистая математика)
                                                               ▲
                                                               │ compute_velocity(delta)
                                                               │ возвращает горизонтальную скорость
Shift, Space ──► CharacterActionInput ──sprint_requested──► GroundCharacter ──► LedgeGuard.constrain()
                                      ──jump()────────────►  (CharacterBody3D)  ──► move_and_slide()
                                                                   │
                                     сигналы: stepped, jumped, landed, sprint_changed
                                                                   ▼
                                                   CharacterSounds, HandSway и всё остальное

мышь ───► OrbitCameraRig ──► CameraArm ──► Camera3D
          (идёт за интерполированной позицией цели; вращение, зум, следование по выбору)
```

Ввод никогда не трогает тело. Он отправляет команды `NavigationMover`. Контроллер перемещения тоже никогда не трогает
тело: он возвращает скорость, когда тело её запрашивает. Камера и ввод друг о друге не знают.

## Один физический тик

1. `CharacterActionInput` выполняется раньше персонажа (`process_physics_priority = -1`): он выставляет
   `GroundCharacter.sprint_requested` и вызывает `jump()`, так что нажатие клавиши доходит до тела в том же тике.
2. `GroundCharacter._physics_process` — единственное место, где тело движется:
   1. решает, ускоряется ли персонаж (запрошено, разрешено, движется, не выдохся), и тратит силы;
   2. вызывает `mover.compute_velocity(delta)` и берёт X и Z результата как горизонтальную скорость;
   3. начинает прыжок, если он в буфере, а тело стоит на полу или только что сошло с него (время койота, coyote time);
   4. в воздухе добавляет гравитацию, умноженную на `gravity_scale`;
   5. даёт `LedgeGuard.constrain()` повернуть скорость вдоль края, если персонаж не прыгает;
   6. вызывает `move_and_slide()`;
   7. испускает `landed` и `stepped` и поворачивает `Visual` к `mover.get_facing()`.
3. `HandSway` выполняется после тела (`process_physics_priority = 1`) и двигает руку по новому состоянию тела.

`PointClickMoveInput._physics_process` в одном месте решает, кто ведёт персонажа: зажатая кнопка мыши, а если её нет —
клавиши с правой кнопкой. Он вызывает `move_to()`, `steer()` или `stop()`. Контроллер перемещения хранит последнюю
команду, и тело подхватывает её при следующем вызове `compute_velocity()`.

Каждый отрисованный кадр `OrbitCameraRig._process` ставит риг камеры в интерполированную трансформацию цели, а его
дочерний `CameraArm` обновляется сразу после него. У `PointClickMoveInput` `process_priority = 1`, поэтому он поправляет
позицию курсора, когда камера в этом кадре уже встала на место.

## Компоненты

Переиспользуемые компоненты лежат в `addons/iso_orbit/`, по папке на каждую часть, которую можно взять отдельно.
Каждый скрипт назван по своему классу в snake_case: `OrbitCameraRig` — это
`addons/iso_orbit/orbit_camera/orbit_camera_rig.gd`.

| Аддон | Класс | Назначение |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig` (Node3D) | Следует за целью, вращается с ПКМ, приближается и отдаляется колесом, по выбору разворачивается за бегом |
| | `CameraArm` (Node3D) | Держит камеру на конце и укорачивается у препятствий; вблизи делает цель полупрозрачной |
| `click_to_move` | `LocomotionSettings` (Resource) | Скорость, разгон, торможение и поворот. Один ресурс можно разделить между многими персонажами |
| | `GroundMotion` (RefCounted) | Кинематика без узлов: желаемое направление и оставшееся расстояние → горизонтальная скорость |
| | `NavigationMover` (Node) | `move_to()` по навигационному пути с точной остановкой, `steer()` по направлению, `stop()`; возвращает скорость, никогда не двигает тело |
| | `PointClickMoveInput` (Node) | Мышь и ПКМ + WASD → команды контроллеру перемещения; прячет курсор и удерживает его на цели |
| | `ClickMarker` (Node3D) | Метка в точке щелчка (`click_marker.tscn`) |
| | `NavigationPathView` (MeshInstance3D) | Рисует оставшийся путь контроллера перемещения |
| `ground_character` | `GroundCharacter` (CharacterBody3D) | Гравитация, прыжок, ускорение с запасом сил, `move_and_slide()`, поворот модели; сигналы шагов, прыжков, приземлений и ускорения |
| | `LedgeGuard` (Node) | Останавливает тело у обрыва или ведёт его вдоль края |
| | `Stamina` (Node) | Запас, который тратится и восстанавливается; ничего не знает о том, кто его тратит |
| | `CharacterActionInput` (Node) | Клавиши ускорения и прыжка → персонаж |
| | `CharacterSounds` (Node3D) | Проигрывает звуки по сигналам персонажа |
| | `HandSway` (Node) | Покачивает узел руки в такт шагам, с инерцией при старте, остановке, поворотах и приземлении |
| | `CharacterAppearance` (Node) | Меняет модель персонажа во время игры |
| | `StaminaBar` (ProgressBar) | Полоса сил в HUD (`stamina_bar.tscn`) |
| `occluded_silhouette` | `OccludedSilhouette` (Node) | Рисует персонажа силуэтом там, где его что-то закрывает; его шейдеры и материалы лежат в той же папке |
| `points_of_interest` | `PointOfInterest` (Area3D) | Место для открытия: испускает `discovered(title)`, когда игрок впервые входит в него |
| | `DiscoveryToast` (Label) | «Открыто место: …» на экране на несколько секунд (`discovery_toast.tscn`) |
| `ui_screens` | `UiRoot` (CanvasLayer) | Стек окон: открытие, закрытие верхнего по Esc, пауза, курсор, фокус клавиатуры |
| | `UiScreen` (Control) | Основа окна: `initial_focus`, `close_requested` |
| | `FpsCounter` (Label) | Кадры в секунду, в том числе на паузе (`fps_counter.tscn`) |

`ground_character` нужен `click_to_move` (тело управляет `NavigationMover`); остальным аддонам не нужно ничего,
кроме движка. Что каждый из них ждёт от проекта: [Использование в своём проекте](integration.md).

Демо в `gdscript/` собирает их вместе:

| Файл | Назначение |
|---|---|
| `main.tscn` | Сцена демо |
| `player/player.tscn`, `player_locomotion.tres` | Герой: `GroundCharacter` со всеми частями, и его настройки бега |
| `demo/hud.gd` | Подсказка по управлению и показ скорости |
| `demo/settings_applier.gd` | Применяет настройки к узлам демо, единое место для «настройка → свойство» |
| `settings/game_settings.gd` | `GameSettings`, автозагрузка `Settings`: значения по умолчанию, `user://settings.cfg`, сигнал `changed`; настройки движка применяет сама |
| `ui/ui_root.tscn` | `UiRoot` с окном настроек и F10 |
| `ui/settings/settings_screen.tscn`, `.gd` | Окно настроек |
| `ui/settings/setting_*.gd` | `SettingCheckButton`, `SettingOptionButton`, `SettingSlider`, `SettingLanguageButton`: элементы, привязанные к ключу настройки |

У каждой системы своя страница: [Передвижение](systems/locomotion.md), [Камера](systems/camera.md),
[Ввод](systems/input.md), [Персонажи](systems/characters.md), [Звук](systems/audio.md), [Интерфейс](systems/ui.md),
[Мир и навигация](systems/world-and-navigation.md).

## Связи, заданные в сцене

Ссылки на узлы — это экспортируемые свойства, заданные в `main.tscn` и `player.tscn`. Подключения сигналов в
`main.tscn`:

| Сигнал | Подключён к | Эффект |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | Метка появляется в точке щелчка |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | Удержание заменяет щелчок, метка гаснет |
| `Player/NavigationMover.arrived` | `ClickMarker.fade_out` | Персонаж дошёл до точки |
| `Player/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | От точки отказались |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | Камера не поворачивается сама, пока не ясно, щелчок это или удержание |

## Настройки

Автозагрузка `Settings` (`GameSettings`) хранит значения и испускает `changed(key, value)`. Настройки уровня движка она
применяет сама: полноэкранный режим, ограничение частоты кадров, V-Sync, интерполяцию физики, масштаб интерфейса, язык и
громкость. Всё остальное применяет `gdscript/demo/settings_applier.gd`, который сопоставляет каждый ключ свойству узла.
Сами компоненты никогда не читают настройки, см. [Настройки](settings.md).

## Почему так устроено

- **Тело двигает только `GroundCharacter`.** Компоненты движения возвращают скорость и никогда не вызывают
  `move_and_slide()`. Гравитация, прыжки и любое будущее отбрасывание складываются в одном месте и не могут мешать
  друг другу.
- **`GroundMotion` — математика без узлов.** Разгон и торможение — чистая функция состояния: её легко тестировать
  отдельно и переносить на другой язык строка за строкой.
- **Персонаж ничего не знает о мыши.** Персонажем игрока он становится потому, что его контроллером перемещения
  управляет `PlayerInput` в главной сцене. Для NPC создайте экземпляр `player.tscn` без узлов `Silhouette` и
  `Appearance`, нужных только игроку, и вызывайте `NavigationMover.move_to()` из своего ИИ.
- **Камера — соседний узел персонажа, а не его потомок.** Она перемещается в `_process` в интерполированную позицию цели
  и сама не интерполируется, поэтому с интерполяцией физики (по умолчанию включена, Настройки → Изображение) бег
  выглядит плавным при любой частоте кадров. Для режима следования камера вычисляет скорость цели по её перемещению за
  физический тик, так что целью может быть любой `Node3D`.
- **Компоненты ничего не знают о настройках.** `LedgeGuard`, `PointClickMoveInput`, `OrbitCameraRig` и остальные
  читают собственные свойства; с автозагрузкой `Settings` работают только `settings_applier.gd` и окно настроек.
  Компонент переносится в другой проект без системы настроек.
- **Окна следуют соглашениям Godot.** Вёрстка — только контейнерами; внешний вид задают тема проекта и её вариации
  типов, а не переопределения на каждом узле. Окно просит закрыть его сигналом, и `UiRoot` его закрывает (вызовы идут
  вниз по дереву, сигналы — вверх). Клавиши — это действия ввода. Фокус клавиатуры ставится при открытии окна и
  восстанавливается при закрытии. Пока окно открыто, игра стоит на паузе (`UiRoot` работает в
  `PROCESS_MODE_ALWAYS`), а камера отпускает захваченный курсор.

## Папки

| Папка | Содержимое |
|---|---|
| `addons/iso_orbit/` | Переиспользуемые компоненты, по папке на каждую часть |
| `gdscript/` | Демо на GDScript: главная сцена, герой, система и окно настроек, подсказка в HUD |
| `shared/` | Содержимое демо, не зависящее от языка скриптов: уровень, персонажи и снаряжение, шейдеры и текстуры мира, звуки, тема интерфейса |
| `l10n/` | Переводы интерфейса |
| `tests/` | Тесты в режиме headless, см. [Тесты](testing.md) |
| `docs/` | Эта документация |

`shared/` рассчитана на будущую версию демо на C#, которая получит свою папку рядом с `gdscript/`. Пока остаются два
исключения: `world.tscn` и `mountain.tscn` используют `addons/iso_orbit/points_of_interest/point_of_interest.gd`, а
два небольших скрипта декораций (`flicker.gd`, `hover_spin.gd`) лежат в `shared/world/props/`. См.
[Известные проблемы](known-issues.md).

---

*Страница соответствует Iso & Orbit 1.0.0.*
