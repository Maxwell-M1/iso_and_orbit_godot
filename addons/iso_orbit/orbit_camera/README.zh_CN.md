<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 94f2d396a032 -->
# 环绕相机

[← 文档目录（模板仓库）](../../../docs/zh_CN/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

适用于等距视角和俯视角游戏的环绕相机。它可以跟随任意 `Node3D`，用鼠标环绕、滚轮缩放。奔跑时，它可以分别转到目标身后、对齐倾角、回到选定高度。相机臂防止相机进入墙体，也可以在障碍物遮住目标时将相机拉近。

属于适用于 Godot 4.7 的 Iso & Orbit。采用 MIT 许可证（见 `LICENSE`）。单独使用此文件夹时不需要其他插件。

| 脚本 | 类 | 职责 |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig`（`Node3D`） | 跟随目标、处理输入和缩放，以及可选的奔跑时对齐 |
| `camera_arm.gd` | `CameraArm`（`Node3D`） | 放置相机、响应障碍物，以及可选的近距离淡化 |

## 放入场景

1. 将此文件夹复制到 `res://addons/iso_orbit/orbit_camera/`。
2. 在**项目设置 → 输入映射**中添加 `camera_rotate`（鼠标右键）、`camera_zoom_in`（滚轮向上）和 `camera_zoom_out`（滚轮向下）。支架导出的动作名称可以修改。缺少动作会在启动时报告错误，也无法触发相应输入。
3. 将以下节点放在移动目标旁边。将 `CameraRig.target` 指向你的角色或其他 `Node3D`。保持相机子树及其祖先节点不缩放。

   ```text
   Scene
   ├── Character (移动的目标)
   └── CameraRig (Node3D + orbit_camera_rig.gd; target = ../Character)
       └── CameraArm (Node3D + camera_arm.gd)
           └── Camera3D (Current = on)
   ```

   支架和相机臂分别会查找第一个直接子节点 `CameraArm` 和 `Camera3D`；也可以显式设置导出的 `arm` 和 `camera` 引用。保持 `Camera3D` 的局部变换为默认值，因为相机臂会放置它。需要这个视角成为活动相机时，请将其设为当前相机。要得到模板的取景效果，将视野角设为 45°，远裁剪面设为 300 个世界单位。
4. 将实体世界碰撞体放在第 1 物理层。相机臂的默认 `collision_mask` 包含第 1 和第 3 层（`0b101`）；第 3 层可放屋顶等仅阻挡相机的物体。角色不要位于此掩码内，以免推挤相机。给身体或其祖先节点加入 `camera_ignore` 可将其排除。还可以将 `CameraArm.fade_target` 指向模型根节点，让相机臂很短时模型变为半透明。
5. 如果目标按物理帧移动，请启用**项目设置 → 物理 → 通用 → 物理插值**。支架在每个渲染帧跟随目标的插值位置，并关闭自身的插值；相机臂和相机默认继承这一模式。

脚本默认提供手动环绕：三个奔跑时对齐开关都关闭，虽然相应时间和目标已有数值。要使用模板英雄调好的可选跟随，请设置 `follow_time = 1.1` 秒、`follow_pitch_angle = -22°`、`follow_pitch_time = 1.1` 秒、`follow_zoom_level = 0.55`、`follow_zoom_time = 1.5` 秒、`follow_wait_after_rotate = true` 和 `height_follow_time = 0.15` 秒。开启 `follow_movement` 可让相机转到奔跑方向后方；只有需要相应对齐时才开启 `follow_pitch` 或 `follow_zoom`。模板英雄起初将三个开关全部关闭。检查器中的角度值以度为单位；GDScript 中请使用 `deg_to_rad()` 赋弧度值。

开启 `follow_wait_after_rotate` 后，玩家主动用鼠标环绕相机，相机会暂停跟随，直到目标减速或开始新的奔跑。如果目标停下前输入又启动新的奔跑，请在那时调用 `end_follow_wait()`。模板在 `gdscript/player/playable_hero.tscn` 中将 `PointClickMoveInput.run_requested` 连接到它，将 `hold_pending_changed` 连接到 `set_follow_paused()`。如果目标连续移动，无法报告新的奔跑，请关闭等待选项。保持 `sharp_turn_speed` 不高于角色转向速率的一半，以免角色掉头时相机跟随经过的中间方向；模板用 360°/秒配合英雄的 720°/秒转向。

不用相机臂、直接将 `Camera3D` 作为支架的子节点也可以。相机保持在缩放距离上，并可能穿墙；障碍物响应和淡化功能需要 `CameraArm`。

缩放曲线、全部属性、遮挡行为及经过测试的交互见[相机](../../../docs/zh_CN/systems/camera.md)。迁移现成英雄见[集成指南](../../../docs/zh_CN/integration.md#将演示中的英雄迁移到你的项目)与[项目配置](../../../docs/zh_CN/project-setup.md)。

---

*本页对应 Iso & Orbit 1.2.0。*
