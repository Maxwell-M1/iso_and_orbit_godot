<!-- translation of README.md @ 84a666a02ac2 -->
# Iso & Orbit - 相机与角色控制器模板

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

版本 1.2.0 · Godot 4.7（已在 4.7.2 上测试）· GDScript · MIT

适用于等距视角和俯视角 RPG 的点击移动角色控制器与环绕相机。点击地面，英雄就会绕开障碍物跑过去；按住按键，英雄会跟随光标。相机可以环绕旋转、缩放，并且不会穿墙。

**第一次使用本项目？**先[运行演示](docs/zh_CN/getting-started.md)，再[迁移现成英雄](docs/zh_CN/integration.md#将演示中的英雄迁移到你的项目)，然后[选择移动与相机配置](docs/zh_CN/configurations.md)。

![点击移动、按住转向、环绕和缩放相机、发现地点](docs/images/demo.gif)

没有第三方素材：角色由脚本用基本几何体搭建，表面图案由着色器生成并烘焙为无缝纹理，声音是合成的。随附视角使用视野角 45° 的透视相机。可复用部分是普通的 GDScript 组件，没有需要启用的编辑器插件。

## 快速上手

1. 安装 Godot 4.7.2，标准版即可。项目使用 GDScript，不需要 .NET SDK。Jolt Physics 已内置于引擎，无须另行安装。渲染器为 Forward+。
2. 克隆仓库，在项目管理器（Project Manager）中导入 `project.godot` 并打开。由于 `.godot/` 不在仓库中，首次导入需要稍等片刻。
3. 按 F5 运行演示（`res://gdscript/main.tscn`）。

操作说明显示在左上角。要隐藏它，打开设置（F10）→ 界面，关闭**操作提示和速度**。界面语言也在同一选项卡中选择。

## 操作

| 输入 | 动作 |
|---|---|
| 左键点击地面 | 跑到该点 |
| 按住左键 | 跟随光标奔跑 |
| 按住左键，然后按右键 | 奔跑时环顾四周；英雄保持原路线 |
| 按住右键，然后按左键 | 朝相机所看方向奔跑；A / D 斜向偏转 |
| 右键 + 鼠标 | 环绕旋转相机 |
| 右键 + WASD | 相对相机移动 |
| 鼠标滚轮 | 缩放：更低更近，或更高更远 |
| Shift | 按住时冲刺（也可在设置中改为切换） |
| 空格 | 跳跃 |
| E | 在传送台上前往它通往的地点 |
| F10 | 打开设置（游戏暂停）；按 Esc 或 F10 关闭 |

所有模式及其设置：[操作](docs/zh_CN/controls.md)。

## 功能

**移动**

- 点击后沿导航网格跑到该点，并有标记显示目标位置。
- 按住左键跟随光标奔跑：默认直奔光标，遇到障碍物时沿其滑行；也可选择沿导航路径前往光标下的点。
- 点击与按住在 0.2 秒后区分，因此按住按键时英雄绝不会先绕路跑向按下的位置。
- 先按右键再按左键（或同时按下）：向相机所看方向奔跑；先按左键再按右键：奔跑中环顾四周，英雄保持路线。右键加 WASD：相对相机移动，可以保持面朝前方，也可以转身面朝前进方向。
- 匀加速与匀减速，精确停在目标点而不冲过头，转向速率有限，静止时可瞬间转身。
- 带体力的冲刺。跳跃支持土狼时间和输入缓冲；在任何物理帧率下跳跃高度都相同。下落可使用单独的重力和速度上限（`FallSettings`）。
- 边缘防护：在落差边缘，英雄会停下，或像沿墙一样沿边缘滑行。
- 0.3 米以内的台阶上下都不会离开地面；45° 以内的斜坡可以走上去。
- 可选悬浮模式：英雄模型悬在地面上方，平滑滑过台阶，随奔跑摇摆、倾斜，不发出脚步声，跳跃后缓慢下落。

**相机**

- 右键环绕旋转，滚轮缩放。距离与俯仰角同时变化：相机越近，角度越低，便于看清前方。
- 可选：自动转到奔跑中的英雄身后，并将倾角和缩放级别平滑调整到设定值；启停在任何帧率下都同样平滑。英雄朝相机奔跑时，即使刚掉头，画面也不会猛然绕转。
- 相机转动时，光标停留在地面上的同一位置，因此按住按键时英雄会保持航向，而不会原地兜圈。
- 相机臂：相机遇到后方的墙、山或屋顶时停下；可选：障碍物遮住英雄时拉近。距离很近时，英雄变为半透明。
- 在障碍物后，英雄显示为一个带描边的剪影，手持装备绘制在其上方。

**关卡**

- 关卡在加载画面后方切换，英雄和界面继续存在：后台加载新关卡、释放旧关卡，然后英雄出现在出生点，相机转到其后方。
- 加载画面将游戏最后一帧模糊并缓缓放大，同时显示地名、进度条和操作提示。
- 传送门可先询问玩家（演示中的传送台提示“E 传送至……”），也可像门一样立即旅行。
- 玩家英雄是现成的 `PlayableHero` 场景，包含角色、输入、相机和点击标记，并提供立即放置它的调用。

**其他内容**

- 设置窗口（F10），包含操作、角色、相机、显示、界面和声音选项卡，设置保存到 `user://settings.cfg`。界面提供英语、西班牙语、日语、巴西葡萄牙语、俄语、土耳其语和简体中文，可随时切换。
- 角色会报告自己在做什么，供动画、特效和界面使用：状态（站立、奔跑、冲刺、跳跃、下落）及每次变化的信号，带左右脚信息的脚步、带高度的台阶事件、起跳和落地、作为混合值的速度、模型坐标轴下的移动和加速度、转向及步态周期。声音已连接到这些信号，一个面板（设置 → 界面）实时显示这一切以及最近的事件。
- 两个演示关卡：一片 80 × 80 米、围着栅栏的林间空地，内有遗迹、营地、农庄、树篱迷宫、带坡道和台阶的平台，以及带螺旋山路的山；还有一座可乘传送台抵达的湖中小岛。五个可发现地点中，草地上有四处及五个 NPC，岛上有一处；可选择十种英雄外观。
- 无头（headless）测试，覆盖移动、输入、跳跃、冲刺和声音、角色状态、台阶和斜坡、相机及相机臂、英雄外观、设置窗口和翻译、关卡与传送。

**不包含：**手柄支持、游戏内按键重新绑定界面和骨骼动画。输入动作可在“项目设置”中配置，界面会读取当前绑定。模型由静态基本几何体构成。

## 整体结构

```
鼠标、WASD  ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (路径或方向)        (加速、制动、
                                                                               转向：纯数学)
                                                               │ 速度
                                                               ▼
Shift, Space ──► CharacterActionInput ──────────────────► GroundCharacter
                                                          (CharacterBody3D：重力、跳跃、冲刺、
                                                           move_and_slide、转动模型)

鼠标 ──► OrbitCameraRig ──► CameraArm ──► Camera3D
```

- **只有 `GroundCharacter` 移动身体。** 移动组件只返回速度，从不调用 `move_and_slide()`，因此重力、跳跃以及将来可能加入的击退都在同一处合并。
- **`GroundMotion` 是不依赖节点的纯数学**，便于单独测试。
- **角色对鼠标一无所知。** 输入节点位于可操控英雄场景（`playable_hero.tscn`），而不在 `player.tscn` 中。制作 NPC 时，实例化 `player.tscn`，去掉玩家专用的 `Silhouette` 和 `Appearance` 节点，然后在 AI 中调用 `NavigationMover.move_to()`。
- **英雄不属于任何关卡。** 它在 `main.tscn` 中与关卡容器并列，关卡在它周围更换。
- **组件对设置一无所知。** 它们只读取自己的导出属性。只有演示中的 `settings_applier.gd` 和设置窗口会与 `Settings` 自动加载通信，因此组件可以脱离它们移植到其他项目。

详见：[架构](docs/zh_CN/architecture.md)。

## 在你的项目中使用

组件位于 `addons/iso_orbit/`，每个部分一个文件夹；将需要的文件夹复制到你项目中的同名文件夹：

| 插件 | 提供的功能 |
|---|---|
| `orbit_camera` | 环绕相机及其相机臂；可跟随任意 `Node3D` 目标 |
| `click_to_move` | 点击和按住沿导航网格移动、方向操控、点击标记 |
| `ground_character` | 现成的角色身体：重力、跳跃、下落设置、带体力的冲刺、边缘防护、脚步信号、声音、手部摆动、悬浮、可切换的模型（需要 `click_to_move`） |
| `occluded_silhouette` | 障碍物后的角色剪影 |
| `points_of_interest` | 可发现的地点及其提示消息 |
| `ui_screens` | 会暂停游戏的窗口栈，以及 FPS 计数器 |
| `levels` | 在加载画面后方切换关卡、通往关卡的传送门和出生点 |

要以最短步骤运行，请按[迁移指南](docs/zh_CN/integration.md#将演示中的英雄迁移到你的项目)复制已装配的 `playable_hero.tscn` 及其依赖。指南包含小型测试关卡、精确的碰撞／导航设置，以及定制前的验证步骤。英雄不依赖演示设置窗口或关卡系统。

使用自己的控制器或 AI 时，`NavigationMover.move_to(point)` 沿导航路径移动，`steer(direction)` 直接引导。身体每个物理帧应用一次返回的速度；移动器从不移动身体。最简接入示例见[使用自己的身体](docs/zh_CN/integration.md#使用自己的身体)。

[配置方案](docs/zh_CN/configurations.md)比较随附默认设置、鼠标沿路径移动和跟随相机探索，并解释各参数的用途。[项目配置](docs/zh_CN/project-setup.md)列出必需的动作、物理层和可选演示依赖。

## 文档

- **入门：** [快速上手](docs/zh_CN/getting-started.md) · [操作](docs/zh_CN/controls.md) · [配置方案](docs/zh_CN/configurations.md) · [设置](docs/zh_CN/settings.md)
- **代码：** [架构](docs/zh_CN/architecture.md) · [在你的项目中使用](docs/zh_CN/integration.md) · [项目配置](docs/zh_CN/project-setup.md)
- **系统：** [移动](docs/zh_CN/systems/locomotion.md) · [相机](docs/zh_CN/systems/camera.md) · [输入](docs/zh_CN/systems/input.md) · [角色](docs/zh_CN/systems/characters.md) · [音频](docs/zh_CN/systems/audio.md) · [UI](docs/zh_CN/systems/ui.md) · [世界与导航](docs/zh_CN/systems/world-and-navigation.md) · [关卡](docs/zh_CN/systems/levels.md)
- **维护：** [测试](docs/zh_CN/testing.md) · [已知问题](docs/zh_CN/known-issues.md) · [术语表](docs/zh_CN/glossary.md) · [路线图](docs/zh_CN/roadmap.md)

## 仓库结构

| 文件夹 | 内容 |
|---|---|
| `addons/iso_orbit/` | 组件，每个可单独取用的部分一个文件夹 |
| `gdscript/` | 组装这些组件的演示：游戏框架 `main.tscn`、可操控英雄、设置系统和设置窗口 |
| `shared/` | 供 GDScript 演示和将来的 C# 演示共用的演示内容：关卡、角色和装备、世界着色器和纹理、声音、UI 主题。关卡使用的两个小型 GDScript 脚本也在这里 |
| `l10n/` | 界面翻译（gettext `.po`） |
| `tests/` | 无头测试 |
| `docs/` | 文档 |

## 测试

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

这里的 `godot` 指你的 Godot 4.7.2 可执行文件；在 Windows 上请使用 `_console.exe` 版本，才能看到输出并获得退出码。只运行部分测试套件时，在 `--` 之后加上其名称的一部分，例如 `-- camera input`。只要有一项检查失败，退出码就是 1。详见：[测试](docs/zh_CN/testing.md)。

## 路线图

- 在 `csharp/` 中提供 C# 示例，使用相同的组件，并在 `shared/world/` 中的关卡上搭建游戏框架。
- 动画：使用 `GroundCharacter.get_locomotion_blend()` 驱动 `AnimationTree` 中的待机、奔跑和冲刺混合。

## 许可证

MIT，见 [LICENSE](LICENSE)。例外：`icon.svg` 是 Andrea Calabró 设计的 Godot 标志，采用 CC BY 4.0 许可。

---

*本页对应 Iso & Orbit 1.2.0。*
