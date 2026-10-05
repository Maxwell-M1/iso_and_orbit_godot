<!-- translation of docs/en/settings.md @ 262d20fd6cef -->
# 設定

[← ドキュメント目次](index.md)

> これは[英語の原文](../en/settings.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

F10で設定ウィンドウが開き、ゲームが一時停止します。EscまたはF10で閉じます。変更はすぐに反映されます（マウスでドラッグするUIスケールだけはボタンを離すまで待ちます）。ウィンドウを閉じたときとゲームの終了時に`user://settings.cfg`へ保存されます。**すべてリセット**で、すべての設定がデフォルトに戻ります。

デフォルト値は`gdscript/settings/game_settings.gd`の`DEFAULTS`にあります。デモは`gdscript/demo/settings_applier.gd`でそれらをノードのプロパティに適用します。下記のとおり、コンポーネント自身のプロパティのデフォルト値は異なる場合があります。設定システムの仕組みと設定の追加方法：[UI](systems/ui.md#設定)。

単独でコピーしたヒーローには[構成](configurations.md)を使い、インスペクターのプロパティと一貫した設定を確認してください。このページは**デモのメニュー**を説明します。下のラベルは初期キー割り当てによるもので、実行中のメニューは`InputMap`から現在のキー名へ置き換えます。

## 操作

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **左ボタン長押し**：カーソルへ直進 / 経路に沿って地点へ | `gameplay/hold_mode` | カーソルへ直進 | `PointClickMoveInput.hold_mode` |
| **右ボタン + WASD**：オフ / 横移動 / 旋回 | `gameplay/camera_keys_mode` | 旋回 | `PointClickMoveInput.keys_with_camera`（コンポーネントのデフォルト：横移動）。オフでは対応するヒントも隠す |
| **左右ボタン + A/D**：オフ / 横移動 / 斜め | `gameplay/camera_steer_keys_mode` | 斜め | `PointClickMoveInput.keys_with_camera_steer`（コンポーネントのデフォルト：横移動）。オフでは対応するヒントも隠す |
| **後退（S）の減速** 0…80%、横移動のときのみ | `gameplay/backward_slowdown` | 30% | `LocomotionSettings.backward_speed_multiplier` = 1 − 値 / 100 |
| **左ボタン長押しで走る間はカーソルを隠す** | `gameplay/hide_cursor_on_hold` | オン | `PointClickMoveInput.hide_cursor_while_held` |
| **左ボタンで走行中の右ボタンはカメラを回すだけ** | `gameplay/look_around` | オン | `PointClickMoveInput.look_around_while_held`。見回しのヒント行にも反映する |

## キャラクター

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **主人公の外見**：10種類から1つ | `character/look` | 8 · ネクロマンサー | `CharacterAppearance.set_look()` |
| **地面の上に浮く** | `character/hover` | オフ | `Hero/Character/Visual/Hover`の`CharacterHover.enabled`（コンポーネントのデフォルトはオン、`player.tscn`ではオフ）。浮遊中は歩数が止まり、`player_floating_fall.tres`で落下が遅くなる |
| **崖から落ちない** | `gameplay/ledge_guard` | オン | `LedgeGuard.enabled` |
| **ジャンプ（スペース）** | `character/jump` | オン | `GroundCharacter.can_jump`。ジャンプのヒントも隠す |
| **ジャンプの高さ** 0.5…1.5 m | `character/jump_height` | 1.0 m | `GroundCharacter.jump_height` |
| **ダッシュ（Shift）** | `character/sprint` | オン | `GroundCharacter.can_sprint`。ダッシュのヒントも隠す |
| **Shift**：長押し / 押すとオン、もう一度でオフ | `character/sprint_mode` | 長押し | `CharacterActionInput.sprint_mode` |
| **速度ボーナス** +10…+100% | `character/sprint_bonus` | +50% | `LocomotionSettings.sprint_speed_multiplier` = 1 + 値 / 100 |
| **ダッシュの疲労** | `character/fatigue` | オン | `GroundCharacter.sprint_tires` |
| **スタミナ持続時間** 3…10秒 | `character/sprint_duration` | 5.0秒 | `GroundCharacter.sprint_duration` |

落下防止のスイッチがキャラクタータブに移った後も、キーは`gameplay/ledge_guard`のままです。そのため、保存済みの選択は失われません。

## カメラ

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **右ボタンでカメラを上下に傾ける** | `camera/mouse_pitch` | オフ | `OrbitCameraRig.mouse_pitch` |
| **走る方向へカメラを回す** | `camera/follow` | オフ | `OrbitCameraRig.follow_movement` |
| **回転時間** 0…10 s（0では「即時」） | `camera/follow_time` | 1.1 s | `OrbitCameraRig.follow_time`（コンポーネントのデフォルト：1.5 s） |
| **カメラへ向かって走るときは除く** | `camera/follow_except_toward` | オン | `OrbitCameraRig.follow_toward_camera_angle`。オフでは0となり、真正面からカメラへ向かう走行も含め、どの走行でも後ろへ回る |
| **角度** 5…60° | `camera/follow_except_toward_angle` | 30° | 除外がオンの間、`OrbitCameraRig.follow_toward_camera_angle`に設定する。コンポーネントのデフォルトも30° |
| **走る間カメラの傾きを揃える** | `camera/align_pitch` | オフ | `OrbitCameraRig.follow_pitch` |
| **見下ろし角** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −値（コンポーネントのデフォルト：−40°） |
| **傾きの調整時間** 0…10 s（0では「即時」） | `camera/align_pitch_time` | 1.1 s | `OrbitCameraRig.follow_pitch_time`（コンポーネントのデフォルト：1.5 s） |
| **走る間カメラの高さを揃える** | `camera/align_height` | オフ | `OrbitCameraRig.follow_zoom` |
| **高さ** 0…100% | `camera/align_height_level` | 55% | `OrbitCameraRig.follow_zoom_level` = 値 / 100。0%はカメラを最も低く、100%は最も高くする |
| **高さの調整時間** 0…10 s（0では「即時」） | `camera/align_height_time` | 1.5 s | `OrbitCameraRig.follow_zoom_time` |
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

ゲームをエディター内、つまりゲームタブ（Game）またはそのフローティングウィンドウ（**Make Game Workspace Floating on Next Play**）で実行している間は、ウィンドウがエディターのものなので、フルスクリーンは機能せず、スイッチも無効になります。エディターから試すには、ゲームタブのメニューで**Embed Game on Next Play**をオフにしてください。ゲームが専用のウィンドウで開きます。

V-Syncでは、フレーム数がモニターのリフレッシュレートを超えることはありません。そのため、そのレート以上のFPS上限はまったく設定されません。設定するとV-Syncと競合し、モニターが表示するより少ないフレーム数になってしまいます（240 Hzのモニターで上限を240にすると約220でした）。

物理補間がないと、キャラクターとカメラはティックごと（毎秒60回）に段階的に動きます。カメラはターゲットの`get_global_transform_interpolated()`を追いますが、これは補間なしでは単に最後のティックでの位置になるからです。60 Hzより高速なモニターではこれが目立ち、カメラが走りに追従していると、旋回時にキャラクターも揺れます。カメラは毎フレーム回転しますが、キャラクターはティックごとにしか回転しないためです。

## インターフェース

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **言語**：English、Español、日本語、Português (Brasil)、Русский、Türkçe、简体中文 | `interface/language` | English | `TranslationServer.set_locale()` |
| **UIスケール** 50…100% | `interface/ui_scale` | 75% | ルートウィンドウの`content_scale_factor` |
| **FPSカウンター** | `interface/fps_counter` | オン | `Hud/FpsCounter`の表示 |
| **操作ヒントと速度** | `interface/help` | オン | `Hud/Panel`の表示 |
| **キャラクターの経路線** | `interface/path_line` | オフ | `Hero/PathView`の表示 |
| **キャラクターの状態とイベント** | `interface/character_state` | オフ | `Hud/CharacterState`の表示（`CharacterMonitor`） |

UIスケールはヒント、FPSカウンター、スタミナバー、キャラクター状態パネル、「発見：…」の通知、移動の案内、ローディング画面、ウィンドウを変えます。3Dビューには影響しません。100%はシーンで作成したサイズです。マウスでスライダーをドラッグした場合は、カーソルの下からスライダーが逃げないよう、ボタンを離した時点で適用します。キーボードとホイールからの変更は直ちに反映されます。

## サウンド

| 設定 | キー | デフォルト | 適用先 |
|---|---|---|---|
| **音量** 0…100%（0では「オフ」） | `sound/volume` | 100% | `Master`バスの音量。0でミュート |
| **足音** | `sound/footsteps` | オン | `CharacterSounds.footsteps_enabled` |
| **ジャンプと着地** | `sound/jump` | オン | `CharacterSounds.jump_enabled` |
| **ダッシュ開始とダッシュ中** | `sound/sprint` | オフ | `CharacterSounds.sprint_enabled`（コンポーネントのデフォルトはオン） |

## 依存する設定

別の設定がないと意味をなさない項目は薄く表示され、変更できません。右ボタン＋WASDが横移動でないときの後退減速、ジャンプがオフのときのジャンプ高、ダッシュがオフのときのダッシュ関連の項目、疲労がオフのときのスタミナ持続時間、旋回がオフのときの回転時間、傾きの自動調整がオフのときの角度と時間、高さの自動調整がオフのときの高さと時間、ヒーローが浮遊して歩数のない間の足音です。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
