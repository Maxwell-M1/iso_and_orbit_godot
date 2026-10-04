<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 6dce2786aac6 -->
# Интересные места

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · **Русский** · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Это перевод [английского оригинала](README.md). При расхождениях верен оригинал.

Места, которые можно открыть: область, которая сообщает, когда игрок впервые в неё входит, и сообщение на экране
«Открыто место: …», которое само находит каждое место.

Часть Iso & Orbit — шаблона камеры и контроллера персонажа для Godot 4.7. Лицензия MIT (см. `LICENSE`).

## Состав

| Файл | Класс | Назначение |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest` (Area3D) | Испускает `discovered(title)`, когда в область впервые входит тело из группы `player`; добавляет себя в группу `points_of_interest` |
| `discovery_toast.gd`, `discovery_toast.tscn` | `DiscoveryToast` (Label) | Показывает «Открыто место: …» на несколько секунд, когда открыто любое место |

Другие аддоны не нужны.

## Настройка

1. Скопируйте эту папку в `res://addons/iso_orbit/points_of_interest/`.
2. Поместите тело игрока в группу `player` (или задайте `player_group`).
3. Для каждого места добавьте `Area3D` с `point_of_interest.gd` и формой столкновения, задайте его `title` и включите
   в его `collision_mask` физический слой игрока.
4. Добавьте `discovery_toast.tscn` в свой HUD. При запуске он подключается к каждому месту в сцене; связывать ничего
   не нужно.

Текст сообщения и названия проходят через сервер переводов, поэтому их можно локализовать. Внешний вид задаёт
вариация типа темы `DiscoveryToast`.

## Документация

В репозитории шаблона: `docs/ru/systems/world-and-navigation.md` и `docs/ru/systems/ui.md`.

---

*Страница соответствует Iso & Orbit 1.1.0.*
