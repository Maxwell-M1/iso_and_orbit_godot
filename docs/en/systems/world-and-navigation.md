# World and navigation

[← Documentation index](../index.md)

The demo's start level is `shared/world/world.tscn`, the meadow: an 80 × 80 m glade behind a wooden fence. Everything
in it is built from primitives and shaders; the fine surface patterns come from baked textures. A teleport pad by the
Ancient Circle leads to the second level, Lonely Isle; both are described in [Levels](levels.md#the-demos-levels).

## Physics layers and navigation

Obstacles are `StaticBody3D` on layer 1 (`world`), characters on layer 2 (`characters`), camera-only bodies on layer 3
(`camera`), invisible walls at the edge of a level on layer 4 (`bounds`), see [Project
setup](../project-setup.md#physics-layers). The navigation mesh is baked from layer 1 collisions (the island's also
from layer 4, its edge walls) with a 0.5 m agent radius; the character's capsule is 0.35 m, so paths keep a margin
from corners.

| `NavigationMesh` parameter | Value | Why |
|---|---|---|
| `agent_radius` | 0.5 m | Paths keep clear of corners |
| `agent_height` | 1.75 m | Existing demo bake value; use at least the full collision height for a new level with ceilings (the hero capsule is 1.8 m) |
| `agent_max_slope` | 40° | The mountain's slopes stay off the mesh |
| `cell_height` | 0.025 m | Fine enough to measure the climb below |
| `cell_size` | 0.25 m | Horizontal bake resolution; must match the navigation map |
| `agent_max_climb` | 0.3 m (12 cells) | The stairs the character steps onto (`GroundCharacter.max_step_height`) |
| `geometry_parsed_geometry_type` | Static Colliders | The mesh follows the collision shapes, not the visible meshes. The collision mask below applies to colliders, and the invisible walls, which have no mesh, count only this way |
| `geometry_collision_mask` | layer 1; the island: 1 and 4 | Only obstacles count, and the invisible walls |
| `filter_walkable_low_height_spans` | off in the demo | Enable for a new level with ceilings so spans below `agent_height` clearance are excluded |

**Match navigation to the collision body.** Use `agent_max_climb` no higher than `GroundCharacter.max_step_height`
(0.3 m here), and a navigation slope limit no higher than the body's floor limit (40° versus 45° here). Bake after
changing either value. Navigation is rasterized into cells, so matching the numbers is not a guarantee for every
edge: test the highest intended stair and the lowest forbidden ledge. The demo tests its 0.2 m stairs and rejects a
0.4 m block. Fine 0.025 m vertical cells make these small height differences distinguishable.

For new levels, use agent height at least equal to the full capsule height and enable
`filter_walkable_low_height_spans`; height alone does not enable that clearance filter. Include ceiling colliders in
the bake. A floating model extends above the body, so check its visual clearance separately. Radius controls path
clearance around walls; after changing capsule radius, check narrow corridors and rebake too.

Keep map and mesh `cell_height` and `cell_size` equal. The demo uses 0.025 m vertically and 0.25 m horizontally;
the corresponding project settings are `navigation/3d/default_cell_height` and `navigation/3d/default_cell_size`.
Godot's [NavigationMesh reference](https://docs.godotengine.org/en/stable/classes/class_navigationmesh.html) describes
the bake resolution, rounding and clearance filter.

The baked surface can sit slightly above the collision floor. `NavigationMover` compares path progress in the XZ
plane; physics determines the body's actual height. Physics layers select bake geometry, whereas the region's
navigation layers and `NavigationMover.navigation_layers` select usable paths.

An empty navigation result falls back to direct movement; a partial path can end short of an unreachable target.
Use **Debug → Visible Navigation** and the demo's **Character path line** before tuning movement to compensate for a
bad route. See [Locomotion](locomotion.md#navigationmover).

## Rebaking the navigation mesh

The mesh is baked in advance and stored right in each level's scene, `shared/world/world.tscn` and
`shared/world/island/island.tscn` (the `NavigationMesh` resource of `NavigationRegion3D`); the game does not recompute
it. After editing a level, rebake its mesh. Both use the same parameters, except the collision mask: the island's
mesh is baked from layers 1 and 4.

**When:** you moved, added, removed or resized anything with a collision shape on layer 1 (`world`): a rock, a crate,
a wall, a tree, a prop, an NPC, the mountain; on the island also an invisible wall (layer 4, `bounds`). Not needed
when only the look changed (a mesh, a
material), or for bodies on layer 3 (`camera`), the player's character (layer 2) and areas (`Area3D`). If you forget,
paths go through a moved object (the character runs into it and slides along) or around the empty spot where it stood.

**In the editor:**

1. Open the level's scene.
2. Select `NavigationRegion3D` in the scene tree.
3. Press **Bake NavigationMesh** on the toolbar above the 3D view. After a couple of seconds the blue mesh in the view
   updates: a hole the agent radius (0.5 m) around the object, solid mesh where it used to stand.
4. Save the scene (Ctrl+S): the mesh is embedded in the scene.

The bake parameters are on the resource itself: select `NavigationRegion3D` and expand `Navigation Mesh` in the
inspector.

After rebaking, run the tests ([Tests](../testing.md)): their routes follow the mesh. In the running game, Debug →
Visible Navigation in the editor shows the mesh, and Settings (F10) → Interface → **Character path line** shows the
character's path.

## The level

- **The center** is the spawn point. Around it: a ring of ruined columns, a U-shaped trap open toward the spawn, a
  long wall with a gap, crates, a grove, a hedge maze and a 1.6 m platform with a ramp on its west side and stairs on
  its east side (seven 0.2 m stairs with 0.4 m treads, one static body of seven boxes). The tests use all of these, so
  they stay where they are.
- **Roads** are dirt strips from the south fence through the gap in the wall to the spawn and on to the mountain, the
  ruins, the camp and the ramp; the farmstead's road branches off south of the wall. They are only a pattern (the
  segments `ROADS` in `shared/world/terrain.gdshaderinc`) and do not affect movement. The ground and the gentle grass
  at the foot of the mountain both draw them, so the road runs into the mountain trail without a break. It reaches the
  start of the trail from the west: east of the trail start the mountain is a solid cliff up to 4 m.
- **Props** from `shared/world/props/`: a forest in the north-west and along the edges, bushes, boulders, a camp in
  the east (a tent, a campfire with flickering light, barrels), a farmstead in the south-west (a house, a well).
- **The mountain** in the north-east, 10 m high, with one spiral trail to the top.
- **The ten hero looks** in a row with their backs to the south wall, east of the gap (see
  [Characters](characters.md#hero-looks)).

Edit the prop instances in the level scene to change the layout, then rebake navigation. The regression tests use
specific routes and obstacle positions in this demo; use a separate level for your own layout, or update the tests
alongside changes to their test geometry.

### Places and NPCs

Four places are `PointOfInterest` areas. The first time the player enters one, "Discovered: …" appears at the top
of the screen for a few seconds. NPCs stand at each place with name labels (`Label3D`) above their heads, facing
its center; the Knight faces down the road.

| Place | Where | Who is there |
|---|---|---|
| Windswept Peak | The top of the mountain in the north-east | The Wizard, by an altar with a crystal |
| Travelers' Camp | East: tent, campfire, barrels | The Ranger and the Dwarf at the fire |
| Farmstead by the Well | South-west: house, well | The Knight on guard by the road |
| Ancient Circle | The ring of columns north-west of the spawn | The Rogue by the altar |

Each NPC is a `StaticBody3D` with a capsule on layer 1 (`World/NavigationRegion3D/Characters`): the navigation mesh
goes around them and nobody walks through them. The camp, the farmstead and the ruins are under `World/Places`; the
peak is in `mountain.tscn`.

**A new place:** add a `PointOfInterest` (an `Area3D` whose `collision_mask` includes the characters' layer 2) with
a collision shape and a `title` to any world scene. The toast finds every place through its group, also on a level
loaded later; no connections are needed. Add the title to the translations ([UI](ui.md#translations)). Lonely Isle has
a fifth place, Hermit's Camp.

## Surfaces

Almost every surface is a shader in `shared/world/` with a material in `shared/world/materials/`; the exceptions are
plain `StandardMaterial3D` materials, listed at the end of this section. What depends on an
object's size and shape is computed by the shader, which is cheap: masonry courses fitted to a box's height, planks,
frames and posts, timber framing, barrel staves and hoops, column flutes and drums, roads along `ROADS`, rock layers by
height. So a box of any size does not stretch its pattern. Fine detail (grass blades, pebbles, leaves, bark, stone
grain) comes from baked textures, see below.

| Surface | Shader | What it looks like |
|---|---|---|
| Walls, platform, ramp, stairs | `stone_masonry` | Blocks in offset courses with joints, each block with its own tint, grain and chips, relief through the normal, dirt and moss near the ground. The top is a course of stones across the short side |
| Hedge maze | `hedge_foliage` | Two layers of leaves, each with its own rotation, size, tint and tilt; the shadow of the bush's depth in the gaps; uneven sides like a trimmed bush |
| Crates, fence | `wood_planks` | Planks with growth rings, fibers, knots and gaps. Crates have a plank frame on each face, a diagonal brace and nails; the fence has long weathered boards on posts every 2.5 m |
| Columns, well | `stone_column` | Flutes around the circumference through the normal, 0.8 m drums with joints from the ground, a smooth base, streaks, rare cracks, lichen, moss near the ground. The well uses round block masonry (`blocks_around`) |
| Boulders, standing stones | `rock` | Grainy stone with veins and cracks, lichen on top, moss near the ground; the pattern is triplanar (`triplanar.gdshaderinc`), different on each boulder |
| House walls | `timber_plaster` | Timber framing: plaster with stains and fine cracks in a frame of posts and beams, a stone plinth |
| House and well roofs | `thatch` | Thatch in rows of sheaves with a shadow under each row, straws down the slope, a tied ridge, moss |
| Tent, flap, banner | `canvas` | Woven canvas: panels with seams, folds, patches; the banner has a border and an emblem |
| Barrels | `barrel` | Staves with gaps, rusty iron hoops, a plank lid |
| Logs, trunks, banner pole | `bark` | Furrowed bark with moss near the ground and on the north side; charred and smoldering logs at the campfire |
| Tree crowns, bushes | `foliage` | Leaves in two layers on three axis planes, lumps, a lighter top; needles on pines, orange and red on the autumn oak |
| Ground | `ground_grid` | See below. The island's grass is `island_ground.tres`, the same ground with the roads off (`roads`) |
| Mountain | `mountain` | Grass, the trail and rock layers chosen by the face color |
| Water in the well, the island's lake | `water` | Slow ripples. The lake (`lake_water.tres`) is a lighter blue with a stronger ripple (`ripple` 0.55 against 0.35) |

The masonry pattern follows the mesh faces and knows the box size: a `BoxMesh` without face subdivisions has a
vertex only at each corner, so `abs(VERTEX)` gives the half sizes. They reach the pixels unchanged (a `flat`
varying): interpolated, they would differ in the last digits from pixel to pixel, and a course count that falls on a
half (a 1.4 m stair with 0.4 m courses) would round up in some pixels and down in others, and flicker. The plaster,
plank and cloth shaders pass the box size the same way. The courses on the sides fit the height, and the
top course of a side is the edge of the top stones, so its joints continue the top's joints at the edge. The ramp
(a thin slab) is one such course, and the joints of its ends match the top. The maze boxes, in contrast, have face
subdivisions every 25 cm (`subdivide_*`), because their sides are displaced by noise from the world position: copies of
a vertex on an edge move together and faces do not split. The collision shapes are still the plain boxes; the leaves
stick out a few centimeters.

**The ground** (`ground_grid.gdshader`, shared part `terrain.gdshaderinc`): grass at several scales (large patches
of dark, normal and dry grass, tussocks, blades in two layers with tilted normals and shadow at the roots, scattered
flowers in clearings) and roads (a ragged edge with tufts of grass, a trodden lighter middle, shallow ruts, grain, fine
cracks in dry spots, pebbles with shadows, more of them at the edge). The fine detail tiles every 3.84 m from baked
textures; the large patches come from a mask over the whole ground. In the distance the detail fades to an average
color through the textures' mip levels. The mountain's grass and trail use the same code. A 1 m grid with thick lines
every 5 m is off by default; turn it on with `grid_strength` on `shared/world/materials/ground.tres` to measure speeds
and distances.

Cheap shader noise (random numbers for stones and planks, lumps of foliage) is in `noise.gdshaderinc`, leaves in
`leaves.gdshaderinc`. A few materials stay plain `StandardMaterial3D`: `dark_wood.tres` and `wood.tres`, which the
characters' equipment (staffs, bow, axe) uses, and the glowing `crystal.tres` and `fire.tres`.

## Baked textures

The surface patterns (grass with blades and flowers, dirt with pebbles, leaves, bark, stone grain, plaster, wood
fibers, thatch, woven cloth) were designed as noise shaders, but the game does not compute them for every pixel: they
were baked once into seamless textures in `shared/world/textures/`, and the world shaders tile them.

Baking replaces repeated per-pixel noise calculations with texture samples. Keep the import settings below when
replacing these textures; several channels contain shader data rather than ordinary color.

- **Seamless.** The noise of the patterns repeats with the tile, with a whole number of features per tile, so the seam
  is invisible. The exception is `ground_mask`: the large patches and roads over the whole 96 m ground, not tiled.
- **Color stays in the world shader.** Leaves, column stone, bark and wood fibers are baked without color (leaf tint,
  shadow, leaf or gap, stains, normal tilt), and the world shader builds the color from material parameters: one
  leaf texture serves the oak, the autumn oak and the hedge. Only grass (a multiplier for the patch tint), flowers and
  pebbles have color baked in.
- **Relief** is the normal tilt in two channels, computed while baking from height differences.
- **Files:** lossless WebP (data under zero alpha stays intact), imported with GPU compression (BPTC), mipmaps and no
  color fix for transparent pixels, since the alpha holds data. Keep these import settings when replacing a texture.

## The mountain and Windswept Peak

The mountain stands in a corner at the edge of the world (its slopes go past the fence) and is visible from
everywhere. The trail to the top is 3 m wide: it starts at the end of the road (23, 0, −19) and winds almost all the
way around the mountain (340°) at a 12° grade. The slopes on both sides are steep (76° above the trail, 60° below):
they cannot be climbed on foot (the body stands only on 45° and flatter) or along a path (the navigation mesh takes
slopes up to 40°), and the ledge guard keeps the character from falling off the trail. A click on the top from the
ground leads along the trail: 51 m in 9.8 s.

At the top there is a shrine: an altar with a glowing crystal floating and slowly turning above it, five standing
stones and a banner. The top is the place Windswept Peak.

The mountain is a height map generated by a script: a mesh with face colors and flat shading, with
the material `materials/mountain.tres` on top (grass with blades, trail dirt with pebbles, rock layers with cracks and
lichen, by face color), and a collision shape from the same triangles (`shared/world/mountain/*.res`). What it took for
a path to be built along the trail:

- The trail has one height across, so its inner edge is steeper than its axis (by the ratio of the axis radius to the
  edge radius). The turns are not tight (radius 9.5 → 7 m), so that even near the top the inner edge is flatter than
  16°: steeper, and a navigation mesh with a 0.075 m climb per 0.25 m cell breaks the trail.
- The entrance from the road: at the foot, while the trail is below 1 m, the outer slope is gentle. Otherwise the
  trail drops off outward from the start, and its entrance narrows to a strip thinner than the agent's margin.
- The last 3 m of the trail are level with the top, so the trail meets the top along a strip, not at a point.

The camera looks from the south-east by default, so on the far side of the trail the mountain hides the hero, who
then shows as a silhouette (see [Characters](characters.md#occludedsilhouette-one-shape-the-weapon-outlined-a-rim)).

---

*This page matches Iso & Orbit 1.2.0.*
