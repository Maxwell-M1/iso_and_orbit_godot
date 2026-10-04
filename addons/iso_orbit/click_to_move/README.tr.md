<!-- translation of addons/iso_orbit/click_to_move/README.md @ fabef0a2f5e6 -->
# Tıklayarak Hareket

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

İzometrik ve yukarıdan bakışlı oyunlar için tıklayarak hareket: zemine tıklayın, karakter navigasyon örgüsü boyunca
oraya koşar ve tam noktada durur; tuşu basılı tutun, imlecin peşinden koşar. Sabit hızlanma ve frenleme, sınırlı
dönüş hızı, dururken anında dönüş. Sağ tuş basılıyken WASD karakteri kameraya göre hareket ettirir.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `locomotion_settings.gd` | `LocomotionSettings` (Resource) | Hız, hızlanma, frenleme, dönüş |
| `ground_motion.gd` | `GroundMotion` (RefCounted) | Matematik: yön ve kalan mesafe → hız |
| `navigation_mover.gd` | `NavigationMover` (Node) | `move_to()`, `steer()`, `stop()`; bir hız döndürür, gövdeyi asla hareket ettirmez |
| `point_click_move_input.gd` | `PointClickMoveInput` (Node) | Fare ve sağ tuş + WASD → hareketlendirici komutları |
| `click_marker.gd`, `click_marker.tscn` | `ClickMarker` (Node3D) | Tıklanan noktadaki işaretçi |
| `navigation_path_view.gd` | `NavigationPathView` (MeshInstance3D) | Kalan yol boyunca bir hata ayıklama çizgisi |

Başka bir eklenti gerekmez. Yerçekimi, zıplama ve depar içeren hazır bir gövde için
`addons/iso_orbit/ground_character` ekleyin.

## Kurulum

1. Bu klasörü `res://addons/iso_orbit/click_to_move/` konumuna kopyalayın.
2. Seviyeniz için bir navigasyon örgüsü pişirin (`NavigationRegion3D`). Örgü yoksa karakter noktaya düz koşar.
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

4. Fareyle kontrol için herhangi bir yere `point_click_move_input.gd` betikli bir `Node` ekleyin ve `mover` ile
   `camera` özelliklerini ayarlayın. `move_to_cursor` (sol tuş), `camera_rotate` (sağ tuş) ve `move_forward`,
   `move_back`, `move_left`, `move_right` (WASD) girdi eylemlerine ihtiyaç duyar; tıklamalar 1. fizik katmanına
   isabet eder (`ground_mask`).
5. Ya da hareketlendiriciye yapay zekâdan komut verin: `move_to(point)`, `steer(direction)`, `stop()`; ve `arrived`
   sinyalini dinleyin.

## Belgeler

Şablon deposunda: `docs/tr/integration.md`, `docs/tr/systems/locomotion.md` ve `docs/tr/systems/input.md`.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
