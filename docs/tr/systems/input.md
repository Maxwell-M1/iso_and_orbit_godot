<!-- translation of docs/en/systems/input.md @ 6012ceb531ff -->
# Girdi

> Bu, [İngilizce orijinalin](../../en/systems/input.md) çevirisidir; fark varsa İngilizce sürüm doğrudur.

İki düğüm oyuncu girdisini komutlara dönüştürür. İkisi de kendisi hiçbir şeyi hareket ettirmez.

- `PointClickMoveInput`: fare ve sağ tuş basılıyken WASD → `NavigationMover.move_to()`, `steer()` ve `stop()`.
- `CharacterActionInput`: depar ve zıplama tuşları → `GroundCharacter.sprint_requested` ve `jump()`.

İkisi de karakter sahnesinde değil, `main.tscn` içindedir; böylece aynı karakteri onların yerine yapay zekâ
yönetebilir. Kontrollerin oyuncu açısından anlatımı için bkz. [Kontroller](../controls.md).

## PointClickMoveInput

| Girdi | Komut |
|---|---|
| Zemine tıklama | `move_to(point)`: kameradan `ground_mask` üzerinde atılan bir ışın noktayı bulur |
| Sol tuş basılı | `hold_mode` değerine göre imlece doğru `steer()` ya da imlecin altındaki noktaya `move_to()` |
| Sol ve sağ tuş basılı | Kameranın baktığı yöne `steer()`; A ve D çapraz olarak ileriye saptırır (`keys_with_camera_steer`) |
| Sağ tuş ve WASD | Kameraya göre, yana adımla veya dönerek `steer()` (`keys_with_camera`); bırakınca `stop()` |

Bir tikte karakteri kimin yöneteceğine tek bir yerde, `_physics_process` içinde karar verilir: önce basılı sol tuş,
yoksa sağ tuşla birlikte klavye tuşları. Bu yüzden sağ tuş ve W basılıyken sol tuşu bırakmak karakteri durdurmaz:
tuşlar hemen devralır.

### Tıklama veya basılı tutma

Bir basış `hold_delay` (0,2 sn) sonrasında basılı tutmaya dönüşür. O zamana kadar karakter yaptığı şeyi sürdürür
(durur ya da koştuğu yere koşmaya devam eder); işaretçi ve basılan noktaya giden bir yol yoktur.

- **Daha erken bırakılırsa: tıklama.** Karakter, tuşa basıldığı noktaya bir yol boyunca koşar. Fare sonradan hareket
  etmiş olsa bile nokta basış anında alınır. İşaretçi belirir (`destination_picked`). Karakter vardığında ya da
  koşudan tuşlar veya basılı tutma uğruna vazgeçildiğinde solar.
- **Daha uzun basılı tutulursa: basılı tutma.** Karakter hemen imlecin peşinden koşar (`hold_started`) ve önce
  basılan noktaya doğru dönmez. Aksi hâlde o noktaya giden yola koyulurdu; engellerin etrafından dolanan bir yol ise
  imleçten bambaşka bir yere götürebilir.

Bunun bedeli, tıklamanın bırakınca, yani basışa göre yaklaşık 0,1 sn daha geç etki etmesidir. Bir basışın tıklama mı
basılı tutma mı olduğu belirsizken `hold_pending_changed(true)` kameranın takip modunu duraklatır; böylece kısa bir
tıklama kamerayı hiçbir zaman oynatmaz.

Sol tuşa basıldığında sağ tuş zaten basılıysa tıklama olmaz: karakter hemen kameranın baktığı yöne koşar.

### Basılı tutma modları

`hold_mode` (Ayarlar → Kontroller → **Basılı sol tuş**):

- `STEER` (varsayılan): yolsuz olarak doğrudan imlece doğru. Karakter engeller boyunca kayar ve rampaya nereden
  yönlendirirseniz oradan çıkar. Karakterin `steer_dead_zone` (0,5 m) yakınında yön değişmez: bu kadar yakında yön
  imlece fazla duyarlı olur. Bırakınca karakter yumuşakça durur.
- `FOLLOW_POINT`: imlecin altındaki noktaya bir navigasyon yolu boyunca. Nokta hareket ederken yol yeniden
  oluşturulur; bu yüzden yükseklik değişimlerinin yakınında (rampa, platform) bir rotadan diğerine atlayabilir.
  Bırakınca karakter son noktaya kadar koşmayı sürdürür ve işaretçi o noktayı gösterir (`destination_picked`);
  `stop_on_release` açıksa bulunduğu yerde frenleyerek durur.

### Sağ tuşla kullanılan tuşlar

Tuşlar yalnızca sağ tuş basılıyken çalışır: kamera fareyle döner ve imleç yakalanır. Sağ tuş olmadan WASD hiçbir şey
yapmaz. Her mod `OFF` ya da iki seçenekten biridir ve yalnız sağ tuş (`keys_with_camera`) ile iki tuş birlikte
(`keys_with_camera_steer`) için ayrı ayrı ayarlanır.

| | `SIDESTEP` | `TURN` |
|---|---|---|
| Sağ tuş + W | ileri, kameranın baktığı yöne | aynısı |
| Sağ tuş + A / D | yana, yüz önde | sola / sağa döner ve o yöne gider |
| Sağ tuş + S | geriye, yüz önde, daha yavaş | geri döner ve kameraya doğru yürür |
| İki tuş (W + A, S + D…) | çapraz, yüz önde | çapraz, yüz gidiş yönünde |
| Sol + sağ tuş + A / D | çapraz ileri, yüz önde | çapraz ileri, yüz gidiş yönünde |

Betik varsayılanı ikisi için de `SIDESTEP`, demonun ayar varsayılanı ise ikisi için de `TURN`.

Çapraz hareket, düz hareket kadar hızlıdır. Geriye hareket daha yavaştır: `NavigationMover` hızı, hareketin bakış
yönüne ne kadar ters olduğuna göre ölçekler, bkz. [Hareket](locomotion.md#navigationmover). Bakış yönü
`steer(direction, facing)` çağrısının ikinci argümanı olarak verilir: yana adımda bu, kameranın ileri yönüdür.
Durduktan sonra karakter baktığı yöne bakmayı sürdürür; bir tıklama ya da basılı tutma onu yeniden koştuğu yöne
çevirir.

Tuşları ya da sağ tuşu bırakın, karakter yumuşakça durur. Tuşlar olmadan tek başına sağ tuş, tıklanan noktaya koşuyu
kesmez; böylece koşarken kamerayı çevirebilirsiniz. Tuşlar ise koşuyu keser ve işaretçi solar. Tuşlar, fiziksel
konuma göre atanmış `move_forward`, `move_back`, `move_left`, `move_right` eylemleridir.

### Tuş basılıyken imleç

**Gizli** (`hide_cursor_while_held`, varsayılan olarak açık). Koşarken imleç yalnızca titreşirdi, özellikle kamera
dönerken ve imleç dünyayla birlikte hareket ederken. Basış basılı tutmaya dönüştüğü anda gizlenir (kısa bir tıklama
ona dokunmaz) ve bırakınca nişan aldığınız yerde yeniden belirir. Bu sırada fare modu `MOUSE_MODE_CONFINED_HIDDEN`
olur: sıradan gizli bir imleç pencereden çıkıp kenarında belirebilirdi. Sağ tuş kamerayı döndürürken imleci kamera
yakalar; sol tuş hâlâ basılıyken sağ tuşu bırakırsanız imleç yeniden gizlenir. Duraklatma (ayarlar penceresi) veya
başka bir pencereye geçme imleci hemen gösterir. `is_cursor_hidden()`, bileşenin imleci gizleyip gizlemediğini
söyler.

**Hedefini korur** (`keep_aim_on_camera_turn`, varsayılan olarak açık). Sol tuş basılıyken koşu yönü imleçten, yani
ekrandaki bir noktadan gelir. İmleç ekranda sabit dururken kamera dönerse imlecin altına zeminin farklı bir noktası
gelir, karakter ona doğru döner, kamera karakterin ardından döner ve karakter daireler çizerek koşar (demonun 1,1 sn
yetişme süresiyle 1,25 sn'de 77,6°; "anında" ile yerinde fırıl fırıl döner). Bu yüzden tuş basılıyken bileşen sistem
imlecini dünyayla birlikte hareket ettirir (`Viewport.warp_mouse()`): imleç zeminde aynı noktanın üstünde kalır,
karakter nişan aldığınız yere koşar ve kamera yavaşça arkasına geçer. Fareyi hareket ettirmek karakteri her zamanki
gibi döndürür. Bırakıldıktan sonra imlece dokunulmaz.

Kapalıyken imleç bir araba gibi yönlendirir: imleci karakterin sağında tutun, karakter imleç tam önüne gelene kadar
sağa kıvrılır. Sistemin imleci hareket ettiremediği yerlerde (örneğin Wayland) koşu yönü yine korunur, ancak imleç
yerinde kalır.

İmleç, kamera o kare için yerine oturduktan sonra `_process` içinde düzeltilir: bileşenin `process_priority` değeri
1, kameranınki 0'dır. Girdi `Camera3D` düğümünü doğrudan okur ve kamera düzeneği hakkında hiçbir şey bilmez.

### Özellikler

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `mover` | — | Komut verilecek `NavigationMover`; zorunlu |
| `camera` | — | Işınlar ve yönler için kamera; boşsa görüntü kapısının (viewport) geçerli kamerası |
| `move_action` | `move_to_cursor` | Tıklama ve basılı tutma |
| `hold_mode` | `STEER` | Yukarıya bakın |
| `keep_aim_on_camera_turn` | açık | Yukarıya bakın |
| `hide_cursor_while_held` | açık | Yukarıya bakın |
| `camera_steer_action` | `camera_rotate` | Bu basılıyken basılı tutma, kameranın baktığı yöne koşturur; boşsa devre dışıdır |
| `ground_mask` | 1. katman | Tıklanabilen fizik katmanları. Karakterlerin katmanını içermemelidir |
| `hold_delay` | 0,2 sn | Bir basışın ne zaman basılı tutmaya dönüştüğü |
| `steer_dead_zone` | 0,5 m | `STEER`: imleç karaktere bu kadar yakınken yön değişmez |
| `stop_on_release` | kapalı | `FOLLOW_POINT`: bırakınca son noktaya koşmak yerine frenleyerek dur |
| `ray_length` | 1000 m | Kameradan atılan ışının uzunluğu |
| `keys_with_camera` | `SIDESTEP` | Sağ tuş + WASD modu |
| `keys_with_camera_steer` | `SIDESTEP` | Sol + sağ tuş + A/D modu |
| `move_forward_action` … `move_right_action` | `move_forward` … `move_right` | Tuşlar |

Sinyaller: `destination_picked(point)`, `hold_started`, `hold_pending_changed(pending)`.

Bileşen başlangıçta girdi eylemlerinin var olup olmadığını denetler ve eksik olanı hata olarak bildirir.

## CharacterActionInput

| Özellik | Varsayılan | Anlamı |
|---|---|---|
| `character` | — | Komut verilecek `GroundCharacter` |
| `sprint_action` | `sprint` | Shift |
| `jump_action` | `jump` | Boşluk |
| `sprint_mode` | `HOLD` | `HOLD`: tuş basılıyken depar. `TOGGLE`: bir basış deparı açar, bir sonraki kapatır; karakter bitkin düştüğünde de kendiliğinden kapanır ve dinlendikten sonra geri gelmez |

Bileşen yalnızca girdiyi iletir; depar için dayanıklılık olup olmadığına ve şu an zıplayıp zıplayamayacağına
karakter karar verir. Fizik tikinde karakterden önce çalışır (`process_physics_priority = -1`); böylece bir basış ve
bırakma karaktere fazladan bir tik gecikme olmadan ulaşır. `is_sprint_toggled()`, `TOGGLE` durumunu söyler.

### Shift takılmaz

`HOLD` modunda depar her tikte `Input.is_action_pressed()` ile okunur, bu yüzden Shift'i bırakmak onu bitirir. Bu,
gerçek olaylarla denetlenir: koşarken, sol tuş basılı koşarken, Shift'i ayarlar penceresinde bırakırken, mod
değiştirdikten sonra.

Ancak bırakmanın kendisi bazen oyuna hiç ulaşmaz ve motor, Shift yeniden basılana kadar onu basılı sayar. Bu, oyun
editörün Oyun (Game) sekmesine gömülüyken odak editöre geçtiğinde (`Input.release_pressed_events()` editör penceresi
odaktayken sıfırlamayı atlar) ya da bir sistem kısayolu bırakmayı yuttuğunda olur. Bu durum için bileşen, deparı her
fare ve klavye olayının taşıdığı gerçek Shift durumuyla karşılaştırır (`shift_pressed`; Windows'ta
`GetKeyboardState` üzerinden gelir). Depar tuşunun kendisi dışındaki herhangi bir fare veya klavye olayı Shift'in
bırakıldığını söylerse takılı kalan basış bırakılır. Bu, depar eylemine atanmış her tuş bir değiştirici tuş olduğunda
(Shift, Ctrl, Alt, Meta) çalışır.

Windows Yapışkan Tuşlar (Sticky Keys) özelliğini açarsa (art arda beş Shift basışı), Shift sistemin kendisinde
takılı kalır; bunu Windows ayarlarından kapatın.

---

*Bu sayfa Iso & Orbit 1.0.0 sürümüne karşılık gelir.*
