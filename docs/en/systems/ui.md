# UI

[← Documentation index](../index.md)

Windows over the game, the settings system, the HUD and interface translations.

## Windows: UiRoot and UiScreen

`UiRoot` (a `CanvasLayer`, `addons/iso_orbit/ui_screens/ui_root.gd`; the demo's instance is `gdscript/ui/ui_root.tscn`)
shows windows as a stack:

- `open(scene)` puts a window on top, `close_top()` closes the top one, `toggle(scene)` closes a window that is open
  (and everything above it) or opens it. Esc (`ui_cancel`) closes the top window; F10 (`toggle_settings`) toggles the
  settings window (`settings_screen`).
- While any window is open the game is paused (`pause_game`) and the mouse cursor is visible. `UiRoot` pauses only a
  running game and ends only its own pause: a game already paused when a window opens stays with whoever paused it,
  and if that ends the pause, the game goes on behind the window (see [Levels](levels.md#a-level-change)). `UiRoot`
  runs in `PROCESS_MODE_ALWAYS` and its windows inherit that.
- Keyboard focus goes to the window's `initial_focus` when it opens and returns to where it was when it closes.
- Signals: `screen_opened(screen)`, `screen_closed(screen)`. Queries: `has_open_screens()`, `get_top_screen()`.

A window is a scene whose root extends `UiScreen`, a full-screen `Control`. A window never closes itself: it asks
with the `close_requested` signal (`request_close()`), and `UiRoot` closes it. Calls go down the tree and signals go
up, so `UiRoot` always knows which windows are open and restores focus and the pause correctly. Override
`_screen_opened()` and `_screen_closed()` to react.

**A new window:** a scene with a `UiScreen` root, laid out with containers and styled by the theme; open it with
`UiRoot.open(scene)`.

## Settings

### GameSettings

The `Settings` autoload (`gdscript/settings/game_settings.gd`, class `GameSettings`) holds the values:

- Keys are constants of the class (`GameSettings.LEDGE_GUARD` is `&"gameplay/ledge_guard"`), so they work in `match`.
  The part before the slash is the section in the file.
- `DEFAULTS` holds every key with its default; the default's type is the setting's type. A value of the wrong type in
  the file (edited by hand) falls back to the default.
- `get_value(key)`, `set_value(key, value)`, `reset_to_defaults()`, and the signal `changed(key, value)`.
- Values load in `_init()`, before any scene node's `_ready()`, and are saved to `user://settings.cfg` when the
  settings window closes and when the game exits. `persistent = false` stops saving; the tests
  set it and reset everything to the defaults, so they ignore the player's settings and never overwrite them.
- Keys listed in `_OBSOLETE_KEYS` are removed from the file on load.
- Engine-level settings are applied by the class itself (`_apply_to_engine()`): full screen, frame rate cap and V-Sync,
  physics interpolation, interface scale, language, volume. Settings of scene nodes are applied by the scene: in the
  demo, `gdscript/demo/settings_applier.gd` reads `get_value()` at startup and listens to `changed`.

**A new setting:**

1. A key constant and a default in `DEFAULTS` in `GameSettings`.
2. A control with that key in `settings_screen.tscn` (see below). The window's code does not change.
3. A branch in `settings_applier.gd` that sets the property, or in `GameSettings._apply_to_engine()` if the engine
   applies it.
4. Its texts in the translations, see [Translations](#translations).

### The settings window

`gdscript/ui/settings/settings_screen.tscn` has six tabs: Controls, Character, Camera, Display, Interface, Sound. All
settings and their defaults are listed in [Settings](../settings.md).

- Each control binds itself to one key and updates when the setting changes anywhere:
  - `SettingCheckButton`: a boolean setting.
  - `SettingOptionButton`: an integer setting; an item's value is its ID, set in the inspector with its text, so the
    items can be reordered freely.
  - `SettingSlider`: a number. `value_label` shows the value with `value_format`; `zero_text` replaces zero (for
    example "instant"); `apply_on_release` applies a mouse drag only on release, for settings that resize the
    interface itself. The limits and step are the `Range` properties.
  - `SettingLanguageButton`: the interface language, see below.
- Controls that make no sense without another setting are dimmed and locked: the backward slowdown without the
  sidestep mode, the jump height without the jump, everything about sprint without sprint, stamina duration without
  fatigue, the turn's time without the turn, the tilt angle and its time without tilt alignment, the height and its
  time without height alignment, the footsteps sound while the hero floats (`_update_dependent_rows()`).
- Each tab page is a `ScrollContainer`: a long tab scrolls (also following keyboard focus) and the window does not
  grow. The window height is the `custom_minimum_size` of the `TabContainer` (440). The long tabs (Camera, the
  longest, and Character) scroll, and the whole window stays on screen at 100% interface scale.
- **Reset all** calls `reset_to_defaults()`. The window saves the settings when it closes.
- The V-Sync hint is composed by the code from a translated sentence and the monitor's refresh rate.

### Interface scale

The interface scale is the root window's `content_scale_factor`. With the `canvas_items` stretch mode it scales all
2D (the hint, the FPS counter, the stamina bar, windows) and leaves the 3D view alone. 100% is the size as authored in
the scenes, 50% half of it. The slider dragged with the mouse applies the scale only on release
(`apply_on_release`); otherwise the window would resize under the mouse and the slider would slide away from it. The
keyboard and the wheel change the scale at once.

## HUD

| Node in `main.tscn` | Script | What it shows |
|---|---|---|
| `Hud`, `Hud/Panel` | `gdscript/demo/hud.gd` on `Hud` | The controls hint, naming the keys bound now (`Hud/ActionTexts`, see [Key names in texts](#key-names-in-texts)), and the speed: how fast the hero really moves (`GroundCharacter.get_move_speed()`; against a wall it is 0). The script only updates the speed; `settings_applier.gd` shows or hides the panel and hides the lines for disabled features (looking around on the run, the keys with RMB, both buttons + A/D, sprint, jump) |
| `Hud/FpsCounter` | `FpsCounter` (Label) | Frames per second in the top-right corner; works while paused |
| `Hud/CharacterState/Monitor` | `CharacterMonitor` (Label) | Under the FPS counter: what the hero is doing (state, speed and blend, movement, turning, ground or air, steps and feet, stamina) and the latest events. Hidden by default. See [Locomotion](locomotion.md#charactermonitor-the-state-as-text) |
| `Hud/DiscoveryToast` | `DiscoveryToast` (Label) | "Discovered: …" for `show_time` (3.5 s) when the player first enters a `PointOfInterest`. Finds all places through the `points_of_interest` group, also those added later, a level loaded during the game (`watch_added_places`, on; off: only the places there at startup); `show_discovery(title)` shows one by hand |
| `Hud/StaminaBar` | `StaminaBar` (ProgressBar) | Appears when stamina starts to be spent, turns red while the character is exhausted (`StaminaBarExhausted` variation) and fades over 0.6 s when full again |
| `Hud/TravelPrompt` | `TravelPrompt` (Control), `gdscript/ui/travel_prompt.gd` | The offer to travel on a teleport pad, above the stamina bar: the key of `interact` in a badge (`InputNames.of_action()`, as the hints name their keys) and "Teleport to <place>". The key or a click confirms (`confirmed(portal)`), the key also with Shift or another modifier held (the hero often sprints onto the pad); the button never takes the keyboard focus, so Space jumps and does not press it. Not a window: the game goes on |

The loading screen (`LoadingScreen` in `main.tscn`, from the `levels` addon) is not part of the HUD: it covers the game
while a level changes, see [Levels](levels.md#the-loading-screen). The HUD hides while it takes its picture and comes
back under it.

The hint panel, the FPS counter, the path line and the character state panel are switched in Settings → Interface.

## Theme

`shared/ui/ui_theme.tres` is the project theme (`gui/theme/custom`): panels, the window, buttons and these type
variations: `WindowPanel`, `WindowLayout`, `TabPage`, `SettingsList`, `HintLabel`, `FpsCounter`, `DiscoveryToast`,
`StaminaBar`, `StaminaBarExhausted`, `KeyBadge`, `TravelButton`. Nodes pick a variation by `theme_type_variation`
instead of overriding styles one by one. The loading screen brings its own theme, `loading_screen_theme.tres` in its
addon, so it looks the same in any project.

## Translations

English is the language of the scenes and scripts themselves. Other languages are gettext translations in
`l10n/ui/<locale>.po`, registered in `project.godot` (`internationalization/locale/translations`). The language is
the setting `interface/language` (Settings → Interface → **Language**, English by default); `GameSettings` passes it
to `TranslationServer.set_locale()`, and the interface switches at once, without a restart.

How texts get translated:

- **Texts in scenes** are translated by the engine: `Label`, `Button` and `CheckButton` texts, `OptionButton` items,
  tooltips, tab titles and `Label3D` texts above the NPCs and on the teleport pads' signs (`auto_translate_mode`). The
  loading screen's title, which its script writes into its label, is translated the same way; its tips are translated
  by its script, which then puts the keys in (`tip_format`).
- **Texts composed by code** use `tr()`: "Discovered: …" with the place name, the travel offer "Teleport to %s",
  slider values with units and the V-Sync hint are rebuilt on `NOTIFICATION_TRANSLATION_CHANGED`; the speed readout is
  rebuilt every frame anyway.
  Such nodes turn auto-translation off for themselves, so the engine does not try to translate the composed
  result.
- **Language names** in the language list are written in their own language ("English", "Русский") and are never
  translated (`SettingLanguageButton.NATIVE_NAMES`).

**A new language:**

1. Copy `l10n/ui/ru.po` to `l10n/ui/<locale>.po`, set `Language` and `Plural-Forms` in the header and translate every
   `msgstr`. A PO editor such as Poedit helps.
2. Add the file to `internationalization/locale/translations` (Project Settings → Localization → Translations).
3. Add the language's own name to `NATIVE_NAMES` in `gdscript/ui/settings/setting_language_button.gd`. The list in
   the settings window is built from the loaded translations, so nothing else changes.
4. Run the tests: `tests/localization_checks.gd` reports every interface string missing from a translation, every
   translation entry the game no longer shows and every translation that loses a key token.

**A new string:** write it in English in the scene or in `tr("...")`, naming keys by tokens (see below), then add a
`msgid` with its translation to every `.po` file. The test collects strings from the scenes, also the templates of
`ActionTexts`; strings that only scripts pass to `tr()` are listed in `SCRIPT_STRINGS` in
`tests/localization_checks.gd`, so add new ones there.

### Key names in texts

A text never writes a key: it writes the input action in braces, and the key bound to it now goes in when the text is
shown. `{sprint} — run faster` shows "Shift — run faster", and "Ctrl — run faster" once sprint is on Ctrl. So the
hints stay right when a game changes the keys in the Input Map, or lets the player change them. `InputNames` (in the
`ui_screens` addon) names the keys:

- `{action}`: the first key or mouse button of the action. A key is named by the letter on it in the player's
  keyboard layout (W on a QWERTY keyboard and on a Russian one, Z on an AZERTY one), with its modifiers (`Ctrl+S`); a
  mouse button by a short name: LMB, RMB, MMB, Wheel up and so on. Physical bindings restricted to a left or right
  modifier also name its side, for example `Ctrl+Right Shift`; logical key bindings match either side.
- `{a/b}`: several actions with slashes between them: `{move_left/move_right}` is "A/D". Two actions on the wheel,
  one up and one down, are "Wheel".
- `{a+b+c+d}`: the names written together when each is a single letter:
  `{move_forward+move_left+move_back+move_right}` is "WASD"; otherwise with slashes.
- An action without events is shown as "Unbound" ("Не назначено" in Russian). A token of an action that is not in
  the Input Map stays as it is, so that the gap shows.

The names are translated as well: the mouse names (`InputNames.get_mouse_names()`), "Space", "Unbound", "Left %s"
and "Right %s" have entries in the `.po` files ("ЛКМ", "Пробел", "Правый Shift"); the other key names are the same
in every language. A translation keeps the tokens of its string; `localization_checks.gd` fails one that loses or
changes a token.

Who puts the names in:

- **`ActionTexts`**, a `Node` in the scene. It takes over every control under its parent (or under `root`) whose
  text, tooltip or `OptionButton` items hold a token: it keeps those texts as templates, turns the control's own
  translation off and sets the translated text with the names in, again when the language changes. The HUD
  (`Hud/ActionTexts`) and the settings window (`ActionTexts` at its root) each have one. Controls without tokens stay
  as they are, including children that inherit translation. An explicitly untranslated control keeps its literal
  template while its key names are localized. Leave out controls whose text a script sets, since a refresh puts the
  template back. After the keys change, refresh them all: `get_tree().call_group(ActionTexts.GROUP, &"refresh")`.
- **Code**: `InputNames.format(tr(text))` for a whole text, `InputNames.of_action(&"interact")` for one key (the
  travel offer's badge). `TravelPrompt` joins `ActionTexts.GROUP`, so the same refresh updates its visible badge.
- **The loading screen's tips**: `LoadingScreen.tip_format` is a `Callable` that turns a translated tip into the text
  shown; `gdscript/main.gd` sets it to `InputNames.format` and adds the loading screen to `ActionTexts.GROUP`.
  `LoadingScreen.refresh()` reformats the current tip without changing its timer. The `levels` addon does not need
  `ui_screens`: without `tip_format` a tip is shown as translated.

For changes made in Project Settings → Input Map before starting the game, the initial texts already use the new
bindings. For changes through `InputMap` during play, call the group refresh after editing the bindings; it also
works while the game is paused. There is no key rebinding tab in the demo's settings window.

---

*This page matches Iso & Orbit 1.2.0.*
