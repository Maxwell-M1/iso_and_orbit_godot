# Characters

[← Documentation index](../index.md)

Character models are built from primitives (capsules, cylinders, spheres, prisms) by a script and live apart from
the logic, in `shared/characters/`. The same model can be the hero's or stand in the level. To copy the assembled
hero and its files into another project, follow
[Using it in your project](../integration.md#taking-the-demos-hero-into-your-project).
[Configurations](../configurations.md) shows control and camera choices.

## Models and equipment

| Model (`shared/characters/models/`) | Who | Equipment |
|---|---|---|
| `knight.tscn` | Knight: plate armor, a bucket helm with a T-shaped visor and a red crest, a red surcoat with a cross, pauldrons | Sword, round shield with a cross |
| `ranger.tscn` | Ranger: a green hood with a tail, pale eyes in its shadow, a quiver of arrows on the back | Bow |
| `mage.tscn` | Wizard: a bell-shaped purple robe with gold trim, a bent pointed hat, a white beard | A glowing floating orb with rings, a spellbook |
| `dwarf.tscn` | Dwarf: short and wide, a red beard with a bead, a nose, a horned helmet | Two-handed axe |
| `rogue.tscn` | Rogue: a dark hood, yellow eyes, a red mask, a three-panel cloak, a belt pouch | Two daggers, the left one in a reverse grip |

Conventions of the five standalone models above:

- It faces −Z with its feet at the origin.
- Its hands are empty nodes `RightHand` and `LeftHand`, "invisible hands". A scene from `equipment/` (staff, sword,
  shield, bow, axe, dagger, book, orb) goes into a hand; the equipment's origin is where it is gripped. To change a
  weapon, replace the hand node's child: at runtime in the game, or permanently in the model scene. The
  item's tilt is its rotation in the hand.
- Shared equipment materials (steel, brass, leather, bone, glowing gems and eyes) are in `materials/`; body and
  clothing colors are inside the model scenes.

## Hero looks

The hero is one of ten mage looks (the Necromancer, look 8, by default), placed in
`Hero/Character/Visual/Hover/Model`: it turns with `Visual` and floats with `Hover` when floating is on. The staff is
in the right hand. All looks are sized for the player's separate collision capsule, have their own eyes
(`EyeRight`, `EyeLeft`) and a staff in `RightHand`, so any of them works as the hero.

| # | Look | What sets it apart |
|---|---|---|
| 1 | Storm Mage | A slate robe with lightning and a glowing hem, storm clouds on the shoulders, a hood with a sparking crest and narrowed spark eyes in its shadow, a staff with ball lightning |
| 2 | Chronomancer | A turquoise robe with bronze, a clock face on the chest, a clock halo, floating gears, brass goggles with amber lenses, an hourglass staff |
| 3 | Hooded Mystic | A deep hood and cloak; no face, only two glowing amber eyes in the shadow |
| 4 | Stargazer | A night-blue robe with stars, a hat with a moon, big eyes looking up at the stars, a staff with a star in rings |
| 5 | Pyromancer | A scarlet robe with flames along the hem, at the shoulders and as a crown, angry fiery eyes, a fire staff |
| 6 | Cryomancer | A white robe with fur, an ice crown and crystals on the shoulders, calm bright blue eyes, a crystal staff |
| 7 | Druid | A brown robe, a cape of leaves, branching antlers, amber animal eyes with slit pupils, a gnarled staff with a seed |
| 8 | Necromancer | A black and violet robe with a ragged hem, a fan collar, green lights in the eye sockets, a skull on the shoulder and on the staff |
| 9 | Archmage | White and gold robes, a beard, a tall hat with a sapphire, kind sapphire eyes and a monocle, a ring of runes around the waist |
| 10 | Battle Mage | A short robe, plate pauldrons, a cloak, potions on the belt, a book at the hip, golden eyes under stern brows, a spear staff |

The models are in `shared/characters/models/mage_options/`, their staffs in `equipment/staff*.tscn`. The hand is
0.52 m from the body's axis, so the bottom of the staff does not sink into a robe; the Archmage holds it at 0.55 m,
the Battle Mage at 0.49 m. The hero looks have only a `RightHand`; the Battle Mage's book hangs at `LeftHip`.

In the start level (`shared/world/world.tscn`) all ten stand in a row on the south side of the south wall, backs to
it (east of the gap in the wall), facing south, each with its number overhead. There is a clear walkway in front of
the whole row.

## CharacterAppearance

Switches the model at runtime (Settings → Character → **Hero look**). `set_look(number)` removes the old model and
puts the new one in its place under the same name. It also resets the new model's physics interpolation (otherwise
the model would slide in from the origin) and hands the new model's `RightHand` to `HandSway`, so the staff swings with
the steps again. The silhouette picks up the new meshes by itself.

| Property | Default | Meaning |
|---|---|---|
| `slot` | — | The node that holds the model (`Visual/Hover` on the player: the hover under `Visual`, which `GroundCharacter` turns) |
| `model_name` | `Model` | Name of the model node inside `slot` |
| `models` | — | Model scenes to choose from; the look number is the position in this list, from 1 |
| `hand_sway` | — | Who gets the new model's hand; if empty, the hand does not swing |
| `hand_path` | `RightHand` | Where the hand holding an item is in the model |

`get_look()` returns the current number (0 for a model not in the list), `get_model()` the model node. Signal:
`look_changed(model)`.

### Use your own model with the playable hero

1. Edit the `gdscript/player/player.tscn` used by your copied `playable_hero.tscn`, or replace that hero's
   `Character` instance with a copy of the scene, keeping its node paths or reassigning the hero's exported
   references. Replace `Visual/Hover/Model` with your model scene and name its root `Model`. Put its feet at the
   local origin and make its front face −Z. Correct a differently oriented mesh inside
   that scene, leaving `Visual` free for `GroundCharacter` to turn. The collision capsule is on the body, separate
   from the model: resize the `CollisionShape3D` and rebake the navigation mesh if your character needs different
   clearance (see [World and navigation](world-and-navigation.md#physics-layers-and-navigation)).
2. If you want looks to switch, put your model scenes in `Appearance.models`; look numbers start at 1. Give each a
   hand node at `Appearance.hand_path` (`RightHand` by default). With no hand, remove `RightHandSway` and clear
   `Appearance.hand_sway`.
   `CharacterAppearance.set_look()` then retargets the sway and the silhouette finds new meshes automatically.
3. If you use only one model, remove `Appearance` and clear the playable hero's `appearance` reference. Remove
   `RightHandSway` as well if there is no held item. If you keep `Appearance` in the full demo, replace its
   `models` list too: `SettingsApplier` calls `set_look()` with the saved look number at startup, and an unchanged
   list would switch back to a mage model.

The model must fit the capsule and nearby ceilings. A floating model rises above the body without moving its
collision shape, so leave room above it or keep `Hover.enabled` off. `Silhouette.target` and
`CameraArm.fade_target` already point to `Visual`; they continue to include a replacement model under it.

## HandSway: a staff in the hand, not glued to the side

`HandSway` (`RightHandSway` on the player) moves the model's hand node relative to its rest position:

- **With the steps**, by `GroundCharacter.get_step_phase()`, the same rhythm the footstep sounds follow. At each step
  the hand is at an extreme (in front and behind in turn, ±7 cm) and lowest (2.5 cm); halfway between steps it is in
  the middle. The item lags a little in tilt (±7°). The swing grows with speed, one and a half times larger when
  sprinting, and fades out when the character stops or is in the air. Without steps (`is_counting_steps()` is
  false: `steps_enabled` off, or a floating hero) the swing fades out too, and comes back with the steps.
- **On the run** the item leans forward (6°).
- **Inertia** on a spring (1.8 Hz, damping 0.45), from `GroundCharacter.get_local_acceleration()`: on acceleration
  the top goes back, on braking forward, in turns outward, and it sways until it settles. Stairs do not jerk it. When
  the character touches the ground the hand dips, deeper the faster the fall (`touched_floor`, so a soft touchdown
  dips it a little too); on take-off, a little. `tilt_per_acceleration` (0.45°) is
  positive: the item lags behind; a negative value tilts it into the acceleration. The spring is a `DampedSpring`,
  the same one `CharacterHover` uses.

It runs in the physics tick after the body, so physics interpolation smooths it just like the body. The step rhythm
is continuous: stop mid-step and the next step comes `first_step_distance` after you start again, but the phase does
not jump; it reaches the whole number at that step. For another hand or an NPC, add another `HandSway` with its own
hand. The amplitudes, lean and spring are exported properties in the groups Swing and Inertia.

## CharacterHover: floating above the ground

`CharacterHover` makes a `GroundCharacter` appear to float: the model hangs `height` above the ground, glides over
stairs instead of jumping onto them, sways gently up and down, leans toward movement and acceleration, and sags a
little on landing. Only the model moves. The body walks as usual: slopes, stairs, jumps and the ledge guard work
the same, and so do the paths and the camera. Its optional `FallSettings` can change downward acceleration and set a
fall speed limit; the shipped hero uses it for a slower descent. Settings → Character → **Float above the ground**
turns it on in the demo.

The node goes between the node the character turns and the model:

```
Player (GroundCharacter)   Hero/Character in the demo
└── Visual            turned by GroundCharacter toward the way it goes
    └── Hover         CharacterHover: raises and tilts itself
        └── Model     the look; CharacterAppearance.slot is Visual/Hover
```

The character writes only the turn of `Visual`, and the hover only its own transform, so they never fight over a
node. A new look from `CharacterAppearance` goes under the hover (`slot`), and the silhouette and the camera's fade
find the model there by themselves. The tilt is applied in the axes of `Visual`, so a hover turned in the scene (for a
model that faces another way) still leans toward the movement.

### Steps

By default, floating suppresses step events. The hover does this with
`GroundCharacter.set_steps_suppressed(self, true)`: no `stepped`, no footstep sounds, no step swing of the staff. Once
the model has settled back on the ground, it lets them go, and they are counted again if `steps_enabled` is on. The
hover never touches `steps_enabled`: the game's own switch stays as the game set it, and several components can stop
the steps at once without undoing each other. Out of the tree the hover lets the steps go, and back in it stops them
again. `steps_while_floating` keeps the steps, for example for a creature that pushes off the ground in the rhythm of
its steps. `GroundCharacter.is_counting_steps()` tells whether steps are counted now.

### The fall

With `fall` set (a `FallSettings`, see [Locomotion](locomotion.md#the-fall)), the hover puts it in place of the
character's own fall while the model floats, from the start of the rise until it has settled
(`GroundCharacter.set_fall_override(self, fall)`, priority 0): after the top of a jump and off an edge the character
gains speed more slowly, up to a limit. The rise of a jump stays the same. Floating turned on mid-fall, the fall slows
down to the limit in `braking_time`; turned off, it stays slow until the model has settled, then speeds up as usual.
Out of the tree the hover gives the fall back. An empty `fall` leaves the character's own fall, exactly as on foot.
The hover puts its fall in place anew at the start of each rise, so of the falls with priority 0 it is then the
latest; a fall that the game puts in place with a higher priority wins over it. A new `fall` given to the hover while
it floats takes its old place.

The demo's hover has `gdscript/player/player_floating_fall.tres`: gravity scale 0.5 instead of the body's 3, and a
2 m/s maximum downward speed. A
floating hero comes down from the top of a 1 m jump in 0.68 s instead of 0.25 s and touches the ground at 2 m/s,
below `landing_min_speed` (2.5 m/s): a soft touchdown, without `landed`, so without the landing sound.

### How it follows the ground

The model floats over a smoothed height of the ground. On the ground the hover looks ahead along the way and eases
toward the ground it finds there, settling at a new height in `glide_time`. It looks exactly as far ahead as the
smoothing lags behind, so on a ramp there is no lag at all, and on stairs the model starts to rise before a stair and
goes up the flight along a smooth line, never moving down while it climbs. Over the edge of a stair it is about half
a stair lower than its height above the stair under it: it follows the line of the stairs, not each step.

The way ahead is checked with rays in pieces of at most 0.15 m, up to 0.9 m ahead. On each piece the ground may rise or
drop no more than a stair (`max_step_height`) or the steepest slope. A ray that starts inside something finds no
ground, so a wall stops the search as well. So the model stays level before a ledge, a gap or a wall that the body will
not pass, and does not rise toward a terrace behind a fence. At the bends at the ends of a ramp it rounds the corner:
it rises a little before the ramp starts and levels out a little before its top, up to about 0.05 m below its height
at the demo's 15° ramp.

In the air, and on the tick of landing, the model moves exactly with the body: a jump has the same arc, a fall off an
edge drops the model with the body. What was left of the glide at the take-off fades out in `glide_time`.

The rays cost: up to seven per tick while the character floats and runs, one while it stands, none in the air or while
it does not float. When the character is teleported (`GroundCharacter.teleport()`), the model is put in place at once,
with physics interpolation on or off; so is it when the character's physics interpolation is reset by hand
(`reset_physics_interpolation()`, which does nothing while the interpolation is off), and after a horizontal move of
more than a meter in one tick. `snap()` does the same by hand.

### The sway

The sway runs on time, so the model sways in place too: one sway up and down takes `bob_period` (2.4 s) at
`bob_height` (4 cm). The movement changes it in proportion to the speed, from standing to running (the blend from 0 to
1): at the running speed it is `run_bob_rate` (1.5) times faster and `run_bob_scale` (0.5) as large, a calmer and
quicker sway. The point in the cycle grows with time, so a change of speed never makes the model jump. With
`random_bob_phase` every hover starts at a random point, so several floating characters do not sway in unison. The sway
is never deeper than `height`: the model does not dip into the ground.

### Tilt and inertia

- **Lean.** `run_lean` (8°) toward the movement at the running speed: forward when running, to the side when moving
  sideways, back when backing up; while sprinting up to `max_lean_scale` (1.5) times as far.
- **Inertia.** `tilt_per_acceleration` per 1 m/s² of `GroundCharacter.get_local_acceleration()`, at most
  `max_inertia_tilt` (15°) in any direction. The sign is the same as in `HandSway`: positive lags behind, like a weight
  on a string; negative tilts into the acceleration, as a hovering craft does: forward when speeding up, back when
  braking, into a turn. The hover's default is −0.25°.
- Both go through springs (`spring_frequency` 1.5 Hz, `spring_damping` 0.5), and the model tilts around a point
  `tilt_pivot_height` (0.9 m) above its feet, about the waist, so its feet do not swing wide.
- **Sag.** When the character touches the ground (`touched_floor`, a soft touchdown too) the model is pushed down by
  `landing_kick` per 1 m/s of fall speed, on a jump's push-off by `jump_kick`, and the spring brings it back. It never
  sags more than `max_drop` (0.15 m) and never more than its height above the ground. The demo's hover has a
  `landing_kick` of 0.2, so its soft touchdown at 2 m/s sags it by about 2 cm.

### Turning it on and off

Turned on, the model rises to `height` in `rise_time` (0.5 s), softly at the start and the end; turned off, it settles
in the same time, and the steps come back when it touches the ground. The sway, the lean and the sag grow and fade
with the rise. Set before the first physics tick (in the scene, or by saved settings at startup), `enabled` takes
effect at once, without rising.

`floating_changed(floating)` comes at the start of the rise and when the model has settled. `is_floating()` tells
whether it floats now, `get_hover_height()` how high above the body's feet the model is.

### Properties

| Group | Property | Default | Meaning |
|---|---|---|---|
| | `character` | — | The `GroundCharacter`; if empty, the nearest one above the node |
| | `enabled` | on (off in the demo's scene) | Float |
| | `height` | 0.35 m | The model's feet above the ground |
| | `rise_time` | 0.5 s | How long the rise and the settling take; 0 is at once |
| | `steps_while_floating` | off | Keep the steps while floating |
| | `fall` | — (`player_floating_fall.tres` in the demo) | How the character falls while floating; empty: as without floating |
| Glide | `glide_time` | 0.3 s | In how long the model settles at a new ground height (95% of the way); 0 follows the ground under the body with every stair |
| Sway | `bob_height` | 0.04 m | How far the model sways up and down while the character stands |
| | `bob_period` | 2.4 s | How long one sway takes while the character stands, from 0.5 s |
| | `run_bob_scale` | 0.5 | The sway at the running speed, as a share of `bob_height` |
| | `run_bob_rate` | 1.5 | How many times faster the model sways at the running speed |
| | `random_bob_phase` | on | Start at a random point of the sway |
| Tilt | `run_lean` | 8° | Lean toward the movement at the running speed |
| | `max_lean_scale` | 1.5 | The lean may grow this many times when sprinting |
| | `tilt_pivot_height` | 0.9 m | The point the model tilts around, above its feet |
| Inertia | `tilt_per_acceleration` | −0.25° per m/s² | Positive lags behind, negative tilts into the acceleration |
| | `max_inertia_tilt` | 15° | The tilt from the acceleration is no larger |
| | `landing_kick` | 0.05 (0.2 in the demo) | The push down when the character touches the ground, per 1 m/s of fall speed |
| | `jump_kick` | 0.3 m/s | The push down on a jump's push-off |
| | `max_drop` | 0.15 m | The sag is no deeper, and never deeper than the height above the ground |
| | `spring_frequency`, `spring_damping` | 1.5 Hz, 0.5 | The springs of the tilt and the sag |

### Things to know

- The model floats `height` higher than the body: the camera's `focus_height` and the arm's `occlusion_points` are
  measured from the body, so raise them if the model floats high.
- Under a low ceiling the floating model can sink into it: the body does not know about the extra height.
- Stairs are smoothed for the model only. The camera follows the body; its `height_follow_time` smooths the climb on
  screen (0.15 s in the demo).
- A fall that gains speed only up to a limit below `landing_min_speed` never lands: no `landed`, so no landing sound
  and nothing else that waits for a real landing. If a floating landing should be heard, give the hover's `fall` a
  `max_speed` of at least `landing_min_speed`, or lower `landing_min_speed`.
- Up must be +Y, as for the whole character.
- While time stands still (`Engine.time_scale` 0), the floating model stays where it is, and so does the hand that
  `HandSway` swings, see [Locomotion](locomotion.md#groundcharacter).
- A mistake in the setup is printed as a warning when the game starts: the hover not under the character's `Visual`,
  no model under it, a second hover on the same character, a `CharacterAppearance.slot` that is not the hover.
- `DampedSpring` is the spring the hover and `HandSway` share: `update(target, frequency, damping, delta)`, `value`,
  `speed`, `keep_within(limit)`, `reset()`. A stiff spring is computed in several short steps per tick, so it stays
  calm at any setting.

### Measured behavior

From `tests/character_state_checks.gd`, with the demo's settings at 60 physics ticks and, for the shape of the path,
without the sway:

- Standing: 0.31 to 0.39 m above the feet (0.35 m and the 4 cm sway).
- Up and down the stairs east of the platform: the climb of the model changes by at most 0.031 m per tick, against
  the body's 0.100 m up and 0.138 m down. The model never moves against the way, and stays at least 0.17 m over the
  stair under it.
- Along the ramp: 0.347 to 0.350 m over the ground in its middle, no lag; at the bends down to 0.30 m.
- A jump without the pushes: in the air and on landing the model keeps its height to within 0.6 mm. With them it sags
  by 0.021 m as it touches the ground at 2 m/s.
- The slower fall: a 1 m jump tops at 1.000 m and touches the ground at 2.00 m/s, without a landing. Turned on while
  falling at 6.4 m/s, floating slows the fall down to 2.2 m/s in 0.3 s, by at most 0.67 m/s per tick; turned off
  mid-fall, the fall stays at 2 m/s for the 30 ticks of the settling, then speeds up at 29.4 m/s², as on foot.
- At the guarded edge of the platform, against a 0.4 m block and at a wall with a terrace behind it: no dip and no
  rise.
- Turned off and on mid-run: at most 0.018 m per tick; settled in 31 ticks (`rise_time` 0.5 s), and the steps come
  back then. With the setting saved on, the hero floats from the first frame.

## OccludedSilhouette: one shape, the weapon outlined, a rim

Where something hides the hero (the mountain, a house, a tree), the hero shows as a light blue silhouette: one flat
shape for the body, the equipment in hand outlined on top of it, and a rim around everything.

`OccludedSilhouette` (`Silhouette` on the player) sets `material_overlay` on every mesh of the model, including meshes
added later (a new look or weapon, through `SceneTree.node_added`). The model's own materials do not change, so the
same model in the level has no silhouette. Body meshes and meshes under the hand nodes (`gear_nodes`: `RightHand`,
`LeftHand`) get different chains of passes. With different equipment names, set `gear_nodes`; without matching nodes,
all meshes use the body fill. An existing `material_overlay` on those meshes is replaced.

Each screen pixel is painted once, by the stencil buffer: a pass draws only where the stencil value is less than its
own and writes its own right away (`stencil_mode read, write, compare_greater, N`). The shaders and materials are in
`addons/iso_orbit/occluded_silhouette/`:

| Pass | `render_priority` | Stencil | What it does |
|---|---|---|---|
| `silhouette_mask` | 1 | writes 4 | Invisible, depth-tested: marks where the character is visible itself, so nothing else draws there |
| `silhouette_body` | 2 | < 2 → 2 | Flat body fill: parts do not overlap and merge into one shape |
| `silhouette_gear` | 3 | < 3 → 3 | Lighter fill for the equipment, on top of the body with its own outline |
| `silhouette_outline` | 4 | < 1 → 1 | The rim: meshes inflated along their normals by 0.4% of the screen height; only the part outside the whole shape remains |

Fills and the rim are drawn only where an obstacle is at least 30 cm closer than the fragment (the depth buffer is
converted to meters in `silhouette_common.gdshaderinc`). Transparent objects are sorted by `render_priority` first, so
the passes run in order for all meshes at once. Change `min_gap` in the body, gear and outline materials together to
alter that gap. The component builds its pass chains at `_ready()`, so change those materials before the scene starts.

`outline_enabled` (Settings → Display → **Silhouette outline behind obstacles**) removes the last pass from the
chains. The rim width is the `width` parameter of `silhouette_outline.tres`; the colors are `color` on the fills and
the rim.

The effect was tested with the Forward+ renderer. The stencil buffer is experimental in Godot 4.5+ and can only be
read in a transparent pass. In Godot 4.7 (D3D12 and Vulkan) the projection in shaders is flipped in Y:
`PROJECTION_MATRIX[1][1]` is negative.
Without `abs()` the "share of the screen → meters" conversion goes negative, the rim mesh shrinks and the rim
disappears.

## Editing the models

The models were built from primitives by a script and are ordinary scenes now: edit them in the editor like any other
scene.

---

*This page matches Iso & Orbit 1.2.0.*
