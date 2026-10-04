<!-- translation of docs/en/roadmap.md @ 6c3e4efdec59 -->
# ロードマップ

> これは[英語の原文](../en/roadmap.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

予定している作業です（順不同）。ここに挙げたものは、まだ何も実装されていません。

- **GDScriptを使わない`shared/`**。レベルは`addons/iso_orbit/points_of_interest/point_of_interest.gd`で場所を示しており、2つのプロップ用スクリプトが`shared/world/props/`にあります。これらをC#版でも使える形にする必要があります。[既知の問題](known-issues.md#プロジェクトファイル)を参照してください。
- **C#の例**。`csharp/`に、同じコンポーネントと、`shared/world/world.tscn`の上に構築したメインシーンを用意します。C#版のグローバルクラス名は、GDScriptのものと異なる必要があります。`class_name`と`[GlobalClass]`は1つの名前空間を共有するためです。
- **アニメーション**。リグ付きのモデルと、`GroundCharacter`が通知するもので駆動する`AnimationTree`：待機、走行、ダッシュのブレンドには`get_locomotion_blend()`または`get_local_movement()`、走行サイクルを地面に合わせるには`get_gait_cycle()`、ジャンプと着地には状態と床のシグナルを使います。

---

*このページは Iso & Orbit 1.1.0 に対応しています。*
