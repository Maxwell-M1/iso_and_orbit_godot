<!-- translation of docs/en/systems/ui.md @ 40a5a08ac8d9 -->
# UI

> これは[英語の原文](../../en/systems/ui.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

ゲームの上に重なるウィンドウ、設定システム、HUD、インターフェースの翻訳について説明します。

## ウィンドウ：UiRootとUiScreen

`UiRoot`（`CanvasLayer`、`addons/iso_orbit/ui_screens/ui_root.gd`。デモのインスタンスは`gdscript/ui/ui_root.tscn`）は、ウィンドウをスタックとして表示します。

- `open(scene)`はウィンドウを最前面に置き、`close_top()`は最前面のウィンドウを閉じ、`toggle(scene)`は開いているウィンドウ（とその上にあるものすべて）を閉じるか、ウィンドウを開きます。Esc（`ui_cancel`）は最前面のウィンドウを閉じ、F10（`toggle_settings`）は設定ウィンドウ（`settings_screen`）の開閉を切り替えます。
- ウィンドウが1つでも開いている間はゲームが一時停止し（`pause_game`）、マウスカーソルが表示されます。`UiRoot`は`PROCESS_MODE_ALWAYS`で動作し、そのウィンドウもそれを継承します。
- キーボードフォーカスは、ウィンドウが開くとその`initial_focus`へ移り、閉じると元の場所に戻ります。
- シグナル：`screen_opened(screen)`、`screen_closed(screen)`。問い合わせ：`has_open_screens()`、`get_top_screen()`。

ウィンドウは、ルートが`UiScreen`（全画面の`Control`）を継承するシーンです。ウィンドウが自分で閉じることはありません。`close_requested`シグナル（`request_close()`）で要求し、`UiRoot`がそれを閉じます。呼び出しはツリーを下り、シグナルは上るので、`UiRoot`はどのウィンドウが開いているかを常に把握しており、フォーカスと一時停止を正しく元に戻せます。反応させるには`_screen_opened()`と`_screen_closed()`をオーバーライドします。

**新しいウィンドウ**：ルートが`UiScreen`のシーンを作り、コンテナでレイアウトしてテーマでスタイルを付けます。`UiRoot.open(scene)`で開きます。

## 設定

### GameSettings

`Settings`自動読み込み（Autoload。`gdscript/settings/game_settings.gd`、クラス`GameSettings`）が値を保持します。

- キーはクラスの定数（`GameSettings.LEDGE_GUARD`は`&"gameplay/ledge_guard"`）なので、`match`で使えます。スラッシュの前の部分は、ファイル内のセクションです。
- `DEFAULTS`はすべてのキーとそのデフォルト値を持ち、デフォルト値の型がその設定の型になります。ファイル内の値の型が間違っている場合（手で編集したなど）は、デフォルト値に戻ります。
- `get_value(key)`、`set_value(key, value)`、`reset_to_defaults()`と、シグナル`changed(key, value)`。
- 値はどのシーンノードの`_ready()`よりも前に`_init()`で読み込まれ、設定ウィンドウを閉じたときとゲームの終了時に`user://settings.cfg`へ保存されます。`persistent = false`で保存が止まります。テストはこれを設定してすべてをデフォルトに戻すので、プレイヤーの設定を無視し、上書きすることもありません。
- `_OBSOLETE_KEYS`に挙げられたキーは、読み込み時にファイルから削除されます。
- エンジンレベルの設定は、クラス自身が適用します（`_apply_to_engine()`）：フルスクリーン、フレームレート上限とV-Sync、物理補間、UIスケール、言語、音量。シーンノードの設定はシーン側で適用します。デモでは、`gdscript/demo/settings_applier.gd`が起動時に`get_value()`を読み、`changed`を受け取ります。

**新しい設定**：

1. `GameSettings`にキーの定数と、`DEFAULTS`のデフォルト値を追加します。
2. `settings_screen.tscn`にそのキーを持つコントロールを追加します（下記参照）。ウィンドウのコードは変更しません。
3. `settings_applier.gd`にプロパティを設定する分岐を追加します。エンジンが適用する設定なら、`GameSettings._apply_to_engine()`に追加します。
4. そのテキストを翻訳に追加します。[翻訳](#翻訳)を参照してください。

### 設定ウィンドウ

`gdscript/ui/settings/settings_screen.tscn`には6つのタブがあります：操作、キャラクター、カメラ、表示、インターフェース、サウンド。すべての設定とそのデフォルト値は[設定](../settings.md)に記載しています。

- 各コントロールは自身を1つのキーに結び付け、設定がどこで変わっても更新されます。
  - `SettingCheckButton`：真偽値の設定。
  - `SettingOptionButton`：整数の設定。項目の値はそのIDで、インスペクター（Inspector）でテキストと一緒に設定するので、項目は自由に並べ替えられます。
  - `SettingSlider`：数値。`value_label`は`value_format`で値を表示し、`zero_text`は0を置き換えます（たとえば「即時」）。`apply_on_release`はマウスでのドラッグを離したときにだけ適用します。インターフェース自体の大きさを変える設定用です。範囲とステップは`Range`のプロパティです。
  - `SettingLanguageButton`：インターフェースの言語。下記参照。
- 別の設定がないと意味をなさないコントロールは、薄く表示されてロックされます：横移動モードでないときの後退の減速、ジャンプがオフのときのジャンプの高さ、ダッシュがオフのときのダッシュ関連すべて、疲労がオフのときのスタミナ持続時間、傾きの揃えがオフのときの見下ろし角、追従と傾きの揃えがどちらもオフのときの追従時間（`_update_dependent_rows()`）。
- 各タブのページは`ScrollContainer`です。長いタブはスクロールし（キーボードフォーカスにも追従）、ウィンドウは大きくなりません。ウィンドウの高さは`TabContainer`の`custom_minimum_size`（440）です。最も長いキャラクタータブも収まり、UIスケール100%でもウィンドウ全体が画面内に収まります。
- **すべてリセット**は`reset_to_defaults()`を呼びます。ウィンドウは閉じるときに設定を保存します。
- V-Syncのヒントは、翻訳された文とモニターのリフレッシュレートからコードで組み立てられます。

### UIスケール

UIスケールはルートウィンドウの`content_scale_factor`です。ストレッチモード`canvas_items`では、すべての2D（ヒント、FPSカウンター、スタミナバー、ウィンドウ）を拡縮し、3Dビューには影響しません。100%はシーンで作成したときのサイズ、50%はその半分です。マウスでドラッグしたスライダーは、離したときにだけスケールを適用します（`apply_on_release`）。そうしないと、マウスの下でウィンドウの大きさが変わり、スライダーがマウスから逃げてしまいます。キーボードとホイールでは、スケールはすぐに変わります。

## HUD

| `main.tscn`内のノード | スクリプト | 表示内容 |
|---|---|---|
| `Hud`、`Hud/Panel` | `Hud`に付いた`gdscript/demo/hud.gd` | 操作ヒントと速度。スクリプトは速度を更新するだけで、パネルの表示・非表示と、無効になった機能（右ボタンと組み合わせるキー、両ボタン + A/D、ダッシュ、ジャンプ）の行を隠す処理は`settings_applier.gd`が行う |
| `Hud/FpsCounter` | `FpsCounter`（Label） | 右上の毎秒フレーム数。一時停止中も動作する |
| `Hud/CharacterState/Monitor` | `CharacterMonitor`（Label） | FPSカウンターの下に、主人公が何をしているか（状態、速度とブレンド、移動、旋回、地上か空中か、ステップと足、スタミナ）と最新のイベントを表示する。デフォルトでは非表示。[ロコモーション](locomotion.md#charactermonitor状態をテキストで)を参照 |
| `Hud/DiscoveryToast` | `DiscoveryToast`（Label） | プレイヤーが初めて`PointOfInterest`に入ったとき、「発見：…」を`show_time`（3.5秒）の間表示する。`points_of_interest`グループを通じてすべての場所を見つける。`show_discovery(title)`で手動で表示できる |
| `Hud/StaminaBar` | `StaminaBar`（ProgressBar） | スタミナの消費が始まると現れ、キャラクターが疲労困憊の間は赤くなり（`StaminaBarExhausted`バリエーション）、再び満タンになると0.6秒かけて消える |

ヒントのパネル、FPSカウンター、経路線、キャラクターの状態パネルは、設定 → インターフェースで切り替えます。

## テーマ

`shared/ui/ui_theme.tres`はプロジェクトのテーマ（`gui/theme/custom`）です：パネル、ウィンドウ、ボタンと、次のタイプバリエーション：`WindowPanel`、`WindowLayout`、`TabPage`、`SettingsList`、`HintLabel`、`FpsCounter`、`DiscoveryToast`、`StaminaBar`、`StaminaBarExhausted`。ノードはスタイルを1つずつオーバーライドする代わりに、`theme_type_variation`でバリエーションを選びます。

## 翻訳

シーンとスクリプト自体の言語は英語です。ほかの言語は`l10n/ui/<locale>.po`にあるgettextの翻訳で、`project.godot`（`internationalization/locale/translations`）に登録されています。言語は設定`interface/language`（設定 → インターフェース → **言語**、デフォルトは英語）で決まります。`GameSettings`がそれを`TranslationServer.set_locale()`に渡し、インターフェースは再起動なしですぐに切り替わります。

テキストの翻訳方法：

- **シーン内のテキスト**はエンジンが翻訳します：`Label`、`Button`、`CheckButton`のテキスト、`OptionButton`の項目、ツールチップ、タブのタイトル、NPCの頭上の`Label3D`のテキスト（`auto_translate_mode`）。
- **コードで組み立てるテキスト**は`tr()`を使います。場所の名前を含む「発見：…」、単位付きのスライダーの値、V-Syncのヒントは、`NOTIFICATION_TRANSLATION_CHANGED`で組み立て直されます。速度表示はどのみち毎フレーム組み立て直されます。こうしたノードは自身の自動翻訳をオフにしているので、エンジンが組み立て済みの結果を翻訳しようとすることはありません。
- 言語リストの**言語名**は、その言語自身で書かれ（「English」「Русский」）、翻訳されることはありません（`SettingLanguageButton.NATIVE_NAMES`）。

**新しい言語**：

1. `l10n/ui/ru.po`を`l10n/ui/<locale>.po`にコピーし、ヘッダーの`Language`と`Plural-Forms`を設定して、すべての`msgstr`を翻訳します。PoeditのようなPOエディターが便利です。
2. そのファイルを`internationalization/locale/translations`に追加します（プロジェクト設定 → ローカライズ → 翻訳（Project Settings → Localization → Translations））。
3. `gdscript/ui/settings/setting_language_button.gd`の`NATIVE_NAMES`に、その言語自身での名前を追加します。設定ウィンドウのリストは読み込まれた翻訳から作られるので、ほかに変更は必要ありません。
4. テストを実行します。`tests/localization_checks.gd`は、翻訳に欠けているインターフェース文字列と、ゲームがもう表示しない翻訳エントリーをすべて報告します。

**新しい文字列**：シーン内か`tr("...")`の中に英語で書き、すべての`.po`ファイルに`msgid`とその翻訳を追加します。テストはシーンから文字列を集めます。スクリプトだけが`tr()`に渡す文字列は`tests/localization_checks.gd`の`SCRIPT_STRINGS`に列挙されているので、新しいものはそこに追加してください。

---

*このページは Iso & Orbit 1.1.0 に対応しています。*
