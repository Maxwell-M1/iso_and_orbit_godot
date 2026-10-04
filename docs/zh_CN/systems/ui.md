<!-- translation of docs/en/systems/ui.md @ 40a5a08ac8d9 -->
# UI

> 本文是[英文原文](../../en/systems/ui.md)的翻译。两者不一致时，以英文版为准。

游戏上层的窗口、设置系统、HUD 和界面翻译。

## 窗口：UiRoot 与 UiScreen

`UiRoot`（一个 `CanvasLayer`，`addons/iso_orbit/ui_screens/ui_root.gd`；演示中的实例是 `gdscript/ui/ui_root.tscn`）以栈的形式显示窗口：

- `open(scene)` 将窗口放到最上层，`close_top()` 关闭最上层窗口，`toggle(scene)` 关闭已打开的窗口（以及它上面的所有窗口），或者打开它。Esc（`ui_cancel`）关闭最上层窗口；F10（`toggle_settings`）切换设置窗口（`settings_screen`）。
- 只要有窗口打开，游戏就会暂停（`pause_game`），鼠标光标可见。`UiRoot` 以 `PROCESS_MODE_ALWAYS` 运行，其窗口继承这一模式。
- 窗口打开时键盘焦点移到其 `initial_focus`，关闭时焦点回到原处。
- 信号：`screen_opened(screen)`、`screen_closed(screen)`。查询：`has_open_screens()`、`get_top_screen()`。

窗口是一个根节点继承 `UiScreen`（全屏 `Control`）的场景。窗口从不自行关闭：它通过 `close_requested` 信号（`request_close()`）请求关闭，由 `UiRoot` 关闭它。调用沿树向下，信号沿树向上，因此 `UiRoot` 始终知道哪些窗口是打开的，并能正确恢复焦点和暂停状态。要对打开和关闭作出响应，请重写 `_screen_opened()` 和 `_screen_closed()`。

**新建窗口：** 一个以 `UiScreen` 为根节点的场景，用容器布局，由主题提供样式；用 `UiRoot.open(scene)` 打开。

## 设置

### GameSettings

`Settings` 自动加载（`gdscript/settings/game_settings.gd`，类 `GameSettings`）保存设置值：

- 键是该类的常量（`GameSettings.LEDGE_GUARD` 即 `&"gameplay/ledge_guard"`），因此可以用在 `match` 中。斜杠之前的部分是文件中的节（section）。
- `DEFAULTS` 包含每个键及其默认值；默认值的类型就是该设置的类型。文件中类型错误的值（手动编辑造成）会回退为默认值。
- `get_value(key)`、`set_value(key, value)`、`reset_to_defaults()`，以及信号 `changed(key, value)`。
- 设置值在 `_init()` 中加载，早于任何场景节点的 `_ready()`，并在设置窗口关闭和游戏退出时保存到 `user://settings.cfg`。`persistent = false` 会停止保存；测试会设置它并将所有设置重置为默认值，因此测试会忽略玩家的设置，也永远不会覆盖它们。
- `_OBSOLETE_KEYS` 中列出的键会在加载时从文件中移除。
- 引擎层面的设置由该类自行应用（`_apply_to_engine()`）：全屏、帧率上限和 V-Sync、物理插值、界面缩放、语言、音量。场景节点的设置由场景应用：在演示中，`gdscript/demo/settings_applier.gd` 在启动时读取 `get_value()`，并监听 `changed`。

**新建设置：**

1. 在 `GameSettings` 中添加一个键常量，并在 `DEFAULTS` 中添加默认值。
2. 在 `settings_screen.tscn` 中添加一个使用该键的控件（见下文）。窗口的代码无需修改。
3. 在 `settings_applier.gd` 中添加设置该属性的分支；如果由引擎应用，则添加到 `GameSettings._apply_to_engine()` 中。
4. 在翻译中添加其文本，见[翻译](#翻译)。

### 设置窗口

`gdscript/ui/settings/settings_screen.tscn` 有六个选项卡：操作、角色、相机、显示、界面、声音。所有设置及其默认值列在[设置](../settings.md)中。

- 每个控件自行绑定到一个键，无论该设置在何处更改，控件都会随之更新：
  - `SettingCheckButton`：布尔设置。
  - `SettingOptionButton`：整数设置；选项的值就是它的 ID，在检查器（Inspector）中与文本一起设置，因此选项可以随意重新排序。
  - `SettingSlider`：数值。`value_label` 按 `value_format` 显示数值；`zero_text` 替代零值（例如“立即”）；`apply_on_release` 让鼠标拖动只在松开时生效，用于会改变界面自身大小的设置。上下限和步长是 `Range` 的属性。
  - `SettingLanguageButton`：界面语言，见下文。
- 离开另一项设置就没有意义的控件会变暗并锁定：未选侧移模式时的后退减速，关闭跳跃时的跳跃高度，关闭冲刺时所有与冲刺相关的设置，关闭疲劳时的体力持续时间，关闭倾角对齐时的倾角，以及跟随和对齐都关闭时的跟上用时（`_update_dependent_rows()`）。
- 每个选项卡页面都是一个 `ScrollContainer`：内容较长的选项卡可以滚动（也会跟随键盘焦点滚动），窗口不会变大。窗口高度是 `TabContainer` 的 `custom_minimum_size`（440）。最长的“角色”选项卡也能放下，在 100% 界面缩放下整个窗口仍能完整显示在屏幕上。
- **全部重置**调用 `reset_to_defaults()`。窗口在关闭时保存设置。
- V-Sync 提示由代码用一句翻译后的文本和显示器刷新率拼接而成。

### 界面缩放

界面缩放就是根窗口的 `content_scale_factor`。在 `canvas_items` 拉伸模式下，它缩放所有 2D 内容（提示、FPS 计数器、体力条、窗口），不影响 3D 视图。100% 是场景中制作时的原始尺寸，50% 是其一半。用鼠标拖动滑块时，缩放只在松开时应用（`apply_on_release`）；否则窗口会在鼠标下改变大小，滑块也会从鼠标下滑走。键盘和滚轮则会立即改变缩放。

## HUD

| `main.tscn` 中的节点 | 脚本 | 显示内容 |
|---|---|---|
| `Hud`、`Hud/Panel` | `Hud` 上的 `gdscript/demo/hud.gd` | 操作提示和速度。脚本只更新速度；`settings_applier.gd` 负责显示或隐藏面板，并隐藏已禁用功能对应的行（配合右键的按键、两键 + A/D、冲刺、跳跃） |
| `Hud/FpsCounter` | `FpsCounter`（Label） | 右上角的每秒帧数；暂停时也工作 |
| `Hud/CharacterState/Monitor` | `CharacterMonitor`（Label） | 位于 FPS 计数器下方：英雄在做什么（状态、速度和混合值、移动、转向、在地面还是空中、脚步和左右脚、体力）以及最近的事件。默认隐藏。见[移动](locomotion.md#charactermonitor以文本显示状态) |
| `Hud/DiscoveryToast` | `DiscoveryToast`（Label） | 玩家首次进入 `PointOfInterest` 时显示“发现地点：…”，持续 `show_time`（3.5 秒）。通过 `points_of_interest` 分组找到所有地点；`show_discovery(title)` 可手动显示一条 |
| `Hud/StaminaBar` | `StaminaBar`（ProgressBar） | 开始消耗体力时出现，角色力竭期间变红（`StaminaBarExhausted` 变体），重新充满后在 0.6 秒内淡出 |

提示面板、FPS 计数器、路径线和角色状态面板在设置 → 界面中开关。

## 主题

`shared/ui/ui_theme.tres` 是项目主题（`gui/theme/custom`）：包括面板、窗口、按钮，以及以下类型变体：`WindowPanel`、`WindowLayout`、`TabPage`、`SettingsList`、`HintLabel`、`FpsCounter`、`DiscoveryToast`、`StaminaBar`、`StaminaBarExhausted`。节点通过 `theme_type_variation` 选择变体，而不是逐个覆盖样式。

## 翻译

英语是场景和脚本本身使用的语言。其他语言是 `l10n/ui/<locale>.po` 中的 gettext 翻译，在 `project.godot` 中注册（`internationalization/locale/translations`）。语言由设置 `interface/language` 决定（设置 → 界面 → **语言**，默认为英语）；`GameSettings` 将其传给 `TranslationServer.set_locale()`，界面立即切换，无需重启。

文本的翻译方式：

- **场景中的文本**由引擎翻译：`Label`、`Button` 和 `CheckButton` 的文本，`OptionButton` 的选项，工具提示，选项卡标题，以及 NPC 头顶的 `Label3D` 文本（`auto_translate_mode`）。
- **由代码拼接的文本**使用 `tr()`：带地点名称的“发现地点：…”、带单位的滑块数值以及 V-Sync 提示会在 `NOTIFICATION_TRANSLATION_CHANGED` 时重新生成；速度读数本来就每帧重新生成。这些节点会关闭自身的自动翻译，以免引擎尝试翻译拼接后的结果。
- 语言列表中的**语言名称**以各自的语言书写（“English”“Русский”），永远不翻译（`SettingLanguageButton.NATIVE_NAMES`）。

**新增语言：**

1. 将 `l10n/ui/ru.po` 复制为 `l10n/ui/<locale>.po`，在文件头中设置 `Language` 和 `Plural-Forms`，并翻译每一条 `msgstr`。Poedit 之类的 PO 编辑器会有帮助。
2. 将该文件添加到 `internationalization/locale/translations`（项目设置 → 本地化 → 翻译（Project Settings → Localization → Translations））。
3. 将该语言的自称名称添加到 `gdscript/ui/settings/setting_language_button.gd` 的 `NATIVE_NAMES` 中。设置窗口中的列表根据已加载的翻译生成，因此无需修改其他内容。
4. 运行测试：`tests/localization_checks.gd` 会报告翻译中缺失的每个界面字符串，以及游戏中不再显示的每个翻译条目。

**新增字符串：** 在场景中或在 `tr("...")` 中用英语书写，然后在每个 `.po` 文件中添加对应的 `msgid` 及其翻译。测试会从场景中收集字符串；只由脚本传给 `tr()` 的字符串列在 `tests/localization_checks.gd` 的 `SCRIPT_STRINGS` 中，因此新的此类字符串也要加到那里。

---

*本页对应 Iso & Orbit 1.1.0。*
