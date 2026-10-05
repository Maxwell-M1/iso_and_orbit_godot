<!-- translation of addons/iso_orbit/ground_character/README.md @ 87915285e965 -->
# 地上キャラクター

[← ドキュメント目次（テンプレートのリポジトリ）](../../../docs/ja/index.md)

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

クリック移動用の完成済みキャラクターボディです。重力、コヨーテタイムと入力バッファを持ち物理ティックレートによらず同じ高さのジャンプ、独立した重力と速度上限を持つ落下、スタミナを使うダッシュ、階段の上り下り、任意の崖ガードを備えます。ボディはアニメーション、エフェクト、UI向けに、状態と変化、足ごとの歩数、踏み切りと着地、ブレンド値としての速度、モデル軸での移動、旋回、歩行周期を報告します。さらに、シグナルで鳴る音、状態を文字で表示するパネル、歩みに合わせて揺れる道具、モデルの浮遊と切り替えも含みます。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `ground_character.gd` | `GroundCharacter`（CharacterBody3D） | 重力、ジャンプ、ダッシュ、階段、`move_and_slide()`、モデルの回転。アニメーション向けの状態、シグナル、問い合わせ。急な跳ねのない`teleport()` |
| `fall_settings.gd` | `FallSettings`（Resource） | 落下時の重力、速度上限、超過速度からの減速 |
| `ledge_guard.gd` | `LedgeGuard`（Node） | 段差でボディを止めるか、縁に沿って滑らせる |
| `stamina.gd` | `Stamina`（Node） | ダッシュの蓄え |
| `character_action_input.gd` | `CharacterActionInput`（Node） | ダッシュとジャンプのキー → キャラクター |
| `character_sounds.gd` | `CharacterSounds`（Node3D） | キャラクターのシグナルでサウンドを再生する |
| `hand_sway.gd` | `HandSway`（Node） | 歩みに合わせて手のノードを振る |
| `character_hover.gd` | `CharacterHover`（Node3D） | モデルを地面から浮かせ、階段を滑らかに越え、揺れと傾きを加える。落下を遅くできる |
| `damped_spring.gd` | `DampedSpring`（RefCounted） | 慣性用に単一の値を扱う減衰ばね |
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

   ボディの`mover`、`visual`、`ledge_guard`、`stamina`を設定します。デモではスロープで速度を保つ`floor_constant_speed`をオンにし、ボディを物理レイヤー2へ置き、レベルと見えない壁のレイヤー1と4に衝突させます。`get_ground_height()`とデフォルトの`LedgeGuard`は同じマスクで地面を探します。ボディは`max_step_height`（0.3 m）までの段と`floor_max_angle`までの斜面を上ります。階段の経路には`agent_max_climb`を越えたい段差高に合わせてメッシュをベイクし、実際のコライダーで試します。`LedgeGuard.max_drop`は`max_step_height`以上にし、下り段差で`stair_taken`が必要なら`floor_snap_length`はそれより小さくします。レベルでボディが回転していても、キャラクターはボディに対して`Visual`だけを回し、最初はボディの−Zを向きます。その後は`teleport(position, facing)`または`NavigationMover.face()`で向きを変えます。
3. キー操作には`character_action_input.gd`を付けた`Node`を追加し、その`character`を設定します。入力アクション`sprint`と`jump`が必要です。欠けたものは起動時に一度報告され、その後は読みません。
4. 任意：`AudioStreamPlayer3D`の子を持つ`CharacterSounds`、`character`とモデルの手を設定した`HandSway`、`slot`とモデルシーン一覧を持つ`CharacterAppearance`、デバッグパネル用に`CanvasLayer`内へ置く`CharacterMonitor`。`LedgeGuard.floor_mask`のデフォルト0はボディの衝突マスクを使い、ボディが立てない急な面を除きます。
5. 浮遊させるには、`character_hover.gd`を付けた`Node3D`を`Visual`とモデルの間（`Visual/Hover/Model`）に置きます。`CharacterAppearance`を使うなら、その`slot`に浮遊ノードを指定します。浮遊中は歩数が止まり、`fall`（`FallSettings`）を設定すればゆっくり下降できます。上がるのはモデルで、ボディと衝突形状は変わりません。
6. 任意でボディの`fall`へ`FallSettings`を設定すると、下降時の重力と速度上限を変えられます。

設定の誤りはゲーム開始時に警告されます。付属の`player.tscn`は高さ1.8 mのカプセル、オンの`floor_constant_speed`、崖ガード、スタミナ、浮遊時の落下リソース、初期状態が**オフ**の浮遊ノードを持ちます。`NavigationMover`は`player_locomotion.tres`を使います。デモの`SettingsApplier`は起動時に保存済み設定でプロパティを書き換える場合があります。ヒーロー全体のコピー手順は`docs/ja/integration.md`、独自モデルと衝突形状の調整は`docs/ja/systems/characters.md`を参照してください。

AIも同じボディを動かせます：`NavigationMover.move_to()`と`GroundCharacter.jump()`を呼び、`sprint_requested`を設定します。

## ドキュメント

テンプレートリポジトリ：`docs/ja/integration.md`、`docs/ja/systems/locomotion.md`、`docs/ja/systems/input.md`（`CharacterActionInput`）、`docs/ja/systems/audio.md`、`docs/ja/systems/characters.md`、`docs/ja/systems/levels.md`（ヒーローのテレポート）。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
