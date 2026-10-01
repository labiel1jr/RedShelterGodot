class_name Newspaper
extends Node3D

## Jornal lançado da bicicleta de jornaleiro (seção 63 do GDD): voa pela
## faixa como um projétil e acerta o primeiro zumbi dela.

var lane_x := 0.0
var speed := 30.0
var damage := 50
var max_range := 22.0
var knockback := 1.2

var _travelled := 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.36, 0.08, 0.26)
	_mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.93, 0.92, 0.86)
	_mesh.material_override = material
	add_child(_mesh)


func _process(delta: float) -> void:
	var step := speed * delta
	global_position.z -= step
	global_position.x = move_toward(global_position.x, lane_x, 25.0 * delta)
	_travelled += step
	_mesh.rotate_y(14.0 * delta)
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if not zombie.is_alive():
			continue
		if absf(zombie.global_position.x - global_position.x) < 1.1 and absf(zombie.global_position.z - global_position.z) < 1.0:
			zombie.take_hit(damage, false, knockback)
			AudioManager.play("hit", -6.0, 1.4)
			Fx.burst(get_parent(), global_position, Color(0.93, 0.92, 0.86), 8, 3.0, 0.08)
			queue_free()
			return
	if _travelled >= max_range:
		queue_free()
