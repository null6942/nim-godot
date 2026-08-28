shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 pearl_color : source_color = vec3(0.94, 0.90, 0.84);
uniform vec3 irid_cool : source_color = vec3(0.45, 0.72, 0.82);
uniform vec3 irid_warm : source_color = vec3(0.82, 0.48, 0.70);
uniform vec3 gold_color : source_color = vec3(0.93, 0.76, 0.32);
uniform float selected : hint_range(0.0, 1.0) = 0.0;
uniform float hovered : hint_range(0.0, 1.0) = 0.0;
uniform float dimmed : hint_range(0.0, 1.0) = 0.0;
uniform float hue_shift : hint_range(-0.1, 0.1) = 0.0;

void fragment() {
	vec3 n = normalize(NORMAL);
	float ndv = clamp(dot(n, normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, 1.7);
	float tight = pow(ndv, 40.0);
	float swirl = sin(n.x * 7.5 + n.y * 5.5 + hue_shift * 14.0) * 0.5 + 0.5;
	vec3 irid = mix(irid_cool, irid_warm, swirl);
	vec3 base = pearl_color + vec3(hue_shift * 0.45, hue_shift * 0.18, -hue_shift * 0.28);
	vec3 col = mix(base, irid, 0.20 + fresnel * 0.50);
	col = mix(col, gold_color, selected * 0.46);
	col *= mix(1.0, 0.55, dimmed);

	ALBEDO = col;
	METALLIC = mix(0.28, 0.52, selected);
	ROUGHNESS = mix(0.045, 0.16, fresnel);
	ROUGHNESS = mix(ROUGHNESS, 0.42, dimmed);
	ROUGHNESS = mix(ROUGHNESS, 0.07, selected);
	SPECULAR = 1.0;
	EMISSION = irid * (0.10 + fresnel * 0.28);
	EMISSION += vec3(1.0, 0.97, 0.92) * tight * 0.65;
	EMISSION += gold_color * (selected * 0.38 + hovered * 0.14);
	RIM = mix(0.45, 0.85, clamp(selected + hovered * 0.45, 0.0, 1.0));
	RIM_TINT = 0.4;
}
