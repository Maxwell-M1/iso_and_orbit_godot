<!-- translation of addons/iso_orbit/click_to_move/README.md @ fabef0a2f5e6 -->
# 点击移动

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

适用于等距视角和俯视角游戏的点击移动：点击地面，角色沿导航网格跑过去，并精确停在该点；按住按键，角色跟随光标奔跑。匀加速与匀减速，转向速率有限，静止时可瞬间转身。按住右键时，WASD 相对相机移动角色。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings`（Resource） | 速度、加速、制动、转向 |
| `ground_motion.gd` | `GroundMotion`（RefCounted） | 数学部分：方向和剩余距离 → 速度 |
| `navigation_mover.gd` | `NavigationMover`（Node） | `move_to()`、`steer()`、`stop()`；返回速度，从不移动身体 |
| `point_click_move_input.gd` | `PointClickMoveInput`（Node） | 鼠标和右键 + WASD → 移动器命令 |
| `click_marker.gd`、`click_marker.tscn` | `ClickMarker`（Node3D） | 点击位置的标记 |
| `navigation_path_view.gd` | `NavigationPathView`（MeshInstance3D） | 沿剩余路径绘制的调试线 |

不需要其他插件。如需带重力、跳跃和冲刺的现成身体，请添加 `addons/iso_orbit/ground_character`。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/click_to_move/`。
2. 为你的关卡烘焙导航网格（`NavigationRegion3D`）。没有导航网格时，角色会直接朝目标点跑。
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

4. 如需鼠标控制，在任意位置添加一个挂载 `point_click_move_input.gd` 的 `Node`，并设置其 `mover` 和 `camera`。它需要输入动作 `move_to_cursor`（左键）、`camera_rotate`（右键）以及 `move_forward`、`move_back`、`move_left`、`move_right`（WASD），点击检测的是物理层 1（`ground_mask`）。
5. 或者由 AI 向移动器下达命令：`move_to(point)`、`steer(direction)`、`stop()`，并监听 `arrived`。

## 文档

见模板仓库中的 `docs/zh_CN/integration.md`、`docs/zh_CN/systems/locomotion.md` 和 `docs/zh_CN/systems/input.md`。

---

*本页对应 Iso & Orbit 1.1.0。*
