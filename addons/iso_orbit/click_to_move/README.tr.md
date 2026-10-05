<!-- translation of addons/iso_orbit/click_to_move/README.md @ 29860f203673 -->
# Tıklayarak Hareket

[← Belge dizini (şablon deposu)](../../../docs/tr/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

İzometrik ve yukarıdan bakışlı oyunlar için tıklayarak hareket: zemine tıklayın, karakter navigasyon yolunu
izleyip erişilebilir son noktasında durur; tuşu basılı tutun, imlecin peşinden koşar. Sabit hızlanma ve frenleme,
sınırlı dönüş hızı, dururken anında dönüş. Sağ tuş basılıyken WASD karakteri kameraya göre hareket ettirir.
İmleci izleyen koşu sırasında sağ tuşa basmak koşuyu rotasında tutar; oyuncu etrafa bakabilir.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Hız, hızlanma, frenleme, dönüş |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | Matematik: yön ve kalan mesafe → hız |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`, `halt()`, `face()`; bir hız döndürür, gövdeyi hareket ettirmez |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Fare ve sağ tuş + WASD → hareket düğümü komutları; `cancel()` sürmekte olan basışı unutur |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | Tıklanan noktadaki işaretçi |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | Kalan yol boyunca bir hata ayıklama çizgisi |

Başka bir eklenti gerekmez. Yerçekimi, zıplama ve depar içeren hazır bir gövde için
`addons/iso_orbit/ground_character` ekleyin.

## Kurulum

1. Bu klasörü `res://addons/iso_orbit/click_to_move/` konumuna kopyalayın.
2. Seviyeniz için navigasyon örgüsü pişirin (`NavigationRegion3D`). Etmen boyutunu ve çıkılabilir basamağı gövdenin
   kapsülüne ve basamaklara uyarlayın. Örgü yoksa veya yol sonucu boşsa hareket düğümü istenen noktaya dümdüz
   gider; kısmi yol en yakın erişilebilir noktada bitebilir. Gövdenin yine de çarpışma geometrisi ve şekli gerekir.
3. `NavigationMover` düğümünü karakterin gövdesinin doğrudan alt düğümü olarak ekleyin. Gövde her fizik tikinde bir
   kez, `move_and_slide()` öncesinde `compute_velocity(delta)` çağırır:

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

   `NavigationMover.settings` alanına hareket düğümü ağaca girmeden önce `LocomotionSettings` kaynağı atayın veya
   betik varsayılanlarıyla oluşturması için boş bırakın. Her karakter ayrı ayar istiyorsa **Make Unique** kullanın.
   Çalışırken kaynak alanlarını değiştirmek işe yarar; `_ready()` sonrasında `mover.settings` kaynağını değiştirmek,
   oluşturulmuş `GroundMotion` örneğindeki kaynağı değiştirmez. Merdiven, zıplama ve kenar koruması için kardeş
   eklentideki `GroundCharacter` bileşenini kullanın.

4. Fareyle kontrol için herhangi bir yere `point_click_move_input.gd` betikli bir `Node` ekleyin ve `mover` ile
   `camera` özelliklerini ayarlayın. `move_to_cursor` (sol tuş), `camera_rotate` (sağ tuş) ve `move_forward`,
   `move_back`, `move_left`, `move_right` (WASD) girdi eylemlerine ihtiyaç duyar. Eksik eylem başlangıçta bir kez
   bildirilir ve sonrasında okunmaz. Tıklamalar 1. fizik katmanına isabet eder (`ground_mask`): karakter katmanını
   ve görünmez duvarları bunun dışında tutun; yoksa tıklama onlara isabet edebilir.
   `addons/iso_orbit/orbit_camera` kamerasıyla `hold_pending_changed` sinyalini `set_follow_paused`,
   `run_requested` sinyalini `end_follow_wait` yöntemine bağlayın. Koşarken etrafa bakma
   (`look_around_while_held`), `camera_steer_action` değerinin kamerayı döndüren eylem olmasına bağlıdır
   (düzeneğin `rotate_action` alanı; ikisi de `camera_rotate`).
5. Ya da hareketlendiriciye yapay zekâdan komut verin: `move_to(point)`, `steer(direction)`, `stop()`; ve `arrived`
   sinyalini dinleyin. Bu, istenen nokta erişilemezse ondan önce bitebilen yolun sonuna varıldığını bildirir.

Hazır kahramanın kopyalama tarifi ve sahne ayarları için bu gövdeyi elle kurmak yerine `docs/tr/integration.md`
sayfasını kullanın. İki girdi modu ve kahramanın ayarları `docs/tr/systems/input.md` içinde açıklanır.

## Belgeler

Şablon deposunda: `docs/tr/integration.md`, `docs/tr/systems/locomotion.md` ve `docs/tr/systems/input.md`.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
