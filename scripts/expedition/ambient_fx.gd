class_name AmbientFx
extends Node3D

## Ambiente da expedição (seção 66 do GDD, J3): papéis voando, fumaça ao
## longe, lâmpada piscando na calçada e chuva leve em algumas expedições.
## Tudo segue a personagem e usa poucas partículas (celular).

## Chance de chover numa expedição (sorteada pela seed: a mesma seed
## repete o tempo).
static var rain_chance := 0.25
const PAPER_COLOR := Color(0.9, 0.87, 0.78)
const SMOKE_COLOR := Color(0.22, 0.21, 0.25)

var raining := false
var _player: Node3D
var _papers: CPUParticles3D
var _rain: CPUParticles3D
var _smokes: Array[CPUParticles3D] = []
var _lamp: OmniLight3D
var _lamp_time := 0.0
var _rng := RandomNumberGenerator.new()


## `sun`: a luz do sol, mais fraca quando chove.
func setup(player: Node3D, expedition_seed: int, sun: DirectionalLight3D) -> void:
	_player = player
	_rng.seed = expedition_seed ^ 0x5EED
	raining = _rng.randf() < rain_chance
	if raining and sun:
		sun.light_energy *= 0.6


func _ready() -> void:
	_papers = _particles(6, 6.0, _quad(Vector2(0.28, 0.2), PAPER_COLOR))
	_papers.emission_box_extents = Vector3(7.0, 0.3, 18.0)
	_papers.direction = Vector3(1, 0.4, 0)
	_papers.spread = 40.0
	_papers.initial_velocity_min = 1.0
	_papers.initial_velocity_max = 2.5
	_papers.gravity = Vector3(0, -0.25, 0)
	_papers.angular_velocity_min = -180.0
	_papers.angular_velocity_max = 180.0

	for side in [-1.0, 1.0]:
		var smoke := _particles(14, 7.0, _box(1.6, SMOKE_COLOR))
		smoke.emission_box_extents = Vector3(0.8, 0.2, 0.8)
		smoke.direction = Vector3(0.2, 1, 0)
		smoke.spread = 10.0
		smoke.initial_velocity_min = 1.2
		smoke.initial_velocity_max = 2.0
		smoke.gravity = Vector3(0.3, 0.4, 0)
		smoke.scale_amount_min = 0.8
		smoke.scale_amount_max = 2.2
		smoke.set_meta(&"side", side)
		_smokes.append(smoke)

	_lamp = OmniLight3D.new()
	_lamp.light_color = Color(1.0, 0.82, 0.5)
	_lamp.omni_range = 7.0
	_lamp.shadow_enabled = false
	add_child(_lamp)
	_place_lamp()

	if raining:
		var drop := _box(1.0, Color(0.7, 0.8, 1.0, 0.45))
		(drop as BoxMesh).size = Vector3(0.025, 0.6, 0.025)
		_rain = _particles(220, 0.9, drop)
		_rain.emission_box_extents = Vector3(12.0, 0.5, 16.0)
		_rain.direction = Vector3(0.1, -1, 0)
		_rain.spread = 2.0
		_rain.initial_velocity_min = 16.0
		_rain.initial_velocity_max = 20.0
		_rain.gravity = Vector3.ZERO


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var p := _player.global_position
	_papers.global_position = Vector3(0, 0.6, p.z - 14.0)
	if _rain:
		_rain.global_position = Vector3(p.x, p.y + 12.0, p.z - 8.0)
	for smoke in _smokes:
		# Coluna fixa no mundo, longe da pista; quando fica para trás, vai
		# para a frente de novo.
		if not smoke.has_meta(&"z") or smoke.get_meta(&"z") > p.z + 10.0:
			smoke.set_meta(&"z", p.z - _rng.randf_range(70.0, 110.0))
			smoke.global_position = Vector3(smoke.get_meta(&"side") * _rng.randf_range(16.0, 28.0), 6.0, smoke.get_meta(&"z"))
	if _lamp.global_position.z > p.z + 6.0:
		_place_lamp()
	# Piscar de lâmpada com defeito: quase sempre acesa, com apagões curtos.
	_lamp_time -= delta
	if _lamp_time <= 0.0:
		var off := _lamp.light_energy > 0.1
		_lamp.light_energy = 0.0 if off else _rng.randf_range(1.6, 2.4)
		_lamp_time = _rng.randf_range(0.04, 0.15) if off else _rng.randf_range(0.2, 1.8)


func _place_lamp() -> void:
	var z := (_player.global_position.z if is_instance_valid(_player) else 0.0) - _rng.randf_range(35.0, 60.0)
	_lamp.global_position = Vector3((-1.0 if _rng.randf() < 0.5 else 1.0) * 5.2, 4.2, z)


func _particles(amount: int, lifetime: float, mesh: Mesh) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.mesh = mesh
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.preprocess = lifetime
	add_child(p)
	return p


func _box(size: float, color: Color) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * size
	mesh.material = _material(color)
	return mesh


func _quad(size: Vector2, color: Color) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = size
	var material := _material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = material
	return mesh


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
