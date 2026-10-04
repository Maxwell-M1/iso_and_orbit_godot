# World and navigation

The demo level is `shared/world/world.tscn`: an 80 × 80 m glade behind a wooden fence. Everything in it is built
from primitives and shaders; the fine surface patterns come from baked textures.

## The level

- **The center** is the spawn point. Around it: a ring of ruined columns, a U-shaped trap open toward the spawn, a
  long wall with a gap, crates, a grove, a hedge maze and a 1.6 m platform that can only be reached by its ramp. The
  tests use all of these, so they stay where they are.
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

The forest, bushes and boulders were placed once by a throwaway script with a fixed seed, keeping clear of the
places the tests use (routes, the run along the southern strip, the jump off the platform, everything around the
spawn). The script is not in the project; the layout is now edited in the editor. When moving trees, keep those
places clear.

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
a collision shape and a `title` to any world scene. The toast finds every place through its group; no connections
are needed. Add the title to the translations ([UI](ui.md#translations)).

## Surfaces

Almost every surface is a shader in `shared/world/` with a material in `shared/world/materials/`; the exceptions are
plain `StandardMaterial3D` materials, listed at the end of this section. What depends on an
object's size and shape is computed by the shader, which is cheap: masonry courses fitted to a box's height, planks,
frames and posts, timber framing, barrel staves and hoops, column flutes and drums, roads along `ROADS`, rock layers by
height. So a box of any size does not stretch its pattern. Fine detail (grass blades, pebbles, leaves, bark, stone
grain) comes from baked textures, see below.

| Surface | Shader | What it looks like |
|---|---|---|
| Walls, platform, ramp | `stone_masonry` | Blocks in offset courses with joints, each block with its own tint, grain and chips, relief through the normal, dirt and moss near the ground. The top is a course of stones across the short side |
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
| Ground | `ground_grid` | See below |
| Mountain | `mountain` | Grass, the trail and rock layers chosen by the face color |
| Water in the well | `water` | Slow ripples |

The masonry pattern follows the mesh faces and knows the box size: a `BoxMesh` without face subdivisions has a
vertex only at each corner, so `abs(VERTEX)` gives the half sizes. The courses on the sides fit the height, and the
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

The reason is frame time. The ground alone cost the GPU about 2.5 ms per frame in a 2560 × 1511 window: every pixel
looped over 18 cells of grass blades with sines and hashes. With textures the GPU needs about 2 ms for the whole frame
instead of 4.5, and the frame rate went from 160–230 to 300–470 (12 views of the level, no V-Sync, an RTX 4090
Laptop GPU; beyond that the CPU is the limit).

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

## Physics layers and navigation

Obstacles are `StaticBody3D` on layer 1 (`world`), characters on layer 2 (`characters`), camera-only bodies on layer 3
(`camera`), see [Project setup](../project-setup.md#physics-layers). The navigation mesh is baked from layer 1
collisions with a 0.5 m agent radius; the character's capsule is 0.35 m, so paths keep a margin from corners.

| `NavigationMesh` parameter | Value | Why |
|---|---|---|
| `agent_radius` | 0.5 m | Paths keep clear of corners |
| `agent_height` | 1.75 m | |
| `agent_max_slope` | 40° | The mountain's slopes stay off the mesh |
| `cell_height` | 0.025 m | Fine enough to measure the climb below |
| `agent_max_climb` | 0.075 m (3 cells) | Below the 0.1 m ledge the body can step onto |
| `geometry_collision_mask` | layer 1 | Only obstacles count |

**A path never leads onto a ledge higher than the body can climb.** The `CharacterBody3D` capsule steps onto a ledge
no higher than `r·(1 − cos floor_max_angle)` = 0.35 × (1 − cos 45°) ≈ 0.1 m. The mesh used to be baked with
`agent_max_climb` = 0.25 m at `cell_height` = 0.25 m, and Recast measures heights in whole cells, so it treated a
ledge of almost 0.5 m as walkable: the path to the platform entered the ramp from the side, where its edge is 0.4 m
above the ground, and the character ran into it. Now a ledge above 0.075 m is not joined, and the ramp (a rise of
0.067 m per 0.25 m cell) stays whole. The navigation map's cell height must not exceed the mesh's (or the engine
warns), so `project.godot` sets `navigation/3d/default_cell_height` to 0.025.

A Recast mesh hangs about two cell heights above the ground (0.05 m here; it was 0.5 m with the old 0.25 m cells).
That is why `NavigationMover` compares path points in the horizontal plane, see
[Locomotion](locomotion.md#navigationmover).

## Rebaking the navigation mesh

The mesh is baked in advance and stored right in `shared/world/world.tscn` (the `NavigationMesh` resource of
`NavigationRegion3D`); the game does not recompute it. After editing the level, rebake it.

**When:** you moved, added, removed or resized anything with a collision shape on layer 1 (`world`): a rock, a crate,
a wall, a tree, a prop, an NPC, the mountain. Not needed when only the look changed (a mesh, a
material), or for bodies on layer 3 (`camera`), the player's character (layer 2) and areas (`Area3D`). If you forget,
paths go through a moved object (the character runs into it and slides along) or around the empty spot where it stood.

**In the editor:**

1. Open `shared/world/world.tscn`.
2. Select `NavigationRegion3D` in the scene tree.
3. Press **Bake NavigationMesh** on the toolbar above the 3D view. After a couple of seconds the blue mesh in the view
   updates: a hole the agent radius (0.5 m) around the object, solid mesh where it used to stand.
4. Save the scene (Ctrl+S): the mesh is embedded in the scene.

The bake parameters are on the resource itself: select `NavigationRegion3D` and expand `Navigation Mesh` in the
inspector.

After rebaking, run the tests ([Tests](../testing.md)): their routes follow the mesh. In the running game, Debug →
Visible Navigation in the editor shows the mesh, and Settings (F10) → Interface → **Character path line** shows the
character's path.

---

*This page matches Iso & Orbit 1.1.0.*
