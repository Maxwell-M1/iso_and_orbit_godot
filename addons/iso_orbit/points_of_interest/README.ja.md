<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 70ad45747177 -->
# ポイント・オブ・インタレスト

[← ドキュメント目次（テンプレートのリポジトリ）](../../../docs/ja/index.md)

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

発見する場所です。プレイヤーが初めて入ったときに通知するエリアと、すべての場所を自動で見つける画面上のメッセージ「発見：…」で構成されます。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest`（Area3D） | `player`グループのボディが初めて入ったときに`discovered(title)`を発信し、`points_of_interest`グループに加わる。`is_discovered()`は発見済みか返し、`mark_discovered()`はシグナルなしで発見済みにする（再読み込みしたレベルやセーブデータに使う） |
| `discovery_toast.gd`、`discovery_toast.tscn` | `DiscoveryToast`（Label） | 場所の発見時に「発見：…」を数秒間表示する。後から読み込まれたレベルの場所にも対応する（`watch_added_places`をオフにすると起動時にあった場所のみ） |

ほかのアドオンは必要ありません。

## セットアップ

1. このフォルダーを`res://addons/iso_orbit/points_of_interest/`にコピーします。
2. プレイヤーのボディを`player`グループに入れます（または`player_group`を設定します）。
3. 場所ごとに、`point_of_interest.gd`とコリジョンシェイプを持つ`Area3D`を追加して`title`を設定し、その`collision_mask`にプレイヤーの物理レイヤーを含めます。
4. `discovery_toast.tscn`をHUDに追加します。起動時にシーン内の全場所へ接続し、`watch_added_places`がオフでなければ後から追加した場所にも接続します。配線は不要です。

発見したことを場所が記憶するのは、そのノードが存在する間だけです。レベルを解放すると場所も消え、同じレベルを再読み込みすると未発見に戻ります。記憶はゲーム側の責任です。テンプレートの`gdscript/main.gd`はレベルごとに発見済みの場所を保ち、再読み込み時に`mark_discovered()`を呼びます。

メッセージのテキストとタイトルは翻訳サーバーを通るので、ローカライズできます。見た目はテーマタイプバリエーション`DiscoveryToast`から取られます。

## ドキュメント

テンプレートリポジトリ：`docs/ja/systems/world-and-navigation.md`、`docs/ja/systems/ui.md`、`docs/ja/systems/levels.md`。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
