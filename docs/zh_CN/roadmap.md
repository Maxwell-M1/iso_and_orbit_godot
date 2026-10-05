<!-- translation of docs/en/roadmap.md @ 785e0b204d0a -->
# 路线图

[← 文档目录](index.md)

> 本文是[英文原文](../en/roadmap.md)的翻译。两者不一致时，以英文版为准。

计划中的工作，不分先后。这里列出的内容都尚未实现。

- **不含 GDScript 的 `shared/`。** 关卡通过组件脚本（`point_of_interest.gd`、`spawn_point.gd`、`level_portal.gd`）标记地点、出生点和传送门，另有两个道具脚本位于 `shared/world/props/`。它们需要改成 C# 版本也能使用的形式。见[已知问题](known-issues.md#项目文件)。
- **C# 示例**：放在 `csharp/` 中，使用相同的组件，并在 `shared/world/` 中的关卡上搭建游戏框架。C# 版本的全局类名必须与 GDScript 版本不同：`class_name` 和 `[GlobalClass]` 共用同一个命名空间。
- **动画。** 一个带骨骼绑定的模型，以及由 `GroundCharacter` 报告的信息驱动的 `AnimationTree`：`get_locomotion_blend()` 或 `get_local_movement()` 用于待机、奔跑和冲刺的混合，`get_gait_cycle()` 让奔跑循环的步伐与地面保持同步，状态和地面信号用于跳跃和落地。

---

*本页对应 Iso & Orbit 1.2.0。*
