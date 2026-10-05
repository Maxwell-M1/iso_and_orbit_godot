<!-- translation of addons/iso_orbit/click_to_move/README.md @ 29860f203673 -->
# クリック移動

[← ドキュメント目次（テンプレートのリポジトリ）](../../../docs/ja/index.md)

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

アイソメトリックやトップダウンのゲーム向けのクリック移動です。地面をクリックすると、キャラクターはナビゲーション経路に沿って進み、その到達可能な終端で止まります。ボタンを長押しするとカーソルを追って走ります。加速と減速は一定で、旋回速度には上限があり、静止状態からは即座に向きを変えます。右ボタンを押している間はWASDでカメラ基準の移動ができます。カーソルを追う走行中に右ボタンを押しても進路は保たれ、プレイヤーは周囲を見回せます。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings`（Resource） | 速度、加速、減速、旋回 |
| `ground_motion.gd` | `GroundMotion`（RefCounted） | 計算：方向と残り距離 → 速度 |
| `navigation_mover.gd` | `NavigationMover`（Node） | `move_to()`、`steer()`、`stop()`、`halt()`、`face()`。速度を返し、ボディは動かさない |
| `point_click_move_input.gd` | `PointClickMoveInput`（Node） | マウスと右ボタン＋WASD → ムーバーへの命令。`cancel()`は押下中の入力を忘れる |
| `click_marker.gd`、`click_marker.tscn` | `ClickMarker`（Node3D） | クリックした地点のマーカー |
| `navigation_path_view.gd` | `NavigationPathView`（MeshInstance3D） | 残りの経路に沿ったデバッグ用の線 |

ほかのアドオンは必要ありません。重力、ジャンプ、ダッシュを備えた完成済みのボディが必要なら、`addons/iso_orbit/ground_character`を追加してください。

## セットアップ

1. このフォルダーを`res://addons/iso_orbit/click_to_move/`にコピーします。
2. レベルのナビゲーションメッシュをベイクします（`NavigationRegion3D`）。エージェントの大きさと登坂高をボディのカプセルと段差に合わせます。メッシュがないか経路が空なら要求地点へ直進し、部分的な経路なら最も近い到達可能地点で終わる場合があります。ボディには物理的な衝突形状とコリジョンシェイプも必要です。
3. キャラクターのボディの直接の子として`NavigationMover`を追加します。ボディは物理ティックごとに1回、`move_and_slide()`の前に`compute_velocity(delta)`を呼びます。

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

   ムーバーがツリーへ入る前に、`NavigationMover.settings`へ`LocomotionSettings`リソースを割り当てます。空ならスクリプトのデフォルト値で作ります。キャラクターごとに調整するなら**Make Unique**を使います。実行中はリソースのフィールドを変更できますが、`_ready()`後に`mover.settings`を交換しても、すでに作られた`GroundMotion`の設定は変わりません。階段、ジャンプ、崖ガードが必要なら、対応するアドオンの`GroundCharacter`を使います。

4. マウスで操作するには、`point_click_move_input.gd`を付けた`Node`を任意の場所に追加し、その`mover`と`camera`を設定します。入力アクション`move_to_cursor`（左ボタン）、`camera_rotate`（右ボタン）、`move_forward`、`move_back`、`move_left`、`move_right`（WASD）が必要です。欠けていれば開始時に一度報告し、その後は読みません。クリックは物理レイヤー1（`ground_mask`）に当たります。キャラクターや見えない壁のレイヤーは外し、地面の代わりにそれらを拾わないようにします。`addons/iso_orbit/orbit_camera`のオービットカメラを使うなら、`hold_pending_changed`を`set_follow_paused`へ、`run_requested`を`end_follow_wait`へ接続します。走行中の見回し（`look_around_while_held`）には、`camera_steer_action`とリグの`rotate_action`が同じカメラ回転アクション（両方`camera_rotate`）である必要があります。
5. またはAIから`move_to(point)`、`steer(direction)`、`stop()`を命じ、`arrived`を受け取ります。これは要求地点ではなく、その手前で終わる場合もある経路の終端に達したことを表します。

組み立て済みヒーローには手作業でこのボディを作る代わりに、`docs/ja/integration.md`のコピー手順とシーン設定を使います。2つの入力モードとヒーローの設定は`docs/ja/systems/input.md`を参照してください。

## ドキュメント

テンプレートのリポジトリ内：`docs/ja/integration.md`、`docs/ja/systems/locomotion.md`、`docs/ja/systems/input.md`。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
