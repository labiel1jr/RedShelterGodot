class_name RouteGenerator
extends RefCounted

## Monta a sequência de chunks da expedição (seções 19 e 23 do GDD):
## chunk inicial, chunks sorteados pela seed até cobrir a distância alvo, e
## o chunk de extração. Alguns chunks do meio recebem um evento (seção 27),
## alguns viram locais especiais (seção 26) e alguns abrem uma bifurcação
## (seção 24): os dois ramos ocupam o mesmo trecho da pista e só o
## escolhido é carregado.
## Mesma seed + mesma região + mesma distância = mesma rota.


class RouteChunk:
	var data: ChunkData
	var index: int
	## Distância (m) do início da rota até o começo deste chunk.
	var start_distance: float
	## Seed própria do chunk, para o conteúdo não depender da ordem de carga.
	var chunk_seed: int
	## Evento procedural deste chunk (seção 27), ou null.
	var event: EventData
	## 0 = rota principal; 1 / 2 = ramo esquerdo / direito da bifurcação
	## `fork_id`.
	var branch := 0
	var fork_id := -1
	## Modificadores de loot e zumbis do ramo (BranchData.mods()).
	var mods := {}
	## Só no chunk da bifurcação: ver Fork.
	var fork: Fork

	func end_distance() -> float:
		return start_distance + data.length


class Fork:
	var id: int
	## [null, ramo esquerdo, ramo direito]
	var sides: Array[BranchData] = [null, null, null]
	## Lado de menor perigo: para onde vai quem está na faixa do meio.
	var default_side := 1
	## Distância em que a faixa da personagem decide o caminho.
	var decision_distance: float
	## Fim da divisória (a faixa do meio fica bloqueada até aqui).
	var divider_end: float
	## Onde cada ramo termina (o da extração antecipada termina a expedição).
	var ends := [0.0, 0.0, 0.0]


static func generate(region: RegionData, expedition_seed: int, target_distance: float) -> Array[RouteChunk]:
	var rng := RandomNumberGenerator.new()
	rng.seed = expedition_seed
	var world := GameManager.WORLD

	var route: Array[RouteChunk] = []
	var distance := 0.0

	distance = _append(route, region.start_chunk, distance, rng)

	var middle_target := target_distance - region.end_chunk.length
	var previous: ChunkData = null
	# Seção 26: locais especiais raros, até o limite da distância; cada POI
	# aparece no máximo uma vez por expedição.
	var max_pois := world.max_pois_for(target_distance)
	var pois_left: Array[ChunkData] = region.pois.duplicate()
	var forks_left: int = world.max_forks_for(target_distance) if world.fork_chunk and world.branches.size() >= 2 else 0
	var fork_count := 0
	while distance < middle_target:
		# Seção 24: bifurcação, se ainda cabe inteira antes da extração.
		var fork_room: float = world.fork_chunk.length + 3 * 40.0 if forks_left > 0 else 0.0
		if route.size() > 2 and forks_left > 0 and distance + fork_room < middle_target and rng.randf() < world.fork_chance:
			distance = _append_fork(route, region, distance, target_distance, fork_count, rng)
			forks_left -= 1
			fork_count += 1
			previous = null
			continue
		var data := _pick_chunk(region.chunks, previous, rng)
		# O primeiro chunk do meio nunca é POI nem tem evento, para a corrida
		# esquentar.
		var is_poi := false
		if route.size() > 1 and max_pois > 0 and not pois_left.is_empty() and rng.randf() < region.poi_chance:
			data = _pick_chunk(pois_left, null, rng)
			pois_left.erase(data)
			max_pois -= 1
			is_poi = true
		distance = _append(route, data, distance, rng)
		previous = data
		if is_poi:
			route[-1].event = data.poi_event
		elif route.size() > 2 and not region.events.is_empty() and rng.randf() < region.event_chance:
			route[-1].event = _pick_event(region.events, rng)

	_append(route, region.end_chunk, distance, rng)
	return route


## Chunk da placa + os dois ramos no mesmo trecho. Retorna a distância em
## que a rota principal continua.
static func _append_fork(route: Array[RouteChunk], region: RegionData, distance: float, target_distance: float, fork_id: int, rng: RandomNumberGenerator) -> float:
	var world := GameManager.WORLD
	var fork := Fork.new()
	fork.id = fork_id
	fork.decision_distance = distance + world.fork_decision_offset
	distance = _append(route, world.fork_chunk, distance, rng)
	route[-1].fork = fork
	fork.divider_end = distance

	# Dois ramos de perigos diferentes; a saída antecipada só nas longas e
	# depois de ~40% da rota.
	var allow_early := target_distance >= world.early_extraction_min_distance - 1.0 and distance >= target_distance * 0.4
	var candidates: Array[BranchData] = []
	for b in world.branches:
		if allow_early or not b.early_extraction:
			candidates.append(b)
	var first := _pick_branch(candidates, rng)
	var others: Array[BranchData] = []
	for b in candidates:
		if b != first and b.danger != first.danger and not (b.early_extraction and first.early_extraction):
			others.append(b)
	if others.is_empty():
		for b in candidates:
			if b != first:
				others.append(b)
	var second := _pick_branch(others, rng)
	var left_first := rng.randf() < 0.5
	fork.sides[1] = first if left_first else second
	fork.sides[2] = second if left_first else first
	fork.default_side = 1 if fork.sides[1].danger <= fork.sides[2].danger else 2

	var count := rng.randi_range(maxi(first.min_chunks, second.min_chunks), maxi(first.max_chunks, second.max_chunks))
	var branch_end := distance
	for side in [1, 2]:
		var branch: BranchData = fork.sides[side]
		var d := distance
		if branch.early_extraction:
			d = _append(route, region.end_chunk, d, rng)
			_tag(route[-1], fork_id, side, branch)
		else:
			var pool: Array[ChunkData] = branch.chunks if not branch.chunks.is_empty() else region.chunks
			var prev: ChunkData = null
			for i in count:
				var data := _pick_chunk(pool, prev, rng)
				d = _append(route, data, d, rng)
				_tag(route[-1], fork_id, side, branch)
				prev = data
			branch_end = maxf(branch_end, d)
		fork.ends[side] = d
	return branch_end


static func _tag(chunk: RouteChunk, fork_id: int, side: int, branch: BranchData) -> void:
	chunk.fork_id = fork_id
	chunk.branch = side
	chunk.mods = branch.mods()


static func _pick_branch(branches: Array[BranchData], rng: RandomNumberGenerator) -> BranchData:
	var weights := PackedFloat32Array()
	for b in branches:
		weights.append(b.weight)
	return branches[rng.rand_weighted(weights)]


static func total_length(route: Array[RouteChunk]) -> float:
	return route[-1].end_distance() if not route.is_empty() else 0.0


static func _append(route: Array[RouteChunk], data: ChunkData, distance: float, rng: RandomNumberGenerator) -> float:
	var chunk := RouteChunk.new()
	chunk.data = data
	chunk.index = route.size()
	chunk.start_distance = distance
	chunk.chunk_seed = rng.randi()
	route.append(chunk)
	return distance + data.length


static func _pick_event(events: Array[EventData], rng: RandomNumberGenerator) -> EventData:
	var weights := PackedFloat32Array()
	for e in events:
		weights.append(e.weight)
	return events[rng.rand_weighted(weights)]


## Sorteio ponderado pelo peso do chunk, sem repetir o anterior.
static func _pick_chunk(chunks: Array[ChunkData], previous: ChunkData, rng: RandomNumberGenerator) -> ChunkData:
	var candidates := chunks.filter(func(c): return c != previous or chunks.size() == 1)
	var weights := PackedFloat32Array()
	for c in candidates:
		weights.append(c.weight)
	return candidates[rng.rand_weighted(weights)]
