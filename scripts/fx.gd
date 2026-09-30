class_name Fx
extends RefCounted

## Efeitos visuais simples com primitivas (Fase 3 do roadmap): partículas de
## impacto, rastro de tiro, clarão de disparo e textos flutuantes.
## CPUParticles3D em vez de GPU para rodar bem em celulares intermediários.
## Seção 51 (object pooling): os estouros de partículas são reaproveitados
## e os meshes/materiais ficam em cache por cor e tamanho.

const BLOOD_COLOR := Color(0.45, 0.05, 0.05)
const MAX_POOLED_BURSTS := 24

static var _burst_pool: Array[CPUParticles3D] = []
static var _mesh_cache := {}


static func _particle_mesh(color: Color, size: float) -> BoxMesh:
	var key := [color, size]
	if not _mesh_cache.has(key):
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE * size
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mesh.material = mat
		_mesh_cache[key] = mesh
	return _mesh_cache[key]


## Um CPUParticles3D parado para reusar, ou um novo (até o limite do pool).
static func _take_burst(parent: Node) -> CPUParticles3D:
	_burst_pool = _burst_pool.filter(func(p): return is_instance_valid(p))
	for p in _burst_pool:
		if not p.emitting and p.get_parent() == parent:
			return p
	var created := CPUParticles3D.new()
	created.one_shot = true
	created.explosiveness = 1.0
	created.lifetime = 0.55
	created.direction = Vector3.UP
	created.spread = 70.0
	created.gravity = Vector3(0, -12, 0)
	created.scale_amount_min = 0.6
	created.scale_amount_max = 1.2
	parent.add_child(created)
	if _burst_pool.size() < MAX_POOLED_BURSTS:
		_burst_pool.append(created)
	else:
		created.finished.connect(created.queue_free)
	return created


## Estouro de partículas (sangue, destroços, coleta). Some sozinho.
static func burst(parent: Node, pos: Vector3, color: Color, amount := 14, speed := 4.0, size := 0.12) -> void:
	var p := _take_burst(parent)
	p.amount = amount
	p.initial_velocity_min = speed * 0.6
	p.initial_velocity_max = speed
	p.mesh = _particle_mesh(color, size)
	p.global_position = pos
	p.restart()


## Rastro do tiro: uma haste fina entre a arma e o ponto de impacto.
static func tracer(parent: Node, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.01:
		return
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, length)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.9, 0.5, 0.9)
	mesh.material = mat
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	parent.add_child(mi)
	mi.global_position = (from + to) / 2.0
	mi.look_at(to, Vector3.UP)

	var tween := mi.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.12)
	tween.tween_callback(mi.queue_free)


## Clarão curto de disparo.
static func muzzle_flash(parent: Node, pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.4)
	light.light_energy = 3.0
	light.omni_range = 4.0
	parent.add_child(light)
	light.global_position = pos

	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.06)
	tween.tween_callback(light.queue_free)


## Texto que sobe e some (dano, loot). Filho de `anchor` para acompanhar a
## corrida em vez de ficar parado no mundo.
static func float_text(anchor: Node3D, world_pos: Vector3, text: String, color := Color.WHITE, font_size := 56) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.01
	label.font_size = font_size
	label.outline_size = 14
	label.modulate = color

	anchor.add_child(label)
	label.global_position = world_pos

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y + 1.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.2)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.4).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)
