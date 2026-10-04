// House walls from a box (BoxMesh without face subdivisions): timber framing, that is, plaster in a wooden frame on a
// stone plinth. Each side face has a plinth of stones, a bottom beam above it, a top beam at the top, and posts at the
// corners and at equal bays; between them is plaster with patches, small cracks and dirt at the bottom. The beams and
// stones stand out from the plaster (relief through the normal). The shader knows the box size: in a box without
// subdivisions every vertex is a corner, and abs(VERTEX) gives half its sides. The shader computes the layout itself;
// the plaster patches, stains and small cracks, the stone grain (the plaster texture) and the beam fibers (wood_grain)
// are baked into seamless textures.
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"

uniform sampler2D plaster_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wood_grain : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 plaster_color : source_color = vec3(0.86, 0.8, 0.7);
uniform vec3 timber_color : source_color = vec3(0.3, 0.2, 0.13);
uniform vec3 stone_color : source_color = vec3(0.55, 0.53, 0.49);
uniform vec3 joint_color : source_color = vec3(0.38, 0.36, 0.33);
// Plinth height and the width of beams and posts, m.
uniform float plinth_height = 0.4;
uniform float beam_width = 0.17;
// Bay between posts, m: adjusted so that a face holds a whole number of bays.
uniform float bay_width = 1.7;
uniform float roughness : hint_range(0.0, 1.0) = 0.92;

const float RELIEF_DEPTH = 0.015;
// Plaster tile, m, and fiber tile: m along and across (as the textures were baked).
const float PLASTER_TILE = 4.0;
const vec2 GRAIN_TILE = vec2(5.0, 1.0);
const int PLASTER = 0;
const int TIMBER = 1;
const int STONE = 2;

struct Part {
	int kind;
	// Distance to the edge of the part (beam, stone), m.
	float edge;
	// Along the beam fibers or along the course of stones, m.
	vec2 grain;
	vec2 id;
};

varying vec3 local_position;
varying vec3 local_normal;
// The half sides of the box, flat: every pixel of a face gets the exact value. Interpolated, it would differ in the last
// digits from pixel to pixel, and a count rounded at a half would differ too: the layout would flicker.
varying flat vec3 half_extent;
varying vec3 world_position;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	half_extent = abs(VERTEX);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Wall part at point f of a face of size 2·extent (x along, y up, from the middle).
Part part_at(vec2 f, vec2 extent, float seed) {
	Part part;
	float from_bottom = f.y + extent.y;
	float to_top = extent.y - f.y;
	if (from_bottom < plinth_height) {
		// Plinth: stones in 0.2 m courses, each course with its own offset.
		float row = floor(from_bottom / 0.2);
		float stone_length = 0.32 + 0.12 * hash(vec2(row, seed));
		float x = f.x / stone_length + hash(vec2(row, 3.1 + seed));
		float inside = fract(x) * stone_length;
		float in_row = from_bottom - row * 0.2;
		part.kind = STONE;
		part.edge = min(min(inside, stone_length - inside), min(row > 0.5 ? in_row : 1.0, 0.2 - in_row));
		part.grain = vec2(f.x, in_row);
		part.id = vec2(floor(x), row + seed * 10.0);
		return part;
	}
	float above_plinth = from_bottom - plinth_height;
	// Posts: at the corners (both faces of a corner share one post) and at equal bays.
	// Rounded half up: round() may go either way at a half.
	float bays = max(1.0, floor(2.0 * extent.x / bay_width + 0.5));
	float bay = 2.0 * extent.x / bays;
	float post = round((f.x + extent.x) / bay);
	float to_post = abs(f.x + extent.x - post * bay) - beam_width * (post < 0.5 || post > bays - 0.5 ? 1.0 : 0.5);
	if (above_plinth < beam_width || to_top < beam_width) {
		// The bottom and top beams span the full length of the face.
		part.kind = TIMBER;
		part.edge = above_plinth < beam_width ? min(above_plinth, beam_width - above_plinth) : beam_width - to_top;
		part.grain = vec2(f.x, above_plinth < beam_width ? above_plinth : to_top);
		part.id = vec2(above_plinth < beam_width ? 1.0 : 2.0, seed);
		return part;
	}
	if (to_post < 0.0) {
		part.kind = TIMBER;
		part.edge = min(-to_post, min(above_plinth - beam_width, to_top - beam_width));
		part.grain = vec2(f.y, f.x);
		part.id = vec2(post, 5.0 + seed);
		return part;
	}
	part.kind = PLASTER;
	part.edge = min(to_post, min(above_plinth - beam_width, to_top - beam_width));
	part.grain = f;
	part.id = vec2(floor((f.x + extent.x) / bay), seed);
	return part;
}

float part_height(Part part) {
	if (part.kind == PLASTER) {
		return 0.35;
	}
	float bevel = smoothstep(0.0, part.kind == STONE ? 0.03 : 0.015, part.edge - (part.kind == STONE ? 0.008 : 0.0));
	return part.kind == STONE ? 0.25 + 0.65 * bevel : 0.35 + 0.65 * bevel;
}

void fragment() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 lp = local_position * scale;
	vec3 extent = half_extent * scale;
	vec3 axis = abs(local_normal);
	bool side = axis.y < max(axis.x, axis.z);
	vec3 u = axis.z >= axis.x ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec2 f = vec2(dot(lp, u), lp.y);
	vec2 face_extent = vec2(dot(extent, u), extent.y);
	float seed = dot(sign(local_normal) * step(0.5, axis), vec3(1.0, 3.0, 5.0)) + 7.0;
	float pixel = max(fwidth(f).x, fwidth(f).y);
	float detail = 1.0 - smoothstep(0.01, 0.04, pixel);

	Part part = part_at(f, face_extent, seed);
	// Each face gets its own tile offset.
	vec4 plaster = texture(plaster_detail, f / PLASTER_TILE + vec2(seed * 0.37, seed * 0.61));
	vec3 color;
	if (!side) {
		color = plaster_color * 0.8;
	} else if (part.kind == PLASTER) {
		// Plaster: patches, yellow stains, thin cracks, dirtier toward the bottom.
		color = plaster_color * (0.92 + 0.12 * plaster.r);
		color = mix(color, color * vec3(0.95, 0.9, 0.78), smoothstep(0.55, 0.75, plaster.g));
		color *= 1.0 - 0.3 * plaster.b * detail;
		color *= mix(0.8, 1.0, smoothstep(0.0, 0.6, f.y + face_extent.y - plinth_height - beam_width));
		color *= mix(0.75, 1.0, smoothstep(0.0, 0.04, part.edge));
	} else if (part.kind == TIMBER) {
		// Beam: fibers along it, each beam with its own tone, dark cracks along it.
		vec2 offset = hash2(part.id + vec2(7.0, 3.0));
		float fibers = texture(wood_grain, part.grain * vec2(3.0 / 2.6, 120.0 / 140.0) / GRAIN_TILE + offset).g;
		color = timber_color * (0.85 + 0.3 * fibers) * (1.0 + (hash(part.id + 2.2) - 0.5) * 0.25);
		float split = texture(wood_grain, part.grain * vec2(1.5 / 0.8, 25.0 / 3.0) / GRAIN_TILE + offset).r;
		color *= 1.0 - 0.4 * (1.0 - smoothstep(0.0, 0.08, abs(split - 0.5))) * detail;
	} else {
		color = stone_color * (0.85 + 0.3 * hash(part.id + 1.7)) * (0.9 + 0.2 * plaster.a);
		color = mix(color, joint_color, (1.0 - smoothstep(0.004, 0.012, part.edge)) * detail);
	}
	// Darker near the ground.
	color *= mix(0.7, 1.0, smoothstep(0.0, 0.3, world_position.y));

	float height = part_height(part);
	float probe = 0.004;
	vec2 slope = vec2(part_height(part_at(f + vec2(probe, 0.0), face_extent, seed)) - height,
			part_height(part_at(f + vec2(0.0, probe), face_extent, seed)) - height) / probe;
	slope *= side ? 1.0 : 0.0;

	ALBEDO = color;
	ROUGHNESS = roughness;
	AO = mix(1.0, part.kind == PLASTER ? mix(0.75, 1.0, smoothstep(0.0, 0.05, part.edge)) : 1.0, detail);
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(local_normal, 0.0)).xyz);
	vec3 u_world = normalize((MODEL_MATRIX * vec4(u, 0.0)).xyz);
	vec3 bumped = world_normal - RELIEF_DEPTH * detail * (slope.x * u_world + slope.y * vec3(0.0, 1.0, 0.0));
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(bumped), 0.0)).xyz);
}
