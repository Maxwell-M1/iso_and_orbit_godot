<!-- translation of addons/iso_orbit/ui_screens/README.md @ f510902e02d8 -->
# Arayüz Pencereleri

[← Belge dizini (şablon deposu)](../../../docs/tr/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Oyunun üstünde yığın hâlinde pencereler: birini diğerinin üstüne açın, en üsttekini Esc ile kapatın; herhangi bir
pencere açıkken oyun duraklatılır ve fare imleci gösterilir, klavye odağı pencereye verilir ve pencere kapanınca geri
döndürülür. Ayrıca oyun duraklatılmışken de çalışan FPS sayacı ve ekrandaki metinler için eylemlere atanmış
tuş adları vardır.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `ui_root.gd` | `UiRoot` (CanvasLayer) | Pencere yığını: `open()`, `close_top()`, `toggle()`; duraklatma, imleç, odak |
| `ui_screen.gd` | `UiScreen` (Control) | Pencere tabanı: `initial_focus`, `close_requested` sinyali |
| `fps_counter.gd`, `fps_counter.tscn` | `FpsCounter` (Label) | Saniyedeki kare sayısı, duraklatılmışken de |
| `input_names.gd` | `InputNames` (RefCounted, static) | Oyuncunun klavye düzenine ve çeviri diline göre eylemin tuşu veya fare düğmesi: `of_action()`, `of_event()`; `format()`, `{sprint}` gibi simgeleri metinde tuş adlarıyla değiştirir |
| `action_texts.gd` | `ActionTexts` (Node) | Üst düğümünün altındaki kontrol metinlerinin simgelerini doldurur; dil değişince ve `refresh()` çağrısında yeniler |

Başka bir eklenti gerekmez.

## Kurulum

1. Bu klasörü `res://addons/iso_orbit/ui_screens/` konumuna kopyalayın.
2. Ana sahneye `ui_root.gd` betikli bir `CanvasLayer` ekleyin. Oyun duraklatılmışken de çalışır.
3. Her pencereyi, kökü `UiScreen` sınıfını genişleten bir sahne olarak yapın. Pencere kendini asla kapatmaz:
   `request_close()` çağırır ve `UiRoot` onu kapatır.
4. Pencereleri `UiRoot.open(scene)` ile açın. Bir pencereyi tuşla açmak için `settings_screen` özelliğini o pencerenin
   sahnesine ayarlayın ve `toggle_settings` girdi eylemini ekleyin (ya da `settings_action` ayarlayın). Yoksa
   `UiRoot` başlangıçta bir kez bildirir ve tuş çalışmaz. Esc, yerleşik `ui_cancel` eylemidir.
5. İsteğe bağlı: `fps_counter.tscn` sahnesini HUD'unuza ekleyin.
6. İsteğe bağlı: metinlerde tuşları `{jump} — jump` gibi eylem simgeleriyle yazıp sahneye `ActionTexts` ekleyin
   (üst düğümünün altındaki kontrollere hizmet eder). Oyuncu tuşları değiştirince
   `get_tree().call_group(ActionTexts.GROUP, &"refresh")` çağırın. Kendi metnini kuran kontroller `refresh()`
   uygulayıp aynı gruba katılabilir. Fare düğmelerini, "Space" tuşunu ve atanmamış eylemleri başka dillerde
   adlandırmak için çevirilerinize `InputNames.get_mouse_names()`, "Space", `InputNames.UNBOUND`,
   `InputNames.LEFT_KEY` ve `InputNames.RIGHT_KEY` girdilerinin adlarını koyun. Son ikisi tuş adı için `%s`
   değerini korur.

`UiRoot` yalnız çalışan oyunu duraklatır ve yalnız kendi başlattığı duraklamayı bitirir. Pencere açıldığında oyun
zaten duraklıysa (örneğin seviye geçişi sırasında), duraklama onu başlatana aittir; o bitirirse oyun pencerenin
arkasında sürer.

Görünüm proje temasından gelir; `FpsCounter`, `FpsCounter` tema türü varyasyonunu kullanır.

## Belgeler

Şablon deposunda: `docs/tr/systems/ui.md` ve seviye değişimindeki pencereler için
`docs/tr/systems/levels.md`.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
