<!-- translation of docs/en/integration.md @ 15ab3be62c8a -->
# プロジェクトへの組み込み

> これは[英語の原文](../en/integration.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

再利用可能なコンポーネントは`addons/iso_orbit/`にあり、パーツごとに1つのフォルダになっています。共通のフォルダにまとめることで、ほかのアドオンと分けています。必要なフォルダを自分のプロジェクトの`addons/iso_orbit/`へコピーし、シーン内でノードを接続して、[プロジェクトのセットアップ](project-setup.md)の説明どおりにプロジェクトを設定してください。スクリプトは通常のGDScriptクラス（`class_name`）なので、有効にするエディタープラグインはありません。

## アドオン

| アドオン | クラス | 必要なもの |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`、`CameraArm` | 入力アクション`camera_rotate`、`camera_zoom_in`、`camera_zoom_out`。アーム用の物理レイヤー |
| `click_to_move` | `LocomotionSettings`、`GroundMotion`、`NavigationMover`、`PointClickMoveInput`、`ClickMarker`、`NavigationPathView` | ワールド内のベイク済み`NavigationRegion3D`（ないとキャラクターは地点へまっすぐ走る）。入力用：任意の`Camera3D`と、アクション`move_to_cursor`、`camera_rotate`、`move_forward`、`move_back`、`move_left`、`move_right` |
| `ground_character` | `GroundCharacter`、`LedgeGuard`、`Stamina`、`CharacterActionInput`、`CharacterSounds`、`HandSway`、`CharacterAppearance`、`StaminaBar` | `click_to_move`。キー用：アクション`sprint`と`jump`。サウンド用：独自のサウンド、または`shared/audio/character/`。手の振りと切り替え可能なモデル用：手のノードを持ち、−Zを向いたモデル |
| `occluded_silhouette` | `OccludedSilhouette`とそのシェーダー、マテリアル | なし：どのモデルでも動作する |
| `points_of_interest` | `PointOfInterest`、`DiscoveryToast` | `player`グループに属し、エリアが検出できる物理レイヤーにあるプレイヤーのボディ |
| `ui_screens` | `UiRoot`、`UiScreen`、`FpsCounter` | 組み込みの`ui_cancel`。`UiRoot`がキーでウィンドウを開く場合はアクション`toggle_settings` |

各アドオンのフォルダには、セットアップ方法を記した`README.md`と`LICENSE`のコピーがあります。アドオンは丸ごと使ってください。中のクラスは型で互いを参照しており、使わないファイルがあっても害はありません。フォルダは`res://addons/iso_orbit/<addon>/`に置いたままにしてください。中のシーンやマテリアルは、そのパスで自身のファイルを参照しています。アドオンを別の場所に置くには、エディターのファイルシステムドック（FileSystem）で移動してください。参照が更新されます。

HUDウィジェット（`StaminaBar`、`DiscoveryToast`、`FpsCounter`）の見た目は、デモのテーマ`shared/ui/ui_theme.tres`にある同名のテーマタイプバリエーションから取られます。それがない場合はデフォルトのテーマを使います。

次のものはこのデモを前提に作られているため、アドオンには含まれていません：設定システム（`gdscript/settings/game_settings.gd`と`gdscript/ui/settings/`の設定ウィンドウ。[設定](#設定)を参照）、`gdscript/ui/ui_root.tscn`（その設定ウィンドウを組み込んだ`UiRoot`）、デモをつなぐ`gdscript/demo/hud.gd`と`settings_applier.gd`。

## カメラ単体で使う

カメラは任意の`Node3D`をターゲットにでき、必要なのは`addons/iso_orbit/orbit_camera/`だけです。

1. `orbit_camera_rig.gd`を付けた`Node3D`を、ターゲットの中ではなく隣に追加します。
2. その子として`camera_arm.gd`を付けた`Node3D`を追加し、さらにその子に`Camera3D`を追加します。
3. リグの`target`を設定します。アームの`fade_target`には、カメラがごく近いときに半透明にしたいノードを設定するか、空のままにします。
4. [プロジェクトのセットアップ](project-setup.md)にある入力アクションと、アーム用の物理レイヤーを追加します。

アームなしで、リグの子に`Camera3D`を置いても動作します。その場合、カメラはズームで設定された距離にとどまり、壁を突き抜けます。リグはターゲットの補間された位置から`_process`で更新されるので、ターゲットが物理ティックで動く場合は、プロジェクトで物理補間をオンにしてください。詳細：[カメラ](systems/camera.md)。

## 完成済みのボディでクリック移動する

`addons/iso_orbit/click_to_move/`と`addons/iso_orbit/ground_character/`をコピーします。

1. レベルのナビゲーションメッシュをベイクします（`NavigationRegion3D` → **ナビゲーションメッシュをベイク**（Bake NavigationMesh））。エージェント半径と最大登坂高さはキャラクターに合わせてください。[ワールドとナビゲーション](systems/world-and-navigation.md)を参照してください。
2. `ground_character.gd`を付けた`CharacterBody3D`を作ります。コリジョンシェイプ、モデル（−Z向き）を入れた`Visual`ノード、そして子として`NavigationMover`（`navigation_mover.gd`を付けた`Node`）と、必要に応じて`LedgeGuard`と`Stamina`を持たせます。ボディの`mover`、`visual`、`ledge_guard`、`stamina`を設定します。
3. ムーバーに`LocomotionSettings`リソースを設定します。空のままにするとデフォルト値が使われます。
4. `point_click_move_input.gd`を付けた`Node`をシーン内の任意の場所に追加し、その`mover`と`camera`を設定します。
5. ダッシュとジャンプのために、必要に応じて`character_action_input.gd`を追加し、`character`にボディを設定します。

`gdscript/player/player.tscn`はこの構成に、サウンド、手の振り、切り替え可能なモデル、シルエットを加えたものです。これをインスタンス化して、不要なものを削除してもかまいません。

## 独自のボディ

独自のキャラクターコントローラーを使い続けるなら、`addons/iso_orbit/click_to_move/`だけを使います。守るべき約束はわずかです。

- `NavigationMover`はボディ（任意の`Node3D`）の直接の子でなければなりません。ボディの位置と、ボディが属するワールドのナビゲーションマップを読み取ります。
- ボディは物理ティックごとに1回、`move_and_slide()`の前に`mover.compute_velocity(delta)`を呼び、結果のXとZを適用します。ムーバーがボディを動かすことはありません。
- 垂直方向の速度（重力、ジャンプ、ノックバック）はボディが担当します。

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover
@onready var ledge_guard: LedgeGuard = $LedgeGuard


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity = ledge_guard.constrain(velocity, delta)
	move_and_slide()
	var facing := mover.get_facing()
	$Visual.rotation.y = atan2(-facing.x, -facing.z)
```

`LedgeGuard`は任意です。`addons/iso_orbit/ground_character/`にあり、ボディの子として置きます。ダッシュするには`mover.sprinting = true`を設定します。速度上限が`LocomotionSettings.sprint_speed_multiplier`倍に上がります。`GroundCharacter`のそれ以外の機能（ジャンプ、スタミナ、階段、状態とそのシグナル、モデルの滑らかな回転）は、自分で用意することになります。

## ムーバーへの命令

プレイヤーの入力、AI、カットシーン、ネットワークコードなど、何からでもキャラクターを動かせます。

| 呼び出し | 効果 |
|---|---|
| `move_to(point)` | ナビゲーション経路に沿って地点へ走り、正確にそこで止まる。毎ティック呼んでもよい。現在の地点から`retarget_tolerance`（0.1 m）より近い地点では経路を再構築しない |
| `steer(direction, facing = Vector3.ZERO)` | 別の指示があるまで、経路なしで指定の方向へ走る。`facing`を指定すると、移動中はその方向を向く（横移動） |
| `stop()` | その場で滑らかに減速して止まる |
| `halt()` | 即座に止まる。たとえばテレポートの後に使う |

シグナル：`destination_changed(point)`、`path_changed`、`arrived`、`destination_cancelled`（`steer()`や`stop()`のために地点が放棄された）。問い合わせ：`is_moving()`、`is_steering()`、`has_destination()`、`get_destination()`、`get_speed()`、`get_heading()`、`get_facing()`、`get_remaining_path()`。詳細：[ロコモーション](systems/locomotion.md)。

## NPC

`player.tscn`（またはムーバーを持つ独自のボディのシーン）をインスタンス化し、プレイヤー専用の`Silhouette`ノードと`Appearance`ノードを削除します。入力ノードは追加しません。AIから`NavigationMover.move_to()`を呼び、`arrived`を受け取ります。デモのキャラクターモデルを使うには、それを`Model`として`Visual`の下に置きます。デモレベルに立っているNPCはキャラクターではなく静的ボディです。[ワールドとナビゲーション](systems/world-and-navigation.md)を参照してください。

## 設定

コンポーネントが設定を読むことはなく、それぞれ自身のエクスポートされたプロパティを読みます。それらを自分の設定メニューに出すには、設定が変わったときに自分のコードからプロパティを設定します。`gdscript/demo/settings_applier.gd`がその例で、1つの`match`で各設定キーをノードのプロパティに対応付けています。デモの設定システムも再利用するには、`gdscript/settings/game_settings.gd`をコピーして`Settings`という名前の自動読み込み（Autoload）として登録し、キーと`DEFAULTS`を自分のものに置き換え、`gdscript/ui/settings/`からコントロールを持ってきます。[UI](systems/ui.md#設定)を参照してください。

---

*このページは Iso & Orbit 1.1.0 に対応しています。*
