// Shared by the silhouette passes (fills and outline): whether a fragment of the character is hidden by something
// in the world. The depth buffer is converted to meters and compared with the distance to the fragment: the
// silhouette is drawn only if the obstacle is closer by min_gap or more, so feet sunk slightly into a slope do not
// glow.
//
// The silhouette's stencil values: each fill or outline pass draws only where the value is less than its own and
// writes its own at once, so every point of the screen is painted once (the mask writes 4 wherever it is drawn):
//   4: the character is visible here by itself (silhouette_mask, render_priority 1); nothing draws here;
//   3: the fill of the gear in hand (silhouette_gear, 3): a separate shape over the body;
//   2: the body fill (silhouette_body, 2): all parts merge into one shape;
//   1: the outline (silhouette_outline, 4): it remains only outside the whole shape.

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
// How much closer (m) an obstacle must be for the character to count as hidden.
uniform float min_gap = 0.3;

bool silhouette_occluded(vec2 screen_uv, vec3 vertex, mat4 inv_projection) {
	float depth = texture(depth_texture, screen_uv).r;
	vec4 view = inv_projection * vec4(screen_uv * 2.0 - 1.0, depth, 1.0);
	float scene_distance = -view.z / view.w;
	return scene_distance < -vertex.z - min_gap;
}
