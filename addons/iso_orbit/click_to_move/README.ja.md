<!-- translation of addons/iso_orbit/click_to_move/README.md @ 784d979b2a2a -->
# クリック移動

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

アイソメトリックやトップダウンのゲーム向けのクリック移動です。地面をクリックすると、キャラクターはナビゲーションメッシュに沿ってそこへ走り、その地点ちょうどで止まります。ボタンを長押しすると、カーソルを追って走ります。一定の加速と減速、旋回速度の制限、静止状態からの即時旋回を備えています。右ボタンを押している間は、WASDでキャラクターをカメラ基準で動かせます。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings`（Resource） | 速度、加速、減速、旋回 |
| `ground_motion.gd` | `GroundMotion`（RefCounted） | 計算：方向と残り距離 → 速度 |
| `navigation_mover.gd` | `NavigationMover`（Node） | `move_to()`、`steer()`、`stop()`。速度を返し、ボディは動かさない |
| `point_click_move_input.gd` | `PointClickMoveInput`（Node） | マウスと右ボタン + WASD → ムーバーへのコマンド |
| `click_marker.gd`、`click_marker.tscn` | `ClickMarker`（Node3D） | クリックした地点のマーカー |
| `navigation_path_view.gd` | `NavigationPathView`（MeshInstance3D） | 残りの経路に沿ったデバッグ用の線 |

ほかのアドオンは必要ありません。重力、ジャンプ、ダッシュを備えた完成済みのボディが必要なら、`addons/iso_orbit/ground_character`を追加してください。

## セットアップ

1. このフォルダーを`res://addons/iso_orbit/click_to_move/`にコピーします。
2. レベルのナビゲーションメッシュをベイクします（`NavigationRegion3D`）。ないとキャラクターは地点へまっすぐ走ります。
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

4. マウスで操作するには、`point_click_move_input.gd`を付けた`Node`を任意の場所に追加し、その`mover`と`camera`を設定します。入力アクション`move_to_cursor`（左ボタン）、`camera_rotate`（右ボタン）、`move_forward`、`move_back`、`move_left`、`move_right`（WASD）が必要です。クリックは物理レイヤー1（`ground_mask`）に当たります。
5. または、AIからムーバーに命令します：`move_to(point)`、`steer(direction)`、`stop()`。そして`arrived`を受け取ります。

## ドキュメント

テンプレートのリポジトリ内：`docs/ja/integration.md`、`docs/ja/systems/locomotion.md`、`docs/ja/systems/input.md`。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
