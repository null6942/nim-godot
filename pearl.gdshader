shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 pearl_color : source_color = vec3(0.94, 0.90, 0.84);
uniform vec3 irid_cool : source_color = vec3(0.38, 0.76, 0.86);
uniform vec3 irid_warm : source_color = vec3(0.86, 0.50, 0.58);
uniform vec3 gold_color : source_color = vec3(0.910, 0.753, 0.337);
uniform float selected : hint_range(0.0, 1.0) = 0.0;
uniform float hovered : hint_range(0.0, 1.0) = 0.0;
uniform float dimmed : hint_range(0.0, 1.0) = 0.0;
uniform float hue_shift : hint_range(-0.1, 0.1) = 0.0;

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 view = normalize(VIEW);
	float ndv = clamp(dot(n, view), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, 1.45);
	float rim_band = pow(1.0 - ndv, 3.2);
	float tight = pow(ndv, 52.0);
	float travel = sin(n.x * 9.2 + n.y * 6.4 + ndv * 7.5 + hue_shift * 16.0) * 0.5 + 0.5;
	float travel2 = sin(n.z * 11.0 - n.y * 4.8 + hue_shift * 11.0 + ndv * 3.0) * 0.5 + 0.5;
	vec3 irid = mix(irid_cool, irid_warm, travel);
	irid = mix(irid, mix(irid_warm, irid_cool, travel2), 0.38);
	vec3 base = pearl_color + vec3(hue_shift * 0.40, hue_shift * 0.16, -hue_shift * 0.26);
	vec3 col = mix(base, irid, 0.14 + fresnel * 0.66);
	col = mix(col, gold_color, selected * 0.50 + hovered * 0.10);
	col *= mix(1.0, 0.50, dimmed);

	ALBEDO = col;
	METALLIC = mix(0.30, 0.56, selected);
	ROUGHNESS = mix(0.032, 0.13, fresnel);
	ROUGHNESS = mix(ROUGHNESS, 0.46, dimmed);
	ROUGHNESS = mix(ROUGHNESS, 0.05, selected);
	SPECULAR = 1.0;
	EMISSION = irid * (0.07 + fresnel * 0.36 + rim_band * 0.12);
	EMISSION += vec3(1.0, 0.97, 0.93) * tight * 0.78;
	EMISSION += gold_color * (selected * 0.40 + hovered * 0.15);
	EMISSION *= mix(1.0, 0.32, dimmed);
	RIM = mix(0.52, 0.94, clamp(selected + hovered * 0.5, 0.0, 1.0));
	RIM_TINT = 0.32;
}
