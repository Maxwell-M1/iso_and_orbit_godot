<!-- translation of docs/en/systems/levels.md @ dc39dc2f669b -->
# 关卡

[← 文档目录](../index.md)

> 本文是[英文原文](../../en/systems/levels.md)的翻译。两者不一致时，以英文版为准。

游戏如何切换关卡：关卡容器和加载画面、传送门与出生点、在关卡间移动的可操控英雄，以及演示中的两个关卡。每关以 `default` 出生点作为未指定名称时的抵达位置。组件位于 `addons/iso_orbit/levels/`；英雄、旅行提示和游戏框架是以这些组件搭建的演示文件。

## 游戏框架

`gdscript/main.tscn` 是游戏运行期间一直存在的场景。当前关卡是关卡容器的子节点；英雄和界面是其兄弟节点，因此关卡会在它们周围更换。

| 节点 | 类 | 作用 |
|---|---|---|
| `Levels` | `LevelHost` | 以当前关卡为唯一子节点，并负责切换它 |
| `Levels/World` | | 在编辑器中放入的初始关卡 `shared/world/world.tscn` |
| `Hero` | `PlayableHero` | 玩家角色，包含输入、相机、点击标记和路径线 |
| `Hud/TravelPrompt` | `TravelPrompt` | 站上传送台时显示的旅行提示 |
| `LoadingScreen` | `LoadingScreen` | 加载关卡时显示的画面 |

`gdscript/main.gd` 将它们连接起来：

| 信号 | 游戏框架的处理方式 |
|---|---|
| `LevelHost.portal_entered(portal)` | 显示该传送门的旅行提示，自动旅行的门除外；若同时进入两扇门，则提示最后进入的门 |
| `LevelHost.portal_exited(portal)` | 隐藏对应提示；如果英雄仍站在另一扇门中，就提示那一扇 |
| `TravelPrompt.confirmed(portal)` | 调用 `portal.travel()` |
| `LevelHost.level_change_started` | 隐藏旅行提示和 HUD，并禁用英雄操控 |
| `LevelHost.level_loaded(level, spawn)` | 将以前发现过的地点标记为已发现，让英雄出现在 `spawn`，相机转到其后方，并在加载画面下恢复 HUD |
| `LevelHost.level_change_finished` | 恢复操控 |
| `LevelHost.level_change_failed` | 显示 HUD、恢复操控；如果英雄仍站在传送门内，再次显示提示 |

启动时，游戏框架将英雄放到初始关卡的 `default` 出生点，同时保持相机自己的初始角度（`OrbitCameraRig.start_yaw`）；从传送门抵达时，相机朝向出生点所指的方向。本次运行发现的地点以关卡文件及地点在关卡中的路径记录：再次加载同一关卡时，用 `PointOfInterest.mark_discovered()` 标记它们，不再重复播报。存档系统也可以保存同一份列表。

英雄实例在关卡切换中持续存在，因此体力、外观和悬浮状态得以保留。传送会清除移动状态并重置相机跟踪；玩家设置仍保存在 `Settings` 自动加载中。

## 一次关卡切换

玩家站上传送台，按 E 或点击旅行提示后：

1. 传送门请求旅行；关卡容器立即检查文件、向加载器请求资源并作出答复。实际切换紧接着才开始，而不是在请求回调内部进行：传送门从物理回调提出请求，关卡不能在此时退出场景树。切换以 `level_change_started` 开始。
2. 如果游戏尚未暂停，此时会暂停。暂停期间，相机释放光标，输入组件让光标显示出来。
3. 加载画面取得下一帧画面（HUD 已隐藏），将其模糊、调暗，再于 0.35 秒内淡入。背景帧缓缓放大 6%，显示地点名称和提示文字，进度条开始推进。
4. 关卡场景在后台加载（`ResourceLoader.load_threaded_request`）。其文件加载使进度条达到 85%，建好的关卡达到 90%。
5. 旧关卡退出场景树并释放；新关卡就位；`level_loaded` 告诉游戏框架应把英雄放在哪里。新关卡的传送门接入信号；旧关卡离开前，其传送门已断开连接。如果期间有别的操作结束了暂停（如关闭窗口），容器会为了替换关卡再次暂停游戏。
6. 游戏仍暂停，容器等待导航地图接纳新关卡（95%）：关卡的全部导航区域进入地图后即可继续，但按实际时钟计算，最长不超过 `navigation_timeout`。导航服务器在游戏暂停时仍工作，因此游戏恢复的第一帧便能在新关卡中找到路径。
7. 结束暂停后，容器在加载画面背后绘制 `warmup_frames` 帧，使新关卡着色器编译，并让英雄在地面上稳定下来。
8. 从切换开始经过 `min_loading_time` 后，进度条填满，画面淡出，然后发出 `level_change_finished`。

关卡容器的设置：

| 属性 | 默认值 | 含义 |
|---|---|---|
| `loading_screen` | 空；演示指定其 `LoadingScreen` | 加载关卡时盖在游戏上的画面。留空时，玩家会直接看到关卡更换 |
| `min_loading_time` | 0.6 秒 | 画面至少保持这么久，避免快速加载时闪现 |
| `warmup_frames` | 3 | 画面消失前在其背后绘制的帧数，让新关卡着色器在看不见时编译 |
| `navigation_timeout` | 2 秒 | 按时钟计算的导航地图最长等待时间；新关卡全部区域进入地图后立即结束。设为 0 则不等待；地图接纳新关卡前，路径可能在旧地图上搜索，或根本没有地图 |

关卡容器的信号和方法：

| 信号或方法 | 含义 |
|---|---|
| `level_change_started(path)` | 切换已经开始；旧关卡仍在 |
| `level_loaded(level, spawn)` | 新关卡已就位，旧关卡已离开；应将角色放在 `spawn`。加载画面仍覆盖游戏 |
| `level_change_finished(level)` | 切换完成，加载画面已消失 |
| `level_change_failed(path, error)` | 切换失败，当前关卡保留：加载失败为 `ERR_CANT_OPEN`，场景根节点不是 `Node3D` 为 `ERR_INVALID_DATA`。它代替 `level_change_finished` 发出 |
| `portal_entered(portal)`、`portal_exited(portal)` | 旅行者进入或离开当前关卡的传送门 |
| `change_level(path, spawn_name = &"default", title = "")` | 开始切换并立即返回，见下文 |
| `get_current_level()` | 游戏当前所在关卡；第一个关卡之前为 `null` |
| `is_changing()` | 是否正在切换：从接受 `change_level()` 到 `level_change_finished` 或 `level_change_failed` |
| `find_spawn_point(spawn_name = &"default", level = null)` | 关卡中的出生点，见[出生点](#出生点) |

编辑器中放置的初始关卡不会发出 `level_loaded`；游戏在 `_ready()` 中通过 `get_current_level()` 和 `find_spawn_point()` 设置它，`gdscript/main.gd` 即是示例。

切换进行中再次请求会返回 `ERR_BUSY`，因此重复按 E 或切换中进入另一扇门不会产生效果。`change_level()` 会立即检查文件：文件不存在返回 `ERR_FILE_NOT_FOUND`；文件不是场景返回 `ERR_INVALID_PARAMETER`；两种情况都不会启动切换。若场景加载失败或其根节点不是 `Node3D`，当前关卡保持不变：错误写入输出，暂停结束，加载画面不等待 `min_loading_time` 就淡出，随后发出 `level_change_failed`。失败的加载会被清理，因此修复文件后，稍后的请求会重新加载。

容器只会结束由它自己开始的暂停。会暂停游戏的窗口（如菜单）应在 `level_change_finished` 之后打开：切换期间打开时，窗口发现游戏已暂停，就把暂停交由容器管理；容器结束暂停后，游戏会在窗口后方继续运行。演示自然满足这条规则：加载画面关闭前不允许任何输入通过，包括 F10。切换中关闭窗口不会造成问题，容器在替换关卡前会再次暂停游戏。如果容器在切换中退出场景树（例如更换游戏场景），切换及其暂停会一起结束。

加载画面、进度条与 `min_loading_time` 都按真实时间运行，不受 `Engine.time_scale` 影响：慢动作中切换所需时间与正常速度一样。

预热能把部分首次使用的工作藏在加载画面后，但不能保证之后绝不会因着色器或资源而卡顿。请用实际关卡内容和目标渲染器测量切换表现。

## 传送门

`LevelPortal` 是一个 `Area3D`：可以用作传送台、门或地图边缘。它需要碰撞形状，以及能检测旅行者所在层（第 2 层，即角色）的 `collision_mask`；自身无须占用物理层。关卡容器会连接当前关卡的传送门，包括以后新增的门，例如完成任务后才打开的门。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `target_level` | | 要前往的关卡场景文件。使用路径而不是已加载场景，因此两个关卡可以相互指向；在检查器中选出的 `uid://` 路径也可以 |
| `target_spawn` | `default` | 抵达时使用的出生点 |
| `title` | | 目标地点名称：显示在旅行提示、加载画面和告示牌上；显示时会翻译 |
| `title_label` | | 位于传送门上方、显示 `title` 的 `Label3D`；传送门会为它写入标题 |
| `traveller_group` | `player` | 哪些对象可以旅行：身体必须位于此分组 |
| `auto_travel` | 关闭 | 旅行者进入时立刻旅行，不显示提示 |

可组合的用法：

- **默认用法，即演示中的传送台：**传送门报告旅行者进入和离开（`traveller_entered`、`traveller_exited`）；关卡容器将其转发为 `portal_entered` 和 `portal_exited`，游戏决定显示什么提示。游戏框架显示“E 传送至<地点>”；走开即隐藏。即使同时按着 Shift 或其他修饰键，E 也能生效，因为英雄常常冲刺跑上传送台。`travel()` 开始切换。
- **启用 `auto_travel`：**适合门或地图边缘。旅行者一进入就旅行，游戏框架不会显示提示。
- **不使用加载画面：**让 `LevelHost.loading_screen` 留空。关卡仍会在后台加载，更换和导航准备期间游戏仍会暂停，但玩家能看见更换过程。
- **通过代码使用传送门：**`LevelHost.change_level(path, spawn_name, title)` 与传送门执行相同切换；过场动画或菜单也可以调用。

调用 `travel()`，或启用 `auto_travel` 后进入时，都会发出 `travel_requested(portal)`；关卡容器会连接这个信号，不使用容器的游戏则要自行连接。`has_traveller()` 可查询旅行者目前是否站在门内。每扇门都属于 `level_portals` 分组。

角色若出生在传送门区域内，会立刻收到返回的旅行提示。若在 `auto_travel` 传送门内出生，下次物理更新会在切换尚未完成的预热阶段检测到它：请求得到 `ERR_BUSY`，容器将其忽略；角色要先走出去再进来，才会再次旅行。若检测时切换已经结束，角色会立即传送回去。因此请把出生点放在传送台旁边、区域之外。

## 出生点

`SpawnPoint` 是带 `spawn_name` 的 `Marker3D`，默认名称为 `default`。角色出现在标记所在位置，朝向标记的 −Z，即节点的前方（小工具中的蓝色轴指向反方向）；`get_facing()` 返回其水平朝向。把标记放在地面上：角色的脚会落在此处；放在地面上方，角色就会下落。每个出生点都属于 `spawn_points` 分组。

`LevelHost.find_spawn_point(name, level)` 返回 `level` 中指定名称的出生点（未提供关卡时使用当前关卡；关卡必须在场景树中）；若找不到则返回 `default`；两者都没有时返回 `null`。切换期间缺少出生点还会在输出中产生警告；如果完全没有出生点，容器会把关卡本身作为 `spawn` 传递，角色抵达关卡原点。每个关卡都应有一个 `default` 出生点：游戏从那里开始，未指定 `target_spawn` 的传送门也抵达那里。名称取自 `spawn_name`，不是节点名称：演示中 `default` 点的节点分别叫 `Start` 和 `Arrival`。请为其他出生点指定不同名称；如果第二个点仍叫 `default`，按该名称查找时会选中场景树顺序中的第一个。

## 加载画面

`LoadingScreen` 是位于第 20 层、盖在窗口上方的 `CanvasLayer`，游戏暂停时也能工作。画面显示期间没有输入事件能传到游戏，因此点击和 F10 都不起作用（`Input` 仍能查询按住的按键）。

| 属性 | 默认值 | 含义 |
|---|---|---|
| `tips` | 空；演示在 `gdscript/main.tscn` 中的实例上设置了六条操作提示 | 一次显示一条，顺序随机；先翻译，再交给 `tip_format` 处理 |
| `tip_format` | 空（由代码指定的 `Callable`）；演示在 `gdscript/main.gd` 中设置为 `InputNames.format` | 将翻译后的提示变为最终显示文本。演示提示使用 `{sprint}` 等标记指代按键，`InputNames.format` 会插入当前绑定的按键，见[文本中的按键名称](ui.md#文本中的按键名称)。留空则直接显示翻译后的提示 |
| `tip_time` | 6 秒 | 每条提示的停留时间；随后用 0.25 秒淡出，切换文字，再用 0.25 秒淡入下一条 |
| `fade_time` | 0.35 秒 | 画面淡入和淡出的用时 |
| `zoom` | 0.06 | 背景靠近的幅度，占原大小的比例 |
| `zoom_time` | 12 秒 | 放大到上述幅度的用时 |

背景取自游戏最后一帧，先缩小八倍，再由着色器进一步模糊（`loading_background.gdshader` 负责模糊、调暗、加深四角，并让文字下方的底部更暗）。没有窗口可绘制时（无窗口运行或窗口最小化），就没有那一帧，画面会使用纯深色。进度条落后于报告进度较多时会快速追上；即使加载器随后报告了更低进度，也不会倒退。

外观定义在根节点的主题 `loading_screen_theme.tres` 中：类型变体 `LoadingTitle`（44 像素、带阴影的暖白色）、`LoadingBar`（细金色进度条）和 `LoadingTip`（18 像素）。给根节点换主题即可换外观，也可以复制 `loading_screen.tscn` 自行制作画面：节点可以移动或修改，但脚本需要 `Control` 类型的 `Root`，以及以唯一名称访问的 `TextureRect` 类型 `Background`、`Label` 类型 `Title` 和 `Tip`、`ProgressBar` 类型 `Bar`。继承 `LoadingScreen` 的脚本可以覆盖 `open()`、`set_progress()` 和 `close()`；场景仍须包含这些节点。查询方法有：`is_open()`（画面正显示、淡入或淡出）、`get_shown_progress()`（进度条填充比例，从 0 到 1）和 `get_tip()`（当前提示的原始模板；没有提示时为空）。`refresh()` 会重新翻译、格式化当前提示，不重置其计时器。演示把加载画面加入 `ActionTexts.GROUP`，因此刷新按键名称时，已显示的加载提示也会更新。

## 可操控的英雄

`gdscript/player/playable_hero.tscn` 是可直接放入游戏场景的玩家英雄：角色（`player.tscn`，位于 `player` 分组）、`PointClickMoveInput`、`CharacterActionInput`、带相机臂和相机的相机支架、点击标记、路径线，以及相应设置和场景内部的六条连接。角色场景本身不含这些部分，因此 AI 也能驱动同一个 `player.tscn`。

`PlayableHero`（`playable_hero.gd`）以带类型的属性暴露组件（`character`、`input`、`actions`、`camera_rig`、`camera_arm`、`camera`、`click_marker`、`path_view`，以及角色的 `sounds`、`appearance`、`hover`、`silhouette`），并提供以下三种操作：

| 调用 | 效果 |
|---|---|
| `teleport(position, facing = Vector3.ZERO, turn_camera = true)` | 忘记正在进行的按住操作（`PointClickMoveInput.cancel()`），立即放置角色（`GroundCharacter.teleport()`），按需使相机沿 `facing` 观察、立即对齐并重新开始跟随。若 `facing` 保持为 `Vector3.ZERO`，角色保留原朝向，相机保留原方向 |
| `place_at(marker, turn_camera = true)` | 将 `teleport()` 应用于标记，面朝其 −Z |
| `controls_enabled` | 关闭时，取消正在进行的按住操作、松开冲刺键并停止输入节点；相机仍由玩家操控。角色仍会继续奔向点击的目标点；可用 `character.mover.stop()` 或 `teleport()` 停下。开启时，操控恢复，输入节点按之前的方式处理 |

英雄根节点永远不移动：角色在其内部移动，相机跟随角色。英雄不依赖关卡组件；使用自己关卡系统的游戏，可在关卡就绪时调用 `place_at()`。

## 演示中的关卡

**草地**（`shared/world/world.tscn`，见[世界与导航](world-and-navigation.md)）在 `Travel` 下包含：原点处朝北的出生点 `Start`（`default`）；位于远古环阵旁、初始位置以北 12 米且从那里能看见的传送台 `IslandPad`，通往孤岛；以及传送台旁边朝东的出生点 `FromIsland`（`from_island`），此时传送台位于英雄左后方不远处。

**孤岛**（`shared/world/island/island.tscn`）是一座湖中直径 30 米的圆形岛屿，使用草地关卡的道具、材质和着色器；除两种材质外没有自己的资源文件：

- 草地使用 `island_ground.tres`：它以草地关卡的地面为基础，关闭了泥路（`roads`），因为道路以世界坐标绘制，只属于草地关卡；
- 湖水使用 `lake_water.tres`：它以水井中平静的水为基础，颜色更浅、涟漪更强，600 米的平面一直延伸到地平线；
- 草地边缘下方有岩石海岸，浅水中散落巨石；
- 距中心 14.5 米处的一圈隐形墙（`Edge`，24 个方盒）防止英雄离开岛屿；它们位于第 4 物理层 `bounds`，角色会与它们碰撞，但点击和相机不会检测到它们，所以点击水面不会命中墙，相机也能穿过；孤岛导航网格从第 1 和第 4 层烘焙，因此路径会避开墙；
- 北部的隐士营地有帐篷、篝火和木桶，是一个可发现的地点（其 `PointOfInterest` 位于 `Places` 下）；
- 南部朝北、指向营地的出生点 `Arrival`（`default`），以及通回草地（出生点 `from_island`）的传送台 `HomePad`，位于英雄背后偏左的位置；
- 自己的导航网格，烘焙方式与草地相同，见[重新烘焙导航网格](world-and-navigation.md#重新烘焙导航网格)。

两个关卡共享环境资源 `shared/world/world_environment.tres`：天空、雾和环境光。每个关卡都有自己的太阳节点副本（`Sun`）。

传送台（`shared/world/props/teleport_pad.tscn`）共用一个场景：`LevelPortal` 上放有石盘、发光镶嵌、头顶高度旋转的水晶、灯光，以及显示地名的标牌。它们没有实体碰撞，所以其下方的导航网格无需改变。

## 添加关卡

1. 创建根节点为 `Node3D` 的场景：加入关卡光源与环境、包含地面和道具的 `NavigationRegion3D`，并在地面上放一个 `spawn_name` 为 `default` 的 `SpawnPoint`。边缘隐形墙应放在第 4 层（`bounds`）。
2. 创建独立的 `NavigationMesh` 并为该关卡烘焙：使用静态碰撞体、第 1 物理层；若有边缘隐形墙，还要包含第 4 层。与地图的 0.025 米单元高度和 0.25 米单元大小匹配；代理半径先用 0.5 米、最大攀爬高度 0.3 米、最大坡度 40°。对于随附的 1.8 米胶囊体，代理高度使用 1.8 米，并启用 `filter_walkable_low_height_spans` 排除低矮天花板。若复制演示的网格资源，重新烘焙前先将其设为唯一，并检查高度／过滤设置。见[世界与导航](world-and-navigation.md#物理层与导航)。
3. 从另一个关卡添加通向新关卡的门：可以实例化 `teleport_pad.tscn`，也可以用自己的 `LevelPortal`；将 `target_level` 指向新场景，并在新关卡中添加返回用的门。在每个传送台旁边放置出生点，再将其名称填入另一端传送台的 `target_spawn`。
4. 将传送门和地点的标题加入翻译：`localization_checks.gd` 会从初始关卡出发，遍历传送门可到达的全部关卡并报告缺少的字符串。只通过代码中的 `change_level()` 到达的关卡不在检查范围内。

---

*本页对应 Iso & Orbit 1.2.0。*
