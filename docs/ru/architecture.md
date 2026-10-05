<!-- translation of docs/en/architecture.md @ adf142a1b736 -->
# Архитектура

[← Оглавление документации](index.md)

> Это перевод [английского оригинала](../en/architecture.md). При расхождениях верен оригинал.

Демо начинается в одной сцене, `gdscript/main.tscn`: оболочке игры с текущим уровнем, героем и интерфейсом.
Каждое поведение — отдельный узел с одной задачей: компонент читает
собственные экспортируемые свойства, предоставляет методы и сигналы и связан с соседями в сцене через ссылки на узлы и
подключения сигналов. Немногие оставшиеся поиски настраиваются: `DiscoveryToast` и оболочка демо находят места
по группе,
`LevelHost` находит порталы и точки появления своего уровня по группам, `PointOfInterest` и `LevelPortal`
определяют тело игрока по группе `player` (`player_group`, `traveller_group`),
`CharacterAppearance` находит модель и её руку по экспортируемым именам, а `CharacterSounds` с пустым свойством
`character` берёт своего родителя.

## Главная сцена

```
Main (Node3D, main.gd)   the game shell: connects the levels, the hero and the interface
├── Levels             LevelHost: the current level, changed behind the loading screen
│   └── World          shared/world/world.tscn: the start level, its navigation mesh, places, NPCs and the pad
├── Hero               gdscript/player/playable_hero.tscn: PlayableHero, the hero the player controls
│   ├── Character          gdscript/player/player.tscn: GroundCharacter, group "player"
│   │   ├── CollisionShape3D   capsule, radius 0.35 m, height 1.8 m
│   │   ├── Visual             turned to face the way the character goes
│   │   │   └── Hover          CharacterHover: floats the model, off by default
│   │   │       └── Model      the current hero look; its RightHand holds the staff
│   │   ├── Silhouette         OccludedSilhouette: the hero seen through obstacles
│   │   ├── Appearance         CharacterAppearance: swaps Visual/Hover/Model at runtime
│   │   ├── RightHandSway      HandSway: swings the right hand with the steps
│   │   ├── NavigationMover    paths and velocity
│   │   ├── LedgeGuard         keeps the body from walking off a drop
│   │   ├── Stamina            sprint reserve
│   │   └── Sounds             CharacterSounds and five AudioStreamPlayer3D
│   ├── PlayerInput        PointClickMoveInput: mouse and WASD → Character/NavigationMover
│   ├── PlayerActionInput  CharacterActionInput: Shift and Space → Character
│   ├── CameraRig          OrbitCameraRig: follows Character, orbit and zoom
│   │   └── CameraArm      CameraArm: shortens at obstacles
│   │       └── Camera3D
│   ├── ClickMarker        the ring on the ground at a clicked point
│   └── PathView           NavigationPathView: the debug path line, hidden by default
├── Hud                controls hint and speed, FpsCounter, CharacterState, DiscoveryToast, StaminaBar,
│                      TravelPrompt (the offer to travel on a pad)
├── SettingsApplier    settings → node properties (demo only)
├── UiRoot             windows over the game: the settings window
└── LoadingScreen      LoadingScreen: the screen while a level loads
```

`player.tscn` содержит только персонажа. Узлы ввода находятся в `playable_hero.tscn`, поэтому той же сценой
персонажа может управлять ИИ, катсцена или сетевой узел. Герой — сосед хоста уровней, а не часть уровня:
уровни сменяются вокруг него. Как это происходит: [Уровни](systems/levels.md).

## Поток данных

```
mouse, WASD ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (path or            (acceleration, braking,
                                    ──stop()────────────►  direction)          turning: plain math)
                                                               ▲
                                                               │ compute_velocity(delta)
                                                               │ returns a horizontal velocity
Shift, Space ──► CharacterActionInput ──sprint_requested──► GroundCharacter ──► LedgeGuard.constrain()
                                      ──jump()────────────►  (CharacterBody3D)  ──► move_and_slide()
                                                                   │
     signals: state_changed, stepped, jumped, left_floor, touched_floor, landed, sprint_changed, stair_taken,
              teleported
                                                                   ▼
                    CharacterSounds, HandSway, CharacterHover, CharacterMonitor, animations, anything else

mouse ──► OrbitCameraRig ──► CameraArm ──► Camera3D
          (follows the target's interpolated position, orbit, zoom, optional follow)

LevelPortal ──traveller_entered──► LevelHost ──portal_entered──► main.gd ──► TravelPrompt
     ▲                                  │                                       │ E or a click
     └───────────── travel() ───────────┼─────────── main.gd ◄── confirmed ─────┘
                                        ▼
    change_level(): paused, LoadingScreen, threaded load, swap ──level_loaded──► main.gd ──► PlayableHero.place_at()
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
   4. применяет гравитацию в воздухе: подъём прыжка замедляет `gravity_scale`, спуск подчиняется действующим
      настройкам падения (`get_fall_settings()`);
   5. даёт `LedgeGuard.constrain()` повернуть скорость вдоль края, если персонаж не прыгает, и измеряет
      ускорение заданной телу скорости (`get_local_acceleration()`);
   6. вызывает `move_and_slide()`, перед ним шагая на ступень вверх, а после него — на ступень вниз (`max_step_height`);
   7. испускает `left_floor`, `touched_floor`, `landed`, `stair_taken` и `stepped`, поворачивает `Visual`
      к `mover.get_facing()` и,
      если состояние изменилось, испускает `state_changed`.
3. `HandSway` и `CharacterHover` выполняются после тела (`process_physics_priority = 1`) и двигают руку
   и модель по его новому состоянию.

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
| `orbit_camera` | `OrbitCameraRig` (Node3D) | Следует за целью, вращается с ПКМ, меняет зум колесом; по желанию плавно поворачивается за бегом и выравнивает наклон и высоту |
| | `CameraArm` (Node3D) | Держит камеру на конце и укорачивается у препятствий; вблизи делает цель полупрозрачной |
| `click_to_move` | `LocomotionSettings` (Resource) | Скорость, разгон, торможение и поворот. Один ресурс можно разделить между многими персонажами |
| | `GroundMotion` (RefCounted) | Кинематика без узлов: желаемое направление и оставшееся расстояние → горизонтальная скорость |
| | `NavigationMover` (Node) | `move_to()` по навигационному пути с точной остановкой, `steer()` по направлению, `stop()`; возвращает скорость, никогда не двигает тело |
| | `PointClickMoveInput` (Node) | Мышь и ПКМ + WASD → команды контроллеру перемещения; прячет курсор и удерживает его на цели |
| | `ClickMarker` (Node3D) | Метка в точке щелчка (`click_marker.tscn`) |
| | `NavigationPathView` (MeshInstance3D) | Рисует оставшийся путь контроллера перемещения |
| `ground_character` | `GroundCharacter` (CharacterBody3D) | Гравитация, прыжок, ускорение с запасом сил, ступени, `move_and_slide()`, поворот модели; сообщает о своём состоянии, шагах, отрывах от земли и приземлениях для анимаций, звуков и интерфейса |
| | `FallSettings` (Resource) | Падение персонажа: гравитация, предел скорости и торможение до него. Один ресурс может использоваться несколькими персонажами |
| | `LedgeGuard` (Node) | Останавливает тело у обрыва или ведёт его вдоль края |
| | `Stamina` (Node) | Запас, который тратится и восстанавливается; ничего не знает о том, кто его тратит |
| | `CharacterActionInput` (Node) | Клавиши ускорения и прыжка → персонаж |
| | `CharacterSounds` (Node3D) | Проигрывает звуки по сигналам персонажа |
| | `HandSway` (Node) | Покачивает узел руки в такт шагам, с инерцией при старте, остановке, поворотах и приземлении |
| | `CharacterHover` (Node3D) | Поднимает модель: сглаживает ступени, качает и наклоняет её; отключает шаги и может замедлять падение при парении |
| | `DampedSpring` (RefCounted) | Затухающая пружина для одного значения, создающая инерцию в `HandSway` и `CharacterHover` |
| | `CharacterMonitor` (Label) | Показывает текстом состояние персонажа и последние события; может выводить события в панель вывода |
| | `CharacterAppearance` (Node) | Меняет модель персонажа во время игры |
| | `StaminaBar` (ProgressBar) | Полоса сил в HUD (`stamina_bar.tscn`) |
| `occluded_silhouette` | `OccludedSilhouette` (Node) | Рисует персонажа силуэтом там, где его что-то закрывает; его шейдеры и материалы лежат в той же папке |
| `points_of_interest` | `PointOfInterest` (Area3D) | Место для открытия: испускает `discovered(title)`, когда игрок впервые входит в него |
| | `DiscoveryToast` (Label) | «Открыто место: …» на экране на несколько секунд (`discovery_toast.tscn`) |
| `ui_screens` | `UiRoot` (CanvasLayer) | Стек окон: открытие, закрытие верхнего по Esc, пауза, курсор, фокус клавиатуры |
| | `UiScreen` (Control) | Основа окна: `initial_focus`, `close_requested` |
| | `FpsCounter` (Label) | Кадры в секунду, в том числе на паузе (`fps_counter.tscn`) |
| | `InputNames` (RefCounted) | Имена клавиш, назначенных действиям, для текстов: `{sprint}` → «Shift» |
| | `ActionTexts` (Node) | Подставляет эти имена в тексты дочерних элементов, в том числе после смены языка |
| `levels` | `LevelHost` (Node3D) | Хранит текущий уровень и сменяет его за экраном загрузки: фоновая загрузка, замена, карта навигации, прогрев; о каждом шаге сообщает сигналом |
| | `LevelPortal` (Area3D) | Путь на другой уровень: сообщает о путешественнике, переносит по `travel()` или автоматически |
| | `SpawnPoint` (Marker3D) | Именованное место появления персонажа на уровне |
| | `LoadingScreen` (CanvasLayer) | Размытый последний кадр, название места, шкала прогресса и подсказки (`loading_screen.tscn`) |

`ground_character` нужен `click_to_move` (тело управляет `NavigationMover`); остальным аддонам не нужно ничего,
кроме движка. Что каждый из них ждёт от проекта: [Использование в своём проекте](integration.md).

Демо в `gdscript/` собирает их вместе:

| Файл | Назначение |
|---|---|
| `main.tscn`, `main.gd` | Оболочка игры: хост с начальным уровнем, герой, интерфейс и экран загрузки; `main.gd` соединяет их |
| `player/player.tscn`, `player_locomotion.tres` | Персонаж героя: `GroundCharacter` со всеми частями и его настройки бега |
| `player/playable_hero.tscn`, `.gd` | `PlayableHero`: персонаж с вводом, камерой, маркером щелчка и линией пути, готовый для игровой сцены |
| `ui/travel_prompt.tscn`, `.gd` | `TravelPrompt`: приглашение к переходу на площадке с клавишей и названием места |
| `demo/hud.gd` | Подсказка по управлению и показ скорости |
| `demo/settings_applier.gd` | Применяет настройки к узлам демо, единое место для «настройка → свойство» |
| `settings/game_settings.gd` | `GameSettings`, автозагрузка `Settings`: значения по умолчанию, `user://settings.cfg`, сигнал `changed`; настройки движка применяет сама |
| `ui/ui_root.tscn` | `UiRoot` с окном настроек и F10 |
| `ui/settings/settings_screen.tscn`, `.gd` | Окно настроек |
| `ui/settings/setting_*.gd` | `SettingCheckButton`, `SettingOptionButton`, `SettingSlider`, `SettingLanguageButton`: элементы, привязанные к ключу настройки |

У каждой системы своя страница: [Передвижение](systems/locomotion.md), [Камера](systems/camera.md),
[Ввод](systems/input.md), [Персонажи](systems/characters.md), [Звук](systems/audio.md), [Интерфейс](systems/ui.md),
[Мир и навигация](systems/world-and-navigation.md), [Уровни](systems/levels.md).

## Соединения в сцене

Ссылки на узлы — экспортируемые свойства в `main.tscn`, `playable_hero.tscn` и `player.tscn`.
Подключения сигналов в `playable_hero.tscn`:

| Сигнал | Подключён к | Эффект |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | Метка появляется в точке щелчка |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | Удержание заменяет щелчок, метка гаснет |
| `Character/NavigationMover.arrived` | `ClickMarker.fade_out` | Персонаж дошёл до точки |
| `Character/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | От точки отказались |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | Камера не поворачивается сама, пока не ясно, щелчок это или удержание |
| `PlayerInput.run_requested` | `CameraRig.end_follow_wait` | Новый бег: камера перестаёт ждать после ручного поворота и снова следует |

`main.gd` соединяет хост уровней и приглашение к переходу в коде; см. [Уровни](systems/levels.md#оболочка-игры).

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
  управляет `PlayerInput` в сцене игрового героя (`playable_hero.tscn`). Для NPC создайте экземпляр `player.tscn`
  без узлов `Silhouette` и
  `Appearance`, нужных только игроку, и вызывайте `NavigationMover.move_to()` из своего ИИ.
- **Герой — сосед хоста уровней, а не часть уровня.** Уровень содержит только мир: землю, декорации, навигацию,
  свет и порталы. Герой, камера и интерфейс остаются при смене уровня. Новому уровню не нужны их копии,
  а выносливость и высота камеры сохраняются.
- **Хост уровней ничего не знает о герое.** Он сигналами сообщает шаги смены, а оболочка ставит героя туда,
  куда указывает новый уровень. Игровой герой работает и без хоста уровней.
- **Камера — соседний узел персонажа, а не его потомок.** Она перемещается в `_process` в интерполированную позицию цели
  и сама не интерполируется, поэтому с интерполяцией физики (по умолчанию включена, Настройки → Изображение) бег
  выглядит плавным при любой частоте кадров. Для режима следования камера вычисляет скорость цели по её перемещению за
  физический тик, так что целью может быть любой `Node3D`. По этому же движению камера отличает резкий
  разворот от плавной дуги и не вращается за промежуточным направлением. Её пружины вычисляются короткими
  шагами и работают одинаково при любой частоте кадров.
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
| `shared/` | Содержимое демо, не зависящее от языка скриптов: уровни, персонажи и снаряжение, шейдеры и текстуры мира, звуки, тема интерфейса |
| `l10n/` | Переводы интерфейса |
| `tests/` | Тесты в режиме headless, см. [Тесты](testing.md) |
| `docs/` | Эта документация |

`shared/` рассчитана на будущую версию демо на C#, которая получит свою папку рядом с `gdscript/`. Пока остаются два
исключения: уровни и площадка используют скрипты компонентов (`world.tscn`, `island.tscn` и `mountain.tscn`
используют `point_of_interest.gd`, уровни — `spawn_point.gd`, а `teleport_pad.tscn` — `level_portal.gd`),
два небольших скрипта декораций (`flicker.gd`, `hover_spin.gd`) лежат в `shared/world/props/`. См.
[Известные проблемы](known-issues.md).

---

*Страница соответствует Iso & Orbit 1.2.0.*
