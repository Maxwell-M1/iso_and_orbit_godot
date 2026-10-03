// Boulder: grainy stone with large patches, light veins and dark cracks, lichen on the upper faces, moss near the
// ground; relief goes through the normal. The pattern is baked into seamless textures (the boulder texture) and lies on
// three planes along the world axes, without UV: it does not stretch over the sphere, and neighboring boulders look
// different.
shader_type spatial;

#include "res://shared/world/triplanar.gdshaderinc"

uniform sampler2D rock_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 rock_color : source_color = vec3(0.52, 0.5, 0.47);
uniform vec3 rock_dark_color : source_color = vec3(0.32, 0.31, 0.29);
uniform vec3 vein_color : source_color = vec3(0.72, 0.7, 0.66);
uniform vec3 lichen_color : source_color = vec3(0.64, 0.62, 0.34);
uniform vec3 moss_color : source_color = vec3(0.26, 0.35, 0.17);
// Amount of lichen on top and moss near the ground: 0 is none at all.
uniform float lichen_amount : hint_range(0.0, 1.0) = 0.5;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.4;
uniform float roughness : hint_range(0.0, 1.0) = 0.92;

// Relief depth, m.
const float RELIEF_DEPTH = 0.02;
// Tile side, m (as the texture was baked).
const float TILE = 4.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 p = world_position;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 detail;
	vec4 normal;
	vec3 gradient;
	triplanar_pair(rock_detail, rock_normal, p, triplanar_weights(world_normal), TILE, 24.0, detail, normal, gradient);

	float grain = detail.g;
	vec3 color = mix(rock_dark_color, rock_color, 0.25 + 0.75 * detail.r);
	color *= 0.86 + 0.28 * grain;
	// Specks: dark and light grains.
	color *= 1.0 + 0.18 * (detail.b * 2.0 - 1.0);
	color = mix(color, vein_color, detail.a * 0.4);
	float crack = normal.b;
	color *= 1.0 - 0.4 * crack;
	// Lichen on upward-facing surfaces, moss near the ground (in the dark patches of the stone).
	float up = smoothstep(0.25, 0.8, world_normal.y);
	// The threshold is high: the patches of the three planes blend and come out larger.
	float lichen = smoothstep(0.58, 0.64, normal.a) * up * lichen_amount * 1.4;
	color = mix(color, lichen_color * (0.8 + 0.4 * grain), clamp(lichen, 0.0, 1.0));
	float moss = (1.0 - smoothstep(0.0, 0.45, p.y)) * smoothstep(0.4, 0.62, 1.0 - detail.r) * moss_amount * 2.0;
	color = mix(color, moss_color * (0.75 + 0.5 * grain), clamp(moss, 0.0, 1.0));

	// Relief along the surface.
	gradient -= dot(gradient, world_normal) * world_normal;

	ALBEDO = color;
	ROUGHNESS = roughness;
	AO = 1.0 - 0.45 * crack;
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(world_normal - RELIEF_DEPTH * gradient), 0.0)).xyz);
}
