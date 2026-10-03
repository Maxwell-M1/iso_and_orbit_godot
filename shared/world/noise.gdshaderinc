// Noise for the world shaders: hashes, smoothed noise and its octaves on a plane, noise in space. Values are 0…1. The
// world shaders take expensive fine patterns from baked textures; this file holds what is cheap to compute on the spot:
// random numbers for stones and planks, foliage lumps in vertices, large patches for baking the ground mask.

// Hashes avoid sin: for large arguments (world coordinates × noise frequency) sin lacks precision on the GPU, and the
// noise breaks up into squares.
float hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(41.3, 17.9)));
}

float hash3(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float bottom = mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x);
	float top = mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x);
	return mix(bottom, top, u.y);
}

// Four octaves: large patches with fine detail.
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * value_noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float bottom = mix(mix(hash3(i), hash3(i + vec3(1.0, 0.0, 0.0)), u.x),
			mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), u.x), u.y);
	float top = mix(mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), u.x),
			mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), u.x), u.y);
	return mix(bottom, top, u.z);
}
