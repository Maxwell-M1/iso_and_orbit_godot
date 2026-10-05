<!-- translation of docs/en/systems/levels.md @ dc39dc2f669b -->
<!-- translation of docs/en/systems/levels.md @ pending -->
# Seviyeler

[← Belge dizini](../index.md)

> Bu, [İngilizce orijinalin](../../en/systems/levels.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Oyunun seviye değiştirme düzeni: seviye sunucusu ve yükleme ekranı, portallar ve doğuş noktaları, seviyeler arasında
taşınan oynanabilir kahraman ve demonun iki seviyesi. Bileşen `addons/iso_orbit/levels/` içindedir; kahraman,
yolculuk teklifi ve oyun kabuğu bu bileşenlerle kurulan demo dosyalarıdır.

## Oyun kabuğu

`gdscript/main.tscn`, oyun boyunca yerinde kalan sahnedir. Geçerli seviye sunucunun çocuğudur; kahraman ile arayüz
onun kardeş düğümleridir. Böylece seviyeler onların çevresinde değişir.

| Düğüm | Sınıf | Görev |
|---|---|---|
| `Levels` | `LevelHost` | Geçerli seviyeyi tek çocuğu olarak tutar ve değiştirir |
| `Levels/World` | | Editörde yerleştirilen başlangıç seviyesi `shared/world/world.tscn` |
| `Hero` | `PlayableHero` | Girdisi, kamerası, tıklama işareti ve yol çizgisiyle oyuncu karakteri |
| `Hud/TravelPrompt` | `TravelPrompt` | Platformdaki yolculuk teklifi |
| `LoadingScreen` | `LoadingScreen` | Seviye yüklenirken gösterilen ekran |

`gdscript/main.gd` bunları bağlar:

| Sinyal | Oyun kabuğunun yaptığı |
|---|---|
| `LevelHost.portal_entered(portal)` | Portal otomatik geçirmiyorsa teklifini gösterir. İki portalın alanındayken son girilenin teklifini gösterir |
| `LevelHost.portal_exited(portal)` | Bu teklifi gizler; kahraman başka portalda duruyorsa onun teklifini gösterir |
| `TravelPrompt.confirmed(portal)` | `portal.travel()` |
| `LevelHost.level_change_started` | Teklifi ve HUD'ı gizler, kahramanın kontrollerini kapatır |
| `LevelHost.level_loaded(level, spawn)` | Daha önce bulunan yerleri bulundu olarak işaretler; kahramanı kamera arkasında olacak biçimde `spawn` noktasına koyar; ekranın altında HUD'ı gösterir |
| `LevelHost.level_change_finished` | Kontrolleri yeniden açar |
| `LevelHost.level_change_failed` | HUD'ı ve kontrolleri yeniden açar; kahraman hâlâ portaldaysa teklifini gösterir |

Başlangıçta kabuk, kahramanı başlangıç seviyesinin `default` doğuş noktasına koyar; kamera kendi ilk açısındadır
(`OrbitCameraRig.start_yaw`). Portaldan varıldığında kamera doğuş noktasının baktığı yöne döner. Bulunan yerler,
oturum boyunca seviye dosyası ve yerin içindeki yoluyla hatırlanır. Seviye yeniden yüklenince
`PointOfInterest.mark_discovered()` bunları bulundu olarak işaretler; ikinci kez duyurulmazlar. Kayıt sistemi aynı
listeyi saklayabilir.

Kahraman örneği geçiş sırasında yerinde kalır; dayanıklılığı, görünümü ve süzülme durumu korunur. Işınlama
hareketini temizleyip kamera takibini sıfırlar; oyuncunun ayarları `Settings` otomatik yüklemesinde kalır.

## Seviye geçişi

Oyuncu platforma basıp E'ye veya teklife tıklar:

1. Portal yolculuk ister; seviye sunucusu dosyayı kontrol eder, yükleyiciden ister ve hemen yanıt verir. Geçiş,
   isteğin içinde değil hemen ardından başlar: portal isteği fizik geri çağrısından gönderir; o sırada seviye sahne
   ağacından çıkmamalıdır. Başlangıç `level_change_started` ile bildirilir.
2. Oyun zaten duraklamadıysa duraklar. Duraklıyken kamera imleci bırakır, girdi onu gösterir.
3. Yükleme ekranı sonraki çizilen kareyi alır (HUD gizlenmiştir), bulanıklaştırıp karartır ve 0.35 sn'de görünür.
   Kare yavaşça %6 yaklaşır; yer adı ile bir ipucu görünür ve çubuk ilerler.
4. Seviye sahnesi arka planda yüklenir (`ResourceLoader.load_threaded_request`). Dosyaları çubuğu %85'e,
   kurulmuş seviye %90'a doldurur.
5. Eski seviye ağaçtan çıkarılıp serbest bırakılır; yenisi yerine girer. `level_loaded`, kahramanın nereye
   konacağını kabuğa bildirir. Yeni portallar bağlanır; eskiler çıkmadan önce ayrılmıştır. Bu arada başka bir
   işlem duraklamayı bitirmişse (kapanan bir pencere), sunucu yer değiştirme için oyunu yeniden duraklatır.
6. Oyun duraklıyken sunucu, navigasyon haritasının yeni seviyeyi kabul etmesini bekler (%95): seviyenin tüm
   navigasyon bölgeleri haritaya girer; ancak gerçek zamanla `navigation_timeout` süresinden uzun beklemez.
   Navigasyon sunucusu oyun duraklıyken de çalıştığından ilk oyun karesinde yeni seviyede yol bulunabilir.
7. Duraklama biter; sunucu ekranın arkasında `warmup_frames` kare çizer: yeni seviyenin gölgelendiricileri
   derlenir, kahraman zemine yerleşir.
8. Başlangıçtan beri `min_loading_time` geçtiğinde çubuk sona dolar, ekran silinir ve
   `level_change_finished` gelir.

Seviye sunucusunun ayarları:

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `loading_screen` | boş; demo kendi `LoadingScreen` düğümünü atar | Yüklenirken oyunun üzerindeki ekran. Boşsa seviye oyuncunun gözünün önünde değişir |
| `min_loading_time` | 0.6 s | Hızlı yüklemede bir anlık parlamayı önlemek için ekranın en kısa kalış süresi |
| `warmup_frames` | 3 | Ekran kalkmadan arkasında çizilen kareler; yeni seviyenin gölgelendiricileri görünmeden derlenir |
| `navigation_timeout` | 2 s | Navigasyon haritasını gerçek zamanla en uzun bekleme; tüm bölgeler girince hemen biter. 0: bekleme yok; o zamana dek yol eski haritada veya hiç harita olmadan aranabilir |

Sinyaller ve yöntemler:

| Sinyal veya yöntem | Anlamı |
|---|---|
| `level_change_started(path)` | Geçiş başladı; eski seviye hâlâ yerinde |
| `level_loaded(level, spawn)` | Yeni seviye yerinde, eski seviye kaldırıldı; karakteri `spawn` noktasına koyun. Ekran oyunu hâlâ örter |
| `level_change_finished(level)` | Geçiş bitti, ekran kalktı |
| `level_change_failed(path, error)` | Seviye değiştirilemedi, eskisi kalır: yükleme hatasında `ERR_CANT_OPEN`, sahne kökü `Node3D` değilse `ERR_INVALID_DATA`. `level_change_finished` yerine gelir |
| `portal_entered(portal)`, `portal_exited(portal)` | Yolcu geçerli seviyenin portalına girdi veya çıktı |
| `change_level(path, spawn_name = &"default", title = "")` | Geçişi başlatıp hemen döner; aşağıya bakın |
| `get_current_level()` | Oyunun bulunduğu seviye; ilki öncesinde `null` |
| `is_changing()` | Kabul edilmiş `change_level()` çağrısından `level_change_finished` veya `level_change_failed` sinyaline kadar geçiş sürer |
| `find_spawn_point(spawn_name = &"default", level = null)` | Seviyenin doğuş noktası; bkz. [Doğuş noktaları](#doğuş-noktaları) |

Editörde yerleştirilen başlangıç seviyesi duyurulmaz: onun için `level_loaded` gelmez. Oyun,
`gdscript/main.gd` gibi, `_ready()` içinde `get_current_level()` ve `find_spawn_point()` ile kurar.

Geçiş sürerken yeni istek reddedilir (`ERR_BUSY`); ikinci E basışı veya o sırada girilen portal etkisizdir.
`change_level()` dosyayı hemen denetler: bulunmayan dosya `ERR_FILE_NOT_FOUND`, sahne olmayan dosya
`ERR_INVALID_PARAMETER` döndürür; başka işlem olmaz. Yüklenemeyen veya kökü `Node3D` olmayan sahnede geçerli
seviye korunur: çıktıya hata yazılır, duraklama biter, ekran `min_loading_time` beklemeden kalkar, sonra
`level_change_failed` gelir. Başarısız yükleme temizlenir; örneğin düzeltmeden sonra yeni istek dosyayı baştan
yükler.

Sunucu yalnız kendi başlattığı duraklamayı bitirir. Oyunu duraklatan pencereyi (menüyü) ancak
`level_change_finished` sonrasında açın: geçiş sırasında açılırsa oyunu duraklı bulup duraklamayı sunucuya bırakır;
sunucu bitirince oyun pencerenin arkasında sürer. Demoda yükleme ekranı kapanana dek F10 dahil girdiyi engellediği
için bu kural kendiliğinden sağlanır. Geçiş sırasında pencere kapanırsa sorun olmaz: sunucu yer değiştirme için
yeniden duraklatır. Geçiş ortasında sunucu ağaçtan çıkarsa (oyun sahnesi değişirse) geçiş ve duraklama onunla biter.

Ekran, çubuğu ve `min_loading_time`, `Engine.time_scale` ne olursa olsun gerçek zamanla ilerler: yavaş çekimde de
geçiş tam hızla aynı süreyi alır. Isınma, ilk kullanım işlemlerinin bir kısmını ekranın ardında gizler; ilerideki
gölgelendirici veya varlık takılmalarını önleme garantisi değildir. Geçişleri kendi seviye içeriğinizle ve hedef
çizicinizle ölçün.

## Portallar

`LevelPortal` bir `Area3D` alanıdır: platform, kapı veya harita sınırı olabilir. Çarpışma şekli ve yolcunun
katmanını (2, karakterler) gören `collision_mask` gerekir; kendi katmanı gerekmez. Seviye sunucusu geçerli
seviyenin portallarını, örneğin görevden sonra eklenenleri de bağlar.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `target_level` | | Gidilecek seviyenin sahne dosyası. Yüklü sahne yerine yol olduğundan iki seviye birbirine açılabilir; Inspector'da seçilen `uid://` yolu da çalışır |
| `target_spawn` | `default` | Varılacak doğuş noktası |
| `title` | | Portalın götürdüğü yerin adı; teklif, yükleme ekranı ve tabela için. Gösterildiği yerde çevrilir |
| `title_label` | | Portalın `title` değerini yazdığı üzerindeki `Label3D` |
| `traveller_group` | `player` | Geçebilenler: bu gruptaki gövdeler |
| `auto_travel` | kapalı | Teklif olmadan, yolcu girer girmez geçiş |

Kullanım biçimleri:

- **Varsayılan demo platformları:** Portal yolcunun giriş çıkışını (`traveller_entered`, `traveller_exited`)
  bildirir; seviye sunucusu `portal_entered` ve `portal_exited` olarak aktarır; oyununuz teklifini belirler. Kabuk,
  "E ile <yere> ışınlan" teklifini gösterir; uzaklaşınca gizler. Kahraman çoğu zaman deparda platforma girdiği
  için E, Shift veya başka değiştirici tuş basılıyken de çalışır. `travel()` geçişi başlatır.
- **`auto_travel` açık:** kapı veya harita sınırı. Yolcu girer girmez geçirir; kabuk teklif göstermez.
- **Yükleme ekranı yok:** `LevelHost.loading_screen` boş bırakılır. Seviye yine arka planda yüklenir; yer değiştirme
  ve navigasyon için oyun duraklar, fakat oyuncu değişimi görür.
- **Kodla kullanılan portal:** `LevelHost.change_level(path, spawn_name, title)` portal ile aynı işi yapar; ara
  sahne veya menü çağırabilir.

`travel()` ve girişteki `auto_travel`, `travel_requested(portal)` yayar; sunucu bu sinyali bağlar, sunucusuz oyun
kendisi bağlar. `has_traveller()` o anda portalda yolcu olup olmadığını söyler. Her portal `level_portals` grubundadır.

Portal alanının içinde beliren karaktere hemen geri dönüş teklif edilir. `auto_travel` portalındaysa fizik yeniden
çalıştığında, ısınma sırasında, geçiş hâlâ sürerken görülür: istek `ERR_BUSY` alır, sunucu bunu yok sayar ve
karakter çıkıp yeniden girene dek geçmez. Geçiş bittiyse hemen geri geçer. Bu nedenle doğuş noktalarını
platformların yanına, portal alanlarının dışına koyun.

## Doğuş noktaları

`SpawnPoint`, varsayılan olarak `default` adlı `spawn_name` taşıyan bir `Marker3D` düğümüdür. Karakter işaretçinin
konumunda belirir; düğümün ileri yönü olan −Z'ye bakar (gizmonun mavi ekseni ters yönü gösterir).
`get_facing()` bu yatay yönü verir. İşaretçiyi yere koyun: karakterin ayakları oraya yerleşir; üstteyse düşer.
Her doğuş noktası `spawn_points` grubundadır.

`LevelHost.find_spawn_point(name, level)`, belirtilen `level` içindeki (verilmediyse geçerli seviye; ağaçta olmalı)
o adlı noktayı, yoksa `default` noktayı, o da yoksa `null` döndürür. Geçişte bulunamayan nokta çıktıya uyarı da
yazar; hiç nokta yoksa sunucu seviyenin kendisini `spawn` olarak verir: karakter seviye kökenine varır. Her seviyeye
bir `default` nokta koyun: oyun orada başlar, `target_spawn` belirtmeyen portal oraya varır. Ad, düğümün adı değil
`spawn_name` değeridir: demodaki `default` noktaların düğüm adları `Start` ve `Arrival` olur. Diğer noktalara
ayrı ad verin: ikinci nokta `default` bırakılırsa o da `default` olur ve bu ad istendiğinde ağaç sırasındaki ilki
seçilir.

## Yükleme ekranı

`LoadingScreen`, pencerelerin üstünde 20. katmanda bulunan, oyun duraklıyken çalışan bir `CanvasLayer` düğümüdür.
Açıkken oyuna hiçbir girdi olayı ulaşmaz; tıklama ve F10 etkisizdir (`Input` basılı tuşları yine bilir).

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `tips` | boş; demo `gdscript/main.tscn` örneğinde altı kontrol ipucu ayarlar | Rastgele sırayla teker teker gösterilir; önce çevrilir, sonra `tip_format` üzerinden geçer |
| `tip_format` | boş (kodun atadığı `Callable`); demo `gdscript/main.gd` içinde `InputNames.format` atar | Çevrilmiş ipucunu gösterilecek metne çevirir. Demoda `{sprint}` gibi simgeleri `InputNames.format` geçerli tuşlarla değiştirir; bkz. [Metinlerde tuş adları](ui.md#metinlerde-tuş-adları). Boşsa ipucu çevrildiği gibi gösterilir |
| `tip_time` | 6 s | Her ipucunun kalış süresi; ardından 0.25 sn'de solar, metin değişir ve yenisi 0.25 sn'de belirir |
| `fade_time` | 0.35 s | Ekranın belirme ve kalkma süresi |
| `zoom` | 0.06 | Arka planın boyutuna oranla ne kadar yaklaşacağı |
| `zoom_time` | 12 s | Bu yaklaşmanın süresi |

Arka plan, oyunun sekiz kez küçültülmüş ve gölgelendiriciyle biraz daha bulanıklaştırılmış son karesidir
(`loading_background.gdshader`: bulanıklık, kararma, koyu köşeler ve yazının altında koyu alt bölüm).
Pencerenin çizmediği durumda (penceresiz çalışma veya simge durumuna küçültülmüş pencere) kare yoktur, ekran düz
koyu renktir. Çubuk gerçek ilerlemenin çok gerisindeyken ona hızla yaklaşır ve yükleyici daha düşük değer bildirse
bile geri gitmez.

Görünüm, ekran kökünün teması `loading_screen_theme.tres` içindedir: `LoadingTitle` (44 px, gölgeli sıcak beyaz),
`LoadingBar` (ince altın renkli çubuk) ve `LoadingTip` (18 px) tür çeşitleri. Başka görünüm için köke başka tema
atayın veya `loading_screen.tscn` kopyasından ekran oluşturun: düğümleri taşıyıp değiştirebilirsiniz, ancak betik
`Control` türündeki `Root`, benzersiz adlı `TextureRect` türündeki `Background`, `Label` türündeki `Title` ve `Tip`
ile `ProgressBar` türündeki `Bar` düğümlerini ister. `LoadingScreen` türevi betik `open()`, `set_progress()` ve
`close()` yöntemlerini geçersiz kılabilir; sahne yine bu düğümleri içermelidir. Sorgular: `is_open()` (ekran açık,
açılıyor veya kapanıyor), `get_shown_progress()` (çubuğun 0 ile 1 arasındaki doluluğu), `get_tip()` (görünen
ipucunun kaynak şablonu; ipucu yoksa boş). `refresh()` zamanlayıcıyı sıfırlamadan ipucunu yeniden çevirip
biçimlendirir. Demo ekranı `ActionTexts.GROUP` içine ekler; böylece tuş adları yenilenince açık ipucu da güncellenir.

## Oynanabilir kahraman

`gdscript/player/playable_hero.tscn`, oyun sahnesine koymaya hazır, oyuncunun denetlediği kahramandır:
`player` grubundaki karakter (`player.tscn`), `PointClickMoveInput`, `CharacterActionInput`, koluyla ve
kamerasıyla kamera düzeneği, tıklama işareti ve yol çizgisi; ayarları ve sahnedeki altı bağlantısıyla birlikte.
Karakter sahnesi bu bileşenleri içermez; aynı `player.tscn` yapay zekâyla da sürülebilir.

`PlayableHero` (`playable_hero.gd`) parçaları türlendirilmiş özellikler olarak sunar: `character`, `input`,
`actions`, `camera_rig`, `camera_arm`, `camera`, `click_marker`, `path_view` ve karakterin `sounds`, `appearance`,
`hover`, `silhouette` alanları. Bunlarla üç işlem yapar:

| Çağrı | Etki |
|---|---|
| `teleport(position, facing = Vector3.ZERO, turn_camera = true)` | Sürmekte olan basış unutulur (`PointClickMoveInput.cancel()`), karakter anında yerleştirilir (`GroundCharacter.teleport()`), istendiyse kamera `facing` yönüne döner, yerine oturur ve takibi baştan başlatır. `facing` değeri `Vector3.ZERO` kalırsa karakterin bakışı ve kameranın yönü korunur |
| `place_at(marker, turn_camera = true)` | İşaretçinin −Z yönüne bakarak ona `teleport()` eder |
| `controls_enabled` | Kapalıyken basış unutulur, depar tuşu bırakılır ve girdi düğümleri durur; kamera oyuncuda kalır. Tıklanmış noktaya koşu sürer: `character.mover.stop()` veya `teleport()` ile durdurun. Açılınca kontroller ve girdi işlemleri geri gelir |

Kahraman kökü hiç taşınmaz: karakter içinde hareket eder, kamera karakteri izler. Kahraman seviye bileşeni olmadan
da çalışır: kendi seviye sisteminizde seviyeler hazır olduğunda `place_at()` çağırın.

## Demonun seviyeleri

**Çayır** (`shared/world/world.tscn`; bkz. [Dünya ve navigasyon](world-and-navigation.md)) sahnesinde `Travel`
altında şunlar vardır: kökende kuzeye bakan `Start` (`default`) doğuş noktası; başlangıcın 12 m kuzeyindeki,
görülebilen Ancient Circle yanındaki adaya açılan `IslandPad` platformu; ve platformun yanında doğuya bakan,
platformu kahramanın biraz geride solunda bırakan `FromIsland` (`from_island`) doğuş noktası.

**Issız Ada** (`shared/world/island/island.tscn`) gölün ortasında 30 m genişlikte yuvarlak bir adadır. Çayırın
nesnelerini, malzemelerini ve gölgelendiricilerini kullanır; iki malzeme dışında kendine özgü dosyası yoktur:

- Çim `island_ground.tres` kaynağıdır: yollar dünya koordinatlarında çizilip çayıra ait olduğundan çayır
  zemininin toprak yolları (`roads`) kapatılmıştır.
- Göl `lake_water.tres` kaynağıdır: kuyunun durgun suyunun daha açık mavi, daha güçlü dalgalı çeşidi; ufka uzanan
  600 m'lik düzlem.
- Çim kenarının altında kayalık kıyı ve sığ suda kayalar vardır.
- 14.5 m uzaklıktaki görünmez duvar halkası (`Edge`, 24 kutu) kahramanı adada tutar. Karakterin çarpıştığı,
  tıklamanın ve kameranın görmediği `bounds` fizik katmanındadır (4). Dolayısıyla suya tıklama duvara isabet etmez,
  kamera içlerinden geçer. Ada navigasyon örgüsü 1 ve 4 katmanlarından pişirilir; yollar duvarlardan uzak durur.
- Kuzeydeki Münzevinin Kampı, çadır, kamp ateşi ve varillerden oluşan keşfedilebilir yerdir; `PointOfInterest`
  düğümü `Places` altındadır.
- Güneyde kuzeye, kampa doğru bakan `Arrival` (`default`) doğuş noktası ve kahramanın sol arkasındaki çayıra dönen
  `HomePad` platformu vardır (varış noktası `from_island`).
- Kendi navigasyon örgüsü çayırınki gibi pişirilir; bkz. [Navigasyon örgüsünü yeniden
  pişirme](world-and-navigation.md#navigasyon-örgüsünü-yeniden-pişirme).

İki seviye de göğü, sisi ve ortam ışığını veren `shared/world/world_environment.tres` ortamını paylaşır. Her
seviyenin kendi güneş (`Sun`) kopyası vardır. Platformlar (`shared/world/props/teleport_pad.tscn`) tek sahnedir:
taş diskli, ışıklı kakmalı, baş yüksekliğinin üstünde dönen kristalli, ışıklı ve yer adını gösteren tabelalı bir
`LevelPortal`. Çarpışmaları yoktur; altlarındaki navigasyon örgüleri bu yüzden değişmemiştir.

## Seviye ekleme

1. Kökü `Node3D` olan sahne kurun: seviyenin ışığı ve ortamı, zemin ve nesnelerle `NavigationRegion3D`, zeminde
   `spawn_name` değeri `default` olan `SpawnPoint`. Kenardaki görünmez duvarlar 4. katmana (`bounds`) girer.
2. Bu seviyeye özgü `NavigationMesh` oluşturup pişirin: statik çarpışmaları, 1. fizik katmanını ve görünmez kenar
   duvarları varsa 4. katmanı kullanın. Haritanın 0.025 m hücre yüksekliğine, 0.25 m hücre boyuna uyun. 0.5 m
   yarıçap, 0.3 m en yüksek çıkılabilir basamak ve 40° en yüksek eğimle başlayın. Sağlanan 1.8 m kapsül için
   1.8 m etmen yüksekliği seçip alçak tavanları çıkarmak için `filter_walkable_low_height_spans` açın. Demo örgü
   kaynağını kopyalarsanız yeniden pişirmeden önce benzersiz yapıp yükseklik/filtre ayarını inceleyin. Bkz.
   [Dünya ve navigasyon](world-and-navigation.md#fizik-katmanları-ve-navigasyon).
3. Başka seviyeden buraya portal ekleyin: `teleport_pad.tscn` örneği veya kendi `LevelPortal` düğümünüzün
   `target_level` alanı yeni sahne olsun; geri dönüş portalı da ekleyin. Her platformun yanına doğuş noktası koyup
   adını karşı portalın `target_spawn` alanına yazın.
4. Portal ve yer adlarını çevirilere ekleyin: `localization_checks.gd`, başlangıç seviyesinden portallarla
   erişilen her seviyeyi dolaşıp eksik metinleri bildirir. Yalnız koddan `change_level()` ile erişilen seviyeyi
   denetlemez.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
