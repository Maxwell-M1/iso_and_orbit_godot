<!-- translation of addons/iso_orbit/occluded_silhouette/README.md @ af038a43f7c2 -->
# Engel Arkası Siluet

[← Belge dizini (şablon deposu)](../../../docs/tr/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Bir karakteri, onu gizleyen her şeyin ardından gösterir: gövde tek bir düz şekil olarak, ellerindeki nesneler üstte
kendi hatlarıyla ve her şeyin çevresinde bir kontur. Karakterin görünür olduğu yerde hiçbir şey çizilmez. Modelin
kendi malzemelerine dokunulmaz; bu yüzden aynı modelin başka yerlerde silueti olmaz.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Görev |
|---|---|
| `occluded_silhouette.gd` | `OccludedSilhouette` (Node): geçişleri, sonradan eklenenler dahil modelin her örgüsüne `material_overlay` olarak koyar |
| `silhouette_mask.gdshader`, `.tres` | Karakterin kendisinin görünür olduğu yeri işaretler |
| `silhouette_body.gdshader`, `.tres` | Düz gövde dolgusu |
| `silhouette_gear.gdshader`, `.tres` | Eldeki nesnelerin daha açık dolgusu |
| `silhouette_outline.gdshader`, `.tres` | Bütün şeklin çevresindeki kontur |
| `silhouette_common.gdshaderinc` | Ortak kod: metre cinsinden derinlik, stencil düzeni |

Başka bir eklenti gerekmez.

## Kurulum

1. Bu klasörü `res://addons/iso_orbit/occluded_silhouette/` konumuna kopyalayın; malzemeler gölgelendiricilere bu
   yolla başvurur.
2. Karaktere `occluded_silhouette.gd` betikli bir `Node` ekleyin. `target` özelliğine modeli tutan düğümü
   (sağlanan kahramanda `Character/Visual`) atayın
   ve `silhouette_mask.tres`, `silhouette_body.tres`, `silhouette_gear.tres` ve `silhouette_outline.tres` dosyalarını
   `mask`, `body_fill`, `gear_fill` ve `outline` özelliklerine atayın.
3. `gear_nodes` içinde adı geçen düğümlerin (`RightHand`, `LeftHand`) altındaki örgüler eldeki nesne sayılır.
   Bu düğümler yoksa bütün örgüler gövde dolgusunu alır; ekipmanın hiyerarşisi farklıysa adları değiştirin.

Renkler malzemelerin `color` parametreleridir, kontur genişliği `silhouette_outline.tres` içindeki `width` değeridir
ve `outline_enabled` konturu kapatır. Siluet için karakterin en az 30 cm önünde bir engel gerekir
(`min_gap`: `silhouette_common.gdshaderinc` dosyasından gelen gövde, ekipman ve kontur malzemelerinin parametresi;
üçünde de değiştirin).

Bileşen, görünüm değişince sonradan eklenen örgüler dahil her örgünün `material_overlay` özelliğini atar. Modeliniz
bu özelliği başka etki için kullanıyorsa hangisinin sahibi olacağını seçin. Bileşen hazır olunca malzemeleri geçiş
zincirlerine kopyalar; renkleri ve `min_gap` değerini sahne başlamadan malzemelerde ayarlayın.
`outline_enabled` çalışma sırasında değişebilir.

Godot 4.5+ sürümlerinde deneysel olan stencil arabelleğini kullanır. Forward+ işleyicisiyle test edilmiştir.

## Belgeler

Şablon deposunda: model değişimi dahil `docs/tr/systems/characters.md` ve oynanabilir kahramanı kopyalamak için
`docs/tr/integration.md`.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
