<!-- translation of addons/iso_orbit/ui_screens/README.md @ b7618a65d4df -->
# UI画面

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

ゲームの上に重なるウィンドウをスタックとして扱います。ウィンドウを別のウィンドウの上に開き、Escで最前面のウィンドウを閉じ、ウィンドウが1つでも開いている間はゲームを一時停止してマウスカーソルを表示し、ウィンドウにキーボードフォーカスを与え、閉じたときに元に戻します。さらに、ゲームの一時停止中も動作し続けるFPSカウンターもあります。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `ui_root.gd` | `UiRoot`（CanvasLayer） | ウィンドウのスタック：`open()`、`close_top()`、`toggle()`。一時停止、カーソル、フォーカス |
| `ui_screen.gd` | `UiScreen`（Control） | ウィンドウの基底：`initial_focus`、`close_requested`シグナル |
| `fps_counter.gd`、`fps_counter.tscn` | `FpsCounter`（Label） | 毎秒のフレーム数。一時停止中も表示する |

ほかのアドオンは必要ありません。

## セットアップ

1. このフォルダーを`res://addons/iso_orbit/ui_screens/`にコピーします。
2. `ui_root.gd`を付けた`CanvasLayer`をメインシーンに追加します。これはゲームの一時停止中も動作します。
3. 各ウィンドウを、ルートが`UiScreen`を継承するシーンとして作ります。ウィンドウが自分で閉じることはありません。`request_close()`を呼び、`UiRoot`がそれを閉じます。
4. ウィンドウは`UiRoot.open(scene)`で開きます。キーでウィンドウを開くには、`settings_screen`にそのシーンを設定し、入力アクション`toggle_settings`を追加します（または`settings_action`を設定します）。Escは組み込みの`ui_cancel`です。
5. 任意：`fps_counter.tscn`をHUDに追加します。

見た目はプロジェクトのテーマから取られます。`FpsCounter`はテーマタイプバリエーション`FpsCounter`を使います。

## ドキュメント

テンプレートのリポジトリ内：`docs/ja/systems/ui.md`。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
