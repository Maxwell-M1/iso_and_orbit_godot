<!-- translation of docs/en/systems/input.md @ 286e042594f2 -->
# Girdi

[← Belge dizini](../index.md)

> Bu, [İngilizce orijinalin](../../en/systems/input.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

İki düğüm oyuncu girdisini komutlara dönüştürür. İkisi de kendisi hiçbir şeyi hareket ettirmez.

- `PointClickMoveInput`: fare ve sağ tuş basılıyken WASD → `NavigationMover.move_to()`, `steer()` ve `stop()`.
- `CharacterActionInput`: depar ve zıplama tuşları → `GroundCharacter.sprint_requested` ve `jump()`.

İkisi de karakter sahnesinde değil, oynanabilir kahraman sahnesi `playable_hero.tscn` içindedir; böylece aynı
karakteri yapay zekâ sürebilir. Oyuncu açısından [Kontroller](../controls.md) sayfasına bakın. Hazır kahramanı
kopyalamak için [Aktarma](../integration.md#demonun-kahramanını-projenize-aktarma), önerilen birleşimler için
[Yapılandırmalar](../configurations.md) sayfasını izleyin.

## PointClickMoveInput

| Girdi | Komut |
|---|---|
| Zemine tıklama | `move_to(point)`: kameradan `ground_mask` üzerinde atılan bir ışın noktayı bulur |
| Sol tuş basılı | `hold_mode` değerine göre imlece doğru `steer()` ya da imlecin altındaki noktaya `move_to()` |
| Önce sağ sonra sol tuş veya ikisi `hold_delay` içinde | Kameranın baktığı yöne `steer()`; A ve D ileriye çapraz saptırır (`keys_with_camera_steer`) |
| Önce sol tuş basılı, sonra sağ | Yeni komut yok: sağ tuş kamerayı döndürürken basılı koşu nişan aldığı yöne gider (`look_around_while_held`) |
| Sağ tuş ve WASD | Kameraya göre, yana adımla veya dönerek `steer()` (`keys_with_camera`); bırakınca `stop()` |

Bir tikte karakteri kimin yöneteceğine tek bir yerde, `_physics_process` içinde karar verilir: önce basılı sol tuş,
yoksa sağ tuşla birlikte klavye tuşları. Bu yüzden sağ tuş ve W basılıyken sol tuşu bırakmak karakteri durdurmaz:
tuşlar hemen devralır.

Tersi durumda, iki tuşlu koşuda sağ tuş bırakılınca koşu kameranın baktığı yönü korur
(`keep_camera_course`). Fare hareket edince imleç devralır (8 px'ten fazla; kamera dönerken elin hareketi
sayılmasın diye ilk `cursor_takeover_delay` 0.2 s içinde değil) ve karakterin koşu yönünde 4 m önünden başlar.
O zamana kadar sol tuş bırakılırsa, iki tuş birlikte bırakılmış gibi, aradaki süre ne olursa olsun karakter
rotasında durur. İnsanlar iki düğmeyi nadiren aynı anda bırakır. `keep_camera_course` kapalıysa sağ tuş
bırakılır bırakılmaz imleç eski, kamera dönmeden önceki konumundan devralır ve karakter sert dönebilir.
Bu nedenle iki tuşu art arda bırakırken `keep_camera_course` değeri koşunun son yönünü belirler.

### Koşarken etrafa bakma

İmleci izleyen basılı koşuda sağ tuşa basmak yalnız kamerayı döndürür (`look_around_while_held`, açık): oyuncu
istediği yöne koşarken çevreye bakmak ister, koşuyu kameraya devretmek değil. Bu ayar olmadan karakter hemen
kameranın baktığı yöne döner; kamera takibi kapalıysa bu genellikle koşu yönü değildir. Sıra, sağ tuşa
basıldığı anda belirlenir:

- İmlecin yönlendirdiği basılı koşuda: etrafa bakar.
- Sol basış basılı tutma olmadan önce (`hold_delay`, 0.2 s) iki tuşa birlikte veya önce sağ tuşa basılırsa:
  koşu kameranın baktığı yöne gider.
- Sağ tuş bırakıldıktan sonra kameranın yönünü koruyan basılı koşuda (`keep_camera_course`): yeniden sağ tuşa
  basınca kameranın baktığı yöne gider. Fare oynayıp imleç yönlendirmeye başladıktan sonra yeni sağ basışı
  yalnız etrafa baktırır.

Bunun için `camera_steer_action`, `OrbitCameraRig.rotate_action` gibi kamerayı döndürmelidir (ikisi de
`camera_rotate`): basılıyken fare nişanı hareket ettirmez. Başka eylem veya onunla dönmeyen kamera kullanıyorsanız
`look_around_while_held` kapalı olsun. Etrafa bakarken tuşlar etkisizdir: sağ tuş yokmuş gibi basılı koşu sürer.

Etrafa bakarken nişan fareyi izlemez: karakterin ayaklarına göre zemin noktasıdır ve kamera kendiliğinden dönünce
de yönü korur (`keep_aim_on_camera_turn`). Fare kamerayı döndürür; `STEER` modunda karakter nişana koşar. Sağ tuş
bırakılınca imleç o noktaya döner, fare yönlendirme sürer. Çok büyük dönüşte nişan ekran dışına çıkarsa bileşen
pencere kenarında ani dönüş olmasın diye onu aynı yön boyunca yaklaştırır.

`FOLLOW_POINT` modunda da etrafa bakarken ve ardından fare hareket edene kadar (8 px üstü,
`cursor_takeover_delay` sonrası) hedef nokta karakterin ayaklarına göre yerinde kalır; karakter aynı yönde koşar,
hedefe varmaz. Başka açıdan imlecin altındaki nokta aynı değildir: kameradan atılan ışın öndeki eğime veya
platforma değebilir. Noktasına ulaşmış basılı koşuda (imleç ayaklarda) korunacak nokta yoktur, etrafa bakınca
orada kalır. Sağ tuş bırakıldığında, bir şey gizlemiyorsa imleç yeni kamera açısından aynı noktayı hedefler.

Sağ tuş kamerayı hâlâ döndürürken sol tuş bırakılırsa, gizli imleç sağ tuş bırakıldığında kameranın eskiye
götürdüğü yere değil, nişan aldığı noktaya gelir. `keep_aim_on_camera_turn` kapalıysa imleç ekranda sabit kalır;
90° kamera dönüşü koşuyu da 90° döndürür. Durmadan etrafa bakmadan kameranın baktığı yöne koşuya geçmek için
sağ tuş basılıyken sol tuşa yeniden basın. `look_around_while_held` kapalıysa sağ tuş her sırada koşuyu yönlendirir.

### Tıklama veya basılı tutma

Bir basış `hold_delay` (0,2 sn) sonrasında basılı tutmaya dönüşür. O zamana kadar karakter yaptığı şeyi sürdürür
(durur ya da koştuğu yere koşmaya devam eder); işaretçi ve basılan noktaya giden bir yol yoktur.

- **Daha erken bırakılırsa: tıklama.** Karakter, tuşa basıldığı noktaya bir yol boyunca koşar. Fare sonradan hareket
  etmiş olsa bile nokta basış anında alınır. İşaretçi belirir (`destination_picked`). Karakter vardığında ya da
  koşudan tuşlar veya basılı tutma uğruna vazgeçildiğinde solar.
- **Daha uzun basılı tutulursa: basılı tutma.** Karakter hemen imlecin peşinden koşar (`hold_started`) ve önce
  basılan noktaya doğru dönmez. Aksi hâlde o noktaya giden yola koyulurdu; engellerin etrafından dolanan bir yol ise
  imleçten bambaşka bir yere götürebilir.

Bunun bedeli, tıklamanın bırakınca, yani basışa göre yaklaşık 0,1 sn daha geç etki etmesidir. Bir basışın tıklama mı
basılı tutma mı olduğu belirsizken `hold_pending_changed(true)` kameranın takip modunu duraklatır
(`playable_hero.tscn` içinde `OrbitCameraRig.set_follow_paused()` yöntemine bağlıdır); kısa tıklama kamerayı oynatmaz.

Sol tuşa basıldığında sağ tuş zaten basılıysa tıklama olmaz: karakter hemen kameranın baktığı yöne koşar.

### Basılı tutma modları

`hold_mode` (Ayarlar → Kontroller → **Basılı sol tuş**):

- `STEER` (varsayılan): yolsuz olarak doğrudan imlece doğru. Karakter engeller boyunca kayar ve rampaya nereden
  yönlendirirseniz oradan çıkar. Karakterin `steer_dead_zone` (0,5 m) yakınında yön değişmez: bu kadar yakında yön
  imlece fazla duyarlı olur. Bırakınca karakter yumuşakça durur.
- `FOLLOW_POINT`: imlecin altındaki noktaya bir navigasyon yolu boyunca. Nokta hareket ederken yol yeniden
  oluşturulur; bu yüzden yükseklik değişimlerinin yakınında (rampa, platform) bir rotadan diğerine atlayabilir.
  Bırakınca karakter son noktaya kadar koşmayı sürdürür ve işaretçi o noktayı gösterir (`destination_picked`);
  `stop_on_release` açıksa bulunduğu yerde frenleyerek durur. Bu ayar yalnız basılı tutmayı etkiler: kısa tıklama
  seçilen noktaya yine koşar. Boş yol doğrudan koşu kullanır, kısmi yol istenen hedefin önünde bitebilir; bkz.
  [Hareket](locomotion.md#navigationmover).

### Sağ tuşla kullanılan tuşlar

Tuşlar yalnızca sağ tuş basılıyken çalışır: kamera fareyle döner ve imleç yakalanır. Sağ tuş olmadan WASD hiçbir şey
yapmaz. Her mod `OFF` ya da iki seçenekten biridir ve yalnız sağ tuş (`keys_with_camera`) ile iki tuş birlikte
(`keys_with_camera_steer`) için ayrı ayrı ayarlanır.

| | `SIDESTEP` | `TURN` |
|---|---|---|
| Sağ tuş + W | ileri, kameranın baktığı yöne | aynısı |
| Sağ tuş + A / D | yana, yüz önde | sola / sağa döner ve o yöne gider |
| Sağ tuş + S | geriye, yüz önde, daha yavaş | geri döner ve kameraya doğru yürür |
| İki tuş (W + A, S + D…) | çapraz, yüz önde | çapraz, yüz gidiş yönünde |
| Sol + sağ tuş + A / D | çapraz ileri, yüz önde | çapraz ileri, yüz gidiş yönünde |

Betik varsayılanı ikisi için de `SIDESTEP`; demo ayarlarında ve `playable_hero.tscn` sahnesinde ikisi de
`TURN` olur. `keys_with_camera_steer = OFF`, iki tuş basılıyken A/D'yi kapatır ama iki tuş yine kameranın
baktığı yöne koşturur. Bunu da kapatmak için `camera_steer_action` değiştirilmelidir; bu, etrafa bakma ve
sağ tuşlu klavye hareketini de etkiler.

Çapraz hareket, düz hareket kadar hızlıdır. Geriye hareket daha yavaştır: `NavigationMover` hızı, hareketin bakış
yönüne ne kadar ters olduğuna göre ölçekler, bkz. [Hareket](locomotion.md#navigationmover). Bakış yönü
`steer(direction, facing)` çağrısının ikinci argümanı olarak verilir: yana adımda bu, kameranın ileri yönüdür.
Durduktan sonra karakter baktığı yöne bakmayı sürdürür; bir tıklama ya da basılı tutma onu yeniden koştuğu yöne
çevirir.

Tuşları ya da sağ tuşu bırakın, karakter yumuşakça durur. Tuşlar olmadan tek başına sağ tuş, tıklanan noktaya koşuyu
kesmez; böylece koşarken kamerayı çevirebilirsiniz. Tuşlar ise koşuyu keser ve işaretçi solar. Tuşlar, fiziksel
konuma göre atanmış `move_forward`, `move_back`, `move_left`, `move_right` eylemleridir.

### Tuş basılıyken imleç

**Gizli** (`hide_cursor_while_held`, varsayılan açık). Koşarken imleç, özellikle kamera döndükçe dünyayla
birlikte taşınırken, yalnız titreşirdi. Basış basılı tutmaya dönünce gizlenir (kısa tıklama etkilemez); bırakılınca
nişan alınan yerde belirir. Bileşen gizli imleci oyun penceresinde tutar. macOS'ta hedef kaymasını önlemek için
`MOUSE_MODE_HIDDEN`, diğer sistemlerde `MOUSE_MODE_CONFINED_HIDDEN` kullanır. Sağ tuşla kamera dönerken kamera
imleci yakalar; sol tuş hâlâ basılıyken sağ tuş bırakılırsa imleç yeniden gizlenir. Oyun duraklayınca veya pencere
değişince hemen görünür. `is_cursor_hidden()` bileşenin gizleyip gizlemediğini söyler.

**Hedefini korur** (`keep_aim_on_camera_turn`, varsayılan açık). Sol tuş basılıyken koşu yönü ekrandaki imleçten
gelir. Kamera dönerken imleç ekranda sabit kalırsa altındaki zemin noktası değişir, karakter ona döner, kamera da
karakteri izler; karakter daire çizer. Bu nedenle bileşen nişanı dünyayla birlikte taşır: kamera koşunun arkasına
yumuşakça dönerken karakter gösterilen yöne koşar. Fare hareketi yine yönlendirir. Sağ tuşla koşarken etrafa
bakmak da aynı nişanla yönü korur.

Kapalıyken imleç araba direksiyonu gibi yönlendirir: karakterin sağına koyarsanız imleç tam önüne gelene kadar
sağa döner. Sistem imleci taşıyamıyorsa (örneğin Wayland) koşu yönü yine korunur, imleç ekranda yerinde kalır.

İmleç `_process` içinde kamera kareye yerleştikten sonra düzeltilir: bileşenin `process_priority` değeri 1,
kameranınki 0'dır. Girdi doğrudan `Camera3D` okur; kamera düzeneğini bilmez.

### Özellikler

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `mover` | — | Komut verilecek `NavigationMover`; zorunlu |
| `camera` | — | Işınlar ve yönler için kamera; boşsa görüntü kapısının (viewport) geçerli kamerası |
| `move_action` | `move_to_cursor` | Tıklama ve basılı tutma |
| `hold_mode` | `STEER` | Yukarıya bakın |
| `keep_aim_on_camera_turn` | açık | Yukarıya bakın |
| `hide_cursor_while_held` | açık | Yukarıya bakın |
| `camera_steer_action` | `camera_rotate` | Basılıyken koşu kameranın baktığı yöne gider (önce basıldıysa veya basış henüz basılı tutma olmadıysa; bkz. `look_around_while_held`). Boşsa bu koşu, etrafa bakma ve sağ tuş gerektiren tuşlar kapanır |
| `look_around_while_held` | açık | İmleci izleyen basılı koşuda sağ tuş yalnız kamerayı döndürür, koşu rotasını korur. Kapalıysa iki tuş her sırada kameraya göre koşturur |
| `keep_camera_course` | açık | Basılı koşuda sağ tuş bırakılınca fare hareket edene dek kamera yönünü korur; sonra karakterin önüne konan imleç yönlendirir. Kapalıysa imleç eski yerinden hemen devralır |
| `cursor_takeover_delay` | 0.2 s | `keep_camera_course` ile sağ tuş bırakıldıktan hemen sonraki fare hareketinin koşuyu devralmama süresi |
| `ground_mask` | 1. katman | Tıklanabilen fizik katmanları. Karakterleri ve 4. katmandaki görünmez duvarları (`bounds`) içermemeli |
| `hold_delay` | 0,2 sn | Bir basışın ne zaman basılı tutmaya dönüştüğü |
| `steer_dead_zone` | 0,5 m | `STEER`: imleç karaktere bu kadar yakınken yön değişmez |
| `stop_on_release` | kapalı | `FOLLOW_POINT`: bırakınca son noktaya koşmak yerine frenleyerek dur |
| `ray_length` | 1000 m | Kameradan atılan ışının uzunluğu |
| `keys_with_camera` | `SIDESTEP` (demoda `TURN`) | Sağ tuş + WASD modu |
| `keys_with_camera_steer` | `SIDESTEP` (demoda `TURN`) | Sol + sağ tuş + A/D modu |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | Tuşlar |

`ground_mask` tıklama ışınının fizik yüzeylerini seçer. `NavigationMover.navigation_layers` rota için yürünebilir
navigasyon bölgelerini seçer; maskeler ayrıdır. Karakteri ve görünmez duvarları tıklama maskesinden çıkarın;
yoksa ışın zemin yerine bunları seçebilir.

Tablo bileşen varsayılanlarını, kahraman sahnesinin `TURN` değerlerini belirterek gösterir. Demoda
`SettingsApplier`, kaydedilmiş `hold_mode`, imleç gizleme, iki tuş modu, etrafa bakma ve nişan koruma değerlerini
başlangıçta uygular. Bu sistem olmadan kopyalanan `playable_hero.tscn` sahne değerlerini korur.

Sinyaller: `destination_picked(point)`, `hold_started`, `hold_pending_changed(pending)` ve `run_requested`:
oyuncu yeni noktaya tıklama, basılı tutmaya dönüşen basış veya sağ tuşlu klavye yürüyüşüyle yeni koşu başlattı.
Karakterin zaten koştuğu noktaya tıklamada veya basılı koşu bitince tuşlar onu sürdürürken gelmez.
`playable_hero.tscn` içinde kameranın dönüş sonrası beklemesini bitirir (`CameraRig.end_follow_wait()`;
bkz. [Kamera](camera.md#takip-modu)).

`cancel()` sürmekte olan basışı unutur: bırakılmamış tıklama noktasına gitmez; basılı tuşun veya sağ tuşlu
klavyenin sürdürdüğü koşu yumuşakça durur (`FOLLOW_POINT` modunda da son noktaya koşmayı sürdürmez); gizli imleç
nişanın olduğu yerde görünür. Basılı kalmış fare tuşu ancak sonraki basıştan itibaren sayılır; sağ tuşlu klavye
her tikte okunur ve hemen yeniden yürür. Tıklanan hedefe koşu hareket düğümüne aittir, sürer
(`NavigationMover.halt()` onu da durdurur). Oynanabilir kahraman ışınlamadan veya kontrolleri almadan önce
bu iptal işlemini çağırır.

Bileşen başlangıçta girdi eylemlerini denetleyip eksik olanı hata olarak bildirir. Sonra onu okumaz:
tuşu çalışmaz, motor ek hata yazmaz; var olan hareket tuşları yürümeyi sürdürür. `CharacterActionInput` ve kamera
düzeneği de böyledir.

## CharacterActionInput

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `character` | — | Komut verilecek `GroundCharacter` |
| `sprint_action` | `sprint` | Shift |
| `jump_action` | `jump` | Boşluk |
| `sprint_mode` | `HOLD` | `HOLD`: tuş basılıyken depar. `TOGGLE`: bir basış deparı açar, bir sonraki kapatır; karakter bitkin düştüğünde de kendiliğinden kapanır ve dinlendikten sonra geri gelmez |

Bileşen yalnızca girdiyi iletir; depar için dayanıklılık olup olmadığına ve şu an zıplayıp zıplayamayacağına
karakter karar verir. Fizik tikinde karakterden önce çalışır (`process_physics_priority = -1`); böylece bir basış ve
bırakma karaktere fazladan bir tik gecikme olmadan ulaşır. `is_sprint_toggled()`, `TOGGLE` durumunu söyler.

### Shift takılmaz

`HOLD` modunda depar isteği her fizik tikinde okunur; Shift bırakılınca normalde hemen biter. Bazen bırakma
gömülü Game sekmesine ulaşmaz veya sistemce engellenir. `sprint_action` eylemine bağlı her tuş değiştirici
(Shift, Ctrl, Alt veya Meta) ise `CharacterActionInput` sonraki fare ve klavye olaylarının taşıdığı değiştirici
durumunu da denetleyerek takılı depar basışını bırakır. Güncel atamaları okur; oyun sırasında yeniden atama da
kapsanır. Değiştirici olmayan depar tuşlarında yalnız olağan eylem durumu kullanılabilir.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
