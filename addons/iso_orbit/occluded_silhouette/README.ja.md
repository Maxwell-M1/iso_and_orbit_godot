<!-- translation of addons/iso_orbit/occluded_silhouette/README.md @ ed5707ab8355 -->
# 遮蔽時のシルエット

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

キャラクターを隠しているものを透かして、キャラクターを表示します。体は1つの平坦な形、手に持ったアイテムはその上に輪郭付きで描かれ、全体の周りに縁取りが付きます。キャラクターが見えている場所には何も描かれません。モデル自身のマテリアルには手を加えないので、ほかの場所にある同じモデルにはシルエットが出ません。

Godot 4.7用のカメラとキャラクターコントローラーのテンプレート、Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。

## 内容

| ファイル | 役割 |
|---|---|
| `occluded_silhouette.gd` | `OccludedSilhouette`（Node）：後から追加されたメッシュも含め、モデルのすべてのメッシュに`material_overlay`としてパスを設定する |
| `silhouette_mask.gdshader`、`.tres` | キャラクター自身が見えている場所に印を付ける |
| `silhouette_body.gdshader`、`.tres` | 体の平坦な塗りつぶし |
| `silhouette_gear.gdshader`、`.tres` | 手に持ったアイテムの明るめの塗りつぶし |
| `silhouette_outline.gdshader`、`.tres` | 形全体の周りの縁取り |
| `silhouette_common.gdshaderinc` | 共通コード：メートル単位の深度、ステンシルの割り当て |

ほかのアドオンは必要ありません。

## セットアップ

1. このフォルダーを`res://addons/iso_orbit/occluded_silhouette/`にコピーします。マテリアルはそのパスでシェーダーを参照しています。
2. `occluded_silhouette.gd`を付けた`Node`をキャラクターに追加します。`target`にモデルを保持するノードを設定し、`mask`、`body_fill`、`gear_fill`、`outline`にそれぞれ`silhouette_mask.tres`、`silhouette_body.tres`、`silhouette_gear.tres`、`silhouette_outline.tres`を割り当てます。
3. `gear_nodes`に名前を挙げたノード（`RightHand`、`LeftHand`）の下にあるメッシュは、手に持ったアイテムとして扱われます。

色はマテリアルの`color`パラメーター、縁取りの幅は`silhouette_outline.tres`の`width`で、`outline_enabled`で縁取りをオフにできます。シルエットが出るには、キャラクターの少なくとも30 cm手前に障害物が必要です（`min_gap`）。

Godot 4.5以降で実験的機能であるステンシルバッファを使います。Forward+レンダラーでテストしています。

## ドキュメント

テンプレートのリポジトリ内：`docs/ja/systems/characters.md`。

---

*このページは Iso & Orbit 1.1.0 に対応しています。*
