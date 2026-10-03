// Ground for the world shaders: grass (tussocks, grass blades, flowers) and trail dirt (ruts, grain, small cracks,
// pebbles). The fine detail is baked into seamless textures with tile TERRAIN_TILE (the grass and dirt textures), and
// the large patches into a mask over the whole ground (ground_mask). Coordinates are meters on the horizontal world
// plane (x, z). The textures are material parameters; ground.tres and mountain.tres set them.

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_flowers : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_pebbles : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_normal : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_mask_tint : filter_linear, repeat_disable;
uniform sampler2D ground_mask_road : filter_linear, repeat_disable;
// Road dirt: in the middle and at the edges; road half width, m.
uniform vec3 road_color : source_color = vec3(0.56, 0.46, 0.32);
uniform vec3 road_edge_color : source_color = vec3(0.42, 0.37, 0.25);
uniform float road_half_width = 0.95;

// Side of the grass and dirt tile, m, and side of the mask centered at the world origin, m.
const float TERRAIN_TILE = 3.84;
const float GROUND_MASK_SIZE = 96.0;
// Grass blades use one mip level finer than usual: the usual choice averages them into a smudge already at medium
// distance.
const float GRASS_MIP_BIAS = -1.0;

// Roads: segments (x1, z1, x2, z2) in world coordinates. The ground and the gentle grass faces at the foot of the
// mountain draw them (the mountain covers the ground there), so the road to the mountain turns into its trail without a
// break.
const vec4 ROADS[16] = {
	// Main road: from the south through the gap in the wall, past the spawn point, to the trail up the mountain. The
	// last segment approaches the trail start from the west: east of the trail start the mountain is solid rock up to 4
	// m (the interval between the start and the end of the trail spiral), and the road would go under it.
	vec4(-2.0, 37.0, -2.0, 20.0), vec4(-2.0, 20.0, -2.0, 9.0), vec4(-2.0, 9.0, 1.0, 2.0), vec4(1.0, 2.0, 9.0, -6.0),
	vec4(9.0, -6.0, 18.0, -9.0), vec4(18.0, -9.0, 19.4, -15.4), vec4(19.4, -15.4, 21.7, -20.1),
	// To the ruins.
	vec4(1.0, 2.0, -6.0, -6.0), vec4(-6.0, -6.0, -10.0, -10.0),
	// To the camp in the east.
	vec4(18.0, -9.0, 26.0, -6.0), vec4(26.0, -6.0, 32.0, -4.0),
	// To the farmstead in the southwest.
	vec4(-2.0, 28.0, -18.0, 30.0), vec4(-18.0, 30.0, -29.0, 25.0), vec4(-29.0, 25.0, -32.0, 21.5),
	// To the platform ramp.
	vec4(-2.0, 20.0, 8.0, 19.0), vec4(8.0, 19.0, 15.5, 18.0)
};

// Ground at a point: color, normal tilt (the horizontal part along world x and z) and occlusion of hollows.
struct Ground {
	vec3 color;
	vec2 tilt;
	float ao;
	// Fine noise 0…1 (6 patches per meter): the uneven trail edge and the grass tufts along it.
	float edge_noise;
};

// Large-scale noise at a point: R is patches of dark and dry grass, G is lighter/darker, B is the tint, A is meadows
// with flowers.
vec4 ground_tint_mask(vec2 p) {
	return texture(ground_mask_tint, p / GROUND_MASK_SIZE + 0.5);
}

// R is the unevenness of the trail edge, G is where the dirt is dry, B is the rut offset, A is its depth.
vec4 ground_road_mask(vec2 p) {
	return texture(ground_mask_road, p / GROUND_MASK_SIZE + 0.5);
}

// Tilt from a texture: 0…1 maps to −range…range.
vec2 unpack_tilt(vec2 packed, float range) {
	return (packed * 2.0 - 1.0) * range;
}

// Grass with color base (the caller sets the large patches): tussocks, grass blades in two layers and flowers in
// meadows.
// mask is ground_tint_mask(p).
Ground grass_at(vec2 p, vec3 base, vec4 mask) {
	// The tint wanders from yellow-green to blue-green.
	vec3 tint = base * (0.86 + 0.28 * mask.g);
	tint *= mix(vec3(1.06, 1.04, 0.88), vec3(0.94, 1.0, 1.08), mask.b);
	vec2 uv = p / TERRAIN_TILE;
	vec4 albedo = texture(grass_albedo, uv, GRASS_MIP_BIAS);
	vec4 normal = texture(grass_normal, uv, GRASS_MIP_BIAS);
	vec4 flowers = texture(grass_flowers, uv);
	Ground ground;
	ground.color = tint * albedo.rgb * 2.0;
	ground.tilt = unpack_tilt(normal.rg, 2.0);
	ground.ao = albedo.a;
	ground.edge_noise = flowers.a;
	// Flowers: there are more of them in meadows.
	float meadow = smoothstep(0.52, 0.68, mask.a);
	float bloom = step(1.0 - 0.45 * meadow - 0.015, normal.b);
	ground.color = mix(ground.color, flowers.rgb, normal.a * bloom);
	return ground;
}

// Trail dirt of color soil (edge_soil at the edges). across is the distance from the trail axis (m, not less than
// zero), outward is the direction from the axis to the point on the plane, half_width is the trail half width, road is
// ground_road_mask(p). Ruts, a trodden middle, grain, small cracks in dry places and pebbles (more of them at the trail
// edge).
Ground dirt_at(vec2 p, float across, vec2 outward, float half_width, vec3 soil, vec3 edge_soil, vec4 road) {
	vec2 uv = p / TERRAIN_TILE;
	vec4 detail = texture(dirt_detail, uv);
	vec4 pebbles = texture(dirt_pebbles, uv);
	vec4 normal = texture(dirt_normal, uv);
	float side = abs(across);
	Ground ground;
	vec3 color = mix(edge_soil, soil, smoothstep(0.0, half_width * 0.6, half_width - side)) * detail.r * 1.5;
	// The trodden middle is lighter; the ruts on either side of it are darker and recessed.
	color *= 1.0 + 0.08 * (1.0 - smoothstep(0.0, half_width * 0.3, side));
	float to_rut = side - (half_width * 0.48 + (road.b - 0.5) * 0.1);
	float rut = (1.0 - smoothstep(0.02, 0.2, abs(to_rut))) * (0.6 + 0.4 * road.a);
	color *= 1.0 - 0.1 * rut;
	ground.tilt = -outward * sign(to_rut) * rut * 0.18 + unpack_tilt(normal.rg, 1.0);
	// Small cracks only in dry places.
	float crack = detail.g * smoothstep(0.55, 0.7, road.g);
	color *= 1.0 - 0.22 * crack;
	ground.ao = 1.0 - 0.3 * crack - 0.15 * rut;
	// Pebbles: more of them at the trail edge; a shadow around them.
	float present = step(0.86 - 0.14 * smoothstep(half_width * 0.4, half_width, side), detail.b);
	float pebble = pebbles.a * present;
	ground.color = mix(color, pebbles.rgb, pebble);
	ground.tilt = ground.tilt * (1.0 - pebble) + unpack_tilt(normal.ba, 1.0) * present;
	ground.ao *= 1.0 - 0.35 * detail.a * present;
	ground.edge_noise = 0.5;
	return ground;
}

// The point of segment ab closest to p.
vec2 closest_on_segment(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	return a + ab * clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
}

// Grass grass with the ROADS roads on top: a ragged edge at two scales, grass tufts at the edge, dirt on the road
// (dirt_at). road is ground_road_mask(p).
Ground with_roads(vec2 p, Ground grass, vec4 road) {
	// The nearest road: distance to its axis and the direction away from it.
	float to_axis = 1e6;
	vec2 closest = p;
	for (int i = 0; i < ROADS.length(); i++) {
		vec2 point = closest_on_segment(p, ROADS[i].xy, ROADS[i].zw);
		float distance_to = length(p - point);
		if (distance_to < to_axis) {
			to_axis = distance_to;
			closest = point;
		}
	}
	vec2 outward = to_axis > 1e-4 ? (p - closest) / to_axis : vec2(1.0, 0.0);
	float edge = to_axis + (road.r - 0.5) * 0.6 + (grass.edge_noise - 0.5) * 0.12;
	float on_road = 1.0 - smoothstep(road_half_width - 0.08, road_half_width + 0.08, edge);
	float tufts = smoothstep(0.55, 0.75, grass.edge_noise)
			* smoothstep(road_half_width - 0.45, road_half_width - 0.05, edge);
	float grassy = max(1.0 - on_road, tufts * on_road);
	if (grassy >= 0.999) {
		return grass;
	}
	Ground dirt = dirt_at(p, to_axis, outward, road_half_width, road_color, road_edge_color, road);
	Ground result;
	result.color = mix(dirt.color, grass.color, grassy);
	result.tilt = mix(dirt.tilt, grass.tilt, grassy);
	result.ao = mix(dirt.ao, grass.ao, grassy);
	result.edge_noise = grass.edge_noise;
	return result;
}
