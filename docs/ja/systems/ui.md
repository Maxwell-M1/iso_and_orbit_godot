<!-- translation of docs/en/systems/ui.md @ 8fc9a768e40b -->
# UI

[← ドキュメント目次](../index.md)

> これは[英語の原文](../../en/systems/ui.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

ゲームの上に重なるウィンドウ、設定システム、HUD、インターフェースの翻訳について説明します。

## ウィンドウ：UiRootとUiScreen

`UiRoot`（`CanvasLayer`、`addons/iso_orbit/ui_screens/ui_root.gd`。デモのインスタンスは`gdscript/ui/ui_root.tscn`）は、ウィンドウをスタックとして表示します。

- `open(scene)`はウィンドウを最前面に置き、`close_top()`は最前面のウィンドウを閉じ、`toggle(scene)`は開いているウィンドウ（とその上にあるものすべて）を閉じるか、ウィンドウを開きます。Esc（`ui_cancel`）は最前面のウィンドウを閉じ、F10（`toggle_settings`）は設定ウィンドウ（`settings_screen`）の開閉を切り替えます。
- ウィンドウが1つでも開いている間はゲームが一時停止し（`pause_game`）、マウスカーソルが表示されます。`UiRoot`が停止するのは実行中のゲームだけで、自身で開始した停止だけを解除します。レベル切り替えなどですでに停止しているときにウィンドウを開くと、元の処理が停止を管理します。その処理が解除すればウィンドウの背後でゲームが進みます（[レベル](levels.md#レベル切り替えの流れ)を参照）。`UiRoot`は`PROCESS_MODE_ALWAYS`で動作し、ウィンドウも継承します。
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
- 別の設定がないと意味をなさないコントロールは薄く表示され、変更できません。横移動なしの後退減速、ジャンプなしのジャンプ高、ダッシュなしのダッシュ関連、疲労なしのスタミナ持続時間、旋回なしの回転時間、傾きの調整なしの角度と時間、高さの調整なしの高さと時間、浮遊中で歩数のない足音が該当します（`_update_dependent_rows()`）。
- 各タブは`ScrollContainer`です。長いタブはキーボードフォーカスに追従してスクロールし、ウィンドウは大きくなりません。高さは`TabContainer`の`custom_minimum_size`（440）です。カメラ（最長）とキャラクターのタブはスクロールし、UIスケール100%でも全体が画面内に収まります。
- **すべてリセット**は`reset_to_defaults()`を呼びます。ウィンドウは閉じるときに設定を保存します。
- V-Syncのヒントは、翻訳された文とモニターのリフレッシュレートからコードで組み立てられます。

### UIスケール

UIスケールはルートウィンドウの`content_scale_factor`です。ストレッチモード`canvas_items`では、すべての2D（ヒント、FPSカウンター、スタミナバー、ウィンドウ）を拡縮し、3Dビューには影響しません。100%はシーンで作成したときのサイズ、50%はその半分です。マウスでドラッグしたスライダーは、離したときにだけスケールを適用します（`apply_on_release`）。そうしないと、マウスの下でウィンドウの大きさが変わり、スライダーがマウスから逃げてしまいます。キーボードとホイールでは、スケールはすぐに変わります。

## HUD

| `main.tscn`内のノード | スクリプト | 表示内容 |
|---|---|---|
| `Hud`、`Hud/Panel` | `Hud`に付いた`gdscript/demo/hud.gd` | 現在のキー名を示す操作ヒント（`Hud/ActionTexts`。[文章内のキー名](#文章内のキー名)を参照）と実際の移動速度（`GroundCharacter.get_move_speed()`。壁に向かっていれば0）。スクリプトは速度だけを更新し、`settings_applier.gd`がパネルや無効な機能の行（見回し、右ボタン＋キー、両ボタン＋A/D、ダッシュ、ジャンプ）を隠す |
| `Hud/FpsCounter` | `FpsCounter`（Label） | 右上の毎秒フレーム数。一時停止中も動作する |
| `Hud/CharacterState/Monitor` | `CharacterMonitor`（Label） | FPSカウンターの下に、主人公が何をしているか（状態、速度とブレンド、移動、旋回、地上か空中か、ステップと足、スタミナ）と最新のイベントを表示する。デフォルトでは非表示。[ロコモーション](locomotion.md#charactermonitor状態を文字で表示)を参照 |
| `Hud/DiscoveryToast` | `DiscoveryToast`（Label） | プレイヤーが初めて`PointOfInterest`に入ったとき「発見：…」を`show_time`（3.5 s）表示する。`points_of_interest`グループから、後で読み込まれたレベルを含むすべての場所を探す（`watch_added_places`はオン。オフなら起動時の場所だけ）。`show_discovery(title)`で手動表示もできる |
| `Hud/StaminaBar` | `StaminaBar`（ProgressBar） | スタミナの消費が始まると現れ、キャラクターが疲労困憊の間は赤くなり（`StaminaBarExhausted`バリエーション）、再び満タンになると0.6秒かけて消える |
| `Hud/TravelPrompt` | `TravelPrompt`（Control）、`gdscript/ui/travel_prompt.gd` | スタミナバーの上に出るテレポートパッドの移動案内。`interact`のキーをバッジに示し（ヒントと同じ`InputNames.of_action()`）、「○○へテレポート」を表示する。キーまたはクリックで確定（`confirmed(portal)`）し、ダッシュ後のShiftなど修飾キーを押していても使える。ボタンはキーボードフォーカスを取らず、Spaceはジャンプのまま。ウィンドウではなくゲームは進み続ける |

ローディング画面（`main.tscn`の`LoadingScreen`、`levels`アドオン）はHUDではなく、レベル切り替え中にゲームを覆います。[レベル](levels.md#ローディング画面)を参照してください。画面の取り込み中はHUDが隠れ、その後画面の背後で戻ります。

ヒントのパネル、FPSカウンター、経路線、キャラクターの状態パネルは、設定 → インターフェースで切り替えます。

## テーマ

`shared/ui/ui_theme.tres`はプロジェクトのテーマ（`gui/theme/custom`）です。パネル、ウィンドウ、ボタンと、`WindowPanel`、`WindowLayout`、`TabPage`、`SettingsList`、`HintLabel`、`FpsCounter`、`DiscoveryToast`、`StaminaBar`、`StaminaBarExhausted`、`KeyBadge`、`TravelButton`のタイプバリエーションを持ちます。ノードは個別にスタイルを上書きせず`theme_type_variation`を選びます。ローディング画面はアドオン内の独自テーマ`loading_screen_theme.tres`を持ち、どのプロジェクトでも同じ見た目になります。

## 翻訳

シーンとスクリプト自体の言語は英語です。ほかの言語は`l10n/ui/<locale>.po`にあるgettextの翻訳で、`project.godot`（`internationalization/locale/translations`）に登録されています。言語は設定`interface/language`（設定 → インターフェース → **言語**、デフォルトは英語）で決まります。`GameSettings`がそれを`TranslationServer.set_locale()`に渡し、インターフェースは再起動なしですぐに切り替わります。

テキストの翻訳方法：

- **シーン内のテキスト**はエンジンが翻訳します。`Label`、`Button`、`CheckButton`のテキスト、`OptionButton`の項目、ツールチップ、タブ名、NPCの頭上やテレポートパッドの看板の`Label3D`テキスト（`auto_translate_mode`）が対象です。ローディング画面のタイトルはスクリプトがラベルに設定しますが、同じ方法で翻訳されます。ヒントはスクリプトが翻訳し、その後でキーを埋め込みます（`tip_format`）。
- **コードで組み立てるテキスト**は`tr()`を使います。場所名を含む「発見：…」、移動案内「%sへテレポート」、単位付きスライダー、V-Syncのヒントは`NOTIFICATION_TRANSLATION_CHANGED`で再構築し、速度は毎フレーム更新します。こうしたノードは自身の自動翻訳をオフにして、完成した文をエンジンが再翻訳しないようにします。
- 言語リストの**言語名**は、その言語自身で書かれ（「English」「Русский」）、翻訳されることはありません（`SettingLanguageButton.NATIVE_NAMES`）。

**新しい言語**：

1. `l10n/ui/ru.po`を`l10n/ui/<locale>.po`にコピーし、ヘッダーの`Language`と`Plural-Forms`を設定して、すべての`msgstr`を翻訳します。PoeditのようなPOエディターが便利です。
2. そのファイルを`internationalization/locale/translations`に追加します（プロジェクト設定 → ローカライズ → 翻訳（Project Settings → Localization → Translations））。
3. `gdscript/ui/settings/setting_language_button.gd`の`NATIVE_NAMES`に、その言語自身での名前を追加します。設定ウィンドウのリストは読み込まれた翻訳から作られるので、ほかに変更は必要ありません。
4. テストを実行します。`tests/localization_checks.gd`は欠けたUI文字列、もう表示しない翻訳エントリー、キーのトークンを失った翻訳を報告します。

**新しい文字列：**シーン内か`tr("...")`の中に英語で書き、キーは下記のトークンで表し、すべての`.po`に`msgid`と翻訳を追加します。テストは`ActionTexts`のテンプレートも含めシーンから文字列を集めます。スクリプトだけが`tr()`へ渡す文は`tests/localization_checks.gd`の`SCRIPT_STRINGS`へ追加してください。

### 文章内のキー名

文中に固定のキー名は書かず、入力アクションを波括弧で書きます。表示時に現在割り当てられたキーへ変わります。`{sprint} — run faster`は「Shift — 速く走る」と表示され、Ctrlへ変更すれば「Ctrl — 速く走る」です。Input Mapでキーを変えるゲームでもヒントが正しく保たれます。`ui_screens`アドオンの`InputNames`がキー名を求めます。

- `{action}`：そのアクションの最初のキーまたはマウスボタン。文字キーはプレイヤーの配列上の名前で、QWERTYとロシア語配列ではW、AZERTYではZです。修飾キーも含み（`Ctrl+S`）、マウスボタンは左・右・中央やホイール上などの短い名前で示します。物理キーで左または右だけに割り当てると`Ctrl+Right Shift`のように側も示し、論理キー割り当ては両側に一致します。
- `{a/b}`：複数アクションをスラッシュで区切ります。`{move_left/move_right}`は「A/D」です。ホイールの上と下の2つなら「ホイール」と表示します。
- `{a+b+c+d}`：それぞれ1文字なら続けて表示します。`{move_forward+move_left+move_back+move_right}`は「WASD」、それ以外はスラッシュ区切りです。
- イベントのないアクションは「未割り当て」と表示します。Input Mapに存在しないアクションのトークンはそのまま残り、欠落に気付けます。

名前も翻訳されます。マウス名（`InputNames.get_mouse_names()`）、「Space」、「Unbound」、「Left %s」、「Right %s」には`.po`に項目があります。ほかのキー名は各言語で同じです。翻訳では元の文のトークンを保ちます。失うか変更すると`localization_checks.gd`が失敗します。

名前を埋め込む場所：

- **`ActionTexts`**はシーン内の`Node`で、親または`root`の下にある、テキスト、ツールチップ、`OptionButton`項目にトークンを持つコントロールを処理します。元の文をテンプレートとして保持し、コントロール自身の翻訳をオフにして、翻訳とキー名を埋め込んだ文を設定します。言語変更後も更新します。HUD（`Hud/ActionTexts`）と設定ウィンドウ（ルートの`ActionTexts`）に各1つあります。トークンのないコントロールは子の翻訳継承を含めそのままで、明示的に翻訳しないコントロールは元の文を保ちつつキー名だけローカライズします。スクリプトでテキストを設定するコントロールは対象から外します。更新するとテンプレートで上書きされるためです。キー変更後は`get_tree().call_group(ActionTexts.GROUP, &"refresh")`ですべてを更新します。
- **コード**では、文全体には`InputNames.format(tr(text))`、単独のキーには`InputNames.of_action(&"interact")`を使います（移動案内のバッジ）。`TravelPrompt`は`ActionTexts.GROUP`に属し、同じ更新で表示中のバッジも変わります。
- **ローディング画面のヒント**では、`LoadingScreen.tip_format`が翻訳済みヒントを表示文へ変える`Callable`です。`gdscript/main.gd`はこれを`InputNames.format`に設定し、画面を`ActionTexts.GROUP`に追加します。`LoadingScreen.refresh()`はタイマーを変えずに現在のヒントを再整形します。`levels`アドオンは`ui_screens`を必要とせず、`tip_format`がなければ翻訳した文をそのまま表示します。

起動前にProject Settings → Input Mapで変更した場合は、最初から新しいキー名が使われます。実行中に`InputMap`から変更した場合はグループの更新を呼んでください。一時停止中も動きます。デモの設定ウィンドウにはキー割り当てタブはありません。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
