<!-- translation of docs/en/integration.md @ 502ddfce7182 -->
# Kendi projenizde kullanma

[← Belge dizini](index.md)

> Bu, [İngilizce orijinalin](../en/integration.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Demonun hareketini ve kamerasını başka bir projeye taşımak istiyorsanız hazır kahramanla başlayın. Zaten bir karakter
kontrolcünüz varsa veya yalnızca kamera gerekiyorsa ayrı bileşenleri kullanın. Betikler sıradan GDScript sınıflarıdır
(`class_name`); etkinleştirilecek bir editör eklentisi veya zorunlu `Settings` otomatik yüklemesi yoktur.

| İstediğiniz | Nereden başlamalı |
|---|---|
| Çalışan kahraman, girdi ve kamera | [Demonun kahramanını aktarın](#demonun-kahramanını-projenize-aktarma), sonra [yapılandırma seçin](configurations.md) |
| Var olan karaktere kamera | [Kamera tek başına](#kamera-tek-başına) |
| Projenin hareket sistemi, kendi modeliniz | [Hazır gövde](#hazır-gövdeyle-tıklayarak-hareket), sonra [model değişimi](systems/characters.md) |
| Kendi kontrolcünüz veya yapay zekânız için yol izleme | [Kendi gövdeniz](#kendi-gövdeniz) ve [hareket düğümüne komut verme](#hareket-düğümüne-komut-verme) |

Aşağıdaki dosya yolları `project.godot` dosyasının bulunduğu proje köküne göredir. Godot içindeki `res://` yolu da
aynı konumu belirtir. İlk çalışan kuruluma kadar sağlanan klasör düzenini koruyun.

## Eklentiler

| Eklenti | Sınıflar | Gereksinimler |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` girdi eylemleri; kol için fizik katmanları |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | Dünyada pişirilmiş bir `NavigationRegion3D` (yoksa karakter noktaya düz koşar). Girdi için: herhangi bir `Camera3D` ve `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` eylemleri |
| `ground_character` | `GroundCharacter`, `FallSettings`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterHover`, `DampedSpring`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. Tuşlar için `sprint` ve `jump` eylemleri. Sesler için kendi dosyalarınız veya `shared/audio/character/`. El sallanması ve değiştirilebilir modeller için −Z yönüne bakan, el düğümü bulunan modeller |
| `occluded_silhouette` | `OccludedSilhouette`, gölgelendiricileri ve malzemeleriyle | Hiçbir şey: her modelde çalışır |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | Oyuncunun gövdesi `player` grubunda ve alanların gördüğü bir fizik katmanında |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter`, `InputNames`, `ActionTexts` | Yerleşik `ui_cancel`; `UiRoot` pencereyi tuşla açacaksa `toggle_settings` eylemi. Tuş adları sizin Input Map'inizden okunur |
| `levels` | `LevelHost`, `LevelPortal`, `SpawnPoint`, `LoadingScreen` | Motor dışında gereksinim yok. Yolcunun gövdesi `player` grubunda ve portalların gördüğü fizik katmanında olmalı |

Her eklenti klasöründe kurulumunu anlatan bir `README.md` ve `LICENSE` dosyasının bir kopyası bulunur. Bir eklentiyi
bütün olarak alın: içindeki sınıflar birbirine türüyle başvurur ve kullanmadığınız bir dosya zarar vermez. Klasörleri
`res://addons/iso_orbit/<addon>/` konumunda tutun: içlerindeki sahneler ve malzemeler dosyalarına bu yollarla
başvurur. Bir eklentiyi başka bir yere koymak için onu editörün DosyaSistemi (FileSystem) panelinde taşıyın; panel
başvuruları günceller.

HUD öğeleri (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) görünümlerini demonun teması `shared/ui/ui_theme.tres`
içindeki aynı adlı tema türü varyasyonlarından alır; bunlar olmadan varsayılan temayı kullanırlar.

Demoya özgü olduğu için eklentilerde bulunmayanlar: ayar sistemi (`gdscript/settings/game_settings.gd` ve
`gdscript/ui/settings/` içindeki pencere; bkz. [Ayarlar](#ayarlar)), bu pencereyle kurulmuş bir `UiRoot` içeren
`gdscript/ui/ui_root.tscn`, demo karakterini kullanan oynanabilir kahraman
(`gdscript/player/playable_hero.tscn`; bkz. [Oynanabilir kahraman](#oynanabilir-kahraman)), yolculuk teklifi
(`gdscript/ui/travel_prompt.tscn`), oyun kabuğu `gdscript/main.gd` ve demoyu birleştiren `gdscript/demo/hud.gd` ile
`settings_applier.gd`.

## Kamera tek başına

Kamera herhangi bir `Node3D` hedefiyle çalışır ve yalnızca `addons/iso_orbit/orbit_camera/` gerektirir.

1. Sahneye, hedefin içine değil yanına, `orbit_camera_rig.gd` betikli bir `Node3D` ekleyin.
2. Ona `camera_arm.gd` betikli bir alt `Node3D` ekleyin, onun altına da bir `Camera3D` ekleyin.
3. Düzeneğin `target` özelliğine hareket eden gövdeyi, `arm` özelliğine kol düğümünü atayın. Kameranın **Current**
   özelliğini açın. Yakından saydamlaşacak model kökünü kolun `fade_target` özelliğine atayın veya boş bırakın.
4. [Proje yapılandırması](project-setup.md) sayfasındaki girdi eylemlerini ve kol için fizik katmanlarını ekleyin.

Kol uzunlukları ile çarpışma yarıçapları anlamlı kalsın diye düzeneği, kolu, kamerayı ve üst düğümlerini `(1, 1, 1)`
ölçeğinde tutun. Kameranın yerel dönüşümünü varsayılan bırakın: kol onu çalışma sırasında yerleştirir. Görüntüyü
değiştirmek için düğüm ölçeğini değil, kadraj özelliklerini kullanın.

Kol olmadan düzeneğin alt düğümü olan bir `Camera3D` de çalışır: kamera bu durumda yakınlaştırmanın belirlediği
mesafede kalır ve duvarların içinden geçer. Düzenek `_process` içinde hedefin enterpole edilmiş konumundan
güncellenir; bu yüzden hedef fizik tiklerinde hareket ediyorsa projede fizik enterpolasyonunu açın. Ayrıntılar:
[Kamera](systems/camera.md).

## Hazır gövdeyle tıklayarak hareket

`addons/iso_orbit/click_to_move/` ve `addons/iso_orbit/ground_character/` klasörlerini kopyalayın.

1. Seviyeniz için bir navigasyon örgüsü pişirin (`NavigationRegion3D` → **NavigationMesh Pişir** (Bake
   NavigationMesh)). Ajan yarıçapı ve azami tırmanma değeri karakterinize uymalıdır, bkz.
   [Dünya ve navigasyon](systems/world-and-navigation.md).
2. `ground_character.gd` betikli bir `CharacterBody3D` oluşturun: bir çarpışma şekli, modeli içeren (−Z yönüne
   bakan) bir `Visual` düğümü ve şu alt düğümler: `NavigationMover` (`navigation_mover.gd` betikli bir `Node`),
   isteğe bağlı olarak `LedgeGuard` ve `Stamina`. Gövdenin `mover`, `visual`, `ledge_guard` ve `stamina`
   özelliklerini ayarlayın.
3. Hareketlendiriciye bir `LocomotionSettings` kaynağı verin ya da varsayılanlar için boş bırakın.
4. Sahnenin herhangi bir yerine `point_click_move_input.gd` betikli bir `Node` ekleyin ve `mover` ile `camera`
   özelliklerini ayarlayın.
5. Depar ve zıplama için isteğe bağlı olarak, `character` özelliği gövdeye ayarlanmış `character_action_input.gd`
   ekleyin.

`gdscript/player/player.tscn` bu kurulumun kendisidir; ek olarak sesler, el sallanması, süzülme (`Visual/Hover`,
varsayılan olarak kapalı, daha yavaş düşüşle), değiştirilebilir model ve siluet içerir. Onu örnekleyip gerekmeyenleri
çıkarabilirsiniz. `GroundCharacter`, `LedgeGuard` ve `CharacterHover` kurulum hataları oyun başlarken uyarı olarak
yazdırılır.

## Oynanabilir kahraman

`gdscript/player/playable_hero.tscn` oyuncunun kontrol ettiği hazır kahramandır: `player` grubundaki `Character`
olarak `player.tscn`, `PointClickMoveInput`, `CharacterActionInput`, kolu ve kamerasıyla kamera düzeneği, tıklama
işareti ve yol çizgisi, ayarları ve bağlantılarıyla birlikte. Oyun sahnenize seviyelerin yanına, seviyenin içine
değil, bir kez ekleyin. `playable_hero.gd` yalnızca eklenti sınıflarını kullanır:

- `place_at(marker)` ve `teleport(position, facing)` kahramanı anında başka yere koyar: sürmekte olan basış unutulur,
  karakter sarsıntısız yerleşir (`GroundCharacter.teleport()`), kamera kahramanın baktığı yöne çevrilip yerine oturur.
  Demodaki başlangıç gibi kameranın açısını korumak için `turn_camera` değerini false yapın.
- `controls_enabled = false`, hareket girdisini, deparı ve zıplamayı kapatır. Kamera kontrol edilebilir kalır;
  önceden tıklanan hedefe koşu sürer. Frenlemek için ayrıca `character.mover.stop()`, yatay hareketi hemen kesmek
  için `halt()` çağırın. Sahne ağacını duraklatmak ayrı bir işlemdir.
- Parçalar türü belirtilmiş özelliklerdir: `character`, `input`, `actions`, `camera_rig`, `camera_arm`, `camera`,
  `click_marker`, `path_view` ve karakterin `sounds`, `appearance`, `hover`, `silhouette` alanları.

Kendi modeliniz için `player.tscn` yerine kendi karakterinizin konduğu bir sahne kopyası oluşturun veya parçaları
elle birleştirin. Kamera için önemli iki bağlantı: `PointClickMoveInput.hold_pending_changed` →
`OrbitCameraRig.set_follow_paused` ve `PointClickMoveInput.run_requested` → `OrbitCameraRig.end_follow_wait`
(kamera, elle döndürmeden sonra yeni koşuyu bekler). Diğer dört bağlantı tıklama işaretini gösterip gizler; bkz.
[Mimari](architecture.md#sahnede-kurulan-bağlantılar). Kameranın `sharp_turn_speed` değerini karakter dönüş hızının
yarısında veya altında tutun; bunu yalnızca `PlayableHero` denetleyip uyarır.

## Demonun kahramanını projenize aktarma

Test edilen demoyla aynı kurulum için Godot 4.7.2, Jolt Physics ve Forward+ kullanın. Küçük bir test seviyesiyle
başlayın; kendi modellerinizi, seviyelerinizi ve ayarlarınızı kopyalanan kahraman orada çalıştıktan sonra ekleyin.

1. **Dosyaları aynı yollara kopyalayın.** Klasör düzenini koruyarak projenize şunları alın:
   - `addons/iso_orbit/click_to_move/`, `ground_character/`, `orbit_camera/` ve `occluded_silhouette/`;
   - `gdscript/player/`: kahraman, karakter, kahraman betiği ve karakter ayar kaynakları;
   - `shared/characters/`: on model, asaları, kitapları ve malzemeleri;
   - `shared/audio/character/`: ayak sesleri, zıplama, iniş ve depar sesleri;
   - `shared/world/materials/wood.tres` ve `dark_wood.tres`: Druid ve Battle Mage karakterlerinin ahşap parçaları
     bunlardan yapılır. Dünya malzemeleriyle birlikte dururlar; yalnız `shared/characters/` kopyası bunları kaçırır.

   Bu dosyaların yanındaki `.uid` ve `.import` dosyalarını da alın: sahneler betikleri ve sesleri bu kimliklerle ve
   yollarla bulur. `.godot/` klasörünü almayın; editör dosyaları kendisi içe aktarır. Sahneler dosyalara bu
   yollardan başvurur. Başka konum kullanacaksanız önce kopyalayıp sonra editörün FileSystem panelinde taşıyın;
   başvuruları günceller.
2. **Projeyi ayarlayın** (Project Settings); bkz. [Proje yapılandırması](project-setup.md):
   - `move_to_cursor`, `camera_rotate`, `camera_zoom_in`, `camera_zoom_out`, `move_forward`, `move_back`, `move_left`,
     `move_right`, `sprint` ve `jump` girdi eylemleri. Eksik eylemi kullanan bileşen başlangıçta bir kez bildirir;
     ilgili tuş veya düğme çalışmaz.
   - `navigation/3d/default_cell_height` = 0.025: sonraki adımdaki navigasyon örgüsüyle eşleşir. Harita ve ona
     atanmış bütün örgüler aynı hücre boyutlarını kullanmalıdır.
   - Fizik enterpolasyonu açık (`physics/common/physics_interpolation`): kamera karakterin enterpolasyonlu konumunu
     izler. Kahraman Jolt Physics (`physics/3d/physics_engine`) ile denetlenmiştir.
   - Fizik katmanları: kahraman gövdesi 2. katmanda, 1 ve 4 ile çarpışır; tıklama zemini 1. katmanda arar; kamera
     kolu 1 ve 3'te durur. Adları değil, sayıları önemlidir: zemini ve duvarları 1. katmana koyun veya sahne
     kopyanızdaki maskeleri değiştirin.
3. **Test seviyesi oluşturun.** Bir `NavigationRegion3D` altında `StaticBody3D` zemin kurun: görünür `BoxMesh` ve
   `BoxShape3D` çarpışması 20 × 1 × 20 m olsun; merkezleri `(0, -0.5, 0)`, üst yüzey Y = 0. `(0, 1, -4)`
   merkezli 2 × 2 × 2 m kutu engel ekleyin; örgü ve çarpışma şekli eşleşsin, katman 1 olsun. Engel,
   `(0, 0, 4)` konumundaki Spawn'dan `(0, 0, -8)` hedefine doğrudan yolu kapatır. Bir ışık ve isterseniz
   `(5, 0.1, 0)` merkezli 3 × 0.2 × 3 m basamak ekleyin. Tek başına görünür örgü çarpışma sağlamaz.
4. **Navigasyon örgüsü oluşturup pişirin.** Bölgeyi seçin, yeni `NavigationMesh` atayın ve şunları ayarlayın:

   | Özellik | Test seviyesi değeri | Gerekçe |
   |---|---|---|
   | Parsed Geometry Type | Static Colliders | Gövdeyi engelleyen geometriyi pişirir |
   | Geometry Collision Mask | katman 1 | Kahramanı değil, zeminle engeli içerir |
   | Agent Radius | 0.5 m | 0.35 m yarıçaplı kapsül çevresinde boşluk |
   | Agent Height | 1.8 m | En azından kapsülün tüm yüksekliği; en alçak tavanı kontrol edin |
   | `filter_walkable_low_height_spans` | `true` | Agent Height değerinden az boşluğu olan zeminleri çıkarır |
   | Agent Max Climb | 0.3 m | `Character.max_step_height` ile eşleşir |
   | Agent Max Slope | 40° | Gövdenin 45° zemin sınırının altında |
   | Cell Height / Cell Size | 0.025 m / 0.25 m | İnce dikey basamaklar; navigasyon haritasının ayarıyla eşleşmeli |

   Zemini ve engeli **bölgenin altında** tutup **Bake NavigationMesh** düğmesine basın ve sahneyi kaydedin.
   Demodaki mevcut örgüler 1.75 m etmen yüksekliği kullanır; alçak yükseklik filtresi kapalıdır. Tavanlı yeni
   seviyede çarpışmanın tam yüksekliğini kullanıp filtreyi açın. Navigasyon fizik çarpışmasının yerini almaz.
   Kullanılabilir yol yoksa bu hareket düğümü hedefe doğrudan gitmeye dönebilir; bu durumda duvarların çevresinden
   rota bulamaz. Ayrıntılar: [Dünya ve navigasyon](systems/world-and-navigation.md#fizik-katmanları-ve-navigasyon).
5. **Kahramanı bölgenin yanına örnekleyin** ve adını `Hero` koyun. `(0, 0, 4)` noktasına `Spawn` adlı `Marker3D`
   ekleyin. Kahraman kökünün ölçeğini `(1, 1, 1)` ve kamerasını geçerli tutun. Sahne şu kadar küçük olabilir:

   ```text
   Game (Node3D)
   ├── NavigationRegion3D
   │   ├── Ground (çarpışma ve örgü içeren StaticBody3D)
   │   └── Obstacle (çarpışma ve örgü içeren StaticBody3D)
   ├── Hero (playable_hero.tscn örneği)
   ├── Spawn (Marker3D)
   └── DirectionalLight3D
   ```

   Şu betiği `Game` düğümüne ekleyip sahneyi çalıştırın:

   ```gdscript
   extends Node3D

   @onready var hero: PlayableHero = $Hero


   func _ready() -> void:
       hero.place_at($Spawn, false)
   ```

   `false` kameranın ilk 45° dönüş açısını korur; kamerayı işaretçinin −Z yönüne çevirmek için değeri çıkarın.
   Başlangıçtan sonra **karakteri kahraman API'siyle** yerleştirin veya ışınlayın. `Hero` kökü sabit bir kaptır;
   hareket eden gövdeyi izlemez. Oyuncunun güncel konumu `hero.character.global_position` ile alınır.
6. **Özelleştirmeden önce sonucu deneyin.** Engelin ötesindeki `(0, 0, -8)` yakınına tıklayın: kahraman çevresinden
   dolaşıp durmalıdır. Hedefi görmek için gerekirse uzaklaşın. Sol fare tuşunu basılı tutun: doğrudan yönlendirmeli,
   bırakınca durmalıdır. Sağ tuşla kamera dönüşünü, tekerlekle yakınlaştırmayı, sağ tuş + WASD'yi, Shift'i ve
   Space'i deneyin. Sağlanan hareket kaynağıyla normal hız 5.5 m/s, depar 8.25 m/s, zıplama yüksekliği 1 m'dir;
   0.2 m basamak için zıplamak gerekmez. Hata ayıklayıcıda eksik eylem, kaynak veya kurulum uyarısını kontrol edin.

Kopyalanan sahne, ayar sistemi olmadan demonun varsayılan davranışını kullanır: iki tuş modu da `TURN`; kamera
takibi, eğim/yükseklik hizalaması ve süzülme kapalıdır; depar sesleri kapalıdır. İlk model Necromancer'dır.
Kesin düğüm yolları, varsayılan değer türleri ve iki kullanışlı çeşit için [Yapılandırmalar](configurations.md)
sayfasına bakın.

### Aktarma sorunlarını giderme

| Belirti | Önce neyi kontrol etmeli |
|---|---|
| Global sınıf veya kaynak eksik | Dört eklenti klasörünü ve listelenen varlıkları özgün yollarına kopyalayın; editörün içe aktarmayı bitirmesini bekleyin. İki ahşap malzemesini de alın |
| Kahraman zeminden düşüyor | Zeminde 1. katmanda çarpışma şekli olmalı; yalnızca MeshInstance3D görseldir |
| Tıklama çalışmıyor | Input Map eylemi, etkin kamera, `PlayerInput.camera`, ışının `ground_mask` değeri; üstteki bir Control fare girdisini tüketebilir |
| Kahraman duvarın çevresinden dolaşmıyor | Bölgenin altındaki çarpışmaları pişirin, bölge ve hareket düğümünün navigasyon katmanlarını kontrol edip oluşan örgüyü inceleyin |
| Yol, çıkılamayan bir basamağın üzerinden geçiyor | Çıkılabilir yüksekliği `max_step_height` ile eşleştirip küçük dikey hücrelerle yeniden pişirin; gerçek geometriyi deneyin |
| Sahne düzenlemeleri başlangıçta kayboluyor | Kopyalanmış `SettingsApplier` onları kaydedilmiş ayarlarla değiştirebilir; tek başına kahraman onu gerektirmez |
| Hareket değişince kamera beklenmedik biçimde dönüyor | Karakterin `turn_speed` ve kameranın `sharp_turn_speed` değerlerini karşılaştırın; bkz. [Yapılandırmalar](configurations.md#yapılandırmayı-bozmadan-ince-ayar) |

Bilmekte yarar var:

- Eklentiler ve `playable_hero.gd`, global sınıf adları tanımlar (`GroundCharacter`, `NavigationMover`,
  `OrbitCameraRig`, `PlayableHero` ve [yukarıdaki tablodakiler](#eklentiler)). Projenizde aynı adlı sınıf varsa
  çakışır: ikisinden birini yeniden adlandırın.
- Karakterin dönüş hızını (`LocomotionSettings` içindeki `turn_speed`) değiştirirken
  `CameraRig.sharp_turn_speed` değerini bunun yarısında veya altında tutun. Aksi halde kamera, kameraya doğru
  yön değişimini yana doğru koşu sanıp dönebilir. Eşik dönüş hızının altına düşmezse kahraman başlangıçta uyarır.
- `Settings` otomatik yüklemesi ve ayarlar penceresi gerekmez. HUD kahramana dahil değildir: dayanıklılık çubuğu
  ve yer bildirimi demonun `main.tscn` sahnesinde eklenir; tema notu için bkz. [Eklentiler](#eklentiler).
- Modeller ve sesler de kod gibi projenin MIT lisansı kapsamındadır.

## Seviyeler

`addons/iso_orbit/levels/` klasörünü kopyalayın. Ana sahnede başlangıç seviyesini tek çocuk olarak tutan
`LevelHost`, yanında kahraman ve `loading_screen.tscn` bulunur. Ana betiğiniz sunucunun sinyallerini bağlar:
`level_change_started` geldiğinde kontrolleri kapatın; `level_loaded(level, spawn)` geldiğinde kahramanı `spawn`
noktasına koyun; `level_change_finished` geldiğinde kontrolleri açın. `level_change_failed` geldiğinde de açın
(seviye yerinde kalır ve `level_change_finished` gelmez). `portal_entered` ve `portal_exited` ile yolculuk teklifini
gösterip gizleyin. `gdscript/main.gd` tam olarak bunu yapar. Her seviyede `default` adlı bir `SpawnPoint` gerekir;
portallar hedef sahne yolunu taşıyan `LevelPortal` alanlarıdır.

Kendi seviye sisteminizle yalnızca oynanabilir kahramanı alıp seviyeler hazır olduğunda `place_at()` çağırın; kendi
karakterinizde aynı etki için `GroundCharacter.teleport()` kullanın. Ayrıntılar, varsayılanlar ve ayar birleşimleri:
[Seviyeler](systems/levels.md).

## Kendi gövdeniz

Kendi karakter kontrolcünüzü korumak için yalnızca `addons/iso_orbit/click_to_move/` klasörünü alın. Sözleşme
kısadır:

- `NavigationMover`, gövdenin (herhangi bir `Node3D`) doğrudan alt düğümü olmalıdır. Gövdenin konumunu ve gövdenin
  dünyasındaki navigasyon haritasını okur.
- Gövde her fizik tikinde bir kez, `move_and_slide()` öncesinde `mover.compute_velocity(delta)` çağırır ve sonucun X
  ve Z bileşenlerini uygular. Hareketlendirici gövdeyi asla hareket ettirmez.
- Dikey hız gövdeye kalır: yerçekimi, zıplamalar, geri itme.

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

Bu küçük gövdeye kendi çarpışma şekli, zemin ve görüntülemek için kamera gerekir; `Visual` altına model ekleyin.
Hareket yönüne bakması için o düğümün −Z yönünü dünya uzayındaki `mover.get_facing()` yönüne döndürün. Kendi gövde
uygulamanızı tutmanız gerekmiyorsa `GroundCharacter`, döndürülmüş üst düğümde bile görsel yönü zaten yönetir.

`LedgeGuard` isteğe bağlıdır ve `addons/iso_orbit/ground_character/` gerektirir: gövdeye çocuk olarak ekleyip
`move_and_slide()` öncesi `velocity = ledge_guard.constrain(velocity, delta)` uygulayın. Depar için
`mover.sprinting = true` ayarlayın; hız sınırı `LocomotionSettings.sprint_speed_multiplier` katına çıkar.
`GroundCharacter` içindeki diğer işlevler (zıplama, dayanıklılık, basamaklar, durum ve sinyaller, modelin yumuşak
dönüşü) artık size kalır.

## Hareket düğümüne komut verme

Bir karakteri her şey yönetebilir: oyuncu girdisi, yapay zekâ, bir ara sahne veya ağ kodu.

| Çağrı | Etki |
|---|---|
| `move_to(point)` | Küresel bir noktaya navigasyon yolunu izler. Erişilemeyen hedef, en yakın erişilebilir yol noktasında bitebilir; boş yol doğrudan harekete döner. Yeni hedef eskisine `retarget_tolerance` (0.1 m) değerinden yakınsa yolu yeniden kurmaz |
| `steer(direction, facing = Vector3.ZERO)` | Aksi söylenene kadar yolsuz olarak bir yöne koşar; `facing` verilirse hareket ederken o yöne bakar (yana adım) |
| `stop()` | Karakterin bulunduğu yerde yumuşakça frenler |
| `halt()` | Anında durur, örneğin bir ışınlanmadan sonra |
| `face(direction)` | Duran karakteri hemen döndürür; örneğin doğuş noktasında |

Karakterin tamamını başka yere koymak için `GroundCharacter.teleport(position, facing)` çağırın: hareket düğümünü
anında durdurur, karakteri ve modelini döndürür, izleyenler için gövdeyi sarsıntısız taşır.

Sinyaller: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (`steer()` veya `stop()`
yüzünden noktadan vazgeçildi). Sorgular: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Ayrıntılar: [Hareket](systems/locomotion.md).

## Bir NPC

`player.tscn` sahnesini (ya da hareketlendiricisi olan kendi gövde sahnenizi) örnekleyin ve yalnızca oyuncuya özgü
`Silhouette` ve `Appearance` düğümlerini kaldırın. Girdi düğümlerini eklemeyin: yapay zekânızdan
`NavigationMover.move_to()` çağırın ve `arrived` sinyalini dinleyin. Demonun karakter modellerinden birini kullanmak
için onu `Visual/Hover` altına `Model` adıyla koyun. NPC'yi editörde döndürmek ilk bakış yönünü belirler; daha sonra
`GroundCharacter.teleport(position, facing)` veya `NavigationMover.face()` döndürür. Demo seviyesinde duran NPC'ler
karakter değil, statik gövdelerdir; bkz.
[Dünya ve navigasyon](systems/world-and-navigation.md).

## Ayarlar

Bileşenler ayarları hiçbir zaman okumaz: her biri kendi dışa aktarılmış özelliklerini okur. Bunları ayarlar
menünüzde sunmak için bir ayar değiştiğinde özellikleri kendi kodunuzdan ayarlayın.
`gdscript/demo/settings_applier.gd` bir örnektir: tek bir `match` her ayar anahtarını bir düğüm özelliğine eşler.
Demonun ayarlar sistemini de yeniden kullanmak için `gdscript/settings/game_settings.gd` dosyasını kopyalayın, onu
`Settings` otomatik yüklemesi olarak kaydedin, anahtarlarını ve `DEFAULTS` içeriğini kendinizinkilerle değiştirin ve
arayüz öğelerini `gdscript/ui/settings/` içinden alın; bkz. [Arayüz](systems/ui.md#ayarlar).

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
