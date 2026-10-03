// Still water (a well): dark and smooth, with a slow ripple: the normal comes from two layers of noise moving in
// different directions. The noise and its slope are baked into a seamless texture (the noise texture).
shader_type spatial;

uniform sampler2D noise_texture : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 water_color : source_color = vec3(0.05, 0.1, 0.12);
// Ripple strength and its speed.
uniform float ripple : hint_range(0.0, 1.0) = 0.35;
uniform float speed = 0.25;

// Noise patches per tile and the slope limit in the texture (as the texture was baked).
const float NOISE_CYCLES = 8.0;
const float NOISE_SLOPE_RANGE = 32.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Noise slope at point uv (in tiles), per unit of uv.
vec2 noise_slope(vec2 uv) {
	return (texture(noise_texture, uv).ba * 2.0 - 1.0) * NOISE_SLOPE_RANGE;
}

void fragment() {
	vec2 p = world_position.xz;
	// Two ripple layers move in different directions; the slope per meter is the slope per tile divided by the tile
	// size.
	vec2 slope = noise_slope((p * 3.0 + vec2(TIME * speed, 0.0)) / NOISE_CYCLES) * 3.0 / NOISE_CYCLES
			+ noise_slope((p * 4.3 - vec2(0.0, TIME * speed * 0.8)) / NOISE_CYCLES) * 4.3 / NOISE_CYCLES;
	vec3 world_normal = normalize(vec3(-slope.x * ripple * 0.05, 1.0, -slope.y * ripple * 0.05));
	ALBEDO = water_color;
	ROUGHNESS = 0.05;
	SPECULAR = 0.6;
	NORMAL = normalize((VIEW_MATRIX * vec4(world_normal, 0.0)).xyz);
}
