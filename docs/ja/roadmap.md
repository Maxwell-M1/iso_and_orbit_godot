<!-- translation of docs/en/roadmap.md @ 785e0b204d0a -->
# ロードマップ

[← ドキュメント目次](index.md)

> これは[英語の原文](../en/roadmap.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

予定している作業です（順不同）。ここに挙げたものは、まだ何も実装されていません。

- **GDScriptを使わない`shared/`。** レベルはコンポーネントのスクリプト（`point_of_interest.gd`、`spawn_point.gd`、`level_portal.gd`）で場所、スポーン地点、ポータルを示し、`shared/world/props/`には小道具用のスクリプトが2つあります。C#版でも使える形が必要です。[既知の問題](known-issues.md#プロジェクトファイル)を参照してください。
- **C#の例。** `csharp/`に同じコンポーネントと、`shared/world/`のレベルをつなぐゲーム全体のシーンを用意します。C#版のグローバルクラス名はGDScript版と異なる必要があります。`class_name`と`[GlobalClass]`は同じ名前空間を共有するためです。
- **アニメーション**。リグ付きのモデルと、`GroundCharacter`が通知するもので駆動する`AnimationTree`：待機、走行、ダッシュのブレンドには`get_locomotion_blend()`または`get_local_movement()`、走行サイクルを地面に合わせるには`get_gait_cycle()`、ジャンプと着地には状態と床のシグナルを使います。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
