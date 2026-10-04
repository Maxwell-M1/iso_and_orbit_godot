// Stone masonry for walls, platforms and ramps made of boxes (BoxMesh without face subdivisions): blocks in offset
// courses with joints, each block with its own tint, grain and chipped edges, dirt and moss near the ground; slabs on
// top. The shader computes the layout itself, so a box of any size does not stretch the pattern; the chips, roughness,
// grain, specks, streaks and moss are baked into seamless textures (the masonry texture), and each stone gets its own
// tile offset.
//
// The pattern follows the mesh faces however the box is rotated, and it knows the box size: in a box without
// subdivisions every vertex is a corner, and abs(VERTEX) gives half its sides. So the courses on the sides are fitted
// to the height (whole courses, from bottom to top), and the top course of a side is made of the edges of the top
// stones: its joints continue the joints of the top at that edge. A thin slab (a ramp) is one such course, and the top
// of a wall is one course of through stones.
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"

uniform sampler2D stone_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_streaks : filter_linear_mipmap_anisotropic, repeat_enable;

// Stone color and how much the blocks differ from each other in tone.
uniform vec3 stone_color : source_color = vec3(0.6, 0.57, 0.5);
uniform float color_variation : hint_range(0.0, 0.5) = 0.16;
uniform vec3 joint_color : source_color = vec3(0.43, 0.41, 0.37);
// Block on the sides: length and course height, m. The height is adjusted so that there is a whole number of courses;
// each course has its own length, ±15%, and its own offset.
uniform vec2 block_size = vec2(0.9, 0.44);
// Top stone: length along the long side and course width across it, m. The width is adjusted so that there is a whole
// number of courses across.
uniform vec2 slab_size = vec2(1.0, 0.8);
// Joint width without chips, m; chips widen it in places by up to another 5 cm.
uniform float joint_width = 0.012;
// Relief: blocks bulge, joints are recessed, the stone is rough (through the normal; the geometry does not change).
uniform float relief : hint_range(0.0, 3.0) = 1.0;
uniform vec3 moss_color : source_color = vec3(0.26, 0.35, 0.17);
// Amount of moss: 0 is none at all. Moss grows in patches near the ground (up to moss_height) and in the joints.
uniform float moss_amount : hint_range(0.0, 1.0) = 0.25;
uniform float moss_height = 0.7;
uniform float roughness : hint_range(0.0, 1.0) = 0.92;

// Relief depth at relief = 1, m.
const float RELIEF_DEPTH = 0.01;
// "No joint": at the box edge the stone wraps around onto the neighboring face.
const float NO_JOINT = 1000.0;
// Tile side, m (as the texture was baked).
const float TILE = 4.0;

varying vec3 local_position;
varying vec3 local_normal;
// The half sides of the box, flat: every pixel of a face gets the exact value. Interpolated, it would differ in the last
// digits from pixel to pixel, and a count of courses that falls on a half (a 1.4 m step with 0.4 m courses) would round
// up in some pixels and down in others: two layouts mixed, flickering as the camera moves.
varying flat vec3 half_extent;
varying vec3 world_position;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	half_extent = abs(VERTEX);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// The stones of course row, about stone_length long, along u: x is the distance to the nearest joint across the course
// (m), y is the stone number. Each course has its own stone length (±15%) and its own offset.
vec2 course(float u, float stone_length, float row) {
	float actual = stone_length * (0.85 + 0.3 * hash(vec2(row, 3.7)));
	float x = u / actual + hash(vec2(row, 9.1));
	float inside = fract(x) * actual;
	return vec2(min(inside, actual - inside), floor(x));
}

// Courses that the length 2·extent divides into: x is how many (at least one), y is the course width.
vec2 rows_of(float extent, float wanted) {
	// Rounded half up: round() may go either way at a half.
	float count = max(1.0, floor(2.0 * extent / wanted + 0.5));
	return vec2(count, 2.0 * extent / count);
}

// Distance to the joint between courses for point at (from the edge, m) in course row; there is no joint at the box
// edges. Beyond the course edge it is less than zero.
float to_row_joint(float at, vec2 rows, float row) {
	float below = row > 0.5 ? at - row * rows.y : NO_JOINT;
	float above = row < rows.x - 1.5 ? (row + 1.0) * rows.y - at : NO_JOINT;
	return min(below, above);
}

// Top stones: courses across the short side. ab is the point (a along the long side, b across it, from the middle),
// extent_ab holds the half sides. x is the distance to the joint across a, y is the distance to the joint between
// courses, zw is the stone number.
vec4 top_stones(vec2 ab, vec2 extent_ab, float row) {
	vec2 rows = rows_of(extent_ab.y, slab_size.y);
	vec2 along = course(ab.x, slab_size.x, row + 100.0);
	return vec4(along.x, to_row_joint(ab.y + extent_ab.y, rows, row), along.y, row + 100.0);
}

float top_row(vec2 ab, vec2 extent_ab) {
	vec2 rows = rows_of(extent_ab.y, slab_size.y);
	return clamp(floor((ab.y + extent_ab.y) / rows.y), 0.0, rows.x - 1.0);
}

// Stone at point lp (m, mesh axes) of face face: 0 is the top or bottom, 1 is a side with its normal along x, 2 is a
// side with its normal along z. row is the course to compute in: relief probes stay in the course of the original
// point, otherwise the neighboring course with its own joints would give a height jump and a notch where the courses
// meet. x is the distance to the nearest joint (m), yz is the stone number.
vec3 stone_at(vec3 lp, vec3 extent, int face, float row) {
	bool x_long = extent.x >= extent.z;
	vec2 ab = x_long ? lp.xz : lp.zx;
	vec2 extent_ab = x_long ? extent.xz : extent.zx;
	if (face == 0) {
		vec4 top = top_stones(ab, extent_ab, row);
		return vec3(min(top.x, top.y), top.zw);
	}
	vec2 rows = rows_of(extent.y, block_size.y);
	float to_course = to_row_joint(lp.y + extent.y, rows, row);
	if (row > rows.x - 1.5) {
		// The top course is made of the edges of the top stones; the side point lies on the top edge.
		vec4 top = top_stones(ab, extent_ab, top_row(ab, extent_ab));
		bool along_a = (face == 2) == x_long;
		return vec3(min(along_a ? top.x : top.y, to_course), top.zw);
	}
	vec2 stone = course(face == 2 ? lp.x : lp.z, block_size.x, row);
	return vec3(min(stone.x, to_course), stone.y, row);
}

// Tile offset for stone id: each stone gets its own roughness and grain.
vec2 stone_offset(vec2 id) {
	return hash2(id + vec2(13.7, 7.1));
}

// The tile at point uv with offset offset. Neighboring stones have different offsets, so where stones meet a mip level
// chosen from the uv difference of neighboring pixels would be the smallest one, and the joint would glow; so the
// derivatives come from uv without the offset.
vec4 detail_at(vec2 uv, vec2 offset, vec2 uv_dx, vec2 uv_dy) {
	return textureGrad(stone_detail, uv + offset, uv_dx, uv_dy);
}

// Surface height: 0 is the bottom of a joint, about 1 is the stone face. p holds the face coordinates (m) for the tile.
// The stone edge is uneven (chips), the face is rough. Chips only shrink the stone: an edge beyond the seam line would
// give a height jump between neighboring stones and a notch.
float surface_height(vec3 lp, vec3 extent, int face, float row, vec2 p, vec2 uv_dx, vec2 uv_dy) {
	vec3 stone = stone_at(lp, extent, face, row);
	float edge = stone.x - detail_at(p / TILE, vec2(0.0), uv_dx, uv_dy).r * 0.025;
	float face_height = smoothstep(joint_width * 0.5, joint_width * 0.5 + 0.06, edge);
	return face_height * (0.85 + 0.15 * detail_at(p / TILE, stone_offset(stone.yz), uv_dx, uv_dy).g);
}

void fragment() {
	// Node scale: into meters along the mesh axes.
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 lp = local_position * scale;
	vec3 extent = half_extent * scale;
	// The face is chosen by the dominant axis of the mesh normal. u, v are the face coordinate axes in mesh axes: the
	// relief tilts the normal along them.
	vec3 axis = abs(local_normal);
	int face = axis.y > max(axis.x, axis.z) ? 0 : (axis.x > axis.z ? 1 : 2);
	bool x_long = extent.x >= extent.z;
	vec3 u = face == 0 ? (x_long ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0))
			: (face == 2 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0));
	vec3 v = face == 0 ? (x_long ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0)) : vec3(0.0, 1.0, 0.0);
	vec2 p = vec2(dot(lp, u), dot(lp, v));
	float row;
	if (face == 0) {
		row = top_row(x_long ? lp.xz : lp.zx, x_long ? extent.xz : extent.zx);
		// An offset so the top noise does not repeat the side noise.
		p += vec2(31.7, 17.3);
	} else {
		vec2 rows = rows_of(extent.y, block_size.y);
		row = clamp(floor((lp.y + extent.y) / rows.y), 0.0, rows.x - 1.0);
	}

	vec2 uv_dx = dFdx(p / TILE);
	vec2 uv_dy = dFdy(p / TILE);
	vec3 stone = stone_at(lp, extent, face, row);
	float height = surface_height(lp, extent, face, row, p, uv_dx, uv_dy);
	// Relief slope from height differences over 4 mm.
	float probe = 0.004;
	vec2 slope = vec2(surface_height(lp + u * probe, extent, face, row, p + vec2(probe, 0.0), uv_dx, uv_dy) - height,
			surface_height(lp + v * probe, extent, face, row, p + vec2(0.0, probe), uv_dx, uv_dy) - height) / probe;
	// From afar the joints are thinner than a pixel: the relief and joints fade out, leaving the stone tones.
	float pixel = max(fwidth(p).x, fwidth(p).y);
	float detail = 1.0 - smoothstep(0.02, 0.06, pixel);

	float tone = hash(stone.yz + vec2(17.0, 29.0)) - 0.5;
	float warmth = hash(stone.yz + vec2(5.3, 1.1)) - 0.5;
	vec3 albedo = stone_color * (1.0 + tone * 2.0 * color_variation);
	albedo *= vec3(1.0 + warmth * 0.1, 1.0, 1.0 - warmth * 0.1);
	vec4 stone_tex = detail_at(p / TILE, stone_offset(stone.yz), uv_dx, uv_dy);
	float grain = stone_tex.b;
	albedo *= 0.85 + 0.3 * grain;
	// Small dark specks and streaks running down.
	albedo *= 1.0 - 0.12 * stone_tex.a;
	vec4 streaks = texture(stone_streaks, p / TILE);
	albedo *= 1.0 - 0.14 * smoothstep(0.45, 0.75, streaks.r);
	float joint = (1.0 - smoothstep(0.15, 0.6, height)) * detail;
	vec3 color = mix(albedo, joint_color, joint);

	// Dirt from the ground and moss in patches: near the ground and in the joints.
	float near_ground = 1.0 - smoothstep(0.0, moss_height, world_position.y);
	color *= 1.0 - 0.22 * (1.0 - smoothstep(0.0, 0.35, world_position.y));
	float patches = smoothstep(0.42, 0.68, streaks.g);
	float moss = clamp((near_ground + joint * 0.7) * patches * moss_amount * 2.0, 0.0, 1.0);
	color = mix(color, moss_color * (0.75 + 0.5 * grain), moss);

	ALBEDO = color;
	ROUGHNESS = mix(roughness, 1.0, max(joint, moss));
	AO = mix(1.0, 0.7 + 0.3 * height, detail);
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(local_normal, 0.0)).xyz);
	vec3 u_world = normalize((MODEL_MATRIX * vec4(u, 0.0)).xyz);
	vec3 v_world = normalize((MODEL_MATRIX * vec4(v, 0.0)).xyz);
	vec3 bumped = world_normal - relief * RELIEF_DEPTH * detail * (slope.x * u_world + slope.y * v_world);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(bumped), 0.0)).xyz);
}
