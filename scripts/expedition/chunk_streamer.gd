extends Node3D

## Chunk streaming (seção 51 do GDD): gera a rota a partir da seed e mantém
## instanciados só os chunks perto da personagem; os que ficam para trás
## são descarregados (com seus obstáculos e loot). Carrega no máximo um
## chunk por frame (espalha o custo) e mescla a geometria estática de cada
## um (MeshMerger) para cortar draw calls.

@export var region: RegionData
@export var load_ahead := 120.0
@export var keep_behind := 30.0
## Nó que recebe os zumbis (ver ChunkPopulator.populate).
@export var actors_path: NodePath
## Nó ExpeditionEvents que dispara avisos e hordas.
@export var events_path: NodePath

## Um chunk acabou de ser instanciado e populado (a Run usa para a mochila
## deixada na morte, seção 47).
signal chunk_loaded(instance: Node3D, chunk: RouteGenerator.RouteChunk)

var route: Array[RouteGenerator.RouteChunk] = []
## Bifurcações da rota (seção 24), na ordem.
var forks: Array[RouteGenerator.Fork] = []
## id da bifurcação → lado escolhido (1 esquerda, 2 direita).
var chosen := {}
## Depois de uma extração antecipada, nada além deste ponto carrega.
var route_end := INF
var _loaded := {}  # índice do chunk → instância
var _player: Node3D
var _actors: Node3D
var _events: Node


func build(expedition_seed: int, target_distance: float) -> float:
	route = RouteGenerator.generate(region, expedition_seed, target_distance)
	# Mescla os chunks da região já na largada (tira o engasgo da 1ª vez).
	for data in region.chunks + [region.start_chunk, region.end_chunk]:
		MeshMerger.prewarm(data.scene)
	for chunk in route:
		if chunk.data.poi_banner != "" or chunk.branch != 0 or chunk.fork:
			MeshMerger.prewarm(chunk.data.scene)
		if chunk.fork:
			forks.append(chunk.fork)
	_player = get_tree().get_first_node_in_group("player")
	_actors = get_node(actors_path)
	_events = get_node_or_null(events_path)
	if _events:
		for chunk in route:
			if chunk.event and chunk.branch == 0:
				_events.schedule(chunk.event, chunk.start_distance, chunk.data.length)
			if chunk.data.poi_banner != "":
				_events.schedule_banner(chunk.data.poi_banner, chunk.data.poi_color, chunk.start_distance)
	# No início carrega tudo o que já está à vista de uma vez.
	_update_streaming(route.size())
	return RouteGenerator.total_length(route)


func loaded_count() -> int:
	return _loaded.size()


## Seção 24: a partir daqui só o ramo `side` da bifurcação carrega.
func choose(fork: RouteGenerator.Fork, side: int) -> void:
	chosen[fork.id] = side
	if fork.sides[side].early_extraction:
		route_end = fork.ends[side]


func _active(chunk: RouteGenerator.RouteChunk) -> bool:
	if chunk.start_distance >= route_end - 0.01:
		return false
	return chunk.branch == 0 or chosen.get(chunk.fork_id, 0) == chunk.branch


func _process(_delta: float) -> void:
	if _player:
		_update_streaming(1)


func _update_streaming(max_loads: int) -> void:
	var distance := -_player.global_position.z
	var loads := 0
	for chunk in route:
		var wanted := chunk.start_distance < distance + load_ahead and chunk.end_distance() > distance - keep_behind and _active(chunk)
		if wanted and not _loaded.has(chunk.index):
			if loads >= max_loads:
				continue
			loads += 1
			_load(chunk)
		elif not wanted and _loaded.has(chunk.index):
			_loaded[chunk.index].queue_free()
			_loaded.erase(chunk.index)


func _load(chunk: RouteGenerator.RouteChunk) -> void:
	var instance: Node3D = chunk.data.scene.instantiate()
	MeshMerger.merge_static(instance, chunk.data.scene.resource_path)
	add_child(instance)
	instance.position = Vector3(0, 0, -chunk.start_distance)
	ChunkPopulator.populate(instance, chunk.data, region, chunk.chunk_seed, _actors, chunk.event, chunk.mods)
	if chunk.fork:
		_write_fork_signs(instance, chunk.fork)
	_loaded[chunk.index] = instance
	chunk_loaded.emit(instance, chunk)


## Placa da bifurcação (seção 24): destino, recompensa e perigo de cada lado.
func _write_fork_signs(instance: Node3D, fork: RouteGenerator.Fork) -> void:
	for side in [1, 2]:
		var branch: BranchData = fork.sides[side]
		var label := instance.find_child("SignLeft" if side == 1 else "SignRight", true, false) as Label3D
		if not label:
			continue
		var arrow := "← " if side == 1 else ""
		var arrow_r := "" if side == 1 else " →"
		label.text = "%s%s%s\n%s\n%s" % [arrow, branch.display_name.to_upper(), arrow_r, branch.reward_text, branch.danger_text()]
		label.modulate = branch.color
