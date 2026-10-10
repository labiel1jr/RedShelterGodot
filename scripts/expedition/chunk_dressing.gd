class_name ChunkDressing
extends RefCounted

## Enfeites de cenário (Fase 15 / A2): objetos dos artistas espalhados nas
## calçadas de cada chunk comum — lixeiras, caçambas, botijões, troncos,
## placas, cercas e entulho. Só visual, sem colisão. A posição sai da seed do
## chunk (a mesma rota repete os mesmos enfeites). Sem o modelo, nada aparece.

## [id, peso, x mínimo, x máximo (distância do centro da pista), girar 90°]
const PROPS := [
	[&"prop_trash_bin_cesta", 3.0, 4.6, 5.4, false],
	[&"prop_trash_bin_cacamba", 1.5, 5.6, 6.0, true],
	[&"prop_trash_bin_cheia", 1.5, 5.6, 6.0, true],
	[&"prop_gas_cylinder", 2.0, 4.5, 6.0, false],
	[&"prop_logs_1", 1.0, 5.0, 6.0, true],
	[&"prop_logs_2", 1.0, 5.0, 6.0, true],
	[&"prop_logs_3", 1.0, 5.0, 6.0, true],
	[&"prop_traffic_light_placa1", 1.0, 4.4, 4.6, false],
	[&"prop_traffic_light_placa2", 1.0, 4.4, 4.6, false],
	[&"prop_traffic_light_placa3", 1.0, 4.4, 4.6, false],
	[&"kit_fence_wall_cerca", 1.5, 6.4, 6.6, true],
	[&"prop_streetlight_inclinado", 0.6, 4.6, 4.9, false],
	[&"prop_rubble_pile", 0.6, 6.4, 6.8, false],
	[&"prop_ruined_oven", 0.4, 6.2, 6.6, false],
	[&"prop_debris_small_entulho", 1.2, 5.6, 6.2, false],
]
const MIN_SPACING := 3.5


static func dress(instance: Node3D, chunk: RouteGenerator.RouteChunk) -> void:
	var data := chunk.data
	if chunk.fork or data.poi_banner != "":
		return
	var path := data.scene.resource_path if data.scene else ""
	if path.contains("start") or path.contains("extraction") or path.contains("fork"):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk.chunk_seed ^ 0xD5E55
	var weights := PackedFloat32Array()
	for p in PROPS:
		weights.append(p[1] if AssetLibrary.has_model(p[0]) else 0.0)
	if weights.is_empty() or Array(weights).max() <= 0.0:
		return
	var used := {-1: [], 1: []}
	for i in rng.randi_range(3, 5):
		var prop: Array = PROPS[rng.rand_weighted(weights)]
		var side := -1 if rng.randf() < 0.5 else 1
		var z := -rng.randf_range(3.0, maxf(4.0, data.length - 3.0))
		var free := true
		for other in used[side]:
			if absf(other - z) < MIN_SPACING:
				free = false
		if not free:
			continue
		used[side].append(z)
		var model := AssetLibrary.instantiate(prop[0])
		model.name = "Dressing_%s" % prop[0]
		# Calçada: topo em y = 0,2.
		model.position = Vector3(side * rng.randf_range(prop[2], prop[3]), 0.2, z)
		model.rotation.y = (PI / 2.0 if prop[4] else 0.0) + rng.randf_range(-0.25, 0.25) + (PI if side > 0 else 0.0)
		instance.add_child(model)
