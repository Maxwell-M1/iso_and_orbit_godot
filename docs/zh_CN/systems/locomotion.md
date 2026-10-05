<!-- translation of docs/en/systems/locomotion.md @ 78c912e8971a -->
# 移动

[← 文档目录](../index.md)

> 本文是[英文原文](../../en/systems/locomotion.md)的翻译。两者不一致时，以英文版为准。

角色如何奔跑、停下、转向、冲刺、跳跃、上台阶和避开落差。要使用装配好的英雄及其依赖文件，请先阅读[在你的项目中使用](../integration.md#将演示中的英雄迁移到你的项目)；现成的操控选择见[配置方案](../configurations.md)。工作由四个类分担：

| 类 | 类型 | 职责 |
|---|---|---|
| `LocomotionSettings` | Resource | 速度、加速、制动、转向 |
| `GroundMotion` | RefCounted | 数学部分：期望方向和剩余距离 → 水平速度 |
| `NavigationMover` | Node，身体的子节点 | 路径和命令；返回速度，从不移动身体 |
| `GroundCharacter` | CharacterBody3D | 重力、跳跃、冲刺、`move_and_slide()`、转动模型 |

身体还接入两个辅助组件：`Stamina`（冲刺储备）和 `LedgeGuard`（防止走下落差）。`FallSettings` 资源指定下落方式，`CharacterMonitor` 以文本显示身体报告的信息。`CharacterHover` 让模型悬浮，见[角色](characters.md#characterhover悬浮在地面上方)。

## 奔跑的手感

- **匀加速与匀减速。** 速度以固定速率变化，由 `acceleration_time` 和 `stop_time` 决定。
- **精确停止。** 接近目标时，速度被限制为 `√(2 · braking · distance left)`：角色恰好在还能停在该点的位置开始制动，绝不会冲过头。
- **新目标不会重置速度。** 制动中的新点击会保留当前速度；角色从该速度重新加速。
- **转向速率有限。** 奔跑中，方向以 `turn_speed` 转动。在方向尚未转到位时，`turn_slowdown` 会减掉一部分速度，因此急转弯是一段紧凑的弧线，而不是大幅度的漂移。
- **静止时瞬间转身。** 低于 `pivot_speed` 时，角色立即转向，因此朝任何方向起步都没有弧线和延迟。
- **必要时急刹。** 如果停止点被设在奔跑中的角色正前方很近处，角色的制动力度最多可达平时的 `max_braking_multiplier` 倍。

## LocomotionSettings

下表同时适用于 `LocomotionSettings` 的脚本默认值和随附的 `gdscript/player/player_locomotion.tres`。独立资源使演示设置可以只修改此英雄的冲刺与后退速度，不影响其他角色。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `max_speed` | 5.5 米/秒 | 奔跑速度 |
| `acceleration_time` | 0.18 秒 | 从静止加速到 `max_speed` 的用时 |
| `stop_time` | 0.22 秒 | 从 `max_speed` 制动到停止的用时；制动距离为 `max_speed × stop_time / 2`（约 0.61 米） |
| `turn_speed` | 720 °/秒 | 奔跑方向转动的速度。相机的 `sharp_turn_speed` 应不高于其一半（见[相机](camera.md#跟随模式)） |
| `turn_slowdown` | 0.75 | 方向追上目标前损失的速度：0 保持速度（大弧线），1 表示转向 90° 或以上时制动到零 |
| `pivot_speed` | 1 米/秒 | 低于此速度时角色瞬间转身 |
| `max_braking_multiplier` | 3 | 对于正前方很近的点，角色的制动力度最多可比平时大多少倍 |
| `sprint_speed_multiplier` | 1.5 | 冲刺时的基础速度倍数（默认 8.25 米/秒）；加速和制动保持不变 |
| `backward_speed_multiplier` | 0.7 | 后退（朝向与移动方向相反）时保留的速度比例 |

由于冲刺只提高速度上限，全速冲刺后的制动会花更长时间、走更远距离：以默认制动率从 8.25 米/秒停下约需 1.36 米，而从 5.5 米/秒停下约需 0.61 米。若点击的目标就在前方很近处，`max_braking_multiplier` 可使角色更快停下。

演示的 `SettingsApplier` 会在启动以及玩家调整设置时改变 `sprint_speed_multiplier` 和 `backward_speed_multiplier`；已保存设置可能覆盖上述值。插件本身不依赖设置系统。要调整运行中的演示，请打开“场景”面板 → 远程（Remote）→ `Hero/Character/NavigationMover` → `settings`。代码每帧读取资源字段，但远程检查器中的改动不会保存：请把确定的值写回 `.tres` 文件。运行时不希望角色之间相互影响，就为每个角色使用独立资源；应在移动器进入场景树前分配，或在编辑器中使用 **Make Unique（设为唯一）**。`_ready()` 后 `GroundMotion` 已持有原资源，此时替换 `mover.settings` 不会替换它正在使用的设置；运行时请编辑原资源的字段。

一个资源可以由多个角色共享，例如同一类的所有 NPC。

## NavigationMover

身体（任意 `Node3D`，通常是 `CharacterBody3D`）的子节点。两种模式：

- `move_to(point)`：沿导航路径绕过障碍物到达路径终点并精确停下。路径由身体所在世界的 `NavigationServer3D` 提供。路径结果为空时（包括世界中没有导航网格），移动器会直奔请求的目标点。
- `steer(direction, facing = Vector3.ZERO)`：不使用路径朝某方向移动，直到 `stop()`、`halt()` 或 `move_to()`。障碍物由身体沿其滑行来处理。指定 `facing` 时，角色在移动中朝向该方向，用于侧移和后退。`stop()` 后保持该朝向；`move_to()`、未指定朝向的 `steer()`、`halt()` 和 `face()` 会清除它。

身体每个物理帧在 `move_and_slide()` 前调用一次 `compute_velocity(delta)`。`stop()` 平滑制动，`halt()` 立即停止（例如传送时），`face(direction)` 则可使静止角色不奔跑就转向，例如在出生点：移动器的行进方向与朝向立即改变，`GroundCharacter` 的模型随后按 `visual_turn_speed` 转动（只有 `GroundCharacter.teleport(position, facing)` 也会立刻转动模型）。若正在奔跑，角色会重新朝向前进方向。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `settings` | — | `LocomotionSettings`；留空时，移动器在 `_ready()` 中按脚本默认值创建一个 |
| `use_navigation` | 开 | 搜索路径；关闭或世界中没有导航时：直接跑向该点 |
| `navigation_layers` | 1 | 路径可以使用的导航层 |
| `waypoint_radius` | 0.4 米 | 距离路径点小于此值时视为已经过该点；值越大，过弯时越早切角 |
| `arrive_distance` | 0.005 米 | 距终点小于此值时角色立即停下。制动本身就会把角色带到该点，因此该阈值很小 |
| `retarget_tolerance` | 0.1 米 | 与当前目标点距离小于此值的新点不会重建路径。按住按键时每个物理帧都会发送一个点 |
| `max_path_deviation` | 2 米 | 被推离路径超过此距离时，角色会获得一条新路径 |
| `sprinting` | 关 | 将速度上限乘以 `sprint_speed_multiplier`。何时开启由所属者决定；若使用 `GroundCharacter`，应改设其 `sprint_requested`，因为它每帧都会设置此值 |

信号：`destination_changed(point)`、`path_changed`、`arrived`、`destination_cancelled`。

`arrived` 表示到达路径终点。导航路径可能停在离请求目标最近的可达点，而非目标本身；如果游戏要求精确抵达，请自行比较位置。直线回退模式除了身体碰撞后的滑行，没有额外避障。

| 查询 | 返回值 |
|---|---|
| `is_moving()` | 角色正按命令前往某点或沿某方向移动。它反映命令而非实际运动：角色起步前仍站着时为真，`stop()` 后正在制动时为假 |
| `is_steering()` | 角色按 `steer()` 沿方向奔跑，而非前往目标点 |
| `has_destination()`、`get_destination()` | 是否正在前往 `move_to()` 指定的点（直到抵达或取消）；以及该点 |
| `get_speed()` | 奔跑速度，米/秒 |
| `get_heading()` | 奔跑指向的方向，水平单位向量；静止时为上次奔跑方向 |
| `get_facing()` | 角色应面朝的方向：沿行进方向（`get_heading()`），或 `steer()` 指定的方向 |
| `get_body()` | 受控身体，即移动器的父节点 |
| `get_remaining_path()` | 从下一个点开始的剩余路径点，位于导航网格高度；直线奔跑时为空 |

**路径点在水平面内比较。**Recast 导航网格悬在地面上方约两个单元格高度处（此处为 0.05 米）。若用三维距离与角色脚部比较，就会差出这么多，这也是移动器自行跟随路径、而不使用 `NavigationAgent3D` 的原因。

**后退更慢。** 当 `steer()` 收到 `facing` 时，速度按移动方向与朝向相反的程度缩放：正后方应用完整的 `backward_speed_multiplier`，斜后方应用其中一部分（侧移时 S + D：慢 21%），横向则不减速。因此减速只存在于按键的侧移模式中，见[输入](input.md)。

## GroundCharacter

这是身体移动的唯一位置。每个物理帧，它更新冲刺状态、从移动器取得水平速度、处理跳跃和重力、让 `LedgeGuard` 修正速度，调用 `move_and_slide()`（调用前走上台阶，调用后走下台阶），随后报告本帧变化：地面接触、经过的台阶、脚步、模型朝 `mover.get_facing()` 的转向和角色状态。

检查器（Inspector）对属性进行了分组：先是各部件和转向，然后是 Ground（地面）、Jump and fall（跳跃与下落）、Sprint（冲刺）和 Steps（脚步）。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `mover` | — | `NavigationMover`；必需 |
| `visual` | — | 相对身体转向角色前进方向的节点；其正面为 −Z |
| `visual_turn_speed` | 1080 °/秒 | 模型的转动速度 |
| `max_step_height` | 0.3 米 | 角色不用跳跃就能走上的最高台阶，也是它不离开地面就能走下的最深台阶。0 表示禁用迈步 |
| `ledge_guard` | — | 可选的 `LedgeGuard`；没有它时角色会从任何高度掉下 |
| `can_jump` | 开 | 允许跳跃；关闭时 `jump()` 不起作用 |
| `jump_height` | 1 米 | 跳跃最高点时脚部的高度 |
| `coyote_time` | 0.1 秒 | 走出边缘后的这段时间内跳跃仍然有效 |
| `jump_buffer_time` | 0.12 秒 | 在落地前这段时间内按下的跳跃会在落地时触发 |
| `gravity_scale` | 3 | 重力倍数：用于跳跃上升，下落时若 `fall` 未另行设置也使用它。角色跑得比真人快，按通常重力下落会显得发飘：1.6 米落差用时 0.33 秒而非 0.57 秒 |
| `fall` | — | 控制下落加速及最高速度的 `FallSettings`，见[下落](#下落)；留空时使用 `gravity_scale`，没有速度上限 |
| `landing_min_speed` | 2.5 米/秒 | 更慢的下落（小颠簸、坡道）只算 `touched_floor`，不算 `landed` |
| `can_sprint` | 开 | 允许冲刺。在奔跑中关闭时，多出的速度会被制动掉 |
| `stamina` | — | 可选的 `Stamina`；没有它时冲刺永不疲劳 |
| `sprint_tires` | 开 | 冲刺消耗体力 |
| `sprint_duration` | 5 秒 | 满储备可持续的时间：每秒消耗 `max_value / sprint_duration` |
| `steps_enabled` | 开 | 是否计步：影响 `stepped` 与步伐节奏；无腿角色可关闭。恢复计步后，第一步在 `first_step_distance` 之后到来 |
| `stride_length` | 1.5 米 | 地面上两步之间的距离 |
| `first_step_distance` | 0.3 米 | 从静止到第一步的距离 |

坡度上限是身体自身的 `floor_max_angle`（检查器中的 Floor → Max Angle，默认 45°）。更陡的表面对身体、台阶处理和边缘防护来说都同样是墙。向上方向固定为 +Y：`up_direction` 必须保持 `Vector3.UP`。

改变身体尺寸或关卡台阶时，须一起调整这些值：`max_step_height` 不低于台阶高度，`LedgeGuard.max_drop` 至少与它相等，导航网格的 `agent_max_climb` 设为希望通过的台阶高度。改变网格参数后重新烘焙。网格只负责规划路线；角色能否通过仍由胶囊体、坡度、天花板净空和碰撞几何体决定。若希望下台阶时发出 `stair_taken`，`floor_snap_length` 要短于 `max_step_height`。演示使用高 1.8 米、半径 0.35 米的胶囊体、0.3 米台阶、0.5 米受保护落差，以及最大攀爬 0.3 米、单元高度 0.025 米的导航网格；见[世界与导航](world-and-navigation.md#物理层与导航)。

身体可以在关卡中预先旋转，例如编辑器中转过的 NPC 或 `PlayableHero` 根节点：角色只相对身体转动 `visual`，最初面朝身体的 −Z，移动器也从那里取初始行进方向。以后可用 `teleport(position, facing)` 或 `NavigationMover.face()` 设定朝向。

组件可以暂时停止脚步计数，而不修改 `steps_enabled`：调用 `set_steps_suppressed(self, true)`，传入 `false` 则释放抑制（`CharacterHover` 在悬浮期间这样做）。只有 `steps_enabled` 开启且没有组件抑制时才计步（`is_counting_steps()`），因此游戏的开关与多个组件不会互相抵消。角色不会延长组件的生命周期：组件释放后，最迟下一帧就自动解除抑制。下落设置的覆盖也遵循此方式，见[下落](#下落)。

角色进入场景树时会打印配置警告，`get_setup_warnings()` 返回同一列表：移动器或边缘防护不是身体的子节点；`LedgeGuard.max_drop` 小于 `max_step_height`，会在角色本可走下的台阶前拦住它；地面吸附长度与台阶一样大，导致身体自行下台阶而没有 `stair_taken`；开启 `can_jump` 但 `jump_height` 或 `gravity_scale` 为 0，角色无法离地（这样的跳跃不会发出 `jumped`）；`fall.max_speed` 低于 `landing_min_speed`，下落永不会产生落地事件；`up_direction` 不是 +Y。`LedgeGuard` 与 `CharacterHover` 也会检查自身配置。

设置 `sprint_requested` 来请求冲刺，调用 `jump()` 来跳跃。`CharacterActionInput` 为玩家完成这两件事；AI 也可以这样做。

`teleport(position, facing)` 立即把角色放到别处，例如出生点或另一关卡。它让移动器立刻停止（`NavigationMover.halt()`）；跟随角色的对象不会看到跳动：速度、加速度和转向速率归零，物理帧之间的平滑从新位置重新开始（悬浮模型也会立即就位），之前缓冲的跳跃被忘记。指定 `facing` 时，角色和模型立刻朝该方向转动。体力保留，身体是否在地面的状态也保持原样，因此双脚应放在地面上。最后发出 `teleported`，供相机、拖尾等跟随者同步跳到新位置。测试中，角色以 5.5 米/秒奔跑时传送，会在同一帧于新位置站定，之后没有残余加速度或转动。

单独的角色传送不会处理玩家输入或相机。玩家英雄应调用 `PlayableHero.teleport()` 或 `place_at()`（见[关卡](levels.md#可操控的英雄)）：它们还会忘记正在按住的操作，并按需转动相机、使相机立即就位。若只调用 `GroundCharacter.teleport()`，应先调用 `PointClickMoveInput.cancel()`（仍按着的鼠标键下一帧会再次让角色奔跑），并将 `teleported` 连接到 `OrbitCameraRig.snap()`。

时间静止（`Engine.time_scale` 为 0）时，物理帧仍以零时间步运行，角色保持当前状态：位置、速度（`get_move_velocity()`）、状态和步伐节奏维持原值，加速度与转向速率为 0，悬浮模型和摆动的手部留在原位。时间恢复后，奔跑从原状态同步继续。测试中，步行及悬浮的英雄以 5.5 米/秒奔跑时可以原地保持，且随后正常继续。此时提供的输入仍能传给角色：冲刺键会改变奔跑角色的冲刺状态（`sprint_changed`），在地面按跳跃也会立即起跳（`jumped`）。如果希望一切状态都不改变，应暂时禁用操控（`PlayableHero.controls_enabled`）。

### 角色报告的信息

动画、特效、声音和界面不必根据速度去推断角色在做什么。瞬间发生的事情以信号发出；一直在变化的量则通过查询读取，每帧或每个物理帧读取一次。

| 信号 | 时机 |
|---|---|
| `state_changed(state, previous)` | 状态改变。在物理帧结束时，在该物理帧的其他信号之后 |
| `stepped(sprinting)` | 一只脚触地（`get_step_foot()` 指出是哪只脚）：在地面上每走过 `stride_length` 触发一次，从静止起步的第一次在 `first_step_distance` 处。脚步按距离而不是时间触发：奔跑时约每秒 3.7 步，冲刺时约 5.5 步，顶着墙站立或在空中时没有脚步 |
| `jumped` | 角色蹬离地面；同一物理帧内随后发出 `left_floor` |
| `left_floor` | 角色离开地面：通过跳跃或走出边缘。走下台阶不算 |
| `touched_floor(fall_speed)` | 在空中停留任意时间后回到地面；每个 `left_floor` 都对应一个。`fall_speed` 是接触瞬间的下落速度 |
| `landed(impact_speed)` | 速度达到 `landing_min_speed` 或更快的 `touched_floor`：真正的落地，而不是小颠簸 |
| `sprint_changed(sprinting)` | 冲刺开始或停止 |
| `stair_taken(height)` | 角色迈上或走下台阶：参数表示两处地面之间的真实高度，向上为正、向下为负（演示台阶为 ±0.2 米）。在帧末、`state_changed` 之前发出。若台阶矮到胶囊体自身可爬上（不超过 `radius × (1 − cos floor_max_angle)`，演示胶囊体约为 0.1 米），或地面吸附（`floor_snap_length`）足以使身体自行走下，则没有此信号 |
| `teleported` | `teleport()` 已将角色放到别处；相机、拖尾等跟随者应立即跳到那里，而非沿路移动 |

| 状态（`GroundCharacter.State`） | 时机 |
|---|---|
| `IDLE` | 在地面上，速度低于 `IDLE_SPEED`（0.1 米/秒），顶着墙奔跑时也是如此 |
| `RUNNING` | 在地面上，以任意速度移动，未冲刺 |
| `SPRINTING` | 在地面上，正在冲刺 |
| `JUMPING` | 跳跃后在空中，直到最高点 |
| `FALLING` | 在空中下降：跳跃越过最高点之后，或走出边缘之后 |

| 查询 | 返回值 |
|---|---|
| `get_state()` | 状态 |
| `get_move_velocity()`、`get_move_speed()` | 实际水平速度及其大小，单位为米/秒：身体真正走过的距离。与 `get_real_velocity()` 不同，它也计入走上台阶的移动；时间静止（`Engine.time_scale` 为 0）时仍保持原值 |
| `get_locomotion_blend()` | 用于一维混合：低于 `IDLE_SPEED` 时站立为 0，达到 `max_speed` 时为 1，全速冲刺时为 2，不受调整后的具体速度影响 |
| `get_local_movement()` | 用于二维混合：x 指向模型右侧（向左为负），y 指向前方（向后为负），向量长度即混合值。奔跑为 (0, 1)，冲刺为 (0, 2)，右侧移为 (1, 0)，左侧移为 (−1, 0)，前左斜向为 (−0.71, 0.71)，后退为 (0, −0.7) |
| `get_local_acceleration()` | 水平运动加速、制动或转向的快慢，单位米/秒²，采用上述相同的二维坐标轴：加速时 y > 0，制动时 y < 0，向左转时 x < 0。它根据驱动身体的速度计算，因此台阶不会使其突然跳变，撞墙的减速也不会体现在其中 |
| `get_turn_rate()` | 模型的转动速度，单位为弧度/秒：向左为正，向右为负 |
| `get_air_time()` | 在空中的秒数；在地面上为 0 |
| `get_step_phase()` | 以数字表示的已走步数：每一步时为整数，小数部分随两步之间的距离增长 |
| `get_gait_cycle()` | 两步构成的周期，从 0 到 1：左脚触地时为 0，右脚触地时为 0.5 |
| `get_step_foot()` | 最后一步的脚，`Foot.LEFT` 或 `Foot.RIGHT`。左右脚交替，停下之后也是如此 |
| `is_sprinting()`、`is_exhausted()`、`get_jump_speed()` | 当前是否在冲刺；是否力竭；跳跃的起跳速度 |
| `is_on_floor()`、`get_floor_angle()`、`velocity.y` | 来自 `CharacterBody3D` 本身：是否在地面上、脚下的坡度、垂直速度 |
| `get_ground_height(point, above, below)` | 某点下方角色可以站立的地面高度：从该点上方 `above` 米向下射到 `below` 米处，使用身体碰撞掩码；若那里没有这种地面，或射线从物体内部开始（墙高于 `above`），返回 NAN |
| `is_counting_steps()` | 当前是否计步：`steps_enabled` 已开启且没有组件抑制 |
| `get_fall_settings()` | 当前生效的下落设置：优先级最高的覆盖；相同优先级选最近指定的；否则使用 `fall`。若为 null，就使用 `gravity_scale` 且不限制速度 |

选择方式：

- **动画混合：**`get_locomotion_blend()` 可驱动在 0、1、2 处设置点的 `BlendSpace1D`；`get_local_movement()` 可驱动含侧移和后退的 `BlendSpace2D`。两者正是对应的输入值。
- **随速度变化的特效：**使用 `get_move_velocity()`，而非 `get_real_velocity()`。身体在 `move_and_slide()` 之后被放上台阶，每次上台阶时真实速度会骤降；时间静止时，真实速度还可能是零时间步上的 0 / 0，即 NaN。
- **惯性**（滞后的手持物、起步或转弯时倾斜的模型、斗篷）：`get_local_acceleration()`。
- **转弯时倾斜、原地转身：**`get_turn_rate()`。它是速率而非角度：只在模型转动时出现，逐帧可能波动，模型朝向就位后回到 0。使用前应平滑处理。
- **短暂下落或重摔：**`get_air_time()`。只在空中停留一瞬时可跳过下落动画，或按下落时间增强落地效果。
- **`touched_floor` 还是 `landed`：**`touched_floor` 结束任何离地状态，可据此切回地面动画；`landed` 只表示达到阈值的真正落地，可用于相机震动、落地声或下蹲。
- **脚印、扬尘或右脚音效：**在 `stepped` 处理器中调用 `get_step_foot()`。
- **台阶音效或迈步动画：**使用 `stair_taken(height)`；不应用它做平滑，因为身体此时已经在台阶上。
- **贴合台阶的双脚、悬在地面上方的模型：**使用 `get_ground_height()`。

**不计步时**（`is_counting_steps()` 为假），没有 `stepped`，`get_step_phase()`、`get_gait_cycle()` 和 `get_step_foot()` 停在上次的值，因此腿部动画此时不应依赖它们。角色仍照常奔跑、跳跃、上台阶。

`HandSway` 跟随步伐相位；动画也可以这样做。驱动 `AnimationTree` 的常见方式是每帧根据查询设置其混合，并根据信号切换状态机：

```gdscript
@export var character: GroundCharacter
@export var tree: AnimationTree


func _ready() -> void:
	character.state_changed.connect(_on_state_changed)
	character.landed.connect(func(_speed: float) -> void:
		tree.set("parameters/land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE))


func _process(_delta: float) -> void:
	# A BlendSpace1D with idle at 0, run at 1 and sprint at 2; for sidesteps, a BlendSpace2D and get_local_movement().
	tree.set("parameters/ground/blend_position", character.get_locomotion_blend())


func _on_state_changed(state: GroundCharacter.State, _previous: GroundCharacter.State) -> void:
	var in_air := state == GroundCharacter.State.JUMPING or state == GroundCharacter.State.FALLING
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	playback.travel("air" if in_air else "ground")
```

要让双脚与地面合拍，请按距离而不是按时间播放奔跑循环：把它的位置设为 `get_gait_cycle()` 乘以循环长度（使用 `TimeSeek` 节点，或用 `seek()` 控制一个暂停的 `AnimationPlayer`）。循环应以左脚触地开始。

### CharacterMonitor：以文本显示状态

一个 `Label`，显示 `GroundCharacter` 正在做什么以及最近的事件，用于调整动画，或作为调试叠加层。在演示中它是 `Hud/CharacterState/Monitor`，通过设置（F10）→ 界面 → **角色状态和事件**显示。文本只来自上面的信号和查询，因此这个脚本也是使用它们的一个示例。

```
Running
Speed 5.5 m/s · blend 1.00
Forward +1.00 · right +0.00
Turning +0°/s
On the ground · slope 0°
Step 38 · left foot · cycle 0.03
Stamina 100%

11.83 s  Jumping → Falling
12.08 s  touched the ground at 7.8 m/s
12.08 s  landing at 7.8 m/s
12.08 s  Falling → Running
12.35 s  step, right foot
12.62 s  step, left foot
```

各行含义：

1. `get_state()` 返回的状态。
2. 实际速度（`get_move_speed()`）和混合值。
3. 模型自身坐标轴下带正负号的移动值：前方 +1.00 表示全速奔跑，−0.70 表示后退；右侧 −1.00 表示向左侧移。
4. 模型转动速率，单位度/秒，向左为正。它是速率而非角度，只在模型转动时显示，朝向就位后回到 0。
5. 在地面上时显示脚下坡度；在空中时显示离地时间与竖向速度。
6. 步数、上一步用哪只脚以及步态周期；不计步时显示“No steps”。
7. 体力；角色无法冲刺时还显示“力竭”。

下面按时间从早到晚列出最近事件与开局以来的时间：带脚别的脚步、带高度的台阶、跳跃、起跳、带下落速度的触地和落地、冲刺及状态改变。面板可见时每帧重建文字；隐藏时不做这项工作，但仍记录事件（`log_events` 开启时也会打印）。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `character` | — | `GroundCharacter`；为空时使用父节点 |
| `history_size` | 6 | 在状态下方显示多少条最近的事件；0 表示只显示状态 |
| `log_events` | 关 | 同时把每个事件连同时间和角色名称打印到输出 |
| `include_steps` | 开 | 也显示和记录脚步及台阶：每秒会有好几步 |

方法：`get_text_now()`、`get_state_lines()`、`get_event_lines()`、`get_state_name(state, translated)`。这些短语都经过 `tr()`，因此面板使用界面语言；输出中的日志保持为英语。

### 台阶和斜坡

**斜坡**由 `move_and_slide()` 自己处理：身体能走上坡度不超过 `floor_max_angle` 的表面，遇到更陡的表面则停下。开启 `floor_constant_speed` 时（演示中的身体已开启），它在坡道上保持速度。

**台阶。**胶囊体本身只能爬上不超过 `radius × (1 − cos floor_max_angle)` 的台阶，对 0.35 米的胶囊体来说是 0.1 米。更高的台阶（不超过 `max_step_height`）由身体自行攀爬；改变 `max_step_height` 后也要检查导航设置：

- **向上。** 如果本物理帧的移动（向前多看 5 厘米）会撞上太陡、无法站立的东西，身体就尝试走台阶：向上 `max_step_height`（或天花板允许的高度），向前移动本物理帧的距离，再向下落到地面上。一条射线检查台阶顶部：那里必须是高出脚部不超过 `max_step_height` 的地面，因此 0.4 米的方块或陡坡不算台阶。身体被放到台阶上，`move_and_slide()` 只是让它在那里站稳。
- **向下。** 如果身体在本物理帧之前站在地面上，之后却在没有跳跃的情况下处于空中，并且其下方不超过 `max_step_height` 深处有地面，身体就会被放到那块地面上：没有 `left_floor`，也不会下落。
- 身体每迈上或走下一级台阶，都会发出 `stair_taken(height)`；这是起点地面到台阶地面的真实高度，演示中每级上行是 +0.2 米、下行是 −0.2 米。
- 胶囊体的圆形底部以一定角度搁在台阶边缘上，身体离边缘较远时，这个角度陡得无法站立。因此台阶上的落脚位置会向前稍远处搜索，每次前移 2 厘米：身体最终会停在比本物理帧本应到达的位置最多靠前几厘米处。

每级台阶大约要花一个物理帧滚过其边缘，此时水平速度降到约 70%（`get_move_speed()` 能看出这一点；`HandSway` 跟随 `get_local_acceleration()`，因此手中的法杖不会因此猛然摆动）。对于很长的楼梯，不可见的坡道碰撞体最为平滑。

身体会立刻上台阶：走上 0.2 米台阶时，单帧约升高 0.1 米，其余部分在胶囊体滚过边缘的后两三帧完成。物理插值会将变化分散到渲染帧，但画面中仍有短促的跳动。悬浮模型（`CharacterHover`）会平滑滑过台阶，相机的 `height_follow_time` 可平滑画面中的爬升（演示中为 0.15 秒，见[相机](camera.md#属性)）。

导航网格必须连接身体能爬上的地方：演示中 `agent_max_climb` 为 0.3 米，与 `max_step_height` 相同（见[世界与导航](world-and-navigation.md#物理层与导航)）。

### 跳跃

起跳速度为 `v = √(2·g·h)`。在起跳的物理帧中，身体获得 `v − g·dt/2` 的速度，不再施加其他重力；土狼时间内起跳也是如此。因此它每个物理帧的位置都恰好落在抛物线上，跳跃高度与物理帧率无关。若直接用 `v`，跳跃会高出 `v·dt/2`，每秒 60 物理帧时为 1.064 米而非 1 米。演示中 `gravity_scale` 为 3，1 米跳跃用时 0.52 秒。

在空中，角色保持原来的奔跑状态，操作方式不变。边缘防护不会拦住跳跃：从平台边缘跳下是有意的行为，而不是意外。

### 下落

跳跃越过顶点或走出边缘后，下落由 `FallSettings` 资源控制：使用角色自己的 `fall`，或组件临时覆盖的设置。跳跃上升过程不变：它按 `gravity_scale` 减速，因此无论下落设置如何，跳跃仍达到 `jump_height`。没有任何下落设置时，角色与以前一样：沿所在位置的重力方向，以重力乘 `gravity_scale` 下落，没有速度上限。有下落设置时，沿地面方向的重力（例如某个区域施加的）仍按原方式作用；如果该处重力根本不向下拉（上升气流），下落设置便无从发挥作用。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `gravity_scale` | 0 | 下落时的重力是世界重力的几倍，决定加速快慢。低于角色自身值时，下落比上升更慢。设为 0 沿用角色自己的 `gravity_scale`，因此新资源默认不会改变行为；只设置速度上限也保留原下落重力 |
| `max_speed` | 0 米/秒 | 最大下落速度：加速到此后保持该速度；0 表示无上限 |
| `braking_time` | 0.3 秒 | 已超过 `max_speed` 的下落在多长时间内消除约 95% 的超速部分：例如角色被向下抛出，或下落途中设置生效。0 表示立即减速 |

组件可暂时用自己的下落设置覆盖 `fall`：调用 `set_fall_override(self, settings, priority)`，传入 `null` 则撤销。多个组件同时覆盖时，最高优先级生效（默认 0）；优先级相同时，最后放入的生效；仅修改现有设置或优先级不会改变其先后顺序。角色自身的 `fall` 不会被改动，组件释放后又会生效。角色不延长组件生命周期：组件被释放就自动撤销。`get_fall_settings()` 返回当前生效的下落设置。`CharacterHover` 每次模型开始升起时以优先级 0 放入自己的 `fall`，见[角色](characters.md#下落)；即使悬浮此后重新开启，游戏以优先级 1 放入的缓降法术仍会优先。

`touched_floor` 和 `landed` 报告触地瞬间的速度。若下落速度上限低于 `landing_min_speed`，通常只有 `touched_floor`；只有角色被更快地抛下，并在减速前触地，才会发出 `landed`。如果角色自己的 `fall` 造成此情况，配置会发出警告：跳跃后永不会触发落地声和效果。悬浮角色则故意轻轻落地。上限恰好等于 `landing_min_speed` 时会产生落地事件。

演示英雄自身没有指定 `fall`。它的悬浮组件使用 `gdscript/player/player_floating_fall.tres`：重力系数为 0.5，而身体为 3；最大下落速度为 2 米/秒。因此悬浮英雄在 1 米跳跃后于空中停留 0.95 秒，而非 0.52 秒；触地速度为 2 米/秒，而非 7.8 米/秒。要在自己的身体中使用同一计算，可以调用 `FallSettings.get_next_speed(speed, acceleration, delta)` 和 `get_gravity_scale(own)`。

## 冲刺与体力

当请求了冲刺且角色正被驱动时（点击、按住按键、同时按住两键、按键），它以 `sprint_speed_multiplier` 倍的速度奔跑并消耗体力。按住 Shift 站着不动不消耗体力。储备耗尽后，角色进入力竭状态：以正常速度奔跑，直到体力恢复到 `recover_ratio`，此时若仍按住 Shift，会自动再次冲刺。

`Stamina` 不关心是什么在消耗它：

| 属性 | 默认值 | 含义 |
|---|---|---|
| `max_value` | 100 | 满储备 |
| `recovery_rate` | 每秒 12.5 | 从空到满需 8 秒 |
| `recovery_delay` | 1 秒 | 最后一次消耗后经过这段时间开始恢复 |
| `recover_ratio` | 0.3 | 力竭的角色恢复到这一比例后可以再次冲刺（1 + 2.4 秒） |

方法：`spend(amount)`、`can_spend()`、`get_ratio()`、`is_exhausted()`、`refill()`。信号：`changed(ratio)`、`exhausted_changed(exhausted)`。HUD 的 `StaminaBar` 监听这些信号。

## LedgeGuard

防止角色走下落差。身体在 `move_and_slide()` 之前调用 `constrain(velocity, delta)`。如果身体在本物理帧结束时会处于落差上方，移动方向会沿边缘转到最近的、下方有地面的方向，并按转角的余弦缩短，与沿墙滑行完全一样。正对边缘奔跑时，角色会停下。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `enabled` | 开 | 启用边缘防护 |
| `max_drop` | 0.5 米 | 深于此值的落差会被防护；较浅落差可能走过。只有不深于 `GroundCharacter.max_step_height` 的落差会作为台阶走下而不离地 |
| `edge_margin` | 0.15 米 | 角色中心离边缘最近可到多少 |
| `margin_probes` | 6 | 沿 `edge_margin` 圆周分布的射线数 |
| `probe_height` | 0.5 米 | 射线从脚部上方这一高度发出，以便找到略高于脚部的地面（坡道） |
| `floor_mask` | 0 | 哪些物体算地面；0 沿用身体的碰撞掩码，因此防护认为可站立的地面与身体一致 |
| `slide_iterations` | 6 | 滑行角度的二分次数；6 次约精确到 1.4° |

在开阔地面上，每个物理帧发出 7 条射线，在边缘处最多 98 条。在空中时边缘防护不起作用。从平台下来的路径沿坡道走，边缘防护不会妨碍它。地面必须是身体能站立的表面：坡度不超过 `floor_max_angle`，并采用与引擎地面检查相同的小幅裕量（`GroundCharacter.FLOOR_ANGLE_MARGIN`）。若 `floor_mask` 包含身体不会碰撞的层，配置会警告：防护会把身体直接穿过的物体误认作地面。

## 实测行为

`tests/movement_checks.gd`、`tests/character_actions_checks.gd` 和 `tests/character_state_checks.gd` 中的场景检查，以每秒 60 物理帧验证随附英雄：

- 默认速度 5.5 米/秒、加速用时 0.18 秒时，0.18 秒内达到 95% 的速度；从 95% 正常制动约需 0.20 秒。制动中重设目标会保留速度，反向点击会沿弧线掉头。
- 冲刺达到 8.25 米/秒。测试中将体力持续时间设为 2 秒，体力耗尽后恢复到阈值，仍持续按住的冲刺请求会自动再次生效。
- 1 米跳跃达到 1.000 米，在空中约停留 0.52 秒。落地前的缓冲按键会触发跳跃，刚走出边缘时也可在土狼时间内起跳。
- 演示的 0.2 米台阶可以双向通过而不离地；`stair_taken` 报告每一级。0.4 米方块和 50° 斜坡会挡住身体。边缘防护会在平台边缘阻止直奔，并让斜向奔跑沿边缘滑行。
- 使用悬浮组件的 0.5 倍下落重力和 2 米/秒上限时，跳跃高度仍是 1 米，但触地速度为 2 米/秒，低于默认的 2.5 米/秒落地阈值。上述结果取决于随附胶囊体、碰撞体、网格和设置；更改几何体或参数后请在自己的关卡中重新测试。

---

*本页对应 Iso & Orbit 1.2.0。*
