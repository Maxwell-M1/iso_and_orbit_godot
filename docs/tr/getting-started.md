<!-- translation of docs/en/getting-started.md @ a68235d39cbc -->
# Başlarken

[← Belge dizini](index.md)

> Bu, [İngilizce orijinalin](../en/getting-started.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

## Gereksinimler

- Godot 4.7.2. Standart sürüm yeterlidir: proje GDScript kullanır, .NET SDK gerekmez.
- Demo için başka bir şey gerekmez: Jolt Physics motora yerleşiktir, işleyici (renderer) olarak Forward+ kullanılır ve
  tüm varlıklar depodadır.

## Açma ve çalıştırma

1. Depoyu klonlayın.
2. Proje Yöneticisi'nde (Project Manager) **İçe Aktar** (Import) düğmesine basın ve `project.godot` dosyasını seçin,
   ardından projeyi açın. `.godot/` önbelleği depoda olmadığından ilk içe aktarma biraz zaman alır.
3. F5'e basın. Ana sahne `res://gdscript/main.tscn` dosyasıdır.

Demo önceden kaydettiğiniz ayarları yükler. Buradaki varsayılanlar için **F10 → Tümünü sıfırla** kullanın. Yeni
klonda betikleri açmadan veya testleri çalıştırmadan önce içe aktarmanın bitmesini bekleyin. Başka projenin
`.godot/` önbelleğini kopyalamayın.

## Ne görürsünüz

Kahraman, çitle çevrili bir açıklığın ortasındaki başlangıç noktasında durur. Kontroller sol üst köşede, kare hızı
sağ üst köşede gösterilir.

- Zemine **sol tık**: kahraman engellerin etrafından dolanarak oraya koşar, bir işaretçi noktayı gösterir.
- **Sol tuşu basılı tutun**: kahraman imlecin peşinden koşar.
- **Sağ tuş + fare**: kamerayı döndürür. **Tekerlek**: yakınlaştırır.
- **Önce sağ, sonra sol tuş**: kameranın baktığı yöne koşar. **Önce sol, sonra sağ tuş**: koşarken etrafa bakar.
  **Sağ tuş + WASD**: kameraya göre hareket eder.
- **Shift** depar attırır, **Boşluk** zıplatır, **F10** ayarları açar.

Tam liste: [Kontroller](controls.md).

Gidilecek yerler:

- **Kadim Çember**, başlangıç noktasının kuzeybatısındaki sütun halkası. Sütunların arasında yürüyün, kahraman
  onların arkasında siluet olarak görünür.
- Doğuda **Yolcular Kampı** ve güneybatıda **Kuyu Başındaki Çiftlik**, NPC'lerle birlikte.
- **Rüzgârlı Doruk**, kuzeydoğudaki dağ: zirvesine tıklayın, kahraman sarmal patikayı izler.
- Yol bulmayı denemek için çalı labirenti, rampalı ve merdivenli platform ile başlangıç noktasının yakınındaki U biçimli
  tuzak.
- Güney duvarının yanında sıralanmış on kahraman görünümü. Birini Ayarlar → Karakter → **Kahraman görünümü** ile
  seçin.
- **Kadim Çember** yanındaki dönen kristalli ışınlanma platformuna çıkın; E'ye basarak veya teklife tıklayarak
  **Issız Ada** ve **Münzevinin Kampı**'na geçin. Adadaki platform ("Yeşil Vadi'ye ışınlan") geri götürür.

## Ayarlar

F10 ayarlar penceresini açar ve oyunu duraklatır; Esc veya F10 kapatır. Ayarlar `user://settings.cfg` dosyasına
kaydedilir ve hemen uygulanır. Kontrol ipuçlarını gizlemek için Ayarlar → Arayüz → **Kontrol ipuçları ve hız**
seçeneğini kapatın. Arayüz dili de aynı sekmede seçilir. Tüm ayarlar: [Ayarlar](settings.md).

## Testleri çalıştırma

```bash
godot --headless --fixed-fps 60 --path . --script res://tests/run_checks.gd
```

Burada `godot`, Godot 4.7.2 çalıştırılabilir dosyanızdır. Windows'ta çıktıyı görmek ve çıkış kodunu almak için
`_console.exe` sürümünü kullanın. Yeni bir klonda önce projeyi bir kez içe aktarın: editörde ya da
`godot --headless --path . --import` ile. Ayrıntılar: [Testler](testing.md).

## Sonraki adımlar

- [Hazır kahramanı aktarma](integration.md#demonun-kahramanını-projenize-aktarma): gereken dosyalar, test seviyesi
  ve çalışan kurulumun denemeleri.
- [Yapılandırmalar](configurations.md): sağlanan varsayılanlar ve iki hareket/kamera seçeneği.
- [Mimari](architecture.md): her düğümün ne yaptığı ve nasıl bağlandıkları.
- [Proje yapılandırması](project-setup.md): fizik katmanları, girdi eylemleri ve isteğe bağlı demo ayarları.

---

*Bu sayfa Iso & Orbit 1.2.0 sürümüne karşılık gelir.*
