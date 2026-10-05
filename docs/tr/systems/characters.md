<!-- translation of docs/en/systems/characters.md @ 48c5e73646e2 -->
# Karakterler

[← Belge dizini](../index.md)

> Bu, [İngilizce orijinalin](../../en/systems/characters.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Karakter modelleri bir betikle ilkel şekillerden (kapsüller, silindirler, küreler, prizmalar) oluşturulmuştur ve
mantıktan ayrı olarak `shared/characters/` içinde bulunur. Aynı model kahramanın modeli olabilir ya da seviyede
durabilir.
Hazır kahramanı dosyalarıyla başka projeye kopyalamak için
[Aktarma](../integration.md#demonun-kahramanını-projenize-aktarma) kılavuzunu izleyin.
[Yapılandırmalar](../configurations.md) kontrol ve kamera seçeneklerini gösterir.

## Modeller ve ekipman

| Model (`shared/characters/models/`) | Kim | Ekipman |
|---|---|---|
| `knight.tscn` | Şövalye: plaka zırh, T biçimli siperlikli ve kırmızı sorguçlu kova miğfer, haçlı kırmızı üstlük, omuzluklar | Kılıç, haçlı yuvarlak kalkan |
| `ranger.tscn` | Korucu: kuyruklu yeşil kukuleta, gölgesinde soluk gözler, sırtında ok sadağı | Yay |
| `mage.tscn` | Büyücü: altın kenarlı çan biçimli mor cüppe, bükük sivri şapka, beyaz sakal | Halkalı, parlayan, havada süzülen bir küre, bir büyü kitabı |
| `dwarf.tscn` | Cüce: kısa ve geniş, boncuklu kızıl sakal, bir burun, boynuzlu miğfer | İki elli balta |
| `rogue.tscn` | Haydut: koyu kukuleta, sarı gözler, kırmızı maske, üç parçalı pelerin, kemer kesesi | İki hançer, soldaki ters tutuşta |

Yukarıdaki beş bağımsız modelin uyduğu kurallar:

- −Z yönüne bakar, ayakları orijindedir.
- Elleri boş `RightHand` ve `LeftHand` düğümleridir, yani "görünmez eller". `equipment/` içinden bir sahne (asa,
  kılıç, kalkan, yay, balta, hançer, kitap, küre) bir ele konur; ekipmanın orijini tutulduğu yerdir. Bir silahı
  değiştirmek için el düğümünün alt düğümünü değiştirin: oyunda çalışma anında ya da model sahnesinde kalıcı olarak.
  Nesnenin eğimi, eldeki dönüşüdür.
- Ortak ekipman malzemeleri (çelik, pirinç, deri, kemik, parlayan taşlar ve gözler) `materials/` içindedir; gövde ve
  giysi renkleri model sahnelerinin içindedir.

## Kahraman görünümleri

Kahraman, `Hero/Character/Visual/Hover/Model` konumundaki on büyücü görünümünden biridir (varsayılan görünüm
8, Ölü Çağıran). `Visual` ile döner; süzülme açıksa `Hover` ile yükselir. Asa sağ eldedir. Bütün görünümler
oyuncunun ayrı çarpışma kapsülüne uyacak boydadır; kendi gözleri (`EyeRight`, `EyeLeft`) ve `RightHand` içinde
asaları vardır. Bu nedenle her biri kahraman olabilir.

| # | Görünüm | Onu farklı kılan |
|---|---|---|
| 1 | Fırtına Büyücüsü | Şimşekli ve parlayan etekli arduvaz renkli bir cüppe, omuzlarda fırtına bulutları, kıvılcım saçan sorguçlu bir kukuleta ve gölgesinde kısılmış kıvılcım gözler, yıldırım toplu bir asa |
| 2 | Zaman Büyücüsü | Bronz süslü turkuaz bir cüppe, göğüste bir saat kadranı, bir saat halesi, havada süzülen dişliler, kehribar camlı pirinç gözlükler, kum saatli bir asa |
| 3 | Kukuletalı Mistik | Derin bir kukuleta ve pelerin; yüz yok, gölgede yalnızca parlayan iki kehribar göz |
| 4 | Yıldız Gözcüsü | Yıldızlı gece mavisi bir cüppe, aylı bir şapka, yukarıya yıldızlara bakan iri gözler, halkalar içinde yıldızlı bir asa |
| 5 | Ateş Büyücüsü | Eteğinde, omuzlarında ve taç olarak alevler bulunan al bir cüppe, öfkeli ateşli gözler, bir ateş asası |
| 6 | Buz Büyücüsü | Kürklü beyaz bir cüppe, buz tacı ve omuzlarda kristaller, sakin parlak mavi gözler, bir kristal asa |
| 7 | Druid | Kahverengi bir cüppe, yapraklardan bir pelerin, dallı boynuzlar, yarık gözbebekli kehribar hayvan gözleri, tohumlu boğumlu bir asa |
| 8 | Ölü Çağıran | Yırtık etekli siyah-mor bir cüppe, yelpaze yaka, göz çukurlarında yeşil ışıklar, omzunda ve asasında bir kafatası |
| 9 | Başbüyücü | Beyaz ve altın rengi cüppeler, bir sakal, safirli uzun bir şapka, nazik safir gözler ve bir monokl, belinin çevresinde bir rün halkası |
| 10 | Savaş Büyücüsü | Kısa bir cüppe, plaka omuzluklar, bir pelerin, kemerde iksirler, kalçada bir kitap, sert kaşların altında altın gözler, mızrak asa |

Modeller `shared/characters/models/mage_options/` içinde, asaları `equipment/staff*.tscn` içindedir. El gövde
ekseninden 0,52 m uzaktadır, böylece asanın alt ucu cüppeye gömülmez; Başbüyücü asayı 0,55 m'de, Savaş Büyücüsü
0,49 m'de tutar. Kahraman görünümlerinde yalnızca bir `RightHand` vardır; Savaş Büyücüsü'nün kitabı `LeftHip`
noktasında asılıdır.

Başlangıç seviyesi `shared/world/world.tscn` içinde on görünüm güney duvarının güneyinde, sırtları duvara dönük
olarak (duvardaki boşluğun doğusunda), güneye
bakarak ve her birinin başının üstünde numarasıyla sıra hâlinde durur. Sıranın tamamının önünde açık bir geçit
vardır.

## CharacterAppearance

Modeli çalışma anında değiştirir (Ayarlar → Karakter → **Kahraman görünümü**). `set_look(number)` eski modeli
kaldırır ve yenisini aynı adla onun yerine koyar. Ayrıca yeni modelin fizik enterpolasyonunu sıfırlar (aksi hâlde
model orijinden kayarak gelirdi) ve yeni modelin `RightHand` düğümünü `HandSway` bileşenine verir; böylece asa
yeniden adımlarla sallanır. Siluet yeni örgüleri kendiliğinden alır.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `slot` | — | Modeli tutan düğüm (oyuncuda `Visual/Hover`: `GroundCharacter` tarafından döndürülen `Visual` altındaki süzülme) |
| `model_name` | `Model` | `slot` içindeki model düğümünün adı |
| `models` | — | Seçilebilecek model sahneleri; görünüm numarası, 1'den başlayarak bu listedeki sıradır |
| `hand_sway` | — | Yeni modelin elini kimin alacağı; boşsa el sallanmaz |
| `hand_path` | `RightHand` | Nesne tutan elin modeldeki yeri |

`get_look()` geçerli numarayı (listede olmayan bir model için 0), `get_model()` model düğümünü döndürür. Sinyal:
`look_changed(model)`.

### Oynanabilir kahramanda kendi modelinizi kullanma

1. Kopyaladığınız `playable_hero.tscn` sahnesinin kullandığı `gdscript/player/player.tscn` dosyasını düzenleyin
   veya kahramanın `Character` örneğini kendi sahnenizle değiştirin; düğüm yollarını koruyun ya da kahramanın
   dışa aktarılan başvurularını yeniden atayın. `Visual/Hover/Model` yerine model sahnenizi koyun, kök adını
   `Model` yapın. Ayakları yerel kökende, önü −Z yönünde olsun. Farklı yöne bakan örgüyü kendi sahnesinde
   düzeltin; `Visual` düğümü `GroundCharacter` dönüşüne serbest kalsın. Çarpışma kapsülü modelden ayrı olarak
   gövdededir: yeni boyut gerekecekse `CollisionShape3D` değiştirip navigasyonu yeniden pişirin; bkz.
   [Dünya ve navigasyon](world-and-navigation.md#fizik-katmanları-ve-navigasyon).
2. Görünüm değiştirmek istiyorsanız sahneleri `Appearance.models` listesine koyun; numaralar 1'den başlar.
   Her birinde `Appearance.hand_path` konumunda (varsayılan `RightHand`) el düğümü olsun. El yoksa
   `RightHandSway` bileşenini kaldırıp `Appearance.hand_sway` alanını boşaltın. Böylece
   `CharacterAppearance.set_look()` sallanmayı yeni ele aktarır, siluet de yeni örgüleri kendisi bulur.
3. Tek model kullanacaksanız `Appearance` düğümünü kaldırın, kahramanın `appearance` başvurusunu temizleyin.
   Elde nesne yoksa `RightHandSway` da kaldırılabilir. Tam demoda `Appearance` tutulursa `models` listesini de
   değiştirin: `SettingsApplier` başlangıçta kaydedilmiş görünüm numarasıyla `set_look()` çağırır; eski liste
   büyücü modeline geri dönerdi.

Model kapsüle ve yakın tavanlara sığmalıdır. Süzülen model gövdeyi ve çarpışmasını taşımadan yükselir; üstte yer
bırakın veya `Hover.enabled` kapalı olsun. `Silhouette.target` ve `CameraArm.fade_target` zaten `Visual` düğümünü
gösterir; altındaki yeni model de kapsanır.

## HandSway: elde tutulan, yana yapışık olmayan bir asa

`HandSway` (oyuncuda `RightHandSway`) modelin el düğümünü dinlenme konumuna göre hareket ettirir:

- **Adımlarla**, ayak seslerinin de izlediği ritim olan `GroundCharacter.get_step_phase()` ile. Her adımda el bir uç
  noktadadır (sırayla önde ve arkada, ±7 cm) ve en alçaktadır (2,5 cm); adımların ortasında el ortadadır. Nesne
  eğimde biraz geride kalır (±7°). Sallanma hızla büyür, deparda bir buçuk kat daha büyüktür ve karakter durduğunda
  veya havadayken söner. Adımlar sayılmıyorsa (`is_counting_steps()` false: `steps_enabled` kapalı veya kahraman
  süzülüyor) sallanma da söner; adımlarla geri gelir.
- **Koşarken** nesne öne eğilir (6°).
- `GroundCharacter.get_local_acceleration()` değerinden yay üzerindeki **atalet** (1.8 Hz, sönümleme 0.45):
  hızlanmada üst uç geriye, frenlemede öne, dönüşlerde dışa gider ve durulana kadar salınır. Basamaklar onu
  sarsmaz. Yere değince el iner; düşüş ne kadar hızlıysa o kadar derine (`touched_floor`, yumuşak inişte de biraz).
  Kalkışta da biraz iner. `tilt_per_acceleration` (0.45°) pozitifken nesne geride kalır; negatifse ivmeye eğilir.
  Yay, `CharacterHover` tarafından da kullanılan `DampedSpring` bileşenidir.

Fizik tikinde gövdeden sonra çalışır; böylece fizik enterpolasyonu onu da gövde gibi yumuşatır. Adım ritmi
süreklidir: adımın ortasında durursanız bir sonraki adım, yeniden başladıktan `first_step_distance` sonra gelir, ancak
faz sıçramaz; o adımda tam sayıya ulaşır. Başka bir el veya bir NPC için kendi eliyle birlikte başka bir `HandSway`
ekleyin. Genlikler, eğilme ve yay, Swing (sallanma) ve Inertia (atalet) gruplarındaki dışa aktarılmış özelliklerdir.

## CharacterHover: yerden yüksekte süzülme

`CharacterHover`, `GroundCharacter` modelini süzülür gibi gösterir: model yerden `height` kadar yukarıda durur,
basamaklara sıçramadan üzerlerinde kayar, hafifçe yükselip alçalır, harekete ve ivmeye doğru eğilir, inişte biraz
çöker. Yalnız model hareket eder. Gövde normal yürür: eğimler, basamaklar, zıplama ve kenar koruması aynı çalışır;
yol ve kamera da öyle. İsteğe bağlı `FallSettings`, aşağı ivmeyi ve en yüksek düşüş hızını değiştirebilir;
sağlanan kahraman bunu yavaş iniş için kullanır. Demoda Ayarlar → Karakter → **Yerden yüksekte süzül** açar.

Düğüm, karakterin döndürdüğü düğümle model arasına girer:

```
Player (GroundCharacter)   demoda Hero/Character
└── Visual            GroundCharacter tarafından gidiş yönüne döndürülür
    └── Hover         CharacterHover: kendisini yükseltir ve eğer
        └── Model     görünüm; CharacterAppearance.slot = Visual/Hover
```

Karakter yalnız `Visual` dönüşünü, süzülme düğümü yalnız kendi dönüşümünü yazar; aynı düğüm için yarışmazlar.
Yeni `CharacterAppearance` görünümü süzülme düğümünün altına (`slot`) gelir; siluet ve kamera saydamlaşması
modeli kendileri bulur. Eğim `Visual` eksenlerinde uygulanır; modelin başka yöne bakması için sahnede döndürülmüş
süzülme düğümü de hareket yönüne eğilir.

### Adımlar

Varsayılan olarak süzülme adım olaylarını durdurur. Bunu
`GroundCharacter.set_steps_suppressed(self, true)` ile yapar: `stepped`, ayak sesi ve asanın adım sallanması yoktur.
Model zemine geri yerleşince serbest bırakır; `steps_enabled` açıksa adımlar yeniden sayılır. Süzülme düğümü
`steps_enabled` değerini değiştirmez: oyunun anahtarı yerinde kalır, birkaç bileşen birbirini geri almadan
adımları durdurabilir. Ağaçtan çıkınca adımları serbest bırakır, geri girince yine durdurur.
`steps_while_floating`, adımları korur; örneğin adım ritmiyle yerden itilen canlı için.
`GroundCharacter.is_counting_steps()` o anda sayılıp sayılmadığını bildirir.

### Düşüş

`fall` alanı doluysa (`FallSettings`; bkz. [Hareket](locomotion.md#düşüş)), model süzülürken kahramanın kendi
düşüşünün yerine bu kaynak konur: yükselmenin başından yeniden yerleşene kadar
(`GroundCharacter.set_fall_override(self, fall)`, öncelik 0). Zıplamanın tepesinden sonra ve kenardan aşağı
karakter daha yavaş hızlanır, sınır hıza gelir; zıplamanın yükselişi değişmez. Düşüş ortasında süzülme açılırsa
`braking_time` süresinde sınıra yavaşlar; kapatılırsa model yerleşene dek yavaş düşmeye devam eder, sonra olağan
hızlanmaya döner. Ağaçtan çıkınca süzülme düşüşü geri verir. Boş `fall`, karakterin kendi düşüşünü korur.
Süzülme düğümü her yükseliş başında kaynağını yeniden koyar; öncelik 0 arasında en yeni olur. Oyunun daha yüksek
öncelikle koyduğu düşüş bunu geçer. Süzülürken verilen yeni `fall`, eskisinin yerini alır.

Demodaki süzülme, `gdscript/player/player_floating_fall.tres` kullanır: gövdenin 3 değeri yerine 0.5 yerçekimi
ölçeği ve en fazla 2 m/s aşağı hız. Süzülen kahraman, 1 m zıplamanın tepesinden 0.25 s yerine 0.68 s'de iner;
2 m/s ile zemine değer. Bu `landing_min_speed` (2.5 m/s) altındadır: yumuşak temas, `landed` ve iniş sesi yoktur.

### Zemini nasıl izler?

Model, zeminin yumuşatılmış yüksekliğinin üstünde süzülür. Gövde zemindeyken ilerisine bakar ve bulduğu zemine
`glide_time` içinde yaklaşır. Tam yumuşatma kadar öne baktığından rampada gecikme olmaz; merdivende model
basamağa gelmeden yükselmeye başlar ve merdiveni düzgün çizgiyle çıkar, çıkarken aşağı inmez. Basamak kenarında,
altındaki basamak üstü yüksekliğinden yaklaşık yarım basamak aşağıdadır: tek tek basamakları değil merdivenin
çizgisini izler.

İleriye bakış, her biri en çok 0.15 m olan ışın parçalarıyla, 0.9 m'ye kadar yapılır. Her parçada zemin en fazla
bir basamak (`max_step_height`) veya en dik izin verilen eğim kadar yükselebilir ya da alçalabilir. Bir şeyin
içinden başlayan ışın zemin bulamaz; duvar aramayı durdurur. Model, gövdenin geçmeyeceği kenar, boşluk veya
duvar önünde düz kalır; çitin arkasındaki terasa doğru yükselmez. Rampanın uçlarındaki kırılmalarda köşeyi
yuvarlar: rampadan biraz önce yükselir, tepesinden biraz önce düzleşir; demonun 15° rampasında yüksekliğinin
yaklaşık 0.05 m altına kadar iner.

Havadayken ve iniş tikinde model gövdeyle tam birlikte hareket eder: zıplama aynı yayı çizer; kenardan düşüşte
model gövdeyle düşer. Kalkışta kalan süzülme `glide_time` süresinde söner.

Işın maliyeti: karakter süzülerek koşarken tik başına yediye kadar, dururken bir; havadayken veya süzülmüyorken
hiç. Işınlanınca (`GroundCharacter.teleport()`) model fizik enterpolasyonu açık veya kapalı olsa da hemen yerine
konur. Karakterin fizik enterpolasyonu elle sıfırlanınca da (`reset_physics_interpolation()`; enterpolasyon
kapalıysa etkisiz) veya bir tikte yatayda bir metreden fazla gidince de öyle. `snap()` elle aynı işi yapar.

### Salınım

Salınım zamana göre ilerler; model dururken de salınır: `bob_period` (2.4 s) süresinde `bob_height` (4 cm) kadar
bir kez yükselip alçalır. Hareket, salınımı duruştan koşuya kadar hız oranında değiştirir (0–1 karışım): koşu
hızında `run_bob_rate` (1.5) kat hızlı, `run_bob_scale` (0.5) payında küçüktür; daha sakin ve hızlı olur.
Döngü konumu zamanla büyür; hız değişimi modeli sıçratmaz. `random_bob_phase` ile her süzülen karakter farklı
noktada başlar, birlikte sallanmazlar. Salınım hiçbir zaman `height` değerinden derin değildir: model zemine girmez.

### Eğim ve atalet

- **Yana eğilme.** `run_lean` (8°), koşu hızında harekete doğru: ileri koşarken öne, yana yürürken yana, geri
  giderken arkaya. Depar sırasında `max_lean_scale` (1.5) katına kadar artar.
- **Atalet.** `GroundCharacter.get_local_acceleration()` değerinin 1 m/s² başına `tilt_per_acceleration`
  kadar; her yönde en fazla `max_inertia_tilt` (15°). İşaret `HandSway` ile aynıdır: pozitif değer ipteki ağırlık
  gibi geride kalır; negatif değer süzülen araç gibi ivmeye eğilir: hızlanırken ileri, frenlerken geri, dönüşün
  içine. Süzülme varsayılanı −0.25°'dir.
- İkisi de yaylardan geçer (`spring_frequency` 1.5 Hz, `spring_damping` 0.5). Model ayaklarının çok açılmaması
  için ayaklarından `tilt_pivot_height` (0.9 m), yani bel yüksekliğindeki nokta çevresinde eğilir.
- **Çökme.** Karakter zemine dokununca (`touched_floor`, yumuşak inişte de) düşüş hızının 1 m/s değeri başına
  `landing_kick` ile aşağı itilir; zıplama kalkışında `jump_kick` uygulanır. Yay geri getirir. Çökme
  `max_drop` (0.15 m) ve yerden yüksekliği aşmaz. Demoda `landing_kick` 0.2'dir; 2 m/s yumuşak inişte
  yaklaşık 2 cm çöker.

### Açma ve kapatma

Açılınca model `rise_time` (0.5 s) süresinde, başı ve sonu yumuşak biçimde `height` değerine çıkar;
kapatılınca aynı sürede iner. Zemine değince adımlar geri gelir. Salınım, eğilme ve çökme yükselişle artıp söner.
İlk fizik tikinden önce (sahnede veya başlangıçta kaydedilmiş ayardan) ayarlanmış `enabled`, yükseliş olmadan
hemen uygulanır.

`floating_changed(floating)` yükselişin başında ve model yerleşince gelir. `is_floating()` şimdi süzülüp
süzülmediğini, `get_hover_height()` modelin gövde ayaklarının üstündeki yüksekliğini bildirir.

### Özellikler

| Grup | Özellik | Varsayılan | Anlamı |
|---|---|---|---|
| | `character` | — | `GroundCharacter`; boşsa düğümün üstündeki en yakın karakter |
| | `enabled` | açık (demo sahnesinde kapalı) | Süzülme |
| | `height` | 0.35 m | Model ayaklarının zeminden yüksekliği |
| | `rise_time` | 0.5 s | Yükselme ve yerleşme süresi; 0 anlık |
| | `steps_while_floating` | kapalı | Süzülürken adımları korur |
| | `fall` | — (demoda `player_floating_fall.tres`) | Süzülürken düşüş ayarı; boşsa yürürkenkiyle aynı |
| Kayma | `glide_time` | 0.3 s | Yeni zemin yüksekliğine yaklaşık %95 yerleşme süresi; 0, her basamağı gövdenin altında izler |
| Salınım | `bob_height` | 0.04 m | Karakter dururken modelin yükselip alçalma uzaklığı |
| | `bob_period` | 2.4 s | Dururken bir salınım süresi, 0.5 s'den başlayarak |
| | `run_bob_scale` | 0.5 | Koşuda salınımın `bob_height` payı |
| | `run_bob_rate` | 1.5 | Koşuda salınımın kaç kat hızlı olduğu |
| | `random_bob_phase` | açık | Salınıma rastgele noktadan başlar |
| Eğim | `run_lean` | 8° | Koşu hızında hareket yönüne eğilme |
| | `max_lean_scale` | 1.5 | Deparda eğilmenin ulaşabileceği çarpan |
| | `tilt_pivot_height` | 0.9 m | Modelin ayaklarından yukarıdaki eğilme merkezi |
| Atalet | `tilt_per_acceleration` | −0.25° / m/s² | Pozitif geride kalır, negatif ivmeye eğilir |
| | `max_inertia_tilt` | 15° | İvmenin en yüksek eğimi |
| | `landing_kick` | 0.05 (demoda 0.2) | Zemine dokunmada 1 m/s düşüş başına aşağı itme |
| | `jump_kick` | 0.3 m/s | Zıplama kalkışında aşağı itme |
| | `max_drop` | 0.15 m | En yüksek çökme; yerden yükseklikten fazla değil |
| | `spring_frequency`, `spring_damping` | 1.5 Hz, 0.5 | Eğim ve çökme yayları |

### Bilinmesi gerekenler

- Model gövdeden `height` kadar yüksekte süzülür: kameranın `focus_height` ve kolun `occlusion_points`
  değerleri gövdeden ölçülür; model çok yüksekteyse bunları yükseltin.
- Alçak tavanın içine model girebilir: gövde ek yüksekliği bilmez.
- Basamaklar yalnız model için yumuşatılır. Kamera gövdeyi izler; `height_follow_time` görüntüdeki çıkışı
  yumuşatır (demoda 0.15 s).
- `landing_min_speed` altı hız sınırıyla düşen karakterin gerçek inişi yoktur: `landed`, iniş sesi ve onu bekleyen
  etkiler gelmez. İniş sesi isteniyorsa süzülmenin `fall` kaynağındaki `max_speed` değerini en az
  `landing_min_speed` yapın
  veya ikincisini düşürün.
- Bütün karakterde olduğu gibi yukarı +Y olmalıdır.
- Zaman dururken (`Engine.time_scale` 0) süzülen model ve `HandSway` el sallanması yerinde kalır; bkz.
  [Hareket](locomotion.md#groundcharacter).
- Kurulum hatası başlangıçta uyarılır: süzülme düğümü karakterin `Visual` altında değildir; altında model
  yoktur; aynı karakterde ikinci süzülme vardır; `CharacterAppearance.slot` süzülme düğümü değildir.
- `DampedSpring`, süzülme ve `HandSway` için ortaktır: `update(target, frequency, damping, delta)`, `value`,
  `speed`, `keep_within(limit)`, `reset()`. Sert yay tik başına birkaç kısa adımda hesaplanır; her ayarda sakin kalır.

### Ölçülen davranış

`tests/character_state_checks.gd` içinden, demoda saniyede 60 fizik tikiyle ve yolun biçimi için salınım olmadan:

- Dururken ayaklardan 0.31–0.39 m yukarıda (0.35 m ve 4 cm salınım).
- Platformun doğusundaki merdiveni çıkıp inerken modelin yükselişi tik başına en fazla 0.031 m değişir;
  gövdenin yukarı 0.100 m ve aşağı 0.138 m değerlerine karşılık. Model ters yöne gitmez ve altındaki basamaktan
  en az 0.17 m yukarıda kalır.
- Rampa boyunca ortasında zeminden 0.347–0.350 m yüksekte, gecikmesiz; kırılmalarda 0.30 m'ye kadar iner.
- İtme olmadan zıplamada model havada ve inişte yüksekliğini 0.6 mm içinde korur. İtmelerle 2 m/s temasında
  0.021 m çöker.
- Yavaş düşüşte 1 m zıplama 1.000 m tepeye çıkar ve `landing_min_speed` altındaki 2.00 m/s hızla,
  gerçek iniş olayı olmadan zemine dokunur.
  6.4 m/s düşüşte açılınca 0.3 s içinde 2.2 m/s'ye yavaşlar, tik başına en fazla 0.67 m/s. Düşüş ortasında
  kapatılınca modelin yerleşmesinin 30 tiki boyunca 2 m/s kalır, sonra yürürkenki gibi 29.4 m/s² ile hızlanır.
- Platformun korunan kenarında, 0.4 m blok ve arkasında teras olan duvarda çökme veya yükseliş yoktur.
- Koşunun ortasında kapatılıp açılınca tik başına en fazla 0.018 m; 31 tikte (`rise_time` 0.5 s) yerleşir,
  adımlar o zaman geri gelir. Kayıtlı ayarla açık başlıyorsa kahraman ilk kareden süzülür.

## OccludedSilhouette: tek şekil, hatları belirgin silah, kontur

Bir şey kahramanı gizlediğinde (dağ, bir ev, bir ağaç) kahraman açık mavi bir siluet olarak görünür: gövde için tek
bir düz şekil, onun üstünde hatları belirgin elde tutulan ekipman ve her şeyin çevresinde bir kontur.

`OccludedSilhouette` (oyuncuda `Silhouette`), sonradan eklenenler (yeni bir görünüm veya silah,
`SceneTree.node_added` üzerinden) dahil modelin her örgüsüne `material_overlay` ayarlar. Modelin kendi malzemeleri
değişmez; bu yüzden seviyedeki aynı modelin silueti olmaz. Gövde örgüleri ve el düğümlerinin (`gear_nodes`:
`RightHand`, `LeftHand`) altındaki örgüler farklı geçiş zincirleri alır.
Ekipmanın düğüm adları farklıysa `gear_nodes` alanını ayarlayın; eşleşme yoksa bütün örgüler gövde dolgusunu
alır. Var olan `material_overlay` değeri değiştirilir.

Her ekran pikseli, stencil arabelleği sayesinde bir kez boyanır: bir geçiş yalnızca stencil değerinin kendi
değerinden küçük olduğu yerde çizer ve kendi değerini hemen yazar (`stencil_mode read, write, compare_greater, N`).
Gölgelendiriciler ve malzemeler `addons/iso_orbit/occluded_silhouette/` içindedir:

| Geçiş | `render_priority` | Stencil | Ne yapar |
|---|---|---|---|
| `silhouette_mask` | 1 | 4 yazar | Görünmez, derinlik testli: karakterin kendisinin görünür olduğu yeri işaretler, böylece oraya başka hiçbir şey çizilmez |
| `silhouette_body` | 2 | < 2 → 2 | Düz gövde dolgusu: parçalar üst üste binmez ve tek bir şekilde birleşir |
| `silhouette_gear` | 3 | < 3 → 3 | Ekipman için daha açık dolgu, gövdenin üstünde, kendi hattıyla |
| `silhouette_outline` | 4 | < 1 → 1 | Kontur: normalleri boyunca ekran yüksekliğinin %0,4'ü kadar şişirilmiş örgüler; yalnızca bütün şeklin dışında kalan kısım kalır |

Dolgular ve kontur yalnızca bir engelin parçadan (fragment) en az 30 cm daha yakın olduğu yerde çizilir (derinlik
arabelleği `silhouette_common.gdshaderinc` içinde metreye dönüştürülür). Saydam nesneler önce `render_priority`
değerine göre sıralanır; böylece geçişler tüm örgüler için aynı anda sırayla çalışır.
Bu boşluğu değiştirmek için gövde, ekipman ve kontur malzemelerindeki `min_gap` değerini birlikte ayarlayın.
Bileşen geçiş zincirlerini `_ready()` içinde kurar; malzemeleri sahne başlamadan değiştirin.

`outline_enabled` (Ayarlar → Görüntü → **Engel arkasında siluet konturu**) son geçişi zincirlerden kaldırır. Kontur
genişliği `silhouette_outline.tres` dosyasının `width` parametresidir; renkler dolgulardaki ve konturdaki `color`
parametresidir.

Etki Forward+ çizicisiyle test edilmiştir. Stencil arabelleği Godot 4.5+ sürümlerinde deneyseldir ve yalnızca
saydam geçişte
okunabilir. Ayrıca Godot 4.7'de (D3D12 ve Vulkan) gölgelendiricilerdeki izdüşüm Y ekseninde ters çevrilmiştir:
`PROJECTION_MATRIX[1][1]` negatiftir. `abs()` olmadan "ekran payı → metre" dönüşümü negatife düşer, kontur örgüsü
küçülür ve kontur kaybolur.

## Modelleri düzenleme

Modeller bir betikle ilkel şekillerden oluşturulmuştur ve artık sıradan sahnelerdir: onları editörde diğer sahneler
gibi düzenleyin.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
