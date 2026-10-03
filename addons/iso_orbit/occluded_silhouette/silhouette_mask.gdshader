// The first silhouette pass: invisible, it only writes 4 to the stencil where the character is visible by itself
// (the mesh passes the depth test). The fills and the outline do not draw there: a staff behind the back does not
// show through the body.
// The stencil values are in silhouette_common.gdshaderinc.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_back, shadows_disabled;
stencil_mode write, compare_always, 4;

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
