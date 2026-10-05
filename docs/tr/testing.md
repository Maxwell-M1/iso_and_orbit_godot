<!-- translation of docs/en/testing.md @ fd518f56694a -->
# Testler

[← Belge dizini](index.md)

> Bu, [İngilizce orijinalin](../en/testing.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Testler ana sahneyi gerçek girdi olayları ve gerçek fizikle headless (pencere açmadan) çalıştırır ve ölçümleri
beklentilerle karşılaştırır.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Burada `godot`, Godot 4.7.2 çalıştırılabilir dosyanızdır. Windows'ta `_console.exe` sürümünü kullanın: normal sürüm
terminalden ayrılır, bu yüzden çıktı görmezsiniz ve çıkış kodu alamazsınız. Yeni bir klonda önce projeyi bir kez içe
aktarın: editörde ya da `godot --headless --path . --import` ile.

PATH'e eklemek yerine çalıştırılabilir dosyanın tam yolunu kullanabilirsiniz. PowerShell'de tırnaklı yolun başına
`&` koyun:

```powershell
& 'C:\path\to\Godot_console.exe' --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Örnek yolu kurulu Godot 4.7.2 konsol dosyanızla değiştirin; komutu proje kökünde çalıştırın.

Yalnızca bazı test paketleri, örneğin kamera üzerinde çalışırken: adlarının parçalarını `--` sonrasına yazın.

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd -- camera input
```

Herhangi bir denetim başarısız olursa çıkış kodu 1 olur. Sonunda çalıştırıcı, her test paketinde kaç denetimin
geçtiğini ve kaçının başarısız olduğunu yazdırır.

## Test paketleri

Paketler `tests/run_checks.gd` içindeki sırada, tek ana sahneyi paylaşarak çalışır. Değişikliğinizle ilgili
olanları seçin; sistemler arası değişimi bütünleştirmeden önce tam çalıştırmayı yapın.

| Test paketi | Başlıca denemeler |
|---|---|
| `movement_checks.gd` | Hızlanma, frenleme, yeni hedef, dönüş, erişilir ve erişilmez hedefler, engellerin çevresindeki rotalar, rampalar ve kenarlar |
| `world_checks.gd` | Demo arazisinde navigasyon, keşif alanları, statik NPC çarpışmaları ve sergilenen kahraman modelleri |
| `hero_look_checks.gd` | On kahraman modelinin değiştirilmesi, ekipman yerleşimi, siluetler ve el hareketi |
| `character_actions_checks.gd` | Depar ve yorgunluk, basılı/aç-kapa girdi, tuş ataması ve değiştiricinin bırakılması, zıplama tamponu/kenar sonrası süre, düşüş geçersiz kılmaları, sinyaller ve sesler |
| `character_state_checks.gd` | Kurulum uyarıları, durum ve animasyon verisi, basamak/eğimler, ışınlama, süzülme, enterpolasyon, duran oyun zamanı ve izleme paneli |
| `input_checks.gd` | Tıklama ve basılı tutma, iki tuşun sırası ve iki tutma modu, klavye modları, imleç yakalama, iptal ve eksik eylemler |
| `camera_checks.gd` | Farklı kare/tik hızlarında kamera dönüşü, yakınlaştırma ve takip; keskin dönüş, kameraya doğru koşu, elle dönüş sonrası bekleme, eğim/yakınlaştırma/yükseklik hizalama ve ışınlama |
| `camera_arm_checks.gd` | Engelden kaçınma, çarpışma katmanları, yok sayılan gruplar, isteğe bağlı örtülme yaklaşması ve yakında saydamlaşma |
| `settings_window_checks.gd` | Duraklama ve odak, her ayar sekmesi, özellik eşleme, bağımlı kontroller, arayüz ölçeği, sıfırlama ve kapatma |
| `localization_checks.gd` | Çeviri kapsamı, korunan eylem simgeleri, dil değişimi, yeniden atanmış 12 eylemin adı, açık araç ipucu/pencere/yükleme ipuçları ve çeviri kalıtımı |
| `level_checks.gd` | Doğuş noktaları, yolculuk teklifleri, yükleme ilerlemesi ve duraklama, sahne değişimi, korunan kahraman durumu ve hatadan kurtarma |

Belgelenen girdi/kamera yapılandırmaları için `movement`, `character_actions`, `input`, `camera` ve
`settings_window` ile başlayın. `camera` filtresi iki kamera paketini de seçer. Kahramanı başka projeye taşırken
[aktarma denetim listesini](integration.md#demonun-kahramanını-projenize-aktarma) de izleyin: bu deponun testlerini
geçmek, gereken her dosya ve proje ayarının kopyalandığını kanıtlamaz.

## Testlerin davranışı

- Varsayılan ayarlarla çalışırlar ve hiçbir şey kaydetmezler: oyuncunun ayarları çalıştırma süresince varsayılanlara
  sıfırlanır ve hiçbir zaman üzerine yazılmaz.
- Her denetim değiştirdiği şeyi geri yükler. Test paketleri tek bir ana sahne üzerinde art arda çalışır, tek başına
  çalıştırılan bir paket ise yeni bir sahne alır; denetim iki durumda da geçmelidir. Her denetimden sonra
  `Engine.time_scale` 1'e döner; zaman yavaşken veya durmuşken çöken denetim sonrakini etkilemez.
- Her motor veya betik hatası **ve uyarısı** çalıştırmayı başarısız kılar: `OS.add_logger()` ile eklenen `Logger`
  sayar, çalıştırıcı "engine and script errors" sayısını başarısızlıklara ekler. Çöken denetim yarıda kesilir,
  diğerleri sürer; sayaç olmasa çökme fark edilmezdi. Yalnız denetimin bilerek oluşturup önceden bildirdiği
  hata sayılmaz (çalıştırıcının `expect_error()` yöntemi, ardından geldiğini görmek için
  `take_expected_errors()`); örneğin seviye olamayan sahne denemesinde. Yoğun CPU yükünde Jolt uyarabilir;
  bkz. [Bilinen sorunlar](known-issues.md#testler).
- Takılan çalıştırma 1200 s oyun süresinden sonra başarısız olur. Seviye arka planda yüklenirken penceresiz
  kareler ekrandakinden çok hızlı ilerleyebilir; seviye denemeleri değişimi gerçek zamanla bekler.
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
| `_error_count()` | Beklenenler dışındaki motor ve betik hatalarının sayısı; denetim işlem öncesi ve sonrası sayıları karşılaştırır |
| `_tree.call(&"expect_error", "part of the message")`, `_tree.call(&"take_expected_errors")` | `check_suite.gd` değil çalıştırıcı yöntemleri: ilki bilerek oluşturulan hatayı önceden bildirir, ikincisi gelmeyen bildirilen hataları döndürüp beklentiyi bitirir |
| `_find_non_finite(found)` | Ana sahnede dönüşümü sonlu olmayan (INF veya NaN) 3D düğümleri toplar |
| `_same_values(a, b)` | İki dizinin aynı değerleri tutup tutmadığı; `==` aksine iki NaN'ı eşit saymaz |
| `_median()`, `_min()`, `_max()`, `_first_time_at_most()` | Kaydedilen değerler üzerinde istatistikler |

`Settings` otomatik yüklemesine erişen sınıfları (ayarlar penceresinin öğeleri) test betiklerinde tür olarak
belirtmeyin. Test betikleri otomatik yükleme adları var olmadan önce derlenir; bu yüzden böyle bir sınıf derlenemez ve
o çalıştırma için tüm oyunu bozar. Ayarlar düğümünü `_tree.root.get_node(^"Settings")` ile alın ve ördek tiplemesi
(duck typing) kullanın.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
