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

@onready var player: CharacterBody3D = get_parent()


static func level_of(id: StringName) -> int:
	return int(GameManager.powerup_levels.get(id, 1))


func data(id: StringName) -> PowerUpData:
	return GameManager.WORLD.powerup(id)


func is_active(id: StringName) -> bool:
	return active.has(id)


func activate(power: PowerUpData) -> void:
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
