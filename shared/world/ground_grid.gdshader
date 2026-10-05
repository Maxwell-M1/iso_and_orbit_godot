// World ground: grass and dirt trails (the ROADS segments in terrain.gdshaderinc; they are only a pattern and do not
// affect movement). Grass: large patches (dark, dry), tussocks, grass blades, flowers in meadows; trail: a ragged edge
// with grass tufts, a trodden middle, ruts, pebbles, small cracks (terrain.gdshaderinc: the fine detail is baked
// textures, with their mip levels in the distance). Relief goes through the normal.
// A grid in world coordinates (it shows how fast the character runs and where it stopped) is turned on by the
// grid_strength parameter.
shader_type spatial;

#include "res://shared/world/terrain.gdshaderinc"

uniform vec3 grass_color : source_color = vec3(0.34, 0.47, 0.25);
uniform vec3 grass_dark_color : source_color = vec3(0.24, 0.37, 0.2);
uniform vec3 grass_dry_color : source_color = vec3(0.5, 0.5, 0.29);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
// The trails (ROADS) are the meadow's: the ground of another level turns them off.
uniform bool roads = true;

// Grid: 0 is off, 1 is full strength. The cell is cell_size, with a thick line every major_every cells.
uniform float grid_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 line_color : source_color = vec3(0.2, 0.24, 0.17);
uniform float cell_size = 1.0;
uniform float major_every = 5.0;
uniform float line_half_width = 0.02;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// 1 on a line of a grid with step spacing, 0 between the lines; the edges are smoothed over the width of a pixel.
float grid(vec2 p, float spacing, float half_width) {
	vec2 to_line = abs(fract(p / spacing + 0.5) - 0.5) * spacing;
	vec2 pixel = fwidth(p);
	vec2 line = 1.0 - smoothstep(vec2(half_width), vec2(half_width) + pixel, to_line);
	return max(line.x, line.y);
}

void fragment() {
	vec2 p = world_position.xz;
	vec4 tint_mask = ground_tint_mask(p);
	vec4 road_mask = ground_road_mask(p);

	// Large patches: dark grass, regular grass, dry grass.
	float patches = tint_mask.r;
	vec3 base = mix(grass_dark_color, grass_color, smoothstep(0.3, 0.6, patches));
	base = mix(base, grass_dry_color, smoothstep(0.62, 0.8, patches) * 0.8);
	Ground grass = grass_at(p, base, tint_mask);

	Ground ground = grass;
	if (roads) {
		ground = with_roads(p, grass, road_mask);
	}
	vec3 color = ground.color;
	vec2 tilt = ground.tilt;
	float ao = ground.ao;

	if (grid_strength > 0.0) {
		float lines = max(grid(p, cell_size, line_half_width), grid(p, cell_size * major_every, line_half_width * 2.0));
		color = mix(color, line_color, lines * grid_strength);
	}
	ALBEDO = color;
	ROUGHNESS = roughness;
	AO = ao;
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(vec3(tilt.x, 1.0, tilt.y)), 0.0)).xyz);
}
