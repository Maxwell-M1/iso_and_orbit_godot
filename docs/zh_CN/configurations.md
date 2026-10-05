<!-- translation of docs/en/configurations.md @ 2173d5158953 -->
# 配置可操控的英雄

[← 文档目录](index.md)

> 本文是[英文原文](../en/configurations.md)的翻译。两者不一致时，以英文版为准。

完成[迁移指南](integration.md)后，从 `gdscript/player/playable_hero.tscn` 开始。下面三种配置都保留随附的角色尺寸、移动资源和相机碰撞设置，只改变操控与观察英雄的方式，不引入随意设定的速度或平滑参数。

| 配置 | 适用情况 | 主要取舍 |
|---|---|---|
| [默认：手动环绕](#默认手动环绕) | 希望稳定观察一个区域，同时能点击寻路和直接操控 | 玩家自行决定相机方向 |
| [鼠标沿路径移动](#鼠标沿路径移动) | 按住鼠标移动时需要绕开已烘焙导航网格中的障碍物 | 在坡道和不同高度重叠的地方，路径可能突然切换 |
| [跟随相机探索](#跟随相机探索) | 长途行进时希望相机回到奔跑方向后方 | 路线变化时画面也会转动 |

## 在哪里修改设置

参数值有三个来源。修改前先确认自己编辑的是哪一个：

| 来源 | 何时生效 | 示例 |
|---|---|---|
| 脚本默认值 | 新增组件且场景没有覆盖该属性时 | `PointClickMoveInput.keys_with_camera` 初始为 `SIDESTEP` |
| 已保存的场景或资源 | 使用随附场景的实例时 | `playable_hero.tscn` 选择 `TURN`；其相机使用 1.1 秒的跟随用时 |
| 演示设置 | `SettingsApplier` 在启动和菜单设置变化时运行 | 即使场景中关闭了相机跟随，`user://settings.cfg` 也可能将它开启 |

在演示中比较各种配置前，先选择**设置 → 全部重置**。菜单改动会保存；运行中场景的**远程（Remote）**检查器改动只是临时的。单独使用英雄时，请编辑复制的场景，或从 `playable_hero.tscn` 创建继承场景，并分别保存各个变体。需要访问实例内部的节点时，启用**可编辑子节点（Editable Children）**。只有希望 `SettingsApplier` 接管这些值时才复制它。

以下路径相对于英雄实例：

| 要调整的内容 | 节点或资源 |
|---|---|
| 点击、按住、按键和光标 | `PlayerInput`（`PointClickMoveInput`） |
| 冲刺键模式和跳跃输入 | `PlayerActionInput`（`CharacterActionInput`） |
| 速度、加速、制动和转向速率 | `Character/NavigationMover` → `settings`，通常是 `player_locomotion.tres` |
| 跳跃、重力、台阶和体力消耗 | `Character`（`GroundCharacter`） |
| 边缘防护／体力恢复 | `Character/LedgeGuard`／`Character/Stamina` |
| 环绕、跟随、倾角和缩放 | `CameraRig`（`OrbitCameraRig`） |
| 相机避障和模型淡化 | `CameraRig/CameraArm`（`CameraArm`） |
| 模型悬浮 | `Character/Visual/Hover`（`CharacterHover`） |

相机支架的角度属性与移动资源的转向速率在**检查器中以度为单位显示**，但在 GDScript 中赋值时须使用**弧度**（`deg_to_rad(30.0)`）。`Camera3D.fov` 不同：在代码中也以度为单位。相机向下倾斜的角度为负。演示中的**向下倾角**滑块使用正角度，**高度**使用百分比：菜单中的 55% 对应 `follow_zoom_level = 0.55`，并非以米为单位的高度。

## 默认：手动环绕

这是随附英雄场景的状态，也是演示执行“全部重置”后的状态。你可以点击地面让英雄绕开障碍物，按住鼠标左键直接引导，也可以按住鼠标右键并用 WASD 相对相机移动。相机跟随角色身体的位置，但不会自动转到奔跑方向后方。

| 部分 | 保留的值 |
|---|---|
| 移动资源 | `max_speed = 5.5`、`sprint_speed_multiplier = 1.5`、`acceleration_time = 0.18`、`stop_time = 0.22`、`turn_speed = 720°/s` |
| 角色 | `jump_height = 1.0`、`gravity_scale = 3.0`、`max_step_height = 0.3`、`sprint_tires = true`、`sprint_duration = 5.0` |
| 输入 | `hold_mode = STEER`、`hold_delay = 0.2`、两种按键模式均为 `TURN`、`look_around_while_held = true`、`keep_aim_on_camera_turn = true` |
| 相机 | `follow_movement = false`、`follow_pitch = false`、`follow_zoom = false`、`mouse_pitch = false`；目标高度仍以 `height_follow_time = 0.15 s` 平滑跟随 |
| 初始视角 | `start_yaw = 45°`、`start_zoom = 0.55`、相机视野角 45° |
| 相机臂 | `keep_out_of_geometry = true`、`pull_in_on_occlusion = false`、碰撞层 1 和 3 |

保持边缘防护启用，并让随附的 `Visual` 继续作为相机臂的淡化目标。墙挡住英雄时，剪影帮助你看见英雄；相机臂则防止相机进入几何体。这是两种不同的功能。

**验证：**先点击有绕行路线的墙后方，再按住鼠标让英雄朝墙移动，最后在移动中环绕相机。点击应沿路径移动；按住时应因碰撞而沿墙滑动或停下。环顾四周时，奔跑路线应保持不变。修改移动参数前，分别测试 0.2 米台阶和跳跃。

## 鼠标沿路径移动

从默认配置开始，修改 `PlayerInput` 的以下属性：

| 属性 | 值 | 效果 |
|---|---|---|
| `hold_mode` | `FOLLOW_POINT` | 按住鼠标时不断更新导航目标点，而不是直线引导 |
| `stop_on_release` | `true` | 松开持续奔跑时按住的鼠标键，在当前位置制动 |
| `keys_with_camera` | `OFF` | 禁用右键 + WASD |
| `keys_with_camera_steer` | `OFF` | 禁用同时按住两个鼠标键时用 A/D 引导 |

保持三个相机跟随开关全关，相机方向就仍由玩家手动控制。默认移动资源已经能迅速加速和停下，无须为这种输入方式改变其速度。

短按仍会一直跑到目的地。`stop_on_release` **只影响按住操作**，演示菜单中没有这个选项；请在场景或代码中设置。把两种按键模式都设为 Off，**并不会**禁用双鼠标键移动：先按右键再按左键，仍会沿相机方向直线奔跑，不使用导航路径。

此配置适合导航网格可靠且光标下方大多只有一个明确地面的关卡。在坡道或平台附近，射线可能命中不同高度，因而重建路径。需要在这类地形上精准直接操控时，请改用默认的 `STEER` 模式。空路径在此控制器中并不代表“不要移动”；如果英雄径直撞向障碍物，请检查导航网格。

**验证：**按住鼠标指向墙的另一侧，将光标移到另一个可达位置，然后在途中松开。英雄应绕墙、重新选定目标，并在松开时制动。再短按一次，确认英雄会继续跑到目的地。

## 跟随相机探索

从默认的 `STEER` 和 `TURN` 输入模式开始，在 `CameraRig` 上启用以下属性：

| 属性 | 值 | 原因 |
|---|---|---|
| `follow_movement` | `true` | 点击或光标引导奔跑时，相机转到后方 |
| `follow_time` | 1.1 秒 | 随附场景调好的转动用时；平滑靠近新方向 |
| `follow_toward_camera_angle` | 30° | 几乎正对相机奔跑时，画面不会绕到身后 |
| `sharp_turn_speed` | 360°/秒 | 是随附角色 720°/秒转向速率的一半；避免跟随掉头过程中的中间朝向 |
| `follow_wait_after_rotate` | `true` | 保持手动选择的视角，直到停下或开始新的奔跑 |
| `follow_pitch` / `follow_pitch_angle` / `follow_pitch_time` | `true` / −22° / 1.1 秒 | 回到能看见前方路线的较浅倾角 |
| `follow_zoom` / `follow_zoom_level` / `follow_zoom_time` | `true` / 0.55 / 1.5 秒 | 移动时回到随附的初始缩放级别 |

这些角度、缩放和用时来自随附场景及演示设置。转向、倾角对齐和缩放对齐相互独立。如果希望玩家保留滚轮选择的缩放级别，就关闭 `follow_zoom`；如果希望滚轮继续以通常方式控制倾角，也关闭 `follow_pitch`。

在演示中，它们对应“相机”选项卡中的**相机随奔跑方向转动**、**奔跑时对齐相机倾角**和**奔跑时对齐相机高度**开关。它们的默认目标值已经与表格一致。

右键环绕优先于自动跟随。由于使用 WASD 需要按住右键，右键 + WASD 移动时相机不会自动转到后方。环绕后只松开右键不会结束等待：需要停下、点击新目的地或开始新的按住奔跑。保留场景中的 `run_requested → end_follow_wait` 连接和 `keep_aim_on_camera_turn = true`；否则相机可能一直等待，或相机移动会改变按住时光标引导的方向。

**验证：**横向穿过画面，转弯 90°，然后向相机方向掉头。第一次转弯应使相机来到路线后方；掉头时画面不应绕转。奔跑中手动环绕，松开右键：选定视角应保持到停下或开始新的奔跑。也请在墙附近重复这一过程，检查相机臂。

单独使用英雄时，下面的代码等同于启用这一配置。请在游戏场景的 `_ready()` 中，等英雄的子节点就绪后运行：

```gdscript
extends Node3D

@onready var hero: PlayableHero = $Hero


func _ready() -> void:
    hero.place_at($Spawn, false)
    var rig := hero.camera_rig
    rig.follow_movement = true
    rig.follow_time = 1.1
    rig.follow_toward_camera_angle = deg_to_rad(30.0)
    rig.sharp_turn_speed = deg_to_rad(360.0)
    rig.follow_wait_after_rotate = true
    rig.follow_pitch = true
    rig.follow_pitch_angle = deg_to_rad(-22.0)
    rig.follow_pitch_time = 1.1
    rig.follow_zoom = true
    rig.follow_zoom_level = 0.55
    rig.follow_zoom_time = 1.5
```

此示例假定英雄的移动和输入设置未经修改。在完整演示中，请改用设置菜单或 `Settings.set_value()`，使保存的设置与控件状态保持一致。

## 可选：悬浮的英雄

三种配置都可以使用现有的悬浮功能：设置 `Character/Visual/Hover.enabled = true`，或在演示中启用**角色 → 悬浮在地面上方**。保留 `height = 0.35 m`、`glide_time = 0.3 s` 和指定的 `player_floating_fall.tres`（下落重力系数 0.5，最大下落速度 2 米/秒）。

悬浮的是模型；碰撞身体仍会走下台阶并下落。此功能不能跨越缺口，也不能飞行。跳跃会上升到相同高度，然后更慢地下落。悬浮时不再触发脚步事件，而以 2 米/秒轻轻落地也低于默认的 2.5 米/秒落地事件阈值。身体的碰撞体不会随着模型升高而变大，因此请测试低矮天花板。模型和下落细节见[角色](systems/characters.md)与[移动](systems/locomotion.md)。

## 调整参数而不破坏配置

- **不同角色需要不同参数时，使用独立资源。** 在检查器中，编辑单个角色前先将移动器的设置资源设为唯一，并以新名称保存。移动器进入场景树前要指定另一个资源。运行时请修改现有资源的字段：在 `_ready()` 之后替换 `mover.settings`，不会替换 `GroundMotion` 已持有的资源。
- **速度与制动一起调整。** `acceleration_time` 和 `stop_time` 是以基础速度计算的用时。冲刺使用相同的加速度和制动力，因此速度为 1.5 倍时，停下也需要 1.5 倍时间：约 0.33 秒，而非 0.22 秒。理想直线制动距离在 5.5 米/秒时约 0.61 米，在 8.25 米/秒时约 1.36 米。边缘附近要留足空间。
- **让相机的急转判定与角色移动匹配。** 保持 `sharp_turn_speed` 不高于 `LocomotionSettings.turn_speed` 的一半。降低角色转向速率时，也要重新检查这个相机阈值。
- **让身体、防护和导航匹配。** 改变胶囊体尺寸、最大台阶高度或坡度限制后，须重新检查导航半径／高度／攀爬高度／坡度并重新烘焙。边缘防护的落差限制仍须允许角色走下预定台阶。物理层与导航层是两套独立设置。
- **每改一种行为，就重复对应验证。** 使用演示中的**角色路径线**和**角色状态和事件**面板，判断问题来自寻路、碰撞、输入还是相机。保留一份已保存的基线场景，避免凭记忆重建。

完整属性参考：[输入](systems/input.md)、[移动](systems/locomotion.md)和[相机](systems/camera.md)。

---

*本页对应 Iso & Orbit 1.2.0。*
