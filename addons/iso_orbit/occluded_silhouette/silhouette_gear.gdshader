// The silhouette fill of the gear in hand (the staff): in its own color over the body silhouette. It draws where the
// stencil is less than 3 (empty or body) and sets 3, so the gear parts also merge into one shape.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back, shadows_disabled;
stencil_mode read, write, compare_greater, 3;

#include "res://addons/iso_orbit/occluded_silhouette/silhouette_common.gdshaderinc"

uniform vec4 color : source_color = vec4(0.72, 0.9, 1.0, 0.75);

void fragment() {
	if (!silhouette_occluded(SCREEN_UV, VERTEX, INV_PROJECTION_MATRIX)) {
		discard;
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
