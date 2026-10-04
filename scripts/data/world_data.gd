class_name WorldData
extends Resource

## O mundo das expedições (seções 25, 28 e 44 do GDD): regiões, distâncias
## de missão e os sobreviventes que podem ser encontrados.

@export var regions: Array[RegionData] = []

@export_group("Distâncias (seção 28)")
@export var distances := PackedFloat32Array([500.0, 1000.0, 2000.0])
@export var distance_names := PackedStringArray(["Curta", "Média", "Longa"])
## Nível da personagem para liberar cada distância.
@export var distance_unlock_levels := PackedInt32Array([1, 2, 4])
## Máximo de locais especiais (seção 26) em cada distância.
@export var distance_max_pois := PackedInt32Array([1, 1, 2, 3])

@export_group("Bifurcações (seção 24)")
## Chunk da bifurcação: placa e divisória na faixa do meio.
@export var fork_chunk: ChunkData
@export var branches: Array[BranchData] = []
## Máximo de bifurcações em cada distância.
@export var distance_max_forks := PackedInt32Array([1, 2, 3, 3])
## Chance de cada chunk do meio abrir uma bifurcação (até o limite).
@export_range(0.0, 1.0) var fork_chance := 0.07
## A extração antecipada só aparece a partir desta distância (Longa).
@export var early_extraction_min_distance := 2000.0
## Onde a divisória começa, a partir do início do chunk da bifurcação: a
## faixa da personagem nesse ponto decide o caminho.
@export var fork_decision_offset := 16.0

@export_group("Veículos (seção 63)")
@export var vehicles: Array[VehicleData] = []
## Chance de cada chunk elegível ter um veículo estacionado.
@export_range(0.0, 1.0) var vehicle_chance := 0.07
## Distância mínima entre dois veículos na mesma expedição.
@export var vehicle_min_gap := 200.0
## Sem veículos nos primeiros metros (a fase Calma) e perto do fim.
@export var vehicle_min_distance := 120.0
@export var vehicle_clear_before_extraction := 150.0
## Sem veículos a menos disto de uma bifurcação.
@export var vehicle_clear_around_fork := 100.0
## O aviso aparece esta distância antes do veículo.
@export var vehicle_sign_distance := 40.0
## Depois de cair do veículo, a personagem fica invulnerável por este tempo.
@export var vehicle_dismount_invulnerability := 1.0

@export_group("Power-ups (seção 64)")
## Os temporizados da pista e o Escudo de caçamba (consumível).
@export var powerups: Array[PowerUpData] = []
## Chance de cada chunk elegível ter um power-up (×`powerup_danger_multiplier`
## na fase Perigo do Director; nenhum no Clímax).
@export_range(0.0, 1.0) var powerup_chance := 0.3
@export var powerup_danger_multiplier := 1.5
@export var powerup_min_gap := 230.0
@export var powerup_min_distance := 60.0
@export var powerup_clear_before_extraction := 60.0
## Quantos temporizados ao mesmo tempo.
@export var powerup_max_active := 2
## Raros: chance em cada chunk de local especial (são poucos por rota), de
## evento ou ramo, e em qualquer chunk (fonte "track"); e a distância mínima
## entre dois. Uns 0,35 raro por expedição de 1 km.
@export_range(0.0, 1.0) var rare_powerup_poi_chance := 0.22
@export_range(0.0, 1.0) var rare_powerup_chance := 0.035
@export_range(0.0, 1.0) var rare_powerup_track_chance := 0.003
@export var rare_powerup_min_gap := 300.0

@export_group("Sobreviventes (seção 44)")
@export var professions: Array[ProfessionData] = []
@export var survivor_names := PackedStringArray()
## Consumo diário de cada morador além da personagem.
@export var survivor_daily_food := 1
@export var survivor_daily_water := 1
## Moradores que cabem sem Dormitório (a cama extra da sala principal).
@export var base_survivor_capacity := 1

@export_group("Personalidade e relacionamento (seção 44)")
@export var traits: Array[TraitData] = []
## Afinidade de 0 a 100 de cada morador com o grupo.
@export var affinity_start := 40
## Por dia com comida e água em Normal.
@export var affinity_daily := 2
## Quando a personagem volta viva com loot.
@export var affinity_loot := 5
## Quando falta comida ou água.
@export var affinity_shortage := -10
## Quando um resgatado é recusado por falta de vaga.
@export var affinity_turned_away := -5
## Com afinidade a partir daqui, o bônus da profissão sobe e o morador pode
## fazer pedidos.
@export var affinity_high := 75
@export var affinity_high_bonus := 0.5
## Com afinidade até aqui e moral crítica, o morador é o primeiro a ir embora.
@export var affinity_low := 20

@export_group("Pedidos dos moradores (seção 44)")
## Chance por dia de um morador com afinidade alta fazer um pedido.
@export_range(0.0, 1.0) var request_chance := 0.3
## Expedições (dias) para cumprir o pedido.
@export var request_days := 5
@export var request_xp := 80
@export var request_morale := 5
@export var request_affinity := 10
## Afinidade perdida quando o pedido expira.
@export var request_fail_affinity := -5
## Recursos que podem ser pedidos e a quantidade [mín, máx].
@export var request_resources := {"food": [6, 10], "water": [6, 10], "components": [3, 5], "medicine": [2, 4], "fuel": [3, 5]}


func distance_unlocked_level(index: int) -> int:
	return distance_unlock_levels[index]


## Limite de POIs para uma distância de expedição (a maior faixa que ela alcança).
func max_pois_for(distance: float) -> int:
	return _per_distance(distance_max_pois, distance)


func max_forks_for(distance: float) -> int:
	return _per_distance(distance_max_forks, distance)


func _per_distance(values: PackedInt32Array, distance: float) -> int:
	var result := 0
	for i in distances.size():
		if distance >= distances[i] - 1.0 and i < values.size():
			result = values[i]
	return result


func vehicle(id: StringName) -> VehicleData:
	for v in vehicles:
		if v.id == id:
			return v
	return null


func powerup(id: StringName) -> PowerUpData:
	for p in powerups:
		if p.id == id:
			return p
	return null


func region(id: StringName) -> RegionData:
	for r in regions:
		if r.id == id:
			return r
	return regions[0]


func trait_by_id(id: StringName) -> TraitData:
	for t in traits:
		if t.id == id:
			return t
	return null


func profession(id: StringName) -> ProfessionData:
	for p in professions:
		if p.id == id:
			return p
	return null
