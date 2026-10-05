<!-- translation of docs/en/project-setup.md @ e52ff77b332d -->
# 项目配置

[← 文档目录](index.md)

> 本文是[英文原文](../en/project-setup.md)的翻译。两者不一致时，以英文版为准。

组件对 `project.godot` 和场景的要求。将组件移到其他项目时，请复制它们用到的那部分配置。

使用装配好的英雄时，请先按照[迁移步骤](integration.md#将演示中的英雄迁移到你的项目)操作。它需要移动／相机／冲刺／跳跃动作、匹配的导航设置和碰撞层。演示的自动加载、UI 主题、翻译、显示设置和关卡系统都是可选的。

## 物理层

| 层 | 名称 | 包含什么 | 谁读取它 |
|---|---|---|---|
| 1 | `world` | 地面、墙、道具、山、站在关卡中的 NPC | 点击射线（`PointClickMoveInput.ground_mask`）、玩家身体及其 `LedgeGuard`（`floor_mask` 为 0 时沿用身体掩码）、`CameraArm.collision_mask`、导航网格烘焙 |
| 2 | `characters` | 玩家的身体（`collision_layer = 2`） | `PointOfInterest` 和 `LevelPortal` 区域（`collision_mask = 2`）；相机臂忽略此层 |
| 3 | `camera` | 只阻挡相机的物体，例如 `shared/world/props/house.tscn` 中的 `RoofCameraBlocker` | 仅 `CameraArm.collision_mask` |
| 4 | `bounds` | 关卡边缘的隐形墙，例如孤岛上的 `Edge` | 玩家身体（`collision_mask` 包含第 1 和第 4 层）及其 `LedgeGuard`；按需供导航网格烘焙使用（如孤岛） |

`CameraArm.collision_mask` 默认为第 1 和第 3 层（`0b101`）。第 2 层上的角色永远不会推动相机。第 3 层上的物体会阻挡相机，但点击、导航和角色都看不到它，因此可以让相机不进入屋顶，同时又不让任何人寻路走上屋顶。第 4 层的物体则相反：它挡住角色，但点击和相机可以穿过，因此点击隐形墙后方的地面或水面不会命中墙。

导航层 1 名为 `ground`；`NavigationMover.navigation_layers` 默认使用它。

物理层与导航层相互独立：碰撞体的物理层决定哪些射线和身体会命中它；导航区域的导航层决定移动器能查询哪些路径。代码中的掩码是位字段：第 1 与第 4 层为 `1 | 8 = 9`，第 1 与第 3 层为 `1 | 4 = 5`。在检查器中，请勾选对应编号的方框。

## 输入动作

| 动作 | 默认绑定 | 使用者 |
|---|---|---|
| `move_to_cursor` | 鼠标左键 | `PointClickMoveInput.move_action` |
| `camera_rotate` | 鼠标右键 | `OrbitCameraRig.rotate_action`、`PointClickMoveInput.camera_steer_action` |
| `camera_zoom_in` | 滚轮向上 | `OrbitCameraRig.zoom_in_action` |
| `camera_zoom_out` | 滚轮向下 | `OrbitCameraRig.zoom_out_action` |
| `move_forward`、`move_back`、`move_left`、`move_right` | W、S、A、D | `PointClickMoveInput`，需按住右键 |
| `sprint` | Shift | `CharacterActionInput.sprint_action` |
| `jump` | 空格 | `CharacterActionInput.jump_action` |
| `toggle_settings` | F10 | `UiRoot.settings_action` |
| `interact` | E | `TravelPrompt.action`：确认演示传送台上的旅行提示 |
| `ui_cancel` | Esc（内置） | `UiRoot`：关闭最上层窗口 |

请在**项目 → 项目设置 → 输入映射**中添加这些动作，字母键使用物理按键事件。单独使用英雄需要前七行（共十个动作）；`toggle_settings`、`interact` 和 `ui_cancel` 属于可选的界面与旅行功能。也可以把此项目 `project.godot` 中 `[input]` 节所需条目合并到你的项目，但不要替换整个项目文件。

按键按物理位置绑定，因此任何键盘布局中的移动键仍位于美式键盘 WASD 的位置。每个组件都通过导出属性接收动作名称，因此你可以改用自己的动作。缺少动作时，使用它的组件会在启动时报告一次（窗口根节点和演示旅行提示也一样），随后不再读取该动作：对应按键不起作用，不会持续报错，已有的移动键仍能行走。

HUD、设置界面和加载提示会从这些动作生成按键名称。如果运行中修改 `InputMap`，且使用这些文字组件，请调用 `get_tree().call_group(ActionTexts.GROUP, &"refresh")`。演示没有游戏内重新绑定菜单，也不会保存按键绑定；见[文本中的按键名称](systems/ui.md#文本中的按键名称)。

## 分组

| 分组 | 含义 |
|---|---|
| `player` | 玩家的身体。`PointOfInterest`（`player_group`）和 `LevelPortal`（`traveller_group`）只对该分组中的身体作出反应。在 `playable_hero.tscn` 中设置于 `Character` 上 |
| `camera_ignore` | 相机臂会穿过的物体（`CameraArm.ignored_groups`）。对属于该分组的节点之下的所有内容都生效，因此只需在道具场景的根节点或关卡中的文件夹节点上设置一次。演示中没有使用 |
| `points_of_interest` | 由每个 `PointOfInterest` 自行加入；`DiscoveryToast` 和演示的游戏框架通过它查找地点 |
| `level_portals`、`spawn_points` | 由每个 `LevelPortal` 和 `SpawnPoint` 自行加入；`LevelHost` 通过它们查找当前关卡中的传送门和出生点 |

## 自动加载

`Settings` → `res://gdscript/settings/game_settings.gd`。只有设置窗口、其控件和 `gdscript/demo/settings_applier.gd` 需要它。组件不依赖它也能工作。见[设置](settings.md)。

## 其他项目设置

| 设置 | 值 | 说明 |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | 演示 |
| `physics/3d/physics_engine` | Jolt Physics | 内置于引擎；相机臂和测试均用它验证过 |
| `navigation/3d/default_cell_height` | 0.025 | 与网格的 `cell_height` 匹配。演示用精细的竖向单元处理台阶；新建的网格与地图也须保持一致。见[世界与导航](systems/world-and-navigation.md) |
| `display/window/stretch/mode` | `canvas_items` | 界面缩放设置通过 `content_scale_factor` 缩放所有 2D 内容，不影响 3D 视图 |
| `display/window/stretch/aspect` | `expand` | 支持任意窗口比例 |
| `gui/theme/custom` | `res://shared/ui/ui_theme.tres` | 所有窗口和 HUD 元素的外观 |
| `internationalization/locale/translations` | `res://l10n/ui/*.po` | 界面翻译；见 [UI](systems/ui.md) |
| `rendering/rendering_device/driver.windows` | `d3d12` | 在 Windows 上使用 Direct3D 12 |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 5（Ultra） | 柔和阴影；`world.tscn` 中的太阳还设置了 `shadow_blur = 1.25` 和 70 米的阴影距离 |
| `rendering/anti_aliasing/quality/msaa_3d` | 2（4×） | 多重采样抗锯齿 |

物理以默认的每秒 60 帧运行。物理插值在 `project.godot` 中是开启的（`physics/common/physics_interpolation`），在运行时通过设置切换（设置 → 显示）。

## 保存的数据

设置保存在项目用户数据文件夹中的 `user://settings.cfg`（在编辑器中：项目 → 打开用户数据文件夹（Project → Open User Data Folder））。删除该文件即可恢复默认值，也可以使用设置窗口中的**全部重置**。

---

*本页对应 Iso & Orbit 1.2.0。*
