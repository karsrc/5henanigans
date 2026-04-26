shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float curvature : hint_range(1.0, 10.0) = 4.0;
uniform float scanline_count : hint_range(0.0, 1080.0) = 256.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.2;
uniform float vignette_multiplier : hint_range(0.0, 5.0) = 1.2;

void fragment() {
	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
	vec2 offset = centered_uv.yx / curvature;
	vec2 distorted_uv = centered_uv + centered_uv * offset * offset;
	distorted_uv = distorted_uv * 0.5 + 0.5;

	if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec4 screen_color = texture(screen_texture, distorted_uv);

		float scanline = sin(distorted_uv.y * scanline_count * 3.14159);
		scanline = clamp(scanline, 0.0, 1.0);
		vec4 color_with_scanlines = mix(screen_color, vec4(0.0, 0.0, 0.0, 1.0), scanline * scanline_strength);

		float vignette = length(centered_uv);
		vignette = smoothstep(0.5, 1.5, vignette);
		
		COLOR = mix(color_with_scanlines, vec4(0.0, 0.0, 0.0, 1.0), vignette * vignette_multiplier);
	}
}