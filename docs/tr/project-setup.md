<!-- translation of docs/en/project-setup.md @ 6e49af9494f6 -->
# Proje yapılandırması

> Bu, [İngilizce orijinalin](../en/project-setup.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Bileşenlerin `project.godot` dosyasından ve sahneden bekledikleri. Bileşenleri başka bir projeye taşırken bu
yapılandırmanın onların kullandığı kısımlarını kopyalayın.

## Fizik katmanları

| Katman | Ad | Üzerinde ne var | Kim okur |
|---|---|---|---|
| 1 | `world` | Zemin, duvarlar, dekor nesneleri, dağ, seviyede duran NPC'ler | Tıklama ışını (`PointClickMoveInput.ground_mask`), `LedgeGuard.floor_mask`, `CameraArm.collision_mask`, navigasyon örgüsü pişirme |
| 2 | `characters` | Oyuncunun gövdesi (`collision_layer = 2`) | `PointOfInterest` alanları (`collision_mask = 2`); kamera kolu bu katmanı yok sayar |
| 3 | `camera` | Yalnızca kamerayı durduran gövdeler, örneğin `shared/world/props/house.tscn` içindeki `RoofCameraBlocker` | Yalnızca `CameraArm.collision_mask` |

`CameraArm.collision_mask` varsayılan olarak 1. ve 3. katmanlardır (`0b101`). 2. katmandaki karakterler kamerayı
asla itmez. 3. katmandaki bir gövde kamerayı durdurur, ancak tıklamalar, navigasyon ve karakterler için görünmezdir;
böylece kimsenin üzerine yol bulmasına izin vermeden kamerayı bir çatının dışında tutabilirsiniz.

Navigasyon katmanı 1'in adı `ground`; `NavigationMover.navigation_layers` varsayılan olarak bu katmanı kullanır.

## Girdi eylemleri

| Eylem | Varsayılan | Kullanan |
|---|---|---|
| `move_to_cursor` | Farenin sol tuşu | `PointClickMoveInput.move_action` |
| `camera_rotate` | Farenin sağ tuşu | `OrbitCameraRig.rotate_action`, `PointClickMoveInput.camera_steer_action` |
| `camera_zoom_in` | Tekerlek yukarı | `OrbitCameraRig.zoom_in_action` |
| `camera_zoom_out` | Tekerlek aşağı | `OrbitCameraRig.zoom_out_action` |
| `move_forward`, `move_back`, `move_left`, `move_right` | W, S, A, D | Sağ tuş basılıyken `PointClickMoveInput` |
| `sprint` | Shift | `CharacterActionInput.sprint_action` |
| `jump` | Boşluk | `CharacterActionInput.jump_action` |
| `toggle_settings` | F10 | `UiRoot.settings_action` |
| `ui_cancel` | Esc (yerleşik) | `UiRoot`: en üstteki pencereyi kapatır |

Tuşlar fiziksel konumlarına göre atanmıştır; bu yüzden WASD her klavye düzeninde yerinde kalır. Her bileşen eylem
adını dışa aktarılmış bir özellik olarak alır; böylece onların yerine kendi eylemlerinizi kullanabilirsiniz.

## Gruplar

| Grup | Anlamı |
|---|---|
| `player` | Oyuncunun gövdesi. `PointOfInterest` yalnızca bu gruptaki gövdelere tepki verir (`player_group`). `main.tscn` içinde `Player` düğümüne atanmıştır |
| `camera_ignore` | Kamera kolunun içinden geçtiği gövdeler (`CameraArm.ignored_groups`). Bu gruptaki bir düğümün altındaki her şeye uygulanır; bu yüzden grubu bir kez, bir dekor sahnesinin köküne ya da seviyedeki bir klasör düğümüne atayın. Demo bunu kullanmaz |
| `points_of_interest` | Her `PointOfInterest` tarafından kendiliğinden eklenir; `DiscoveryToast` yerleri bu grup üzerinden bulur |

## Otomatik yükleme

`Settings` → `res://gdscript/settings/game_settings.gd`. Yalnızca ayarlar penceresi, onun öğeleri ve
`gdscript/demo/settings_applier.gd` için gereklidir. Bileşenler onsuz çalışır. Bkz. [Ayarlar](settings.md).

## Diğer proje ayarları

| Ayar | Değer | Notlar |
|---|---|---|
| `application/run/main_scene` | `res://gdscript/main.tscn` | Demo |
| `physics/3d/physics_engine` | Jolt Physics | Motora yerleşik; kamera kolu ve testler onunla doğrulanmıştır |
| `navigation/3d/default_cell_height` | 0,025 | Navigasyon örgüsünün hücre yüksekliğini aşmamalıdır; örgünün gövdenin tırmanamayacağı çıkıntıları birleştirmemesi için bu değer 0,025 m'dir; bkz. [Dünya ve navigasyon](systems/world-and-navigation.md) |
| `display/window/stretch/mode` | `canvas_items` | Arayüz ölçeği ayarı tüm 2B öğeleri `content_scale_factor` ile ölçekler ve 3B görünüme dokunmaz |
| `display/window/stretch/aspect` | `expand` | Her pencere biçimi |
| `gui/theme/custom` | `res://shared/ui/ui_theme.tres` | Tüm pencerelerin ve HUD öğelerinin görünümü |
| `internationalization/locale/translations` | `res://l10n/ui/*.po` | Arayüz çevirileri; bkz. [Arayüz](systems/ui.md) |
| `rendering/rendering_device/driver.windows` | `d3d12` | Windows'ta Direct3D 12 |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 5 (Ultra) | Yumuşak gölgeler; `world.tscn` içindeki güneşte ayrıca `shadow_blur = 1.25` ve 70 m gölge mesafesi vardır |
| `rendering/anti_aliasing/quality/msaa_3d` | 2 (4×) | Çoklu örneklemeli kenar yumuşatma |

Fizik, varsayılan olan saniyede 60 tikte çalışır. Fizik enterpolasyonu `project.godot` içinde açıktır
(`physics/common/physics_interpolation`) ve çalışma anında bir ayarla açılıp kapatılır (Ayarlar → Görüntü).

## Kaydedilen veriler

Ayarlar, projenin kullanıcı veri klasöründeki `user://settings.cfg` dosyasına kaydedilir (editörde: Proje →
Kullanıcı Veri Klasörünü Aç, Project → Open User Data Folder). Varsayılanlara dönmek için dosyayı silin ya da ayarlar
penceresinde **Tümünü sıfırla** düğmesini kullanın.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
