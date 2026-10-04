<!-- translation of docs/en/settings.md @ 60ac8a94fbe7 -->
# Ayarlar

> Bu, [İngilizce orijinalin](../en/settings.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

F10 ayarlar penceresini açar ve oyunu duraklatır; Esc veya F10 kapatır. Değişiklikler hemen uygulanır; pencere
kapandığında ve oyundan çıkıldığında `user://settings.cfg` dosyasına kaydedilir. **Tümünü sıfırla** her ayarı
varsayılan değerine döndürür.

Varsayılan değerler `gdscript/settings/game_settings.gd` dosyasındaki `DEFAULTS` içindedir. Demo bunları
`gdscript/demo/settings_applier.gd` içinde düğüm özelliklerine uygular; aşağıda belirtildiği gibi bileşenlerin kendi
özellik varsayılanları farklı olabilir. Ayarlar sisteminin nasıl çalıştığı ve yeni bir ayarın nasıl ekleneceği:
[Arayüz](systems/ui.md#ayarlar).

## Kontroller

| Ayar | Anahtar | Varsayılan | Uygulandığı yer |
|---|---|---|---|
| **Basılı sol tuş**: Doğrudan imlece / Yol boyunca noktaya | `gameplay/hold_mode` | Doğrudan imlece | `PointClickMoveInput.hold_mode` |
| **Sağ tuş + WASD**: Kapalı / Yana adım / Dönüş | `gameplay/camera_keys_mode` | Dönüş | `PointClickMoveInput.keys_with_camera` (bileşen varsayılanı: yana adım) |
| **Sol + sağ tuş + A/D**: Kapalı / Yana adım / Çapraz | `gameplay/camera_steer_keys_mode` | Çapraz | `PointClickMoveInput.keys_with_camera_steer` (bileşen varsayılanı: yana adım) |
| **Geri yürürken (S) yavaşlama** %0…80, yalnızca yana adımda | `gameplay/backward_slowdown` | %30 | `LocomotionSettings.backward_speed_multiplier` = 1 − değer |
| **Basılı sol tuşla koşarken imleci gizle** | `gameplay/hide_cursor_on_hold` | açık | `PointClickMoveInput.hide_cursor_while_held` |

## Karakter

| Ayar | Anahtar | Varsayılan | Uygulandığı yer |
|---|---|---|---|
| **Kahraman görünümü**: ondan biri | `character/look` | 10 · Savaş Büyücüsü | `CharacterAppearance.set_look()` |
| **Kenarlardan düşmeyi önle** | `gameplay/ledge_guard` | açık | `LedgeGuard.enabled` |
| **Zıplama (Boşluk)** | `character/jump` | açık | `GroundCharacter.can_jump` |
| **Zıplama yüksekliği** 0,5…1,5 m | `character/jump_height` | 1,0 m | `GroundCharacter.jump_height` |
| **Depar (Shift)** | `character/sprint` | açık | `GroundCharacter.can_sprint` |
| **Shift**: Basılı tut / Bas: açık, tekrar: kapalı | `character/sprint_mode` | Basılı tut | `CharacterActionInput.sprint_mode` |
| **Hız artışı** +%10…+%100 | `character/sprint_bonus` | +%50 | `LocomotionSettings.sprint_speed_multiplier` = 1 + değer |
| **Depar yorgunluğu** | `character/fatigue` | açık | `GroundCharacter.sprint_tires` |
| **Dayanıklılık süresi** 3…10 sn | `character/sprint_duration` | 5,0 sn | `GroundCharacter.sprint_duration` |

Kenar koruması düğmesi Karakter sekmesine taşındıktan sonra ayar anahtarı `gameplay/ledge_guard` olarak kaldı; böylece
kaydedilmiş bir seçim kaybolmaz.

## Kamera

| Ayar | Anahtar | Varsayılan | Uygulandığı yer |
|---|---|---|---|
| **Sağ tuş kamerayı yukarı ve aşağı eğer** | `camera/mouse_pitch` | kapalı | `OrbitCameraRig.mouse_pitch` |
| **Kamerayı koşu yönüne çevir** | `camera/follow` | kapalı | `OrbitCameraRig.follow_movement` |
| **Kamera eğimini hizala** | `camera/align_pitch` | kapalı | `OrbitCameraRig.follow_pitch` |
| **Aşağı eğim** 8…80° | `camera/align_pitch_angle` | 22° | `OrbitCameraRig.follow_pitch_angle` = −değer (bileşen varsayılanı: −40°) |
| **Yetişme süresi** 0…10 sn (0'da "anında"), dönüş ve eğim için | `camera/follow_time` | 1,1 sn | `OrbitCameraRig.follow_time` (bileşen varsayılanı: 1,5 sn) |
| **Kamera dönerken imleç hedefini korur** | `camera/keep_aim` | açık | `PointClickMoveInput.keep_aim_on_camera_turn` |
| **Kamera arkasındaki engellerde durur** | `camera/keep_out_of_geometry` | açık | `CameraArm.keep_out_of_geometry` |
| **Karakter gizlenince yaklaş** | `camera/pull_in_on_occlusion` | kapalı | `CameraArm.pull_in_on_occlusion` |

## Görüntü

| Ayar | Anahtar | Varsayılan | Uygulandığı yer |
|---|---|---|---|
| **Tam ekran** | `display/fullscreen` | kapalı | `DisplayServer.window_set_mode()` |
| **FPS sınırı**: 24, 30, 60, 120, 240, Sınırsız | `display/max_fps` | Sınırsız | `Engine.max_fps` |
| **Dikey senkronizasyon (V-Sync)** | `display/vsync` | kapalı | `DisplayServer.window_set_vsync_mode()` |
| **Fizik enterpolasyonu (karakter ve kamera)** | `display/physics_interpolation` | açık | `SceneTree.physics_interpolation` |
| **Engel arkasında siluet konturu** | `display/silhouette_outline` | açık | `OccludedSilhouette.outline_enabled` |

Tam ekran, oyun editörün içinde, Oyun (Game) sekmesinde ya da onun kayan penceresinde (**Make Game Workspace Floating on
Next Play**) çalışırken işe yaramaz: pencere editöre aittir, bu yüzden orada anahtar devre dışıdır. Editörden denemek
için Oyun sekmesinin menüsünde **Embed Game on Next Play** seçeneğini kapatın: oyun o zaman kendi penceresinde açılır.

V-Sync açıkken kare sayısı hiçbir zaman monitörün yenileme hızını aşmaz; bu yüzden bu hıza eşit veya daha yüksek bir
FPS sınırı hiç uygulanmaz: V-Sync ile çakışır ve monitörün gösterdiğinden daha az kare verirdi (240 Hz monitörde 240
sınırı yaklaşık 220 kare veriyordu).

Fizik enterpolasyonu olmadan karakter ve kamera tikten tike (saniyede 60) kesik kesik hareket eder: kamera hedefin
`get_global_transform_interpolated()` değerini izler ve bu değer enterpolasyon olmadan yalnızca hedefin son tikteki
konumudur. 60 Hz'den hızlı bir monitörde bu fark edilir; kamera koşuyu takip ederken karakter dönüşlerde ayrıca
sallanır: kamera her karede, karakter yalnızca her tikte döner.

## Arayüz

| Ayar | Anahtar | Varsayılan | Uygulandığı yer |
|---|---|---|---|
| **Dil**: English, Español, 日本語, Português (Brasil), Русский, Türkçe, 简体中文 | `interface/language` | English | `TranslationServer.set_locale()` |
| **Arayüz ölçeği** %50…100 | `interface/ui_scale` | %75 | Kök pencerenin `content_scale_factor` özelliği |
| **FPS sayacı** | `interface/fps_counter` | açık | `Hud/FpsCounter` görünürlüğü |
| **Kontrol ipuçları ve hız** | `interface/help` | açık | `Hud/Panel` görünürlüğü |
| **Karakter yol çizgisi** | `interface/path_line` | kapalı | `PathView` görünürlüğü |

Arayüz ölçeği 3B görünümü değil; ipucu panelini, FPS sayacını, dayanıklılık çubuğunu ve pencereleri değiştirir. %100,
sahnelerde tasarlandığı hâliyle boyuttur.

## Ses

| Ayar | Anahtar | Varsayılan | Uygulandığı yer |
|---|---|---|---|
| **Ses düzeyi** %0…100 (0'da "kapalı") | `sound/volume` | %100 | `Master` veri yolunun ses düzeyi; 0 sesi kapatır |
| **Ayak sesleri** | `sound/footsteps` | açık | `CharacterSounds.footsteps_enabled` |
| **Zıplama ve iniş** | `sound/jump` | açık | `CharacterSounds.jump_enabled` |
| **Depar başlangıcı ve depar** | `sound/sprint` | kapalı | `CharacterSounds.sprint_enabled` |

## Bağımlı ayarlar

Başka bir ayar olmadan anlamsız kalan öğeler soluk görünür ve değiştirilemez: Sağ tuş + WASD için yana adım modu
olmadan geri yavaşlama, zıplama olmadan zıplama yüksekliği, depar olmadan deparla ilgili her şey, yorgunluk olmadan
dayanıklılık süresi, eğim hizalama olmadan eğim açısı ve ne takip ne de eğim hizalama açıkken yetişme süresi.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
