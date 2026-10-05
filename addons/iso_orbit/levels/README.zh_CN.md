<!-- translation of addons/iso_orbit/levels/README.md @ 8dd533b32064 -->
# 关卡

[← 文档目录（模板仓库）](../../../docs/zh_CN/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · **简体中文**

> 本文是[英文原文](README.md)的翻译。两者不一致时，以英文版为准。

玩家角色和界面保持原位，关卡在加载画面后方切换：关卡容器在后台加载下一关、释放旧关卡，并告知游戏把角色放在哪里；传送门可以先经玩家确认，也可以立即通往其他关卡；出生点指定抵达位置；加载画面在地名、进度条和提示背后显示模糊的游戏最后一帧。

这是适用于 Godot 4.7 的相机与角色控制器模板 Iso & Orbit 的一部分。采用 MIT 许可证（见 `LICENSE`）。

## 内容

| 文件 | 类 | 作用 |
|---|---|---|
| `level_host.gd` | `LevelHost`（Node3D） | 容纳当前关卡；`change_level(path, spawn_name, title)` 在后台加载下一关、替换当前关卡，并通过信号报告每一步；将关卡中传送门（包括以后新增的门）的旅行者事件转发为 `portal_entered` 和 `portal_exited` |
| `level_portal.gd` | `LevelPortal`（Area3D） | 通往另一关卡：报告旅行者进入和离开，在调用 `travel()` 时或自动（`auto_travel`）旅行，并可将 `title` 写入可选的标牌 |
| `spawn_point.gd` | `SpawnPoint`（Marker3D） | 按名称指定角色出现的位置；角色面朝标记的 −Z |
| `loading_screen.gd`、`loading_screen.tscn`、`loading_background.gdshader`、`loading_screen_theme.tres` | `LoadingScreen`（CanvasLayer） | 加载画面：最后一帧被模糊、调暗并缓缓放大，显示地名、不会倒退的进度条和提示；显示期间输入事件不会传给游戏 |

不需要其他插件：关卡容器不知道角色、相机或界面的具体实现。你的游戏通过容器的信号将它们连接起来。

## 配置

1. 将此文件夹复制到 `res://addons/iso_orbit/levels/`。
2. 在持续存在的主场景中，添加挂载 `level_host.gd` 的 `Node3D`，并将初始关卡作为其唯一子节点。玩家角色、相机和界面应放在容器旁边，不要放进关卡。
3. 将 `loading_screen.tscn` 加入主场景，并指定为容器的 `loading_screen`；也可留空，使关卡切换时不显示加载画面。
4. 在每个关卡的地面上添加挂载 `spawn_point.gd` 的 `Marker3D`，将其 `spawn_name` 设为 `default`；传送门抵达位置则添加其他名称的出生点。
5. 添加传送门时，创建挂载 `level_portal.gd` 的 `Area3D` 及碰撞形状；其 `collision_mask` 必须包含角色所在层。设置 `target_level`（场景文件）、`target_spawn` 和 `title`。将角色身体放入 `player` 分组，或修改 `traveller_group`。
6. 在主脚本中连接容器的信号：
   - `level_change_started`：隐藏不应出现在加载画面截图中的元素，并禁用操控；
   - `level_loaded(level, spawn)`：将角色放在 `spawn`（使用 `GroundCharacter.teleport()` 可避免抵达时跳动），并转动相机；
   - `level_change_finished`：恢复操控；
   - `level_change_failed(path, error)`：恢复操控并重新显示先前隐藏的内容；当前关卡仍在。加载失败后只会发出此信号，不会发出 `level_change_finished`；
   - `portal_entered(portal)` 和 `portal_exited(portal)`：显示和隐藏旅行提示；确认后调用 `portal.travel()`。

容器不会通报初始关卡：请在主脚本的 `_ready()` 中通过 `get_current_level()` 和 `find_spawn_point()` 设置它。

默认情况下，传送门先询问玩家：游戏显示旅行提示，再调用 `travel()`。启用 `auto_travel` 时，角色一进入就旅行，适用于门或地图边缘。切换紧接请求之后才开始，不在请求回调内执行，因此传送门可以从物理回调提出请求。加载和替换期间游戏暂停；容器在暂停状态下等待导航地图接纳新关卡，然后结束暂停，并在加载画面背后绘制几帧，让着色器在看不见时编译，随后画面淡出。容器设置包括 `min_loading_time`（0.6 秒，画面最短停留时间）、`warmup_frames`（3，画面背后绘制的帧数）和 `navigation_timeout`（2 秒，导航地图最长等待时间）；`is_changing()` 可查询是否正在切换。切换期间调用 `change_level()` 返回 `ERR_BUSY`；错误的文件分别返回 `ERR_FILE_NOT_FOUND` 和 `ERR_INVALID_PARAMETER`。如果稍后加载失败，当前关卡保留并发出 `level_change_failed`；下次请求会重新加载文件。容器只结束由它自己开始的暂停：会暂停游戏的窗口应在 `level_change_finished` 后打开。画面与等待按真实时间运行，不受 `Engine.time_scale` 影响。

加载画面的外观定义在 `loading_screen_theme.tres` 中（类型变体 `LoadingTitle`、`LoadingBar`、`LoadingTip`）。给画面根节点换主题即可换外观，或复制 `loading_screen.tscn` 自制画面：脚本需要 `Root`，以及以唯一名称访问的 `Background`、`Title`、`Bar` 和 `Tip` 节点。只有给 `tips` 添加内容才会显示提示；每条提示先翻译，再由代码设置的 `tip_format` 处理（`ui_screens` 插件中的 `InputNames.format` 会插入当前绑定的按键：`{sprint}` 显示为“Shift”）。

## 文档

模板仓库中的说明：`docs/zh_CN/systems/levels.md` 和 `docs/zh_CN/integration.md`。

---

*本页对应 Iso & Orbit 1.2.0。*
