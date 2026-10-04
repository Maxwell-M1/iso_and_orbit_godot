<!-- translation of docs/en/roadmap.md @ 6c3e4efdec59 -->
# 路线图

> 本文是[英文原文](../en/roadmap.md)的翻译。两者不一致时，以英文版为准。

计划中的工作，不分先后。这里列出的内容都尚未实现。

- **不含 GDScript 的 `shared/`。** 关卡使用 `addons/iso_orbit/points_of_interest/point_of_interest.gd` 标记地点，另有两个道具脚本位于 `shared/world/props/`。它们需要改成 C# 版本也能使用的形式。见[已知问题](known-issues.md#项目文件)。
- **C# 示例**：放在 `csharp/` 中，使用相同的组件，主场景基于 `shared/world/world.tscn` 构建。C# 版本的全局类名必须与 GDScript 版本不同：`class_name` 和 `[GlobalClass]` 共用同一个命名空间。
- **动画。** 一个带骨骼绑定的模型，以及由 `GroundCharacter` 报告的信息驱动的 `AnimationTree`：`get_locomotion_blend()` 或 `get_local_movement()` 用于待机、奔跑和冲刺的混合，`get_gait_cycle()` 让奔跑循环的步伐与地面保持同步，状态和地面信号用于跳跃和落地。

---

*本页对应 Iso & Orbit 1.1.0。*
