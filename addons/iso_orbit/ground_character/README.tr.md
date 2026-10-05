<!-- translation of addons/iso_orbit/ground_character/README.md @ 87915285e965 -->
# Zemin Karakteri

[← Belge dizini (şablon deposu)](../../../docs/tr/index.md)

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Tıklayarak hareket için hazır karakter gövdesi: yerçekimi, kenardan ayrıldıktan hemen sonraki kısa süre ve girdi
tamponlamasıyla zıplama (her fizik tik hızında aynı yükseklik), kendine özgü yerçekimi ve hız sınırıyla düşüş,
dayanıklılıkla depar, basamaklardan çıkma ve inme, gövdeyi düşüş kenarlarında durduran isteğe bağlı koruma.
Gövde animasyonlar, efektler ve arayüz için ne yaptığını bildirir: durum ve değişiklikleri, hangi
ayakla atıldığıyla birlikte adımlar, kalkışlar ve inişler, karışım değeri olarak hız, modelin eksenlerinde hareket,
dönüş ve yürüyüş döngüsü. Ayrıca: bu sinyallere bağlı sesler, durumu metin olarak gösteren bir panel, adımlarla sallanan
eldeki nesne, modelin süzülme modu ve değiştirilebilir modeller.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Yerçekimi, zıplama, depar, basamaklar, `move_and_slide()`, modeli döndürme; animasyonlar için durum, sinyaller ve sorgular; sarsıntısız `teleport()` |
| `fall_settings.gd` | `FallSettings` (Resource) | Düşüş yerçekimi, hız sınırı ve ona frenleme |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Gövdeyi bir uçurumda durdurur ya da kenar boyunca kaydırır |
| `stamina.gd` | `Stamina` (Node) | Depar rezervi |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Depar ve zıplama tuşları → karakter |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Karakterin sinyallerinde sesler çalar |
| `hand_sway.gd` | `HandSway` (Node) | Bir el düğümünü adımlarla sallar |
| `character_hover.gd` | `CharacterHover` (Node3D) | Modeli yerden yükseltir, basamaklarda süzdürür, sallayıp eğer; düşüşü yavaşlatabilir |
| `damped_spring.gd` | `DampedSpring` (RefCounted) | Atalet için tek değerli sönümlü yay |
| `character_monitor.gd` | `CharacterMonitor` (Label) | Karakterin durumunu ve son olaylarını metin olarak gösterir; olayları günlüğe yazabilir |
| `character_appearance.gd` | `CharacterAppearance` (Node) | Modeli çalışma anında değiştirir |
| `stamina_bar.gd`, `stamina_bar.tscn` | `StaminaBar` (ProgressBar) | `Stamina` için bir HUD çubuğu |

`addons/iso_orbit/click_to_move` gerektirir: gövdeyi bir `NavigationMover` yönetir.

## Kurulum

1. Bu klasörü ve `click_to_move` klasörünü `res://addons/iso_orbit/` konumuna kopyalayın.
2. Karakteri oluşturun:

   ```
   Player           ground_character.gd betikli CharacterBody3D
   ├── CollisionShape3D
   ├── Visual       Node3D; içindeki model −Z yönüne bakar
   ├── NavigationMover   click_to_move eklentisinden
   ├── LedgeGuard   isteğe bağlı
   └── Stamina      isteğe bağlı
   ```

   Gövdenin `mover`, `visual`, `ledge_guard` ve `stamina` özelliklerini ayarlayın. Demo ayrıca gövdede
   `floor_constant_speed` ayarlar, böylece karakter rampalarda hızını korur; gövdeyi de seviyeden ayrı olarak 2. fizik
   katmanına koyar; seviye ve görünmez duvarları içeren 1 ve 4. katmanlarla çarpışır. `get_ground_height()` ve
   varsayılan `LedgeGuard`, aynı maskeyle zemin arar. Gövde `max_step_height` (0.3 m) basamağa ve
   `floor_max_angle` eğimine kadar çıkabilir. Basamak rotaları için navigasyon örgüsünün `agent_max_climb` değerini
   hedeflenen basamak yüksekliğine eşleyip pişirilmiş yolu gerçek çarpışmada deneyin. `LedgeGuard.max_drop`,
   `max_step_height` değerinden düşük olmasın; inişte `stair_taken` istiyorsanız `floor_snap_length` daha kısa olsun.
   Gövde sahnede dönük durabilir: karakter yalnız gövdeye göre `Visual` düğümünü döndürür ve gövdenin −Z yönüne
   bakarak başlar. Sonradan `teleport(position, facing)` veya `NavigationMover.face()` onu döndürür.
3. Tuşlar için `character_action_input.gd` betikli bir `Node` ekleyin ve `character` özelliğini ayarlayın. `sprint`
   ve `jump` girdi eylemlerine ihtiyaç duyar; eksik olan başlangıçta bir kez bildirilir ve sonra okunmaz.
4. İsteğe bağlı: `AudioStreamPlayer3D` çocuklarıyla `CharacterSounds`; `character` ve model el düğümü atanmış
   `HandSway`; `slot` ve model sahneleri listesi atanmış `CharacterAppearance`; hata ayıklama paneli için bir
   `CanvasLayer` içinde `CharacterMonitor`. `LedgeGuard.floor_mask` varsayılanı 0'dır: gövdenin çarpışma maskesini
   kullanır ve gövdenin üzerinde duramayacağı kadar dik yüzeyleri reddeder.
5. Süzülme için `Visual` ile model arasına `character_hover.gd` betikli `Node3D` koyun (`Visual/Hover/Model`);
   `CharacterAppearance` kullanıyorsanız `slot` bu düğüm olsun. Süzülürken adımlar kesilir; `fall` alanına
   `FallSettings` atanırsa daha yavaş inebilir. Model yükselir, gövde ve çarpışma şekli yükselmez.
6. İsteğe bağlı: gövdenin kendi düşüşü için `fall` alanına `FallSettings` atayın; inişte ayrı yerçekimi ve hız
   sınırı sağlar.

Kurulum yanlışları oyun açılırken uyarı olarak yazılır. Sağlanan `player.tscn`, 1.8 m kapsül,
`floor_constant_speed` açık, kenar koruması, dayanıklılık, süzülme düşüş kaynağı ve başlangıçta **kapalı**
süzülme düğümü içerir. `NavigationMover`, `player_locomotion.tres` kullanır; demonun `SettingsApplier`
bileşeni başlangıçta kaydedilmiş ayarlardan özellikleri değiştirebilir. Kahraman kopyalama tarifi için
`docs/tr/integration.md`, kendi modeliniz ve çarpışması için `docs/tr/systems/characters.md` sayfasına bakın.

Aynı gövdeyi yapay zekâ da yönetebilir: `NavigationMover.move_to()` ve `GroundCharacter.jump()` çağırın,
`sprint_requested` ayarlayın.

## Belgeler

Şablon deposunda: `docs/tr/integration.md`, `docs/tr/systems/locomotion.md`, `docs/tr/systems/input.md`
(`CharacterActionInput`), `docs/tr/systems/audio.md`, `docs/tr/systems/characters.md` ve kahramanın ışınlanması
için `docs/tr/systems/levels.md`.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
