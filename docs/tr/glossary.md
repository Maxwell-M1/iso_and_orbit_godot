<!-- translation of docs/en/glossary.md @ 537f8443c59c -->
# Sözlük

[← Belge dizini](index.md)

> Bu, [İngilizce orijinalin](../en/glossary.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Terimler, bu belgelerde ve kodda kullanıldıkları anlamıyla.

| Terim | Anlamı |
|---|---|
| **Ajan yarıçapı** (agent radius) | Navigasyon örgüsünün engellerden ne kadar uzak durduğu: 0,5 m, karakterin 0,35 m'lik kapsülünden fazla; böylece yollar köşelerden pay bırakır |
| **Kol** (arm) | `CameraArm`: kamerayı hedeften çıkan bir çizginin ucunda tutan düğüm. Uzunluğunu tekerlek belirler; engeller onu kısaltır |
| **Karışım** (blend) | `GroundCharacter.get_locomotion_blend()`: animasyonlar için sayı olarak hız; dururken 0, koşarken 1, deparda 2 |
| **Sınırlar** (bounds) | 4. fizik katmanı: seviye kenarındaki görünmez duvarlar. Karakter çarpışır, tıklamalar ve kamera kolu içlerinden geçer |
| **Yalnızca kamera için gövde** (camera-only body) | 3. fizik katmanındaki (`camera`) bir gövde: kamera kolunu durdurur, ancak tıklamalar, navigasyon ve karakterler onu yok sayar |
| **Karakter durumu** (character state) | Karakterin ne yaptığı: duruyor, koşuyor, depar atıyor, zıplıyor veya düşüyor (`GroundCharacter.get_state()`, `state_changed` sinyali) |
| **Tıklama** (click) | Sol tuşa basılıp basılı tutma gecikmesi içinde bırakılması. Karakter, tuşa basıldığı noktaya bir yol boyunca koşar |
| **Yapılandırma uyarısı** (configuration warning) | Düğüm yanlış kurulduğu sürece Scene panelinde düğümün yanında görünen uyarı işareti: boş bir bağlantı, yanlış bir üst düğüm, eksik bir girdi eylemi. Bileşenler editörde kendilerini denetler ve kurulum düzeltilir düzeltilmez uyarı kaybolur |
| **Çakal süresi** (coyote time) | Bir kenardan yürüyerek çıktıktan sonra zıplamanın hâlâ çalıştığı kısa süre (0,1 sn) |
| **Boyutlar** (dimensions) | `StaticProp.dimensions`: katı bir dekor nesnesinin kendi eksenleri boyunca metre cinsinden boyutu; modeli ve çarpışması birlikte yeniden boyutlandırılır. Bir eksende 0, parçalarının o eksendeki boyutunu korur |
| **Editör önizlemesi** (editor preview) | Bir bileşenin, oyunun başlangıçta kurduklarından editörde gösterdikleri: kameranın başlangıç görüntüsü, devriye gezen bir karakterin modeli ve adı, bir portalın tabelasındaki başlık, bir dekor nesnesinin boyutu. Sahneye hiçbir zaman kaydedilmez |
| **Bitkin** (exhausted) | Dayanıklılık bittikten sonraki durum: dayanıklılık `recover_ratio` (%30) değerine dolana kadar depar yok |
| **Bakış yönü** (facing) | Karakterin nereye baktığı; nereye hareket ettiğinin aksine. Yana adımda veya geri geri yürürken ikisi farklıdır. `NavigationMover.get_facing()` |
| **Düşüş ayarları** (fall settings) | Zıplama tepesinden veya kenardan sonraki düşüşün yerçekimi, en yüksek hızı ve ona yavaşlama (`FallSettings`). Zıplamanın yükselişini etkilemez |
| **Süzülme** (floating) | Gövde yürümeyi sürdürürken modelin yerden yüksek durup basamaklarda kayması (`CharacterHover`). Adım yoktur; demoda daha yavaş iner |
| **Takip** (follow) | Kameranın koşunun arkasına dönmesi, eğimini ve yüksekliğini hedeflere getirmesi; her hareket yumuşak başlar ve biter (`follow_movement`, `follow_pitch`, `follow_zoom`). Dönüşten sonra duruşa veya yeni koşuya kadar bekleyebilir (`follow_wait_after_rotate`, demoda açık) |
| **Yürüyüş döngüsü** (gait cycle) | Sol ve sağ olmak üzere iki adım, 0 ile 1 arasında bir sayı olarak (`GroundCharacter.get_gait_cycle()`). Zamanı değil, kat edilen mesafeyi izler |
| **Gidiş yönü** (heading) | Karakterin hareket ettiği yön. `NavigationMover.get_heading()` |
| **Kahraman görünümü** (hero look) | Oyuncunun karakterinin giyebileceği on modelden biri; ayarlarda numarayla seçilir (`CharacterAppearance`) |
| **Basılı tutma** (hold) | Sol tuşun basılı tutma gecikmesinden uzun süre basılı tutulması. Karakter imlecin peşinden koşar |
| **Basılı tutma gecikmesi** (hold delay) | Tıklamayı basılı tutmadan ayıran süre: 0,2 sn (`PointClickMoveInput.hold_delay`) |
| **Zıplama tamponu** (jump buffer) | İnişten kısa süre önce basılan zıplama hatırlanır ve inişte gerçekleşir (0,12 sn) |
| **Hedefi koruma** (keeping the aim) | Tuş basılıyken ve kamera dönerken sistem imlecini dünyayla birlikte hareket ettirme; böylece imleç zeminde aynı noktanın üstünde kalır (`keep_aim_on_camera_turn`) |
| **Kenar koruması** (ledge guard) | `LedgeGuard`: karakteri 0,5 m'den yüksek bir uçurumda durdurur ya da kenar boyunca kaydırır |
| **Seviye sunucusu** (level host) | `LevelHost`: geçerli seviyeyi tutar ve yükleme ekranının ardında değiştirir; kahraman ve arayüz seviyenin parçası değil, kardeşidir |
| **Yükleme ekranı** (loading screen) | `LoadingScreen`: seviye değişirken oyunu örter; bulanık son kareyi, yer adını, ilerleme çubuğunu ve ipuçlarını gösterir |
| **Görünüm** (look) | Bkz. kahraman görünümü |
| **Etrafa bakma** (looking around) | İmleci izleyen basılı koşu sırasında sağ tuşa basmak: fare yalnız kamerayı döndürür, koşu yönünü korur (`look_around_while_held`). Önce sağ tuşa basılırsa koşuyu kameranın baktığı yöne yönlendirir |
| **İşaretçi** (marker) | `ClickMarker`: tıklanan noktada zemindeki halka |
| **Hareketlendirici** (mover) | `NavigationMover`: komutları (`move_to`, `steer`, `stop`) her tikte yatay bir hıza dönüştürür. Gövdeyi asla hareket ettirmez |
| **Navigasyon örgüsü** (navigation mesh) | Seviyenin 1. katmandaki çarpışmalarından (adada görünmez duvarların 4. katmanı da) pişirilen yürünebilir alan. Her seviye sahnesinde saklanır; yollar üzerinde aranır |
| **Yolculuk teklifi** (offer to travel) | `TravelPrompt`: kahraman önce soran portalda dururken ekranda tuş ve "... ışınlan" metni. E (`interact` eylemi) veya teklife tıklama geçirir, uzaklaşmak gizler |
| **Devriye** (patrol) | Bir karakterin seviyedeki bir rotada kendi kendine yürümesi, turlar arasında kendi yerinde beklemesi ve yolunu kesen herkes için durması (`PatrolController`): çayırdaki şövalye, adadaki korucu |
| **Fizik enterpolasyonu** (physics interpolation) | Gövdeleri fizik tikleri arasında ekranın kare hızında çizme. Varsayılan olarak açıktır; bir ayar kapatır |
| **Eğim** (pitch, tilt) | Kameranın aşağıya ne kadar dik baktığı. Kodda negatif açılar, ayarlarda aşağı doğru derece |
| **Yerinde dönüş** (pivot) | Dururken, `pivot_speed` (1 m/sn) altında anında dönme |
| **Yer** (place) | Bir `PointOfInterest`: oyuncu ilk kez girdiğinde "Keşfedildi: …" gösteren bir alan |
| **Oynanabilir kahraman** (playable hero) | `PlayableHero` (`playable_hero.tscn`): girdisi, kamerası, tıklama işareti ve yol çizgisiyle oyuncunun denetlediği kahraman; oyun sahnesinde seviyelerin yanında durur |
| **Portal** (portal) | `LevelPortal`: başka seviyeye götüren alan; demo ışınlanma platformları portaldır |
| **Dekor nesnesi** (prop) | Seviyeye yerleştirilmiş katı bir nesne, kökü `StaticProp` olan bir sahne: kökünden taşınır, boyutlarıyla yeniden boyutlandırılır |
| **Yaklaşma** (pull-in) | Kameranın karakteri gizleyen bir engelin önüne geçmesi (`pull_in_on_occlusion`) |
| **Rota** (route) | Bir devriyenin yürüdüğü, seviyedeki `Path3D`: editörün eğrisi için çizdiği çizgi |
| **Keskin dönüş** (sharp turn) | Koşunun `OrbitCameraRig.sharp_turn_speed` (360°/s) değerinden hızlı yön değişimi, örneğin ters yöne dönüş. Kamera ara yönleri izlemez, ardından yeni yönü alır |
| **Oyun kabuğu** (shell) | Oyun boyunca kalan sahne (`main.gd` betikli `main.tscn`): seviye sunucusu, kahraman, arayüz ve yükleme ekranı |
| **Yana adım** (sidestep) | Sağ tuşla kullanılan bir tuş modu: karakter yana veya geriye hareket ederken kameranın baktığı yöne bakmayı sürdürür |
| **Siluet** (silhouette) | Bir şey karakteri gizlediğinde onun konturlu düz bir şekil olarak çizilmesi (`OccludedSilhouette`) |
| **Doğuş noktası** (spawn point) | `SpawnPoint`: seviyede karakterin adla seçilen ortaya çıkış yeri; her seviyede bir `default` vardır |
| **Depar** (sprint) | Shift basılıyken veya açık konumdayken dayanıklılık harcayarak daha hızlı (×1,5) koşma |
| **Basamak yüksekliği** (stair height) | Karakterin zıplamadan çıktığı en yüksek basamak: 0,3 m (`GroundCharacter.max_step_height`) |
| **Dayanıklılık** (stamina) | Depar rezervi (`Stamina`): deparda harcanır, bir duraklamadan sonra yenilenir |
| **Başlangıç seviyesi** (start level) | Editörde seviye sunucusunun altına konan ve sunucunun `initial_level` alanında adı verilen ilk seviye: çitli çayır `shared/world/world.tscn`. Oyunda adadaki platformun başlığı olan Yeşil Vadi adıyla bilinir |
| **Yönlendirme** (steer) | Yolsuz olarak bir yöne koşma: `NavigationMover.steer()`. Tuşu basılı tutmak varsayılan olarak imlece doğru yönlendirir |
| **Altyazılar** (subtitles) | Bir karakterin söylediği, ekranın altında adıyla birlikte (`SubtitleDisplay`) |
| **Işınlama** (teleport) | Karakteri koşu veya sarsıntı olmadan anında başka yere koyma: `GroundCharacter.teleport()`, `PlayableHero.teleport()` |
| **Tik** (tick) | Bir fizik adımı; saniyede 60 |
| **Yolcu** (traveller) | Portalı kullanabilen gövde: portalın `traveller_group` grubunda olan (`player` varsayılan) |
| **Dönüş modu** (turn mode) | Sağ tuşla kullanılan bir tuş modu: karakter gittiği yöne bakacak şekilde döner |
| **Isınma** (warm-up) | Seviye sunucusunun yeni seviyeyi yükleme ekranının ardında çizdiği kareler; gölgelendiriciler derlenir, karakter yerleşir (`LevelHost.warmup_frames`, 3) |
| **Sapma** (yaw) | Kameranın dikey eksen etrafındaki yönü |
| **Yakınlaştırma** (zoom) | Kameranın mesafesini ve eğimini birlikte belirleyen, 0 (en yakın) ile 1 (en uzak) arasında bir değer |

---

*Bu sayfa Iso & Orbit 1.3.0 sürümüne karşılık gelir.*
