<!-- translation of docs/en/systems/audio.md @ 6a9b8c66c53c -->
# 音频

> 本文是[英文原文](../../en/systems/audio.md)的翻译。两者不一致时，以英文版为准。

`GroundCharacter` 通过信号报告自身发生的事情；声音使用其中的 `stepped(sprinting)`、`jumped`、`landed(impact_speed)` 和 `sprint_changed(sprinting)`（全部信号见[移动](locomotion.md#角色报告的信息)）。声音、脚下扬尘或动画连接到这些信号；角色本身对它们一无所知。演示连接的是声音。

## CharacterSounds

`CharacterSounds`（`Player/Sounds`）是角色的一个 `Node3D` 子节点。它的子节点是 `AudioStreamPlayer3D` 节点，因此声音从角色身上发出，对 NPC 也同样适用。没有这个节点，角色的工作方式完全相同，只是没有声音。

| 声音 | 播放器 | 播放内容 |
|---|---|---|
| 脚步声 | `Footsteps` | 一个包含四种变体的 `AudioStreamRandomizer`，音高（±8%）和音量随机，最多同时播放三个。冲刺时音调略高（`sprint_step_pitch` 1.08）、音量略大（+2 dB）；由于脚步按距离触发，频率会自然变快 |
| 跳跃 | `Jump` | 蹬地声和衣物的呼呼声 |
| 落地 | `Land` | 沉重的砰声，下落越快越响：达到 `land_full_speed`（10 米/秒）时为满音量，永远不低于 `min_land_volume`（30%） |
| 冲刺起步 | `SprintStart` | 冲刺开始时的蹬地声和逐渐增强的气流声 |
| 冲刺中 | `SprintLoop` | 2 秒的急促呼吸和气流循环音，在 `sprint_loop_fade`（0.25 秒）内淡入淡出 |

| 属性 | 默认值 | 含义 |
|---|---|---|
| `character` | 父节点 | 播放谁的信号对应的声音 |
| `footsteps`、`jump`、`land`、`sprint_start`、`sprint_loop` | — | 各播放器 |
| `footsteps_enabled`、`jump_enabled`、`sprint_enabled` | 开 | 声音分组；jump 包括跳跃和落地，sprint 包括起步和循环音 |
| `sprint_step_pitch`、`sprint_step_volume_db` | 1.08、+2 dB | 冲刺时的脚步声 |
| `land_full_speed`、`min_land_volume` | 10 米/秒、0.3 | 落地音量曲线 |
| `sprint_loop_fade` | 0.25 秒 | 冲刺循环音的淡入淡出时间 |

音量设置在 `gdscript/player/player.tscn` 中的各播放器上；可以在游戏运行时通过远程（Remote）场景树调整。例外是 `Land`：它的音量在每次落地前根据下落速度设置（`land_full_speed`、`min_land_volume`）。声音分组在设置 → 声音中切换；演示默认关闭冲刺声音。那里的总音量对应 `Master` 总线：百分比是振幅的比例（50% 即低 6 dB），0 表示将总线静音。

## 声音本身

`shared/audio/character/` 中的文件由脚本合成：砰声是音高下降的正弦波，嘎吱声和气流声是经过带通滤波器的噪声。冲刺循环音的 WAV 中带有 `smpl` 块，默认的导入循环模式“从 WAV 检测”（Detect From WAV）会让它循环播放，无需改动导入设置。循环接缝处做了从结尾到开头的交叉淡化，因此不会有咔哒声。

可以用真实录制的声音替换它们：把同名文件放进该文件夹即可。

---

*本页对应 Iso & Orbit 1.1.0。*
