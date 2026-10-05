<!-- translation of docs/en/testing.md @ fd518f56694a -->
# 测试

[← 文档目录](index.md)

> 本文是[英文原文](../en/testing.md)的翻译。两者不一致时，以英文版为准。

测试以无头模式运行主场景，使用真实的输入事件和真实的物理，并将测量结果与预期进行比较。

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

这里的 `godot` 指你的 Godot 4.7.2 可执行文件。在 Windows 上请使用 `_console.exe` 版本：普通版本会与终端分离，因此你既看不到输出，也得不到退出码。刚克隆的仓库需要先导入一次项目，可以在编辑器中导入，也可以运行 `godot --headless --path . --import`。

可以直接使用可执行文件的完整路径，无须将其加入 PATH。在 PowerShell 中，带引号的路径前要加 `&`：

```powershell
& 'C:\path\to\Godot_console.exe' --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

将示例路径替换为你安装的 Godot 4.7.2 控制台版可执行文件，并在本项目根目录运行。

只运行部分测试套件（例如在调整相机时）：在 `--` 之后加上其名称的一部分。

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

只要有一项检查失败，退出码就是 1。最后，运行器会打印每个测试套件中通过和失败的检查数量。

## 测试套件

测试套件按 `tests/run_checks.gd` 所列顺序运行，共用一个主场景。修改时可先运行相关套件；跨系统集成前应运行全部套件。

| 测试套件 | 主要检查 |
|---|---|
| `movement_checks.gd` | 加速、制动、重新指定目标、转向、可达和不可达目标、绕障碍物的路线、坡道及边缘 |
| `world_checks.gd` | 演示地形上的导航、地点发现区域、静态 NPC 碰撞及英雄展示模型 |
| `hero_look_checks.gd` | 切换全部十种英雄模型、装备位置、剪影和手部运动 |
| `character_actions_checks.gd` | 冲刺与疲劳、按住／切换输入、重新绑定及修饰键释放、跳跃缓冲／土狼时间、下落覆盖、角色信号和声音 |
| `character_state_checks.gd` | 配置警告、状态和动画数据、台阶／斜坡、传送、悬浮、插值、停止游戏时间和监视面板 |
| `input_checks.gd` | 点击与按住、双鼠标键的顺序、两种按住模式、按键模式、光标捕获、取消操作及缺失的输入动作 |
| `camera_checks.gd` | 不同渲染／物理帧率下的环绕、缩放和跟随，急转、朝相机奔跑、手动环绕后的等待、倾角／缩放／高度对齐和传送 |
| `camera_arm_checks.gd` | 避开障碍物、碰撞层、忽略分组、可选的遮挡拉近和近距离淡化 |
| `settings_window_checks.gd` | 暂停与焦点、各设置选项卡、属性映射、依赖控件、界面缩放、重置和关闭 |
| `localization_checks.gd` | 翻译覆盖、保留动作标记、语言切换、12 个重新绑定动作的名称、已打开的提示／窗口／加载提示及翻译继承 |
| `level_checks.gd` | 出生点、旅行提示、加载进度和暂停、场景替换、保留英雄状态及失败恢复 |

对文档所述输入／相机配置，可先运行 `movement`、`character_actions`、`input`、`camera` 和 `settings_window`。过滤器 `camera` 会选择两个相机套件。把英雄复制到别的项目时，还应按[迁移检查清单](integration.md#将演示中的英雄迁移到你的项目)验证：本仓库测试通过并不能证明必需文件和项目设置都已复制。

## 测试的行为

- 测试使用默认设置运行，不保存任何内容：运行期间玩家的设置被重置为默认值，且永远不会被覆盖。
- 每项检查都会恢复它所更改的内容。测试套件在同一个主场景上依次运行，而单独运行的套件会得到一个全新的主场景，检查在两种情况下都必须通过。每项检查后 `Engine.time_scale` 都会恢复为 1，因此即使某项检查在慢动作或时间停止时崩溃，也不会影响后续检查。
- 任何引擎或脚本错误或警告也会导致运行失败：通过 `OS.add_logger()` 添加的 `Logger` 会统计这些问题，运行器将其数量打印为“engine and script errors”，并计入失败数。崩溃的检查会中断，但其他检查继续，否则崩溃可能悄悄漏过。只有检查有意触发并事先声明的错误（运行器的 `expect_error()`，随后由 `take_expected_errors()` 确认它出现）不会计入失败；不能作为关卡的场景检查就是一例。CPU 负载很高时，Jolt 可能额外产生一条警告，见[已知问题](known-issues.md#测试)。
- 卡住的运行在游戏时间 1200 秒后判定为失败。关卡在后台加载时，无窗口绘制的帧运行得比屏幕上快得多，游戏时间也随之加速；因此关卡检查按真实时间等待切换。
- 退出前，运行器会移除主场景并等待 0.1 秒。使用 `--fixed-fps` 时，游戏时间比现实时间走得快，而音频按现实时间播放，因此结束前刚播放的脚步声仍在发声。立即退出有时会使引擎报告泄漏的 `AudioStreamPlayback` 对象和脚步声资源。
- 无头窗口无法移动系统光标，因此测试只能看到奔跑方向；光标本身需在游戏中检查。无头窗口也从不改变鼠标模式（`Input.mouse_mode` 始终为 `VISIBLE`），因此对于隐藏光标，测试读取的是 `PointClickMoveInput.is_cursor_hidden()`。
- 限值尽可能根据组件的设置计算，因此调整 `LocomotionSettings` 本身不会使测试失败。

## 编写检查

新的检查就是在合适的测试套件中添加一个 `_check_…` 函数，并在该套件的 `_checks()` 中加一行。新的测试套件就是一个继承 `check_suite.gd` 的 `tests/<topic>_checks.gd` 文件，并在 `SUITES` 中加一行。`check_suite.gd` 提供共用的辅助函数：

| 辅助函数 | 作用 |
|---|---|
| `_teleport(position)` | 将玩家放到某点并使其静止，然后等待几个物理帧 |
| `_run_until_arrived(target, max_time)` | 下达奔跑命令，并记录到达前的时间、速度、行走距离和卡住的物理帧数 |
| `_check_route(title, from, to, max_time)` | 检查一条路线：按时到达且未卡住；对于可到达的点，精确到达该点且位于正确的楼层 |
| `_ticks(count)`、`_frames(count)`、`_wait_until(condition, max_ticks)` | 等待 |
| `_send_key()`、`_send_button()`、`_send_motion()` | 真实的输入事件 |
| `_expect(condition, what)` | 统计一项通过或失败的检查并打印 |
| `_error_count()` | 到目前为止引擎和脚本错误的数量（不含预期错误）；检查会比较操作前后的数量 |
| `_tree.call(&"expect_error", "part of the message")`、`_tree.call(&"take_expected_errors")` | 运行器的方法，不属于 `check_suite.gd`：前者声明检查将有意触发的错误，使其不计入失败；后者返回已声明却未出现的错误，并停止等待它们 |
| `_find_non_finite(found)` | 收集主场景中变换包含无穷大或 NaN 的 3D 节点 |
| `_same_values(a, b)` | 判断两个数组值是否相同；与 `==` 不同，它不会把 NaN 视为等于 NaN |
| `_median()`、`_min()`、`_max()`、`_first_time_at_most()` | 对记录值的统计 |

不要在测试脚本中把访问 `Settings` 自动加载的类（设置窗口的控件）用作类型名。测试脚本在自动加载名称存在之前就被编译，因此这样的类会编译失败，并导致本次运行的整个游戏无法工作。请用 `_tree.root.get_node(^"Settings")` 获取设置节点，并使用鸭子类型。

---

*本页对应 Iso & Orbit 1.2.0。*
