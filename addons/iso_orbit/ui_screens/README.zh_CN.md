<!-- translation of addons/iso_orbit/ui_screens/README.md @ b7618a65d4df -->
# UI 窗口

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

以栈的形式管理游戏上层的窗口：可以在一个窗口上再打开另一个，按 Esc 关闭最上层窗口，有窗口打开时暂停游戏并显示鼠标光标，将键盘焦点交给窗口并在窗口关闭时归还。另外还有一个在游戏暂停时也能工作的 FPS 计数器。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `ui_root.gd` | `UiRoot`（CanvasLayer） | 窗口栈：`open()`、`close_top()`、`toggle()`；暂停、光标、焦点 |
| `ui_screen.gd` | `UiScreen`（Control） | 窗口的基类：`initial_focus`、`close_requested` 信号 |
| `fps_counter.gd`、`fps_counter.tscn` | `FpsCounter`（Label） | 每秒帧数，暂停时也工作 |

不需要其他插件。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/ui_screens/`。
2. 在主场景中添加一个挂载 `ui_root.gd` 的 `CanvasLayer`。它在游戏暂停时也会运行。
3. 将每个窗口做成根节点继承 `UiScreen` 的场景。窗口从不自行关闭：它调用 `request_close()`，由 `UiRoot` 关闭它。
4. 用 `UiRoot.open(scene)` 打开窗口。要通过按键打开某个窗口，将 `settings_screen` 设为该窗口的场景，并添加输入动作 `toggle_settings`（或设置 `settings_action`）。Esc 对应内置的 `ui_cancel`。
5. 可选：将 `fps_counter.tscn` 添加到你的 HUD。

外观来自项目主题；`FpsCounter` 使用主题类型变体 `FpsCounter`。

## 文档

见模板仓库中的 `docs/zh_CN/systems/ui.md`。

---

*本页对应 Iso & Orbit 1.0.0。*
