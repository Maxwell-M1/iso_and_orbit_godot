<!-- translation of docs/en/architecture.md @ 566cc270b5a0 -->
# 架构

> 本文是[英文原文](../en/architecture.md)的翻译。两者不一致时，以英文版为准。

演示只有一个场景：`gdscript/main.tscn`。每种行为都是一个只负责一件事的独立节点：组件读取自己的导出属性，对外提供方法和信号，并通过节点引用和信号连接与场景中的相邻节点相连。仅剩的几处查找都是可配置的：`DiscoveryToast` 按分组查找地点，`CharacterAppearance` 按导出的名称查找模型及其手部节点，`CharacterSounds` 的 `character` 属性为空时使用其父节点。

## 主场景

```
Main (Node3D)
├── World              shared/world/world.tscn：关卡及其导航网格、地点和 NPC
├── Player             gdscript/player/player.tscn：GroundCharacter，分组 "player"
│   ├── CollisionShape3D   胶囊体，半径 0.35 米，高 1.8 米
│   ├── Visual             转向角色前进的方向
│   │   └── Model          当前的英雄外观；它的 RightHand 握着法杖
│   ├── Silhouette         OccludedSilhouette：透过障碍物看到的英雄
│   ├── Appearance         CharacterAppearance：在运行时替换 Visual/Model
│   ├── RightHandSway      HandSway：随脚步摆动右手
│   ├── NavigationMover    路径与速度
│   ├── LedgeGuard         防止身体走下落差
│   ├── Stamina            冲刺体力储备
│   └── Sounds             CharacterSounds 和五个 AudioStreamPlayer3D
├── PlayerInput        PointClickMoveInput：鼠标和 WASD → Player/NavigationMover
├── PlayerActionInput  CharacterActionInput：Shift 和空格 → Player
├── CameraRig          OrbitCameraRig：跟随 Player，环绕和缩放
│   └── CameraArm      CameraArm：遇到障碍物时缩短
│       └── Camera3D
├── ClickMarker        点击位置地面上的圆环
├── PathView           NavigationPathView：调试用路径线，默认隐藏
├── Hud                操作提示和速度、FpsCounter、CharacterState、DiscoveryToast、StaminaBar
├── SettingsApplier    设置 → 节点属性（仅限演示）
└── UiRoot             游戏上层的窗口：设置窗口
```

`player.tscn` 只包含角色。输入节点位于 `main.tscn` 中，因此同一个角色场景也可以由其他东西驱动：AI、过场动画或网络对端。

## 数据流

```
鼠标、WASD  ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (路径或方向)        (加速、制动、
                                    ──stop()────────────►                      转向：纯数学)
                                                               ▲
                                                               │ compute_velocity(delta)
                                                               │ 返回水平速度
Shift, Space ──► CharacterActionInput ──sprint_requested──► GroundCharacter ──► LedgeGuard.constrain()
                                      ──jump()────────────►  (CharacterBody3D)  ──► move_and_slide()
                                                                   │
                信号：state_changed, stepped, jumped, left_floor, touched_floor, landed, sprint_changed
                                                                   ▼
                              CharacterSounds, HandSway, CharacterMonitor, 动画, 以及其他任何对象

鼠标 ──► OrbitCameraRig ──► CameraArm ──► Camera3D
         (跟随目标的插值位置、环绕、缩放、可选的跟随模式)
```

输入从不直接操作身体，它向 `NavigationMover` 发送命令。移动器也从不操作身体：身体请求时，它返回一个速度。相机和输入互不知晓。

## 一个物理帧

1. `CharacterActionInput` 在角色之前运行（`process_physics_priority = -1`）：它设置 `GroundCharacter.sprint_requested` 并调用 `jump()`，因此按键在同一个物理帧内就能传到身体。
2. `GroundCharacter._physics_process` 是身体移动的唯一位置：
   1. 判断角色是否冲刺（已请求、已允许、正在移动、未力竭），并消耗体力；
   2. 调用 `mover.compute_velocity(delta)`，取其 X 和 Z 作为水平速度；
   3. 如果缓冲了跳跃，且身体在地面上或刚离开地面（土狼时间），则开始跳跃；
   4. 在空中时加上重力乘以 `gravity_scale`；
   5. 除非角色正在跳跃，否则让 `LedgeGuard.constrain()` 将速度转为沿边缘方向；
   6. 调用 `move_and_slide()`，在它之前走上台阶，在它之后走下台阶（`max_step_height`）；
   7. 发出 `left_floor`、`touched_floor`、`landed` 和 `stepped`，将 `Visual` 转向 `mover.get_facing()`，如果状态发生了变化，再发出 `state_changed`。
3. `HandSway` 在身体之后运行（`process_physics_priority = 1`），根据身体的新状态移动手部。

`PointClickMoveInput._physics_process` 在一处决定由谁驱动角色：按住的鼠标按键，否则是配合右键的按键。它调用 `move_to()`、`steer()` 或 `stop()`。移动器保存最后一条命令，身体在下次调用 `compute_velocity()` 时取用。

每个渲染帧中，`OrbitCameraRig._process` 将相机支架放到目标的插值变换处，其子节点 `CameraArm` 紧接着更新。`PointClickMoveInput` 的 `process_priority = 1`，因此它在相机本帧就位之后才修正光标位置。

## 组件

可复用的组件位于 `addons/iso_orbit/`，每个可单独取用的部分一个文件夹。每个脚本都以其类名的蛇形命名（snake case）命名：`OrbitCameraRig` 对应 `addons/iso_orbit/orbit_camera/orbit_camera_rig.gd`。

| 插件 | 类 | 职责 |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`（Node3D） | 跟随目标，右键环绕，滚轮缩放，可选跟随奔跑方向转动 |
| | `CameraArm`（Node3D） | 在末端持有相机，遇到障碍物时缩短；近距离时淡化目标 |
| `click_to_move` | `LocomotionSettings`（Resource） | 速度、加速、制动和转向。一个资源可由多个角色共享 |
| | `GroundMotion`（RefCounted） | 不依赖节点的运动学：期望方向和剩余距离 → 水平速度 |
| | `NavigationMover`（Node） | `move_to()` 沿导航路径移动并精确停下，`steer()` 朝某方向移动，`stop()`；返回速度，从不移动身体 |
| | `PointClickMoveInput`（Node） | 鼠标和右键 + WASD → 移动器命令；隐藏光标并修正其瞄准 |
| | `ClickMarker`（Node3D） | 点击位置的标记（`click_marker.tscn`） |
| | `NavigationPathView`（MeshInstance3D） | 绘制移动器的剩余路径 |
| `ground_character` | `GroundCharacter`（CharacterBody3D） | 重力、跳跃、带体力的冲刺、台阶、`move_and_slide()`、转动模型；报告自身的状态、脚步、起跳和落地，供动画、声音和界面使用 |
| | `LedgeGuard`（Node） | 在落差处让身体停下，或让它沿边缘滑行 |
| | `Stamina`（Node） | 会消耗和恢复的储备值；不关心是什么在消耗它 |
| | `CharacterActionInput`（Node） | 冲刺和跳跃按键 → 角色 |
| | `CharacterSounds`（Node3D） | 根据角色的信号播放声音 |
| | `HandSway`（Node） | 随脚步摆动手部节点，起步、停下、转向和落地时带有惯性 |
| | `CharacterMonitor`（Label） | 以文本显示角色的状态和最近的事件；可以把事件记录到输出中 |
| | `CharacterAppearance`（Node） | 在运行时替换角色模型 |
| | `StaminaBar`（ProgressBar） | HUD 上的体力条（`stamina_bar.tscn`） |
| `occluded_silhouette` | `OccludedSilhouette`（Node） | 在角色被遮挡处将其绘制为剪影；其着色器和材质位于同一文件夹 |
| `points_of_interest` | `PointOfInterest`（Area3D） | 可发现的地点：玩家首次进入时发出 `discovered(title)` |
| | `DiscoveryToast`（Label） | 在屏幕上显示“发现地点：…”几秒钟（`discovery_toast.tscn`） |
| `ui_screens` | `UiRoot`（CanvasLayer） | 窗口栈：打开窗口、按 Esc 关闭最上层窗口、暂停、光标、键盘焦点 |
| | `UiScreen`（Control） | 窗口的基类：`initial_focus`、`close_requested` |
| | `FpsCounter`（Label） | 每秒帧数，暂停时也工作（`fps_counter.tscn`） |

`ground_character` 需要 `click_to_move`（身体驱动一个 `NavigationMover`）；其他插件除引擎外不需要任何东西。各插件对项目的要求：[在你的项目中使用](integration.md)。

`gdscript/` 中的演示将它们组装起来：

| 文件 | 职责 |
|---|---|
| `main.tscn` | 演示场景 |
| `player/player.tscn`、`player_locomotion.tres` | 英雄：带有全部部件的 `GroundCharacter`，及其奔跑设置 |
| `demo/hud.gd` | 操作提示和速度读数 |
| `demo/settings_applier.gd` | 将设置应用到演示的节点，“设置 → 属性”集中在一处 |
| `settings/game_settings.gd` | `GameSettings`，即 `Settings` 自动加载：默认值、`user://settings.cfg`、`changed` 信号；自行应用引擎设置 |
| `ui/ui_root.tscn` | 配置了设置窗口和 F10 的 `UiRoot` |
| `ui/settings/settings_screen.tscn`、`.gd` | 设置窗口 |
| `ui/settings/setting_*.gd` | `SettingCheckButton`、`SettingOptionButton`、`SettingSlider`、`SettingLanguageButton`：绑定到设置键的控件 |

每个系统都有自己的页面：[移动](systems/locomotion.md)、[相机](systems/camera.md)、[输入](systems/input.md)、[角色](systems/characters.md)、[音频](systems/audio.md)、[UI](systems/ui.md)、[世界与导航](systems/world-and-navigation.md)。

## 场景中建立的连接

节点引用是在 `main.tscn` 和 `player.tscn` 中设置的导出属性。`main.tscn` 中的信号连接：

| 信号 | 连接到 | 效果 |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | 标记出现在点击位置 |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | 按住取代了点击，标记淡出 |
| `Player/NavigationMover.arrived` | `ClickMarker.fade_out` | 角色到达了该点 |
| `Player/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | 该点被放弃 |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | 在判定按下是点击还是按住之前，相机不会自行转动 |

## 设置

`Settings` 自动加载（`GameSettings`）存储设置值并发出 `changed(key, value)`。它自行应用引擎层面的设置：全屏、帧率上限、V-Sync、物理插值、界面缩放、语言和音量。其余设置由 `gdscript/demo/settings_applier.gd` 应用，它将每个键映射到一个节点属性。组件本身从不读取设置，见[设置](settings.md)。

## 为什么这样构建

- **只有 `GroundCharacter` 移动身体。** 移动组件只返回速度，从不调用 `move_and_slide()`。重力、跳跃以及将来可能加入的击退都在同一处合并，不会相互冲突。
- **`GroundMotion` 是不依赖节点的纯数学。** 加速和制动是状态的纯函数：便于单独测试，也便于逐行移植到其他语言。
- **角色对鼠标一无所知。** 它之所以成为玩家角色，是因为主场景中的 `PlayerInput` 驱动着它的移动器。制作 NPC 时，实例化 `player.tscn`，去掉玩家专用的 `Silhouette` 和 `Appearance` 节点，然后在 AI 中调用 `NavigationMover.move_to()`。
- **相机是角色的兄弟节点，而不是子节点。** 它在 `_process` 中移动到目标的插值位置，自身不参与插值，因此开启物理插值（默认开启，设置 → 显示）后，在任何帧率下奔跑都很平滑。在跟随模式下，相机根据目标每个物理帧的移动计算其速度，因此任何 `Node3D` 都可以作为目标。
- **组件对设置一无所知。** `LedgeGuard`、`PointClickMoveInput`、`OrbitCameraRig` 等组件只读取自己的属性；只有 `settings_applier.gd` 和设置窗口与 `Settings` 自动加载通信。组件可以不带设置系统移植到其他项目。
- **窗口遵循 Godot 的惯例。** 布局只使用容器；外观来自项目主题及其类型变体，而不是每个节点上的覆盖项。窗口通过信号请求关闭，由 `UiRoot` 关闭它（调用沿树向下，信号沿树向上）。按键都是输入动作。窗口打开时设置键盘焦点，关闭时恢复。窗口打开期间游戏暂停（`UiRoot` 以 `PROCESS_MODE_ALWAYS` 运行），相机会释放已捕获的光标。

## 文件夹

| 文件夹 | 内容 |
|---|---|
| `addons/iso_orbit/` | 可复用的组件，每个部分一个文件夹 |
| `gdscript/` | GDScript 版演示：主场景、英雄、设置系统和设置窗口、HUD 提示 |
| `shared/` | 不依赖脚本语言的演示内容：关卡、角色和装备、世界着色器和纹理、声音、UI 主题 |
| `l10n/` | 界面翻译 |
| `tests/` | 无头测试，见[测试](testing.md) |
| `docs/` | 本文档 |

`shared/` 旨在供将来的 C# 版演示复用，C# 版会在 `gdscript/` 旁边拥有自己的文件夹。目前还有两个例外：`world.tscn` 和 `mountain.tscn` 使用了 `addons/iso_orbit/points_of_interest/point_of_interest.gd`，另有两个小型道具脚本（`flicker.gd`、`hover_spin.gd`）位于 `shared/world/props/`。见[已知问题](known-issues.md)。

---

*本页对应 Iso & Orbit 1.1.0。*
