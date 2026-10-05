<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 94f2d396a032 -->
<!-- translation of addons/iso_orbit/orbit_camera/README.md @ pending -->
# Yörünge kamerası

[← Belge dizini (şablon deposu)](../../../docs/tr/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

İzometrik ve yukarıdan bakışlı oyunlar için yörünge kamerası. Herhangi bir `Node3D` hedefi izler, fareyle çevresinde
döner ve tekerlekle yakınlaşır. Koşuda ayrı ayrı hedefin arkasına dönebilir, eğimini hizalayabilir ve seçilen
yakınlaştırmaya dönebilir. Kolu kamerayı duvarların dışında tutar; engel hedefi gizlediğinde isteğe bağlı yaklaşır.

Godot 4.7 için Iso & Orbit'in parçasıdır. MIT lisansı (bkz. `LICENSE`). Bu klasör tek başına başka eklenti istemez.

| Betik | Sınıf | Görev |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig` (`Node3D`) | Hedef takibi, girdi, yakınlaştırma ve isteğe bağlı koşu hizalaması |
| `camera_arm.gd` | `CameraArm` (`Node3D`) | Kamera yerleşimi, engel tepkisi ve isteğe bağlı yakında saydamlaşma |

## Sahneye ekleme

1. Bu klasörü `res://addons/iso_orbit/orbit_camera/` konumuna kopyalayın.
2. **Project Settings → Input Map** bölümüne `camera_rotate` (sağ fare tuşu), `camera_zoom_in` (tekerlek yukarı) ve
   `camera_zoom_out` (tekerlek aşağı) eylemlerini ekleyin. Düzeneğin dışa aktardığı eylem adları değiştirilebilir.
   Eksik eylem başlangıçta hata verir ve girdi tetiklemez.
3. Aşağıdaki düğümleri hareket eden hedefin yanına ekleyin. `CameraRig.target` alanına karakterinizi veya başka
   `Node3D` hedefi atayın. Kamera alt ağacını ve üst düğümlerini ölçeklendirmeyin.

   ```text
   Scene
   ├── Character (hareket eden hedef)
   └── CameraRig (Node3D + orbit_camera_rig.gd; target = ../Character)
       └── CameraArm (Node3D + camera_arm.gd)
           └── Camera3D (Current = on)
   ```

   Düzenek ve kol sırasıyla ilk doğrudan `CameraArm` ve `Camera3D` çocuklarını bulur; dışa aktarılan `arm` ve
   `camera` başvurularını da atayabilirsiniz. Kolu kamerayı yerleştirdiğinden `Camera3D` varsayılan yerel dönüşümde
   kalsın. Etkin görüntü olması gerektiğinde Current özelliğini açın. Şablon kadrajı için görüş açısını 45°, uzak
   düzlemi 300 dünya birimi yapın.
4. Katı dünya çarpışmasını 1. fizik katmanına koyun. Kolun varsayılan `collision_mask` değeri 1 ve 3. katmanlardır
   (`0b101`); 3. katmanda yalnız kameraya engel olan çatılar bulunabilir. Karakterleri bu maskeden çıkarın ki
   kamerayı itmesinler. Gövdeyi hariç tutmak için kendisine veya üst düğümüne `camera_ignore` ekleyin. İsterseniz
   yakında saydamlaşacak model kökünü `CameraArm.fade_target` alanına atayın.
5. Hedef fizik tiklerinde hareket ediyorsa **Project Settings → Physics → Common → Physics Interpolation** ayarını
   açın. Düzenek her çizilen karede enterpolasyonlu hedef konumunu izler, kendi enterpolasyonunu kapatır. Kolu ve
   kamerası bu modu varsayılan olarak devralır.

Betik varsayılanları elle döndürülen kamerayı verir: koşudaki üç hizalama anahtarı da kapalıdır, süre ve hedefleri
tanımlı olsa bile. Şablon kahramanının ayarlanmış isteğe bağlı takibi için `follow_time = 1.1` s,
`follow_pitch_angle = -22°`, `follow_pitch_time = 1.1` s, `follow_zoom_level = 0.55`,
`follow_zoom_time = 1.5` s, `follow_wait_after_rotate = true` ve `height_follow_time = 0.15` s kullanın.
Koşunun arkasına dönmek için `follow_movement`; yalnız istediğiniz hizalamalar için `follow_pitch` ve/veya
`follow_zoom` açın. Kahraman sahnesi başlangıçta üçünü de kapalı tutar. Açılar Inspector'da derece, GDScript
atamalarında `deg_to_rad()` ile radyan kullanır.

`follow_wait_after_rotate` açıkken bilinçli fare dönüşü sonrasında hedef yavaşlayana veya yeni koşu başlayana dek
takip bekler. Girdi, hedef durmadan yeni koşu başlatıyorsa o anda `end_follow_wait()` çağırın. Şablon,
`gdscript/player/playable_hero.tscn` içinde `PointClickMoveInput.run_requested` sinyalini buna,
`hold_pending_changed` sinyalini `set_follow_paused()` yöntemine bağlar. Hedef sürekli hareket edip yeni koşuyu
bildiremiyorsa bekleme seçeneğini kapalı bırakın. Ters yöne dönme sırasında kamera ara yönleri izlemesin diye
`sharp_turn_speed` eşiğini karakter dönüş hızının yarısında veya altında tutun; şablonda kahramanın 720°/s
dönüşüne karşı 360°/s kullanılır.

Kol olmadan düzeneğin doğrudan `Camera3D` çocuğu da çalışır. Yakınlaştırma uzaklığında kalır ve duvarların
içinden geçebilir; engel tepkisi ve saydamlaşma için `CameraArm` gerekir.

Yakınlaştırma eğrisi, bütün özellikler, örtülme davranışı ve denenen etkileşimler için
[Kamera](../../../docs/tr/systems/camera.md); hazır kahramanı aktarmak için
[Aktarma](../../../docs/tr/integration.md#demonun-kahramanını-projenize-aktarma) ve
[Proje yapılandırması](../../../docs/tr/project-setup.md) sayfalarına bakın.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
