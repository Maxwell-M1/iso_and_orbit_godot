<!-- translation of README.md @ 6853806db277 -->
# Iso & Orbit - Camera and Character Controller Template

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

バージョン 1.1.0 · Godot 4.7（4.7.2でテスト済み） · GDScript · MIT

アイソメトリックやトップダウンのRPG向けの、クリック移動式キャラクターコントローラーとオービットカメラです。地面をクリックすると、主人公は障害物を避けながらそこへ走ります。ボタンを長押しすると、主人公はカーソルを追いかけます。カメラは回転とズームができ、壁にめり込みません。

![クリックで移動、長押しで操縦、カメラの回転とズーム、場所の発見](docs/images/demo.gif)

サードパーティのアセットは使っていません。キャラクターはスクリプトがプリミティブから組み立て、表面の模様はシェーダーで生成してシームレステクスチャにベイクし、サウンドは合成しています。

## はじめに

1. Godot 4.7.2（標準版または.NET版）をインストールします。Jolt Physicsはエンジンに組み込まれているので、追加のインストールは不要です。レンダラーはForward+です。
2. リポジトリをクローンし、プロジェクトマネージャー（Project Manager）で`project.godot`をインポートして開きます。`.godot/`はリポジトリに含まれていないため、最初のインポートには少し時間がかかります。
3. F5を押してデモ（`res://gdscript/main.tscn`）を実行します。

操作方法は画面左上に表示されます。非表示にするには、設定（F10）→ インターフェースを開き、**操作ヒントと速度**をオフにします。インターフェースの言語も同じタブで選べます。

## 操作方法

| 入力 | 動作 |
|---|---|
| 地面を左クリック | その地点へ走る |
| 左ボタンを長押し | カーソルを追って走る |
| 左 + 右ボタン | カメラの向きへ走る。A / Dで斜めに曲がる |
| 右ボタン + マウス | カメラを回す |
| 右ボタン + WASD | カメラ基準で移動 |
| マウスホイール | ズーム：低く近く、または高く遠く |
| Shift | 押している間ダッシュ（設定で切り替え式にもできる） |
| スペース | ジャンプ |
| F10 | 設定を開く（ゲームを一時停止）。EscまたはF10で閉じる |

すべてのモードとその設定：[操作方法](docs/ja/controls.md)。

## 機能

**移動**

- クリックすると、ナビゲーションメッシュに沿ってその地点へ走ります。マーカーが行き先を示します。
- 左ボタンを長押しすると、カーソルを追って走ります。デフォルトではカーソルへ直進して障害物に沿って滑り、オプションでカーソル下の地点までナビゲーション経路に沿って走ります。
- クリックと長押しは0.2秒後に区別されるため、ボタンを長押ししても、押した地点へ主人公が寄り道することはありません。
- 両ボタン同時：カメラの向きへ走ります。右ボタンとWASD：カメラ基準で移動し、前を向いたまま進むか、進む方向へ向きを変えます。
- 一定の加速と減速、行き過ぎのない目標地点ぴったりでの停止、旋回速度の制限、静止状態からの即時旋回。
- スタミナ付きのダッシュ。コヨーテタイムと入力バッファ付きのジャンプ。ジャンプの高さは物理ティックレートによらず同じです。
- 落下防止：段差の縁で主人公は止まるか、壁と同じように縁に沿って滑ります。

**カメラ**

- 右ボタンで回転、ホイールでズーム。距離とピッチは連動します。カメラが近いほど角度が低くなるので、前方が見えます。
- オプションで、走る主人公の背後に回り込み、ピッチを設定した角度へ徐々に合わせます。
- カメラの回転中もカーソルは地面の同じ地点の上にとどまるため、ボタンを押したままでも主人公はぐるぐる回らずに進路を保ちます。
- カメラアーム：カメラは背後の壁、山、屋根で止まり、オプションで障害物が主人公を隠すと寄ります。近づくと主人公は半透明になります。
- 障害物の裏では、主人公は輪郭付きの1つのシルエットとして表示され、手に持った装備はその上に描かれます。

**その他の同梱物**

- 操作、キャラクター、カメラ、表示、インターフェース、サウンドのタブを持つ設定ウィンドウ（F10）。設定は`user://settings.cfg`に保存されます。インターフェースは英語、スペイン語、日本語、ブラジルポルトガル語、ロシア語、トルコ語、簡体字中国語に対応し、その場で切り替えられます。
- ステップ、ジャンプ、着地、ダッシュのキャラクターシグナルと、それらに接続されたサウンド。
- デモレベル：遺跡、野営地、農家、生け垣の迷路、スロープ、らせん状の山道がある山を備えた、柵に囲まれた80 × 80 mの草地。発見できる4つの場所とそこに配置された5人のNPC、選べる10種類の主人公の外見。
- 移動、入力、ジャンプ、ダッシュとサウンド、カメラとそのアーム、主人公の外見、設定ウィンドウと翻訳のヘッドレステスト。さらに、エディターを開かずに全シーンからエディターのノード警告を見つけるスクリプト。

**含まれないもの**：ゲームパッド対応（マウスとキーボードのみ）とアニメーション（モデルは静的なプリミティブです）。

## 全体の構成

```
マウス/WASD ──► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (パスまたは         (加速、ブレーキ、
                                                           方向)               旋回：単純な計算)
                                                               │ 速度
                                                               ▼
Shift, Space ──► CharacterActionInput ──────────────────► GroundCharacter
                                                          (CharacterBody3D: 重力、ジャンプ、ダッシュ、
                                                           move_and_slide、モデルの回転)

マウス ──► OrbitCameraRig ──► CameraArm ──► Camera3D
```

- **ボディを動かすのは`GroundCharacter`だけです**。移動コンポーネントは速度を返すだけで`move_and_slide()`を呼ばないため、重力、ジャンプ、将来のノックバックはすべて1か所でまとめて処理されます。
- **`GroundMotion`はノードを使わない計算です**。単独でテストしやすくなっています。
- **キャラクターはマウスについて何も知りません**。入力ノードは`player.tscn`ではなく`main.tscn`にあります。NPCにするには、プレイヤー専用の`Silhouette`ノードと`Appearance`ノードを除いて`player.tscn`をインスタンス化し、AIから`NavigationMover.move_to()`を呼び出します。
- **コンポーネントは設定について何も知りません**。自身のエクスポートされたプロパティを読むだけです。`Settings`自動読み込み（Autoload）とやり取りするのはデモの`settings_applier.gd`と設定ウィンドウだけなので、コンポーネントはそれらなしで別のプロジェクトへ移せます。

詳細：[アーキテクチャ](docs/ja/architecture.md)。

## プロジェクトへの組み込み

コンポーネントは`addons/iso_orbit/`にあり、パーツごとに1つのフォルダになっています。必要なものを自分のプロジェクトの同じフォルダへコピーしてください。

| アドオン | 提供するもの |
|---|---|
| `orbit_camera` | オービットカメラとそのアーム。任意の`Node3D`ターゲットで動作 |
| `click_to_move` | クリックと長押しによるナビゲーションメッシュ上の移動、ステア、クリックマーカー |
| `ground_character` | 完成済みのボディ：重力、ジャンプ、スタミナ付きダッシュ、落下防止、ステップシグナル、サウンド、手の振り、切り替え可能なモデル（`click_to_move`が必要） |
| `occluded_silhouette` | 障害物の裏のキャラクターのシルエット |
| `points_of_interest` | 発見できる場所と、その通知メッセージ |
| `ui_screens` | ゲームを一時停止するウィンドウのスタックと、FPSカウンター |

移動は連鎖で成り立っています。入力が`NavigationMover`に命令を出し、ムーバーは速度を計算するだけなので、ムーバーが属するボディが物理ティックごとにその速度を適用します。`GroundCharacter`は完成済みのボディです。最小限のボディは次のようになります。

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

`mover.move_to(point)`や`mover.steer(direction)`は、独自の入力、AI、ネットワークコードなど、どこからでも呼び出せます。各アドオンに必要なものは[プロジェクトへの組み込み](docs/ja/integration.md)に、コンポーネントが`project.godot`に求める物理レイヤー、入力アクション、グループは[プロジェクトのセットアップ](docs/ja/project-setup.md)に記載しています。

## ドキュメント

- **スタート**：[はじめに](docs/ja/getting-started.md) · [操作方法](docs/ja/controls.md) · [設定](docs/ja/settings.md)
- **コード**：[アーキテクチャ](docs/ja/architecture.md) · [プロジェクトへの組み込み](docs/ja/integration.md) · [プロジェクトのセットアップ](docs/ja/project-setup.md)
- **システム**：[ロコモーション](docs/ja/systems/locomotion.md) · [カメラ](docs/ja/systems/camera.md) · [入力](docs/ja/systems/input.md) · [キャラクター](docs/ja/systems/characters.md) · [オーディオ](docs/ja/systems/audio.md) · [UI](docs/ja/systems/ui.md) · [ワールドとナビゲーション](docs/ja/systems/world-and-navigation.md)
- **保守**：[テスト](docs/ja/testing.md) · [既知の問題](docs/ja/known-issues.md) · [用語集](docs/ja/glossary.md) · [ロードマップ](docs/ja/roadmap.md)

## リポジトリの構成

| フォルダ | 内容 |
|---|---|
| `addons/iso_orbit/` | コンポーネント。単独で取り出せるパーツごとに1つのフォルダ |
| `gdscript/` | それらを組み立てるデモ：`main.tscn`、主人公、設定システムと設定ウィンドウ |
| `shared/` | GDScript版のデモと将来のC#版で共有するためのデモコンテンツ：レベル、キャラクターと装備、ワールドのシェーダーとテクスチャ、サウンド、UIテーマ。レベルで使う小さなGDScriptスクリプト2つもここにあります |
| `l10n/` | インターフェースの翻訳（gettext `.po`） |
| `tests/` | ヘッドレステスト |
| `docs/` | ドキュメント |

## テスト

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

ここで`godot`はGodot 4.7.2の実行ファイルです。Windowsでは、出力を表示して終了コードを得るために`_console.exe`版を使ってください。一部のスイートだけを実行するには、`--`の後に名前の一部を付け加えます（例：`-- camera input`）。いずれかのチェックが失敗すると、終了コードは1になります。詳細：[テスト](docs/ja/testing.md)。

## ロードマップ

- `csharp/`にC#の例。同じコンポーネントと、`shared/world/world.tscn`の上に構築したメインシーンを備えます。
- アニメーション：`NavigationMover.get_speed()`から`AnimationTree`の待機/走行ブレンドを制御します。

## ライセンス

MIT。[LICENSE](LICENSE)を参照してください。例外：`icon.svg`（Andrea CalabróによるGodotロゴ、CC BY 4.0）。

---

*このページは Iso & Orbit 1.1.0 に対応しています。*
