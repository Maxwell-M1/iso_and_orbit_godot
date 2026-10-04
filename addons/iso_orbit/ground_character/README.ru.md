<!-- translation of addons/iso_orbit/ground_character/README.md @ 9b116d7ff0dd -->
# Наземный персонаж

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · **Русский** · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Это перевод [английского оригинала](README.md). При расхождениях верен оригинал.

Готовое тело персонажа для перемещения по щелчку: гравитация, прыжок со временем койота (coyote time) и буфером ввода
(одной и той же высоты при любой частоте физических тиков), ускорение с запасом сил, подъём и спуск по ступеням, защита
от обрывов, которая останавливает тело у края. Тело сообщает, что оно делает, для анимаций, эффектов и интерфейса:
состояние и его смены, шаги с указанием ноги, отрывы от земли и приземления, скорость как значение смешивания, движение
в осях модели, поворот и цикл походки. Также в комплекте: звуки на эти сигналы, панель, которая показывает состояние
текстом, предмет в руке, качающийся в такт шагам, и сменные модели.

Часть Iso & Orbit — шаблона камеры и контроллера персонажа для Godot 4.7. Лицензия MIT (см. `LICENSE`).

## Состав

| Файл | Класс | Назначение |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Гравитация, прыжок, ускорение, ступени, `move_and_slide()`, поворот модели; состояние, сигналы и запросы для анимаций |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Останавливает тело у обрыва или ведёт его вдоль края |
| `stamina.gd` | `Stamina` (Node) | Запас сил для ускорения |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Клавиши ускорения и прыжка → персонаж |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Проигрывает звуки по сигналам персонажа |
| `hand_sway.gd` | `HandSway` (Node) | Покачивает узел руки в такт шагам |
| `character_monitor.gd` | `CharacterMonitor` (Label) | Показывает текстом состояние персонажа и последние события; может записывать события в журнал |
| `character_appearance.gd` | `CharacterAppearance` (Node) | Меняет модель во время игры |
| `stamina_bar.gd`, `stamina_bar.tscn` | `StaminaBar` (ProgressBar) | Полоса в HUD для `Stamina` |

Нужен `addons/iso_orbit/click_to_move`: телом управляет `NavigationMover`.

## Настройка

1. Скопируйте эту папку и `click_to_move` в `res://addons/iso_orbit/`.
2. Соберите персонажа:

   ```
   Player           CharacterBody3D с ground_character.gd
   ├── CollisionShape3D
   ├── Visual       Node3D; модель внутри смотрит в −Z
   ├── NavigationMover   из click_to_move
   ├── LedgeGuard   необязательно
   └── Stamina      необязательно
   ```

   Задайте у тела `mover`, `visual`, `ledge_guard` и `stamina`. Демо ещё включает у тела `floor_constant_speed`, чтобы
   персонаж не терял скорость на пандусах, и помещает его на физический слой 2, отдельно от уровня. Тело поднимается на
   ступени до `max_step_height` (0,3 м) и на склоны до своего `floor_max_angle`; чтобы пути вели вверх по ступеням,
   запекайте навигационную сетку с `agent_max_climb`, равным `max_step_height`.
3. Для клавиш добавьте `Node` с `character_action_input.gd` и задайте его `character`. Ему нужны действия ввода
   `sprint` и `jump`.
4. По желанию: `CharacterSounds` с дочерними `AudioStreamPlayer3D`, `HandSway` с узлом руки модели,
   `CharacterAppearance` со списком сцен моделей, `CharacterMonitor` в `CanvasLayer` для отладочной панели. По умолчанию
   `LedgeGuard.floor_mask` — физический слой 1.

Тем же телом может управлять ИИ: вызывайте `NavigationMover.move_to()` и `GroundCharacter.jump()`, выставляйте
`sprint_requested`.

## Документация

В репозитории шаблона: `docs/ru/integration.md`, `docs/ru/systems/locomotion.md`, `docs/ru/systems/audio.md`
и `docs/ru/systems/characters.md`.

---

*Страница соответствует Iso & Orbit 1.1.0.*
