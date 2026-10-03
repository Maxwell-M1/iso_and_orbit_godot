<!-- translation of docs/en/known-issues.md @ 4b99df29bb4c -->
# Bilinen sorunlar

> Bu, [İngilizce orijinalin](../en/known-issues.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Projenin sınırlamaları ve projenin etrafından dolaştığı motor tuhaflıkları. Her madde ne gördüğünüzü ve ne yapmanız
gerektiğini söyler.

## Sınırlamalar

- **Yalnızca fare ve klavye.** Oyun kumandası desteği yoktur.
- **Animasyon yok.** Modeller durağan ilkel şekillerdir; yalnızca eldeki nesne adımlarla sallanır (`HandSway`). Bir
  `AnimationTree` yönetmek için `NavigationMover.get_speed()` ve `GroundCharacter.get_step_phase()` hazırdır.
- **Karakterler arasında kaçınma yok.** `NavigationMover` bir yolu izler ve navigasyon kaçınmasını (avoidance)
  kullanmaz; bu yüzden hareket eden karakterler birbirlerinin etrafından dolaşmaz. Oyuncunun gövdesi 2. katmandadır
  ve yalnızca 1. katmanla çarpışır; bu yüzden `player.tscn` ile yapılmış iki karakter birbirinin içinden geçer;
  birbirlerini engellemeleri gerekiyorsa `collision_mask` özelliklerine 2. katmanı ekleyin. Demodaki NPC'ler yerinde
  durur ve navigasyon örgüsüne engel olarak pişirilmiştir.
- **Navigasyon örgüsü önceden pişirilmiştir.** Çalışma anında bir engeli taşımak yolları değiştirmez. Seviyeyi
  düzenledikten sonra örgüyü yeniden pişirin
  ([Dünya ve navigasyon](systems/world-and-navigation.md#navigasyon-örgüsünü-yeniden-pişirme)).
- **Yalnızca Godot 4.7.** Proje 4.7.2 üzerinde test edilmiştir. Siluet stencil arabelleğine (4.5+) ihtiyaç duyar ve
  sahne uyarıları denetimi 4.7.2'nin koşullarını yineler.

## Girdi

- **Tıklama, bırakınca etki eder.** Bir basış ancak 0,2 sn sonra (`hold_delay`) ya da bırakıldığında tıklama veya
  basılı tutma olur; bu yüzden bir tıklama, basışta etki etseydi olacağından yaklaşık 0,1 sn daha geç etki eder. Bu
  kasıtlıdır: aksi hâlde basılı tutma önce kahramanı basılan noktaya bir yol boyunca gönderirdi. Bkz.
  [Girdi](systems/input.md#tıklama-veya-basılı-tutma).
- **Bazı sistemlerde imleç hedefini koruyamayabilir.** Kamera dönerken hedefi korumak sistem imlecini hareket
  ettirir (`Viewport.warp_mouse()`). Sistemin buna izin vermediği yerlerde (örneğin Wayland) koşu yönü yine korunur,
  ancak imleç ekranda olduğu yerde kalır.
- **"Yol boyunca noktaya" rota değiştirebilir.** Bu basılı tutma modunda imlecin altındaki nokta hareket ettikçe yol
  yeniden oluşturulur ve yükseklik değişimlerinin yakınında (rampa, platform) bir rotadan diğerine atlayabilir.
  Varsayılan mod olan doğrudan imlece hareketin böyle bir sorunu yoktur.
- **Oyun editörün içinde çalışırken Shift takılı kalabilir.** Oyun editörün Oyun (Game) sekmesine gömülüyken odak
  editöre geçerse motor basılı tuşları sıfırlamaz. Depar eylemi değiştirici tuşlara atanmış olduğu sürece
  `CharacterActionInput`, takılı kalan deparı bir sonraki fare veya klavye olayında bırakır. Windows Yapışkan Tuşlar
  (Sticky Keys) özelliği açılırsa (art arda beş Shift basışı), Shift sistemin kendisinde takılı kalır; Yapışkan
  Tuşlar'ı Windows ayarlarından kapatın. Bkz. [Girdi](systems/input.md#shift-takılmaz).

## Kamera

- **Bir engelin hemen arkasındaki gövde.** Jolt, bir şekil atımının başlangıcında temas ettiği gövdeleri bildirmez.
  Kameranın içinde bulunduğu engelin hemen arkasında başka bir gövde varsa (arkasında uçurum olan bir çit), kol
  bunun yerine hedefe daha yakın boş alan arar. Bkz.
  [Kamera](systems/camera.md#kol-engelin-arkasındaki-boşluğu-bir-gövdenin-içinde-olmaktan-nasıl-ayırır).
- **Harekette kesiklik.** Fizik enterpolasyonu varsayılan olarak kapalıdır. O olmadan karakter ve kamera tikten tike,
  saniyede 60 kez hareket eder; bu da hızlı bir monitörde düzensiz görünür. Ayarlar → Görüntü'den açın.

## Testler

- **Nadir bir Jolt uyarısı çalıştırmayı başarısız kılar.** Yoğun CPU yükü altında, örneğin yeni bir içe aktarmanın
  hemen ardından yapılan ilk çalıştırmada, Jolt Physics "Jolt Physics job system exceeded the maximum number of jobs.
  This should not happen." yazdırabilir. Test çalıştırıcısı her motor uyarısını ve hatasını başarısızlık sayar; bu
  yüzden tüm denetimler geçse de çalıştırma 1 çıkış koduyla ve "engine and script errors: 1" ile biter. Uyarı
  projeden değil, motorun fizik iş sisteminden gelir: testleri meşgul olmayan bir makinede yeniden çalıştırın.

## İşleme

- **Siluet deneysel bir motor özelliği kullanır.** Stencil arabelleği Godot 4.5+ sürümlerinde deneyseldir ve
  yalnızca saydam bir geçişte okunabilir. Gelecekteki bir motor sürümü bunu değiştirirse bakılacak yer siluettir.
- **Godot 4.7'de izdüşüm Y ekseninde ters çevrilmiştir** (D3D12 ve Vulkan): gölgelendiricilerde
  `PROJECTION_MATRIX[1][1]` negatiftir. Siluet konturu bunun `abs()` değerini alır; bu olmadan kontur örgüsü küçülür
  ve kontur kaybolur.

## Proje dosyaları

- **Yuvarlanmış dönüşler "non-uniform scale" uyarılarına yol açar.** Bir `.tscn` dosyasına 4 basamakla yazılan bir
  dönüş, temel (basis) eksen uzunluklarının 1e-5'ten fazla farklı olmasına yol açar ve motor gövdelerde ve
  şekillerde tekdüze olmayan ölçek bildirir. `Transform3D` sayılarını tam hassasiyetle yazın (9 anlamlı basamak).
- **`shared/` henüz tamamen dilden bağımsız değil.** `world.tscn` ve `mountain.tscn`,
  `addons/iso_orbit/points_of_interest/point_of_interest.gd` betiğini kullanır ve iki küçük dekor betiği
  `shared/world/props/` içinde bulunur. Bir C# sürümünün kendi yerler betiğine ya da yerleri yalnızca sahne
  aracılığıyla işaretlemenin bir yoluna ihtiyacı olurdu.
- **Çıkışta bildirilen sızan kaynaklar.** Bir betik ayak sesleri çaldıktan hemen sonra çıkarsa motor sızan
  `AudioStreamPlayback` nesneleri bildirebilir: `--fixed-fps` ile oyun süresi gerçek zamanın önüne geçer, sesler ise
  hâlâ çalar. Çıkmadan önce sahneyi serbest bırakın ve bir süre bekleyin; `tests/run_checks.gd` 0,1 sn bekler.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
