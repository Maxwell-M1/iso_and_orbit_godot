// A thatched roof from a prism (PrismMesh: the ridge along the mesh Z axis, slopes on the sides): thatch in courses of
// sheaves across the slope (the lower edge of each course is thicker and casts a shadow on the course below, and the
// edge is uneven); straws run down the slope; a tied roll along the ridge. Patches of old gray thatch and moss, darker
// toward the eaves. Courses follow the height in mesh axes. The straws and patches are baked into a seamless texture
// (the thatch texture).
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"

uniform sampler2D thatch_detail : filter_linear_mipmap_anisotropic, repeat_enable;

uniform vec3 straw_color : source_color = vec3(0.72, 0.58, 0.32);
uniform vec3 straw_dark_color : source_color = vec3(0.42, 0.32, 0.18);
uniform vec3 old_color : source_color = vec3(0.5, 0.47, 0.4);
uniform vec3 moss_color : source_color = vec3(0.3, 0.38, 0.18);
// Height of a course of sheaves (vertically), m.
uniform float course_height = 0.18;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

const float RELIEF_DEPTH = 0.03;
// Tile: m along the ridge and in height (as the texture was baked).
const vec2 TILE = vec2(2.0, 4.0);

varying vec3 local_position;
varying vec3 local_normal;
// Half the prism height: in a prism without subdivisions every vertex is on the ridge or at the base.
varying float half_height;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	half_height = abs(VERTEX.y);
}

// Position within a course of sheaves: 0 at the lower (thick) edge of the course, 1 at the upper one; the edge is
// uneven.
float in_course(vec2 p) {
	float y = p.y + 0.035 * (value_noise(vec2(p.x * 4.0, floor(p.y / course_height))) - 0.5);
	return fract(y / course_height);
}

// Roof height: within a course it grows toward the lower edge (the sheaves are thicker there), plus the straws.
float thatch_height(vec2 p) {
	return 1.0 - in_course(p) + 0.25 * texture(thatch_detail, p / TILE).g;
}

void fragment() {
	vec3 lp = local_position;
	vec3 n = normalize(local_normal);
	bool bottom = n.y < -0.7;
	bool gable = abs(n.z) > 0.7;
	// Coordinates: along the ridge (across it on the gable) and height.
	vec2 p = vec2(gable ? lp.x : lp.z, lp.y);
	float pixel = max(fwidth(p).x, fwidth(p).y);
	float detail = 1.0 - smoothstep(0.008, 0.03, pixel);

	float course = in_course(p);
	vec4 straw = texture(thatch_detail, p / TILE);
	float strands = straw.r;
	vec3 color = mix(straw_dark_color, straw_color, 0.55 + 0.45 * strands * detail);
	color *= 0.85 + 0.3 * straw.b;
	// Shadow under the lower edge of the course above; darker toward the eaves.
	color *= mix(1.0, 0.55, smoothstep(0.78, 1.0, course) * detail);
	color *= mix(0.8, 1.0, smoothstep(-half_height, 0.3 - half_height, lp.y));
	// Old, grayed thatch in patches, and moss.
	color = mix(color, old_color * (0.85 + 0.3 * strands), smoothstep(0.5, 0.72, straw.a) * 0.7);
	float moss = smoothstep(0.62, 0.75, texture(thatch_detail, p / TILE + 0.5).b) * moss_amount * 1.5;
	color = mix(color, moss_color * (0.8 + 0.4 * strands), clamp(moss, 0.0, 1.0));
	// Ridge: a roll of thatch along it, tied across every 0.4 m.
	bool ridge = !bottom && !gable && half_height - lp.y < 0.14;
	if (ridge) {
		// The straws of the roll lie along the ridge: the same texture, rotated by a quarter turn.
		float along = texture(thatch_detail, vec2(p.y / TILE.x, p.x * 6.0 / 28.0)).r;
		color = mix(straw_dark_color, straw_color, 0.35 + 0.45 * along) * 0.9;
		float tie = 1.0 - smoothstep(0.03, 0.06, abs(fract(p.x * 2.5) - 0.5));
		color = mix(color, vec3(0.22, 0.16, 0.09), tie * detail);
	}
	color = bottom ? straw_dark_color * 0.5 : color;

	vec3 world_normal = normalize((MODEL_MATRIX * vec4(n, 0.0)).xyz);
	vec3 u_world = normalize((MODEL_MATRIX * vec4(gable ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0), 0.0)).xyz);
	// Up along the surface: the world vertical projected onto the face; dy/ds is its height.
	vec3 up_world = vec3(0.0, 1.0, 0.0) - world_normal.y * world_normal;
	vec3 v_world = length(up_world) > 0.01 ? normalize(up_world) : vec3(0.0);
	float probe = 0.004;
	float height = thatch_height(p);
	float slope_u = (thatch_height(p + vec2(probe, 0.0)) - height) / probe;
	float slope_v = (thatch_height(p + vec2(0.0, probe)) - height) / probe * v_world.y;
	slope_v *= ridge ? 0.0 : 1.0;
	vec3 bumped = world_normal - RELIEF_DEPTH * detail * (slope_u * u_world + slope_v * v_world);

	ALBEDO = color;
	ROUGHNESS = roughness;
	AO = mix(1.0, mix(1.0, 0.6, smoothstep(0.7, 1.0, course) * (ridge ? 0.0 : 1.0)), detail);
	NORMAL = normalize((VIEW_MATRIX * vec4(bottom ? world_normal : normalize(bumped), 0.0)).xyz);
}
