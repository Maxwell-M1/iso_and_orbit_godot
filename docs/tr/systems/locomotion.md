<!-- translation of docs/en/systems/locomotion.md @ 5c06aa020dad -->
# Hareket

> Bu, [İngilizce orijinalin](../../en/systems/locomotion.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Bir karakterin nasıl koştuğu, durduğu, döndüğü, depar attığı, zıpladığı, basamak çıktığı ve uçurumlardan nasıl uzak
durduğu, ayrıca ne yaptığını nasıl bildirdiği. Aşağıdan yukarıya dört sınıf:

| Sınıf | Tür | Görev |
|---|---|---|
| `LocomotionSettings` | Resource | Hız, hızlanma, frenleme, dönüş |
| `GroundMotion` | RefCounted | Matematik: istenen yön ve kalan mesafe → yatay hız |
| `NavigationMover` | Node, gövdenin alt düğümü | Yollar ve komutlar; bir hız döndürür, gövdeyi asla hareket ettirmez |
| `GroundCharacter` | CharacterBody3D | Yerçekimi, zıplama, depar, `move_and_slide()`, modeli döndürme |

Gövdeye iki yardımcı takılır: `Stamina` (depar rezervi) ve `LedgeGuard` (uçurumdan yürüyerek düşmeyi önler).
`CharacterMonitor`, gövdenin bildirdiklerini metin olarak gösterir.

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
zıplamayı ve yerçekimini işler, hızı `LedgeGuard` ile düzelttirir, öncesinde bir basamak çıkışı ve sonrasında bir
basamak inişiyle `move_and_slide()` çağırır, ardından tikin neyi değiştirdiğini bildirir: zemin teması, adımlar, modelin
`mover.get_facing()` yönüne dönüşü ve durum.

Denetçi (Inspector) özellikleri gruplar: önce parçalar ve dönüş, ardından Ground (zemin), Jump and fall (zıplama ve
düşüş), Sprint (depar) ve Steps (adımlar).

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `mover` | — | `NavigationMover`; zorunlu |
| `visual` | — | Karakterin gittiği yöne çevrilen düğüm; önü −Z yönüdür |
| `visual_turn_speed` | 1080 °/sn | Modelin ne kadar hızlı döndüğü |
| `max_step_height` | 0,3 m | Karakterin zıplamadan çıktığı en yüksek basamak ve yerden kesilmeden indiği en derin basamak. 0 basamak çıkıp inmeyi kapatır |
| `ledge_guard` | — | İsteğe bağlı `LedgeGuard`; olmadan karakter her yükseklikten düşer |
| `can_jump` | açık | Zıplamaya izin verilir; kapalıyken `jump()` hiçbir şey yapmaz |
| `jump_height` | 1 m | Zıplamanın tepesinde ayakların yüksekliği |
| `coyote_time` | 0,1 sn | Bir kenardan yürüyerek çıktıktan sonra zıplama bu kadar süre daha çalışır |
| `jump_buffer_time` | 0,12 sn | İnişten bu kadar önce basılan zıplama inişte gerçekleşir |
| `gravity_scale` | 3 | Yerçekimi çarpanı. Karakter bir insandan hızlı koşar ve normal yerçekiminde süzülerek inerdi: 1,6 m'lik bir düşüş 0,57 sn yerine 0,33 sn sürer |
| `landing_min_speed` | 2,5 m/sn | Daha yavaş bir düşüş (bir tümsek, bir rampa) yalnızca `touched_floor` olur, `landed` olmaz |
| `can_sprint` | açık | Depara izin verilir. Koşarken kapatılırsa fazla hız frenlenerek düşürülür |
| `stamina` | — | İsteğe bağlı `Stamina`; olmadan depar hiç yormaz |
| `sprint_tires` | açık | Depar dayanıklılık harcar |
| `sprint_duration` | 5 sn | Dolu bir rezervin ne kadar yettiği: saniyede `max_value / sprint_duration` harcar |
| `stride_length` | 1,5 m | Zeminde adımlar arasındaki mesafe |
| `first_step_distance` | 0,3 m | Duruştan ilk adıma kadar mesafe |

Eğim sınırı gövdenin kendi `floor_max_angle` özelliğidir (denetçide Floor → Max Angle, varsayılan olarak 45°). Daha dik
bir yüzey gövde için de, basamaklar için de, kenar koruması için de bir duvardır.

Depar istemek için `sprint_requested` ayarlayın, zıplamak için `jump()` çağırın. Oyuncu için ikisini de
`CharacterActionInput` yapar; yapay zekâ da aynısını yapabilir.

### Karakterin bildirdikleri

Animasyonlar, efektler, sesler ve arayüz, karakterin ne yaptığını hızdan çıkarmak zorunda değildir. Anlık olaylar sinyal
olarak gelir; sürekli değişenler ise her karede veya her tikte sorgularla okunur.

| Sinyal | Ne zaman |
|---|---|
| `state_changed(state, previous)` | Durum değişti. Tikin sonunda, tikin diğer sinyallerinden sonra |
| `stepped(sprinting)` | Bir ayak yere değdi (hangisi olduğunu `get_step_foot()` söyler): zeminde kat edilen her `stride_length` mesafede, ilki duruştan `first_step_distance` sonra. Adımlar zamanı değil mesafeyi izler: koşarken saniyede yaklaşık 3,7, deparda 5,5; duvara dayanmış dururken veya havadayken hiç |
| `jumped` | Karakter zeminden itildi; aynı tikte ardından `left_floor` gelir |
| `left_floor` | Karakter yerden kesildi: bir zıplamayla ya da bir kenardan çıkarak. Bir basamak aşağı inmek sayılmaz |
| `touched_floor(fall_speed)` | Havada geçen herhangi bir süreden sonra yeniden yerde; her `left_floor` için bir tane |
| `landed(impact_speed)` | `landing_min_speed` veya daha yüksek hızla bir `touched_floor`: bir tümsek değil, gerçek bir iniş |
| `sprint_changed(sprinting)` | Depar başladı veya bitti |

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
| `get_move_velocity()`, `get_move_speed()` | Gerçek yatay hız ve büyüklüğü, m/sn: gövdenin gerçekten kat ettiği. `get_real_velocity()` değerinden farklı olarak bir basamak çıkışını da sayar |
| `get_locomotion_blend()` | 1B karışım için: dururken 0, `max_speed` hızında 1, tam depar hızında 2; hızlar nasıl ayarlanmış olursa olsun |
| `get_local_movement()` | 2B karışım için: x modelin sağına, y ileriye, uzunluk karışım değeridir. Koşu (0; 1), depar (0; 2), sağa yana adım (1; 0), geri geri yürüme (0; −0,7) |
| `get_turn_rate()` | Modelin ne kadar hızlı döndüğü, rad/sn: sola pozitif, sağa negatif |
| `get_air_time()` | Havada geçen saniye; yerde 0 |
| `get_step_phase()` | Atılan adımlar bir sayı olarak: her adımda tam sayı, kesirli kısım adımlar arasındaki mesafeyle büyür |
| `get_gait_cycle()` | 0'dan 1'e iki adımlık döngü: sol ayak yere değdiğinde 0, sağ ayak değdiğinde 0,5 |
| `get_step_foot()` | Son adımın ayağı, `Foot.LEFT` veya `Foot.RIGHT`. Ayaklar, araya duruşlar girse de sırayla değişir |
| `is_sprinting()`, `is_exhausted()`, `get_jump_speed()` | Şu an depar atıyor; bitkin; zıplamanın kalkış hızı |
| `is_on_floor()`, `get_floor_angle()`, `velocity.y` | `CharacterBody3D` sınıfının kendisinden: yerde mi, ayak altındaki eğim, dikey hız |

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
Step 37 · left foot · cycle 0.03
Stamina 100%

12.35 s  step, right foot
12.62 s  step, left foot
12.80 s  jump
12.80 s  left the ground
12.80 s  Running → Jumping
```

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `character` | — | `GroundCharacter`; boşsa üst düğüm |
| `history_size` | 6 | Durumun altında kaç son olayın gösterileceği; 0 yalnızca durumu gösterir |
| `log_events` | kapalı | Her olayı zamanı ve karakterin adıyla çıktıya da yazdır |
| `include_steps` | açık | Adımları da göster ve günlüğe yaz: saniyede birkaç tane olur |

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
- Kapsülün yuvarlak tabanı bir basamak kenarına açılı olarak dayanır; gövde kenardan uzaktayken bu açı üzerinde
  durulamayacak kadar diktir. Bu yüzden basamaktaki yer biraz daha ileride, 2 cm'lik adımlarla aranır: gövde, tikin onu
  götüreceği yerden birkaç santimetreye kadar ileride durur.

Her basamak, kenarının üzerinden yuvarlanarak geçilen yaklaşık bir tike mal olur; bu sırada yatay hız yaklaşık %70'e
düşer (`get_move_speed()` bunu gösterir, eldeki asa ise neredeyse hiç kıpırdamaz). Uzun bir merdiven için en akıcısı
görünmez bir rampa çarpışma şeklidir.

Navigasyon örgüsü gövdenin çıkabildiği yerleri birleştirmelidir: demoda `agent_max_climb`, `max_step_height` ile aynı
olarak 0,3 m'dir (bkz. [Dünya ve navigasyon](world-and-navigation.md#fizik-katmanları-ve-navigasyon)).

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

Testler (`tests/movement_checks.gd`, `tests/character_actions_checks.gd`, `tests/character_state_checks.gd`,
`tests/camera_checks.gd`) demonun ayarlarını saniyede 60 fizik tikiyle ölçer. Sınırları ayarlardan hesaplanır, bu yüzden
ayarları değiştirebilirsiniz.

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
- Karakterin bildirdikleri: tam hızda koşu 1,00, tam depar 2,00 karışım değeri verir; yana adım (1,00; 0,00), geri geri
  yürüme (0,00; −0,70). Bir koşudaki durumlar: `RUNNING`, `SPRINTING`, `RUNNING`, `IDLE`. Bir zıplama: `jumped`,
  `left_floor`, 0,27 sn `JUMPING` (formüle göre tepeye 0,26 sn), `FALLING`, `touched_floor`, `landed`, `IDLE`; havada
  0,52 sn. Platform kenarından: `left_floor` ve doğrudan `FALLING`. Ayaklar bir duruştan sonra da sırayla değişir.
- Platformun doğusundaki merdiven (0,2 m yüksekliğinde, 0,4 m derinliğinde basamaklar), bir tıklamayla: yerden
  kesilmeden çıkış ve iniş; medyan hız çıkarken 5,4 m/sn, inerken 5,5 m/sn, en düşük 3,9 ve 5,0 m/sn. `max_step_height`
  0 iken karakter ilk basamakta durur. 0,4 m'lik bir blok onu durdurur, 30°'lik bir eğim yürüyerek çıkılır, 50°'lik bir
  eğim çıkılamaz.
- Dağ patikasında, rampada, çayırda ve labirentte karakter zıplamadan asla yerden kesilmez.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
