shader_type canvas_item;
// The background of the loading screen: the last frame of the game, already shrunk, blurred a little more, darkened,
// with darker corners and a darker bottom under the text.

// The blur, in pixels of the shrunk frame.
uniform float blur : hint_range(0.0, 4.0) = 1.5;
// How much darker than the frame.
uniform float darkness : hint_range(0.0, 1.0) = 0.45;
// How much the corners darken.
uniform float vignette : hint_range(0.0, 2.0) = 0.9;
// How much the bottom darkens, under the text.
uniform float bottom_shade : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec2 offset = TEXTURE_PIXEL_SIZE * blur;
	// A 3 × 3 tent: the middle counts four times, the sides twice, the corners once.
	vec3 sum = texture(TEXTURE, UV).rgb * 4.0;
	sum += (texture(TEXTURE, UV + vec2(offset.x, 0.0)).rgb + texture(TEXTURE, UV - vec2(offset.x, 0.0)).rgb
			+ texture(TEXTURE, UV + vec2(0.0, offset.y)).rgb + texture(TEXTURE, UV - vec2(0.0, offset.y)).rgb) * 2.0;
	sum += texture(TEXTURE, UV + offset).rgb + texture(TEXTURE, UV - offset).rgb
			+ texture(TEXTURE, UV + vec2(offset.x, -offset.y)).rgb
			+ texture(TEXTURE, UV + vec2(-offset.x, offset.y)).rgb;
	vec3 color = sum / 16.0 * (1.0 - darkness);
	vec2 from_center = UV - 0.5;
	color *= clamp(1.0 - vignette * dot(from_center, from_center), 0.0, 1.0);
	color *= 1.0 - bottom_shade * smoothstep(0.45, 1.0, UV.y);
	// COLOR comes in with the screen's fade in its alpha (the frame itself is opaque).
	COLOR = vec4(color, COLOR.a);
}
