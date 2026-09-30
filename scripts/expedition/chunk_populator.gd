class_name ChunkPopulator
extends RefCounted

## Camadas 2 e 3 da geração (seções 21 e 22 do GDD): em cada Marker3D do nó
## "Rows" de um chunk, aplica um padrão de gameplay — obstáculos, loot e
## zumbis — sorteado pela seed do chunk. Eventos (seção 27) que mudam o
## layout — caminhão, explosão, recurso raro, sobrevivente — trocam o padrão
## de uma das linhas.

## R (recurso raro) e S (sobrevivente) também são passáveis.
const VALID_ROUTE_CHARS := ".$LHRS"
const LANE_WIDTH := 2.5
## Quantidade de cada loot: [mín, máx] por tipo, na ordem de
## GameManager.LOOT_KEYS (comida, água, sucata, munição, componentes,
## medicamentos, combustível).
const LOOT_AMOUNTS := [[1, 3], [1, 3], [2, 4], [3, 6], [1, 2], [1, 2], [1, 3]]
## Recurso raro (seção 27): [tipo, quantidade], em fila na faixa.
const RARE_CACHE := [[2, 8], [3, 12], [5, 2]]

const WALL_SCENE := preload("res://scenes/obstacles/wall.tscn")
const LOW_SCENE := preload("res://scenes/obstacles/barrier_low.tscn")
const HIGH_SCENE := preload("res://scenes/obstacles/bar_high.tscn")
const LOOT_SCENE := preload("res://scenes/obstacles/loot.tscn")
const ZOMBIE_SCENE := preload("res://scenes/zombie.tscn")
const SURVIVOR_SCENE := preload("res://scenes/survivor_npc.tscn")
const TRUCK_SCENE := preload("res://scenes/obstacles/truck.tscn")
const FIRE_SCENE := preload("res://scenes/obstacles/fire.tscn")


## Um padrão é válido se tem 3 faixas conhecidas e ao menos uma passável
## sem lutar (seção 22: "cada padrão deverá possuir uma rota válida").
static func is_valid_pattern(pattern: String) -> bool:
	if pattern.length() != 3:
		return false
	var has_route := false
	for c in pattern:
		if not c in ".WLH$ZRS":
			return false
		if c in VALID_ROUTE_CHARS:
			has_route = true
	return has_route


## `actors` recebe os zumbis: eles perseguem a personagem e não podem sumir
## junto com o chunk que ficou para trás.
## Retorna a distância local (z) da linha do evento, ou 0 se não houver.
## `mods`: modificadores do ramo de uma bifurcação (BranchData.mods()).
static func populate(chunk: Node3D, data: ChunkData, region: RegionData, chunk_seed: int, actors: Node3D, event: EventData = null, mods := {}) -> float:
	var rows := chunk.get_node_or_null("Rows")
	if not rows or rows.get_child_count() == 0:
		return 0.0

	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_seed
	var weights := _pattern_weights(region.patterns, data, mods)
	var loot_weights := data.loot_weights if not data.loot_weights.is_empty() else region.loot_weights
	var branch_loot: PackedFloat32Array = mods.get("loot_weights", PackedFloat32Array())
	if not branch_loot.is_empty():
		loot_weights = branch_loot
	var amount_bonus: int = region.loot_amount_bonus + int(mods.get("loot_amount_bonus", 0))

	# Linha do evento: a do meio do chunk.
	var event_row: Node = null
	var event_pattern := ""
	if event and event.id != &"horde":
		event_row = rows.get_child(floori(rows.get_child_count() / 2.0))
		event_pattern = _event_pattern(event.id, rng)

	for marker in rows.get_children():
		var pattern: String = marker.get_meta("pattern", "")
		if marker == event_row:
			pattern = event_pattern
		if pattern == "":
			pattern = region.patterns[rng.rand_weighted(weights)]
		if not is_valid_pattern(pattern):
			push_error("Padrão inválido '%s' em %s/%s" % [pattern, data.display_name, marker.name])
			continue

		for lane in 3:
			var local := Vector3((lane - 1) * LANE_WIDTH, 0.0, marker.position.z)
			match pattern[lane]:
				"W":
					_add(chunk, (region.wall_scene if region.wall_scene else WALL_SCENE).instantiate(), local)
				"L":
					_add(chunk, (region.low_scene if region.low_scene else LOW_SCENE).instantiate(), local)
				"H":
					_add(chunk, (region.high_scene if region.high_scene else HIGH_SCENE).instantiate(), local)
				"$":
					var loot := LOOT_SCENE.instantiate()
					loot.loot_type = rng.rand_weighted(loot_weights)
					var amounts: Array = LOOT_AMOUNTS[loot.loot_type]
					loot.amount = rng.randi_range(amounts[0], amounts[1]) + amount_bonus
					_add(chunk, loot, local)
				"Z":
					spawn_zombie(region, rng, actors, chunk.to_global(local))
				"R":
					_add_rare_cache(chunk, local, data.cache_loot if not data.cache_loot.is_empty() else RARE_CACHE)
				"S":
					var npc := SURVIVOR_SCENE.instantiate()
					var world := GameManager.WORLD
					npc.survivor_name = world.survivor_names[rng.randi() % world.survivor_names.size()]
					npc.profession = world.professions[rng.randi() % world.professions.size()]
					_add(chunk, npc, local)

		if marker == event_row:
			_decorate_event(chunk, event.id, pattern, marker.position.z)

	return event_row.position.z if event_row else 0.0


## Padrões especiais de evento (R = recurso raro, S = sobrevivente).
static func _event_pattern(id: StringName, rng: RandomNumberGenerator) -> String:
	var options: Array
	match id:
		&"truck":
			# O caminhão tombado ocupa duas faixas vizinhas.
			options = ["WW.", ".WW"]
		&"explosion":
			options = ["WW.", ".WW", "W.W"]
		&"rare_cache":
			options = ["ZRZ", "RZW", "WZR"]
		&"survivor":
			options = ["S.W", "W.S", ".SW", "WS."]
		_:
			return ""
	return options[rng.randi() % options.size()]


## Visual do evento sobre as paredes da linha: caminhão tombado ou fogo.
static func _decorate_event(chunk: Node3D, id: StringName, pattern: String, z: float) -> void:
	var blocked: Array[int] = []
	for lane in 3:
		if pattern[lane] == "W":
			blocked.append(lane)
	if blocked.is_empty():
		return
	var center_x := 0.0
	for lane in blocked:
		center_x += (lane - 1) * LANE_WIDTH
	center_x /= blocked.size()
	match id:
		&"truck":
			_add(chunk, TRUCK_SCENE.instantiate(), Vector3(center_x, 0.0, z))
		&"explosion":
			for lane in blocked:
				_add(chunk, FIRE_SCENE.instantiate(), Vector3((lane - 1) * LANE_WIDTH, 0.0, z))


## Recurso raro (seção 27): muita sucata e munição e alguns medicamentos
## num ponto perigoso.
## `items`: [[tipo, quantidade], ...] (os POIs trazem o seu), em fila.
static func _add_rare_cache(chunk: Node3D, local: Vector3, items: Array) -> void:
	for i in items.size():
		var loot := LOOT_SCENE.instantiate()
		loot.loot_type = items[i][0]
		loot.amount = items[i][1]
		loot.rare = true
		_add(chunk, loot, local + Vector3(0, 0, -1.6 * i))


## Zumbi de tipo sorteado pelos pesos da região. Também usado pela Run para
## os zumbis atraídos pelo ruído e pela horda.
static func spawn_zombie(region: RegionData, rng: RandomNumberGenerator, actors: Node3D, global_pos: Vector3) -> Node3D:
	var zombie := ZOMBIE_SCENE.instantiate()
	if not region.zombie_types.is_empty():
		var weights := region.zombie_weights
		if weights.size() != region.zombie_types.size():
			weights = PackedFloat32Array()
			for zombie_type in region.zombie_types:
				weights.append(zombie_type.spawn_weight)
		zombie.data = region.zombie_types[rng.rand_weighted(weights)]
	actors.add_child(zombie)
	zombie.global_position = global_pos
	return zombie


static func _add(chunk: Node3D, node: Node3D, local: Vector3) -> void:
	chunk.add_child(node)
	node.position = local


static func _pattern_weights(patterns: PackedStringArray, data: ChunkData, mods := {}) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	var loot_mult: float = data.loot_multiplier * float(mods.get("loot_multiplier", 1.0))
	var zombie_mult: float = data.zombie_multiplier * float(mods.get("zombie_multiplier", 1.0))
	for pattern in patterns:
		var w := 1.0
		if "$" in pattern:
			w *= loot_mult
		if "Z" in pattern:
			w *= zombie_mult
		weights.append(w)
	return weights
