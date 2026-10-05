<!-- translation of docs/en/configurations.md @ 2173d5158953 -->
<!-- translation of docs/en/configurations.md @ pending -->
# Oynanabilir kahramanı yapılandırma

[← Belge dizini](index.md)

> Bu, [İngilizce orijinalin](../en/configurations.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

[Aktarma kılavuzunu](integration.md) tamamladıktan sonra `gdscript/player/playable_hero.tscn` ile başlayın. Aşağıdaki
üç yapılandırma, sağlanan karakter boyutunu, hareket kaynağını ve kamera çarpışma ayarlarını korur. Rastgele hız veya
yumuşatma değerleri eklemeden kahramanı kontrol etme ve görme biçimini değiştirirler.

| Yapılandırma | Ne için uygun | Başlıca ödünleşim |
|---|---|---|
| [Varsayılan: elle döndürülen kamera](#varsayılan-elle-döndürülen-kamera) | Hem tıklayarak hareket hem doğrudan yönlendirmeyle bir bölgeyi sabit açıdan görmek | Kamera yönünü oyuncu seçer |
| [Yol izleyen fare hareketi](#yol-izleyen-fare-hareketi) | Fare basılıyken pişirilmiş engellerin çevresinden dolaşmak | Rampaların ve üst üste gelen yüksekliklerin yakınında yol değişebilir |
| [Kamera takibiyle keşif](#kamera-takibiyle-keşif) | Kameranın koşu yönünün arkasına dönmesini istediğiniz uzun yolculuklar | Rota değiştikçe görüntü döner |

## Bir ayar nerede değiştirilir?

Değerlerin üç kaynağı vardır. Hangisini düzenlediğinizi kontrol edin:

| Kaynak | Ne zaman geçerli | Örnek |
|---|---|---|
| Betik varsayılanları | Sahne tarafından geçersiz kılınmamış yeni bir bileşende | `PointClickMoveInput.keys_with_camera` başlangıçta `SIDESTEP` değerindedir |
| Kaydedilmiş sahne veya kaynak | Sağlanan sahnenin bir örneğinde | `playable_hero.tscn`, `TURN` seçer; kamerasının takip süresi 1.1 sn'dir |
| Demo ayarları | `SettingsApplier` başlangıçta ve menü ayarı değiştiğinde çalışır | Sahnede kapalı olsa bile `user://settings.cfg` kamera takibini açabilir |

Demoda yapılandırmaları karşılaştırmadan önce **Ayarlar → Tümünü sıfırla** seçeneğini kullanın. Menü değişiklikleri
kaydedilir; çalışan sahnenin **Remote** denetçisinde yapılan değişiklikler geçicidir. Tek başına kullanılacak bir
kahraman için kopyalanan sahneleri düzenleyin veya `playable_hero.tscn` sahnesinden kalıtımla yeni bir sahne oluşturup
her çeşidi ayrı kaydedin. İç düğümlere erişmek için sahne örneklerinde **Editable Children** özelliğini açın. Bu
değerleri yönetmesini istemiyorsanız `SettingsApplier` bileşenini kopyalamayın.

Aşağıdaki yollar kahraman örneğine göredir:

| Ayarlanacak özellik | Düğüm veya kaynak |
|---|---|
| Tıklama, basılı tutma, tuşlar ve imleç | `PlayerInput` (`PointClickMoveInput`) |
| Depar tuşu modu ve zıplama girdisi | `PlayerActionInput` (`CharacterActionInput`) |
| Hız, hızlanma, frenleme ve dönüş hızı | `Character/NavigationMover` → `settings`, genellikle `player_locomotion.tres` |
| Zıplama, yerçekimi, basamaklar ve dayanıklılık tüketimi | `Character` (`GroundCharacter`) |
| Kenar koruması / dayanıklılığın yenilenmesi | `Character/LedgeGuard` / `Character/Stamina` |
| Kamera dönüşü, takip, eğim ve yakınlaştırma | `CameraRig` (`OrbitCameraRig`) |
| Kamera engelleri ve saydamlaşma | `CameraRig/CameraArm` (`CameraArm`) |
| Süzülen model | `Character/Visual/Hover` (`CharacterHover`) |

Kamera düzeneğinin açı alanları ve hareket kaynağının dönüş hızı **Inspector'da derece**, GDScript atamalarında ise
**radyan** (`deg_to_rad(30.0)`) kullanır. `Camera3D.fov` farklıdır: kodda da derece kullanır. Aşağıya bakan kamera
eğimi negatiftir. Demodaki **Aşağı eğim** kaydırıcısı pozitif derece, **Yükseklik** ise yüzde kullanır: menüdeki %55,
metre cinsinden bir yükseklik değil, `follow_zoom_level = 0.55` değeridir.

## Varsayılan: elle döndürülen kamera

Sağlanan kahraman sahnesi ve **Tümünü sıfırla** işleminden sonraki demo böyledir. Engellerin çevresinden gitmek için
tıklayabilir, doğrudan yönlendirmek için sol fare tuşunu basılı tutabilir veya kameraya göre hareket etmek için sağ
fare tuşunu WASD ile birlikte kullanabilirsiniz. Kamera gövdenin konumunu izler, ancak kendiliğinden koşunun arkasına
dönmez.

| Bölüm | Korunacak değerler |
|---|---|
| Hareket kaynağı | `max_speed = 5.5`, `sprint_speed_multiplier = 1.5`, `acceleration_time = 0.18`, `stop_time = 0.22`, `turn_speed = 720°/s` |
| Karakter | `jump_height = 1.0`, `gravity_scale = 3.0`, `max_step_height = 0.3`, `sprint_tires = true`, `sprint_duration = 5.0` |
| Girdi | `hold_mode = STEER`, `hold_delay = 0.2`, iki tuş modu da `TURN`, `look_around_while_held = true`, `keep_aim_on_camera_turn = true` |
| Kamera | `follow_movement = false`, `follow_pitch = false`, `follow_zoom = false`, `mouse_pitch = false`; hedef yüksekliğinin yumuşatılması `height_follow_time = 0.15 s` ile etkin kalır |
| İlk görüntü | `start_yaw = 45°`, `start_zoom = 0.55`, kamera görüş açısı 45° |
| Kamera kolu | `keep_out_of_geometry = true`, `pull_in_on_occlusion = false`, çarpışma katmanları 1 ve 3 |

Kenar korumasını etkin, sağlanan `Visual` düğümünü de kamera kolunun saydamlaşacak hedefi olarak tutun. Duvarın
arkasında siluet kahramanı görünür kılar; kol ise kameranın geometriye girmesini önler. Görevleri farklıdır.

**Deneyin:** Çevresinden dolaşılabilen bir duvarın ötesine tıklayın, fareyi duvara doğru basılı tutun ve hareket
ederken kamerayı döndürün. Tıklama bir yol izlemeli; basılı tutma çarpışmaya karşı kaymalı veya durmalıdır. Etrafa
bakmak koşu yönünü korumalıdır. Hareket değerlerini değiştirmeden önce 0.2 m'lik basamağı ve zıplamayı ayrı deneyin.

## Yol izleyen fare hareketi

Varsayılan yapılandırmadan başlayın. `PlayerInput` üzerindeki şu özellikleri değiştirin:

| Özellik | Değer | Etki |
|---|---|---|
| `hold_mode` | `FOLLOW_POINT` | Basılı tutulan fare tuşu, dümdüz yönlendirmek yerine navigasyon hedefini günceller |
| `stop_on_release` | `true` | Basılı tutularak yapılan koşu bırakıldığında mevcut konumda frenler |
| `keys_with_camera` | `OFF` | Sağ fare tuşu + WASD kullanımını kapatır |
| `keys_with_camera_steer` | `OFF` | İki fare tuşu basılıyken A/D ile yönlendirmeyi kapatır |

Kamera yönünün elle kontrol edilmesi için üç kamera takibi anahtarını da kapalı tutun. Varsayılan hareket kaynağı
zaten hızla ivmelenip durur; bu girdi biçimi için hızını değiştirmeniz gerekmez.

Kısa tıklamalar yine hedefe kadar koşar. `stop_on_release` **yalnızca basılı tutmayı** etkiler ve demo menüsünde
bulunmaz; sahnede veya kodda ayarlayın. İki tuş modunu da Kapalı yapmak, iki fare tuşuyla hareketi **kapatmaz**:
sağ tuşu izleyen sol tuş, navigasyon yolu kullanmadan kameranın baktığı yöne dümdüz koşar.

Bu yapılandırma, güvenilir bir pişirilmiş örgüsü olan ve imlecin altındaki zeminin çoğunlukla açıkça belli olduğu
seviyelere uygundur. Bir rampa veya platform yakınında ışın farklı bir yüksekliği seçip yolu yeniden kurabilir.
Böyle arazide hassas doğrudan kontrol için varsayılan `STEER` modunu kullanın. Bu kontrolcüde boş yol, güvenli bir
"hareket etme" sonucu değildir; kahraman doğrudan engele yönelirse navigasyon örgüsünü inceleyin.

**Deneyin:** Duvarın ötesinde fareyi basılı tutun, imleci erişilebilir başka bir noktaya taşıyın ve yolda bırakın.
Kahraman duvarı dolanmalı, yeni hedefe yönelmeli ve bırakınca frenlemelidir. Sonra kısa bir tıklama yaparak hedefe
kadar gittiğini doğrulayın.

## Kamera takibiyle keşif

Varsayılan `STEER` ve `TURN` girdi modlarıyla başlayın. `CameraRig` üzerinde şu özellikleri açın:

| Özellik | Değer | Gerekçe |
|---|---|---|
| `follow_movement` | `true` | Tıklamayla veya imleçle yönlendirilen koşunun arkasına döner |
| `follow_time` | 1.1 s | Sağlanan sahnenin ayarlanmış dönüş süresi; yeni yöne yumuşakça yaklaşır |
| `follow_toward_camera_angle` | 30° | Neredeyse doğrudan kameraya yönelik koşuda görüntünün çevreye dönmesini önler |
| `sharp_turn_speed` | 360°/s | Karakterin 720°/s dönüş hızının yarısı; yön değiştirirken ara yönleri takip etmez |
| `follow_wait_after_rotate` | `true` | Elle seçilen görüntüyü duruşa veya yeni koşuya kadar korur |
| `follow_pitch` / `follow_pitch_angle` / `follow_pitch_time` | `true` / −22° / 1.1 s | İlerideki rotayı gösteren hafif eğimli görüntüye döner |
| `follow_zoom` / `follow_zoom_level` / `follow_zoom_time` | `true` / 0.55 / 1.5 s | Hareket ederken sağlanan ilk yakınlaştırma düzeyine döner |

Açılar, yakınlaştırma ve süreler sağlanan sahneyle demo ayarlarından gelir. Dönüş, eğim hizalama ve yakınlaştırma
hizalaması birbirinden bağımsızdır. Oyuncunun tekerlekle seçtiği yakınlaştırma korunacaksa `follow_zoom` kapalı
kalsın; tekerleğin eğimi de olağan biçimde kontrol etmesi için `follow_pitch` özelliğini de kapalı bırakın.

Demoda bunlar Kamera sekmesindeki **Kamerayı koşu yönüne çevir**, **Koşarken kamera eğimini hizala** ve
**Koşarken kamera yüksekliğini hizala** anahtarlarıdır. Varsayılan hedef değerleri tablodakilerle zaten eşleşir.

Sağ tuşla elle döndürme, otomatik takipten önceliklidir. WASD sağ tuşu gerektirdiğinden kamera sağ tuş + WASD
hareketinin arkasına kendiliğinden dönmez. Kamerayı elle döndürdükten sonra yalnızca sağ tuşu bırakmak beklemeyi
bitirmez: durun, yeni hedefe tıklayın veya yeni bir basılı tutma başlatın. Sahnedeki
`run_requested → end_follow_wait` bağlantısını ve `keep_aim_on_camera_turn = true` değerini koruyun. Aksi halde
takip beklemeye devam edebilir veya kamera hareketi basılı imlecin yönünü değiştirebilir.

**Deneyin:** Görüntünün enine koşun, 90° dönün, sonra kameraya doğru yön değiştirin. İlk dönüş kamerayı rotanın
arkasına getirmeli; tersine dönüş kamerayı çevresinde döndürmemelidir. Koşarken kamerayı elle döndürüp sağ tuşu
bırakın: seçtiğiniz görüntü duruşa veya yeni koşuya kadar kalmalıdır. Kamera kolunu denetlemek için aynı diziyi
duvar yakınında uygulayın.

Tek başına kullanılan bir kahramanda bu profili etkinleştiren kod şöyledir. Kahramanın çocukları hazır olduktan
sonra oyun sahnenizin `_ready()` yönteminde çalıştırın:

```gdscript
extends Node3D

@onready var hero: PlayableHero = $Hero


func _ready() -> void:
    hero.place_at($Spawn, false)
    var rig := hero.camera_rig
    rig.follow_movement = true
    rig.follow_time = 1.1
    rig.follow_toward_camera_angle = deg_to_rad(30.0)
    rig.sharp_turn_speed = deg_to_rad(360.0)
    rig.follow_wait_after_rotate = true
    rig.follow_pitch = true
    rig.follow_pitch_angle = deg_to_rad(-22.0)
    rig.follow_pitch_time = 1.1
    rig.follow_zoom = true
    rig.follow_zoom_level = 0.55
    rig.follow_zoom_time = 1.5
```

Bu örnek, kahramanın hareket ve girdi ayarlarının değiştirilmediğini varsayar. Tam demoda kaydedilmiş ayarlarla
kontrollerin uyumlu kalması için bunun yerine ayarlar menüsünü veya `Settings.set_value()` yöntemini kullanın.

## İsteğe bağlı: süzülen kahraman

Üç yapılandırmanın herhangi biri mevcut süzülme düzenini kullanabilir: `Character/Visual/Hover.enabled = true`
ayarlayın veya demoda **Karakter → Yerden yüksekte süzül** seçeneğini açın. `height = 0.35 m`, `glide_time = 0.3 s`
ve atanmış `player_floating_fall.tres` kaynağını (düşüş yerçekimi ölçeği 0.5, en yüksek düşüş hızı 2 m/s) koruyun.

Model süzülür; çarpışma gövdesi basamakları geçmeye ve düşmeye devam eder. Bu boşlukların üzerinden uçuş sağlamaz.
Zıplama aynı yüksekliğe çıkar, sonra daha yavaş iner. Süzülürken ayak adımı olayları durur ve 2 m/s hızındaki yumuşak
iniş, varsayılan 2.5 m/s iniş olayı eşiğinin altındadır. Gövdenin çarpışma şekli yükselen modelle birlikte büyümez:
alçak tavanları deneyin. Model ve düşüş ayrıntıları: [Karakterler](systems/characters.md) ve
[Hareket](systems/locomotion.md).

## Yapılandırmayı bozmadan ince ayar

- **Değerler farklı olacaksa kaynakları ayrı tutun.** Bir karakteri düzenlemeden önce Inspector'da hareket
  ayarları kaynağını benzersiz yapıp yeni adla kaydedin. Hareket düğümü sahne ağacına girmeden önce başka bir kaynak
  atayın. Çalışma zamanında mevcut kaynağın alanlarını düzenleyin: `_ready()` sonrasında `mover.settings` kaynağını
  değiştirmek, `GroundMotion` tarafından zaten tutulan kaynağı değiştirmez.
- **Hızla frenlemeyi birlikte değiştirin.** `acceleration_time` ve `stop_time`, temel hızdaki sürelerdir. Depar aynı
  ivmeyi ve frenlemeyi kullanır. Bu yüzden 1.5× hızlı deparın durması da 1.5× uzun sürer: 0.22 sn yerine yaklaşık
  0.33 sn. İdeal düz çizgi durma mesafesi 5.5 m/s için yaklaşık 0.61 m, 8.25 m/s için 1.36 m'dir. Kenarlarda yer
  bırakın.
- **Kamera dönüşü algılamasını hareketle eşleştirin.** `sharp_turn_speed` değerini
  `LocomotionSettings.turn_speed` değerinin yarısında veya altında tutun. Bu kamera eşiğini gözden geçirmeden
  karakterin dönüş hızını düşürmeyin.
- **Gövdeyi, korumayı ve navigasyonu birlikte ayarlayın.** Kapsül boyutunu, en yüksek basamak boyunu veya eğim
  sınırını değiştirirseniz navigasyon yarıçapını, yüksekliğini, çıkılabilir basamağı ve eğimi gözden geçirip örgüyü
  yeniden pişirin. Korumanın düşüş sınırı amaçlanan merdivenlere hâlâ izin vermelidir. Fizik katmanları ile
  navigasyon katmanları ayrı ayarlardır.
- **Bir davranışı değiştirip ilgili denemeyi yineleyin.** Sorunun rota, çarpışma, girdi veya kamera kaynaklı olduğunu
  anlamak için demodaki **Karakter yol çizgisi** ve **Karakter durumu ve olaylar** panellerini kullanın. Başlangıç
  düzenini bellekten yeniden kurmaya çalışmak yerine bir temel sahne kaydedin.

Tüm özellikler: [Girdi](systems/input.md), [Hareket](systems/locomotion.md) ve [Kamera](systems/camera.md).

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
