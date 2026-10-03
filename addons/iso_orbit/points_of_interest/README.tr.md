<!-- translation of addons/iso_orbit/points_of_interest/README.md @ 4bf86f099c43 -->
# İlgi Noktaları

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Keşfedilecek yerler: oyuncu ilk kez girdiğinde bunu bildiren bir alan ve her yeri kendiliğinden bulan, ekrandaki
"Keşfedildi: …" mesajı.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `point_of_interest.gd` | `PointOfInterest` (Area3D) | `player` grubundaki bir gövde ilk kez girdiğinde `discovered(title)` sinyalini yayar; `points_of_interest` grubuna katılır |
| `discovery_toast.gd`, `discovery_toast.tscn` | `DiscoveryToast` (Label) | Herhangi bir yer keşfedildiğinde birkaç saniye "Keşfedildi: …" gösterir |

Başka bir eklenti gerekmez.

## Kurulum

1. Bu klasörü `res://addons/iso_orbit/points_of_interest/` konumuna kopyalayın.
2. Oyuncunun gövdesini `player` grubuna koyun (ya da `player_group` ayarlayın).
3. Her yer için `point_of_interest.gd` betikli ve çarpışma şekilli bir `Area3D` ekleyin, `title` özelliğini
   ayarlayın ve `collision_mask` özelliğinin oyuncunun fizik katmanını içermesini sağlayın.
4. `discovery_toast.tscn` sahnesini HUD'unuza ekleyin. Başlangıçta sahnedeki her yere bağlanır; bağlantı kurmanız
   gerekmez.

Mesaj metni ve başlıklar çeviri sunucusundan geçer, bu yüzden yerelleştirilebilirler. Görünüm `DiscoveryToast` tema
türü varyasyonundan gelir.

## Belgeler

Şablon deposunda: `docs/tr/systems/world-and-navigation.md` ve `docs/tr/systems/ui.md`.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
