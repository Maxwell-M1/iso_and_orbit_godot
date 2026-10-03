<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 77aade651b48 -->
# Yörünge Kamerası

[English](README.md) · [Español](README.es.md) · [日本語](README.ja.md) · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · **Türkçe** · [简体中文](README.zh_CN.md)

> Bu, [İngilizce orijinalin](README.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

İzometrik ve yukarıdan bakışlı oyunlar için bir yörünge kamerası: bir hedefi izler, farenin sağ tuşuyla onun etrafında
döner, tekerlekle yakınlaştırır (mesafe ve eğim birlikte değişir) ve koşan hedefin arkasına kendiliğinden dönebilir.
Kamera, arkasındaki duvarlarda duran ve bir engel hedefi gizlediğinde yaklaşabilen bir kolun ucunda durur.

Godot 4.7 için bir kamera ve karakter kontrolcüsü şablonu olan Iso & Orbit'in parçasıdır. MIT lisansı (bkz.
`LICENSE`).

## İçerik

| Dosya | Sınıf | Görev |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig` (Node3D) | Hedefi izler, yörünge, yakınlaştırma, takip modu |
| `camera_arm.gd` | `CameraArm` (Node3D) | Kamerayı tutar ve engellerde kısalır; çok yakında hedefi saydamlaştırır |

Başka bir eklenti gerekmez.

## Kurulum

1. Bu klasörü `res://addons/iso_orbit/orbit_camera/` konumuna kopyalayın.
2. Girdi eylemlerini ekleyin (adlar dışa aktarılmış özelliklerdir, bu yüzden kendi eylemlerinizi kullanabilirsiniz):
   `camera_rotate` (farenin sağ tuşu), `camera_zoom_in` (tekerlek yukarı), `camera_zoom_out` (tekerlek aşağı).
3. Kamerayı hedefin içinde değil, yanında oluşturun:

   ```
   CameraRig    orbit_camera_rig.gd betikli Node3D, target = karakteriniz
   └── CameraArm    camera_arm.gd betikli Node3D
       └── Camera3D
   ```

4. Fizik katmanları: kol 1. ve 3. katmanlardaki gövdelerde durur (`collision_mask`). Seviye geometrisini bunlardan
   birine koyun, karakterleri bu katmanların dışında tutun. `camera_ignore` grubundaki (ya da bu gruptaki bir düğümün
   altındaki) gövdeler kolu asla durdurmaz.
5. Hedef fizik tiklerinde hareket ediyorsa projede fizik enterpolasyonunu açın: düzenek hedefin enterpole edilmiş
   konumunu izler.

Kol olmadan düzeneğin alt düğümü olan bir `Camera3D` de çalışır: yakınlaştırmanın belirlediği mesafede kalır ve
duvarların içinden geçer.

## Belgeler

Şablon deposunda: `docs/tr/systems/camera.md` (tüm özellikler, yakınlaştırma eğrisi, takip modu, kolun nasıl
çalıştığı) ve `docs/tr/project-setup.md`.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
