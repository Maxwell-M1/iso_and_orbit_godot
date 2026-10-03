// Foliage for the hedge, bush and crown shaders: surface lumps and two layers of leaves on a plane. The leaves are
// baked into seamless textures (the leaves_broad and leaves_needle textures) without color: the color is assembled here
// from the material parameters. The textures are material parameters. Requires noise.gdshaderinc.

uniform sampler2D leaves_detail : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D leaves_normal : filter_linear_mipmap_anisotropic, repeat_enable;

// Side of the leaf tile, in leaf lengths (as the texture was baked).
const float LEAVES_PERIOD = 32.0;

// Displacement of a vertex located at the world point world: a random vector that varies smoothly over the world,
// giving lumps of about size meters and smaller ones, up to amount meters. It fades out near the ground so the bottom
// does not lift off. It depends only on the position, so the copies of a vertex on a box edge get the same displacement
// and the faces do not split apart.
vec3 lumps(vec3 world, float size, float amount) {
	vec3 p = world / size;
	vec3 big = vec3(noise3(p), noise3(p + 19.1), noise3(p + 37.7)) - 0.5;
	vec3 q = p * 1.9375;
	vec3 small = vec3(noise3(q + 5.3), noise3(q + 23.9), noise3(q + 51.2)) - 0.5;
	return (big + 0.5 * small) * 1.4 * amount * smoothstep(0.0, 0.3, world.y);
}

// Displaces vertex by lumps (lumps) and recomputes normal from two neighboring surface points.
void lumpy_vertex(inout vec3 vertex, inout vec3 normal, mat4 model, float size, float amount) {
	vec3 side = abs(normal.y) > 0.5 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 first = normalize(cross(normal, side));
	vec3 second = cross(normal, first);
	float probe = 0.05;
	vec3 here = vertex + lumps((model * vec4(vertex, 1.0)).xyz, size, amount);
	vec3 a = vertex + first * probe;
	vec3 b = vertex + second * probe;
	a += lumps((model * vec4(a, 1.0)).xyz, size, amount);
	b += lumps((model * vec4(b, 1.0)).xyz, size, amount);
	vec3 bent = normalize(cross(a - here, b - here));
	normal = dot(bent, normal) < 0.0 ? -bent : bent;
	vertex = here;
}

struct Leaves {
	// Color: leaves and the gaps between them.
	vec3 color;
	// 1 is a leaf, 0 is a gap.
	float covered;
	// 1 is the near layer, less is the far one (deeper in the foliage).
	float light;
	// Tilt of the leaf normal along the plane axes.
	vec2 tilt;
	// Clumps: 0 is a hollow, 1 is a bulge (also used for the average color in the distance).
	float clump;
};

// Leaves on a plane at point q (in leaf lengths): two layers; the near one is removed in places along large clumps, and
// there the far one or a gap shows. The leaf tint lies between dark and light; a share of the leaves (share) is mixed
// with accent (yellowed, autumn). depth is the color of the gaps.
Leaves leaves_at(vec2 q, vec3 dark, vec3 light, vec3 accent, float share, vec3 depth) {
	vec2 uv = q / LEAVES_PERIOD;
	vec4 detail = texture(leaves_detail, uv);
	vec4 normal = texture(leaves_normal, uv);
	Leaves result;
	result.covered = detail.a;
	result.light = normal.a;
	result.clump = normal.b;
	vec3 tint = mix(dark, light, detail.r);
	tint = mix(tint, accent, step(1.0 - share, detail.g) * 0.6);
	float shade = detail.b * mix(0.7, 1.15, result.clump);
	result.color = mix(depth, tint * shade, result.covered);
	result.tilt = (normal.rg * 2.0 - 1.0) * result.covered;
	return result;
}
