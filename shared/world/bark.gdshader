// Bark of trunks (a cylinder or cone along the mesh Y axis) and logs: lengthwise furrows between bark plates (noise
// stretched along the axis) with relief through the normal; moss near the ground and on the north side, lichen; growth
// rings on the end faces. A smooth pole has no furrows (furrows = 0), only the fibers remain. Campfire logs are charred
// toward the middle (charred) and smolder in the furrows. The pattern is baked into seamless textures (the bark
// texture) and lies on two planes along the trunk in mesh axes, offset by the node position: logs can lie at any angle,
// and neighboring trees look different.
shader_type spatial;

uniform sampler2D bark_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D bark_normal : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 bark_color : source_color = vec3(0.37, 0.28, 0.2);
uniform vec3 bark_dark_color : source_color = vec3(0.16, 0.11, 0.07);
// Wood on the end faces.
uniform vec3 wood_color : source_color = vec3(0.64, 0.5, 0.33);
uniform vec3 moss_color : source_color = vec3(0.27, 0.36, 0.16);
// Furrow depth: 0 is smooth wood, 1 is bark.
uniform float furrows : hint_range(0.0, 1.0) = 1.0;
// Furrows per meter across.
uniform float furrow_scale = 9.0;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.4;
// Charring toward the middle of the log (campfire): 0 is none.
uniform float charred : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.92;

// Relief depth at furrows = 1, m.
const float RELIEF_DEPTH = 0.012;
// Bark tile, m, and furrows per meter in it (as the texture was baked: 18 furrows per tile).
const float TILE = 2.0;
const float BAKED_FURROWS = 9.0;

varying vec3 local_position;
varying vec3 local_normal;
varying vec3 world_position;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 lp = local_position + NODE_POSITION_WORLD * 1.37;
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(local_normal, 0.0)).xyz);
	bool cap = abs(normalize(local_normal).y) > 0.7;
	float pixel = length(fwidth(world_position));
	float detail = 1.0 - smoothstep(0.02, 0.07, pixel);

	// Bark lies on two planes along the trunk axis (mesh Y), blended by the mesh normal.
	vec2 weights = pow(abs(normalize(local_normal).xz), vec2(4.0));
	weights /= weights.x + weights.y + 1e-5;
	float scale = furrow_scale / BAKED_FURROWS / TILE;
	vec2 uv_x = vec2(lp.z, lp.y) * scale + 0.31;
	vec2 uv_z = vec2(lp.x, lp.y) * scale;
	vec4 detail_tex = texture(bark_detail, uv_x) * weights.x + texture(bark_detail, uv_z) * weights.y;
	vec4 normal_x = texture(bark_normal, uv_x);
	vec4 normal_z = texture(bark_normal, uv_z);
	vec4 normal_tex = normal_x * weights.x + normal_z * weights.y;

	vec3 color;
	vec3 bump = vec3(0.0);
	float furrow = 0.0;
	if (cap) {
		// End face: uneven growth rings around the axis.
		float radius = length(local_position.xz);
		vec2 cap_uv = local_position.xz / TILE;
		float rings = fract(radius * 30.0 + texture(bark_detail, cap_uv * 4.0).b * 1.5);
		color = mix(wood_color, wood_color * 0.62, (1.0 - smoothstep(0.0, 0.25, min(rings, 1.0 - rings))) * detail);
		color *= 0.9 + 0.2 * texture(bark_detail, cap_uv * vec2(0.5, 5.0)).g;
	} else {
		furrow = 1.0 - mix(1.0, detail_tex.r, furrows);
		// Fibers along the axis and tone patches.
		float fibers = detail_tex.g;
		color = mix(bark_color, bark_dark_color, clamp(furrow * 0.85 + 0.25 * fibers, 0.0, 1.0));
		color *= 0.85 + 0.3 * detail_tex.b;
		// Plate relief: the baked slope in mesh axes, then into the world along the surface.
		float range = 60.0 * furrow_scale / BAKED_FURROWS;
		vec2 slope_x = (normal_x.rg * 2.0 - 1.0) * range;
		vec2 slope_z = (normal_z.rg * 2.0 - 1.0) * range;
		vec3 gradient = vec3(slope_z.x * weights.y, slope_x.y * weights.x + slope_z.y * weights.y,
				slope_x.x * weights.x);
		gradient = (MODEL_MATRIX * vec4(gradient * furrows, 0.0)).xyz;
		bump = (gradient - dot(gradient, world_normal) * world_normal) * RELIEF_DEPTH * max(furrows, 0.3);
	}
	// Moss: in patches near the ground and on the north side (−Z); lichen in small light spots.
	float north = smoothstep(-0.2, 0.8, -world_normal.z);
	float low = 1.0 - smoothstep(0.0, 0.9, world_position.y);
	float patches = detail_tex.a;
	float moss = clamp((low + 0.5 * north) * patches * moss_amount * 1.6, 0.0, 1.0) * (cap ? 0.0 : 1.0);
	color = mix(color, moss_color * (0.8 + 0.4 * normal_tex.a), moss);
	float lichen = normal_tex.b * moss_amount * (cap ? 0.0 : 0.6);
	color = mix(color, vec3(0.6, 0.62, 0.48), lichen);

	// Charred toward the middle of the log; the furrows smolder.
	float char_mask = charred * (1.0 - smoothstep(0.08, 0.4, abs(local_position.y)));
	color = mix(color, vec3(0.05, 0.04, 0.035), char_mask * 0.9);
	float flicker = texture(bark_normal, uv_z * 1.5 + vec2(TIME * 0.05, TIME * 0.03)).a;
	float ember = char_mask * smoothstep(0.35, 0.8, furrow) * (0.6 + 0.4 * flicker);

	ALBEDO = color;
	ROUGHNESS = roughness;
	EMISSION = vec3(1.0, 0.32, 0.05) * ember * 2.0;
	AO = mix(1.0, 1.0 - 0.5 * furrow, detail);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(world_normal - bump * detail), 0.0)).xyz);
}
