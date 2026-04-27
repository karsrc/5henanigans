shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float curvature : hint_range(1.0, 10.0) = 6.0;
uniform float scanline_count : hint_range(0.0, 1080.0) = 280.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.25; 
uniform float brightness_boost : hint_range(1.0, 3.0) = 1.3; 
uniform float vignette_multiplier : hint_range(0.0, 5.0) = 0.8;

void fragment() {
	// 1. Curvature Math
	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
	vec2 offset = centered_uv.yx / curvature;
	vec2 distorted_uv = centered_uv + centered_uv * offset * offset;
	distorted_uv = distorted_uv * 0.5 + 0.5;

	// Corner Cutoff
	if (distorted_uv.x < 0.0 || distorted_uv.x > 1.0 || distorted_uv.y < 0.0 || distorted_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec4 screen_color = texture(screen_texture, distorted_uv);

		// 2. The Compensation Boost
		screen_color.rgb *= brightness_boost;

		// 3. Scanline Multiplier (Multiply, don't subtract)
		float scanline = sin(distorted_uv.y * scanline_count * 3.14159);
		scanline = (scanline * 0.5) + 0.5; 
		
		float multiplier = mix(1.0 - scanline_strength, 1.0, scanline);
		screen_color.rgb *= multiplier;

		// 4. Vignette
		float vignette = length(centered_uv);
		vignette = smoothstep(0.6, 1.6, vignette);
		COLOR = mix(screen_color, vec4(0.0, 0.0, 0.0, 1.0), vignette * vignette_multiplier);
	}
}