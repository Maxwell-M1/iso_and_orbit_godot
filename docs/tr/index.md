<!-- translation of docs/en/index.md @ 0499e77e2e07 -->
# Belgeler

[English](../en/index.md) · [Español](../es/index.md) · [日本語](../ja/index.md) · [Português (Brasil)](../pt_BR/index.md) · [Русский](../ru/index.md) · **Türkçe** · [简体中文](../zh_CN/index.md)

> Bu, [İngilizce orijinalin](../en/index.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Godot 4.7 için izometrik ve yukarıdan bakışlı RPG'lere yönelik, tıklayarak hareket eden bir karakter kontrolcüsü ve
bir yörünge kamerası; iki demo seviyesiyle birlikte. Genel bakış için [README](../../README.tr.md) ile başlayın.

Orijinal belgeler İngilizcedir. Çeviriler onu izler ve geride kalabilir; aralarında fark olduğunda İngilizce sayfa
doğrudur.

## İlk çalışan kurulum

1. Varsayılan kontrolleri denemek için [demoyu çalıştırın](getting-started.md).
2. [Kahramanı](integration.md#demonun-kahramanını-projenize-aktarma) kendi projenizde küçük bir seviyeye aktarın.
   Karakteri değiştirmeden önce dosya listesi, Input Map ve navigasyon adımlarını izleyin.
3. [Yapılandırma seçin](configurations.md): elle döndürülen kamera, yol izleyen fare hareketi veya kamera takibiyle
   keşif.
4. Özellikleri [hareket](systems/locomotion.md), [girdi](systems/input.md) ve [kamera](systems/camera.md)
   başvurularıyla ayarlayın. [Karakterler](systems/characters.md) model değişimini ve animasyon eklemeyi açıklar.

## Belge menüsü

Bir sayfa seçin. Eklenti kurulum kılavuzları sistem başvurularından sonra gelir.

### Başlangıç

- [Başlarken](getting-started.md): gereksinimler, projeyi açma, demoda neler olduğu.
- [Kontroller](controls.md): tüm girdiler, tıklama ile basılı tutma farkı, sağ tuşla kullanılan tuşlar, kamera.
- [Ayarlar](settings.md): ayarlar penceresindeki her seçenek, anahtarı, varsayılan değeri ve neyi değiştirdiği.
- [Kahraman yapılandırmaları](configurations.md): değerlerin kaynağı, kesin düğüm yolları, üç uyumlu düzen ve
  sonucun nasıl denetleneceği.

### Kod

- [Mimari](architecture.md): ana sahne, verinin bir fizik tikinde nasıl aktığı, bileşenler ve neden bu şekilde
  ayrıldıkları.
- [Kendi projenizde kullanma](integration.md): eklentiler ve her birinin ihtiyaçları, tek başına kamera, tıklayarak
  hareket, kendi gövdeniz, NPC'ler.
- [Proje yapılandırması](project-setup.md): bileşenlerin beklediği fizik katmanları, girdi eylemleri, gruplar ve
  proje ayarları.

### Sistemler

- [Hareket](systems/locomotion.md): `LocomotionSettings`, `GroundMotion`, `NavigationMover`, `GroundCharacter`,
  karakterin animasyonlar ve arayüz için bildirdikleri, `CharacterMonitor`, basamaklar ve eğimler, depar ve
  dayanıklılık, zıplama, düşüş (`FallSettings`) ve kenar koruması.
- [Kamera](systems/camera.md): `OrbitCameraRig` (yörünge, yakınlaştırma eğrisi, takip) ve `CameraArm` (engeller,
  yaklaşma, saydamlaşma).
- [Girdi](systems/input.md): `PointClickMoveInput` (tıklama, basılı tutma, tuşlar, imleç) ve `CharacterActionInput`.
- [Karakterler](systems/characters.md): modeller ve ekipman, kahraman görünümleri, el sallanması, siluet.
- [Ses](systems/audio.md): karakter sesleri ve nasıl sentezlendikleri.
- [Arayüz](systems/ui.md): pencereler, ayarlar sistemi ve penceresi, HUD, tema, çeviriler.
- [Dünya ve navigasyon](systems/world-and-navigation.md): seviye, yerler, yüzeyler ve pişirilmiş dokular, dağ,
  navigasyon örgüsü ve onu yeniden pişirme.
- [Seviyeler](systems/levels.md): oyun kabuğu, seviye sunucusu, yükleme ekranı, portallar, doğuş noktaları,
  oynanabilir kahraman ve ada.

### Eklenti kurulum kılavuzları

- [Tıklayarak hareket](../../addons/iso_orbit/click_to_move/README.tr.md)
- [Yerde hareket eden karakter](../../addons/iso_orbit/ground_character/README.tr.md)
- [Yörünge kamerası](../../addons/iso_orbit/orbit_camera/README.tr.md)
- [Engellerin arkasında siluet](../../addons/iso_orbit/occluded_silhouette/README.tr.md)
- [İlgi noktaları](../../addons/iso_orbit/points_of_interest/README.tr.md)
- [Arayüz pencereleri](../../addons/iso_orbit/ui_screens/README.tr.md)
- [Seviye geçişleri](../../addons/iso_orbit/levels/README.tr.md)

### Bakım

- [Testler](testing.md): testleri çalıştırma, her test paketinin neyi kapsadığı, denetim yazma.
- [Bilinen sorunlar](known-issues.md): sınırlamalar ve motor tuhaflıkları, bunlarla ilgili ne yapılacağı.
- [Sözlük](glossary.md): kodda ve belgelerde kullanılan terimler.
- [Yol haritası](roadmap.md): planlanan çalışmalar.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
