shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 key_green : source_color = vec4(0.08, 0.94, 0.10, 1.0);
uniform float green_cut : hint_range(0.0, 1.0) = 0.16;
uniform float green_soft : hint_range(0.0, 1.0) = 0.12;
uniform float black_cut : hint_range(0.0, 1.0) = 0.0;
uniform float black_soft : hint_range(0.0, 1.0) = 0.06;
uniform float sat_cut : hint_range(0.0, 1.0) = 0.0;
uniform float sat_soft : hint_range(0.0, 1.0) = 0.08;
uniform float spill : hint_range(0.0, 1.0) = 0.55;
uniform float crop_top : hint_range(0.0, 1.0) = 0.0;
uniform float crop_bottom : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float mx = max(col.r, max(col.g, col.b));
	float mn = min(col.r, min(col.g, col.b));
	float sat = mx - mn;
	float g_dom = col.g - max(col.r, col.b);
	float key_d = distance(col.rgb, key_green.rgb);

	float green_kill = 0.0;
	if (col.g > 0.42 && g_dom > 0.06) {
		green_kill = max(
			smoothstep(green_cut, green_cut + green_soft, g_dom),
			1.0 - smoothstep(green_cut, green_cut + green_soft, key_d)
		);
	}

	float black_kill = 0.0;
	if (black_cut > 0.001) {
		black_kill = 1.0 - smoothstep(black_cut, black_cut + black_soft, luma);
	}

	float sat_kill = 0.0;
	if (sat_cut > 0.001 && luma < 0.62) {
		sat_kill = (1.0 - smoothstep(sat_cut, sat_cut + sat_soft, sat)) * (1.0 - smoothstep(0.42, 0.62, luma));
	}

	float crop = 1.0;
	if (crop_top > 0.001) {
		crop *= smoothstep(crop_top - 0.05, crop_top + 0.02, UV.y);
	}
	if (crop_bottom > 0.001) {
		crop *= 1.0 - smoothstep(1.0 - crop_bottom - 0.02, 1.0 - crop_bottom + 0.06, UV.y);
	}

	float alpha = col.a * (1.0 - clamp(green_kill, 0.0, 1.0));
	alpha *= (1.0 - clamp(black_kill, 0.0, 1.0));
	alpha *= (1.0 - clamp(sat_kill, 0.0, 1.0));
	alpha *= crop;

	if (g_dom > 0.0) {
		col.g = mix(col.g, min(col.g, max(col.r, col.b)), spill * green_kill);
	}

	COLOR = vec4(col.rgb, alpha);
}
