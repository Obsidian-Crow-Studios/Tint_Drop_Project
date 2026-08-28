shader_type canvas_item;
render_mode unshaded, blend_mix;

// Letter-shaped mask on the extra-crowd still: replace baked CLEARED gel
// by copying sunburst from the SAME texture. Dilate just enough to fill
// glyph gaps so EAR does not remain as a silhouette. y_cut is above pips.

uniform float y_cut : hint_range(0.0, 1.0) = 0.322;

bool is_gel(vec3 c) {
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = mx - mn;
	bool cyan = (c.b > c.r + 0.14) && (c.b > 0.33) && (sat > 0.25);
	bool magenta = (c.r > 0.49) && (c.b > 0.33) && (c.g + 0.14 < c.r) && (sat > 0.25);
	bool orange = (c.r > 0.67) && (c.r > c.b + 0.20) && (sat > 0.49) && (luma < 0.90);
	return cyan || magenta || orange;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec4 outc = col;
	if (UV.y <= y_cut) {
		float e = 4.0 / 720.0;
		float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		int gel_n = int(is_gel(col.rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(e, 0.0)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(-e, 0.0)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(0.0, e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(0.0, -e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(e, e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(-e, e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(e, -e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(-e, -e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(2.0 * e, 0.0)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(-2.0 * e, 0.0)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(0.0, 2.0 * e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(0.0, -2.0 * e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(4.0 * e, 0.0)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(-4.0 * e, 0.0)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(0.0, 4.0 * e)).rgb));
		gel_n += int(is_gel(texture(TEXTURE, UV + vec2(0.0, -4.0 * e)).rgb));
		// Dark outlines / glyph holes in the letter band are not gel-colored
		// but still read as EAR if left behind.
		bool dark_glyph = (UV.y < 0.305) && (luma < 0.50);
		if (gel_n >= 1 || dark_glyph) {
			// Copy sunburst from the top of THIS still (same x). No second plate.
			vec2 sx = vec2(clamp(UV.x, 0.0, 1.0), 0.0);
			vec4 fill = texture(TEXTURE, sx + vec2(0.0, 0.006));
			fill += texture(TEXTURE, sx + vec2(0.0, 0.014));
			fill += texture(TEXTURE, sx + vec2(0.0, 0.022));
			outc = fill * 0.333;
		}
	}
	COLOR = outc;
}
