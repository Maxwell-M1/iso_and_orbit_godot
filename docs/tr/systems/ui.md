<!-- translation of docs/en/systems/ui.md @ 64e56dbf9718 -->
# Arayüz

> Bu, [İngilizce orijinalin](../../en/systems/ui.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

Oyunun üstündeki pencereler, ayarlar sistemi, HUD ve arayüz çevirileri.

## Pencereler: UiRoot ve UiScreen

`UiRoot` (bir `CanvasLayer`, `addons/iso_orbit/ui_screens/ui_root.gd`; demodaki örneği `gdscript/ui/ui_root.tscn`)
pencereleri bir yığın olarak gösterir:

- `open(scene)` bir pencereyi en üste koyar, `close_top()` en üsttekini kapatır, `toggle(scene)` açık olan bir
  pencereyi (ve üstündeki her şeyi) kapatır ya da onu açar. Esc (`ui_cancel`) en üstteki pencereyi kapatır; F10
  (`toggle_settings`) ayarlar penceresini (`settings_screen`) açıp kapatır.
- Herhangi bir pencere açıkken oyun duraklatılır (`pause_game`) ve fare imleci görünür. `UiRoot`,
  `PROCESS_MODE_ALWAYS` modunda çalışır ve pencereleri bunu miras alır.
- Pencere açıldığında klavye odağı pencerenin `initial_focus` öğesine geçer, kapandığında eski yerine döner.
- Sinyaller: `screen_opened(screen)`, `screen_closed(screen)`. Sorgular: `has_open_screens()`, `get_top_screen()`.

Pencere, kökü `UiScreen` sınıfını (tam ekran bir `Control`) genişleten bir sahnedir. Pencere kendini asla kapatmaz:
`close_requested` sinyaliyle (`request_close()`) ister ve `UiRoot` onu kapatır. Çağrılar ağaçta aşağı, sinyaller
yukarı gider; böylece `UiRoot` hangi pencerelerin açık olduğunu her zaman bilir ve odağı ve duraklatmayı doğru
şekilde geri yükler. Tepki vermek için `_screen_opened()` ve `_screen_closed()` metotlarını geçersiz kılın.

**Yeni bir pencere:** kökü `UiScreen` olan, kapsayıcılarla yerleştirilmiş ve temayla biçimlendirilmiş bir sahne;
onu `UiRoot.open(scene)` ile açın.

## Ayarlar

### GameSettings

`Settings` otomatik yüklemesi (autoload; `gdscript/settings/game_settings.gd`, sınıf `GameSettings`) değerleri
tutar:

- Anahtarlar sınıfın sabitleridir (`GameSettings.LEDGE_GUARD` değeri `&"gameplay/ledge_guard"`); bu yüzden `match`
  içinde çalışırlar. Eğik çizgiden önceki kısım dosyadaki bölümdür.
- `DEFAULTS` her anahtarı varsayılan değeriyle tutar; varsayılan değerin türü ayarın türüdür. Dosyada (elle
  düzenlenmiş) yanlış türde bir değer varsayılana döner.
- `get_value(key)`, `set_value(key, value)`, `reset_to_defaults()` ve `changed(key, value)` sinyali.
- Değerler herhangi bir sahne düğümünün `_ready()` çağrısından önce, `_init()` içinde yüklenir ve ayarlar penceresi
  kapandığında ve oyundan çıkıldığında `user://settings.cfg` dosyasına kaydedilir. `persistent = false` kaydetmeyi
  durdurur; testler bunu ayarlar ve her şeyi varsayılanlara sıfırlar, böylece oyuncunun ayarlarını yok sayar ve
  hiçbir zaman üzerine yazmaz.
- `_OBSOLETE_KEYS` içinde listelenen anahtarlar yüklemede dosyadan kaldırılır.
- Motor düzeyindeki ayarları sınıfın kendisi uygular (`_apply_to_engine()`): tam ekran, kare hızı sınırı ve V-Sync,
  fizik enterpolasyonu, arayüz ölçeği, dil, ses düzeyi. Sahne düğümlerinin ayarlarını sahne uygular: demoda
  `gdscript/demo/settings_applier.gd` başlangıçta `get_value()` okur ve `changed` sinyalini dinler.

**Yeni bir ayar:**

1. `GameSettings` içinde bir anahtar sabiti ve `DEFAULTS` içinde bir varsayılan değer.
2. `settings_screen.tscn` içinde o anahtara bağlı bir arayüz öğesi (aşağıya bakın). Pencerenin kodu değişmez.
3. `settings_applier.gd` içinde özelliği ayarlayan bir dal ya da ayarı motor uyguluyorsa
   `GameSettings._apply_to_engine()` içinde.
4. Metinlerinin çevirileri, bkz. [Çeviriler](#çeviriler).

### Ayarlar penceresi

`gdscript/ui/settings/settings_screen.tscn` altı sekmeye sahiptir: Kontroller, Karakter, Kamera, Görüntü, Arayüz,
Ses. Tüm ayarlar ve varsayılan değerleri [Ayarlar](../settings.md) sayfasında listelenir.

- Her öğe kendini tek bir anahtara bağlar ve ayar herhangi bir yerde değiştiğinde güncellenir:
  - `SettingCheckButton`: mantıksal (boolean) bir ayar.
  - `SettingOptionButton`: tam sayı bir ayar; bir öğenin değeri, Denetçi'de (Inspector) metniyle birlikte ayarlanan
    kimliğidir (ID); bu yüzden öğeler serbestçe yeniden sıralanabilir.
  - `SettingSlider`: bir sayı. `value_label` değeri `value_format` ile gösterir; `zero_text` sıfırın yerine geçer
    (örneğin "anında"); `apply_on_release`, arayüzün kendisini yeniden boyutlandıran ayarlar için fareyle sürüklemeyi
    yalnızca bırakınca uygular. Sınırlar ve adım, `Range` özellikleridir.
  - `SettingLanguageButton`: arayüz dili, aşağıya bakın.
- Başka bir ayar olmadan anlamsız kalan öğeler soluklaşır ve kilitlenir: yana adım modu olmadan geri yavaşlama,
  zıplama olmadan zıplama yüksekliği, depar olmadan deparla ilgili her şey, yorgunluk olmadan dayanıklılık süresi,
  eğim hizalama olmadan eğim açısı, takip veya hizalama olmadan yetişme süresi (`_update_dependent_rows()`).
- Her sekme sayfası bir `ScrollContainer` düğümüdür: uzun bir sekme kaydırılır (klavye odağını da izleyerek) ve
  pencere büyümez. Pencere yüksekliği, `TabContainer` düğümünün `custom_minimum_size` değeridir (440). En uzun sekme
  olan Karakter sığar ve %100 arayüz ölçeğinde tüm pencere ekranda kalır.
- **Tümünü sıfırla**, `reset_to_defaults()` çağırır. Pencere kapandığında ayarları kaydeder.
- V-Sync ipucu, kod tarafından çevrilmiş bir cümle ve monitörün yenileme hızından oluşturulur.

### Arayüz ölçeği

Arayüz ölçeği, kök pencerenin `content_scale_factor` değeridir. `canvas_items` esnetme moduyla tüm 2B öğeleri
(ipucu, FPS sayacı, dayanıklılık çubuğu, pencereler) ölçekler ve 3B görünüme dokunmaz. %100 sahnelerde tasarlandığı
hâliyle boyut, %50 bunun yarısıdır. Fareyle sürüklenen kaydırıcı ölçeği yalnızca bırakınca uygular
(`apply_on_release`); aksi hâlde pencere farenin altında yeniden boyutlanır ve kaydırıcı fareden kayıp giderdi.
Klavye ve tekerlek ölçeği hemen değiştirir.

## HUD

| `main.tscn` içindeki düğüm | Betik | Ne gösterir |
|---|---|---|
| `Hud`, `Hud/Panel` | `Hud` üzerinde `gdscript/demo/hud.gd` | Kontrol ipuçları ve hız. Betik yalnızca hızı günceller; paneli `settings_applier.gd` gösterir veya gizler ve devre dışı özelliklerin satırlarını (sağ tuşla tuşlar, iki tuş + A/D, depar, zıplama) gizler |
| `Hud/FpsCounter` | `FpsCounter` (Label) | Sağ üst köşede saniyedeki kare sayısı; duraklatılmışken de çalışır |
| `Hud/DiscoveryToast` | `DiscoveryToast` (Label) | Oyuncu bir `PointOfInterest` alanına ilk kez girdiğinde `show_time` (3,5 sn) süresince "Keşfedildi: …". Tüm yerleri `points_of_interest` grubu üzerinden bulur; `show_discovery(title)` birini elle gösterir |
| `Hud/StaminaBar` | `StaminaBar` (ProgressBar) | Dayanıklılık harcanmaya başladığında belirir, karakter bitkinken kırmızıya döner (`StaminaBarExhausted` varyasyonu) ve yeniden dolunca 0,6 sn içinde solar |

İpucu paneli, FPS sayacı ve yol çizgisi Ayarlar → Arayüz içinde açılıp kapatılır.

## Tema

`shared/ui/ui_theme.tres` proje temasıdır (`gui/theme/custom`): paneller, pencere, düğmeler ve şu tür
varyasyonları: `WindowPanel`, `WindowLayout`, `TabPage`, `SettingsList`, `HintLabel`, `FpsCounter`, `DiscoveryToast`,
`StaminaBar`, `StaminaBarExhausted`. Düğümler stilleri tek tek geçersiz kılmak yerine `theme_type_variation` ile bir
varyasyon seçer.

## Çeviriler

Sahnelerin ve betiklerin kendi dili İngilizcedir. Diğer diller, `project.godot` içinde
(`internationalization/locale/translations`) kayıtlı, `l10n/ui/<locale>.po` dosyalarındaki gettext çevirileridir.
Dil, `interface/language` ayarıdır (Ayarlar → Arayüz → **Dil**, varsayılan olarak İngilizce); `GameSettings` onu
`TranslationServer.set_locale()` metoduna iletir ve arayüz yeniden başlatma gerekmeden hemen değişir.

Metinler nasıl çevrilir:

- **Sahnelerdeki metinleri** motor çevirir: `Label`, `Button` ve `CheckButton` metinleri, `OptionButton` öğeleri,
  araç ipuçları, sekme başlıkları ve NPC'lerin üstündeki `Label3D` metinleri (`auto_translate_mode`).
- **Kodla oluşturulan metinler** `tr()` kullanır: yer adıyla "Keşfedildi: …", birimli kaydırıcı değerleri ve V-Sync
  ipucu `NOTIFICATION_TRANSLATION_CHANGED` geldiğinde yeniden oluşturulur; hız göstergesi zaten her karede yeniden
  oluşturulur. Bu tür düğümler kendileri için otomatik çeviriyi kapatır; böylece motor oluşturulmuş sonucu çevirmeye
  çalışmaz.
- Dil listesindeki **dil adları** kendi dillerinde yazılır ("English", "Русский") ve hiçbir zaman çevrilmez
  (`SettingLanguageButton.NATIVE_NAMES`).

**Yeni bir dil:**

1. `l10n/ui/ru.po` dosyasını `l10n/ui/<locale>.po` olarak kopyalayın, başlıkta `Language` ve `Plural-Forms`
   değerlerini ayarlayın ve her `msgstr` girdisini çevirin. Poedit gibi bir PO düzenleyicisi işinizi kolaylaştırır.
2. Dosyayı `internationalization/locale/translations` ayarına ekleyin (Proje Ayarları → Yerelleştirme → Çeviriler;
   Project Settings → Localization → Translations).
3. Dilin kendi dilindeki adını `gdscript/ui/settings/setting_language_button.gd` içindeki `NATIVE_NAMES` içine
   ekleyin. Ayarlar penceresindeki liste yüklü çevirilerden oluşturulur, bu yüzden başka hiçbir şey değişmez.
4. Testleri çalıştırın: `tests/localization_checks.gd`, bir çeviride eksik olan her arayüz metnini ve oyunun artık
   göstermediği her çeviri girdisini bildirir.

**Yeni bir metin:** onu sahnede ya da `tr("...")` içinde İngilizce yazın, ardından her `.po` dosyasına çevirisiyle
birlikte bir `msgid` ekleyin. Test metinleri sahnelerden toplar; yalnızca betiklerin `tr()` metoduna verdiği metinler
`tests/localization_checks.gd` içindeki `SCRIPT_STRINGS` içinde listelenir, bu yüzden yenilerini oraya ekleyin.

---

*Bu sayfa Iso & Orbit 1.1.0 sürümüne karşılık gelir.*
