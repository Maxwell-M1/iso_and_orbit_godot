<!-- translation of docs/en/systems/world-and-navigation.md @ c9c7a768629e -->
# Dünya ve navigasyon

[← Belge dizini](../index.md)

> Bu, [İngilizce orijinalin](../../en/systems/world-and-navigation.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Demonun başlangıç seviyesi `shared/world/world.tscn` içindeki çayırdır: ahşap çitin ardında 80 × 80 m açıklık.
İçindeki her şey ilkel şekillerden ve gölgelendiricilerden yapılmıştır; ince yüzey desenleri pişirilmiş dokulardan
gelir. Kadim Çember'in yanındaki ışınlanma platformu ikinci seviye Issız Ada'ya götürür; ikisi de
[Seviyeler](levels.md#demonun-seviyeleri) sayfasında açıklanır.

## Fizik katmanları ve navigasyon

Engeller 1. katmanda (`world`) `StaticBody3D`, karakterler 2. katmanda (`characters`), yalnız kamerayı durduran
gövdeler 3. katmanda (`camera`), seviye kenarındaki görünmez duvarlar 4. katmandadır (`bounds`); bkz.
[Proje yapılandırması](../project-setup.md#fizik-katmanları). Navigasyon örgüsü 1. katman çarpışmalarından,
adada ayrıca 4. katmandaki kenar duvarlarından, 0.5 m etmen yarıçapıyla pişirilir. Karakter kapsülünün yarıçapı
0.35 m olduğundan yollar köşelerden pay bırakır.

| `NavigationMesh` parametresi | Değer | Neden |
|---|---|---|
| `agent_radius` | 0.5 m | Yollar köşelerden uzak durur |
| `agent_height` | 1.75 m | Mevcut demo pişirme değeri; tavanlı yeni seviyede çarpışma yüksekliğinin tamamını kullanın (kahraman kapsülü 1.8 m) |
| `agent_max_slope` | 40° | Dağın yamaçları örgünün dışında kalır |
| `cell_height` | 0.025 m | Aşağıdaki çıkış yüksekliğini ölçecek kadar ince |
| `cell_size` | 0.25 m | Yatay pişirme çözünürlüğü; navigasyon haritasıyla eşleşmeli |
| `agent_max_climb` | 0.3 m (12 hücre) | Karakterin çıktığı basamaklar (`GroundCharacter.max_step_height`) |
| `geometry_parsed_geometry_type` | Static Colliders | Örgü görünür örgüleri değil çarpışma şekillerini izler. Aşağıdaki maske çarpışmalara uygulanır; görünür örgüsü olmayan duvarlar ancak böyle sayılır |
| `geometry_collision_mask` | 1. katman; adada 1 ve 4 | Engeller ve görünmez duvarlar sayılır |
| `filter_walkable_low_height_spans` | demoda kapalı | Tavanlı yeni seviyede `agent_height` altı boşlukları dışlamak için açın |

**Navigasyonu çarpışma gövdesiyle eşleştirin.** `agent_max_climb`, `GroundCharacter.max_step_height` değerini
(burada 0.3 m) aşmasın; navigasyon eğim sınırı da gövdenin zemin sınırını aşmasın (burada 40° ve 45°). İkisinden
biri değişirse yeniden pişirin. Navigasyon hücrelere bölünür; aynı sayılar her kenarda garanti vermez: geçilmesi
istenen en yüksek basamağı ve yasaklanacak en alçak çıkıntıyı deneyin. Demo 0.2 m basamakları geçer, 0.4 m bloğu
reddeder. İnce 0.025 m dikey hücreler bu küçük yükseklik farklarını ayırır.

Yeni seviyede etmen yüksekliğini kapsülün tam boyuna eşit veya daha yüksek seçin ve
`filter_walkable_low_height_spans` açın; yükseklik tek başına boşluk filtresini açmaz. Tavan çarpışmalarını
pişirmeye katın. Süzülen model gövdenin üstüne uzanır; görsel boşluğu ayrıca denetleyin. Yarıçap duvar
çevresindeki yol payını belirler; kapsül yarıçapı değişirse dar koridorları denetleyip yeniden pişirin.

Harita ile örgünün `cell_height` ve `cell_size` değerleri eşit olsun. Demo dikeyde 0.025 m, yatayda 0.25 m
kullanır; karşılık gelen proje ayarları `navigation/3d/default_cell_height` ve
`navigation/3d/default_cell_size` alanlarıdır. Godot'un
[NavigationMesh başvurusu](https://docs.godotengine.org/en/stable/classes/class_navigationmesh.html) pişirme
çözünürlüğünü, yuvarlamayı ve boşluk filtresini açıklar.

Pişirilmiş yüzey çarpışma zemininden biraz yüksek olabilir. `NavigationMover` yol ilerlemesini XZ düzleminde
karşılaştırır; gövdenin gerçek yüksekliğini fizik belirler. Pişirme geometrisini fizik katmanları, kullanılabilir
yolları ise bölgenin navigasyon katmanları ve `NavigationMover.navigation_layers` seçer.

Boş navigasyon sonucu doğrudan harekete döner; kısmi yol erişilemeyen hedefin önünde bitebilir. Kötü rotayı
hareket ayarlarıyla telafi etmeden önce **Debug → Visible Navigation** ve demodaki **Karakter yol çizgisi**
panelini kullanın. Bkz. [Hareket](locomotion.md#navigationmover).

## Navigasyon örgüsünü yeniden pişirme

Örgü önceden pişirilir ve her seviyenin kendi sahnesinde, `shared/world/world.tscn` ve
`shared/world/island/island.tscn` içinde (`NavigationRegion3D` düğümünün `NavigationMesh` kaynağı) saklanır;
oyun yeniden hesaplamaz. Seviye düzenlenince yeniden pişirin. İki seviye aynı parametreleri kullanır; yalnız
çarpışma maskesi farklıdır: adada 1 ve 4. katmanlar pişirilir.

**Ne zaman:** 1. katmanda (`world`) çarpışma şekli olan herhangi bir şeyi taşıdığınızda, eklediğinizde,
kaldırdığınızda veya yeniden boyutlandırdığınızda: bir kaya, bir sandık, bir duvar, bir ağaç, bir dekor nesnesi, bir
NPC, dağ; adada 4. katmandaki (`bounds`) görünmez duvarlar da. Yalnızca görünüm değiştiğinde (bir örgü, malzeme)
ya da 3. katmandaki (`camera`) gövdeler, oyuncunun
karakteri (2. katman) ve alanlar (`Area3D`) için gerekmez. Unutursanız yollar taşınmış bir nesnenin içinden (karakter
ona çarpar ve boyunca kayar) ya da eskiden durduğu boş yerin etrafından geçer.

**Editörde:**

1. Seviyenin sahnesini açın.
2. Sahne ağacında `NavigationRegion3D` düğümünü seçin.
3. 3B görünümün üstündeki araç çubuğunda **NavigationMesh Pişir** (Bake NavigationMesh) düğmesine basın. Birkaç saniye
   sonra görünümdeki mavi örgü güncellenir: nesnenin çevresinde ajan yarıçapı (0,5 m) kadar bir delik, eskiden
   durduğu yerde kesintisiz örgü.
4. Sahneyi kaydedin (Ctrl+S): örgü sahneye gömülüdür.

Pişirme parametreleri kaynağın kendisindedir: `NavigationRegion3D` düğümünü seçin ve Denetçi'de (Inspector)
`Navigation Mesh` özelliğini genişletin.

Yeniden pişirdikten sonra testleri çalıştırın ([Testler](../testing.md)): rotaları örgüyü izler. Çalışan oyunda
editördeki Hata Ayıklama → Görünür Navigasyon (Debug → Visible Navigation) örgüyü, Ayarlar (F10) → Arayüz →
**Karakter yol çizgisi** de karakterin yolunu gösterir.

## Seviye

- **Merkez** başlangıç noktasıdır. Çevresinde: yıkık sütunlardan bir halka, başlangıç noktasına doğru açık U biçimli bir
  tuzak, boşluklu uzun bir duvar, sandıklar, bir koru, bir çalı labirenti ve batı yanında bir rampası, doğu yanında bir
  merdiveni (0,2 m yüksekliğinde ve 0,4 m derinliğinde yedi basamak) olan 1,6 m'lik bir platform. Testler bunların
  hepsini kullanır, bu yüzden yerlerinde kalırlar.
- **Yollar**, güney çitinden duvardaki boşluktan geçerek başlangıç noktasına ve oradan dağa, harabelere, kampa ve
  rampaya uzanan toprak şeritlerdir; çiftliğin yolu duvarın güneyinden ayrılır. Yalnızca bir desendirler
  (`shared/world/terrain.gdshaderinc` içindeki `ROADS` segmentleri) ve hareketi etkilemezler. Zemin ve dağın
  eteğindeki yumuşak eğimli çimen ikisi de onları çizer; böylece yol kesintisiz olarak dağ patikasına bağlanır. Yol
  patikanın başlangıcına batıdan ulaşır: patika başlangıcının doğusunda dağ 4 m'ye kadar yekpare bir uçurumdur.
- `shared/world/props/` içinden **dekor nesneleri**: kuzeybatıda ve kenarlar boyunca bir orman, çalılar, kayalar,
  doğuda bir kamp (bir çadır, titrek ışıklı bir kamp ateşi, fıçılar), güneybatıda bir çiftlik (bir ev, bir kuyu).
- Kuzeydoğuda, 10 m yüksekliğinde, zirvesine tek bir sarmal patika çıkan **dağ**.
- Güney duvarına sırtlarını dönmüş, boşluğun doğusunda sıra hâlinde **on kahraman görünümü** (bkz.
  [Karakterler](characters.md#kahraman-görünümleri)).

Yerleşimi değiştirmek için seviye sahnesindeki nesne örneklerini düzenleyin, sonra navigasyonu yeniden pişirin.
Regresyon testleri demoda belirli rotaları ve engel konumlarını kullanır; kendi düzeniniz için ayrı seviye açın
veya test geometrisiyle birlikte testleri de güncelleyin.

### Yerler ve NPC'ler

Dört yer `PointOfInterest` alanıdır. Oyuncu birine ilk kez girdiğinde ekranın üstünde birkaç saniyeliğine
"Keşfedildi: …" belirir. Her yerde, başlarının üstünde ad etiketleri (`Label3D`) olan NPC'ler yerin merkezine bakarak
durur; Şövalye yol boyunca bakar.

| Yer | Nerede | Orada kim var |
|---|---|---|
| Rüzgârlı Doruk | Kuzeydoğudaki dağın zirvesi | Kristalli bir sunağın yanında Büyücü |
| Yolcular Kampı | Doğu: çadır, kamp ateşi, fıçılar | Ateşin başında Korucu ve Cüce |
| Kuyu Başındaki Çiftlik | Güneybatı: ev, kuyu | Yolun yanında nöbet tutan Şövalye |
| Kadim Çember | Başlangıç noktasının kuzeybatısındaki sütun halkası | Sunağın yanında Haydut |

Her NPC, 1. katmanda kapsüllü bir `StaticBody3D` gövdesidir (`World/NavigationRegion3D/Characters`): navigasyon
örgüsü onların etrafından geçer ve kimse içlerinden geçemez. Kamp, çiftlik ve harabeler `World/Places` altındadır;
doruk `mountain.tscn` içindedir.

**Yeni bir yer:** herhangi bir dünya sahnesine bir çarpışma şekli ve bir `title` ile birlikte bir `PointOfInterest`
(`collision_mask` özelliği karakterlerin 2. katmanını içeren bir `Area3D`) ekleyin. Bildirim her yeri grubu üzerinden
bulur; sonradan yüklenen seviyelerde de bağlantı gerekmez. Başlığı çevirilere ekleyin
([Arayüz](ui.md#çeviriler)). Issız Ada'daki beşinci yer Münzevinin Kampı'dır.

## Yüzeyler

Neredeyse her yüzey, `shared/world/` içinde bir gölgelendirici ve `shared/world/materials/` içinde bir malzemedir;
istisnalar bu bölümün sonunda listelenen sıradan `StandardMaterial3D` malzemeleridir. Bir nesnenin boyutuna ve
biçimine bağlı olan şeyleri ucuz bir şekilde gölgelendirici hesaplar: bir kutunun yüksekliğine uydurulmuş taş
sıraları, tahtalar, çerçeveler ve direkler, ahşap iskelet, fıçı çıtaları ve çemberleri, sütun yivleri ve tamburları,
`ROADS` boyunca yollar, yüksekliğe göre kaya katmanları. Böylece her boyuttaki kutu desenini germez. İnce ayrıntılar
(çimen yaprakları, çakıllar, yapraklar, ağaç kabuğu, taş dokusu) pişirilmiş dokulardan gelir, aşağıya bakın.

| Yüzey | Gölgelendirici | Görünümü |
|---|---|---|
| Duvarlar, platform, rampa, merdiven | `stone_masonry` | Derzli, şaşırtmalı sıralarda bloklar; her bloğun kendi tonu, dokusu ve kırıkları, normal ile kabartma, zemine yakın kir ve yosun. Üstte kısa kenar boyunca dizilmiş bir sıra taş |
| Çalı labirenti | `hedge_foliage` | Her biri kendi dönüşü, boyutu, tonu ve eğimiyle iki yaprak katmanı; boşluklarda çalının derinliğinin gölgesi; budanmış bir çalı gibi düzensiz yanlar |
| Sandıklar, çit | `wood_planks` | Yıllık halkalı, lifli, budaklı ve aralıklı tahtalar. Sandıkların her yüzünde bir tahta çerçeve, çapraz bir destek ve çiviler var; çitte her 2,5 m'de bir direkler üzerinde yıpranmış uzun tahtalar |
| Sütunlar, kuyu | `stone_column` | Normal ile çevre boyunca yivler, zeminden itibaren derzli 0,8 m'lik tamburlar, düz bir kaide, akıntı izleri, seyrek çatlaklar, liken, zemine yakın yosun. Kuyu, daire boyunca dizilmiş bloklardan bir taş duvar deseni kullanır (`blocks_around`) |
| Kayalar, dikili taşlar | `rock` | Damarlı ve çatlaklı taneli taş, üstte liken, zemine yakın yosun; desen triplanar (`triplanar.gdshaderinc`), her kayada farklı |
| Ev duvarları | `timber_plaster` | Ahşap iskelet: direk ve kirişlerden bir çerçeve içinde lekeli ve ince çatlaklı sıva, taş bir kaide |
| Ev ve kuyu çatıları | `thatch` | Her sıranın altında gölge bulunan demet sıraları hâlinde saman, eğim boyunca saplar, bağlı bir mahya, yosun |
| Çadır, kapak, sancak | `canvas` | Dokuma kanvas: dikişli paneller, kıvrımlar, yamalar; sancakta bir kenar şeridi ve bir amblem |
| Fıçılar | `barrel` | Aralıklı çıtalar, paslı demir çemberler, tahta bir kapak |
| Kütükler, ağaç gövdeleri, sancak direği | `bark` | Zemine yakın ve kuzey tarafında yosunlu, oluklu ağaç kabuğu; kamp ateşinde kömürleşmiş ve için için yanan kütükler |
| Ağaç tepeleri, çalılar | `foliage` | Üç eksen düzleminde iki katman yaprak, öbekler, daha açık bir tepe; çamlarda iğne yapraklar, sonbahar meşesinde turuncu ve kırmızı |
| Zemin | `ground_grid` | Aşağıya bakın. Adanın çimi, yolları kapalı (`roads`) aynı zemin olan `island_ground.tres` kaynağıdır |
| Dağ | `mountain` | Yüz rengine göre seçilen çimen, patika ve kaya katmanları |
| Kuyudaki su ve ada gölü | `water` | Yavaş dalgacıklar. Göl (`lake_water.tres`) daha açık mavi, daha güçlü dalgalıdır (`ripple` 0.55; kuyuda 0.35) |

Taş duvar deseni örgünün yüzlerini izler ve kutunun boyutunu bilir: yüz alt bölümleri olmayan bir `BoxMesh` yalnızca
her köşede bir köşe noktasına sahiptir, bu yüzden `abs(VERTEX)` yarı boyutları verir. Bu değerler piksele değişmeden
(`flat` değişkenle) ulaşır. Enterpolasyon son basamakları pikselden piksele farklılaştırırdı; yarı değere denk gelen
sıra sayısı (0.4 m sıralı 1.4 m basamak) bazı piksellerde aşağı, bazılarında yukarı yuvarlanıp titrerdi. Sıva,
tahta ve kumaş gölgelendiricileri kutu boyunu aynı biçimde aktarır. Yanlardaki sıralar yüksekliğe
uyar ve bir yanın en üst sırası üst taşların kenarıdır; böylece derzleri, üst yüzün derzlerini kenarda sürdürür.
Rampa (ince bir levha) böyle tek bir sıradır ve uçlarının derzleri üst yüzle eşleşir. Labirent kutularında ise her
25 cm'de bir yüz alt bölümü vardır (`subdivide_*`), çünkü yanları dünya konumundan gelen gürültüyle kaydırılır: bir
kenardaki köşe noktasının kopyaları birlikte hareket eder ve yüzler ayrılmaz. Çarpışma şekilleri yine sıradan
kutulardır; yapraklar birkaç santimetre dışarı taşar.

**Zemin** (`ground_grid.gdshader`, ortak kısım `terrain.gdshaderinc`): birkaç ölçekte çimen (koyu, normal ve kuru
çimenden büyük alanlar, öbekler, eğik normalli ve köklerinde gölge bulunan iki katman çimen yaprağı, açıklıklarda
dağınık çiçekler) ve yollar (çimen tutamlarıyla düzensiz bir kenar, ezilmiş daha açık renkli bir orta kısım, sığ
tekerlek izleri, tanecikler, kuru yerlerde ince çatlaklar, gölgeli çakıllar, kenarda daha çok). İnce ayrıntı
pişirilmiş dokulardan her 3,84 m'de bir döşenerek tekrarlanır; büyük alanlar tüm zemini kaplayan bir maskeden gelir.
Uzakta ayrıntı, dokuların mip seviyeleri aracılığıyla ortalama bir renge dönüşür. Dağın çimeni ve patikası aynı kodu
kullanır. Her 5 m'de kalın çizgili 1 m'lik bir ızgara varsayılan olarak kapalıdır; hızları ve mesafeleri ölçmek için
onu `shared/world/materials/ground.tres` üzerindeki `grid_strength` ile açın.

Ucuz gölgelendirici gürültüsü (taşlar ve tahtalar için rastgele sayılar, yaprak öbekleri) `noise.gdshaderinc`
içinde, yapraklar `leaves.gdshaderinc` içindedir. Birkaç malzeme sıradan `StandardMaterial3D` olarak kalır:
karakterlerin ekipmanının (asalar, yay, balta) kullandığı `dark_wood.tres` ve `wood.tres` ile parlayan
`crystal.tres` ve `fire.tres`.

## Pişirilmiş dokular

Yüzey desenleri (yaprakları ve çiçekleriyle çimen, çakıllı toprak, yapraklar, ağaç kabuğu, taş dokusu, sıva, ahşap
lifleri, saman, dokuma kumaş) gürültü gölgelendiricileri olarak tasarlanmıştır, ancak oyun bunları her piksel için
hesaplamaz: `shared/world/textures/` içinde bir kez dikişsiz dokulara pişirilmişlerdir ve dünya gölgelendiricileri
onları döşer.

Pişirme, her pikselde tekrarlanan gürültü hesaplarını doku örnekleriyle değiştirir. Bu dokuları yenilerken aşağıdaki
içe aktarma ayarlarını koruyun; bazı kanallar sıradan renk değil gölgelendirici verisi taşır.

- **Dikişsiz.** Desenlerin gürültüsü, döşeme başına tam sayıda öğeyle döşemeyle birlikte tekrarlanır; bu yüzden dikiş
  görünmez. İstisna `ground_mask` dokusudur: tüm 96 m'lik zemini kaplayan büyük alanlar ve yollar, döşenmeden.
- **Renk dünya gölgelendiricisinde kalır.** Yapraklar, sütun taşı, ağaç kabuğu ve ahşap lifleri renksiz pişirilir
  (yaprak tonu, gölge, yaprak veya boşluk, lekeler, normal eğimi) ve dünya gölgelendiricisi rengi malzeme
  parametrelerinden oluşturur: tek bir yaprak dokusu meşeye, sonbahar meşesine ve çalı çite hizmet eder. Yalnızca
  çimen (alan tonu için bir çarpan), çiçekler ve çakılların rengi pişirilmiştir.
- **Kabartma**, iki kanaldaki normal eğimidir ve pişirme sırasında yükseklik farklarından hesaplanır.
- **Dosyalar:** kayıpsız WebP (sıfır alfa altındaki veri bozulmadan kalır); alfa veri taşıdığından GPU
  sıkıştırmasıyla (BPTC), mipmap'lerle ve saydam pikseller için renk düzeltmesi olmadan içe aktarılır. Bir dokuyu
  değiştirirken bu içe aktarma ayarlarını koruyun.

## Dağ ve Rüzgârlı Doruk

Dağ, dünyanın kenarındaki bir köşede durur (yamaçları çitin ötesine uzanır) ve her yerden görünür. Zirveye giden
patika 3 m genişliğindedir: yolun sonunda (23, 0, −19) başlar ve 12° eğimle dağın neredeyse tamamen çevresini dolanır
(340°). İki taraftaki yamaçlar diktir (patikanın üstünde 76°, altında 60°): yürüyerek (gövde yalnızca 45° ve daha düz
yüzeylerde durabilir) ya da bir yol boyunca (navigasyon örgüsü 40°'ye kadar eğimleri alır) tırmanılamazlar; kenar
koruması da karakterin patikadan düşmesini önler. Zeminden zirveye bir tıklama patika boyunca götürür: 9,8 sn'de
51 m.

Zirvede bir tapınak vardır: üstünde parlayan bir kristalin süzülüp yavaşça döndüğü bir sunak, beş dikili taş ve bir
sancak. Zirve, Rüzgârlı Doruk adlı yerdir.

Dağ, bir betikle üretilmiş bir yükseklik haritasıdır: yüz renkli ve düz gölgelemeli bir örgü, üstünde
`materials/mountain.tres` malzemesi (yüz rengine göre yapraklı çimen, çakıllı patika toprağı, çatlaklı ve likenli kaya
katmanları) ve aynı üçgenlerden bir çarpışma şekli (`shared/world/mountain/*.res`). Patika boyunca bir yol
oluşturulabilmesi için gerekenler:

- Patikanın enine yüksekliği tektir, bu yüzden iç kenarı ekseninden daha diktir (eksen yarıçapının kenar yarıçapına
  oranında). Dönüşler dar değildir (yarıçap 9,5 → 7 m); böylece zirveye yakında bile iç kenar 16°'den daha düzdür:
  daha dik olursa, 0,25 m'lik hücre başına 0,075 m tırmanmalı bir navigasyon örgüsü patikayı böler.
- Yoldan giriş: eteğinde, patika 1 m'nin altındayken dış yamaç yumuşaktır. Aksi hâlde patika başlangıçtan itibaren
  dışa doğru dik düşer ve girişi ajanın payından daha ince bir şeride daralırdı.
- Patikanın son 3 m'si zirveyle aynı yüksekliktedir; böylece patika zirveyle bir noktada değil, bir şerit boyunca
  buluşur.

Kamera varsayılan olarak güneydoğudan bakar; bu yüzden patikanın uzak tarafında dağ kahramanı gizler ve kahraman o
zaman siluet olarak görünür (bkz.
[Karakterler](characters.md#occludedsilhouette-tek-şekil-hatları-belirgin-silah-kontur)).

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
