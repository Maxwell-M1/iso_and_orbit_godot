// A hedge from a box: foliage in clumps and uneven sides, like a trimmed bush. The box needs face subdivisions (BoxMesh
// subdivide_*, a cell of about 25 cm): vertices are displaced in lumps based on their world position, so the copies of
// a vertex on an edge get the same displacement and the faces do not split apart, and near the ground the displacement
// fades out so the bottom does not lift off. Leaves are drawn on the faces in two layers (leaves.gdshaderinc, baked
// textures): the near layer covers the far one, and the gaps show the shadow of the bush's depth.
shader_type spatial;

#include "res://shared/world/noise.gdshaderinc"
#include "res://shared/world/leaves.gdshaderinc"

uniform vec3 leaf_color : source_color = vec3(0.2, 0.36, 0.13);
uniform vec3 leaf_light_color : source_color = vec3(0.4, 0.56, 0.2);
// Color of the gaps: the depth of the bush.
uniform vec3 depth_color : source_color = vec3(0.05, 0.1, 0.04);
// Leaf length, m.
uniform float leaf_size = 0.08;
// Unevenness: the largest vertex displacement, m.
uniform float lumpiness = 0.09;
uniform float roughness : hint_range(0.0, 1.0) = 0.75;

varying vec3 rest_position;
varying vec3 local_normal;
varying vec3 world_position;

void vertex() {
	rest_position = VERTEX;
	local_normal = NORMAL;
	vec3 vertex = VERTEX;
	vec3 normal = NORMAL;
	lumpy_vertex(vertex, normal, MODEL_MATRIX, 0.625, lumpiness);
	VERTEX = vertex;
	NORMAL = normal;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 lp = rest_position * scale;
	// The face is chosen by the dominant axis of the mesh normal; u and v are its coordinate axes.
	vec3 axis = abs(local_normal);
	bool top = axis.y > max(axis.x, axis.z);
	vec3 u = top || axis.z >= axis.x ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec3 v = top ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
	vec2 p = vec2(dot(lp, u), dot(lp, v)) + (top ? vec2(13.1, 7.3) : vec2(0.0));

	Leaves leaves = leaves_at(p / leaf_size, leaf_color, leaf_light_color, vec3(0.5, 0.52, 0.2), 0.06, depth_color);
	// From afar a leaf is smaller than a couple of pixels: their average color replaces the leaves.
	vec2 q = p / leaf_size;
	float detail = 1.0 - smoothstep(0.35, 0.9, max(fwidth(q).x, fwidth(q).y));
	vec3 average = mix(leaf_color, leaf_light_color, 0.45) * mix(0.62, 1.05, leaves.clump) * 0.9;
	vec3 color = mix(average, leaves.color, detail);
	// The bottom of the bush is in shadow, darker near the ground.
	color *= mix(0.6, 1.0, smoothstep(0.0, 0.45, world_position.y));

	ALBEDO = color;
	ROUGHNESS = roughness;
	AO = mix(1.0, mix(0.45, 1.0, leaves.covered * leaves.light), detail);
	vec3 u_view = normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(u, 0.0))).xyz);
	vec3 v_view = normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(v, 0.0))).xyz);
	NORMAL = normalize(NORMAL + detail * (leaves.tilt.x * u_view + leaves.tilt.y * v_view));
}
