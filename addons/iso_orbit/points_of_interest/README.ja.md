<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 4bf86f099c43 -->
# ポイント・オブ・インタレスト

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

発見する場所です。プレイヤーが初めて入ったときに通知するエリアと、すべての場所を自動で見つける画面上のメッセージ「発見：…」で構成されます。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest`（Area3D） | `player`グループのボディが初めて入ったときに`discovered(title)`を発信する。`points_of_interest`グループに加わる |
| `discovery_toast.gd`、`discovery_toast.tscn` | `DiscoveryToast`（Label） | いずれかの場所が発見されると、「発見：…」を数秒間表示する |

ほかのアドオンは必要ありません。

## セットアップ

1. このフォルダーを`res://addons/iso_orbit/points_of_interest/`にコピーします。
2. プレイヤーのボディを`player`グループに入れます（または`player_group`を設定します）。
3. 場所ごとに、`point_of_interest.gd`とコリジョンシェイプを持つ`Area3D`を追加して`title`を設定し、その`collision_mask`にプレイヤーの物理レイヤーを含めます。
4. `discovery_toast.tscn`をHUDに追加します。起動時にシーン内のすべての場所に接続するので、配線は必要ありません。

メッセージのテキストとタイトルは翻訳サーバーを通るので、ローカライズできます。見た目はテーマタイプバリエーション`DiscoveryToast`から取られます。

## ドキュメント

テンプレートのリポジトリ内：`docs/ja/systems/world-and-navigation.md`と`docs/ja/systems/ui.md`。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
