// A barrel from a cylinder (CylinderMesh, mesh Y axis, centered at the origin): staves around the circumference with
// gaps, fibers along them, rusty iron hoops near the ends; the lid is planks with a rim. Relief (gaps, raised hoops)
// goes through the normal. Fibers and rust come from seamless textures (the wood_grain and noise textures).
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"

uniform sampler2D wood_grain : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_texture : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 wood_color : source_color = vec3(0.55, 0.37, 0.21);
uniform vec3 wood_dark_color : source_color = vec3(0.32, 0.2, 0.1);
uniform vec3 hoop_color : source_color = vec3(0.2, 0.19, 0.18);
uniform vec3 rust_color : source_color = vec3(0.42, 0.24, 0.11);
// Number of staves around the circumference.
uniform float staves = 16.0;
// Half height and lid radius of the barrel, m (as in the mesh).
uniform float half_height = 0.45;
uniform float lid_radius = 0.36;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;

const float TAU_VALUE = 6.2831853;
const float RELIEF_DEPTH = 0.008;
// Fiber tile: m along and across (as the texture was baked); noise patches per tile (as the texture was baked).
const vec2 GRAIN_TILE = vec2(5.0, 1.0);
const float NOISE_CYCLES = 8.0;

varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}

// Hoop at height y: 1 on the iron, falling off at its edge; the hoops sit 7 and 24 cm from each end.
float hoop_at(float y) {
	float from_end = half_height - abs(y);
	float to_hoop = min(abs(from_end - 0.07), abs(from_end - 0.24));
	return 1.0 - smoothstep(0.016, 0.02, to_hoop);
}

// Height of the side surface: gaps between staves are recessed, hoops stand out. along is the arc length around the
// circumference, m.
float side_height(float along, float y, float stave_width) {
	float x = fract(along / stave_width);
	float to_gap = min(x, 1.0 - x) * stave_width;
	return smoothstep(0.002, 0.008, to_gap) * 0.6 + hoop_at(y) * 0.4;
}

void fragment() {
	vec3 lp = local_position;
	vec3 n = normalize(local_normal);
	bool lid = abs(n.y) > 0.7;
	float pixel = length(fwidth(lp));
	float detail = 1.0 - smoothstep(0.004, 0.02, pixel);
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(n, 0.0)).xyz);

	vec3 color;
	float metal = 0.0;
	vec3 bump = vec3(0.0);
	if (lid) {
		// Lid: planks across, a rim along the edge.
		float board = floor(lp.x / 0.12);
		float to_gap = abs(fract(lp.x / 0.12) - 0.5) * 0.12;
		color = wood_color * (0.85 + 0.3 * hash(vec2(board, 2.0)));
		vec2 grain = vec2(lp.z * 4.0 / 2.6, lp.x * 60.0 / 140.0) / GRAIN_TILE + hash2(vec2(board, 3.0));
		color *= 0.85 + 0.3 * texture(wood_grain, grain).g;
		color = mix(color, wood_dark_color * 0.5, (1.0 - smoothstep(0.052, 0.058, to_gap)) * detail);
		float rim = smoothstep(lid_radius - 0.035, lid_radius - 0.03, length(lp.xz));
		color = mix(color, wood_dark_color, rim);
	} else {
		float radius = max(length(lp.xz), 0.01);
		float angle = atan(lp.z, lp.x);
		float stave_width = TAU_VALUE * radius / staves;
		float along = angle * radius;
		float stave = floor(angle / TAU_VALUE * staves);
		float x = fract(angle / TAU_VALUE * staves);
		float gap = 1.0 - smoothstep(0.002, 0.006, min(x, 1.0 - x) * stave_width);
		// Stave: its own tone and fibers along it.
		color = wood_color * (0.82 + 0.36 * hash(vec2(stave, 4.0)));
		vec2 grain = vec2(lp.y * 3.0 / 2.6, x * 40.0 / 140.0) / GRAIN_TILE + hash2(vec2(stave, 4.0));
		color = mix(color, wood_dark_color, 0.4 * texture(wood_grain, grain).g);
		color = mix(color, wood_dark_color * 0.4, gap * detail);
		// Hoops with rust.
		metal = hoop_at(lp.y);
		// Rust: noise around the circle (16 patches) and along the height; the angle jumps by a full turn where the
		// circle closes, hence the mip level correction.
		vec2 rust_uv = vec2(angle / TAU_VALUE * 2.0, lp.y * 20.0 / NOISE_CYCLES);
		vec2 rust_dx = dFdx(rust_uv);
		vec2 rust_dy = dFdy(rust_uv);
		rust_dx.x -= round(rust_dx.x * 0.5) * 2.0;
		rust_dy.x -= round(rust_dy.x * 0.5) * 2.0;
		float rust = textureGrad(noise_texture, rust_uv, rust_dx, rust_dy).r;
		vec3 iron = mix(hoop_color, rust_color, smoothstep(0.45, 0.75, rust));
		color = mix(color, iron, metal);
		// Relief from height differences along the arc and along the height.
		float probe = 0.003;
		float height = side_height(along, lp.y, stave_width);
		vec2 slope = vec2(side_height(along + probe, lp.y, stave_width) - height,
				side_height(along, lp.y + probe, stave_width) - height) / probe;
		vec3 around = normalize((MODEL_MATRIX * vec4(-lp.z, 0.0, lp.x, 0.0)).xyz);
		vec3 up = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
		bump = RELIEF_DEPTH * (slope.x * around + slope.y * up);
	}

	ALBEDO = color;
	METALLIC = metal * 0.55;
	ROUGHNESS = mix(roughness, 0.55, metal);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(world_normal - bump * detail), 0.0)).xyz);
}
