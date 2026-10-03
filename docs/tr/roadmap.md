<!-- translation of docs/en/roadmap.md @ 8e61c7584e54 -->
# Yol haritası

> Bu, [İngilizce orijinalin](../en/roadmap.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Belirli bir sıra olmadan planlanan çalışmalar. Buradakilerin hiçbiri henüz uygulanmadı.

- **GDScript'siz `shared/`.** Seviye, yerleri `addons/iso_orbit/points_of_interest/point_of_interest.gd` ile
  işaretler ve iki dekor betiği `shared/world/props/` içinde bulunur. Bunların bir C# sürümünün de kullanabileceği
  bir biçime getirilmesi gerekiyor. Bkz. [Bilinen sorunlar](known-issues.md#proje-dosyaları).
- **Bir C# örneği**: `csharp/` içinde, aynı bileşenlerle ve `shared/world/world.tscn` üzerine kurulu bir ana
  sahneyle. C# sürümünün global sınıf adları GDScript olanlardan farklı olmalıdır: `class_name` ve `[GlobalClass]`
  tek bir ad alanını paylaşır.
- **Animasyonlar.** Bir `AnimationTree` içindeki bekleme/koşu karışımını `NavigationMover.get_speed()` ile yönetmek
  ve yürüme döngüsünü, ayak seslerinin zaten izlediği ritim olan `GroundCharacter.get_step_phase()` ile uyumlu
  tutmak.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
