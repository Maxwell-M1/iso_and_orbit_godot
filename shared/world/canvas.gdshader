// Cloth: tent canvas, an awning, a banner. A weave of threads in two directions, panels with seams across them (every
// panel_width), folds and sag through the normal, stitched patches, dirtier toward the ground. A banner (banner) is a
// box without face subdivisions: a border along the edges and a round emblem in the middle, sized from abs(VERTEX).
// Coordinates are in mesh axes: along the X or Z axis (by the face normal) and height. The weave and smooth patches
// come from seamless textures (the cloth_weave and noise textures).
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"

uniform sampler2D cloth_weave : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_texture : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 cloth_color : source_color = vec3(0.8, 0.72, 0.56);
uniform vec3 cloth_dark_color : source_color = vec3(0.55, 0.47, 0.35);
uniform vec3 patch_color : source_color = vec3(0.66, 0.56, 0.42);
// Panel width between seams, m; 0 means no seams.
uniform float panel_width = 0.8;
// Fold depth; 0 is smooth.
uniform float folds : hint_range(0.0, 2.0) = 1.0;
// Share of 1.2 m cells with a patch.
uniform float patch_share : hint_range(0.0, 1.0) = 0.25;
// Banner: border and emblem.
uniform bool banner = false;
uniform vec3 trim_color : source_color = vec3(0.85, 0.68, 0.3);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;

// Side of the weave tile, m, and noise patches per tile (as the textures were baked).
const float WEAVE_TILE = 0.5;
const float NOISE_CYCLES = 8.0;

varying vec3 local_position;
varying vec3 local_normal;
// The half sides of the box, flat: every pixel of a face gets the exact value; interpolated, it would differ in the last
// digits from pixel to pixel.
varying flat vec3 half_extent;
varying vec3 world_position;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	half_extent = abs(VERTEX);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(local_normal);
	// u runs along the X or Z axis (whichever lies in the face plane), v is the height.
	bool along_x = abs(n.z) > abs(n.x);
	vec2 p = vec2(along_x ? local_position.x : local_position.z, local_position.y);
	float pixel = max(fwidth(p).x, fwidth(p).y);
	float detail = 1.0 - smoothstep(0.004, 0.02, pixel);

	// Weave: threads across and along.
	float weave = texture(cloth_weave, p / WEAVE_TILE).r;
	vec3 color = mix(cloth_dark_color, cloth_color, 0.75 + 0.25 * mix(0.5, weave, detail));
	color *= 0.84 + 0.28 * texture(noise_texture, (p * 1.5 + 3.0) / NOISE_CYCLES).r;
	// Rain stains: streaks running from top to bottom.
	float rain = texture(noise_texture, (vec2(p.x * 3.0, p.y * 0.4) + 11.0) / NOISE_CYCLES).g;
	color *= 1.0 - 0.12 * smoothstep(0.5, 0.75, rain);
	// Panel seams: a double stitch line.
	float seam = 0.0;
	if (panel_width > 0.0) {
		float to_seam = abs(fract(p.x / panel_width + 0.5) - 0.5) * panel_width;
		seam = 1.0 - smoothstep(0.004, 0.012, abs(to_seam - 0.012));
		color *= 1.0 - 0.25 * seam * detail;
		color *= 1.0 - 0.12 * (1.0 - smoothstep(0.0, 0.02, to_seam));
	}
	// Patches: a rectangle in some of the 1.2 m cells, with stitching along its edge.
	vec2 cell = floor(p / 1.2);
	vec2 in_cell = p - cell * 1.2;
	vec2 patch_min = vec2(0.2, 0.2) + hash2(cell + 3.1) * 0.4;
	vec2 patch_max = patch_min + vec2(0.18, 0.15) + hash2(cell + 7.9) * 0.2;
	vec2 to_patch = min(in_cell - patch_min, patch_max - in_cell);
	float in_patch = step(0.0, min(to_patch.x, to_patch.y)) * step(1.0 - patch_share, hash(cell + 5.5))
			* (banner ? 0.0 : 1.0);
	color = mix(color, patch_color * (0.9 + 0.2 * weave), in_patch);
	float stitch = in_patch * (1.0 - smoothstep(0.008, 0.014, min(to_patch.x, to_patch.y)))
			* step(0.5, fract((in_cell.x + in_cell.y) * 30.0));
	color *= 1.0 - 0.35 * stitch * detail;

	if (banner) {
		vec2 extent = vec2(along_x ? half_extent.x : half_extent.z, half_extent.y);
		vec2 to_edge = extent - abs(p);
		float trim = 1.0 - smoothstep(0.05, 0.058, min(to_edge.x, to_edge.y));
		float ring = abs(length(p) - extent.y * 0.42);
		float emblem = max(1.0 - smoothstep(0.022, 0.03, ring), 1.0 - smoothstep(0.06, 0.068, length(p)));
		color = mix(color, trim_color * (0.85 + 0.25 * weave), max(trim, emblem));
	}
	// Dirt toward the ground.
	color *= mix(0.68, 1.0, smoothstep(0.0, 0.45, world_position.y));

	// Folds: waves across the panels, deeper toward the bottom, bent by noise.
	float sag = folds * (0.5 + 0.5 * smoothstep(0.6, -0.6, p.y));
	float wave = cos(p.x * 6.2832 / 0.45 + texture(noise_texture, p * 0.8 / NOISE_CYCLES + 0.5).r * 4.0);
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(n, 0.0)).xyz);
	vec3 u_world = normalize((MODEL_MATRIX * vec4(along_x ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0), 0.0)).xyz);
	vec3 bumped = world_normal + u_world * wave * 0.12 * sag;

	ALBEDO = color;
	ROUGHNESS = roughness;
	AO = 1.0 - 0.15 * sag * (0.5 - 0.5 * wave);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(bumped), 0.0)).xyz);
}
