<!-- translation of addons/iso_orbit/occluded_silhouette/README.md @ ed5707ab8355 -->
# 遮挡剪影

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

透过任何遮挡物显示角色：身体显示为一个平面形状，手中的物品以轮廓叠加在上方，整体外围有一圈描边。角色可见的地方不绘制任何东西。模型自身的材质保持不变，因此在别处使用同一模型时不会有剪影。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 职责 |
|---|---|
| `occluded_silhouette.gd` | `OccludedSilhouette`（Node）：将各通道作为 `material_overlay` 设置到模型的每个网格上，包括之后添加的网格 |
| `silhouette_mask.gdshader`、`.tres` | 标记角色本身可见的位置 |
| `silhouette_body.gdshader`、`.tres` | 身体的平面填充 |
| `silhouette_gear.gdshader`、`.tres` | 手持物品的浅色填充 |
| `silhouette_outline.gdshader`、`.tres` | 环绕整个形状的描边 |
| `silhouette_common.gdshaderinc` | 共用代码：以米为单位的深度、模板值布局 |

不需要其他插件。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/occluded_silhouette/`；材质通过该路径引用着色器。
2. 给角色添加一个挂载 `occluded_silhouette.gd` 的 `Node`。将 `target` 设为容纳模型的节点，并把 `silhouette_mask.tres`、`silhouette_body.tres`、`silhouette_gear.tres` 和 `silhouette_outline.tres` 分别赋给 `mask`、`body_fill`、`gear_fill` 和 `outline`。
3. 位于 `gear_nodes` 中所列节点（`RightHand`、`LeftHand`）之下的网格被视为手持物品。

颜色是各材质的 `color` 参数，描边宽度是 `silhouette_outline.tres` 中的 `width`，`outline_enabled` 可以关闭描边。剪影要求障碍物位于角色前方至少 30 厘米处（`min_gap`）。

使用模板缓冲区，该功能在 Godot 4.5+ 中是实验性的。已在 Forward+ 渲染器上测试。

## 文档

见模板仓库中的 `docs/zh_CN/systems/characters.md`。

---

*本页对应 Iso & Orbit 1.1.0。*
