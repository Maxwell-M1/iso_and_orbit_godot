<!-- translation of docs/en/systems/audio.md @ 551102f71d1a -->
# Ses

> Bu, [İngilizce orijinalin](../../en/systems/audio.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

`GroundCharacter` başına gelenleri sinyallerle bildirir: `stepped(sprinting)`, `jumped`, `landed(impact_speed)`,
`sprint_changed(sprinting)` (bkz. [Hareket](locomotion.md#sinyaller)). Sesler, ayak altındaki toz veya animasyonlar
bunlara bağlanır; karakterin kendisi bunlardan habersizdir. Demo sesleri bağlar.

## CharacterSounds

`CharacterSounds` (`Player/Sounds`), karakterin `Node3D` türündeki bir alt düğümüdür. Alt düğümleri
`AudioStreamPlayer3D` düğümleridir; böylece ses karakterden gelir ve bir NPC için de aynı şekilde çalışır. Bu düğüm
olmadan karakter tamamen aynı şekilde, yalnızca sessizce çalışır.

| Ses | Oynatıcı | Ne çalar |
|---|---|---|
| Ayak sesleri | `Footsteps` | Rastgele perde (±%8) ve ses düzeyiyle dört varyantlı bir `AudioStreamRandomizer`, aynı anda üçe kadar. Deparda biraz daha tiz (`sprint_step_pitch` 1,08) ve daha yüksek (+2 dB); adımlar mesafeyi izlediğinden kendiliğinden daha sık |
| Zıplama | `Jump` | Ayağın itişi ve giysilerin hışırtısı |
| İniş | `Land` | Ağır bir gümleme; düşüş ne kadar hızlıysa o kadar yüksek: `land_full_speed` (10 m/sn) değerinden itibaren tam ses, hiçbir zaman `min_land_volume` (%30) değerinden kısık değil |
| Depar başlangıcı | `SprintStart` | Deparın başında bir itiş ve yükselen bir hava hışırtısı |
| Depar | `SprintLoop` | Hızlı nefes ve havadan oluşan 2 sn'lik bir döngü; `sprint_loop_fade` (0,25 sn) süresinde yavaşça açılıp kapanır |

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `character` | üst düğüm | Kimin sinyallerinin çalınacağı |
| `footsteps`, `jump`, `land`, `sprint_start`, `sprint_loop` | — | Oynatıcılar |
| `footsteps_enabled`, `jump_enabled`, `sprint_enabled` | açık | Ses grupları; zıplama grubu zıplamayı ve inişi, depar grubu başlangıcı ve döngüyü kapsar |
| `sprint_step_pitch`, `sprint_step_volume_db` | 1,08; +2 dB | Deparda ayak sesleri |
| `land_full_speed`, `min_land_volume` | 10 m/sn; 0,3 | İniş ses düzeyi eğrisi |
| `sprint_loop_fade` | 0,25 sn | Depar döngüsünün yavaşça açılıp kapanma süresi |

Ses düzeyleri `gdscript/player/player.tscn` içindeki oynatıcılarda ayarlanır; bunları çalışan oyunda Uzak (Remote)
ağacı üzerinden ayarlayın. İstisna `Land` oynatıcısıdır: ses düzeyi her inişten önce düşüş hızından ayarlanır
(`land_full_speed`, `min_land_volume`). Gruplar Ayarlar → Ses içinde açılıp kapatılır; demo depar seslerini
varsayılan olarak kapatır. Oradaki genel ses düzeyi `Master` veri yoludur: yüzde, genliğin bir payıdır (%50, 6 dB
daha kısıktır), 0 veri yolunun sesini kapatır.

## Seslerin kendileri

`shared/audio/character/` içindeki dosyalar bir betikle sentezlenmiştir: gümlemeler perdesi düşen sinüslerdir,
çıtırtılar ve hava sesi bant geçiren filtrelerden geçirilmiş gürültüdür. Depar döngüsü WAV içinde bir `smpl` parçası
taşır ve varsayılan içe aktarma döngü modu "WAV'dan Algıla" (Detect From WAV), içe aktarma ayarlarına dokunmadan onu
döngüye sokar. Döngü dikişi sondan başa çapraz geçişle birleştirilmiştir, bu yüzden tıkırdamaz.

Bunların yerine gerçek kayıt sesler kullanılabilir: aynı adlı dosyaları klasöre koyun.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
