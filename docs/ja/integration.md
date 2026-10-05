<!-- translation of docs/en/integration.md @ 502ddfce7182 -->
# プロジェクトへの組み込み

[← ドキュメント目次](index.md)

> これは[英語の原文](../en/integration.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

別のプロジェクトでもデモと同じ移動とカメラを使いたいなら、完成済みのヒーローから始めます。すでにキャラクターコントローラーがある場合や、カメラだけが必要な場合は、個別のコンポーネントを使います。スクリプトは通常のGDScriptクラス（`class_name`）です。有効化するエディタープラグインはなく、`Settings`の自動読み込みも必須ではありません。

| やりたいこと | 最初に読む場所 |
|---|---|
| 完成済みのヒーロー、入力、カメラを使う | [デモのヒーローを移植する](#デモのヒーローを自分のプロジェクトへ移植する)、続いて[構成を選ぶ](configurations.md) |
| 既存のキャラクターにカメラを付ける | [カメラ単体で使う](#カメラ単体で使う) |
| 自分のモデルでこのプロジェクトの移動機能を使う | [完成済みのボディ](#完成済みのボディでクリック移動する)、続いて[モデルの交換](systems/characters.md) |
| 独自のコントローラーやAIで経路移動を使う | [独自のボディ](#独自のボディ)と[ムーバーへの命令](#ムーバーへの命令) |

以下のファイルパスは、`project.godot`があるプロジェクトのルートからの相対パスです。`res://`はGodot内で同じ場所を表します。最初の組み込みが動くまでは、付属のフォルダ構成を保ってください。

## アドオン

| アドオン | クラス | 必要なもの |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`、`CameraArm` | 入力アクション`camera_rotate`、`camera_zoom_in`、`camera_zoom_out`。アーム用の物理レイヤー |
| `click_to_move` | `LocomotionSettings`、`GroundMotion`、`NavigationMover`、`PointClickMoveInput`、`ClickMarker`、`NavigationPathView` | ワールド内のベイク済み`NavigationRegion3D`（ないとキャラクターは地点へまっすぐ走る）。入力用：任意の`Camera3D`と、アクション`move_to_cursor`、`camera_rotate`、`move_forward`、`move_back`、`move_left`、`move_right` |
| `ground_character` | `GroundCharacter`、`FallSettings`、`LedgeGuard`、`Stamina`、`CharacterActionInput`、`CharacterSounds`、`HandSway`、`CharacterHover`、`DampedSpring`、`CharacterAppearance`、`StaminaBar` | `click_to_move`。キー用：アクション`sprint`と`jump`。サウンド用：独自のサウンド、または`shared/audio/character/`。手の振りと切り替え可能なモデル用：手のノードを持ち、−Zを向いたモデル |
| `occluded_silhouette` | `OccludedSilhouette`とそのシェーダー、マテリアル | なし：どのモデルでも動作する |
| `points_of_interest` | `PointOfInterest`、`DiscoveryToast` | `player`グループに属し、エリアが検出できる物理レイヤーにあるプレイヤーのボディ |
| `ui_screens` | `UiRoot`、`UiScreen`、`FpsCounter`、`InputNames`、`ActionTexts` | 組み込みの`ui_cancel`。`UiRoot`がキーでウィンドウを開く場合はアクション`toggle_settings`。キー名の表示はInput Mapを参照する |
| `levels` | `LevelHost`、`LevelPortal`、`SpawnPoint`、`LoadingScreen` | エンジン以外は不要。ポータルが検出できる物理レイヤー上で、`player`グループに属する移動者のボディ |

各アドオンのフォルダには、セットアップ方法を記した`README.md`と`LICENSE`のコピーがあります。アドオンは丸ごと使ってください。中のクラスは型で互いを参照しており、使わないファイルがあっても害はありません。フォルダは`res://addons/iso_orbit/<addon>/`に置いたままにしてください。中のシーンやマテリアルは、そのパスで自身のファイルを参照しています。アドオンを別の場所に置くには、エディターのファイルシステムドック（FileSystem）で移動してください。参照が更新されます。

HUDウィジェット（`StaminaBar`、`DiscoveryToast`、`FpsCounter`）の見た目は、デモのテーマ`shared/ui/ui_theme.tres`にある同名のテーマタイプバリエーションから取られます。それがない場合はデフォルトのテーマを使います。

次のものはデモ固有の構成に依存するため、アドオンに含まれません。設定システム（`gdscript/settings/game_settings.gd`と`gdscript/ui/settings/`の設定ウィンドウ。[設定](#設定)を参照）、そのウィンドウを組み込んだ`UiRoot`である`gdscript/ui/ui_root.tscn`、デモのキャラクターを基にしたヒーロー（`gdscript/player/playable_hero.tscn`。[操作するヒーロー](#操作するヒーロー)を参照）、移動先の案内（`gdscript/ui/travel_prompt.tscn`）、ゲーム全体をつなぐ`gdscript/main.gd`、デモ用の`gdscript/demo/hud.gd`と`settings_applier.gd`です。

## カメラ単体で使う

カメラは任意の`Node3D`をターゲットにでき、必要なのは`addons/iso_orbit/orbit_camera/`だけです。

1. `orbit_camera_rig.gd`を付けた`Node3D`を、ターゲットの中ではなく隣に追加します。
2. その子として`camera_arm.gd`を付けた`Node3D`を追加し、さらにその子に`Camera3D`を追加します。
3. リグの`target`に移動するボディを、`arm`にアームノードを設定します。カメラの**Current**を設定します。アームの`fade_target`には、近距離で半透明にしたいモデルのルートを設定するか、空のままにします。
4. [プロジェクトのセットアップ](project-setup.md)にある入力アクションと、アーム用の物理レイヤーを追加します。

リグ、アーム、カメラとその親ノードのスケールはすべて`(1, 1, 1)`に保ち、カメラのローカルトランスフォームは初期値のままにします。アームが実行時に設定します。視野を変えるには、ノードのスケールではなくフレーミング用のプロパティを使ってください。

アームなしで、リグの子に`Camera3D`を置いても動作します。その場合、カメラはズームで設定された距離にとどまり、壁を突き抜けます。リグはターゲットの補間された位置から`_process`で更新されるので、ターゲットが物理ティックで動く場合は、プロジェクトで物理補間をオンにしてください。詳細：[カメラ](systems/camera.md)。

## 完成済みのボディでクリック移動する

`addons/iso_orbit/click_to_move/`と`addons/iso_orbit/ground_character/`をコピーします。

1. レベルのナビゲーションメッシュをベイクします（`NavigationRegion3D` → **ナビゲーションメッシュをベイク**（Bake NavigationMesh））。エージェント半径と最大登坂高さはキャラクターに合わせてください。[ワールドとナビゲーション](systems/world-and-navigation.md)を参照してください。
2. `ground_character.gd`を付けた`CharacterBody3D`を作ります。コリジョンシェイプ、モデル（−Z向き）を入れた`Visual`ノード、そして子として`NavigationMover`（`navigation_mover.gd`を付けた`Node`）と、必要に応じて`LedgeGuard`と`Stamina`を持たせます。ボディの`mover`、`visual`、`ledge_guard`、`stamina`を設定します。
3. ムーバーに`LocomotionSettings`リソースを設定します。空のままにするとデフォルト値が使われます。
4. `point_click_move_input.gd`を付けた`Node`をシーン内の任意の場所に追加し、その`mover`と`camera`を設定します。
5. ダッシュとジャンプのために、必要に応じて`character_action_input.gd`を追加し、`character`にボディを設定します。

`gdscript/player/player.tscn`はこの構成に、サウンド、手の振り、浮遊機能（`Visual/Hover`。初期状態ではオフで、落下速度を遅くする設定付き）、切り替え可能なモデル、シルエットを加えたものです。インスタンス化して不要な部分を外せます。`GroundCharacter`、`LedgeGuard`、`CharacterHover`の設定に誤りがあると、ゲーム開始時に警告が表示されます。

## 操作するヒーロー

`gdscript/player/playable_hero.tscn`は、プレイヤー用の完成済みヒーローです。`player.tscn`を`Character`として配置し（`player`グループに所属）、`PointClickMoveInput`、`CharacterActionInput`、アームとカメラを持つリグ、クリックマーカー、経路線を設定と接続付きで組み合わせています。ゲームシーン内でレベルの隣に1回だけ配置し、レベルの中には入れません。スクリプト`playable_hero.gd`が使うのはアドオンのクラスだけです。

- `place_at(marker)`と`teleport(position, facing)`はヒーローを即座に別の場所へ移します。押下中の入力を忘れ、キャラクターは引っかからずに移動し（`GroundCharacter.teleport()`）、カメラはヒーローの向きへ回って新しい位置に移ります。`turn_camera`がfalseなら、デモ開始時と同様にカメラの角度を維持します。
- `controls_enabled = false`は移動入力、ダッシュ、ジャンプを無効にします。カメラは操作でき、すでにクリックした目的地への走行も続きます。減速させるには`character.mover.stop()`を、水平移動を即座に止めるには`halt()`も呼びます。シーンツリーの一時停止は別の操作です。
- 各部分は型付きプロパティの`character`、`input`、`actions`、`camera_rig`、`camera_arm`、`camera`、`click_marker`、`path_view`、およびキャラクターの`sounds`、`appearance`、`hover`、`silhouette`から参照できます。

独自のモデルを使うには、シーンをコピーして`player.tscn`を自分のキャラクターに置き換えるか、各部分を手動で組み立てます。カメラに重要な接続は2つあります。`PointClickMoveInput.hold_pending_changed`から`OrbitCameraRig.set_follow_paused`への接続と、`PointClickMoveInput.run_requested`から`OrbitCameraRig.end_follow_wait`への接続です（オービット後のカメラは次の走行まで待機します）。残りの4つはクリックマーカーの表示と非表示を制御します。[アーキテクチャ](architecture.md#シーン内で行われる接続)を参照してください。カメラの`sharp_turn_speed`はキャラクターの旋回速度の半分以下にします。この関係を確認して警告を出すのは`PlayableHero`だけです。

## デモのヒーローを自分のプロジェクトへ移植する

テスト済みのデモと同じ構成にするには、Godot 4.7.2、Jolt Physics、Forward+を使います。まず小さなテストレベルを用意し、コピーしたヒーローが動いてから自分のモデル、レベル、設定を追加します。

1. **ファイルを同じパスへコピーします。** 次のフォルダ構成を保ったまま、自分のプロジェクトへ入れます。
   - `addons/iso_orbit/click_to_move/`、`ground_character/`、`orbit_camera/`、`occluded_silhouette/`。
   - `gdscript/player/`：ヒーロー、キャラクター、ヒーローのスクリプト、キャラクターの設定リソース。
   - `shared/characters/`：10種類のモデル、杖と本、マテリアル。
   - `shared/audio/character/`：足音、ジャンプ、着地、ダッシュの音。
   - `shared/world/materials/wood.tres`と`dark_wood.tres`：ドルイドとバトルメイジの木製パーツに使います。ワールドのマテリアルと同じ場所にあるため、`shared/characters/`だけでは不足します。

   これらのファイルの隣にある`.uid`と`.import`もコピーします。シーンはスクリプトとサウンドをIDとパスで見つけます。`.godot/`はコピーしません。移植先のエディターがインポートします。シーンはこれらのパスでファイルを参照するため、別の場所に置くなら先にコピーし、エディターのFileSystemドック内で移動して参照を更新します。
2. **プロジェクトを設定します**（Project Settings）。[プロジェクトのセットアップ](project-setup.md)を参照してください。
   - 入力アクション`move_to_cursor`、`camera_rotate`、`camera_zoom_in`、`camera_zoom_out`、`move_forward`、`move_back`、`move_left`、`move_right`、`sprint`、`jump`。欠けていると、そのアクションを使うコンポーネントが開始時に一度通知し、対応するキーやボタンが効きません。
   - `navigation/3d/default_cell_height`を0.025にします。次の手順のナビゲーションメッシュと合わせるためです。マップと、そこに割り当てるすべてのメッシュのセルサイズを一致させます。
   - 物理補間（`physics/common/physics_interpolation`）をオンにします。カメラが補間されたキャラクター位置を追います。ヒーローはJolt Physics（`physics/3d/physics_engine`）で確認されています。
   - 物理レイヤーを設定します。ヒーローのボディはレイヤー2にあり、レイヤー1と4に衝突します。クリック用レイはレイヤー1の地面を探し、カメラアームはレイヤー1と3で止まります。名前ではなく番号が重要です。地面と壁をレイヤー1に置くか、コピーしたシーンのマスクを変更してください。
3. **テストレベルを作ります。** `NavigationRegion3D`の下に`StaticBody3D`の地面を置き、`BoxShape3D`と見える`BoxMesh`を付けます。どちらも20 × 1 × 20 m、中心は`(0, -0.5, 0)`とし、上面をY = 0にします。中心が`(0, 1, -4)`の2 × 2 × 2 mの箱型障害物を追加し、メッシュと衝突形状を合わせてレイヤー1に置きます。これでSpawnの`(0, 0, 4)`から`(0, 0, -8)`への直線を塞げます。ライトを追加し、必要なら中心`(5, 0.1, 0)`の3 × 0.2 × 3 mの段差も追加します。見えるメッシュだけでは衝突しません。
4. **ナビゲーションメッシュを作成してベイクします。** リージョンを選び、新しい`NavigationMesh`を割り当て、次のように設定します。

   | プロパティ | テストレベルの値 | 理由 |
   |---|---|---|
   | Parsed Geometry Type | Static Colliders | ボディを遮る形状と同じものをベイクする |
   | Geometry Collision Mask | レイヤー1 | 床と障害物を含め、ヒーローを除く |
   | Agent Radius | 0.5 m | 半径0.35 mのカプセルの周囲に余裕を取る |
   | Agent Height | 1.8 m | カプセル全体の高さ以上。最も低い天井も確認する |
   | `filter_walkable_low_height_spans` | `true` | Agent Heightを下回る空間の床を除く |
   | Agent Max Climb | 0.3 m | `Character.max_step_height`に合わせる |
   | Agent Max Slope | 40° | ボディの床判定上限45°より小さくする |
   | Cell Height / Cell Size | 0.025 m / 0.25 m | 細かな垂直段差。ナビゲーションマップの設定と合わせる |

   地面と障害物を**リージョンの下**に置き、**Bake NavigationMesh**を押してシーンを保存します。デモの既存メッシュはAgent Heightが1.75 mで、低い空間を除外するフィルターはオフです。天井のある新しいレベルでは、衝突形状の全高を使ってフィルターを有効にします。ナビゲーションは物理的な衝突を置き換えません。利用できる経路がなければ、このムーバーは目標へ直接移動する場合があり、その状態では壁を迂回できません。詳細は[ワールドとナビゲーション](systems/world-and-navigation.md#物理レイヤーとナビゲーション)を参照してください。
5. **ヒーローをリージョンの兄弟ノードとしてインスタンス化**し、`Hero`という名前にします。`(0, 0, 4)`に`Spawn`という`Marker3D`を追加します。ヒーローのルートスケールを`(1, 1, 1)`に保ち、カメラをCurrentにします。最小構成は次のとおりです。

   ```text
   Game (Node3D)
   ├── NavigationRegion3D
   │   ├── Ground (StaticBody3D：衝突形状とメッシュ付き)
   │   └── Obstacle (StaticBody3D：衝突形状とメッシュ付き)
   ├── Hero (playable_hero.tscnのインスタンス)
   ├── Spawn (Marker3D)
   └── DirectionalLight3D
   ```

   次のスクリプトを`Game`に付け、そのシーンを実行します。

   ```gdscript
   extends Node3D

   @onready var hero: PlayableHero = $Hero


   func _ready() -> void:
       hero.place_at($Spawn, false)
   ```

   `false`はカメラの初期45°オービット角を維持します。省くと、カメラはマーカーの−Z方向の後ろへ移ります。起動後に配置やテレポートを行うときは、**ヒーローAPIを通してキャラクター**を動かします。`Hero`のルートは動かないコンテナで、移動するボディを追いません。プレイヤーの現在位置には`hero.character.global_position`を使います。
6. **カスタマイズ前に結果を確認します。** 障害物の向こうにある`(0, 0, -8)`付近の地面をクリックすると、ヒーローが迂回して停止するはずです。目的地が見えなければズームアウトします。左ボタンを押し続けると直接操舵し、離すと停止するはずです。右ボタンでのオービット、ホイールズーム、右ボタン＋WASD、Shift、Spaceも試します。付属の移動リソースでは通常速度5.5 m/s、ダッシュ速度8.25 m/s、ジャンプ高1 mで、0.2 mの段差にはジャンプが不要です。デバッガーで入力アクション、リソース、設定の警告を確認してください。

コピーしたシーンは、設定システムがなくてもデモの標準動作になります。2つのキーモードは`TURN`で、カメラの追従、上下角と高さの自動調整、浮遊、ダッシュ音はオフです。最初のモデルはネクロマンサーです。正確なノードパス、デフォルト値の種類、2つの応用構成は[構成](configurations.md)を参照してください。

### 移植時のトラブルシューティング

| 症状 | 最初に確認すること |
|---|---|
| グローバルクラスまたはリソースが見つからない | 4つのアドオンフォルダと指定したアセットを元のパスにコピーし、エディターのインポート完了を待つ。2つの木材マテリアルも含める |
| ヒーローが床をすり抜ける | 床にはレイヤー1のコリジョンシェイプが必要。MeshInstance3Dだけでは見た目にすぎない |
| クリックしても動かない | Input Mapアクション、有効なカメラ、`PlayerInput.camera`、レイの`ground_mask`を確認する。重なったControlがマウス入力を消費している場合もある |
| 壁を迂回せず突き当たる | リージョンの下にあるコライダーをベイクし、リージョンとムーバーのナビゲーションレイヤーおよび生成されたメッシュを確認する |
| ヒーローが上れない段差を経路が横切る | 登坂高を`max_step_height`に合わせ、垂直セルを細かくして再ベイクし、実際の形状で試す |
| 起動時にシーンの編集結果が消える | コピーした`SettingsApplier`が保存済み設定で上書きしている可能性がある。単独のヒーローには不要 |
| 移動を変えた後、カメラが予期せず回る | キャラクターの`turn_speed`とカメラの`sharp_turn_speed`を比べる。[構成](configurations.md#構成を崩さずに調整する)を参照 |

覚えておくこと：

- アドオンと`playable_hero.gd`はグローバルクラス名を宣言します（`GroundCharacter`、`NavigationMover`、`OrbitCameraRig`、`PlayableHero`、その他のクラスは[上の表](#アドオン)を参照）。自分のプロジェクトに同名のクラスがあると衝突するため、どちらかの名前を変更します。
- キャラクターの旋回速度（`LocomotionSettings`の`turn_speed`）を変えるときは、`CameraRig.sharp_turn_speed`をその半分以下に保ちます。これより高いと、カメラが方向転換中の向きを横方向への走行と解釈し、回転する場合があります。旋回速度より小さくない場合、ヒーローは開始時に警告します。
- `Settings`の自動読み込みも設定ウィンドウも不要です。HUDはヒーローに含まれません。スタミナバーと場所の通知はデモの`main.tscn`で追加されます。テーマについては[アドオン](#アドオン)の注記を参照してください。
- モデルとサウンドもコードと同じく、プロジェクトのMITライセンスに従います。

## レベル

`addons/iso_orbit/levels/`をコピーします。メインシーンには、開始レベルだけを子として持つ`LevelHost`、その隣のヒーロー、`loading_screen.tscn`を配置します。メインスクリプトではホストのシグナルを接続します。`level_change_started`で操作を無効にし、`level_loaded(level, spawn)`でヒーローを`spawn`に置き、`level_change_finished`で操作を戻します。`level_change_failed`でも操作を戻します（レベルは残り、`level_change_finished`は来ません）。`portal_entered`と`portal_exited`では移動先の案内を表示・非表示にします。`gdscript/main.gd`がこの処理を実装しています。各レベルには`default`という名前の`SpawnPoint`が必要です。ポータルは行き先シーンのパスを持つ`LevelPortal`エリアです。

独自のレベルシステムを使うなら、操作するヒーローだけを取り、レベルの準備ができたときに`place_at()`を呼びます。独自のキャラクターでは`GroundCharacter.teleport()`で同じように配置します。詳細、デフォルト値、設定の組み合わせは[レベル](systems/levels.md)を参照してください。

## 独自のボディ

独自のキャラクターコントローラーを使い続けるなら、`addons/iso_orbit/click_to_move/`だけを使います。守るべき約束はわずかです。

- `NavigationMover`はボディ（任意の`Node3D`）の直接の子でなければなりません。ボディの位置と、ボディが属するワールドのナビゲーションマップを読み取ります。
- ボディは物理ティックごとに1回、`move_and_slide()`の前に`mover.compute_velocity(delta)`を呼び、結果のXとZを適用します。ムーバーがボディを動かすことはありません。
- 垂直方向の速度（重力、ジャンプ、ノックバック）はボディが担当します。

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
```

この最小構成のボディには、独自のコリジョンシェイプ、床、表示用のカメラが必要です。モデルは`Visual`ノードの下に追加します。移動方向を向かせるには、そのノードの−Zをワールド空間の`mover.get_facing()`へ向けます。ボディを自作する必要がなければ、`GroundCharacter`が親ノードの回転も含めて見た目の向きを処理します。

`LedgeGuard`は任意で、`addons/iso_orbit/ground_character/`が必要です。ボディの子として追加し、`move_and_slide()`より前に`velocity = ledge_guard.constrain(velocity, delta)`を適用します。ダッシュには`mover.sprinting = true`を設定します。速度上限が`LocomotionSettings.sprint_speed_multiplier`倍になります。その場合、`GroundCharacter`が担う残りの機能（ジャンプ、スタミナ、階段、状態とシグナル、モデルの滑らかな旋回）は自分で実装します。

## ムーバーへの命令

プレイヤーの入力、AI、カットシーン、ネットワークコードなど、何からでもキャラクターを動かせます。

| 呼び出し | 効果 |
|---|---|
| `move_to(point)` | グローバル座標の地点へナビゲーション経路をたどる。到達できない目標では最も近い到達可能な経路上の地点で終わる場合があり、経路が空なら直接移動に切り替わる。現在の目標から`retarget_tolerance`（0.1 m）以内では経路を再構築しない |
| `steer(direction, facing = Vector3.ZERO)` | 別の指示があるまで、経路なしで指定の方向へ走る。`facing`を指定すると、移動中はその方向を向く（横移動） |
| `stop()` | その場で滑らかに減速して止まる |
| `halt()` | 即座に止まる。たとえばテレポートの後に使う |
| `face(direction)` | スポーン地点などで、停止中のキャラクターを即座に指定方向へ向ける |

キャラクター全体を別の場所へ移すには、`GroundCharacter.teleport(position, facing)`を呼びます。ムーバーを即座に止め、キャラクターとモデルの向きを変え、追従するものが急に跳ねないようボディを移します。

シグナル：`destination_changed(point)`、`path_changed`、`arrived`、`destination_cancelled`（`steer()`や`stop()`のために地点が放棄された）。問い合わせ：`is_moving()`、`is_steering()`、`has_destination()`、`get_destination()`、`get_speed()`、`get_heading()`、`get_facing()`、`get_remaining_path()`。詳細：[ロコモーション](systems/locomotion.md)。

## NPC

`player.tscn`（またはムーバー付きの独自ボディシーン）をインスタンス化し、プレイヤー専用の`Silhouette`と`Appearance`ノードを削除します。入力ノードは追加せず、AIから`NavigationMover.move_to()`を呼び、`arrived`を受け取ります。デモのキャラクターモデルを使うなら、`Visual/Hover`の下に`Model`として置きます。エディターでNPCを回転すると開始時の向きが決まります。その後は`GroundCharacter.teleport(position, facing)`または`NavigationMover.face()`で向きを変えます。デモレベルに立っているNPCはキャラクターではなく静的ボディです。[ワールドとナビゲーション](systems/world-and-navigation.md)を参照してください。

## 設定

コンポーネントが設定を読むことはなく、それぞれ自身のエクスポートされたプロパティを読みます。それらを自分の設定メニューに出すには、設定が変わったときに自分のコードからプロパティを設定します。`gdscript/demo/settings_applier.gd`がその例で、1つの`match`で各設定キーをノードのプロパティに対応付けています。デモの設定システムも再利用するには、`gdscript/settings/game_settings.gd`をコピーして`Settings`という名前の自動読み込み（Autoload）として登録し、キーと`DEFAULTS`を自分のものに置き換え、`gdscript/ui/settings/`からコントロールを持ってきます。[UI](systems/ui.md#設定)を参照してください。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
