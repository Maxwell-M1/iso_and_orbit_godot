<!-- translation of addons/iso_orbit/click_to_move/README.md @ 29860f203673 -->
# 点击移动

[← 文档目录（模板仓库）](../../../docs/zh_CN/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

适用于等距视角和俯视角游戏的点击移动：点击地面，角色沿导航路径移动，停在可达路径的终点；按住按键，角色跟随光标奔跑。匀加速与匀减速、转向速率有限，静止时可瞬间转身。按住右键时，WASD 相对相机移动角色。跟随光标奔跑中再按右键，角色会保持路线，让玩家环顾四周。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings`（Resource） | 速度、加速、制动、转向 |
| `ground_motion.gd` | `GroundMotion`（RefCounted） | 数学部分：方向和剩余距离 → 速度 |
| `navigation_mover.gd` | `NavigationMover`（Node） | `move_to()`、`steer()`、`stop()`、`halt()`、`face()`；返回速度，从不移动身体 |
| `point_click_move_input.gd` | `PointClickMoveInput`（Node） | 鼠标和右键 + WASD → 移动器命令；`cancel()` 取消正在进行的按住操作 |
| `click_marker.gd`、`click_marker.tscn` | `ClickMarker`（Node3D） | 点击位置的标记 |
| `navigation_path_view.gd` | `NavigationPathView`（MeshInstance3D） | 沿剩余路径绘制的调试线 |

不需要其他插件。如需带重力、跳跃和冲刺的现成身体，请添加 `addons/iso_orbit/ground_character`。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/click_to_move/`。
2. 为你的关卡烘焙导航网格（`NavigationRegion3D`）。按身体胶囊体及台阶设置代理尺寸和最大攀爬高度。没有网格或路径结果为空时，移动器会直奔请求的目标点；部分路径可能停在最近的可达点。身体仍需要碰撞形状和带碰撞的地形。
3. 将 `NavigationMover` 添加为角色身体的直接子节点。身体在每个物理帧调用一次 `compute_velocity(delta)`，在 `move_and_slide()` 之前：

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

   移动器进入场景树前，将 `NavigationMover.settings` 指定为 `LocomotionSettings` 资源；也可留空，由脚本以默认值创建。每个角色需要独立调整时，请使用 **Make Unique（设为唯一）**。运行中修改现有资源的字段会生效；但在 `_ready()` 后替换 `mover.settings`，不会更新已创建的 `GroundMotion` 实例。如果需要台阶、跳跃或边缘防护，可以使用配套插件中的 `GroundCharacter`。

4. 如需鼠标控制，在任意位置添加一个挂载 `point_click_move_input.gd` 的 `Node`，并设置其 `mover` 和 `camera`。它需要输入动作 `move_to_cursor`（左键）、`camera_rotate`（右键）以及 `move_forward`、`move_back`、`move_left`、`move_right`（WASD）；缺少的动作会在启动时报告一次，之后不会读取。点击射线检测第 1 物理层（`ground_mask`）：角色层和隐形墙不要包含在内，否则点击可能命中角色或墙。若使用 `addons/iso_orbit/orbit_camera` 的相机，请将 `hold_pending_changed` 连接到相机的 `set_follow_paused`，将 `run_requested` 连接到 `end_follow_wait`。奔跑中环顾四周（`look_around_while_held`）要求 `camera_steer_action` 与旋转相机的动作相同，即相机支架的 `rotate_action`；两者默认都是 `camera_rotate`。
5. 或者由 AI 向移动器下达命令：`move_to(point)`、`steer(direction)`、`stop()`，并监听 `arrived`。该信号表示到达路径终点；目标点不可达时，终点可能位于请求点之前。

若要使用已装配好的英雄及其场景设置，请按 `docs/zh_CN/integration.md` 的迁移说明复制，不必手动构建此身体。两种输入模式及英雄的设置见 `docs/zh_CN/systems/input.md`。

## 文档

见模板仓库中的 `docs/zh_CN/integration.md`、`docs/zh_CN/systems/locomotion.md` 和 `docs/zh_CN/systems/input.md`。

---

*本页对应 Iso & Orbit 1.2.0。*
