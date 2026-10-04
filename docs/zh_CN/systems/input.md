<!-- translation of docs/en/systems/input.md @ 4f1e5987b000 -->
# 输入

> 本文是[英文原文](../../en/systems/input.md)的翻译。两者不一致时，以英文版为准。

两个节点将玩家输入转换为命令。它们自己都不移动任何东西。

- `PointClickMoveInput`：鼠标，以及按住右键时的 WASD → `NavigationMover.move_to()`、`steer()` 和 `stop()`。
- `CharacterActionInput`：冲刺和跳跃按键 → `GroundCharacter.sprint_requested` 和 `jump()`。

两者都位于 `main.tscn` 中，而不在角色场景中，因此同一个角色也可以改由 AI 驱动。从玩家角度看的操作说明，见[操作](../controls.md)。

## PointClickMoveInput

| 输入 | 命令 |
|---|---|
| 点击地面 | `move_to(point)`：从相机发出、针对 `ground_mask` 的射线找到该点 |
| 按住左键 | 根据 `hold_mode`，`steer()` 朝向光标，或 `move_to()` 前往光标下的点 |
| 同时按住左右键 | `steer()` 朝相机所看方向；A 和 D 斜向前偏转（`keys_with_camera_steer`） |
| 右键加 WASD | 相对相机 `steer()`，侧移或转向（`keys_with_camera`）；松开时 `stop()` |

每个物理帧由谁驱动角色，在 `_physics_process` 这一处决定：优先是按住的左键，否则是配合右键的按键。因此在按住右键和 W 时松开左键，角色不会停下：按键会立即接管。

### 点击还是按住

按下经过 `hold_delay`（0.2 秒）后变为按住。在此之前，角色继续做原来的事（站着，或继续朝原来的方向跑），既没有标记，也没有通往按下位置的路径。

- **提前松开：点击。** 角色沿路径跑向按下按键时的位置。该点在按下的瞬间确定，即使之后鼠标移动过也是如此。标记出现（`destination_picked`）。角色到达，或这次奔跑因改用按键或按住而被放弃时，标记淡出。
- **按得更久：按住。** 角色立即跟随光标奔跑（`hold_started`），而不会先转向按下的位置。否则它会先沿着通往那个点的路径出发，而绕开障碍物的路径可能通向与光标完全不同的地方。

代价是点击在松开时才生效，比按下即生效晚约 0.1 秒。在尚不确定按下是点击还是按住时，`hold_pending_changed(true)` 会暂停相机的跟随模式，因此短促的点击绝不会移动相机。

如果按下左键时右键已经按住，就不会产生点击：角色立即朝相机所看方向奔跑。

### 按住模式

`hold_mode`（设置 → 操作 → **按住左键**）：

- `STEER`（默认）：不使用路径，直奔光标。角色沿障碍物滑行，无论你指向坡道的哪里都能跑上去。光标距角色在 `steer_dead_zone`（0.5 米）以内时方向不变：离得这么近，方向对光标过于敏感。松开时角色平稳停下。
- `FOLLOW_POINT`：沿导航路径前往光标下的点。该点移动时路径会重建，因此在高度变化处（坡道、平台）附近，路径可能从一条路线跳到另一条。松开后角色继续跑到最后一个点，并由标记显示该点（`destination_picked`）；开启 `stop_on_release` 时，角色就地制动停下。

### 配合右键的按键

按键只在按住右键时有效：此时相机随鼠标转动，光标被捕获。不按右键时 WASD 不起作用。每个模式为 `OFF` 或两种变体之一，分别针对单独按住右键（`keys_with_camera`）和同时按住两键（`keys_with_camera_steer`）设置。

| | `SIDESTEP` | `TURN` |
|---|---|---|
| 右键 + W | 向前，朝相机所看方向 | 相同 |
| 右键 + A / D | 向侧面移动，面朝前方 | 向左 / 右转身并朝那里走 |
| 右键 + S | 后退，面朝前方，速度较慢 | 转身走向相机 |
| 两个键（W + A、S + D…） | 斜向移动，面朝前方 | 斜向移动，面朝前进方向 |
| 左键 + 右键 + A / D | 斜向前，面朝前方 | 斜向前，面朝前进方向 |

两者的脚本默认值都是 `SIDESTEP`；演示的设置默认两者都是 `TURN`。

斜向移动与直线移动一样快。后退更慢：`NavigationMover` 按移动方向与朝向相反的程度缩放速度，见[移动](locomotion.md#navigationmover)。朝向作为 `steer(direction, facing)` 的第二个参数传入：侧移时它就是相机的前方方向。停下后角色保持原来的朝向；点击或按住会让它重新面朝奔跑方向。

松开按键或右键，角色平稳停下。只按住右键而不按任何键，不会打断跑向点击位置的过程，因此可以在奔跑中转动相机。按键会打断它，标记随之淡出。这些按键对应动作 `move_forward`、`move_back`、`move_left`、`move_right`，按物理位置绑定。

### 按住按键时的光标

**隐藏**（`hide_cursor_while_held`，默认开启）。奔跑时光标只会闪来闪去，尤其是在相机转动、光标随世界移动的时候。按下一旦变为按住，光标即隐藏（短促的点击不会影响它），松开后在你瞄准的位置重新出现。在此期间鼠标模式为 `MOUSE_MODE_CONFINED_HIDDEN`：普通的隐藏光标可能离开窗口并出现在窗口边缘。在 macOS 上，引擎通过自行移动光标来把它限制在窗口内，并会把为保持瞄准（见下文）而做的每次光标移动重复计算一次，导致瞄准逐渐偏离。因此在 macOS 上模式为 `MOUSE_MODE_HIDDEN`。在任何系统上，隐藏的系统光标都不跟随瞄准：反正看不见它，而且在 macOS 上编辑器的“游戏”选项卡（Game）中，每次这样的移动都会晚一两帧才生效，转向时角色会抖动。组件根据鼠标移动来移动自己的光标，系统光标到达窗口边缘时将其移回窗口中央，松开时再把它放到你瞄准的位置。右键环绕相机时，由相机捕获光标；在仍按住左键的情况下松开右键，光标会再次隐藏。暂停（设置窗口）或切换到其他窗口时，光标会立即显示。`is_cursor_hidden()` 表示组件是否已隐藏光标。

**保持瞄准**（`keep_aim_on_camera_turn`，默认开启）。按住左键时，奔跑方向来自光标，也就是屏幕上的一个点。如果相机转动时光标在屏幕上不动，光标下就会换成地面上的另一处，角色随之转向，相机又随角色转动，角色就会原地兜圈（在演示的 1.1 秒跟上用时下，1.25 秒内偏转 77.6°；设为“立即”时则会原地打转）。因此在按住按键期间，组件会让光标随世界移动（可见的系统光标通过 `Viewport.warp_mouse()`，隐藏的光标只在松开时移动）：光标停留在地面上的同一位置，角色朝你瞄准的地方奔跑，相机平滑地转到它身后。移动鼠标照常转动角色。松开后不再干预光标。

关闭时，光标像驾驶汽车一样操控方向：把光标放在角色右侧，角色就会向右偏转，直到光标位于正前方。在系统无法移动光标的地方（例如 Wayland），奔跑方向依然保持，但光标停在原处。

光标在相机本帧就位后，于 `_process` 中修正：该组件的 `process_priority` 为 1，相机的为 0。输入组件直接读取 `Camera3D`，对相机支架一无所知。

### 属性

| 属性 | 默认值 | 含义 |
|---|---|---|
| `mover` | — | 要下达命令的 `NavigationMover`；必需 |
| `camera` | — | 用于射线和方向的相机；为空时使用视口的当前相机 |
| `move_action` | `move_to_cursor` | 点击和按住 |
| `hold_mode` | `STEER` | 见上文 |
| `keep_aim_on_camera_turn` | 开 | 见上文 |
| `hide_cursor_while_held` | 开 | 见上文 |
| `camera_steer_action` | `camera_rotate` | 按住该动作时，按住左键会朝相机所看方向奔跑；为空则禁用 |
| `ground_mask` | 第 1 层 | 可以点击的物理层。不得包含角色所在的层 |
| `hold_delay` | 0.2 秒 | 按下变为按住的时间 |
| `steer_dead_zone` | 0.5 米 | `STEER`：光标距角色这么近时不改变方向 |
| `stop_on_release` | 关 | `FOLLOW_POINT`：松开时制动停下，而不是继续跑到最后一个点 |
| `ray_length` | 1000 米 | 从相机发出的射线长度 |
| `keys_with_camera` | `SIDESTEP` | 右键 + WASD 模式 |
| `keys_with_camera_steer` | `SIDESTEP` | 左键 + 右键 + A/D 模式 |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | 按键 |

信号：`destination_picked(point)`、`hold_started`、`hold_pending_changed(pending)`。

组件在启动时检查其输入动作是否存在，缺少时报告错误。

## CharacterActionInput

| 属性 | 默认值 | 含义 |
|---|---|---|
| `character` | — | 要下达命令的 `GroundCharacter` |
| `sprint_action` | `sprint` | Shift |
| `jump_action` | `jump` | 空格 |
| `sprint_mode` | `HOLD` | `HOLD`：按住按键时冲刺。`TOGGLE`：按一下开启冲刺，再按一下关闭；角色力竭时冲刺也会自动关闭，休息后不会自动恢复 |

该组件只负责传递输入；是否有足够的体力冲刺、当前能否跳跃，由角色决定。它在物理帧中先于角色运行（`process_physics_priority = -1`），因此按下和松开都能传到角色，不会多出一个物理帧的延迟。`is_sprint_toggled()` 返回 `TOGGLE` 模式下的状态。

### Shift 不会卡住

在 `HOLD` 模式下，冲刺状态每个物理帧都从 `Input.is_action_pressed()` 读取，因此松开 Shift 就会结束冲刺。这一点已用真实事件验证：奔跑中、按住左键奔跑时、在设置窗口中松开、切换模式之后。

但松开事件本身有时根本到不了游戏，引擎会一直认为 Shift 处于按下状态，直到再次按下它。当游戏嵌入编辑器的“游戏”选项卡（Game）且焦点移到编辑器时（编辑器窗口拥有焦点时，`Input.release_pressed_events()` 会跳过重置），或者系统快捷键吞掉了松开事件时，就会出现这种情况。针对这种情况，组件会用每个鼠标和键盘事件携带的 Shift 真实状态（`shift_pressed`；在 Windows 上来自 `GetKeyboardState`）来核对冲刺状态。如果除冲刺键本身以外的任何鼠标或键盘事件表明 Shift 已松开，卡住的按下状态就会被释放。只要绑定到冲刺动作的每个键都是修饰键（Shift、Ctrl、Alt、Meta），这一机制就有效。

如果 Windows 开启了粘滞键（连续按五次 Shift），Shift 会在系统层面卡住；请在 Windows 设置中关闭它。

---

*本页对应 Iso & Orbit 1.1.0。*
