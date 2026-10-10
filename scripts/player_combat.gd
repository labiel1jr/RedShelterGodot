extends Node

## Combate da personagem, sem tela ou modo separado — ela continua correndo.
## Faca (seções 10, 11, 14 e 15 do GDD): ataque de emergência; atinge
## primeiro quem está agarrando, senão o zumbi mais próximo à frente.
## Arma de fogo (seções 34 e 35): mira automática no zumbi mais próximo à
## frente na faixa; gasta munição e faz ruído. A escopeta espalha chumbos
## pela faixa e pelas vizinhas; a SMG dispara em rajada.

signal grab_changed(is_grabbed: bool)
signal ammo_changed(ammo: int)
signal knife_durability_changed(current: int, max_durability: int)

## Dano do golpe com a faca quebrada (seção 16): sobra o soco.
const BROKEN_DAMAGE := 10

## Arma branca equipada (faca, facão, machado...).
## Armas na mão aparecem maiores que o tamanho real do catálogo, para serem
## lidas na câmera da corrida (a faca de 0,35 m fica com ~0,55 m, como a
## forma provisória).
const HELD_MODEL_SCALE := 1.6

@export var weapon: WeaponData
## Arma de fogo equipada (pistola, escopeta ou SMG).
@export var pistol: RangedWeaponData
## Velocidade da corrida enquanto há zumbi agarrado (1.0 = normal).
@export var grabbed_speed_multiplier := 0.7
## Largura (em X) em que um zumbi à frente conta como alvo.
@export var target_half_width := 1.3

## Modificadores da progressão (seções 42 e 43), definidos pela Run.
var melee_damage_multiplier := 1.0
var crit_bonus := 0.0
var cooldown_multiplier := 1.0

var grabbers: Array[Node3D] = []
var ammo := 0
var knife_durability := 0
var _combo_step := 0
var _time_since_attack := 999.0
var _time_since_shot := 999.0
var _swing_side := 1.0
var _bursting := false

@onready var player: CharacterBody3D = get_parent()
@onready var knife_pivot: Node3D = get_parent().get_node("KnifePivot")
@onready var gun_pivot: Node3D = get_parent().get_node("GunPivot")
@onready var muzzle: Node3D = get_parent().get_node("GunPivot/Muzzle")


func _ready() -> void:
	player.tapped.connect(shoot)


func _process(delta: float) -> void:
	_time_since_attack += delta
	_time_since_shot += delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F, KEY_J:
				attack()
			KEY_K, KEY_ENTER:
				shoot()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Toques também geram cliques emulados; esses já viram tiro pelo sinal
		# `tapped` do controlador.
		if event.device != InputEvent.DEVICE_ID_EMULATION:
			shoot()


func is_grabbed() -> bool:
	return not grabbers.is_empty()


func set_ammo(value: int) -> void:
	ammo = maxi(0, value)
	ammo_changed.emit(ammo)


func set_knife_durability(value: int) -> void:
	knife_durability = clampi(value, 0, weapon.max_durability)
	knife_durability_changed.emit(knife_durability, weapon.max_durability)


func is_knife_broken() -> bool:
	return knife_durability <= 0


## Seção 63: montada, o veículo pode tomar o lugar das armas.
func _vehicle_takes_input() -> bool:
	var vehicle := player.get_node_or_null("Vehicle")
	if not vehicle or not vehicle.is_mounted():
		return false
	return vehicle.throw_newspapers() or vehicle.blocks_weapons()


func attack() -> void:
	if _vehicle_takes_input():
		return
	if _time_since_attack < melee_cooldown():
		return
	if _time_since_attack > weapon.combo_window:
		_combo_step = 0
	_time_since_attack = 0.0

	var damage := BROKEN_DAMAGE
	var is_crit := false
	if not is_knife_broken():
		damage = int(round(weapon.combo_damage[_combo_step] * melee_damage_multiplier))
		is_crit = randf() < weapon.crit_chance + crit_bonus
		if is_crit:
			damage = int(round(damage * weapon.crit_multiplier))
		_combo_step = (_combo_step + 1) % weapon.combo_damage.size()

	_play_swing()
	AudioManager.play("swing", -6.0)

	var target := _find_melee_target()
	if not target:
		return
	target.take_hit(damage, is_crit)
	AudioManager.play("hit", -2.0, 1.25 if is_crit else 1.0)
	Juice.hit_stop(0.07 if is_crit else 0.045)
	if is_crit:
		Juice.slow_motion(0.35, 0.15)
		Juice.shake(Juice.SHAKE_LIGHT)

	# Seção 16: cada golpe que acerta gasta durabilidade.
	if not is_knife_broken():
		set_knife_durability(knife_durability - 1)
		if is_knife_broken():
			AudioManager.play("crash", -4.0, 1.4)
			Fx.float_text(player, player.global_position + Vector3.UP * 2.6, "ARMA QUEBRADA", Color(1, 0.35, 0.25), 60)


## Intervalo entre golpes da arma branca; a Adrenalina (seção 64) encurta.
func melee_cooldown() -> float:
	var bonus := 0.0
	var powerups := player.get_node_or_null("PowerUps")
	if powerups and powerups.is_active(&"adrenalina"):
		bonus = powerups.data(&"adrenalina").attack_speed_bonus
	return weapon.attack_cooldown * cooldown_multiplier * (1.0 - bonus)


func shoot() -> void:
	if _vehicle_takes_input():
		return
	if _bursting or _time_since_shot < pistol.fire_cooldown * cooldown_multiplier:
		return
	_time_since_shot = 0.0

	if ammo <= 0:
		AudioManager.play("empty")
		Fx.float_text(player, muzzle.global_position + Vector3.UP * 0.6, "SEM MUNIÇÃO", Color(1, 0.4, 0.3), 40)
		return

	# Seção 34: o ruído conta por disparo (a rajada inteira da SMG é um).
	var run_manager := get_tree().get_first_node_in_group("run_manager")
	if run_manager:
		run_manager.add_noise(pistol.noise)

	if pistol.burst <= 1:
		_fire_once()
		return
	_bursting = true
	for i in pistol.burst:
		if ammo <= 0 or not is_inside_tree():
			break
		_fire_once()
		await get_tree().create_timer(pistol.burst_interval, false).timeout
	_bursting = false
	_time_since_shot = 0.0


## Um tiro (ou um disparo de escopeta): gasta 1 de munição.
func _fire_once() -> void:
	set_ammo(ammo - 1)
	AudioManager.play("shot", -3.0 if pistol.pellets <= 1 else 0.0, 0.75 if pistol.pellets > 1 else (1.15 if pistol.burst > 1 else 1.0), 0.05)
	var from := muzzle.global_position
	var world := get_tree().current_scene

	if pistol.pellets > 1:
		_fire_spread(from, world)
	else:
		var target := _find_ranged_target()
		var to := from + Vector3(0, 0, -pistol.fire_range)
		if target:
			to = target.global_position + Vector3.UP * 1.3 * target.data.size
			_hit(target, pistol.damage, player.global_position.z - target.global_position.z)
		Fx.tracer(world, from, to)
	Fx.muzzle_flash(world, from)
	Fx.burst(world, from + Vector3(0.25, 0.1, 0.3), Color(0.85, 0.68, 0.3), 1, 3.0, 0.05)
	_play_recoil()


## Escopeta: os chumbos se dividem entre os zumbis no cone (a faixa e as
## vizinhas); quem está sozinho no cone leva quase tudo. Perde força com a
## distância.
func _fire_spread(from: Vector3, world: Node) -> void:
	var half_width := target_half_width + pistol.spread_lanes * ChunkPopulator.LANE_WIDTH
	var targets: Array[Node3D] = []
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if not zombie.is_alive() or zombie in grabbers:
			continue
		var ahead: float = player.global_position.z - zombie.global_position.z
		if ahead < -0.5 or ahead > pistol.fire_range:
			continue
		if absf(zombie.global_position.x - player.global_position.x) > half_width:
			continue
		targets.append(zombie)
	for i in 3:
		var x := (i - 1) * 0.9
		Fx.tracer(world, from, from + Vector3(x * 2.0, 0, -minf(pistol.fire_range, 10.0)))
	if targets.is_empty():
		return
	var per_target := maxi(2, ceili(float(pistol.pellets) / targets.size()))
	for target in targets:
		var ahead: float = player.global_position.z - target.global_position.z
		_hit(target, pistol.damage * per_target, ahead)


func _hit(target: Node3D, base_damage: int, ahead: float) -> void:
	var falloff := lerpf(1.0, pistol.range_falloff, clampf(ahead / pistol.fire_range, 0.0, 1.0))
	var damage := int(round(base_damage * falloff))
	var is_crit := randf() < pistol.crit_chance + crit_bonus
	if is_crit:
		damage = int(round(damage * pistol.crit_multiplier))
	target.take_hit(damage, is_crit, pistol.knockback)
	if not target.is_alive():
		AudioManager.play("hit", -4.0, 0.6, 0.0)


## Tamanho e cor das armas na mão conforme as equipadas.
func apply_visuals() -> void:
	var knife_mesh: MeshInstance3D = knife_pivot.get_node("Knife")
	# Modelo do artista (Fase 15 / A2), com o pivô no cabo e a lâmina para -Z.
	var model := knife_pivot.get_node_or_null("Model")
	if model and model.get_meta(&"asset_id", &"") != weapon.asset_id:
		model.free()
		model = null
	if not model and AssetLibrary.has_model(weapon.asset_id):
		model = AssetLibrary.instantiate(weapon.asset_id)
		model.name = "Model"
		model.set_meta(&"asset_id", weapon.asset_id)
		knife_pivot.add_child(model)
	knife_mesh.visible = model == null
	if model:
		model.scale = weapon.visual_scale * HELD_MODEL_SCALE
	knife_mesh.scale = weapon.visual_scale
	knife_mesh.position.z = -0.3 * weapon.visual_scale.z
	var mat := StandardMaterial3D.new()
	mat.albedo_color = weapon.blade_color
	mat.metallic = 0.6
	knife_mesh.material_override = mat
	var gun_mesh: MeshInstance3D = gun_pivot.get_node("Gun")
	gun_mesh.scale = pistol.visual_scale
	gun_mesh.position.z = -0.15 * pistol.visual_scale.z
	muzzle.position.z = -0.38 * pistol.visual_scale.z


## Chamado pelo zumbi ao agarrar. Retorna a ordem de chegada (posição dele).
func register_grab(zombie: Node3D) -> int:
	grabbers.append(zombie)
	if grabbers.size() == 1:
		player.speed_multiplier = grabbed_speed_multiplier
		grab_changed.emit(true)
	return grabbers.size() - 1


func release_grab(zombie: Node3D) -> void:
	grabbers.erase(zombie)
	if grabbers.is_empty():
		player.speed_multiplier = 1.0
		grab_changed.emit(false)


func _find_melee_target() -> Node3D:
	grabbers.assign(grabbers.filter(func(z): return is_instance_valid(z)))
	if not grabbers.is_empty():
		return grabbers[0]
	return _nearest_ahead(weapon.reach)


## A pistola não mira em quem já está agarrando: para isso existe a faca.
func _find_ranged_target() -> Node3D:
	return _nearest_ahead(pistol.fire_range)


func _nearest_ahead(max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_ahead := max_distance
	for zombie in get_tree().get_nodes_in_group("zombie"):
		if not zombie.is_alive() or zombie in grabbers:
			continue
		var ahead: float = player.global_position.z - zombie.global_position.z
		if ahead < -0.5 or ahead > best_ahead:
			continue
		if absf(zombie.global_position.x - player.global_position.x) > target_half_width:
			continue
		best = zombie
		best_ahead = ahead
	return best


func _play_swing() -> void:
	# Golpe alternando de lado a cada toque do combo.
	_swing_side = -_swing_side
	knife_pivot.rotation.y = 1.2 * _swing_side
	var tween := create_tween()
	tween.tween_property(knife_pivot, "rotation:y", -1.2 * _swing_side, 0.12)
	tween.tween_property(knife_pivot, "rotation:y", 0.0, 0.15)


func _play_recoil() -> void:
	gun_pivot.rotation.x = 0.5
	var tween := create_tween()
	tween.tween_property(gun_pivot, "rotation:x", 0.0, 0.15)
