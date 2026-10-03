<!-- translation of docs/en/roadmap.md @ 8e61c7584e54 -->
# ロードマップ

> これは[英語の原文](../en/roadmap.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

予定している作業です（順不同）。ここに挙げたものは、まだ何も実装されていません。

- **GDScriptを使わない`shared/`**。レベルは`addons/iso_orbit/points_of_interest/point_of_interest.gd`で場所を示しており、2つのプロップ用スクリプトが`shared/world/props/`にあります。これらをC#版でも使える形にする必要があります。[既知の問題](known-issues.md#プロジェクトファイル)を参照してください。
- **C#の例**。`csharp/`に、同じコンポーネントと、`shared/world/world.tscn`の上に構築したメインシーンを用意します。C#版のグローバルクラス名は、GDScriptのものと異なる必要があります。`class_name`と`[GlobalClass]`は1つの名前空間を共有するためです。
- **アニメーション**。`NavigationMover.get_speed()`から`AnimationTree`の待機/走行ブレンドを制御し、歩行サイクルを`GroundCharacter.get_step_phase()`（足音がすでに従っているリズム）に合わせます。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
