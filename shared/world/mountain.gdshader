// Mountain: face colors from the generator (vertex colors: grass, trail dirt, rock) with detail on top: grass and trail
// dirt are the same as below (terrain.gdshaderinc; the grass at the foot also gets the world roads), rock in layers
// with grain, cracks and lichen; relief goes through the normal. The kind of a face is determined by its color: green
// is grass, reddish-brown is dirt, gray-brown is rock. The fine rock detail is baked into seamless textures (the
// mountain_rock texture) and lies on three planes along the world axes; the shader computes the height layers itself.
shader_type spatial;

#include "res://shared/world/terrain.gdshaderinc"
#include "res://shared/world/triplanar.gdshaderinc"

uniform sampler2D rock_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 lichen_color : source_color = vec3(0.56, 0.56, 0.4);
// Grass and trail dirt use a flat color, with no tone difference between neighboring faces: otherwise triangles show
// through under the grass blades. Only rock keeps the difference between faces.
uniform vec3 grass_color : source_color = vec3(0.36, 0.5, 0.27);
uniform vec3 path_color : source_color = vec3(0.52, 0.41, 0.28);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;

const float RELIEF_DEPTH = 0.06;
// Side of the rock tile, m (as the texture was baked).
const float ROCK_TILE = 6.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// The generator sets vertex colors as regular (sRGB) colors, while the shader works in linear ones.
vec3 to_linear(vec3 color) {
	return mix(color / 12.92, pow((color + 0.055) / 1.055, vec3(2.4)), step(0.04045, color));
}

void fragment() {
	vec3 p = world_position;
	vec3 face = COLOR.rgb;
	vec3 base = to_linear(face);
	float grass = smoothstep(0.04, 0.08, face.g - face.r);
	float dirt = smoothstep(0.07, 0.1, face.r - face.g) * (1.0 - grass);
	float rock = 1.0 - grass - dirt;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	vec3 color = vec3(0.0);
	vec2 ground_tilt = vec2(0.0);
	float ao = 1.0;
	// Grass and trail dirt as below; the mountain trail has no ruts (with half_width 10 the ruts lie outside the
	// trail).
	if (grass > 0.001) {
		vec4 tint_mask = ground_tint_mask(p.xz);
		Ground ground = grass_at(p.xz, grass_color * (0.85 + 0.25 * tint_mask.r), tint_mask);
		// Gentle grass faces at the foot cover the world ground, so the road to the trail is drawn on them too.
		ground = with_roads(p.xz, ground, ground_road_mask(p.xz));
		color += ground.color * grass;
		ground_tilt += ground.tilt * grass;
		ao *= mix(1.0, ground.ao, grass);
	}
	if (dirt > 0.001) {
		Ground ground = dirt_at(p.xz, 0.0, vec2(0.0), 10.0, path_color, path_color * 0.85, ground_road_mask(p.xz));
		color += ground.color * dirt;
		ground_tilt += ground.tilt * dirt;
		ao *= mix(1.0, ground.ao, dirt);
	}
	vec3 gradient = vec3(0.0);
	if (rock > 0.001) {
		// Rock: lighter and darker layers, grain, cracks, lichen on upward-facing surfaces.
		vec4 detail;
		vec4 normal;
		triplanar_pair(rock_detail, rock_normal, p, triplanar_weights(world_normal), ROCK_TILE, 24.0, detail, normal,
				gradient);
		float strata = sin(p.y * 5.0 + normal.b * 4.0);
		vec3 rock_color = base * (0.85 + 0.12 * strata + 0.25 * detail.r);
		rock_color *= 0.88 + 0.24 * detail.g;
		rock_color *= 1.0 - 0.45 * detail.b;
		float lichen = detail.a * smoothstep(0.2, 0.7, world_normal.y);
		rock_color = mix(rock_color, lichen_color * (0.8 + 0.3 * normal.a), lichen * 0.55);
		color += rock_color * rock;
		ao *= 1.0 - 0.4 * detail.b * rock;
		// Rock relief along the face: height layers and the baked lumps, grain and cracks.
		gradient.y += 0.35 * cos(p.y * 5.0 + normal.b * 4.0) * 5.0;
		gradient = (gradient - dot(gradient, world_normal) * world_normal) * rock;
	}

	ALBEDO = color;
	ROUGHNESS = roughness;
	AO = ao;
	vec3 bumped = normalize(world_normal - RELIEF_DEPTH * gradient + vec3(ground_tilt.x, 0.0, ground_tilt.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(bumped, 0.0)).xyz);
}
