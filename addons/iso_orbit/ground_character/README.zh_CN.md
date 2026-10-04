<!-- translation of addons/iso_orbit/ground_character/README.md @ 9b116d7ff0dd -->
# 地面角色

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

用于点击移动的现成角色身体：重力，带土狼时间和输入缓冲的跳跃（在任何物理帧率下高度都相同），带体力的冲刺，上下台阶，在落差处让身体停下的边缘防护。身体会报告自己在做什么，供动画、特效和界面使用：状态及其变化，带左右脚信息的脚步，起跳和落地，作为混合值的速度，模型坐标轴下的移动，转向和步态周期。另外还包括：响应这些信号的声音，以文本显示状态的面板，随脚步摆动的手持物品，以及可切换的模型。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `ground_character.gd` | `GroundCharacter`（CharacterBody3D） | 重力、跳跃、冲刺、台阶、`move_and_slide()`、转动模型；状态、信号以及供动画使用的查询 |
| `ledge_guard.gd` | `LedgeGuard`（Node） | 在落差处让身体停下，或让它沿边缘滑行 |
| `stamina.gd` | `Stamina`（Node） | 冲刺储备 |
| `character_action_input.gd` | `CharacterActionInput`（Node） | 冲刺和跳跃按键 → 角色 |
| `character_sounds.gd` | `CharacterSounds`（Node3D） | 响应角色的信号播放声音 |
| `hand_sway.gd` | `HandSway`（Node） | 随脚步摆动手部节点 |
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

   设置身体的 `mover`、`visual`、`ledge_guard` 和 `stamina`。演示还在身体上设置了 `floor_constant_speed`，使角色在坡道上保持速度，并把身体放在物理层 2 上，与关卡分开。身体能走上不超过 `max_step_height`（0.3 米）的台阶和不超过其 `floor_max_angle` 的斜坡；要让路径通过台阶，烘焙导航网格时把 `agent_max_climb` 设为与 `max_step_height` 相同。
3. 如需按键控制，添加一个挂载 `character_action_input.gd` 的 `Node`，并设置其 `character`。它需要输入动作 `sprint` 和 `jump`。
4. 可选：带 `AudioStreamPlayer3D` 子节点的 `CharacterSounds`，指定了模型手部节点的 `HandSway`，带模型场景列表的 `CharacterAppearance`，作为调试面板放在 `CanvasLayer` 中的 `CharacterMonitor`。`LedgeGuard.floor_mask` 默认为物理层 1。

AI 也可以驱动同一个身体：调用 `NavigationMover.move_to()` 和 `GroundCharacter.jump()`，设置 `sprint_requested`。

## 文档

见模板仓库中的 `docs/zh_CN/integration.md`、`docs/zh_CN/systems/locomotion.md`、`docs/zh_CN/systems/audio.md` 和 `docs/zh_CN/systems/characters.md`。

---

*本页对应 Iso & Orbit 1.1.0。*
