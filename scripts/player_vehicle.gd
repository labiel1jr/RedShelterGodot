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
## Bicicleta: lançamentos de jornal que sobram.
var newspapers_left := 0
var _throw_cooldown := 0.0
## Na faixa do meio sem zumbi à vista, o jornal do lado alterna.
var _side_toggle := 1
## Mochila a jato: 0–100; em 100 explode.
var heat := 0.0
var _heat_warned := false
var _flame_timer := 0.0
## Ímã: a faixa do lado escolhida (-1 = ainda não) e a faixa em que ela
## estava quando escolheu. Fica a mesma até trocar de faixa.
var _magnet_side := -1
var _magnet_from_lane := -1
## Furgão: balas da metralhadora e a área que cobre as duas faixas.
var turret_ammo_left := 0
## Arrancada de moto (seção 64): sem dano no veículo até esta distância.
var protected_until := -INF
var _turret_timer := 0.0
var _bumper: Area3D
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
	newspapers_left = vehicle.newspapers
	player.vehicle_speed = vehicle.speed_multiplier
	player.jump_multiplier = vehicle.jump_multiplier
	player.lane_speed_multiplier = vehicle.lane_speed_multiplier
	player.can_slide = vehicle.can_slide
	heat = 0.0
	_heat_warned = false
	_magnet_from_lane = -1
	turret_ammo_left = vehicle.turret_ammo
	if vehicle.two_lanes:
		player.set_two_lane(true)
		_set_player_visible(false)
		_bumper = Area3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(4.6, 2.4, 3.6)
		shape.shape = box
		shape.position = Vector3(0, 1.2, -0.4)
		_bumper.add_child(shape)
		_bumper.area_entered.connect(_on_bumper_area)
		add_child(_bumper)
	if vehicle.jetpack:
		player.hold_to_fly = true
		player.max_rise_speed = vehicle.max_rise_speed
		player.ceiling = vehicle.max_height
	_visual = build_visual(vehicle)
	add_child(_visual)
	_flash_material = _visual.get_meta("material")
	# Montar sacode quem estava agarrando.
	var combat := player.get_node_or_null("Combat")
	if combat:
		for grabber in combat.grabbers.duplicate():
			if is_instance_valid(grabber):
				grabber.shove()
	AudioManager.play("pickup", -2.0, 0.7)
	Juice.punch(_visual, 0.4, 0.4)
	Fx.burst(player.get_parent(), player.global_position + Vector3.UP * 0.2, Color(0.62, 0.58, 0.52), 16, 4.0, 0.12)
	mounted_changed.emit(vehicle)
	return true


## `message`: o aviso que sobe da personagem ("PATINS QUEBRARAM"...).
func dismount(message: String) -> void:
	if not data:
		return
	var color := data.color
	data = null
	protected_until = -INF
	player.vehicle_speed = 1.0
	player.jump_multiplier = 1.0
	player.lane_speed_multiplier = 1.0
	player.can_slide = true
	player.hold_to_fly = false
	player.thrust_input = false
	player.lift = 0.0
	player.gravity_scale = 1.0
	player.ceiling = INF
	if player.two_lane:
		player.set_two_lane(false)
		_set_player_visible(true)
	if _bumper:
		_bumper.queue_free()
		_bumper = null
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
	_throw_cooldown -= delta
	time_left -= delta
	if data.noise_per_second > 0.0:
		var run_manager := get_tree().get_first_node_in_group("run_manager")
		if run_manager:
			run_manager.add_noise(data.noise_per_second * delta)
	if data.jetpack:
		_update_jetpack(delta)
		if not data:
			return
	if data.turret_ammo > 0:
		_update_turret(delta)
	if time_left <= 0.0:
		dismount("%s: ACABOU" % data.display_name.to_upper())


## Furgão: a metralhadora do teto atira sozinha no zumbi mais perto à
## frente, em qualquer das 3 faixas.
func _update_turret(delta: float) -> void:
	_turret_timer -= delta
	if _turret_timer > 0.0 or turret_ammo_left <= 0:
		return
	var best: Node3D = null
	var best_ahead := data.turret_range
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if not zombie.is_alive():
			continue
		var ahead: float = player.global_position.z - zombie.global_position.z
		if ahead < 1.0 or ahead > best_ahead or absf(zombie.global_position.x) > 4.0:
			continue
		best = zombie
		best_ahead = ahead
	if not best:
		return
	_turret_timer = data.turret_interval
	turret_ammo_left -= 1
	var from := player.global_position + Vector3(0, 2.5, -1.0)
	var world := player.get_parent()
	Fx.tracer(world, from, best.global_position + Vector3.UP * 1.3 * best.data.size)
	if turret_ammo_left % 3 == 0:
		Fx.muzzle_flash(world, from)
		AudioManager.play("shot", -10.0, 1.4, 0.05)
	best.take_hit(data.turret_damage, false, 0.4)


## Furgão: a área das duas faixas atropela, derruba obstáculos e pega loot.
func _on_bumper_area(area: Area3D) -> void:
	if not data:
		return
	if area.is_in_group("obstacle"):
		hit_obstacle(area)
	elif area.is_in_group("zombie"):
		ram_zombie(area)
	elif area.is_in_group("loot"):
		area._on_body_entered(player)


## Furgão: atravessa o obstáculo, pagando em HP. Retorna true se tratou.
func hit_obstacle(obstacle: Node3D) -> bool:
	if not data or not data.smashes_through:
		return false
	if obstacle.has_meta("smashed"):
		return true
	obstacle.set_meta("smashed", true)
	var world := player.get_parent()
	Fx.burst(world, obstacle.global_position + Vector3.UP, Color(0.5, 0.5, 0.5), 18, 6.0, 0.2)
	AudioManager.play("crash", -2.0, 0.8)
	obstacle.queue_free()
	absorb(data.wall_cost if obstacle.kind == &"wall" else data.obstacle_cost)
	return true


## Furgão: atropela o zumbi (de qualquer tipo), pagando em HP. Retorna true
## se tratou.
func ram_zombie(zombie: Node3D) -> bool:
	if not data or not data.smashes_through:
		return false
	if zombie.has_meta("rammed") or not zombie.is_alive():
		return true
	zombie.set_meta("rammed", true)
	var vehicle := data
	var cost := vehicle.ram_cost_weak
	match zombie.data.attack:
		ZombieData.Attack.EXPLODE:
			cost = vehicle.ram_cost_explosive
		ZombieData.Attack.SMASH:
			cost = vehicle.ram_cost_brute
		_:
			if zombie.data.armor > 0:
				cost = vehicle.ram_cost_armored
	if zombie.data.attack == ZombieData.Attack.EXPLODE:
		zombie.take_hit(vehicle.ram_damage, false)
	else:
		zombie.shove(vehicle.ram_damage)
	absorb(cost)
	return true


## Dentro do furgão a personagem some (o furgão a cobre).
func _set_player_visible(value: bool) -> void:
	for path in ["MeshInstance3D", "KnifePivot", "GunPivot"]:
		var node := player.get_node_or_null(path)
		if node:
			node.visible = value


## Segurar sobe e esquenta; soltar plana (gravidade menor na descida) e
## esfria. Em 100 de calor, explode.
func _update_jetpack(delta: float) -> void:
	var thrusting: bool = player.thrust_input
	player.lift = data.thrust_acceleration if thrusting else 0.0
	player.gravity_scale = data.glide_gravity if not thrusting and player.vertical_velocity < 0.0 else 1.0
	heat = clampf(heat + (data.heat_per_second if thrusting else -data.cool_per_second) * delta, 0.0, 100.0)
	if thrusting:
		_flame_timer -= delta
		if _flame_timer <= 0.0:
			_flame_timer = 0.05
			Fx.burst(player.get_parent(), player.global_position + Vector3(0, 0.8, 0.45), Color(1.0, 0.6, 0.2), 2, 1.5, 0.06)
	if heat >= 100.0:
		_explode_jetpack()
		return
	if heat >= 80.0 and not _heat_warned:
		_heat_warned = true
		Fx.float_text(player, player.global_position + Vector3.UP * 2.6, "SUPERAQUECENDO!", Color(1.0, 0.45, 0.2), 52)
		AudioManager.play("alarm", -6.0, 1.3, 0.0)
	elif heat < 60.0:
		_heat_warned = false
	_magnet(delta)


## A mochila explode: fere a personagem (sem o veículo para absorver) e
## derruba os zumbis em volta.
func _explode_jetpack() -> void:
	var vehicle := data
	var center := player.global_position + Vector3.UP
	dismount("%s EXPLODIU" % vehicle.display_name.to_upper())
	var world := player.get_parent()
	Fx.burst(world, center, Color(1.0, 0.55, 0.1), 30, 8.0, 0.25)
	Fx.muzzle_flash(world, center)
	AudioManager.play("explosion", 0.0, 1.0, 0.1, 0.1)
	var health := player.get_node_or_null("Health")
	if health:
		health.take_damage(vehicle.explosion_damage, true)
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if zombie.is_alive() and zombie.global_position.distance_to(player.global_position) <= vehicle.explosion_radius:
			zombie.take_hit(vehicle.explosion_zombie_damage, false, 2.0)
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager:
		run_manager.add_noise(8.0, false)


## Puxa o loot à frente na faixa dela e numa faixa ao lado (na faixa do meio,
## o lado com o loot mais perto). Com a mochila cheia, não puxa.
func _magnet(delta: float) -> void:
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager and run_manager.carried_weight() >= run_manager.backpack_capacity() - 0.5:
		return
	var lane: int = player.current_lane
	if lane != _magnet_from_lane:
		_magnet_from_lane = lane
		_magnet_side = 1 if lane != 1 else -1
	if _magnet_side < 0:
		var side := _side_with_nearest_loot()
		if side != 0:
			_magnet_side = 1 + side
	var side_lane := _magnet_side
	var target := player.global_position + Vector3(0, 0.4, 0)
	for loot in get_tree().get_nodes_in_group("loot"):
		var ahead: float = player.global_position.z - loot.global_position.z
		if ahead < -1.0 or ahead > data.magnet_range:
			continue
		var loot_lane := clampi(roundi(loot.global_position.x / ChunkPopulator.LANE_WIDTH) + 1, 0, 2)
		if loot_lane != lane and loot_lane != side_lane:
			continue
		loot.global_position = loot.global_position.move_toward(target, data.magnet_speed * delta)


## +1 / -1 = o lado com o loot mais perto à frente; 0 = nenhum.
func _side_with_nearest_loot() -> int:
	var best_ahead := INF
	var best_side := 0
	for loot in get_tree().get_nodes_in_group("loot"):
		var ahead: float = player.global_position.z - loot.global_position.z
		var dx: float = loot.global_position.x - player.global_position.x
		if ahead < 0.0 or ahead > data.magnet_range or absf(dx) < 1.2:
			continue
		if ahead < best_ahead:
			best_ahead = ahead
			best_side = 1 if dx > 0.0 else -1
	return best_side


## Montada, as armas da personagem não funcionam (mãos ocupadas)?
func blocks_weapons() -> bool:
	return data != null and data.disables_weapons


## Bicicleta: o toque (ou ATACAR) lança dois jornais — um na faixa dela e
## outro na do lado. Na faixa do meio, o do lado vai para onde está o zumbi
## mais perto. Retorna true se a bicicleta tratou o toque.
func throw_newspapers() -> bool:
	if not data or data.newspapers <= 0:
		return false
	if _throw_cooldown > 0.0:
		return true
	if newspapers_left <= 0:
		AudioManager.play("empty")
		Fx.float_text(player, player.global_position + Vector3.UP * 2.2, "SEM JORNAIS", data.color, 40)
		_throw_cooldown = data.newspaper_cooldown
		return true
	_throw_cooldown = data.newspaper_cooldown
	newspapers_left -= 1
	var lane: int = player.current_lane
	# Nas faixas da ponta, a única do lado é a do meio.
	var side_lane := 1 if lane != 1 else 1 + _side_with_nearest_zombie()
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	var parent: Node = run_manager.actors if run_manager else get_tree().current_scene
	for target_lane in [lane, side_lane]:
		var paper := Newspaper.new()
		paper.lane_x = (target_lane - 1) * ChunkPopulator.LANE_WIDTH
		paper.speed = data.newspaper_speed
		paper.damage = data.newspaper_damage
		paper.max_range = data.newspaper_range
		paper.knockback = data.newspaper_knockback
		parent.add_child(paper)
		paper.global_position = player.global_position + Vector3(0, 1.2, -0.6)
	AudioManager.play("swing", -4.0, 1.3)
	return true


## +1 = direita, -1 = esquerda: o lado com o zumbi mais perto à frente.
func _side_with_nearest_zombie() -> int:
	var best_ahead := INF
	var best_side := 0
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if not zombie.is_alive():
			continue
		var ahead: float = player.global_position.z - zombie.global_position.z
		if ahead < 0.0 or ahead > data.newspaper_range:
			continue
		var dx: float = zombie.global_position.x - player.global_position.x
		if absf(dx) < 1.2:
			continue
		if ahead < best_ahead:
			best_ahead = ahead
			best_side = 1 if dx > 0.0 else -1
	if best_side == 0:
		_side_toggle = -_side_toggle
		return _side_toggle
	return best_side


## Moto: combustível coletado montada dá mais tempo.
func add_fuel(units: int) -> void:
	if not data or data.fuel_time_bonus <= 0.0 or units <= 0:
		return
	var bonus := data.fuel_time_bonus * units
	time_left += bonus
	Fx.float_text(player, player.global_position + Vector3.UP * 2.6, "+%d s" % roundi(bonus), data.color, 44)


## Dano que iria para a personagem. Retorna true se o veículo absorveu.
func absorb(amount: int) -> bool:
	if not data:
		return false
	if -player.global_position.z < protected_until:
		return true
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
	# `absorb` pode desmontar (HP zerado): guarda os valores antes.
	var vehicle := data
	if vehicle.passes_weak_zombies and VehicleData.is_weak(zombie.data):
		absorb(vehicle.weak_zombie_cost)
		zombie.shove(vehicle.knock_down_damage)
		return true
	absorb(vehicle.contact_damage)
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
		&"bicicleta":
			for z in [-0.55, 0.55]:
				_box(root, Vector3(0.06, 0.62, 0.62), Vector3(0, 0.31, z), wheel_material)
			_box(root, Vector3(0.07, 0.07, 1.05), Vector3(0, 0.62, 0), material)
			_box(root, Vector3(0.07, 0.5, 0.07), Vector3(0, 0.45, -0.45), material)
			_box(root, Vector3(0.6, 0.05, 0.05), Vector3(0, 0.92, -0.5), wheel_material)
			var paper_material := StandardMaterial3D.new()
			paper_material.albedo_color = Color(0.93, 0.92, 0.86)
			_box(root, Vector3(0.4, 0.24, 0.32), Vector3(0, 0.82, -0.78), paper_material)
		&"moto":
			for z in [-0.62, 0.62]:
				_box(root, Vector3(0.2, 0.62, 0.62), Vector3(0, 0.31, z), wheel_material)
			_box(root, Vector3(0.46, 0.34, 1.3), Vector3(0, 0.55, 0), material)
			_box(root, Vector3(0.36, 0.22, 0.5), Vector3(0, 0.82, -0.25), material)
			_box(root, Vector3(0.72, 0.06, 0.06), Vector3(0, 1.0, -0.6), wheel_material)
		&"furgao":
			var metal := StandardMaterial3D.new()
			metal.albedo_color = Color(0.45, 0.47, 0.5)
			metal.metallic = 0.6
			_box(root, Vector3(4.0, 1.9, 3.2), Vector3(0, 1.35, 0.3), material)
			_box(root, Vector3(4.0, 1.3, 1.1), Vector3(0, 1.0, -1.85), material)
			_box(root, Vector3(4.2, 0.8, 0.18), Vector3(0, 0.75, -2.5), metal)
			for x in [-1.7, 1.7]:
				for z in [-1.4, 1.2]:
					_box(root, Vector3(0.4, 0.8, 0.8), Vector3(x, 0.4, z), wheel_material)
			_box(root, Vector3(0.6, 0.45, 0.7), Vector3(0, 2.5, -0.6), metal)
			_box(root, Vector3(0.14, 0.14, 1.0), Vector3(0, 2.55, -1.3), wheel_material)
		&"jetpack":
			_box(root, Vector3(0.5, 0.6, 0.28), Vector3(0, 1.25, 0.32), material)
			for x in [-0.15, 0.15]:
				_box(root, Vector3(0.14, 0.5, 0.14), Vector3(x, 1.1, 0.5), wheel_material)
			var flame := StandardMaterial3D.new()
			flame.albedo_color = Color(1.0, 0.6, 0.2)
			flame.emission_enabled = true
			flame.emission = Color(1.0, 0.5, 0.1)
			flame.emission_energy_multiplier = 1.5
			for x in [-0.15, 0.15]:
				_box(root, Vector3(0.1, 0.12, 0.1), Vector3(x, 0.8, 0.5), flame)
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
