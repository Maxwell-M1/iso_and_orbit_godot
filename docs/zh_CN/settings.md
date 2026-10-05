<!-- translation of docs/en/settings.md @ 262d20fd6cef -->
# 设置

[← 文档目录](index.md)

> 本文是[英文原文](../en/settings.md)的翻译。两者不一致时，以英文版为准。

F10 打开设置窗口并暂停游戏；按 Esc 或 F10 关闭。更改立即生效（只有用鼠标拖动界面缩放滑块时，要等松开才生效），并在窗口关闭和游戏退出时保存到 `user://settings.cfg`。**全部重置**会将所有设置恢复为默认值。

默认值位于 `gdscript/settings/game_settings.gd` 的 `DEFAULTS` 中。演示在 `gdscript/demo/settings_applier.gd` 中将它们应用到节点属性；组件自身的属性默认值可能不同，下文会注明。设置系统的工作原理以及如何添加设置：[UI](systems/ui.md#设置)。

单独使用复制来的英雄时，请参阅[配置方案](configurations.md)，查找检查器属性并选择协调一致的配置。本页说明的是**演示菜单**。以下标签使用原始按键绑定；运行中的菜单会根据 `InputMap` 替换为当前按键。

## 操作

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **按住左键**：直奔光标 / 沿路径前往该点 | `gameplay/hold_mode` | 直奔光标 | `PointClickMoveInput.hold_mode` |
| **右键 + WASD**：关闭 / 侧移 / 转向 | `gameplay/camera_keys_mode` | 转向 | `PointClickMoveInput.keys_with_camera`（组件默认值：侧移）；关闭后也隐藏操作提示中关于右键 + WASD 的一行 |
| **左键 + 右键 + A/D**：关闭 / 侧移 / 斜向 | `gameplay/camera_steer_keys_mode` | 斜向 | `PointClickMoveInput.keys_with_camera_steer`（组件默认值：侧移）；关闭后也隐藏操作提示中关于左键 + 右键 + A/D 的一行 |
| **后退（S）减速** 0…80%，仅限侧移 | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − 值 / 100 |
| **按住左键奔跑时隐藏光标** | `gameplay/hide_cursor_on_hold` | 开 | `PointClickMoveInput.hide_cursor_while_held` |
| **按住左键奔跑时，右键只旋转相机** | `gameplay/look_around` | 开 | `PointClickMoveInput.look_around_while_held`；关闭时也隐藏关于环顾四周的操作提示 |

## 角色

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **英雄外观**：十选一 | `character/look` | 8 · 死灵法师 | `CharacterAppearance.set_look()` |
| **悬浮在地面上方** | `character/hover` | 关 | `Hero/Character/Visual/Hover` 上的 `CharacterHover.enabled`（组件默认开；`player.tscn` 将其关闭）；悬浮时停止计步并减慢下落（`player_floating_fall.tres`） |
| **防止从边缘跌落** | `gameplay/ledge_guard` | 开 | `LedgeGuard.enabled` |
| **跳跃（空格）** | `character/jump` | 开 | `GroundCharacter.can_jump`；关闭后也隐藏跳跃提示 |
| **跳跃高度** 0.5…1.5 米 | `character/jump_height` | 1.0 米 | `GroundCharacter.jump_height` |
| **冲刺（Shift）** | `character/sprint` | 开 | `GroundCharacter.can_sprint`；关闭后也隐藏冲刺提示 |
| **Shift**：按住 / 按下开启，再按关闭 | `character/sprint_mode` | 按住 | `CharacterActionInput.sprint_mode` |
| **速度加成** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + 值 / 100 |
| **冲刺疲劳** | `character/fatigue` | 开 | `GroundCharacter.sprint_tires` |
| **体力持续** 3…10 秒 | `character/sprint_duration` | 5.0 秒 | `GroundCharacter.sprint_duration` |

边缘防护的控件位于“角色”选项卡，但仍沿用保存键 `gameplay/ledge_guard`。

## 相机

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **右键可上下倾斜相机** | `camera/mouse_pitch` | 关 | `OrbitCameraRig.mouse_pitch` |
| **相机随奔跑方向转动** | `camera/follow` | 关 | `OrbitCameraRig.follow_movement` |
| **转动用时** 0…10 秒（0 显示“立即”） | `camera/follow_time` | 1.1 秒 | `OrbitCameraRig.follow_time`（组件默认值：1.5 秒） |
| **朝相机奔跑时除外** | `camera/follow_except_toward` | 开 | `OrbitCameraRig.follow_toward_camera_angle`：关闭时设为 0，相机会转到任何奔跑的后方，包括正朝相机奔跑 |
| **角度** 5…60° | `camera/follow_except_toward_angle` | 30° | 开启上述例外时，`OrbitCameraRig.follow_toward_camera_angle` = 此值（组件默认值也是 30°） |
| **奔跑时对齐相机倾角** | `camera/align_pitch` | 关 | `OrbitCameraRig.follow_pitch` |
| **向下倾角** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −值（组件默认值：−40°） |
| **倾角对齐用时** 0…10 秒（0 显示“立即”） | `camera/align_pitch_time` | 1.1 秒 | `OrbitCameraRig.follow_pitch_time`（组件默认值：1.5 秒） |
| **奔跑时对齐相机高度** | `camera/align_height` | 关 | `OrbitCameraRig.follow_zoom` |
| **高度** 0…100% | `camera/align_height_level` | 55% | `OrbitCameraRig.follow_zoom_level` = 值 / 100：0% 是相机降到最低，100% 是升到最高 |
| **高度对齐用时** 0…10 秒（0 显示“立即”） | `camera/align_height_time` | 1.5 秒 | `OrbitCameraRig.follow_zoom_time` |
| **相机转动时光标保持瞄准** | `camera/keep_aim` | 开 | `PointClickMoveInput.keep_aim_on_camera_turn` |
| **相机遇到后方障碍物时停下** | `camera/keep_out_of_geometry` | 开 | `CameraArm.keep_out_of_geometry` |
| **角色被遮挡时拉近** | `camera/pull_in_on_occlusion` | 关 | `CameraArm.pull_in_on_occlusion` |

## 显示

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **全屏** | `display/fullscreen` | 关 | `DisplayServer.window_set_mode()` |
| **FPS 上限**：24、30、60、120、240、不限 | `display/max_fps` | 不限 | `Engine.max_fps` |
| **垂直同步（V-Sync）** | `display/vsync` | 关 | `DisplayServer.window_set_vsync_mode()` |
| **物理插值（角色和相机）** | `display/physics_interpolation` | 开 | `SceneTree.physics_interpolation` |
| **障碍物后的剪影描边** | `display/silhouette_outline` | 开 | `OccludedSilhouette.outline_enabled` |

游戏在编辑器内运行时，即在“游戏”选项卡（Game）或其浮动窗口（**Make Game Workspace Floating on Next Play**）中，窗口归编辑器所有，因此全屏无效，开关也不可用。要在编辑器中试用，请在“游戏”选项卡的菜单中关闭**Embed Game on Next Play**，游戏就会在自己的窗口中打开。

开启 V-Sync 时，帧数永远不会超过显示器的刷新率，因此等于或高于该刷新率的 FPS 上限根本不会被设置：否则它会与 V-Sync 冲突，使帧数低于显示器能显示的帧数（在 240 Hz 显示器上设 240 的上限，实际约为 220）。

不开启物理插值时，角色和相机逐个物理帧跳跃式移动（每秒 60 次）：相机跟随目标的 `get_global_transform_interpolated()`，而在没有插值时，它就是目标在上一个物理帧的位置。在高于 60 Hz 的显示器上这会很明显；相机跟随奔跑转向时，角色在转弯时还会晃动：相机每一帧都在转，而角色只在每个物理帧转。

## 界面

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **语言**：English、Español、日本語、Português (Brasil)、Русский、Türkçe、简体中文 | `interface/language` | English | `TranslationServer.set_locale()` |
| **界面缩放** 50…100% | `interface/ui_scale` | 75% | 根窗口的 `content_scale_factor` |
| **FPS 计数器** | `interface/fps_counter` | 开 | `Hud/FpsCounter` 的可见性 |
| **操作提示和速度** | `interface/help` | 开 | `Hud/Panel` 的可见性 |
| **角色路径线** | `interface/path_line` | 关 | `Hero/PathView` 的可见性 |
| **角色状态和事件** | `interface/character_state` | 关 | `Hud/CharacterState` 的可见性（`CharacterMonitor`） |

界面缩放会改变提示、FPS 计数器、体力条、角色状态面板、“发现地点：……”消息、旅行提示、加载画面和窗口的大小，不影响 3D 视图。100% 即场景中制作时的原始尺寸。用鼠标拖动时，松开滑块后才应用缩放，避免滑块从光标下移走；键盘和滚轮操作则立即生效。

## 声音

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **音量** 0…100%（为 0 时显示“关”） | `sound/volume` | 100% | `Master` 总线音量；为 0 时静音 |
| **脚步声** | `sound/footsteps` | 开 | `CharacterSounds.footsteps_enabled` |
| **跳跃和落地** | `sound/jump` | 开 | `CharacterSounds.jump_enabled` |
| **冲刺起步和冲刺中** | `sound/sprint` | 关 | `CharacterSounds.sprint_enabled`（组件默认开） |

## 相互依赖的设置

依赖其他设置的控件在条件不满足时会变暗且无法更改：右键 + WASD 未设为侧移时的后退减速、关闭跳跃时的跳跃高度、关闭冲刺时的全部冲刺设置、关闭疲劳时的体力持续时间、关闭相机转向时的转动用时、关闭倾角对齐时的倾角和用时、关闭高度对齐时的高度和用时，以及英雄悬浮时的脚步声（此时不会计步）。

---

*本页对应 Iso & Orbit 1.2.0。*
