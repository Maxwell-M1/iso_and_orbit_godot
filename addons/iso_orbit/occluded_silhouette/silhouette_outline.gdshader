// The silhouette outline: meshes inflated along the normals by the fraction width of the screen height (the same at
// any distance and resolution) are drawn only where the stencil is 0: outside the body and gear fills and where the
// character is not visible by itself. It sets 1 so that the outlines of neighboring parts do not overlap. It runs
// after the fills (render_priority 4).
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, shadows_disabled;
stencil_mode read, write, compare_greater, 1;

#include "res://addons/iso_orbit/occluded_silhouette/silhouette_common.gdshaderinc"

uniform vec4 color : source_color = vec4(0.85, 0.96, 1.0, 0.95);
// The outline thickness as a fraction of the screen height (0.004 is 2.6 pixels at a height of 648, 4.3 at 1080).
uniform float width : hint_range(0.0, 0.02, 0.0005) = 0.004;

void vertex() {
	// The screen height at the vertex depth is 2·depth / |P[1][1]| meters. The absolute value: in Godot 4.7
	// (Vulkan/D3D12) the projection is flipped along Y and P[1][1] is negative; without the absolute value the mesh
	// shrinks instead of inflating, and there is no outline.
	float depth = max(-(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z, 0.05);
	VERTEX += NORMAL * width * 2.0 * depth / abs(PROJECTION_MATRIX[1][1]);
}

void fragment() {
	if (!silhouette_occluded(SCREEN_UV, VERTEX, INV_PROJECTION_MATRIX)) {
		discard;
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
