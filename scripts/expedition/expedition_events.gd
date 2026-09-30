extends Node

## Eventos procedurais da expedição (seção 27 do GDD). O RouteGenerator
## sorteia qual chunk tem evento; o ChunkPopulator monta o layout (caminhão,
## fogo, recurso raro, sobrevivente); aqui ficam os gatilhos por distância:
## o aviso no HUD ao se aproximar e a horda, que surge e persegue.

## O aviso aparece quando o chunk do evento está a esta distância.
const WARN_AHEAD := 38.0
## A horda surge quando a personagem entra no chunk.
const HORDE_TRIGGER_INTO := 4.0
const HORDE_SPAWN_AHEAD := 32.0

class Scheduled:
	var event: EventData
	var start_distance: float
	var length: float
	var warned := false
	var fired := false

var _scheduled: Array[Scheduled] = []
## Avisos sem evento (locais especiais, mochila): [distância, texto, cor].
var _banners: Array = []
var _rng := RandomNumberGenerator.new()
var _run: Node


func _ready() -> void:
	_run = get_parent()


func schedule(event: EventData, start_distance: float, length: float) -> void:
	var s := Scheduled.new()
	s.event = event
	s.start_distance = start_distance
	s.length = length
	_scheduled.append(s)
	_rng.seed = hash(start_distance)


## Aviso no HUD quando a personagem chegar perto de `start_distance`.
func schedule_banner(text: String, color: Color, start_distance: float) -> void:
	_banners.append([start_distance, text, color])


func scheduled_count() -> int:
	return _scheduled.size()


func _process(_delta: float) -> void:
	if _run.run_ended:
		return
	var distance: float = _run.distance_travelled()
	for i in range(_banners.size() - 1, -1, -1):
		if distance >= _banners[i][0] - WARN_AHEAD:
			_run.hud.show_banner(_banners[i][1], _banners[i][2])
			_banners.remove_at(i)
	for s in _scheduled:
		if not s.warned and distance >= s.start_distance - WARN_AHEAD:
			s.warned = true
			_warn(s)
		if not s.fired and s.event.id == &"horde" and distance >= s.start_distance + HORDE_TRIGGER_INTO:
			s.fired = true
			_spawn_horde(s)


func _warn(s: Scheduled) -> void:
	# A horda avisa só quando surge.
	if s.event.id == &"horde":
		return
	_run.hud.show_banner(s.event.banner, s.event.banner_color)
	if s.event.id == &"explosion":
		_boom(s)
	elif s.event.id == &"truck":
		_run.camera.shake(0.35)


## Explosão à frente que deixou parte da rota bloqueada e em chamas.
func _boom(s: Scheduled) -> void:
	var pos := Vector3(0, 1.5, -(s.start_distance + s.length / 2.0))
	var world: Node = _run.actors
	Fx.burst(world, pos, Color(1.0, 0.55, 0.1), 40, 10.0, 0.35)
	Fx.burst(world, pos, Color(0.2, 0.18, 0.16), 30, 7.0, 0.4)
	Fx.muzzle_flash(world, pos)
	_run.camera.shake(0.6)
	_run.add_noise(4.0, false)


## Seção 27: "um grupo de zumbis começa uma perseguição".
func _spawn_horde(s: Scheduled) -> void:
	spawn_horde_now(s.event.banner, s.event.banner_color, _rng)


## Horda à frente, já perseguindo. Também usada pelo clímax do Director.
## `size_delta`: zumbis a mais ou a menos que a horda normal (mínimo 3).
func spawn_horde_now(banner: String, color: Color, rng: RandomNumberGenerator, size_delta := 0) -> void:
	_run.hud.show_banner(banner, color)
	_run.camera.shake(0.25)
	var region: RegionData = _run.chunk_streamer.region
	var count := maxi(3, 4 + ceili(region.difficulty / 2.0) + size_delta)
	var base: float = _run.distance_travelled() + HORDE_SPAWN_AHEAD
	for i in count:
		var lane := rng.randi_range(0, 2)
		var pos := Vector3((lane - 1) * ChunkPopulator.LANE_WIDTH, 0.0, -(base + i * 2.2 + rng.randf_range(0.0, 1.5)))
		var zombie := ChunkPopulator.spawn_zombie(region, rng, _run.actors, pos)
		zombie.alert()
