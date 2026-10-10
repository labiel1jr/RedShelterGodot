// Contorno do cel-shading (seção 65 do GDD): casco invertido, desenhado como
// material_overlay de cada objeto. A malha é "inflada" e só as faces de trás
// aparecem, formando a linha escura em volta.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, fog_disabled;

// Espessura em metros perto da câmera; cresce com a distância para a linha
// manter mais ou menos a mesma grossura na tela.
uniform float width = 0.03;
uniform vec4 outline_color : source_color = vec4(0.086, 0.078, 0.122, 1.0);
// Entre estas distâncias o contorno some (0 = nunca some).
uniform float fade_start = 0.0;
uniform float fade_end = 0.0;
// Malhas primitivas centradas (caixa, cápsula): inflar a partir do centro
// evita rachaduras nos cantos. Malhas mescladas: inflar pela normal.
uniform bool from_center = false;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = length(CAMERA_POSITION_WORLD - world_pos);
	float w = width * (1.0 + dist * 0.04);
	if (fade_end > fade_start) {
		w *= 1.0 - smoothstep(fade_start, fade_end, dist);
	}
	vec3 dir = from_center ? normalize(VERTEX + vec3(0.0001)) : NORMAL;
	VERTEX += dir * w;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
