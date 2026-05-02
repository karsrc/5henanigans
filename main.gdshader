shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// === TASTEFUL ARCADE VIBE ===
uniform float curvature : hint_range(1.0, 10.0) = 4.5;
uniform float rgb_shift : hint_range(0.0, 0.02) = 0.003;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.6;
uniform float brightness_boost : hint_range(1.0, 2.0) = 1.15; // Arcades glow!

// === DEATH SETTINGS ===
uniform float bw_blend : hint_range(0.0, 1.0) = 0.0;
uniform float bar_progress : hint_range(0.0, 0.5) = 0.0;
uniform float threshold : hint_range(0.0, 1.0) = 0.35;
uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 100.0) = 1.0;

vec2 curve(vec2 uv) {
	// Mathematically perfectly symmetrical curve
	uv = (uv - 0.5) * 2.0;
	uv.x *= 1.0 + pow(abs(uv.y) / curvature, 2.0);
	uv.y *= 1.0 + pow(abs(uv.x) / curvature, 2.0);
	return (uv / 2.0) + 0.5;
}

void fragment() {
	vec2 uv = curve(SCREEN_UV);

	// Symmetrical black borders (Strictly using if/else, NO early returns)
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// 1. Safe Pixelation
		if (pixel_size > 1.0) {
			vec2 pixel_scale = SCREEN_PIXEL_SIZE * pixel_size;
			uv = floor(uv / pixel_scale) * pixel_scale;
		}

		// 2. Smart Color Bleed (Center stays sharp)
		float dist = distance(uv, vec2(0.5));
		vec2 shift = vec2(rgb_shift * pow(dist, 2.0), 0.0); 

		float r = texture(screen_texture, uv + shift).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - shift).b;
		vec4 original = vec4(r, g, b, 1.0);

		// 3. Blur
		if (blur_amount > 0.0) {
			float offset = blur_amount * 0.002;
			original += texture(screen_texture, uv + vec2(offset, offset));
			original += texture(screen_texture, uv + vec2(-offset, -offset));
			original += texture(screen_texture, uv + vec2(offset, -offset));
			original += texture(screen_texture, uv + vec2(-offset, offset));
			original /= 5.0;
		}

		// 4. Animal Well monochrome
		float lum = dot(original.rgb, vec3(0.299, 0.587, 0.114));
		float bw = step(threshold, lum);
		vec3 one_bit_color = mix(vec3(0.0), vec3(0.85, 0.95, 1.0), bw);
		vec3 final_color = mix(original.rgb, one_bit_color, bw_blend);

		// 5. Arcade Polish: Scanlines, Shadow Mask, and Brightness
		float scanline = step(0.5, mod(FRAGCOORD.y * 0.5, 1.0));
		final_color = mix(final_color, final_color * 0.65, scanline * scanline_intensity);
		
		// Subtle vertical grid (The "Shadow Mask")
		if (mod(FRAGCOORD.x, 3.0) < 1.0) {
			final_color *= 0.9;
		}

		final_color *= brightness_boost; // Punch up the arcade glow
		final_color *= smoothstep(1.0 + vignette_intensity, 1.0 - vignette_intensity, dist * 1.5);

		// 6. Straight Bars
		float in_bounds_top = step(bar_progress, SCREEN_UV.y);
		float in_bounds_bottom = step(SCREEN_UV.y, 1.0 - bar_progress);
		final_color *= in_bounds_top * in_bounds_bottom;

		COLOR = vec4(final_color, 1.0);
	}
}