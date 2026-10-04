<!-- translation of docs/en/settings.md @ dabbac251e72 -->
# 设置

> 本文是[英文原文](../en/settings.md)的翻译。两者不一致时，以英文版为准。

F10 打开设置窗口并暂停游戏；按 Esc 或 F10 关闭。更改立即生效，并在窗口关闭和游戏退出时保存到 `user://settings.cfg`。**全部重置**会将所有设置恢复为默认值。

默认值位于 `gdscript/settings/game_settings.gd` 的 `DEFAULTS` 中。演示在 `gdscript/demo/settings_applier.gd` 中将它们应用到节点属性；组件自身的属性默认值可能不同，下文会注明。设置系统的工作原理以及如何添加设置：[UI](systems/ui.md#设置)。

## 操作

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **按住左键**：直奔光标 / 沿路径前往该点 | `gameplay/hold_mode` | 直奔光标 | `PointClickMoveInput.hold_mode` |
| **右键 + WASD**：关闭 / 侧移 / 转向 | `gameplay/camera_keys_mode` | 转向 | `PointClickMoveInput.keys_with_camera`（组件默认值：侧移） |
| **左键 + 右键 + A/D**：关闭 / 侧移 / 斜向 | `gameplay/camera_steer_keys_mode` | 斜向 | `PointClickMoveInput.keys_with_camera_steer`（组件默认值：侧移） |
| **后退（S）减速** 0…80%，仅限侧移 | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − 值 |
| **按住左键奔跑时隐藏光标** | `gameplay/hide_cursor_on_hold` | 开 | `PointClickMoveInput.hide_cursor_while_held` |

## 角色

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **英雄外观**：十选一 | `character/look` | 10 · 战斗法师 | `CharacterAppearance.set_look()` |
| **防止从边缘跌落** | `gameplay/ledge_guard` | 开 | `LedgeGuard.enabled` |
| **跳跃（空格）** | `character/jump` | 开 | `GroundCharacter.can_jump` |
| **跳跃高度** 0.5…1.5 米 | `character/jump_height` | 1.0 米 | `GroundCharacter.jump_height` |
| **冲刺（Shift）** | `character/sprint` | 开 | `GroundCharacter.can_sprint` |
| **Shift**：按住 / 按下开启，再按关闭 | `character/sprint_mode` | 按住 | `CharacterActionInput.sprint_mode` |
| **速度加成** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + 值 |
| **冲刺疲劳** | `character/fatigue` | 开 | `GroundCharacter.sprint_tires` |
| **体力持续** 3…10 秒 | `character/sprint_duration` | 5.0 秒 | `GroundCharacter.sprint_duration` |

边缘防护开关移到“角色”选项卡后，它的键仍为 `gameplay/ledge_guard`，因此已保存的选择不会丢失。

## 相机

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **右键可上下倾斜相机** | `camera/mouse_pitch` | 关 | `OrbitCameraRig.mouse_pitch` |
| **相机随奔跑方向转动** | `camera/follow` | 关 | `OrbitCameraRig.follow_movement` |
| **对齐相机倾角** | `camera/align_pitch` | 关 | `OrbitCameraRig.follow_pitch` |
| **向下倾角** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −值（组件默认值：−40°） |
| **跟上用时** 0…10 秒（为 0 时显示“立即”），用于转向和倾角 | `camera/follow_time` | 1.1 秒 | `OrbitCameraRig.follow_time`（组件默认值：1.5 秒） |
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
| **角色路径线** | `interface/path_line` | 关 | `PathView` 的可见性 |

界面缩放会改变提示、FPS 计数器、体力条和窗口的大小，不影响 3D 视图。100% 即场景中制作时的原始尺寸。

## 声音

| 设置项 | 键 | 默认值 | 应用到 |
|---|---|---|---|
| **音量** 0…100%（为 0 时显示“关”） | `sound/volume` | 100% | `Master` 总线音量；为 0 时静音 |
| **脚步声** | `sound/footsteps` | 开 | `CharacterSounds.footsteps_enabled` |
| **跳跃和落地** | `sound/jump` | 开 | `CharacterSounds.jump_enabled` |
| **冲刺起步和冲刺中** | `sound/sprint` | 关 | `CharacterSounds.sprint_enabled` |

## 相互依赖的设置

离开另一项设置就没有意义的控件会变暗且无法更改：未给右键 + WASD 选择侧移模式时的后退减速，关闭跳跃时的跳跃高度，关闭冲刺时所有与冲刺相关的设置，关闭疲劳时的体力持续时间，关闭倾角对齐时的倾角，以及跟随和倾角对齐都关闭时的跟上用时。

---

*本页对应 Iso & Orbit 1.0.0。*
