<!-- translation of docs/en/systems/locomotion.md @ 78c912e8971a -->
# ロコモーション

[← ドキュメント目次](../index.md)

> これは[英語の原文](../../en/systems/locomotion.md)の翻訳です。内容が異なる場合は、英語版を参照してください。

キャラクターが走る、止まる、向きを変える、ダッシュする、ジャンプする、階段を上る、崖から落ちないようにする仕組みを説明します。完成済みヒーローと再利用に必要なファイルについては、[自分のプロジェクトで使う](../integration.md#デモのヒーローを自分のプロジェクトへ移植する)から始めてください。完成済みの操作方式を選ぶには[構成](../configurations.md)を参照します。作業は4つのクラスに分かれます。

| クラス | 種類 | 役割 |
|---|---|---|
| `LocomotionSettings` | Resource | 速度、加速、減速、旋回 |
| `GroundMotion` | RefCounted | 計算：目標方向と残り距離 → 水平方向の速度 |
| `NavigationMover` | Node、ボディの子 | 経路と命令。速度を返すが、ボディ自体は動かさない |
| `GroundCharacter` | CharacterBody3D | 重力、ジャンプ、ダッシュ、`move_and_slide()`、モデルの回転 |

ボディには2つの補助ノードを接続できます。`Stamina`はダッシュ用の蓄え、`LedgeGuard`は崖から歩いて落ちるのを防ぎます。`FallSettings`リソースは落下の仕方を指定します。`CharacterMonitor`はボディが報告する状態を文字で表示します。`CharacterHover`はモデルを地面から浮かせます。[キャラクター](characters.md#characterhoverで地面から浮かせる)を参照してください。

## 走りの感触

- **一定の加速と減速。** 速度は`acceleration_time`と`stop_time`から決まる一定の割合で変わります。
- **正確な停止。** 目標の近くでは速度を`√(2 · braking · distance left)`に制限します。キャラクターは目標地点で止まれる位置から減速し、行き過ぎません。
- **新しい目標では速度をリセットしない。** 減速中に新しくクリックしても現在の速度を保ち、そこから再加速します。
- **旋回速度の制限。** 走行方向は`turn_speed`で回ります。向きが追いつくまでは`turn_slowdown`が速度を少し落とし、急旋回でも大きく流れず小さな弧を描きます。
- **静止状態からの即時旋回。** `pivot_speed`未満では即座に向きを変えます。どの方向へ走り出しても弧や遅れがありません。
- **必要なら強く減速する。** 走行中のキャラクターのすぐ前に停止地点を置くと、通常の最大`max_braking_multiplier`倍の強さで減速することがあります。

## LocomotionSettings

次の値は`LocomotionSettings`スクリプトのデフォルトであり、付属の`gdscript/player/player_locomotion.tres`の値でもあります。独立したリソースにしているため、デモの設定からこのヒーローのダッシュ速度と後退速度を変えても、ほかのキャラクターには影響しません。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `max_speed` | 5.5 m/s | 走行速度 |
| `acceleration_time` | 0.18 s | 静止から`max_speed`に達する時間 |
| `stop_time` | 0.22 s | `max_speed`から止まる時間。制動距離は`max_speed × stop_time / 2`（約0.61 m） |
| `turn_speed` | 720 °/s | 走行方向が回る速さ。カメラの`sharp_turn_speed`はその半分以下に保つ（[カメラ](camera.md#追従モード)を参照） |
| `turn_slowdown` | 0.75 | 方向が追いつくまでに失う速度。0なら速度を保ち大きく弧を描く。1なら90°以上の旋回で速度を0まで落とす |
| `pivot_speed` | 1 m/s | この速度未満では即座に向きを変える |
| `max_braking_multiplier` | 3 | すぐ前の地点で止まるため、通常より何倍強く減速できるか |
| `sprint_speed_multiplier` | 1.5 | ダッシュ中の通常速度に対する倍率（デフォルトで8.25 m/s）。加速と減速は変わらない |
| `backward_speed_multiplier` | 0.7 | 移動方向と逆を向いて後退するときに残る速度の割合 |

ダッシュでは速度上限だけが上がるため、全速から止まるまでの時間と距離が長くなります。デフォルトの減速率では、8.25 m/sから約1.36 m、通常の5.5 m/sから約0.61 mです。すぐ前をクリックすると`max_braking_multiplier`によってより早く止まる場合があります。

デモの`SettingsApplier`は起動時と設定変更時に`sprint_speed_multiplier`と`backward_speed_multiplier`を書き換えます。保存済み設定は上記の値を上書きできます。アドオン自体に設定システムはありません。実行中のデモを調整するには、Sceneドック → Remote → `Hero/Character/NavigationMover` → `settings`を開きます。コードは毎ティックリソースのフィールドを読みますが、Remoteインスペクターの変更は保存されません。結果を`.tres`ファイルへコピーします。実行時の変更をほかのキャラクターに及ぼしたくないなら、キャラクターごとに別のリソースを使います。ムーバーがシーンツリーに入る前に割り当てるか、エディターで**Make Unique**を使ってください。`_ready()`の後では`GroundMotion`が元のリソースを保持しており、`mover.settings`を交換しても計算に使う設定は交換されません。実行中は既存リソースのフィールドを編集します。

同じ種類のNPC全員など、複数のキャラクターで1つのリソースを共有することもできます。

## NavigationMover

ボディ（任意の`Node3D`、通常は`CharacterBody3D`）の子で、2つのモードがあります。

- `move_to(point)`：ナビゲーション経路で障害物を迂回して進み、経路の終端で正確に止まります。経路はボディのワールドの`NavigationServer3D`から得ます。ナビゲーションメッシュがないワールドを含め、経路が空なら要求した地点へまっすぐ走ります。
- `steer(direction, facing = Vector3.ZERO)`：`stop()`、`halt()`、`move_to()`が来るまで、経路を使わず指定方向へ進みます。障害物はボディが沿って滑ることで処理します。`facing`を指定すると移動中もその方向を向き、横移動や後退ができます。この向きは`stop()`の後も残り、`move_to()`、向きの指定がない`steer()`、`halt()`、`face()`で解除されます。

ボディは各物理ティックで`move_and_slide()`より前に`compute_velocity(delta)`を1回呼びます。`stop()`は滑らかに減速し、`halt()`はテレポート時などに即座に止めます。`face(direction)`はスポーン地点などで停止中のキャラクターを走らせずに向けます。ムーバーの進行方向と向きは即座に変わり、`GroundCharacter`のモデルは`visual_turn_speed`で追います。モデルも即座に向けるのは`GroundCharacter.teleport(position, facing)`だけです。走行中に呼ぶと、再び進行方向を向きます。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `settings` | — | `LocomotionSettings`。空ならムーバーが`_ready()`でスクリプトのデフォルト値を持つものを作る |
| `use_navigation` | オン | 経路を探す。オフ、またはワールドにナビゲーションがなければ地点へ直進 |
| `navigation_layers` | 1 | 経路が使えるナビゲーションレイヤー |
| `waypoint_radius` | 0.4 m | 経路上の点にこれより近づけば通過とみなす。大きいほど早く角を切る |
| `arrive_distance` | 0.005 m | 終端にこれより近づくと即座に止まる。減速そのものが地点へ運ぶため、閾値は小さい |
| `retarget_tolerance` | 0.1 m | 現在の目標からこれより近い新しい地点では経路を再構築しない。ボタンの長押しは毎ティック地点を送る |
| `max_path_deviation` | 2 m | 経路からこれより遠くへ押し出されたら新しい経路を得る |
| `sprinting` | オフ | 速度上限を`sprint_speed_multiplier`倍にする。使う時期は所有者が決める。`GroundCharacter`があると毎ティック値を設定するため、代わりにその`sprint_requested`を設定する |

シグナル：`destination_changed(point)`、`path_changed`、`arrived`、`destination_cancelled`。

`arrived`は経路の終端に達したことを意味します。ナビゲーション経路が要求地点ではなく最も近い到達可能地点で終わることもあるため、正確な要求地点が必要なゲームでは位置を比較します。直進への切り替えでは、ボディが障害物に沿って滑る以上の回避はありません。

| 問い合わせ | 戻り値 |
|---|---|
| `is_moving()` | 地点または方向へ移動を指示されているか。実際の動きではなく命令を表すため、開始位置でまだ立っていてもtrue、`stop()`後に減速中でもfalseになる |
| `is_steering()` | 地点ではなく`steer()`で指定した方向へ走っているか |
| `has_destination()`、`get_destination()` | `move_to()`で指定した地点へ向かっているか（到着または取消しまで）、およびその地点 |
| `get_speed()` | 走行速度（m/s） |
| `get_heading()` | 走る方向の水平単位ベクトル。立っているときは最後に走った方向 |
| `get_facing()` | キャラクターが向くべき方向。進行方向（`get_heading()`）または`steer()`が指定した向き |
| `get_body()` | 操作するボディ、つまり親ノード |
| `get_remaining_path()` | 次の点から始まる残りの経路点。ナビゲーションメッシュの高さにあり、直進中は空 |

**経路点は水平面で比較します。** Recastのナビゲーションメッシュは地面からセル高約2つ分（ここでは0.05 m）浮いています。キャラクターの足との3D距離を使うと、その分ずれます。これがムーバーが`NavigationAgent3D`ではなく自分で経路をたどる理由です。

**後退は遅くなります。** `steer()`に`facing`を渡すと、移動が向きとどれほど逆かに応じて速度を縮めます。真後ろは`backward_speed_multiplier`を完全に適用し、斜め後ろは一部だけ適用します（横移動中のS＋Dは21%遅い）。真横は減速しません。したがって減速するのはキーの横移動モードだけです。[入力](input.md)を参照してください。

## GroundCharacter

ボディを動かす唯一の場所です。各物理ティックでダッシュ状態を更新し、ムーバーから水平速度を受け、ジャンプと重力を処理し、`LedgeGuard`に速度を補正させます。その後、前に上り階段、後に下り階段の処理を挟んで`move_and_slide()`を呼びます。最後に床との接触、通った階段、足音用の歩数、`mover.get_facing()`へ向かうモデルの回転、状態の変化を報告します。

インスペクターのプロパティは、最初に構成部品と旋回、その後にGround、Jump and fall、Sprint、Stepsのグループに分かれます。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `mover` | — | 必須の`NavigationMover` |
| `visual` | — | ボディを基準に、進行方向へ回すノード。正面は−Z |
| `visual_turn_speed` | 1080 °/s | モデルの旋回速度 |
| `max_step_height` | 0.3 m | ジャンプせず上れる最大の段差高と、地面を離れず下りられる最大の段差高。0なら階段処理を無効にする |
| `ledge_guard` | — | 任意の`LedgeGuard`。なければどんな高さからも落ちる |
| `can_jump` | オン | ジャンプの許可。オフなら`jump()`は何もしない |
| `jump_height` | 1 m | ジャンプの頂点での足の高さ |
| `coyote_time` | 0.1 s | 縁から歩いて落ちた後もジャンプできる時間 |
| `jump_buffer_time` | 0.12 s | 着地前のこの時間内に押したジャンプを着地時に発動する |
| `gravity_scale` | 3 | ジャンプ上昇時の重力倍率。`fall`に別の値がなければ下降時も同じ。キャラクターは人より速く走るため、通常の重力ではゆっくり落ちすぎる。1.6 mの落下は0.57秒ではなく0.33秒になる |
| `fall` | — | 落下の加速と最高速度を決める`FallSettings`。[落下](#落下)を参照。空なら`gravity_scale`を使い、速度上限はない |
| `landing_min_speed` | 2.5 m/s | これより遅い落下（小さな段差やスロープ）は`touched_floor`だけで`landed`にならない |
| `can_sprint` | オン | ダッシュの許可。走行中にオフにすると追加速度は減速して消える |
| `stamina` | — | 任意の`Stamina`。なければダッシュで疲れない |
| `sprint_tires` | オン | ダッシュ中にスタミナを消費する |
| `sprint_duration` | 5 s | 満タンの蓄えが続く時間。毎秒`max_value / sprint_duration`を消費する |
| `steps_enabled` | オン | 歩数を数え、`stepped`と歩行周期を出す。脚のないキャラクターならオフ。再びオンにすると`first_step_distance`後に最初の一歩が来る |
| `stride_length` | 1.5 m | 地面を歩いたときの歩幅 |
| `first_step_distance` | 0.3 m | 静止から最初の一歩までの距離 |

斜面の上限はボディ自身の`floor_max_angle`です（インスペクターのFloor → Max Angle、デフォルト45°）。それより急な面はボディ、階段処理、崖ガードにとって壁です。上方向は+Yなので、`up_direction`は`Vector3.UP`のままにします。

ボディの大きさやレベルの階段を変更するときは、これらを一緒に調整します。`max_step_height`は通したい階段高以上に、`LedgeGuard.max_drop`は`max_step_height`以上に、ナビゲーションメッシュの`agent_max_climb`は実際に越えたい段差高にします。メッシュ設定を変更したら再ベイクします。メッシュは経路を考えるだけで、カプセル、床の傾斜、天井の空間、衝突形状が実際に通れるかを決めます。下り段差で`stair_taken`を受けたいなら`floor_snap_length`を`max_step_height`より短くします。デモは高さ1.8 m、半径0.35 mのカプセル、0.3 mの段差、0.5 mの落下防止、最大登坂高0.3 m・セル高0.025 mのナビゲーションメッシュを使います。[ワールドとナビゲーション](world-and-navigation.md#物理レイヤーとナビゲーション)を参照してください。

NPCをエディターで回転させたり、`PlayableHero`のルートを回したりして、ボディがレベル内で別の向きを向くこともあります。キャラクターはボディを基準に`visual`だけを回し、最初はボディの−Z方向を向きます。ムーバーもそこから開始方向を得ます。後から`teleport(position, facing)`または`NavigationMover.face()`で向きを設定できます。

コンポーネントは`steps_enabled`に触れず、一時的に歩数を止められます。`set_steps_suppressed(self, true)`で止め、`false`で戻します（`CharacterHover`は浮遊中にこれを使います）。歩数が数えられるのは`steps_enabled`がオンで、どのコンポーネントも止めていないとき（`is_counting_steps()`）です。これならゲームのスイッチと複数のコンポーネントが互いの設定を打ち消しません。キャラクターはコンポーネントを生存させず、解放されたものは次のティックまでに自動的に抑制を解除します。落下設定も同じ仕組みです。[落下](#落下)を参照してください。

設定に誤りがあるとキャラクターがツリーに入る際に警告し、`get_setup_warnings()`でも同じ一覧を返します。ムーバーまたは崖ガードがボディの子でない場合、`LedgeGuard.max_drop`が`max_step_height`より低く下れるはずの階段で止まる場合、床へのスナップ長が階段と同じで自動的に下りて`stair_taken`が出ない場合、`can_jump`はオンでも`jump_height`または`gravity_scale`が0で地面を離れない場合（このジャンプは`jumped`も出さず何もしません）、`fall.max_speed`が`landing_min_speed`未満で着地イベントが出ない場合、`up_direction`が+Yでない場合です。`LedgeGuard`と`CharacterHover`も同様に自身の設定を検査します。

ダッシュを要求するには`sprint_requested`を設定し、ジャンプするには`jump()`を呼びます。プレイヤーでは`CharacterActionInput`が両方を行い、AIも同じ方法を使えます。

`teleport(position, facing)`はスポーン地点や別のレベルへキャラクターを即座に移します。ムーバーを完全に止め（`NavigationMover.halt()`）、追従するものが急に跳ねないようにします。速度、加速度、旋回速度は0になり、物理ティック間の平滑化は新しい場所から始まります。浮遊モデルもそこへ瞬時に移り、以前押したジャンプは忘れます。`facing`があればキャラクターとモデルも即座に向きます。スタミナは維持され、接地状態も以前のままなので、足を地面に置いてください。最後に`teleported`シグナルが出ます。カメラや軌跡など追従するものは、このシグナルで新しい場所へ瞬時に移ります。検査では、5.5 m/sで走行中にテレポートすると、同じフレームで新しい場所に静止し、その後も加速と旋回はありません。

テレポートはプレイヤー入力やカメラを変更しません。プレイヤーのヒーローでは`PlayableHero.teleport()`または`place_at()`を使います（[レベル](levels.md#操作するヒーロー)を参照）。これらは押下中の入力も忘れ、必要ならカメラを回して位置を瞬時に合わせます。`GroundCharacter.teleport()`だけを使うなら、先に`PointClickMoveInput.cancel()`を呼びます。マウスボタンが押されたままだと次のティックで再び動き出すためです。また`teleported`を`OrbitCameraRig.snap()`へ接続します。

時間が止まっている（`Engine.time_scale`が0）間も、物理ティックは長さ0で進みます。キャラクターの位置、速度（`get_move_velocity()`）、状態、歩行周期はそのままで、加速度と旋回速度は0になります。浮遊モデルと揺れる手も止まります。時間が再び進めば、同じ歩調から走りを再開します。検査では、徒歩または浮遊中の5.5 m/sのヒーローが誤差なくそのまま留まり、その後走り続けます。その間の入力はキャラクターへ届き、ダッシュキーは走行中のダッシュ状態を切り替え（`sprint_changed`）、地面で押したジャンプは直ちに発動します（`jumped`）。何も変えたくなければ、その間は`PlayableHero.controls_enabled`で操作を無効にします。

### キャラクターが報告すること

アニメーション、エフェクト、サウンド、インターフェースが、キャラクターの行動を速度から推測する必要はありません。瞬間的な出来事はシグナルで受け取り、常に変化するものは毎フレームまたは毎ティック、問い合わせで読みます。

| シグナル | 発信されるとき |
|---|---|
| `state_changed(state, previous)` | 状態が変わったとき。ティックの終わり、ほかのシグナルの後 |
| `stepped(sprinting)` | 足が地面に着いたとき。足は`get_step_foot()`でわかる。地面を`stride_length`進むごとに発信され、静止から最初の一歩は`first_step_distance`後。歩数は時間でなく距離に従い、走行中は毎秒約3.7歩、ダッシュ中は5.5歩、壁に向かって静止中や空中では0歩 |
| `jumped` | 地面を蹴ったとき。同じティックで`left_floor`が続く |
| `left_floor` | ジャンプまたは縁から地面を離れたとき。階段を1段下りる場合は含まない |
| `touched_floor(fall_speed)` | 空中にいた後で地面へ戻ったとき。`left_floor`ごとに1回。`fall_speed`は接地時の速度 |
| `landed(impact_speed)` | `landing_min_speed`以上の速度での`touched_floor`。小さな段差ではなく本当の着地 |
| `sprint_changed(sprinting)` | ダッシュが始まるか止まるとき |
| `stair_taken(height)` | 階段を上り下りしたとき。以前立っていた地面から新しい地面までの実高で、上りは正、下りは負（デモでは±0.2 m）。ティック末尾の`state_changed`より前に発信される。カプセルが自力で越えられる高さ（`radius × (1 − cos floor_max_angle)`まで。デモのカプセルでは0.1 m）や`floor_snap_length`が下ろす段差では発信されない |
| `teleported` | `teleport()`が配置を終えたとき。カメラや軌跡など追従するものは移動経路を描かず、そこへ瞬時に移る |

| 状態（`GroundCharacter.State`） | 条件 |
|---|---|
| `IDLE` | 地上で`IDLE_SPEED`（0.1 m/s）未満。壁に向かって走る場合も含む |
| `RUNNING` | 地上で速度を問わず移動中、ダッシュはしていない |
| `SPRINTING` | 地上でダッシュ中 |
| `JUMPING` | ジャンプ後、頂点までの空中 |
| `FALLING` | 頂点を過ぎた後、または縁から落ちた後の下降中 |

| 問い合わせ | 戻り値 |
|---|---|
| `get_state()` | 状態 |
| `get_move_velocity()`、`get_move_speed()` | ボディが実際に進んだ水平速度とその大きさ（m/s）。`get_real_velocity()`と違い、階段を上る分も含み、時間停止中（`Engine.time_scale`が0）も値を保つ |
| `get_locomotion_blend()` | 1Dブレンド用。静止時（`IDLE_SPEED`未満）は0、`max_speed`で1、全速ダッシュで2。速度の調整値に左右されない |
| `get_local_movement()` | 2Dブレンド用。xはモデルの右（負は左）、yは前（負は後ろ）で、ベクトル長はブレンド値。通常走行は(0, 1)、ダッシュは(0, 2)、右への横移動は(1, 0)、左は(−1, 0)、左前方は(−0.71, 0.71)、後退は(0, −0.7) |
| `get_local_acceleration()` | 同じ軸での加速、減速、旋回の速さ（m/s²）。加速するとy > 0、減速ではy < 0、左旋回ではx < 0。ボディを駆動する速度から求めるため、階段では急変せず、壁への衝突も現れない |
| `get_turn_rate()` | モデルの旋回速度（rad/s）。左は正、右は負 |
| `get_air_time()` | 空中にいる秒数。地上では0 |
| `get_step_phase()` | 歩数を表す数値。各一歩で整数になり、小数部は次の一歩までの距離に応じて増える |
| `get_gait_cycle()` | 2歩分の周期を0から1で示す。左足の接地で0、右足で0.5 |
| `get_step_foot()` | 最後の一歩の足、`Foot.LEFT`または`Foot.RIGHT`。停止を挟んでも交互になる |
| `is_sprinting()`、`is_exhausted()`、`get_jump_speed()` | 現在ダッシュ中か、疲労困憊か、ジャンプの踏み切り速度 |
| `is_on_floor()`、`get_floor_angle()`、`velocity.y` | `CharacterBody3D`自体が持つ接地状態、足元の斜面、垂直速度 |
| `get_ground_height(point, above, below)` | 地点の下で立てる地面の高さ。地点の`above`メートル上から`below`メートル下まで、ボディの衝突マスクを使い1本のレイを飛ばす。地面がない場合や、レイが`above`より高い壁などの内部から始まる場合はNAN |
| `is_counting_steps()` | `steps_enabled`がオンで、どのコンポーネントも止めておらず、現在歩数を数えているか |
| `get_fall_settings()` | 有効な落下設定。上書きの優先度が最も高いもの、同順位なら最後に設定されたもの、なければ`fall`。Nullなら速度上限のない`gravity_scale` |

用途別の選び方：

- **アニメーションのブレンド：**0、1、2に点を置いた`BlendSpace1D`には`get_locomotion_blend()`、横移動と後退を含む`BlendSpace2D`には`get_local_movement()`を使います。これらが正確な入力です。
- **速度に追従するエフェクト：**`get_real_velocity()`ではなく`get_move_velocity()`を使います。この実速度は`move_and_slide()`後にボディが階段へ置かれるたびに小さくなり、時間停止中は長さ0のティックで移動量を割るため0 / 0、NaNになります。
- **慣性表現：**遅れて揺れる道具、発進や旋回で傾くモデル、マントには`get_local_acceleration()`を使います。
- **旋回時の傾きやその場旋回：**`get_turn_rate()`を使います。角度ではなく速度で、モデルが回る間だけ値が出てティックごとに揺れ、向きが揃うと0へ戻ります。使用前に平滑化してください。
- **短い落下と大きな落下の区別：**`get_air_time()`を使います。空中にいたのが一瞬なら落下アニメーションを省き、長く落ちたほど着地を強くできます。
- **`touched_floor`と`landed`：**`touched_floor`は空中で過ごした後の接地すべてで出るため、空中アニメーションの終了に使います。`landed`は大きな着地だけで、カメラの揺れ、着地音、しゃがみなどに使います。
- **足跡、砂ぼこり、右足の足音：**`stepped`の処理内で`get_step_foot()`を使います。
- **階段の音や段を上がるアニメーション：**`stair_taken(height)`を使います。平滑化には使いません。ボディはすでに段の上です。
- **階段に接地する足や、地面の上のモデル：**`get_ground_height()`を使います。

**歩数を数えないとき**（`is_counting_steps()`がfalse）は`stepped`が出ず、`get_step_phase()`、`get_gait_cycle()`、`get_step_foot()`は最後の値で止まります。その間、脚のアニメーションをこれらに追従させないでください。キャラクター自体は通常どおり走り、ジャンプし、階段を上ります。

`HandSway`は歩行周期に従い、アニメーションも同じ方法を使えます。通常は毎フレーム問い合わせから`AnimationTree`のブレンド値を設定し、シグナルでステートマシンを切り替えます。

```gdscript
@export var character: GroundCharacter

@export var tree: AnimationTree


func _ready() -> void:
	character.state_changed.connect(_on_state_changed)
	character.landed.connect(func(_speed: float) -> void:
		tree.set("parameters/land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE))


func _process(_delta: float) -> void:
	# 静止0、走行1、ダッシュ2のBlendSpace1D。横移動にはBlendSpace2Dとget_local_movement()を使う。
	tree.set("parameters/ground/blend_position", character.get_locomotion_blend())


func _on_state_changed(state: GroundCharacter.State, _previous: GroundCharacter.State) -> void:
	var in_air := state == GroundCharacter.State.JUMPING or state == GroundCharacter.State.FALLING
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	playback.travel("air" if in_air else "ground")
```

地面と足の動きを合わせるには、走行周期を時間ではなく距離で再生します。周期内の位置を`get_gait_cycle()`と周期の長さの積に設定します（`TimeSeek`ノード、または一時停止した`AnimationPlayer`の`seek()`）。周期は左足が接地するところから始めます。

### CharacterMonitor：状態を文字で表示

`GroundCharacter`の現在の行動と最新イベントを表示する`Label`です。アニメーション調整やデバッグ用オーバーレイに使えます。デモでは`Hud/CharacterState/Monitor`で、設定（F10）→ インターフェース → **キャラクターの状態とイベント**から表示します。文字は上のシグナルと問い合わせだけから作るため、このスクリプトはそれらの使用例でもあります。

```
Running
Speed 5.5 m/s · blend 1.00
Forward +1.00 · right +0.00
Turning +0°/s
On the ground · slope 0°
Step 38 · left foot · cycle 0.03
Stamina 100%

11.83 s  Jumping → Falling
12.08 s  touched the ground at 7.8 m/s
12.08 s  landing at 7.8 m/s
12.08 s  Falling → Running
12.35 s  step, right foot
12.62 s  step, left foot
```

各行の意味：

1. `get_state()`が返す状態。
2. 実際の速度（`get_move_speed()`）とブレンド値。
3. モデルの軸で表した符号付きの移動量。前方+1.00は通常の全速走行、−0.70は後退。右方向−1.00は左への横移動です。
4. モデルの旋回速度。度/秒で、左が正です。角度ではなく速度なので、モデルが回る間だけ表示され、向きが揃うと0へ戻ります。
5. 地上なら足元の傾斜、空中なら滞空時間と垂直速度。
6. 歩数、最後の足、歩行周期。歩数を数えないときは「No steps」。
7. スタミナ。ダッシュできない間は「exhausted」も表示されます。

下には開始からの時刻とともに、古い順で最新のイベントを表示します。足、階段の高さ、ジャンプ、踏み切り、落下速度付きの着地、ダッシュ、状態変化を含みます。パネルが見えている間は毎フレーム文字を再構築します。隠れている間は省きますが、イベントは記録し続けます（`log_events`なら出力にも書きます）。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `character` | — | `GroundCharacter`。空なら親 |
| `history_size` | 6 | 状態の下に表示する最新イベントの数。0なら状態だけ |
| `log_events` | オフ | すべてのイベントを時刻とキャラクター名付きで出力にも書く |
| `include_steps` | オン | 毎秒数回ある足と階段も表示・記録する |

メソッド：`get_text_now()`、`get_state_lines()`、`get_event_lines()`、`get_state_name(state, translated)`。表示文は`tr()`を通るためパネルにはインターフェースの言語が使われ、出力のログは英語のままです。

### 階段と斜面

**斜面**は`move_and_slide()`自身が処理します。ボディは`floor_max_angle`以下の面を上り、それより急なら止まります。デモのボディでは`floor_constant_speed`がオンなので、スロープ上でも速度を保ちます。

**階段。** カプセルが自身の形だけで乗り越えられる段差は`radius × (1 − cos floor_max_angle)`までで、半径0.35 mのカプセルなら0.1 mです。より高い`max_step_height`までの段差は、ボディが次のように処理します。

- **上り。** ティック中の移動をさらに5 cm先まで調べ、立てないほど急なものにぶつかるなら階段を試します。`max_step_height`だけ上へ（天井があればそこまで）、そのティックの移動分だけ前へ、地面まで下へと探します。上面をレイで確認し、足元から`max_step_height`を超えない高さの地面だけを認めます。したがって0.4 mのブロックや急斜面は階段になりません。ボディを段の上に置き、`move_and_slide()`で位置を落ち着かせます。
- **下り。** ティック前に地上にいて、ティック後にジャンプせず空中へ出たとき、`max_step_height`以内の深さに地面があればその上へ置きます。`left_floor`も落下も起きません。
- ボディが上り下りした各段は`stair_taken(height)`で報告されます。前に立っていた地面から新しい地面までの実高で、デモの段なら上りが+0.2 m、下りが−0.2 mです。
- カプセルの丸い底は段の縁に斜めに触れ、縁から遠いうちは立てないほど急な角度になります。そのため2 cm刻みで少し先の接地点を探し、ボディはそのティックの通常の移動先より数センチ先に置かれる場合があります。

段の縁を転がって越える約1ティックの間、水平速度は約70%へ落ちます（`get_move_speed()`には現れますが、`HandSway`は`get_local_acceleration()`に従うため手の杖には現れません）。長い階段では見えないスロープのコライダーが最も滑らかです。

ボディは階段を即座に上ります。0.2 mの段では1ティックで約0.1 m上がり、残りはカプセルが縁を越える次の2～3ティックに進みます。物理補間は描画フレームへ分散しますが、画面上では短い揺れが残ります。浮遊モデルは代わりに階段を滑らかに越え（`CharacterHover`）、カメラの`height_follow_time`は視点の上昇を滑らかにします（デモでは0.15 s。[カメラ](camera.md#プロパティ)を参照）。

ナビゲーションメッシュはボディが上れる場所を接続しなければなりません。デモの`agent_max_climb`は`max_step_height`と同じ0.3 mです（[ワールドとナビゲーション](world-and-navigation.md#物理レイヤーとナビゲーション)を参照）。

### ジャンプ

踏み切り速度は`v = √(2·g·h)`です。踏み切りのティックでは`v − g·dt/2`を与え、ほかの重力は加えません。コヨーテタイム中でも同じです。これで毎ティックの位置は放物線上に正確に乗り、ジャンプ高はティックレートに左右されません。単に`v`を与えると`v·dt/2`だけ高くなり、60ティックでは1 mでなく1.064 mです。デモでは`gravity_scale`が3のとき、1 mのジャンプに0.52 sかかります。

空中でもキャラクターは以前のように走り続け、操作も変わりません。崖ガードはジャンプを止めません。足場の縁からのジャンプは意図した行動だからです。

### 落下

ジャンプの頂点を過ぎた後や縁から落ちたときの下降は、`FallSettings`リソースに従います。キャラクター自身の`fall`、またはコンポーネントが代わりに設定したものです。ジャンプの上昇は変わらず`gravity_scale`で減速するため、どの落下設定でも高さは`jump_height`のままです。落下設定がなければ従来どおり、場所の重力が引く方向へ重力×`gravity_scale`で速度上限なく落ちます。設定があっても、エリアの重力が地面に沿って引く力は従来どおり作用します。上昇気流のように重力が下へまったく引かない場所では、設定が整える下降自体がありません。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `gravity_scale` | 0 | 下降中にワールドの重力を何倍にし、どの速さで落下速度を増やすか。キャラクター自身より小さければ上昇よりゆっくり下降する。0ならキャラクター自身の`gravity_scale`を使うため、新規リソースだけでは挙動が変わらず、速度上限だけを設定しても落下時の重力は保たれる |
| `max_speed` | 0 m/s | 落下の最高速度。そこまで加速してから一定速度になる。0なら制限なし |
| `braking_time` | 0.3 s | `max_speed`を超える落下が、その超過分の95%を減速する時間。下向きに投げられた後や、落下途中に設定が有効になったときに作用する。0なら即時 |

コンポーネントは一時的に自身の落下設定で`fall`を上書きできます。`set_fall_override(self, settings, priority)`を使い、解除には`null`を渡します。複数なら優先度が最も高いもの（デフォルトは0）、同順位なら最後に設定したコンポーネントが有効です。設定内容や優先度を変更するだけでは同順位内の順序は変わりません。`fall`自体は変更されないため、全コンポーネントが解除すればゲーム本来の設定に戻ります。キャラクターはコンポーネントを生存させず、解放されれば自動的に解除されます。`get_fall_settings()`は有効な落下設定を返します。`CharacterHover`はモデルが浮き始めるたび自身の`fall`を優先度0で設定します（[キャラクター](characters.md#落下)を参照）。ゲームが優先度1で設定する落下速度低下の呪文などは、浮遊中もそちらが優先されます。

`touched_floor`と`landed`は接地した瞬間の速度を報告します。`landing_min_speed`より低い最高速度までしか加速しない落下では`touched_floor`だけが出ます。`landed`が出るのは、それより速く下向きに投げられ、減速しきる前に接地した場合だけです。キャラクター自身の`fall`でこれが起きるなら、ジャンプ後に着地音やエフェクトが一度も出なくなるため設定警告です。浮遊中は柔らかい着地としてデモが意図した動作です。最高速度が`landing_min_speed`とちょうど同じなら着地イベントが出ます。

デモのヒーロー自身には`fall`がありません。浮遊ノードには`gdscript/player/player_floating_fall.tres`があり、ボディの3ではなく重力倍率0.5、最大下降速度2 m/sです。そのため、浮遊中のヒーローは1 mジャンプ後に0.52 sではなく0.95 s滞空し、7.8 m/sではなく2 m/sで接地します。独自ボディでは`FallSettings.get_next_speed(speed, acceleration, delta)`と`get_gravity_scale(own)`が計算を担います。

## ダッシュとスタミナ

ダッシュが要求され、キャラクターがクリック、長押し、両ボタン、キーのいずれかで操作されている間は、通常の`sprint_speed_multiplier`倍速く走り、スタミナを消費します。Shiftを押しながら静止しても消費しません。蓄えが尽きると疲労困憊になり、`recover_ratio`まで回復する間は通常速度で走ります。その時点でもShiftが押されていれば自動的にダッシュを再開します。

`Stamina`は何が蓄えを消費するかを知りません。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `max_value` | 100 | 満タンの蓄え |
| `recovery_rate` | 毎秒12.5 | 空から満タンまで8 s |
| `recovery_delay` | 1 s | 最後の消費から回復が始まるまでの時間 |
| `recover_ratio` | 0.3 | 疲労困憊のキャラクターがダッシュを再開できる割合（1 + 2.4 s） |

メソッド：`spend(amount)`、`can_spend()`、`get_ratio()`、`is_exhausted()`、`refill()`。シグナル：`changed(ratio)`、`exhausted_changed(exhausted)`。HUDの`StaminaBar`がこれらを受け取ります。

## LedgeGuard

キャラクターが崖から歩いて落ちるのを防ぎます。ボディは`move_and_slide()`の前に`constrain(velocity, delta)`を呼びます。そのティックの終わりに崖の上へ出てしまうなら、移動を縁に沿って地面がある最も近い方向へ回し、旋回角のコサイン分だけ短くします。壁に沿って滑る場合と同じで、縁へ真っすぐ走ると止まります。

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `enabled` | オン | 崖からの落下を防ぐ |
| `max_drop` | 0.5 m | これより深い落差を守り、浅い落差は通れる場合がある。落下せずに下りられるのは`GroundCharacter.max_step_height`以内の段差だけ |
| `edge_margin` | 0.15 m | キャラクターの中心が縁へ近づける距離 |
| `margin_probes` | 6 | `edge_margin`の円周上のレイ数 |
| `probe_height` | 0.5 m | 足元より少し上の地面（スロープ）も見つけるため、レイを足よりこの高さから出す |
| `floor_mask` | 0 | 地面とみなすもの。0ならボディの衝突マスクを使い、ボディが立てるものを地面とみなす |
| `slide_iterations` | 6 | 滑り方向を探す角度の半減回数。6回で約1.4° |

開けた地面では1ティックに7本、縁では最大98本のレイを使います。空中ではガードは何もしません。足場から下りる経路がスロープを通るなら、ガードは邪魔しません。地面とみなすのは、エンジンの床判定と同じ小さな余裕（`GroundCharacter.FLOOR_ANGLE_MARGIN`）を含めて、ボディの`floor_max_angle`以下で立てる面です。`floor_mask`がボディの衝突しないレイヤーを含むと設定警告が出ます。ボディがすり抜けるものをガードが地面とみなすためです。

## 測定された挙動

`tests/movement_checks.gd`、`tests/character_actions_checks.gd`、`tests/character_state_checks.gd`のシーン検査は、付属のヒーローを毎秒60物理ティックで確認します。

- デフォルトの5.5 m/sの走行と0.18 sの加速では、0.18 sで速度の95%に達し、95%からの通常停止は約0.20 sです。減速中の新しい目標では速度が保たれ、後ろをクリックすると弧を描いて向きを変えます。
- ダッシュは8.25 m/sに達します。テストで持続時間を2 sにしたスタミナは尽きた後、閾値を超えて回復し、押し続けているダッシュ要求で再開します。
- 1 mのジャンプは1.000 mに達し、滞空時間は約0.52 sです。着地直前の入力バッファが働き、縁から離れた直後の入力もコヨーテタイム内なら有効です。
- デモの0.2 mの階段は両方向とも地面を離れずに通れ、`stair_taken`が各段を報告します。0.4 mのブロックと50°の斜面はボディを止めます。ガードは足場の縁への走行を止め、斜めの走行を縁に沿って滑らせます。
- 浮遊ノードの落下重力0.5、速度上限2 m/sではジャンプ高は1 mのまま、接地速度は2 m/sになり、デフォルトの着地閾値2.5 m/sを下回ります。これらの結果は付属のカプセル、コライダー、メッシュ、設定に依存します。形状や値を変えた場合は自分のレベルで検査してください。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
