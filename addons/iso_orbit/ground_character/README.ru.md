<!-- translation of addons/iso_orbit/ground_character/README.md @ 87915285e965 -->
# Наземный персонаж

[← Оглавление документации (репозиторий шаблона)](../../../docs/ru/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · **Русский** · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Это перевод [английского оригинала](README.md). При расхождениях верен оригинал.

Готовое тело персонажа для перемещения по щелчку: гравитация, прыжок с койот-временем и буфером ввода
(одинаковой высоты при любой частоте физических тиков), падение со своими гравитацией и пределом скорости,
ускоренный бег с выносливостью, подъём и спуск по ступеням и необязательная защита от обрывов. Тело сообщает
анимации, эффектам и интерфейсу о своём состоянии и его смене, шагах и ноге, отрыве и приземлении, скорости
как значении смешивания, движении в осях модели, повороте и фазе походки. Также есть звуки по сигналам,
панель состояния, качающийся в такт шагам предмет в руке, парение модели и сменные модели.

Часть Iso & Orbit — шаблона камеры и контроллера персонажа для Godot 4.7. Лицензия MIT (см. `LICENSE`).

## Состав

| Файл | Класс | Назначение |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Гравитация, прыжок, ускоренный бег, ступени, `move_and_slide()`, поворот модели; состояние, сигналы и запросы для анимаций; перенос без рывка через `teleport()` |
| `fall_settings.gd` | `FallSettings` (Resource) | Падение персонажа: гравитация, предел скорости и торможение до него |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Останавливает тело у обрыва или ведёт его вдоль края |
| `stamina.gd` | `Stamina` (Node) | Запас сил для ускорения |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Клавиши ускорения и прыжка → персонаж |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Проигрывает звуки по сигналам персонажа |
| `hand_sway.gd` | `HandSway` (Node) | Покачивает узел руки в такт шагам |
| `character_hover.gd` | `CharacterHover` (Node3D) | Поднимает модель над землёй, плавно проводит её по ступеням, покачивает и наклоняет; может замедлять падение |
| `damped_spring.gd` | `DampedSpring` (RefCounted) | Затухающая пружина для одного значения, создающая инерцию |
| `character_monitor.gd` | `CharacterMonitor` (Label) | Показывает текстом состояние персонажа и последние события; может записывать события в журнал |
| `character_appearance.gd` | `CharacterAppearance` (Node) | Меняет модель во время игры |
| `stamina_bar.gd`, `stamina_bar.tscn` | `StaminaBar` (ProgressBar) | Полоса в HUD для `Stamina` |

Нужен `addons/iso_orbit/click_to_move`: телом управляет `NavigationMover`.

## Настройка

1. Скопируйте эту папку и `click_to_move` в `res://addons/iso_orbit/`.
2. Соберите персонажа:

   ```
   Player           CharacterBody3D with ground_character.gd
   ├── CollisionShape3D
   ├── Visual       Node3D; the model inside faces −Z
   ├── NavigationMover   from click_to_move
   ├── LedgeGuard   optional
   └── Stamina      optional
   ```

   Задайте у тела `mover`, `visual`, `ledge_guard` и `stamina`. Демо ещё включает у тела `floor_constant_speed`, чтобы
   персонаж сохранял скорость на пандусах, и помещает его на физический слой 2 отдельно от уровня, со столкновением
   со слоями 1 и 4 (уровень и его невидимые стены): `get_ground_height()` и, по умолчанию, `LedgeGuard` ищут землю
   с той же маской. Тело берёт ступени до `max_step_height` (0,3 м) и склоны до `floor_max_angle`; для пути по
   лестнице согласуйте `agent_max_climb` навигационной сетки с нужной высотой ступени и проверьте запечённый путь
   на реальном коллайдере. Держите `LedgeGuard.max_drop` не меньше `max_step_height`, а `floor_snap_length`
   короче него, если нужен `stair_taken` на спуске. Тело может стоять в уровне повёрнутым: персонаж поворачивает
   только `Visual` относительно тела и сначала смотрит вдоль −Z тела. Позже его поворачивают
   `teleport(position, facing)` или `NavigationMover.face()`.
3. Для клавиш добавьте `Node` с `character_action_input.gd` и задайте его `character`. Ему нужны действия ввода
   `sprint` и `jump`; об отсутствующем действии сообщается один раз при запуске, затем оно не читается.
4. По желанию: `CharacterSounds` с дочерними `AudioStreamPlayer3D`, `HandSway` с его `character` и узлом руки модели,
   `CharacterAppearance` со `slot` и списком сцен моделей, `CharacterMonitor` в `CanvasLayer` для отладочной
   панели. `LedgeGuard.floor_mask` 0 (по умолчанию) берёт маску коллизий тела и исключает слишком крутые для него
   поверхности.
5. Для парения поместите `Node3D` с `character_hover.gd` между `Visual` и моделью (`Visual/Hover/Model`) и
   сделайте его `slot` компонента `CharacterAppearance`, если он используется. Пока персонаж парит, этот узел
   отключает шаги; назначенный ему `fall` (`FallSettings`) может замедлить спуск. Поднимается модель, а не тело
   и его форма столкновения.
6. По желанию назначьте телу собственный ресурс `FallSettings` в `fall`: он меняет гравитацию при спуске и
   ограничивает скорость.

Ошибки настройки печатаются предупреждениями при запуске. У готового `player.tscn` капсула высотой 1,8 м,
включён `floor_constant_speed`, есть защита от края, выносливость, ресурс парящего падения и узел парения,
который изначально **выключен**. `NavigationMover` использует `player_locomotion.tres`; `SettingsApplier` демо
может применить сохранённые настройки при запуске. Инструкция по копированию героя — в
`docs/ru/integration.md`, подгонка своей модели и коллайдера — в `docs/ru/systems/characters.md`.

Тем же телом может управлять ИИ: вызывайте `NavigationMover.move_to()` и `GroundCharacter.jump()`, выставляйте
`sprint_requested`.

## Документация

В репозитории шаблона: `docs/ru/integration.md`, `docs/ru/systems/locomotion.md`, `docs/ru/systems/input.md`
(`CharacterActionInput`), `docs/ru/systems/audio.md`, `docs/ru/systems/characters.md` и
`docs/ru/systems/levels.md` (перенос героя).

---

*Страница соответствует Iso & Orbit 1.2.0.*
