<!-- translation of docs/en/testing.md @ 9fd6c842b560 -->
# Testler

> Bu, [İngilizce orijinalin](../en/testing.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Testler ana sahneyi gerçek girdi olayları ve gerçek fizikle headless (pencere açmadan) çalıştırır ve ölçümleri
beklentilerle karşılaştırır.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Burada `godot`, Godot 4.7.2 çalıştırılabilir dosyanızdır. Windows'ta `_console.exe` sürümünü kullanın: normal sürüm
terminalden ayrılır, bu yüzden çıktı görmezsiniz ve çıkış kodu alamazsınız. Yeni bir klonda önce projeyi bir kez içe
aktarın: editörde ya da `godot --headless --path . --import` ile.

Yalnızca bazı test paketleri, örneğin kamera üzerinde çalışırken: adlarının parçalarını `--` sonrasına yazın.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

Herhangi bir denetim başarısız olursa çıkış kodu 1 olur. Sonunda çalıştırıcı, her test paketinde kaç denetimin
geçtiğini ve kaçının başarısız olduğunu yazdırır.

## Test paketleri

Test paketleri, `tests/run_checks.gd` içindeki `SUITES` sırasıyla, ana sahnenin tek bir örneği üzerinde çalışır.

| Test paketi | Neyi kapsar |
|---|---|
| `movement_checks.gd` | Hızlanma ve tam duruş, frenlerken yeni bir tıklama, frenlerken dönüş, tam hızda geri dönüş. Rotalar: tuzağın etrafından, duvardaki boşluktan, labirent, rampadan yukarı ve aşağı, rampanın yanlarından platforma, bir sandığın üzerindeki ulaşılamaz nokta. Kenar koruması ve onsuz düşme |
| `world_checks.gd` | Dağ: zeminden zirveye patika boyunca bir yol, yer mesajıyla birlikte bir kez keşfedilir, patikanın dışında yamaca tırmanılamaz, koruma patikada tutar. Kamp, çiftlik ve harabeler mesajlarıyla keşfedilir. NPC'ler: ekipmanlı ve etiketli beş NPC, her yerde biri var, hepsi zeminde duruyor, yollar onların etrafından geçiyor, kimse içlerinden geçmiyor. Kahraman görünümleri: numarayla on görünüm, her birinin gövdesi, gözleri ve sağ elinde asası var; sıranın önündeki geçit tam hızda geçilebilir |
| `hero_look_checks.gd` | Oyuncunun modeli: dönerken asa sağ elde; gövde ve ekipman için ayrı siluet zincirleri, sonradan eklenen örgülerde de; kontur ayarı. El sallanması: dururken hareketsiz; koşarken sallanma ve alçalma, uç noktalar sırayla adımlarda; hızlanmada geride kalma; duruştan sonra geri dönme; inişte alçalma. Kahraman görünümü: başlangıçta varsayılan; on görünümün her biri çalışma anında tek modelle ayarlanır, asa yeni elde sallanır ve siluet yeni örgülerde olur |
| `character_actions_checks.gd` | Girdi eylemi üzerinden depar ve yorgunluk, dayanıklılık çubuğu. Basılı tutma modunda Shift'i gerçek olaylarla bırakma (koşarken, sol tuşla, ayarlar penceresinde, aç/kapa modundan sonra, kaybolan bir bırakma). Aç/kapa modu. Depar ve zıplama kapalı, yorgunluksuz depar. Zıplama: yükseklik, tampon, çakal süresi, koruma açıkken kenardan zıplama, 1,5 m zıplama. Karakter sinyalleri: mesafeye göre ve deparda daha sık adımlar, dururken veya havadayken adım yok, düşüş hızıyla zıplama ve iniş, rampadan inişsiz yürüyerek inme, depar başlangıcı ve bitişi. Her sinyal için bir ses ve aç/kapa düğmeleri; depar döngüsü döngü hâlinde çalar |
| `input_checks.gd` | Fare tıklaması: basılıyken koşu ve işaretçi yok, bırakınca basılan noktaya koşu. `STEER` modunda basılı tutma: imlece doğru koşu, asla basılan noktaya değil, işaretçi yok, bırakınca hızlı duruş. `FOLLOW_POINT` modunda basılı tutma: basılıyken koşu; bırakınca `stop_on_release` ile hızlı duruş, aksi hâlde imlecin son noktasına işaretçisiyle koşu. İki tuş: rampadan yukarı, kamerayla dönme. Sağ tuş + WASD yana adım ve dönüş: W, A, D, S ve tuş çiftleri için yön, bakış ve hız; sağ tuş olmadan veya kapalı modda hiçbir şey; tuşlarla ve fare tuşuyla durma; tek başına sağ tuş tıklamayı kesmez. Sol + sağ tuş + A/D üç modun hepsinde. Sağ tuş + W ile yürürken sol tuşa basıp bırakma: yürüyüş durmadan sürer. Tuşlar tıklanan noktaya koşudan vazgeçirir ve işaretçisi solar. Sol tuş basılıyken koşarken imleç gizli |
| `camera_checks.gd` | Takip modu (kapalı, anında, varsayılan, çok yavaş) ve duraklamaları (sağ tuş, karar verilmemiş bir basış). İmleç hedefini koruyarak ve korumadan sol tuşu basılı tutma. Fareyle yörünge ve yakınlaştırma: orta seviyenin altında tekerlek kamerayı hızla yataylaştırır; varsayılan olarak sağ tuş eğmez, ayarla eğer, ayar kapatılınca tekerleğin eğimi geri gelir. Koşarken eğim hizalama |
| `camera_arm_checks.gd` | Açık alanda tam uzunluk. Arkada bir uçurum: anında duruş; ona doğru yürürken kamera yaklaşır ve dışarıda kalır; uçurum kalkınca bir duraklamadan sonra yumuşak dönüş; durdurma kapalıyken kamera uçurumun içindedir. Hemen arkasında uçurum olan bir çit. Kamera katmanındaki gövdeler onu durdurur, karakter katmanındakiler durdurmaz. Yarı yolda bir çit: varsayılan olarak kamera arkasında kalır, yaklaşma açıkken yumuşakça önüne geçer, kısa bir örtülme sayılmaz. Karakterin dibinde bir çit: karakterin sırtına sıçrama yok. İnce bir direk sayılmaz. Kolu sıyıran bir sütun kamerayı oynatmaz. `camera_ignore` içindeki ve bu gruptaki bir düğümün altındaki gövdeler. Çok yakında saydamlaşma. Ayarlar kola ulaşır |
| `settings_window_checks.gd` | F10, duraklatma, odak, serbest bırakılan imleç yakalama; aç/kapa düğmeleri düğümlerine ulaşır; Kontroller sekmesi (tuş modları, geri yavaşlama kaydırıcısı); Ses sekmesi (ses düzeyi `Master` veri yoluna, aç/kapa düğmeleri karakter seslerine ulaşır); Karakter sekmesi (kahraman görünümü, zıplama yüksekliği, Shift modu, hız artışı, yorgunluk ve dayanıklılık); bağımlı öğeler soluklaşır; eğim kaydırıcısı kameranın sınırları içinde kalır; arayüz ölçeği; sıfırlama; Esc |
| `localization_checks.gd` | Varsayılan olarak İngilizce. Sahnelerdeki, açık ayarlar penceresindeki ve betiklerdeki her arayüz metninin her dilde bir çevirisi vardır ve kullanılmayan çeviri girdisi yoktur. Dili değiştirmek kodla oluşturulan metinleri değiştirir; dil adları çevrilmez; sıfırlama İngilizceye döndürür |

## Testlerin davranışı

- Varsayılan ayarlarla çalışırlar ve hiçbir şey kaydetmezler: oyuncunun ayarları çalıştırma süresince varsayılanlara
  sıfırlanır ve hiçbir zaman üzerine yazılmaz.
- Her denetim değiştirdiği şeyi geri yükler. Test paketleri tek bir ana sahne üzerinde art arda çalışır, tek başına
  çalıştırılan bir paket ise yeni bir sahne alır; bir denetim her iki durumda da geçmelidir.
- Herhangi bir motor veya betik hatası da çalıştırmayı başarısız kılar: `OS.add_logger()` ile eklenen bir `Logger`
  bunları sayar, çalıştırıcı sayıyı "engine and script errors" olarak yazdırır ve başarısızlıklara ekler. Çöken bir
  denetim yarıda kesilir ama diğerleri devam eder; sayaç olmasa çökme fark edilmeden geçerdi. Yoğun CPU yükü altında
  Jolt kendi uyarısını ekleyebilir, bkz. [Bilinen sorunlar](known-issues.md#testler).
- Takılan bir çalıştırma, 600 sn oyun süresinden sonra başarısız olur.
- Çıkmadan önce çalıştırıcı ana sahneyi kaldırır ve 0,1 sn bekler. `--fixed-fps` ile oyun süresi gerçek zamandan
  hızlı akar, ses ise gerçek zamanlı çalar; bu yüzden sondan hemen önce çalınan ayak sesleri hâlâ duyuluyordur. Hemen
  çıkmak bazen motorun sızan `AudioStreamPlayback` nesneleri ve ayak sesi kaynakları bildirmesine yol açar.
- Headless pencere sistem imlecini hareket ettiremez, bu yüzden testler yalnızca koşu yönünü görür; imlecin kendisi
  oyunda denetlenir. Headless pencere fare modunu da hiçbir zaman değiştirmez (`Input.mouse_mode` her zaman
  `VISIBLE`), bu yüzden gizli imleç için testler `PointClickMoveInput.is_cursor_hidden()` değerini okur.
- Sınırlar mümkün olduğunca bileşenlerin ayarlarından hesaplanır; bu yüzden `LocomotionSettings` ayarlamak testleri
  tek başına bozmaz.

## Denetim yazma

Yeni bir denetim, uygun test paketinde bir `_check_…` fonksiyonu ve o paketin `_checks()` fonksiyonuna eklenen bir
satırdır. Yeni bir test paketi, `check_suite.gd` sınıfını genişleten bir `tests/<topic>_checks.gd` dosyası ve
`SUITES` içine eklenen bir satırdır. `check_suite.gd` ortak yardımcıları içerir:

| Yardımcı | Yaptığı |
|---|---|
| `_teleport(position)` | Oyuncuyu durmuş hâlde bir noktaya koyar ve birkaç tik bekler |
| `_run_until_arrived(target, max_time)` | Bir koşu komutu verir ve varışa kadar süreyi, hızları, yürünen mesafeyi ve takılı kalınan tikleri kaydeder |
| `_check_route(title, from, to, max_time)` | Bir rota: zamanında ve takılmadan varıldı, ulaşılabilir bir nokta için tam o noktaya ve doğru katta |
| `_ticks(count)`, `_frames(count)`, `_wait_until(condition, max_ticks)` | Bekleme |
| `_send_key()`, `_send_button()`, `_send_motion()` | Gerçek girdi olayları |
| `_expect(condition, what)` | Geçen veya başarısız olan bir denetimi sayar ve yazdırır |
| `_median()`, `_min()`, `_max()`, `_first_time_at_most()` | Kaydedilen değerler üzerinde istatistikler |

`Settings` otomatik yüklemesine erişen sınıfları (ayarlar penceresinin öğeleri) test betiklerinde tür olarak
belirtmeyin. Test betikleri otomatik yükleme adları var olmadan önce derlenir; bu yüzden böyle bir sınıf derlenemez ve
o çalıştırma için tüm oyunu bozar. Ayarlar düğümünü `_tree.root.get_node(^"Settings")` ile alın ve ördek tiplemesi
(duck typing) kullanın.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
