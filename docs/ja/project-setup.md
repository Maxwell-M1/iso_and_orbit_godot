<!-- translation of docs/en/project-setup.md @ e52ff77b332d -->
# プロジェクトのセットアップ

[← ドキュメント目次](index.md)

> これは[英語の原文](../en/project-setup.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

コンポーネントが`project.godot`とシーンに求めるものです。コンポーネントを別のプロジェクトへ移すときは、この設定のうち、そのコンポーネントが使う部分をコピーしてください。

完成済みヒーローには先に[移植手順](integration.md#デモのヒーローを自分のプロジェクトへ移植する)を使います。移動・カメラ・ダッシュ・ジャンプのアクション、対応するナビゲーション設定と衝突レイヤーが必要です。デモの自動読み込み、UIテーマ、翻訳、表示設定、レベルシステムは任意です。

## 物理レイヤー

| レイヤー | 名前 | 何が置かれるか | 誰が読むか |
|---|---|---|---|
| 1 | `world` | 地面、壁、小道具、山、レベルに立っているNPC | クリックレイ（`PointClickMoveInput.ground_mask`）、プレイヤーのボディと`LedgeGuard`（`floor_mask`が0ならボディのマスク）、`CameraArm.collision_mask`、ナビゲーションメッシュのベイク |
| 2 | `characters` | プレイヤーのボディ（`collision_layer = 2`） | `PointOfInterest`と`LevelPortal`のエリア（`collision_mask = 2`）。カメラアームは無視する |
| 3 | `camera` | カメラだけを止めるボディ。たとえば`shared/world/props/house.tscn`の`RoofCameraBlocker` | `CameraArm.collision_mask`のみ |
| 4 | `bounds` | 島の`Edge`など、レベル端の見えない壁 | プレイヤーのボディ（`collision_mask`はレイヤー1と4）とその`LedgeGuard`、必要なレベル（島）のナビゲーションメッシュのベイク |

`CameraArm.collision_mask`のデフォルトはレイヤー1と3（`0b101`）です。レイヤー2のキャラクターがカメラを押すことはありません。レイヤー3のボディはカメラを止めますが、クリック、ナビゲーション、キャラクターからは見えません。誰も屋根の上へ経路を引けないまま、カメラを屋根から守れます。レイヤー4は逆で、キャラクターを止めますが、クリックとカメラは通過します。見えない壁の向こうの地面や水をクリックしても、レイが壁に当たることはありません。

ナビゲーションレイヤー1の名前は`ground`です。`NavigationMover.navigation_layers`のデフォルトはこのレイヤーです。物理レイヤーとナビゲーションレイヤーは別の設定です。コライダーの物理レイヤーはレイとボディの衝突を決め、リージョンのナビゲーションレイヤーはムーバーが探せる経路を決めます。コードではマスクはビット値で、レイヤー1と4が`1 | 8 = 9`、レイヤー1と3が`1 | 4 = 5`です。インスペクターでは番号のチェックボックスを選びます。

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
| `interact` | E | `TravelPrompt.action`。デモでパッド上の移動案内を確定する |
| `ui_cancel` | Esc（組み込み） | `UiRoot`：最前面のウィンドウを閉じる |

**Project → Project Settings → Input Map**でこれらを追加し、文字キーには物理キーイベントを使います。単独のヒーローには最初の7行（10アクション）が必要です。`toggle_settings`、`interact`、`ui_cancel`は任意のUIと移動機能用です。このプロジェクトの`project.godot`の`[input]`節から必要な項目を自分のプロジェクトへ統合することもできます。プロジェクトファイル全体は置き換えないでください。

キーは物理的な位置で割り当てられているので、どの配列でもWASDの位置は変わりません。各コンポーネントはアクション名をエクスポートされたプロパティとして受け取るため、独自のアクションも使えます。欠けたアクションは使うコンポーネントが起動時に一度報告し、その後は読みません。キーやボタンは効かず、追加エラーは出ません。ほかの移動キーは引き続き使えます。

HUD、設定、ローディング画面のヒントはアクションからキー名を得ます。実行中に`InputMap`を変更したら、これらのテキストコンポーネントを使う場合は`get_tree().call_group(ActionTexts.GROUP, &"refresh")`を呼びます。デモにはキー割り当て画面や割り当ての保存機能はありません。[文章内のキー名](systems/ui.md#文章内のキー名)を参照してください。

## グループ

| グループ | 意味 |
|---|---|
| `player` | プレイヤーのボディ。`PointOfInterest`（`player_group`）と`LevelPortal`（`traveller_group`）はこのグループのボディだけに反応する。`playable_hero.tscn`の`Character`へ設定する |
| `camera_ignore` | カメラアームが通り抜けるボディ（`CameraArm.ignored_groups`）。グループに属するノードの下にあるものすべてに適用されるので、プロップシーンのルートかレベルのフォルダー用ノードに一度設定すればよい。デモでは使っていない |
| `points_of_interest` | 各`PointOfInterest`が自身で追加する。`DiscoveryToast`とデモのゲーム全体のシーンはこれを通じて場所を探す |
| `level_portals`、`spawn_points` | 各`LevelPortal`と`SpawnPoint`が自身で追加する。`LevelHost`はレベル内の対象をここから探す |

## 自動読み込み（Autoload）

`Settings` → `res://gdscript/settings/game_settings.gd`。これを必要とするのは、設定ウィンドウ、そのコントロール、`gdscript/demo/settings_applier.gd`だけです。コンポーネントはこれがなくても動作します。[設定](settings.md)を参照してください。

## その他のプロジェクト設定

| 設定 | 値 | 備考 |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | デモ |
| `physics/3d/physics_engine` | Jolt Physics | エンジンに組み込み。カメラアームとテストはこれで検証している |
| `navigation/3d/default_cell_height` | 0.025 | メッシュの`cell_height`と合わせる。デモでは階段用に細かい垂直セルを使い、新しいメッシュとマップの組も一致させる。[ワールドとナビゲーション](systems/world-and-navigation.md)を参照 |
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

*このページは Iso & Orbit 1.2.0 に対応しています。*
