<!-- translation of docs/en/systems/locomotion.md @ 5c06aa020dad -->
# ロコモーション

> これは[英語の原文](../../en/systems/locomotion.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

キャラクターが走り、止まり、向きを変え、ダッシュし、ジャンプし、階段を上り、段差から落ちないようにする仕組みと、自分が何をしているかを伝える仕組みです。下の層から順に4つのクラスがあります。

| クラス | 種類 | 役割 |
|---|---|---|
| `LocomotionSettings` | Resource | 速度、加速、減速、旋回 |
| `GroundMotion` | RefCounted | 計算：目標の方向と残り距離 → 水平方向の速度 |
| `NavigationMover` | Node、ボディの子 | 経路とコマンド。速度を返し、ボディは動かさない |
| `GroundCharacter` | CharacterBody3D | 重力、ジャンプ、ダッシュ、`move_and_slide()`、モデルの回転 |

ボディには2つの補助ノードを接続します：`Stamina`（ダッシュの蓄え）と`LedgeGuard`（段差から歩いて落ちないようにする）。`CharacterMonitor`は、ボディが通知する内容をテキストで表示します。

## 走りの感触

- **一定の加速と減速**。速度は`acceleration_time`と`stop_time`から決まる一定の割合で変わります。
- **正確な停止**。目標の近くでは、速度は`√(2 · braking · distance left)`に制限されます。キャラクターは、まだその地点で止まれるちょうどの位置で減速を始め、行き過ぎることはありません。
- **新しい目標でリセットしない**。減速中に新たにクリックしても現在の速度は保たれ、キャラクターはそこから再び加速します。
- **旋回速度の制限**。走行中、方向は`turn_speed`で回ります。方向が追いつくまでの間は`turn_slowdown`が速度を少し落とすので、急な方向転換は大きく流れるのではなく、小さな弧になります。
- **静止状態からの即時旋回**。`pivot_speed`未満ではキャラクターは即座に向きを変えるので、どの方向へ走り出しても弧も遅れもありません。
- **必要なときは強くブレーキをかける**。走っているキャラクターのすぐ前に停止地点が設定されると、通常の最大`max_braking_multiplier`倍の強さで減速することがあります。

## LocomotionSettings

デモは`gdscript/player/player_locomotion.tres`を使います。これはスクリプトのデフォルト値のうち2つを変更しています。

| プロパティ | デモ | スクリプトのデフォルト | 意味 |
|---|---|---|---|
| `max_speed` | 5.5 m/s | 5.5 m/s | 走る速さ |
| `acceleration_time` | 0.35秒 | 0.18秒 | 静止から`max_speed`まで |
| `stop_time` | 0.4秒 | 0.22秒 | `max_speed`から停止まで。制動距離は`max_speed × stop_time / 2`（デモでは1.1 m） |
| `turn_speed` | 720 °/s | 720 °/s | 走る方向が回る速さ |
| `turn_slowdown` | 0.75 | 0.75 | 方向が追いつくまでに失う速度：0なら速度を保つ（大きな弧）、1なら90°以上の旋回で0まで減速する |
| `pivot_speed` | 1 m/s | 1 m/s | これ未満ではキャラクターは即座に向きを変える |
| `max_braking_multiplier` | 3 | 3 | すぐ前の地点で止まるために、キャラクターが通常よりどれだけ強く減速できるか |
| `sprint_speed_multiplier` | 1.5 | 1.5 | ダッシュ中の速度上限（8.25 m/s）。加速と減速は変わらない |
| `backward_speed_multiplier` | 0.7 | 0.7 | 後ろ向きに移動するとき（移動方向と逆を向いているとき）に残る速度の割合 |

設定ウィンドウは実行時に`sprint_speed_multiplier`と`backward_speed_multiplier`を変更します。それ以外はリソースで調整します。ゲームの実行中に調整するには：シーンドック（Scene）→ リモート（Remote）→ `Player/NavigationMover` → `settings`。コードは毎ティックそれらを読みますが、そこで行った変更は保存されないので、結果を`.tres`ファイルにコピーしてください。

1つのリソースを複数のキャラクター、たとえば同じ種類のNPCすべてで共有できます。

## NavigationMover

ボディ（任意の`Node3D`、通常は`CharacterBody3D`）の子です。2つのモードがあります。

- `move_to(point)`：ナビゲーション経路に沿って障害物を迂回しながら地点へ進み、正確に止まります。経路はボディのワールドの`NavigationServer3D`から得ます。ナビゲーションマップがない場合、キャラクターは地点へまっすぐ走ります。
- `steer(direction, facing = Vector3.ZERO)`：`stop()`、`halt()`、`move_to()`のいずれかが来るまで、経路なしで指定の方向へ進みます。障害物は、ボディがそれに沿って滑ることで処理されます。`facing`を指定すると、キャラクターは移動中その方向を向きます（横移動と後退）。向きは停止後も、向きを指定しないコマンドが来るまで保たれます。

ボディは物理ティックごとに1回、`move_and_slide()`の前に`compute_velocity(delta)`を呼びます。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `settings` | — | `LocomotionSettings`。空ならデフォルト値 |
| `use_navigation` | オン | 経路を探索する。オフ、またはワールドにナビゲーションがない場合：地点へまっすぐ走る |
| `navigation_layers` | 1 | 経路が使えるナビゲーションレイヤー |
| `waypoint_radius` | 0.4 m | これより近づくと経路の点を通過したとみなす。大きくすると早めに角を曲がる |
| `arrive_distance` | 0.005 m | 終点にこれより近づくと、キャラクターは即座に止まる。減速自体で地点まで届くので、しきい値はごく小さい |
| `retarget_tolerance` | 0.1 m | 現在の地点からこれより近い新しい地点では、経路を再構築しない。ボタンを押し続けると毎ティック地点が送られる |
| `max_path_deviation` | 2 m | これより経路から押し出されると、キャラクターは新しい経路を得る |
| `sprinting` | オフ | 速度上限を`sprint_speed_multiplier`倍に上げる。いつ上げるかは所有者が決める |

シグナル：`destination_changed(point)`、`path_changed`、`arrived`、`destination_cancelled`。

**経路の点は水平面で比較します**。Recastのナビゲーションメッシュは、地面からセルの高さ約2つ分（ここでは0.05 m）浮いています。キャラクターの足元との3D距離で比較すると、その分だけずれてしまいます。そのため、ムーバーは`NavigationAgent3D`を使わずに自分で経路をたどります。

**後退は遅くなります**。`steer()`に`facing`が渡されると、移動方向が向きとどれだけ逆向きかに応じて速度が縮められます。真後ろなら`backward_speed_multiplier`が完全に適用され、斜め後ろならその一部（横移動中のS + D：21%遅い）、真横なら適用されません。そのため、減速はキーの横移動モードにしか存在しません。[入力](input.md)を参照してください。

## GroundCharacter

ボディが動く唯一の場所です。各物理ティックで、ダッシュの状態を更新し、ムーバーから水平方向の速度を受け取り、ジャンプと重力を処理し、`LedgeGuard`に速度を補正させ、`move_and_slide()`を呼びます（呼ぶ前に段を上り、呼んだ後に段を下ります）。続いて、そのティックで変わったことを通知します：床との接触、ステップ、`mover.get_facing()`の方へのモデルの回転、状態。

インスペクター（Inspector）ではプロパティがグループに分かれています：最初にパーツと回転、続いてGround、Jump and fall、Sprint、Steps。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `mover` | — | `NavigationMover`。必須 |
| `visual` | — | キャラクターの進む方向へ向けるノード。前方は−Z |
| `visual_turn_speed` | 1080 °/s | モデルが回る速さ |
| `max_step_height` | 0.3 m | キャラクターがジャンプせずに上れる最も高い段であり、地面を離れずに下りられる最も深い段。0にすると段の昇降を無効にする |
| `ledge_guard` | — | 任意の`LedgeGuard`。ないとキャラクターはどんな高さからでも落ちる |
| `can_jump` | オン | ジャンプを許可する。オフだと`jump()`は何もしない |
| `jump_height` | 1 m | ジャンプの頂点での足の高さ |
| `coyote_time` | 0.1秒 | 縁から歩いて落ちた後、この時間はまだジャンプが有効 |
| `jump_buffer_time` | 0.12秒 | 着地のこの時間前までに押したジャンプは、着地時に発動する |
| `gravity_scale` | 3 | 重力の倍率。キャラクターは人より速く走るので、通常の重力ではふわふわ落ちてしまう：1.6 mの落下が0.57秒ではなく0.33秒になる |
| `landing_min_speed` | 2.5 m/s | これより遅い落下（小さな段差、スロープ）は`touched_floor`だけで、`landed`にはならない |
| `can_sprint` | オン | ダッシュを許可する。走行中にオフにすると、余分な速度は減速して消える |
| `stamina` | — | 任意の`Stamina`。ないとダッシュしても疲れない |
| `sprint_tires` | オン | ダッシュでスタミナを消費する |
| `sprint_duration` | 5秒 | 満タンの蓄えが持つ時間：毎秒`max_value / sprint_duration`を消費する |
| `stride_length` | 1.5 m | ステップ間の地上の距離 |
| `first_step_distance` | 0.3 m | 静止から最初のステップまでの距離 |

斜面の上限はボディ自身の`floor_max_angle`です（インスペクターのFloor → Max Angle、デフォルトは45°）。それより急な面は、ボディにとっても、段の昇降にとっても、落下防止にとっても同じく壁です。

ダッシュを要求するには`sprint_requested`を設定し、ジャンプするには`jump()`を呼びます。プレイヤーの場合は`CharacterActionInput`がその両方を行います。AIも同じことができます。

### キャラクターが通知すること

アニメーション、エフェクト、サウンド、インターフェースは、キャラクターが何をしているかを速度から推測する必要はありません。瞬間的な出来事はシグナルとして届き、絶えず変化するものは毎フレームまたは毎ティック、問い合わせで読み取ります。

| シグナル | タイミング |
|---|---|
| `state_changed(state, previous)` | 状態が変わった。ティックの終わりに、そのティックのほかのシグナルの後で発生する |
| `stepped(sprinting)` | 足が地面に着いた（どちらの足かは`get_step_foot()`でわかる）：地上を`stride_length`進むごとに発生し、最初の1回は静止から`first_step_distance`の位置。ステップは時間ではなく距離に従う：走行中は毎秒約3.7回、ダッシュ中は5.5回、壁に向かって立っているときや空中では0回 |
| `jumped` | キャラクターが地面を蹴った。同じティックで`left_floor`が続く |
| `left_floor` | キャラクターが地面を離れた：ジャンプによって、または縁から。段を下りるステップは含まない |
| `touched_floor(fall_speed)` | 空中にいた時間の長さにかかわらず、地面に戻った。`left_floor`1回につき1回 |
| `landed(impact_speed)` | `landing_min_speed`以上の速さでの`touched_floor`：小さな段差ではない本当の着地 |
| `sprint_changed(sprinting)` | ダッシュが開始または停止した |

| 状態（`GroundCharacter.State`） | タイミング |
|---|---|
| `IDLE` | 地上で、`IDLE_SPEED`（0.1 m/s）より遅い。壁に向かって走っているときも含む |
| `RUNNING` | 地上で、速さにかかわらず移動中、ダッシュはしていない |
| `SPRINTING` | 地上で、ダッシュ中 |
| `JUMPING` | ジャンプ後の空中、頂点まで |
| `FALLING` | 下降中の空中：ジャンプの頂点を過ぎた後、または縁から落ちたとき |

| 問い合わせ | 戻り値 |
|---|---|
| `get_state()` | 状態 |
| `get_move_velocity()`、`get_move_speed()` | 実際の水平方向の速度とその大きさ（m/s）：ボディが本当に進む量。`get_real_velocity()`と違い、段を上る分も数える |
| `get_locomotion_blend()` | 1Dブレンド用：静止で0、`max_speed`で1、ダッシュの最高速度で2。速度をどう調整しても変わらない |
| `get_local_movement()` | 2Dブレンド用：xはモデルの右、yは前方、長さはブレンド値。走行は(0, 1)、ダッシュは(0, 2)、右への横移動は(1, 0)、後退は(0, −0.7) |
| `get_turn_rate()` | モデルが回る速さ（rad/s）：正なら左、負なら右 |
| `get_air_time()` | 空中にいる秒数。地上では0 |
| `get_step_phase()` | 踏んだ歩数を表す数値：ステップのたびに整数になり、ステップ間の距離に応じて小数部が増える |
| `get_gait_cycle()` | 2歩分のサイクル（0から1）：左足が地面に着くと0、右足で0.5 |
| `get_step_foot()` | 最後のステップの足、`Foot.LEFT`または`Foot.RIGHT`。足は停止をはさんでも交互になる |
| `is_sprinting()`、`is_exhausted()`、`get_jump_speed()` | 今ダッシュしているか、疲労困憊か、ジャンプの踏み切り速度 |
| `is_on_floor()`、`get_floor_angle()`、`velocity.y` | `CharacterBody3D`自体から：地上にいるか、足元の傾斜、垂直方向の速度 |

`HandSway`はステップの位相に従っており、アニメーションも同じようにできます。`AnimationTree`を駆動する通常の方法は、毎フレーム問い合わせからブレンドを設定し、シグナルでステートマシンを切り替えることです。

```gdscript
@export var character: GroundCharacter
@export var tree: AnimationTree


func _ready() -> void:
	character.state_changed.connect(_on_state_changed)
	character.landed.connect(func(_speed: float) -> void:
		tree.set("parameters/land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE))


func _process(_delta: float) -> void:
	# A BlendSpace1D with idle at 0, run at 1 and sprint at 2; for sidesteps, a BlendSpace2D and get_local_movement().
	tree.set("parameters/ground/blend_position", character.get_locomotion_blend())


func _on_state_changed(state: GroundCharacter.State, _previous: GroundCharacter.State) -> void:
	var in_air := state == GroundCharacter.State.JUMPING or state == GroundCharacter.State.FALLING
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	playback.travel("air" if in_air else "ground")
```

足の動きを地面と合わせるには、走行サイクルを時間ではなく距離で再生します：サイクルの位置を、`get_gait_cycle()`にその長さを掛けた値に設定します（`TimeSeek`ノード、または一時停止した`AnimationPlayer`と`seek()`）。サイクルは、左足が地面に着くところから始まるようにしてください。

### CharacterMonitor：状態をテキストで

`GroundCharacter`が何をしているかと、その最新のイベントを表示する`Label`です。アニメーションの調整やデバッグ用のオーバーレイに使います。デモでは`Hud/CharacterState/Monitor`で、設定（F10）→ インターフェース → **キャラクターの状態とイベント**で表示されます。テキストは上記のシグナルと問い合わせだけから作られるので、このスクリプトはそれらの使用例にもなっています。

```
Running
Speed 5.5 m/s · blend 1.00
Forward +1.00 · right +0.00
Turning +0°/s
On the ground · slope 0°
Step 37 · left foot · cycle 0.03
Stamina 100%

12.35 s  step, right foot
12.62 s  step, left foot
12.80 s  jump
12.80 s  left the ground
12.80 s  Running → Jumping
```

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `character` | — | `GroundCharacter`。空なら親 |
| `history_size` | 6 | 状態の下に表示する最新のイベントの数。0なら状態だけを表示する |
| `log_events` | オフ | すべてのイベントを、その時刻とキャラクターの名前とともに出力にも書き出す |
| `include_steps` | オン | ステップも表示し、ログに書き出す：ステップは毎秒数回ある |

メソッド：`get_text_now()`、`get_state_lines()`、`get_event_lines()`、`get_state_name(state, translated)`。文言は`tr()`を通るので、パネルはインターフェースの言語で表示されます。出力のログは英語のままです。

### 階段と斜面

**斜面**は`move_and_slide()`自体の仕事です：ボディは`floor_max_angle`より急でない面を歩いて上り、それより急な面では止まります。デモのボディでオンになっている`floor_constant_speed`があれば、スロープ上でも速度を保ちます。

**階段**。カプセルが物理だけで乗り越えられる段差は`radius × (1 − cos floor_max_angle)`まで、0.35 mのカプセルでは0.1 mです。それより高い`max_step_height`までの段は、ボディが自分で上ります：

- **上り**。そのティックの移動を5 cm先まで延ばして調べ、立てないほど急なものにぶつかる場合、ボディは段を試します：`max_step_height`だけ上へ（天井があればそこまで）、そのティックの移動分だけ前へ、そして地面まで下へ。レイが上面を調べます：足から`max_step_height`以内の高さにある地面でなければならないので、0.4 mのブロックや急な斜面は段になりません。ボディは段の上に置かれ、`move_and_slide()`はそこに落ち着かせるだけです。
- **下り**。ティックの前にボディが地上に立っていて、ティックの後にジャンプなしで空中にあり、その下`max_step_height`以内の深さに地面がある場合、ボディはその地面の上に置かれます：`left_floor`も落下も起きません。
- カプセルの丸い底は段の縁に斜めに触れ、ボディが縁から遠いうちは、その角度が急すぎて立てません。そのため、段の上の位置は2 cm刻みで少し先まで探します：ボディは、そのティックで移動するはずの位置より最大数センチ先に置かれます。

段ごとに約1ティック、カプセルが縁を転がるように越える時間がかかり、その間は水平方向の速度が約70%に落ちます（`get_move_speed()`には表れますが、手の杖はほとんど動きません）。長い階段には、見えないスロープのコライダーが最も滑らかです。

ナビゲーションメッシュは、ボディが上れるものをつながなければなりません：デモでは`agent_max_climb`は0.3 mで、`max_step_height`と同じです（[ワールドとナビゲーション](world-and-navigation.md#物理レイヤーとナビゲーション)を参照）。

### ジャンプ

踏み切りの速度は`v = √(2·g·h)`です。踏み切りのティックでは、ボディに`v − g·dt/2`を与えます。こうすると各ティックでの位置が正確に放物線上に乗り、ジャンプの高さがティックレートに依存しなくなります。単に`v`を与えると、ジャンプは`v·dt/2`だけ高くなり、60ティックでは1 mではなく1.064 mになります。デモでは`gravity_scale` 3で、1 mのジャンプに0.52秒かかります。

空中でもキャラクターはそれまでどおり走り続け、操作も変わりません。落下防止はジャンプを止めません。プラットフォームの縁から跳ぶのは意図的な行動であり、事故ではないからです。

## ダッシュとスタミナ

ダッシュが要求されていて、キャラクターが操作されている間（クリック、ボタン長押し、両ボタン、キー）、キャラクターは`sprint_speed_multiplier`倍速く走り、スタミナを消費します。Shiftを押したまま立ち止まっていても何も消費しません。蓄えが尽きるとキャラクターは疲労困憊の状態になり、スタミナが`recover_ratio`まで回復するまで通常の速さで走り、Shiftを押したままなら自動的に再びダッシュします。

`Stamina`は、何がそれを消費するかを知りません。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `max_value` | 100 | 満タンの蓄え |
| `recovery_rate` | 毎秒12.5 | 空から満タンまで8秒 |
| `recovery_delay` | 1秒 | 最後に消費してからこの時間後に回復が始まる |
| `recover_ratio` | 0.3 | 疲労困憊のキャラクターは、この割合まで回復すると再びダッシュする（1 + 2.4秒） |

メソッド：`spend(amount)`、`can_spend()`、`get_ratio()`、`is_exhausted()`、`refill()`。シグナル：`changed(ratio)`、`exhausted_changed(exhausted)`。HUDの`StaminaBar`がこれらを受け取ります。

## LedgeGuard

キャラクターが段差から歩いて落ちるのを防ぎます。ボディは`move_and_slide()`の前に`constrain(velocity, delta)`を呼びます。ティックの終わりにボディが段差の上に出てしまう場合、移動は縁に沿って、下に地面がある最も近い方向へ向きを変えられ、その角度のコサインの分だけ短くなります。壁に沿って滑るのとまったく同じです。縁に向かってまっすぐ走ると、キャラクターは止まります。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `enabled` | オン | 縁を守る |
| `max_drop` | 0.5 m | これより低い段差はステップとして歩いて下りられる。これより高いものは崖 |
| `edge_margin` | 0.15 m | キャラクターの中心が縁にどこまで近づけるか |
| `margin_probes` | 6 | `edge_margin`の円周上のレイの数 |
| `probe_height` | 0.5 m | レイは足からこの高さで開始し、足より少し上にある地面（スロープ）も見つける |
| `floor_mask` | レイヤー1 | 地面とみなすもの |
| `slide_iterations` | 6 | 滑る角度を半分にする回数。6で約1.4° |

開けた地面ではティックあたり7本のレイ、縁では最大98本です。空中では落下防止は何もしません。プラットフォームから下りる経路はスロープを通るので、落下防止がその邪魔をすることはありません。

## 測定された挙動

テスト（`tests/movement_checks.gd`、`tests/character_actions_checks.gd`、`tests/character_state_checks.gd`、`tests/camera_checks.gd`）は、毎秒60物理ティックでデモの設定を測定します。判定の上限・下限は設定から計算されるので、設定を変更してもかまいません。

- 0.33秒で最高速度の95%に達し、95%から0.35秒で停止します。停止位置はクリックした地点ちょうどです。
- 減速中にさらに遠くを新たにクリック：速度は2.66 m/sからすぐに再び上がり、0まで落ちることはありません。
- 全速で走るキャラクターの後ろをクリック：0.34 m進み続け、弧は横に0.63 m膨らみ、0.28秒後に戻る方向へ走ります。
- プラットフォームの縁へまっすぐ：縁から0.15 mの位置で速度0で停止します。45°で：同じ高さのまま、縁に沿って3.89 m/s（5.5 × cos 45°、壁に沿うのと同じ）でプラットフォームの角まで滑ります。落下防止なし：1.6 mを0.35秒で落下します。
- ダッシュ：8.25 m/s。`sprint_duration`を2秒にすると（毎秒50を消費）2.02秒でスタミナが尽き、その後は5.5 m/sになります。3.38秒後にキャラクターは回復し（1 + 2.4秒）、Shiftを押したまま再び8.25 m/sでダッシュします。
- ジャンプ：頂点は1.000 m、滞空時間は0.517秒（式では0.522秒）。地面から0.4 mの高さで押すと、着地の次のティックでジャンプが発動します。頂点で押すと忘れられます。縁から歩いて落ちて3ティック後にスペースを押すとジャンプし、9ティック後ではジャンプしません。
- キャラクターが通知すること：全速の走行でブレンドは1.00、全速のダッシュで2.00。横移動は(1.00, 0.00)、後退は(0.00, −0.70)。走行中の状態：`RUNNING`、`SPRINTING`、`RUNNING`、`IDLE`。ジャンプ：`jumped`、`left_floor`、0.27秒間の`JUMPING`（式では頂点まで0.26秒）、`FALLING`、`touched_floor`、`landed`、`IDLE`。滞空時間は0.52秒。プラットフォームの縁から：`left_floor`の後、すぐに`FALLING`。足は停止の後も交互になります。
- プラットフォームの東の階段（高さ0.2 mの段、踏み面0.4 m）をクリックで：地面を離れずに上り下りし、速度の中央値は上りで5.4 m/s、下りで5.5 m/s、最低はそれぞれ3.9 m/sと5.0 m/sです。`max_step_height`が0だと、キャラクターは最初の段で止まります。0.4 mのブロックでは止まり、30°の斜面は歩いて上れますが、50°の斜面は上れません。
- 山道、スロープ、草地、迷路では、キャラクターはジャンプなしで地面を離れることはありません。

---

*このページは Iso & Orbit 1.1.0 に対応しています。*
