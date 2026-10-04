<!-- translation of addons/iso_orbit/ui_screens/README.md @ fe8d4c35a41a -->
# Arayüz Pencereleri

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Oyunun üstünde yığın hâlinde pencereler: birini diğerinin üstüne açın, en üsttekini Esc ile kapatın; herhangi bir
pencere açıkken oyun duraklatılır ve fare imleci gösterilir, klavye odağı pencereye verilir ve pencere kapanınca geri
döndürülür. Ayrıca oyun duraklatılmışken de çalışmayı sürdüren bir FPS sayacı.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `ui_root.gd` | `UiRoot` (CanvasLayer) | Pencere yığını: `open()`, `close_top()`, `toggle()`; duraklatma, imleç, odak |
| `ui_screen.gd` | `UiScreen` (Control) | Pencere tabanı: `initial_focus`, `close_requested` sinyali |
| `fps_counter.gd`, `fps_counter.tscn` | `FpsCounter` (Label) | Saniyedeki kare sayısı, duraklatılmışken de |

Başka bir eklenti gerekmez.

## Kurulum

1. Bu klasörü `res://addons/iso_orbit/ui_screens/` konumuna kopyalayın.
2. Ana sahneye `ui_root.gd` betikli bir `CanvasLayer` ekleyin. Oyun duraklatılmışken de çalışır.
3. Her pencereyi, kökü `UiScreen` sınıfını genişleten bir sahne olarak yapın. Pencere kendini asla kapatmaz:
   `request_close()` çağırır ve `UiRoot` onu kapatır.
4. Pencereleri `UiRoot.open(scene)` ile açın. Bir pencereyi tuşla açmak için `settings_screen` özelliğini o pencerenin
   sahnesine ayarlayın ve `toggle_settings` girdi eylemini ekleyin (ya da `settings_action` ayarlayın). Esc, yerleşik
   `ui_cancel` eylemidir.
5. İsteğe bağlı: `fps_counter.tscn` sahnesini HUD'unuza ekleyin.

Görünüm proje temasından gelir; `FpsCounter`, `FpsCounter` tema türü varyasyonunu kullanır.

## Belgeler

Şablon deposunda: `docs/tr/systems/ui.md`.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
