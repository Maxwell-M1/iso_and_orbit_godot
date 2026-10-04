<!-- translation of docs/en/settings.md @ dabbac251e72 -->
# 設定

> これは[英語の原文](../en/settings.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

F10で設定ウィンドウが開き、ゲームが一時停止します。EscまたはF10で閉じます。変更はすぐに反映され、ウィンドウを閉じたときとゲームの終了時に`user://settings.cfg`へ保存されます。**すべてリセット**で、すべての設定がデフォルトに戻ります。

デフォルト値は`gdscript/settings/game_settings.gd`の`DEFAULTS`にあります。デモは`gdscript/demo/settings_applier.gd`でそれらをノードのプロパティに適用します。下記のとおり、コンポーネント自身のプロパティのデフォルト値は異なる場合があります。設定システムの仕組みと設定の追加方法：[UI](systems/ui.md#設定)。

## 操作

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **左ボタン長押し**：カーソルへ直進 / 経路に沿って地点へ | `gameplay/hold_mode` | カーソルへ直進 | `PointClickMoveInput.hold_mode` |
| **右ボタン + WASD**：オフ / 横移動 / 旋回 | `gameplay/camera_keys_mode` | 旋回 | `PointClickMoveInput.keys_with_camera`（コンポーネントのデフォルト：横移動） |
| **左右ボタン + A/D**：オフ / 横移動 / 斜め | `gameplay/camera_steer_keys_mode` | 斜め | `PointClickMoveInput.keys_with_camera_steer`（コンポーネントのデフォルト：横移動） |
| **後退（S）の減速** 0…80%、横移動のときのみ | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − 値 |
| **左ボタン長押しで走る間はカーソルを隠す** | `gameplay/hide_cursor_on_hold` | オン | `PointClickMoveInput.hide_cursor_while_held` |

## キャラクター

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **主人公の外見**：10種類から1つ | `character/look` | 10 · 戦闘魔導士 | `CharacterAppearance.set_look()` |
| **崖から落ちない** | `gameplay/ledge_guard` | オン | `LedgeGuard.enabled` |
| **ジャンプ（スペース）** | `character/jump` | オン | `GroundCharacter.can_jump` |
| **ジャンプの高さ** 0.5…1.5 m | `character/jump_height` | 1.0 m | `GroundCharacter.jump_height` |
| **ダッシュ（Shift）** | `character/sprint` | オン | `GroundCharacter.can_sprint` |
| **Shift**：長押し / 押すとオン、もう一度でオフ | `character/sprint_mode` | 長押し | `CharacterActionInput.sprint_mode` |
| **速度ボーナス** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + 値 |
| **ダッシュの疲労** | `character/fatigue` | オン | `GroundCharacter.sprint_tires` |
| **スタミナ持続時間** 3…10秒 | `character/sprint_duration` | 5.0秒 | `GroundCharacter.sprint_duration` |

落下防止のスイッチがキャラクタータブに移った後も、キーは`gameplay/ledge_guard`のままです。そのため、保存済みの選択は失われません。

## カメラ

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **右ボタンでカメラを上下に傾ける** | `camera/mouse_pitch` | オフ | `OrbitCameraRig.mouse_pitch` |
| **走る方向へカメラを回す** | `camera/follow` | オフ | `OrbitCameraRig.follow_movement` |
| **カメラの傾きを揃える** | `camera/align_pitch` | オフ | `OrbitCameraRig.follow_pitch` |
| **見下ろし角** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −値（コンポーネントのデフォルト：−40°） |
| **追従時間** 0…10秒（0では「即時」）、旋回と傾きの両方に適用 | `camera/follow_time` | 1.1秒 | `OrbitCameraRig.follow_time`（コンポーネントのデフォルト：1.5秒） |
| **カメラ回転中もカーソルが狙いを保つ** | `camera/keep_aim` | オン | `PointClickMoveInput.keep_aim_on_camera_turn` |
| **カメラが背後の障害物で止まる** | `camera/keep_out_of_geometry` | オン | `CameraArm.keep_out_of_geometry` |
| **キャラクターが隠れたら寄る** | `camera/pull_in_on_occlusion` | オフ | `CameraArm.pull_in_on_occlusion` |

## 表示

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **フルスクリーン** | `display/fullscreen` | オフ | `DisplayServer.window_set_mode()` |
| **FPS上限**：24、30、60、120、240、無制限 | `display/max_fps` | 無制限 | `Engine.max_fps` |
| **垂直同期（V-Sync）** | `display/vsync` | オフ | `DisplayServer.window_set_vsync_mode()` |
| **物理補間（キャラクターとカメラ）** | `display/physics_interpolation` | オン | `SceneTree.physics_interpolation` |
| **障害物の裏のシルエット輪郭** | `display/silhouette_outline` | オン | `OccludedSilhouette.outline_enabled` |

ゲームをエディターのゲームタブ（Game）内で実行している間は、ウィンドウがエディターのものなので、フルスクリーンは機能しません。エディターから試すには、ゲームタブのメニューで**Embed Game on Next Play**をオフにしてください。

V-Syncでは、フレーム数がモニターのリフレッシュレートを超えることはありません。そのため、そのレート以上のFPS上限はまったく設定されません。設定するとV-Syncと競合し、モニターが表示するより少ないフレーム数になってしまいます（240 Hzのモニターで上限を240にすると約220でした）。

物理補間がないと、キャラクターとカメラはティックごと（毎秒60回）に段階的に動きます。カメラはターゲットの`get_global_transform_interpolated()`を追いますが、これは補間なしでは単に最後のティックでの位置になるからです。60 Hzより高速なモニターではこれが目立ち、カメラが走りに追従していると、旋回時にキャラクターも揺れます。カメラは毎フレーム回転しますが、キャラクターはティックごとにしか回転しないためです。

## インターフェース

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **言語**：English、Español、日本語、Português (Brasil)、Русский、Türkçe、简体中文 | `interface/language` | English | `TranslationServer.set_locale()` |
| **UIスケール** 50…100% | `interface/ui_scale` | 75% | ルートウィンドウの`content_scale_factor` |
| **FPSカウンター** | `interface/fps_counter` | オン | `Hud/FpsCounter`の表示 |
| **操作ヒントと速度** | `interface/help` | オン | `Hud/Panel`の表示 |
| **キャラクターの経路線** | `interface/path_line` | オフ | `PathView`の表示 |

UIスケールは、ヒント、FPSカウンター、スタミナバー、ウィンドウの大きさを変えますが、3Dビューは変えません。100%はシーンで作成したときのサイズです。

## サウンド

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **音量** 0…100%（0では「オフ」） | `sound/volume` | 100% | `Master`バスの音量。0でミュート |
| **足音** | `sound/footsteps` | オン | `CharacterSounds.footsteps_enabled` |
| **ジャンプと着地** | `sound/jump` | オン | `CharacterSounds.jump_enabled` |
| **ダッシュ開始とダッシュ中** | `sound/sprint` | オフ | `CharacterSounds.sprint_enabled` |

## 依存する設定

別の設定がないと意味をなさない項目は、薄く表示されて変更できなくなります。右ボタン + WASDが横移動モードでないときの後退の減速、ジャンプがオフのときのジャンプの高さ、ダッシュがオフのときのダッシュ関連すべて、疲労がオフのときのスタミナ持続時間、傾きの揃えがオフのときの見下ろし角、追従と傾きの揃えがどちらもオフのときの追従時間です。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
