<!-- translation of docs/en/systems/camera.md @ d5569844bc1c -->
# 相机

[← 文档目录](../index.md)

> 本文是[英文原文](../../en/systems/camera.md)的翻译。两者不一致时，以英文版为准。

`OrbitCameraRig` 跟随一个 `Node3D` 目标，允许用鼠标绕目标转动，并用滚轮同时改变距离与倾角。其子节点 `CameraArm` 沿局部 +Z 放置 `Camera3D`，防止相机进入附近的几何体。目标奔跑时自动转向、倾角对齐和缩放对齐是三个彼此独立的选项。

```text
PlayableHero (模板中固定不动的根节点)
├── Character (移动的目标)
└── CameraRig (OrbitCameraRig; target = ../Character)
    └── CameraArm (CameraArm)
        └── Camera3D (current = true)
```

把支架放在移动目标旁边，不要放在其内部：支架会自行设置全局位置和旋转。保持支架、相机臂、相机及其祖先节点的缩放为 `(1, 1, 1)`，使相机臂长度和碰撞半径有确定意义。支架每个渲染帧根据 `target.get_global_transform_interpolated()` 放置相机，并在 `_ready()` 中关闭自身的物理插值；子节点默认继承该模式。如果目标在物理帧中移动，请开启项目物理插值，否则目标会明显地逐帧跳动。模板已开启此设置。`height_follow_time` 可在插值之后平滑目标的竖向台阶移动。

`Camera3D` 的初始局部变换应保持默认值：相机臂负责设置其局部位置和旋转。模板将它设为 **Current（当前）**，视野角为 45°，远裁剪面为 300 个世界单位。如果稍后场景中出现另一个当前相机，当英雄应掌握视角时，请重新将此相机设为当前。如何复制相机或整个英雄见[集成指南](../integration.md#单独使用相机)，输入动作及物理层见[项目配置](../project-setup.md)。

## 当前生效的是哪组参数？

以下脚本参数是可复用组件的默认值。`gdscript/player/playable_hero.tscn` 覆盖其中少数参数；主场景启动后，演示的 `SettingsApplier` 再应用已保存的 `Settings` 值。复制来的英雄场景不需要演示设置窗口或自动加载，会使用场景中保存的值。

| 设置 | 脚本默认值 | 可操控英雄场景／全新演示 |
|---|---:|---:|
| 奔跑时转向、倾角、缩放对齐 | 全部关闭 | 全部关闭 |
| `follow_time` | 1.5 秒 | 1.1 秒 |
| `follow_pitch_angle`、`follow_pitch_time` | −40°、1.5 秒 | −22°、1.1 秒 |
| `follow_zoom_level`、`follow_zoom_time` | 0.55、1.5 秒 | 0.55、1.5 秒 |
| `follow_wait_after_rotate` | 关闭 | 开启 |
| `height_follow_time` | 0 秒 | 0.15 秒 |

转向、倾角和缩放各自的时间与目标值，只有对应跟随开关开启时才生效。`height_follow_time` 则始终平滑跟随目标的竖向移动，手动环绕模式也一样。演示中，以前保存在 `user://settings.cfg` 的选择可以覆盖全新默认值。`SettingsApplier` 将设置窗口中正值的“向下倾角”转换为负俯仰角，并将 0–100% 的“高度”转换为支架的 0–1 缩放级别。

长度和速度以 Godot 世界单位计量（若场景采用模板的 1 单位 = 1 米比例，也就是米）。标有 `radians_as_degrees` 的角度与角速度在检查器中以度显示，但 GDScript 赋值使用弧度：`follow_pitch_angle` 应写 `deg_to_rad(-22.0)`，`sharp_turn_speed` 应写 `deg_to_rad(360.0)`。`playable_hero.tscn` 中序列化的 `-0.383972...` 等于 −22°。

## 环绕、倾斜与缩放

按住 `camera_rotate`（模板中为右键）并移动鼠标即可环绕。光标会被捕获，松开后回到原先位置；失去焦点或暂停也会释放它。关闭 `mouse_pitch` 时，鼠标竖向移动不起作用，由滚轮选择倾角；开启后可用鼠标倾斜，`invert_pitch` 反转竖向。滚轮向上使相机降低，向下使其升高。平滑滚动可以按 `zoom_step` 的一部分移动。

缩放值从 0（近）到 1（远），默认滚轮步进为 0.1。相机臂长度在 `near_distance` 5 和 `far_distance` 20 个世界单位之间插值。距离近时倾角更浅，其曲线如下：

| 缩放 | 距离 | 基础倾角 |
|---:|---:|---:|
| 0 | 5 | −22° |
| 0.2（`flatten_end_zoom`） | 8 | −22° |
| 0.5（`flatten_start_zoom`） | 12.5 | −38.5° |
| 0.55（`start_zoom`） | 13.25 | −40.15° |
| 1 | 20 | −55° |

从缩放 0.5 降到 0.2 时，相机的倾角迅速变浅，更容易看清前方地面；低于 0.2 后只改变距离。鼠标倾斜和奔跑时倾角跟随会在曲线上叠加偏移，并受 `min_pitch`、`max_pitch`（−80°、−8°）约束。关闭 `mouse_pitch` 会清除鼠标的偏移，除非 `follow_pitch` 仍保持倾角。`rotation_sharpness` 和 `zoom_sharpness` 平滑鼠标与滚轮变化；设为 0 则相应输入立即生效。

## 跟随模式

可以任意组合开启 `follow_movement`、`follow_pitch` 和 `follow_zoom`，分别让相机转到奔跑方向后方、趋近指定倾角，以及趋近指定缩放级别。支架每个物理帧测量任意 `Node3D` 目标的水平移动，不依赖角色速度属性。低于 `follow_min_speed` 时不跟随；从该速度到其两倍之间，跟随力度平滑增加。目标停下后，下一次奔跑使用新的方向。

每种启用的运动都通过各自的弹簧平滑开始、平滑收敛。其用时大致表示满速奔跑中从静止完成 95% 变化所需的时间，前提是未触及转速上限；设为 0 表示立即变化。移动停止或跟随暂停时，进行中的运动会制动，不会生硬中断。`rotation_sharpness` 和 `zoom_sharpness` 决定此时制动的速率。跟随直接移动相机，输入平滑不会再额外叠加一次延迟。

| 属性 | 脚本默认值 | 效果 |
|---|---:|---|
| `follow_movement`、`follow_time` | 关、1.5 秒 | 转到水平奔跑方向后方；用时表示接近完成转向所需时间 |
| `follow_max_turn_speed` | 0 | 自动偏航的最大速度，单位 °/秒；0 表示无上限，包括立即转向 |
| `follow_toward_camera_angle` | 30° | 忽略与正对相机方向夹角不超过此值的奔跑；夹角达到两倍时转向力度完整。0 会取消此例外 |
| `sharp_turn_speed` | 360°/秒 | 急转或掉头时忽略经过的中间方向，之后接上新方向；0 关闭这一防护 |
| `teleport_speed` | 50 世界单位/秒 | 两次物理帧间的水平移动超过此速度时按传送处理，不视为奔跑 |
| `follow_pitch`、`follow_pitch_angle`、`follow_pitch_time` | 关、−40°、1.5 秒 | 让倾角趋近指定的向下角度，与偏航独立 |
| `follow_zoom`、`follow_zoom_level`、`follow_zoom_time` | 关、0.55、1.5 秒 | 让缩放趋近指定的 0–1 级别，与偏航和倾角独立 |
| `follow_min_speed` | 1 世界单位/秒 | 开始跟随的最小水平速度；到达其两倍时力度完整 |
| `follow_wait_after_rotate` | 关 | 鼠标环绕后保持所选视角，直到目标慢于 `follow_min_speed` 或报告新的奔跑 |

朝向相机的例外**只影响转向**。若开启倾角或缩放对齐，正对相机奔跑仍能改变倾角和缩放。急转防护也只影响转向：掉头期间倾角和缩放继续工作，已经开始的转向可能滑行到停止。模板英雄的 `LocomotionSettings.turn_speed` 为 720°/秒，360°/秒的急转阈值会捕获掉头，同时允许较缓的弧线。修改角色转向速度时，保持 `sharp_turn_speed` 不高于其一半；若正阈值达到角色转向速度，`PlayableHero` 会警告。将 `follow_toward_camera_angle` 设为 0，则明确允许相机绕到朝它奔跑的角色身后。

同时开启倾角和缩放对齐时，缩放改变距离，倾角对齐会补偿缩放曲线的变化。画面分别收敛到 `follow_pitch_angle` 和 `follow_zoom_level`。奔跑中滚轮和鼠标仍可使用；启用的跟随运动会再把画面带回其目标。`height_follow_time` 与之独立：它平滑支架对目标**世界 Y 坐标**的跟随，尤其用于台阶，不改变缩放级别。设为 0 时精确跟踪目标高度；英雄场景中的 0.15 秒表示约在此时间内完成竖向变化的 95%。

### 跟随何时暂停

按住右键时，三种跟随运动都会停止拉动。开启 `follow_wait_after_rotate` 后，持续至少 0.2 秒或鼠标移动至少 2 像素的一次环绕结束时，会在本次奔跑继续期间保持选定视角。如果松开右键之前失去焦点或游戏暂停，也一样；短促的点击不会开始等待。关闭此选项时，环绕结束就恢复跟随。等待在以下情况结束：移动速度降到 `follow_min_speed` 以下、`end_follow_wait()` 报告新的奔跑、调用 `snap()`、目标改变，或一次移动超过 `teleport_speed`。旧奔跑尚未停下就可能开始新奔跑，因此使用此选项时请将输入的 `run_requested` 信号连接到 `end_follow_wait()`。若目标持续移动而游戏无法报告新奔跑，相机可能无限期等待；此时请关闭等待选项。

`playable_hero.tscn` 还将 `PointClickMoveInput.hold_pending_changed` 连接到 `set_follow_paused()`。左键按下的最初 0.2 秒，输入尚在判断点击还是按住，此连接会暂停跟随。`run_requested` 则会在新点击、新按住或右键 + 方向键开始行走时结束环绕后的等待。持续按住左键奔跑时按右键可用于环顾四周；右键松开后，那段奔跑并不算新奔跑，因此相机会保持玩家选定的视角，直到之后停下或开始新的奔跑。输入的 `keep_aim_on_camera_turn` 会在相机移动时使光标继续瞄准同一世界位置，避免奔跑方向追着相机转。

当 `Engine.time_scale` 为 0 时，跟随运动保持当前状态，时间继续后再恢复。如果手动移动目标，或短距离传送未触发 `teleport_speed` 检查，请调用 `snap()`，使相机及相机臂立即就位并重置运动历史。

## 属性

| 分类 | 属性 | 脚本默认值 | 含义 |
|---|---|---:|---|
| 目标 | `target` | 无 | 要跟随的 `Node3D` |
| 目标 | `arm`、`camera` | 无 | 未指定时选取第一个类型匹配的直接子节点；只有没有相机臂时才单独使用 `camera` |
| 输入 | `rotate_action`、`zoom_in_action`、`zoom_out_action` | `camera_rotate`、`camera_zoom_in`、`camera_zoom_out` | 输入映射动作；缺少时启动会报错 |
| 输入 | `mouse_sensitivity`、`mouse_pitch`、`invert_pitch`、`zoom_step` | 0.25 °/像素、关、关、0.1 | 鼠标环绕速率、鼠标倾角控制、滚轮增量 |
| 取景 | `focus_height` | 1.2 世界单位 | 目标原点上方的瞄准位置 |
| 取景 | `near_distance`、`far_distance` | 5、20 | 缩放为 0 和 1 时的相机臂长度 |
| 取景 | `near_pitch`、`far_pitch` | −22°、−55° | 缩放为 0 和 1 时的基础倾角 |
| 取景 | `flatten_start_zoom`、`flatten_end_zoom` | 0.5、0.2 | 倾角更快变浅的缩放区间 |
| 取景 | `min_pitch`、`max_pitch` | −80°、−8° | 最终倾角限制，包括鼠标和跟随的偏移 |
| 取景 | `start_zoom`、`start_yaw` | 0.55、45° | 初始缩放和相对世界坐标轴的偏航；之后可用 `look_along()` 改变偏航 |
| 平滑 | `rotation_sharpness`、`zoom_sharpness` | 30、10 | 值越高，越快达到鼠标／滚轮目标；0 为立即变化 |
| 平滑 | `height_follow_time` | 0 秒 | 跟随目标竖向位置完成约 95% 变化的用时；0 为精确跟踪 |

`look_along(direction)` 会立即让视角沿**世界空间**方向的水平分量观察，并停止正在进行的自动转向。`snap()` 会立即应用当前偏航、倾角、缩放、目标位置和相机臂的碰撞响应；传送后应调用它。`get_zoom()` 返回当前 0–1 缩放值。`is_rotating()`、`is_follow_paused()`、`is_follow_waiting()` 和 `is_target_turning_sharply()` 报告相应状态。`set_follow_paused(paused)` 与 `end_follow_wait()` 控制上文所述暂停。

支架需要相机臂或相机子节点（也可以显式设置 `arm`／`camera` 属性）；调试构建中缺少时会触发断言。它设置全局旋转，因此即使固定的英雄根节点本身被旋转，`start_yaw`、`look_along()` 和自动转向仍使用世界坐标轴。

## 障碍物、遮挡与淡化

`CameraArm` 通常启用 `keep_out_of_geometry`：理想相机位置上的球体必须容得下，且不与物理身体相交。如果墙、坡面或屋顶占据该位置，相机臂会立即缩短。目标与相机之间虽然有栅栏，但栅栏后方仍有足够空间时，相机臂不会缩短。若希望目标被栅栏遮挡时，相机主动移到栅栏前方，请开启 `pull_in_on_occlusion`；相机臂会等待持续遮挡，且至少剩余 `min_pull_in_length` 才会拉近。视线恢复后稍作等待，再平滑退回。若返回路线有障碍物，会跳过它，而不是穿过它。

### 相机臂如何区分障碍物后方有空间与身处物体内部

相机臂先检查理想终点处的相机球体能否放入。如果目标与相机之间有栅栏，但终点空旷，相机便能留在栅栏后方。如果终点接触或位于物体内部，相机臂就寻找更靠近目标的空位。Jolt 形状投射不会报告投射起点已经接触或进入的物体，所以相机臂会单独检查起点空间；两个物体紧挨着时，从更靠近目标的位置开始搜索。这也能防止相机进入后方紧贴悬崖的栅栏。

球体和可见性射线都使用 `collision_mask`（二进制 `0b101`，即第 1 和第 3 层）。模板中，第 1 层是实体世界几何体，第 3 层是 `RoofCameraBlocker` 等仅挡相机的几何体；第 2 层的角色和第 4 层的隐形角色边界不会移动相机臂。位于 `camera_ignore` 分组中的身体，或该分组节点下的身体，会被忽略。将此分组放在道具根节点上，即可影响每个实例。复制到其他项目时，掩码编号很重要；层名称只是标签。关闭 `keep_out_of_geometry` 后，不论是否开启遮挡拉近，相机臂都不再防止相机进入其后方几何体。

默认的五个 `occlusion_points` 会采样目标胸部、头部、膝盖和两侧。坐标相对于**相机臂起点**；支架将起点放在目标原点上方 `focus_height` 处。x 是相机右侧，y 向上，z 水平指向相机。`occlusion_share = 0.75` 表示五个点至少要有四个被遮挡。较高或悬浮的模型需要调整采样点和 `focus_height`。模板的 `CharacterHover` 可将可见模型抬高到身体上方 0.35 个世界单位。

`fade_target` 可选。指定后，相机臂短于 `fade_start_length` 时，会调整目标下各 `GeometryInstance3D` 的 `transparency`；达到 `fade_end_length` 时为 `fade_transparency`。英雄将 `Character/Visual` 指定为淡化目标。这种近距离淡化不同于可选的 `OccludedSilhouette` 插件：后者让角色透过障碍物显示。

| 属性 | 脚本默认值 | 含义 |
|---|---:|---|
| `length`、`camera` | 10、无 | 理想相机臂长度（通常由支架设置），以及未指定时找到的第一个直接 `Camera3D` 子节点 |
| `keep_out_of_geometry`、`probe_radius` | 开、0.3 | 让相机球体留在掩码内各身体之外 |
| `collision_mask`、`ignored_groups` | 第 1 + 第 3 层、`camera_ignore` | 碰撞与遮挡检查考虑的身体，以及要排除的分组 |
| `pull_in_on_occlusion`、`min_pull_in_length`、`pull_in_sharpness` | 关、2.5、10 | 拉近开关、最短长度和接近速率（0 表示立即） |
| `occlusion_points`、`occlusion_share`、`occlusion_delay` | 五个点、0.75、0.25 秒 | 可见性采样、遮挡比例、开始拉近或退回前的延迟 |
| `return_delay`、`return_sharpness` | 0.3 秒、4 | 相机臂伸长前的等待与伸长速度（平滑度为 0 表示等待后立即伸长） |
| `fade_target`、`fade_start_length`、`fade_end_length`、`fade_transparency` | 无、1.5、0.7、0.75 | 可选的模型淡化；相机臂长度不超过 0.7 时达到完整淡化值 |
| `debug_draw` | 关 | 绘制理想／实际相机臂长度、相机球体和可见性射线；可从另一台相机观察 |

`CameraArm.snap()` 会重新计算碰撞并立即放置相机，不等待返回延迟。`get_current_length()` 给出受障碍物影响后的实际长度；`is_pulled_in_by_occlusion()` 表示目标遮挡是否正使相机臂拉近。

上述行为由 [`tests/camera_checks.gd`](../../../tests/camera_checks.gd) 和 [`tests/camera_arm_checks.gd`](../../../tests/camera_arm_checks.gd) 验证：涵盖跟随用时、朝相机与急转防护、鼠标环绕后的等待、倾角／缩放对齐、台阶竖向平滑、避障、可选拉近、忽略分组和淡化。

---

*本页对应 Iso & Orbit 1.2.0。*
