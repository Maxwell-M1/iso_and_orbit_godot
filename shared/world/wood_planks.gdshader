// Wood on boxes (BoxMesh without face subdivisions): planks with growth rings, fibers, knots and gaps between them. A
// crate is a frame of planks along the edges of each face, a diagonal brace on the sides and nails; a fence is long
// planks on posts; a door, shutters and posts are upright planks (vertical). The pattern follows the mesh faces and
// knows the box size: in a box without subdivisions every vertex is a corner, and abs(VERTEX) gives half its sides. The
// ring curvature and the fibers are baked into a seamless texture (the wood_grain texture), and each plank gets its own
// offset.
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"

uniform sampler2D wood_grain : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 wood_color : source_color = vec3(0.56, 0.38, 0.21);
uniform vec3 wood_dark_color : source_color = vec3(0.35, 0.22, 0.11);
uniform vec3 gap_color : source_color = vec3(0.09, 0.06, 0.04);
// How much the planks differ from each other in tone.
uniform float color_variation : hint_range(0.0, 0.5) = 0.14;
// Grayness of old wood: 0 is fresh, 1 is fully gray.
uniform float weathering : hint_range(0.0, 1.0) = 0.0;
// Width of a cladding plank, m: adjusted so that a face holds a whole number of planks.
uniform float plank_width = 0.2;
// Width of the frame planks along the edges of each face (crate, door), m; 0 means no frame.
uniform float frame_width = 0.0;
// Diagonal brace on the sides inside the frame.
uniform bool brace = false;
// On the sides the planks stand vertically (door, shutters, posts); otherwise they lie lengthwise.
uniform bool vertical = false;
// Posts on the sides and on top every this many meters (fence), m; 0 means no posts. Planks end at the posts.
uniform float post_spacing = 0.0;
uniform float post_width = 0.18;
uniform float relief : hint_range(0.0, 3.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;

// Width of the gap between planks, m.
const float GAP = 0.006;
// "No gap": at the box edge the plank wraps around onto the neighboring face.
const float NO_GAP = 1000.0;
// Relief depth at relief = 1, m: frame planks and posts sit higher than the cladding.
const float RELIEF_DEPTH = 0.012;
// Fiber tile: m along and across (as the texture was baked).
const vec2 GRAIN_TILE = vec2(5.0, 1.0);

struct Board {
	// Distance to the gap around the plank, m.
	float edge;
	// Along the fibers (m) and across from the middle of the plank (m).
	vec2 grain;
	vec2 id;
	// 0 is cladding, 1 is the frame and posts on top of it, the brace is in between.
	float lift;
};

varying vec3 local_position;
varying vec3 local_normal;
varying vec3 half_extent;
varying vec3 world_position;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	half_extent = abs(VERTEX);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Plank at point f of a face of size 2·extent (x along, y across, from the middle). side marks a side face (it has the
// brace), seed gives each face its own planks.
Board board_at(vec2 f, vec2 extent, bool side, float seed) {
	Board board;
	vec2 to_edge = extent - abs(f);
	float to_post = NO_GAP;
	// Span between posts: the planks of each span get their own tone and pattern.
	float span = 0.0;
	if (post_spacing > 0.0) {
		span = floor(f.x / post_spacing);
		float post = round(f.x / post_spacing);
		float off = f.x - post * post_spacing;
		to_post = abs(off) - post_width * 0.5;
		if (to_post < 0.0) {
			board.edge = -to_post;
			board.grain = vec2(f.y, off);
			board.id = vec2(post, 91.0 + seed);
			board.lift = 1.0;
			return board;
		}
	}
	float frame = frame_width;
	float to_brace = NO_GAP;
	if (frame > 0.0) {
		if (to_edge.y < frame) {
			// The cross planks of the frame span the full length of the face; the lengthwise ones sit between them.
			board.edge = frame - to_edge.y;
			board.grain = vec2(f.x, to_edge.y - frame * 0.5);
			board.id = vec2(sign(f.y), 50.0 + seed);
			board.lift = 1.0;
			return board;
		}
		if (to_edge.x < frame) {
			board.edge = min(frame - to_edge.x, to_edge.y - frame);
			board.grain = vec2(f.y, to_edge.x - frame * 0.5);
			board.id = vec2(sign(f.x), 60.0 + seed);
			board.lift = 1.0;
			return board;
		}
		if (side && brace) {
			// A corner-to-corner brace inside the frame; on neighboring faces it runs in different directions.
			vec2 inner = extent - frame;
			vec2 direction = normalize(vec2(inner.x, inner.y * (mod(seed, 2.0) < 1.0 ? 1.0 : -1.0)));
			float across = f.x * direction.y - f.y * direction.x;
			to_brace = abs(across) - frame * 0.5;
			if (to_brace < 0.0) {
				board.edge = min(-to_brace, min(to_edge.x, to_edge.y) - frame);
				board.grain = vec2(dot(f, direction), across);
				board.id = vec2(0.0, 70.0 + seed);
				board.lift = 0.6;
				return board;
			}
		}
	}
	// Cladding: rows of planks across, inside the frame; planks end at the frame, the brace and the posts.
	float inner_y = extent.y - frame;
	float rows = max(1.0, round(2.0 * inner_y / plank_width));
	float width = 2.0 * inner_y / rows;
	float row = clamp(floor((f.y + inner_y) / width), 0.0, rows - 1.0);
	float at = f.y + inner_y - row * width;
	float to_row = min(row > 0.5 ? at : NO_GAP, row < rows - 1.5 ? width - at : NO_GAP);
	float to_frame = frame > 0.0 ? min(to_edge.x, to_edge.y) - frame : NO_GAP;
	board.edge = min(min(to_row, to_post), min(to_frame, to_brace));
	board.grain = vec2(f.x, at - width * 0.5);
	board.id = vec2(row, span + 20.0 * seed);
	board.lift = 0.0;
	return board;
}

// Surface height: 0 is the bottom of a gap; on a plank it follows its "lift" (the frame is higher than the cladding),
// with a bevel along the edge.
float board_height(Board board) {
	float face = smoothstep(GAP * 0.5, GAP * 0.5 + 0.01, board.edge);
	return face * (0.5 + 0.5 * board.lift);
}

void fragment() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 lp = local_position * scale;
	vec3 extent = half_extent * scale;
	// The face is chosen by the dominant axis of the mesh normal. u, v are the face coordinate axes in mesh axes; on
	// the top, u runs along the long side.
	vec3 axis = abs(local_normal);
	bool side = axis.y < max(axis.x, axis.z);
	bool x_long = extent.x >= extent.z;
	vec3 u = side ? (axis.z >= axis.x ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0))
			: (x_long ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0));
	vec3 v = side ? vec3(0.0, 1.0, 0.0) : (x_long ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0));
	if (vertical && side) {
		vec3 across = u;
		u = v;
		v = across;
	}
	vec2 f = vec2(dot(lp, u), dot(lp, v));
	vec2 face_extent = vec2(dot(extent, u), dot(extent, v));
	vec3 n = sign(local_normal) * step(0.5, axis);
	float seed = dot(n, vec3(1.0, 3.0, 5.0)) + 7.0;

	Board board = board_at(f, face_extent, side, seed);
	float height = board_height(board);
	float probe = 0.003;
	vec2 slope = vec2(board_height(board_at(f + vec2(probe, 0.0), face_extent, side, seed)) - height,
			board_height(board_at(f + vec2(0.0, probe), face_extent, side, seed)) - height) / probe;
	// From afar the gaps and fibers are thinner than a pixel: only the plank tone remains.
	float pixel = max(fwidth(f).x, fwidth(f).y);
	float detail = 1.0 - smoothstep(0.008, 0.03, pixel);

	// Rings cut along the plank: dark stripes along the fibers, bent by noise; fibers are strokes along the plank.
	vec2 g = board.grain;
	vec4 grain = texture(wood_grain, g / GRAIN_TILE + hash2(board.id + vec2(5.1, 9.0)));
	float rings = fract((g.y + hash(board.id) * 3.7) * 13.0 + grain.r * 2.2);
	float ring_line = (1.0 - smoothstep(0.0, 0.2, min(rings, 1.0 - rings))) * detail;
	float fibers = grain.g;
	vec3 color = mix(wood_color, wood_dark_color, 0.55 * ring_line + 0.3 * fibers * detail);
	color *= 1.0 + (hash(board.id + vec2(2.2, 0.7)) - 0.5) * 2.0 * color_variation;
	// Knots: every 0.9 m along the plank with a 40% chance, a dark core and a halo.
	float knot_cell = floor(g.x / 0.9);
	vec2 knot_seed = board.id + vec2(knot_cell * 1.7, 4.4);
	vec2 knot = vec2((knot_cell + 0.2 + 0.6 * hash(knot_seed)) * 0.9, (hash(knot_seed + 1.3) - 0.5) * 0.06);
	float knot_distance = length((g - knot) * vec2(1.0, 2.0));
	float has_knot = step(0.6, hash(knot_seed + 2.9)) * detail;
	color = mix(color, wood_dark_color * 0.6, has_knot * (1.0 - smoothstep(0.01, 0.025, knot_distance)));
	color *= 1.0 - 0.18 * has_knot * (1.0 - smoothstep(0.02, 0.06, knot_distance));
	// Old wood turns gray.
	float luma = dot(color, vec3(0.3, 0.55, 0.15));
	color = mix(color, vec3(luma * 1.05, luma, luma * 0.92), weathering * 0.75);
	color = mix(gap_color, color, mix(1.0, smoothstep(0.0, 0.5, height), detail));

	// Nails: at the corners and midpoints of the frame; on posts, one per cladding plank.
	float nail = NO_GAP;
	if (frame_width > 0.0) {
		vec2 corner = face_extent - frame_width * 0.5;
		vec2 af = abs(f);
		nail = min(length(af - corner), min(length(af - vec2(0.0, corner.y)), length(af - vec2(corner.x, 0.0))));
	}
	if (post_spacing > 0.0 && board.id.y > 90.0) {
		float rows = max(1.0, round(2.0 * face_extent.y / plank_width));
		float width = 2.0 * face_extent.y / rows;
		float row_center = (clamp(floor((f.y + face_extent.y) / width), 0.0, rows - 1.0) + 0.5) * width - face_extent.y;
		nail = length(vec2(board.grain.y, f.y - row_center));
	}
	float on_nail = (1.0 - smoothstep(0.007, 0.011, nail)) * detail;
	color = mix(color, vec3(0.16, 0.15, 0.14), on_nail);

	// Wood is darker near the ground: damp and dirt.
	color *= mix(0.72, 1.0, smoothstep(0.0, 0.3, world_position.y));

	ALBEDO = color;
	ROUGHNESS = mix(mix(roughness, 1.0, 1.0 - smoothstep(0.0, 0.5, height)), 0.45, on_nail);
	METALLIC = on_nail * 0.6;
	AO = mix(1.0, 0.65 + 0.35 * smoothstep(0.0, 0.5, height), detail);
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(local_normal, 0.0)).xyz);
	vec3 u_world = normalize((MODEL_MATRIX * vec4(u, 0.0)).xyz);
	vec3 v_world = normalize((MODEL_MATRIX * vec4(v, 0.0)).xyz);
	vec3 bumped = world_normal - relief * RELIEF_DEPTH * detail * (slope.x * u_world + slope.y * v_world);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(bumped), 0.0)).xyz);
}
