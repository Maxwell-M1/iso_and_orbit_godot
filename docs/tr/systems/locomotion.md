<!-- translation of docs/en/systems/locomotion.md @ 1ec8642147fb -->
# Hareket

> Bu, [İngilizce orijinalin](../../en/systems/locomotion.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Bir karakterin nasıl koştuğu, durduğu, döndüğü, depar attığı, zıpladığı ve uçurumlardan nasıl uzak durduğu. Aşağıdan
yukarıya dört sınıf:

| Sınıf | Tür | Görev |
|---|---|---|
| `LocomotionSettings` | Resource | Hız, hızlanma, frenleme, dönüş |
| `GroundMotion` | RefCounted | Matematik: istenen yön ve kalan mesafe → yatay hız |
| `NavigationMover` | Node, gövdenin alt düğümü | Yollar ve komutlar; bir hız döndürür, gövdeyi asla hareket ettirmez |
| `GroundCharacter` | CharacterBody3D | Yerçekimi, zıplama, depar, `move_and_slide()`, modeli döndürme |

Gövdeye iki yardımcı takılır: `Stamina` (depar rezervi) ve `LedgeGuard` (uçurumdan yürüyerek düşmeyi önler).

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

Demo `gdscript/player/player_locomotion.tres` dosyasını kullanır. Bu dosya betik varsayılanlarından ikisini
değiştirir.

| Özellik | Demo | Betik varsayılanı | Anlamı |
|---|---|---|---|
| `max_speed` | 5,5 m/sn | 5,5 m/sn | Koşu hızı |
| `acceleration_time` | 0,35 sn | 0,18 sn | Duruştan `max_speed` değerine |
| `stop_time` | 0,4 sn | 0,22 sn | `max_speed` değerinden duruşa; fren mesafesi `max_speed × stop_time / 2` (demoda 1,1 m) |
| `turn_speed` | 720 °/sn | 720 °/sn | Koşu yönünün ne kadar hızlı döndüğü |
| `turn_slowdown` | 0,75 | 0,75 | Yön yetişirken kaybedilen hız: 0 hızı korur (geniş yay), 1 ise 90° veya daha büyük bir dönüş için sıfıra kadar frenler |
| `pivot_speed` | 1 m/sn | 1 m/sn | Bunun altında karakter anında döner |
| `max_braking_multiplier` | 3 | 3 | Karakterin hemen önündeki bir nokta için normalden ne kadar sert frenleyebileceği |
| `sprint_speed_multiplier` | 1,5 | 1,5 | Deparda hız sınırı (8,25 m/sn); hızlanma ve frenleme aynı kalır |
| `backward_speed_multiplier` | 0,7 | 0,7 | Geriye hareket ederken (harekete ters yöne bakarken) kalan hız payı |

Ayarlar penceresi `sprint_speed_multiplier` ve `backward_speed_multiplier` değerlerini çalışma anında değiştirir.
Geri kalanlar kaynakta ayarlanır. Oyun çalışırken ayarlamak için: Sahne paneli (Scene dock) → Uzak (Remote) →
`Player/NavigationMover` → `settings`. Kod bunları her tikte okur, ancak orada yapılan değişiklikler kaydedilmez; bu
yüzden sonucu `.tres` dosyasına kopyalayın.

Tek bir kaynak birkaç karakter tarafından paylaşılabilir, örneğin aynı türden tüm NPC'ler.

## NavigationMover

Gövdenin bir alt düğümü (herhangi bir `Node3D`, genellikle bir `CharacterBody3D`). İki mod:

- `move_to(point)`: bir navigasyon yolu boyunca, engellerin etrafından dolaşarak bir noktaya, tam duruşla. Yol,
  gövdenin dünyası için `NavigationServer3D` üzerinden gelir. Navigasyon haritası yoksa karakter noktaya düz koşar.
- `steer(direction, facing = Vector3.ZERO)`: `stop()`, `halt()` veya `move_to()` gelene kadar yolsuz olarak bir
  yöne. Engeller, gövdenin onlar boyunca kaymasıyla aşılır. `facing` verilirse karakter hareket ederken o yöne bakar:
  yana adım ve geri geri yürüme. Bakış yönü duruştan sonra da, onu içermeyen bir komut gelene kadar korunur.

Gövde her fizik tikinde bir kez, `move_and_slide()` öncesinde `compute_velocity(delta)` çağırır.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `settings` | — | `LocomotionSettings`; boşsa varsayılanlar |
| `use_navigation` | açık | Yol ara; kapalıysa veya dünyada navigasyon yoksa: noktaya düz koş |
| `navigation_layers` | 1 | Yolun kullanabileceği navigasyon katmanları |
| `waypoint_radius` | 0,4 m | Bundan daha yakında bir yol noktası geçilmiş sayılır; daha büyük değer köşeleri daha erken keser |
| `arrive_distance` | 0,005 m | Sona bundan daha yakınken karakter hemen durur. Frenlemenin kendisi onu noktaya getirir, bu yüzden eşik çok küçüktür |
| `retarget_tolerance` | 0,1 m | Mevcut noktaya bundan daha yakın yeni bir nokta yolu yeniden oluşturmaz. Basılı tuş her tikte bir nokta gönderir |
| `max_path_deviation` | 2 m | Yoldan bundan daha uzağa itilen karakter yeni bir yol alır |
| `sprinting` | kapalı | Hız sınırını `sprint_speed_multiplier` ile yükselt. Ne zaman olacağına sahibi karar verir |

Sinyaller: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled`.

**Yol noktaları yatay düzlemde karşılaştırılır.** Bir Recast navigasyon örgüsü zeminin yaklaşık iki hücre yüksekliği
(burada 0,05 m) üstünde durur. 3B mesafeleri karakterin ayaklarıyla karşılaştırmak o kadar sapma verirdi;
hareketlendiricinin `NavigationAgent3D` kullanmak yerine yolu kendisinin izlemesinin nedeni budur.

**Geri geri yürüme daha yavaştır.** `steer()` bir `facing` aldığında hız, hareketin bakış yönüne ne kadar ters
olduğuna göre ölçeklenir: tam geriye `backward_speed_multiplier` değerinin tamamı, çapraz geriye bir kısmı uygulanır
(yana adımda S + D: %21 daha yavaş), yana hiç uygulanmaz. Bu yüzden yavaşlama yalnızca tuşların yana adım modunda
vardır, bkz. [Girdi](input.md).

## GroundCharacter

Gövdenin hareket ettiği tek yer. Her fizik tikinde depar durumunu günceller, yatay hızı hareketlendiriciden alır,
zıplamayı ve yerçekimini işler, hızı `LedgeGuard` ile düzelttirir, `move_and_slide()` çağırır, adımları ve inişleri
bildirir ve `visual` düğümünü `mover.get_facing()` yönüne çevirir.

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `mover` | — | `NavigationMover`; zorunlu |
| `visual` | — | Karakterin gittiği yöne çevrilen düğüm; önü −Z yönüdür |
| `visual_turn_speed` | 1080 °/sn | Modelin ne kadar hızlı döndüğü |
| `gravity_scale` | 3 | Yerçekimi çarpanı. Karakter bir insandan hızlı koşar ve normal yerçekiminde süzülerek inerdi: 1,6 m'lik bir düşüş 0,57 sn yerine 0,33 sn sürer |
| `ledge_guard` | — | İsteğe bağlı `LedgeGuard`; olmadan karakter her yükseklikten düşer |
| `can_sprint` | açık | Depara izin verilir. Koşarken kapatılırsa fazla hız frenlenerek düşürülür |
| `stamina` | — | İsteğe bağlı `Stamina`; olmadan depar hiç yormaz |
| `sprint_tires` | açık | Depar dayanıklılık harcar |
| `sprint_duration` | 5 sn | Dolu bir rezervin ne kadar yettiği: saniyede `max_value / sprint_duration` harcar |
| `can_jump` | açık | Zıplamaya izin verilir; kapalıyken `jump()` hiçbir şey yapmaz |
| `jump_height` | 1 m | Zıplamanın tepesinde ayakların yüksekliği |
| `coyote_time` | 0,1 sn | Bir kenardan yürüyerek çıktıktan sonra zıplama bu kadar süre daha çalışır |
| `jump_buffer_time` | 0,12 sn | İnişten bu kadar önce basılan zıplama inişte gerçekleşir |
| `landing_min_speed` | 2,5 m/sn | Daha yavaş düşüşler (bir basamak aşağı, rampa) iniş sayılmaz |
| `stride_length` | 1,5 m | Zeminde adımlar arasındaki mesafe |
| `first_step_distance` | 0,3 m | Duruştan ilk adıma kadar mesafe |

Depar istemek için `sprint_requested` ayarlayın, zıplamak için `jump()` çağırın. Oyuncu için ikisini de
`CharacterActionInput` yapar; yapay zekâ da aynısını yapabilir.

### Sinyaller

| Sinyal | Ne zaman |
|---|---|
| `stepped(sprinting)` | Bir ayak yere değdi: zeminde kat edilen her `stride_length` mesafede, ilki duruştan `first_step_distance` sonra. Adımlar zamanı değil mesafeyi izler: koşarken saniyede yaklaşık 3,7, deparda 5,5; duvara dayanmış dururken veya havadayken hiç |
| `jumped` | Karakter zeminden itildi |
| `landed(impact_speed)` | Karakter indi; `impact_speed`, m/sn cinsinden düşüş hızıdır |
| `sprint_changed(sprinting)` | Depar başladı veya bitti |

`get_step_phase()`, adım ritmini atılan adım sayısı olarak döndürür: her adımda bir tam sayı, adımlar arasındaki
mesafeyle 0'dan 1'e büyüyen kesirli kısım. `HandSway` bunu kullanır; bir animasyon da kullanabilir. Diğer sorgular:
`is_sprinting()`, `is_exhausted()`, `get_jump_speed()`.

### Zıplama

Kalkış hızı `v = √(2·g·h)`. Kalkış tikinde gövde `v − g·dt/2` hızını alır: böylece her tikteki konumları tam olarak
parabolün üzerinde yer alır ve zıplama yüksekliği tik hızına bağlı olmaz. Düz `v` ile zıplama `v·dt/2` kadar yüksek
olurdu: 60 tikte 1 m yerine 1,064 m. Demoda `gravity_scale` 3 ile 1 m'lik bir zıplama 0,52 sn sürer.

Havada karakter olduğu gibi koşmayı sürdürür ve kontroller aynı kalır. Kenar koruması zıplamayı tutmaz: bir platform
kenarından zıplamak kaza değil, bilinçli bir adımdır.

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
| `max_drop` | 0,5 m | Daha alçak bir düşüş basamaktır ve yürüyerek inilebilir; daha yükseği bir uçurumdur |
| `edge_margin` | 0,15 m | Karakterin merkezinin kenara ne kadar yaklaşabileceği |
| `margin_probes` | 6 | `edge_margin` çemberi etrafındaki ışınlar |
| `probe_height` | 0,5 m | Ayakların biraz üzerindeki zemini (rampa) bulmak için ışınlar ayakların bu kadar üstünden başlar |
| `floor_mask` | 1. katman | Neyin zemin sayıldığı |
| `slide_iterations` | 6 | Kayma açısının yarıya bölünme sayısı; 6 yaklaşık 1,4° verir |

Açık zeminde bu, tik başına 7 ışın, kenarda ise 98'e kadar ışın demektir. Havada koruma hiçbir şey yapmaz.
Platformdan aşağı giden bir yol rampayı izler ve koruma ona engel olmaz.

## Ölçülen davranış

Testler (`tests/movement_checks.gd`, `tests/character_actions_checks.gd`, `tests/camera_checks.gd`) demonun
ayarlarını saniyede 60 fizik tikiyle ölçer. Sınırları ayarlardan hesaplanır, bu yüzden ayarları değiştirebilirsiniz.

- Tam hızın %95'ine 0,33 sn'de; %95'ten duruşa 0,35 sn'de; duruş tam tıklanan noktada.
- Frenlerken daha uzağa yeni bir tıklama: hız 2,66 m/sn'den hemen yeniden artar, hiç sıfıra düşmez.
- Tam hızda karakterin arkasına bir tıklama: 0,34 m daha ilerler, yay yana doğru 0,63 m gider ve 0,28 sn sonra geri
  koşar.
- Platform kenarına dümdüz: kenardan 0,15 m uzakta sıfır hızla duruş. 45°'de: kenar boyunca platformun köşesine
  kadar, aynı yükseklikte 3,89 m/sn hızla kayma (5,5 × cos 45°, duvar boyunca olduğu gibi). Koruma olmadan: 0,35 sn'de
  1,6 m düşüş.
- Depar: 8,25 m/sn. `sprint_duration` 2 sn iken (saniyede 50) dayanıklılık 2,02 sn sonra biter, ardından 5,5 m/sn;
  3,38 sn sonra karakter yenilenmiştir (1 + 2,4 sn) ve Shift hâlâ basılıyken yeniden 8,25 m/sn ile depar atar.
- Zıplama: tepe 1,000 m'de, havada 0,517 sn (formüle göre 0,522). Zeminden 0,4 m yukarıdayken basılırsa zıplama
  inişten sonraki tikte gerçekleşir; tepedeyken basılırsa unutulur. Kenardan yürüyerek çıktıktan 3 tik sonra Boşluk
  zıplatır, 9 tik sonra zıplatmaz.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
