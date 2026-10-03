<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 77aade651b48 -->
# 环绕相机

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

适用于等距视角和俯视角游戏的环绕相机：它跟随目标，用鼠标右键环绕，用滚轮缩放（距离和俯仰角同时变化），还能自动转到奔跑中的目标身后。相机位于相机臂的末端，相机臂遇到后方的墙会停下，并可在障碍物遮住目标时拉近。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig`（Node3D） | 跟随目标、环绕、缩放、跟随模式 |
| `camera_arm.gd` | `CameraArm`（Node3D） | 持有相机，遇到障碍物时缩短；近距离时淡化目标 |

不需要其他插件。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/orbit_camera/`。
2. 添加输入动作（动作名称是导出属性，因此可以使用你自己的动作）：`camera_rotate`（鼠标右键）、`camera_zoom_in`（滚轮向上）、`camera_zoom_out`（滚轮向下）。
3. 在目标旁边（而不是目标内部）搭建相机：

   ```
   CameraRig    Node3D，挂载 orbit_camera_rig.gd，target = 你的角色
   └── CameraArm    Node3D，挂载 camera_arm.gd
       └── Camera3D
   ```

4. 物理层：相机臂会在第 1 和第 3 层上的物体处停下（`collision_mask`）。将关卡几何体放在其中一层上，不要把角色放在这两层上。`camera_ignore` 分组中的物体（或属于该分组的节点之下的物体）永远不会阻挡相机臂。
5. 如果目标在物理帧中移动，请在项目中开启物理插值：相机支架跟随的是目标的插值位置。

不用相机臂、直接将 `Camera3D` 作为相机支架的子节点也可以：相机保持在缩放所设定的距离上，并会穿墙。

## 文档

见模板仓库中的 `docs/zh_CN/systems/camera.md`（所有属性、缩放曲线、跟随模式、相机臂的工作原理）和 `docs/zh_CN/project-setup.md`。

---

*本页对应 Iso & Orbit 1.0.0。*
