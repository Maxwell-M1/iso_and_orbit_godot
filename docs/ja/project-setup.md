<!-- translation of docs/en/project-setup.md @ 6e49af9494f6 -->
# プロジェクトのセットアップ

> これは[英語の原文](../en/project-setup.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

コンポーネントが`project.godot`とシーンに求めるものです。コンポーネントを別のプロジェクトへ移すときは、この設定のうち、そのコンポーネントが使う部分をコピーしてください。

## 物理レイヤー

| レイヤー | 名前 | 何が置かれるか | 誰が読むか |
|---|---|---|---|
| 1 | `world` | 地面、壁、プロップ、山、レベルに立っているNPC | クリックのレイキャスト（`PointClickMoveInput.ground_mask`）、`LedgeGuard.floor_mask`、`CameraArm.collision_mask`、ナビゲーションメッシュのベイク |
| 2 | `characters` | プレイヤーのボディ（`collision_layer = 2`） | `PointOfInterest`エリア（`collision_mask = 2`）。カメラアームは無視する |
| 3 | `camera` | カメラだけを止めるボディ。たとえば`shared/world/props/house.tscn`の`RoofCameraBlocker` | `CameraArm.collision_mask`のみ |

`CameraArm.collision_mask`のデフォルトはレイヤー1と3（`0b101`）です。レイヤー2のキャラクターがカメラを押すことはありません。レイヤー3のボディはカメラを止めますが、クリック、ナビゲーション、キャラクターからは見えません。そのため、誰も屋根の上へ経路を引けないようにしたまま、カメラが屋根に入り込まないようにできます。

ナビゲーションレイヤー1の名前は`ground`です。`NavigationMover.navigation_layers`のデフォルトはこのレイヤーです。

## 入力アクション

| アクション | デフォルト | 使用元 |
|---|---|---|
| `move_to_cursor` | マウスの左ボタン | `PointClickMoveInput.move_action` |
| `camera_rotate` | マウスの右ボタン | `OrbitCameraRig.rotate_action`、`PointClickMoveInput.camera_steer_action` |
| `camera_zoom_in` | ホイール上 | `OrbitCameraRig.zoom_in_action` |
| `camera_zoom_out` | ホイール下 | `OrbitCameraRig.zoom_out_action` |
| `move_forward`、`move_back`、`move_left`、`move_right` | W、S、A、D | `PointClickMoveInput`（右ボタンを押している間） |
| `sprint` | Shift | `CharacterActionInput.sprint_action` |
| `jump` | スペース | `CharacterActionInput.jump_action` |
| `toggle_settings` | F10 | `UiRoot.settings_action` |
| `ui_cancel` | Esc（組み込み） | `UiRoot`：最前面のウィンドウを閉じる |

キーは物理的な位置で割り当てられているので、どのキーボード配列でもWASDの位置は変わりません。各コンポーネントはアクション名をエクスポートされたプロパティとして受け取るので、代わりに独自のアクションを使えます。

## グループ

| グループ | 意味 |
|---|---|
| `player` | プレイヤーのボディ。`PointOfInterest`はこのグループのボディにだけ反応する（`player_group`）。`main.tscn`の`Player`に設定されている |
| `camera_ignore` | カメラアームが通り抜けるボディ（`CameraArm.ignored_groups`）。グループに属するノードの下にあるものすべてに適用されるので、プロップシーンのルートかレベルのフォルダー用ノードに一度設定すればよい。デモでは使っていない |
| `points_of_interest` | 各`PointOfInterest`が自身で追加する。`DiscoveryToast`はこれを通じて場所を見つける |

## 自動読み込み（Autoload）

`Settings` → `res://gdscript/settings/game_settings.gd`。これを必要とするのは、設定ウィンドウ、そのコントロール、`gdscript/demo/settings_applier.gd`だけです。コンポーネントはこれがなくても動作します。[設定](settings.md)を参照してください。

## その他のプロジェクト設定

| 設定 | 値 | 備考 |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | デモ |
| `physics/3d/physics_engine` | Jolt Physics | エンジンに組み込み。カメラアームとテストはこれで検証している |
| `navigation/3d/default_cell_height` | 0.025 | ナビゲーションメッシュのセルの高さを超えてはならない。メッシュ側は、ボディが登れない段差をつながないように0.025 mにしている。[ワールドとナビゲーション](systems/world-and-navigation.md)を参照 |
| `display/window/stretch/mode` | `canvas_items` | UIスケールの設定は`content_scale_factor`ですべての2Dを拡縮し、3Dビューには影響しない |
| `display/window/stretch/aspect` | `expand` | どんなウィンドウ形状にも対応 |
| `gui/theme/custom` | `res://shared/ui/ui_theme.tres` | すべてのウィンドウとHUD要素の見た目 |
| `internationalization/locale/translations` | `res://l10n/ui/*.po` | インターフェースの翻訳。[UI](systems/ui.md)を参照 |
| `rendering/rendering_device/driver.windows` | `d3d12` | WindowsではDirect3D 12 |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 5（Ultra） | ソフトシャドウ。`world.tscn`の太陽にも`shadow_blur = 1.25`と70 mの影の距離が設定されている |
| `rendering/anti_aliasing/quality/msaa_3d` | 2（4×） | マルチサンプル・アンチエイリアス |

物理はデフォルトの毎秒60ティックで動作します。物理補間は`project.godot`でオンになっており（`physics/common/physics_interpolation`）、実行時に設定（設定 → 表示）で切り替えます。

## 保存データ

設定は、プロジェクトのユーザーデータフォルダーにある`user://settings.cfg`に保存されます（エディターでは：プロジェクト → ユーザーデータフォルダーを開く（Project → Open User Data Folder））。デフォルトに戻すには、このファイルを削除するか、設定ウィンドウの**すべてリセット**を使います。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
