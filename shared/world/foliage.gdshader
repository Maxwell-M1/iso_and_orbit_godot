// A tree crown or bush from a sphere or cone: a lumpy surface (vertices are displaced by noise from their world
// position), leaves in two layers (leaves.gdshaderinc, baked textures) on three planes along the mesh axes, blended by
// the normal, with no UV and no seam; clumps, a lighter top and a darker bottom, the depth of the crown in the gaps.
// Needles are the same leaves, only narrow (leaves_needle textures).
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"
#include "res://shared/world/leaves.gdshaderinc"

uniform vec3 leaf_color : source_color = vec3(0.2, 0.4, 0.16);
uniform vec3 leaf_light_color : source_color = vec3(0.38, 0.58, 0.22);
// Accent on a share of the leaves: yellowed ones, red in an autumn crown.
uniform vec3 accent_color : source_color = vec3(0.5, 0.52, 0.2);
uniform float accent_share : hint_range(0.0, 1.0) = 0.06;
// Color of the gaps: the depth of the crown.
uniform vec3 depth_color : source_color = vec3(0.04, 0.09, 0.03);
// Leaf length, m (the textures set the width: broad leaves or needles).
uniform float leaf_size = 0.13;
// Lumps: their size and the largest vertex displacement, m.
uniform float lump_size = 0.7;
uniform float lumpiness = 0.14;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;

varying vec3 rest_position;
varying vec3 local_normal;
varying vec3 world_position;

void vertex() {
	rest_position = VERTEX;
	local_normal = NORMAL;
	vec3 vertex = VERTEX;
	vec3 normal = NORMAL;
	lumpy_vertex(vertex, normal, MODEL_MATRIX, lump_size, lumpiness);
	VERTEX = vertex;
	NORMAL = normal;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	// Offset by the node position: neighboring identical trees get different leaves.
	vec3 lp = rest_position * scale + NODE_POSITION_WORLD * 1.37;
	// Weights of the three planes come from the mesh normal, sharply: only narrow bands blend.
	vec3 weights = pow(abs(normalize(local_normal)), vec3(4.0));
	weights /= weights.x + weights.y + weights.z;

	vec3 color = vec3(0.0);
	float covered = 0.0;
	float light = 0.0;
	float clump = 0.0;
	vec3 tilt = vec3(0.0);
	// The plane perpendicular to axis i: its coordinates are the other two mesh axes.
	for (int i = 0; i < 3; i++) {
		float weight = weights[i];
		if (weight < 0.02) {
			continue;
		}
		vec3 u = i == 0 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		vec3 v = i == 2 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
		Leaves leaves = leaves_at((vec2(dot(lp, u), dot(lp, v)) + float(i) * 17.3) / leaf_size, leaf_color,
				leaf_light_color, accent_color, accent_share, depth_color);
		color += leaves.color * weight;
		covered += leaves.covered * weight;
		light += leaves.light * weight;
		clump += leaves.clump * weight;
		tilt += (leaves.tilt.x * u + leaves.tilt.y * v) * weight;
	}
	// From afar a leaf is smaller than a couple of pixels: their average color replaces the leaves.
	vec3 q = lp / leaf_size;
	float detail = 1.0 - smoothstep(0.35, 0.9, length(fwidth(q)) * 0.7);
	vec3 average = mix(mix(leaf_color, leaf_light_color, 0.45), accent_color, accent_share * 0.6)
			* mix(0.62, 1.05, clump) * 0.9;
	color = mix(average, color, detail);
	// The top of the crown is lighter, the bottom is in its shadow.
	color *= mix(0.62, 1.12, smoothstep(-0.6, 0.8, normalize(local_normal).y));

	ALBEDO = color;
	ROUGHNESS = roughness;
	AO = mix(1.0, mix(0.45, 1.0, covered * light), detail);
	vec3 tilt_view = (VIEW_MATRIX * (MODEL_MATRIX * vec4(tilt, 0.0))).xyz;
	NORMAL = normalize(NORMAL + detail * tilt_view);
}
