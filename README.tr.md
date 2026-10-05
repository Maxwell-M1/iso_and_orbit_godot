<!-- translation of README.md @ 84a666a02ac2 -->
# Iso & Orbit - Kamera ve Karakter Kontrolcüsü Şablonu

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Sürüm 1.2.0 · Godot 4.7 (4.7.2 üzerinde test edildi) · GDScript · MIT

İzometrik ve yukarıdan bakışlı RPG'ler için tıklayarak hareket eden bir karakter kontrolcüsü ve bir yörünge kamerası.
Zemine tıklayın, kahraman engellerin etrafından dolanarak oraya koşar; tuşu basılı tutun, kahraman imleci izler.
Kamera karakterin etrafında döner, yakınlaşıp uzaklaşır ve duvarlara girmez.

**Projeye yeni mi başladınız?** [Demoyu çalıştırın](docs/tr/getting-started.md),
[hazır kahramanı aktarın](docs/tr/integration.md#demonun-kahramanını-projenize-aktarma), ardından
[hareket ve kamera yapılandırması seçin](docs/tr/configurations.md).

![Tıklayarak hareket, basılı tutarak yönlendirme, kamerayı döndürme ve yakınlaştırma, yer keşfi](docs/images/demo.gif)

Üçüncü taraf varlık yok: karakterler bir betikle ilkel şekillerden oluşturulmuştur, yüzey desenleri
gölgelendiricilerle üretilip dikişsiz dokulara pişirilmiştir, sesler sentezlenmiştir.
Sağlanan görüntü, 45° görüş açılı perspektif kamera kullanır. Yeniden kullanılabilir parçalar sıradan GDScript
bileşenleridir; etkinleştirilecek editör eklentisi yoktur.

## Başlarken

1. Godot 4.7.2'yi kurun: standart veya .NET sürümü. Jolt Physics motora yerleşiktir, ayrıca kurulacak bir şey yok.
   İşleyici: Forward+.
2. Depoyu klonlayın, Proje Yöneticisi'nde (Project Manager) `project.godot` dosyasını içe aktarın ve projeyi açın.
   `.godot/` depoda bulunmadığından ilk içe aktarma biraz zaman alır.
3. Demoyu çalıştırmak için F5'e basın (`res://gdscript/main.tscn`).

Kontroller sol üst köşede listelenir. Gizlemek için Ayarlar (F10) → Arayüz sekmesini açın ve **Kontrol ipuçları ve
hız** seçeneğini kapatın. Arayüz dili de aynı sekmede seçilir.

## Kontroller

| Girdi | Eylem |
|---|---|
| Zemine sol tık | O noktaya koşar |
| Sol tuşu basılı tutmak | İmlecin peşinden koşar |
| Önce sol, sonra sağ tuşu basılı tutmak | Koşarken etrafa bakar; kahraman yönünü korur |
| Önce sağ, sonra sol tuşu basılı tutmak | Kameranın baktığı yöne koşar; A / D çapraz yönlendirir |
| Sağ tuş + fare | Kamerayı döndürür |
| Sağ tuş + WASD | Kameraya göre hareket eder |
| Fare tekerleği | Yakınlaştırma: daha alçak ve yakın ya da daha yüksek ve uzak |
| Shift | Basılıyken depar (ya da ayarlarda aç/kapa) |
| Boşluk | Zıplar |
| E | Işınlanma platformunda götürdüğü yere geçer |
| F10 | Ayarları açar (oyunu duraklatır); Esc veya F10 kapatır |

Tüm modlar ve ayarları: [Kontroller](docs/tr/controls.md).

## Özellikler

**Hareket**

- Tıklayın, kahraman navigasyon örgüsü üzerinden noktaya koşar; bir işaretçi hedefi gösterir.
- Sol tuşu basılı tutarak imlecin peşinden koşun: varsayılan olarak doğrudan imlece, engeller boyunca kayarak; isteğe
  bağlı olarak imlecin altındaki noktaya bir navigasyon yolu boyunca.
- Tıklama ile basılı tutma 0,2 sn sonra ayırt edilir; böylece tuşu basılı tutmak kahramanı hiçbir zaman bastığınız
  noktaya dolambaçlı bir yoldan göndermez.
- Önce sağ, sonra sol tuş (ya da ikisi birlikte): kameranın baktığı yöne koşar. Önce sol, sonra sağ tuş: koşarken
  etrafa bakar ve kahraman rotasını korur. Sağ tuş ve WASD: kameraya göre hareket eder; yüz önde kalır veya gidiş
  yönüne döner.
- Sabit hızlanma ve frenleme, hedefi aşmadan tam hedefte durma, sınırlı dönüş hızı ve dururken anında dönüş.
- Dayanıklılıkla depar. Kenardan ayrıldıktan hemen sonra zıplama (coyote time) ve girdi tamponlaması;
  zıplama yüksekliği her fizik tik hızında aynıdır. Düşüşün kendi yerçekimi ve hız sınırı olabilir (`FallSettings`).
- Kenar koruması: bir uçurumun kenarında kahraman durur ya da duvar boyunca olduğu gibi kenar boyunca kayar.
- 0,3 m'ye kadar basamaklar yerden kesilmeden çıkılır ve inilir; 45°'ye kadar eğimlerde yukarı yürünür.
- İsteğe bağlı süzülme modu: kahraman yerden yüksekte durur, basamakların üzerinde süzülür, koşarken sallanıp
  eğilir; ayak sesi çıkarmaz ve zıplamadan yavaşça iner.

**Kamera**

- Sağ tuşla döndürme, tekerlekle yakınlaştırma. Mesafe ve eğim birlikte değişir: kamera ne kadar yakınsa açısı o kadar
  alçaktır, böylece ileride ne olduğunu görürsünüz.
- İsteğe bağlı olarak koşan kahramanın arkasına döner, eğimini ve yüksekliğini belirlenen değerlere getirir.
  Her kare hızında benzer biçimde yumuşakça başlar ve durur; kameraya doğru koşu, yön değişiminden sonra bile
  kamerayı çevresinde döndürmez.
- Kamera dönerken imleç zeminde aynı noktanın üstünde kalır; böylece basılı tuş kahramanı daireler çizdirmek yerine
  rotasında tutar.
- Kamera kolu: kamera arkasındaki duvarda, dağda veya çatıda durur ve isteğe bağlı olarak bir engel kahramanı
  gizlediğinde yaklaşır. Çok yakında kahraman yarı saydam olur.
- Engellerin arkasında kahraman konturlu tek bir siluet olarak görünür; elindeki ekipman bunun üstüne çizilir.

**Seviyeler**

- Kahraman ve arayüz yerinde kalırken seviyeler yükleme ekranının ardında değişir: sonraki seviye arka planda
  yüklenir, eskisi kaldırılır; kahraman, kamera arkasında olacak biçimde bir doğuş noktasına varır.
- Ekran, oyunun bulanık ve yavaşça yaklaşan son karesini, yer adını, ilerleme çubuğunu ve kontrol ipuçlarını gösterir.
- Portallar önce sorar (demo platformları "E ile ... ışınlan" teklif eder) veya kapı gibi hemen geçirir.
- Oyuncunun kontrol ettiği kahraman tek hazır sahnedir (`PlayableHero`): karakter, girdi, kamera, tıklama işareti
  ve onu istediğiniz yere koyan çağrılar.

**Ayrıca**

- Kontroller, karakter, kamera, görüntü, arayüz ve ses sekmelerine sahip, `user://settings.cfg` dosyasına kaydedilen
  bir ayarlar penceresi (F10). Arayüz İngilizce, İspanyolca, Japonca, Brezilya Portekizcesi, Rusça, Türkçe ve
  Basitleştirilmiş Çince dillerindedir ve anında değiştirilebilir.
- Karakter animasyonlar, efektler ve arayüz için ne yaptığını bildirir: durum (duruyor, koşuyor, depar atıyor, zıplıyor,
  düşüyor) ve her değişikliği için bir sinyal, hangi ayakla atıldığıyla birlikte adımlar, kalkışlar ve inişler, karışım
  değeri olarak hız, modelin eksenlerinde hareket ve ivme, dönüş ve yürüyüş döngüsü. Sesler sinyallere bağlıdır;
  Ayarlar → Arayüz bölümündeki panel, hepsini son olaylarla birlikte canlı olarak gösterir.
- İki demo seviyesi: harabeler, kamp, çiftlik, çalı labirenti, rampalı ve merdivenli platform ve sarmal patikalı
  dağ içeren 80 × 80 m'lik çitli açıklık; ışınlanma platformuyla varılan göldeki küçük ada. Beş keşfedilecek yer:
  açıklıkta beş NPC'nin beklediği dört yer, adada bir yer. On kahraman görünümü seçilebilir.
- Hareket, girdi, zıplama, depar ve sesler, karakterin durumu, basamaklar ve eğimler, kamera ve kolu, kahraman
  görünümleri, ayarlar penceresi ve çeviriler, seviyeler ve ışınlanma için penceresiz testler.

**Dahil olmayanlar:** oyun kumandası desteği, oyun içi tuş yeniden atama menüsü ve iskelet animasyonları. Girdi
eylemleri Project Settings içinde ayarlanabilir; arayüz geçerli atamaları okur. Modeller durağan ilkel şekillerdir.

## Nasıl bir araya geliyor

```
fare, WASD ───► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (yol veya           (hızlanma, frenleme,
                                                           yön)                dönüş: düz matematik)
                                                               │ hız
                                                               ▼
Shift, Boşluk ─► CharacterActionInput ──────────────────► GroundCharacter
                                                          (CharacterBody3D: yerçekimi, zıplama, depar,
                                                           move_and_slide, modeli döndürme)

fare ──► OrbitCameraRig ──► CameraArm ──► Camera3D
```

- **Gövdeyi yalnızca `GroundCharacter` hareket ettirir.** Hareket bileşenleri bir hız döndürür ve hiçbir zaman
  `move_and_slide()` çağırmaz; böylece yerçekimi, zıplamalar ve ileride eklenecek geri itmeler tek bir yerde birleşir.
- **`GroundMotion` düğümsüz matematiktir**, tek başına test etmesi kolaydır.
- **Karakter fare hakkında hiçbir şey bilmez.** Girdi düğümleri `player.tscn` içinde değil, oynanabilir kahraman
  sahnesi `playable_hero.tscn` içindedir.
  Bir NPC için `player.tscn` sahnesini yalnızca oyuncuya özgü `Silhouette` ve `Appearance` düğümleri olmadan
  örnekleyin ve yapay zekânızdan `NavigationMover.move_to()` çağırın.
- **Kahraman bir seviyenin parçası değildir.** `main.tscn` içinde seviye sunucusunun kardeşidir; seviyeler
  çevresinde değişir.
- **Bileşenler ayarlar hakkında hiçbir şey bilmez.** Kendi dışa aktarılmış özelliklerini okurlar. `Settings` otomatik
  yüklemesiyle yalnızca demonun `settings_applier.gd` dosyası ve ayarlar penceresi konuşur; böylece bir bileşen bunlar
  olmadan başka bir projeye taşınabilir.

Ayrıntılar: [Mimari](docs/tr/architecture.md).

## Kendi projenizde kullanma

Bileşenler `addons/iso_orbit/` içinde, her parça için bir klasör olarak bulunur; ihtiyacınız olanları projenizin aynı
klasörüne kopyalayın:

| Eklenti | Ne sağlar |
|---|---|
| `orbit_camera` | Yörünge kamerası ve kolu; herhangi bir `Node3D` hedefiyle çalışır |
| `click_to_move` | Navigasyon örgüsü üzerinde tıklayarak ve basılı tutarak hareket, yönlendirme, tıklama işaretçisi |
| `ground_character` | Hazır gövde: yerçekimi, zıplama, düşüş ayarları, dayanıklılıkla depar, kenar koruması, adım sinyalleri, sesler, el sallanması, süzülme, değiştirilebilir modeller (`click_to_move` gerektirir) |
| `occluded_silhouette` | Karakterin engellerin arkasındaki silueti |
| `points_of_interest` | Keşfedilecek yerler ve onlarla ilgili mesaj |
| `ui_screens` | Oyunu duraklatan bir pencere yığını ve bir FPS sayacı |
| `levels` | Yükleme ekranının ardında değişen seviyeler, portallar ve doğuş noktaları |

En kısa çalışan yol için hazır `playable_hero.tscn` sahnesini ve bağımlılıklarını
[aktarma kılavuzuyla](docs/tr/integration.md#demonun-kahramanını-projenize-aktarma) kopyalayın. Kılavuz, küçük test
seviyesi, kesin çarpışma/navigasyon ayarları ve özelleştirmeden önceki denemeleri içerir. Kahraman, demonun ayarlar
penceresi veya seviye sistemi olmadan da çalışır.

Kendi kontrolcünüz veya yapay zekânız için `NavigationMover.move_to(point)` navigasyon yolunu izler,
`steer(direction)` doğrudan hareket eder. Gövde dönen hızı her fizik tikinde bir kez uygular; hareket düğümü
gövdeyi kendi taşımaz. Küçük örnek: [Kendi gövdeniz](docs/tr/integration.md#kendi-gövdeniz).

[Yapılandırmalar](docs/tr/configurations.md), sağlanan varsayılan düzeni yol izleyen fare hareketi ve kamera
takibiyle keşif düzenleriyle karşılaştırır; parametrelerin neden değiştiğini açıklar.
[Proje yapılandırması](docs/tr/project-setup.md), gerekli eylemleri, katmanları ve isteğe bağlı demo
bağımlılıklarını listeler.

## Belgeler

- **Başlangıç:** [Başlarken](docs/tr/getting-started.md) · [Kontroller](docs/tr/controls.md) ·
  [Yapılandırmalar](docs/tr/configurations.md) · [Ayarlar](docs/tr/settings.md)
- **Kod:** [Mimari](docs/tr/architecture.md) · [Kendi projenizde kullanma](docs/tr/integration.md) ·
  [Proje yapılandırması](docs/tr/project-setup.md)
- **Sistemler:** [Hareket](docs/tr/systems/locomotion.md) · [Kamera](docs/tr/systems/camera.md) ·
  [Girdi](docs/tr/systems/input.md) · [Karakterler](docs/tr/systems/characters.md) ·
  [Ses](docs/tr/systems/audio.md) · [Arayüz](docs/tr/systems/ui.md) ·
  [Dünya ve navigasyon](docs/tr/systems/world-and-navigation.md) · [Seviyeler](docs/tr/systems/levels.md)
- **Bakım:** [Testler](docs/tr/testing.md) · [Bilinen sorunlar](docs/tr/known-issues.md) ·
  [Sözlük](docs/tr/glossary.md) · [Yol haritası](docs/tr/roadmap.md)

## Depo yapısı

| Klasör | İçerik |
|---|---|
| `addons/iso_orbit/` | Bileşenler; tek başına alınabilen her parça için bir klasör |
| `gdscript/` | Bunları birleştiren demo: oyun kabuğu `main.tscn`, oynanabilir kahraman, ayarlar sistemi ve penceresi |
| `shared/` | GDScript demosu ile gelecekteki C# örneğinin paylaşacağı demo içeriği: seviyeler, karakterler ve ekipman, dünya gölgelendiricileri ve dokuları, sesler, arayüz teması. Seviyelerin kullandığı iki küçük GDScript betiği de burada bulunur |
| `l10n/` | Arayüz çevirileri (gettext `.po`) |
| `tests/` | Headless testler |
| `docs/` | Belgeler |

## Testler

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Burada `godot`, Godot 4.7.2 çalıştırılabilir dosyanızdır; Windows'ta çıktıyı görmek ve çıkış kodunu almak için
`_console.exe` sürümünü kullanın. Yalnızca bazı test paketlerini çalıştırmak için adlarının parçalarını `--` sonrasına
ekleyin, örneğin `-- camera input`. Herhangi bir denetim başarısız olursa çıkış kodu 1 olur. Ayrıntılar:
[Testler](docs/tr/testing.md).

## Yol haritası

- `csharp/` içinde aynı bileşenleri ve `shared/world/` içindeki seviyelerin üstüne kurulu oyun kabuğunu kullanan
  C# örneği.
- Animasyonlar: `GroundCharacter.get_locomotion_blend()` ile `AnimationTree` içindeki durma, koşu ve depar
  karışımını sürmek.

## Lisans

MIT, bkz. [LICENSE](LICENSE). İstisna: `icon.svg`, Andrea Calabró'nun Godot logosu, CC BY 4.0.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
