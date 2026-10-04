<!-- translation of README.md @ 6853806db277 -->
# Iso & Orbit - 相机与角色控制器模板

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

版本 1.1.0 · Godot 4.7（已在 4.7.2 上测试）· GDScript · MIT

适用于等距视角和俯视角 RPG 的点击移动角色控制器与环绕相机。点击地面，英雄就会绕开障碍物跑过去；按住按键，英雄会跟随光标。相机可以环绕旋转、缩放，并且不会穿墙。

![点击移动、按住转向、环绕和缩放相机、发现地点](docs/images/demo.gif)

没有第三方素材：角色由脚本用基本几何体搭建，表面图案由着色器生成并烘焙为无缝纹理，声音是合成的。

## 快速上手

1. 安装 Godot 4.7.2，标准版或 .NET 版均可。Jolt Physics 已内置于引擎，无需另行安装。渲染器为 Forward+。
2. 克隆仓库，在项目管理器（Project Manager）中导入 `project.godot` 并打开。由于 `.godot/` 不在仓库中，首次导入需要稍等片刻。
3. 按 F5 运行演示（`res://gdscript/main.tscn`）。

操作说明显示在左上角。要隐藏它，打开设置（F10）→ 界面，关闭**操作提示和速度**。界面语言也在同一选项卡中选择。

## 操作

| 输入 | 动作 |
|---|---|
| 左键点击地面 | 跑到该点 |
| 按住左键 | 跟随光标奔跑 |
| 左键 + 右键 | 向相机所看方向奔跑；A / D 斜向偏转 |
| 右键 + 鼠标 | 环绕旋转相机 |
| 右键 + WASD | 相对相机移动 |
| 鼠标滚轮 | 缩放：更低更近，或更高更远 |
| Shift | 按住时冲刺（也可在设置中改为切换） |
| 空格 | 跳跃 |
| F10 | 打开设置（游戏暂停）；按 Esc 或 F10 关闭 |

所有模式及其设置：[操作](docs/zh_CN/controls.md)。

## 功能

**移动**

- 点击后沿导航网格跑到该点，并有标记显示目标位置。
- 按住左键跟随光标奔跑：默认直奔光标，遇到障碍物时沿其滑行；也可选择沿导航路径前往光标下的点。
- 点击与按住在 0.2 秒后区分，因此按住按键时英雄绝不会先绕路跑向按下的位置。
- 同时按住两键：向相机所看方向奔跑。右键加 WASD：相对相机移动，可以保持面朝前方，也可以转身面朝前进方向。
- 匀加速与匀减速，精确停在目标点而不冲过头，转向速率有限，静止时可瞬间转身。
- 带体力的冲刺。跳跃支持土狼时间和输入缓冲；在任何物理帧率下跳跃高度都相同。
- 边缘防护：在落差边缘，英雄会停下，或像沿墙一样沿边缘滑行。

**相机**

- 右键环绕旋转，滚轮缩放。距离与俯仰角同时变化：相机越近，角度越低，便于看清前方。
- 可选：自动转到奔跑中的英雄身后，并将俯仰角平滑调整到设定角度。
- 相机转动时，光标停留在地面上的同一位置，因此按住按键时英雄会保持航向，而不会原地兜圈。
- 相机臂：相机遇到后方的墙、山或屋顶时停下；可选：障碍物遮住英雄时拉近。距离很近时，英雄变为半透明。
- 在障碍物后，英雄显示为一个带描边的剪影，手持装备绘制在其上方。

**其他内容**

- 设置窗口（F10），包含操作、角色、相机、显示、界面和声音选项卡，设置保存到 `user://settings.cfg`。界面提供英语、西班牙语、日语、巴西葡萄牙语、俄语、土耳其语和简体中文，可随时切换。
- 角色的脚步、跳跃、落地和冲刺信号，并已连接对应的声音。
- 演示关卡：一片 80 × 80 米、围着栅栏的林间空地，内有遗迹、营地、农庄、树篱迷宫、坡道，以及一座带螺旋山路的山。有四个可发现的地点，五个 NPC 驻守其间，还有十种英雄外观可选。
- 无头（headless）测试，覆盖移动、输入、跳跃、冲刺和声音、相机及相机臂、英雄外观、设置窗口和翻译；另有一个脚本，无需打开编辑器即可找出所有场景中编辑器的节点警告。

**不包含：** 手柄支持（仅支持鼠标和键盘）和动画：模型是静态的基本几何体。

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
- **角色对鼠标一无所知。** 输入节点位于 `main.tscn`，而不在 `player.tscn` 中。制作 NPC 时，实例化 `player.tscn`，去掉玩家专用的 `Silhouette` 和 `Appearance` 节点，然后在 AI 中调用 `NavigationMover.move_to()`。
- **组件对设置一无所知。** 它们只读取自己的导出属性。只有演示中的 `settings_applier.gd` 和设置窗口会与 `Settings` 自动加载通信，因此组件可以脱离它们移植到其他项目。

详见：[架构](docs/zh_CN/architecture.md)。

## 在你的项目中使用

组件位于 `addons/iso_orbit/`，每个部分一个文件夹；将需要的文件夹复制到你项目中的同名文件夹：

| 插件 | 提供的功能 |
|---|---|
| `orbit_camera` | 环绕相机及其相机臂；可跟随任意 `Node3D` 目标 |
| `click_to_move` | 点击和按住沿导航网格移动、方向操控、点击标记 |
| `ground_character` | 现成的角色身体：重力、跳跃、带体力的冲刺、边缘防护、脚步信号、声音、手部摆动、可切换的模型（需要 `click_to_move`） |
| `occluded_silhouette` | 障碍物后的角色剪影 |
| `points_of_interest` | 可发现的地点及其提示消息 |
| `ui_screens` | 会暂停游戏的窗口栈，以及 FPS 计数器 |

移动是一条链：输入向 `NavigationMover` 下达命令，移动器只计算速度，由它所属的身体在每个物理帧应用。`GroundCharacter` 是现成的身体；最简单的身体如下：

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
```

可以在任何地方调用 `mover.move_to(point)` 或 `mover.steer(direction)`：你自己的输入、AI 或网络代码。[在你的项目中使用](docs/zh_CN/integration.md)说明了每个插件的需求，[项目配置](docs/zh_CN/project-setup.md)列出了组件要求 `project.godot` 提供的物理层、输入动作和分组。

## 文档

- **入门：** [快速上手](docs/zh_CN/getting-started.md) · [操作](docs/zh_CN/controls.md) · [设置](docs/zh_CN/settings.md)
- **代码：** [架构](docs/zh_CN/architecture.md) · [在你的项目中使用](docs/zh_CN/integration.md) · [项目配置](docs/zh_CN/project-setup.md)
- **系统：** [移动](docs/zh_CN/systems/locomotion.md) · [相机](docs/zh_CN/systems/camera.md) · [输入](docs/zh_CN/systems/input.md) · [角色](docs/zh_CN/systems/characters.md) · [音频](docs/zh_CN/systems/audio.md) · [UI](docs/zh_CN/systems/ui.md) · [世界与导航](docs/zh_CN/systems/world-and-navigation.md)
- **维护：** [测试](docs/zh_CN/testing.md) · [已知问题](docs/zh_CN/known-issues.md) · [术语表](docs/zh_CN/glossary.md) · [路线图](docs/zh_CN/roadmap.md)

## 仓库结构

| 文件夹 | 内容 |
|---|---|
| `addons/iso_orbit/` | 组件，每个可单独取用的部分一个文件夹 |
| `gdscript/` | 组装这些组件的演示：`main.tscn`、英雄、设置系统和设置窗口 |
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

- 在 `csharp/` 中提供 C# 示例，使用相同的组件，主场景基于 `shared/world/world.tscn` 构建。
- 动画：用 `NavigationMover.get_speed()` 驱动 `AnimationTree` 中的待机/奔跑混合。

## 许可证

MIT，见 [LICENSE](LICENSE)。例外：`icon.svg` 是 Andrea Calabró 设计的 Godot 标志，采用 CC BY 4.0 许可。

---

*本页对应 Iso & Orbit 1.1.0。*
