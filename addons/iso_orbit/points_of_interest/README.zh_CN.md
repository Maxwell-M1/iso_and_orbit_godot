<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 70ad45747177 -->
# 兴趣点

[← 文档目录（模板仓库）](../../../docs/zh_CN/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

可发现的地点：一个在玩家首次进入时发出通知的区域，以及一条会自动找到所有地点的屏幕消息“发现地点：…”。

属于 Iso & Orbit——一个适用于 Godot 4.7 的相机与角色控制器模板。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 职责 |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest`（Area3D） | `player` 分组中的身体首次进入时发出 `discovered(title)`；自身加入 `points_of_interest` 分组；`is_discovered()` 查询是否已发现；`mark_discovered()` 不发出信号而直接标记已发现（重新加载关卡或读档时使用） |
| `discovery_toast.gd`、`discovery_toast.tscn` | `DiscoveryToast`（Label） | 任何地点被发现时显示“发现地点：……”几秒钟，也支持以后加载的关卡中的地点（`watch_added_places`；关闭时仅关注启动时已有的地点） |

不需要其他插件。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/points_of_interest/`。
2. 将玩家身体加入 `player` 分组（或设置 `player_group`）。
3. 为每个地点添加一个挂载 `point_of_interest.gd` 并带碰撞形状的 `Area3D`，设置其 `title`，并让其 `collision_mask` 包含玩家所在的物理层。
4. 将 `discovery_toast.tscn` 添加到你的 HUD。它在启动时连接场景中的每个地点，除非关闭 `watch_added_places`，否则也会连接以后新增的地点；无须手动连接。

地点只在自身存在时记得是否被发现：释放关卡时，地点也随之消失；再次加载同一关卡，地点起初是未发现状态。记住哪些地点已发现是游戏的职责：模板中的 `gdscript/main.gd` 按关卡记录已发现地点，在再次加载时调用 `mark_discovered()`。

消息文本和地点标题都经过翻译服务器处理，因此可以本地化。外观来自主题类型变体 `DiscoveryToast`。

## 文档

见模板仓库中的 `docs/zh_CN/systems/world-and-navigation.md`、`docs/zh_CN/systems/ui.md` 和 `docs/zh_CN/systems/levels.md`。

---

*本页对应 Iso & Orbit 1.2.0。*
