<!-- translation of docs/en/integration.md @ 69adeef2aab9 -->
# Kendi projenizde kullanma

> Bu, [İngilizce orijinalin](../en/integration.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Yeniden kullanılabilir bileşenler `addons/iso_orbit/` içindedir, her parça için bir klasör; ortak klasör onları diğer
eklentilerinizden ayrı tutar. İhtiyacınız olan klasörleri projenizin `addons/iso_orbit/` klasörüne kopyalayın,
düğümleri sahnelerinizde bağlayın ve projeyi [Proje yapılandırması](project-setup.md) sayfasında anlatıldığı gibi
ayarlayın. Betikler sıradan GDScript sınıflarıdır (`class_name`): etkinleştirilecek bir editör eklentisi yoktur.

## Eklentiler

| Eklenti | Sınıflar | Gereksinimler |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig`, `CameraArm` | `camera_rotate`, `camera_zoom_in`, `camera_zoom_out` girdi eylemleri; kol için fizik katmanları |
| `click_to_move` | `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `PointClickMoveInput`, `ClickMarker`, `NavigationPathView` | Dünyada pişirilmiş bir `NavigationRegion3D` (yoksa karakter noktaya düz koşar). Girdi için: herhangi bir `Camera3D` ve `move_to_cursor`, `camera_rotate`, `move_forward`, `move_back`, `move_left`, `move_right` eylemleri |
| `ground_character` | `GroundCharacter`, `LedgeGuard`, `Stamina`, `CharacterActionInput`, `CharacterSounds`, `HandSway`, `CharacterAppearance`, `StaminaBar` | `click_to_move`. Tuşlar için: `sprint` ve `jump` eylemleri. Sesler için: kendi sesleriniz ya da `shared/audio/character/`. El sallanması ve değiştirilebilir modeller için: −Z yönüne bakan ve bir el düğümü olan modeller |
| `occluded_silhouette` | `OccludedSilhouette`, gölgelendiricileri ve malzemeleriyle | Hiçbir şey: her modelde çalışır |
| `points_of_interest` | `PointOfInterest`, `DiscoveryToast` | Oyuncunun gövdesi `player` grubunda ve alanların gördüğü bir fizik katmanında |
| `ui_screens` | `UiRoot`, `UiScreen`, `FpsCounter` | Yerleşik `ui_cancel`; `UiRoot` bir pencereyi tuşla açıyorsa `toggle_settings` eylemi |

Her eklenti klasöründe kurulumunu anlatan bir `README.md` ve `LICENSE` dosyasının bir kopyası bulunur. Bir eklentiyi
bütün olarak alın: içindeki sınıflar birbirine türüyle başvurur ve kullanmadığınız bir dosya zarar vermez. Klasörleri
`res://addons/iso_orbit/<addon>/` konumunda tutun: içlerindeki sahneler ve malzemeler dosyalarına bu yollarla
başvurur. Bir eklentiyi başka bir yere koymak için onu editörün DosyaSistemi (FileSystem) panelinde taşıyın; panel
başvuruları günceller.

HUD öğeleri (`StaminaBar`, `DiscoveryToast`, `FpsCounter`) görünümlerini demonun teması `shared/ui/ui_theme.tres`
içindeki aynı adlı tema türü varyasyonlarından alır; bunlar olmadan varsayılan temayı kullanırlar.

Bu demo etrafında kurulu oldukları için eklentilerde olmayanlar: ayarlar sistemi (`gdscript/settings/game_settings.gd`
ve `gdscript/ui/settings/` içindeki ayarlar penceresi, bkz. [Ayarlar](#ayarlar)), `gdscript/ui/ui_root.tscn` (o
pencereyle ayarlanmış bir `UiRoot`) ve demonun yapıştırıcı kodu `gdscript/demo/hud.gd` ile `settings_applier.gd`.

## Yalnızca kamera

Kamera herhangi bir `Node3D` hedefiyle çalışır ve yalnızca `addons/iso_orbit/orbit_camera/` gerektirir.

1. Sahneye, hedefin içine değil yanına, `orbit_camera_rig.gd` betikli bir `Node3D` ekleyin.
2. Ona `camera_arm.gd` betikli bir alt `Node3D` ekleyin, onun altına da bir `Camera3D` ekleyin.
3. Düzeneğin `target` özelliğini ayarlayın. Kolun `fade_target` özelliğini, kamera çok yakınken yarı saydam olması
   gereken düğüme ayarlayın ya da boş bırakın.
4. [Proje yapılandırması](project-setup.md) sayfasındaki girdi eylemlerini ve kol için fizik katmanlarını ekleyin.

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

`gdscript/player/player.tscn` bu kurulumun kendisidir; ek olarak sesler, el sallanması, değiştirilebilir model ve
siluet içerir. Onu örnekleyip ihtiyacınız olmayanları kaldırabilirsiniz.

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
@onready var ledge_guard: LedgeGuard = $LedgeGuard


func _physics_process(delta: float) -> void:
	var planar := mover.compute_velocity(delta)
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity = ledge_guard.constrain(velocity, delta)
	move_and_slide()
	var facing := mover.get_facing()
	$Visual.rotation.y = atan2(-facing.x, -facing.z)
```

`LedgeGuard` isteğe bağlıdır: `addons/iso_orbit/ground_character/` içinden, gövdenin bir alt düğümü. Depar için
`mover.sprinting = true` ayarlayın: hız sınırı `LocomotionSettings.sprint_speed_multiplier` katına çıkar.
`GroundCharacter` içindeki geri kalan her şey (zıplama, dayanıklılık, adım sinyalleri, modelin yumuşak dönüşü) bu
durumda size kalır.

## Hareketlendiriciye komut verme

Bir karakteri her şey yönetebilir: oyuncu girdisi, yapay zekâ, bir ara sahne veya ağ kodu.

| Çağrı | Etki |
|---|---|
| `move_to(point)` | Bir navigasyon yolu boyunca bir noktaya koşar ve tam orada durur. Her tikte çağrılabilir; mevcut noktaya `retarget_tolerance` (0,1 m) değerinden daha yakın bir nokta yolu yeniden oluşturmaz |
| `steer(direction, facing = Vector3.ZERO)` | Aksi söylenene kadar yolsuz olarak bir yöne koşar; `facing` verilirse hareket ederken o yöne bakar (yana adım) |
| `stop()` | Karakterin bulunduğu yerde yumuşakça frenler |
| `halt()` | Anında durur, örneğin bir ışınlanmadan sonra |

Sinyaller: `destination_changed(point)`, `path_changed`, `arrived`, `destination_cancelled` (`steer()` veya `stop()`
yüzünden noktadan vazgeçildi). Sorgular: `is_moving()`, `is_steering()`, `has_destination()`, `get_destination()`,
`get_speed()`, `get_heading()`, `get_facing()`, `get_remaining_path()`. Ayrıntılar: [Hareket](systems/locomotion.md).

## Bir NPC

`player.tscn` sahnesini (ya da hareketlendiricisi olan kendi gövde sahnenizi) örnekleyin ve yalnızca oyuncuya özgü
`Silhouette` ve `Appearance` düğümlerini kaldırın. Girdi düğümlerini eklemeyin: yapay zekânızdan
`NavigationMover.move_to()` çağırın ve `arrived` sinyalini dinleyin. Demonun karakter modellerinden birini kullanmak
için onu `Visual` altına `Model` adıyla koyun. Demo seviyesinde duran NPC'ler karakter değil, statik gövdelerdir; bkz.
[Dünya ve navigasyon](systems/world-and-navigation.md).

## Ayarlar

Bileşenler ayarları hiçbir zaman okumaz: her biri kendi dışa aktarılmış özelliklerini okur. Bunları ayarlar
menünüzde sunmak için bir ayar değiştiğinde özellikleri kendi kodunuzdan ayarlayın.
`gdscript/demo/settings_applier.gd` bir örnektir: tek bir `match` her ayar anahtarını bir düğüm özelliğine eşler.
Demonun ayarlar sistemini de yeniden kullanmak için `gdscript/settings/game_settings.gd` dosyasını kopyalayın, onu
`Settings` otomatik yüklemesi olarak kaydedin, anahtarlarını ve `DEFAULTS` içeriğini kendinizinkilerle değiştirin ve
arayüz öğelerini `gdscript/ui/settings/` içinden alın; bkz. [Arayüz](systems/ui.md#ayarlar).

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
