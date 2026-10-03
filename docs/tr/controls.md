<!-- translation of docs/en/controls.md @ b096a8a367b0 -->
# Kontroller

> Bu, [İngilizce orijinalin](../en/controls.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Fare ve klavye; oyun kumandası desteği yoktur. Aşağıdaki davranışların çoğu ayarlar penceresinden (F10)
değiştirilebilir, bkz. [Ayarlar](settings.md). Girdinin iç işleyişi: [Girdi](systems/input.md).

| Girdi | Eylem |
|---|---|
| Zemine sol tık | Engellerin etrafından dolanarak o noktaya koşar; zeminde bir işaretçi belirir |
| Sol tuşu basılı tutmak | İmlecin peşinden koşar; koşarken imleç gizlenir |
| Sol + sağ tuş, herhangi bir sırayla | Kameranın baktığı yöne koşar. Kamerayı fareyle çevirin, kahraman da onunla birlikte döner. A / D çapraz olarak ileriye yönlendirir. Durmak için sol tuşu bırakın |
| Sağ tuş + fare | Kamerayı kahramanın etrafında döndürür; ardından imleç eski yerine döner |
| Sağ tuş + WASD | Kameraya göre hareket eder, yana adımla veya dönerek (aşağıya bakın). Durmak için tuşları ya da sağ tuşu bırakın |
| Fare tekerleği | Kamerayı kahramana daha yakın alçaltır ya da daha yükseğe ve uzağa kaldırır |
| Shift | Basılıyken depar ya da basışla aç/kapa (bir ayar). Yorgunluk açıkken dayanıklılık yettiği sürece; dayanıklılık çubuğu ekranın altındadır |
| Boşluk | Zıplar |
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

Tuş basılıyken kamera döndüğünde (takip modu) imleç dünyayla birlikte hareket eder ve nişan aldığınız noktanın
üstünde kalır; böylece kahraman rotasını korur. Ayarlar → Kamera → **Kamera dönerken imleç hedefini korur**.

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
**Kapalı** olarak ayarlanan bir mod, kontrol ipuçlarındaki satırını da kaldırır.

Tuşlar fiziksel konumlarına göre atanmıştır; bu yüzden her klavye düzeninde WASD konumunda kalırlar.

## Kamera

- **Yörünge:** sağ tuş ve fare. Ayarlar → Kamera → **Sağ tuş kamerayı yukarı ve aşağı eğer** açıksa (varsayılan
  olarak kapalı) dikey hareket kamerayı da eğer.
- **Yakınlaştırma:** tekerlek mesafeyi ve eğimi birlikte değiştirir. Orta seviyenin altında kamera hızla yataylaşır,
  böylece ileride ne olduğunu görürsünüz.
- **Takip** (varsayılan olarak kapalı): Ayarlar → Kamera → **Kamerayı koşu yönüne çevir** ve **Kamera eğimini
  hizala**. Sağ tuş basılıyken ya da sol tuşa basışın ilk 0,2 sn'sinde kamera takip etmez.
- **Engeller:** kamera arkasındaki dağda, duvarda veya çatıda durur. İsteğe bağlı olarak bir engel kahramanı
  gizlediğinde yaklaşır. Engellerin arkasında kahraman siluet olarak görünür.

Ayrıntılar: [Kamera](systems/camera.md).

## Depar ve zıplama

- **Depar:** Shift basılıyken ve kahraman hareket ederken 1,5 kat daha hızlı. Yorgunluk açıkken dayanıklılık 5 sn
  yeter; bitince kahraman, dayanıklılık %30'a dolana kadar normal hızda koşar, Shift hâlâ basılıysa ardından
  kendiliğinden yeniden depar atar. Shift basılıyken yerinde durmak hiçbir şey harcamaz. Aç/kapa modunda bir basış
  deparı açar, bir sonraki kapatır; kahraman bitkin düştüğünde de kapanır.
- **Zıplama:** 1 m yükseklik. İnişten kısa süre önce basılan zıplama inişte gerçekleşir; bir kenardan yürüyerek
  çıktıktan kısa süre sonra basılan zıplama da çalışır. Kenar koruması kenardan zıplamayı engellemez.

Ayrıntılar: [Hareket](systems/locomotion.md).

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
