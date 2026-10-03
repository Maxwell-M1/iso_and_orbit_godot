// The body silhouette fill: a flat color with no edges between parts. It draws where the stencil is less than 2
// (empty) and sets 2: the next part no longer draws at that point, so all parts of the body merge into one shape.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, shadows_disabled;
stencil_mode read, write, compare_greater, 2;

#include "res://addons/iso_orbit/occluded_silhouette/silhouette_common.gdshaderinc"

uniform vec4 color : source_color = vec4(0.42, 0.74, 1.0, 0.55);

void fragment() {
	if (!silhouette_occluded(SCREEN_UV, VERTEX, INV_PROJECTION_MATRIX)) {
		discard;
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
