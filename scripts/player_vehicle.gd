class_name PlayerVehicle
extends Node3D

## Seção 63 do GDD: o veículo em que a personagem está montada. Fica como
## filho da Player (nó "Vehicle"). Montada, todo dano vai para o HP do
## veículo (PlayerHealth pergunta aqui antes); quando o HP ou o tempo acaba,
## ela cai na faixa sem dano e fica um instante invulnerável.

## `data` é null ao desmontar.
signal mounted_changed(data: VehicleData)

var data: VehicleData = null
var hp := 0
var time_left := 0.0
var _visual: Node3D
var _flash_material: StandardMaterial3D

@onready var player: CharacterBody3D = get_parent()


func is_mounted() -> bool:
	return data != null


## Monta no veículo; não troca se já estiver em outro.
func mount(vehicle: VehicleData) -> bool:
	if data:
		return false
	data = vehicle
	hp = vehicle.max_hp
	time_left = vehicle.duration
	player.vehicle_speed = vehicle.speed_multiplier
	player.jump_multiplier = vehicle.jump_multiplier
	player.lane_speed_multiplier = vehicle.lane_speed_multiplier
	player.can_slide = vehicle.can_slide
	_visual = build_visual(vehicle)
	add_child(_visual)
	_flash_material = _visual.get_meta("material")
	AudioManager.play("pickup", -2.0, 0.7)
	mounted_changed.emit(vehicle)
	return true


## `message`: o aviso que sobe da personagem ("PATINS QUEBRARAM"...).
func dismount(message: String) -> void:
	if not data:
		return
	var color := data.color
	data = null
	player.vehicle_speed = 1.0
	player.jump_multiplier = 1.0
	player.lane_speed_multiplier = 1.0
	player.can_slide = true
	if _visual:
		_visual.queue_free()
		_visual = null
	var health := player.get_node_or_null("Health")
	if health:
		health.make_invulnerable(GameManager.WORLD.vehicle_dismount_invulnerability)
	var pos := player.global_position + Vector3.UP * 0.3
	Fx.burst(player.get_parent(), pos, color, 14, 4.0, 0.12)
	Fx.float_text(player, pos + Vector3.UP * 2.0, message, color, 52)
	AudioManager.play("crash", -4.0, 1.3)
	mounted_changed.emit(null)


func _process(delta: float) -> void:
	if not data:
		return
	time_left -= delta
	if data.noise_per_second > 0.0:
		var run_manager := get_tree().get_first_node_in_group("run_manager")
		if run_manager:
			run_manager.add_noise(data.noise_per_second * delta)
	if time_left <= 0.0:
		dismount("%s: ACABOU" % data.display_name.to_upper())


## Dano que iria para a personagem. Retorna true se o veículo absorveu.
func absorb(amount: int) -> bool:
	if not data:
		return false
	hp -= amount
	if _flash_material:
		_flash_material.emission_energy_multiplier = 2.5
		var tween := create_tween()
		tween.tween_property(_flash_material, "emission_energy_multiplier", 0.3, 0.2)
	if hp <= 0:
		dismount("%s QUEBROU" % data.display_name.to_upper())
	return true


## Um zumbi que agarra encostou. Retorna true se o veículo resolveu o
## encontro (e o zumbi não agarra).
func on_grabber_contact(zombie: Node3D) -> bool:
	if not data:
		return false
	if data.grab_breaks:
		# Patins: o agarrão derruba e quebra; o zumbi agarra normalmente.
		dismount("%s QUEBROU" % data.display_name.to_upper())
		return false
	if data.passes_weak_zombies and VehicleData.is_weak(zombie.data):
		absorb(data.weak_zombie_cost)
		zombie.shove(data.knock_down_damage)
		return true
	absorb(data.contact_damage)
	zombie.shove()
	return true


## Golpe do Bruto. Retorna true se o veículo resolveu (o skate quebra).
func on_smash() -> bool:
	if not data or not data.smash_breaks:
		return false
	dismount("%s QUEBROU" % data.display_name.to_upper())
	return true


## Visual com primitivas, nos pés da personagem (origem no chão). Também
## usado no veículo estacionado.
static func build_visual(vehicle: VehicleData) -> Node3D:
	var root := Node3D.new()
	root.name = "VehicleVisual"
	var material := StandardMaterial3D.new()
	material.albedo_color = vehicle.color
	material.emission_enabled = true
	material.emission = vehicle.color
	material.emission_energy_multiplier = 0.3
	var wheel_material := StandardMaterial3D.new()
	wheel_material.albedo_color = Color(0.12, 0.12, 0.13)
	root.set_meta("material", material)
	match vehicle.id:
		&"patins":
			for side in [-1.0, 1.0]:
				_box(root, Vector3(0.18, 0.14, 0.42), Vector3(side * 0.2, 0.13, 0.0), material)
				for z in [-0.14, 0.0, 0.14]:
					_box(root, Vector3(0.08, 0.08, 0.08), Vector3(side * 0.2, 0.04, z), wheel_material)
		&"skate":
			_box(root, Vector3(0.42, 0.05, 1.05), Vector3(0, 0.12, 0), material)
			for x in [-0.15, 0.15]:
				for z in [-0.34, 0.34]:
					_box(root, Vector3(0.08, 0.08, 0.08), Vector3(x, 0.04, z), wheel_material)
		_:
			_box(root, Vector3(0.6, 0.3, 1.0), Vector3(0, 0.15, 0), material)
	return root


static func _box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)
