<!-- translation of addons/iso_orbit/ui_screens/README.md @ f510902e02d8 -->
# UI 窗口

[← 文档目录（模板仓库）](../../../docs/zh_CN/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

以栈的形式管理游戏上层的窗口：可以在一个窗口上再打开另一个，按 Esc 关闭最上层窗口，有窗口打开时暂停游戏并显示鼠标光标，将键盘焦点交给窗口并在窗口关闭时归还。另外还提供游戏暂停时也能工作的 FPS 计数器，以及供屏幕文字使用的当前输入动作按键名称。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `ui_root.gd` | `UiRoot`（CanvasLayer） | 窗口栈：`open()`、`close_top()`、`toggle()`；暂停、光标、焦点 |
| `ui_screen.gd` | `UiScreen`（Control） | 窗口的基类：`initial_focus`、`close_requested` 信号 |
| `fps_counter.gd`、`fps_counter.tscn` | `FpsCounter`（Label） | 每秒帧数，暂停时也工作 |
| `input_names.gd` | `InputNames`（RefCounted，静态） | 根据玩家键盘布局和翻译给出动作对应的按键或鼠标按钮：`of_action()`、`of_event()`；`format()` 根据 `{sprint}` 等标记将按键名填入文字 |
| `action_texts.gd` | `ActionTexts`（Node） | 填充父节点下各控件文字中的标记；切换语言和调用 `refresh()` 时重新填充 |

不需要其他插件。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/ui_screens/`。
2. 在主场景中添加一个挂载 `ui_root.gd` 的 `CanvasLayer`。它在游戏暂停时也会运行。
3. 将每个窗口做成根节点继承 `UiScreen` 的场景。窗口从不自行关闭：它调用 `request_close()`，由 `UiRoot` 关闭它。
4. 用 `UiRoot.open(scene)` 打开窗口。要通过按键打开某个窗口，将 `settings_screen` 设为该窗口的场景，并添加输入动作 `toggle_settings`（或设置 `settings_action`）；缺少动作时，`UiRoot` 在启动时报告一次，按键不会生效。Esc 对应内置的 `ui_cancel`。
5. 可选：将 `fps_counter.tscn` 添加到你的 HUD。
6. 可选：在文字中以动作标记表示按键，例如 `{jump} — jump`，并在场景中加入 `ActionTexts` 节点（它处理父节点下的控件）。玩家更改绑定后，调用 `get_tree().call_group(ActionTexts.GROUP, &"refresh")`。自行拼接文字的控件可实现 `refresh()` 并加入同一分组。要在其他语言中显示鼠标按钮、“Space”和未绑定动作的名称，请将 `InputNames.get_mouse_names()`、“Space”、`InputNames.UNBOUND`、`InputNames.LEFT_KEY` 和 `InputNames.RIGHT_KEY` 对应项加入翻译。最后两项应保留代表按键名称的 `%s`。

`UiRoot` 只会暂停正在运行的游戏，并只会结束由它自己开始的暂停：如果打开窗口前游戏已因关卡切换等原因暂停，暂停仍属于原管理者；若后者结束暂停，游戏会在窗口后方继续运行。

外观来自项目主题；`FpsCounter` 使用主题类型变体 `FpsCounter`。

## 文档

见模板仓库中的 `docs/zh_CN/systems/ui.md`，关卡切换期间的窗口行为见 `docs/zh_CN/systems/levels.md`。

---

*本页对应 Iso & Orbit 1.2.0。*
