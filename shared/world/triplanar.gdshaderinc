// A baked texture tile on three planes along the axes (world or mesh), blended by the normal, with no UV and no seam.
// On the side planes the second coordinate is height: whatever is stretched along the height in the texture (streaks,
// cracks) stands vertically on the surface.

// Weights of the three planes from normal n: sharp, only narrow bands blend.
vec3 triplanar_weights(vec3 n) {
	vec3 weights = pow(abs(n), vec3(4.0));
	return weights / (weights.x + weights.y + weights.z);
}

// Point p (in tiles) on the plane perpendicular to axis axis. The offset keeps the planes from repeating each other.
vec2 triplanar_uv(vec3 p, int axis) {
	return axis == 0 ? p.zy + 0.31 : (axis == 1 ? p.xz : p.xy + 0.67);
}

// Slope slope (along the two axes of plane axis) as a vector in three axes.
vec3 triplanar_gradient(vec2 slope, int axis) {
	return axis == 0 ? vec3(0.0, slope.y, slope.x) : (axis == 1 ? vec3(slope.x, 0.0, slope.y)
			: vec3(slope.x, slope.y, 0.0));
}

// Two textures with tile size tile (m) at point p: detail as is, normal also as RGBA, and its RG is a slope of
// −range…range per meter, summed into gradient (the caller projects it along the surface).
void triplanar_pair(sampler2D detail, sampler2D normal, vec3 p, vec3 weights, float tile, float range,
		out vec4 detail_value, out vec4 normal_value, out vec3 gradient) {
	detail_value = vec4(0.0);
	normal_value = vec4(0.0);
	gradient = vec3(0.0);
	for (int axis = 0; axis < 3; axis++) {
		float weight = weights[axis];
		if (weight < 0.02) {
			continue;
		}
		vec2 uv = triplanar_uv(p / tile, axis);
		detail_value += texture(detail, uv) * weight;
		vec4 n = texture(normal, uv);
		normal_value += n * weight;
		gradient += triplanar_gradient((n.rg * 2.0 - 1.0) * range, axis) * weight;
	}
	float total = dot(weights, step(vec3(0.02), weights));
	detail_value /= total;
	normal_value /= total;
	gradient /= total;
}
