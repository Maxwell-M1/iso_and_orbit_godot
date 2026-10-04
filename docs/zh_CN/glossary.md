<!-- translation of docs/en/glossary.md @ baab36cb2064 -->
# 术语表

> 本文是[英文原文](../en/glossary.md)的翻译。两者不一致时，以英文版为准。

本文档和代码中所使用的术语。

| 术语 | 含义 |
|---|---|
| **代理半径（Agent radius）** | 导航网格与障碍物保持的距离：0.5 米，大于角色胶囊体的 0.35 米，因此路径与拐角保持一定余量 |
| **相机臂（Arm）** | `CameraArm`：在从目标引出的一条线的末端持有相机的节点。滚轮设置其长度；障碍物会使其缩短 |
| **仅阻挡相机的物体（Camera-only body）** | 位于物理层 3（`camera`）上的物体：它会阻挡相机臂，但点击、导航和角色都会忽略它 |
| **点击（Click）** | 在按住延迟内松开的一次左键按下。角色沿路径跑向按下按键时的位置 |
| **土狼时间（Coyote time）** | 走出边缘后的一小段时间，在此期间跳跃仍然有效（0.1 秒） |
| **力竭（Exhausted）** | 体力耗尽后的状态：在体力恢复到 `recover_ratio`（30%）之前不能冲刺 |
| **朝向（Facing）** | 角色面朝的方向，区别于它移动的方向。侧移或后退时两者不同。`NavigationMover.get_facing()` |
| **跟随（Follow）** | 相机自动转到奔跑中的角色身后，并可选地平滑调整倾角（`follow_movement`、`follow_pitch`） |
| **行进方向（Heading）** | 角色移动的方向。`NavigationMover.get_heading()` |
| **英雄外观（Hero look）** | 玩家角色可使用的十种模型之一，在设置中按编号选择（`CharacterAppearance`） |
| **按住（Hold）** | 左键按住的时间超过按住延迟。角色跟随光标奔跑 |
| **按住延迟（Hold delay）** | 区分点击与按住的时间：0.2 秒（`PointClickMoveInput.hold_delay`） |
| **跳跃缓冲（Jump buffer）** | 落地前不久按下的跳跃会被记住，并在落地时触发（0.12 秒） |
| **保持瞄准（Keeping the aim）** | 在按住按键且相机转动时，让系统光标随世界移动，使光标停留在地面上的同一位置（`keep_aim_on_camera_turn`） |
| **边缘防护（Ledge guard）** | `LedgeGuard`：在高于 0.5 米的落差处让角色停下，或让它沿边缘滑行 |
| **外观（Look）** | 见英雄外观 |
| **标记（Marker）** | `ClickMarker`：点击位置地面上的圆环 |
| **移动器（Mover）** | `NavigationMover`：每个物理帧把命令（`move_to`、`steer`、`stop`）转换为水平速度。它从不移动身体 |
| **导航网格（Navigation mesh）** | 根据关卡中第 1 层的碰撞烘焙出的可行走区域，存储在 `world.tscn` 中。路径在其上搜索 |
| **物理插值（Physics interpolation）** | 以显示帧率在物理帧之间绘制物体。默认开启；可通过设置关闭 |
| **俯仰角、倾角（Pitch, tilt）** | 相机向下看的陡峭程度。代码中为负角度，设置中为向下的度数 |
| **原地转身（Pivot）** | 静止时（低于 `pivot_speed`，即 1 米/秒）的瞬间转身 |
| **地点（Place）** | `PointOfInterest`：玩家首次进入时显示“发现地点：…”的区域 |
| **拉近（Pull-in）** | 相机移到遮挡角色的障碍物前方（`pull_in_on_occlusion`） |
| **侧移（Sidestep）** | 配合右键的一种按键模式：角色在向侧面或向后移动时，保持面朝相机所看方向 |
| **剪影（Silhouette）** | 角色被遮挡处绘制成的带描边的平面形状（`OccludedSilhouette`） |
| **冲刺（Sprint）** | 按住 Shift 或用 Shift 切换开启时更快地奔跑（×1.5），消耗体力 |
| **体力（Stamina）** | 冲刺储备（`Stamina`）：冲刺时消耗，停顿后恢复 |
| **方向操控（Steer）** | 不使用路径朝某方向奔跑：`NavigationMover.steer()`。默认情况下，按住按键会朝光标方向操控 |
| **物理帧（Tick）** | 一个物理步；每秒 60 个 |
| **转向模式（Turn mode）** | 配合右键的一种按键模式：角色转身面朝前进方向 |
| **偏航角（Yaw）** | 相机绕垂直轴的方向 |
| **缩放（Zoom）** | 取值从 0（最近）到 1（最远），同时决定相机的距离和倾角 |

---

*本页对应 Iso & Orbit 1.1.0。*
