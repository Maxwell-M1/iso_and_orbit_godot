<!-- translation of docs/en/controls.md @ 18ede9271cf7 -->
# Kontroller

[← Belge dizini](index.md)

> Bu, [İngilizce orijinalin](../en/controls.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Fare ve klavye; oyun kumandası desteği yoktur. Aşağıdaki davranışların çoğu ayarlar penceresinden (F10)
değiştirilebilir, bkz. [Ayarlar](settings.md). Girdinin iç işleyişi: [Girdi](systems/input.md).

Bu sayfadaki ve belgelerdeki tuş/düğmeler, demonun Project Settings → Input Map varsayılanlarıdır. Oyundaki,
ayarlar penceresindeki ve yükleme ekranındaki ipuçları güncel atanmış tuş adlarını gösterir; atama değişince
yenisini gösterirler (bkz. [Metinlerde tuş adları](systems/ui.md#metinlerde-tuş-adları)).

| Girdi | Eylem |
|---|---|
| Zemine sol tık | Engellerin etrafından dolanarak o noktaya koşar; zeminde bir işaretçi belirir |
| Sol tuşu basılı tutmak | İmlecin peşinden koşar; koşarken imleç gizlenir |
| Önce sol tuşu basılı tutup sonra sağ tuşa basmak | Koşarken etrafa bakar: fare kamerayı döndürür, kahraman rotasını korur. Sağ tuşu bırakınca fareyle yönlendirme sürer |
| Önce sağ tuşu basılı tutup sonra sol tuşa basmak veya ikisine birlikte basmak | Kameranın baktığı yöne koşar ve kamera döndükçe döner; A / D ileriye çapraz saptırır. Durmak için sol tuşu veya iki tuşu herhangi bir sırayla bırakın |
| Sağ tuş + fare | Kamerayı kahramanın etrafında döndürür; ardından imleç eski yerine döner |
| Sağ tuş + WASD | Kameraya göre hareket eder, yana adımla veya dönerek (aşağıya bakın). Durmak için tuşları ya da sağ tuşu bırakın |
| Fare tekerleği | Kamerayı kahramana daha yakın alçaltır ya da daha yükseğe ve uzağa kaldırır |
| Shift | Basılıyken depar ya da basışla aç/kapa (bir ayar). Yorgunluk açıkken dayanıklılık yettiği sürece; dayanıklılık çubuğu ekranın altındadır |
| Boşluk | Zıplar |
| E | Işınlanma platformunda götürdüğü yere geçer; teklife tıklamak da aynı işi yapar |
| F10 | Ayarlar (oyunu duraklatır); Esc veya F10 kapatır |

## Tıklama veya basılı tutma

Bir basışın tıklama mı yoksa basılı tutma mı olduğuna 0,2 sn sonra karar verilir.

- **Tıklama** (daha erken bırakılırsa): fare sonradan hareket etmiş olsa bile kahraman bastığınız noktaya bir yol
  boyunca koşar ve orada bir işaretçi belirir. Koşu, tuş bırakılınca başlar. İşaretçi, kahraman vardığında ya da
  basılı tutarak veya tuşlarla kontrolü devraldığınızda solar.
- **Basılı tutma** (daha uzun basılırsa): kahraman hemen imlecin peşinden koşar ve hiçbir zaman bastığınız noktaya
  doğru dönmez.

Karar verilene kadar kahraman yaptığı şeyi sürdürür.

Kahramanın basılı tuşu nasıl izleyeceği (Ayarlar → Kontroller → **Basılı sol tuş**):

- **Doğrudan imlece** (varsayılan): yol araması yapılmaz. Kahraman engeller boyunca kayar, rampaya nereden
  yönlendirirseniz oradan çıkar ve tuş bırakılınca yumuşakça durur.
- **Yol boyunca noktaya**: kahraman imlecin altındaki noktaya bir navigasyon yolu izler. Yükseklik değişimlerinin
  yakınında (rampa, platform) yol, rotalar arasında atlayabilir. Tuş bırakılınca kahraman son noktaya kadar koşmayı
  sürdürür.

Sol tuş basılıyken kamera kendiliğinden dönerse (takip modu), imleç dünyayla birlikte hareket edip nişan
aldığınız yerin üstünde kalır; kahraman rotasını korur. Koşarken etrafa bakmak için sağ tuşla döndürmede de
böyledir. Ayarlar → Kamera → **Kamera dönerken imleç hedefini korur**.

## Fare tuşlarının basış sırası

Sağ tuş her zaman kamerayı döndürür. Koşuyu da yönlendirip yönlendirmeyeceği basış sırasına bağlıdır.
Varsayılan ayarlarda:

| Basış sırası | Kahraman | Kamera |
|---|---|---|
| Sol tuş basılı | İmlece doğru düz koşar | Yerinde kalır (takip varsayılan olarak kapalı) |
| ...sonra sağ tuş da basılı, fare hareketli | Aynı yönde koşar: etrafa bakmak yönü değiştirmez. Bu sırada tuşlar etkisizdir | Kahraman çevresinde döner |
| ...sonra sol hâlâ basılıyken sağ tuş bırakılır | Aynı yönde koşar. Gizli imleç hedeflenen yerin üstündedir, fare oradan yönlendirir | Seçilen açıda kalır |
| ...veya önce sol tuş bırakılır | Yumuşakça durur; sağ tuş bırakılınca imleç hedeflenen yerde belirir | Sağ tuş bırakılana dek döner |
| Önce sağ sonra sol tuş veya 0.2 s içinde ikisi | Kameranın baktığı yöne koşar ve onunla döner; A / D çapraz saptırır | Fareyle döner |
| ...sonra sol hâlâ basılıyken sağ tuş bırakılır | Fare hareket edene kadar kameranın yönünde gider; sonra kahramanın 4 m önüne taşınan imleç yönlendirir | Seçilen açıda kalır |
| ...fareyi hareket ettirmeden sağ tuşa yeniden basılır | Yine kameranın baktığı yöne koşar. Fare hareket edip imleç yönlendirmeye başladıktan sonra sağ tuş yalnız etrafa baktırır | Fareyle döner |
| Sol tuş bırakılır | Yaklaşık çeyrek saniyede yumuşakça durur. Sağ tuş ve W basılıysa tuşlarla yürümeyi sürdürür | — |
| İki tuş herhangi sırayla ve arada herhangi süreyle bırakılır; arada fare de oynasa | İmlece dönmeden kendi rotasında durur | — |
| Tıklama, sonra sağ tuş | Tıklanan noktaya koşmayı sürdürür | Kahraman çevresinde döner |
| Sağ tuş ve WASD | Kameraya göre yürür, gittiği yöne döner | Fareyle döner |

Etrafa bakmadan hiç durmadan kameranın baktığı yöne koşmaya geçmek için sağ tuş basılıyken sol tuşa yeniden basın.

### Ayarların değiştirdikleri

- **{move_to_cursor} ile koşarken {camera_rotate} yalnızca kamerayı döndürür** (Kontroller) kapalıysa sağ tuş
  sırası ne olursa olsun koşuyu yönlendirir; imleç ardındaki koşu sırasında basılırsa kahraman hemen kameranın
  baktığı yöne döner.
- **Kamera dönerken imleç hedefini korur** (Kamera) kapalıysa etrafa bakarken imleç ekranda aynı yerde kalır;
  koşu kamerayla birlikte yay çizerek döner. Koşuyu izleyen kamera da aynı etkiyi yapar.
- **Basılı sol tuş → Yol boyunca noktaya** (Kontroller) seçiliyken kahraman imleç altındaki noktaya yol izler.
  Etrafa bakarken ve sonrasında fare oynayana kadar koştuğu nokta imlecin altında değil, kahramana göre eski
  yerindedir; başka açıdan imleç rampayı veya platformu gösterebilir. Sol tuş bırakılınca son noktaya koşar.
- **Basılı sol tuşla koşarken imleci gizle** (Kontroller) kapalıysa etrafa baktıktan sonra imleç eski ekran
  yerinden, kamera dönerken nişan aldığı yeni yere sıçrar.
- **Kamerayı koşu yönüne çevir**, **Koşarken kamera eğimini hizala**, **Koşarken kamera yüksekliğini hizala**
  (Kamera): kamera imleç ardındaki veya tıklanan noktadaki koşuyu yumuşakça izler, ancak sağ tuş basılıyken
  izlemez. Sağ tuşla döndürdükten sonra, koşarken etrafa bakıldığında da, kahraman durana veya sol tuşla yeni
  koşu (yeni noktaya tıklama veya yeni basılı tutma) başlatılana dek seçilen açıda kalır. Tuşlarla yürüyüşü
  izlemez: tuşlar sağ tuşu gerektirir.
- **Sağ tuş + WASD** ve **Sol + sağ tuş + A/D** (Kontroller): tuşların hareket biçimi; aşağıya bakın.

## Sağ tuşla kullanılan tuşlar

WASD yalnızca sağ tuş basılıyken çalışır. Sağ tuş olmadan hiçbir şey yapmaz. Mod, yalnız sağ tuş (**Sağ tuş +
WASD**) ve iki tuş birlikte (**Sol + sağ tuş + A/D**) için ayrı ayrı seçilir; her birinde **Kapalı** ve iki seçenek
vardır:

| | Yana adım | Dönüş / çapraz (varsayılan) |
|---|---|---|
| Sağ tuş + W | ileri, kameranın baktığı yöne | aynısı |
| Sağ tuş + A / D | yana, yüz önde | sola / sağa döner ve o yöne gider |
| Sağ tuş + S | geriye, yüz önde, daha yavaş | geri döner ve kameraya doğru yürür |
| İki tuş (W + A, S + D…) | çapraz, yüz önde | çapraz, yüz gidiş yönünde |
| Sol + sağ tuş + A / D | çapraz ileri, yüz önde | çapraz ileri, yüz gidiş yönünde |

Çapraz hareket, düz hareket kadar hızlıdır. Geri geri yürüme varsayılan olarak %30 daha yavaştır (5,5 yerine
3,85 m/sn; Ayarlar → Kontroller → **Geri yürürken (S) yavaşlama**). Çapraz geriye hareket kısmen yavaşlar (yana
adımda S + D: %21), yana hareket hiç yavaşlamaz; bu yüzden yavaşlama yalnızca yana adım modunda vardır.

Durduktan sonra kahraman baktığı yöne bakmayı sürdürür; bir tıklama ya da basılı tutma onu yeniden koştuğu yöne
çevirir.

Tuşlara basmadan yalnızca sağ tuşu basılı tutmak, tıklanan noktaya koşuyu kesmez; böylece koşarken kamerayı
çevirebilirsiniz. Sağ tuş ve W basılıyken sol tuşu bırakırsanız kahraman durmadan tuşlarla yürümeyi sürdürür.
**Kapalı** olarak ayarlanan mod, kontrol ipuçlarındaki satırını da kaldırır. Tuşların iki fare düğmesiyle
birlikte etkisi için [Fare tuşlarının basış sırası](#fare-tuşlarının-basış-sırası) bölümüne bakın.

Hareket tuşları ABD QWERTY klavyedeki WASD fiziksel konumlarına bağlıdır. Gösterilen harfler klavye düzenini izler;
örneğin AZERTY'de aynı konumlar ZQSD olur. Atamaları Project Settings → Input Map içinden değiştirin; demoda
henüz oyun içi yeniden atama menüsü yoktur.

## Kamera

- **Yörünge:** sağ tuş ve fare. Ayarlar → Kamera → **Sağ tuş kamerayı yukarı ve aşağı eğer** açıksa (varsayılan
  olarak kapalı) dikey hareket kamerayı da eğer.
- **Yakınlaştırma:** tekerlek mesafeyi ve eğimi birlikte değiştirir. Orta seviyenin altında kamera hızla yataylaşır,
  böylece ileride ne olduğunu görürsünüz.
- **Takip** (varsayılan olarak kapalı): Ayarlar → Kamera → **Kamerayı koşu yönüne çevir**,
  **Koşarken kamera eğimini hizala** ve **Koşarken kamera yüksekliğini hizala**. Sağ tuş basılıyken veya sol
  tuşa basışın ilk 0.2 s'sinde kamera takip etmez. Sağ tuşla, koşarken etrafa bakma dahil, döndürüldükten sonra
  kahraman durana veya sol tuşla yeni koşu başlatılana kadar seçilen açıda kalır; karakter frenlerken veya
  tıklanmış noktaya koşarken birden dönmez. Tuşlar sağ tuşu gerektirdiğinden tuşlarla yürüyüş izlenmez.
- **Engeller:** kamera arkasındaki dağda, duvarda veya çatıda durur. İsteğe bağlı olarak bir engel kahramanı
  gizlediğinde yaklaşır. Engellerin arkasında kahraman siluet olarak görünür.

Ayrıntılar: [Kamera](systems/camera.md).

## Işınlanma

Kadim Çember yanındaki ışıklı platform Issız Ada'ya, adadaki platform geriye götürür. Üstüne çıkınca ekranın
altında "E ile ... ışınlan" teklifi belirir; uzaklaşınca gizlenir. E'ye basın (platforma deparla girip Shift'i
basılı tutsanız da çalışır) veya teklife tıklayın: yükleme ekranı geçişi örter, kahraman diğer platformun yanına
kamera arkasında olacak biçimde varır ve kontroller geri gelir. Geçiş boyunca basılı kalan sol tuş ancak sonraki
basışında yeni basış sayılır; hâlâ basılı tuşlar (W, A, S veya D ile sağ tuş ya da Shift) hemen çalışır.
Ayrıntılar: [Seviyeler](systems/levels.md).

## Depar ve zıplama

- **Depar:** Shift basılıyken ve kahraman hareket ederken 1,5 kat daha hızlı. Yorgunluk açıkken dayanıklılık 5 sn
  yeter; bitince kahraman, dayanıklılık %30'a dolana kadar normal hızda koşar, Shift hâlâ basılıysa ardından
  kendiliğinden yeniden depar atar. Shift basılıyken yerinde durmak hiçbir şey harcamaz. Aç/kapa modunda bir basış
  deparı açar, bir sonraki kapatır; kahraman bitkin düştüğünde de kapanır.
- **Zıplama:** 1 m yükseklik. İnişten kısa süre önce basılan zıplama inişte gerçekleşir; bir kenardan yürüyerek
  çıktıktan kısa süre sonra basılan zıplama da çalışır. Kenar koruması kenardan zıplamayı engellemez.

Ayrıntılar: [Hareket](systems/locomotion.md).

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
