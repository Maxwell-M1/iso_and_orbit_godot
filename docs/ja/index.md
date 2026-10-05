<!-- translation of docs/en/index.md @ 0499e77e2e07 -->
# ドキュメント

[English](../en/index.md) · [Español](../es/index.md) · **日本語** · [Português (Brasil)](../pt_BR/index.md) · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · [简体中文](../zh_CN/index.md)

> これは[英語の原文](../en/index.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

Godot 4.7でアイソメトリックやトップダウンのRPGを作るための、クリック移動式キャラクターコントローラーとオービットカメラ、そして2つのデモレベルです。概要は[README](../../README.ja.md)から読み始めてください。

英語のドキュメントが原文です。翻訳はそれに従いますが、更新が遅れることがあります。内容が異なる場合は、英語のページが正しいものとします。

## 最初に動く状態まで組み込む

1. [デモを実行する](getting-started.md)で標準の操作を試します。
2. [ヒーローを移植する](integration.md#デモのヒーローを自分のプロジェクトへ移植する)で、自分のプロジェクトに小さなレベルを作って配置します。キャラクターを変更する前に、ファイル一覧、Input Map、ナビゲーションの手順を終えてください。
3. [構成を選ぶ](configurations.md)で、手動オービット、経路に沿うマウス移動、移動方向に追従するカメラを比較します。
4. [移動](systems/locomotion.md)、[入力](systems/input.md)、[カメラ](systems/camera.md)の参照を使って個々のプロパティを調整します。[キャラクター](systems/characters.md)にはモデルの交換とアニメーションの追加方法があります。

## ドキュメントメニュー

以下からページを選んでください。システムの説明の後に、アドオンのセットアップガイドもあります。

### スタート

- [はじめに](getting-started.md)：動作要件、プロジェクトの開き方、デモの内容。
- [操作方法](controls.md)：すべての入力、クリックと長押しの違い、右ボタンと組み合わせるキー、カメラ。
- [設定](settings.md)：設定ウィンドウの全項目について、そのキー、デフォルト値、変更される内容。
- [ヒーローの構成](configurations.md)：値の供給元、正確なノードパス、3つの一貫した構成と確認方法。

### コード

- [アーキテクチャ](architecture.md)：メインシーン、1回の物理ティックでのデータの流れ、コンポーネントと、それらをこのように分けた理由。
- [プロジェクトへの組み込み](integration.md)：アドオンとそれぞれに必要なもの、カメラ単体での使用、クリック移動、独自のボディ、NPC。
- [プロジェクトのセットアップ](project-setup.md)：コンポーネントが前提とする物理レイヤー、入力アクション、グループ、プロジェクト設定。

### システム

- [ロコモーション](systems/locomotion.md)：`LocomotionSettings`、`GroundMotion`、`NavigationMover`、`GroundCharacter`、アニメーションとインターフェースのためにキャラクターが通知すること、`CharacterMonitor`、階段と斜面、ダッシュとスタミナ、ジャンプ、落下（`FallSettings`）、崖ガード。
- [カメラ](systems/camera.md)：`OrbitCameraRig`（回転、ズームカーブ、追従）と`CameraArm`（障害物、接近、フェード）。
- [入力](systems/input.md)：`PointClickMoveInput`（クリック、長押し、キー、カーソル）と`CharacterActionInput`。
- [キャラクター](systems/characters.md)：モデルと装備、ヒーローの外見、手の揺れ、浮遊、シルエット。
- [オーディオ](systems/audio.md)：キャラクターのサウンドとその合成方法。
- [UI](systems/ui.md)：ウィンドウ、設定システムと設定ウィンドウ、HUD、テーマ、翻訳。
- [ワールドとナビゲーション](systems/world-and-navigation.md)：レベル、場所、表面とベイク済みテクスチャ、山、ナビゲーションメッシュとその再ベイク方法。
- [レベル](systems/levels.md)：ゲーム全体のシーン、レベルホストとローディング画面、ポータルとスポーン地点、操作するヒーロー、島。

### アドオンのセットアップガイド

- [クリック移動](../../addons/iso_orbit/click_to_move/README.ja.md)
- [地上キャラクター](../../addons/iso_orbit/ground_character/README.ja.md)
- [オービットカメラ](../../addons/iso_orbit/orbit_camera/README.ja.md)
- [遮蔽物越しのシルエット](../../addons/iso_orbit/occluded_silhouette/README.ja.md)
- [注目ポイント](../../addons/iso_orbit/points_of_interest/README.ja.md)
- [UIウィンドウ](../../addons/iso_orbit/ui_screens/README.ja.md)
- [レベル切り替え](../../addons/iso_orbit/levels/README.ja.md)

### 保守

- [テスト](testing.md)：実行方法、各スイートの対象範囲、チェックの書き方。
- [既知の問題](known-issues.md)：制限事項とエンジンの癖、およびその対処法。
- [用語集](glossary.md)：コードとドキュメントで使う用語。
- [ロードマップ](roadmap.md)：予定している作業。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
