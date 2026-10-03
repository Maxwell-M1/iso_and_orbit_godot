<!-- translation of docs/en/systems/characters.md @ 7b2e479acc2d -->
# Karakterler

> Bu, [İngilizce orijinalin](../../en/systems/characters.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Karakter modelleri bir betikle ilkel şekillerden (kapsüller, silindirler, küreler, prizmalar) oluşturulmuştur ve
mantıktan ayrı olarak `shared/characters/` içinde bulunur. Aynı model kahramanın modeli olabilir ya da seviyede
durabilir.

## Modeller ve ekipman

| Model (`shared/characters/models/`) | Kim | Ekipman |
|---|---|---|
| `knight.tscn` | Şövalye: plaka zırh, T biçimli siperlikli ve kırmızı sorguçlu kova miğfer, haçlı kırmızı üstlük, omuzluklar | Kılıç, haçlı yuvarlak kalkan |
| `ranger.tscn` | Korucu: kuyruklu yeşil kukuleta, gölgesinde soluk gözler, sırtında ok sadağı | Yay |
| `mage.tscn` | Büyücü: altın kenarlı çan biçimli mor cüppe, bükük sivri şapka, beyaz sakal | Halkalı, parlayan, havada süzülen bir küre, bir büyü kitabı |
| `dwarf.tscn` | Cüce: kısa ve geniş, boncuklu kızıl sakal, bir burun, boynuzlu miğfer | İki elli balta |
| `rogue.tscn` | Haydut: koyu kukuleta, sarı gözler, kırmızı maske, üç parçalı pelerin, kemer kesesi | İki hançer, soldaki ters tutuşta |

Her modelin uyduğu kurallar:

- −Z yönüne bakar, ayakları orijindedir.
- Elleri boş `RightHand` ve `LeftHand` düğümleridir, yani "görünmez eller". `equipment/` içinden bir sahne (asa,
  kılıç, kalkan, yay, balta, hançer, kitap, küre) bir ele konur; ekipmanın orijini tutulduğu yerdir. Bir silahı
  değiştirmek için el düğümünün alt düğümünü değiştirin: oyunda çalışma anında ya da model sahnesinde kalıcı olarak.
  Nesnenin eğimi, eldeki dönüşüdür.
- Ortak ekipman malzemeleri (çelik, pirinç, deri, kemik, parlayan taşlar ve gözler) `materials/` içindedir; gövde ve
  giysi renkleri model sahnelerinin içindedir.

## Kahraman görünümleri

Kahraman, `Visual` ile birlikte dönen `Player/Visual/Model` konumuna yerleştirilmiş on büyücü görünümünden biridir
(varsayılan olarak Savaş Büyücüsü). Asa sağ eldedir. Tüm görünümlerin ortak noktaları oyuncu boyutunda bir kapsül
gövde, kendi gözleri (`EyeRight`, `EyeLeft`) ve `RightHand` içindeki bir asadır; bu yüzden herhangi biri kahraman
olarak çalışır.

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

Seviyede onu da güney duvarının güney tarafında, sırtları duvara dönük olarak (duvardaki boşluğun doğusunda), güneye
bakarak ve her birinin başının üstünde numarasıyla sıra hâlinde durur. Sıranın tamamının önünde açık bir geçit
vardır.

## CharacterAppearance

Modeli çalışma anında değiştirir (Ayarlar → Karakter → **Kahraman görünümü**). `set_look(number)` eski modeli
kaldırır ve yenisini aynı adla onun yerine koyar. Ayrıca yeni modelin fizik enterpolasyonunu sıfırlar (aksi hâlde
model orijinden kayarak gelirdi) ve yeni modelin `RightHand` düğümünü `HandSway` bileşenine verir; böylece asa
yeniden adımlarla sallanır. Siluet yeni örgüleri kendiliğinden alır.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `slot` | — | Modeli tutan düğüm (oyuncuda `GroundCharacter` tarafından döndürülen `Visual`) |
| `model_name` | `Model` | `slot` içindeki model düğümünün adı |
| `models` | — | Seçilebilecek model sahneleri; görünüm numarası, 1'den başlayarak bu listedeki sıradır |
| `hand_sway` | — | Yeni modelin elini kimin alacağı; boşsa el sallanmaz |
| `hand_path` | `RightHand` | Nesne tutan elin modeldeki yeri |

`get_look()` geçerli numarayı (listede olmayan bir model için 0), `get_model()` model düğümünü döndürür. Sinyal:
`look_changed(model)`.

## HandSway: elde tutulan, yana yapışık olmayan bir asa

`HandSway` (oyuncuda `RightHandSway`) modelin el düğümünü dinlenme konumuna göre hareket ettirir:

- **Adımlarla**, ayak seslerinin de izlediği ritim olan `GroundCharacter.get_step_phase()` ile. Her adımda el bir uç
  noktadadır (sırayla önde ve arkada, ±7 cm) ve en alçaktadır (2,5 cm); adımların ortasında el ortadadır. Nesne
  eğimde biraz geride kalır (±7°). Sallanma hızla büyür, deparda bir buçuk kat daha büyüktür ve karakter durduğunda
  veya havadayken söner.
- **Koşarken** nesne öne eğilir (6°).
- Bir yay üzerinde **atalet** (1,8 Hz, sönümleme 0,45): hızlanmada üst uç geriye, frenlemede öne, dönüşlerde dışa
  gider ve durulana kadar salınır. İnişte el, düşüş ne kadar hızlıysa o kadar derine iner; kalkışta biraz iner.

Fizik tikinde gövdeden sonra çalışır; böylece fizik enterpolasyonu onu da gövde gibi yumuşatır. Adım ritmi
süreklidir: adımın ortasında durursanız bir sonraki adım, yeniden başladıktan `first_step_distance` sonra gelir, ancak
faz sıçramaz; o adımda tam sayıya ulaşır. Başka bir el veya bir NPC için kendi eliyle birlikte başka bir `HandSway`
ekleyin. Genlikler, eğilme ve yay, Swing (sallanma) ve Inertia (atalet) gruplarındaki dışa aktarılmış özelliklerdir.

## OccludedSilhouette: tek şekil, hatları belirgin silah, kontur

Bir şey kahramanı gizlediğinde (dağ, bir ev, bir ağaç) kahraman açık mavi bir siluet olarak görünür: gövde için tek
bir düz şekil, onun üstünde hatları belirgin elde tutulan ekipman ve her şeyin çevresinde bir kontur.

`OccludedSilhouette` (oyuncuda `Silhouette`), sonradan eklenenler (yeni bir görünüm veya silah,
`SceneTree.node_added` üzerinden) dahil modelin her örgüsüne `material_overlay` ayarlar. Modelin kendi malzemeleri
değişmez; bu yüzden seviyedeki aynı modelin silueti olmaz. Gövde örgüleri ve el düğümlerinin (`gear_nodes`:
`RightHand`, `LeftHand`) altındaki örgüler farklı geçiş zincirleri alır.

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

`outline_enabled` (Ayarlar → Görüntü → **Engel arkasında siluet konturu**) son geçişi zincirlerden kaldırır. Kontur
genişliği `silhouette_outline.tres` dosyasının `width` parametresidir; renkler dolgulardaki ve konturdaki `color`
parametresidir.

İki motor ayrıntısı: stencil arabelleği Godot 4.5+ sürümlerinde deneyseldir ve yalnızca saydam bir geçişte
okunabilir. Ayrıca Godot 4.7'de (D3D12 ve Vulkan) gölgelendiricilerdeki izdüşüm Y ekseninde ters çevrilmiştir:
`PROJECTION_MATRIX[1][1]` negatiftir. `abs()` olmadan "ekran payı → metre" dönüşümü negatife düşer, kontur örgüsü
küçülür ve kontur kaybolur.

## Modelleri düzenleme

Modeller bir betikle ilkel şekillerden oluşturulmuştur ve artık sıradan sahnelerdir: onları editörde diğer sahneler
gibi düzenleyin.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
