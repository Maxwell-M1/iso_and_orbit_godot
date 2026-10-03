<!-- translation of docs/en/integration.md @ 9c463782c813 -->
# 在你的项目中使用

> 本文是[英文原文](../en/integration.md)的翻译。两者不一致时，以英文版为准。

可复用的组件位于 `addons/iso_orbit/`，每个部分一个文件夹；这个公共文件夹让它们与你的其他插件分开。将需要的文件夹复制到你项目的 `addons/iso_orbit/` 中，在场景中连接好节点，并按[项目配置](project-setup.md)中的说明配置项目。这些脚本是普通的 GDScript 类（`class_name`）：没有需要启用的编辑器插件。

## 插件

| 插件 | 类 | 需求 |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`、`CameraArm` | 输入动作 `camera_rotate`、`camera_zoom_in`、`camera_zoom_out`；供相机臂使用的物理层 |
| `click_to_move` | `LocomotionSettings`、`GroundMotion`、`NavigationMover`、`PointClickMoveInput`、`ClickMarker`、`NavigationPathView` | 世界中有已烘焙的 `NavigationRegion3D`（没有的话，角色会直接朝目标点跑）。输入部分需要：任意 `Camera3D`，以及动作 `move_to_cursor`、`camera_rotate`、`move_forward`、`move_back`、`move_left`、`move_right` |
| `ground_character` | `GroundCharacter`、`LedgeGuard`、`Stamina`、`CharacterActionInput`、`CharacterSounds`、`HandSway`、`CharacterAppearance`、`StaminaBar` | `click_to_move`。按键需要：动作 `sprint` 和 `jump`。声音需要：你自己的声音，或 `shared/audio/character/`。手部摆动和可切换模型需要：朝向 −Z 且带有手部节点的模型 |
| `occluded_silhouette` | `OccludedSilhouette` 及其着色器和材质 | 无：适用于任何模型 |
| `points_of_interest` | `PointOfInterest`、`DiscoveryToast` | 玩家身体位于 `player` 分组中，且处在区域能检测到的物理层上 |
| `ui_screens` | `UiRoot`、`UiScreen`、`FpsCounter` | 内置的 `ui_cancel`；如果 `UiRoot` 通过按键打开窗口，还需要动作 `toggle_settings` |

每个插件文件夹都有一个说明配置方法的 `README.md` 和一份 `LICENSE` 副本。请整体取用插件：其中的类通过类型相互引用，而用不到的文件也没有坏处。请将文件夹保留在 `res://addons/iso_orbit/<addon>/`：其中的场景和材质通过这些路径引用各自的文件。要把插件放到别处，请在编辑器的文件系统面板（FileSystem）中移动，它会更新引用。

HUD 部件（`StaminaBar`、`DiscoveryToast`、`FpsCounter`）的外观来自演示主题 `shared/ui/ui_theme.tres` 中同名的主题类型变体；没有这些变体时，它们使用默认主题。

以下内容不在插件中，因为它们是围绕这个演示构建的：设置系统（`gdscript/settings/game_settings.gd` 和 `gdscript/ui/settings/` 中的设置窗口，见[设置](#设置)）、`gdscript/ui/ui_root.tscn`（配置了该窗口的 `UiRoot`），以及演示的胶水代码 `gdscript/demo/hud.gd` 和 `settings_applier.gd`。

## 单独使用相机

相机可用于任何 `Node3D` 目标，只需要 `addons/iso_orbit/orbit_camera/`。

1. 在场景中目标的旁边（而不是目标内部）添加一个挂载 `orbit_camera_rig.gd` 的 `Node3D`。
2. 给它添加一个挂载 `camera_arm.gd` 的子节点 `Node3D`，再给后者添加一个 `Camera3D` 子节点。
3. 设置相机支架的 `target`。将相机臂的 `fade_target` 设为相机很近时应变为半透明的节点，或留空。
4. 添加[项目配置](project-setup.md)中的输入动作，并为相机臂添加其中的物理层。

不用相机臂、直接将 `Camera3D` 作为相机支架的子节点也可以：此时相机保持在缩放所设定的距离上，并会穿墙。相机支架在 `_process` 中根据目标的插值位置更新，因此如果目标在物理帧中移动，请在项目中开启物理插值。详见：[相机](systems/camera.md)。

## 使用现成身体的点击移动

复制 `addons/iso_orbit/click_to_move/` 和 `addons/iso_orbit/ground_character/`。

1. 为你的关卡烘焙导航网格（`NavigationRegion3D` → **烘焙导航网格**（Bake NavigationMesh））。其代理半径和最大攀爬高度应与你的角色相符，见[世界与导航](systems/world-and-navigation.md)。
2. 创建一个挂载 `ground_character.gd` 的 `CharacterBody3D`：包含碰撞形状、带有模型（朝向 −Z）的 `Visual` 节点，以及这些子节点：`NavigationMover`（挂载 `navigation_mover.gd` 的 `Node`），可选的 `LedgeGuard` 和 `Stamina`。设置身体的 `mover`、`visual`、`ledge_guard` 和 `stamina`。
3. 给移动器指定一个 `LocomotionSettings` 资源，或留空以使用默认值。
4. 在场景中任意位置添加一个挂载 `point_click_move_input.gd` 的 `Node`，并设置其 `mover` 和 `camera`。
5. 如需冲刺和跳跃，可以再添加 `character_action_input.gd`，并将其 `character` 设为该身体。

`gdscript/player/player.tscn` 就是这套配置，外加声音、手部摆动、可切换模型和剪影。你可以实例化它，再删除不需要的部分。

## 使用自己的身体

如果要保留你自己的角色控制器，只取用 `addons/iso_orbit/click_to_move/` 即可。约定很简单：

- `NavigationMover` 必须是身体（任意 `Node3D`）的直接子节点。它读取身体的位置以及身体所在世界的导航地图。
- 身体在每个物理帧调用一次 `mover.compute_velocity(delta)`（在 `move_and_slide()` 之前），并应用结果的 X 和 Z。移动器从不移动身体。
- 垂直速度由身体自己负责：重力、跳跃、击退。

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover
@onready var ledge_guard: LedgeGuard = $LedgeGuard


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity = ledge_guard.constrain(velocity, delta)
	move_and_slide()
	var facing := mover.get_facing()
	$Visual.rotation.y = atan2(-facing.x, -facing.z)
```

`LedgeGuard` 是可选的：它是身体的子节点，来自 `addons/iso_orbit/ground_character/`。要冲刺，设置 `mover.sprinting = true`：速度上限会乘以 `LocomotionSettings.sprint_speed_multiplier`。`GroundCharacter` 中的其他一切（跳跃、体力、脚步信号、模型的平滑转向）则需要你自己实现。

## 向移动器下达命令

任何东西都可以驱动角色：玩家输入、AI、过场动画或网络代码。

| 调用 | 效果 |
|---|---|
| `move_to(point)` | 沿导航路径跑到某点，并精确停在那里。可以每个物理帧调用；与当前目标点距离小于 `retarget_tolerance`（0.1 米）的新点不会重建路径 |
| `steer(direction, facing = Vector3.ZERO)` | 不使用路径朝某方向奔跑，直到收到其他命令；指定 `facing` 时，移动中朝向该方向（侧移） |
| `stop()` | 在角色当前位置平稳制动 |
| `halt()` | 立即停止，例如在传送之后 |

信号：`destination_changed(point)`、`path_changed`、`arrived`、`destination_cancelled`（目标点因 `steer()` 或 `stop()` 而被放弃）。查询：`is_moving()`、`is_steering()`、`has_destination()`、`get_destination()`、`get_speed()`、`get_heading()`、`get_facing()`、`get_remaining_path()`。详见：[移动](systems/locomotion.md)。

## NPC

实例化 `player.tscn`（或你自己带有移动器的身体场景），并删除玩家专用的 `Silhouette` 和 `Appearance` 节点。不要添加输入节点：在 AI 中调用 `NavigationMover.move_to()` 并监听 `arrived`。要使用演示中的某个角色模型，将其放在 `Visual` 下并命名为 `Model`。演示关卡中站立的 NPC 是静态物体，而不是角色；见[世界与导航](systems/world-and-navigation.md)。

## 设置

组件从不读取设置：每个组件只读取自己的导出属性。要在你的设置菜单中提供这些选项，请在设置变化时由你自己的代码设置这些属性。`gdscript/demo/settings_applier.gd` 就是一个示例：一个 `match` 将每个设置键映射到一个节点属性。如果还想复用演示的设置系统，请复制 `gdscript/settings/game_settings.gd`，将其注册为 `Settings` 自动加载，把其中的键和 `DEFAULTS` 换成你自己的，并从 `gdscript/ui/settings/` 取用控件；见 [UI](systems/ui.md#设置)。

---

*本页对应 Iso & Orbit 1.0.0。*
