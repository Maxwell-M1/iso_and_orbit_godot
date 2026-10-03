<!-- translation of docs/en/index.md @ ac381bae4d1d -->
# ドキュメント

[English](../en/index.md) · [Español](../es/index.md) · **日本語** · [Português (Brasil)](../pt_BR/index.md) · [Русский](../ru/index.md) · [Türkçe](../tr/index.md) · [简体中文](../zh_CN/index.md)

> これは[英語の原文](../en/index.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

Godot 4.7でアイソメトリックやトップダウンのRPGを作るための、クリック移動式キャラクターコントローラーとオービットカメラ、そしてデモレベルです。概要は[README](../../README.ja.md)から読み始めてください。

英語のドキュメントが原文です。翻訳はそれに従いますが、更新が遅れることがあります。内容が異なる場合は、英語のページが正しいものとします。

## スタート

- [はじめに](getting-started.md)：動作要件、プロジェクトの開き方、デモの内容。
- [操作方法](controls.md)：すべての入力、クリックと長押しの違い、右ボタンと組み合わせるキー、カメラ。
- [設定](settings.md)：設定ウィンドウの全項目について、そのキー、デフォルト値、変更される内容。

## コード

- [アーキテクチャ](architecture.md)：メインシーン、1回の物理ティックでのデータの流れ、コンポーネントと、それらをこのように分けた理由。
- [プロジェクトへの組み込み](integration.md)：アドオンとそれぞれに必要なもの、カメラ単体での使用、クリック移動、独自のボディ、NPC。
- [プロジェクトのセットアップ](project-setup.md)：コンポーネントが前提とする物理レイヤー、入力アクション、グループ、プロジェクト設定。

## システム

- [ロコモーション](systems/locomotion.md)：`LocomotionSettings`、`GroundMotion`、`NavigationMover`、`GroundCharacter`、ダッシュとスタミナ、ジャンプ、落下防止。
- [カメラ](systems/camera.md)：`OrbitCameraRig`（回転、ズームカーブ、追従）と`CameraArm`（障害物、接近、フェード）。
- [入力](systems/input.md)：`PointClickMoveInput`（クリック、長押し、キー、カーソル）と`CharacterActionInput`。
- [キャラクター](systems/characters.md)：モデルと装備、主人公の外見、手の振り、シルエット。
- [オーディオ](systems/audio.md)：キャラクターのサウンドとその合成方法。
- [UI](systems/ui.md)：ウィンドウ、設定システムと設定ウィンドウ、HUD、テーマ、翻訳。
- [ワールドとナビゲーション](systems/world-and-navigation.md)：レベル、場所、表面とベイク済みテクスチャ、山、ナビゲーションメッシュとその再ベイク方法。

## 保守

- [テスト](testing.md)：実行方法、各スイートの対象範囲、チェックの書き方。
- [既知の問題](known-issues.md)：制限事項とエンジンの癖、およびその対処法。
- [用語集](glossary.md)：コードとドキュメントで使う用語。
- [ロードマップ](roadmap.md)：予定している作業。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
