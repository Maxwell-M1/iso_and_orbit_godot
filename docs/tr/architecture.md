<!-- translation of docs/en/architecture.md @ 38b9342d8085 -->
# Mimari

> Bu, [İngilizce orijinalin](../en/architecture.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Demo tek bir sahnedir: `gdscript/main.tscn`. Her davranış, tek bir işi olan ayrı bir düğümdür: bileşen kendi dışa
aktarılmış özelliklerini okur, metotlar ve sinyaller sunar ve sahnedeki komşularına düğüm referansları ve sinyal
bağlantılarıyla bağlanır. Kalan birkaç arama yapılandırılabilir: `DiscoveryToast` yerleri grup üzerinden bulur,
`CharacterAppearance` modeli ve elini dışa aktarılmış adlarla bulur, `character` özelliği boş olan `CharacterSounds`
ise üst düğümünü alır.

## Ana sahne

```
Main (Node3D)
├── World              shared/world/world.tscn: seviye, navigasyon örgüsü, yerler ve NPC'ler
├── Player             gdscript/player/player.tscn: GroundCharacter, "player" grubu
│   ├── CollisionShape3D   kapsül, yarıçap 0,35 m, yükseklik 1,8 m
│   ├── Visual             karakterin gittiği yöne çevrilir
│   │   └── Model          geçerli kahraman görünümü; RightHand düğümü asayı tutar
│   ├── Silhouette         OccludedSilhouette: engellerin ardından görülen kahraman
│   ├── Appearance         CharacterAppearance: Visual/Model'i çalışma anında değiştirir
│   ├── RightHandSway      HandSway: sağ eli adımlarla sallar
│   ├── NavigationMover    yollar ve hız
│   ├── LedgeGuard         gövdenin uçurumdan yürüyerek düşmesini önler
│   ├── Stamina            depar rezervi
│   └── Sounds             CharacterSounds ve beş AudioStreamPlayer3D
├── PlayerInput        PointClickMoveInput: fare ve WASD → Player/NavigationMover
├── PlayerActionInput  CharacterActionInput: Shift ve Boşluk → Player
├── CameraRig          OrbitCameraRig: Player'ı izler, yörünge ve yakınlaştırma
│   └── CameraArm      CameraArm: engellerde kısalır
│       └── Camera3D
├── ClickMarker        tıklanan noktada zemindeki halka
├── PathView           NavigationPathView: hata ayıklama yol çizgisi, varsayılan olarak gizli
├── Hud                kontrol ipuçları ve hız, FpsCounter, DiscoveryToast, StaminaBar
├── SettingsApplier    ayarlar → düğüm özellikleri (yalnızca demo)
└── UiRoot             oyunun üstündeki pencereler: ayarlar penceresi
```

`player.tscn` yalnızca karakteri içerir. Girdi düğümleri `main.tscn` içindedir; böylece aynı karakter sahnesi başka
bir şey tarafından yönetilebilir: yapay zekâ, bir ara sahne veya ağdaki bir eş.

## Veri akışı

```
fare, WASD ───► PointClickMoveInput ──move_to(point)────► NavigationMover ──► GroundMotion
                                    ──steer(direction)──► (yol veya           (hızlanma, frenleme,
                                    ──stop()────────────►  yön)                dönüş: düz matematik)
                                                               ▲
                                                               │ compute_velocity(delta)
                                                               │ yatay bir hız döndürür
Shift, Boşluk ─► CharacterActionInput ──sprint_requested──► GroundCharacter ──► LedgeGuard.constrain()
                                      ──jump()────────────►  (CharacterBody3D)  ──► move_and_slide()
                                                                   │
                                    sinyaller: stepped, jumped, landed, sprint_changed
                                                                   ▼
                                                   CharacterSounds, HandSway, başka herhangi bir şey

fare ───► OrbitCameraRig ──► CameraArm ──► Camera3D
          (hedefin enterpole edilmiş konumunu izler, yörünge, yakınlaştırma, isteğe bağlı takip)
```

Girdi gövdeye hiçbir zaman dokunmaz. `NavigationMover` düğümüne komutlar gönderir. Hareketlendirici de gövdeye
dokunmaz: gövde istediğinde bir hız döndürür. Kamera ve girdi birbirinden habersizdir.

## Bir fizik tiki

1. `CharacterActionInput` karakterden önce çalışır (`process_physics_priority = -1`):
   `GroundCharacter.sprint_requested` değerini ayarlar ve `jump()` çağırır; böylece bir tuşa basış gövdeye aynı
   tikte ulaşır.
2. `GroundCharacter._physics_process`, gövdenin hareket ettiği tek yer:
   1. karakterin depar atıp atmayacağına karar verir (istenmiş, izin verilmiş, hareket hâlinde, bitkin değil) ve
      dayanıklılık harcar;
   2. `mover.compute_velocity(delta)` çağırır ve sonucun X ve Z bileşenlerini yatay hız olarak alır;
   3. tamponda bir zıplama varsa ve gövde zemindeyse ya da zeminden yeni ayrıldıysa (çakal süresi, coyote time)
      zıplamayı başlatır;
   4. havadayken `gravity_scale` ile çarpılmış yerçekimini ekler;
   5. karakter zıplamıyorsa, hızı bir kenar boyunca çevirmesi için `LedgeGuard.constrain()` metodunu çağırır;
   6. `move_and_slide()` çağırır;
   7. `landed` ve `stepped` sinyallerini yayar ve `Visual` düğümünü `mover.get_facing()` yönüne çevirir.
3. `HandSway` gövdeden sonra çalışır (`process_physics_priority = 1`) ve eli gövdenin yeni durumuna göre hareket
   ettirir.

`PointClickMoveInput._physics_process`, karakteri kimin yöneteceğine tek bir yerde karar verir: basılı bir fare
tuşu, yoksa sağ tuşla birlikte klavye tuşları. `move_to()`, `steer()` veya `stop()` çağırır. Hareketlendirici son
komutu saklar ve gövde bir sonraki `compute_velocity()` çağrısında onu alır.

Çizilen her karede `OrbitCameraRig._process` kamera düzeneğini hedefin enterpole edilmiş dönüşümüne yerleştirir ve
alt düğümü `CameraArm` hemen ardından güncellenir. `PointClickMoveInput` düğümünde `process_priority = 1` olduğundan
imleç konumunu, kamera o kare için yerine oturduktan sonra düzeltir.

## Bileşenler

Yeniden kullanılabilir bileşenler `addons/iso_orbit/` içindedir; tek başına alınabilen her parça için bir klasör. Her
betik, sınıfının snake case biçimindeki adını taşır: `OrbitCameraRig` için
`addons/iso_orbit/orbit_camera/orbit_camera_rig.gd`.

| Eklenti | Sınıf | Görev |
|---|---|---|
| `orbit_camera` | `OrbitCameraRig` (Node3D) | Bir hedefi izler, sağ tuşla döner, tekerlekle yakınlaştırır, isteğe bağlı olarak koşunun ardından döner |
| | `CameraArm` (Node3D) | Kamerayı ucunda tutar ve engellerde kısalır; çok yakında hedefi saydamlaştırır |
| `click_to_move` | `LocomotionSettings` (Resource) | Hız, hızlanma, frenleme ve dönüş. Tek bir kaynak birçok karakter tarafından paylaşılabilir |
| | `GroundMotion` (RefCounted) | Düğümsüz kinematik: istenen yön ve kalan mesafe → yatay hız |
| | `NavigationMover` (Node) | Navigasyon yolu boyunca tam duruşlu `move_to()`, bir yöne `steer()`, `stop()`; bir hız döndürür, gövdeyi asla hareket ettirmez |
| | `PointClickMoveInput` (Node) | Fare ve sağ tuş + WASD → hareketlendirici komutları; imleci gizler ve yeniden hedefler |
| | `ClickMarker` (Node3D) | Tıklanan noktadaki işaretçi (`click_marker.tscn`) |
| | `NavigationPathView` (MeshInstance3D) | Hareketlendiricinin kalan yolunu çizer |
| `ground_character` | `GroundCharacter` (CharacterBody3D) | Yerçekimi, zıplama, dayanıklılıkla depar, `move_and_slide()`, modeli döndürme; adımlar, zıplamalar, inişler ve depar için sinyaller |
| | `LedgeGuard` (Node) | Gövdeyi bir uçurumda durdurur ya da kenar boyunca kaydırır |
| | `Stamina` (Node) | Harcanan ve yenilenen bir rezerv; onu neyin harcadığını bilmez |
| | `CharacterActionInput` (Node) | Depar ve zıplama tuşları → karakter |
| | `CharacterSounds` (Node3D) | Karakterin sinyallerine göre sesler çalar |
| | `HandSway` (Node) | Bir el düğümünü adımlarla sallar; kalkışlarda, duruşlarda, dönüşlerde ve inişlerde ataletle |
| | `CharacterAppearance` (Node) | Karakter modelini çalışma anında değiştirir |
| | `StaminaBar` (ProgressBar) | HUD'un dayanıklılık çubuğu (`stamina_bar.tscn`) |
| `occluded_silhouette` | `OccludedSilhouette` (Node) | Bir şey karakteri gizlediğinde onu siluet olarak çizer; gölgelendiricileri ve malzemeleri aynı klasördedir |
| `points_of_interest` | `PointOfInterest` (Area3D) | Keşfedilecek bir yer: oyuncu ilk kez girdiğinde `discovered(title)` sinyalini yayar |
| | `DiscoveryToast` (Label) | Ekranda birkaç saniye "Keşfedildi: …" (`discovery_toast.tscn`) |
| `ui_screens` | `UiRoot` (CanvasLayer) | Bir pencere yığını: açma, en üsttekini Esc ile kapatma, duraklatma, imleç, klavye odağı |
| | `UiScreen` (Control) | Pencere tabanı: `initial_focus`, `close_requested` |
| | `FpsCounter` (Label) | Saniyedeki kare sayısı, duraklatılmışken de (`fps_counter.tscn`) |

`ground_character` için `click_to_move` gerekir (gövde bir `NavigationMover` yönetir); diğer eklentiler motordan
başka bir şeye ihtiyaç duymaz. Her birinin projeden beklediği: [Kendi projenizde kullanma](integration.md).

`gdscript/` içindeki demo bunları bir araya getirir:

| Dosya | Görev |
|---|---|
| `main.tscn` | Demo sahnesi |
| `player/player.tscn`, `player_locomotion.tres` | Kahraman: tüm parçalarıyla bir `GroundCharacter` ve koşu ayarları |
| `demo/hud.gd` | Kontrol ipuçları ve hız göstergesi |
| `demo/settings_applier.gd` | Ayarları demonun düğümlerine uygular; "ayar → özellik" eşlemesi için tek yer |
| `settings/game_settings.gd` | `GameSettings`, yani `Settings` otomatik yüklemesi: varsayılanlar, `user://settings.cfg`, `changed` sinyali; motor ayarlarını kendisi uygular |
| `ui/ui_root.tscn` | Ayarlar penceresi ve F10 ile birlikte `UiRoot` |
| `ui/settings/settings_screen.tscn`, `.gd` | Ayarlar penceresi |
| `ui/settings/setting_*.gd` | `SettingCheckButton`, `SettingOptionButton`, `SettingSlider`, `SettingLanguageButton`: bir ayar anahtarına bağlı arayüz öğeleri |

Her sistemin kendi sayfası vardır: [Hareket](systems/locomotion.md), [Kamera](systems/camera.md),
[Girdi](systems/input.md), [Karakterler](systems/characters.md), [Ses](systems/audio.md), [Arayüz](systems/ui.md),
[Dünya ve navigasyon](systems/world-and-navigation.md).

## Sahnede yapılan bağlantılar

Düğüm referansları, `main.tscn` ve `player.tscn` içinde ayarlanan dışa aktarılmış özelliklerdir. `main.tscn`
içindeki sinyal bağlantıları:

| Sinyal | Bağlandığı yer | Etki |
|---|---|---|
| `PlayerInput.destination_picked(point)` | `ClickMarker.show_at` | İşaretçi tıklanan noktada belirir |
| `PlayerInput.hold_started` | `ClickMarker.fade_out` | Basılı tutma tıklamanın yerini alır, işaretçi solar |
| `Player/NavigationMover.arrived` | `ClickMarker.fade_out` | Karakter noktaya ulaştı |
| `Player/NavigationMover.destination_cancelled` | `ClickMarker.fade_out` | Noktadan vazgeçildi |
| `PlayerInput.hold_pending_changed(pending)` | `CameraRig.set_follow_paused` | Bir basışın tıklama mı basılı tutma mı olduğu anlaşılana kadar kamera kendiliğinden dönmez |

## Ayarlar

`Settings` otomatik yüklemesi (`GameSettings`) değerleri saklar ve `changed(key, value)` sinyalini yayar. Motor
düzeyindeki ayarları kendisi uygular: tam ekran, kare hızı sınırı, V-Sync, fizik enterpolasyonu, arayüz ölçeği, dil ve
ses düzeyi. Geri kalan her şeyi, her anahtarı bir düğüm özelliğine eşleyen `gdscript/demo/settings_applier.gd` uygular.
Bileşenlerin kendileri ayarları hiçbir zaman okumaz, bkz. [Ayarlar](settings.md).

## Neden bu şekilde kurulu

- **Gövdeyi yalnızca `GroundCharacter` hareket ettirir.** Hareket bileşenleri bir hız döndürür ve hiçbir zaman
  `move_and_slide()` çağırmaz. Yerçekimi, zıplamalar ve ileride eklenecek geri itmeler tek bir yerde birleşir ve
  birbiriyle çakışamaz.
- **`GroundMotion` düğümsüz matematiktir.** Hızlanma ve frenleme durumun saf bir fonksiyonudur: tek başına test
  etmesi ve başka bir dile satır satır aktarması kolaydır.
- **Karakter fare hakkında hiçbir şey bilmez.** Oyuncunun karakteri olmasının nedeni, ana sahnedeki `PlayerInput`
  düğümünün onun hareketlendiricisini yönetmesidir. Bir NPC için `player.tscn` sahnesini yalnızca oyuncuya özgü
  `Silhouette` ve `Appearance` düğümleri olmadan örnekleyin ve yapay zekânızdan `NavigationMover.move_to()` çağırın.
- **Kamera karakterin alt düğümü değil, kardeşidir.** `_process` içinde hedefin enterpole edilmiş konumuna gider ve
  kendisi enterpole edilmez; böylece fizik enterpolasyonuyla (varsayılan olarak açık, Ayarlar → Görüntü) koşu her kare
  hızında akıcıdır. Takip modu için kamera hedefin hızını onun fizik tiki başına hareketinden hesaplar; bu yüzden
  herhangi bir `Node3D` hedef olabilir.
- **Bileşenler ayarlar hakkında hiçbir şey bilmez.** `LedgeGuard`, `PointClickMoveInput`, `OrbitCameraRig` ve
  diğerleri kendi özelliklerini okur; `Settings` otomatik yüklemesiyle yalnızca `settings_applier.gd` ve ayarlar
  penceresi konuşur. Bir bileşen ayarlar sistemi olmadan başka bir projeye taşınabilir.
- **Pencereler Godot'nun kurallarına uyar.** Yerleşim yalnızca kapsayıcılarla yapılır; görünüm her düğümdeki
  geçersiz kılmalardan değil, proje temasından ve onun tür varyasyonlarından gelir. Pencere bir sinyalle kapatılmayı
  ister ve `UiRoot` onu kapatır (çağrılar ağaçta aşağı, sinyaller yukarı gider). Tuşlar girdi eylemleridir. Klavye
  odağı pencere açıldığında ayarlanır ve kapandığında geri yüklenir. Bir pencere açıkken oyun duraklatılır (`UiRoot`,
  `PROCESS_MODE_ALWAYS` modunda çalışır) ve kamera yakaladığı imleci serbest bırakır.

## Klasörler

| Klasör | İçerik |
|---|---|
| `addons/iso_orbit/` | Yeniden kullanılabilir bileşenler, her parça için bir klasör |
| `gdscript/` | GDScript ile yazılmış demo: ana sahne, kahraman, ayarlar sistemi ve penceresi, HUD ipucu |
| `shared/` | Betik dilinden bağımsız demo içeriği: seviye, karakterler ve ekipman, dünya gölgelendiricileri ve dokuları, sesler, arayüz teması |
| `l10n/` | Arayüz çevirileri |
| `tests/` | Headless testler, bkz. [Testler](testing.md) |
| `docs/` | Bu belgeler |

`shared/`, demonun gelecekteki bir C# sürümü tarafından yeniden kullanılmak üzere tasarlanmıştır; o sürüm
`gdscript/` yanında kendi klasörünü alacaktır. Şimdilik iki istisna var: `world.tscn` ve `mountain.tscn`,
`addons/iso_orbit/points_of_interest/point_of_interest.gd` betiğini kullanır ve iki küçük dekor betiği
(`flicker.gd`, `hover_spin.gd`) `shared/world/props/` içinde bulunur. Bkz. [Bilinen sorunlar](known-issues.md).

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
