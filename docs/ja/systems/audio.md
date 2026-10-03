<!-- translation of docs/en/systems/audio.md @ 551102f71d1a -->
# オーディオ

> これは[英語の原文](../../en/systems/audio.md)の翻訳です。内容が異なる場合は、英語版が正しいものとします。

`GroundCharacter`は、自身に起きたことをシグナルで通知します：`stepped(sprinting)`、`jumped`、`landed(impact_speed)`、`sprint_changed(sprinting)`（[ロコモーション](locomotion.md#シグナル)を参照）。サウンド、足元の土ぼこり、アニメーションはこれらに接続し、キャラクター自身はそれらについて何も知りません。デモではサウンドを接続しています。

## CharacterSounds

`CharacterSounds`（`Player/Sounds`）は、キャラクターの子である`Node3D`です。その子は`AudioStreamPlayer3D`ノードなので、音はキャラクターの位置から聞こえ、NPCでも同じように機能します。このノードがなくても、キャラクターは音が出ないだけで、まったく同じように動作します。

| サウンド | 再生ノード | 再生される内容 |
|---|---|---|
| 足音 | `Footsteps` | 4種類のバリエーションを持つ`AudioStreamRandomizer`。ピッチ（±8%）と音量がランダムで、同時に最大3つ。ダッシュ中は少し高く（`sprint_step_pitch` 1.08）、大きく（+2 dB）なる。ステップは距離に従うので、間隔は自然に速くなる |
| ジャンプ | `Jump` | 足で蹴る音と服がこすれる音 |
| 着地 | `Land` | 重いドスンという音。落下が速いほど大きい：`land_full_speed`（10 m/s）から最大音量になり、`min_land_volume`（30%）より小さくはならない |
| ダッシュ開始 | `SprintStart` | ダッシュの開始時の蹴る音と、高まっていく風の音 |
| ダッシュ中 | `SprintLoop` | 速い呼吸と風の音の2秒のループ。`sprint_loop_fade`（0.25秒）でフェードイン・フェードアウトする |

| プロパティ | デフォルト | 意味 |
|---|---|---|
| `character` | 親 | どのキャラクターのシグナルで再生するか |
| `footsteps`、`jump`、`land`、`sprint_start`、`sprint_loop` | — | 再生ノード |
| `footsteps_enabled`、`jump_enabled`、`sprint_enabled` | オン | サウンドのグループ。ジャンプのグループはジャンプと着地、ダッシュのグループは開始とループを含む |
| `sprint_step_pitch`、`sprint_step_volume_db` | 1.08、+2 dB | ダッシュ中の足音 |
| `land_full_speed`、`min_land_volume` | 10 m/s、0.3 | 着地音の音量カーブ |
| `sprint_loop_fade` | 0.25秒 | ダッシュのループ音のフェード |

音量は`gdscript/player/player.tscn`の各再生ノードで設定されています。実行中のゲームでは、リモートツリー（Remote）から調整できます。例外は`Land`で、その音量は着地のたびに落下速度から設定されます（`land_full_speed`、`min_land_volume`）。グループは設定 → サウンドで切り替えます。デモではダッシュのサウンドがデフォルトでオフです。そこにある全体の音量は`Master`バスの音量です。パーセントは振幅の割合で（50%で6 dB小さくなる）、0でバスがミュートされます。

## サウンドそのもの

`shared/audio/character/`のファイルはスクリプトで合成しました。ドスンという音はピッチが下がっていくサイン波、ザクッという音や風の音はバンドパスフィルターを通したノイズです。ダッシュのループ音はWAV内に`smpl`チャンクを持っており、インポート時のデフォルトのループモード「WAVから検出」（Detect From WAV）により、インポート設定に手を加えなくてもループします。ループのつなぎ目は終わりから始まりへクロスフェードしているので、プチッというノイズは出ません。

実際に録音したサウンドに置き換えることもできます。同じ名前のファイルをこのフォルダーに置いてください。

---

*このページは Iso & Orbit 1.0.0 に対応しています。*
