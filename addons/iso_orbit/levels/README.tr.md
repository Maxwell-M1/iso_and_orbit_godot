<!-- translation of addons/iso_orbit/levels/README.md @ 8dd533b32064 -->
<!-- translation of addons/iso_orbit/levels/README.md @ pending -->
# Seviyeler

[← Belge dizini (şablon deposu)](../../../docs/tr/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Oyuncunun karakteri ve arayüzü yerinde kalırken yükleme ekranının ardında seviye değiştirir: sonraki seviyeyi arka
planda yükleyip eskisini kaldıran ve karakterin nereye konacağını oyuna bildiren seviye sunucusu; onayla veya hemen
başka seviyeye götüren portallar; doğuş noktaları; yer adı, ilerleme çubuğu ve ipuçlarının arkasında oyunun son
karesini bulanık gösteren yükleme ekranı.

Godot 4.7 için kamera ve karakter kontrolcüsü şablonu Iso & Orbit'in parçasıdır. MIT lisansı (bkz. `LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `level_host.gd` | `LevelHost` (Node3D) | Geçerli seviyeyi tutar; `change_level(path, spawn_name, title)` sonrakini arka planda yükleyip yer değiştirir ve her adımı sinyalle bildirir; sonradan eklenenler dahil seviyenin portallarına giren ve çıkan yolcuları `portal_entered` ve `portal_exited` olarak yeniden yayar |
| `level_portal.gd` | `LevelPortal` (Area3D) | Başka seviyeye geçiş: yolcunun girip çıktığını bildirir, `travel()` ile veya kendiliğinden (`auto_travel`) geçirir, `title` değerini isteğe bağlı tabelaya yazar |
| `spawn_point.gd` | `SpawnPoint` (Marker3D) | Karakterin adıyla seçilen ortaya çıkış yeri; işaretçinin −Z yönüne bakar |
| `loading_screen.gd`, `loading_screen.tscn`, `loading_background.gdshader`, `loading_screen_theme.tres` | `LoadingScreen` (CanvasLayer) | Yüklenirken oyunun son karesini bulanık ve karanlık gösterir, yavaşça yaklaştırır; yer adı, geriye gitmeyen çubuk ve ipuçları vardır; açıkken oyuna girdi olayı ulaşmaz |

Başka eklenti gerekmez: seviye sunucusu karakteri, kamerayı veya arayüzü bilmez. Oyununuz bunları sinyallerine bağlar.

## Kurulum

1. Bu klasörü `res://addons/iso_orbit/levels/` konumuna kopyalayın.
2. Ana sahneye (oyun boyunca kalan sahneye) `level_host.gd` kullanan bir `Node3D` ekleyin; başlangıç seviyesini tek
   çocuğu yapın. Oyuncu karakteri, kamera ve arayüz, seviyenin içinde değil, sunucunun yanında dursun.
3. Ana sahneye `loading_screen.tscn` ekleyip sunucunun `loading_screen` alanına atayın veya ekransız geçiş için
   alanı boş bırakın.
4. Her seviyede `spawn_point.gd` kullanan, yerde duran ve `spawn_name` değeri `default` olan bir `Marker3D` ekleyin.
   Portalların varacağı yerlere başka adlı noktalar ekleyin.
5. Portal için `level_portal.gd` kullanan bir `Area3D` ve çarpışma şekli ekleyin; `collision_mask` karakterin
   katmanını içermelidir. `target_level` (sahne dosyası), `target_spawn` ve `title` değerlerini ayarlayın. Karakter
   gövdesini `player` grubuna koyun veya `traveller_group` özelliğini değiştirin.
6. Ana betiğinizde sunucunun sinyallerini bağlayın:
   - `level_change_started`: yükleme ekranının resminde görünmemesi gerekenleri gizleyip kontrolleri kapatın;
   - `level_loaded(level, spawn)`: karakteri `spawn` konumuna yerleştirip kamerayı döndürün;
     `GroundCharacter.teleport()` sarsıntısız yerleşim sağlar;
   - `level_change_finished`: kontrolleri açın;
   - `level_change_failed(path, error)`: kontrolleri açıp gizlediklerinizi gösterin; geçerli seviye yerinde kalır.
     Hatalı yüklemeden sonra yalnız bu sinyal gelir, `level_change_finished` gelmez;
   - `portal_entered(portal)` ve `portal_exited(portal)`: yolculuk teklifini gösterip gizleyin; onayda
     `portal.travel()` çağırın.

Sunucu başlangıç seviyesini bildirmez: ana betiğinizin `_ready()` yönteminde `get_current_level()` ve
`find_spawn_point()` ile onu kurun.

Portal varsayılan olarak önce sorar: oyun teklif gösterir ve `travel()` çağırır. `auto_travel` açıkken karakter
içeri girer girmez, kapı veya harita sınırı gibi, geçirir. Geçiş isteğin hemen ardından başlar, isteğin içinde değil;
dolayısıyla portal bunu fizik geri çağrısından isteyebilir. Yükleme ve yer değiştirme sırasında oyun duraklar.
Sunucu, duraklama sürerken yeni seviyenin navigasyon haritasına alınmasını bekler; sonra duraklamayı bitirip ekranın
ardında birkaç kare çizer. Böylece gölgelendiriciler görünmeden derlenir. Sunucu ayarları: `min_loading_time`
(0.6 sn, ekranın en kısa kalış süresi), `warmup_frames` (3, arkasında çizilen kareler) ve
`navigation_timeout` (2 sn, harita için en uzun bekleme); `is_changing()` geçişin sürüp sürmediğini söyler.
`change_level()` geçiş sırasında `ERR_BUSY`, yanlış dosyada `ERR_FILE_NOT_FOUND` veya
`ERR_INVALID_PARAMETER` döndürür. Daha sonra başarısız olan yükleme geçerli seviyeyi korur,
`level_change_failed` verir; sonraki istek dosyayı yeniden yükler. Sunucu yalnızca kendisinin başlattığı
duraklamayı bitirir: oyunu duraklatan pencereyi `level_change_finished` sonrasında açın. Ekran ve bekleme süreleri,
`Engine.time_scale` ne olursa olsun gerçek zamana göre işler.

Yükleme ekranının görünümü `loading_screen_theme.tres` içindedir (`LoadingTitle`, `LoadingBar`, `LoadingTip` tür
çeşitleri). Başka görünüm için ekran köküne farklı tema atayın veya `loading_screen.tscn` kopyasından kendi ekranınızı
yapın: betiğin `Root` ve benzersiz adlarıyla `Background`, `Title`, `Bar`, `Tip` düğümlerine ihtiyacı vardır.
`tips` alanına ekleyene kadar ipucu yoktur; her ipucu çevrilir ve kod ayarlamışsa `tip_format` ile biçimlendirilir
(`ui_screens` eklentisindeki `InputNames.format`, o anda atanmış tuşları koyar: `{sprint}` "Shift" gösterir).

## Belgeler

Şablon deposunda: `docs/tr/systems/levels.md` ve `docs/tr/integration.md`.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
