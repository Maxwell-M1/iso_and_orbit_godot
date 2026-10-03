<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 4bf86f099c43 -->
# 兴趣点

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

可发现的地点：一个在玩家首次进入时发出通知的区域，以及一条会自动找到所有地点的屏幕消息“发现地点：…”。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest`（Area3D） | `player` 分组中的物体首次进入时发出 `discovered(title)`；自身加入 `points_of_interest` 分组 |
| `discovery_toast.gd`、`discovery_toast.tscn` | `DiscoveryToast`（Label） | 任何地点被发现时，显示“发现地点：…”几秒钟 |

不需要其他插件。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/points_of_interest/`。
2. 将玩家身体加入 `player` 分组（或设置 `player_group`）。
3. 为每个地点添加一个挂载 `point_of_interest.gd` 并带碰撞形状的 `Area3D`，设置其 `title`，并让其 `collision_mask` 包含玩家所在的物理层。
4. 将 `discovery_toast.tscn` 添加到你的 HUD。它在启动时自动连接场景中的每个地点，无需手动连接。

消息文本和地点标题都经过翻译服务器处理，因此可以本地化。外观来自主题类型变体 `DiscoveryToast`。

## 文档

见模板仓库中的 `docs/zh_CN/systems/world-and-navigation.md` 和 `docs/zh_CN/systems/ui.md`。

---

*本页对应 Iso & Orbit 1.0.0。*
