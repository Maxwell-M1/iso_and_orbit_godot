<!-- translation of docs/en/glossary.md @ 0821af632403 -->
# Sözlük

> Bu, [İngilizce orijinalin](../en/glossary.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Terimler, bu belgelerde ve kodda kullanıldıkları anlamıyla.

| Terim | Anlamı |
|---|---|
| **Ajan yarıçapı** (agent radius) | Navigasyon örgüsünün engellerden ne kadar uzak durduğu: 0,5 m, karakterin 0,35 m'lik kapsülünden fazla; böylece yollar köşelerden pay bırakır |
| **Kol** (arm) | `CameraArm`: kamerayı hedeften çıkan bir çizginin ucunda tutan düğüm. Uzunluğunu tekerlek belirler; engeller onu kısaltır |
| **Karışım** (blend) | `GroundCharacter.get_locomotion_blend()`: animasyonlar için sayı olarak hız; dururken 0, koşarken 1, deparda 2 |
| **Yalnızca kamera için gövde** (camera-only body) | 3. fizik katmanındaki (`camera`) bir gövde: kamera kolunu durdurur, ancak tıklamalar, navigasyon ve karakterler onu yok sayar |
| **Karakter durumu** (character state) | Karakterin ne yaptığı: duruyor, koşuyor, depar atıyor, zıplıyor veya düşüyor (`GroundCharacter.get_state()`, `state_changed` sinyali) |
| **Tıklama** (click) | Sol tuşa basılıp basılı tutma gecikmesi içinde bırakılması. Karakter, tuşa basıldığı noktaya bir yol boyunca koşar |
| **Çakal süresi** (coyote time) | Bir kenardan yürüyerek çıktıktan sonra zıplamanın hâlâ çalıştığı kısa süre (0,1 sn) |
| **Bitkin** (exhausted) | Dayanıklılık bittikten sonraki durum: dayanıklılık `recover_ratio` (%30) değerine dolana kadar depar yok |
| **Bakış yönü** (facing) | Karakterin nereye baktığı; nereye hareket ettiğinin aksine. Yana adımda veya geri geri yürürken ikisi farklıdır. `NavigationMover.get_facing()` |
| **Takip** (follow) | Kameranın koşan karakterin arkasına kendiliğinden dönmesi ve isteğe bağlı olarak eğimini yavaşça ayarlaması (`follow_movement`, `follow_pitch`) |
| **Yürüyüş döngüsü** (gait cycle) | Sol ve sağ olmak üzere iki adım, 0 ile 1 arasında bir sayı olarak (`GroundCharacter.get_gait_cycle()`). Zamanı değil, kat edilen mesafeyi izler |
| **Gidiş yönü** (heading) | Karakterin hareket ettiği yön. `NavigationMover.get_heading()` |
| **Kahraman görünümü** (hero look) | Oyuncunun karakterinin giyebileceği on modelden biri; ayarlarda numarayla seçilir (`CharacterAppearance`) |
| **Basılı tutma** (hold) | Sol tuşun basılı tutma gecikmesinden uzun süre basılı tutulması. Karakter imlecin peşinden koşar |
| **Basılı tutma gecikmesi** (hold delay) | Tıklamayı basılı tutmadan ayıran süre: 0,2 sn (`PointClickMoveInput.hold_delay`) |
| **Zıplama tamponu** (jump buffer) | İnişten kısa süre önce basılan zıplama hatırlanır ve inişte gerçekleşir (0,12 sn) |
| **Hedefi koruma** (keeping the aim) | Tuş basılıyken ve kamera dönerken sistem imlecini dünyayla birlikte hareket ettirme; böylece imleç zeminde aynı noktanın üstünde kalır (`keep_aim_on_camera_turn`) |
| **Kenar koruması** (ledge guard) | `LedgeGuard`: karakteri 0,5 m'den yüksek bir uçurumda durdurur ya da kenar boyunca kaydırır |
| **Görünüm** (look) | Bkz. kahraman görünümü |
| **İşaretçi** (marker) | `ClickMarker`: tıklanan noktada zemindeki halka |
| **Hareketlendirici** (mover) | `NavigationMover`: komutları (`move_to`, `steer`, `stop`) her tikte yatay bir hıza dönüştürür. Gövdeyi asla hareket ettirmez |
| **Navigasyon örgüsü** (navigation mesh) | Seviyenin 1. katmandaki çarpışmalarından pişirilen ve `world.tscn` içinde saklanan yürünebilir alan. Yollar onun üzerinde aranır |
| **Fizik enterpolasyonu** (physics interpolation) | Gövdeleri fizik tikleri arasında ekranın kare hızında çizme. Varsayılan olarak açıktır; bir ayar kapatır |
| **Eğim** (pitch, tilt) | Kameranın aşağıya ne kadar dik baktığı. Kodda negatif açılar, ayarlarda aşağı doğru derece |
| **Yerinde dönüş** (pivot) | Dururken, `pivot_speed` (1 m/sn) altında anında dönme |
| **Yer** (place) | Bir `PointOfInterest`: oyuncu ilk kez girdiğinde "Keşfedildi: …" gösteren bir alan |
| **Yaklaşma** (pull-in) | Kameranın karakteri gizleyen bir engelin önüne geçmesi (`pull_in_on_occlusion`) |
| **Yana adım** (sidestep) | Sağ tuşla kullanılan bir tuş modu: karakter yana veya geriye hareket ederken kameranın baktığı yöne bakmayı sürdürür |
| **Siluet** (silhouette) | Bir şey karakteri gizlediğinde onun konturlu düz bir şekil olarak çizilmesi (`OccludedSilhouette`) |
| **Depar** (sprint) | Shift basılıyken veya açık konumdayken dayanıklılık harcayarak daha hızlı (×1,5) koşma |
| **Basamak yüksekliği** (stair height) | Karakterin zıplamadan çıktığı en yüksek basamak: 0,3 m (`GroundCharacter.max_step_height`) |
| **Dayanıklılık** (stamina) | Depar rezervi (`Stamina`): deparda harcanır, bir duraklamadan sonra yenilenir |
| **Yönlendirme** (steer) | Yolsuz olarak bir yöne koşma: `NavigationMover.steer()`. Tuşu basılı tutmak varsayılan olarak imlece doğru yönlendirir |
| **Tik** (tick) | Bir fizik adımı; saniyede 60 |
| **Dönüş modu** (turn mode) | Sağ tuşla kullanılan bir tuş modu: karakter gittiği yöne bakacak şekilde döner |
| **Sapma** (yaw) | Kameranın dikey eksen etrafındaki yönü |
| **Yakınlaştırma** (zoom) | Kameranın mesafesini ve eğimini birlikte belirleyen, 0 (en yakın) ile 1 (en uzak) arasında bir değer |

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
