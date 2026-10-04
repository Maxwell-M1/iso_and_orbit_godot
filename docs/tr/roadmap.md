<!-- translation of docs/en/roadmap.md @ 6c3e4efdec59 -->
# Yol haritası

> Bu, [İngilizce orijinalin](../en/roadmap.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Belirli bir sıra olmadan planlanan çalışmalar. Buradakilerin hiçbiri henüz uygulanmadı.

- **GDScript'siz `shared/`.** Seviye, yerleri `addons/iso_orbit/points_of_interest/point_of_interest.gd` ile
  işaretler ve iki dekor betiği `shared/world/props/` içinde bulunur. Bunların bir C# sürümünün de kullanabileceği
  bir biçime getirilmesi gerekiyor. Bkz. [Bilinen sorunlar](known-issues.md#proje-dosyaları).
- **Bir C# örneği**: `csharp/` içinde, aynı bileşenlerle ve `shared/world/world.tscn` üzerine kurulu bir ana
  sahneyle. C# sürümünün global sınıf adları GDScript olanlardan farklı olmalıdır: `class_name` ve `[GlobalClass]`
  tek bir ad alanını paylaşır.
- **Animasyonlar.** İskeletli bir model ve `GroundCharacter` sınıfının bildirdikleriyle yönetilen bir `AnimationTree`:
  bekleme, koşu ve depar karışımları için `get_locomotion_blend()` veya `get_local_movement()`, koşu döngüsünü zeminle
  uyumlu tutmak için `get_gait_cycle()`, zıplamalar ve inişler için durum ve zemin sinyalleri.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
