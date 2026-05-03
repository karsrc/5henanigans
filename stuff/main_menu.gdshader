shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float curvature : hint_range(1.0, 10.0) = 4.5;
uniform float rgb_shift : hint_range(0.0, 0.02) = 0.002; 
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.35; 
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.8; 
uniform float retro_softness : hint_range(0.0, 5.0) = 1.2; 
uniform float brightness : hint_range(0.0, 2.0) = 1.2; 
uniform float bw_blend : hint_range(0.0, 1.0) = 0.0;
uniform float bar_progress : hint_range(0.0, 0.5) = 0.0;
uniform float threshold : hint_range(0.0, 1.0) = 0.35;
uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 100.0) = 1.0;
vec2 curve(vec2 uv) {
	uv = (uv - 0.5) * 2.0;
	uv.x *= 1.0 + pow(abs(uv.y) / curvature, 2.0);
	uv.y *= 1.0 + pow(abs(uv.x) / curvature, 2.0);
	return (uv / 2.0) + 0.5;
}
void fragment() {
	vec2 uv = curve(SCREEN_UV);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		if (pixel_size > 1.0) {
			vec2 pixel_scale = SCREEN_PIXEL_SIZE * pixel_size;
			uv = floor(uv / pixel_scale) * pixel_scale;
		}
		vec2 shift = vec2(rgb_shift * pow(distance(uv, vec2(0.5)), 1.5), 0.0); 
		vec2 smudge = vec2(SCREEN_PIXEL_SIZE.x * retro_softness, 0.0);
		vec3 col_center = vec3(
			texture(screen_texture, uv + shift).r,
			texture(screen_texture, uv).g,
			texture(screen_texture, uv - shift).b
		);
		vec3 col_left = vec3(
			texture(screen_texture, uv + shift - smudge).r,
			texture(screen_texture, uv - smudge).g,
			texture(screen_texture, uv - shift - smudge).b
		);
		vec3 col_right = vec3(
			texture(screen_texture, uv + shift + smudge).r,
			texture(screen_texture, uv + smudge).g,
			texture(screen_texture, uv - shift + smudge).b
		);

		vec4 original = vec4((col_center * 0.5) + (col_left * 0.25) + (col_right * 0.25), 1.0);
		if (blur_amount > 0.0) {
			float offset = blur_amount * 0.002;
			original += texture(screen_texture, uv + vec2(offset, offset));
			original += texture(screen_texture, uv + vec2(-offset, -offset));
			original += texture(screen_texture, uv + vec2(offset, -offset));
			original += texture(screen_texture, uv + vec2(-offset, offset));
			original /= 5.0; 
		}

		float lum = dot(original.rgb, vec3(0.299, 0.587, 0.114));
		float bw = step(threshold, lum);
		vec3 one_bit_color = mix(vec3(0.0), vec3(0.85, 0.95, 1.0), bw);
		vec3 final_color = mix(original.rgb, one_bit_color, bw_blend);
		float scanline = step(0.5, mod(FRAGCOORD.y * 0.5, 1.0));
		final_color = mix(final_color, final_color * 0.6, scanline * scanline_intensity);
		float vig_math = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
		vig_math = clamp(vig_math * 16.0, 0.0, 1.0);
		vig_math = pow(vig_math, 0.5);
		
		float final_vignette = mix(1.0, vig_math, vignette_intensity);
		
		final_color *= mix(final_vignette, 1.0, bw_blend); 
		final_color *= mix(brightness, 1.0, bw_blend); 
		float in_bounds_top = step(bar_progress, SCREEN_UV.y);
		float in_bounds_bottom = step(SCREEN_UV.y, 1.0 - bar_progress);
		final_color *= in_bounds_top * in_bounds_bottom;

		COLOR = vec4(final_color, 1.0);
	}
}