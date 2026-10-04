<!-- translation of docs/en/systems/camera.md @ 2985993ef79c -->
# Kamera

> Bu, [İngilizce orijinalin](../../en/systems/camera.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

İki düğüm: `OrbitCameraRig` bir hedefi izler, onun etrafında döner ve yakınlaştırır; alt düğümü `CameraArm`,
`Camera3D` düğümünü bir kolun ucunda tutar ve engellerde kolu kısaltır.

```
CameraRig (OrbitCameraRig)     hedefe yerleştirilir, sapma ve eğimle döndürülür
└── CameraArm (CameraArm)      yerel +Z boyunca kol; uzunluğunu düzenek yakınlaştırmaya göre belirler
    └── Camera3D               kolun ucunda, kol boyunca geriye bakar
```

Düzenek hedefin alt düğümü değil, kardeşidir. `_process` içinde hedefin enterpole edilmiş konumuna gider ve kendi
fizik enterpolasyonu kapalıdır: aksi hâlde zaten yumuşatılmış bir konumu yeniden yumuşatır ve bir tik geride kalırdı.
Projede fizik enterpolasyonu açıkken kamera ve karakter her kare hızında akıcı hareket eder.

## OrbitCameraRig

- **Yörünge.** Sağ tuşu (`camera_rotate`) basılı tutun ve fareyi hareket ettirin. Döndürürken imleç yakalanır ve tuşu
  bıraktığınızda bulunduğu yere döner. Döndürme sırasında pencere odağı kaybederse veya oyun duraklarsa düzenek
  imleci kendisi serbest bırakır.
- **Fareyle eğme** (`mouse_pitch`, varsayılan olarak kapalı). Sağ tuşla dikey fare hareketi kamerayı da eğer.
  Kapalıyken eğim yalnızca yakınlaştırmadan gelir.
- **Yakınlaştırma.** Tekerlek kamerayı aşağıya ve yakına ya da yukarıya ve uzağa taşır. Mesafe ve eğim birlikte
  değişir.
- **Takip** (`follow_movement`, `follow_pitch`, ikisi de varsayılan olarak kapalı). Kamera koşan hedefin arkasına
  yavaş yavaş döner ve eğimini yavaşça `follow_pitch_angle` değerine getirir.

### Yakınlaştırma eğrisi

Yakınlaştırma 0 (en yakın) ile 1 (en uzak) arasında bir değerdir; tekerleğin her çentiği onu `zoom_step` (0,1) kadar
değiştirir. Mesafe `near_distance` (5 m) ile `far_distance` (20 m) arasında değişir. Eğim `near_pitch` (−22°) ile
`far_pitch` (−55°) arasında değişir, ancak düzgün değil: tepeden `flatten_start_zoom` (0,5; 12,5 m; −38,5°) değerine
kadar düzgün değişir, bunun altında ise kamera hızla yataylaşır; böylece karakterin önü orta yükseklikte bile görünür.
`flatten_end_zoom` (0,2; 8 m) değerinden itibaren kamera −22° açıyla bakar ve yalnızca yaklaşır.

Demo `start_zoom` 0,55 ile başlar. Oradan bir çentik aşağı: −33,5°, iki: −26°, üç (8,75 m): −22,5°.

Eğim, yakınlaştırma eğimine bir ofset eklenmesiyle elde edilir. Fare (`mouse_pitch` ile) ve takip modu ofseti
değiştirir; böylece tekerlek ve fare her zamanki gibi çalışır ve koşarken eğim yavaşça seçilen açıya döner.
`mouse_pitch` kapatılınca ofset sıfırlanır. Eğim hiçbir zaman `min_pitch` (−80°) ve `max_pitch` (−8°) sınırlarını
aşmaz.

### Takip modu

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `follow_movement` | kapalı | Kamerayı koşan hedefin arkasına çevir |
| `follow_pitch` | kapalı | Koşarken eğimi, dönüşle aynı hızda ve aynı durumlarda yavaşça `follow_pitch_angle` değerine getir; `follow_movement` olmadan da çalışır |
| `follow_pitch_angle` | −40° | Hedef eğim (aşağı negatiftir), `min_pitch` ve `max_pitch` ile sınırlıdır |
| `follow_time` | 1,5 sn | Neredeyse tamamen dönme süresi (açının %5'i kalır); 0 anında demektir |
| `follow_min_speed` | 1 m/sn | Bu hızın altında kamera dönmez: dururken veya yerinde dönerken yön güvenilir değildir. Bu hız ile iki katı arasında dönüş yumuşakça güçlenir |

Demonun ayarları farklı varsayılanlar kullanır: yetişme süresi 1,1 sn ve 22° aşağı eğim.

Kamera şu durumlarda takip etmez:

- sağ tuş basılıyken: kamerayı fare kontrol eder, iki tuşla koşarken de;
- sol tuşa basıldıktan sonraki ilk 0,2 sn boyunca, bunun tıklama mı basılı tutma mı olduğu belli olana kadar.
  Duraklama, `main.tscn` içinde `CameraRig.set_follow_paused()` metoduna bağlanan
  `PointClickMoveInput.hold_pending_changed` sinyalinden gelir.

Hedefin hızını düzenek, hedefin fizik tiki başına hareketinden ölçer; bu yüzden herhangi bir `Node3D` hedef olabilir.

Sol tuş basılıyken kamera döndüğünde imleç zeminde farklı bir noktayı gösterir, karakter ona doğru, kamera da
karakterin ardından dönerdi: karakter daireler çizerek koşardı. Bu yüzden tuş basılıyken girdi bileşeni sistem
imlecini dünyayla birlikte hareket ettirir. Bkz. [Girdi](input.md#tuş-basılıyken-imleç).

### Özellikler

| Grup | Özellik | Varsayılan | Anlamı |
|---|---|---|---|
| | `target` | — | Neyin izleneceği |
| | `arm` | — | `CameraArm`; boşsa ilk `CameraArm` alt düğümü |
| | `camera` | — | Kol olmadan kullanılır; boşsa ilk `Camera3D` alt düğümü |
| Input (girdi) | `rotate_action`, `zoom_in_action`, `zoom_out_action` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` | Girdi eylemleri |
| | `mouse_sensitivity` | 0,25 °/px | Yörünge hızı |
| | `mouse_pitch` | kapalı | Dikey fare hareketi kamerayı eğer |
| | `invert_pitch` | kapalı | Bu eğmeyi ters çevir |
| | `zoom_step` | 0,1 | Tekerlek çentiği başına yakınlaştırma değişimi |
| Framing (kadraj) | `focus_height` | 1,2 m | Kameranın baktığı noktanın hedefin orijininden yüksekliği |
| | `near_distance`, `far_distance` | 5 m, 20 m | En yakın ve en uzak yakınlaştırmada kol uzunluğu |
| | `near_pitch`, `far_pitch` | −22°, −55° | En yakın ve en uzak yakınlaştırmada eğim |
| | `flatten_start_zoom`, `flatten_end_zoom` | 0,5; 0,2 | Eğimin daha hızlı yataylaşmaya başladığı ve yatay olduğu yer |
| | `min_pitch`, `max_pitch` | −80°, −8° | Eğim sınırları |
| | `start_zoom`, `start_yaw` | 0,55; 45° | Başlangıç yakınlaştırması ve yönü |
| Follow (takip) | yukarıya bakın | | |
| Smoothing (yumuşatma) | `rotation_sharpness`, `zoom_sharpness` | 30, 10 | Kameranın istenen sapmaya, eğime ve yakınlaştırmaya ne kadar hızlı ulaştığı |

Metotlar: `look_along(direction)` kamerayı anında bir yön boyunca bakacak şekilde çevirir; `snap()` istenen konuma
atlar, örneğin hedef ışınlandıktan sonra; `is_rotating()`; `set_follow_paused(paused)`.

## CameraArm

Kol uzunluğunu tekerlek belirler; kol engellerde kısalır ve yer açıldığında o uzunluğa geri döner.

- **Arkadakinde durma** (`keep_out_of_geometry`, varsayılan olarak açık). Kameranın arkasında dağ, duvar veya çatı
  varsa kamera içine girmez, hedefe doğru yaklaşır. Dağa doğru yürüyün, kamera yamaca girmeden hedefe yaklaşır;
  uzaklaşın, arkasında yer açılınca geri gider. Kol yalnızca kamera kolun ucunda duramıyorsa kısalır. Kamera ile
  hedef arasında, arkasında yer olan bir sütun veya çit kamerayı oynatmaz: karakter siluet olarak görünür.
- **Hedef gizlenince yaklaşma** (`pull_in_on_occlusion`, varsayılan olarak kapalı). Bir çit veya duvar hedefi
  neredeyse tamamen gizlerse kamera yumuşakça engelin önüne geçer, ancak hedefe hiçbir zaman `min_pull_in_length`
  (2,5 m) değerinden daha fazla yaklaşmaz. Karakter duvarın hemen dibinde duruyorsa kamera karakterin sırtına
  sıçramak yerine yerinde kalır.
- **Yakında saydamlaşma.** Kol çok kısaldığında `fade_target` yarı saydam olur.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `length` | 10 m | Kol uzunluğu; düzenek tarafından yakınlaştırmaya göre ayarlanır |
| `camera` | — | Kamera; boşsa ilk `Camera3D` alt düğümü |
| `keep_out_of_geometry` | açık | Kameranın arkasındaki gövdelerde dur |
| `probe_radius` | 0,3 m | Kamera bu yarıçapta bir küredir ve duvarlardan bu kadar uzak durur |
| `collision_mask` | 1. ve 3. katmanlar | Kolu durduran gövdeler: `world` ve `camera`. Karakterler (2. katman) durdurmaz |
| `ignored_groups` | `camera_ignore` | Bu gruplardaki ya da bu gruplardaki bir düğümün altındaki gövdeler kolu durdurmaz |
| `pull_in_on_occlusion` | kapalı | Hedef gizlenince yaklaş |
| `min_pull_in_length` | 2,5 m | Kamera, gizlenen hedef yüzünden bundan daha fazla yaklaşmaz; engelin önünde daha az yer varsa yerinde kalır |
| `pull_in_sharpness` | 10 | Kameranın gizleyen bir engelin önüne ne kadar hızlı geçtiği (0 anında). Arkadaki bir gövdede ise her zaman anında durur |
| `occlusion_points` | göğüs, baş, dizler, yanlar | Görünürlüğü denetlenen hedef noktaları, kolun başlangıcına göre: sağ, yukarı, kameraya doğru |
| `occlusion_share` | 0,75 | Noktaların bu payı gizlendiğinde hedef gizlenmiş sayılır. İnce bir direk veya ağaç gövdesi beşten üçünü gizler ve sayılmaz |
| `occlusion_delay` | 0,25 sn | Kameranın yaklaşması için hedefin ne kadar süre gizli, geri çekilmesi için ne kadar süre görünür kalması gerektiği |
| `return_delay`, `return_sharpness` | 0,3 sn; 4 | Kol anında kısalır ama bir duraklamadan sonra ve yumuşakça uzar; böylece kamera sütunlar arasında seğirmez |
| `fade_target` | — | Yakında neyin yarı saydam olacağı (demoda `Player/Visual`) |
| `fade_start_length`, `fade_end_length`, `fade_transparency` | 1,5 m; 0,7 m; 0,75 | Hedef ilk uzunlukta saydamlaşmaya başlar ve ikincisinde %75 saydamdır |
| `debug_draw` | kapalı | Kolu (gri: tekerlek uzunluğu, yeşil: mevcut uzunluk), kamera küresini ve hedefin noktalarına giden ışınları (kırmızı: gizli) çiz. Başka bir kameradan görünür |

Metotlar: `snap()`, `get_current_length()`, `is_pulled_in_by_occlusion()`.

### Yalnızca kamera için gövdeler

Bunları 3. fizik katmanına (`camera`) koyun. Karakterler onlarla çarpışmaz, tıklamalar ve navigasyon onları görmez.
Evin çatısında (`shared/world/props/house.tscn` içindeki `RoofCameraBlocker`) böyle bir gövde vardır: kamera çatıda
durur, ancak kimse üzerine tırmanamaz veya üzerinden yol bulamaz.

### `camera_ignore` grubu

Grup, içindeki bir düğümün altındaki her şeye de uygulanır. Onu bir kez, bir dekor sahnesinin köküne (böylece
seviyedeki her örnekte bulunur) ya da seviyedeki bir klasör düğümüne atayın. Demonun buna ihtiyacı yoktur: ağaç
gövdeleri (2,4 m'ye kadar) en yakın yakınlaştırmada bile (zeminden 3 m yukarıda) kameranın altında kalır.

### Kol, engelin arkasındaki boşluğu bir gövdenin içinde olmaktan nasıl ayırır

Kol önce kameranın kolun ucunda durup duramayacağını denetler: küre orada hiçbir şeye değmemeli ve uç bir gövdenin
içinde olmamalıdır. Kameradan hedefe giden bir ışın, içinden başladığı bir gövdenin yüzeylerini görmez; bu yüzden
kameranın önündeki engelin uzak yüzeyini bulur. O yüzeyden kolun ucuna giden bir ışın, kameranın içinde bulunduğu
gövdeye girer ve oradan hiç çıkmaz. Yolda bir şey varsa küre o yüzeyden kameraya doğru atılır ve diğerlerini geçerek
yoldaki gövdenin önünde durur. Kolun yalnızca sıyırdığı bir sütun kamerayı oynatmaz.

Jolt, kürenin bir atımın başlangıcında temas ettiği gövdeleri bildirmez. Bu yüzden yüzeyin hemen arkasında başka bir
gövde varsa (arkasında uçurum olan bir çit), boş alan hedefe daha yakında aranır.

## Ölçülen davranış

`tests/camera_checks.gd` ve `tests/camera_arm_checks.gd` içinden:

- Koşu kameraya 90° açıdayken takip: `follow_time` 0 iken %95 dönüş 0,17 sn'de, demonun 1,1 değeriyle 1,23 sn'de; 10
  iken 2 sn sonra 90°'nin yalnızca 39°'si dönülmüştür. Dururken dönmez. Sağ tuş basılıyken dönmez, bırakılınca devam
  eder.
- Takip açıkken (1,1 sn) sol tuşu basılı tutma: ilk 0,2 sn kamera yerinde kalır (kısa bir tıklama onu oynatmaz),
  ardından 1,25 sn'de koşunun arkasına kalan 28,3°'nin 27,1°'sini döner, bu sırada koşu yönü 0,01° değişir;
  "anında" ile de aynı. Fareyi 150 px hareket ettirmek koşuyu 25° döndürür ve yeni yön korunur.
  `keep_aim_on_camera_turn` kapalıyken karakter 1,25 sn'de 77,6° kıvrılır.
- Eğim hizalama: tekerlekle alçaltılmış bir kamera (22,5° aşağı), `follow_time` 0,5 iken yavaşça 55°'ye gelir; yolun
  %95'ini yaklaşık 0,65 sn'de alır ve dönüş kapalıysa koşunun ardından dönmez. 89°, kameranın 80° sınırına kırpılır.
  Takip ve 20° eğimle sol tuşu basılı tutma: eğim 20°'ye giderken 1,25 sn'de 80°'den 22,5°'ye iner ve koşu yönü
  0,01° değişir.
- Kol: açık alanda tam uzunluk; arkadaki bir uçurum onu anında durdurur; uçuruma doğru yürürken kamera yaklaşır ve
  uçurumun dışında kalır; uçurum kalkınca kol bir duraklamadan sonra yumuşakça geri döner. Hemen arkasında uçurum
  olan bir çit: kamera çitin önünde durur. Kamera ile karakter arasında yarı yolda bir çit: varsayılan olarak kamera
  çitin arkasında kalır; yaklaşma açıkken yumuşakça önüne geçer ve kısa bir örtülme sayılmaz. Karakterin dibinde bir
  çit: kamera karakterin sırtına sıçramaz. İnce bir direk sayılmaz, kolu sıyıran bir sütun kamerayı oynatmaz,
  `camera_ignore` içindeki gövdeler onu durdurmaz ve çok yakında karakter yarı saydamdır.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
