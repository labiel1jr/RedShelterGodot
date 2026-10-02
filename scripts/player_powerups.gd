class_name PlayerPowerUps
extends Node

## Seção 64 do GDD: os power-ups ativos da personagem (nó "PowerUps" da
## Player). Os temporizados somam tempo se pegar o mesmo de novo; no máximo
## `powerup_max_active` ao mesmo tempo (o mais perto de acabar sai). O
## Escudo de caçamba vem do abrigo e é erguido com toque duplo, Q ou o botão.

signal changed

## id → segundos restantes.
var active := {}
var shield_charges := 0
var shields_used := 0
var shield_armed := false
## Onde o sinalizador está aceso (só vale enquanto ativo).
var flare_position := Vector3.ZERO

var _flare_node: Node3D
## Rota dos telhados: o telhado (visual) com o loot em cima.
var _roof: Node3D
## Rampa de entulho: segundos de salto que faltam.
var _ramp_left := 0.0

@onready var player: CharacterBody3D = get_parent()


static func level_of(id: StringName) -> int:
	return int(GameManager.powerup_levels.get(id, 1))


func data(id: StringName) -> PowerUpData:
	return GameManager.WORLD.powerup(id)


func is_active(id: StringName) -> bool:
	return active.has(id)


## A rota dos telhados não funciona montada; a rampa, nem no furgão nem na
## mochila a jato.
func can_activate(power: PowerUpData) -> bool:
	var vehicle := player.get_node_or_null("Vehicle")
	if not vehicle or not vehicle.is_mounted():
		return true
	if power.roof_height > 0.0:
		return false
	if power.ramp_distance > 0.0:
		return not (vehicle.data.two_lanes or vehicle.data.jetpack)
	return true


func is_ramping() -> bool:
	return _ramp_left > 0.0


func activate(power: PowerUpData) -> void:
	if not can_activate(power):
		return
	# Instantâneo: o salto da rampa não ocupa vaga de ativo.
	if power.ramp_distance > 0.0:
		_start_ramp(power)
		AudioManager.play("pickup", -2.0, 1.4)
		Fx.float_text(player, player.global_position + Vector3.UP * 2.4, "%s!" % power.display_name.to_upper(), power.color, 52)
		changed.emit()
		return
	# A rota dos telhados cancela os outros.
	if power.roof_height > 0.0:
		for id in active.keys():
			if id != power.id:
				_end(id)
	elif active.has(&"telhados"):
		return
	var seconds := power.duration(level_of(power.id))
	if active.has(power.id):
		active[power.id] += seconds
	else:
		# Por uma variável: ler direto da constante WORLD fixa o valor na compilação.
		var world: WorldData = GameManager.WORLD
		if active.size() >= world.powerup_max_active:
			var shortest: StringName = active.keys()[0]
			for id in active:
				if active[id] < active[shortest]:
					shortest = id
			_end(shortest)
		active[power.id] = seconds
		_start(power)
	AudioManager.play("pickup", -2.0, 1.4)
	Fx.float_text(player, player.global_position + Vector3.UP * 2.4, "%s!" % power.display_name.to_upper(), power.color, 52)
	changed.emit()


func _start(power: PowerUpData) -> void:
	if power.roof_height > 0.0:
		_start_rooftop(power, power.duration(level_of(power.id)))
	if power.flare_radius > 0.0:
		flare_position = player.global_position
		_flare_node = _make_flare(power.color)
		var run_manager := get_tree().get_first_node_in_group("run_manager")
		var parent: Node = run_manager.actors if run_manager else player.get_parent()
		parent.add_child(_flare_node)
		_flare_node.global_position = flare_position
		# Quem já estava agarrando solta e vai atrás da luz.
		var combat := player.get_node_or_null("Combat")
		if combat:
			for grabber in combat.grabbers.duplicate():
				if is_instance_valid(grabber):
					grabber.shove()


func _end(id: StringName) -> void:
	active.erase(id)
	if id == &"telhados":
		_end_rooftop()
	if id == &"sinalizador" and _flare_node:
		_flare_node.queue_free()
		_flare_node = null
	changed.emit()


func _process(delta: float) -> void:
	for id in active.keys():
		active[id] -= delta
		if active[id] <= 0.0:
			_end(id)
	if active.has(&"ima"):
		_magnet(data(&"ima"), delta)
	if active.has(&"telhados"):
		# Desce antes da extração (o portão fica no chão).
		var run_manager := get_tree().get_first_node_in_group("run_manager")
		if run_manager and run_manager.distance_travelled() > run_manager.extraction_distance - 40.0:
			_end(&"telhados")
	if _ramp_left > 0.0:
		_ramp_left -= delta
		if _ramp_left <= 0.0:
			player.ramp_gravity_scale = 0.0
			var health := player.get_node_or_null("Health")
			if health:
				health.make_invulnerable(0.5)


# -------------------------------------------------------- rota dos telhados

## Sobe para o telhado: um telhado comprido à frente (visual, sem colisão),
## com uma linha de munição e componentes em cada faixa. Lá em cima não há
## zumbis nem obstáculos (ficam no chão).
func _start_rooftop(power: PowerUpData, seconds: float) -> void:
	player.rooftop_height = power.roof_height
	var combat := player.get_node_or_null("Combat")
	if combat:
		for grabber in combat.grabbers.duplicate():
			if is_instance_valid(grabber):
				grabber.shove()
	var speed: float = player.forward_speed * player.vehicle_speed
	var length := speed * seconds * 1.3 + 30.0
	var start_z := player.global_position.z
	_roof = Node3D.new()
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	var parent: Node = run_manager.actors if run_manager else player.get_parent()
	parent.add_child(_roof)
	_roof.global_position = Vector3(0, power.roof_height, start_z)
	var roof_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(8.0, 0.4, length)
	roof_mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.36, 0.38, 0.42)
	roof_mesh.material_override = material
	roof_mesh.position = Vector3(0, -0.2, -length / 2.0 + 6.0)
	_roof.add_child(roof_mesh)
	var loot_scene: PackedScene = load("res://scenes/obstacles/loot.tscn")
	var z := 10.0
	var i := 0
	while z < length - 10.0:
		var lane := i % 3
		var loot: Node3D = loot_scene.instantiate()
		# Uma fileira em cada três é de componentes; o resto, munição.
		loot.loot_type = 4 if (i / 3) % 3 == 2 else 3
		loot.amount = 3 if loot.loot_type == 3 else 1
		_roof.add_child(loot)
		loot.position = Vector3((lane - 1) * ChunkPopulator.LANE_WIDTH, 0.0, -z)
		z += power.roof_loot_spacing / 3.0
		i += 1


## Desce numa faixa livre (sem obstáculo nem zumbi perto do ponto de queda),
## com um instante sem dano ao chegar.
func _end_rooftop() -> void:
	if player.rooftop_height < 0.0:
		return
	player.rooftop_height = -1.0
	var land_z := player.global_position.z - 6.0
	var best_lane: int = player.current_lane
	var best_score := INF
	for lane in 3:
		var score := absf(lane - player.current_lane) * 0.5
		var x := (lane - 1) * ChunkPopulator.LANE_WIDTH
		for node in get_tree().get_nodes_in_group("obstacle") + get_tree().get_nodes_in_group("zombie"):
			if absf(node.global_position.x - x) < 1.3 and absf(node.global_position.z - land_z) < 8.0:
				score += 10.0
		if score < best_score:
			best_score = score
			best_lane = lane
	if not player.two_lane:
		player.current_lane = best_lane
		player.target_x = (best_lane - 1) * ChunkPopulator.LANE_WIDTH
	var health := player.get_node_or_null("Health")
	if health:
		health.make_invulnerable(1.5)
	if _roof:
		var roof := _roof
		_roof = null
		get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(roof): roof.queue_free())


# ------------------------------------------------------- rampa de entulho

## Salto longo: dura `ramp_distance / velocidade` segundos com pico em
## `ramp_height`, com a gravidade ajustada para isso.
func _start_ramp(power: PowerUpData) -> void:
	var speed: float = maxf(4.0, player.forward_speed * player.vehicle_speed * player.speed_multiplier)
	var airtime := power.ramp_distance / speed
	var gravity := 8.0 * power.ramp_height / (airtime * airtime)
	player.ramp_gravity_scale = gravity / -player.GRAVITY
	player.vertical_velocity = sqrt(2.0 * gravity * power.ramp_height)
	_ramp_left = airtime
	var combat := player.get_node_or_null("Combat")
	if combat:
		for grabber in combat.grabbers.duplicate():
			if is_instance_valid(grabber):
				grabber.shove()
	Fx.burst(player.get_parent(), player.global_position, power.color, 14, 4.0, 0.15)


## Ímã de sucata: puxa o loot à frente nas 3 faixas; com a mochila cheia, não.
func _magnet(power: PowerUpData, delta: float) -> void:
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager and run_manager.carried_weight() >= run_manager.backpack_capacity() - 0.5:
		return
	var target := player.global_position + Vector3(0, 0.4, 0)
	for loot in get_tree().get_nodes_in_group("loot"):
		var ahead: float = player.global_position.z - loot.global_position.z
		if ahead < -1.0 or ahead > power.magnet_range:
			continue
		loot.global_position = loot.global_position.move_toward(target, power.magnet_speed * delta)


## Sinalizador: este zumbi vai atrás da luz (e não agarra)?
func lures(zombie: Node3D) -> bool:
	if not active.has(&"sinalizador"):
		return false
	return zombie.global_position.distance_to(player.global_position) <= data(&"sinalizador").flare_radius


# ------------------------------------------------------------------ escudo

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		arm_shield()


## Ergue um escudo (se tiver e nenhum estiver erguido).
func arm_shield() -> bool:
	if shield_armed or shield_charges <= 0:
		return false
	shield_charges -= 1
	shields_used += 1
	shield_armed = true
	var shield := data(&"escudo")
	AudioManager.play("pickup", -2.0, 0.6)
	Fx.float_text(player, player.global_position + Vector3.UP * 2.4, "ESCUDO!", shield.color, 52)
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager and Settings.should_show_hint(&"powerup_escudo"):
		run_manager.hud.show_hint(shield.hint)
	changed.emit()
	return true


## O escudo segura um golpe: retorna true se segurou (e quebrou).
func block_hit() -> bool:
	if not shield_armed:
		return false
	_break_shield()
	return true


## O escudo segura um agarrão: o zumbi é empurrado e não agarra.
func block_grab(zombie: Node3D) -> bool:
	if not shield_armed:
		return false
	_break_shield()
	zombie.shove()
	return true


func _break_shield() -> void:
	shield_armed = false
	var shield := data(&"escudo")
	var level := level_of(shield.id)
	var world := player.get_parent()
	Fx.burst(world, player.global_position + Vector3.UP, shield.color, 16, 5.0, 0.15)
	AudioManager.play("crash", -2.0, 1.2)
	if level >= shield.push_from_level:
		for zombie in get_tree().get_nodes_in_group("zombie"):
			if zombie.is_alive() and absf(zombie.global_position.x - player.global_position.x) < 1.3 \
					and absf(zombie.global_position.z - player.global_position.z) < 6.0:
				zombie.shove(shield.push_damage)
	if level >= shield.invulnerable_from_level:
		var health := player.get_node_or_null("Health")
		if health:
			health.make_invulnerable(shield.invulnerability)
	changed.emit()


## Brilho do sinalizador aceso no chão.
func _make_flare(color: Color) -> Node3D:
	var root := Node3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.18, 0.18, 0.5)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	mesh.material_override = material
	mesh.position.y = 0.15
	root.add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 3.0
	light.omni_range = 9.0
	light.position.y = 1.0
	root.add_child(light)
	return root
