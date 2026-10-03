class_name ExpeditionDirector
extends Node

## Expedition Director (seção 30 do GDD): lê a tensão da corrida e alterna o
## ritmo calmo → tensão → perigo → alívio → clímax. Não mexe na estrutura
## sorteada pela seed (chunks, obstáculos, padrões): só decide os extras do
## chunk que acabou de carregar (zumbis a mais ou loot de recompensa), quanto
## o ruído atrai zumbis e a horda do clímax perto da extração.

enum Phase { CALM, TENSION, DANGER, RELIEF, CLIMAX }
const PHASE_NAMES: Array[String] = ["CALMO", "TENSÃO", "PERIGO", "ALÍVIO", "CLÍMAX"]

## Fração inicial da rota sempre calma.
@export var calm_fraction := 0.12
## A partir desta fração da rota começa o clímax.
@export var climax_fraction := 0.85
## Segundos sem ameaça para o Director subir o ritmo (TENSÃO).
@export var quiet_time_for_tension := 16.0
## Tensão que dispara o ALÍVIO, e quanto ele dura.
@export var relief_trigger := 75.0
@export var relief_duration := 12.0
## Zumbis a mais no chunk que carrega durante a TENSÃO.
@export var tension_extra_zombies := 2
## Loot de recompensa no chunk que carrega durante o ALÍVIO.
@export var relief_bonus_loot := 1
## A horda do clímax só em expedições a partir desta distância (Longa).
@export var climax_min_distance := 1500.0
## Tamanho da horda do clímax em relação à horda do evento.
@export var climax_horde_delta := -2
## Quanto o ruído atrai zumbis em cada fase (multiplica a chance da Run).
@export var attract_by_phase := PackedFloat32Array([0.3, 1.5, 1.0, 0.0, 1.2])

var phase := Phase.CALM
## 0 a 100, suavizada.
var tension := 0.0
var rng := RandomNumberGenerator.new()
## Quantas vezes cada fase aconteceu e quantos extras o Director criou.
var stats := {"extra_zombies": 0, "bonus_loot": 0, "climax": false, "reliefs": 0}

var _run: Node
var _quiet := 0.0
var _relief_left := 0.0
var _climax_done := false
## [tempo, dano] dos últimos golpes.
var _recent_damage: Array = []
var _time := 0.0
var _last_hp := -1
## Rádio de alerta (seção 64): segundos de calma forçada; adia o clímax.
var _calm_left := 0.0


func _ready() -> void:
	_run = get_parent()
	# Por caminho: os @onready da Run ainda não existem quando os filhos
	# fazem _ready.
	_run.get_node("Chunks").chunk_loaded.connect(_on_chunk_loaded)
	_run.get_node("Player/Health").health_changed.connect(_on_health_changed)


func add_calm(seconds: float) -> void:
	_calm_left += seconds


func phase_name() -> String:
	return PHASE_NAMES[phase]


## Multiplicador da chance de o ruído atrair zumbis.
func attract_multiplier() -> float:
	return attract_by_phase[phase]


func _on_health_changed(current: int, _max_hp: int) -> void:
	if _last_hp >= 0 and current < _last_hp:
		_recent_damage.append([_time, _last_hp - current])
	_last_hp = current


func _process(delta: float) -> void:
	if _run.run_ended:
		return
	_time += delta
	while not _recent_damage.is_empty() and _time - _recent_damage[0][0] > 10.0:
		_recent_damage.pop_front()

	# Tensão: dano recente, zumbis perto, agarrão, ruído e HP baixo.
	var damage := 0.0
	for d in _recent_damage:
		damage += d[1]
	var player: Node3D = _run.player
	var near := 0
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if zombie.is_alive() and absf(zombie.global_position.z - player.global_position.z) < 15.0:
			near += 1
	var grabbed: bool = _run.player_combat.is_grabbed()
	var health: Node = _run.player_health
	var hp_ratio := float(health.current_hp) / maxf(1.0, health.max_hp)
	var target := clampf(damage * 1.2 + near * 9.0 + (25.0 if grabbed else 0.0) + _run.noise * 2.5 + (1.0 - hp_ratio) * 25.0, 0.0, 100.0)
	tension = lerpf(tension, target, 1.0 - exp(-delta * 2.0))

	if near > 0 or grabbed or damage > 0.0:
		_quiet = 0.0
	else:
		_quiet += delta
	_relief_left = maxf(0.0, _relief_left - delta)
	_calm_left = maxf(0.0, _calm_left - delta)
	_update_phase()


func _update_phase() -> void:
	if _calm_left > 0.0:
		phase = Phase.CALM
		return
	var progress: float = _run.distance_travelled() / maxf(1.0, _run.extraction_distance)
	if progress >= climax_fraction:
		phase = Phase.CLIMAX
		if not _climax_done:
			_climax_done = true
			_start_climax()
	elif _relief_left > 0.0:
		phase = Phase.RELIEF
	elif tension >= relief_trigger:
		# Acabou de passar por um pico: respiro.
		_relief_left = relief_duration
		phase = Phase.RELIEF
		stats.reliefs += 1
	elif progress < calm_fraction:
		phase = Phase.CALM
	elif _quiet >= quiet_time_for_tension:
		phase = Phase.TENSION
	else:
		phase = Phase.DANGER


## Horda perto da extração (seção 30: "CLÍMAX → EXTRAÇÃO").
func _start_climax() -> void:
	if _run.extraction_distance < climax_min_distance or _run.early_extraction:
		return
	stats.climax = true
	_run.events.spawn_horde_now("ELES ESTÃO CHEGANDO!", Color(1.0, 0.3, 0.25), rng, climax_horde_delta)


## Extras do chunk que acabou de carregar, conforme a fase.
func _on_chunk_loaded(instance: Node3D, chunk: RouteGenerator.RouteChunk) -> void:
	if chunk.start_distance < 60.0 or chunk.fork or chunk.data == _run.chunk_streamer.region.end_chunk:
		return
	var region: RegionData = _run.chunk_streamer.region
	match phase:
		Phase.TENSION:
			for i in tension_extra_zombies:
				var lane := rng.randi_range(0, 2)
				var pos := Vector3((lane - 1) * ChunkPopulator.LANE_WIDTH, 0.0, -(chunk.start_distance + rng.randf_range(12.0, chunk.data.length - 4.0)))
				ChunkPopulator.spawn_zombie(region, rng, _run.actors, pos)
				stats.extra_zombies += 1
		Phase.RELIEF:
			for i in relief_bonus_loot:
				var loot := ChunkPopulator.LOOT_SCENE.instantiate()
				loot.loot_type = rng.rand_weighted(region.loot_weights)
				var amounts: Array = ChunkPopulator.LOOT_AMOUNTS[loot.loot_type]
				loot.amount = rng.randi_range(amounts[0], amounts[1]) + region.loot_amount_bonus
				instance.add_child(loot)
				# Entre as linhas de padrões, para não cair num obstáculo.
				var z: float = [14.0, 26.0][rng.randi() % 2]
				loot.position = Vector3((rng.randi_range(0, 2) - 1) * ChunkPopulator.LANE_WIDTH, 0.0, -z)
				stats.bonus_loot += 1
