<!-- translation of addons/iso_orbit/occluded_silhouette/README.md @ ed5707ab8355 -->
# Силуэт за препятствиями

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · **Русский** · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> Это перевод [английского оригинала](README.md). При расхождениях верен оригинал.

Показывает персонажа сквозь то, что его закрывает: тело — одной плоской фигурой, предметы в руках — контуром поверх
неё, а вокруг всего — кайму. Там, где персонаж виден, ничего не рисуется. Собственные материалы модели остаются
нетронутыми, поэтому у той же модели в другом месте силуэта нет.

Часть Iso & Orbit — шаблона камеры и контроллера персонажа для Godot 4.7. Лицензия MIT (см. `LICENSE`).

## Состав

| Файл | Назначение |
|---|---|
| `occluded_silhouette.gd` | `OccludedSilhouette` (Node): накладывает проходы на каждый меш модели как `material_overlay`, в том числе на меши, добавленные позже |
| `silhouette_mask.gdshader`, `.tres` | Отмечает, где персонаж виден сам |
| `silhouette_body.gdshader`, `.tres` | Плоская заливка тела |
| `silhouette_gear.gdshader`, `.tres` | Более светлая заливка предметов в руках |
| `silhouette_outline.gdshader`, `.tres` | Кайма вокруг всей фигуры |
| `silhouette_common.gdshaderinc` | Общий код: глубина в метрах, раскладка трафарета |

Другие аддоны не нужны.

## Настройка

1. Скопируйте эту папку в `res://addons/iso_orbit/occluded_silhouette/`; материалы ссылаются на шейдеры по этому
   пути.
2. Добавьте персонажу `Node` с `occluded_silhouette.gd`. В `target` укажите узел, в котором лежит модель, и
   назначьте `silhouette_mask.tres`, `silhouette_body.tres`, `silhouette_gear.tres` и `silhouette_outline.tres` в
   `mask`, `body_fill`, `gear_fill` и `outline`.
3. Меши под узлами, перечисленными в `gear_nodes` (`RightHand`, `LeftHand`), считаются предметами в руках.

Цвета — параметры `color` у материалов, ширина каймы — `width` в `silhouette_outline.tres`, а `outline_enabled`
отключает кайму. Силуэт появляется, только если препятствие стоит хотя бы в 30 см перед персонажем (`min_gap`).

Использует буфер трафарета, который в Godot 4.5+ экспериментальный. Проверено с рендерером Forward+.

## Документация

В репозитории шаблона: `docs/ru/systems/characters.md`.

---

*Страница соответствует Iso & Orbit 1.1.0.*
