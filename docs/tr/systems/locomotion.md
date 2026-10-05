<!-- translation of docs/en/systems/locomotion.md @ 78c912e8971a -->
# Hareket

[← Belge dizini](../index.md)

> Bu, [İngilizce orijinalin](../../en/systems/locomotion.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Karakterin koşması, durması, dönmesi, deparı, zıplaması, basamak çıkması ve düşüş kenarlarından uzak durması.
Hazır kahramanla gerekli dosyaları başka projede kullanmak için önce
[Aktarma kılavuzuna](../integration.md#demonun-kahramanını-projenize-aktarma) bakın. Hazır kontrol seçenekleri için
[Yapılandırmalar](../configurations.md) sayfasını açın. İş dört sınıfa bölünür:

| Sınıf | Tür | Görev |
|---|---|---|
| `LocomotionSettings` | Resource | Hız, hızlanma, frenleme, dönüş |
| `GroundMotion` | RefCounted | Matematik: istenen yön ve kalan mesafe → yatay hız |
| `NavigationMover` | Node, gövdenin alt düğümü | Yollar ve komutlar; bir hız döndürür, gövdeyi asla hareket ettirmez |
| `GroundCharacter` | CharacterBody3D | Yerçekimi, zıplama, depar, `move_and_slide()`, modeli döndürme |

Gövdeye iki yardımcı takılır: `Stamina` (depar rezervi) ve `LedgeGuard` (yüksekten yürüyerek düşmeyi önler).
`FallSettings` kaynağı nasıl düşeceğini belirtir. `CharacterMonitor`, gövdenin bildirdiklerini metin olarak
gösterir. `CharacterHover` modeli yerden yükseltir; bkz.
[Karakterler](characters.md#characterhover-yerden-yüksekte-süzülme).

## Koşunun hissi

- **Sabit hızlanma ve frenleme.** Hız, `acceleration_time` ve `stop_time` değerlerinden çıkan sabit bir oranla
  değişir.
- **Tam duruş.** Hedefin yakınında hız `√(2 · braking · distance left)` ile sınırlanır: karakter, noktada hâlâ
  durabileceği yerde tam olarak frenlemeye başlar ve noktayı asla aşmaz.
- **Yeni hedefte sıfırlama yok.** Frenlerken yapılan yeni bir tıklama mevcut hızı korur; karakter oradan yeniden
  hızlanır.
- **Sınırlı dönüş hızı.** Koşarken yön `turn_speed` hızında döner. Yön henüz yetişmemişken `turn_slowdown` hızın bir
  kısmını düşürür; böylece keskin bir dönüş geniş bir savrulma değil, dar bir yay olur.
- **Dururken anında dönüş.** `pivot_speed` altında karakter hemen döner; böylece herhangi bir yöne kalkışta yay ve
  gecikme olmaz.
- **Gerektiğinde sert frenleme.** Durma noktası koşan bir karakterin hemen önüne konursa karakter normalden
  `max_braking_multiplier` katına kadar daha sert frenleyebilir.

## LocomotionSettings

Buradaki değerler hem `LocomotionSettings` betiğinin hem sağlanan `gdscript/player/player_locomotion.tres`
kaynağının varsayılanlarıdır. Ayrı kaynak, demonun ayarlarının bu kahramanın depar ve geri yürüme hızını diğer
karakterleri değiştirmeden ayarlamasını sağlar.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `max_speed` | 5.5 m/s | Koşu hızı |
| `acceleration_time` | 0.18 s | Duruştan `max_speed` değerine ulaşma süresi |
| `stop_time` | 0.22 s | `max_speed` değerinden duruşa; fren mesafesi `max_speed × stop_time / 2` (yaklaşık 0.61 m) |
| `turn_speed` | 720 °/s | Koşu yönünün dönüş hızı. Kameranın `sharp_turn_speed` eşiğini bunun yarısında veya altında tutun; bkz. [Kamera](camera.md#takip-modu) |
| `turn_slowdown` | 0.75 | Yön yetişirken kaybolan hız: 0 korur (geniş yay), 1 en az 90° dönüşte sıfıra kadar frenler |
| `pivot_speed` | 1 m/s | Bunun altında karakter anında döner |
| `max_braking_multiplier` | 3 | Hemen önündeki nokta için normalden ne kadar sert frenleyebileceği |
| `sprint_speed_multiplier` | 1.5 | Deparda temel hızın çarpanı (varsayılanlarla 8.25 m/s); ivme ve frenleme aynı kalır |
| `backward_speed_multiplier` | 0.7 | Hareketin tersine bakarken geriye yürüyüşte kalan hız payı |

Depar yalnız hız sınırını yükselttiğinden tam deparın durması daha uzun sürer ve daha fazla yol alır: varsayılan
frenlemeyle 8.25 m/s hızda yaklaşık 1.36 m, 5.5 m/s hızda yaklaşık 0.61 m. Çok yakın tıklanan noktada
`max_braking_multiplier` daha çabuk durdurabilir.

Demo `SettingsApplier`, başlangıçta ve oyuncu ayarı değiştirdiğinde `sprint_speed_multiplier` ile
`backward_speed_multiplier` değerlerini ayarlar; kaydedilmiş ayarlar yukarıdaki değerleri geçersiz kılabilir.
Eklentinin kendi ayar sistemi yoktur. Çalışan demoda ayar için Scene paneli → Remote →
`Hero/Character/NavigationMover` → `settings` yolunu kullanın. Kod kaynak alanlarını her tikte okur; ancak Remote
değişiklikleri kaydedilmez: sonucu `.tres` dosyasına geçirin. Çalışma zamanı değişikliklerinin başkalarını
etkilememesi için her karaktere ayrı kaynak kullanın. Kaynağı hareket düğümü sahne ağacına girmeden atayın veya
editörde **Make Unique** kullanın: `_ready()` sonrasında `GroundMotion` eski kaynağı tutar, dolayısıyla o anda
`mover.settings` kaynağını değiştirmek hareket ayarlarını değiştirmez. Çalışırken mevcut kaynağın alanlarını
düzenleyin.

Tek bir kaynak birkaç karakter tarafından paylaşılabilir, örneğin aynı türden tüm NPC'ler.

## NavigationMover

Gövdenin bir alt düğümü (herhangi bir `Node3D`, genellikle bir `CharacterBody3D`). İki mod:

- `move_to(point)`: navigasyon yolu boyunca engelleri dolanarak noktaya gider ve yolun sonunda tam durur. Yol,
  gövdenin dünyası için `NavigationServer3D` üzerinden gelir. Sonuç boşsa (navigasyon örgüsü olmayan dünya dahil)
  karakter istenen noktaya dümdüz koşar.
- `steer(direction, facing = Vector3.ZERO)`: `stop()`, `halt()` veya `move_to()` gelene kadar yolsuz olarak bir
  yöne. Engeller, gövdenin onlar boyunca kaymasıyla aşılır. `facing` verilirse karakter hareket ederken o yöne bakar:
  yana adım ve geri geri yürüme. Bakış yönü `stop()` sonrasında kalır; `move_to()`, bakış yönü verilmemiş
  `steer()`, `halt()` ve `face()` onu temizler.

Gövde her fizik tikinde `move_and_slide()` öncesi bir kez `compute_velocity(delta)` çağırır. `stop()` yumuşakça
frenler, `halt()` hemen durur (ışınlama için). `face(direction)` koşu başlatmadan duran karakteri, örneğin doğuş
noktasında döndürür: hareket düğümünün yönü ve bakışı anında değişir; `GroundCharacter` modeli
`visual_turn_speed` hızında döndürür. Modeli de anında yalnız `GroundCharacter.teleport(position, facing)`
döndürür. Sürmekte olan koşu yeniden gittiği yöne bakar.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `settings` | — | `LocomotionSettings`; boşsa hareket düğümü `_ready()` içinde betik varsayılanlarıyla oluşturur |
| `use_navigation` | açık | Yol ara; kapalıysa veya dünyada navigasyon yoksa: noktaya düz koş |
| `navigation_layers` | 1 | Yolun kullanabileceği navigasyon katmanları |
| `waypoint_radius` | 0,4 m | Bundan daha yakında bir yol noktası geçilmiş sayılır; daha büyük değer köşeleri daha erken keser |
| `arrive_distance` | 0,005 m | Sona bundan daha yakınken karakter hemen durur. Frenlemenin kendisi onu noktaya getirir, bu yüzden eşik çok küçüktür |
| `retarget_tolerance` | 0,1 m | Mevcut noktaya bundan daha yakın yeni bir nokta yolu yeniden oluşturmaz. Basılı tuş her tikte bir nokta gönderir |
| `max_path_deviation` | 2 m | Yoldan bundan daha uzağa itilen karakter yeni bir yol alır |
| `sprinting` | kapalı | Hız sınırını `sprint_speed_multiplier` ile yükseltir. Sahibi ne zaman olacağına karar verir. `GroundCharacter` her tikte ayarladığından onunla `sprint_requested` kullanın |

Sinyaller: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled`.

`arrived`, karakterin yol sonuna ulaştığını bildirir. Navigasyon yolu istenen hedef yerine en yakın erişilebilir
noktada bitebilir; oyununuz tam hedefi gerektiriyorsa konumları karşılaştırın. Düz çizgiye dönüş, gövdenin
çarpışmada kayması dışında engelden kaçınmaz.

| Sorgu | Döndürdüğü |
|---|---|
| `is_moving()` | Noktaya veya yöne komut verilmiş olmasıdır, gerçek hareket değil: başlangıçta dururken true, `stop()` sonrası frenlerken false olabilir |
| `is_steering()` | Noktaya değil `steer()` ile verilen yöne koşar |
| `has_destination()`, `get_destination()` | `move_to()` hedefi sürüyor mu (ulaşana veya iptal edilene dek); bu nokta |
| `get_speed()` | Koşu hızı, m/s |
| `get_heading()` | Koşunun yönü, yatay birim vektör; durunca son koşunun yönü |
| `get_facing()` | Karakterin bakacağı yön: koşu (`get_heading()`) veya `steer()` ile verilen yön |
| `get_body()` | Sürdüğü gövde, üst düğümü |
| `get_remaining_path()` | Navigasyon örgüsü yüksekliğindeki kalan yol noktaları; dümdüz koşuda boş |

**Yol noktaları yatay düzlemde karşılaştırılır.** Bir Recast navigasyon örgüsü zeminin yaklaşık iki hücre yüksekliği
(burada 0,05 m) üstünde durur. 3B mesafeleri karakterin ayaklarıyla karşılaştırmak o kadar sapma verirdi;
hareketlendiricinin `NavigationAgent3D` kullanmak yerine yolu kendisinin izlemesinin nedeni budur.

**Geri geri yürüme daha yavaştır.** `steer()` bir `facing` aldığında hız, hareketin bakış yönüne ne kadar ters
olduğuna göre ölçeklenir: tam geriye `backward_speed_multiplier` değerinin tamamı, çapraz geriye bir kısmı uygulanır
(yana adımda S + D: %21 daha yavaş), yana hiç uygulanmaz. Bu yüzden yavaşlama yalnızca tuşların yana adım modunda
vardır, bkz. [Girdi](input.md).

## GroundCharacter

Gövdenin hareket ettiği tek yer. Her fizik tikinde depar durumunu günceller, yatay hızı hareketlendiriciden alır,
zıplamayı ve yerçekimini işler, hızı `LedgeGuard` ile düzelttirir, öncesinde bir basamak çıkışı ve sonrasında bir
basamak inişiyle `move_and_slide()` çağırır, ardından tikin neyi değiştirdiğini bildirir: zemin teması, çıkılan
basamak, adımlar, modelin `mover.get_facing()` yönüne dönüşü ve durum.

Denetçi (Inspector) özellikleri gruplar: önce parçalar ve dönüş, ardından Ground (zemin), Jump and fall (zıplama ve
düşüş), Sprint (depar) ve Steps (adımlar).

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `mover` | — | `NavigationMover`; zorunlu |
| `visual` | — | Gövdeye göre karakterin gittiği yöne çevrilen düğüm; önü −Z yönüdür |
| `visual_turn_speed` | 1080 °/sn | Modelin ne kadar hızlı döndüğü |
| `max_step_height` | 0,3 m | Karakterin zıplamadan çıktığı en yüksek basamak ve yerden kesilmeden indiği en derin basamak. 0 basamak çıkıp inmeyi kapatır |
| `ledge_guard` | — | İsteğe bağlı `LedgeGuard`; olmadan karakter her yükseklikten düşer |
| `can_jump` | açık | Zıplamaya izin verilir; kapalıyken `jump()` hiçbir şey yapmaz |
| `jump_height` | 1 m | Zıplamanın tepesinde ayakların yüksekliği |
| `coyote_time` | 0,1 sn | Bir kenardan yürüyerek çıktıktan sonra zıplama bu kadar süre daha çalışır |
| `jump_buffer_time` | 0,12 sn | İnişten bu kadar önce basılan zıplama inişte gerçekleşir |
| `gravity_scale` | 3 | Zıplarken ve `fall` başka değer vermiyorsa inerken yerçekimi çarpanı. Karakter insandan hızlı koştuğu için normal yerçekiminde süzülür gibi inerdi: 1.6 m düşüş 0.57 sn yerine 0.33 sn sürer |
| `fall` | — | Düşüş ivmesi ve en yüksek hızı için `FallSettings`; bkz. [Düşüş](#düşüş). Boşsa `gravity_scale` geçerlidir ve hız sınırı yoktur |
| `landing_min_speed` | 2.5 m/s | Daha yavaş düşüş (tümsek, rampa) yalnız `touched_floor` üretir, `landed` üretmez |
| `can_sprint` | açık | Depara izin verilir. Koşarken kapatılırsa fazla hız frenlenerek düşürülür |
| `stamina` | — | İsteğe bağlı `Stamina`; olmadan depar hiç yormaz |
| `sprint_tires` | açık | Depar dayanıklılık harcar |
| `sprint_duration` | 5 sn | Dolu bir rezervin ne kadar yettiği: saniyede `max_value / sprint_duration` harcar |
| `steps_enabled` | açık | Adımları sayar: `stepped` ve adım ritmi. Bacaksız karakterde kapatın. Yeniden açılınca ilk adım `first_step_distance` sonra gelir |
| `stride_length` | 1,5 m | Zeminde adımlar arasındaki mesafe |
| `first_step_distance` | 0,3 m | Duruştan ilk adıma kadar mesafe |

Eğim sınırı gövdenin kendi `floor_max_angle` özelliğidir (denetçide Floor → Max Angle, varsayılan olarak 45°). Daha dik
bir yüzey gövde için de, basamaklar için de, kenar koruması için de bir duvardır. Yukarı +Y'dir:
`up_direction`, `Vector3.UP` olarak kalmalıdır.

Gövde boyutu veya seviye basamakları değişirse bunları birlikte ayarlayın: `max_step_height` basamak yüksekliğinden
az, `LedgeGuard.max_drop` da `max_step_height` değerinden düşük olmasın. Navigasyon örgüsündeki
`agent_max_climb`, aşılmasını istediğiniz basamak yüksekliği olsun; ayar değişince örgüyü yeniden pişirin.
Örgü rota planlar; kapsül, zemin eğimi, tavan boşluğu ve çarpışma geometrisi o rotanın gerçekten izlenip
izlenemeyeceğine karar verir. İnişte `stair_taken` istiyorsanız `floor_snap_length`, `max_step_height` değerinden
kısa olsun. Demo 1.8 m boyunda, 0.35 m yarıçaplı kapsül, 0.3 m basamak, 0.5 m korunan düşüş ve 0.3 m çıkışlı,
0.025 m hücre yüksekliğinde navigasyon örgüsü kullanır; bkz.
[Dünya ve navigasyon](world-and-navigation.md#fizik-katmanları-ve-navigasyon).

Gövde sahnede dönük durabilir; editörde döndürülmüş NPC veya `PlayableHero` kökü gibi. Karakter yalnız `visual`
düğümünü gövdeye göre döndürür ve başlangıçta gövdenin −Z yönüne bakar; hareket düğümü ilk yönünü buradan alır.
Daha sonra `teleport(position, facing)` veya `NavigationMover.face()` bakış yönünü belirler.

Bileşen, `steps_enabled` değerine dokunmadan adımları geçici durdurabilir: `set_steps_suppressed(self, true)`;
yeniden başlatmak için `false` kullanır (`CharacterHover` süzülürken bunu yapar). Adımlar ancak
`steps_enabled` açık ve hiçbir bileşen durdurmamışken sayılır (`is_counting_steps()`); böylece oyun anahtarıyla
bileşenler birbirlerinin seçimini geri almaz. Karakter bileşeni hayatta tutmaz: serbest bırakılınca en geç sonraki
tikte adımlar sürer. Düşüş de aynı biçimde çalışır; bkz. [Düşüş](#düşüş).

Kurulum hataları karakter ağaca girince uyarı yazdırır; `get_setup_warnings()` aynı listeyi döndürür: hareket
düğümü veya kenar koruması gövdenin çocuğu değildir; `LedgeGuard.max_drop`, `max_step_height` değerinden düşüktür
ve inilebilen basamakları engeller; zemin yapışma mesafesi basamak kadar uzundur ve `stair_taken` vermeden
kendiliğinden iner; `can_jump` açık ama `jump_height` veya `gravity_scale` 0'dır ve zıplama yerden kesilmez
(böyle deneme `jumped` olmadan etkisiz kalır); `fall.max_speed`, `landing_min_speed` altındadır ve düşüşten
iniş sinyali hiç gelmez; `up_direction` +Y değildir. `LedgeGuard` ve `CharacterHover` kendi kurulumlarını da böyle
denetler.

Depar istemek için `sprint_requested` ayarlayın, zıplamak için `jump()` çağırın. Oyuncu için ikisini de
`CharacterActionInput` yapar; yapay zekâ da aynısını yapabilir.

`teleport(position, facing)` karakteri anında başka yere, örneğin doğuş noktasına veya başka seviyeye koyar.
Hemen durdurur (`NavigationMover.halt()`), ardından hareketi izleyenler sıçrama görmez: hız, ivme ve dönüş hızı
sıfırlanır; fizik tikleri arasındaki yumuşatma yeni konumda başlar (süzülen model de oraya yerleşir); önceki
zıplama isteği unutulur. `facing` verilirse karakter ve modeli de hemen o yöne döner. Dayanıklılık korunur;
zeminde durma durumu önceki gibi kalır, bu nedenle ayakları zemine koyun. Sonunda `teleported` sinyali gelir:
kamera veya iz gibi takipçiler oraya birlikte sıçrasın. Denemelerde 5.5 m/s koşunun ortasındaki ışınlama,
karakteri aynı karede yeni yerde durdurur; sonrasında ivme veya dönüş kalmaz.

Işınlama oyuncu girdisini ve kamerayı değiştirmez. Oyuncu kahramanında `PlayableHero.teleport()` veya `place_at()`
kullanın (bkz. [Seviyeler](levels.md#oynanabilir-kahraman)): sürmekte olan basışı da unutur, istenirse kamerayı
döndürür ve yerine yerleştirir. Yalnız `GroundCharacter.teleport()` kullanırsanız önce
`PointClickMoveInput.cancel()` çağırın (basılı fare düğmesi sonraki tikte tekrar koşu gönderir) ve `teleported`
sinyalini `OrbitCameraRig.snap()` yöntemine bağlayın.

Zaman durunca (`Engine.time_scale` 0) fizik tikleri sıfır adımla sürer; karakterin konumu,
`get_move_velocity()` hızı, durumu ve adım ritmi korunur, ivme ve dönüş hızı 0 olur. Süzülen model ile sallanan el
yerinde kalır. Zaman ilerleyince koşu uyum içinde sürer. Denemelerde 5.5 m/s hızla koşan kahraman, yürürken veya
süzülürken, hatasız aynı yerde kalır ve sonra koşar. Bu sıradaki girdi karaktere yine ulaşır: depar tuşu koşunun
depar durumunu değiştirir (`sprint_changed`), zeminde basılan zıplama hemen gerçekleşir (`jumped`). Hiçbir şey
değişmesin istiyorsanız o süre boyunca kontrolleri kapatın (`PlayableHero.controls_enabled`).

### Karakterin bildirdikleri

Animasyonlar, efektler, sesler ve arayüz, karakterin ne yaptığını hızdan çıkarmak zorunda değildir. Anlık olaylar sinyal
olarak gelir; sürekli değişenler ise her karede veya her tikte sorgularla okunur.

| Sinyal | Ne zaman |
|---|---|
| `state_changed(state, previous)` | Durum değişti. Tikin sonunda, tikin diğer sinyallerinden sonra |
| `stepped(sprinting)` | Bir ayak yere değdi (hangisi olduğunu `get_step_foot()` söyler): zeminde kat edilen her `stride_length` mesafede, ilki duruştan `first_step_distance` sonra. Adımlar zamanı değil mesafeyi izler: koşarken saniyede yaklaşık 3,7, deparda 5,5; duvara dayanmış dururken veya havadayken hiç |
| `jumped` | Karakter zeminden itildi; aynı tikte ardından `left_floor` gelir |
| `left_floor` | Karakter yerden kesildi: bir zıplamayla ya da bir kenardan çıkarak. Bir basamak aşağı inmek sayılmaz |
| `touched_floor(fall_speed)` | Havada geçen herhangi bir süreden sonra yeniden yerde; her `left_floor` için bir tane. `fall_speed` temas anındaki hızdır |
| `landed(impact_speed)` | `landing_min_speed` veya daha yüksek hızla bir `touched_floor`: bir tümsek değil, gerçek bir iniş |
| `sprint_changed(sprinting)` | Depar başladı veya bitti |
| `stair_taken(height)` | Basamak çıkıldı veya inildi; yükseklik yerden yere ölçülür, yukarı pozitif, aşağı negatif (demoda ±0.2 m). Tikin sonunda, `state_changed` öncesinde gelir. Kapsülün kendi çıkabildiği (demoda `radius × (1 − cos floor_max_angle)` = 0.1 m) veya `floor_snap_length` ile inilen küçük basamaklar sinyal vermez |
| `teleported` | `teleport()` karakteri başka yere koydu; kamera ve iz gibi takipçiler yol alarak değil, oraya sıçrayarak gitmeli |

| Durum (`GroundCharacter.State`) | Ne zaman |
|---|---|
| `IDLE` | Yerde, `IDLE_SPEED` (0,1 m/sn) değerinden yavaş; bir duvara doğru koşarken de |
| `RUNNING` | Yerde, herhangi bir hızla hareket ediyor, depar atmıyor |
| `SPRINTING` | Yerde, depar atıyor |
| `JUMPING` | Bir zıplamadan sonra havada, tepeye kadar |
| `FALLING` | Havada aşağı iniyor: bir zıplamanın tepesinden sonra ya da bir kenardan çıkınca |

| Sorgu | Döndürdüğü |
|---|---|
| `get_state()` | Durum |
| `get_move_velocity()`, `get_move_speed()` | Gerçek yatay hız ve büyüklüğü, m/s: gövdenin gerçekten kat ettiği. `get_real_velocity()` aksine basamak çıkışını sayar ve zaman durduğunda (`Engine.time_scale` 0) değerini korur |
| `get_locomotion_blend()` | 1B karışım için: `IDLE_SPEED` altında 0, `max_speed` hızında 1, tam depar hızında 2; hız ayarlarından bağımsız |
| `get_local_movement()` | 2B karışım: x modelin sağı (sol negatif), y ileri (geri negatif), uzunluk karışım değeri. Koşu (0, 1), depar (0, 2), sağa yana adım (1, 0), sola (−1, 0), ileri sola (−0.71, 0.71), geri (0, −0.7) |
| `get_local_acceleration()` | Aynı eksenlerde hareketin hızlanması, frenlenmesi ve dönmesi, m/s²: hızlanınca y > 0, frenleyince y < 0, sola dönüşte x < 0. Gövdeyi süren hızdan hesaplanır; basamakta sıçramaz, duvara çarpmayı göstermez |
| `get_turn_rate()` | Modelin ne kadar hızlı döndüğü, rad/sn: sola pozitif, sağa negatif |
| `get_air_time()` | Havada geçen saniye; yerde 0 |
| `get_step_phase()` | Atılan adımlar bir sayı olarak: her adımda tam sayı, kesirli kısım adımlar arasındaki mesafeyle büyür |
| `get_gait_cycle()` | 0'dan 1'e iki adımlık döngü: sol ayak yere değdiğinde 0, sağ ayak değdiğinde 0,5 |
| `get_step_foot()` | Son adımın ayağı, `Foot.LEFT` veya `Foot.RIGHT`. Ayaklar, araya duruşlar girse de sırayla değişir |
| `is_sprinting()`, `is_exhausted()`, `get_jump_speed()` | Şu an depar atıyor; bitkin; zıplamanın kalkış hızı |
| `is_on_floor()`, `get_floor_angle()`, `velocity.y` | `CharacterBody3D` sınıfının kendisinden: yerde mi, ayak altındaki eğim, dikey hız |
| `get_ground_height(point, above, below)` | Noktanın altındaki üzerinde durulabilir zeminin yüksekliği: noktanın `above` metre üstünden `below` metre altına gövde çarpışma maskesiyle ışın. Zemin yoksa veya ışın bir şeyin içinden başlarsa (örneğin `above` değerinden yüksek duvar) NAN |
| `is_counting_steps()` | Şimdi adımlar sayılıyor: `steps_enabled` açık ve hiçbir bileşen durdurmuyor |
| `get_fall_settings()` | Geçerli düşüş: en yüksek öncelikli, eşitlikte en son konan geçersiz kılma; yoksa `fall`. Boş değer, hız sınırsız `gravity_scale` anlamına gelir |

Hangisini ne için kullanmalı:

- **Animasyon karışımı:** 0, 1, 2 noktalarındaki `BlendSpace1D` için `get_locomotion_blend()`;
  yana adım ve geri yürüyüş içeren `BlendSpace2D` için `get_local_movement()`. Bunlar kesin girişleridir.
- **Hızı izleyen efektler:** `get_real_velocity()` yerine `get_move_velocity()`. Basamak çıkışında gövde
  `move_and_slide()` sonrasında basamağa konduğundan gerçek hız azalır. Zaman durunca tik hareketinin sıfır tik
  süresine bölünmesi 0 / 0, NaN üretir.
- **Atalet** (arkada kalan eşya, kalkışa veya dönüşe eğilen model, pelerin): `get_local_acceleration()`.
- **Dönüşe eğilme ve yerinde dönme:** `get_turn_rate()`. Açı değil hızdır: model dönerken görünür, tikten tike
  oynar, model yönüne bakınca 0'a döner. Kullanımdan önce yumuşatın.
- **Kısa iniş veya sert düşüş:** `get_air_time()`. Bir anlık havalanmada düşüş animasyonunu atlayın veya iniş
  etkisini havada kalışla artırın.
- **`touched_floor` veya `landed`:** `touched_floor` her havada kalışı bitirir; hava animasyonunu onunla kapatın.
  `landed` yalnız gerçek iniştir: kamera sarsıntısı, iniş sesi veya çömelme için.
- **Ayak izi, toz, sağ ayak sesi:** `stepped` işleyicisinde `get_step_foot()`.
- **Basamak sesi veya çıkış animasyonu:** `stair_taken(height)`; yumuşatma için değil, gövde zaten basamaktadır.
- **Basamağa oturan ayaklar, zeminin üstündeki model:** `get_ground_height()`.

**Adımlar kapalıyken** (`is_counting_steps()` false), `stepped` gelmez; `get_step_phase()`, `get_gait_cycle()` ve
`get_step_foot()` son değerlerinde kalır. Bacak animasyonu da o sırada onları izlememelidir. Karakter olağan
biçimde koşar, zıplar ve basamak çıkar.

`HandSway` adım fazını izler; bir animasyon da aynısını yapabilir. Bir `AnimationTree` yönetmenin olağan yolu,
karışımlarını her karede sorgulardan ayarlamak ve durum makinesini sinyallerle geçirmektir:

```gdscript
@export var character: GroundCharacter
@export var tree: AnimationTree


func _ready() -> void:
	character.state_changed.connect(_on_state_changed)
	character.landed.connect(func(_speed: float) -> void:
		tree.set("parameters/land/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE))


func _process(_delta: float) -> void:
	# A BlendSpace1D with idle at 0, run at 1 and sprint at 2; for sidesteps, a BlendSpace2D and get_local_movement().
	tree.set("parameters/ground/blend_position", character.get_locomotion_blend())


func _on_state_changed(state: GroundCharacter.State, _previous: GroundCharacter.State) -> void:
	var in_air := state == GroundCharacter.State.JUMPING or state == GroundCharacter.State.FALLING
	var playback: AnimationNodeStateMachinePlayback = tree.get("parameters/playback")
	playback.travel("air" if in_air else "ground")
```

Ayakları zeminle uyumlu tutmak için koşu döngüsünü zamana göre değil mesafeye göre oynatın: konumunu `get_gait_cycle()`
ile uzunluğunun çarpımına ayarlayın (bir `TimeSeek` düğümü ya da `seek()` ile duraklatılmış bir `AnimationPlayer`).
Döngü sol ayağın yere değmesiyle başlamalıdır.

### CharacterMonitor: metin olarak durum

Bir `GroundCharacter` karakterinin ne yaptığını ve son olaylarını gösteren bir `Label`; animasyonları ayarlamak için ya
da hata ayıklama katmanı olarak. Demoda `Hud/CharacterState/Monitor` düğümüdür ve Ayarlar (F10) → Arayüz → **Karakter
durumu ve olaylar** ile gösterilir. Metin yalnızca yukarıdaki sinyallerden ve sorgulardan gelir; bu yüzden betik aynı
zamanda bunların kullanımına bir örnektir.

```
Running
Speed 5.5 m/s · blend 1.00
Forward +1.00 · right +0.00
Turning +0°/s
On the ground · slope 0°
Step 38 · left foot · cycle 0.03
Stamina 100%

11.83 s  Jumping → Falling
12.08 s  touched the ground at 7.8 m/s
12.08 s  landing at 7.8 m/s
12.08 s  Falling → Running
12.35 s  step, right foot
12.62 s  step, left foot
```

Satırların anlamı:

1. `get_state()` ile alınan durum.
2. Gerçek hız (`get_move_speed()`) ve karışım değeri.
3. Model eksenlerinde işaretli hareket: ileri +1.00 tam koşu, −0.70 geri yürüyüş; sağ −1.00 sola yana adımdır.
4. Modelin saniyedeki dönüş hızı, sola pozitif. Açı değil hızdır; model dönerken görünür ve yöne bakınca 0 olur.
5. Yerdeyse ayak altındaki eğim; havadaysa havada kalma süresi ve dikey hız.
6. Adım sayısı, son basan ayak ve yürüyüş döngüsü; adımlar sayılmıyorsa "Adım yok".
7. Dayanıklılık; depar atamıyorsa "tükendi".

Altında en eskiden yeniye, başlangıçtan beri geçen zamanla son olaylar görünür: ayakla adımlar, yükseklikleriyle
basamaklar, zıplama ve yerden ayrılma, düşüş hızıyla iniş, depar ve durum değişimleri. Panel açıkken metnini her
karede yeniler; gizliyken yenilemeyi atlar ama olayları kaydetmeye devam eder (`log_events` ile yazdırır).

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `character` | — | `GroundCharacter`; boşsa üst düğüm |
| `history_size` | 6 | Durumun altında kaç son olayın gösterileceği; 0 yalnızca durumu gösterir |
| `log_events` | kapalı | Her olayı zamanı ve karakterin adıyla çıktıya da yazdır |
| `include_steps` | açık | Adımları ve basamakları da gösterip günlüğe yazar: saniyede birkaç tane olur |

Metotlar: `get_text_now()`, `get_state_lines()`, `get_event_lines()`, `get_state_name(state, translated)`. İfadeler
`tr()` üzerinden geçer, böylece panel arayüz dilinde konuşur; çıktıdaki günlük İngilizce kalır.

### Basamaklar ve eğimler

**Eğimler** `move_and_slide()` metodunun kendi işidir: gövde `floor_max_angle` değerinden dik olmayan bir yüzeyde yukarı
yürür, daha dik olanında durur. Demonun gövdesinde açık olan `floor_constant_speed` ile rampada hızını korur.

**Basamaklar.** Bir kapsül bir çıkıntıya kendiliğinden yalnızca `radius × (1 − cos floor_max_angle)` yüksekliğe kadar
çıkar; 0,35 m'lik kapsül için bu 0,1 m'dir. `max_step_height` değerine kadar daha yüksek basamakları gövde kendisi
çıkar:

- **Yukarı.** Tikin hareketi, 5 cm ileriye bakıldığında üzerinde durulamayacak kadar dik bir şeye çarparsa gövde bir
  basamak dener: `max_step_height` kadar (ya da bir tavanın izin verdiği kadar) yukarı, tikin hareketi kadar ileri,
  zemine doğru aşağı. Bir ışın üst yüzeyi kontrol eder: ayakların en fazla `max_step_height` üstünde bir zemin
  olmalıdır; bu yüzden 0,4 m'lik bir blok ya da dik bir eğim basamak değildir. Gövde basamağın üzerine konur ve
  `move_and_slide()` onu yalnızca oraya oturtur.
- **Aşağı.** Gövde tikten önce yerdeyse, tikten sonra zıplamadan havadaysa ve altında en fazla `max_step_height`
  derinlikte zemin varsa gövde o zemine konur: `left_floor` yok, düşüş yok.
- Gövdenin geçtiği her basamak `stair_taken(height)` ile bildirilir: önceki zeminden yeni zemine gerçek yükseklik,
  demo merdivenlerinde yukarı +0.2 m, aşağı −0.2 m.
- Kapsülün yuvarlak tabanı bir basamak kenarına açılı olarak dayanır; gövde kenardan uzaktayken bu açı üzerinde
  durulamayacak kadar diktir. Bu yüzden basamaktaki yer biraz daha ileride, 2 cm'lik adımlarla aranır: gövde, tikin onu
  götüreceği yerden birkaç santimetreye kadar ileride durur.

Her basamak, kenarının üzerinden yuvarlanarak geçilen yaklaşık bir tike mal olur; bu sırada yatay hız yaklaşık %70'e
düşer (`get_move_speed()` bunu gösterir; `HandSway`, `get_local_acceleration()` izlediğinden eldeki asa bunu fark
etmez). Uzun merdiven için en akıcısı görünmez rampa çarpışma şeklidir.

Gövde basamağa hemen çıkar: 0.2 m basamağın yaklaşık 0.1 m'sini bir tikte, kalanını kapsül kenarın üzerinden
yuvarlanırken sonraki iki veya üç tikte çıkar. Fizik enterpolasyonu bunu çizilen karelere yayar, ama ekranda yine
kısa bir sıçramadır. Süzülen model (`CharacterHover`) basamaklar üzerinde kayar; kameranın `height_follow_time`
değeri görüntüdeki çıkışı yumuşatır (demoda 0.15 s; bkz. [Kamera](camera.md#özellikler)).

Navigasyon örgüsü gövdenin çıkabildiği yerleri birleştirmelidir: demoda `agent_max_climb`, `max_step_height` ile aynı
olarak 0,3 m'dir (bkz. [Dünya ve navigasyon](world-and-navigation.md#fizik-katmanları-ve-navigasyon)).

### Zıplama

Kalkış hızı `v = √(2·g·h)`. Kalkış tikinde gövde `v − g·dt/2` hızını alır ve başka yerçekimi uygulanmaz;
kenardan ayrıldıktan hemen sonraki zıplamada da böyledir. Böylece her tikteki konumlar tam olarak
parabolün üzerinde yer alır ve zıplama yüksekliği tik hızına bağlı olmaz. Düz `v` ile zıplama `v·dt/2` kadar yüksek
olurdu: 60 tikte 1 m yerine 1.064 m. Demoda `gravity_scale` 3 ile 1 m'lik zıplama 0.52 s sürer.

Havada karakter olduğu gibi koşmayı sürdürür ve kontroller aynı kalır. Kenar koruması zıplamayı tutmaz: bir platform
kenarından zıplamak kaza değil, bilinçli bir adımdır.

### Düşüş

Zıplamanın tepesinden sonra ve kenardan aşağı inişte `FallSettings` kaynağı geçerlidir: karakterin kendi `fall`
değeri veya bir bileşenin geçici olarak yerine koyduğu değer. Yükseliş değişmez, `gravity_scale` ile yavaşlar;
dolayısıyla düşüş ayarı ne olursa olsun zıplama `jump_height` kadar yükselir. Düşüş ayarı yoksa karakter eskisi gibi,
yerçekimi hangi yöne çekerse `gravity_scale` katıyla ve hız sınırı olmadan düşer. Ayar varken de bir alanın yatay
yerçekimi eskisi gibi çeker; yerçekimi aşağıya hiç çekmiyorsa (yukarı akım) ayarın biçimlendireceği düşüş yoktur.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `gravity_scale` | 0 | Aşağı inişte dünya yerçekiminin çarpanı, yani düşüşün hızlanması. Karakterinkinden düşükse çıkıştan yavaş iner. 0 karakterin kendi `gravity_scale` değerini alır; yeni kaynak tek başına düşüşü değiştirmez, yalnız hız sınırı konabilir |
| `max_speed` | 0 m/s | En hızlı düşüş: bu hıza dek hızlanır, sonra sabit gider. 0 sınır yok demektir |
| `braking_time` | 0.3 s | `max_speed` üzerindeki düşüşün fazla hızının %95'ini ne sürede yitireceği; aşağı fırlatılmada veya ayar düşüş ortasında etkinleşince. 0 anlık |

Bileşen kendi düşüşünü geçici olarak `fall` yerine koyabilir: `set_fall_override(self, settings, priority)`;
geri vermek için `null` kullanır. Birkaç bileşen varsa en yüksek öncelik (varsayılan 0), eşitlikte en son atanmış
olan geçerlidir. Bileşen yalnız ayarını veya önceliğini değiştirirse sırasını korur. `fall` değişmez; bileşenler
bırakınca oyunun ayarı geri gelir. Karakter bileşeni hayatta tutmaz; serbest bırakılınca geçersiz kılma biter.
`get_fall_settings()` etkin düşüşü döndürür. `CharacterHover`, model yükselmeye başladığında kendi `fall`
kaynağını öncelik 0 ile koyar (bkz. [Karakterler](characters.md#düşüş)); oyunun öncelik 1 ile koyduğu yavaş düşüş
büyüsü, süzülme açıkken de baskın olur.

`touched_floor` ve `landed`, zemine dokunulduğu andaki hızı bildirir. `landing_min_speed` altında hız sınırı
olan düşüş yalnız `touched_floor` üretir. Karakter daha hızlı aşağı fırlatılıp yavaşlamadan yere değer ise
`landed` de gelir. Karakterin kendi `fall` ayarında bu kurulum uyarısıdır: zıplamadan sonra iniş sesi ve etkileri
hiç gelmez. Süzülen karakterde demo bunu ister: yumuşak iniş. Sınır tam `landing_min_speed` ise iniş sayılır.

Demo kahramanının kendi `fall` değeri yoktur. Süzülme için `gdscript/player/player_floating_fall.tres` kullanır:
gövdenin 3 değerine karşılık 0.5 yerçekimi ölçeği ve 2 m/s azami iniş hızı. Süzülen kahraman 1 m zıplamada
0.52 s yerine 0.95 s havada kalır ve 7.8 m/s yerine 2 m/s ile zemine dokunur.
`FallSettings.get_next_speed(speed, acceleration, delta)` ve `get_gravity_scale(own)` kendi gövdeniz için hesaplama
adımıdır.

## Depar ve dayanıklılık

Depar istendiği ve karakter yönetildiği sürece (bir tıklama, basılı bir tuş, iki tuş, klavye tuşları)
`sprint_speed_multiplier` kat daha hızlı koşar ve dayanıklılık harcar. Shift basılıyken yerinde durmak hiçbir şey
harcamaz. Rezerv bitince karakter bitkin düşer: dayanıklılık `recover_ratio` değerine dolana kadar normal hızda
koşar, ardından Shift hâlâ basılıysa kendiliğinden yeniden depar atar.

`Stamina` onu neyin harcadığını bilmez:

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `max_value` | 100 | Dolu rezerv |
| `recovery_rate` | saniyede 12,5 | Boştan doluya 8 sn |
| `recovery_delay` | 1 sn | Yenilenme son harcamadan bu kadar sonra başlar |
| `recover_ratio` | 0,3 | Bitkin bir karakter bu payı yeniledikten sonra yeniden depar atar (1 + 2,4 sn) |

Metotlar: `spend(amount)`, `can_spend()`, `get_ratio()`, `is_exhausted()`, `refill()`. Sinyaller: `changed(ratio)`,
`exhausted_changed(exhausted)`. HUD'daki `StaminaBar` bunları dinler.

## LedgeGuard

Karakterin bir uçurumdan yürüyerek düşmesini önler. Gövde `move_and_slide()` öncesinde `constrain(velocity, delta)`
çağırır. Gövde tiki bir uçurumun üzerinde bitirecekse hareket, kenar boyunca altında zemin olan en yakın yöne
çevrilir ve dönüş açısının kosinüsü oranında kısaltılır; tıpkı bir duvar boyunca kaymada olduğu gibi. Kenara dümdüz
koşmak karakteri durdurur.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `enabled` | açık | Kenarları koru |
| `max_drop` | 0.5 m | Daha derin düşüşler korunur; daha alçaklardan geçilebilir. Yalnız `GroundCharacter.max_step_height` içindeki düşüşler yerden kesilmeden inilir |
| `edge_margin` | 0,15 m | Karakterin merkezinin kenara ne kadar yaklaşabileceği |
| `margin_probes` | 6 | `edge_margin` çemberi etrafındaki ışınlar |
| `probe_height` | 0,5 m | Ayakların biraz üzerindeki zemini (rampa) bulmak için ışınlar ayakların bu kadar üstünden başlar |
| `floor_mask` | 0 | Neyin zemin sayıldığı; 0 gövdenin çarpışma maskesini alır, böylece gövdenin üzerinde durduğu şey zemin sayılır |
| `slide_iterations` | 6 | Kayma açısının yarıya bölünme sayısı; 6 yaklaşık 1,4° verir |

Açık zeminde bu, tik başına 7 ışın, kenarda ise 98'e kadar ışın demektir. Havada koruma hiçbir şey yapmaz.
Platformdan aşağı giden bir yol rampayı izler ve koruma ona engel olmaz.
Zemin, gövdenin üzerinde durabildiği şeydir: `floor_max_angle` değerinden dik değil, motorun zemin denetimiyle aynı
küçük tolerans (`GroundCharacter.FLOOR_ANGLE_MARGIN`) geçerlidir. Gövdenin çarpışmadığı katmanları içeren
`floor_mask` kurulum uyarısı üretir: koruma, gövdenin içinden düşeceği şeyi zemin sayardı.

## Ölçülen davranış

`tests/movement_checks.gd`, `tests/character_actions_checks.gd` ve `tests/character_state_checks.gd` içindeki
sahne denemeleri sağlanan kahramanı saniyede 60 fizik tikinde dener:

- Varsayılan 5.5 m/s koşu ve 0.18 s ivmeyle %95 hıza 0.18 s'de ulaşır; %95'ten normal duruş yaklaşık 0.20 s
  sürer. Frenlerken yeni hedef hızı korur; ters yöne tıklama yay çizdirir.
- Depar 8.25 m/s hızına ulaşır. Denemede dayanıklılık süresi 2 s iken tükenir, eşiği geçerek yenilenir ve hâlâ
  basılı depar isteği yeniden başlar.
- 1 m zıplama 1.000 m'ye ulaşır ve yaklaşık 0.52 s havada kalır. İnişten hemen önce tamponlanan basış çalışır;
  kenardan ayrıldıktan hemen sonra da kısa süre zıplanabilir.
- Demodaki 0.2 m basamaklar iki yönde yerden kesilmeden geçilir; `stair_taken` her birini bildirir. 0.4 m blok
  ve 50° eğim gövdeyi durdurur. Koruma platform kenarında koşuyu durdurur ve açılı koşuyu kenar boyunca kaydırır.
- Süzülmenin 0.5 düşüş yerçekimi ve 2 m/s sınırıyla zıplama yüksekliği 1 m kalır; yere temas 2 m/s ile olur,
  varsayılan 2.5 m/s iniş eşiğinin altındadır. Sonuçlar sağlanan kapsül, çarpışmalar, örgü ve ayarlara bağlıdır;
  kendi seviyenizde değişen geometriyi ve değerleri yeniden deneyin.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
