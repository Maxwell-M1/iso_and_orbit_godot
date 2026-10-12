<!-- translation of docs/en/editor_authoring.md @ a4a7c741507e -->
# Editörde sahne düzenleme

[← Belge dizini](index.md)

> Bu, [İngilizce orijinalin](../en/editor_authoring.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Demonun sahneleri editörde düzenlenmek üzere hazırlanmıştır. Düğümler Inspector'da birbirine bağlanır; bileşenler
kurulumlarını denetler ve bir şey eksik ya da yanlış olduğu sürece Scene panelinde uyarı gösterir; oyunun başlangıçta
kurduğu şeyler de (kameranın görüntüsü, bir karakterin modeli ve başının üstündeki ad, bir portalın tabelasındaki
başlık, bir dekor nesnesinin boyutu) editörde görünür. Bu önizlemeler hiçbir zaman kaydedilmez: kaydedilen sahne
sizin ayarladıklarınızı tutar, bu yüzden diff'inde yalnızca sizin değişiklikleriniz görünür.

## Bağlantılar ve uyarılar

Başka düğümlerle çalışan bir bileşenin bu düğümlere özellik olarak bağlantıları vardır: `PlayableHero.character`,
`GroundCharacter.mover`, `OccludedSilhouette.target` gibi. Bunları Inspector'da bir düğümü alana sürükleyerek
ayarlayın. Bileşenin ihtiyaç duyduğu bir bağlantı boş olduğu ya da bir düğüm çalışamayacağı bir yerde durduğu sürece
(hareket ettirdiği gövdenin altında olmayan bir `NavigationMover`, hedef sahnesi olmayan bir `LevelPortal`,
Input Map'te bulunmayan bir girdi eylemi) Scene paneli düğümün yanında bir uyarı işareti gösterir; nedenini görmek
için imleci işaretin üzerine getirin. Uyarılar düzenlemelerinizi izler: bir özelliği değiştirdikçe, bir çocuk ekleyip
kaldırdıkça, bir rotanın eğrisini, bir kenar korumasının `max_drop` değerini veya bir karakterin düşüş ayarlarını
düzenledikçe belirir ve kaybolurlar. Sahneyi yeniden açmak gerekmez.

Bileşenler editörde kendilerini denetler, çünkü betikleri araç (tool) betikleridir. Editörde yalnızca denetler ve
önizlerler: orada girdi, fizik veya zamanlayıcı çalışmaz ve hesapladıkları hiçbir şey sahneye yazılmaz. Oyunda her
zaman olduğu gibi çalışırlar.

## Başlangıç seviyesi

`gdscript/main.tscn`, seviye sunucusu `Levels` düğümünü ve onun çocuğu olarak başlangıç seviyesi `World` düğümünü
tutar; `Levels.initial_level` de bu seviyeyi belirtir. Bu alan boşken sunucu ilk `Node3D` çocuğuyla başlar; birden
çok 3B çocuk varsa ve hiçbiri belirtilmemişse uyarı gösterir. Bkz. [Seviyeler](systems/levels.md).

## Editörde kamera

`Hero/CameraRig` oyunun başladığı görüntüyü gösterir: düzenek hedefin konumunda, onun `focus_height` kadar üstünde
durur, `start_yaw` kadar döner, `start_zoom` değerinin belirlediği kadar eğilir ve uzaklaşır; kol da kamerayı o
uzaklıkta gösterir. Başlangıcın kadrajını ayarlamak için bu özellikleri değiştirin; 3B görünüm hemen izler.

Oyun düzeneğin dönüşümünü, kameranın dönüşümünü ve bir düzeneğin altındaki kolun `length` değerini her karede
ayarlar; bu yüzden editörde bunlar da önizlemedir: elle taşınan bir düzenek veya kamera oyunun koyduğu yere geri döner
ve bir düzeneğin altında kolun `length` değeri salt okunurdur. Kaydetme, sahnenin yüklendiği değerleri korur; böylece
önizleme hiçbir zaman diff'te görünmez ve kahramanı yerleştiren sahne, kamerasının konumunun bir kopyasını hiçbir
zaman almaz. Hedefi olmayan bir düzenek farklıdır: oyun onu taşımaz, bu yüzden konumu size aittir ve ayarladığınız
gibi kaydedilir; yalnızca dönüşü önizlenir.

## Ayarlar penceresinden gelen ayarlar

`SettingsApplier`, oyuncunun kaydedilmiş ayarlarını (F10) sahnede ayarlanan değerlerin üzerine uygular. Sahnenin
değerleri aynı zamanda varsayılanlardır: oyuncunun değiştirmediği bir ayar sahnenin değerini korur ve **Tümünü
sıfırla** bunlara döner. Sahnenin düğümlerini Inspector'da ayarlarken onları tam ayarlandıkları gibi çalıştırmak
için `SettingsApplier.use_saved_settings` özelliğini kapatın; ayarlar penceresi o zaman onlara dokunmaz ve yalnızca
motor ayarlarını (tam ekran, kare hızı, V-Sync, fizik enterpolasyonu, arayüz ölçeği, dil, ses düzeyi) değiştirir.
Bkz. [Ayarlar](settings.md).

## Katı dekor nesneleri

Katı bir dekor nesnesi, kökü `StaticProp` olan bir sahnedir; bu kök, `shared/world/props/static_prop.gd` betikli bir
`StaticBody3D` düğümüdür. Görünen parçaları ve çarpışma şekilleri kökün gruplanmış çocuklarıdır; bu yüzden 3B
görünümde bir tıklama dekor nesnesinin tamamını seçer.

- Onu kökünden **taşıyın**.
- Onu `dimensions` ile, dekor nesnesinin kendi eksenleri boyunca metre cinsinden **yeniden boyutlandırın**: görünen
  parçalar ve çarpışma birlikte değişir. Bir eksende 0, parçaların o eksendeki boyutunu korur; böylece `(0, 0, 0)`
  değerindeki yeni bir dekor nesnesi yapıldığı boyuttadır, daha uzun yapılan bir sütun için de yalnızca yüksekliğini
  ayarlamak yeter. Kökü ölçeklendirmeyin, ölçeklendirilirse uyarı gösterir; çocuklarını da ölçeklendirmeyin;
  büyütülen veya küçültülen bir örgünün çarpışma şekli de onunla birlikte değiştirilmelidir.
- Onu `surface_material` ile **yeniden renklendirin**: bu malzeme, görünen bütün parçalarının malzemesinin yerine
  geçer; boşsa parçalar kendi malzemelerini korur.

Seviyelerin paylaştığı dekor nesneleri `shared/world/props/` içindeki sahnelerdir: `stone_pillar.tscn`,
`solid_box.tscn` (duvarlar, sandıklar, platform ve rampası), `grove_tree.tscn`, `rock.tscn` ve ormanın, kampın ve
çiftliğin katı dekor nesneleri (bir çalının çarpışması yoktur ve `StaticProp` değildir). Bir örnek kendi `dimensions`
ve `surface_material` değerlerini ayarlar; bütün örneklerini değiştirmek için dekor nesnesinin sahnesini düzenleyin.
Bir kez kullanılan bir parça, kendi `StaticProp` köküyle doğrudan seviyesinde durur: çayırın zemini, platformun
merdiveni, labirentin çalı çitleri, yerlerdeki figürler, on kahraman görünümü, adanın zemini ve kenar duvarları. Çalı
çitler örgülerinin boyutunu korur: yaprakları yaklaşık 25 cm'lik hücrelere bölünmüş bir örgü gerektirir; bu yüzden
başka boyutta bir çalı çite `dimensions` değil, o boyutta bir örgü verilir.

Parçaları her zamanki gibi düzenleyin: bir çocuğu taşıyın, bir örgüyü veya şekli değiştirin, bir parça ekleyin. Dekor
nesnesi değişikliği yeni biçimi olarak alır: `dimensions` değerinin 0 olduğu eksenlerde parçaların yeni boyutunu alır,
diğerlerinde esnetmesini korur. Yeni bir dekor nesnesi kendiliğinden gruplanmaz: kökünü seçin ve 3B görünümün araç
çubuğundaki Group düğmesine basın. Kaydetme parçaları sizin yaptığınız gibi korur; yeniden boyutlandırma bir
önizlemedir ve sahne açıldığında ve oyun başladığında yeniden uygulanır. Yeniden boyutlandırılan bir şekil kendine ait
bir kopyadır; bu yüzden bir örneği yeniden boyutlandırmak başka bir örneği hiçbir zaman değiştirmez. Eşit olmayan
biçimde esnetilen yuvarlak veya döndürülmüş bir şekil, aynı biçimde esnetilmiş dışbükey (convex) bir şekle dönüşür.

Hareketli parçaları sıradan bir `Node3D` altında tutun: kendini hareket ettiren bir düğüm, dekor nesnesinin yeniden
boyutlandırdığı düğüm olmamalıdır. Dağda dekor nesnesi `CrystalAnchor` düğümünü yeniden boyutlandırıp yerleştirir,
onun çocuğu `Crystal` ise döner ve inip çıkar.

Bir dekor nesnesinin çarpışmasını değiştirdikten sonra (onu taşıyarak, yeniden boyutlandırarak veya düzenleyerek)
navigasyon örgüsünü yeniden pişirin, bkz.
[Dünya ve navigasyon](systems/world-and-navigation.md#navigasyon-örgüsünü-yeniden-pişirme).

## Devriyeler

Çayırdaki şövalye bir rotada yürür. `shared/world/world.tscn` sahnesini açın ve bir `Path3D` olan `Routes/KnightPatrol`
düğümünü seçin: eğrisini 3B görünümde eğri araçlarıyla düzenleyin; şövalye orada çizilen çizgide, kavislerinde yumuşakça
dönerek yürür. Bir köşeyi yuvarlamak için araç çubuğunda **Select Control Points** kipini açın ve noktanın tutamaçlarını
çıkarmak için noktadan Shift ile sürükleyin. Çizgiyi çitlerden yaklaşık şövalyenin genişliği kadar uzak tutun: çizgi
boyunca onların çevresinden dolaşacak bir yol aramaz. Şövalye (`NavigationRegion3D/Characters/Knight`, bir
`gdscript/npc/knight_patrol.tscn` örneği) **Route** alanında ona başvurur. Evin yanındaki yerinden rotanın ilk noktasına
yürür, sonuncusundan sonra da en kısa yoldan geri döner: bu iki yol çizilen çizginin parçası değildir. Rota seviyeye
aittir; bu yüzden aynı karakter başka bir seviyede başka bir rotada yürüyebilir. Adanın korucusu (`island_patrol.tscn`)
adada `Routes/IslandPatrol` rotasında yürür. Noktası olmayan ya da karakterin içinde duran bir rota, karakterin kökü
olan `Knight` üzerinde uyarı gösterir.

Editörde devriye gezen bir karakter modelini ve başının üstündeki adını gösterir; ikisi de sahneye kaydedilmez. Kökünde
**Model Scene**, **Speaker Name** (başın üstünde ve altyazılarda) ve **Blocked Line** (biri yolunda yeterince uzun
durduğunda söylediği) ayarlanır. Yürüyüşü `Character/PatrolController` üzerinde ayarlanır (**Editable Children**
seçeneğini açın): **Cycle Wait**, bir turdan sonra kendi yerindeki bekleme (10 sn); **Waypoint Wait**, eğrinin her
noktasındaki duruş; **Blocked Delay**, replikten önce birinin yolda ne kadar durması gerektiği (şövalye için 2,5 sn);
**Blocking Distance** ve **Blocking Angle**, önünde birinin onu durdurduğu alan: 1 m ileri, her iki yana 25° açılarak,
el feneri ışığı gibi. Yanlarında ve arkasında kimse onu durdurmaz. Bkz.
[Hareket](systems/locomotion.md#patrolcontroller-rotada-yürüme).

## Editör tarafını denetleme

`tests/run_checks.gd` oyunu denetler, ancak editörü çalıştıramaz. Editör tarafının, yani düzenlemeleri izleyen
uyarıların, önizlemelerin ve sahnelerin neyle kaydedildiğinin kendi denetimleri vardır:
`tests/editor_tool_checks.tscn` sahnesini açın ve Inspector'da **Run Checks** düğmesine basın. Sonuç orada **Status**
ve **Results** alanlarında ve `.godot/editor_tool_checks/results.json` dosyasında görünür; çıktıya durum satırı
yazılır. Denetimler sahnelerini yalnızca her çalıştırmada temizlenen o klasöre kaydeder: projenin hiçbir sahnesi ve
oyuncunun hiçbir ayarı yazılmaz. Bkz. [Testler](testing.md#editördeki-denetimler).

---

*Bu sayfa Iso & Orbit 1.3.0 sürümüne karşılık gelir.*
