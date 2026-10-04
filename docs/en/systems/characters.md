# Characters

Character models are built from primitives (capsules, cylinders, spheres, prisms) by a script and live apart from
the logic, in `shared/characters/`. The same model can be the hero's or stand in the level.

## Models and equipment

| Model (`shared/characters/models/`) | Who | Equipment |
|---|---|---|
| `knight.tscn` | Knight: plate armor, a bucket helm with a T-shaped visor and a red crest, a red surcoat with a cross, pauldrons | Sword, round shield with a cross |
| `ranger.tscn` | Ranger: a green hood with a tail, pale eyes in its shadow, a quiver of arrows on the back | Bow |
| `mage.tscn` | Wizard: a bell-shaped purple robe with gold trim, a bent pointed hat, a white beard | A glowing floating orb with rings, a spellbook |
| `dwarf.tscn` | Dwarf: short and wide, a red beard with a bead, a nose, a horned helmet | Two-handed axe |
| `rogue.tscn` | Rogue: a dark hood, yellow eyes, a red mask, a three-panel cloak, a belt pouch | Two daggers, the left one in a reverse grip |

Conventions every model follows:

- It faces −Z with its feet at the origin.
- Its hands are empty nodes `RightHand` and `LeftHand`, "invisible hands". A scene from `equipment/` (staff, sword,
  shield, bow, axe, dagger, book, orb) goes into a hand; the equipment's origin is where it is gripped. To change a
  weapon, replace the hand node's child: at runtime in the game, or permanently in the model scene. The
  item's tilt is its rotation in the hand.
- Shared equipment materials (steel, brass, leather, bone, glowing gems and eyes) are in `materials/`; body and
  clothing colors are inside the model scenes.

## Hero looks

The hero is one of ten mage looks (the Battle Mage by default), placed in `Player/Visual/Model`, which turns with
`Visual`. The staff is in the right hand. All looks share a capsule body of the player's size, their own eyes
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

In the level all ten stand in a row on the south side of the south wall, backs to it (east of the gap in the
wall), facing south,
each with its number overhead. There is a clear walkway in front of the whole row.

## CharacterAppearance

Switches the model at runtime (Settings → Character → **Hero look**). `set_look(number)` removes the old model and
puts the new one in its place under the same name. It also resets the new model's physics interpolation (otherwise
the model would slide in from the origin) and hands the new model's `RightHand` to `HandSway`, so the staff swings with
the steps again. The silhouette picks up the new meshes by itself.

| Property | Default | Meaning |
|---|---|---|
| `slot` | — | The node that holds the model (`Visual` on the player, turned by `GroundCharacter`) |
| `model_name` | `Model` | Name of the model node inside `slot` |
| `models` | — | Model scenes to choose from; the look number is the position in this list, from 1 |
| `hand_sway` | — | Who gets the new model's hand; if empty, the hand does not swing |
| `hand_path` | `RightHand` | Where the hand holding an item is in the model |

`get_look()` returns the current number (0 for a model not in the list), `get_model()` the model node. Signal:
`look_changed(model)`.

## HandSway: a staff in the hand, not glued to the side

`HandSway` (`RightHandSway` on the player) moves the model's hand node relative to its rest position:

- **With the steps**, by `GroundCharacter.get_step_phase()`, the same rhythm the footstep sounds follow. At each step
  the hand is at an extreme (in front and behind in turn, ±7 cm) and lowest (2.5 cm); halfway between steps it is in
  the middle. The item lags a little in tilt (±7°). The swing grows with speed, one and a half times larger when
  sprinting, and fades out when the character stops or is in the air.
- **On the run** the item leans forward (6°).
- **Inertia** on a spring (1.8 Hz, damping 0.45): on acceleration the top goes back, on braking forward, in turns
  outward, and it sways until it settles. On landing the hand dips deeper the faster the fall; on take-off, a little.

It runs in the physics tick after the body, so physics interpolation smooths it just like the body. The step rhythm
is continuous: stop mid-step and the next step comes `first_step_distance` after you start again, but the phase does
not jump; it reaches the whole number at that step. For another hand or an NPC, add another `HandSway` with its own
hand. The amplitudes, lean and spring are exported properties in the groups Swing and Inertia.

## OccludedSilhouette: one shape, the weapon outlined, a rim

Where something hides the hero (the mountain, a house, a tree), the hero shows as a light blue silhouette: one flat
shape for the body, the equipment in hand outlined on top of it, and a rim around everything.

`OccludedSilhouette` (`Silhouette` on the player) sets `material_overlay` on every mesh of the model, including meshes
added later (a new look or weapon, through `SceneTree.node_added`). The model's own materials do not change, so the
same model in the level has no silhouette. Body meshes and meshes under the hand nodes (`gear_nodes`: `RightHand`,
`LeftHand`) get different chains of passes.

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
the passes run in order for all meshes at once.

`outline_enabled` (Settings → Display → **Silhouette outline behind obstacles**) removes the last pass from the
chains. The rim width is the `width` parameter of `silhouette_outline.tres`; the colors are `color` on the fills and
the rim.

Two engine details: the stencil buffer is experimental in Godot 4.5+ and can only be read in a transparent pass. And
in Godot 4.7 (D3D12 and Vulkan) the projection in shaders is flipped in Y: `PROJECTION_MATRIX[1][1]` is negative.
Without `abs()` the "share of the screen → meters" conversion goes negative, the rim mesh shrinks and the rim
disappears.

## Editing the models

The models were built from primitives by a script and are ordinary scenes now: edit them in the editor like any other
scene.

---

*This page matches Iso & Orbit 1.1.0.*
