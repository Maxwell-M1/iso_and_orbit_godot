<!-- translation of addons/iso_orbit/levels/README.md @ 8dd533b32064 -->
# レベル

[← ドキュメント目次（テンプレートリポジトリ）](../../../docs/ja/index.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版を参照してください。

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

プレイヤーのキャラクターとインターフェースを残したまま、ローディング画面の背後でレベルを切り替えるためのアドオンです。レベルホストが次のレベルをバックグラウンドで読み込み、古いレベルを解放し、キャラクターの配置先をゲームへ通知します。確認してから、または即座に別のレベルへ移動するポータル、スポーン地点、直前のゲーム画面をぼかした背景に場所の名前、進捗バー、ヒントを重ねるローディング画面も含みます。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `level_host.gd` | `LevelHost`（Node3D） | 現在のレベルを保持する。`change_level(path, spawn_name, title)`は次のレベルをバックグラウンドで読み込み、入れ替え、各段階をシグナルで通知する。現在のレベルのポータルから来る移動者の出入りを、後から追加されたポータルも含めて`portal_entered`と`portal_exited`として再通知する |
| `level_portal.gd` | `LevelPortal`（Area3D） | 別のレベルへの入口。移動者の出入りを通知し、`travel()`または自動移動（`auto_travel`）で移動する。任意の看板に`title`を書き込む |
| `spawn_point.gd` | `SpawnPoint`（Marker3D） | 名前で指定するキャラクターの出現位置。マーカーの−Z方向を向く |
| `loading_screen.gd`、`loading_screen.tscn`、`loading_background.gdshader`、`loading_screen_theme.tres` | `LoadingScreen`（CanvasLayer） | レベル読み込み中の画面。直前のフレームをぼかして暗くし、ゆっくり拡大し、場所の名前、後戻りしない進捗バー、ヒントを示す。表示中は入力イベントがゲームへ届かない |

ほかのアドオンは不要です。レベルホストはキャラクター、カメラ、インターフェースを知りません。ゲーム側でそのシグナルに接続します。

## セットアップ

1. このフォルダを`res://addons/iso_orbit/levels/`へコピーします。
2. 常駐するメインシーンに`level_host.gd`を付けた`Node3D`を追加し、開始レベルを唯一の子にします。プレイヤーのキャラクター、カメラ、インターフェースはホストの隣に配置し、レベルの中には入れません。
3. メインシーンに`loading_screen.tscn`を追加し、ホストの`loading_screen`に設定します。空のままなら画面なしでレベルを切り替えます。
4. すべてのレベルで、`spawn_point.gd`を付けた`Marker3D`を地面上に置き、`spawn_name`を`default`にします。ポータルの到着先には別の名前を付けた地点も追加します。
5. ポータルには`level_portal.gd`を付けた`Area3D`とコリジョンシェイプを追加します。`collision_mask`にはキャラクターのレイヤーを含めます。`target_level`（シーンファイル）、`target_spawn`、`title`を設定します。キャラクターのボディを`player`グループに入れるか、`traveller_group`を変更します。
6. メインスクリプトでホストのシグナルを接続します。
   - `level_change_started`：ローディング画面に写したくないものを隠し、操作を無効にします。
   - `level_loaded(level, spawn)`：キャラクターを`spawn`へ配置し（`GroundCharacter.teleport()`なら急なずれが生じません）、カメラを回します。
   - `level_change_finished`：操作を戻します。
   - `level_change_failed(path, error)`：操作を戻して隠したものを表示します。現在のレベルは残ります。読み込み失敗後はこのシグナルだけが来て、`level_change_finished`は来ません。
   - `portal_entered(portal)`と`portal_exited(portal)`：移動の案内を表示・非表示にします。確定時には`portal.travel()`を呼びます。

ホストは開始レベルを通知しません。メインスクリプトの`_ready()`で`get_current_level()`と`find_spawn_point()`を使って準備します。

ポータルのデフォルトでは、ゲームがまず案内を表示して`travel()`を呼びます。`auto_travel`をオンにすると、ドアやマップ端のようにキャラクターが入った時点で移動します。切り替えは要求の直後に始まり、要求の実行中には始まらないため、物理コールバックからも要求できます。読み込みと入れ替えの間はゲームが一時停止します。ホストは一時停止のままナビゲーションマップに新しいレベルが入るまで待ち、再開後にローディング画面の背後で数フレーム描画してシェーダーを見えないところでコンパイルし、その後に画面を消します。ホストの設定は`min_loading_time`（0.6秒、画面の最短表示時間）、`warmup_frames`（3、画面の背後で描画するフレーム数）、`navigation_timeout`（2秒、マップを待つ最長時間）です。`is_changing()`で切り替え中か確認できます。切り替え中の`change_level()`は`ERR_BUSY`、不正なファイルには`ERR_FILE_NOT_FOUND`または`ERR_INVALID_PARAMETER`を返します。後から読み込みに失敗した場合は現在のレベルが残り、`level_change_failed`が届きます。次の要求ではファイルを再読み込みします。ホストが終わらせるのは自身で開始した一時停止だけです。ゲームを一時停止するウィンドウは`level_change_finished`の後で開きます。画面と待機時間は`Engine.time_scale`に関係なく実時間で進みます。

ローディング画面の見た目は`loading_screen_theme.tres`（タイプバリエーション`LoadingTitle`、`LoadingBar`、`LoadingTip`）にあります。別の見た目には画面のルートへ別のテーマを与えるか、`loading_screen.tscn`をコピーして独自の画面を作ります。スクリプトには`Root`と、ユニーク名で参照できる`Background`、`Title`、`Bar`、`Tip`が必要です。`tips`に追加するまでヒントは表示されません。各ヒントは翻訳され、コードで設定した`tip_format`に渡されます（`ui_screens`アドオンの`InputNames.format`は現在割り当てられたキーを埋め込み、`{sprint}`を「Shift」と表示します）。

## ドキュメント

テンプレートリポジトリ：`docs/ja/systems/levels.md`と`docs/ja/integration.md`。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
