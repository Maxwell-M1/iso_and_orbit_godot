<!-- translation of docs/en/systems/camera.md @ d5569844bc1c -->
<!-- translation of docs/en/systems/camera.md @ pending -->
# Kamera

[← Belge dizini](../index.md)

> Bu, [İngilizce orijinalin](../../en/systems/camera.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

`OrbitCameraRig`, bir `Node3D` hedefi izler; fareyle çevresinde döner, tekerlekle uzaklığı ve eğimi değiştirir.
Çocuğu `CameraArm`, `Camera3D` düğümünü yerel +Z boyunca yerleştirir ve yakınındaki geometriden uzak tutar.
Koşarken otomatik dönüş, eğim hizalaması ve yakınlaştırma hizalaması birbirinden bağımsız üç seçenektir.

```text
PlayableHero (şablonda sabit kök)
├── Character (hareket eden hedef)
└── CameraRig (OrbitCameraRig; target = ../Character)
    └── CameraArm (CameraArm)
        └── Camera3D (current = true)
```

Düzeneği hareket eden hedefin içine değil yanına koyun: küresel konumunu ve dönüşünü kendisi ayarlar. Kol uzunlukları
ve çarpışma yarıçapları anlamlı kalsın diye düzenek, kol, kamera ve üst düğümleri `(1, 1, 1)` ölçeğinde olsun.
Düzenek, her çizilen karede kamerayı `target.get_global_transform_interpolated()` konumundan yerleştirir ve kendi
fizik enterpolasyonunu `_ready()` içinde kapatır; çocukları varsayılan olarak aynı modu devralır. Hedef fizik
tiklerinde hareket ediyorsa projede fizik enterpolasyonunu açın; yoksa hedef gözle görülür biçimde tik tik ilerler.
Şablonda açıktır. `height_follow_time`, enterpolasyondan sonra hedefin dikey basamaklarını yumuşatabilir.

`Camera3D`, varsayılan yerel dönüşümüyle başlamalıdır: kol çalışma sırasında konumunu ve dönüşünü ayarlar.
Şablonda **Current** açıktır; 45° görüş açısı ve 300 dünya birimi uzak düzlemi kullanır. Sahneye sonradan başka
bir etkin kamera girerse, görüntü kahramanın olacağı zaman bu kamerayı yeniden etkin yapın. Kamerayı veya tüm
kahramanı kopyalamak için [Aktarma](../integration.md#kamera-tek-başına), eylem ve fizik katmanları için
[Proje yapılandırması](../project-setup.md) sayfasına bakın.

## Etkin değerler hangileri?

Aşağıdaki betik değerleri yeniden kullanılabilir bileşen varsayılanlarıdır.
`gdscript/player/playable_hero.tscn` bunların birkaçını geçersiz kılar; demo başlarken `SettingsApplier` kaydedilmiş
`Settings` değerlerini uygular. Kopyalanan kahraman sahnesi demo ayar penceresi veya otomatik yüklemesi olmadan,
sahnedeki değerlerle çalışır.

| Ayar | Betik varsayılanı | Oynanabilir kahraman sahnesi / yeni demo |
|---|---:|---:|
| Koşuda dönüş, eğim ve yakınlaştırma hizalaması | hepsi kapalı | hepsi kapalı |
| `follow_time` | 1.5 s | 1.1 s |
| `follow_pitch_angle`, `follow_pitch_time` | −40°, 1.5 s | −22°, 1.1 s |
| `follow_zoom_level`, `follow_zoom_time` | 0.55, 1.5 s | 0.55, 1.5 s |
| `follow_wait_after_rotate` | kapalı | açık |
| `height_follow_time` | 0 s | 0.15 s |

Dönüş, eğim ve yakınlaştırma süreleriyle hedefleri yalnız ilgili takip anahtarı açıkken etkili olur.
`height_follow_time`, elle döndürmede de hedefin dikey hareketini her zaman yumuşatır. Demoda önceden
`user://settings.cfg` dosyasına kaydedilmiş seçimler yeni kurulum varsayılanlarını değiştirebilir.
`SettingsApplier`, penceredeki pozitif "Aşağı eğim" derecelerini negatif eğime; %0–100 yüksekliği düzeneğin
0–1 yakınlaştırma değerine dönüştürür.

Uzunluklar ve hızlar Godot dünya birimleridir (şablondaki 1 birim = 1 m ölçeğinde metredir).
`radians_as_degrees` işaretli açılar ve açısal hızlar Inspector'da derece gösterilir, ama GDScript atamalarında
radyan kullanılır: `follow_pitch_angle` için `deg_to_rad(-22.0)`, `sharp_turn_speed` için
`deg_to_rad(360.0)` kullanın. `playable_hero.tscn` içindeki serileştirilmiş `-0.383972...`, −22°'dir.

## Dönüş, eğim ve yakınlaştırma

`camera_rotate` tuşunu (şablonda sağ fare tuşu) basılı tutup fareyi hareket ettirerek kamerayı döndürün. İmleç
yakalanır ve bırakılınca eski yerine döner; odağın kaybı veya duraklama da onu bırakır. `mouse_pitch` kapalıyken
dikey fare hareketi etkisizdir ve eğimi tekerlek seçer. Fareyle eğmek için açın; `invert_pitch` ekseni tersine
çevirir. Tekerleği yukarı kaydırmak kamerayı alçaltır, aşağı kaydırmak yükseltir. Yumuşak kaydırma,
`zoom_step` değerinin bir kesri kadar ilerleyebilir.

Yakınlaştırma 0 (yakın) ile 1 (uzak) arasındadır. Varsayılan tekerlek adımı 0.1'dir. Kol uzunluğu
`near_distance` 5 ile `far_distance` 20 dünya birimi arasında değişir. Yakına geldikçe eğim azalır:

| Yakınlaştırma | Uzaklık | Temel eğim |
|---:|---:|---:|
| 0 | 5 | −22° |
| 0.2 (`flatten_end_zoom`) | 8 | −22° |
| 0.5 (`flatten_start_zoom`) | 12.5 | −38.5° |
| 0.55 (`start_zoom`) | 13.25 | −40.15° |
| 1 | 20 | −55° |

0.2 ile 0.5 arasında kamera alçalırken eğim hızla yataylaşır; ilerideki zemin daha kolay görülür. 0.2 altında
yalnız uzaklık değişir. Fare ve takip eğimi, `min_pitch` ve `max_pitch` (−80° ve −8°) ile sınırlı bir ofset
ekler. `mouse_pitch` kapatılınca, `follow_pitch` eğimi korumuyorsa ofseti silinir. `rotation_sharpness` ve
`zoom_sharpness` fare ve tekerlek değişimlerini yumuşatır; 0 ilgili girdiyi anlık yapar.

## Takip modu

`follow_movement`, `follow_pitch` ve `follow_zoom` seçeneklerinden istediklerinizi açın: kamera sırasıyla koşu
yönünün arkasına döner, seçilen eğime yaklaşır ve seçilen yakınlaştırmaya gelir. Düzenek her fizik tikinde herhangi
bir `Node3D` hedefin yatay hareketini ölçer; karakterin hız özelliği gerekmez. `follow_min_speed` altında takip
etmez, bu hızla iki katı arasında takip gücü yumuşakça artar. Duran hedef yeni koşuya yeni yönle başlar.

Etkin hareketlerin her biri kendi yayı üzerinde yumuşakça başlar ve yerleşir. Süresi, dönüş hızı sınırı engel
olmadıkça, tam hızlı koşuda hareketsiz durumdan değişimin yaklaşık %95'ini tamamlama süresidir; 0 anlık değişim
ister. Hareket durunca veya takip duraklayınca başlamış hareket kesilmek yerine frenler. Bu frenleme hızını
`rotation_sharpness` ve `zoom_sharpness` belirler. Takip kamerayı doğrudan taşır; girdi yumuşatması ikinci bir
gecikme eklemez.

| Özellik | Betik varsayılanı | Etki |
|---|---:|---|
| `follow_movement`, `follow_time` | kapalı, 1.5 s | Yatay koşunun arkasına dönüş; dönüşü hemen hemen bitirme süresi |
| `follow_max_turn_speed` | 0 | Otomatik yatay dönüşün °/s cinsinden üst sınırı; 0, anlık dönüşte de sınırı kaldırır |
| `follow_toward_camera_angle` | 30° | Kameraya doğrudan yönün bu açısı içindeki koşuları yok sayar; açının iki katında tam dönüş gücü. 0 istisnayı kaldırır |
| `sharp_turn_speed` | 360°/s | Daha keskin yön değişimi veya tersine dönüşte ara yönleri yok sayıp yeni yönü izler; 0 korumayı kapatır |
| `teleport_speed` | 50 dünya birimi/s | Fizik tikleri arasındaki bundan hızlı yatay hareket koşu değil ışınlama sayılır |
| `follow_pitch`, `follow_pitch_angle`, `follow_pitch_time` | kapalı, −40°, 1.5 s | Yatay dönüşten bağımsız olarak seçilen aşağı eğime gelir |
| `follow_zoom`, `follow_zoom_level`, `follow_zoom_time` | kapalı, 0.55, 1.5 s | Dönüş ve eğimden bağımsız olarak 0–1 yakınlaştırma düzeyine gelir |
| `follow_min_speed` | 1 dünya birimi/s | Takibin başladığı en düşük yatay hız; iki katında tam güç |
| `follow_wait_after_rotate` | kapalı | Fareyle döndürme sonrası hedef `follow_min_speed` altına yavaşlayana veya yeni koşu bildirilene kadar görüntüyü korur |

Kameraya doğru koşu koruması **yalnız dönüşü** etkiler. Doğrudan kameraya koşarken eğim ve yakınlaştırma açık ise
değişebilir. Keskin dönüş koruması da yalnız dönüşü etkiler: ters yöne dönerken eğimle yakınlaştırma sürer; başlamış
bir kamera dönüşü yavaşlayıp durabilir. Şablon kahramanının 720°/s `LocomotionSettings.turn_speed` değeri için
360°/s eşik ters yön değişimlerini yakalarken daha yavaş kavisleri izler. Karakter dönüş hızını değiştirirseniz
`sharp_turn_speed` değerini bunun yarısında veya altında tutun. Pozitif eşik karakter dönüş hızına ulaşırsa
`PlayableHero` uyarır. `follow_toward_camera_angle` değerini 0 yapmak, kameraya doğru koşunun arkasına dönmeye
bilerek izin verir.

Eğim ve yakınlaştırma hizalaması birlikte açıkken yakınlaştırma uzaklığı değiştirir; eğim hizalaması yakınlaştırma
eğrisini telafi eder. Görüntü bağımsız olarak `follow_pitch_angle` ve `follow_zoom_level` değerlerine yerleşir.
Tekerlek ve fare koşu sırasında da çalışır; açık takip hareketleri görüntüyü yeniden hedeflere çeker.
`height_follow_time` ayrıdır: özellikle basamaklarda düzeneğin hedefin **dünya Y konumunu** nasıl izlediğini
yumuşatır. Yakınlaştırma düzeyini değiştirmez. 0 hedef yüksekliğini tam izler; kahraman sahnesindeki 0.15 s,
dikey değişimin %95'ini yaklaşık bu sürede tamamlar.

### Takibin durakladığı durumlar

Sağ fare tuşu basılıyken üç takip hareketi de çekmeyi bırakır. `follow_wait_after_rotate` açıkken, en az 0.2 sn
veya 2 px hareket içeren bir kamera döndürmesi bittikten sonra geçerli koşu boyunca seçilen görüntü korunur. Sağ
tuş bırakılmadan odak kaybolur veya oyun duraklarsa da böyledir; daha kısa dokunuş bekleme başlatmaz. Seçenek
kapalıyken dönüş bittiğinde takip sürer. Hedef `follow_min_speed` altına yavaşlayınca, `end_follow_wait()` yeni
koşu bildirince, `snap()` çağrılınca, hedef değişince veya hareket `teleport_speed` değerini aşınca bekleme biter.
Yeni koşu eskisi durmadan başlayabilir; bu seçenek kullanılıyorsa girdinin `run_requested` sinyalini
`end_follow_wait()` yöntemine bağlayın. Böyle sinyal olmadan sürekli hareket eden hedef kamerayı sonsuza dek
bekletebilir; oyununuz yeni koşuyu bildiremiyorsa seçeneği kapalı bırakın.

`playable_hero.tscn`, `PointClickMoveInput.hold_pending_changed` sinyalini `set_follow_paused()` yöntemine de
bağlar. Sol fare tuşuna basıldıktan sonraki ilk 0.2 sn'de, girdi bunun tıklama mı basılı tutma mı olduğuna karar
verirken takibi duraklatır. `run_requested`, yeni tıklama, basılı tutma veya sağ tuş + tuş koşusunda döndürme sonrası
beklemeyi bitirir. Süren sol tuş koşusunda sağ tuşa basıp etrafa bakabilirsiniz; sağ tuş bırakıldığında o koşu
yeni sayılmaz. Görüntü sonraki duruşa veya yeni koşuya kadar seçildiği yerde kalır.
`keep_aim_on_camera_turn`, kamera hareket ederken imlecin aynı dünya noktasını hedeflemesini sağlar; koşu yönü
kamerayı kovalamaz.

`Engine.time_scale` 0 olduğunda takip hareketleri durumlarını korur; zaman ilerleyince sürer. Hedefi elle
taşırsanız veya `teleport_speed` denetimini tetiklemeyecek kısa mesafeye ışınlarsanız kamerayı ve kolu yerine
oturtup hareket geçmişini sıfırlamak için `snap()` çağırın.

## Özellikler

| Grup | Özellik | Betik varsayılanı | Anlamı |
|---|---|---:|---|
| Hedef | `target` | yok | İzlenecek `Node3D` |
| Hedef | `arm`, `camera` | yok | Atanmamışsa ilk eşleşen doğrudan çocuk; `camera` yalnız kol yokken kullanılır |
| Girdi | `rotate_action`, `zoom_in_action`, `zoom_out_action` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` | Input Map eylemleri; eksik olanlar başlangıçta hata bildirir |
| Girdi | `mouse_sensitivity`, `mouse_pitch`, `invert_pitch`, `zoom_step` | 0.25 °/px, kapalı, kapalı, 0.1 | Fareyle dönüş hızı, fareyle eğim denetimi, tekerlek adımı |
| Kadraj | `focus_height` | 1.2 dünya birimi | Hedefin kökeninin üstündeki bakış noktası |
| Kadraj | `near_distance`, `far_distance` | 5, 20 | Yakınlaştırma 0 ve 1'deki kol uzunlukları |
| Kadraj | `near_pitch`, `far_pitch` | −22°, −55° | Yakınlaştırma 0 ve 1'deki temel eğimler |
| Kadraj | `flatten_start_zoom`, `flatten_end_zoom` | 0.5, 0.2 | Eğimin daha hızlı yataylaştığı yakınlaştırma aralığı |
| Kadraj | `min_pitch`, `max_pitch` | −80°, −8° | Fare ve takip ofsetleri dahil son eğim sınırları |
| Kadraj | `start_zoom`, `start_yaw` | 0.55, 45° | İlk yakınlaştırma ve dünya eksenli yatay açı; `look_along()` daha sonra açıyı değiştirebilir |
| Yumuşatma | `rotation_sharpness`, `zoom_sharpness` | 30, 10 | Yüksek değer fare/tekerlek hedeflerine daha çabuk ulaşır; 0 anlıktır |
| Yumuşatma | `height_follow_time` | 0 s | Dikey hedef takibinin yaklaşık %95'ini tamamlama süresi; 0 tam izler |

`look_along(direction)`, **dünya uzayındaki** bir yönün yatay bileşeni boyunca görüntüyü anında döndürür ve süren
otomatik dönüşü durdurur. `snap()`, geçerli yatay açıyı, eğimi, yakınlaştırmayı, hedef konumunu ve kolun çarpışma
tepkisini hemen uygular; ışınlamadan sonra kullanın. `get_zoom()` güncel 0–1 yakınlaştırmayı döndürür.
`is_rotating()`, `is_follow_paused()`, `is_follow_waiting()` ve `is_target_turning_sharply()` ilgili durumları
bildirir. `set_follow_paused(paused)` ve `end_follow_wait()` yukarıdaki duraklamaları yönetir.

Düzenek bir kol veya kamera çocuğu (ya da açıkça atanmış `arm`/`camera`) ister; yoksa hata ayıklama derlemesinde
assert çalışır. Küresel dönüşünü kendi ayarladığından `start_yaw`, `look_along()` ve otomatik dönüş, sabit kahraman
kökü döndürülmüş olsa bile dünya eksenlerini kullanır.

## Engeller, örtülme ve saydamlaşma

`CameraArm` normalde `keep_out_of_geometry` kullanır: istenen kamera konumunda kamera küresi fizik gövdelerinin
dışına sığmalıdır. Duvar, eğim veya çatı kamerayı içine alacaksa kol hemen kısalır. Hedefle kamera arasındaki çit,
kameranın arkasında yer varsa kolu kısaltmaz. Hedefi örten çitin önüne özellikle geçmek için
`pull_in_on_occlusion` açın; kol kalıcı örtülme bekler ve ancak en az `min_pull_in_length` kalıyorsa yaklaşır.
Örtülme kalkınca kısa süre bekleyip yumuşakça geri döner. Dönüş yolunda engel varsa içinden uçmak yerine üzerinden
atlar.

### Kol engelin arkasındaki boşlukla gövdenin içini nasıl ayırır?

Kol önce kamera küresinin istenen uç konumuna sığıp sığmadığını denetler. Uç serbestse hedefle kamera arasındaki
çitin arkasında kalabilir. Uç bir gövdeye dokunuyorsa veya içindeyse kol hedefe daha yakın serbest yer arar. Jolt
şekil taramaları başlangıçta dokunulan veya içine girilmiş gövdeleri bildirmez; kol bu ilk boşluğu ayrıca denetler.
İki gövde birbirine yakınsa hedefe daha yakın bir noktadan arar. Böylece hemen arkasında uçurum olan çite de
kamera girmez.

Küre ve görünürlük ışınları `collision_mask` kullanır (ikilik `0b101`, 1 ve 3. katmanlar). Şablonda 1. katman
katı dünya geometrisi, 3. katman `RoofCameraBlocker` gibi yalnız kameraya yönelik geometridir. 2. katmandaki
karakterler ve 4. katmandaki görünmez karakter sınırları kolu oynatmaz. `camera_ignore` grubundaki veya bu
gruptaki düğümün altındaki gövdeler yok sayılır. Bir nesnenin her örneğini etkilemek için grubu köküne koyun.
Başka projeye aktarırken maske sayıları önemlidir; katman adları yalnız etikettir. `keep_out_of_geometry`
kapalıysa yaklaşma ayarı ne olursa olsun kol kamerayı arkasındaki geometriden korumaz.

Varsayılan beş `occlusion_points`, hedefin göğsünü, başını, dizlerini ve yanlarını örnekler. Bunlar düzeneğin
hedef kökeninden `focus_height` kadar yukarı koyduğu **kol başlangıcına** göredir; x kameranın sağı, y yukarı,
z yatay olarak kameraya doğrudur. `occlusion_share = 0.75`, beş noktadan en az dördünün örtülmesi demektir. Daha
uzun veya süzülen model için noktaları ve `focus_height` değerini ayarlayın. Şablonun `CharacterHover` bileşeni
görünen modeli gövdeden 0.35 dünya birimi yukarı kaldırabilir.

`fade_target` isteğe bağlıdır. Atanınca kol `fade_start_length` değerinden kısaldıkça altındaki
`GeometryInstance3D` düğümlerinin `transparency` değerini değiştirir; `fade_end_length` noktasında
`fade_transparency` değerine ulaşır. Kahraman `Character/Visual` düğümünü atar. Yakın mesafe saydamlaşması,
karakteri engellerin içinden çizen isteğe bağlı `OccludedSilhouette` eklentisinden ayrıdır.

| Özellik | Betik varsayılanı | Anlamı |
|---|---:|---|
| `length`, `camera` | 10, yok | İstenen kol uzunluğu (genellikle düzenek ayarlar) ve atanmadıysa ilk doğrudan `Camera3D` çocuğu |
| `keep_out_of_geometry`, `probe_radius` | açık, 0.3 | Kamera küresini maskelenen gövdelerin dışında tutar |
| `collision_mask`, `ignored_groups` | 1 + 3. katmanlar, `camera_ignore` | Çarpışma ve örtülme denetimindeki gövdeler ve dışlanacak gruplar |
| `pull_in_on_occlusion`, `min_pull_in_length`, `pull_in_sharpness` | kapalı, 2.5, 10 | Yaklaşma anahtarı, en kısa uzunluk ve yaklaşma hızı (0 anlık) |
| `occlusion_points`, `occlusion_share`, `occlusion_delay` | beş nokta, 0.75, 0.25 s | Görünürlük örnekleri, örtülen pay ve yaklaşma/dönüş öncesi gecikme |
| `return_delay`, `return_sharpness` | 0.3 s, 4 | Kolun uzama öncesi beklemesi ve hızı (0 keskinlik bekleme sonrası anlık) |
| `fade_target`, `fade_start_length`, `fade_end_length`, `fade_transparency` | yok, 1.5, 0.7, 0.75 | İsteğe bağlı model saydamlaşması; 0.7 birim veya daha yakında tam |
| `debug_draw` | kapalı | İstenen/geçerli kol uzunluğunu, kamera küresini ve görünürlük ışınlarını çizer; başka kameradan yararlıdır |

`CameraArm.snap()` çarpışmayı yeniden hesaplayıp dönüş gecikmesi olmadan kamerayı yerleştirir.
`get_current_length()` engellerden sonraki gerçek uzunluğu verir; `is_pulled_in_by_occlusion()` hedefin
örtülmesinin kolu o anda içeri çekip çekmediğini bildirir.

Yukarıdaki davranışlar [`tests/camera_checks.gd`](../../../tests/camera_checks.gd) ve
[`tests/camera_arm_checks.gd`](../../../tests/camera_arm_checks.gd) ile denetlenir: takip zamanlaması,
kameraya doğru koşu ve keskin dönüş korumaları, elle döndürme sonrası bekleme, eğim/yakınlaştırma hizalaması,
basamaklarda dikey yumuşatma, engellerden kaçınma, isteğe bağlı yaklaşma, yok sayılan gruplar ve saydamlaşma.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
