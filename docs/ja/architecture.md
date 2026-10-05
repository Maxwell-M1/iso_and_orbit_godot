<!-- translation of docs/en/architecture.md @ adf142a1b736 -->
# アーキテクチャ

[← ドキュメント目次](index.md)

> これは[英語の原文](../en/architecture.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

デモは現在のレベル、ヒーロー、インターフェースを保持するゲーム全体のシーン`gdscript/main.tscn`から始まります。各動作は役割が1つの独立したノードです。コンポーネントは自身のエクスポートされたプロパティを読み、メソッドとシグナルを公開し、シーン内のノード参照とシグナル接続で隣とつながります。残る少数の検索は設定可能です。`DiscoveryToast`とゲーム全体のシーンは場所をグループで探し、`LevelHost`はレベルのポータルとスポーン地点をグループで探します。`PointOfInterest`と`LevelPortal`は`player`グループでプレイヤーのボディを知ります（`player_group`、`traveller_group`）。`CharacterAppearance`はエクスポートされた名前でモデルと手を探し、`CharacterSounds`は`character`が空なら親を使います。

## メインシーン

```
Main (Node3D, main.gd)   レベル、ヒーロー、UIをつなぐゲーム全体のシーン
├── Levels             LevelHost：ローディング画面の背後で切り替わる現在のレベル
│   └── World          shared/world/world.tscn：開始レベル、ナビゲーション、場所、NPC、パッド
├── Hero               gdscript/player/playable_hero.tscn：操作するヒーロー
│   ├── Character          gdscript/player/player.tscn：GroundCharacter、グループ "player"
│   │   ├── CollisionShape3D   カプセル、半径0.35 m、高さ1.8 m
│   │   ├── Visual             キャラクターの進行方向へ回る
│   │   │   └── Hover          CharacterHover：モデルを浮かせる。デフォルトではオフ
│   │   │       └── Model      現在の外見。RightHandに杖を持つ
│   │   ├── Silhouette         OccludedSilhouette：障害物越しのヒーロー
│   │   ├── Appearance         CharacterAppearance：Visual/Hover/Modelを交換
│   │   ├── RightHandSway      HandSway：歩みに合わせて右手を振る
│   │   ├── NavigationMover    経路と速度
│   │   ├── LedgeGuard         崖からの落下を防ぐ
│   │   ├── Stamina            ダッシュの蓄え
│   │   └── Sounds             CharacterSoundsと5つのAudioStreamPlayer3D
│   ├── PlayerInput        PointClickMoveInput：マウスとWASD → Character/NavigationMover
│   ├── PlayerActionInput  CharacterActionInput：ShiftとSpace → Character
│   ├── CameraRig          OrbitCameraRig：Characterを追い、回転とズーム
│   │   └── CameraArm      CameraArm：障害物で縮む
│   │       └── Camera3D
│   ├── ClickMarker        クリック地点の地面に出るリング
│   └── PathView           NavigationPathView：デバッグ用の経路線、通常は非表示
├── Hud                操作ヒントと速度、FpsCounter、CharacterState、DiscoveryToast、StaminaBar、
│                      TravelPrompt（パッド上での移動案内）
├── SettingsApplier    設定 → ノードのプロパティ（デモのみ）
├── UiRoot             ゲーム上のウィンドウ：設定ウィンドウ
└── LoadingScreen      LoadingScreen：レベル読み込み中の画面
```

`player.tscn`にはキャラクターだけが入ります。入力ノードは`playable_hero.tscn`にあるため、同じキャラクターシーンをAI、カットシーン、ネットワークピアでも操作できます。ヒーローはレベルの中でなくレベルホストの隣にあり、周りのレベルだけが切り替わります。[レベル](systems/levels.md)を参照してください。

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
     シグナル：state_changed, stepped, jumped, left_floor, touched_floor, landed, sprint_changed, stair_taken,
              teleported
                                                                   ▼
                    CharacterSounds, HandSway, CharacterHover, CharacterMonitor, アニメーションなど

マウス ──► OrbitCameraRig ──► CameraArm ──► Camera3D
          (ターゲットの補間された位置への追従、回転、ズーム、オプションの自動追従)

LevelPortal ──traveller_entered──► LevelHost ──portal_entered──► main.gd ──► TravelPrompt
     ▲                                  │                                       │ Eまたはクリック
     └───────────── travel() ───────────┼─────────── main.gd ◄── confirmed ─────┘
                                        ▼
    change_level(): 一時停止、LoadingScreen、非同期読み込み、入れ替え ──level_loaded──► main.gd ──► PlayableHero.place_at()
```

入力がボディに触れることはありません。入力は`NavigationMover`にコマンドを送ります。ムーバーもボディには触れず、ボディに求められたときに速度を返します。カメラと入力は互いを知りません。

## 1回の物理ティック

1. `CharacterActionInput`はキャラクターより先に実行されます（`process_physics_priority = -1`）。`GroundCharacter.sprint_requested`を設定して`jump()`を呼ぶので、キー入力は同じティックのうちにボディに届きます。
2. `GroundCharacter._physics_process`（ボディが動く唯一の場所）：
   1. キャラクターがダッシュするか（要求されている、許可されている、移動中、疲れ切っていない）を決め、スタミナを消費します。
   2. `mover.compute_velocity(delta)`を呼び、そのXとZを水平方向の速度とします。
   3. ジャンプがバッファされていて、ボディが床の上にいるか床を離れた直後なら（コヨーテタイム）、ジャンプを開始します。
   4. 空中では重力を加えます。ジャンプの上昇は`gravity_scale`で減速し、下降は有効な落下設定（`get_fall_settings()`）に従います。
   5. ジャンプ中でなければ`LedgeGuard.constrain()`に速度を縁に沿わせ、駆動速度の加速を`get_local_acceleration()`で測ります。
   6. `move_and_slide()`を呼びます。呼ぶ前に段を上り、呼んだ後に段を下ります（`max_step_height`）。
   7. `left_floor`、`touched_floor`、`landed`、`stair_taken`、`stepped`を発信し、`Visual`を`mover.get_facing()`へ向け、状態が変われば`state_changed`を発信します。
3. `HandSway`と`CharacterHover`はボディの後に実行され（`process_physics_priority = 1`）、新しい状態に基づいて手とモデルを動かします。

`PointClickMoveInput._physics_process`は、誰がキャラクターを動かすか（押されたマウスボタン、そうでなければ右ボタンと組み合わせたキー）を1か所で決め、`move_to()`、`steer()`、`stop()`のいずれかを呼びます。ムーバーは最後のコマンドを保持し、ボディは次に`compute_velocity()`を呼んだときにそれを受け取ります。

描画されるフレームごとに、`OrbitCameraRig._process`はリグをターゲットの補間されたトランスフォームに置き、その直後に子の`CameraArm`が更新されます。`PointClickMoveInput`は`process_priority = 1`なので、そのフレームのカメラ位置が確定した後でカーソル位置を補正します。

## コンポーネント

再利用可能なコンポーネントは`addons/iso_orbit/`にあり、単独で取り出せるパーツごとに1つのフォルダになっています。各スクリプトはクラス名をスネークケースにした名前です。たとえば`OrbitCameraRig`は`addons/iso_orbit/orbit_camera/orbit_camera_rig.gd`です。

| アドオン | クラス | 役割 |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`（Node3D） | ターゲットを追い、右ボタンで回転、ホイールでズーム。任意で走行の後ろへ回り、傾きと高さも滑らかに調整する |
| | `CameraArm`（Node3D） | 先端にカメラを保持し、障害物で縮む。近づくとターゲットをフェードさせる |
| `click_to_move` | `LocomotionSettings`（Resource） | 速度、加速、減速、旋回。1つのリソースを多くのキャラクターで共有できる |
| | `GroundMotion`（RefCounted） | ノードを使わない運動学：目標の方向と残り距離 → 水平方向の速度 |
| | `NavigationMover`（Node） | ナビゲーション経路に沿って正確に停止する`move_to()`、方向を指定する`steer()`、`stop()`。速度を返し、ボディは動かさない |
| | `PointClickMoveInput`（Node） | マウスと右ボタン + WASD → ムーバーへのコマンド。カーソルを隠し、狙いを補正する |
| | `ClickMarker`（Node3D） | クリックした地点のマーカー（`click_marker.tscn`） |
| | `NavigationPathView`（MeshInstance3D） | ムーバーの残りの経路を描画する |
| `ground_character` | `GroundCharacter`（CharacterBody3D） | 重力、ジャンプ、スタミナ付きダッシュ、階段、`move_and_slide()`、モデルの回転。アニメーション、サウンド、インターフェースのために状態、ステップ、踏み切り、着地を通知する |
| | `FallSettings`（Resource） | 落下時の重力、速度上限、超過速度からの減速。複数のキャラクターで共有できる |
| | `LedgeGuard`（Node） | 段差でボディを止めるか、縁に沿って滑らせる |
| | `Stamina`（Node） | 消費されては回復する蓄え。何がそれを消費するかは知らない |
| | `CharacterActionInput`（Node） | ダッシュとジャンプのキー → キャラクター |
| | `CharacterSounds`（Node3D） | キャラクターのシグナルに応じてサウンドを再生する |
| | `HandSway`（Node） | 歩みに合わせて手のノードを振る。動き出し、停止、旋回、着地では慣性が働く |
| | `CharacterHover`（Node3D） | モデルを地面から浮かせ、階段を滑らかに越え、揺らして傾ける。浮遊中は歩数を止め、落下も遅くできる |
| | `DampedSpring`（RefCounted） | `HandSway`と`CharacterHover`が使う、1つの値を扱う慣性用の減衰ばね |
| | `CharacterMonitor`（Label） | キャラクターの状態と最新のイベントをテキストで表示する。イベントを出力に記録することもできる |
| | `CharacterAppearance`（Node） | 実行時にキャラクターのモデルを差し替える |
| | `StaminaBar`（ProgressBar） | HUDのスタミナバー（`stamina_bar.tscn`） |
| `occluded_silhouette` | `OccludedSilhouette`（Node） | 何かに隠れた部分のキャラクターをシルエットとして描画する。そのシェーダーとマテリアルは同じフォルダにある |
| `points_of_interest` | `PointOfInterest`（Area3D） | 発見する場所：プレイヤーが初めて入ったときに`discovered(title)`を発信する |
| | `DiscoveryToast`（Label） | 「発見：…」を数秒間画面に表示する（`discovery_toast.tscn`） |
| `ui_screens` | `UiRoot`（CanvasLayer） | ウィンドウのスタック：開く、Escで最前面のウィンドウを閉じる、一時停止、カーソル、キーボードフォーカス |
| | `UiScreen`（Control） | ウィンドウの基底：`initial_focus`、`close_requested` |
| | `FpsCounter`（Label） | 毎秒のフレーム数。一時停止中も表示する（`fps_counter.tscn`） |
| | `InputNames`（RefCounted） | 入力アクションに割り当てたキー名を文に入れる。`{sprint}` → 「Shift」 |
| | `ActionTexts`（Node） | 子のコントロールの文にキー名を入れ、言語変更後も更新する |
| `levels` | `LevelHost`（Node3D） | 現在のレベルを保持し、ローディング画面の背後で読み込み、入れ替え、ナビゲーションマップの準備とウォームアップを行い、各段階をシグナルで通知する |
| | `LevelPortal`（Area3D） | 別のレベルへの入口。移動者を報告し、`travel()`または自動で移動する |
| | `SpawnPoint`（Marker3D） | 名前で指定するキャラクターのレベル内の出現場所 |
| | `LoadingScreen`（CanvasLayer） | ぼかした直前のフレーム、場所名、進捗バー、ヒントを表示する（`loading_screen.tscn`） |

`ground_character`には`click_to_move`が必要です（ボディが`NavigationMover`を動かすため）。ほかのアドオンはエンジン以外に何も必要としません。それぞれがプロジェクトに求めるもの：[プロジェクトへの組み込み](integration.md)。

`gdscript/`のデモがそれらを組み立てています。

| ファイル | 役割 |
|---|---|
| `main.tscn`、`main.gd` | 開始レベルを持つレベルホスト、ヒーロー、UI、ローディング画面をつなぐゲーム全体のシーン。`main.gd`が接続する |
| `player/player.tscn`、`player_locomotion.tres` | 主人公：すべてのパーツを備えた`GroundCharacter`と、その走行設定 |
| `player/playable_hero.tscn`、`.gd` | `PlayableHero`。入力、カメラ、クリックマーカー、経路線付きのキャラクターで、ゲームシーンに配置できる |
| `ui/travel_prompt.tscn`、`.gd` | `TravelPrompt`。キーと場所名を示す、パッド上の移動案内 |
| `demo/hud.gd` | 操作ヒントと速度表示 |
| `demo/settings_applier.gd` | 設定をデモのノードに適用する。「設定 → プロパティ」の対応を1か所にまとめる |
| `settings/game_settings.gd` | `GameSettings`（`Settings`自動読み込み）：デフォルト値、`user://settings.cfg`、`changed`シグナル。エンジンの設定は自身で適用する |
| `ui/ui_root.tscn` | 設定ウィンドウとF10を備えた`UiRoot` |
| `ui/settings/settings_screen.tscn`、`.gd` | 設定ウィンドウ |
| `ui/settings/setting_*.gd` | `SettingCheckButton`、`SettingOptionButton`、`SettingSlider`、`SettingLanguageButton`：設定キーに結び付けられたコントロール |

各システムには専用のページがあります：[ロコモーション](systems/locomotion.md)、[カメラ](systems/camera.md)、[入力](systems/input.md)、[キャラクター](systems/characters.md)、[オーディオ](systems/audio.md)、[UI](systems/ui.md)、[ワールドとナビゲーション](systems/world-and-navigation.md)、[レベル](systems/levels.md)。

## シーン内で行われる接続

ノード参照は`main.tscn`、`playable_hero.tscn`、`player.tscn`のエクスポートプロパティで設定します。`playable_hero.tscn`内のシグナル接続：

| シグナル | 接続先 | 効果 |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | クリックした地点にマーカーが表示される |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | 長押しがクリックに取って代わり、マーカーが消えていく |
| `Character/NavigationMover.arrived` | `ClickMarker.fade_out` | キャラクターが地点に到達した |
| `Character/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | 地点が放棄された |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | 押下がクリックか長押しか判明するまで、カメラは自動で回転しない |
| `PlayerInput.run_requested` | `CameraRig.end_follow_wait` | 新しい走行で、オービット後に待っていたカメラの追従を再開する |

`main.gd`はレベルホストと移動案内をコードで接続します。[レベル](systems/levels.md#ゲーム全体のシーン)を参照してください。

## 設定

`Settings`自動読み込み（Autoload、`GameSettings`）は値を保存し、`changed(key, value)`を発信します。エンジンレベルの設定（フルスクリーン、フレームレート上限、V-Sync、物理補間、UIスケール、言語、音量）は自身で適用します。それ以外はすべて`gdscript/demo/settings_applier.gd`が適用し、各キーをノードのプロパティに対応付けます。コンポーネント自身が設定を読むことはありません。[設定](settings.md)を参照してください。

## なぜこのような構成なのか

- **ボディを動かすのは`GroundCharacter`だけです**。移動コンポーネントは速度を返すだけで、`move_and_slide()`を呼びません。重力、ジャンプ、将来のノックバックは1か所でまとめて処理されるので、互いに競合することがありません。
- **`GroundMotion`はノードを使わない計算です**。加速と減速は状態の純粋関数なので、単独でテストしやすく、別の言語へ1行ずつ移植するのも簡単です。
- **キャラクターはマウスについて何も知りません**。操作するヒーローシーン（`playable_hero.tscn`）の`PlayerInput`がムーバーを動かすからプレイヤー用になるだけです。NPCにはプレイヤー専用の`Silhouette`と`Appearance`を外した`player.tscn`を使い、AIから`NavigationMover.move_to()`を呼びます。
- **ヒーローはレベル内ではなく、レベルホストの隣にいます。** レベルシーンには地面、小道具、ナビゲーション、光、ポータルだけを置きます。ヒーロー、カメラ、UIは切り替え中も残るため、新しいレベルにコピーする必要がなく、スタミナやカメラの高さも失われません。
- **レベルホストはヒーローを知りません。** 切り替えの各段階をシグナルで通知し、ゲーム全体のシーンが新しいレベルの指定地点へヒーローを置きます。ヒーローはレベルホストなしでも動きます。
- **カメラはキャラクターの子ではなく兄弟です**。`_process`でターゲットの補間位置へ移り、自身は補間されません。物理補間がオンなら（デフォルトでオン、設定 → 表示）、どのフレームレートでも滑らかです。追従モードでは物理ティックごとの移動から速度を計算するので任意の`Node3D`をターゲットにできます。同じ移動から急反転と緩やかなカーブを区別し、反転中には振り回されません。ばねは短いステップで計算するため、フレームレートが変わっても同様に動きます。
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

`shared/`は将来のC#版デモでも再利用する想定で、C#版は`gdscript/`の隣に専用フォルダを持ちます。現時点では2つ例外があります。レベルとパッドがコンポーネントのスクリプトを使うこと（`world.tscn`、`island.tscn`、`mountain.tscn`は`point_of_interest.gd`、各レベルは`spawn_point.gd`、`teleport_pad.tscn`は`level_portal.gd`）、そして小道具用の`flicker.gd`と`hover_spin.gd`が`shared/world/props/`にあることです。[既知の問題](known-issues.md)を参照してください。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
