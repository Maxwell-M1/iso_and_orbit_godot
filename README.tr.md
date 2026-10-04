<!-- translation of README.md @ 6853806db277 -->
# Iso & Orbit - Kamera ve Karakter Kontrolcüsü Şablonu

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Sürüm 1.1.0 · Godot 4.7 (4.7.2 üzerinde test edildi) · GDScript · MIT

İzometrik ve yukarıdan bakışlı RPG'ler için tıklayarak hareket eden bir karakter kontrolcüsü ve bir yörünge kamerası.
Zemine tıklayın, kahraman engellerin etrafından dolanarak oraya koşar; tuşu basılı tutun, kahraman imleci izler.
Kamera karakterin etrafında döner, yakınlaşıp uzaklaşır ve duvarlara girmez.

![Tıklayarak hareket, basılı tutarak yönlendirme, kamerayı döndürme ve yakınlaştırma, yer keşfi](docs/images/demo.gif)

Üçüncü taraf varlık yok: karakterler bir betikle ilkel şekillerden oluşturulmuştur, yüzey desenleri
gölgelendiricilerle üretilip dikişsiz dokulara pişirilmiştir, sesler sentezlenmiştir.

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
| Sol + sağ tuş | Kameranın baktığı yöne koşar; A / D çapraz yönlendirir |
| Sağ tuş + fare | Kamerayı döndürür |
| Sağ tuş + WASD | Kameraya göre hareket eder |
| Fare tekerleği | Yakınlaştırma: daha alçak ve yakın ya da daha yüksek ve uzak |
| Shift | Basılıyken depar (ya da ayarlarda aç/kapa) |
| Boşluk | Zıplar |
| F10 | Ayarları açar (oyunu duraklatır); Esc veya F10 kapatır |

Tüm modlar ve ayarları: [Kontroller](docs/tr/controls.md).

## Özellikler

**Hareket**

- Tıklayın, kahraman navigasyon örgüsü üzerinden noktaya koşar; bir işaretçi hedefi gösterir.
- Sol tuşu basılı tutarak imlecin peşinden koşun: varsayılan olarak doğrudan imlece, engeller boyunca kayarak; isteğe
  bağlı olarak imlecin altındaki noktaya bir navigasyon yolu boyunca.
- Tıklama ile basılı tutma 0,2 sn sonra ayırt edilir; böylece tuşu basılı tutmak kahramanı hiçbir zaman bastığınız
  noktaya dolambaçlı bir yoldan göndermez.
- İki tuş birlikte: kameranın baktığı yöne koşma. Sağ tuş ve WASD: kameraya göre hareket; yüz önde kalarak ya da
  gidilen yöne dönerek.
- Sabit hızlanma ve frenleme, hedefi aşmadan tam hedefte durma, sınırlı dönüş hızı ve dururken anında dönüş.
- Dayanıklılıkla depar. Çakal süresi (coyote time) ve girdi tamponlamalı zıplama; zıplama yüksekliği her fizik tik
  hızında aynıdır.
- Kenar koruması: bir uçurumun kenarında kahraman durur ya da duvar boyunca olduğu gibi kenar boyunca kayar.

**Kamera**

- Sağ tuşla döndürme, tekerlekle yakınlaştırma. Mesafe ve eğim birlikte değişir: kamera ne kadar yakınsa açısı o kadar
  alçaktır, böylece ileride ne olduğunu görürsünüz.
- İsteğe bağlı olarak koşan kahramanın arkasına döner ve eğimini yavaşça belirlenen açıya getirir.
- Kamera dönerken imleç zeminde aynı noktanın üstünde kalır; böylece basılı tuş kahramanı daireler çizdirmek yerine
  rotasında tutar.
- Kamera kolu: kamera arkasındaki duvarda, dağda veya çatıda durur ve isteğe bağlı olarak bir engel kahramanı
  gizlediğinde yaklaşır. Çok yakında kahraman yarı saydam olur.
- Engellerin arkasında kahraman konturlu tek bir siluet olarak görünür; elindeki ekipman bunun üstüne çizilir.

**Ayrıca**

- Kontroller, karakter, kamera, görüntü, arayüz ve ses sekmelerine sahip, `user://settings.cfg` dosyasına kaydedilen
  bir ayarlar penceresi (F10). Arayüz İngilizce, İspanyolca, Japonca, Brezilya Portekizcesi, Rusça, Türkçe ve
  Basitleştirilmiş Çince dillerindedir ve anında değiştirilebilir.
- Adımlar, zıplamalar, inişler ve depar için karakter sinyalleri ve bunlara bağlı sesler.
- Bir demo seviyesi: harabeler, bir kamp, bir çiftlik, bir çalı labirenti, bir rampa ve sarmal patikalı bir dağ
  içeren, çitle çevrili 80 × 80 m'lik bir açıklık. Beş NPC'nin beklediği dört keşfedilecek yer ve seçilebilecek on
  kahraman görünümü.
- Hareket, girdi, zıplama, depar ve sesler, kamera ve kolu, kahraman görünümleri, ayarlar penceresi ve çeviriler için
  headless (pencere açmadan çalışan) testler; ayrıca editörü açmadan tüm sahnelerdeki editör düğüm uyarılarını bulan
  bir betik.

**Dahil olmayanlar:** oyun kumandası desteği (yalnızca fare ve klavye) ve animasyonlar: modeller durağan ilkel
şekillerdir.

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
- **Karakter fare hakkında hiçbir şey bilmez.** Girdi düğümleri `player.tscn` içinde değil, `main.tscn` içindedir.
  Bir NPC için `player.tscn` sahnesini yalnızca oyuncuya özgü `Silhouette` ve `Appearance` düğümleri olmadan
  örnekleyin ve yapay zekânızdan `NavigationMover.move_to()` çağırın.
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
| `ground_character` | Hazır gövde: yerçekimi, zıplama, dayanıklılıkla depar, kenar koruması, adım sinyalleri, sesler, el sallanması, değiştirilebilir modeller (`click_to_move` gerektirir) |
| `occluded_silhouette` | Karakterin engellerin arkasındaki silueti |
| `points_of_interest` | Keşfedilecek yerler ve onlarla ilgili mesaj |
| `ui_screens` | Oyunu duraklatan bir pencere yığını ve bir FPS sayacı |

Hareket bir zincir hâlinde işler: girdi bir `NavigationMover` düğümüne komut verir, hareketlendirici yalnızca bir hız
hesaplar ve ait olduğu gövde bu hızı her fizik tikinde uygular. `GroundCharacter` hazır gövdedir; en basit gövde
şöyle görünür:

```gdscript
extends CharacterBody3D

@onready var mover: NavigationMover = $NavigationMover


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
```

`mover.move_to(point)` veya `mover.steer(direction)` metodunu herhangi bir yerden çağırın: kendi girdinizden, yapay
zekâdan veya ağ kodundan. [Kendi projenizde kullanma](docs/tr/integration.md) her eklentinin neye ihtiyaç duyduğunu
anlatır; [Proje yapılandırması](docs/tr/project-setup.md) ise bileşenlerin `project.godot` dosyasından beklediği
fizik katmanlarını, girdi eylemlerini ve grupları listeler.

## Belgeler

- **Başlangıç:** [Başlarken](docs/tr/getting-started.md) · [Kontroller](docs/tr/controls.md) ·
  [Ayarlar](docs/tr/settings.md)
- **Kod:** [Mimari](docs/tr/architecture.md) · [Kendi projenizde kullanma](docs/tr/integration.md) ·
  [Proje yapılandırması](docs/tr/project-setup.md)
- **Sistemler:** [Hareket](docs/tr/systems/locomotion.md) · [Kamera](docs/tr/systems/camera.md) ·
  [Girdi](docs/tr/systems/input.md) · [Karakterler](docs/tr/systems/characters.md) ·
  [Ses](docs/tr/systems/audio.md) · [Arayüz](docs/tr/systems/ui.md) ·
  [Dünya ve navigasyon](docs/tr/systems/world-and-navigation.md)
- **Bakım:** [Testler](docs/tr/testing.md) · [Bilinen sorunlar](docs/tr/known-issues.md) ·
  [Sözlük](docs/tr/glossary.md) · [Yol haritası](docs/tr/roadmap.md)

## Depo yapısı

| Klasör | İçerik |
|---|---|
| `addons/iso_orbit/` | Bileşenler; tek başına alınabilen her parça için bir klasör |
| `gdscript/` | Bunları bir araya getiren demo: `main.tscn`, kahraman, ayarlar sistemi ve penceresi |
| `shared/` | GDScript demosu ile gelecekteki bir C# demosunun ortak kullanması amaçlanan demo içeriği: seviye, karakterler ve ekipman, dünya gölgelendiricileri ve dokuları, sesler, arayüz teması. Seviyenin kullandığı iki küçük GDScript betiği de burada bulunur |
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

- `csharp/` içinde, aynı bileşenleri ve `shared/world/world.tscn` üzerine kurulu bir ana sahneyi kullanan bir C#
  örneği.
- Animasyonlar: bir `AnimationTree` içindeki bekleme/koşu karışımını `NavigationMover.get_speed()` ile yönetmek.

## Lisans

MIT, bkz. [LICENSE](LICENSE). İstisna: `icon.svg`, Andrea Calabró'nun Godot logosu, CC BY 4.0.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
