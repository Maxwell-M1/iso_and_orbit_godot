<!-- translation of addons/iso_orbit/ground_character/README.md @ 9b116d7ff0dd -->
# 地上キャラクター

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

クリック移動用の完成済みのキャラクターボディです。重力、コヨーテタイムと入力バッファ付きのジャンプ（物理ティックレートによらず同じ高さ）、スタミナ付きのダッシュ、階段の上り下り、段差でボディを止める落下防止を備えています。ボディはアニメーション、エフェクト、インターフェースのために自分が何をしているかを通知します：状態とその変化、どちらの足かを含むステップ、踏み切りと着地、ブレンド値としての速度、モデルの軸での移動、旋回、歩行サイクル。さらに、それらのシグナルで鳴るサウンド、状態をテキストで表示するパネル、歩みに合わせて揺れる手持ちのアイテム、切り替え可能なモデルも含まれています。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `ground_character.gd` | `GroundCharacter`（CharacterBody3D） | 重力、ジャンプ、ダッシュ、階段、`move_and_slide()`、モデルの回転。アニメーション向けの状態、シグナル、問い合わせ |
| `ledge_guard.gd` | `LedgeGuard`（Node） | 段差でボディを止めるか、縁に沿って滑らせる |
| `stamina.gd` | `Stamina`（Node） | ダッシュの蓄え |
| `character_action_input.gd` | `CharacterActionInput`（Node） | ダッシュとジャンプのキー → キャラクター |
| `character_sounds.gd` | `CharacterSounds`（Node3D） | キャラクターのシグナルでサウンドを再生する |
| `hand_sway.gd` | `HandSway`（Node） | 歩みに合わせて手のノードを振る |
| `character_monitor.gd` | `CharacterMonitor`（Label） | キャラクターの状態と最新のイベントをテキストで表示する。イベントをログに出力することもできる |
| `character_appearance.gd` | `CharacterAppearance`（Node） | 実行時にモデルを差し替える |
| `stamina_bar.gd`、`stamina_bar.tscn` | `StaminaBar`（ProgressBar） | `Stamina`用のHUDバー |

`addons/iso_orbit/click_to_move`が必要です。ボディは`NavigationMover`によって動かされます。

## セットアップ

1. このフォルダーと`click_to_move`を`res://addons/iso_orbit/`にコピーします。
2. キャラクターを組み立てます。

   ```
   Player           ground_character.gd付きのCharacterBody3D
   ├── CollisionShape3D
   ├── Visual       Node3D。中のモデルは−Zを向く
   ├── NavigationMover   click_to_moveのもの
   ├── LedgeGuard   任意
   └── Stamina      任意
   ```

   ボディの`mover`、`visual`、`ledge_guard`、`stamina`を設定します。デモではさらに、スロープでもキャラクターが速度を保つようにボディの`floor_constant_speed`を設定し、レベルと分けるためにボディを物理レイヤー2に置いています。ボディは`max_step_height`（0.3 m）までの段と、`floor_max_angle`までの斜面を上ります。階段を上る経路のために、`agent_max_climb`を`max_step_height`と同じ値にしてナビゲーションメッシュをベイクしてください。
3. キー操作のために、`character_action_input.gd`を付けた`Node`を追加し、その`character`を設定します。入力アクション`sprint`と`jump`が必要です。
4. 任意：`AudioStreamPlayer3D`の子を持つ`CharacterSounds`、モデルの手のノードを指定した`HandSway`、モデルのシーンのリストを持つ`CharacterAppearance`、デバッグパネル用に`CanvasLayer`内に置いた`CharacterMonitor`。`LedgeGuard.floor_mask`のデフォルトは物理レイヤー1です。

AIも同じボディを動かせます：`NavigationMover.move_to()`と`GroundCharacter.jump()`を呼び、`sprint_requested`を設定します。

## ドキュメント

テンプレートのリポジトリ内：`docs/ja/integration.md`、`docs/ja/systems/locomotion.md`、`docs/ja/systems/audio.md`、`docs/ja/systems/characters.md`。

---

*このページは Iso & Orbit 1.1.0 に対応しています。*
