// A ruined column from a cylinder (CylinderMesh standing on the ground): flutes around the circumference (fluting) and
// joints between drums through the normal; a smooth base near the ground; weathered stone with streaks, cracks, lichen
// patches and moss near the ground; the broken-off top is rough. Drums are counted from the ground (by world height),
// so the top drum of a broken column is incomplete. Without flutes and with blocks around the circumference
// (blocks_around) it becomes round masonry, like a well's. The weathered stone is baked into seamless textures (the
// column texture) and lies on three planes along the world axes: each column gets its own pattern. The shader computes
// the flutes, joints and drums itself.
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"
#include "res://shared/world/triplanar.gdshaderinc"

uniform sampler2D stone_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_normal : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 stone_color : source_color = vec3(0.74, 0.71, 0.64);
uniform vec3 stone_dark_color : source_color = vec3(0.52, 0.5, 0.45);
uniform vec3 lichen_color : source_color = vec3(0.64, 0.62, 0.34);
uniform vec3 moss_color : source_color = vec3(0.26, 0.35, 0.17);
// Number of flutes around the circumference and their depth, m.
uniform float flutes = 16.0;
uniform float flute_depth = 0.018;
// Height of a drum (a masonry course) and of the smooth base, m.
uniform float drum_height = 0.8;
uniform float base_height = 0.3;
// Number of blocks around the circumference in each course (round masonry); 0 makes the drum solid.
uniform float blocks_around = 0.0;
// Amount of lichen and moss: 0 is none at all.
uniform float lichen_amount : hint_range(0.0, 1.0) = 0.5;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.4;
uniform float roughness : hint_range(0.0, 1.0) = 0.9;

const float TAU_VALUE = 6.2831853;
// Depth of the joint between drums and of the stone roughness, m.
const float JOINT_DEPTH = 0.006;
const float GRAIN_DEPTH = 0.006;
// Tile side, m (as the texture was baked).
const float TILE = 4.0;

varying vec3 local_position;
varying vec3 local_normal;
varying vec3 world_position;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Distance to the joint between drums (or above the base) at height y, m.
float to_joint(float y) {
	float above = y - base_height;
	if (above < 0.0) {
		return -above;
	}
	float drum = floor(above / drum_height);
	return min(above - drum * drum_height, (drum + 1.0) * drum_height - above);
}

// Distance to the nearest joint at height y, angle angle and radius radius, m: between courses and, in round masonry,
// between the blocks of a course (each course has its own offset).
float joint_distance(float y, float angle, float radius) {
	float nearest = to_joint(y);
	if (blocks_around > 0.0) {
		float drum = floor(max(y - base_height, 0.0) / drum_height);
		float x = fract(angle / TAU_VALUE * blocks_around + hash(vec2(drum, 5.3)));
		nearest = min(nearest, min(x, 1.0 - x) * TAU_VALUE * radius / blocks_around);
	}
	return nearest;
}

void fragment() {
	vec3 p = world_position;
	float y = p.y;
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(local_normal, 0.0)).xyz);
	bool cap = abs(local_normal.y) > 0.7;
	// From afar the joints and flutes are thinner than a pixel: the relief fades out, leaving the stone tone.
	float pixel = length(fwidth(p));
	float detail = 1.0 - smoothstep(0.03, 0.09, pixel);

	vec3 bump = vec3(0.0);
	float groove = 0.0;
	float joint = 0.0;
	float drum = floor(max(y - base_height, 0.0) / drum_height) + (y < base_height ? -1.0 : 0.0);
	if (!cap) {
		float radius = max(length(local_position.xz), 0.01);
		vec3 around = normalize((MODEL_MATRIX * vec4(-local_position.z, 0.0, local_position.x, 0.0)).xyz);
		// Flute: a parabola across its width, with sharp edges between flutes. The slope runs along the arc of the
		// circle.
		float phase = atan(local_position.z, local_position.x) * flutes / TAU_VALUE;
		float x = fract(phase) - 0.5;
		float fluted = smoothstep(base_height, base_height + 0.06, y);
		groove = (1.0 - 4.0 * x * x) * fluted;
		float flute_slope = 8.0 * x * flutes / (TAU_VALUE * radius) * flute_depth * fluted;
		// Joint: a thin groove with a bevel; the slope comes from differences along the height and along the arc.
		float probe = 0.004;
		float angle = atan(local_position.z, local_position.x);
		float joint_here = smoothstep(0.003, 0.02, joint_distance(y, angle, radius));
		float joint_up = (smoothstep(0.003, 0.02, joint_distance(y + probe, angle, radius)) - joint_here) / probe;
		float joint_around = (smoothstep(0.003, 0.02, joint_distance(y, angle + probe / radius, radius)) - joint_here)
				/ probe;
		joint = 1.0 - joint_here;
		bump = (flute_slope + joint_around * JOINT_DEPTH) * around + joint_up * JOINT_DEPTH * vec3(0.0, 1.0, 0.0);
	}
	// Roughness: the baked slope, along the surface.
	vec4 detail_tex;
	vec4 normal_tex;
	vec3 gradient;
	triplanar_pair(stone_detail, stone_normal, p, triplanar_weights(world_normal), TILE, 16.0, detail_tex, normal_tex,
			gradient);
	float here = detail_tex.g;
	gradient -= dot(gradient, world_normal) * world_normal;
	bump += gradient * GRAIN_DEPTH * (cap ? 2.5 : 1.0);

	// Stone: large patches, each drum with its own tone, a darker base, streaks running down, cracks.
	float column_seed = hash(floor(NODE_POSITION_WORLD.xz * 3.0));
	vec3 color = mix(stone_dark_color, stone_color, 0.35 + 0.65 * detail_tex.r);
	color *= 1.0 + (hash(vec2(drum, column_seed * 91.0)) - 0.5) * 0.12;
	color *= y < base_height && !cap ? 0.88 : 1.0;
	color *= 0.9 + 0.2 * here;
	// Streaks: by the angle around the axis and the height.
	float around_axis = atan(p.z - NODE_POSITION_WORLD.z, p.x - NODE_POSITION_WORLD.x) / TAU_VALUE + column_seed;
	// The angle jumps by a full turn where the circle closes: without a correction the mip level there is the smallest
	// one, and a seam shows.
	vec2 streak_uv = vec2(around_axis, y / TILE);
	vec2 streak_dx = dFdx(streak_uv);
	vec2 streak_dy = dFdy(streak_uv);
	streak_dx.x -= round(streak_dx.x);
	streak_dy.x -= round(streak_dy.x);
	float streaks = textureGrad(stone_normal, streak_uv, streak_dx, streak_dy).a;
	color *= 1.0 - 0.16 * smoothstep(0.45, 0.75, streaks);
	// Cracks: thin, stretched along the column, and only in places.
	float crack = detail_tex.b * detail;
	color *= 1.0 - 0.45 * crack;
	color *= 1.0 - 0.25 * groove * detail;
	color = mix(color, color * 0.65, joint * detail);
	// Lichen in patches, more of it on top; moss near the ground.
	float lichen = detail_tex.a * lichen_amount * (cap ? 1.4 : 0.8);
	color = mix(color, lichen_color * (0.8 + 0.4 * here), clamp(lichen, 0.0, 1.0));
	float moss = (1.0 - smoothstep(0.0, 0.6, y)) * normal_tex.b * moss_amount * 2.0;
	color = mix(color, moss_color * (0.75 + 0.5 * here), clamp(moss, 0.0, 1.0));

	ALBEDO = color;
	ROUGHNESS = roughness;
	// Weaker specular than the default: otherwise the flutes catch the sky and the stone in shadow looks like metal.
	SPECULAR = 0.3;
	AO = mix(1.0, (1.0 - 0.35 * groove) * (1.0 - 0.4 * joint), detail);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(world_normal - bump * detail), 0.0)).xyz);
}
