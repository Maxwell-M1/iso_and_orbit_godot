<!-- translation of docs/en/integration.md @ 502ddfce7182 -->
# 在你的项目中使用

[← 文档目录](index.md)

> 本文是[英文原文](../en/integration.md)的翻译。两者不一致时，以英文版为准。

如果想在其他项目中使用演示的移动和相机，先从现成的英雄场景入手。如果你已有角色控制器，或只需要相机，也可以单独使用组件。脚本都是普通的 GDScript 类（`class_name`）；没有需要启用的编辑器插件，也不强制要求 `Settings` 自动加载。

| 你的目标 | 从这里开始 |
|---|---|
| 可用的英雄、输入和相机 | [迁移演示中的英雄](#将演示中的英雄迁移到你的项目)，然后[选择配置](configurations.md) |
| 给现有角色添加相机 | [单独使用相机](#单独使用相机) |
| 使用项目的移动系统和自己的模型 | [使用现成身体的点击移动](#使用现成身体的点击移动)，然后[替换模型](systems/characters.md) |
| 让自己的控制器或 AI 使用路径移动 | [使用自己的身体](#使用自己的身体)和[向移动器下达命令](#向移动器下达命令) |

下文路径相对于 `project.godot` 所在的项目根目录。`res://` 路径表示 Godot 中的相同位置。第一次集成并验证时，请保留随附的文件夹布局。

## 插件

| 插件 | 类 | 需求 |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`、`CameraArm` | 输入动作 `camera_rotate`、`camera_zoom_in`、`camera_zoom_out`；供相机臂使用的物理层 |
| `click_to_move` | `LocomotionSettings`、`GroundMotion`、`NavigationMover`、`PointClickMoveInput`、`ClickMarker`、`NavigationPathView` | 世界中有已烘焙的 `NavigationRegion3D`（没有的话，角色会直接朝目标点跑）。输入部分需要：任意 `Camera3D`，以及动作 `move_to_cursor`、`camera_rotate`、`move_forward`、`move_back`、`move_left`、`move_right` |
| `ground_character` | `GroundCharacter`、`FallSettings`、`LedgeGuard`、`Stamina`、`CharacterActionInput`、`CharacterSounds`、`HandSway`、`CharacterHover`、`DampedSpring`、`CharacterAppearance`、`StaminaBar` | `click_to_move`。按键需要动作 `sprint` 和 `jump`；声音可用自己的文件或 `shared/audio/character/`；手部摆动和可切换模型需要朝向 −Z、带有手部节点的模型 |
| `occluded_silhouette` | `OccludedSilhouette` 及其着色器和材质 | 无：适用于任何模型 |
| `points_of_interest` | `PointOfInterest`、`DiscoveryToast` | 玩家身体位于 `player` 分组中，且处在区域能检测到的物理层上 |
| `ui_screens` | `UiRoot`、`UiScreen`、`FpsCounter`、`InputNames`、`ActionTexts` | 内置的 `ui_cancel`；如果 `UiRoot` 通过按键打开窗口，还需要动作 `toggle_settings`。按键名称会读取你项目的输入映射 |
| `levels` | `LevelHost`、`LevelPortal`、`SpawnPoint`、`LoadingScreen` | 除引擎外不依赖其他组件。旅行者身体须在 `player` 分组中，并处于传送门可检测的物理层 |

每个插件文件夹都有一个说明配置方法的 `README.md` 和一份 `LICENSE` 副本。请整体取用插件：其中的类通过类型相互引用，而用不到的文件也没有坏处。请将文件夹保留在 `res://addons/iso_orbit/<addon>/`：其中的场景和材质通过这些路径引用各自的文件。要把插件放到别处，请在编辑器的文件系统面板（FileSystem）中移动，它会更新引用。

HUD 部件（`StaminaBar`、`DiscoveryToast`、`FpsCounter`）的外观来自演示主题 `shared/ui/ui_theme.tres` 中同名的主题类型变体；没有这些变体时，它们使用默认主题。

以下内容围绕演示本身构建，因此不在插件内：设置系统（`gdscript/settings/game_settings.gd` 和 `gdscript/ui/settings/` 中的设置窗口，见[设置](#设置)）、配置了该窗口的 `gdscript/ui/ui_root.tscn`（`UiRoot`）、可操控的英雄（`gdscript/player/playable_hero.tscn`，以演示角色为基础，见[可操控的英雄](#可操控的英雄)）、旅行提示（`gdscript/ui/travel_prompt.tscn`）、游戏框架 `gdscript/main.gd`，以及演示的连接代码 `gdscript/demo/hud.gd` 和 `settings_applier.gd`。

## 单独使用相机

相机可用于任何 `Node3D` 目标，只需要 `addons/iso_orbit/orbit_camera/`。

1. 在场景中目标的旁边（而不是目标内部）添加一个挂载 `orbit_camera_rig.gd` 的 `Node3D`。
2. 给它添加一个挂载 `camera_arm.gd` 的子节点 `Node3D`，再给后者添加一个 `Camera3D` 子节点。
3. 将支架的 `target` 指向移动的身体，`arm` 指向相机臂节点，并勾选相机的 **Current（当前）** 属性。将相机臂的 `fade_target` 指向近距离时要变成半透明的模型根节点，或留空。
4. 添加[项目配置](project-setup.md)中的输入动作，并为相机臂添加其中的物理层。

保持支架、相机臂、相机及其祖先节点的缩放为 `(1, 1, 1)`，相机的局部变换也保持默认值：相机臂在运行时设置它。请通过取景属性调整画面，不要缩放节点。

不用相机臂、直接将 `Camera3D` 作为相机支架的子节点也可以：此时相机保持在缩放所设定的距离上，并会穿墙。相机支架在 `_process` 中根据目标的插值位置更新，因此如果目标在物理帧中移动，请在项目中开启物理插值。详见：[相机](systems/camera.md)。

## 使用现成身体的点击移动

复制 `addons/iso_orbit/click_to_move/` 和 `addons/iso_orbit/ground_character/`。

1. 为你的关卡烘焙导航网格（`NavigationRegion3D` → **烘焙导航网格**（Bake NavigationMesh））。其代理半径和最大攀爬高度应与你的角色相符，见[世界与导航](systems/world-and-navigation.md)。
2. 创建一个挂载 `ground_character.gd` 的 `CharacterBody3D`：包含碰撞形状、带有模型（朝向 −Z）的 `Visual` 节点，以及这些子节点：`NavigationMover`（挂载 `navigation_mover.gd` 的 `Node`），可选的 `LedgeGuard` 和 `Stamina`。设置身体的 `mover`、`visual`、`ledge_guard` 和 `stamina`。
3. 给移动器指定一个 `LocomotionSettings` 资源，或留空以使用默认值。
4. 在场景中任意位置添加一个挂载 `point_click_move_input.gd` 的 `Node`，并设置其 `mover` 和 `camera`。
5. 如需冲刺和跳跃，可以再添加 `character_action_input.gd`，并将其 `character` 设为该身体。

`gdscript/player/player.tscn` 就是这套配置，外加声音、手部摆动、悬浮（默认关闭的 `Visual/Hover`，并采用较慢的下落）、可切换模型和剪影。你可以实例化它，再删除不需要的部分。`GroundCharacter`、`LedgeGuard` 和 `CharacterHover` 的配置错误会在游戏启动时以警告形式打印。

## 可操控的英雄

`gdscript/player/playable_hero.tscn` 是已装配好的玩家英雄：`player.tscn` 作为 `Character`（位于 `player` 分组中），再加上 `PointClickMoveInput`、`CharacterActionInput`、带相机臂和相机的相机支架、点击标记及路径线，连同它们的设置与信号连接。把它放入游戏场景一次，作为关卡的兄弟节点，而不是放进某个关卡内部。其脚本 `playable_hero.gd` 只使用插件中的类：

- `place_at(marker)` 和 `teleport(position, facing)` 会立即放置英雄：取消正在进行的按住操作，通过 `GroundCharacter.teleport()` 让角色无跳动地抵达，让相机朝向英雄并立即对齐。若将 `turn_camera` 设为 `false`，相机保持原角度，演示启动时就是这样。
- `controls_enabled = false` 禁用移动输入、冲刺和跳跃。玩家仍可操控相机，已有点击目标的奔跑也会继续。若需制动，还要调用 `character.mover.stop()`；若需立即停止水平移动，则调用 `halt()`。暂停场景树是另一回事。
- 各组件以带类型的属性暴露：`character`、`input`、`actions`、`camera_rig`、`camera_arm`、`camera`、`click_marker`、`path_view`，以及角色的 `sounds`、`appearance`、`hover`、`silhouette`。

要用自己的模型，可以复制此场景，用自己的角色替换 `player.tscn`，也可以手动装配。相机所需的两条关键连接是 `PointClickMoveInput.hold_pending_changed` 到 `OrbitCameraRig.set_follow_paused`，以及 `PointClickMoveInput.run_requested` 到 `OrbitCameraRig.end_follow_wait`（环绕后相机会等待新的奔跑）。其余四条连接负责显示和隐藏点击标记，见[架构](architecture.md#场景中建立的连接)。保持相机的 `sharp_turn_speed` 不高于角色转向速率的一半；目前只有 `PlayableHero` 会检查并对此发出警告。

## 将演示中的英雄迁移到你的项目

如果想得到与经过测试的演示相同的配置，请使用 Godot 4.7.2、Jolt Physics 和 Forward+。先制作一个小型测试关卡；确认复制的英雄在那里正常工作后，再加入自己的模型、关卡和设置。

1. **按原路径复制文件。** 将以下内容连同文件夹结构复制到你的项目：
   - `addons/iso_orbit/click_to_move/`、`ground_character/`、`orbit_camera/` 和 `occluded_silhouette/`；
   - `gdscript/player/`：英雄、角色、英雄脚本和角色设置资源；
   - `shared/characters/`：十种模型、法杖、书籍及材质；
   - `shared/audio/character/`：脚步、跳跃、落地和冲刺音效；
   - `shared/world/materials/wood.tres` 和 `dark_wood.tres`：德鲁伊与战斗法师的木质部件使用这两种材质。它们存放在世界材质目录中，只复制 `shared/characters/` 会漏掉。

   也要带上这些文件旁边的 `.uid` 和 `.import` 文件：场景会通过这些标识和路径找到脚本与声音。不要复制 `.godot/`：你的编辑器会自行导入文件。场景按上述路径引用文件；如果最终需要放在别处，先按原路径复制，再在编辑器的文件系统面板中移动，引用会随之更新。
2. **配置项目**（Project Settings），参见[项目配置](project-setup.md)：
   - 输入动作 `move_to_cursor`、`camera_rotate`、`camera_zoom_in`、`camera_zoom_out`、`move_forward`、`move_back`、`move_left`、`move_right`、`sprint` 和 `jump`。缺少某个动作时，使用它的组件会在启动时报告一次，对应按键或鼠标操作不会生效；
   - 将 `navigation/3d/default_cell_height` 设为 0.025，以匹配下一步的导航网格。同一导航地图及其分配的所有网格都应采用匹配的单元尺寸；
   - 开启物理插值（`physics/common/physics_interpolation`）：相机跟随角色的插值位置。此英雄用 Jolt Physics（`physics/3d/physics_engine`）检查过；
   - 物理层：英雄身体位于第 2 层，与第 1 和第 4 层碰撞；点击检测第 1 层地面；相机臂被第 1 和第 3 层阻挡。层名称无关紧要，层编号很重要：请将自己的地面和墙体放在第 1 层，或在复制的场景里修改这些掩码。
3. **制作测试关卡。** 在 `NavigationRegion3D` 下，添加带 `BoxShape3D` 的 `StaticBody3D` 地面和可见的 `BoxMesh`；两者均为 20 × 1 × 20 米，中心在 `(0, -0.5, 0)`，使顶面位于 Y = 0。在 `(0, 1, -4)` 放置一个 2 × 2 × 2 米的方盒障碍物，其网格与碰撞形状相符，位于第 1 层。它会挡住 Spawn `(0, 0, 4)` 到 `(0, 0, -8)` 的直线路线。再加一盏灯，并可选地在 `(5, 0.1, 0)` 放一个 3 × 0.2 × 3 米的台阶。只有可见网格并不产生碰撞。
4. **创建并烘焙导航网格。** 选中导航区域，指定新的 `NavigationMesh`，然后设置：

   | 属性 | 测试关卡的值 | 原因 |
   |---|---|---|
   | Parsed Geometry Type | Static Colliders | 烘焙与身体发生碰撞的相同几何体 |
   | Geometry Collision Mask | 第 1 层 | 包含地面和障碍物，不包含英雄 |
   | Agent Radius | 0.5 米 | 为半径 0.35 米的胶囊体留出空间 |
   | Agent Height | 1.8 米 | 至少等于胶囊体完整高度；检查最低的天花板 |
   | `filter_walkable_low_height_spans` | `true` | 排除净空低于 Agent Height 的地面区域 |
   | Agent Max Climb | 0.3 米 | 与 `Character.max_step_height` 一致 |
   | Agent Max Slope | 40° | 低于身体的 45° 地面坡度上限 |
   | Cell Height / Cell Size | 0.025 米 / 0.25 米 | 精细处理竖向台阶；与导航地图设置匹配 |

   保持地面和障碍物位于区域**之下**，然后点击 **Bake NavigationMesh（烘焙导航网格）**并保存场景。演示现有的网格使用 1.75 米的代理高度，且未启用低矮区域过滤。对于有天花板的新关卡，请使用完整的碰撞体高度并启用过滤。导航不会取代物理碰撞。如果没有可用路径，移动器可能退回到直奔目标的模式；在这种模式下，它不会绕墙。详见[世界与导航](systems/world-and-navigation.md#物理层与导航)。
5. **将英雄作为导航区域的兄弟节点实例化**，命名为 `Hero`。在 `(0, 0, 4)` 添加名为 `Spawn` 的 `Marker3D`。保持英雄根节点缩放为 `(1, 1, 1)`，并让其相机保持当前相机状态。场景最简单可以是这样：

   ```text
   Game (Node3D)
   ├── NavigationRegion3D
   │   ├── Ground (带碰撞体和网格的 StaticBody3D)
   │   └── Obstacle (带碰撞体和网格的 StaticBody3D)
   ├── Hero (playable_hero.tscn 的实例)
   ├── Spawn (Marker3D)
   └── DirectionalLight3D
   ```

   将以下脚本附加到 `Game` 并运行该场景：

   ```gdscript
   extends Node3D

   @onready var hero: PlayableHero = $Hero


   func _ready() -> void:
       hero.place_at($Spawn, false)
   ```

   传入 false 会保留相机初始的 45° 环绕角；省略它，相机会转到标记 −Z 方向的后方。启动后请**通过英雄 API 放置或传送角色**。`Hero` 根节点只是固定容器，不会跟随移动中的身体。玩家当前位置应读取 `hero.character.global_position`。
6. **先验证结果，再做定制。** 点击障碍物另一侧靠近 `(0, 0, -8)` 的地面：英雄应绕过去并停下。必要时缩小画面以看见目的地。按住鼠标左键应直接引导，松开后停下。再测试右键环绕、滚轮缩放、右键 + WASD、Shift 和空格键。随附移动资源的普通速度为 5.5 米/秒，冲刺为 8.25 米/秒，跳跃高度为 1 米，0.2 米台阶无须跳跃。检查调试器是否报告缺少动作、资源或配置警告。

复制的场景即使不接入设置系统，也具有演示的默认行为：两种按键模式都是 `TURN`；相机跟随、倾角／高度对齐和悬浮均关闭；冲刺音效关闭。初始模型是死灵法师。请查看[配置方案](configurations.md)，了解精确节点路径、各种默认值之间的区别和另外两种实用配置。

### 迁移故障排查

| 症状 | 首先检查 |
|---|---|
| 找不到全局类或资源 | 按原路径复制上述四个插件文件夹及资源，等待编辑器完成导入；别漏掉两种木材材质 |
| 英雄穿过地面下落 | 地面需要第 1 层上的碰撞形状；单独的 MeshInstance3D 只有视觉效果 |
| 点击没有反应 | 输入映射动作、当前相机、`PlayerInput.camera` 和射线的 `ground_mask`；重叠的 Control 也可能吞掉鼠标输入 |
| 英雄撞墙而不绕墙 | 烘焙区域下的碰撞体，检查区域／移动器的导航层，并查看生成的网格 |
| 路径穿过英雄无法攀爬的台阶 | 使最大攀爬高度与 `max_step_height` 匹配，使用精细的竖向单元并重新烘焙；在实际地形上测试 |
| 场景改动在启动时消失 | 复制来的 `SettingsApplier` 可能会用已保存设置覆盖改动；单独使用英雄不需要它 |
| 修改移动后相机意外转动 | 对照角色的 `turn_speed` 和相机的 `sharp_turn_speed`；见[配置方案](configurations.md#调整参数而不破坏配置) |

还需注意：

- 插件和 `playable_hero.gd` 声明了全局类名（`GroundCharacter`、`NavigationMover`、`OrbitCameraRig`、`PlayableHero` 及[上表](#插件)中的其他类）。如果项目已有同名类，两者会冲突；请重命名其中一个。
- 改变角色转向速度（其 `LocomotionSettings` 中的 `turn_speed`）时，请保持 `CameraRig.sharp_turn_speed` 不高于该速度的一半；否则相机可能在角色向侧面奔跑并掉头的途中跟随中间方向而转动。当它不低于角色转向速度时，英雄启动会发出警告。
- 不需要 `Settings` 自动加载，也不需要设置窗口。HUD 不属于英雄场景：演示的 `main.tscn` 添加了体力条和地点提示，其主题见[插件](#插件)中的说明。
- 模型和声音与代码一样，都采用项目的 MIT 许可证。

## 关卡

复制 `addons/iso_orbit/levels/`。主场景包含以初始关卡为唯一子节点的 `LevelHost`、位于旁边的英雄和 `loading_screen.tscn`。主脚本连接关卡容器的信号：`level_change_started` 时禁用英雄操控，`level_loaded(level, spawn)` 时将英雄放在 `spawn`，`level_change_finished` 时恢复操控；`level_change_failed` 时也须恢复（当前关卡保持不变，而且不会再发出 `level_change_finished`）；`portal_entered` 和 `portal_exited` 分别显示、隐藏旅行提示。`gdscript/main.gd` 正是这样做的。每个关卡需要一个名为 `default` 的 `SpawnPoint`；传送门是持有目标场景路径的 `LevelPortal` 区域。

如果你已有自己的关卡系统，只取可操控的英雄，并在关卡就绪时调用 `place_at()`；如果也有自己的角色，则调用 `GroundCharacter.teleport()` 达到相同效果。详细说明、默认值与各种设置组合见[关卡](systems/levels.md)。

## 使用自己的身体

如果要保留你自己的角色控制器，只取用 `addons/iso_orbit/click_to_move/` 即可。约定很简单：

- `NavigationMover` 必须是身体（任意 `Node3D`）的直接子节点。它读取身体的位置以及身体所在世界的导航地图。
- 身体在每个物理帧调用一次 `mover.compute_velocity(delta)`（在 `move_and_slide()` 之前），并应用结果的 X 和 Z。移动器从不移动身体。
- 垂直速度由身体自己负责：重力、跳跃、击退。

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

这个最简身体还需要自己的碰撞形状、地面和可用于观察它的相机；可在 `Visual` 节点下添加模型。要使模型朝向移动方向，请让该节点的 −Z 轴沿世界空间中的 `mover.get_facing()` 指向。如果不需要保留自己的身体实现，`GroundCharacter` 已能处理视觉朝向，包括父节点旋转的情况。

`LedgeGuard` 是可选的，它需要 `addons/iso_orbit/ground_character/`：将它作为身体的子节点，并在 `move_and_slide()` 前应用 `velocity = ledge_guard.constrain(velocity, delta)`。要冲刺，设置 `mover.sprinting = true`：速度上限会乘以 `LocomotionSettings.sprint_speed_multiplier`。`GroundCharacter` 中的其他一切（跳跃、体力、台阶、状态及其信号、模型的平滑转向）则需要你自己实现。

## 向移动器下达命令

任何东西都可以驱动角色：玩家输入、AI、过场动画或网络代码。

| 调用 | 效果 |
|---|---|
| `move_to(point)` | 沿导航路径前往全局坐标中的点。无法到达的目标可能停在最近的可达路径点；空路径会退回直线移动。新目标与当前目标相距不超过 `retarget_tolerance`（0.1 米）时不会重建路径 |
| `steer(direction, facing = Vector3.ZERO)` | 不使用路径朝某方向奔跑，直到收到其他命令；指定 `facing` 时，移动中朝向该方向（侧移） |
| `stop()` | 在角色当前位置平稳制动 |
| `halt()` | 立即停止，例如在传送之后 |
| `face(direction)` | 立即让静止角色转向，例如在出生点 |

要立即将整个角色放到别处，请调用 `GroundCharacter.teleport(position, facing)`：它会停止移动器、转动角色及其模型，并让身体移动后其跟随者不会发生跳动。

信号：`destination_changed(point)`、`path_changed`、`arrived`、`destination_cancelled`（目标点因 `steer()` 或 `stop()` 而被放弃）。查询：`is_moving()`、`is_steering()`、`has_destination()`、`get_destination()`、`get_speed()`、`get_heading()`、`get_facing()`、`get_remaining_path()`。详见：[移动](systems/locomotion.md)。

## NPC

实例化 `player.tscn`（或你自己带有移动器的身体场景），并删除玩家专用的 `Silhouette` 和 `Appearance` 节点。不要添加输入节点：在 AI 中调用 `NavigationMover.move_to()` 并监听 `arrived`。要使用演示中的某个角色模型，将其放在 `Visual/Hover` 下并命名为 `Model`。在编辑器中转动 NPC 可以设置其初始朝向；之后可用 `GroundCharacter.teleport(position, facing)` 或 `NavigationMover.face()` 转向。演示关卡中站立的 NPC 是静态身体，不是角色；见[世界与导航](systems/world-and-navigation.md)。

## 设置

组件从不读取设置：每个组件只读取自己的导出属性。要在你的设置菜单中提供这些选项，请在设置变化时由你自己的代码设置这些属性。`gdscript/demo/settings_applier.gd` 就是一个示例：一个 `match` 将每个设置键映射到一个节点属性。如果还想复用演示的设置系统，请复制 `gdscript/settings/game_settings.gd`，将其注册为 `Settings` 自动加载，把其中的键和 `DEFAULTS` 换成你自己的，并从 `gdscript/ui/settings/` 取用控件；见 [UI](systems/ui.md#设置)。

---

*本页对应 Iso & Orbit 1.2.0。*
