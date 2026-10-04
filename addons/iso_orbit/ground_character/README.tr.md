<!-- translation of addons/iso_orbit/ground_character/README.md @ c944f71371be -->
# Zemin Karakteri

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Tıklayarak hareket için hazır bir karakter gövdesi: yerçekimi, çakal süresi (coyote time) ve girdi tamponlamalı
zıplama (her fizik tik hızında aynı yükseklik), dayanıklılıkla depar, gövdeyi uçurumlarda durduran bir kenar koruması,
adımlar, zıplamalar, inişler ve depar için sinyaller, bu sinyallere bağlı sesler, adımlarla sallanan eldeki nesne ve
değiştirilebilir modeller.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `ground_character.gd` | `GroundCharacter` (CharacterBody3D) | Yerçekimi, zıplama, depar, `move_and_slide()`, modeli döndürme; sinyaller |
| `ledge_guard.gd` | `LedgeGuard` (Node) | Gövdeyi bir uçurumda durdurur ya da kenar boyunca kaydırır |
| `stamina.gd` | `Stamina` (Node) | Depar rezervi |
| `character_action_input.gd` | `CharacterActionInput` (Node) | Depar ve zıplama tuşları → karakter |
| `character_sounds.gd` | `CharacterSounds` (Node3D) | Karakterin sinyallerinde sesler çalar |
| `hand_sway.gd` | `HandSway` (Node) | Bir el düğümünü adımlarla sallar |
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
   `floor_constant_speed` ayarlar, böylece karakter rampalarda hızını korur; gövdeyi de seviyeden ayrı olarak 2.
   fizik katmanına koyar.
3. Tuşlar için `character_action_input.gd` betikli bir `Node` ekleyin ve `character` özelliğini ayarlayın. `sprint`
   ve `jump` girdi eylemlerine ihtiyaç duyar.
4. İsteğe bağlı: `AudioStreamPlayer3D` alt düğümleriyle `CharacterSounds`, modelin el düğümüyle `HandSway`, model
   sahneleri listesiyle `CharacterAppearance`. `LedgeGuard.floor_mask` varsayılan olarak 1. fizik katmanıdır.

Aynı gövdeyi yapay zekâ da yönetebilir: `NavigationMover.move_to()` ve `GroundCharacter.jump()` çağırın,
`sprint_requested` ayarlayın.

## Belgeler

Şablon deposunda: `docs/tr/integration.md`, `docs/tr/systems/locomotion.md`, `docs/tr/systems/audio.md` ve
`docs/tr/systems/characters.md`.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
