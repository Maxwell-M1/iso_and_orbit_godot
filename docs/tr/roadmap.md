<!-- translation of docs/en/roadmap.md @ 785e0b204d0a -->
# Yol haritası

[← Belge dizini](index.md)

> Bu, [İngilizce orijinalin](../en/roadmap.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Belirli bir sıra olmadan planlanan çalışmalar. Buradakilerin hiçbiri henüz uygulanmadı.

- **GDScript'siz `shared/`.** Seviyeler yerleri, doğuş noktalarını ve portalları bileşen betikleriyle
  (`point_of_interest.gd`, `spawn_point.gd`, `level_portal.gd`) işaretler; ayrıca iki dekor betiği
  `shared/world/props/` içinde bulunur. Bunların C# sürümünün de kullanabileceği
  bir biçime getirilmesi gerekiyor. Bkz. [Bilinen sorunlar](known-issues.md#proje-dosyaları).
- **Bir C# örneği**: `csharp/` içinde aynı bileşenlerle, `shared/world/` içindeki seviyelerin üstüne kurulu
  oyun kabuğuyla. C# sürümünün global sınıf adları GDScript olanlardan farklı olmalıdır: `class_name` ve `[GlobalClass]`
  tek bir ad alanını paylaşır.
- **Animasyonlar.** İskeletli bir model ve `GroundCharacter` sınıfının bildirdikleriyle yönetilen bir `AnimationTree`:
  bekleme, koşu ve depar karışımları için `get_locomotion_blend()` veya `get_local_movement()`, koşu döngüsünü zeminle
  uyumlu tutmak için `get_gait_cycle()`, zıplamalar ve inişler için durum ve zemin sinyalleri.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
