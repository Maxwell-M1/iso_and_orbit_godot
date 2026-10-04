<!-- translation of docs/en/architecture.md @ 8409307c5782 -->
# アーキテクチャ

> これは[英語の原文](../en/architecture.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

デモは`gdscript/main.tscn`という1つのシーンです。それぞれの挙動は、1つの役割だけを持つ個別のノードです。コンポーネントは自身のエクスポートされたプロパティを読み、メソッドとシグナルを公開し、シーン内でノード参照とシグナル接続を通じて隣のノードとつながります。残っているわずかな検索処理は設定で変更できます。`DiscoveryToast`はグループで場所を見つけ、`CharacterAppearance`はエクスポートされた名前でモデルとその手を見つけ、`CharacterSounds`は`character`プロパティが空なら親を使います。

## メインシーン

```
Main (Node3D)
├── World              shared/world/world.tscn：レベル、そのナビゲーションメッシュ、場所、NPC
├── Player             gdscript/player/player.tscn：GroundCharacter、グループ "player"
│   ├── CollisionShape3D   カプセル、半径0.35 m、高さ1.8 m
│   ├── Visual             キャラクターの進む方向へ向けられる
│   │   └── Model          現在の主人公の外見。そのRightHandが杖を持つ
│   ├── Silhouette         OccludedSilhouette：障害物越しに見える主人公
│   ├── Appearance         CharacterAppearance：実行時にVisual/Modelを差し替える
│   ├── RightHandSway      HandSway：歩みに合わせて右手を振る
│   ├── NavigationMover    経路と速度
│   ├── LedgeGuard         ボディが段差から歩いて落ちるのを防ぐ
│   ├── Stamina            ダッシュの蓄え
│   └── Sounds             CharacterSoundsと5つのAudioStreamPlayer3D
├── PlayerInput        PointClickMoveInput：マウスとWASD → Player/NavigationMover
├── PlayerActionInput  CharacterActionInput：ShiftとSpace → Player
├── CameraRig          OrbitCameraRig：Playerを追従、回転とズーム
│   └── CameraArm      CameraArm：障害物で縮む
│       └── Camera3D
├── ClickMarker        クリックした地点の地面に出るリング
├── PathView           NavigationPathView：デバッグ用の経路線、デフォルトでは非表示
├── Hud                操作ヒントと速度、FpsCounter、DiscoveryToast、StaminaBar
├── SettingsApplier    設定 → ノードのプロパティ（デモのみ）
└── UiRoot             ゲームの上に重なるウィンドウ：設定ウィンドウ
```

`player.tscn`にはキャラクターだけが入っています。入力ノードは`main.tscn`にあるので、同じキャラクターシーンをAI、カットシーン、ネットワークピアなど、ほかのものから動かせます。

## データの流れ

```
マウス/WASD ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (パスまたは         (加速、ブレーキ、
                                    ──stop()────────────►  方向)               旋回：単純な計算)
                                                               ▲
                                                               │ compute_velocity(delta)
                                                               │ 水平方向の速度を返す
Shift, Space ──► CharacterActionInput ──sprint_requested──► GroundCharacter ──► LedgeGuard.constrain()
                                      ──jump()────────────►  (CharacterBody3D)  ──► move_and_slide()
                                                                   │
                                     シグナル：stepped, jumped, landed, sprint_changed
                                                                   ▼
                                                   CharacterSounds, HandSway, その他何でも

マウス ──► OrbitCameraRig ──► CameraArm ──► Camera3D
          (ターゲットの補間された位置への追従、回転、ズーム、オプションの自動追従)
```

入力がボディに触れることはありません。入力は`NavigationMover`にコマンドを送ります。ムーバーもボディには触れず、ボディに求められたときに速度を返します。カメラと入力は互いを知りません。

## 1回の物理ティック

1. `CharacterActionInput`はキャラクターより先に実行されます（`process_physics_priority = -1`）。`GroundCharacter.sprint_requested`を設定して`jump()`を呼ぶので、キー入力は同じティックのうちにボディに届きます。
2. `GroundCharacter._physics_process`（ボディが動く唯一の場所）：
   1. キャラクターがダッシュするか（要求されている、許可されている、移動中、疲れ切っていない）を決め、スタミナを消費します。
   2. `mover.compute_velocity(delta)`を呼び、そのXとZを水平方向の速度とします。
   3. ジャンプがバッファされていて、ボディが床の上にいるか床を離れた直後なら（コヨーテタイム）、ジャンプを開始します。
   4. 空中では、重力に`gravity_scale`を掛けたものを加えます。
   5. キャラクターがジャンプ中でなければ、`LedgeGuard.constrain()`に速度を縁に沿った向きへ変えさせます。
   6. `move_and_slide()`を呼びます。
   7. `landed`と`stepped`を発信し、`Visual`を`mover.get_facing()`の方へ向けます。
3. `HandSway`はボディの後に実行され（`process_physics_priority = 1`）、ボディの新しい状態に基づいて手を動かします。

`PointClickMoveInput._physics_process`は、誰がキャラクターを動かすか（押されたマウスボタン、そうでなければ右ボタンと組み合わせたキー）を1か所で決め、`move_to()`、`steer()`、`stop()`のいずれかを呼びます。ムーバーは最後のコマンドを保持し、ボディは次に`compute_velocity()`を呼んだときにそれを受け取ります。

描画されるフレームごとに、`OrbitCameraRig._process`はリグをターゲットの補間されたトランスフォームに置き、その直後に子の`CameraArm`が更新されます。`PointClickMoveInput`は`process_priority = 1`なので、そのフレームのカメラ位置が確定した後でカーソル位置を補正します。

## コンポーネント

再利用可能なコンポーネントは`addons/iso_orbit/`にあり、単独で取り出せるパーツごとに1つのフォルダになっています。各スクリプトはクラス名をスネークケースにした名前です。たとえば`OrbitCameraRig`は`addons/iso_orbit/orbit_camera/orbit_camera_rig.gd`です。

| アドオン | クラス | 役割 |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`（Node3D） | ターゲットを追い、右ボタンで回転、ホイールでズーム。オプションで走る方向へ向く |
| | `CameraArm`（Node3D） | 先端にカメラを保持し、障害物で縮む。近づくとターゲットをフェードさせる |
| `click_to_move` | `LocomotionSettings`（Resource） | 速度、加速、減速、旋回。1つのリソースを多くのキャラクターで共有できる |
| | `GroundMotion`（RefCounted） | ノードを使わない運動学：目標の方向と残り距離 → 水平方向の速度 |
| | `NavigationMover`（Node） | ナビゲーション経路に沿って正確に停止する`move_to()`、方向を指定する`steer()`、`stop()`。速度を返し、ボディは動かさない |
| | `PointClickMoveInput`（Node） | マウスと右ボタン + WASD → ムーバーへのコマンド。カーソルを隠し、狙いを補正する |
| | `ClickMarker`（Node3D） | クリックした地点のマーカー（`click_marker.tscn`） |
| | `NavigationPathView`（MeshInstance3D） | ムーバーの残りの経路を描画する |
| `ground_character` | `GroundCharacter`（CharacterBody3D） | 重力、ジャンプ、スタミナ付きダッシュ、`move_and_slide()`、モデルの回転。ステップ、ジャンプ、着地、ダッシュのシグナル |
| | `LedgeGuard`（Node） | 段差でボディを止めるか、縁に沿って滑らせる |
| | `Stamina`（Node） | 消費されては回復する蓄え。何がそれを消費するかは知らない |
| | `CharacterActionInput`（Node） | ダッシュとジャンプのキー → キャラクター |
| | `CharacterSounds`（Node3D） | キャラクターのシグナルに応じてサウンドを再生する |
| | `HandSway`（Node） | 歩みに合わせて手のノードを振る。動き出し、停止、旋回、着地では慣性が働く |
| | `CharacterAppearance`（Node） | 実行時にキャラクターのモデルを差し替える |
| | `StaminaBar`（ProgressBar） | HUDのスタミナバー（`stamina_bar.tscn`） |
| `occluded_silhouette` | `OccludedSilhouette`（Node） | 何かに隠れた部分のキャラクターをシルエットとして描画する。そのシェーダーとマテリアルは同じフォルダにある |
| `points_of_interest` | `PointOfInterest`（Area3D） | 発見する場所：プレイヤーが初めて入ったときに`discovered(title)`を発信する |
| | `DiscoveryToast`（Label） | 「発見：…」を数秒間画面に表示する（`discovery_toast.tscn`） |
| `ui_screens` | `UiRoot`（CanvasLayer） | ウィンドウのスタック：開く、Escで最前面のウィンドウを閉じる、一時停止、カーソル、キーボードフォーカス |
| | `UiScreen`（Control） | ウィンドウの基底：`initial_focus`、`close_requested` |
| | `FpsCounter`（Label） | 毎秒のフレーム数。一時停止中も表示する（`fps_counter.tscn`） |

`ground_character`には`click_to_move`が必要です（ボディが`NavigationMover`を動かすため）。ほかのアドオンはエンジン以外に何も必要としません。それぞれがプロジェクトに求めるもの：[プロジェクトへの組み込み](integration.md)。

`gdscript/`のデモがそれらを組み立てています。

| ファイル | 役割 |
|---|---|
| `main.tscn` | デモシーン |
| `player/player.tscn`、`player_locomotion.tres` | 主人公：すべてのパーツを備えた`GroundCharacter`と、その走行設定 |
| `demo/hud.gd` | 操作ヒントと速度表示 |
| `demo/settings_applier.gd` | 設定をデモのノードに適用する。「設定 → プロパティ」の対応を1か所にまとめる |
| `settings/game_settings.gd` | `GameSettings`（`Settings`自動読み込み）：デフォルト値、`user://settings.cfg`、`changed`シグナル。エンジンの設定は自身で適用する |
| `ui/ui_root.tscn` | 設定ウィンドウとF10を備えた`UiRoot` |
| `ui/settings/settings_screen.tscn`、`.gd` | 設定ウィンドウ |
| `ui/settings/setting_*.gd` | `SettingCheckButton`、`SettingOptionButton`、`SettingSlider`、`SettingLanguageButton`：設定キーに結び付けられたコントロール |

各システムには専用のページがあります：[ロコモーション](systems/locomotion.md)、[カメラ](systems/camera.md)、[入力](systems/input.md)、[キャラクター](systems/characters.md)、[オーディオ](systems/audio.md)、[UI](systems/ui.md)、[ワールドとナビゲーション](systems/world-and-navigation.md)。

## シーン内での接続

ノード参照は、`main.tscn`と`player.tscn`で設定されたエクスポートプロパティです。`main.tscn`でのシグナル接続：

| シグナル | 接続先 | 効果 |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | クリックした地点にマーカーが表示される |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | 長押しがクリックに取って代わり、マーカーが消えていく |
| `Player/NavigationMover.arrived` | `ClickMarker.fade_out` | キャラクターが地点に到達した |
| `Player/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | 地点が放棄された |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | 押下がクリックか長押しか判明するまで、カメラは自動で回転しない |

## 設定

`Settings`自動読み込み（Autoload、`GameSettings`）は値を保存し、`changed(key, value)`を発信します。エンジンレベルの設定（フルスクリーン、フレームレート上限、V-Sync、物理補間、UIスケール、言語、音量）は自身で適用します。それ以外はすべて`gdscript/demo/settings_applier.gd`が適用し、各キーをノードのプロパティに対応付けます。コンポーネント自身が設定を読むことはありません。[設定](settings.md)を参照してください。

## なぜこのような構成なのか

- **ボディを動かすのは`GroundCharacter`だけです**。移動コンポーネントは速度を返すだけで、`move_and_slide()`を呼びません。重力、ジャンプ、将来のノックバックは1か所でまとめて処理されるので、互いに競合することがありません。
- **`GroundMotion`はノードを使わない計算です**。加速と減速は状態の純粋関数なので、単独でテストしやすく、別の言語へ1行ずつ移植するのも簡単です。
- **キャラクターはマウスについて何も知りません**。メインシーンの`PlayerInput`がそのムーバーを動かしているから、プレイヤーのキャラクターになっているだけです。NPCにするには、プレイヤー専用の`Silhouette`ノードと`Appearance`ノードを除いて`player.tscn`をインスタンス化し、AIから`NavigationMover.move_to()`を呼び出します。
- **カメラはキャラクターの子ではなく兄弟です**。カメラは`_process`でターゲットの補間された位置へ移動し、自身は補間されないので、物理補間がオンなら（デフォルトでオン、設定 → 表示）、どのフレームレートでも走りが滑らかになります。追従モードでは、カメラは物理ティックごとのターゲットの移動量からその速度を計算するので、どんな`Node3D`でもターゲットにできます。
- **コンポーネントは設定について何も知りません**。`LedgeGuard`、`PointClickMoveInput`、`OrbitCameraRig`などは自身のプロパティを読むだけで、`Settings`自動読み込みとやり取りするのは`settings_applier.gd`と設定ウィンドウだけです。コンポーネントは設定システムなしで別のプロジェクトへ移せます。
- **ウィンドウはGodotの慣例に従います**。レイアウトにはコンテナだけを使い、見た目は各ノードのオーバーライドではなく、プロジェクトのテーマとそのタイプバリエーションから決まります。ウィンドウはシグナルで閉じるよう要求し、`UiRoot`がそれを閉じます（呼び出しはツリーを下り、シグナルは上る）。キーは入力アクションです。キーボードフォーカスはウィンドウを開いたときに設定され、閉じたときに元に戻ります。ウィンドウが開いている間はゲームが一時停止し（`UiRoot`は`PROCESS_MODE_ALWAYS`で動作）、カメラはキャプチャしたカーソルを解放します。

## フォルダ

| フォルダ | 内容 |
|---|---|
| `addons/iso_orbit/` | 再利用可能なコンポーネント。パーツごとに1つのフォルダ |
| `gdscript/` | GDScriptによるデモ：メインシーン、主人公、設定システムと設定ウィンドウ、HUDのヒント |
| `shared/` | スクリプト言語に依存しないデモコンテンツ：レベル、キャラクターと装備、ワールドのシェーダーとテクスチャ、サウンド、UIテーマ |
| `l10n/` | インターフェースの翻訳 |
| `tests/` | ヘッドレステスト。[テスト](testing.md)を参照 |
| `docs/` | このドキュメント |

`shared/`は、将来のC#版デモで再利用することを想定しています。C#版は`gdscript/`の隣に専用のフォルダを持つことになります。現時点では例外が2つあります。`world.tscn`と`mountain.tscn`が`addons/iso_orbit/points_of_interest/point_of_interest.gd`を使っていることと、2つの小さなプロップ用スクリプト（`flicker.gd`、`hover_spin.gd`）が`shared/world/props/`にあることです。[既知の問題](known-issues.md)を参照してください。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
