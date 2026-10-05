<!-- translation of addons/iso_orbit/orbit_camera/README.md @ 94f2d396a032 -->
# オービットカメラ

[← ドキュメント目次（テンプレートリポジトリ）](../../../docs/ja/index.md)

> これは[英語の原文](README.md)の翻訳です。内容が異なる場合は、英語版を参照してください。

[English](README.md) · [Español](README.es.md) · **日本語** · [Português (Brasil)](README.pt_BR.md) · [Русский](README.ru.md) · [Türkçe](README.tr.md) · [简体中文](README.zh_CN.md)

アイソメトリックやトップダウンのゲーム向けのオービットカメラです。任意の`Node3D`を追い、マウスでその周りを回り、ホイールでズームします。走行中は、ターゲットの背後への旋回、傾きの調整、指定したズームへの復帰を独立して有効にできます。アームはカメラを壁に入れず、障害物でターゲットが隠れるときに任意で手前へ引き寄せます。

Godot 4.7用Iso & Orbitの一部です。MITライセンス（`LICENSE`を参照）。単独で使う場合、ほかのアドオンは不要です。

| スクリプト | クラス | 役割 |
|---|---|---|
| `orbit_camera_rig.gd` | `OrbitCameraRig`（`Node3D`） | ターゲット追従、入力、ズーム、任意の走行時自動調整 |
| `camera_arm.gd` | `CameraArm`（`Node3D`） | カメラ配置、障害物への反応、任意の近距離フェード |

## シーンへの配置

1. このフォルダを`res://addons/iso_orbit/orbit_camera/`へコピーします。
2. **Project Settings → Input Map**で`camera_rotate`（右マウスボタン）、`camera_zoom_in`（ホイール上）、`camera_zoom_out`（ホイール下）を追加します。リグのエクスポートされたアクション名は変更できます。欠けたアクションは起動時にエラーとして報告され、入力を起動できません。
3. 動くターゲットの隣に次のノードを置きます。`CameraRig.target`へキャラクターなどの`Node3D`を設定します。カメラのサブツリーと親ノードのスケールは変えません。

   ```text
   Scene
   ├── Character (移動するターゲット)
   └── CameraRig (Node3D + orbit_camera_rig.gd; target = ../Character)
       └── CameraArm (Node3D + camera_arm.gd)
           └── Camera3D (Current = on)
   ```

   リグとアームはそれぞれ最初の直接の子`CameraArm`と`Camera3D`を探します。エクスポートされた`arm`と`camera`を明示的に設定することもできます。アームが配置するため`Camera3D`のローカルトランスフォームは初期値にします。この視点を使うときはCurrentにします。テンプレートと同じ構図には視野角45°、遠方クリップ距離300ワールド単位を設定します。
4. 固体のワールド形状を物理レイヤー1に置きます。アームのデフォルトの`collision_mask`はレイヤー1と3（`0b101`）です。レイヤー3には屋根などカメラ専用の障害物を置けます。キャラクターをそのマスクから外し、カメラを押さないようにします。ボディかその親を`camera_ignore`へ入れると除外されます。任意で`CameraArm.fade_target`へモデルのルートを指定すると、アームが非常に短いとき半透明になります。
5. ターゲットが物理ティックで動くなら**Project Settings → Physics → Common → Physics Interpolation**を有効にします。リグは描画フレームごとにターゲットの補間位置を追い、自身の補間はオフにします。アームとカメラはデフォルトでそのモードを継承します。

スクリプトのデフォルトは手動オービットで、3つの走行時自動調整はすべてオフです。時間と目標値が設定されていても有効にはなりません。テンプレートのヒーロー向けに調整済みの任意の追従には、`follow_time = 1.1` s、`follow_pitch_angle = -22°`、`follow_pitch_time = 1.1` s、`follow_zoom_level = 0.55`、`follow_zoom_time = 1.5` s、`follow_wait_after_rotate = true`、`height_follow_time = 0.15` sを使います。走行の後ろへ旋回するなら`follow_movement`を有効にし、傾きやズームを合わせたい場合だけ`follow_pitch`と`follow_zoom`を有効にします。ヒーローの初期状態では3つともオフです。角度はインスペクターでは度で指定し、GDScriptでは`deg_to_rad()`によるラジアンを代入します。

`follow_wait_after_rotate`がオンなら、意図したマウスオービットの後は、ターゲットが減速するか新しい走行を始めるまで追従を待機します。停止前に入力が次の走行を始める場合は`end_follow_wait()`を呼びます。テンプレートの`gdscript/player/playable_hero.tscn`では`PointClickMoveInput.run_requested`をこれに、`hold_pending_changed`を`set_follow_paused()`へ接続します。ターゲットが常に動き続け、新しい走行を通知できないなら待機オプションをオフにします。反転中の途中方向へカメラを引っ張らないよう`sharp_turn_speed`はキャラクターの旋回速度の半分以下に保ちます。テンプレートではヒーローの720°/sに対して360°/sです。

アームがなくても、リグの直接の子に`Camera3D`を置けば動きます。カメラはズーム距離に留まり、壁を通過することがあります。障害物への対応とフェードには`CameraArm`が必要です。

ズーム曲線、全プロパティ、遮蔽の挙動、検査済みの相互作用は[カメラ](../../../docs/ja/systems/camera.md)を参照してください。完成済みヒーローの移植は[組み込み](../../../docs/ja/integration.md#デモのヒーローを自分のプロジェクトへ移植する)と[プロジェクトのセットアップ](../../../docs/ja/project-setup.md)を参照してください。

---

*このページは Iso & Orbit 1.2.0 に対応しています。*
