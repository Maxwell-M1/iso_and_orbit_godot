<!-- translation of docs/en/systems/locomotion.md @ 1ec8642147fb -->
# 移动

> 本文是[英文原文](../../en/systems/locomotion.md)的翻译。两者不一致时，以英文版为准。

角色如何奔跑、停下、转向、冲刺、跳跃以及避开落差。共四个类，自底向上：

| 类 | 类型 | 职责 |
|---|---|---|
| `LocomotionSettings` | Resource | 速度、加速、制动、转向 |
| `GroundMotion` | RefCounted | 数学部分：期望方向和剩余距离 → 水平速度 |
| `NavigationMover` | Node，身体的子节点 | 路径和命令；返回速度，从不移动身体 |
| `GroundCharacter` | CharacterBody3D | 重力、跳跃、冲刺、`move_and_slide()`、转动模型 |

身体还接入两个辅助组件：`Stamina`（冲刺储备）和 `LedgeGuard`（防止走下落差）。

## 奔跑的手感

- **匀加速与匀减速。** 速度以固定速率变化，由 `acceleration_time` 和 `stop_time` 决定。
- **精确停止。** 接近目标时，速度被限制为 `√(2 · braking · distance left)`：角色恰好在还能停在该点的位置开始制动，绝不会冲过头。
- **新目标不会重置速度。** 制动中的新点击会保留当前速度；角色从该速度重新加速。
- **转向速率有限。** 奔跑中，方向以 `turn_speed` 转动。在方向尚未转到位时，`turn_slowdown` 会减掉一部分速度，因此急转弯是一段紧凑的弧线，而不是大幅度的漂移。
- **静止时瞬间转身。** 低于 `pivot_speed` 时，角色立即转向，因此朝任何方向起步都没有弧线和延迟。
- **必要时急刹。** 如果停止点被设在奔跑中的角色正前方很近处，角色的制动力度最多可达平时的 `max_braking_multiplier` 倍。

## LocomotionSettings

演示使用 `gdscript/player/player_locomotion.tres`。它修改了脚本默认值中的两项。

| 属性 | 演示 | 脚本默认值 | 含义 |
|---|---|---|---|
| `max_speed` | 5.5 米/秒 | 5.5 米/秒 | 奔跑速度 |
| `acceleration_time` | 0.35 秒 | 0.18 秒 | 从静止到 `max_speed` 的时间 |
| `stop_time` | 0.4 秒 | 0.22 秒 | 从 `max_speed` 到停止的时间；制动距离为 `max_speed × stop_time / 2`（演示中为 1.1 米） |
| `turn_speed` | 720 °/秒 | 720 °/秒 | 奔跑方向的转动速度 |
| `turn_slowdown` | 0.75 | 0.75 | 方向转到位前损失的速度：0 保持速度（大弧线），1 表示转向 90° 或以上时制动到零 |
| `pivot_speed` | 1 米/秒 | 1 米/秒 | 低于此速度时角色瞬间转身 |
| `max_braking_multiplier` | 3 | 3 | 对于正前方很近的点，角色的制动力度最多可比平时大多少倍 |
| `sprint_speed_multiplier` | 1.5 | 1.5 | 冲刺时的速度上限倍数（8.25 米/秒）；加速和制动保持不变 |
| `backward_speed_multiplier` | 0.7 | 0.7 | 后退（朝向与移动方向相反）时保留的速度比例 |

设置窗口会在运行时修改 `sprint_speed_multiplier` 和 `backward_speed_multiplier`。其余属性在资源中调整。要在游戏运行时调整：场景面板（Scene）→ 远程（Remote）→ `Player/NavigationMover` → `settings`。代码每个物理帧都会读取这些值，但在那里所做的修改不会被保存，因此请把结果复制到 `.tres` 文件中。

一个资源可以由多个角色共享，例如同一类的所有 NPC。

## NavigationMover

身体（任意 `Node3D`，通常是 `CharacterBody3D`）的子节点。两种模式：

- `move_to(point)`：沿导航路径绕过障碍物前往某点，并精确停下。路径来自身体所在世界的 `NavigationServer3D`。没有导航地图时，角色直接朝该点跑。
- `steer(direction, facing = Vector3.ZERO)`：不使用路径朝某方向移动，直到 `stop()`、`halt()` 或 `move_to()`。障碍物由身体沿其滑行来处理。指定 `facing` 时，角色在移动中朝向该方向：用于侧移和后退。停下后朝向保持不变，直到收到不指定朝向的命令。

身体在每个物理帧调用一次 `compute_velocity(delta)`，在 `move_and_slide()` 之前。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `settings` | — | `LocomotionSettings`；为空时使用默认值 |
| `use_navigation` | 开 | 搜索路径；关闭或世界中没有导航时：直接跑向该点 |
| `navigation_layers` | 1 | 路径可以使用的导航层 |
| `waypoint_radius` | 0.4 米 | 距离路径点小于此值时视为已经过该点；值越大，过弯时越早切角 |
| `arrive_distance` | 0.005 米 | 距终点小于此值时角色立即停下。制动本身就会把角色带到该点，因此该阈值很小 |
| `retarget_tolerance` | 0.1 米 | 与当前目标点距离小于此值的新点不会重建路径。按住按键时每个物理帧都会发送一个点 |
| `max_path_deviation` | 2 米 | 被推离路径超过此距离时，角色会获得一条新路径 |
| `sprinting` | 关 | 将速度上限乘以 `sprint_speed_multiplier`。何时开启由所属者决定 |

信号：`destination_changed(point)`、`path_changed`、`arrived`、`destination_cancelled`。

**路径点在水平面内比较。** Recast 导航网格悬浮在地面上方约两个单元格高度处（这里为 0.05 米）。若用三维距离与角色脚部比较，就会差出这么多，这就是移动器自行跟随路径、而不使用 `NavigationAgent3D` 的原因。

**后退更慢。** 当 `steer()` 收到 `facing` 时，速度按移动方向与朝向相反的程度缩放：正后方应用完整的 `backward_speed_multiplier`，斜后方应用其中一部分（侧移时 S + D：慢 21%），横向则不减速。因此减速只存在于按键的侧移模式中，见[输入](input.md)。

## GroundCharacter

身体移动的唯一位置。在每个物理帧中，它更新冲刺状态，从移动器获取水平速度，处理跳跃和重力，让 `LedgeGuard` 修正速度，调用 `move_and_slide()`，报告脚步和落地，并将 `visual` 转向 `mover.get_facing()`。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `mover` | — | `NavigationMover`；必需 |
| `visual` | — | 转向角色前进方向的节点；其正面为 −Z |
| `visual_turn_speed` | 1080 °/秒 | 模型的转动速度 |
| `gravity_scale` | 3 | 重力倍数。角色跑得比真人快，在正常重力下下落会显得发飘：1.6 米的下落用时 0.33 秒，而不是 0.57 秒 |
| `ledge_guard` | — | 可选的 `LedgeGuard`；没有它时角色会从任何高度掉下 |
| `can_sprint` | 开 | 允许冲刺。在奔跑中关闭时，多出的速度会被制动掉 |
| `stamina` | — | 可选的 `Stamina`；没有它时冲刺永不疲劳 |
| `sprint_tires` | 开 | 冲刺消耗体力 |
| `sprint_duration` | 5 秒 | 满储备可持续的时间：每秒消耗 `max_value / sprint_duration` |
| `can_jump` | 开 | 允许跳跃；关闭时 `jump()` 不起作用 |
| `jump_height` | 1 米 | 跳跃最高点时脚部的高度 |
| `coyote_time` | 0.1 秒 | 走出边缘后的这段时间内跳跃仍然有效 |
| `jump_buffer_time` | 0.12 秒 | 在落地前这段时间内按下的跳跃会在落地时触发 |
| `landing_min_speed` | 2.5 米/秒 | 低于此速度的下落（走下台阶、坡道）不算落地 |
| `stride_length` | 1.5 米 | 地面上两步之间的距离 |
| `first_step_distance` | 0.3 米 | 从静止到第一步的距离 |

设置 `sprint_requested` 来请求冲刺，调用 `jump()` 来跳跃。`CharacterActionInput` 为玩家完成这两件事；AI 也可以这样做。

### 信号

| 信号 | 时机 |
|---|---|
| `stepped(sprinting)` | 一只脚触地：在地面上每走过 `stride_length` 触发一次，从静止起步的第一次在 `first_step_distance` 处。脚步按距离而不是时间触发：奔跑时约每秒 3.7 步，冲刺时约 5.5 步，顶着墙站立或在空中时没有脚步 |
| `jumped` | 角色蹬离地面 |
| `landed(impact_speed)` | 角色落地；`impact_speed` 是下落速度，单位为米/秒 |
| `sprint_changed(sprinting)` | 冲刺开始或停止 |

`get_step_phase()` 以已走步数的形式返回步伐节奏：每一步时为整数，两步之间小数部分随距离从 0 增长到 1。`HandSway` 使用它；动画也可以使用。其他查询：`is_sprinting()`、`is_exhausted()`、`get_jump_speed()`。

### 跳跃

起跳速度为 `v = √(2·g·h)`。在起跳的物理帧中，身体获得的速度是 `v − g·dt/2`：这样它在每个物理帧的位置都恰好落在抛物线上，跳跃高度与物理帧率无关。如果直接用 `v`，跳跃会高出 `v·dt/2`，在每秒 60 物理帧时为 1.064 米而不是 1 米。在演示中，`gravity_scale` 为 3 时，1 米的跳跃用时 0.52 秒。

在空中，角色保持原来的奔跑状态，操作方式不变。边缘防护不会拦住跳跃：从平台边缘跳下是有意的行为，而不是意外。

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
| `max_drop` | 0.5 米 | 低于此值的落差算台阶，可以走下；更高的视为悬崖边缘 |
| `edge_margin` | 0.15 米 | 角色中心离边缘最近可到多少 |
| `margin_probes` | 6 | 沿 `edge_margin` 圆周分布的射线数 |
| `probe_height` | 0.5 米 | 射线从脚部上方这一高度发出，以便找到略高于脚部的地面（坡道） |
| `floor_mask` | 第 1 层 | 哪些物体算作地面 |
| `slide_iterations` | 6 | 滑行角度的二分次数；6 次约精确到 1.4° |

在开阔地面上，每个物理帧发出 7 条射线，在边缘处最多 98 条。在空中时边缘防护不起作用。从平台下来的路径沿坡道走，边缘防护不会妨碍它。

## 实测行为

测试（`tests/movement_checks.gd`、`tests/character_actions_checks.gd`、`tests/camera_checks.gd`）以每秒 60 物理帧测量演示的设置。测试的限值根据设置计算，因此你可以修改这些设置。

- 0.33 秒达到全速的 95%；从 95% 到停止用时 0.35 秒；精确停在点击的位置。
- 制动中在更远处再次点击：速度从 2.66 米/秒立即重新增加，从不降到零。
- 全速时在角色身后点击：角色继续前冲 0.34 米，弧线向侧面偏出 0.63 米，0.28 秒后往回跑。
- 正对平台边缘：在距边缘 0.15 米处停下，速度为零。以 45° 跑向边缘：以 3.89 米/秒（5.5 × cos 45°，与沿墙一样）沿边缘滑行到平台拐角，高度不变。没有边缘防护时：0.35 秒内下落 1.6 米。
- 冲刺：8.25 米/秒。`sprint_duration` 为 2 秒时（每秒消耗 50），体力在 2.02 秒后耗尽，之后为 5.5 米/秒；3.38 秒后角色恢复（1 + 2.4 秒），在仍按住 Shift 的情况下再次以 8.25 米/秒冲刺。
- 跳跃：最高点 1.000 米，空中停留 0.517 秒（按公式为 0.522 秒）。在离地 0.4 米处按下时，跳跃在落地后的下一个物理帧触发；在最高点按下则被忽略。走出边缘 3 个物理帧后按空格可以起跳，9 个物理帧后则不行。

---

*本页对应 Iso & Orbit 1.0.0。*
