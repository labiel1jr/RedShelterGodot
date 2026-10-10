extends SceneTree
## Converte os modelos de art/ModelosImplantacao para o padrão do catálogo:
## metros, pivô no chão (centro da base), 1 material só com a cor (512 px).
## [id, categoria, arquivo, malha, medida ("h" altura / "max" maior lado / "k" fator), valor, textura ("" = a do material)]
const OBJ := "Objetos/Objetos_pos_apocalipticos.fbx"
const POLE_K := 6.5 / 11.42748
const LOG_K := 0.45 / 0.840669
const ITEMS := [
	["loot_food", "loot", "AguaEComida/Agua_e_comida.fbx", "Comida", "max", 0.6, "pof"],
	["loot_water", "loot", "AguaEComida/Agua_e_comida.fbx", "agua", "max", 0.6, "pof"],
	["loot_medicine", "loot", "medicalkit/MedKit_Low_Poly.fbx", "MedKit", "max", 0.6, "medkit"],
	["loot_scrap", "loot", "Sucata/Sucata01.dae", "scrap_high", "max", 0.7, "scrap"],
	["prop_trash_bin_cesta", "street_props", OBJ, "cesta_de_lixo", "h", 1.0, ""],
	["prop_trash_bin_cacamba", "street_props", OBJ, "cacamba_grande", "h", 1.3, ""],
	["prop_trash_bin_cheia", "street_props", OBJ, "lixeira_grande_cheia_de_lixo", "h", 1.3, ""],
	["prop_streetlight_poste", "street_props", OBJ, "poste_01", "k", POLE_K, ""],
	["prop_streetlight_inclinado", "street_props", OBJ, "poste_inclinado_01", "k", POLE_K, ""],
	["prop_streetlight_fios", "street_props", OBJ, "fios_de_postes_01", "k", POLE_K, ""],
	["prop_crates_enferrujada", "street_props", OBJ, "caixa_enferrujada_01", "h", 0.9, ""],
	["prop_debris_small_tijolos", "street_props", OBJ, "tijolos01", "h", 0.35, ""],
	["prop_debris_small_lata", "street_props", OBJ, "lata_de_cerveja", "h", 0.15, ""],
	["prop_debris_small_garrafa", "street_props", OBJ, "garrafa01", "h", 0.32, ""],
	["prop_debris_small_balde", "street_props", OBJ, "balde01", "h", 0.4, ""],
	["prop_debris_small_laje", "street_props", OBJ, "pedra_De_Forno_01", "h", 0.25, ""],
	["prop_debris_small_entulho", "street_props", OBJ, "Pilha_de_entulho_pequena_01", "h", 0.45, ""],
	["prop_rubble_pile", "street_props", OBJ, "Pilha_de_entulho_01", "h", 0.9, ""],
	["prop_ruined_oven", "street_props", OBJ, "Pilha_de_entulho_Forno_em_ruinas_01", "h", 2.2, ""],
	["prop_gas_cylinder", "street_props", OBJ, "botijao_de_gas", "h", 0.6, ""],
	["prop_logs_1", "nature", OBJ, "tronco01", "k", LOG_K, ""],
	["prop_logs_2", "nature", OBJ, "tronco02", "k", LOG_K, ""],
	["prop_logs_3", "nature", OBJ, "tronco03", "k", LOG_K, ""],
	["prop_traffic_light_placa1", "street_props", OBJ, "placa01", "h", 2.6, ""],
	["prop_traffic_light_placa2", "street_props", OBJ, "placa02", "h", 2.8, ""],
	["prop_traffic_light_placa3", "street_props", OBJ, "placa03", "h", 1.6, ""],
	["kit_fence_wall_cerca", "street_kit", OBJ, "cerca01", "h", 1.8, ""],
]


func _tex(name: String) -> Texture2D:
	return load("res://tex512/%s.png" % name)


func _initialize() -> void:
	await process_frame
	var cache := {}
	var preview := Node3D.new()
	root.add_child(preview)
	var x := 0.0
	for item in ITEMS:
		var file: String = item[2]
		if not cache.has(file):
			var s: Node3D = load("res://" + file).instantiate()
			root.add_child(s)
			cache[file] = s
		var mi: MeshInstance3D = null
		for m: MeshInstance3D in cache[file].find_children("*", "MeshInstance3D", true, false):
			if m.name == item[3]:
				mi = m
		if not mi:
			print("FALTOU ", item[0]); continue
		var a: AABB = mi.global_transform * mi.mesh.get_aabb()
		var k: float = item[5]
		match item[4]:
			"h": k = item[5] / a.size.y
			"max": k = item[5] / maxf(a.size.x, maxf(a.size.y, a.size.z))
		var base := Vector3(a.get_center().x, a.position.y, a.get_center().z)
		var b := Basis().scaled(Vector3.ONE * k)
		var xform: Transform3D = Transform3D(b, -(b * base)) * mi.global_transform
		var mesh: ArrayMesh = mi.mesh.duplicate()
		for i in mesh.get_surface_count():
			var tex: Texture2D = null
			if item[6] != "":
				tex = _tex(item[6])
			else:
				var src: Material = mi.get_active_material(i)
				var orig = src.get("albedo_texture") if src else null
				if orig:
					tex = _tex("obj_" + orig.resource_path.get_file().get_basename())
			var mat := StandardMaterial3D.new()
			mat.resource_name = "%s_%d" % [item[0], i]
			mat.albedo_texture = tex
			if tex and tex.get_image() and tex.get_image().detect_alpha() != Image.ALPHA_NONE:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mesh.surface_set_material(i, mat)
		var out := Node3D.new(); out.name = item[0]
		var m2 := MeshInstance3D.new(); m2.name = item[0] + "_mesh"; m2.mesh = mesh; m2.transform = xform
		out.add_child(m2); m2.owner = out
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://out/" + item[1]))
		var doc := GLTFDocument.new(); var st := GLTFState.new()
		doc.append_from_scene(out, st)
		var err := doc.write_to_filesystem(st, "res://out/%s/%s.glb" % [item[1], item[0]])
		var fa: AABB = xform * mi.mesh.get_aabb()
		print("OK ", item[0], " err=", err, " size=", fa.size)
		out.position.x = x; x += maxf(fa.size.x, 0.6) + 0.4
		preview.add_child(out)
	for s in cache.values():
		s.queue_free()
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.55, 0.55, 0.6); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 0.5; root.add_child(env)
	var l := DirectionalLight3D.new(); root.add_child(l); l.rotation = Vector3(-0.8, 0.5, 0)
	var cam := Camera3D.new(); root.add_child(cam)
	cam.look_at_from_position(Vector3(x * 0.5, 6.0, 14.0), Vector3(x * 0.5, 0.8, 0))
	cam.fov = 75
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview_all.png")
	quit()
