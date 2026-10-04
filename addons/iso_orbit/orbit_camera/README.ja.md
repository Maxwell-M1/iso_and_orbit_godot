<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 6c214bf8ea42 -->
# オービットカメラ

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

アイソメトリックやトップダウンのゲーム向けのオービットカメラです。ターゲットを追い、マウスの右ボタンで回転し、ホイールでズームし（距離とピッチが連動して変わる）、走るターゲットの背後へ自動で回り込むこともできます。カメラはアームの先端にあり、アームは背後の壁で止まり、障害物がターゲットを隠すとカメラを寄せることもできます。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | クラス | 役割 |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig`（Node3D） | ターゲットの追従、回転、ズーム、追従モード |
| `camera_arm.gd` | `CameraArm`（Node3D） | カメラを保持し、障害物で縮む。近づくとターゲットをフェードさせる |

ほかのアドオンは必要ありません。

## セットアップ

1. このフォルダーを`res://addons/iso_orbit/orbit_camera/`にコピーします。
2. 入力アクションを追加します（名前はエクスポートされたプロパティなので、独自の名前も使えます）：`camera_rotate`（マウスの右ボタン）、`camera_zoom_in`（ホイール上）、`camera_zoom_out`（ホイール下）。
3. カメラをターゲットの中ではなく隣に組み立てます。

   ```
   CameraRig    orbit_camera_rig.gd付きのNode3D、target = 自分のキャラクター
   └── CameraArm    camera_arm.gd付きのNode3D
       └── Camera3D
   ```

4. 物理レイヤー：アームはレイヤー1と3のボディで止まります（`collision_mask`）。レベルのジオメトリはどちらかに置き、キャラクターはそれらに置かないでください。`camera_ignore`グループに属するボディ（またはそのグループのノードの下にあるボディ）がアームを止めることはありません。
5. ターゲットが物理ティックで動く場合は、プロジェクトで物理補間をオンにしてください。リグはターゲットの補間された位置を追います。

アームなしで、リグの子に`Camera3D`を置いても動作します。その場合、カメラはズームで設定された距離にとどまり、壁を突き抜けます。

## ドキュメント

テンプレートのリポジトリ内：`docs/ja/systems/camera.md`（全プロパティ、ズームカーブ、追従モード、アームの仕組み）と`docs/ja/project-setup.md`。

---

*このページは Iso & Orbit 1.1.0 に対応しています。*
