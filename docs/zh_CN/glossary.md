<!-- translation of docs/en/glossary.md @ 2c04d3857e30 -->
# 术语表

[← 文档目录](index.md)

> 本文是[英文原文](../en/glossary.md)的翻译。两者不一致时，以英文版为准。

本文档和代码中所使用的术语。

| 术语 | 含义 |
|---|---|
| **代理半径（Agent radius）** | 导航网格与障碍物保持的距离：0.5 米，大于角色胶囊体的 0.35 米，因此路径与拐角保持一定余量 |
| **相机臂（Arm）** | `CameraArm`：在从目标引出的一条线的末端持有相机的节点。滚轮设置其长度；障碍物会使其缩短 |
| **混合（Blend）** | `GroundCharacter.get_locomotion_blend()`：供动画使用的、以数字表示的速度，站立为 0，奔跑为 1，冲刺为 2 |
| **边界（Bounds）** | 第 4 物理层：关卡边缘的隐形墙。角色会与其碰撞，但点击和相机臂可以穿过 |
| **仅阻挡相机的物体（Camera-only body）** | 位于物理层 3（`camera`）上的物体：它会阻挡相机臂，但点击、导航和角色都会忽略它 |
| **角色状态（Character state）** | 角色在做什么：站立、奔跑、冲刺、跳跃或下落（`GroundCharacter.get_state()`，信号 `state_changed`） |
| **点击（Click）** | 在按住延迟内松开的一次左键按下。角色沿路径跑向按下按键时的位置 |
| **土狼时间（Coyote time）** | 走出边缘后的一小段时间，在此期间跳跃仍然有效（0.1 秒） |
| **力竭（Exhausted）** | 体力耗尽后的状态：在体力恢复到 `recover_ratio`（30%）之前不能冲刺 |
| **朝向（Facing）** | 角色面朝的方向，区别于它移动的方向。侧移或后退时两者不同。`NavigationMover.get_facing()` |
| **下落设置（Fall settings）** | 角色在跳跃顶点之后或走出边缘后如何下降：下落重力、最大下落速度，以及超速时如何减速（`FallSettings`）。跳跃上升阶段不受其影响 |
| **悬浮（Floating）** | 英雄的模型悬在地面上方并平滑滑过台阶，身体仍照常行走（`CharacterHover`）。悬浮角色没有脚步事件，演示中还会更慢地下落 |
| **跟随（Follow）** | 相机自动转到奔跑中的角色身后，并将倾角和缩放调整至设定值；各动作平滑启停（`follow_movement`、`follow_pitch`、`follow_zoom`）。环绕后可等待角色停下或开始新的奔跑（`follow_wait_after_rotate`，演示中开启） |
| **步态周期（Gait cycle）** | 左右两步，表示为从 0 到 1 的数字（`GroundCharacter.get_gait_cycle()`）。它跟随走过的距离，而不是时间 |
| **行进方向（Heading）** | 角色移动的方向。`NavigationMover.get_heading()` |
| **英雄外观（Hero look）** | 玩家角色可使用的十种模型之一，在设置中按编号选择（`CharacterAppearance`） |
| **按住（Hold）** | 左键按住的时间超过按住延迟。角色跟随光标奔跑 |
| **按住延迟（Hold delay）** | 区分点击与按住的时间：0.2 秒（`PointClickMoveInput.hold_delay`） |
| **跳跃缓冲（Jump buffer）** | 落地前不久按下的跳跃会被记住，并在落地时触发（0.12 秒） |
| **保持瞄准（Keeping the aim）** | 在按住按键且相机转动时，让系统光标随世界移动，使光标停留在地面上的同一位置（`keep_aim_on_camera_turn`） |
| **边缘防护（Ledge guard）** | `LedgeGuard`：在高于 0.5 米的落差处让角色停下，或让它沿边缘滑行 |
| **关卡容器（Level host）** | `LevelHost`：容纳当前关卡并在加载画面后方切换它的节点；英雄与界面是其兄弟节点，不属于关卡 |
| **加载画面（Loading screen）** | `LoadingScreen`：关卡更换期间盖在游戏上的画面，包含模糊的最后一帧、地名、进度条和提示 |
| **外观（Look）** | 见英雄外观 |
| **环顾四周（Looking around）** | 跟随光标持续奔跑时再按右键：鼠标只转动相机，奔跑保持路线（`look_around_while_held`）。若先按右键，它会引导角色朝相机方向奔跑 |
| **标记（Marker）** | `ClickMarker`：点击位置地面上的圆环 |
| **移动器（Mover）** | `NavigationMover`：每个物理帧把命令（`move_to`、`steer`、`stop`）转换为水平速度。它从不移动身体 |
| **导航网格（Navigation mesh）** | 根据关卡第 1 层的碰撞体烘焙的可行走区域（岛上还包括第 4 层的隐形墙），保存在各关卡场景中；路径在其上搜索 |
| **旅行提示（Offer to travel）** | `TravelPrompt`：英雄站在先询问玩家的传送门（如传送台）上时，屏幕上的按键及“传送至……”提示。按 E（`interact` 动作）或点击可旅行，走开后提示消失 |
| **物理插值（Physics interpolation）** | 以显示帧率在物理帧之间绘制物体。默认开启；可通过设置关闭 |
| **俯仰角、倾角（Pitch, tilt）** | 相机向下看的陡峭程度。代码中为负角度，设置中为向下的度数 |
| **原地转身（Pivot）** | 静止时（低于 `pivot_speed`，即 1 米/秒）的瞬间转身 |
| **地点（Place）** | `PointOfInterest`：玩家首次进入时显示“发现地点：…”的区域 |
| **可操控的英雄（Playable hero）** | `PlayableHero`（`playable_hero.tscn`）：包含输入、相机、点击标记和路径线的玩家英雄，应与关卡并列放在游戏场景中 |
| **传送门（Portal）** | `LevelPortal`：通往另一关卡的区域；演示中的传送台就是传送门 |
| **拉近（Pull-in）** | 相机移到遮挡角色的障碍物前方（`pull_in_on_occlusion`） |
| **急转（Sharp turn）** | 奔跑方向以高于 `OrbitCameraRig.sharp_turn_speed`（360°/秒）的速率改变，例如掉头；相机不会跟随经过的中间方向，而会在转向后接上新方向 |
| **游戏框架（Shell）** | 游戏运行期间持续存在的场景（带 `main.gd` 的 `main.tscn`）：包含关卡容器、英雄、界面和加载画面 |
| **侧移（Sidestep）** | 配合右键的一种按键模式：角色在向侧面或向后移动时，保持面朝相机所看方向 |
| **剪影（Silhouette）** | 角色被遮挡处绘制成的带描边的平面形状（`OccludedSilhouette`） |
| **出生点（Spawn point）** | `SpawnPoint`：按名称指定角色在关卡中出现的位置；每个关卡都有一个 `default` 出生点 |
| **冲刺（Sprint）** | 按住 Shift 或用 Shift 切换开启时更快地奔跑（×1.5），消耗体力 |
| **台阶高度（Stair height）** | 角色不用跳跃就能走上的最高台阶：0.3 米（`GroundCharacter.max_step_height`） |
| **体力（Stamina）** | 冲刺储备（`Stamina`）：冲刺时消耗，停顿后恢复 |
| **初始关卡（Start level）** | 编辑器中放在关卡容器下、游戏启动时加载的关卡：`shared/world/world.tscn`，即有栅栏的草地；岛上传送台显示它的名称“翠谷” |
| **方向操控（Steer）** | 不使用路径朝某方向奔跑：`NavigationMover.steer()`。默认情况下，按住按键会朝光标方向操控 |
| **传送（Teleport）** | 立即将角色放到别处，无须奔跑，也不会跳动：`GroundCharacter.teleport()`、`PlayableHero.teleport()` |
| **物理帧（Tick）** | 一个物理步；每秒 60 个 |
| **旅行者（Traveller）** | 可使用传送门的身体，位于传送门的 `traveller_group` 分组中（默认为 `player`） |
| **转向模式（Turn mode）** | 配合右键的一种按键模式：角色转身面朝前进方向 |
| **预热（Warm-up）** | 关卡容器在加载画面消失前，于其后方绘制新关卡的若干帧，使着色器完成编译、角色稳定下来（`LevelHost.warmup_frames`，默认 3） |
| **偏航角（Yaw）** | 相机绕垂直轴的方向 |
| **缩放（Zoom）** | 取值从 0（最近）到 1（最远），同时决定相机的距离和倾角 |

---

*本页对应 Iso & Orbit 1.2.0。*
