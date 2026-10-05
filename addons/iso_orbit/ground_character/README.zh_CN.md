<!-- translation of addons/iso_orbit/ground_character/README.md @ 87915285e965 -->
# 地面角色

[← 文档目录（模板仓库）](../../../docs/zh_CN/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

用于点击移动的现成角色身体：重力、带土狼时间和输入缓冲的跳跃（在任何物理帧率下高度都相同）、可单独设置重力和速度上限的下落、带体力的冲刺、上下台阶，以及可选的边缘防护。身体会报告自己在做什么，供动画、特效和界面使用：状态及其变化、带左右脚信息的脚步、起跳和落地、作为混合值的速度、模型坐标轴下的移动、转向和步态周期。还包括响应信号的声音、文本状态面板、随脚步摆动的手持物品、模型悬浮模式和可切换的模型。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `ground_character.gd` | `GroundCharacter`（CharacterBody3D） | 重力、跳跃、冲刺、台阶、`move_and_slide()`、转动模型；供动画使用的状态、信号和查询；无跳动的 `teleport()` |
| `fall_settings.gd` | `FallSettings`（Resource） | 下落时的重力、速度上限，以及接近上限的制动方式 |
| `ledge_guard.gd` | `LedgeGuard`（Node） | 在落差处让身体停下，或让它沿边缘滑行 |
| `stamina.gd` | `Stamina`（Node） | 冲刺储备 |
| `character_action_input.gd` | `CharacterActionInput`（Node） | 冲刺和跳跃按键 → 角色 |
| `character_sounds.gd` | `CharacterSounds`（Node3D） | 响应角色的信号播放声音 |
| `hand_sway.gd` | `HandSway`（Node） | 随脚步摆动手部节点 |
| `character_hover.gd` | `CharacterHover`（Node3D） | 让模型悬浮、平滑滑过台阶、摇摆和倾斜；可减慢下落 |
| `damped_spring.gd` | `DampedSpring`（RefCounted） | 用于惯性效果的单值阻尼弹簧 |
| `character_monitor.gd` | `CharacterMonitor`（Label） | 以文本显示角色的状态和最近的事件；可以记录这些事件 |
| `character_appearance.gd` | `CharacterAppearance`（Node） | 在运行时替换模型 |
| `stamina_bar.gd`、`stamina_bar.tscn` | `StaminaBar`（ProgressBar） | 显示 `Stamina` 的 HUD 条 |

需要 `addons/iso_orbit/click_to_move`：身体由 `NavigationMover` 驱动。

## 配置

1. 将此文件夹和 `click_to_move` 复制到 `res://addons/iso_orbit/`。
2. 搭建角色：

   ```
   Player           CharacterBody3D，挂载 ground_character.gd
   ├── CollisionShape3D
   ├── Visual       Node3D；内部的模型朝向 −Z
   ├── NavigationMover   来自 click_to_move
   ├── LedgeGuard   可选
   └── Stamina      可选
   ```

   设置身体的 `mover`、`visual`、`ledge_guard` 和 `stamina`。演示还在身体上启用 `floor_constant_speed`，使角色在坡道上保持速度，并把身体放在第 2 物理层，与第 1 和第 4 层（关卡及其隐形墙）碰撞：`get_ground_height()` 和默认的 `LedgeGuard` 用相同掩码寻找地面。身体能走上不超过 `max_step_height`（0.3 米）的台阶和不超过其 `floor_max_angle` 的斜坡；烘焙台阶路径时，应让 `agent_max_climb` 与预期台阶高度匹配，并用实际碰撞体测试烘焙的路线。`LedgeGuard.max_drop` 应至少等于 `max_step_height`；若需要下台阶时发出 `stair_taken`，则 `floor_snap_length` 要小于台阶高度。身体在关卡中可以预先旋转：角色只相对身体转动 `Visual`，初始面朝身体的 −Z；之后可用 `teleport(position, facing)` 或 `NavigationMover.face()` 使其转向。
3. 如需按键控制，添加一个挂载 `character_action_input.gd` 的 `Node`，并设置其 `character`。它需要输入动作 `sprint` 和 `jump`；缺少的动作会在启动时报告一次，之后不会读取。
4. 可选：带 `AudioStreamPlayer3D` 子节点的 `CharacterSounds`；设置了 `character` 与模型手部节点的 `HandSway`；带有 `slot` 和模型场景列表的 `CharacterAppearance`；作为调试面板放在 `CanvasLayer` 中的 `CharacterMonitor`。`LedgeGuard.floor_mask` 默认是 0，此时沿用身体的碰撞掩码，并排除陡得无法站立的表面。
5. 如需悬浮，在 `Visual` 与模型之间放一个挂载 `character_hover.gd` 的 `Node3D`（`Visual/Hover/Model`）；若使用 `CharacterAppearance`，将它设为 `slot`。悬浮时该组件关闭脚步计数；如果指定其 `fall`（`FallSettings`），角色还能更慢地下落。升高的是模型，身体和碰撞形状不会升高。
6. 可选：在身体的 `fall` 属性中指定 `FallSettings` 资源，设置独立的下落重力和速度上限。

配置错误会在游戏启动时打印为警告。随附的 `player.tscn` 使用 1.8 米胶囊体、启用 `floor_constant_speed`，并包含边缘防护、体力、悬浮下落资源和初始**关闭**的悬浮组件。其 `NavigationMover` 使用 `player_locomotion.tres`；演示的 `SettingsApplier` 可在启动时按已保存设置修改属性。复制可操控英雄的方法见 `docs/zh_CN/integration.md`；为自己的模型匹配碰撞形状见 `docs/zh_CN/systems/characters.md`。

AI 也可以驱动同一个身体：调用 `NavigationMover.move_to()` 和 `GroundCharacter.jump()`，设置 `sprint_requested`。

## 文档

见模板仓库中的 `docs/zh_CN/integration.md`、`docs/zh_CN/systems/locomotion.md`、`docs/zh_CN/systems/input.md`（`CharacterActionInput`）、`docs/zh_CN/systems/audio.md`、`docs/zh_CN/systems/characters.md` 和 `docs/zh_CN/systems/levels.md`（传送英雄）。

---

*本页对应 Iso & Orbit 1.2.0。*
