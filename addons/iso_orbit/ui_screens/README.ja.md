<!-- translation of addons/iso_orbit/ui_screens/README.md @ f510902e02d8 -->
# UI画面

[← ドキュメント目次（テンプレートのリポジトリ）](../../../docs/ja/index.md)

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

ゲーム上のウィンドウをスタックとして扱います。重ねて開き、Escで最前面を閉じ、1つでも開いている間はゲームを一時停止してカーソルを表示し、キーボードフォーカスをウィンドウへ渡して閉じたら戻します。さらに、一時停止中も動くFPSカウンターと、画面の文に現在割り当てられたキー名を埋め込む機能があります。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `ui_root.gd` | `UiRoot`（CanvasLayer） | ウィンドウのスタック：`open()`、`close_top()`、`toggle()`。一時停止、カーソル、フォーカス |
| `ui_screen.gd` | `UiScreen`（Control） | ウィンドウの基底：`initial_focus`、`close_requested`シグナル |
| `fps_counter.gd`、`fps_counter.tscn` | `FpsCounter`（Label） | 毎秒のフレーム数。一時停止中も表示する |
| `input_names.gd` | `InputNames`（RefCounted、static） | プレイヤーの配列と翻訳に従うアクションのキー名・マウスボタン名。`of_action()`、`of_event()`。`format()`は`{sprint}`などのトークンを文中で置き換える |
| `action_texts.gd` | `ActionTexts`（Node） | 親ノードの下にあるコントロールの文中トークンを埋め、言語変更時や`refresh()`で更新する |

ほかのアドオンは必要ありません。

## セットアップ

1. このフォルダーを`res://addons/iso_orbit/ui_screens/`にコピーします。
2. `ui_root.gd`を付けた`CanvasLayer`をメインシーンに追加します。これはゲームの一時停止中も動作します。
3. 各ウィンドウを、ルートが`UiScreen`を継承するシーンとして作ります。ウィンドウが自分で閉じることはありません。`request_close()`を呼び、`UiRoot`がそれを閉じます。
4. ウィンドウは`UiRoot.open(scene)`で開きます。キーで開くには`settings_screen`にそのシーンを設定し、入力アクション`toggle_settings`を追加します（または`settings_action`を設定）。欠けていれば`UiRoot`は開始時に一度報告し、キーは効きません。Escは組み込みの`ui_cancel`です。
5. 任意：`fps_counter.tscn`をHUDに追加します。
6. 任意：`{jump} — jump`のように文中にアクショントークンを書き、シーンに`ActionTexts`ノードを追加します（その親の下のコントロールを処理します）。キーを変更した後は`get_tree().call_group(ActionTexts.GROUP, &"refresh")`を呼びます。自身で文章を作るコントロールも`refresh()`を実装して同じグループに加われます。マウスボタン、「Space」、未割り当てアクションを多言語で表示するには、翻訳に`InputNames.get_mouse_names()`の名前、「Space」、`InputNames.UNBOUND`、`InputNames.LEFT_KEY`、`InputNames.RIGHT_KEY`を登録します。最後の2つはキー名用の`%s`を保ちます。

`UiRoot`は実行中のゲームだけを一時停止し、自分で始めた一時停止だけを終わらせます。レベル切り替えなどですでに停止していれば、元の処理が停止を管理します。その処理が解除すると、ウィンドウの背後でゲームは再開します。

見た目はプロジェクトのテーマから取られます。`FpsCounter`はテーマタイプバリエーション`FpsCounter`を使います。

## ドキュメント

テンプレートリポジトリ：`docs/ja/systems/ui.md`、およびレベル切り替え中のウィンドウについては`docs/ja/systems/levels.md`。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
