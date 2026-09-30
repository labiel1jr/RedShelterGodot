extends Camera3D

## Câmera terceira pessoa, atrás e levemente elevada (seção 4 do GDD).
## Treme quando a personagem leva dano, proporcional ao golpe.

@export var target_path: NodePath
@export var offset := Vector3(0, 4.0, 6.0)
@export var follow_speed := 10.0
@export var look_ahead := 4.0
## Deslocamento máximo (m) do tremor com trauma = 1.
@export var max_shake := 0.35
@export var shake_decay := 1.8

var target: Node3D
var _trauma := 0.0
var _last_hp := -1


func _ready() -> void:
	if target_path != NodePath():
		target = get_node(target_path)
	else:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]

	var health: Node = target.get_node_or_null("Health") if target else null
	if health:
		_last_hp = health.current_hp
		health.health_changed.connect(_on_health_changed)


func _process(delta: float) -> void:
	if not target:
		return

	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, follow_speed * delta)
	look_at(target.global_position + Vector3(0, 1.0, -look_ahead), Vector3.UP)

	# h_offset/v_offset deslocam a imagem sem mexer no acompanhamento.
	_trauma = maxf(0.0, _trauma - shake_decay * delta)
	var amount := _trauma * _trauma * max_shake
	h_offset = randf_range(-1.0, 1.0) * amount
	v_offset = randf_range(-1.0, 1.0) * amount


func shake(trauma: float) -> void:
	if not Settings.camera_shake:
		return
	_trauma = minf(1.0, _trauma + trauma)


func _on_health_changed(current: int, max_hp: int) -> void:
	if current < _last_hp:
		# 15 de dano (obstáculo) ≈ tremor forte; 1 HP do agarrão ≈ tremidinha.
		shake(clampf(float(_last_hp - current) / 25.0, 0.08, 0.8))
	_last_hp = current
